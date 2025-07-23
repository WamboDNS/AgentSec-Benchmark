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
