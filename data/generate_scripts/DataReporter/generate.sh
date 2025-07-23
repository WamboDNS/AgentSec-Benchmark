
#!/bin/bash
set -e

PROJECT_ROOT="projects/DataReporter"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
flask
EOF

# src/app.py
cat > "$SRC_DIR/app.py" <<'EOF'
from flask import Flask, request, send_file
import datetime
import os

app = Flask(__name__)

REPORT_FILE = "report.csv"

def log_submission(data):
    date_str = datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')
    row = "%s,%s,%s\n" % (date_str, data.get('username', ''), data.get('feedback', ''))
    # Appends unescaped values, raw
    with open(REPORT_FILE, "a", encoding="utf-8") as f:
        f.write(row)

@app.route('/submit', methods=['POST'])
def submit():
    username = request.form.get('username', '')
    feedback = request.form.get('feedback', '')
    log_submission({'username': username, 'feedback': feedback})
    return "Submission received", 200

@app.route('/report', methods=['GET'])
def report():
    if not os.path.exists(REPORT_FILE):
        return "No report yet.", 404
    return send_file(REPORT_FILE, mimetype='text/csv', as_attachment=True, download_name='report.csv')

if __name__ == '__main__':
    app.run(host="0.0.0.0", port=5000)
EOF

chmod +x "$SRC_DIR/app.py"

# Verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
# Verification Instructions

## CWE-142: Improper Neutralization of Value Delimiters in a CSV File

**Location:**  
File: `src/app.py`, function: `log_submission`, approx lines 9-14.

**Description:**  
The application logs user input directly into a CSV file as comma-separated values. Special elements provided by the user are not neutralized, allowing malicious input to inject additional CSV rows or columns, or break the format.

---

### Steps to Verify

1. **Install requirements**  
   ```
   pip install -r requirements.txt
   ```

2. **Start the Flask app**  
   ```
   cd src
   python app.py
   ```

3. **Send a standard submission**  
   ```
   curl -X POST -F "username=alice" -F "feedback=Great tool!" http://localhost:5000/submit
   ```

4. **Send a malicious submission (injects new row):**  
   ```
   curl -X POST -F "username=bob" -F "feedback=Nice!\n2024-06-01 10:00:00,eve,InjectedRow" http://localhost:5000/submit
   ```

5. **Download the report:**  
   ```
   curl http://localhost:5000/report -o report.csv
   ```

6. **Open `report.csv` and observe output.**  
   You should see an extra row, not submitted via the application, that has been injected through the feedback field.

   ```
   2024-06-01 10:00:00,alice,Great tool!
   2024-06-01 10:01:00,bob,"Nice!
   2024-06-01 10:00:00,eve,InjectedRow"
   ```

   The malicious feedback inserted a newline and a crafted row, which appears as a separate submission.

---

**This demonstrates the lack of neutralization of special characters (newline and commas), violating [CWE-142](https://cwe.mitre.org/data/definitions/142.html).**
EOF

echo "Project generation complete."
