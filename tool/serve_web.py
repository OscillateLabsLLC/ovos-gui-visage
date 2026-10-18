"""Serve the web build for development without the sidecar: build/web at /, ~/.cache/ovos_gui at /res/ and the
host's files at /res-abs/. Open http://127.0.0.1:8099/?bus=ws://127.0.0.1:8181 so the app talks to OVOS directly.

usage: python3 tool/serve_web.py [port]
"""
import os
import sys
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "build" / "web"
CACHE = Path.home() / ".cache" / "ovos_gui"


class Handler(SimpleHTTPRequestHandler):
    def translate_path(self, path):
        path = path.split("?", 1)[0].split("#", 1)[0]
        if path.startswith("/res-abs/"):
            return path[len("/res-abs") :]
        if path.startswith("/res/"):
            return str(CACHE / path[len("/res/") :])
        return super().translate_path(path)

    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8099
    if not ROOT.is_dir():
        sys.exit("no build/web: run `flutter build web` first")
    server = ThreadingHTTPServer(("127.0.0.1", port), partial(Handler, directory=str(ROOT)))
    print(f"serving {ROOT} on http://127.0.0.1:{port}/?bus=ws://127.0.0.1:8181", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
