"""Compiler and executable Luau regression checks without a Roblox client."""
from pathlib import Path
import json
import os
import subprocess
import tempfile
from tree_sitter import Language, Parser
import tree_sitter_luau

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'modular_dist'
LUAU = os.environ.get('LUAU', str(ROOT / '.tools/luau/luau.exe'))
COMPILER = os.environ.get('LUAU_COMPILE', str(ROOT / '.tools/luau/luau-compile.exe'))
manifest = json.loads((OUT / 'modules-manifest.json').read_text())
loader = (OUT / 'larp').read_text()
parser = Parser(Language(tree_sitter_luau.language()))

def lua_string(s):
    return json.dumps(s, ensure_ascii=True)

def run(code, label):
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / 'test.lua'
        path.write_text(code, encoding='utf-8')
        result = subprocess.run([LUAU, str(path)], capture_output=True, text=True)
        assert result.returncode == 0, f'{label}: {result.stdout}\n{result.stderr}'
        print(label + ': PASS')

for path in [OUT / 'larp', *(OUT / spec['path'] for spec in manifest['modules'].values())]:
    result = subprocess.run([COMPILER, '--null', str(path)], capture_output=True, text=True)
    assert result.returncode == 0, f'{path}: {result.stderr}'
print(f'Loader and {len(manifest["modules"])} real modules compile: PASS')

# Reconstruct the transformed source in execution order and compare syntax trees.
source_path = ROOT / 'larplite.lua'
if not source_path.exists(): source_path = ROOT / 'src/larplite.lua'
source = source_path.read_bytes().replace(b'\r\n', b'\n')
tree = parser.parse(source)
expected = []
for node in tree.root_node.named_children:
    if node.type == 'comment': continue
    text = node.text.decode()
    if node.type == 'variable_declaration':
        text = text.removeprefix('local ')
        if '=' not in text:
            text += ' = ' + ', '.join('nil' for _ in text.split(','))
    elif text.startswith('local function '): text = text.removeprefix('local ')
    expected.append(text)
module_blocks = {}
for name, spec in manifest['modules'].items():
    data = (OUT / spec['path']).read_bytes()
    module_tree = parser.parse(data)
    ret = next(n for n in module_tree.root_node.named_children if n.type == 'return_statement')
    table = ret.named_children[0].named_children[0]
    blocks = []
    for field in table.named_children:
        function = field.named_children[0]
        body = next(n for n in function.named_children if n.type == 'block')
        blocks.append([n.text.decode() for n in body.named_children if n.type != 'comment'])
    module_blocks[name] = blocks
actual = [statement for name, index in manifest['steps'] for statement in module_blocks[name][index - 1]]
assert actual == expected, 'Statement order or content changed during splitting'
print(f'All {len(expected)} statements retain exact order and transformed content: PASS')

# Use tiny modules of the same byte lengths to exercise the actual generated loader.
fake = {}
for name, spec in manifest['modules'].items():
    functions = []
    for index in range(1, spec['blocks'] + 1):
        extra = ''
        if name == 'core' and index == 1:
            extra = 'Players = "shared"; assert(_LarpLiteLoaderOptions.Defaults.setfps == 77); '
        if name == 'main': extra = 'assert(Players == "shared"); '
        functions.append('function(...) ' + extra + f'record("{name}:{index}") end')
    text = 'return {' + ','.join(functions) + '}\n--'
    assert len(text) <= spec['bytes']
    fake[spec['path']] = text + ' ' * (spec['bytes'] - len(text))
fixture = 'local sources = {\n' + ',\n'.join('[' + lua_string(path) + '] = ' + lua_string(text) for path, text in fake.items()) + '\n}\n'
fixture += 'local expected = {' + ','.join(lua_string(f'{name}:{index}') for name, index in manifest['steps']) + '}\n'
fixture += 'local loaderSource = ' + lua_string(loader) + '\n'
fixture += 'local moduleCount = ' + str(len(manifest['modules'])) + '\n'
fixture += 'local sourceSizes = {' + ','.join('['+lua_string(v['path'])+']='+str(v['bytes']) for v in manifest['modules'].values()) + '}\n'
fixture += r'''
local base = getfenv()
local globals, cache, records = {}, {}, {}
local downloads, active, peak, activeBytes, peakBytes = 0, 0, 0, 0, 0
local cancelAt,compiles
local broken = false
local jobs = {}
local mainThread = coroutine.running()
local api = {}
function api.spawn(fn) table.insert(jobs, coroutine.create(fn)) end
function api.wait()
    if coroutine.running() ~= mainThread then coroutine.yield(); return end
    local job = table.remove(jobs, 1)
    if job then
        local ok, err = coroutine.resume(job)
        assert(ok, tostring(err))
        if coroutine.status(job) ~= "dead" then table.insert(jobs, job) end
    end
end
local env = setmetatable({
    getgenv = function() return globals end,
    record = function(value) table.insert(records, value) end,
    isfile = function(path) return cache[path] ~= nil end,
    readfile = function(path) return cache[path] end,
    writefile = function(path, value) cache[path] = value end,
    isfolder = function() return true end,
    makefolder = function() end,
    task = api,
    game = { HttpGet = function(_, url)
        local path = url:match("/main/(.*)$")
        downloads += 1; active += 1; peak = math.max(peak, active)
        activeBytes+=sourceSizes[path];peakBytes=math.max(peakBytes,activeBytes)
        if cancelAt and downloads==cancelAt then globals._1rzHubLiteLoaderTicket={} end
        api.wait()
        active -= 1
        activeBytes-=sourceSizes[path]
        if broken and path:match("modules/eggs/") then error("simulated network failure") end
        assert(sources[path], url)
        return sources[path]
    end },
}, { __index = base })
local function launch(options)
    local fn = assert(loadstring(loaderSource))
    setfenv(fn, env)
    return pcall(fn, options)
end
local options = { Cache = true, DownloadConcurrency = 4, Defaults = { setfps = 77 }, Config = {} }
assert(launch(options))
assert(peak == 4, "Downloads should overlap, bounded at four")
assert(peakBytes<=512*1024,"Bound simultaneous source reservations at the default memory budget")
assert(globals.BGSI_Lite_LoaderMetrics.PeakFetchBytes==peakBytes and globals.BGSI_Lite_LoaderMetrics.Modules==moduleCount)
assert(downloads == moduleCount)
assert(#records == #expected)
for i, value in ipairs(expected) do assert(records[i] == value, value) end
assert(globals._1rzHubLiteLoaderOptions ~= options, "Copy caller options")
assert(globals._1rzHubLiteLoaderOptions.Defaults ~= options.Defaults)
records = {}; downloads = 0
assert(launch(nil)); assert(downloads == 0, "Warm cache should avoid HTTP")
assert(#records == #expected)
local cacheKey = next(cache); cache[cacheKey] = "broken cache"
downloads = 0; records = {}
assert(launch(nil)); assert(downloads == 1, "Repair corrupt cache")
cache[cacheKey] = string.rep("!", #cache[cacheKey])
downloads = 0; records = {}
assert(launch(nil)); assert(downloads == 1, "Repair same-size syntax corruption")
cache = {}; broken = true; records = {}; downloads = 0
local ok, err = launch(options)
assert(not ok and tostring(err):match("eggs"))
assert(#records == 0, "Failed preflight must not execute any module")
assert(downloads == moduleCount + 2, "One failed module gets three attempts")
cache = {}; broken = false; records = {}; downloads = 0
options.Cache = false
assert(launch(options)); assert(next(cache) == nil)
assert(downloads == moduleCount)
-- Without filesystem APIs the loader must still work.
env.isfile = false; records = {}; downloads = 0; options.Cache = true
assert(launch(options)); assert(downloads == moduleCount)
options.Cache=false;options.DownloadMemoryBudgetKB=128
records={};downloads=0;peakBytes=0
assert(launch(options));assert(downloads==moduleCount and #records==#expected)
local largest=0;for _,bytes in pairs(sourceSizes)do largest=math.max(largest,bytes)end
assert(peakBytes<=math.max(128*1024,largest),"A single oversize module may load alone, without overlapping another source")
local metrics=globals.BGSI_Lite_LoaderMetrics
compiles=0;env.loadstring=function(text,name)compiles+=1;return base.loadstring(text,name)end
cancelAt=1;downloads=0;records={}
assert(launch(options));assert(#records==0 and downloads==1 and compiles==0,"Superseded preflight must stop fetching and never compile or start the stale response")
assert(globals.BGSI_Lite_LoaderMetrics==metrics,"Canceled launch keeps the active loader metrics")
'''
run(fixture, 'Real loader: ordering, shared scope, byte/concurrency budget, oversized module, warm/invalid cache, retries, failed preflight, superseded HTTP cancellation, no-file fallback')

# Execute the real settings schema and loadConfig function with fixture files.
wanted = {'defaultConfig', 'copyLoaderValue', 'applyLoaderSettings', 'loadConfig'}
selected = []
for node in tree.root_node.named_children:
    text = node.text.decode()
    if any(text.startswith(prefix + name) for name in wanted for prefix in ('local ', 'local function ', 'function ')):
        selected.append(text)
config_test = '''local files = {}
local loaderOptions = {Defaults = {}, Config = {}}
local configFile, sharedConfigFile, legacyConfigFile = "account", "shared", "legacy"
local function isfile(name) return files[name] ~= nil end
local function readfile(name) return files[name] end
local function decodeCopy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = decodeCopy(item) end
    return result
end
local HttpService = {JSONDecode = function(_, value) if value == "broken" then error("JSON") end return decodeCopy(value) end}
local warnings = 0
local function warn(...) warnings += 1 end
'''
config_test += '\n'.join(selected) + '\n'
config_test += '''
applyLoaderSettings(defaultConfig, {setfps = 77, chunkerRenderDistance = 2})
files.account = {setfps = 144, autoHatch = true, selectedEgg = "Saved Egg", selectedWorldChests = {"Saved"}}
local config = loadConfig()
assert(config.setfps == 144 and config.autoHatch and config.selectedEgg == "Saved Egg")
assert(config.chunkerRenderDistance == 2)
assert(defaultConfig.setfps == 77 and defaultConfig.autoHatch == false)
config.selectedWorldChests[1] = "Changed"
assert(files.account.selectedWorldChests[1] == "Saved")
loaderOptions.Config = {setfps = 30, autoHatch = false, selectedEgg = "Override", unknownKey = true, chunkerRenderDistance = "bad"}
config = loadConfig()
assert(config.setfps == 30 and config.autoHatch == false and config.selectedEgg == "Override")
assert(config.chunkerRenderDistance == 2 and warnings == 2)
loaderOptions.Config = {}
config = loadConfig()
assert(config.setfps == 144 and config.selectedEgg == "Saved Egg")
files.account = nil; files.shared = {setfps = 100, autoSpamE = true}; files.legacy = {setfps = 55, selectedEgg = "Legacy"}
config = loadConfig()
assert(config.setfps == 100 and config.autoSpamR and config.selectedEgg == "Legacy")
files.account = "broken"
assert(loadConfig().setfps == 100)
files = {}; assert(loadConfig().setfps == 77)
files.account={halloweenShrineTarget="Luck"}
config=loadConfig();assert(#config.halloweenShrineTargets==1 and config.halloweenShrineTargets[1]=="Luck", "Migrate old saved single targets")
files.legacy={halloweenShrineTargets={"Secret"}}
assert(loadConfig().halloweenShrineTargets[1]=="Luck","Account single-target selection outranks a legacy multi-target file")
files.legacy=nil
files.account={halloweenShrineTarget="Secret",halloweenShrineTargets={}}
assert(#loadConfig().halloweenShrineTargets==0,"An explicitly cleared target list stays empty")
files.account={halloweenShrineTargets={"Luck","Secret"}}
config=loadConfig();assert(#config.halloweenShrineTargets==2)
loaderOptions.Config={halloweenShrineTarget="Luck"}
assert(loadConfig().halloweenShrineTargets[1]=="Luck","Legacy inline override remains supported")
loaderOptions.Config={halloweenShrineTargets={}}
assert(#loadConfig().halloweenShrineTargets==0,"Inline empty targets override saved selections")
loaderOptions.Config={};files={};loaderOptions.Defaults={halloweenShrineTargets={"Luck","Secret"}}
applyLoaderSettings(defaultConfig,loaderOptions.Defaults)
assert(#loadConfig().halloweenShrineTargets==2,"Inline defaults support multi targets")
files.account={halloweenShrineTarget="Secret"}
assert(#loadConfig().halloweenShrineTargets==1 and loadConfig().halloweenShrineTargets[1]=="Secret","Saved single choice outranks new defaults")
'''
run(config_test, 'Real config: saved priority, defaults, overrides, deep copies, invalid input, migration, corrupt JSON')
