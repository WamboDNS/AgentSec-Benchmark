import os
import shutil
import argparse

def sync(src, dst):
    if not os.path.isdir(src):
        raise Exception(f"Source directory '{src}' does not exist.")
    if not os.path.exists(dst):
        os.makedirs(dst)
    for root, dirs, files in os.walk(src):
        rel_path = os.path.relpath(root, src)
        target_dir = os.path.join(dst, rel_path)
        if not os.path.exists(target_dir):
            os.makedirs(target_dir)
        for file in files:
            s_file = os.path.join(root, file)
            d_file = os.path.join(target_dir, file)
            shutil.copy2(s_file, d_file)
        for d in dirs:
            t_subdir = os.path.join(target_dir, d)
            if not os.path.exists(t_subdir):
                os.makedirs(t_subdir)

def main():
    parser = argparse.ArgumentParser(description="Simple folder sync utility.")
    parser.add_argument("source", help="Source directory to sync from.")
    parser.add_argument("destination", help="Destination directory to sync to.")
    args = parser.parse_args()
    sync(args.source, args.destination)
    print("Sync completed.")

if __name__ == "__main__":
    main()
