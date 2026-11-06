#!/usr/bin/env python3
"""Martini Society — server locale minimale (solo libreria standard, niente da installare).

Avvio:  python3 server.py            (porta 8000)
        python3 server.py 9000       (porta personalizzata)

I dati stanno in data.json accanto a questo file: copialo per fare un backup.
"""
import json
import os
import socket
import sys
import threading
import uuid
from datetime import datetime
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlparse

ROOT = os.path.dirname(os.path.abspath(__file__))
STATIC = os.path.join(ROOT, "docs")
DATA = os.path.join(ROOT, "data.json")
COLLECTIONS = ("friends", "events", "places", "wishlist", "columns")
LOCK = threading.Lock()


def load():
    if not os.path.exists(DATA):
        return {c: [] for c in COLLECTIONS}
    with open(DATA, encoding="utf-8") as f:
        d = json.load(f)
    for c in COLLECTIONS:
        d.setdefault(c, [])
    return d


def save(d):
    tmp = DATA + ".tmp"
    with open(tmp, "w", encoding="utf-8") as f:
        json.dump(d, f, ensure_ascii=False, indent=2)
    os.replace(tmp, DATA)


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *a, **k):
        super().__init__(*a, directory=STATIC, **k)

    def log_message(self, fmt, *args):  # log più sobrio
        if "/api/state" not in (args[0] if args else ""):
            sys.stderr.write("  · %s\n" % (fmt % args))

    def _send(self, code, obj):
        body = json.dumps(obj, ensure_ascii=False).encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(body)

    def _route(self):
        parts = [p for p in urlparse(self.path).path.split("/") if p]
        if not parts or parts[0] != "api":
            return None
        col = parts[1] if len(parts) > 1 else None
        item = parts[2] if len(parts) > 2 else None
        return col, item

    def _body(self):
        n = int(self.headers.get("Content-Length") or 0)
        if n > 2_000_000:
            raise ValueError("payload troppo grande")
        raw = self.rfile.read(n) if n else b"{}"
        data = json.loads(raw or b"{}")
        if not isinstance(data, dict):
            raise ValueError("serve un oggetto JSON")
        return data

    def do_GET(self):
        r = self._route()
        if r is None:
            return super().do_GET()
        col, _ = r
        with LOCK:
            d = load()
        if col == "state":
            return self._send(200, d)
        if col in COLLECTIONS:
            return self._send(200, d[col])
        return self._send(404, {"error": "non trovato"})

    def do_POST(self):
        r = self._route()
        if not r or r[0] not in COLLECTIONS:
            return self._send(404, {"error": "non trovato"})
        try:
            obj = self._body()
        except Exception as e:
            return self._send(400, {"error": str(e)})
        obj["id"] = uuid.uuid4().hex[:10]
        obj["createdAt"] = datetime.now().isoformat(timespec="seconds")
        with LOCK:
            d = load()
            d[r[0]].append(obj)
            save(d)
        return self._send(201, obj)

    def do_PUT(self):
        r = self._route()
        if not r or r[0] not in COLLECTIONS or not r[1]:
            return self._send(404, {"error": "non trovato"})
        try:
            obj = self._body()
        except Exception as e:
            return self._send(400, {"error": str(e)})
        col, item = r
        with LOCK:
            d = load()
            for i, x in enumerate(d[col]):
                if x.get("id") == item:
                    obj["id"] = item
                    obj.setdefault("createdAt", x.get("createdAt"))
                    d[col][i] = obj
                    save(d)
                    return self._send(200, obj)
        return self._send(404, {"error": "non trovato"})

    def do_DELETE(self):
        r = self._route()
        if not r or r[0] not in COLLECTIONS or not r[1]:
            return self._send(404, {"error": "non trovato"})
        col, item = r
        with LOCK:
            d = load()
            before = len(d[col])
            d[col] = [x for x in d[col] if x.get("id") != item]
            save(d)
        return self._send(200 if len(d[col]) < before else 404, {"ok": True})


def lan_ip():
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    try:
        s.connect(("10.255.255.255", 1))
        return s.getsockname()[0]
    except Exception:
        return "127.0.0.1"
    finally:
        s.close()


if __name__ == "__main__":
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8000
    srv = ThreadingHTTPServer(("0.0.0.0", port), Handler)
    print("\n  🍸  Martini Society è aperto!\n")
    print(f"  Sul tuo PC:          http://localhost:{port}")
    print(f"  Amiche sulla Wi-Fi:  http://{lan_ip()}:{port}\n")
    print("  (Ctrl+C per chiudere)\n")
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        print("\n  Ciao ragazze 💋\n")
