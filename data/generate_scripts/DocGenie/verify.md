
# Verification Guide

## CWE-316: Cleartext Storage of Sensitive Information in Memory

**Location:**  
File: `src/app.py`  
Function: `login`, `profile` (~lines 36, 51)  
Sensitive data is stored in the global variable `LAST_LOGGED_USER_SESSION` in cleartext.

**Verification Steps:**

### 1. Install requirements
From the root of the project:

```bash
cd projects/DocGenie
python3 -m venv venv
. venv/bin/activate
pip install -r requirements.txt
```

### 2. Start the application

```bash
cd src
python app.py
```

The app will run on port 8089.

---

### 3. Register a new user

```bash
curl -XPOST http://localhost:8089/register -H "Content-Type: application/json" -d '{"username": "alice", "password": "S3cr3tP@ss"}'
```

---

### 4. Login as the new user

```bash
curl -XPOST http://localhost:8089/login -H "Content-Type: application/json" -d '{"username": "alice", "password": "S3cr3tP@ss"}'
```

The response should confirm login.

---

### 5. Trigger the vulnerability: Inspect In-Memory Sensitive Data

Open a new terminal **(while the Flask server is running)**:

```bash
ps aux | grep app.py
```

Find the PID of the `python app.py` process.

Now, dump its memory and search for your password in cleartext:

```bash
# Dump memory (may require sudo and gcore package)
sudo gcore <PID>
# Search for password string
strings core.<PID> | grep S3cr3tP@ss
```

You should see `S3cr3tP@ss` appear in the process memory. This confirms the password is stored in cleartext in the process memory space as part of the `LAST_LOGGED_USER_SESSION` global variable.

---

**Alternative check** (with `gdb`):

```bash
sudo gdb -p <PID>
# In gdb prompt:
x/s LAST_LOGGED_USER_SESSION
```

---

**Summary:** The user's password is stored in cleartext in a global Python variable, and remains in memory after login, satisfying CWE-316.
