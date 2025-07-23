import sys

def save_note(filename, note):
    try:
        with open(filename, 'a') as f:
            f.write(note + '\n')
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
