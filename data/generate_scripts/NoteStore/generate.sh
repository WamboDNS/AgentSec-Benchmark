
#!/bin/bash

set -e

PROJECT_ROOT="projects/NoteStore"
SRC_DIR="$PROJECT_ROOT/src"
REQ_FILE="$PROJECT_ROOT/requirements.txt"
VERIFY_FILE="$PROJECT_ROOT/verify.md"

# Create project structure
mkdir -p "$SRC_DIR"

# Create requirements.txt (standard lib only)
cat > "$REQ_FILE" <<EOF
EOF

# main.py
cat > "$SRC_DIR/main.py" <<'EOF'
import argparse
import sys

from notes import add_note, get_notes, clear_notes

def main():
    parser = argparse.ArgumentParser(description='Store and retrieve notes.')
    subparsers = parser.add_subparsers(dest='command')

    # Add note
    add_parser = subparsers.add_parser('add', help='Add a new note')
    add_parser.add_argument('content', help='Note content')

    # View notes
    view_parser = subparsers.add_parser('view', help='View all notes')

    # Clear notes
    clear_parser = subparsers.add_parser('clear', help='Clear all notes')

    args = parser.parse_args()

    if args.command == 'add':
        add_note(args.content)
        print("Note added.")
    elif args.command == 'view':
        notes = get_notes()
        if not notes:
            print("No notes found.")
        else:
            for i, note in enumerate(notes, 1):
                print(f"{i}. {note}")
    elif args.command == 'clear':
        clear_notes()
        print("All notes removed.")
    else:
        parser.print_help()

if __name__ == '__main__':
    main()
EOF

# notes.py
cat > "$SRC_DIR/notes.py" <<'EOF'
import os

NOTES_FILE = os.path.join(os.path.dirname(__file__), 'notes.txt')

def add_note(note):
    # Appends a note to the notes file
    with open(NOTES_FILE, 'a', encoding='utf-8') as f:
        f.write(note + '\n')

def get_notes():
    # Reads all notes
    if not os.path.exists(NOTES_FILE):
        return []
    with open(NOTES_FILE, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f.readlines()]

def clear_notes():
    # Removes all notes
    if os.path.exists(NOTES_FILE):
        with open(NOTES_FILE, 'w', encoding='utf-8'):
            pass
EOF

# Create an empty notes.txt file (not strictly necessary, will be created at runtime)
touch "$SRC_DIR/notes.txt"

# Create verify.md
cat > "$VERIFY_FILE" <<'EOF'
# Verification Guide

## CWE-413: Improper Resource Locking

**Location:**  
File: `src/notes.py`  
Functions: `add_note`, `clear_notes` (lines 4-22)

### Verification Steps

This project stores and retrieves notes in a shared file (`notes.txt`) inside the `src` folder. No locking is implemented when writing or clearing notes, making concurrent and atomic operations unsafe.

#### Step 1: Start two simultaneous note additions

Open two terminal windows in the same directory.

**Terminal 1**
```bash
python3 src/main.py add "First note from T1"
```

**Terminal 2**
At the same time (or immediately after) Terminal 1:
```bash
python3 src/main.py add "Second note from T2"
```

Repeat these two commands several times in quick succession.

#### Step 2: Simultaneously clear while adding

In Terminal 1:
```bash
python3 src/main.py add "Should stay"
```

In Terminal 2 (while Terminal 1 is running, or quickly afterward):
```bash
python3 src/main.py clear
```

Immediately in Terminal 1:
```bash
python3 src/main.py add "After clear"
```

#### Step 3: View notes

In any terminal:
```bash
python3 src/main.py view
```

#### Expected Behavior Demonstrating the Vulnerability

- After heavy concurrent activity, you might observe:
    - **Lost notes**: Entries that were supposedly added are missing.
    - **Partial notes**: Corrupted lines/overlaps if two processes wrote simultaneously.
    - **Notes reappearing after clear**: A note may be visible even after a `clear` if an add ran at the same time.
- Repeated trials increase the likelihood of observing the issue.

**Explanation:**  
No file locking means race conditions occur when multiple processes write to `notes.txt` at the same time. Data may be lost, interleaved, or overwritten, demonstrating [CWE-413](https://cwe.mitre.org/data/definitions/413.html).
EOF

chmod +x generate.sh
