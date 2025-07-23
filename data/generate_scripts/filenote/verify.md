
# Verification Guide

## CWE-153: Improper Neutralization of Substitution Characters in Downstream Components

**CWE ID:** CWE-153  
**Location:** `save_note` function, approx line 41 in `src/app.py`

### Vulnerability Description
The application accepts a user-supplied filename via the form and writes/reads files using that name, without neutralizing special characters (such as "../", "/", "\", or absolute path markers). This enables directory traversal or other injection of special file-handling elements.

### Verification Steps

#### Step 1: Install and run the app

```bash
cd projects/filenote
pip install -r requirements.txt
cd src
python app.py
```

#### Step 2: Create a traversal note

In your browser, open [http://localhost:5000](http://localhost:5000)

Submit the form:
- **Note name:** `../testleak`
- **Contents:** `my secret`

#### Step 3: Confirm the traversal

- Check that a file named `testleak` was created one directory above `src/notes/`.
  - Run: `ls ../testleak` (from `src/notes` directory, or `cat ../testleak`).
- In browser, try to load directly:  
  http://localhost:5000/note/../testleak  
  You should see the note content displayed.

#### Step 4: Arbitrary file write/read

- Try with filenames like `/tmp/attacker`, `../../app.py` to demonstrate writes outside the intended directory or reading arbitrary files.
- For example, you can overwrite any file the process can write.

#### Step 5: Optional - Create a file with special OS (e.g., Windows) path characters to test for handling of backslashes (`..\testleak`) or drive letters on Windows.

---
**Result**: The application does not neutralize special elements in the `filename`, allowing attackers to exploit file system context and access files outside intended directory.

