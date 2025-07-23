
#!/bin/bash
set -e

PROJECT_ROOT="projects/DataStreamProcessor"
SRC_DIR="$PROJECT_ROOT/src"

mkdir -p "$SRC_DIR"

# requirements.txt (no external packages for this example)
cat > "$PROJECT_ROOT/requirements.txt" <<EOF

EOF

# src/devices.py
cat > "$SRC_DIR/devices.py" <<'EOF'
import threading
import time

# Simulates a DMA-capable device handler.
class DMACapableDevice:
    def __init__(self, device_name):
        self.device_name = device_name
        self.enabled = False
        self.configured = False
    def enable(self):
        # Enables the device (DMA accessible)
        self.enabled = True
    def configure_security(self, key):
        # Simulate security configuration (like encryption key)
        time.sleep(0.5)  # Simulating configuration delay
        self.security_key = key
        self.configured = True
    def transfer(self, data):
        if not self.enabled:
            raise RuntimeError("Device not enabled")
        # Simulate DMA transfer
        # (No real hardware -- just returns data, as if read from memory)
        return data

# Simulate a device manager that handles DMA devices
class DeviceManager:
    def __init__(self):
        self.devices = {}
    def add_device(self, name):
        dev = DMACapableDevice(name)
        self.devices[name] = dev
        return dev
    def get_device(self, name):
        return self.devices[name]
EOF

# src/app.py
cat > "$SRC_DIR/app.py" <<'EOF'
import sys
from devices import DeviceManager
import threading

def initialize_dma_device(manager, device_name, security_key, buffer):
    # --- VULNERABILITY: CWE-1190 ---
    dev = manager.add_device(device_name)
    dev.enable()   # Enables DMA access BEFORE security is configured
    dev.configure_security(security_key)
    # Now transfer data (simulates device reading from memory)
    received = dev.transfer(buffer)
    print("Transfer complete. Data sent: %s" % received.decode())

def main():
    import argparse

    parser = argparse.ArgumentParser(description="Simple Data Stream Processor")
    parser.add_argument('--device', required=True, help='Device name')
    parser.add_argument('--key', required=True, help='Security key')
    parser.add_argument('--file', required=True, help='File to transfer')
    args = parser.parse_args()

    with open(args.file, 'rb') as f:
        buffer = f.read()

    manager = DeviceManager()
    initialize_dma_device(manager, args.device, args.key, buffer)

if __name__ == "__main__":
    main()
EOF

# src/attacker.py
cat > "$SRC_DIR/attacker.py" <<'EOF'
from devices import DeviceManager
import sys
import time
import threading

"""
A simulated DMA attacker: attempts to access the device memory buffer as soon
as the DMA device is enabled but before security is set up.
"""

def attack(manager, device_name):
    time.sleep(0.05)  # Attack as soon as possible after .enable() is called
    try:
        dev = manager.get_device(device_name)
        if dev.enabled and not getattr(dev, "configured", False):
            # Attempt to read the buffer (simulate attack)
            # The attack payload expects 'buffer' to be present via transfer()
            # We supply dummy data as we don't have direct access; but in a real
            # scenario, memory contents could be dumped here.
            print("[!!] DMA Attack: Device enabled and not secured! Attempting buffer read...")
            stolen = dev.transfer(b'STOLEN_SECRET_DATA')
            print("Attacker extracted: %s" % stolen.decode(errors='replace'))
        else:
            print("Attack failed: Device is either not enabled, or already secured.")
    except Exception as e:
        print("Attack exception:", e)

if __name__ == "__main__":
    # Run a simulated attack. Usually imported and run as a thread.
    manager = DeviceManager()
    device_name = sys.argv[1]
    attack(manager, device_name)
EOF

# src/main.py
cat > "$SRC_DIR/main.py" <<'EOF'
import threading
import time
from devices import DeviceManager
import app
import sys

# This is for demonstration: run the main transfer and the attacker at the same time
def main():
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument('--file', required=True, help='Data file to transfer')
    parser.add_argument('--run-attack', action='store_true', help='Launch simulated DMA attack')
    args = parser.parse_args()

    device_name = "alpha"
    key = "supersecret_key"
    manager = DeviceManager()

    with open(args.file, 'rb') as f:
        buffer = f.read()

    threads = []
    if args.run_attack:
        from attacker import attack
        t = threading.Thread(target=attack, args=(manager, device_name))
        t.start()
        threads.append(t)
    # Run DMA initialization (vulnerable order of operations)
    app.initialize_dma_device(manager, device_name, key, buffer)
    for t in threads:
        t.join()

if __name__ == "__main__":
    main()
EOF

chmod +x "$SRC_DIR/main.py"
chmod +x "$SRC_DIR/app.py"
chmod +x "$SRC_DIR/attacker.py"
