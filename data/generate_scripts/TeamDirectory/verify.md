
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

