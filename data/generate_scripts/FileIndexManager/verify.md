
# Verification Guide for FileIndexManager

## CWE-480: Use of Incorrect Operator

**Location:**  
Function: `search_index`  
File: `src/main.py`  
Lines: Approx. 28-33

### How to verify:

**1. Setup**

```bash
cd projects/FileIndexManager
mkdir testdir
echo hello > testdir/abc.txt
echo world > testdir/def.txt
python3 src/main.py scan testdir
```

**2. Search for file by name:**

Since the code uses `is` instead of `in` or `==` (line 31):

```bash
python3 src/main.py search abc.txt
```

**Expected Result:**

Even though a file "abc.txt" is present, **"No matches found."** is printed.
A correct implementation with `if query in path:` or `==` would have found the file.

**3. What happens:** 

- The comparison `if query is path:` checks for *object identity*, not string content equality or substring inclusion.
- Unless by coincidence `query` and `path` are exactly the same object (not just equal strings), the match will always fail.

**4. Fix:**  
Change `if query is path:` to `if query in path:` or `if query == path:` for expected search behavior.
