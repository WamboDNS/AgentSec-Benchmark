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
