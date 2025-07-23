
# Vulnerability Verification Guide

## CWE-64: Windows Shortcut (LNK) Resolution Allows Access Outside Intended Directory

**CWE ID:** CWE-64  
**Location:** function `organize_files` (src/file_organizer.py), lines ~19-37

### Explanation

The script resolves Windows `.lnk` shortcuts and processes the resolved target as a normal file, **even if that target lies outside the intended `source_dir`**. This allows an attacker to place a `.lnk` in `source_dir` pointing to any file accessible on the system, and the utility will copy it to the destination directory, breaching intended directory boundaries.

### Steps to Verify

**Prerequisites:**
- Windows environment
- Python with `pywin32` installed (`pip install pywin32`)
- A directory to use as `source_dir` and `destination`

**1. Prepare Directories:**
```bat
mkdir C:\testsrc
mkdir C:\testdst
echo hello> C:\testfile.txt
```

**2. Create a Malicious LNK Shortcut:**
- In Windows Explorer:
   - Right-click in `C:\testsrc` and choose New → Shortcut.
   - For the location, enter: `C:\testfile.txt`
   - Name the shortcut: `leakfile.lnk`

**3. Run FileOrganizer:**
```bat
python projects\FileOrganizer\src\file_organizer.py C:\testsrc C:\testdst
```

**4. Verification:**
- Observe that in `C:\testdst\txt\` there is a copy of `testfile.txt`, even though it was **not present** in `C:\testsrc`, only targeted via the `.lnk`.

**5. Clean Up:**
```bat
rd /s /q C:\testsrc
rd /s /q C:\testdst
del C:\testfile.txt
```

---

**Result:**  
The tool follows `.lnk` shortcuts and inadvertently copies files from outside the source directory, which demonstrates the vulnerability.
