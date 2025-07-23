import sys
import os

def generate_hello_script(username, out_path):
    script_content = f'''
from runtime_support import greet

def main():
    greet("{username}")

if __name__ == "__main__":
    main()
'''
    with open(out_path, 'w') as f:
        f.write(script_content.lstrip())

def main():
    if len(sys.argv) < 3:
        print("Usage: python generator.py <username> <output_script.py>")
        sys.exit(1)
    username = sys.argv[1]
    out_file = sys.argv[2]
    generate_hello_script(username, out_file)
    print(f"Script generated at {out_file}.")

if __name__ == '__main__':
    main()
