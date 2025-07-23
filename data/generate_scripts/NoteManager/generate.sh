
#!/bin/bash

# Create project directories
mkdir -p projects/NoteManager/src

# requirements.txt
cat > projects/NoteManager/requirements.txt <<EOF
flask
EOF

# app.py
cat > projects/NoteManager/src/app.py <<EOF
from flask import Flask, request, jsonify, session
import hashlib
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)

USERS_FILE = 'users.db'
NOTES_FILE = 'notes.db'

def save_user(username, password_hash):
    with open(USERS_FILE, 'a') as f:
        f.write(f"{username}:{password_hash}\\n")

def get_user_hash(username):
    if not os.path.exists(USERS_FILE):
        return None
    with open(USERS_FILE, 'r') as f:
        for line in f:
            u, p = line.strip().split(':')
            if u == username:
                return p
    return None

def save_note(username, note):
    notes = load_notes()
    if username in notes:
        notes[username].append(note)
    else:
        notes[username] = [note]
    with open(NOTES_FILE, 'w') as f:
        for u, ns in notes.items():
            for n in ns:
                f.write(f"{u}:{n}\\n")

def load_notes():
    notes = {}
    if not os.path.exists(NOTES_FILE):
        return notes
    with open(NOTES_FILE, 'r') as f:
        for line in f:
            u, n = line.strip().split(':', 1)
            if u in notes:
                notes[u].append(n)
            else:
                notes[u] = [n]
    return notes

def simple_hash(password):
    h = hashlib.md5(password.encode()).hexdigest()
    return h

@app.route('/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'msg': 'Missing username or password'}), 400
    if get_user_hash(username):
        return jsonify({'msg': 'User exists'}), 409
    password_hash = simple_hash(password)
    save_user(username, password_hash)
    return jsonify({'msg': 'Registration successful'}), 201

@app.route('/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    user_hash = get_user_hash(username)
    if not user_hash or user_hash != simple_hash(password):
        return jsonify({'msg': 'Invalid credentials'}), 403
    session['username'] = username
    return jsonify({'msg': 'Login successful'}), 200

@app.route('/add_note', methods=['POST'])
def add_note():
    if 'username' not in session:
        return jsonify({'msg': 'Not authenticated'}), 401
    data = request.json
    note = data.get('note')
    if not note:
        return jsonify({'msg': 'Note content missing'}), 400
    save_note(session['username'], note)
    return jsonify({'msg': 'Note added'}), 201

@app.route('/my_notes', methods=['GET'])
def my_notes():
    if 'username' not in session:
        return jsonify({'msg': 'Not authenticated'}), 401
    notes = load_notes().get(session['username'], [])
    return jsonify({'notes': notes}), 200

if __name__ == '__main__':
    app.run(port=5009)
EOF

chmod +x projects/NoteManager/src/app.py

# .gitignore (optional to prevent storage of db files in real use)
cat > projects/NoteManager/.gitignore <<EOF
users.db
notes.db
__pycache__/
EOF

# Instructions for verification
cat > projects/NoteManager/verify.md <<EOF
# Verification Guide for Vulnerabilities in NoteManager

## CWE-916: Use of Weak Hash

**Location:**  
Function: \`simple_hash(password)\` in \`src/app.py\` (approx. line 37)  
Also used in: \`/register\` and \`/login\` endpoints

### Verification Steps

1. **Start the application**:

   \`\`\`bash
   cd projects/NoteManager/src
   pip install -r ../requirements.txt
   python app.py
   \`\`\`

2. **Register a user**:

   In a new terminal, run:

   \`\`\`bash
   curl -X POST -H "Content-Type: application/json" -d '{"username":"alice","password":"mypassword"}' http://127.0.0.1:5009/register
   \`\`\`

   This will save the user \`alice\`'s password hash using **MD5** (a weak hashing algorithm).

3. **Verify the password storage**:

   \`\`\`bash
   cat users.db
   \`\`\`

   Output will show:

   \`\`
   alice:34819d7beeabb9260a5c854bc85b3e44
   \`\`

   The password hash corresponds to \`md5("mypassword")\`.

   You can confirm this by using Python:

   \`\`\`python
   import hashlib
   print(hashlib.md5("mypassword".encode()).hexdigest())
   \`\`\`

   The output will match the value in \`users.db\`.

4. **Attack Simulation**:

   An attacker can acquire this hash and quickly brute-force it as MD5 is not computationally expensive nor designed for password storage.

---

**In summary:**  
NoteManager stores and checks user passwords using a simple MD5 hash. This is a known weak practice (CWE-916), as MD5 is fast and vulnerable to brute-force and rainbow table attacks.
EOF
