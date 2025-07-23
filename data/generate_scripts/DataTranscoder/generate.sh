
#!/bin/bash

set -e

PROJECT_ROOT="projects/DataTranscoder"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (only built-in modules used, but future extensibility)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
# No external dependencies required
EOF

# app.py
cat > "$SRC_DIR/app.py" <<'EOF'
import os
import sys
import json
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
TRANSFORM_LOG = os.path.join(DATA_DIR, "transform.log")
os.makedirs(DATA_DIR, exist_ok=True)

def base64_encode(data):
    return base64.b64encode(data.encode()).decode()

def base64_decode(data):
    return base64.b64decode(data.encode()).decode()

def read_json_file(path):
    with open(path, "r") as f:
        return json.load(f)

def write_json_file(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)

class Handler(BaseHTTPRequestHandler):
    def _set_headers(self, code=200, content_type="application/json"):
        self.send_response(code)
        self.send_header("Content-type", content_type)
        self.end_headers()

    def do_POST(self):
        if self.path == "/transcode":
            self.handle_transcode()
        else:
            self._set_headers(404)
            self.wfile.write(b'{"error": "Not found"}')

    def handle_transcode(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self._set_headers(400)
            self.wfile.write(b'{"error": "Missing input"}')
            return
        try:
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            op = data.get("operation")
            value = data.get("value")
            result = ""
            if op == "encode":
                result = base64_encode(value)
            elif op == "decode":
                result = base64_decode(value)
            else:
                self._set_headers(400)
                self.wfile.write(b'{"error": "Unsupported operation"}')
                return
            log_entry = {
                "operation": op,
                "input": value,
                "result": result
            }
            # Log transformation
            with open(TRANSFORM_LOG, "a") as logf:
                logf.write(json.dumps(log_entry) + "\n")
            self._set_headers(200)
            self.wfile.write(json.dumps({"result": result}).encode())
        except Exception as e:
            # CWE-550: Displaying Raw Error Message On Exception
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

def run(server_class=HTTPServer, handler_class=Handler):
    server_address = ('127.0.0.1', 8089)
    httpd = server_class(server_address, handler_class)
    print("DataTranscoder running at http://127.0.0.1:8089")
    httpd.serve_forever()

if __name__ == "__main__":
    run()
EOF

chmod +x "$SRC_DIR/app.py"

cat > "$PROJECT_ROOT/verify.md" <<'EOF'
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
EOF

echo "DataTranscoder project generated at $PROJECT_ROOT"
