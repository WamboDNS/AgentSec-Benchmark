
#!/bin/bash
set -e

PROJECT_ROOT="projects/TextScriptor"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

# src/generator.py
cat > "$SRC_DIR/generator.py" <<'PYEOF'
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
PYEOF

# src/runtime_support.py (this file is *not* provided by the generator by default)
cat > "$SRC_DIR/runtime_support.py" <<'PYEOF'
def greet(name):
    print(f"Hello, {name}! Welcome to TextScriptor.")
PYEOF

# src/__init__.py
touch "$SRC_DIR/__init__.py"

# Quickstart readme
cat > "$PROJECT_ROOT/README.md" <<'EOF'
# TextScriptor

TextScriptor is a simple code generator utility that creates personalized Python greeter scripts.

## Example usage

Generate a personalized script:
```
python src/generator.py Alice hello_greeter.py
```

This creates `hello_greeter.py`. The script requires a runtime support module to function.
EOF

chmod +x "$SRC_DIR/generator.py"
chmod +x "$PROJECT_ROOT/requirements.txt"
