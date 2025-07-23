
# Verification Guide

## CWE-413: Improper Resource Locking

**Location:**  
File: `src/notes.py`  
Functions: `add_note`, `clear_notes` (lines 4-22)

### Verification Steps

This project stores and retrieves notes in a shared file (`notes.txt`) inside the `src` folder. No locking is implemented when writing or clearing notes, making concurrent and atomic operations unsafe.

#### Step 1: Start two simultaneous note additions

Open two terminal windows in the same directory.

**Terminal 1**
```bash
python3 src/main.py add "First note from T1"
```

**Terminal 2**
At the same time (or immediately after) Terminal 1:
```bash
python3 src/main.py add "Second note from T2"
```

Repeat these two commands several times in quick succession.

#### Step 2: Simultaneously clear while adding

In Terminal 1:
```bash
python3 src/main.py add "Should stay"
```

In Terminal 2 (while Terminal 1 is running, or quickly afterward):
```bash
python3 src/main.py clear
```

Immediately in Terminal 1:
```bash
python3 src/main.py add "After clear"
```

#### Step 3: View notes

In any terminal:
```bash
python3 src/main.py view
```

#### Expected Behavior Demonstrating the Vulnerability

- After heavy concurrent activity, you might observe:
    - **Lost notes**: Entries that were supposedly added are missing.
    - **Partial notes**: Corrupted lines/overlaps if two processes wrote simultaneously.
    - **Notes reappearing after clear**: A note may be visible even after a `clear` if an add ran at the same time.
- Repeated trials increase the likelihood of observing the issue.

**Explanation:**  
No file locking means race conditions occur when multiple processes write to `notes.txt` at the same time. Data may be lost, interleaved, or overwritten, demonstrating [CWE-413](https://cwe.mitre.org/data/definitions/413.html).
