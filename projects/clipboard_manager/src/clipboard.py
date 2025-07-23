import sys

MAX_CLIPBOARD_SIZE = 128

class Clipboard:
    def __init__(self):
        self.data = bytearray(MAX_CLIPBOARD_SIZE)

    def copy(self, input_bytes):
        """
        Copies bytes into the internal clipboard buffer.
        """
        for i, b in enumerate(input_bytes):
            self.data[i] = b

    def paste(self):
        """
        Returns the current clipboard buffer as string (strip null bytes).
        """
        return self.data.rstrip(b'\x00').decode(errors='ignore')

def main():
    clipboard = Clipboard()
    if len(sys.argv) < 2:
        print("Usage: python clipboard.py <copy|paste> [text]")
        return

    command = sys.argv[1]
    if command == "copy":
        if len(sys.argv) < 3:
            print("Usage: python clipboard.py copy <text>")
            return
        text = sys.argv[2]
        clipboard.copy(text.encode())
        print("Copied!")
    elif command == "paste":
        print(clipboard.paste())
    else:
        print("Unknown command:", command)

if __name__ == '__main__':
    main()
