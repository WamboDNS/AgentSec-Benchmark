
# Verification Guide

## CWE-1007: Insufficient Visual Distinction of Homoglyphs
**Location:**  
Function: `display_name`  
File: `src/app.py`, ~line 51

### Steps to Verify

1. **Install dependencies:**
   ```
   pip install -r projects/fileroutes/requirements.txt
   ```

2. **Run the application:**
   ```
   cd projects/fileroutes/src
   python app.py
   ```

3. **Prepare two files with homoglyphs in names. For example:**
   - "File with latin 'a'":  
     Filename: `data.txt`

   - "File with Cyrillic 'а' (U+0430)":  
     Filename: `dаta.txt`  
     (Note: In the second name, the 'a' after 'd' is replaced by Cyrillic 'а', not ASCII 'a'.  
     You can generate the Cyrillic letter using:  
     Python: `print('d\u0430ta.txt')` )

4. **Upload both files via the web UI:**
    - Click "Browse", select `data.txt`, and upload.
    - Click "Browse", select `dаta.txt` (with Cyrillic 'а'), and upload.

5. **View the list of uploaded files:**  
    - Both files will be listed with nearly identical names.
    - Click "Show Name" for both files. Observe the files appear visually identical in the browser.

6. **Verification:**
    - Although the file names are visually similar or identical, they are two different files. This can mislead a user to perform actions (like download or delete) on the wrong file.

**Proof:**  
- The application displays file names as-is without normalization or highlighting, making it impossible for a user to distinguish between ASCII 'a' and Cyrillic 'а' in file names.

