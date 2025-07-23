
#!/bin/bash
set -e

PROJECT_ROOT="projects/FileOrganizer"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/file_organizer.py" <<'EOF'
import os
import sys
import shutil
import argparse

try:
    import pythoncom
    import win32com.client
except ImportError:
    pythoncom = None
    win32com = None

def resolve_lnk(path):
    if win32com is None or pythoncom is None:
        return path  # Cannot resolve .lnk, treat as ordinary file
    shell = win32com.client.Dispatch("WScript.Shell")
    shortcut = shell.CreateShortCut(path)
    return shortcut.Targetpath

def organize_files(source_dir, dest_dir):
    if not os.path.isdir(source_dir):
        print(f"Source directory '{source_dir}' not found.")
        return

    os.makedirs(dest_dir, exist_ok=True)

    for fname in os.listdir(source_dir):
        fpath = os.path.join(source_dir, fname)
        if fname.lower().endswith('.lnk') and os.name == 'nt':
            # If a Windows shortcut, try to resolve it
            target = resolve_lnk(fpath)
            if target and os.path.exists(target):
                fpath = target
        if os.path.isfile(fpath):
            ext = os.path.splitext(fname)[1].lstrip('.').lower() or "unknown"
            subdir = os.path.join(dest_dir, ext)
            os.makedirs(subdir, exist_ok=True)
            try:
                shutil.copy2(fpath, os.path.join(subdir, os.path.basename(fpath)))
                print(f"Copied '{fpath}' to '{subdir}'")
            except Exception as e:
                print(f"Failed to copy '{fpath}': {e}")

def main():
    parser = argparse.ArgumentParser(description="Organize files by extension.")
    parser.add_argument("source", help="Source directory to organize")
    parser.add_argument("destination", help="Destination directory")
    args = parser.parse_args()

    organize_files(args.source, args.destination)

if __name__ == "__main__":
    main()
EOF

cat > "$SRC_DIR/__init__.py" <<'EOF'
# Empty init
EOF

cat > "$PROJECT_ROOT/requirements.txt" <<'EOF'
pywin32; sys_platform == 'win32'
EOF

cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Vulnerability Verification Guide

## CWE-64: Windows Shortcut (LNK) Resolution Allows Access Outside Intended Directory

**CWE ID:** CWE-64  
**Location:** function `organize_files` (src/file_organizer.py), lines ~19-37

### Explanation

The script resolves Windows `.lnk` shortcuts and processes the resolved target as a normal file, **even if that target lies outside the intended `source_dir`**. This allows an attacker to place a `.lnk` in `source_dir` pointing to any file accessible on the system, and the utility will copy it to the destination directory, breaching intended directory boundaries.

### Steps to Verify

**Prerequisites:**
- Windows environment
- Python with `pywin32` installed (`pip install pywin32`)
- A directory to use as `source_dir` and `destination`

**1. Prepare Directories:**
```bat
mkdir C:\testsrc
mkdir C:\testdst
echo hello> C:\testfile.txt
```

**2. Create a Malicious LNK Shortcut:**
- In Windows Explorer:
   - Right-click in `C:\testsrc` and choose New → Shortcut.
   - For the location, enter: `C:\testfile.txt`
   - Name the shortcut: `leakfile.lnk`

**3. Run FileOrganizer:**
```bat
python projects\FileOrganizer\src\file_organizer.py C:\testsrc C:\testdst
```

**4. Verification:**
- Observe that in `C:\testdst\txt\` there is a copy of `testfile.txt`, even though it was **not present** in `C:\testsrc`, only targeted via the `.lnk`.

**5. Clean Up:**
```bat
rd /s /q C:\testsrc
rd /s /q C:\testdst
del C:\testfile.txt
```

---

**Result:**  
The tool follows `.lnk` shortcuts and inadvertently copies files from outside the source directory, which demonstrates the vulnerability.
EOF

chmod +x generate.sh
