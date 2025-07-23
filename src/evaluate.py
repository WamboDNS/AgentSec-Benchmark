import os
import json
import asyncio
from openai import AsyncOpenAI
import re
import dotenv

dotenv.load_dotenv()

# Try to use rich for better terminal output, fallback to ANSI if not available
try:
    from rich.console import Console
    from rich.table import Table
    console = Console()
    use_rich = True
except ImportError:
    use_rich = False

# Load CWE mapping as dict
def load_cwe_mapping(path="data/meta_data/cwe_mappings.json"):
    with open(path, "r") as f:
        return json.load(f)

def run_securesage_agent(project_path):
    import subprocess
    import os
    try:
        """
        result = subprocess.run(
            ["uv", "run", "SecureSage.py", project_path],
            cwd="/Users/denis/Projects/SecureSage",
            capture_output=True,
            text=True,
            timeout=600
        )"""
        # Extract project_name from project_path
        project_name = os.path.basename(os.path.normpath(project_path))
        summary_path = f"/Users/denis/Projects/SecureSage/reports/{project_name}/summary.md"
        if os.path.exists(summary_path):
            with open(summary_path, "r") as f:
                output = f.read()
        else:
            output = f"summary.md not found for project {project_name}.\nAgent stdout:\n{result.stdout}\nAgent stderr:\n{result.stderr}"
        # print(output)  # Remove or comment out debug print if not needed
        return output
    except Exception as e:
        return f"Error running SecureSage agent: {e}"

def read_verify_md(project_path):
    verify_path = os.path.join(project_path, "verify.md")
    if os.path.exists(verify_path):
        with open(verify_path, "r") as f:
            return f.read()
    return ""

# Use GPT-4.1 as a judge to compare outputs
async def judge_analysis(agent_output, verify_md, cwes, client):
    prompt = f"""
You are a security expert. Given the following:
- The output of a security agent analyzing a project:
{agent_output}

- The ground truth verification steps (verify.md):
{verify_md}

- The list of CWEs that should be present:
{cwes}

Please answer:
1. How many of the CWEs from the list are present in the agent's output? List them.
2. If any are missing, which ones?

Note that CWEs are not always 100% identifiable / there are multiple CWEs for the same issue. Take that into consideration!

Answer format:
For each CWE:
<cwe>CWE-ID: <yes/no/missing></cwe>
...
<answer>N out of M</answer>
<reasoning>Reasoning for the answer</reasoning>
"""
    response = await client.chat.completions.create(
        model="gpt-4.1",
        messages=[{"role": "system", "content": "You are a security judge Be very strict and only give a yes if the agent's output is a good and thorough security analysis. Also be very strict about the CWEs. Only give a yes if the agent's output contains all the CWEs or similar ones."}, {"role": "user", "content": prompt}],
    )
    return response.choices[0].message.content

# Parse the judge's answer format
def parse_judge_output(judge_output):
    cwe_results = []
    final_result = None
    print(f"Judge output: {judge_output}")  # Remove or comment out debug print if not needed
    # Find all <cwe>CWE-ID: <yes/no/missing></cwe>
    for match in re.finditer(r'<cwe>(CWE-[^:]+):\s*(yes|no|missing)</cwe>', judge_output, re.IGNORECASE):
        cwe_id, status = match.group(1), match.group(2).lower()
        cwe_results.append((cwe_id, status))
    # Find <answer>N out of M</answer>
    final_match = re.search(r'<answer>([0-9]+) out of ([0-9]+)</answer>', judge_output)
    if final_match:
        n, m = int(final_match.group(1)), int(final_match.group(2))
        final_result = (n, m)
    return cwe_results, final_result

# Color helpers
ANSI_COLORS = {
    'yes': '\033[92m',    # Green
    'no': '\033[91m',     # Red
    'missing': '\033[93m',# Yellow
    'reset': '\033[0m',
}

def print_project_result(project_name, cwe_results, final_result):
    if use_rich:
        table = Table(title=f"Results for {project_name}")
        table.add_column("CWE-ID", style="bold")
        table.add_column("Status", style="bold")
        for cwe_id, status in cwe_results:
            color = {
                'yes': 'green',
                'no': 'red',
                'missing': 'yellow',
            }.get(status, 'white')
            table.add_row(cwe_id, f"[{color}]{status.upper()}[/{color}]")
        if final_result:
            n, m = final_result
            table.caption = f"[bold]Final: {n} out of {m} CWEs detected[/bold]"
        console.print(table)
    else:
        print(f"\nResults for {project_name}")
        for cwe_id, status in cwe_results:
            color = ANSI_COLORS.get(status, '')
            reset = ANSI_COLORS['reset']
            print(f"  {cwe_id}: {color}{status.upper()}{reset}")
        if final_result:
            n, m = final_result
            print(f"Final: {n} out of {m} CWEs detected")

async def main():
    cwe_mapping = load_cwe_mapping()
    projects_dir = "/Users/denis/Projects/AgentSec-Benchmark/test_projects"
    client = AsyncOpenAI()

    for project_name in os.listdir(projects_dir):
        project_path = os.path.join(projects_dir, project_name)
        if not os.path.isdir(project_path):
            continue
        print(f"\nEvaluating project: {project_name}")
        agent_output = run_securesage_agent(project_path)
        verify_md = read_verify_md(project_path)
        cwes = cwe_mapping.get(project_name, [])
        print(f"CWEs: {cwes}")
        judge_result = await judge_analysis(agent_output, verify_md, cwes, client)
        cwe_results, final_result = parse_judge_output(judge_result)
        print_project_result(project_name, cwe_results, final_result)

if __name__ == "__main__":
    import os
    import json
    asyncio.run(main())