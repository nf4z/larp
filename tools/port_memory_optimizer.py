"""Embed reversible visual optimization and the native Chunker retention repair."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]

def generate():
    path=ROOT/'larplite.lua'
    if not path.exists():path=ROOT/'src/larplite.lua'
    source=path.read_text(encoding='utf-8')
    block=(ROOT/'tools/templates/larplite-memory-optimizer.lua').read_text(encoding='utf-8')
    block=block.replace('__CHUNKER_MEMORY__',(ROOT/'shared_src/chunker-memory.lua').read_text(encoding='utf-8'))
    block=block.replace('__MEMORY_OPTIMIZER__',(ROOT/'shared_src/memory-optimizer.lua').read_text(encoding='utf-8'))
    block=block.replace('__MEMORY_HISTORY__',(ROOT/'shared_src/memory-history.lua').read_text(encoding='utf-8'))
    begin,end='-- MEMORY_OPTIMIZER_BEGIN','-- MEMORY_OPTIMIZER_END'
    if begin in source:
        a=source.index(begin);b=source.index(end,a)+len(end)
        source=source[:a]+block.rstrip()+source[b:]
    else:
        marker='activeStates.BGSI_Lite_ApplyPerformanceSettings = function()'
        assert marker in source
        source=source.replace(marker,block+'\n'+marker,1)
    path.write_text(source,encoding='utf-8')

if __name__=='__main__':generate()
