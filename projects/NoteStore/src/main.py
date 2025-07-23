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
