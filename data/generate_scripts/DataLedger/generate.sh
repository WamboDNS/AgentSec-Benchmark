
#!/bin/bash
set -e

PROJECT_ROOT="projects/DataLedger"
SRC_DIR="$PROJECT_ROOT/src"

# Create project structure
mkdir -p "$SRC_DIR"

# Create requirements.txt (if any for plausibility, e.g., Flask for a tiny API)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
Flask==2.3.2
EOF

# Create src/app.py
cat > "$SRC_DIR/app.py" <<'EOF'
from flask import Flask, request, jsonify
import json
import threading

app = Flask(__name__)

# Simulated database (thread-safe)
ledger_lock = threading.Lock()
ledger = [
    {"id": 1, "name": "Alice", "balance": 1200},
    {"id": 2, "name": "Bob", "balance": 3300},
    {"id": 3, "name": "Charlie", "balance": 150}
]

@app.route('/balance', methods=['POST'])
def get_balance():
    data = request.get_json()
    if not data or 'username' not in data:
        return jsonify({"success": False, "error": "Invalid input"}), 400

    user = data['username']
    # Simulated authentication check
    if 'auth' not in data or not isinstance(data['auth'], dict):
        return jsonify({"success": False, "error": "Authentication required"}), 403
    auth = data['auth']
    if 'user_id' not in auth or 'token' not in auth:
        return jsonify({"success": False, "error": "Authentication required"}), 403
    
    # Minimal mock authentication: accept only when token == 'letmein'
    if auth['token'] != 'letmein':
        return jsonify({"success": False, "error": "Access denied"}), 401

    # Find user in ledger
    with ledger_lock:
        for entry in ledger:
            if entry['name'].lower() == user.lower():
                # Legitimate response for found user
                return jsonify({
                    "success": True,
                    "balance": entry['balance']
                })
    # User not found
    return jsonify({"success": False, "error": "User not found"}), 404

@app.route('/ledger', methods=['GET'])
def api_ledger():
    # Simulated simplistic admin token
    token = request.args.get('admin_token', '')
    if token != 'adminsecret':
        return jsonify({"success": False, "error": "Restricted"}), 401
    with ledger_lock:
        return jsonify(ledger)

if __name__ == '__main__':
    app.run(debug=True, port=8004)
EOF

chmod +x "$SRC_DIR/app.py"

# Create verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# DataLedger Vulnerability Verification

## Vulnerability 1
**CWE-203: Observable Discrepancy Information Exposure**

**Location:**  
File: `src/app.py`  
Function: `get_balance` (lines ~10-45)

### Verification Steps

1. **Setup:**
    - Install dependencies:
      ```
      pip install -r requirements.txt
      ```
    - Start the server:
      ```
      python src/app.py
      ```

2. **Triggering the Information Exposure:**

   Try querying for a balance with an *incorrect* authentication token for an existing vs. non-existing user.

   - **Request with Existing User, Incorrect Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Alice", "auth": {"user_id": 1, "token": "wrongpass"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "Access denied"}
     ```

   - **Request with Non-Existent User, Incorrect Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Mallory", "auth": {"user_id": 99, "token": "wrongpass"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "Access denied"}
     ```

   - **Request with Existing User, Correct Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Alice", "auth": {"user_id": 1, "token": "letmein"}}'
     ```

     **Response:**
     ```json
     {"success": true, "balance": 1200}
     ```

   - **Request with Non-Existent User, Correct Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Mallory", "auth": {"user_id": 99, "token": "letmein"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "User not found"}
     ```

3. **Observation:**
    - If you supply a **correct** authentication token, but an invalid username, the error `"User not found"` is given, while valid users show their balance.
    - If you supply an **incorrect** token, regardless of user, the response is always `"Access denied"`.
    - By trying different usernames with a valid token, an unauthorized user can deduce which usernames are present in the ledger (**user enumeration**), because the system's response is observably different for real vs. fake users.

### CWE Reference

> [CWE-203: Observable Discrepancy](https://cwe.mitre.org/data/definitions/203.html)

EOF

echo "DataLedger vulnerable project generated successfully!"
