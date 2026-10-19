"""Drive the face picker page (docs/face-palettes.html) in headless Chrome against a fake message bus.

The fake bus is a small websocket server on 127.0.0.1. It answers visage.face.get and visage.face.set with
visage.face.state, as the app does (lib/face/face_remote.dart), and it can stop answering. Chrome is driven over the
DevTools protocol: every key press and click goes into that headless browser only, never to the desktop.

usage: python3 -I tool/test_picker.py [--page PATH] [--screenshot PATH]
needs: Google Chrome or Chromium ($CHROME overrides the path) and websocket-client
"""

import argparse
import base64
import hashlib
import json
import os
import shutil
import socket
import subprocess
import sys
import tempfile
import threading
import time
import urllib.error
import urllib.request
from pathlib import Path

import websocket

PAGE = Path(__file__).resolve().parent.parent / "docs" / "face-palettes.html"
WS_GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
SET, GET, STATE = "visage.face.set", "visage.face.get", "visage.face.state"
PARTS = ("eyes", "mouth", "mouthSize", "backdrop", "colours")
# facePresets in lib/face/styles.dart: eyes, mouth, backdrop, colours.
PRESETS = {
    "visage": ("lens", "outline", "none", "visage"),
    "mark1": ("ring", "matrix", "mark1", "mark1"),
    "scanner": ("visor", "matrix", "none", "visage"),
    "robot": ("block", "solid", "none", "visage"),
    "retro": ("ring", "waveform", "none", "visage"),
    "hybrid": ("lens", "matrix", "none", "visage"),
    "camera": ("aperture", "grille", "none", "visage"),
    "pod": ("oval", "none", "none", "visage"),
    "led": ("pixel", "matrix", "none", "visage"),
    "orbit": ("mono", "orb", "none", "visage"),
    "buddy": ("dot", "bars", "none", "visage"),
}
# The fake device starts on a face that is not the page's own default, so a checked "hybrid" card proves the page
# took the state from the bus.
START = "hybrid"


def preset_face(name, size):
    eyes, mouth, backdrop, colours = PRESETS[name]
    return {"eyes": eyes, "mouth": mouth, "mouthSize": size, "backdrop": backdrop, "colours": colours}


def merge(face, data):
    """visage.face.set as FaceSpec.merge applies it: a preset resets every part but the mouth size, then named parts win."""
    if "preset" in data:
        face = preset_face(data["preset"], face["mouthSize"])
    return {**face, **{k: data[k] for k in PARTS if k in data}}


def preset_of(face):
    return next((name for name in PRESETS if preset_face(name, face["mouthSize"]) == face), None)


def recv_exact(conn, n):
    data = b""
    while len(data) < n:
        chunk = conn.recv(n - len(data))
        if not chunk:
            raise ConnectionError("the page closed the socket")
        data += chunk
    return data


class FakeBus:
    """A websocket server (RFC 6455, unfragmented text frames) in place of the OVOS message bus."""

    def __init__(self):
        self.server = socket.create_server(("127.0.0.1", 0))
        self.port = self.server.getsockname()[1]
        self.lock = threading.Lock()
        self.clients = []
        self.faults = []
        self.reset()
        threading.Thread(target=self._accept, daemon=True).start()

    def reset(self):
        with self.lock:
            self.received = []
            self.answering = True
            self.face = preset_face(START, "regular")

    def messages(self, kind):
        with self.lock:
            return [m.get("data") for m in self.received if m.get("type") == kind]

    def close(self):
        self.server.close()
        with self.lock:
            for conn in self.clients:
                conn.close()

    def _accept(self):
        while True:
            try:
                conn, _ = self.server.accept()
            except OSError:  # close() shut the server socket: the run is over.
                return
            threading.Thread(target=self._serve, args=(conn,), daemon=True).start()

    def _serve(self, conn):
        try:
            self._handshake(conn)
            with self.lock:
                self.clients.append(conn)
            while (text := self._read_text(conn)) is not None:
                self._handle(conn, json.loads(text))
        except ConnectionError:
            pass  # Expected: a page that navigates away drops its socket without a close frame.
        except Exception as err:  # Anything else is a fault, and the last check fails on it.
            self.faults.append(f"{type(err).__name__}: {err}")
        finally:
            with self.lock:
                if conn in self.clients:
                    self.clients.remove(conn)
            conn.close()

    def _handshake(self, conn):
        request = b""
        while b"\r\n\r\n" not in request:
            chunk = conn.recv(4096)
            if not chunk:
                raise ConnectionError("closed during the handshake")
            request += chunk
        lines = request.decode().split("\r\n")[1:]
        headers = {k.strip().lower(): v.strip() for k, _, v in (line.partition(":") for line in lines if ":" in line)}
        accept = base64.b64encode(hashlib.sha1((headers["sec-websocket-key"] + WS_GUID).encode()).digest()).decode()
        conn.sendall(
            "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\n"
            f"Sec-WebSocket-Accept: {accept}\r\n\r\n".encode()
        )

    def _read_text(self, conn):
        """The next text message, or None after a close frame. Pings get a pong."""
        while True:
            head = recv_exact(conn, 2)
            opcode, length = head[0] & 0x0F, head[1] & 0x7F
            if not head[0] & 0x80:
                raise ValueError("a fragmented frame; the fake bus reads whole frames only")
            if not head[1] & 0x80:
                raise ValueError("a client frame without a mask (RFC 6455 5.1)")
            if length >= 126:
                length = int.from_bytes(recv_exact(conn, 2 if length == 126 else 8), "big")
            mask = recv_exact(conn, 4)
            payload = bytes(b ^ mask[i % 4] for i, b in enumerate(recv_exact(conn, length)))
            if opcode == 0x1:
                return payload.decode()
            if opcode == 0x8:
                self._send(conn, 0x8, payload[:2])
                return None
            if opcode == 0x9:
                self._send(conn, 0xA, payload)
            elif opcode != 0xA:
                raise ValueError(f"unexpected opcode {opcode:#x}")

    def _send(self, conn, opcode, payload):
        n = len(payload)
        size = bytes([n]) if n < 126 else bytes([126]) + n.to_bytes(2, "big") if n < 65536 else bytes([127]) + n.to_bytes(8, "big")
        conn.sendall(bytes([0x80 | opcode]) + size + payload)

    def _handle(self, conn, msg):
        with self.lock:
            self.received.append(msg)
            if msg.get("type") == SET:
                self.face = merge(self.face, msg.get("data") or {})
            answer = self.answering and msg.get("type") in (SET, GET)
            state = {"type": STATE, "data": {**self.face, "preset": preset_of(self.face)}, "context": {}}
        if answer:
            self._send(conn, 0x1, json.dumps(state).encode())


class CheckFailed(Exception):
    pass


def expect(ok, message):
    if not ok:
        raise CheckFailed(message)


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
            except (urllib.error.URLError, ConnectionError):
                pass  # Not listening yet; the deadline bounds the wait.
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


class Run:
    """What every check gets: the browser, the bus, and the steps they share."""

    def __init__(self, chrome, bus, page, screenshot):
        self.chrome, self.bus, self.page, self.screenshot = chrome, bus, page, screenshot

    def load(self, *flags, bus=True):
        """Opens the page fresh, with the bus in the hash unless bus=False, and waits until it is ready."""
        hash_parts = ([f"bus=ws://127.0.0.1:{self.bus.port}/core"] if bus else []) + list(flags)
        url = self.page.as_uri() + ("#" + "&".join(hash_parts) if hash_parts else "")
        self.chrome.js("if (location.protocol === 'file:') localStorage.clear(); window.__old = true")
        self.bus.reset()
        self.chrome.call("Page.navigate", url="about:blank")
        self.chrome.call("Page.navigate", url=url)
        ready = "!window.__old && location.protocol === 'file:' && document.readyState === 'complete'"
        self.wait(ready + " && document.querySelectorAll('#cards .card').length > 0", True, "the page to load")
        self.chrome.js(HELPERS)
        if bus:
            self.wait("document.getElementById('status').dataset.state", "live", "the page to connect to the bus")
            self.wait("__t.checked('cards')", START, "the page to show the face the bus announced")

    def wait(self, expression, want, what, timeout=3.0):
        deadline = time.monotonic() + timeout
        while (got := self.chrome.js(expression)) != want:
            if time.monotonic() > deadline:
                raise CheckFailed(f"waited {timeout:g} s for {what}: wanted {want!r}, got {got!r}")
            time.sleep(0.05)

    def wait_sets(self, want, timeout=3.0):
        deadline = time.monotonic() + timeout
        while (got := self.bus.messages(SET)) != want:
            if time.monotonic() > deadline:
                raise CheckFailed(f"the page sent {SET} {got}, wanted {want}")
            time.sleep(0.05)

    def tab_to(self, group):
        for _ in range(40):
            self.chrome.press("Tab")
            if self.focus().startswith(group + "/"):
                return
        raise CheckFailed(f"40 presses of Tab did not reach the {group} group; focus is on {self.focus()}")

    def focus(self):
        return self.chrome.js("__t.focus()")

    def checked(self, group):
        return self.chrome.js(f"__t.checked('{group}')")

    def moving(self, selector):
        """True if the canvas changes over half a second."""
        before = self.chrome.js(f"__t.pixels({json.dumps(selector)})")
        time.sleep(0.5)
        return self.chrome.js(f"__t.pixels({json.dumps(selector)})") != before

    def no_sets(self):
        time.sleep(0.3)
        expect(self.bus.messages(SET) == [], f"the page sent {SET} {self.bus.messages(SET)}")


CHECKS = []


def check(name):
    def register(fn):
        CHECKS.append((name, fn))
        return fn

    return register


def card(name):
    return f'#cards [aria-labelledby="title-{name}"]'


@check("arrow keys move focus between the cards and do not apply")
def arrows_on_cards(t):
    t.load()
    t.tab_to("cards")
    expect(t.focus() == "cards/hybrid", f"Tab reached {t.focus()}, not the current face")
    seen = []
    for key in ("ArrowRight", "ArrowRight", "ArrowLeft", "ArrowUp"):
        t.chrome.press(key)
        seen.append(t.focus())
    expect(seen == ["cards/camera", "cards/pod", "cards/camera", "cards/hybrid"], f"focus went {seen}")
    t.no_sets()
    expect(t.checked("cards") == "hybrid", f"the checked card changed to {t.checked('cards')}")


@check("arrow keys move focus within an option group and do not apply")
def arrows_on_options(t):
    t.load("customise")
    t.tab_to("eyes")
    expect(t.focus() == "eyes/Round", f"Tab reached {t.focus()}, not the current eyes")
    seen = []
    for key in ("ArrowRight", "ArrowDown", "ArrowLeft"):
        t.chrome.press(key)
        seen.append(t.focus())
    expect(seen == ["eyes/LED ring", "eyes/Square", "eyes/LED ring"], f"focus went {seen}")
    t.no_sets()
    expect(t.checked("eyes") == "Round", f"the checked eyes changed to {t.checked('eyes')}")


@check("Space or Enter applies the focused card or option")
def keys_apply(t):
    t.load("customise")
    t.tab_to("cards")
    t.chrome.press("ArrowRight")
    t.chrome.press(" ")
    t.wait("__t.checked('cards')", "camera", "Space to apply the Camera card")
    t.wait_sets([{"preset": "camera"}])
    t.wait("__t.checked('eyes')", "Camera", "the eyes group to follow the Camera face")
    t.tab_to("eyes")
    t.chrome.press("ArrowRight")
    t.chrome.press("Enter")
    t.wait("__t.checked('eyes')", "One lens", "Enter to apply the One lens eyes")
    t.wait_sets([{"preset": "camera"}, {"eyes": "mono", "mouth": "grille", "mouthSize": "regular", "colours": "visage"}])


@check("a tap applies a card")
def tap_applies(t):
    t.load()
    t.chrome.click(card("robot"))
    t.wait("__t.checked('cards')", "robot", "the tap to apply the Robot card")
    t.wait_sets([{"preset": "robot"}])


@check('"Saved" shows after the assistant answers with visage.face.state')
def saved(t):
    t.load()
    t.chrome.click(card("camera"))
    t.wait("__t.saved()", "ok:Saved.", '"Saved."', timeout=2)


@check('"Not saved" shows 4 s after a change the assistant does not answer')
def not_saved(t):
    t.load()
    with t.bus.lock:
        t.bus.answering = False
    t.chrome.click(card("pod"))
    start, seen = time.monotonic(), set()
    while "did not answer" not in (text := t.chrome.js("__t.saved()")):
        seen.add(text)
        expect(time.monotonic() - start < 6, f"no warning 6 s after the change; the message was {seen}")
        time.sleep(0.05)
    elapsed = time.monotonic() - start
    expect(3.8 <= elapsed <= 5, f"the warning came after {elapsed:.1f} s, not 4 s")
    expect(text == "warn:Not saved. Your assistant did not answer.", f"the warning was {text!r}")
    expect(not any("Saved." in s and "Not" not in s for s in seen), f'"Saved." showed with no answer: {seen}')


@check('"Changed on this page only" shows with no bus')
def no_bus(t):
    t.load(bus=False)
    status = t.chrome.js("document.getElementById('status').textContent")
    expect(status.startswith("Preview only."), f"the status line said {status!r}")
    t.chrome.click(card("robot"))
    t.wait("__t.saved()", "ok:Changed on this page only.", '"Changed on this page only."')
    expect(t.checked("cards") == "robot", f"the checked card is {t.checked('cards')}")
    expect(t.bus.received == [], f"the bus got {t.bus.received}")


@check("Undo puts back the face before the last change, and only that one")
def undo(t):
    t.load()
    t.chrome.click(card("robot"))
    t.wait("__t.saved()", "ok:Saved.", '"Saved." for Robot')
    t.chrome.click(card("pod"))
    t.wait_sets([{"preset": "robot"}, {"preset": "pod"}])
    t.wait("__t.checked('cards')", "pod", "the Pod card")
    t.chrome.click("#undo")
    t.wait("__t.checked('cards')", "robot", "Undo to put back Robot")
    back = {"eyes": "block", "mouth": "solid", "mouthSize": "regular", "colours": "visage", "backdrop": "none"}
    t.wait_sets([{"preset": "robot"}, {"preset": "pod"}, back])
    expect(t.chrome.js("document.getElementById('undo').hidden"), "Undo is still offered after one use")
    if t.screenshot:
        t.chrome.screenshot(t.screenshot)


@check("#customise opens the Customise section")
def hash_customise(t):
    t.load("customise")
    expect(t.chrome.js("document.getElementById('customise').open"), "Customise is closed")
    expect(t.chrome.js("document.getElementById('all').hidden"), "every combination is shown too")


@check("#all opens every combination")
def hash_all(t):
    t.load("all")
    expect(not t.chrome.js("document.getElementById('all').hidden"), "every combination is hidden")
    expect(t.chrome.js("document.getElementById('showAll').getAttribute('aria-expanded')") == "true", "aria-expanded is not true")
    expect(t.chrome.js("document.querySelectorAll('#grid .cell').length") == 72, "the grid does not have 72 cells")
    expect(not t.chrome.js("document.getElementById('customise').open"), "Customise is open too")


@check("with normal motion, the preview and the focused cell move")
def motion_normal(t):
    t.load("customise", "all")
    t.chrome.js("document.querySelector('#grid .cell').focus()")
    expect(t.moving("#preview"), "the preview is still")
    expect(t.moving("#grid .cell canvas"), "the focused cell is still")
    expect(not t.moving(card("hybrid") + " canvas"), "a card moves")


@check("with prefers-reduced-motion: reduce, only the selected face moves")
def motion_reduced(t):
    t.chrome.call("Emulation.setEmulatedMedia", features=[{"name": "prefers-reduced-motion", "value": "reduce"}])
    try:
        t.load("customise", "all")
        expect(t.chrome.js("matchMedia('(prefers-reduced-motion: reduce)').matches"), "the emulation did not apply")
        t.chrome.js("document.querySelector('#grid .cell').focus()")
        expect(not t.moving("#preview"), "the Talking preview moves; it should be one still open mouth")
        t.chrome.click("#views [role=radio]", "Listening")
        t.chrome.js("document.querySelector('#grid .cell').focus()")
        expect(t.moving("#preview"), "the Listening preview of the selected face is still")
        expect(not t.moving("#grid .cell canvas"), "the focused cell moves")
        expect(not t.moving(card("hybrid") + " canvas"), "a card moves")
    finally:
        t.chrome.call("Emulation.setEmulatedMedia", features=[])


@check("no script errors on the page or bad frames on the bus")
def no_errors(t):
    expect(t.chrome.errors == [], f"the page threw {t.chrome.errors}")
    expect(t.bus.faults == [], f"the fake bus saw {t.bus.faults}")


def run_checks(run):
    failed = 0
    for name, fn in CHECKS:
        start = time.monotonic()
        try:
            fn(run)
            print(f"PASS  {name} ({time.monotonic() - start:.1f} s)", flush=True)
        except (CheckFailed, RuntimeError) as err:
            failed += 1
            print(f"FAIL  {name}: {err}", flush=True)
    return failed


def main():
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--page", type=Path, default=PAGE, help="the page to test (default: docs/face-palettes.html)")
    parser.add_argument("--screenshot", help="save a PNG of the page after the Undo check")
    args = parser.parse_args()
    page = args.page.resolve()
    if not page.is_file():
        sys.exit(f"no page at {page}")
    start = time.monotonic()
    bus, chrome = FakeBus(), None
    scratch = tempfile.TemporaryDirectory(prefix="test-picker-", ignore_cleanup_errors=True)
    try:
        chrome = Chrome(Path(scratch.name))
        failed = run_checks(Run(chrome, bus, page, args.screenshot))
    finally:
        if chrome:
            chrome.close()
        bus.close()
        scratch.cleanup()
    print(f"{len(CHECKS) - failed} of {len(CHECKS)} checks passed in {time.monotonic() - start:.1f} s")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
