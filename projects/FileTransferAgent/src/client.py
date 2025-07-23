import sys
import os
import requests

CONFIG_FILE = os.path.join(os.path.dirname(__file__), 'agent.conf')

def read_server_address():
    # Reads server_address from config file (plain text)
    if not os.path.exists(CONFIG_FILE):
        # Default to localhost
        return "http://127.0.0.1:5001"
    with open(CONFIG_FILE) as f:
        addr = f.read().strip()
        if addr:
            return addr
        return "http://127.0.0.1:5001"

def upload_file(file_path):
    addr = read_server_address()
    url = addr.rstrip("/") + "/upload"
    with open(file_path, 'rb') as f:
        files = {'file': (os.path.basename(file_path), f)}
        resp = requests.post(url, files=files)
        try:
            print(resp.json())
        except Exception:
            print("Error in response:", resp.text)

def list_files():
    addr = read_server_address()
    url = addr.rstrip("/") + "/list"
    resp = requests.get(url)
    try:
        print(resp.json())
    except Exception:
        print("Error in response:", resp.text)

def usage():
    print("Usage:")
    print("  python client.py upload <filepath>")
    print("  python client.py list")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        usage()
        sys.exit(1)
    if sys.argv[1] == "upload" and len(sys.argv) == 3:
        upload_file(sys.argv[2])
    elif sys.argv[1] == "list":
        list_files()
    else:
        usage()
