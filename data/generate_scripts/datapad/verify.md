
# Vulnerability Verification Guide

## CWE-806: Buffer Access Using Size of Source Buffer

- **CWE ID:** CWE-806
- **Location:** `pad_file` function in `src/filepad.py`, approx. lines 7-27.

### Verification Steps

This issue arises because the `buffer` is allocated using the size of the source buffer (`len(data)`) but then written to using indices that may exceed this allocation due to the `padded_size` calculation. When input files are not a multiple of 512 bytes, this code attempts to write padding beyond the end of the buffer.

#### Steps:

1. Create a small file that is **not** a multiple of 512 bytes:
   ```bash
   echo -n "hello world" > test.txt
   ```

2. Run the padding tool:
   ```bash
   python3 src/filepad.py pad test.txt test.padded
   ```

3. **Observe the output:**  
   - The tool should print an `Error: bytearray index out of range` exception.
   - This indicates it attempted to write beyond the allocated buffer size due to using the source's size rather than the padded destination buffer size.

#### Expected result:

You should see output similar to:

```
Error: bytearray index out of range
```

This demonstrates the presence of the incorrect buffer sizing logic described in CWE-806.
