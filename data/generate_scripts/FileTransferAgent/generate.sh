
#!/bin/bash

set -e

PROJDIR="projects/FileTransferAgent"
SRCDIR="$PROJDIR/src"

mkdir -p "$SRCDIR"

# Create requirements.txt
cat > "$PROJDIR/requirements.txt" <<EOF
flask
requests
EOF

# Create src/server.py
cat > "$SRCDIR/server.py" <<'EOF'
from flask import Flask, request, jsonify
from werkzeug.utils import secure_filename
import os

app = Flask(__name__)
UPLOAD_FOLDER = os.path.abspath(os.path.dirname(__file__))

@app.route('/upload', methods=['POST'])
def upload_file():
    if 'file' not in request.files:
        return jsonify({'success': False, 'error': 'No file part'}), 400
    file = request.files['file']
    if file.filename == '':
        return jsonify({'success': False, 'error': 'No selected file'}), 400
    filename = secure_filename(file.filename)
    save_path = os.path.join(UPLOAD_FOLDER, filename)
    file.save(save_path)
    return jsonify({'success': True, 'filename': filename})

@app.route('/list', methods=['GET'])
def list_files():
    files = [f for f in os.listdir(UPLOAD_FOLDER)
             if os.path.isfile(os.path.join(UPLOAD_FOLDER, f))]
    return jsonify({'files': files})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5001)
EOF

# Create src/client.py
cat > "$SRCDIR/client.py" <<'EOF'
import sys
import os
import requests

CONFIG_FILE = os.path.join(os.path.dirname(__file__), 'agent.conf')

def read_server_address():
    # Reads server_address from config file (plain text)
    if not os.path.exists(CONFIG_FILE):
        # Default to localhost
        return "http://127.0.0.1:5001"
    with open(CONFIG_FILE) as f:
        addr = f.read().strip()
        if addr:
            return addr
        return "http://127.0.0.1:5001"

def upload_file(file_path):
    addr = read_server_address()
    url = addr.rstrip("/") + "/upload"
    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f)}
        resp = requests.post(url, files=files)
        try:
            print(resp.json())
        except Exception:
            print("Error in response:", resp.text)

def list_files():
    addr = read_server_address()
    url = addr.rstrip("/") + "/list"
    resp = requests.get(url)
    try:
        print(resp.json())
    except Exception:
        print("Error in response:", resp.text)

def usage():
    print("Usage:")
    print("  python client.py upload <filepath>")
    print("  python client.py list")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)
    if sys.argv[1] == "upload" and len(sys.argv) == 3:
        upload_file(sys.argv[2])
    elif sys.argv[1] == "list":
        list_files()
    else:
        usage()
EOF

# Create src/agent.conf (default config)
cat > "$SRCDIR/agent.conf" <<EOF
http://127.0.0.1:5001
EOF

# Create verify.md
cat > "$PROJDIR/verify.md" <<'EOF'
# Verification Guide

## CWE-923: Improper Restriction of Communication Channel to Intended Endpoints

### Vulnerability Location

- **File:** `src/client.py`
- **Function:** `read_server_address`
- **Approximate Line Number:** 6-16

The client reads the server address for file upload operations from a plain text configuration file (`agent.conf`) without any validation or secure binding to an intended endpoint (i.e., no cryptographic authentication, no fixed endpoint, configurable by the user or attacker with no protections).

### Verification Steps

#### 1. Set up the legitimate server

In a terminal, start the provided server:

```bash
cd projects/FileTransferAgent/src
python3 server.py
```

#### 2. Confirm normal client operation

In another terminal, with the default config (which points to localhost):

```bash
cd projects/FileTransferAgent/src
echo "test file content" > test.txt
python3 client.py upload test.txt
python3 client.py list
```

Files should be uploaded to the local server.

#### 3. Simulate an attacker starting a malicious server

In a third terminal, start a *malicious* server (can simply copy `server.py` to another port):

```bash
cd projects/FileTransferAgent/src
# Modify this server to e.g., log or exfiltrate files before saving, or just copy as-is for demonstration
# Start on a different port
python3 server.py # Let this be on port 5002 after modification, or use the mode below.
```

Or, for a simple demonstration, use `nc` (netcat) to exfiltrate uploads:

```bash
nc -l 0.0.0.0 7000
```

#### 4. Change the client config to point to the attacker's "server"

Edit the `agent.conf` file in `src/` to:

```
http://127.0.0.1:7000
```

#### 5. Upload using the client

```bash
python3 client.py upload test.txt
```

If using `nc`, you will see file data appear in the `nc` terminal, showing the client blindly sent it anywhere configured. If using the second server process, you could inspect its uploads or modify its logic to simulate a real attack.

#### 6. Analysis

This demonstrates that the client process – which may be used in privileged scripts or for sensitive files – will upload to any endpoint specified, with no validation, trust anchor, or endpoint authentication. This is a classic CWE-923: Improper Restriction of Communication Channel to Intended Endpoints.

**In summary:** An attacker who is able to modify the `agent.conf` file or influence the environment can redirect sensitive file uploads to an arbitrary, attacker-controlled endpoint.

EOF

chmod +x generate.sh
