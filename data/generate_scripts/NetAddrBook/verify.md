
# Verification Guide

## CWE-501: Trust Boundary Violation: Mixing Trusted and Untrusted Data

**CWE ID:** CWE-501  
**File:** `src/addressbook.py`  
**Vulnerable Location:** Functions `import_entries`, `add_entry`, and the handling of the address book data structure (approx lines 13-53).

### Vulnerability Details

The application's address book manages both trusted and untrusted (imported from external files) contact entries in the same JSON array and structure (`book.json`). No integrity or provenance flagging is enforced between trusted and untrusted entries, except for the 'trusted' boolean, which is not actively enforced, making it easy to mix and misuse data.

### Verification Steps

#### 1. Create the project and switch to its directory

```bash
bash generate.sh
cd projects/NetAddrBook/src
```

#### 2. Add a trusted contact

```bash
./addressbook.py add --name "Alice" --email "alice@example.com" --notes "Colleague" --trusted
```

#### 3. Prepare a malicious import file (untrusted contact)

Create `untrusted.json`:

```json
[
    {
        "name": "Mallory",
        "email": "mallory@evil.com",
        "notes": "Injected <script>alert(1)</script>."
    }
]
```

Save this content to a file named `untrusted.json` in the current directory.

#### 4. Import the untrusted contacts

```bash
./addressbook.py import --file untrusted.json
```

#### 5. Observe data mixing

List all contacts:

```bash
./addressbook.py list
```

**Expected output (trusted and untrusted are mixed together, visibly indistinguishable except for the 'trusted' marker):**

```
1. [trusted] Alice <alice@example.com> - Colleague
2. [untrusted] Mallory <mallory@evil.com> - Injected <script>alert(1)</script>.
```

#### 6. Export all contacts (trusted and untrusted mixed)

```bash
./addressbook.py export --file exported.json
```

View the contents of `exported.json`:

```bash
cat exported.json
```

*You will see that the data structure freely mixes trusted ("Alice") and untrusted ("Mallory") entries with identical structure. The untrusted notes content is present directly alongside trusted entries.*

#### 7. Demonstrate risk

If a downstream user or system uses `exported.json` without further validation, the untrusted entry is indistinguishable in structure, demonstrating the risk of trust boundary violation through structural mixing.

---

**Summary:**  
Structural data mixing as implemented in `addressbook.py` enables exploitation opportunities or confusion at integrity boundaries.
