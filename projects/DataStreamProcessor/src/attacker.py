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
