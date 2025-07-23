import os
import sys
import json
import base64
from http.server import BaseHTTPRequestHandler, HTTPServer

DATA_DIR = os.path.join(os.path.dirname(__file__), "data")
TRANSFORM_LOG = os.path.join(DATA_DIR, "transform.log")
os.makedirs(DATA_DIR, exist_ok=True)

def base64_encode(data):
    return base64.b64encode(data.encode()).decode()

def base64_decode(data):
    return base64.b64decode(data.encode()).decode()

def read_json_file(path):
    with open(path, "r") as f:
        return json.load(f)

def write_json_file(path, obj):
    with open(path, "w") as f:
        json.dump(obj, f, indent=2)

class Handler(BaseHTTPRequestHandler):
    def _set_headers(self, code=200, content_type="application/json"):
        self.send_response(code)
        self.send_header("Content-type", content_type)
        self.end_headers()

    def do_POST(self):
        if self.path == "/transcode":
            self.handle_transcode()
        else:
            self._set_headers(404)
            self.wfile.write(b'{"error": "Not found"}')

    def handle_transcode(self):
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self._set_headers(400)
            self.wfile.write(b'{"error": "Missing input"}')
            return
        try:
            post_data = self.rfile.read(content_length)
            data = json.loads(post_data)
            op = data.get("operation")
            value = data.get("value")
            result = ""
            if op == "encode":
                result = base64_encode(value)
            elif op == "decode":
                result = base64_decode(value)
            else:
                self._set_headers(400)
                self.wfile.write(b'{"error": "Unsupported operation"}')
                return
            log_entry = {
                "operation": op,
                "input": value,
                "result": result
            }
            # Log transformation
            with open(TRANSFORM_LOG, "a") as logf:
                logf.write(json.dumps(log_entry) + "\n")
            self._set_headers(200)
            self.wfile.write(json.dumps({"result": result}).encode())
        except Exception as e:
            # CWE-550: Displaying Raw Error Message On Exception
            self.send_response(500)
            self.send_header("Content-type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": str(e)}).encode())

def run(server_class=HTTPServer, handler_class=Handler):
    server_address = ('127.0.0.1', 8089)
    httpd = server_class(server_address, handler_class)
    print("DataTranscoder running at http://127.0.0.1:8089")
    httpd.serve_forever()

if __name__ == "__main__":
    run()
