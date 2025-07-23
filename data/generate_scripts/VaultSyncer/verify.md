
# Verification Guide: VaultSyncer

This guide will help you verify the presence of the vulnerability from CWE-13 in the VaultSyncer project.

---

## CWE-13: Plaintext Password in Configuration File

**CWE ID:** CWE-13  
**Location:** `src/config.yaml`, also loaded by `src/config.py` and used in `vault_client.py` (lines 7–15)

### How to Verify

1. **Locate the Plaintext Password:**  
   Open the YAML configuration file containing credentials:
   ```bash
   cat projects/VaultSyncer/src/config.yaml
   ```

   **Expected Output (the password is visible in plaintext):**
   ```
   vault:
     url: "https://demo-vault.example.com"
     username: "admin"
     password: "supersecret123"
   ```

2. **Observe Usage in the Code:**  
   Check how the password is loaded and directly used for authentication:
   ```bash
   head -20 projects/VaultSyncer/src/vault_client.py
   ```

   In the code, you will see:
   ```python
   ...
   self.password = config['vault']['password']
   ...
   payload = {
       "username": self.username,
       "password": self.password
   }
   ...
   ```

3. **Exploit Scenario:**  
   Any user who is able to read `src/config.yaml` can easily obtain the plaintext password and access vault credentials.

4. **Optional - Run the Sync (Demo):**
   ```bash
   cd projects/VaultSyncer/src
   pip install -r ../requirements.txt
   python sync.py
   ```

   (Note: The default demo URL is not a live endpoint, but this illustrates that the password is consumed as-programmed from the plaintext config.)

---

**Summary:**  
The existence of a plaintext password in `config.yaml`, and its programmatic use, fulfills the condition for CWE-13.

