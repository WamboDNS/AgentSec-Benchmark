
#!/bin/bash
set -e

PROJECT_ROOT="projects/DataStatsCLI"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (no extra deps)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
# No external requirements
EOF

# src/main.py
cat > "$SRC_DIR/main.py" <<'EOF'
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
EOF

# src/__init__.py
touch "$SRC_DIR/__init__.py"

# Verification instructions
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## CWE-1176: Inefficient Algorithmic Implementation

- **CWE ID:** CWE-1176
- **Location:** `manual_mean` (line 5) and `manual_stddev` (line 15) in `src/main.py`

### Verification Steps

1. **Prepare Input File:**

   Create a file with a large number of numeric entries. For example:
   ```bash
   seq 1 10000 > numbers.txt
   ```

2. **Run the Application:**
   ```bash
   cd projects/DataStatsCLI/src
   python3 main.py ../../numbers.txt
   ```

3. **Observation:**

   The program will take a noticeable amount of time (several seconds) to process large input files, much slower than a typical mean/stddev calculator.  
   This is due to inefficient O(N^2) algorithms for both mean and standard deviation calculation, as the code redundantly re-computes sums and means in nested loops.

4. **Optional Profiling:**
   
   You can measure the time using the following command:
   ```bash
   time python3 main.py ../../numbers.txt
   ```

   Notice the high CPU usage and long elapsed time, confirming the presence of the inefficient computation.

EOF

chmod +x generate.sh
