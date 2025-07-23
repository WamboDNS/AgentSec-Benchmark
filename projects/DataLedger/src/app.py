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
