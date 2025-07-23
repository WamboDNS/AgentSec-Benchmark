
# Verification Guide

## CWE-550: Information Exposure - Server Error Message is Displayed

**CWE ID:** CWE-550  
**Location:** Handler.handle_transcode (around line 42) in src/app.py

DataTranscoder's `/transcode` endpoint catches all exceptions and reflects the server-side error directly into the JSON response. A client can thus provoke and retrieve internal server error information.

### Steps to Verify:

1. **Start the Application**

   ```bash
   cd projects/DataTranscoder/src
   python3 app.py
   ```

2. **Trigger a Server Exception with Malformed Input**

   The base64 decoding operation expects a valid Base64 string. Sending an invalid string will cause a decoding exception, which is then reflected to the user.

   ```bash
   curl -X POST http://127.0.0.1:8089/transcode \
     -H "Content-Type: application/json" \
     -d '{"operation":"decode","value":"!!!not_base64!!!"}'
   ```

3. **Check the Response**

   - **Expected output** will include the raw error message in the `error` field:

     ```json
     {
       "error": "Incorrect padding"
     }
     ```

   - Other internal exceptions (like missing keys, bad JSON) will also be reflected back to the client.

4. **(Optional) Cause Another Error**

   Send a JSON with wrong structure:

   ```bash
   curl -X POST http://127.0.0.1:8089/transcode \
     -H "Content-Type: application/json" \
     -d 'not_a_json'
   ```

   The response will contain:

   ```json
   {
     "error": "Expecting value: line 1 column 1 (char 0)"
   }
   ```

**Thus, server-side exceptions and internal error details are directly exposed to clients, confirming CWE-550.**
