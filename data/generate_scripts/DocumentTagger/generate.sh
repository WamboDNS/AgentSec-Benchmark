
#!/bin/bash
set -e

PROJECT_ROOT="projects/DocumentTagger"
SRC_DIR="$PROJECT_ROOT/src"

# Create project structure
mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" << EOF
flask
EOF

# src/app.py
cat > "$SRC_DIR/app.py" << EOF
from flask import Flask, request, jsonify
import base64

app = Flask(__name__)

# Simulate a simple in-memory document metadata tagging API

# In-memory storage for document tags and related sensitive data
doc_db = {}

def extract_doc_info(file_bytes):
    # Let's say we read fake "sensitive" document info, e.g. the first 32 bytes could be considered some token or password
    doc_info = {
        "title": "Untitled Document",
        "owner_password": file_bytes[:32].decode(errors='ignore').strip(),   # <-- this is sensitive (CWE-316)
        "metadata": base64.b64encode(file_bytes[:16]).decode()
    }
    return doc_info

@app.route('/upload', methods=['POST'])
def upload_doc():
    if 'file' not in request.files:
        return jsonify({'error': 'Missing file'}), 400
    file = request.files['file']
    doc_bytes = file.read()
    doc_id = base64.b16encode(doc_bytes[:8]).decode()
    doc_info = extract_doc_info(doc_bytes)
    doc_db[doc_id] = {
        "info": doc_info,   # <-- Sensitive info (e.g. owner_password) is stored as cleartext (CWE-316)
        "tags": []
    }
    return jsonify({'doc_id': doc_id})

@app.route('/tag', methods=['POST'])
def tag_doc():
    data = request.json
    doc_id = data.get('doc_id')
    tag = data.get('tag')
    if doc_id not in doc_db:
        return jsonify({"error": "Not found"}), 404
    doc_db[doc_id]["tags"].append(tag)
    return jsonify({"status": "tag added"})

@app.route('/doc/<doc_id>', methods=['GET'])
def get_doc(doc_id):
    if doc_id not in doc_db:
        return jsonify({"error": "Not found"}), 404
    # Return all info for demonstration purposes (also exposing sensitive info in memory)
    return jsonify(doc_db[doc_id]["info"])

if __name__ == '__main__':
    app.run(port=5004)
EOF
chmod +x "$SRC_DIR/app.py"
