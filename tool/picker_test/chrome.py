"""Headless Chrome driven over the DevTools protocol: every key press and click goes into that browser only."""

import base64
import json
import os
import shutil
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

import websocket


def free_port():
    with socket.socket() as s:
        s.bind(("127.0.0.1", 0))
        return s.getsockname()[1]


def find_chrome():
    mac = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
    for candidate in (os.environ.get("CHROME"), mac, *(shutil.which(n) for n in ("google-chrome", "chromium-browser", "chromium"))):
        if candidate and Path(candidate).exists():
            return candidate
    sys.exit("no Chrome found: install Google Chrome or set CHROME to its path")


KEYS = {
    "Tab": ("Tab", 9, ""),
    "ArrowRight": ("ArrowRight", 39, ""),
    "ArrowLeft": ("ArrowLeft", 37, ""),
    "ArrowUp": ("ArrowUp", 38, ""),
    "ArrowDown": ("ArrowDown", 40, ""),
    " ": ("Space", 32, " "),
    "Enter": ("Enter", 13, "\r"),
}

# Test helpers put on the page's window after each load; the page file is not changed.
HELPERS = r"""
window.__t = {
  name(n) {
    if (!n) return null;
    const title = n.getAttribute('aria-labelledby');
    return title && title.startsWith('title-') ? title.slice(6) : n.textContent.replace('✓', '').trim();
  },
  checked(group) { return this.name(document.querySelector(`#${group} [aria-checked="true"]`)); },
  focus() {
    const a = document.activeElement, g = a && a.closest('[role="radiogroup"]');
    return g ? `${g.id}/${this.name(a)}` : (a ? a.tagName.toLowerCase() + (a.id ? '#' + a.id : '') : 'none');
  },
  find(selector, text) {
    const n = [...document.querySelectorAll(selector)].find((n) => !text || n.textContent.includes(text));
    if (!n) throw new Error(`nothing matches ${selector} ${text || ''}`);
    return n;
  },
  centre(selector, text) {
    const n = this.find(selector, text);
    n.scrollIntoView({ block: 'center' });
    const r = n.getBoundingClientRect();
    return [r.left + r.width / 2, r.top + r.height / 2];
  },
  pixels(selector) {
    const c = this.find(selector), d = c.getContext('2d').getImageData(0, 0, c.width, c.height).data;
    let h = 0;
    for (let i = 0; i < d.length; i++) h = (Math.imul(h, 31) + d[i]) | 0;
    return h;
  },
  saved() { const s = document.getElementById('saved'); return `${s.dataset.tone || ''}:${s.textContent}`; },
};
"""


class Chrome:
    """Headless Chrome with one page, driven over the DevTools protocol."""

    def __init__(self, scratch):
        self.port = free_port()
        self.log_path = scratch / "chrome.log"
        flags = [
            "--headless=new",
            f"--remote-debugging-port={self.port}",
            f"--user-data-dir={scratch / 'profile'}",
            "--no-first-run",
            "--no-default-browser-check",
            "--window-size=1280,1000",
        ]
        if sys.platform.startswith("linux"):
            flags.append("--no-sandbox")  # CI runners block the user namespaces Chrome's sandbox needs.
        with open(self.log_path, "wb") as log:
            self.proc = subprocess.Popen([find_chrome(), *flags, "about:blank"], stdout=log, stderr=subprocess.STDOUT)
        self.ws = websocket.create_connection(self._page_socket(), timeout=15, suppress_origin=True)
        self.next_id = 0
        self.errors = []
        self.call("Runtime.enable")
        self.call("Emulation.setFocusEmulationEnabled", enabled=True)

    def _page_socket(self):
        deadline = time.monotonic() + 20
        while time.monotonic() < deadline:
            if self.proc.poll() is not None:
                raise RuntimeError(f"Chrome exited with {self.proc.returncode}:\n{self.log_path.read_text(errors='replace')}")
            try:
                with urllib.request.urlopen(f"http://127.0.0.1:{self.port}/json", timeout=2) as r:
                    pages = [t for t in json.load(r) if t.get("type") == "page"]
                if pages:
                    return pages[0]["webSocketDebuggerUrl"]
            except (urllib.error.URLError, ConnectionError, TimeoutError):
                pass  # Not listening yet, or too busy starting to answer; the deadline bounds the wait.
            time.sleep(0.1)
        raise RuntimeError("Chrome's DevTools port did not answer within 20 s")

    def call(self, method, **params):
        self.next_id += 1
        self.ws.send(json.dumps({"id": self.next_id, "method": method, "params": params}))
        while True:
            msg = json.loads(self.ws.recv())
            if msg.get("id") == self.next_id:
                if "error" in msg:
                    raise RuntimeError(f"{method}: {msg['error']}")
                return msg.get("result", {})
            if msg.get("method") == "Runtime.exceptionThrown":
                details = msg["params"]["exceptionDetails"]
                self.errors.append(details.get("exception", {}).get("description") or details.get("text"))

    def js(self, expression):
        result = self.call("Runtime.evaluate", expression=expression, returnByValue=True, awaitPromise=True)
        if "exceptionDetails" in result:
            raise RuntimeError(f"{expression}: {result['exceptionDetails'].get('exception', {}).get('description')}")
        return result["result"].get("value")

    def press(self, key):
        code, vk, text = KEYS[key]
        common = {"key": key, "code": code, "windowsVirtualKeyCode": vk, "nativeVirtualKeyCode": vk}
        down = {"type": "keyDown", "text": text} if text else {"type": "rawKeyDown"}
        self.call("Input.dispatchKeyEvent", **down, **common)
        self.call("Input.dispatchKeyEvent", type="keyUp", **common)

    def click(self, selector, text=None):
        x, y = self.js(f"__t.centre({json.dumps(selector)}, {json.dumps(text)})")
        self.call("Input.dispatchMouseEvent", type="mouseMoved", x=x, y=y)
        self.call("Input.dispatchMouseEvent", type="mousePressed", x=x, y=y, button="left", buttons=1, clickCount=1)
        self.call("Input.dispatchMouseEvent", type="mouseReleased", x=x, y=y, button="left", buttons=0, clickCount=1)

    def screenshot(self, path):
        Path(path).write_bytes(base64.b64decode(self.call("Page.captureScreenshot", format="png")["data"]))

    def close(self):
        try:
            self.ws.close()
        finally:
            self.proc.terminate()
            try:
                self.proc.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.proc.kill()
                self.proc.wait(timeout=5)
