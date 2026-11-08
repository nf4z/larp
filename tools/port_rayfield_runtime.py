"""Embed the isolated Rayfield service/clone adapter and cache-first loader."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate():
    path=ROOT/'larplite.lua'
    if not path.exists():path=ROOT/'src/larplite.lua'
    source=path.read_text(encoding='utf-8')
    a=source.index('\tlocal rayfieldFile = "RayfieldGen2.lua"')
    b=source.index('\n\tlocal rayfieldWindow',a)
    block=(ROOT/'tools/templates/larplite-rayfield-loader.lua').read_text(encoding='utf-8')
    block=block.replace('__RAYFIELD_RUNTIME__',(ROOT/'shared_src/rayfield-runtime.lua').read_text(encoding='utf-8'))
    path.write_text(source[:a]+block.rstrip()+'\n'+source[b:],encoding='utf-8')
if __name__=='__main__':generate()
