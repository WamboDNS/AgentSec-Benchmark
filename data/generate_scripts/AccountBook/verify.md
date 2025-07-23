
# verify.md

## CWE-620: Unverified Password Change

**Location:**  
`change_password` function, projects/AccountBook/src/app.py, lines ~70-83.

### Verification Steps

1. **Install Requirements:**
   ```bash
   pip install -r projects/AccountBook/requirements.txt
   ```

2. **Run the Application:**
   ```bash
   cd projects/AccountBook/src
   python app.py
   ```

3. **Register Two Accounts via Web Browser:**
   - Open [http://localhost:5000/](http://localhost:5000/) in your browser.
   - Click "register a new user".
   - Register **userA** with password **passwordA**.
   - Log out.
   - Register **userB** with password **passwordB**.

4. **Log Out and Log In as userA:**
   - Click "Log Out" if needed.
   - Login as **userA**.

5. **Change Password (No Old Password Required):**
   - Click "Change Password".
   - In "New Password", enter **newpassA**.
   - Submit.
   - Observe "Password changed successfully."

6. **Verification:**
    - Log Out.
    - Try to login as **userA** with password **passwordA** (should fail).
    - Try to login as **userA** with **newpassA** (should succeed).

7. **KEY TEST (Demonstrates Vulnerability):**
   - While logged in as **userB**, click "Change Password".
   - Enter "somethingelse" as new password.
   - Submit.
   - At *no point* were either userA or userB asked to present their current password when changing password.

**Impact:**  
Any authenticated user can change their own password without authenticating with their old password, enabling easy account takeover if session is hijacked or system does not properly validate sessions.

