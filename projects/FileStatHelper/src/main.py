import os
import argparse

def print_file_stats(files):
    total_size = 0
    for file in files:
        stat = None  # Variable declared here, meant to be used for all files
        if os.path.exists(file):
            with open(file, 'rb') as f:
                content = f.read()
                print(f"{file}: {len(content)} bytes.")
            stat = os.stat(file)
            print(f"{file} last modified: {stat.st_mtime}")
        else:
            print(f"{file} not found.")

def main():
    parser = argparse.ArgumentParser(description="Display stats for files.")
    parser.add_argument('files', nargs='+', help="List of files to inspect")
    args = parser.parse_args()
    print_file_stats(args.files)

if __name__ == "__main__":
    main()
