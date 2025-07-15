from dotenv import load_dotenv
from openai import AsyncOpenAI
from prompt import PROMPT as system_prompt
from typing import List, Tuple
import random
import json
import os
import re
import subprocess
import asyncio
import aiofiles

load_dotenv()

client = AsyncOpenAI(api_key=os.getenv("OPENAI_API_KEY"))
random.seed(777)

async def prompt_script(cwes: list[tuple[str, str]]) -> str:
    messages = [{"role": "system", "content": system_prompt}]
    messages.append({"role": "user", "content": f"CWE IDs: {cwes}"})
    response = await client.chat.completions.create(
        model="gpt-4.1",
        messages=messages,
    )
    return response.choices[0].message.content

async def generate(response: str, cwes: List[Tuple[str, str]]) -> bool:
    project_name = parse_xml(response, "name")
    code = parse_xml(response, "code")
    verify = parse_xml(response, "verify")
    
    try:
        dir_path = f"data/generate_scripts/{project_name}"
        os.makedirs(dir_path, exist_ok=True)
        
        async with aiofiles.open(f"{dir_path}/generate.sh", "w") as f:
            await f.write(code)
            
        os.chmod(f"{dir_path}/generate.sh", 0o755)
        
        # Execute the script
        print(f"Executing generate.sh for project: {project_name}")
        print(os.getcwd())
        result = subprocess.run(["bash", f"./{dir_path}/generate.sh"], capture_output=True, text=True)
        
        async with aiofiles.open(f"{dir_path}/verify.md", "w") as f:
            await f.write(verify)
        await update_cwe_mapping(project_name, cwes)
        return True
    except Exception as e:
        print(f"Error generating script: {e}")
        return False
    
def get_cwes(n: int = 5) -> List[Tuple[str, str]]:
    cwes: List[str] = []
    with open("data/meta_data/extracted_cwes.json", "r") as f:
        file_content = json.load(f)
        cwes = [(cwe["id"], cwe["description"]) for cwe in file_content]
    return random.sample(cwes, n)

async def update_cwe_mapping(project_name: str, cwes: List[Tuple[str, str]]) -> None:
    mapping = "data/meta_data/cwe_mappings.json"
    
    # Create the file if it doesn't exist
    if not os.path.exists(mapping):
        os.makedirs(os.path.dirname(mapping), exist_ok=True)
        file_content = {}
    else:
        async with aiofiles.open(mapping, "r") as f:
            content = await f.read()
            file_content = json.loads(content)
    
    file_content[project_name] = cwes
    lock = asyncio.Lock()
    async with lock:
        async with aiofiles.open(mapping, "w") as f:
            await f.write(json.dumps(file_content, indent=2))
        
def parse_xml(response: str, key: str) -> str:
    thinking = re.search(fr'<{key}>(.*?)</{key}>', response, re.DOTALL)
    if thinking:
        return thinking.group(1)
    return None

async def start_generation(n: int) -> None:
    cwes: List[Tuple[str, str]] = []
    cwes = get_cwes(n=n)
    print(f"CWE IDs: {cwes}")
    response = await prompt_script(cwes)
    await generate(response, cwes)
    
async def main():
    # Generate projects with 1 CWE each
    tasks_1 = []
    for i in range(50):
        task = start_generation(n=1)
        tasks_1.append(task)
    await asyncio.gather(*tasks_1)
    
    # Generate projects with 3 CWEs each
    """tasks_3 = []
    for i in range(50):
        task = start_generation(n=3)
        tasks_3.append(task)
    await asyncio.gather(*tasks_3)
    
    # Generate projects with 5 CWEs each
    tasks_5 = []
    for i in range(50):
        task = start_generation(n=5)
        tasks_5.append(task)
    await asyncio.gather(*tasks_5)
    
    # Generate projects with 10 CWEs each
    tasks_10 = []
    for i in range(50):
        task = start_generation(n=10)
        tasks_10.append(task)
    await asyncio.gather(*tasks_10)"""

if __name__ == "__main__":
    asyncio.run(main())