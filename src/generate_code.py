from dotenv import load_dotenv
from openai import OpenAI
from prompt import PROMPT as system_prompt
from typing import List, Tuple
import random
import json
import os
import re

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
random.seed(42)

def prompt_script(cwes: list[tuple[str, str]]) -> str:
    messages = [{"role": "system", "content": system_prompt}]
    messages.append({"role": "user", "content": f"CWE IDs: {cwes}"})
    response = client.chat.completions.create(
        model="gpt-4.1",
        messages=messages,
    )
    return response.choices[0].message.content

def generate(response: str) -> bool:
    project_name = parse_xml(response, "name")
    code = parse_xml(response, "code")
    verify = parse_xml(response, "verify")
    
    try:
        dir_path = f"data/generate_scripts/{project_name}"
        os.makedirs(dir_path, exist_ok=True)
        with open(f"{dir_path}/generate.sh", "w") as f:
            f.write(code)
        
        with open(f"{dir_path}/verify.md", "w") as f:
            f.write(verify)
        update_cwe_mapping(project_name, cwes)
        return True
    except Exception as e:
        print(f"Error generating script: {e}")
        return False
    
def get_cwes(n: int = 10) -> List[Tuple[str, str]]:
    cwes: List[str] = []
    with open("data/meta_data/extracted_cwes.json", "r") as f:
        file_content = json.load(f)
        cwes = [(cwe["id"], cwe["description"]) for cwe in file_content]
    return random.sample(cwes, n)

def update_cwe_mapping(project_name: str, cwes: List[Tuple[str, str]]) -> None:
    mapping = "data/meta_data/cwe_mappings.json"
    with open(mapping, "r") as f:
        file_content = json.load(f)
        file_content[project_name] = cwes
    with open(mapping, "w") as f:
        json.dump(file_content, f)
        
def parse_xml(xml_file: str, key: str) -> str:
    thinking = re.search(fr'<{key}>(.*?)</{key}>', response, re.DOTALL)
    if thinking:
        return thinking.group(1)
    return None
    
if __name__ == "__main__":
    cwes: List[Tuple[str, str]] = []
    cwes = get_cwes(n=3)
    print(f"CWE IDs: {cwes}")
    response = prompt_script(cwes)
    generate(response)
    