
# Verification Guide

This guide describes how CWE-316 (Cleartext Storage of Sensitive Information in Memory) is present in this project.

---

## CWE-316: Cleartext Storage of Sensitive Information in Memory

**File:** `src/app.py`  
**Function:** `extract_doc_info`, assignment to `doc_db` in `/upload` route  
**Approximate Line:** 10-22, 27-38

### Vulnerability Location

The API stores potentially sensitive document information (e.g., extracted "owner_password" from uploaded file) as cleartext in the global `doc_db` dictionary in memory.

### Steps to Verify

1. **Start the application:**

   ```bash
   cd projects/DocumentTagger/src
   pip install -r ../requirements.txt
   python app.py
   ```

2. **Upload a document with a known string in the first 32 bytes.**

   Create a test file:

   ```bash
   printf "SECRET-PASS-12345\nrest of the doc content here..." > testdoc.txt
   ```

   Upload it:

   ```bash
   curl -F "file=@testdoc.txt" http://127.0.0.1:5004/upload
   ```

   - You will receive a JSON response such as `{"doc_id": "<docid>"}`.

3. **Retrieve the info for the uploaded document:**

   Replace `<docid>` with the value returned above:

   ```bash
   curl http://127.0.0.1:5004/doc/<docid>
   ```

   - The JSON output includes the key `"owner_password"` with value `SECRET-PASS-12345` (the first bytes of your uploaded file, demonstrated as "sensitive" data), shown as cleartext.

4. **Confirm the presence of cleartext sensitive data in memory:**

   - Open another terminal and, while the Flask app is still running, use Python REPL to inspect:

     ```bash
     cd projects/DocumentTagger/src
     python
     >>> from app import doc_db
     >>> list(doc_db.values())
     ```

   - You will see the sensitive information in cleartext for all uploaded documents.

---

**This demonstrates that sensitive data (`owner_password`) from uploaded files is stored in memory in cleartext, mapping to CWE-316.**
