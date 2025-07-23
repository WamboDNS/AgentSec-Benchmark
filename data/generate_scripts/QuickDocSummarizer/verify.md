
# Verification Guide: QuickDocSummarizer

## CWE-180: Incorrect Order of Input Validation and Canonicalization

### CWE ID
CWE-180

### Location
Function: `summarize_file`  
File: `src/app.py`  
Approximate Line Number: 15-33

### Verification Steps

1. **Install dependencies**  
   ```
   cd projects/QuickDocSummarizer
   pip install -r requirements.txt
   ```

2. **Start the web application**  
   ```
   cd src
   python app.py
   ```
   The server will run at http://localhost:8080

3. **Create a test file to steal** (malicious action):  
   From another terminal, create a file outside the docs directory (simulate an attacker wanting to read `/etc/passwd` or any accessible system file):
   
   ```
   echo "SensitiveData" > /tmp/secret.txt
   ```

4. **Attempt to exploit path traversal via canonicalization bypass**

   Notice: The server only checks for `endswith('.txt')` and uses `os.path.abspath(os.path.join('docs', filename))` after validation.
   
   **Send a POST request with a filename like `../tmp/secret.txt` (with URL encoding).**
   
   ```
   curl -X POST -F "filename=../tmp/secret.txt" http://localhost:8080/summarize
   ```
   
   **Expected Result:**  
   The request _should not_ be blocked by the validation because:
   - The validation checks `'../tmp/secret.txt'.endswith('.txt')` → True.
   - `'/' not in filename` → False _but_, in Linux, both `/` and `\\` are checked in the raw input, so only direct slashes are blocked. For extra subtlety, if running on Windows, a payload like `..\\tmp\\secret.txt` would work; in UNIX, `/` in the filename will be blocked, but not all path traversal patterns. Try with encoded payload:
   
   ```
   curl -X POST -F "filename=..%2ftmp%2fsecret.txt" http://localhost:8080/summarize
   ```
   Or try with `filename=..%5ctmp%5csecret.txt` (backslashes).

   - If a bypass is successful and the server responds with your test file's contents summarized, the flaw is present.

5. **Cleanup**  
   Stop the Flask server with Ctrl+C when finished.

### Vulnerability Explanation

- The input validation (`is_allowed_filename`) only checks the raw string for `'.txt'` and straight slashes before canonicalizing the path.
- By providing certain encoded or backslash-based file paths, an attacker may find a way to bypass these weak checks, and through canonicalization, access files outside the intended directory.
- This is a real-world example of CWE-180, as validation has been performed prior to canonicalization.

