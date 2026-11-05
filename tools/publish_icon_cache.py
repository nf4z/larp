"""Publish regenerated cache and testHub atomically using an authenticated GitHub CLI.

Run build_icon_cache.py and build_testhub.py first. No token is stored in game code.
Usage: python tools/publish_icon_cache.py --repo nf4z/larp --branch main
"""
from pathlib import Path
import argparse
import base64
import json
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
def main():
    ap=argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--repo',default='nf4z/larp')
    ap.add_argument('--branch',default='main')
    args=ap.parse_args()
    def api(endpoint,body=None,method=None):
        command=['gh','api',endpoint]
        with tempfile.TemporaryDirectory() as directory:
            if body is not None:
                path=Path(directory)/'body.json';path.write_text(json.dumps(body),encoding='utf-8')
                command+=['--method',method or 'POST','--input',str(path)]
            result=subprocess.run(command,capture_output=True,text=True,encoding='utf-8')
            if result.returncode: raise RuntimeError(result.stderr.strip())
            return json.loads(result.stdout)
    prefix=f'repos/{args.repo}'
    head=api(f'{prefix}/commits/{args.branch}')
    files=json.loads((ROOT/'icon-cache/publish-files.json').read_text())
    files+=['icon-cache/publish-files.json','icon-cache/README.md','testHub']
    files+= [p.relative_to(ROOT).as_posix() for p in (ROOT/'icon-cache/assets').glob('*.png')] if (ROOT/'icon-cache/assets').exists() else []
    if (ROOT/'icon-cache/mirrors.json').exists(): files.append('icon-cache/mirrors.json')
    entries=[]
    for name in sorted(set(files)):
        path=ROOT/name
        entry={'path':name,'type':'blob','mode':'100644'}
        if path.suffix=='.png':
            entry['sha']=api(f'{prefix}/git/blobs',{'content':base64.b64encode(path.read_bytes()).decode(),'encoding':'base64'})['sha']
        else: entry['content']=path.read_text(encoding='utf-8')
        entries.append(entry)
    tree={'sha':head['commit']['tree']['sha']}
    # GitHub can time out hashing thousands of inline blobs in one request.
    for offset in range(0,len(entries),100):
        tree=api(f'{prefix}/git/trees',{'base_tree':tree['sha'],'tree':entries[offset:offset+100]})
    commit=api(f'{prefix}/git/commits',{'message':'Refresh categorized native icon cache','tree':tree['sha'],'parents':[head['sha']]})
    api(f'{prefix}/git/refs/heads/{args.branch}',{'sha':commit['sha'],'force':False},method='PATCH')
    print(f'https://github.com/{args.repo}/commit/{commit["sha"]}')
if __name__=='__main__': main()
