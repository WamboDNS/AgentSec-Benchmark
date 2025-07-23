
# Vulnerability Verification Guide

## CWE-798: Use of Hard-coded Credentials

**Location:**  
Function: `check_auth` (lines 11-14), `API_USER` and `API_PASS` in `src/app.py`

---

### Verification Steps

#### 1. Install requirements

```bash
cd projects/QuickNoteManager
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

#### 2. Start the application

```bash
cd src
python app.py
```

Application should start at `http://127.0.0.1:5000`.

#### 3. Access with hard-coded credentials

Try to create a note using the hard-coded API credentials via HTTP Basic Auth.

```bash
curl -u admin:Secr3tP@ssw0rd! -X POST http://127.0.0.1:5000/notes -H "Content-Type: application/json" -d '{"title": "TestNote", "content": "This is a test note."}'
```

Should return:

```json
{"message": "Note saved"}
```

Now, retrieve all notes:

```bash
curl -u admin:Secr3tP@ssw0rd! http://127.0.0.1:5000/notes
```

Should list the note you just entered.

#### 4. Attempt with incorrect credentials

```bash
curl -u admin:wrongpass http://127.0.0.1:5000/notes
```

Should return:

```json
{"message": "Authentication required"}
```

#### 5. Locating the Hard-coded Credentials

Open `src/app.py` and observe lines 12-13:

```python
API_USER = "admin"
API_PASS = "Secr3tP@ssw0rd!"
```

---

**Summary:** The credentials that allow full API control are hard-coded into the source code, illustrating CWE-798.
