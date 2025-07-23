
#!/bin/bash

set -e

PROJECT_ROOT="projects/datamerge"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (no dependencies required)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

# main python application
cat > "$SRC_DIR/merger.py" <<'EOF'
import sys

def to_int_or_none(element):
    try:
        return int(element)
    except Exception:
        return None

def read_numbers_from_file(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()
    return [line.strip() for line in lines if line.strip()]

def merge_and_sum(file1, file2, output):
    numbers1 = read_numbers_from_file(file1)
    numbers2 = read_numbers_from_file(file2)

    merged = []
    for item in numbers1 + numbers2:
        value = to_int_or_none(item)
        merged.append(value)

    total_sum = sum(merged)
    with open(output, "w") as f:
        f.write(str(total_sum) + "\n")

    print(f"Merged {len(numbers1)} + {len(numbers2)} items. Output written to {output}.")

def main():
    if len(sys.argv) != 4:
        print("Usage: python merger.py <input_file1> <input_file2> <output_file>")
        sys.exit(1)
    file1, file2, output = sys.argv[1:4]
    merge_and_sum(file1, file2, output)

if __name__ == "__main__":
    main()
EOF

chmod +x "$SRC_DIR/merger.py"

# Create verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## Vulnerability 1

- **CWE ID:** CWE-464 (Addition of Data Structure Sentinel)
- **Location:** Function: `to_int_or_none`, `merge_and_sum` in `src/merger.py` (approx lines 4-24)

### Explanation
Invalid conversions via `int()` (e.g., when a file contains a non-integer like "hello" or an empty string) are mapped to `None` by `to_int_or_none`. These `None` values are then appended to the merged list and directly summed: `sum(merged)`. However, Python's `sum` will raise a TypeError if `None` is present—this is detectable via testing. In certain languages, `None` (or the equivalent sentinel) can pass silently, introducing logic flaws. Here, the subtle risk is that unexpected `None` values as sentinels enter the data structure due to failed conversion, reflecting CWE-464.

### Steps to Verify

#### 1. Create two test files:

```bash
echo -e "1\n2\nhello\n4" > file1.txt
echo -e "6\n" > file2.txt
```

#### 2. Run the program:

```bash
cd projects/datamerge/src
python merger.py ../../file1.txt ../../file2.txt output.txt
```

#### 3. Observe the exception:

You should see a traceback ending with:

```
TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
```

#### 4. Interpretation

This demonstrates that the data structure (the merged list) has been unintentionally polluted with a sentinel value (`None`), breaking logic. If the code attempted to handle these merged results with, for example, `filter(None, merged)`, the sum would silently drop all zeros and `None`, creating subtle logic errors. In this code, the unhandled sentinel directly causes failure.

#### 5. Clean up

```bash
rm ../../file1.txt ../../file2.txt output.txt
```

EOF

echo "Project datamerge generated in $PROJECT_ROOT"
