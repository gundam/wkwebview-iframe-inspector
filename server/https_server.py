#!/usr/bin/env python3
"""Serve three local HTTPS origins for the WKWebView demo."""

from __future__ import annotations

import http.server
import socketserver
import ssl
import subprocess
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
WEB_ROOT = ROOT / "web"
CERT_DIR = ROOT / ".certs"
CERT_FILE = CERT_DIR / "local.crt"
KEY_FILE = CERT_DIR / "local.key"
CERT_VERSION_FILE = CERT_DIR / "version"
CERT_VERSION = "4"
PORT = 8443


def ensure_certificate() -> None:
    if (
        CERT_FILE.exists()
        and KEY_FILE.exists()
        and CERT_VERSION_FILE.exists()
        and CERT_VERSION_FILE.read_text().strip() == CERT_VERSION
    ):
        return

    CERT_DIR.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            "openssl", "req", "-x509", "-newkey", "rsa:2048", "-nodes",
            "-days", "365", "-sha256", "-keyout", str(KEY_FILE), "-out", str(CERT_FILE),
            "-subj", "/CN=samsungweb.localhost",
            "-addext", "subjectAltName=DNS:samsungweb.localhost,DNS:paypalweb.localhost,DNS:checkoutweb.localhost,DNS:localhost,IP:127.0.0.1",
            "-addext", "basicConstraints=critical,CA:FALSE",
            "-addext", "keyUsage=critical,digitalSignature,keyEncipherment",
            "-addext", "extendedKeyUsage=serverAuth",
        ],
        check=True,
    )
    CERT_VERSION_FILE.write_text(CERT_VERSION)


class DomainRequestHandler(http.server.SimpleHTTPRequestHandler):
    def translate_path(self, path: str) -> str:
        host = self.headers.get("Host", "").split(":", 1)[0].lower()
        domain_directory = {
            "paypalweb.localhost": "b",
            "checkoutweb.localhost": "c",
        }.get(host, "a")
        domain_root = WEB_ROOT / domain_directory

        clean_path = path.split("?", 1)[0].split("#", 1)[0].lstrip("/")
        if not clean_path:
            default_pages = {
                "samsungweb.localhost": "direct.html",
                "paypalweb.localhost": "balance.html",
                "checkoutweb.localhost": "send-money.html",
            }
            clean_path = default_pages.get(host, "direct.html")

        candidate = (domain_root / clean_path).resolve()
        if domain_root.resolve() not in candidate.parents and candidate != domain_root.resolve():
            return str(domain_root / "404.html")
        return str(candidate)

    def end_headers(self) -> None:
        self.send_header("Cache-Control", "no-store")
        self.send_header("X-Content-Type-Options", "nosniff")
        super().end_headers()


class LocalThreadingHTTPServer(http.server.ThreadingHTTPServer):
    def server_bind(self) -> None:
        # Avoid a reverse-DNS lookup during startup; local proxy/DNS tools can
        # otherwise delay Python's default HTTPServer.server_bind().
        socketserver.TCPServer.server_bind(self)
        host, port = self.server_address[:2]
        self.server_name = host
        self.server_port = port


def main() -> None:
    ensure_certificate()
    server = LocalThreadingHTTPServer(("127.0.0.1", PORT), DomainRequestHandler)
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=CERT_FILE, keyfile=KEY_FILE)
    server.socket = context.wrap_socket(server.socket, server_side=True)

    print(f"Samsungweb: https://samsungweb.localhost:{PORT}/direct.html", flush=True)
    print(f"Samsungweb iframe page: https://samsungweb.localhost:{PORT}/iframe.html", flush=True)
    print(f"Samsungweb multi-level page: https://samsungweb.localhost:{PORT}/multilevel.html", flush=True)
    print(f"PayPal Sandbox page: https://samsungweb.localhost:{PORT}/paypal-sandbox-container.html", flush=True)
    print(f"Paypalweb balance: https://paypalweb.localhost:{PORT}/balance.html", flush=True)
    print(f"Checkoutweb send money: https://checkoutweb.localhost:{PORT}/send-money.html", flush=True)
    print("Press Control-C to stop the server.", flush=True)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nHTTPS server stopped.", flush=True)
    finally:
        server.server_close()


if __name__ == "__main__":
    if "--prepare" in sys.argv:
        ensure_certificate()
        print(CERT_FILE)
    else:
        main()
