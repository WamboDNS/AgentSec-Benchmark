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
