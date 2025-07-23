
#!/bin/bash

set -e

PROJECT_ROOT="projects/EasyCertVerifier"

# Create directory structure
mkdir -p "$PROJECT_ROOT/src"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
cryptography
requests
EOF

# src/cert_handler.py
cat > "$PROJECT_ROOT/src/cert_handler.py" <<'EOF'
import os
import ssl
import requests
from cryptography import x509
from cryptography.hazmat.backends import default_backend

TRUSTED_CERTS_FOLDER = os.path.join(os.path.dirname(__file__), "certs")

def load_cert(cert_path):
    with open(cert_path, "rb") as f:
        cert_data = f.read()
    return x509.load_pem_x509_certificate(cert_data, default_backend())

def is_cert_trusted(cert):
    trusted_certs = []
    trusted_paths = []
    for fname in os.listdir(TRUSTED_CERTS_FOLDER):
        if fname.endswith(".pem"):
            trusted_paths.append(os.path.join(TRUSTED_CERTS_FOLDER, fname))
    for p in trusted_paths:
        try:
            c = load_cert(p)
            trusted_certs.append(c)
        except Exception:
            continue
    for tc in trusted_certs:
        if cert.issuer == tc.subject:
            return True
    return False

def initial_revocation_check(cert):
    # Simulate a certificate revocation check (e.g., via an HTTP-based CRL)
    crl_url = cert.extensions.get_extension_for_class(x509.CRLDistributionPoints).value[0].full_name[0].value
    try:
        resp = requests.get(crl_url, timeout=2)
        if resp.status_code == 200:
            # Very basic check: look for cert serial number in text response (mock CRL)
            if hex(cert.serial_number)[2:] in resp.text:
                return False
    except Exception:
        pass  # Ignore CRL issues
    return True

class CertVerifier:
    def __init__(self, cert_pem_path):
        self.cert = load_cert(cert_pem_path)
        self.trusted = is_cert_trusted(self.cert)
        self.revocation_checked = False
        self.revocation_ok = False

    def verify(self):
        if not self.trusted:
            raise Exception("Certificate is not trusted.")
        if not self.revocation_checked:
            self.revocation_ok = initial_revocation_check(self.cert)
            self.revocation_checked = True
        if not self.revocation_ok:
            raise Exception("Certificate was revoked.")
        return True

EOF

# src/app.py
cat > "$PROJECT_ROOT/src/app.py" <<'EOF'
import argparse
import os
from cert_handler import CertVerifier

DATA_FILE = os.path.join(os.path.dirname(__file__), "protected_info.txt")

def privileged_action():
    print("=== Secret data ===")
    with open(DATA_FILE, "r") as f:
        print(f.read())

def main():
    parser = argparse.ArgumentParser(description="EasyCertVerifier - Certificate protected info fetcher.")
    parser.add_argument("--cert", type=str, required=True, help="Path to user certificate (.pem)")
    parser.add_argument("--action", type=str, choices=["view"], required=True, help="Action to perform")
    args = parser.parse_args()

    verifier = CertVerifier(args.cert)
    try:
        verifier.verify()
        if args.action == "view":
            privileged_action()
    except Exception as e:
        print(f"Access denied: {str(e)}")

if __name__ == "__main__":
    main()
EOF

# Place a simple data file
cat > "$PROJECT_ROOT/src/protected_info.txt" <<EOF
This is top secret information - only visible with a valid certificate.
EOF

# Place a trusted CA certificate
cat > "$PROJECT_ROOT/src/certs_trusted_ca.pem" <<EOF
-----BEGIN CERTIFICATE-----
MIIBbDCCARSgAwIBAgIUeh9WhTij1IoHpy1ewl2ne2Zj3K4wCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMVGVzdCBDQSBSb290MB4XDTI0MDYwMTAwMDAwMFoXDTM0MDUy
OTAwMDAwMFowFzEVMBMGA1UEAwwMVGVzdCBDQSBSb290MFkwEwYHKoZIzj0CAQYI
KoZIzj0DAQcDQgAE633pUXAj0U1M5e05KDfI9Ug9c0JDMmH4SFGU6Q/2YJVvvv9Y
5iroV6I8EIJPESp59uumw8DpsaODrPIU8JVPC6NTMFEwHQYDVR0OBBYEFEdl6kF1
fWJFCvyI0/K+bFrhEabQMB8GA1UdIwQYMBaAFEdl6kF1fWJFCvyI0/K+bFrhEabQ
MA8GA1UdEwEB/wQFMAMBAf8wCgYIKoZIzj0EAwIDSQAwRgIhANyci3oxs6lfjlo8
9Gfj/qnZzAFZQZatVJasz4R8eGWgAiEAmlpO+pMJSlreJsw9Qnajw3o0bS8AKdIn
bK8AZ+t5LHw=
-----END CERTIFICATE-----
EOF

# Place two user certificates - one “good”, one “to be revoked”
cat > "$PROJECT_ROOT/src/certs_user_good.pem" <<EOF
-----BEGIN CERTIFICATE-----
MIIBhTCCASmgAwIBAgIUEmoZBaTF0EV+jJK1de8pW7S3A3swCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMVGVzdCBDQSBSb290MB4XDTI0MDYwMTAwMDAwMFoXDTI1MDYw
MTAwMDAwMFowHzEdMBsGA1UEAwwUc2VjdXJlVXNlcjFAZXhhbXBsZS5jb20wWTAT
BgcqhkjOPQIBBggqhkjOPQMBBwNCAATPo4FI7o8ujFI0S9Zr5jnbTTbakZm2dpXi
ydDzJBu1QiWESwwy8GTH2wjWCsDPYcH3baKaIdnVTPv9+1Oev38co1MwUTAdBgNV
HQ4EFgQUEjY2zKY8RQKyp+yb+ziPkux+1b0wHwYDVR0jBBgwFoAUR2XqQXV9YkUK
/ IjT8r5sWuERptAwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBGAiEA
uKDGGPswCEaSqsG1foJk7ayq266UK/AwOFg/HdCIkzECIQDqSc6oTM3JIRrvgbN9
EAEln1bQv15Fw3Uj5uXg0VON8A==
-----END CERTIFICATE-----
EOF

cat > "$PROJECT_ROOT/src/certs_user_revoked.pem" <<EOF
-----BEGIN CERTIFICATE-----
MIIBhTCCASmgAwIBAgIUT5jBfheN2ANxUVttZZmMt5H/q1owCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMVGVzdCBDQSBSb290MB4XDTI0MDYwMTAwMDAwMFoXDTI1MDYw
MTAwMDAwMFowHzEdMBsGA1UEAwwUc2VjdXJlVXNlcjJAZXhhbXBsZS5jb20wWTAT
BgcqhkjOPQIBBggqhkjOPQMBBwNCAAT8B0ldskj6KHzg5Pgx5zIk0Z12rxWWN7JY
YvVxDsKo21RRAemm3cI2GLNkXN3/VOepehx270KKEpnbq5z4PecTo1MwUTAdBgNV
HQ4EFgQUlIzkE4QZ72LHItEl3CRuI0SDIWIwHwYDVR0jBBgwFoAUR2XqQXV9YkUK
/ IjT8r5sWuERptAwDwYDVR0TAQH/BAUwAwEB/zAKBggqhkjOPQQDAgNJADBGAiEA
i73yuLrX0onGTfp+QmAxrGWKZ4yMi58pEo/HW1nHDMEAIQD49vJ/EAWE5AuFqaOq
5p3wQVDpIz0tqp+HGi4Ps8eDjQ==
-----END CERTIFICATE-----
EOF

# Place folder to hold trusted certs (and move ca into it)
mkdir -p "$PROJECT_ROOT/src/certs"
cp "$PROJECT_ROOT/src/certs_trusted_ca.pem" "$PROJECT_ROOT/src/certs/"

# Remove certs_CA untill
rm "$PROJECT_ROOT/src/certs_trusted_ca.pem"

# Place a simple, mock HTTP CRL server as a background process script
cat > "$PROJECT_ROOT/src/mock_crl_server.py" <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer

# Suppose the REVOKED serial number (in hex): '5398c17e178dd80371515b6d65998cb791ffa'
REVOKED_SERIAL_HEX = "5398c17e178dd80371515b6d65998cb791ffa"

class SimpleCRLHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Always respond to any requested CRL
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        # Body: REVOKED serial in text
        self.wfile.write(REVOKED_SERIAL_HEX.encode())

def run(server_class=HTTPServer, handler_class=SimpleCRLHandler):
    server_address = ('', 9080)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()

if __name__ == '__main__':
    run()
EOF

# Patch the user certs to include the mock CRL distribution point (append extension)
# (Note: For the purposes of the mock, the code parses this as a literal string.)
for certfile in certs_user_good.pem certs_user_revoked.pem; do
    mv "$PROJECT_ROOT/src/$certfile" "$PROJECT_ROOT/src/tmpcert.pem"
    echo '' >> "$PROJECT_ROOT/src/tmpcert.pem"
    echo "CRL Distribution Points:" >> "$PROJECT_ROOT/src/tmpcert.pem"
    echo "    Full Name:" >> "$PROJECT_ROOT/src/tmpcert.pem"
    echo "      URI:http://localhost:9080/crl.pem" >> "$PROJECT_ROOT/src/tmpcert.pem"
    mv "$PROJECT_ROOT/src/tmpcert.pem" "$PROJECT_ROOT/src/$certfile"
done

# Make sure the script is executable
chmod +x "$PROJECT_ROOT/src/mock_crl_server.py"

# Make sure cert_handler.py and app.py are readable
chmod 644 "$PROJECT_ROOT/src/"*.py

# Provide instructions file
cat > "$PROJECT_ROOT/verify.md" <<'EOF'
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
EOF

echo "Project generated at $PROJECT_ROOT"

