
#!/bin/bash

PROJECT_ROOT="projects/TeamDirectory"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

cat > "$SRC_DIR/app.py" << 'EOF'
import sys
import argparse
from ldap3 import Server, Connection, ALL, SUBTREE

def search_employee(username, ldap_server_url, base_dn, user_dn, password):
    # Connect to LDAP server
    server = Server(ldap_server_url, get_info=ALL)
    conn = Connection(server, user=user_dn, password=password, auto_bind=True)
    
    # Build LDAP filter using user-provided input
    ldap_filter = f"(uid={username})"
    conn.search(search_base=base_dn, search_filter=ldap_filter, search_scope=SUBTREE, attributes=['cn', 'mail', 'department'])
    if not conn.entries:
        print("No user found.")
    else:
        for entry in conn.entries:
            print("Name:", entry.cn)
            print("Email:", entry.mail)
            print("Department:", entry.department)
            print("-" * 25)
    conn.unbind()

def main():
    parser = argparse.ArgumentParser(description="TeamDirectory employee search utility")
    parser.add_argument('--username', required=True, help="Username to search for")
    parser.add_argument('--ldap-url', default='ldap://localhost:389', help="LDAP server URI")
    parser.add_argument('--base-dn', default='ou=users,dc=example,dc=com', help="Base DN for LDAP search")
    parser.add_argument('--user-dn', default='cn=admin,dc=example,dc=com', help="Bind DN for LDAP")
    parser.add_argument('--password', default='adminpassword', help="Password for Bind DN")

    args = parser.parse_args()

    search_employee(
        username=args.username,
        ldap_server_url=args.ldap_url,
        base_dn=args.base_dn,
        user_dn=args.user_dn,
        password=args.password
    )

if __name__ == '__main__':
    main()
EOF

cat > "$PROJECT_ROOT/requirements.txt" << 'EOF'
ldap3==2.9.1
EOF

cat > "$PROJECT_ROOT/verify.md" << 'EOF'
# Verification Guide for TeamDirectory

This guide demonstrates how to confirm the presence of the implemented CWE vulnerability.

---

## 1. CWE-90: Improper Neutralization of Special Elements used in an LDAP Query ('LDAP Injection')

**Location:**  
File: `src/app.py`  
Function: `search_employee()`  
Approximate Line: 11

### Verification Steps:

**Prerequisites:**
- An accessible test LDAP server.  
  - For demonstration, you can use [osixia/docker-openldap](https://github.com/osixia/docker-openldap) to run a local LDAP server with default settings.  
- Install required dependencies:
    ```
    pip install ldap3==2.9.1
    ```
- The user `cn=admin,dc=example,dc=com` with password `adminpassword` exists on the server.

---

### a. Normal Search

```
python src/app.py --username johndoe
```

_Expected outcome:_  
Results for user `johndoe` are returned (or "No user found" if not present).

---

### b. LDAP Injection Demo

Suppose you want to perform an injection that retrieves all users by manipulating the LDAP filter.  
Supply a username value that closes the filter and adds another clause:  
```
python src/app.py --username "*)(objectClass=*)"
```

_Expected outcome:_  
Instead of just returning the entry for user `"*)(objectClass=*)"`, this crafted filter turns into:
```
(uid=*)(objectClass=*)
```
which causes the query to return all records in the base DN, effectively bypassing the intended username restriction.

You should see output for all users in the directory, demonstrating that unsanitized input is directly interpolated into the LDAP query.

---

**Note:**  
Depending on your LDAP data, you can try other filter manipulations, e.g.:
```
python src/app.py --username 'johndoe)(|(objectClass=*))'
```

This will search for `uid=johndoe` OR any object with any class (returning all users).

---

**CWE:**  
- CWE-90: The username argument is interpolated directly into the LDAP filter string without sanitization, allowing injection.

EOF

chmod +x generate.sh
