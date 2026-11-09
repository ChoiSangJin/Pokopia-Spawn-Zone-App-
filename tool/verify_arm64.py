"""Fail if an APK is absent or contains anything except arm64 native libraries."""
import sys
import zipfile
from pathlib import Path

apk = Path(sys.argv[1])
with zipfile.ZipFile(apk) as archive:
    entries = archive.namelist()
    abis = {name.split('/')[1] for name in entries if name.startswith('lib/') and name.endswith('.so')}
    print(f'Native ABIs found: {sorted(abis)}')
    assert abis == {'arm64-v8a'}, f'Unexpected ABIs: {abis}'
    assert 'lib/arm64-v8a/libflutter.so' in entries, 'Flutter runtime missing'
    if '--debug' not in sys.argv:
        assert 'lib/arm64-v8a/libapp.so' in entries, 'Release app missing'
print(f'arm64-v8a verified: {apk}')
