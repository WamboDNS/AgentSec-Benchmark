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
