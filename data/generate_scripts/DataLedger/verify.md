
# DataLedger Vulnerability Verification

## Vulnerability 1
**CWE-203: Observable Discrepancy Information Exposure**

**Location:**  
File: `src/app.py`  
Function: `get_balance` (lines ~10-45)

### Verification Steps

1. **Setup:**
    - Install dependencies:
      ```
      pip install -r requirements.txt
      ```
    - Start the server:
      ```
      python src/app.py
      ```

2. **Triggering the Information Exposure:**

   Try querying for a balance with an *incorrect* authentication token for an existing vs. non-existing user.

   - **Request with Existing User, Incorrect Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Alice", "auth": {"user_id": 1, "token": "wrongpass"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "Access denied"}
     ```

   - **Request with Non-Existent User, Incorrect Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Mallory", "auth": {"user_id": 99, "token": "wrongpass"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "Access denied"}
     ```

   - **Request with Existing User, Correct Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Alice", "auth": {"user_id": 1, "token": "letmein"}}'
     ```

     **Response:**
     ```json
     {"success": true, "balance": 1200}
     ```

   - **Request with Non-Existent User, Correct Token:**
     ```
     curl -X POST http://localhost:8004/balance \
        -H "Content-Type: application/json" \
        -d '{"username": "Mallory", "auth": {"user_id": 99, "token": "letmein"}}'
     ```

     **Response:**
     ```json
     {"success": false, "error": "User not found"}
     ```

3. **Observation:**
    - If you supply a **correct** authentication token, but an invalid username, the error `"User not found"` is given, while valid users show their balance.
    - If you supply an **incorrect** token, regardless of user, the response is always `"Access denied"`.
    - By trying different usernames with a valid token, an unauthorized user can deduce which usernames are present in the ledger (**user enumeration**), because the system's response is observably different for real vs. fake users.

### CWE Reference

> [CWE-203: Observable Discrepancy](https://cwe.mitre.org/data/definitions/203.html)

