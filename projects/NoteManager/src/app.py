from flask import Flask, request, jsonify, session
import hashlib
import os

app = Flask(__name__)
app.secret_key = os.urandom(24)

USERS_FILE = 'users.db'
NOTES_FILE = 'notes.db'

def save_user(username, password_hash):
    with open(USERS_FILE, 'a') as f:
        f.write(f"{username}:{password_hash}\n")

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
                f.write(f"{u}:{n}\n")

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
