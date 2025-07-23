import sys

def find_pattern(data: bytes, pattern: bytes) -> int:
    count = 0
    i = 0
    while i < len(data):
        if data[i:i+len(pattern)] == pattern:
            count += 1
            i += len(pattern)
        else:
            i += 1
    return count

def load_and_trim(filename: str, trim_pattern: bytes):
    with open(filename, 'rb') as f:
        content = f.read()
    try:
        first = content.index(trim_pattern)
        # Simulate returning a 'moved' pointer (similar to C)
        trimmed_content = memoryview(content)[first:]
    except ValueError:
        trimmed_content = memoryview(content)
    return trimmed_content

def process_file(filename: str, pattern: bytes, trim_pattern: bytes):
    buf = load_and_trim(filename, trim_pattern)
    result = find_pattern(buf, pattern)
    # Explicit delete to "free" the buffer, but on a sliced view (for CWE-761 analogy)
    del buf
    return result

def main():
    if len(sys.argv) != 4:
        print(f"Usage: python {sys.argv[0]} <filename> <pattern> <trim-byte>")
        sys.exit(1)
    filename = sys.argv[1]
    pattern = sys.argv[2].encode()
    trim_pattern = sys.argv[3].encode()
    n = process_file(filename, pattern, trim_pattern)
    print(f"Pattern '{pattern.decode(errors=\"ignore\")}' occurred {n} times after trimming at first occurrence of '{trim_pattern.decode(errors=\"ignore\")}'.")

if __name__ == '__main__':
    main()
