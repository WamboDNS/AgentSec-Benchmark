from dotenv import load_dotenv
from openai import OpenAI
from prompt import PROMPT as system_prompt
from typing import List
import random
import json
import os

load_dotenv()

client = OpenAI(api_key=os.getenv("OPENAI_API_KEY"))
random.seed(777)

def generate_script(cwes: list[str]) -> bool:
    messages = [{"role": "system", "content": system_prompt}]
    messages.append({"role": "user", "content": f"CWE IDs: {cwes}"})
    response = client.chat.completions.create(
        model="gpt-4.1",
        messages=messages,
    )
    with open("data/generated_script.sh", "w") as f:
        f.write(response.choices[0].message.content)
    
def get_cwes(n: int = 10) -> List[str]:
    cwes: List[str] = []
    with open("data/extracted_cwes.json", "r") as f:
        file_content = json.load(f)
        cwes = [cwe["id"] for cwe in file_content] # maybe add description here and in system prompt also
    return random.sample(cwes, n)
    
if __name__ == "__main__":
    cwes: List[str] = []
    cwes = get_cwes(n=1)
    print(f"CWE IDs: {cwes}")
    generate_script(cwes)