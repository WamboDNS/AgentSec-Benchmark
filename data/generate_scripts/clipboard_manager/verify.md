
# Verification Guide

This project implements a simple clipboard manager with copy and paste capabilities.

---

## CWE-120: Buffer Copy without Size Check (Classic Buffer Overflow)

**Location:**  
- File: `src/clipboard.py`  
- Function: `Clipboard.copy`  
- Approximate line: 11-18

### Verification Steps

1. Open a terminal and change into the project directory:
   ```
   cd projects/clipboard_manager
   ```

2. Run the `copy` command with a large input (200+ characters, exceeding 128 bytes). For example:
   ```
   python3 src/clipboard.py copy "$(python3 -c 'print("A"*200)')"
   ```
3. Observe the error message (should be an IndexError/exception indicating a buffer overflow).

4. Alternatively, try a normal-sized copy (within 128 characters) to see normal behavior:
   ```
   python3 src/clipboard.py copy "Hello, clipboard!"
   python3 src/clipboard.py paste
   ```

**Notes:**  
Because the `copy` function copies every byte from the input into a fixed-size `self.data` buffer without checking bounds, supplying an overly-long input will lead to a runtime exception and possible memory corruption in a C/C++ equivalent.

---
