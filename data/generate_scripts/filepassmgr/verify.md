
# Verification Guide

## CWE-316: The product stores sensitive information in cleartext in memory.

**Location:**  
File: `src/main.py`, Function: `load_credentials`, `get_password_for_service`, and main menu loop (~lines 10-70).

### Verification Steps

1. **Setup and Run**  
   Navigate to the project directory:
   ```
   cd projects/filepassmgr
   ```
   Run the application:
   ```
   python3 src/main.py
   ```

2. **Add Credentials**  
   - Choose option "1" to add credentials.
   - Enter sample data, e.g.:  
     Service Name: `testservice`  
     Username: `alice`  
     Password: `supersecretpass`

3. **Keep the Application Running.**  
   Open a new terminal window.

4. **Find the Running Process ID**  
   ```
   pgrep -f filepassmgr/src/main.py
   ```
   (Suppose it prints PID `12345`)

5. **Search for Sensitive Info in Memory**
   Use `strings` to examine the process memory for the plaintext password:
   ```
   sudo strings /proc/12345/mem 2>/dev/null | grep supersecretpass
   ```
   Alternatively, use `grep` on `/proc/<PID>/maps` and `/proc/<PID>/mem` (requires sudo, and will likely show the password in cleartext!).

6. **Expected Result**
   The plaintext password (`supersecretpass`) appears in the process memory, confirming that sensitive credentials are stored in cleartext and not properly cleared from memory.

**Note:** This is possible because the application loads and manipulates passwords in unprotected variables without ever clearing or securing memory used to store sensitive data.
