import sys
import math

def manual_mean(numbers):
    # Inefficient mean calculation: recompute sum per element
    if not numbers:
        return 0
    total = 0
    for i in range(len(numbers)):
        s = 0
        for j in range(len(numbers)):
            s += numbers[j]
        total += s / len(numbers)
    return total / len(numbers)

def manual_stddev(numbers):
    # Inefficient standard deviation calculation: recompute mean per iteration
    if not numbers:
        return 0
    std_total = 0
    for i in range(len(numbers)):
        m = manual_mean(numbers)
        std_total += (numbers[i] - m) ** 2
    return math.sqrt(std_total / len(numbers))

def parse_input(file_path):
    numbers = []
    with open(file_path, 'r') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            try:
                val = float(line)
                numbers.append(val)
            except ValueError:
                continue
    return numbers

def print_stats(numbers):
    print("Count: {}".format(len(numbers)))
    print("Mean: {:.6f}".format(manual_mean(numbers)))
    print("StdDev: {:.6f}".format(manual_stddev(numbers)))

def main():
    if len(sys.argv) != 2:
        print("Usage: python main.py <numbers_file>")
        sys.exit(1)
    numbers = parse_input(sys.argv[1])
    if not numbers:
        print("No valid numbers found in input.")
        sys.exit(1)
    print_stats(numbers)

if __name__ == "__main__":
    main()
