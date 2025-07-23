
#!/bin/bash
set -e

PROJECT_ROOT="projects/directory_lookup_tool"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
Flask==2.3.2
ldap3==2.9.1
EOF

# src/app.py
cat > "$SRC_DIR/app.py" <<'EOF'
from flask import Flask, request, jsonify
from ldap3 import Server, Connection, ALL

app = Flask(__name__)

LDAP_SERVER = 'ldap://localhost'
BASE_DN = 'dc=example,dc=com'

@app.route('/search', methods=['GET'])
def search():
    username = request.args.get('username', '')
    server = Server(LDAP_SERVER, get_info=ALL)
    conn = Connection(server, auto_bind=True)
    # Vulnerable LDAP filter construction
    ldap_filter = f"(uid={username})"
    conn.search(BASE_DN, ldap_filter, attributes=['cn', 'mail'])
    entries = []
    for entry in conn.entries:
        entries.append({
            'cn': str(entry.cn),
            'mail': str(entry.mail)
        })
    return jsonify({'results': entries})

if __name__ == '__main__':
    app.run(port=5000)
EOF

# Make sure generate.sh is executable
chmod +x "$0"
EOF
