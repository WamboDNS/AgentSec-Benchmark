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
