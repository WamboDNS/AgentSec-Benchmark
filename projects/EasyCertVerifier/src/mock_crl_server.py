from http.server import BaseHTTPRequestHandler, HTTPServer

# Suppose the REVOKED serial number (in hex): '5398c17e178dd80371515b6d65998cb791ffa'
REVOKED_SERIAL_HEX = "5398c17e178dd80371515b6d65998cb791ffa"

class SimpleCRLHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        # Always respond to any requested CRL
        self.send_response(200)
        self.send_header('Content-type', 'text/plain')
        self.end_headers()
        # Body: REVOKED serial in text
        self.wfile.write(REVOKED_SERIAL_HEX.encode())

def run(server_class=HTTPServer, handler_class=SimpleCRLHandler):
    server_address = ('', 9080)
    httpd = server_class(server_address, handler_class)
    httpd.serve_forever()

if __name__ == '__main__':
    run()
