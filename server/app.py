"""Loopback-only static game host and shared bank API. No model calls during play."""
import hashlib
import http.server
import json
import os
from pathlib import Path
if __package__ in (None, ""):
    import sys
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from server.bank import CATEGORIES, ROOT, capacity, load_bank, public_question

PORT = int(os.environ.get('PORT', '8765'))

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs): super().__init__(*args, directory=str(ROOT / 'builds/web'), **kwargs)
    def log_message(self, format, *args): pass
    def end_headers(self):
        self.send_header('X-Content-Type-Options', 'nosniff')
        super().end_headers()
    def reply(self, status, value, cache=False):
        data = json.dumps(value, ensure_ascii=False).encode()
        tag = '"' + hashlib.sha256(data).hexdigest() + '"'
        if cache and self.headers.get('If-None-Match') == tag:
            self.send_response(304)
            self.send_header('ETag', tag)
            self.send_header('Cache-Control', 'public, max-age=300')
            self.end_headers()
            return
        self.send_response(status)
        self.send_header('Content-Type', 'application/json')
        self.send_header('Cache-Control', 'public, max-age=300' if cache else 'no-store')
        self.send_header('ETag', tag)
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)
    def do_GET(self):
        if self.path == '/api/config':
            return self.reply(200, {'ai_available': False, 'bank_available': True, 'categories': CATEGORIES, 'scheduled_refresh': False})
        if self.path == '/api/bank':
            try:
                questions = load_bank()
                return self.reply(200, {'questions': [public_question(q) for q in questions], 'capacity': capacity(questions), 'freshness': 'reviewed snapshot; refresh job disabled'}, True)
            except (ValueError, OSError):
                return self.reply(503, {'error': 'Shared bank unavailable; bundled practice remains available.'})
        return super().do_GET()
    def do_POST(self):
        # Earlier clients must never silently trigger paid generation.
        self.reply(410, {'error': 'Per-play generation is retired. Use the cached shared bank; lifelines are local simulations.'})

if __name__ == '__main__':
    print(f'Trivia: http://127.0.0.1:{PORT} | reviewed shared bank | generation and scheduler OFF', flush=True)
    http.server.ThreadingHTTPServer(('127.0.0.1', PORT), Handler).serve_forever()
