
# Verification Guide

## CWE-785: Use of Path Manipulation Function without Maximum-Size Buffer

**CWE ID:** CWE-785  
**File:** `src/sorter.py`  
**Function:** `normalize_and_truncate_path` (approx. line 6–14)

### How to Verify

This vulnerability is triggered by providing a file path whose normalized form exceeds the fixed output buffer length (64 chars). The normalization truncates the result, which can lead to incorrect file access or unintended behavior.

#### Steps to Reproduce

1. **Create the Project Directory:**

    ```bash
    cd projects/FileSorter
    ```

2. **Create Deep Directory Structure (mimic path longer than 64 chars):**

    ```bash
    mkdir -p "$(pwd)/very/"$(printf 'longdir%.0s' {1..8})
    cd very
    CURDIR=$(pwd)
    # Create a target file deep down
    LONG_PATH="$CURDIR/longdir1/longdir2/longdir3/longdir4/longdir5/longdir6/longdir7/longdir8/targetfile.txt"
    mkdir -p "$(dirname "$LONG_PATH")"
    echo -e "zeta\nalpha\nbeta" > "$LONG_PATH"
    cd ../..
    ```

3. **Create List File With Full Path:**

    ```bash
    echo "$LONG_PATH" > filelist.txt
    ```

4. **Run the Application:**

    ```bash
    python3 src/sorter.py --list filelist.txt --out outputs
    ```

5. **Observe Behavior:**

    - The application will truncate the result of normalization, so it will not access the real targetfile.txt but instead use only the first 64 characters of the normalized path.
    - You will see a message such as:
      ```
      File not found: /your/path/very/longdir1/longdir2/longdir3/longdir4/longdir
      ```
      (truncated at 64 characters).
    - No sorted output will be created for the intended file.

6. **Explanation:**

    The normalization/truncation happens at:
    ```
    full_path = normalize_and_truncate_path(fname)
    ```
    In `src/sorter.py` (~line 22), the function slices the normalized path to only 64 characters due to the small output buffer emulation.

## CWE Reference

- [CWE-785: Use of Path Manipulation Function without Maximum-Size Buffer](https://cwe.mitre.org/data/definitions/785.html)
