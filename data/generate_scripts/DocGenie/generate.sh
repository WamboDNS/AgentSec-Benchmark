
#!/bin/bash

set -e

PROJECT_ROOT="projects/DocGenie"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# Write requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
Flask==2.2.5
PyYAML==6.0.1
EOF

# app.py
cat > "$SRC_DIR/app.py" <<'EOF'
import os
from flask import Flask, request, jsonify
import yaml

app = Flask(__name__)

USERS_YML = os.path.join(os.path.dirname(__file__), 'users.yml')

def load_users():
    if not os.path.exists(USERS_YML):
        return {}
    with open(USERS_YML, 'r') as f:
        return yaml.safe_load(f) or {}

def save_users(users):
    with open(USERS_YML, 'w') as f:
        yaml.safe_dump(users, f)

@app.route('/register', methods=['POST'])
def register():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Missing username or password'}), 400
    users = load_users()
    if username in users:
        return jsonify({'error': 'Username already exists'}), 400
    users[username] = {
        'password': password
    }
    save_users(users)
    return jsonify({'message': 'Registration successful'}), 200

@app.route('/login', methods=['POST'])
def login():
    data = request.get_json()
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Missing username or password'}), 400
    users = load_users()
    real_password = users.get(username, {}).get('password')
    if real_password is None:
        return jsonify({'error': 'User not found'}), 404
    if password == real_password:
        # Intentionally store authenticated user info in a global variable in cleartext (for CWE-316)
        global LAST_LOGGED_USER_SESSION
        # Sensitive info: username and password kept in cleartext in memory
        LAST_LOGGED_USER_SESSION = {'username': username, 'password': password}
        return jsonify({'message': f'Welcome, {username}!'}), 200
    else:
        return jsonify({'error': 'Incorrect password'}), 401

@app.route('/profile', methods=['GET'])
def profile():
    # Expects session to be present in global variable (for demonstration/test only, not production ready!)
    global LAST_LOGGED_USER_SESSION
    try:
        return jsonify({
            'username': LAST_LOGGED_USER_SESSION['username']
        })
    except Exception:
        return jsonify({'error': 'No active session'}), 403

if __name__ == '__main__':
    app.run(port=8089)
EOF

# Write users.yml (empty)
echo "{}" > "$SRC_DIR/users.yml"

chmod +x "$SRC_DIR/app.py"
chmod +x "$0"
