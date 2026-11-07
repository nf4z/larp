"""Embed the same shrine policy in Larplite's editable monolith."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def generate():
 path=ROOT/'larplite.lua'
 if not path.exists():path=ROOT/'src/larplite.lua'
 source=path.read_text(encoding='utf-8')
 policy=(ROOT/'shared_src/halloween-shrine.lua').read_text(encoding='utf-8')
 block=(ROOT/'tools/templates/larplite-halloween-shrine.lua').read_text(encoding='utf-8').replace('__HALLOWEEN_ENGINE__',policy)
 begin='-- HALLOWEEN_SHRINE_BEGIN'
 end='-- HALLOWEEN_SHRINE_END'
 if begin in source:
  a=source.index(begin);b=source.index(end,a)+len(end)
  source=source[:a]+block.rstrip()+source[b:]
 else:
  marker='do\n\tscriptStateOB:AddSection("Dream Fountain")'
  assert marker in source
  source=source.replace(marker,block+'\n'+marker,1)
 path.write_text(source,encoding='utf-8')
if __name__=='__main__':generate();print('Embedded shared Halloween shrine policy in Larplite')
