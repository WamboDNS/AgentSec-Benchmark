
#!/bin/bash

set -e

PROJECT_ROOT="projects/FileIndexManager"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

cat > "$SRC_DIR/main.py" <<'EOF'
import sys
import os

INDEX_FILENAME = "file_index.txt"

def scan_dir(directory):
    index = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            path = os.path.join(root, f)
            try:
                size = os.stat(path).st_size
            except Exception:
                size = -1
            index.append((path, size))
    return index

def write_index(index, out_file):
    with open(out_file, 'w') as f:
        for path, size in index:
            f.write(f"{path},{size}\n")

def load_index(in_file):
    index = []
    try:
        with open(in_file, 'r') as f:
            for line in f:
                path, size = line.rstrip('\n').split(',', 1)
                index.append((path, int(size)))
    except Exception:
        pass
    return index

def search_index(index, query):
    found = []
    for path, size in index:
        # Should use 'in' but accidentally uses 'is' operator (CWE-480)
        if query is path:
            found.append((path, size))
    return found

def print_usage():
    print("Usage:")
    print("  python main.py scan <directory>")
    print("  python main.py search <query>")

def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == 'scan':
        if len(sys.argv) != 3:
            print_usage()
            sys.exit(1)
        dir_to_scan = sys.argv[2]
        index = scan_dir(dir_to_scan)
        write_index(index, INDEX_FILENAME)
        print(f"Indexed {len(index)} files in '{dir_to_scan}' into {INDEX_FILENAME}")
    elif cmd == 'search':
        if len(sys.argv) != 3:
            print_usage()
            sys.exit(1)
        query = sys.argv[2]
        index = load_index(INDEX_FILENAME)
        results = search_index(index, query)
        if results:
            print("Results:")
            for path, size in results:
                print(f"{path} ({size} bytes)")
        else:
            print("No matches found.")
    else:
        print_usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
EOF

cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide for FileIndexManager

## CWE-480: Use of Incorrect Operator

**Location:**  
Function: `search_index`  
File: `src/main.py`  
Lines: Approx. 28-33

### How to verify:

**1. Setup**

```bash
cd projects/FileIndexManager
mkdir testdir
echo hello > testdir/abc.txt
echo world > testdir/def.txt
python3 src/main.py scan testdir
```

**2. Search for file by name:**

Since the code uses `is` instead of `in` or `==` (line 31):

```bash
python3 src/main.py search abc.txt
```

**Expected Result:**

Even though a file "abc.txt" is present, **"No matches found."** is printed.
A correct implementation with `if query in path:` or `==` would have found the file.

**3. What happens:** 

- The comparison `if query is path:` checks for *object identity*, not string content equality or substring inclusion.
- Unless by coincidence `query` and `path` are exactly the same object (not just equal strings), the match will always fail.

**4. Fix:**  
Change `if query is path:` to `if query in path:` or `if query == path:` for expected search behavior.
EOF

chmod +x generate.sh
