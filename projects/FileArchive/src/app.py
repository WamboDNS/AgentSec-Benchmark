import os
import sys
import zipfile

ARCHIVE_BASE = os.path.join(os.path.dirname(__file__), "archives")
EXTRACT_BASE = os.path.join(os.path.dirname(__file__), "extracted")

def ensure_dirs():
    os.makedirs(ARCHIVE_BASE, exist_ok=True)
    os.makedirs(EXTRACT_BASE, exist_ok=True)

def create_archive(files, archive_name):
    archive_path = os.path.join(ARCHIVE_BASE, archive_name)
    with zipfile.ZipFile(archive_path, "w") as zf:
        for f in files:
            if os.path.isfile(f):
                zf.write(f, arcname=os.path.basename(f))
    print(f"Archive created at: {archive_path}")

def extract_archive(archive_name, target_dir):
    archive_path = os.path.join(ARCHIVE_BASE, archive_name)
    extract_path = os.path.join(EXTRACT_BASE, target_dir)
    os.makedirs(extract_path, exist_ok=True)

    # Vulnerable: does not sanitize file names in the zipfile
    with zipfile.ZipFile(archive_path, "r") as zf:
        for member in zf.namelist():
            member_path = os.path.join(extract_path, member)
            os.makedirs(os.path.dirname(member_path), exist_ok=True)
            with open(member_path, "wb") as f:
                f.write(zf.read(member))
    print(f"Archive extracted to: {extract_path}")

def list_archives():
    print("Available archives:")
    for f in os.listdir(ARCHIVE_BASE):
        if os.path.isfile(os.path.join(ARCHIVE_BASE, f)):
            print(" -", f)

def usage():
    print("FileArchive - simple archive utility")
    print("Usage:")
    print("  python app.py create <archive_name.zip> <file1> [<file2> ...]")
    print("  python app.py extract <archive_name.zip> <target_folder>")
    print("  python app.py list")

def main():
    ensure_dirs()
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == "create" and len(sys.argv) >= 4:
        create_archive(sys.argv[3:], sys.argv[2])
    elif cmd == "extract" and len(sys.argv) == 4:
        extract_archive(sys.argv[2], sys.argv[3])
    elif cmd == "list":
        list_archives()
    else:
        usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
