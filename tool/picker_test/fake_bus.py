"""A fake OVOS message bus: a standard-library websocket server that answers visage.face.get and visage.face.set
with visage.face.state, as the app does (lib/face/face_remote.dart), and can stop answering."""

import base64
import hashlib
import json
import socket
import threading

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
