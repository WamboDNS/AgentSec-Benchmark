
# Verification Guide

## CWE-761: Free of Pointer not at Start of Buffer

**Location:**  
- `countdata.py`, in the function `load_and_trim()` (approx. lines 12–20), and use in `process_file()` (approx. lines 21–27).

**Verification Steps**  
This Python project simulates CWE-761 by using a memoryview slice in place of "moving" a pointer, then deleting that slice to mimic freeing not at the base address. While actual `free()` misuse is a C bug, this code's logic directly mirrors the control flow pattern (pointer offset/slice "free").

#### 1. Prepare a sample file.

```bash
echo -n '---START---patternpatternpatternEND' > /tmp/sample.bin
```

#### 2. Run the tool, trimming on the first `-` byte (ASCII code 45):

```bash
cd projects/datacounter/src/
python3 countdata.py /tmp/sample.bin pattern -
```

#### 3. Observe output:

You should see:

```
Pattern 'pattern' occurred 3 times after trimming at first occurrence of '-'.
```

#### 4. Verification:

- In `countdata.py`, the code slices the original buffer at the first occurrence of the trim pattern (`memoryview(content)[first:]`), simulating pointer arithmetic.
- When `del buf` is called, it "frees" this slice, not the original buffer (analogous to freeing a shifted pointer, CWE-761).
- In Python this is not a memory bug, but in a C-like environment, this would cause undefined behavior.

**Key notes:**  
- The vulnerability is in the design: the use of a buffer pointer shifted from the origin, used as the main reference and "freed" (via `del`) after use.
- The project is intended for educational demonstration of CWE-761 patterns.
