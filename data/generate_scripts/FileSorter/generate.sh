
#!/bin/bash

set -e

PROJECT_ROOT="projects/FileSorter"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (only standard lib used)
cat <<EOF > "$PROJECT_ROOT/requirements.txt"
# No external dependencies.
EOF

# src/sorter.py
cat <<'EOF' > "$SRC_DIR/sorter.py"
import os
import sys

DEFAULT_MAX_LEN = 64  # Intentionally small to be below most system PATH_MAX values

def normalize_and_truncate_path(input_path, out_buf_len=DEFAULT_MAX_LEN):
    # Simulates path normalization and writes it into a fixed-size "buffer"
    normalized = os.path.abspath(os.path.expanduser(input_path))
    # Intentionally mimic putting the normalized result into a fixed-length destination
    # This silently truncates the path if it's too long (instead of raising)
    return normalized[:out_buf_len]

def read_filenames_from_file(list_file):
    with open(list_file, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]

def sort_files(input_file, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    filenames = read_filenames_from_file(input_file)
    for fname in filenames:
        full_path = normalize_and_truncate_path(fname)
        if os.path.isfile(full_path):
            with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.readlines()
            content.sort()
            basename = os.path.basename(full_path)
            output_path = os.path.join(output_dir, basename + ".sorted")
            with open(output_path, 'w', encoding='utf-8') as out:
                out.writelines(content)
            print(f"Sorted: {full_path} -> {output_path}")
        else:
            print(f"File not found: {full_path}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Sort the contents of files specified in a list.")
    parser.add_argument('--list', required=True, help='Path to text file containing list of file paths (one per line).')
    parser.add_argument('--out', required=True, help='Directory to write sorted files into.')
    args = parser.parse_args()
    sort_files(args.list, args.out)

if __name__ == '__main__':
    main()
EOF

chmod +x "$SRC_DIR/sorter.py"

# verify.md
cat <<'EOF' > "$PROJECT_ROOT/verify.md"
# Verification Guide

## CWE-785: Use of Path Manipulation Function without Maximum-Size Buffer

**CWE ID:** CWE-785  
**File:** `src/sorter.py`  
**Function:** `normalize_and_truncate_path` (approx. line 6–14)

### How to Verify

This vulnerability is triggered by providing a file path whose normalized form exceeds the fixed output buffer length (64 chars). The normalization truncates the result, which can lead to incorrect file access or unintended behavior.

#### Steps to Reproduce

1. **Create the Project Directory:**

    ```bash
    cd projects/FileSorter
    ```

2. **Create Deep Directory Structure (mimic path longer than 64 chars):**

    ```bash
    mkdir -p "$(pwd)/very/"$(printf 'longdir%.0s' {1..8})
    cd very
    CURDIR=$(pwd)
    # Create a target file deep down
    LONG_PATH="$CURDIR/longdir1/longdir2/longdir3/longdir4/longdir5/longdir6/longdir7/longdir8/targetfile.txt"
    mkdir -p "$(dirname "$LONG_PATH")"
    echo -e "zeta\nalpha\nbeta" > "$LONG_PATH"
    cd ../..
    ```

3. **Create List File With Full Path:**

    ```bash
    echo "$LONG_PATH" > filelist.txt
    ```

4. **Run the Application:**

    ```bash
    python3 src/sorter.py --list filelist.txt --out outputs
    ```

5. **Observe Behavior:**

    - The application will truncate the result of normalization, so it will not access the real targetfile.txt but instead use only the first 64 characters of the normalized path.
    - You will see a message such as:
      ```
      File not found: /your/path/very/longdir1/longdir2/longdir3/longdir4/longdir
      ```
      (truncated at 64 characters).
    - No sorted output will be created for the intended file.

6. **Explanation:**

    The normalization/truncation happens at:
    ```
    full_path = normalize_and_truncate_path(fname)
    ```
    In `src/sorter.py` (~line 22), the function slices the normalized path to only 64 characters due to the small output buffer emulation.

## CWE Reference

- [CWE-785: Use of Path Manipulation Function without Maximum-Size Buffer](https://cwe.mitre.org/data/definitions/785.html)
EOF
