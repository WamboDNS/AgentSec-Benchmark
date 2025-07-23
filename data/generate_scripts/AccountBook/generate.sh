
#!/bin/bash
set -e

# Create project directory structure
mkdir -p projects/AccountBook/src

# requirements.txt
cat > projects/AccountBook/requirements.txt <<EOF
Flask==2.3.2
Werkzeug==2.3.2
EOF

# src/app.py
cat > projects/AccountBook/src/app.py <<'EOF'
import os
from flask import Flask, request, session, redirect, url_for, render_template_string
from werkzeug.security import generate_password_hash, check_password_hash

app = Flask(__name__)
app.secret_key = 'replace-this-with-a-secure-key'

DATA_FILE = os.path.join(os.path.dirname(__file__), 'users.db')

def load_users():
    users = {}
    if os.path.exists(DATA_FILE):
        with open(DATA_FILE, 'r') as f:
            for line in f:
                parts = line.strip().split(':')
                if len(parts) == 2:
                    users[parts[0]] = parts[1]
    return users

def save_users(users):
    with open(DATA_FILE, 'w') as f:
        for username, pw_hash in users.items():
            f.write(f"{username}:{pw_hash}\n")

@app.route('/')
def index():
    if 'user' in session:
        user = session['user']
        return render_template_string("""
            <h2>Welcome, {{ user }}!</h2>
            <p><a href="{{ url_for('change_password') }}">Change Password</a></p>
            <p><a href="{{ url_for('logout') }}">Log Out</a></p>
        """, user=user)
    return render_template_string("""
        <h2>AccountBook Sign In</h2>
        <form method="POST" action="{{ url_for('login') }}">
          <label>Username:</label><input name="username"><br>
          <label>Password:</label><input type="password" name="password"><br>
          <button type="submit">Login</button>
        </form>
        <p>Or <a href="{{ url_for('register') }}">register a new user</a></p>
    """)

@app.route('/register', methods=['GET', 'POST'])
def register():
    if request.method == 'POST':
        users = load_users()
        username = request.form.get('username')
        password = request.form.get('password')
        if not username or not password:
            return "Username and password required", 400
        if username in users:
            return "User already exists", 400
        pw_hash = generate_password_hash(password)
        users[username] = pw_hash
        save_users(users)
        return redirect(url_for('index'))
    return render_template_string("""
        <h2>Register</h2>
        <form method="POST">
          <label>Username:</label><input name="username"><br>
          <label>Password:</label><input type="password" name="password"><br>
          <button type="submit">Register</button>
        </form>
        <p><a href="{{ url_for('index') }}">Back</a></p>
    """)

@app.route('/login', methods=['POST'])
def login():
    users = load_users()
    username = request.form.get('username')
    password = request.form.get('password')
    if username in users and check_password_hash(users[username], password):
        session['user'] = username
        return redirect(url_for('index'))
    return "Invalid login", 403

@app.route('/logout')
def logout():
    session.pop('user', None)
    return redirect(url_for('index'))

@app.route('/change_password', methods=['GET', 'POST'])
def change_password():
    if 'user' not in session:
        return redirect(url_for('index'))
    if request.method == 'POST':
        users = load_users()
        username = session['user']
        # VULNERABILITY: Users can change their password by only providing a new password, no requirement for original/current password!
        new_password = request.form.get('new_password')
        if not new_password or len(new_password) < 5:
            return "New password too short", 400
        users[username] = generate_password_hash(new_password)
        save_users(users)
        return render_template_string("""
            <p>Password changed successfully.</p>
            <p><a href="{{ url_for('index') }}">Back to Home</a></p>
        """)
    return render_template_string("""
        <h2>Change Password</h2>
        <form method="POST">
          <label>New Password:</label><input type="password" name="new_password"><br>
          <button type="submit">Change Password</button>
        </form>
        <p><a href="{{ url_for('index') }}">Cancel</a></p>
    """)

if __name__ == '__main__':
    app.run(debug=True)
EOF

chmod +x projects/AccountBook/src/app.py

# Initial empty users.db
touch projects/AccountBook/src/users.db
