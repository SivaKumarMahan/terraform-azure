#!/usr/bin/env python3
"""Tiny web server for the scale set instances (standard library only).

GET /        -> 200, plain text with the instance host name
GET /health  -> 200 "ok" (used by the App Gateway probe and the
                Application Health extension for rolling upgrades and repairs)
anything else -> 404
"""
import os
import socket
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

PORT = int(os.environ.get("PORT", "80"))
HOSTNAME = socket.gethostname()


class Handler(BaseHTTPRequestHandler):
    server_version = "web"
    sys_version = ""

    def _send(self, status, body):
        data = body.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        if self.command != "HEAD":
            self.wfile.write(data)

    def do_GET(self):
        path = self.path.split("?", 1)[0]
        if path == "/health":
            self._send(200, "ok\n")
        elif path == "/":
            self._send(200, f"hello from {HOSTNAME}\n")
        else:
            self._send(404, "not found\n")

    do_HEAD = do_GET


if __name__ == "__main__":
    ThreadingHTTPServer(("0.0.0.0", PORT), Handler).serve_forever()
