"""Fetch only web templates from the official release archive using HTTP ranges."""
import io
import pathlib
import subprocess
import zipfile

URL = 'https://github.com/godotengine/godot-builds/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz'

class RemoteZip(io.RawIOBase):
    def __init__(self):
        # Pinned release size from GitHub's release metadata. curl uses the OS trust store.
        self.length = 1281349702
        self.pos = 0

    def seekable(self): return True
    def tell(self): return self.pos
    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else self.pos + offset if whence == 1 else self.length + offset
        return self.pos

    def read(self, size=-1):
        end = self.length if size < 0 else min(self.pos + size, self.length)
        if end <= self.pos: return b''
        data = subprocess.run(['curl', '--fail', '-sSL', '--max-time', '120',
                               '--range', f'{self.pos}-{end-1}', URL], check=True, capture_output=True).stdout
        if len(data) != end - self.pos: raise RuntimeError('Range request not honored')
        self.pos += len(data)
        return data

target = pathlib.Path(__file__).resolve().parents[1] / '.tools'
target.mkdir(exist_ok=True)
with zipfile.ZipFile(RemoteZip()) as archive:
    for name in ['templates/web_nothreads_release.zip', 'templates/web_nothreads_debug.zip']:
        data = archive.read(name)
        path = target / pathlib.Path(name).name
        path.write_bytes(data)
        print(f'{path.name}: {len(data):,} bytes', flush=True)
