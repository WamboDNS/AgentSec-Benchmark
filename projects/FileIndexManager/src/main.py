import sys
import os

INDEX_FILENAME = "file_index.txt"

def scan_dir(directory):
    index = []
    for root, dirs, files in os.walk(directory):
        for f in files:
            path = os.path.join(root, f)
            try:
                size = os.stat(path).st_size
            except Exception:
                size = -1
            index.append((path, size))
    return index

def write_index(index, out_file):
    with open(out_file, 'w') as f:
        for path, size in index:
            f.write(f"{path},{size}\n")

def load_index(in_file):
    index = []
    try:
        with open(in_file, 'r') as f:
            for line in f:
                path, size = line.rstrip('\n').split(',', 1)
                index.append((path, int(size)))
    except Exception:
        pass
    return index

def search_index(index, query):
    found = []
    for path, size in index:
        # Should use 'in' but accidentally uses 'is' operator (CWE-480)
        if query is path:
            found.append((path, size))
    return found

def print_usage():
    print("Usage:")
    print("  python main.py scan <directory>")
    print("  python main.py search <query>")

def main():
    if len(sys.argv) < 2:
        print_usage()
        sys.exit(1)
    cmd = sys.argv[1]
    if cmd == 'scan':
        if len(sys.argv) != 3:
            print_usage()
            sys.exit(1)
        dir_to_scan = sys.argv[2]
        index = scan_dir(dir_to_scan)
        write_index(index, INDEX_FILENAME)
        print(f"Indexed {len(index)} files in '{dir_to_scan}' into {INDEX_FILENAME}")
    elif cmd == 'search':
        if len(sys.argv) != 3:
            print_usage()
            sys.exit(1)
        query = sys.argv[2]
        index = load_index(INDEX_FILENAME)
        results = search_index(index, query)
        if results:
            print("Results:")
            for path, size in results:
                print(f"{path} ({size} bytes)")
        else:
            print("No matches found.")
    else:
        print_usage()
        sys.exit(1)

if __name__ == "__main__":
    main()
