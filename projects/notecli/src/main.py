import argparse
from getpass import getpass

def save_note(username, password, title, content):
    # Trivial file storage demo (not secure, just for example)
    filename = f"${username}_notes.txt"
    with open(filename, "a") as f:
        f.write(f"Title: ${title}\n")
        f.write(f"Content: ${content}\n")
        f.write("-" * 40 + "\n")

def list_notes(username):
    filename = f"${username}_notes.txt"
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
