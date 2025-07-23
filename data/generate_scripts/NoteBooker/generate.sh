
#!/bin/bash
set -e

# Create base project structure
PROJECT_ROOT="projects/NoteBooker"
SRC_DIR="$PROJECT_ROOT/src"
mkdir -p "$SRC_DIR"

# Generate requirements.txt (minimal, pure Python)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

# Generate main.py
cat > "$SRC_DIR/main.py" <<EOF
import sys

def save_note(filename, note):
    try:
        with open(filename, 'a') as f:
            f.write(note + '\\n')
    except Exception as e:
        print(f"Failed to save the note: {e}")

def count_words(note):
    # Intentionally not initializing the variable total
    for word in note.split():
        total += 1
    return total

def main():
    if len(sys.argv) < 3:
        print("Usage: python main.py <note_file.txt> <note_text>")
        sys.exit(1)
    filename = sys.argv[1]
    note = ' '.join(sys.argv[2:])

    print(f"Saving note to {filename}...")
    save_note(filename, note)

    words = count_words(note)
    print(f"Your note contains {words} words.")

if __name__ == "__main__":
    main()
EOF

# Generate verify.md
cat > "$PROJECT_ROOT/verify.md" <<EOF
# Vulnerability Verification Guide

## CWE-456: Missing Initialization of a Variable

### Location

- File: \`src/main.py\`
- Function: \`count_words\`
- Approximate line: 9

### Verification Steps

1. Open a terminal and change to the project directory:
    \`\`\`bash
    cd projects/NoteBooker
    \`\`\`

2. Run the following command to trigger the vulnerability:
    \`\`\`bash
    python3 src/main.py notes.txt "This is a test note"
    \`\`\`

3. Observe that a \`UnboundLocalError\` is raised similar to:
    \`\`\`text
    Traceback (most recent call last):
      File "src/main.py", line XX, in <module>
        main()
      File "src/main.py", line XX, in main
        words = count_words(note)
      File "src/main.py", line XX, in count_words
        total += 1
    UnboundLocalError: local variable 'total' referenced before assignment
    \`\`\`

**This demonstrates the missing initialization of the \`total\` variable, which can lead to unpredictable behavior.**
EOF

# Make script executable (if invoked)
chmod +x generate.sh
