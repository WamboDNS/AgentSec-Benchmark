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

