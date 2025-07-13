import sys
import os

def display_file(filename):
    # Attempts to print the contents of a file line by line.
    # Supposedly, only allows access to user files under 'user_files'
    base_dir = os.path.join(os.path.dirname(__file__), '..', 'user_files')
    target_path = os.path.abspath(os.path.join(base_dir, filename))
    if not target_path.startswith(os.path.abspath(base_dir)):
        print("File access denied.")
        return
    try:
        with open(target_path, 'r') as f:
            for line in f:
                print(line.rstrip())
    except FileNotFoundError:
        print("File not found.")

def main():
    if len(sys.argv) != 2:
        print("Usage: python main.py <filename>")
        return

    display_file(sys.argv[1])

if __name__ == "__main__":
    main()
