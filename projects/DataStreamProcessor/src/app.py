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
