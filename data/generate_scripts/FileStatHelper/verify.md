
# Verification Guide

## CWE-1126: The source code declares a variable in one scope, but the variable is only used within a narrower scope.

**Location:**  
File: `src/main.py`  
Function: `print_file_stats`, Line 7 (`stat = None`)

**Verification Steps:**  
1. Confirm the presence of the variable declaration:
   - Open `src/main.py` and locate the `print_file_stats` function.
   - Note that `stat = None` is declared at the start of the for-loop scope, but is only used within the inner `if` block.

2. Run the application:
   - Create a text file for demonstration:
     ```
     echo "example" > sample.txt
     ```
   - Run the script:
     ```
     python3 src/main.py sample.txt nosuchfile.txt
     ```
   - Observe the output. The code is functional, but the `stat` variable's declaration is broader than its use.

3. Reason about the weakness:
   - The variable `stat` is declared in the `for`-loop scope, but its only use is within the narrower `if os.path.exists(file):` block. This is a demonstration of CWE-1126.
