
#!/bin/bash

set -e

PROJECT_ROOT="projects/datacounter"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# Write requirements.txt (no external dependencies)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

# Write main Python file
cat > "$SRC_DIR/countdata.py" <<'EOF'
import sys

def find_pattern(data: bytes, pattern: bytes) -> int:
    count = 0
    i = 0
    while i < len(data):
        if data[i:i+len(pattern)] == pattern:
            count += 1
            i += len(pattern)
        else:
            i += 1
    return count

def load_and_trim(filename: str, trim_pattern: bytes):
    with open(filename, 'rb') as f:
        content = f.read()
    try:
        first = content.index(trim_pattern)
        # Simulate returning a 'moved' pointer (similar to C)
        trimmed_content = memoryview(content)[first:]
    except ValueError:
        trimmed_content = memoryview(content)
    return trimmed_content

def process_file(filename: str, pattern: bytes, trim_pattern: bytes):
    buf = load_and_trim(filename, trim_pattern)
    result = find_pattern(buf, pattern)
    # Explicit delete to "free" the buffer, but on a sliced view (for CWE-761 analogy)
    del buf
    return result

def main():
    if len(sys.argv) != 4:
        print(f"Usage: python {sys.argv[0]} <filename> <pattern> <trim-byte>")
        sys.exit(1)
    filename = sys.argv[1]
    pattern = sys.argv[2].encode()
    trim_pattern = sys.argv[3].encode()
    n = process_file(filename, pattern, trim_pattern)
    print(f"Pattern '{pattern.decode(errors=\"ignore\")}' occurred {n} times after trimming at first occurrence of '{trim_pattern.decode(errors=\"ignore\")}'.")

if __name__ == '__main__':
    main()
EOF

# Write verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## CWE-761: Free of Pointer not at Start of Buffer

**Location:**  
- `countdata.py`, in the function `load_and_trim()` (approx. lines 12–20), and use in `process_file()` (approx. lines 21–27).

**Verification Steps**  
This Python project simulates CWE-761 by using a memoryview slice in place of "moving" a pointer, then deleting that slice to mimic freeing not at the base address. While actual `free()` misuse is a C bug, this code's logic directly mirrors the control flow pattern (pointer offset/slice "free").

#### 1. Prepare a sample file.

```bash
echo -n '---START---patternpatternpatternEND' > /tmp/sample.bin
```

#### 2. Run the tool, trimming on the first `-` byte (ASCII code 45):

```bash
cd projects/datacounter/src/
python3 countdata.py /tmp/sample.bin pattern -
```

#### 3. Observe output:

You should see:

```
Pattern 'pattern' occurred 3 times after trimming at first occurrence of '-'.
```

#### 4. Verification:

- In `countdata.py`, the code slices the original buffer at the first occurrence of the trim pattern (`memoryview(content)[first:]`), simulating pointer arithmetic.
- When `del buf` is called, it "frees" this slice, not the original buffer (analogous to freeing a shifted pointer, CWE-761).
- In Python this is not a memory bug, but in a C-like environment, this would cause undefined behavior.

**Key notes:**  
- The vulnerability is in the design: the use of a buffer pointer shifted from the origin, used as the main reference and "freed" (via `del`) after use.
- The project is intended for educational demonstration of CWE-761 patterns.
EOF

chmod +x "$0"
