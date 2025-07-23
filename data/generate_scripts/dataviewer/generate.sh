
#!/bin/bash

set -e

PROJECT_ROOT="projects/dataviewer"
SRC_DIR="$PROJECT_ROOT/src"
REQ_FILE="$PROJECT_ROOT/requirements.txt"
VERIFY_FILE="$PROJECT_ROOT/verify.md"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$REQ_FILE" <<EOF
Flask==2.3.3
EOF

# src/app.py
cat > "$SRC_DIR/app.py" <<'EOF'
from flask import Flask, request, jsonify

app = Flask(__name__)

# Simulated "Database" for demonstration purposes
DATA_STORE = {}

class DataObject:
    def __init__(self, name, value):
        self.name = name
        self.value = value
        # E.g., a 'private' option that should not be mass updated
        self._admin = False

    def to_dict(self):
        return {
            "name": self.name,
            "value": self.value,
            "admin": self._admin
        }

    def update_attributes(self, attributes):
        # Accepts dict and blindly writes keys to object attributes
        for key, val in attributes.items():
            setattr(self, key, val)

@app.route('/create', methods=['POST'])
def create_data():
    data = request.get_json()
    if not data or 'name' not in data or 'value' not in data:
        return jsonify({"error": "Missing required parameter."}), 400
    name = data['name']
    obj = DataObject(name, data['value'])
    DATA_STORE[name] = obj
    return jsonify({"message": "DataObject created.", "object": obj.to_dict()}), 201

@app.route('/update/<string:name>', methods=['POST'])
def update_data(name):
    if name not in DATA_STORE:
        return jsonify({"error": "Not found."}), 404
    data = request.get_json()
    if not data:
        return jsonify({"error": "No data provided."}), 400
    obj = DATA_STORE[name]
    obj.update_attributes(data)
    return jsonify({"message": "Updated.", "object": obj.to_dict()}), 200

@app.route('/show/<string:name>', methods=['GET'])
def show_data(name):
    if name not in DATA_STORE:
        return jsonify({"error": "Not found."}), 404
    obj = DATA_STORE[name]
    return jsonify(obj.to_dict())

if __name__ == '__main__':
    app.run(debug=True)
EOF

chmod +x "$SRC_DIR/app.py"

# verify.md
cat > "$VERIFY_FILE" <<'EOF'
# Verification Guide

## CWE-1321: Improperly Controlled Modification of Object Prototype Attributes ('Prototype Pollution')
**Location**: DataObject.update_attributes() in src/app.py, approx. line 22

### Verification Steps

1. Install dependencies:

    ```
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    ```

2. Run the application:

    ```
    cd src
    python app.py
    ```

3. In a separate terminal, create a new object:

    ```
    curl -X POST -H "Content-Type: application/json" -d '{"name":"sample1", "value":"42"}' http://127.0.0.1:5000/create
    ```

    - Response should confirm creation.

4. Update the object with an "internal" attribute (`_admin`) which should not be externally settable:

    ```
    curl -X POST -H "Content-Type: application/json" -d '{"_admin": true}' http://127.0.0.1:5000/update/sample1
    ```

    - Response will show `"admin": true` indicating that the internal attribute was set via user input.

5. Confirm the effect by fetching the object:

    ```
    curl http://127.0.0.1:5000/show/sample1
    ```

    - The output includes `"admin": true`, demonstrating that a normally private or protected field was changed by an external user.

**Conclusion:**  
The `update_attributes()` method directly writes arbitrary attributes based on user-supplied JSON, allowing the manipulation of internal/protected fields—demonstrating CWE-1321.
EOF

echo "Project dataviewer generated in $PROJECT_ROOT"
