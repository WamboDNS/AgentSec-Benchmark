
#!/bin/bash
set -e

PROJECT_DIR="projects/QuickDocSummarizer"
SRC_DIR="$PROJECT_DIR/src"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_DIR/requirements.txt" <<EOF
flask
EOF

# app.py
cat > "$SRC_DIR/app.py" <<'EOF'
import os
from flask import Flask, request, jsonify

app = Flask(__name__)

def is_allowed_filename(filename):
    # Only allow .txt files and no slashes
    return filename.endswith('.txt') and '/' not in filename and '\\' not in filename

def summarize(text):
    # Dummy simple summarization: returns first 2 lines
    return '\n'.join(text.splitlines()[:2])

@app.route('/summarize', methods=['POST'])
def summarize_file():
    filename = request.form.get('filename', '')
    # Input validation BEFORE canonicalization (get absolute path)
    if not is_allowed_filename(filename):
        return jsonify({"error": "Invalid file name"}), 400
    
    # Canonicalization - resolve to absolute path
    abs_path = os.path.abspath(os.path.join('docs', filename))
    try:
        with open(abs_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception:
        return jsonify({"error": "File not found"}), 404

    summary = summarize(content)
    return jsonify({"summary": summary})

if __name__ == "__main__":
    # Make sure docs directory exists for demo
    os.makedirs('docs', exist_ok=True)
    # Create a sample file
    with open('docs/example.txt', 'w', encoding='utf-8') as f:
        f.write('This is an example documentation file.\nIt has multiple lines.\nThis section should be summarized.\n')
    app.run(port=8080)
EOF

chmod +x "$SRC_DIR/app.py"

# END OF SCRIPT
EOF
