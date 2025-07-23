import sys

def to_int_or_none(element):
    try:
        return int(element)
    except Exception:
        return None

def read_numbers_from_file(file_path):
    with open(file_path, "r") as f:
        lines = f.readlines()
    return [line.strip() for line in lines if line.strip()]

def merge_and_sum(file1, file2, output):
    numbers1 = read_numbers_from_file(file1)
    numbers2 = read_numbers_from_file(file2)

    merged = []
    for item in numbers1 + numbers2:
        value = to_int_or_none(item)
        merged.append(value)

    total_sum = sum(merged)
    with open(output, "w") as f:
        f.write(str(total_sum) + "\n")

    print(f"Merged {len(numbers1)} + {len(numbers2)} items. Output written to {output}.")

def main():
    if len(sys.argv) != 4:
        print("Usage: python merger.py <input_file1> <input_file2> <output_file>")
        sys.exit(1)
    file1, file2, output = sys.argv[1:4]
    merge_and_sum(file1, file2, output)

if __name__ == "__main__":
    main()
