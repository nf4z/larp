"""Mirror authorized PNG exports or publicly accessible originals into the icon cache.

No credentials are embedded or requested. Protected downloads remain explicitly missing.
Usage: python tools/mirror_icon_assets.py --import-dir /path/to/pngs
       python tools/mirror_icon_assets.py --download
"""
from pathlib import Path
import argparse
import hashlib
import json
from concurrent.futures import ThreadPoolExecutor
import requests

ROOT = Path(__file__).resolve().parents[1]
def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--import-dir', type=Path)
    ap.add_argument('--download', action='store_true')
    ap.add_argument('--workers', type=int, default=4)
    args = ap.parse_args()
    ids = json.loads((ROOT/'icon-cache/assets.json').read_text())
    output = ROOT/'icon-cache/assets'
    output.mkdir(exist_ok=True)
    def mirror(asset):
        target = output/f'{asset}.png'
        status = {'assetId': asset}
        try:
            if target.exists(): content = target.read_bytes()
            elif args.import_dir and (args.import_dir/f'{asset}.png').exists(): content = (args.import_dir/f'{asset}.png').read_bytes()
            elif args.download:
                response = requests.get('https://assetdelivery.roblox.com/v1/asset/',params={'id':asset},timeout=15)
                if response.status_code != 200: return dict(status, status=f'http-{response.status_code}')
                content = response.content
            else: return dict(status,status='not-exported')
            if not content.startswith(b'\x89PNG\r\n\x1a\n'): return dict(status,status='not-png')
            target.write_bytes(content)
            return dict(status,status='mirrored',path=target.relative_to(ROOT).as_posix(),sha256=hashlib.sha256(content).hexdigest())
        except requests.RequestException: return dict(status,status='network-error')
    with ThreadPoolExecutor(max_workers=max(1,min(args.workers,8))) as pool: report=list(pool.map(mirror,ids))
    (ROOT/'icon-cache/mirrors.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'mirrored':sum(x['status']=='mirrored' for x in report),'total':len(report)}))
if __name__=='__main__': main()
