"""Bundle pinned official TopbarPlus into a lazy standalone executor-compatible module."""
from pathlib import Path
import json
ROOT=Path(__file__).resolve().parents[1]
source=ROOT/'vendor/TopbarPlus/src'
files=sorted(source.rglob('*.lua'))
nodes={'':('ModuleScript',None)}
module_paths={}
for p in files:
    rel=p.relative_to(source)
    parts=rel.parts[:-1] if p.name=='init.lua' else (*rel.parts[:-1],p.stem)
    key='/'.join(parts);module_paths[p]=key
    for index in range(1,len(parts)+1):
        k='/'.join(parts[:index]);nodes.setdefault(k,('Folder','/'.join(parts[:index-1])))
    nodes[key]=('ModuleScript','/'.join(parts[:-1]) if parts else None)
lines=['-- TopbarPlus, ForeverHD. MPL-2.0; see vendor/TopbarPlus/LICENSE.',
       '-- Upstream sources and Attribute preserved. Loader adapts Reference registration only.',
       'local originalRequire = require', 'local nodes, factories, cache, loading = {}, {}, {}, {}']
for key,(kind,parent) in sorted(nodes.items(),key=lambda x:(x[0].count('/'),len(x[0]),x[0])):
    lines += [f'nodes[{json.dumps(key)}] = Instance.new("{kind}")',f'nodes[{json.dumps(key)}].Name = {json.dumps(key.split("/")[-1] or "BgsiscriptTopbarPlus")}']
    if parent is not None:lines.append(f'nodes[{json.dumps(key)}].Parent = nodes[{json.dumps(parent)}]')
lines += ['local function bundledRequire(module)',
 '    if not factories[module] then return originalRequire(module) end',
 '    if cache[module] ~= nil then return cache[module] end',
 '    assert(not loading[module], "Circular TopbarPlus require")',
 '    loading[module] = true',
 '    local result = factories[module](module, bundledRequire)',
 '    loading[module] = nil; cache[module] = result',
 '    return result', 'end']
for p in files:
    content=p.read_text(encoding='utf-8')
    if p.name=='Reference.lua':
        a=content.index('function Reference.addToReplicatedStorage()');b=content.index('\nfunction Reference.getObject()',a)
        content=content[:a]+'''-- A bundled ModuleScript has no engine Source; do not advertise it as a native require target.
function Reference.addToReplicatedStorage() return false end
'''+content[b:]
    lines += [f'factories[nodes[{json.dumps(module_paths[p])}]] = function(script, require)',content,'end']
lines.append('return bundledRequire(nodes[""])')
(ROOT/'vendor/TopbarPlus/bundle.lua').write_text('\n'.join(lines)+'\n',encoding='utf-8',newline='\n')
print(f'TopbarPlus: {len(files)} official modules bundled')
