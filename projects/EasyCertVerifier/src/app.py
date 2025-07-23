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
