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
