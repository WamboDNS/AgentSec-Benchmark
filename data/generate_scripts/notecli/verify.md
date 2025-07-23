
# Vulnerability Verification Guide

## 1. CWE-549: Missing Password Masking (Passwords Displayed in Plaintext Input)

**CWE ID:** CWE-549  
**Description:** Passwords provided to the CLI are visible during input because the argument parser uses standard command line flags which are echoed on screen, instead of masking the password input.

**Location:**  
- File: `src/main.py`  
- Functions: CLI argument definitions / lines ~14-27 for both the "add" and "list" commands where `--password` is a normal argument.

### Verification Steps

#### 1. Run the CLI app and observe password entry

1. In your terminal, navigate to the project directory:

   ```
   cd projects/notecli/src
   ```

2. Run the CLI to add a note:

   ```
   python3 main.py add --username alice --password MySecret123 --title "Groceries" --content "Eggs, Milk"
   ```

   - Notice that the password "MySecret123" is fully visible in your shell history and on-screen input.

3. Alternatively, run the "list" command (again, password is exposed on command line):

   ```
   python3 main.py list --username alice --password MySecret123
   ```

4. You can also view your shell history (e.g., `history | grep main.py`) and see the plaintext password:

   ```
   history | grep main.py
   ```

**Result:**  
The password is not masked or securely handled during entry. Anyone observing your screen or reviewing your shell command history can recover credentials.

---
