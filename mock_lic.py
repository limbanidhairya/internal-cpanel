from http.server import BaseHTTPRequestHandler, HTTPServer
from urllib.parse import urlparse, parse_qs
import sys

class MockServer(BaseHTTPRequestHandler):
    def do_GET(self):
        parsed_path = urlparse(self.path)
        
        if parsed_path.path == '/xml/verifyfeed':
            query_components = parse_qs(parsed_path.query)
            ip = query_components.get('ip', ['122.171.23.58'])[0]
            
            self.send_response(200)
            self.send_header('Content-type', 'text/xml')
            self.end_headers()
            
            xml_response = f"""<?xml version='1.0' standalone='yes'?>
<cpanellicenses>
  <license ip="{ip}">
    <attributes adddate="2026-03-01 00:20:15" basepkg="1" company="cPanel Direct" expdate="unknown" package="CPDIRECT-PREMIER" producttype="1" status="1" valid="1" />
  </license>
</cpanellicenses>"""
            self.wfile.write(xml_response.encode('utf-8'))

        elif parsed_path.path == '/api/ipaddrs':
            query_components = parse_qs(parsed_path.query)
            ip = query_components.get('ip', ['122.171.23.58'])[0]
            
            self.send_response(200)
            self.send_header('Content-type', 'application/json')
            self.end_headers()
            
            import json
            json_response = {
                "current": [
                    {
                        "basepkg": 1,
                        "package": "CPDIRECT-PREMIER",
                        "status": 1
                    }
                ],
                "history": [],
                "ip": ip
            }
            self.wfile.write(json.dumps(json_response).encode('utf-8'))

        elif parsed_path.path == '/v1.0/':
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"135.181.78.227")
        else:
            # For anything else (like store checks), return 200 OK empty
            self.send_response(200)
            self.send_header('Content-type', 'text/plain')
            self.end_headers()
            self.wfile.write(b"OK")

if __name__ == '__main__':
    port = 8080
    server_address = ('0.0.0.0', port)
    httpd = HTTPServer(server_address, MockServer)
    print(f"Starting mocked cPanel API on port {port}...")
    httpd.serve_forever()
