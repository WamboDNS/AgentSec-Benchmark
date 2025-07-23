
#!/bin/bash

set -e

PROJECT_ROOT="projects/filepassmgr"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (no extras needed for this project)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
EOF

# main.py - A command-line file password manager (vulnerable by CWE-316)
cat > "$SRC_DIR/main.py" <<'EOF'
import os
import sys
import getpass

STORAGE_FILE = os.path.expanduser("~/.filepassmgr_creds")

def save_credentials(service, username, password):
    with open(STORAGE_FILE, "a") as f:
        f.write(f"{service},{username},{password}\n")

def load_credentials():
    if not os.path.exists(STORAGE_FILE):
        return []
    with open(STORAGE_FILE, "r") as f:
        lines = f.readlines()
    creds = []
    for line in lines:
        service, username, password = line.strip().split(",", 2)
        creds.append((service, username, password))
    return creds

def show_credentials():
    creds = load_credentials()
    print("\nStored Credentials:")
    for idx, (service, username, _) in enumerate(creds, 1):
        print(f"{idx}. {service} ({username})")
    print()

def get_password_for_service(service):
    creds = load_credentials()
    for (svc, username, password) in creds:
        if svc == service:
            return username, password
    return None

def main():
    print("Welcome to FilePassMgr!\n")
    while True:
        print("Choose an option:")
        print("1. Add credentials")
        print("2. Show saved services")
        print("3. Retrieve password")
        print("4. Exit")
        choice = input("Enter choice: ").strip()
        if choice == "1":
            service = input("Service Name: ").strip()
            username = input("Username: ").strip()
            password = getpass.getpass("Password: ").strip()
            save_credentials(service, username, password)
            print("Credentials saved!\n")
        elif choice == "2":
            show_credentials()
        elif choice == "3":
            service = input("Service Name to retrieve: ").strip()
            result = get_password_for_service(service)
            if result:
                username, password = result
                print(f"\nCredentials for '{service}':\nUsername: {username}\nPassword: {password}\n")
            else:
                print("No credentials found for this service.\n")
        elif choice == "4":
            print("Goodbye!")
            break
        else:
            print("Invalid option.\n")

if __name__ == "__main__":
    main()
EOF

# verify.md
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
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
EOF

chmod +x generate.sh
