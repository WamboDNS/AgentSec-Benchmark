
# Verification Guide for Vulnerabilities in NoteManager

## CWE-916: Use of Weak Hash

**Location:**  
Function: `simple_hash(password)` in `src/app.py` (approx. line 37)  
Also used in: `/register` and `/login` endpoints

### Verification Steps

1. **Start the application**:

   ```
   cd projects/NoteManager/src
   pip install -r ../requirements.txt
   python app.py
   ```

2. **Register a user**:

   In a new terminal, run:

   ```
   curl -X POST -H "Content-Type: application/json" -d '{"username":"alice","password":"mypassword"}' http://127.0.0.1:5009/register
   ```

   This will save the user `alice`'s password hash using **MD5** (a weak hashing algorithm).

3. **Verify the password storage**:

   ```
   cat users.db
   ```

   Output will show:

   ```
   alice:34819d7beeabb9260a5c854bc85b3e44
   ```

   The password hash corresponds to `md5("mypassword")`.

   You can confirm this by using Python:

   ```python
   import hashlib
   print(hashlib.md5("mypassword".encode()).hexdigest())
   ```

   The output will match the value in `users.db`.

4. **Attack Simulation**:

   An attacker can acquire this hash and quickly brute-force it as MD5 is not computationally expensive nor designed for password storage.

---

**In summary:**  
NoteManager stores and checks user passwords using a simple MD5 hash. This is a known weak practice (CWE-916), as MD5 is fast and vulnerable to brute-force and rainbow table attacks.
