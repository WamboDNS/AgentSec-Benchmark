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
