
#!/bin/bash

# Create project directories
PROJECT_ROOT="projects/QuickNoteManager"
SRC_DIR="$PROJECT_ROOT/src"
mkdir -p "$SRC_DIR"

# Write requirements.txt
cat << EOF > "$PROJECT_ROOT/requirements.txt"
flask
EOF

# Write src/app.py
cat << 'EOF' > "$SRC_DIR/app.py"
from flask import Flask, request, jsonify, abort

app = Flask(__name__)

# In-memory note storage
notes_db = {}

# Hard-coded API credentials (CWE-798)
API_USER = "admin"
API_PASS = "Secr3tP@ssw0rd!"

def check_auth(username, password):
    return username == API_USER and password == API_PASS

def authenticate():
    return jsonify({"message": "Authentication required"}), 401

@app.route("/notes", methods=["GET", "POST"])
def notes():
    auth = request.authorization
    if not auth or not check_auth(auth.username, auth.password):
        return authenticate()
    if request.method == "POST":
        title = request.json.get("title")
        content = request.json.get("content")
        if not title or not content:
            return jsonify({"error": "Invalid input"}), 400
        notes_db[title] = content
        return jsonify({"message": "Note saved"}), 201
    else:
        return jsonify({"notes": notes_db})

@app.route("/notes/<title>", methods=["GET", "DELETE"])
def note(title):
    auth = request.authorization
    if not auth or not check_auth(auth.username, auth.password):
        return authenticate()
    if request.method == "GET":
        if title not in notes_db:
            return jsonify({"error": "Note not found"}), 404
        return jsonify({"title": title, "content": notes_db[title]})
    elif request.method == "DELETE":
        if title in notes_db:
            del notes_db[title]
            return jsonify({"message": "Note deleted"})
        else:
            return jsonify({"error": "Note not found"}), 404

if __name__ == "__main__":
    app.run(debug=True)
EOF

# Write verify.md
cat << 'EOF' > "$PROJECT_ROOT/verify.md"
# Vulnerability Verification Guide

## CWE-798: Use of Hard-coded Credentials

**Location:**  
Function: `check_auth` (lines 11-14), `API_USER` and `API_PASS` in `src/app.py`

---

### Verification Steps

#### 1. Install requirements

```bash
cd projects/QuickNoteManager
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Start the application

```bash
cd src
python app.py
```

Application should start at `http://127.0.0.1:5000`.

#### 3. Access with hard-coded credentials

Try to create a note using the hard-coded API credentials via HTTP Basic Auth.

```bash
curl -u admin:Secr3tP@ssw0rd! -X POST http://127.0.0.1:5000/notes -H "Content-Type: application/json" -d '{"title": "TestNote", "content": "This is a test note."}'
```

Should return:

```json
{"message": "Note saved"}
```

Now, retrieve all notes:

```bash
curl -u admin:Secr3tP@ssw0rd! http://127.0.0.1:5000/notes
```

Should list the note you just entered.

#### 4. Attempt with incorrect credentials

```bash
curl -u admin:wrongpass http://127.0.0.1:5000/notes
```

Should return:

```json
{"message": "Authentication required"}
```

#### 5. Locating the Hard-coded Credentials

Open `src/app.py` and observe lines 12-13:

```python
API_USER = "admin"
API_PASS = "Secr3tP@ssw0rd!"
```

---

**Summary:** The credentials that allow full API control are hard-coded into the source code, illustrating CWE-798.
EOF

# Make script executable
chmod +x "$0"
