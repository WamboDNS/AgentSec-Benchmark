
#!/bin/bash
set -e

PROJECT_ROOT="projects/QuickListProc"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
flask
EOF

# app.py
cat > "$SRC_DIR/app.py" <<'EOF'
from flask import Flask, request, jsonify
import json

app = Flask(__name__)

def process_list(data):
    # Assumes 'items' is always present and is a list of strings.
    # Does not check for missing or incorrectly specified 'items' field.
    item_list = data['items']
    results = []
    for entry in item_list:
        # process: uppercase transformation and length report
        results.append({
            'original': entry,
            'upper': entry.upper(),
            'length': len(entry)
        })
    return results

@app.route('/analyze', methods=['POST'])
def analyze():
    try:
        # Expects JSON like: {"items": ["foo", "bar"]}
        data = request.get_json(force=True)
        result = process_list(data)
        return jsonify({"results": result}), 200
    except Exception as exc:
        # Will leak stack trace or internal error to client
        return jsonify({"error": str(exc)}), 500

if __name__ == '__main__':
    app.run(port=5003)
EOF
chmod +x "$SRC_DIR/app.py"

# verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Guide

## CWE-238: Improper Handling of Incomplete Structural Elements

**Location:**  
- File: `src/app.py`  
- Function: `process_list(data)` (~line 7), called from `/analyze` route handler.

---

### Vulnerability Context

The `process_list` function expects that every incoming JSON payload will contain an `items` field that is a list of strings. There are no checks for its presence or correct type. If a client omits the `items` field or provides it in an incomplete or malformed way, the application will throw an uncaught exception, which is then included in the error response.

---

### Steps to Verify

#### 1. Setup

```bash
cd projects/QuickListProc
pip install -r requirements.txt
python src/app.py
```

#### 2. Correct Usage (Baseline)

```bash
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"items": ["hello", "world"]}' \
    http://localhost:5003/analyze | jq
```
You should get a proper response with uppercased entries.

#### 3. Trigger the CWE-238 (Structural Incompleteness)

**Test: Omit the required `items` field.**

```bash
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"notitems": ["foo"]}' \
    http://localhost:5003/analyze | jq
```

**Expected Result:**  
The server responds with HTTP 500 and an error message indicating a KeyError or similar exception, confirming that missing structural requirements are handled improperly.

Sample output:
```json
{
  "error": "'items'"
}
```

**Test: Malformed `items` field (not a list).**

```bash
curl -s -X POST -H "Content-Type: application/json" \
    -d '{"items": "notalist"}' \
    http://localhost:5003/analyze | jq
```

**Expected Result:**
Error mentioning that iteration or upper() failed, e.g.:
```json
{
  "error": "'str' object is not iterable"
}
```

---

### CWE Reference

- [CWE-238: Improper Handling of Incomplete Structural Elements](https://cwe.mitre.org/data/definitions/238.html)
EOF

echo "QuickListProc project generated in $PROJECT_ROOT"
