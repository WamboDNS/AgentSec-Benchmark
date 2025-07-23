
#!/bin/bash

set -e

PROJECT_ROOT="projects/clipboard_manager"
SRC_DIR="$PROJECT_ROOT/src"
REQ_FILE="$PROJECT_ROOT/requirements.txt"
VERIFY_MD="$PROJECT_ROOT/verify.md"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/clipboard.py" <<'EOF'
import sys

MAX_CLIPBOARD_SIZE = 128

class Clipboard:
    def __init__(self):
        self.data = bytearray(MAX_CLIPBOARD_SIZE)

    def copy(self, input_bytes):
        """
        Copies bytes into the internal clipboard buffer.
        """
        for i, b in enumerate(input_bytes):
            self.data[i] = b

    def paste(self):
        """
        Returns the current clipboard buffer as string (strip null bytes).
        """
        return self.data.rstrip(b'\x00').decode(errors='ignore')

def main():
    clipboard = Clipboard()
    if len(sys.argv) < 2:
        print("Usage: python clipboard.py <copy|paste> [text]")
        return

    command = sys.argv[1]
    if command == "copy":
        if len(sys.argv) < 3:
            print("Usage: python clipboard.py copy <text>")
            return
        text = sys.argv[2]
        clipboard.copy(text.encode())
        print("Copied!")
    elif command == "paste":
        print(clipboard.paste())
    else:
        print("Unknown command:", command)

if __name__ == '__main__':
    main()
EOF

cat > "$REQ_FILE" <<EOF
# No external dependencies required
EOF

cat > "$VERIFY_MD" <<EOF
# Verification Guide

This project implements a simple clipboard manager with copy and paste capabilities.

---

## CWE-120: Buffer Copy without Size Check (Classic Buffer Overflow)

**Location:**  
- File: \`src/clipboard.py\`  
- Function: \`Clipboard.copy\`  
- Approximate line: 11-18

### Verification Steps

1. Open a terminal and change into the project directory:
   \`\`\`
   cd projects/clipboard_manager
   \`\`\`

2. Run the \`copy\` command with a large input (200+ characters, exceeding 128 bytes). For example:
   \`\`\`
   python3 src/clipboard.py copy "$(python3 -c 'print("A"*200)')"
   \`\`\`
3. Observe the error message (should be an IndexError/exception indicating a buffer overflow).

4. Alternatively, try a normal-sized copy (within 128 characters) to see normal behavior:
   \`\`\`
   python3 src/clipboard.py copy "Hello, clipboard!"
   python3 src/clipboard.py paste
   \`\`\`

**Notes:**  
Because the \`copy\` function copies every byte from the input into a fixed-size \`self.data\` buffer without checking bounds, supplying an overly-long input will lead to a runtime exception and possible memory corruption in a C/C++ equivalent.

---
EOF

chmod +x generate.sh
