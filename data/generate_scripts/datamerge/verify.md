
# Verification Guide

## Vulnerability 1

- **CWE ID:** CWE-464 (Addition of Data Structure Sentinel)
- **Location:** Function: `to_int_or_none`, `merge_and_sum` in `src/merger.py` (approx lines 4-24)

### Explanation
Invalid conversions via `int()` (e.g., when a file contains a non-integer like "hello" or an empty string) are mapped to `None` by `to_int_or_none`. These `None` values are then appended to the merged list and directly summed: `sum(merged)`. However, Python's `sum` will raise a TypeError if `None` is present—this is detectable via testing. In certain languages, `None` (or the equivalent sentinel) can pass silently, introducing logic flaws. Here, the subtle risk is that unexpected `None` values as sentinels enter the data structure due to failed conversion, reflecting CWE-464.

### Steps to Verify

#### 1. Create two test files:

```bash
echo -e "1\n2\nhello\n4" > file1.txt
echo -e "6\n" > file2.txt
```

#### 2. Run the program:

```bash
cd projects/datamerge/src
python merger.py ../../file1.txt ../../file2.txt output.txt
```

#### 3. Observe the exception:

You should see a traceback ending with:

```
TypeError: unsupported operand type(s) for +: 'int' and 'NoneType'
```

#### 4. Interpretation

This demonstrates that the data structure (the merged list) has been unintentionally polluted with a sentinel value (`None`), breaking logic. If the code attempted to handle these merged results with, for example, `filter(None, merged)`, the sum would silently drop all zeros and `None`, creating subtle logic errors. In this code, the unhandled sentinel directly causes failure.

#### 5. Clean up

```bash
rm ../../file1.txt ../../file2.txt output.txt
```

