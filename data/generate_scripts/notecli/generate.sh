
#!/bin/bash

set -e

PROJECT_ROOT="projects/notecli"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# Create main CLI application
cat > "$SRC_DIR/main.py" <<EOF
import argparse
from getpass import getpass

def save_note(username, password, title, content):
    # Trivial file storage demo (not secure, just for example)
    filename = f"\${username}_notes.txt"
    with open(filename, "a") as f:
        f.write(f"Title: \${title}\\n")
        f.write(f"Content: \${content}\\n")
        f.write("-" * 40 + "\\n")

def list_notes(username):
    filename = f"\${username}_notes.txt"
    try:
        with open(filename, "r") as f:
            print(f.read())
    except FileNotFoundError:
        print("No notes found.")

def main():
    parser = argparse.ArgumentParser(description='notecli - Manage your notes.')
    subparsers = parser.add_subparsers(dest='command')

    add_parser = subparsers.add_parser('add', help='Add a new note')
    add_parser.add_argument('--username', required=True, help='Your username')
    # --- CWE-549: Password input is not masked ---
    add_parser.add_argument('--password', required=True, help='Your password')
    add_parser.add_argument('--title', required=True, help='Note title')
    add_parser.add_argument('--content', required=True, help='Note content')

    view_parser = subparsers.add_parser('list', help='List your notes')
    view_parser.add_argument('--username', required=True, help='Your username')
    # List command also asks for password (not masked)
    view_parser.add_argument('--password', required=True, help='Your password')

    args = parser.parse_args()

    if args.command == 'add':
        # Password is not validated in demo, but shown in plaintext (CWE-549)
        save_note(args.username, args.password, args.title, args.content)
        print("Note saved.")
    elif args.command == 'list':
        list_notes(args.username)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
EOF

# Create requirements.txt (empty, only stdlib is used)
echo "" > "$PROJECT_ROOT/requirements.txt"

# Create verify.md guide
cat > "$PROJECT_ROOT/verify.md" <<EOF
# Vulnerability Verification Guide

## 1. CWE-549: Missing Password Masking (Passwords Displayed in Plaintext Input)

**CWE ID:** CWE-549  
**Description:** Passwords provided to the CLI are visible during input because the argument parser uses standard command line flags which are echoed on screen, instead of masking the password input.

**Location:**  
- File: \`src/main.py\`  
- Functions: CLI argument definitions / lines ~14-27 for both the "add" and "list" commands where \`--password\` is a normal argument.

### Verification Steps

#### 1. Run the CLI app and observe password entry

1. In your terminal, navigate to the project directory:

   \`\`\`bash
   cd projects/notecli/src
   \`\`\`

2. Run the CLI to add a note:

   \`\`\`bash
   python3 main.py add --username alice --password MySecret123 --title "Groceries" --content "Eggs, Milk"
   \`\`\`

   - Notice that the password "MySecret123" is fully visible in your shell history and on-screen input.

3. Alternatively, run the "list" command (again, password is exposed on command line):

   \`\`\`bash
   python3 main.py list --username alice --password MySecret123
   \`\`\`

4. You can also view your shell history (e.g., \`history | grep main.py\`) and see the plaintext password:

   \`\`\`bash
   history | grep main.py
   \`\`\`

**Result:**  
The password is not masked or securely handled during entry. Anyone observing your screen or reviewing your shell command history can recover credentials.

---
EOF

chmod +x generate.sh
