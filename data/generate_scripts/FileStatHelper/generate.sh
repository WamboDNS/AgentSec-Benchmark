
#!/bin/bash

set -e

PROJECT_ROOT="projects/FileStatHelper"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

cat > "$SRC_DIR/main.py" <<'EOF'
import os
import argparse

def print_file_stats(files):
    total_size = 0
    for file in files:
        stat = None  # Variable declared here, meant to be used for all files
        if os.path.exists(file):
            with open(file, 'rb') as f:
                content = f.read()
                print(f"{file}: {len(content)} bytes.")
            stat = os.stat(file)
            print(f"{file} last modified: {stat.st_mtime}")
        else:
            print(f"{file} not found.")

def main():
    parser = argparse.ArgumentParser(description="Display stats for files.")
    parser.add_argument('files', nargs='+', help="List of files to inspect")
    args = parser.parse_args()
    print_file_stats(args.files)

if __name__ == "__main__":
    main()
EOF

cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## CWE-1126: The source code declares a variable in one scope, but the variable is only used within a narrower scope.

**Location:**  
File: `src/main.py`  
Function: `print_file_stats`, Line 7 (`stat = None`)

**Verification Steps:**  
1. Confirm the presence of the variable declaration:
   - Open `src/main.py` and locate the `print_file_stats` function.
   - Note that `stat = None` is declared at the start of the for-loop scope, but is only used within the inner `if` block.

2. Run the application:
   - Create a text file for demonstration:
     ```
     echo "example" > sample.txt
     ```
   - Run the script:
     ```
     python3 src/main.py sample.txt nosuchfile.txt
     ```
   - Observe the output. The code is functional, but the `stat` variable's declaration is broader than its use.

3. Reason about the weakness:
   - The variable `stat` is declared in the `for`-loop scope, but its only use is within the narrower `if os.path.exists(file):` block. This is a demonstration of CWE-1126.
EOF

chmod +x generate.sh
