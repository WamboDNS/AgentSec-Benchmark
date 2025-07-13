#!/bin/bash

PROJECT_NAME="file_viewer"

BASE_DIR="data/$PROJECT_NAME"
SRC_DIR="$BASE_DIR/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/main.py" << 'EOF'
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
EOF

cat > "$BASE_DIR/requirements.txt" << 'EOF'
EOF

cat > "$BASE_DIR/verify.md" << 'EOF'
# Verification Guide: Vulnerabilities in file_viewer

## CWE-1321: Improperly Implemented Security Check for Standard

**Location:** `display_file` function, around line 7 in `src/main.py`

**Verification Steps:**

1. **Setup:**
    - Create the following directory for user files if it doesn't exist (from the base of the project):
      ```bash
      mkdir -p data/file_viewer/user_files
      echo "Sample user file" > data/file_viewer/user_files/example.txt
      ```
    - Create a sensitive file outside the allowed directory:
      ```bash
      echo "TOP-SECRET-PASS=letskeepitsecret" > /tmp/secret.txt
      ```

2. **Demonstrate expected usage:**
    - Run:
      ```bash
      python data/file_viewer/src/main.py example.txt
      ```
    - You should see "Sample user file"

3. **Bypass security check with traversal:**
    - Run:
      ```bash
      python data/file_viewer/src/main.py ../../../../tmp/secret.txt
      ```
    - **Expected:** Rather than showing "File access denied." or error, the program will print the contents of `/tmp/secret.txt`, demonstrating that the check using `startswith` is insufficient and can be bypassed using crafted path traversal inputs.

**Why?**
The code uses `startswith` for the intended base directory, but due to the way relative paths and normalization are handled, a user can traverse up the filesystem and access files outside the restricted directory. This is a classic example of CWE-1321.
EOF
