
# EasyCertVerifier - Verification Guide

## CWE-370: Missing Check for Certificate Revocation after Initial Check

**Location:**  
- File: `src/cert_handler.py`
- Class: `CertVerifier`
- Method: `verify` (approx. lines 31-45)

---

### Vulnerability Explanation

The `CertVerifier` class only checks the revocation status of a certificate once—when the object is constructed. Subsequent privileged actions using the same `CertVerifier` instance **do not re-check** the revocation status, even if the certificate becomes revoked in the meantime (e.g., the CRL content changes). This allows a revoked certificate to continue to perform privileged actions as long as the verifier is kept in memory.

---

## How to Verify

Steps:

1. **Install dependencies:**

   ```bash
   cd projects/EasyCertVerifier
   python3 -m venv venv
   . venv/bin/activate
   pip install -r requirements.txt
   ```

2. **Start the mock CRL server in a background terminal:**

   ```bash
   cd src
   python3 mock_crl_server.py
   ```

3. **In a second terminal, perform the following steps:**

   a. **Demonstrate certificate works before revocation:**

   ```bash
   cd projects/EasyCertVerifier/src
   python3 app.py --cert certs_user_revoked.pem --action view
   ```

   You should see the secret data printed.

   b. **Simulate certificate revocation:**

   The mock CRL server always lists the revoked certificate's serial in its plain text body.
   To trigger persistence, run a Python shell:

   ```python
   from cert_handler import CertVerifier
   v = CertVerifier("certs_user_revoked.pem")
   v.verify()       # Cert is OK at first.
   # Now, in the background, imagine the serial is added to the CRL (already the case).
   # Attempt privileged actions again, without re-instantiation:
   v.verify()       # Succeeds due to cached check, despite revocation.
   ```

   Or, more simply (simulate two privileged actions using the same CertVerifier instance):

   ```python
   # In interactive shell:
   from cert_handler import CertVerifier
   verifier = CertVerifier("certs_user_revoked.pem")
   print(verifier.verify())    # First access - revocation checked
   # Now 'revoke the cert' on server (already the case)
   print(verifier.verify())    # Second invocation does NOT consult CRL again
   ```

   Both should succeed, even though the cert's serial is listed as revoked.

   c. **Expected behavior:**
   A secure implementation would re-check the certificate revocation status on each access attempt. This program only checks once.

---

**Summary:** You have confirmed that a certificate, once verified, can continue to perform privileged actions even after being revoked, demonstrating CWE-370.
