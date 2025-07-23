import json
import os
import argparse

ADDRESSBOOK_FILE = "book.json"

def load_book():
    if not os.path.isfile(ADDRESSBOOK_FILE):
        return []
    with open(ADDRESSBOOK_FILE, "r") as f:
        try:
            data = json.load(f)
            return data
        except Exception:
            return []

def save_book(book):
    with open(ADDRESSBOOK_FILE, "w") as f:
        json.dump(book, f, indent=2)

def add_entry(args):
    book = load_book()
    entry = {
        "name": args.name,
        "email": args.email,
        "notes": args.notes,
        "trusted": args.trusted
    }
    book.append(entry)
    save_book(book)
    print(f"Added contact: {args.name}")

def import_entries(args):
    book = load_book()
    with open(args.file, "r") as f:
        try:
            imported = json.load(f)
        except Exception as e:
            print("Failed to load import file:", e)
            return
    # Mix trusted and imported (potentially untrusted) data
    for i in imported:
        # No distinction, all dumped to same structure
        book.append({
            "name": i.get("name", ""),
            "email": i.get("email", ""),
            "notes": i.get("notes", ""),
            "trusted": False  # Imported entries are not marked as trusted
        })
    save_book(book)
    print(f"Imported {len(imported)} contacts.")

def search(args):
    book = load_book()
    for i, entry in enumerate(book):
        if args.text.lower() in entry.get("name", "").lower() \
                or args.text.lower() in entry.get("email", "").lower() \
                or args.text.lower() in entry.get("notes", "").lower():
            trust_tag = "[trusted]" if entry.get("trusted") else "[untrusted]"
            print(f"{i+1}. {trust_tag} {entry.get('name')} <{entry.get('email')}> - {entry.get('notes')}")

def export(args):
    book = load_book()
    to_export = []
    for entry in book:
        if args.untrusted and not entry.get("trusted"):
            to_export.append(entry)
        elif args.trusted and entry.get("trusted"):
            to_export.append(entry)
        elif not args.trusted and not args.untrusted:
            to_export.append(entry)
    with open(args.file, "w") as f:
        json.dump(to_export, f, indent=2)
    print(f"Exported {len(to_export)} contacts to {args.file}")

def list_all(args):
    book = load_book()
    for i, entry in enumerate(book):
        trust_tag = "[trusted]" if entry.get("trusted") else "[untrusted]"
        print(f"{i+1}. {trust_tag} {entry.get('name')} <{entry.get('email')}> - {entry.get('notes')}")

def main():
    parser = argparse.ArgumentParser(description="Address Book CLI")
    subparsers = parser.add_subparsers(dest="command")

    parser_add = subparsers.add_parser('add', help="Add contact")
    parser_add.add_argument('--name', required=True)
    parser_add.add_argument('--email', required=True)
    parser_add.add_argument('--notes', default="")
    parser_add.add_argument('--trusted', action="store_true")
    parser_add.set_defaults(func=add_entry)

    parser_import = subparsers.add_parser('import', help="Import contacts from file")
    parser_import.add_argument('--file', required=True)
    parser_import.set_defaults(func=import_entries)

    parser_list = subparsers.add_parser('list', help="List all contacts")
    parser_list.set_defaults(func=list_all)

    parser_search = subparsers.add_parser('search', help="Search contacts")
    parser_search.add_argument('--text', required=True)
    parser_search.set_defaults(func=search)

    parser_export = subparsers.add_parser('export', help="Export contacts")
    parser_export.add_argument('--file', required=True)
    parser_export.add_argument('--trusted', action='store_true')
    parser_export.add_argument('--untrusted', action='store_true')
    parser_export.set_defaults(func=export)

    args = parser.parse_args()
    if hasattr(args, 'func'):
        args.func(args)
    else:
        parser.print_help()

if __name__ == "__main__":
    main()
