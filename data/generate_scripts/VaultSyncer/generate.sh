
#!/bin/bash

set -e

PROJECT_ROOT="projects/VaultSyncer"
SRC_DIR="$PROJECT_ROOT/src"

# Clean and create directories
rm -rf "$PROJECT_ROOT"
mkdir -p "$SRC_DIR"

# requirements.txt
cat > "$PROJECT_ROOT/requirements.txt" <<EOF
requests
pyyaml
EOF

# src/config.yaml (contains plaintext password)
cat > "$SRC_DIR/config.yaml" <<EOF
vault:
  url: "https://demo-vault.example.com"
  username: "admin"
  password: "supersecret123"
EOF

# src/config.py
cat > "$SRC_DIR/config.py" <<'EOF'
import yaml
import os

def load_config(path=None):
    if path is None:
        path = os.path.join(os.path.dirname(__file__), 'config.yaml')
    with open(path, 'r') as f:
        config = yaml.safe_load(f)
    return config
EOF

# src/vault_client.py
cat > "$SRC_DIR/vault_client.py" <<'EOF'
import requests
from config import load_config

class VaultClient:
    def __init__(self, config_path=None):
        config = load_config(config_path)
        self.url = config['vault']['url'].rstrip('/')
        self.username = config['vault']['username']
        self.password = config['vault']['password']
        self.token = None

    def authenticate(self):
        payload = {
            "username": self.username,
            "password": self.password
        }
        resp = requests.post(f"{self.url}/api/login", json=payload, timeout=5)
        resp.raise_for_status()
        self.token = resp.json().get('token')

    def get_secrets(self):
        if self.token is None:
            self.authenticate()
        headers = {'Authorization': f'Bearer {self.token}'}
        resp = requests.get(f"{self.url}/api/secrets", headers=headers, timeout=5)
        resp.raise_for_status()
        return resp.json().get('secrets', [])
EOF

# src/sync.py
cat > "$SRC_DIR/sync.py" <<'EOF'
from vault_client import VaultClient
import sys

def main():
    config_path = None
    if len(sys.argv) > 1:
        config_path = sys.argv[1]
    client = VaultClient(config_path)
    try:
        secrets = client.get_secrets()
        print("Secrets synced:")
        for secret in secrets:
            print("-", secret)
    except Exception as e:
        print("Error during sync:", e)

if __name__ == "__main__":
    main()
EOF

# Make generate.sh executable if user saves it as a file
chmod +x "$0"
