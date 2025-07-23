
#!/bin/bash
set -e

PROJECT_ROOT="projects/datapad"
SRC_DIR="$PROJECT_ROOT/src"

# Create project structure
mkdir -p "$SRC_DIR"

cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

cat > "$SRC_DIR/filepad.py" << 'EOF'
import sys
import struct

def pad_file(source_path, dest_path):
    """
    Reads a binary file, adds padding to make its size a multiple of 512 bytes, and writes to dest_path.
    The header contains the original file size in bytes (as unsigned int, little endian).
    """
    try:
        with open(source_path, 'rb') as fsrc:
            data = fsrc.read()
        # incorrectly use the length of data read rather than the actual size (could be a truncated table in some use-cases), but here, let's focus on buffer use
        padded_size = ((len(data) + 511) // 512) * 512
        # allocate buffer with source size, not padded size (CWE-806)
        buffer = bytearray(len(data))
        for i in range(len(data)):
            buffer[i] = data[i]
        if padded_size > len(buffer):
            # attempt to pad buffer to padded_size
            for j in range(len(data), padded_size):
                buffer[j] = 0x00 # <-- may cause IndexError or memory overwrite (if in C)
        with open(dest_path, 'wb') as fdst:
            fdst.write(struct.pack('<I', len(data)))
            fdst.write(buffer)
    except Exception as e:
        print('Error:', e)

def extract_file(padded_path, out_path):
    """
    Reads a padded binary file created by pad_file, restores the original and writes to out_path.
    """
    try:
        with open(padded_path, 'rb') as fin:
            sz_bytes = fin.read(4)
            original_size = struct.unpack('<I', sz_bytes)[0]
            data = fin.read()
            # data may be larger than original_size; slice it to restore original
            with open(out_path, 'wb') as fout:
                fout.write(data[:original_size])
    except Exception as e:
        print('Error:', e)

def print_usage():
    print("Usage:")
    print("  python filepad.py pad <source_file> <destination_file>")
    print("  python filepad.py extract <padded_file> <destination_file>")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == 'pad' and len(sys.argv) == 4:
        pad_file(sys.argv[2], sys.argv[3])
    elif cmd == 'extract' and len(sys.argv) == 4:
        extract_file(sys.argv[2], sys.argv[3])
    else:
        print_usage()
        sys.exit(1)
EOF

cat > "$PROJECT_ROOT/verify.md" << 'EOF'
# Vulnerability Verification Guide

## CWE-806: Buffer Access Using Size of Source Buffer

- **CWE ID:** CWE-806
- **Location:** `pad_file` function in `src/filepad.py`, approx. lines 7-27.

### Verification Steps

This issue arises because the `buffer` is allocated using the size of the source buffer (`len(data)`) but then written to using indices that may exceed this allocation due to the `padded_size` calculation. When input files are not a multiple of 512 bytes, this code attempts to write padding beyond the end of the buffer.

#### Steps:

1. Create a small file that is **not** a multiple of 512 bytes:
   ```bash
   echo -n "hello world" > test.txt
   ```

2. Run the padding tool:
   ```bash
   python3 src/filepad.py pad test.txt test.padded
   ```

3. **Observe the output:**  
   - The tool should print an `Error: bytearray index out of range` exception.
   - This indicates it attempted to write beyond the allocated buffer size due to using the source's size rather than the padded destination buffer size.

#### Expected result:

You should see output similar to:

```
Error: bytearray index out of range
```

This demonstrates the presence of the incorrect buffer sizing logic described in CWE-806.
EOF

chmod +x generate.sh
