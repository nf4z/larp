"""Exercise the actual upstream Rayfield service helpers and Larplite initialization."""
from pathlib import Path
import json,subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
factory=(ROOT/'shared_src/rayfield-runtime.lua').read_text(encoding='utf-8')
fixture=json.loads((ROOT/'tools/fixtures/rayfield-services.json').read_text(encoding='utf-8'))
source=(ROOT/'larplite.lua').read_text(encoding='utf-8')
a=source.index('\tlocal rayfieldFile = "RayfieldGen2.lua"');b=source.index('\n\tlocal rayfieldWindow',a)
prefix=source[a:b]
services='local ae={}\n'+fixture['services']+'\nreturn ae'
analytics=fixture['analytics']+'\nreturn ah'
code='local install=(function()\n'+factory+'\nend)()\n'+r'''
local base=getfenv()
local function object(name)return {ClassName=name,__instance=true}end
local core,players,textService,guiService,tween=object('CoreGui'),object('Players'),object('TextService'),object('GuiService'),object('TweenService')
local cloneMode,cloneCalls,gets='valid',0,0
local function nativeClone(value)
 cloneCalls+=1
 assert(value~=nil,"invalid argument #1 to 'cloneref' (userdata expected, got nil)")
 if cloneMode=='throw'then error('Executor cannot clone this reference')end
 if cloneMode=='nil'then return nil end
 return value
end
local dataModel={GetService=function(_,name)gets+=1;if name=='TweenService'then return tween end end,
 FindService=function(_,name)if name=='TextService'then return textService end end,
 FindFirstChild=function(_,name)if name=='GuiService'then return guiService end end}
local external=setmetatable({game=dataModel,cloneref=nativeClone,Config={external=true},
 typeof=function(value)if type(value)=='table'and value.__instance then return 'Instance'end;return typeof(value)end},{__index=base})
setfenv(install,external)
local runtime=install({Environment=external,Game=dataModel,Services={CoreGui=core,Players=players}})
local rawSource='''+json.dumps(services)+r'''
local broken=assert(loadstring(rawSource));setfenv(broken,external)
local ok,why=pcall(function()broken().getService('CoreGui')end)
assert(not ok and tostring(why):find('userdata expected, got nil',1,true),'Reproduce the reported error with the actual Rayfield helper')
local patched=assert(loadstring(runtime.Prepare(rawSource)));setfenv(patched,runtime.Environment)
local service=patched()
assert(service.getService('CoreGui')==core,'Known native reference fixes a nil GetService result')
assert(service.getService('TextService')==textService and service.getService('GuiService')==guiService,'Fallback to native service lookup')
assert(service.getService('TweenService')==tween)
local before=gets;service.getService('TweenService');assert(gets==before,'Reuse resolved service references')
for _,mode in ipairs({'throw','nil'})do cloneMode=mode;assert(service.getService('CoreGui')==core,'Clone failure retains a valid instance')end
assert(runtime.Environment.cloneref(nil)==nil)
assert(runtime.Environment.cloneref('unchanged')=='unchanged')
assert(external.cloneref==nativeClone and external.game==dataModel,'No executor globals are patched')
assert(getfenv(runtime.Environment._LarpLiteUiService)==external and runtime.Environment.Config.external,'Library callbacks inherit the clean external environment')
local missing,message=pcall(service.getService,'MissingService')
assert(not missing and tostring(message):find('Rayfield service unavailable: MissingService',1,true),'Name genuinely missing services rather than calling cloneref(nil)')
local analyticsChunk=assert(loadstring(runtime.Prepare('''+json.dumps(analytics)+r''')));setfenv(analyticsChunk,runtime.Environment)
assert(analyticsChunk()('Players')==players,'The second upstream service helper uses the same repair')

-- Execute the real cache-first bootstrap in a polluted hub context.
local _LarpLiteExternalEnvironment=external
local Players,CoreGui=players,core
local Workspace,ReplicatedStorage,HttpService,RunService,UserInputService=object('Workspace'),object('ReplicatedStorage'),object('HttpService'),object('RunService'),object('UserInputService')
local payload='local ae={}\n'..'''+json.dumps(fixture['services'])+r'''..'\nlocal core=ae.getService("CoreGui")\nreturn {CreateWindow=function()end,Core=core,Config=Config} -- CreateDropdown CreateStat\n'..string.rep(' ',11000)
local cached,downloads,written=payload,0,nil
local game=setmetatable({HttpGet=function()downloads+=1;return payload end},{__index=dataModel})
local function isfile()return cached~=nil end
local function readfile()return cached end
local function writefile(_,text)written=text end
local Config={hub=true}
local function loadUI()
'''+prefix+r'''
return Rayfield
end
local library=loadUI();assert(library.Core==core and library.Config.external and not library.Config.hub and downloads==0,'Real cached bootstrap uses clean services/environment')
cached=nil;library=loadUI();assert(library.Core==core and downloads==1 and written==payload,'Fresh bootstrap receives the adapter without rewriting the cache')
print('Rayfield runtime: exact upstream nil-cloneref reproduction, snapshot/native service fallback, throwing/nil clone support, analytics helper, clean environment and real cached/fresh bootstraps: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'rayfield.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
