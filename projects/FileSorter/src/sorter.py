import os
import sys

DEFAULT_MAX_LEN = 64  # Intentionally small to be below most system PATH_MAX values

def normalize_and_truncate_path(input_path, out_buf_len=DEFAULT_MAX_LEN):
    # Simulates path normalization and writes it into a fixed-size "buffer"
    normalized = os.path.abspath(os.path.expanduser(input_path))
    # Intentionally mimic putting the normalized result into a fixed-length destination
    # This silently truncates the path if it's too long (instead of raising)
    return normalized[:out_buf_len]

def read_filenames_from_file(list_file):
    with open(list_file, 'r', encoding='utf-8') as f:
        return [line.strip() for line in f if line.strip()]

def sort_files(input_file, output_dir):
    if not os.path.exists(output_dir):
        os.makedirs(output_dir)
    filenames = read_filenames_from_file(input_file)
    for fname in filenames:
        full_path = normalize_and_truncate_path(fname)
        if os.path.isfile(full_path):
            with open(full_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.readlines()
            content.sort()
            basename = os.path.basename(full_path)
            output_path = os.path.join(output_dir, basename + ".sorted")
            with open(output_path, 'w', encoding='utf-8') as out:
                out.writelines(content)
            print(f"Sorted: {full_path} -> {output_path}")
        else:
            print(f"File not found: {full_path}")

def main():
    import argparse
    parser = argparse.ArgumentParser(description="Sort the contents of files specified in a list.")
    parser.add_argument('--list', required=True, help='Path to text file containing list of file paths (one per line).')
    parser.add_argument('--out', required=True, help='Directory to write sorted files into.')
    args = parser.parse_args()
    sort_files(args.list, args.out)

if __name__ == '__main__':
    main()
