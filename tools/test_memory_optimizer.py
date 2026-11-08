"""Reproduce native chunk retention; exercise reversible visual changes and real Safe Mode."""
from pathlib import Path
import subprocess,tempfile
from tree_sitter import Language,Parser
import tree_sitter_luau
ROOT=Path(__file__).resolve().parents[1]
source=(ROOT/'larplite.lua').read_text(encoding='utf-8')
tree=Parser(Language(tree_sitter_luau.language())).parse(source.encode())
def statement(prefix):
    return next(n.text.decode() for n in tree.root_node.named_children if n.text.decode().startswith(prefix))
patch=(ROOT/'shared_src/chunker-memory.lua').read_text(encoding='utf-8')
visual=(ROOT/'shared_src/memory-optimizer.lua').read_text(encoding='utf-8')
native=(ROOT/'tools/fixtures/native-chunker.lua').read_text(encoding='utf-8')
code='local installPatch=(function()\n'+patch+'\nend)()\nlocal installVisual=(function()\n'+visual+'\nend)()\n'+r'''
local vectorCache={};local vectorMT={}
local Vector3={new=function(x,y,z)
 local key=x..','..y..','..z
 if not vectorCache[key] then vectorCache[key]=setmetatable({X=x,Y=y,Z=z},vectorMT)end
 return vectorCache[key]
end}
vectorMT.__add=function(a,b)return Vector3.new(a.X+b.X,a.Y+b.Y,a.Z+b.Z)end
vectorMT.__mul=function(a,b)return Vector3.new(a.X*b.X,a.Y*b.Y,a.Z*b.Z)end
local workspace={Rendered={}}
local function signal()
 local handlers={};local api={}
 function api:Connect(fn)
  local connection={live=true};handlers[connection]=fn
  function connection:Disconnect()self.live=false;handlers[self]=nil end
  return connection
 end
 function api:Fire(...)for connection,fn in pairs(handlers)do if connection.live then fn(...)end end end
 function api:Count()local n=0;for _ in pairs(handlers)do n+=1 end;return n end
 return api
end
local Instance={new=function()return {}end}
local Signal={new=signal}
local native=(function()
'''+native+r'''
end)()
local origin,far=Vector3.new(0,0,0),Vector3.new(10000,0,0)
local chunk=native.new(128,2)
chunk:Add(origin,'item');chunk:Update(origin)
local coord=chunk:ToCoord(origin)
assert(chunk._loaded[coord])
chunk:Remove(origin,'item');chunk:Update(far)
assert(chunk._chunks[coord]==nil and chunk._loaded[coord], 'Reproduce stale loaded-coordinate leak in the supplied native game code')
local now,active,enabled,cap,pruned=0,true,true,4,0
local context={Active=function()return active end,Enabled=function()return enabled end,
 DistanceCap=function()return cap end,Now=function()return now end,Position=function()return origin end,Pruned=function(n)pruned+=n end}
local originalUpdate,originalRemove=native.Update,native.Remove
local api=installPatch(native,context)
chunk:Update(origin);assert(chunk.RenderDistance==2 and pruned==1 and not chunk._loaded[coord])
local visits=0;local getChunk=native.GetChunk
native.GetChunk=function(self,coord)visits+=1;return getChunk(self,coord)end
chunk:Update(origin);assert(visits==9,'Native 2D distance 2 stays 9 cells, rather than widening to 49')
chunk.Mode='3D';visits=0;chunk:Update(origin);assert(visits==27,'Native 3D distance 2 stays 27 cells rather than 343')
cap=1;visits=0;chunk:Update(origin);assert(visits==1 and chunk.RenderDistance==1)
chunk:Add(Vector3.new(128,0,0),'nearby');chunk:Update(origin)
local nearby=chunk:ToCoord(Vector3.new(128,0,0));assert(not chunk._loaded[nearby])
cap=nil;enabled=false;api.Refresh(origin)
assert(chunk.RenderDistance==2 and chunk._loaded[nearby],'Safe Mode reloads the full native nearby range')
enabled=true;cap=1;chunk:Update(origin);assert(not chunk._loaded[nearby])
cap=nil;api.Refresh(nil);assert(chunk.RenderDistance==2,'Restore ranges even while the character is absent')
cap=1;chunk:Update(origin)
api.Destroy();assert(native.Update==originalUpdate and native.Remove==originalRemove)
assert(chunk.RenderDistance==2 and chunk._loaded[nearby],'Unload restores ranges and loads visible objects')
api.Destroy()
local tuple={Update=function()return 'ok',nil,3 end,Remove=function()return false,'kept'end}
local tuplePatch=installPatch(tuple,context)
local self={RenderDistance=1,_chunks={},_loaded={},ToCoord=function()return 1 end}
local a,b,c=tuple.Update(self,origin);assert(a=='ok' and b==nil and c==3)
local d,e=tuple.Remove(self,origin);assert(d==false and e=='kept')
tuplePatch.Destroy()

local function node(class,parent)
 local item={class=class,Parent=parent,children={},RenderFidelity='Precise'}
 if parent then table.insert(parent.children,item)end
 function item:IsA(name)return self.class==name or (name=='GuiBase2d' and self.class=='ViewportFrame')end
 function item:IsDescendantOf(root)local p=self.Parent;while p do if p==root then return true end;p=p.Parent end;return false end
 function item:FindFirstChildOfClass(class)for _,child in ipairs(self.children)do if child.class==class then return child end end end
 function item:GetChildren()return self.children end
 return item
end
local root=node('Workspace');root.DescendantAdded=signal()
local scenery=node('MeshPart',root);scenery.MeshId='keep-mesh';scenery.TextureID='keep-texture';scenery.CanCollide=true
local character=node('Model',root);node('Humanoid',character);local avatar=node('MeshPart',character)
local viewport=node('ViewportFrame',root);local iconMesh=node('MeshPart',viewport)
local already=node('MeshPart',root);already.RenderFidelity='Performance'
local low={Enabled=false,Changed=signal()}
local currentCap=1
local optimizer=installVisual({Root=root,Fidelity='Performance',Active=function()return active end,Now=function()return now end,
 LowDetail=function()return low end,PatchChunker=installPatch,DistanceCap=function()return currentCap end,Position=function()return origin end,
 Sample=function()return {totalMB=900,luaMB=40,texturesMB=300,meshesMB=70}end})
optimizer.SetEnabled(true);assert(low.Enabled and root.DescendantAdded:Count()==1)
while optimizer.Pending()do optimizer.Step()end
assert(scenery.RenderFidelity=='Performance' and avatar.RenderFidelity=='Precise' and iconMesh.RenderFidelity=='Precise')
assert(scenery.MeshId=='keep-mesh' and scenery.TextureID=='keep-texture' and scenery.CanCollide,'Mesh/assets/physics are retained')
local streamed=node('MeshPart',root);root.DescendantAdded:Fire(streamed);root.DescendantAdded:Fire(streamed);optimizer.Step()
assert(streamed.RenderFidelity=='Performance')
assert(optimizer.Sample().totalMB==900 and optimizer.Report.meshesChanged==2)
optimizer.SetEnabled(false)
assert(not low.Enabled and scenery.RenderFidelity=='Precise' and streamed.RenderFidelity=='Precise' and already.RenderFidelity=='Performance')
assert(root.DescendantAdded:Count()==0 and low.Changed:Count()==0)
optimizer.SetEnabled(true);while optimizer.Pending()do optimizer.Step()end
low.Enabled=true;low.Changed:Fire(true)
optimizer.SetEnabled(false);assert(low.Enabled,'Preserve a native setting changed by the user during optimization')
low.Enabled=false
optimizer.SetEnabled(true)
local offscreen=node('MeshPart',root);root.DescendantAdded:Fire(offscreen)
optimizer.SetEnabled(false);optimizer.Step();assert(offscreen.RenderFidelity=='Precise','Disabling drops pending work')

-- Execute the real performance/Safe Mode functions against the real optimizer.
local Config={safeMode=false,safeModeSavedConfig={},autoOptimizeMemory=true,autoHatch=true,noHatchAnim=true,disableRendering=true,setfps=30,chunkerRenderDistance=1}
local _G={}
local defaultConfig=table.clone(Config)
local activeStates={BGSI_Lite_MemoryOptimizer=optimizer,BGSI_Lite_OriginalQualityLevel='Original',BGSI_Lite_OriginalSavedQualityLevel='Saved',BGSI_Lite_OriginalFpsCap=144,
 BGSI_Lite_SafeModePreservedKeys={safeMode=true,safeModeSavedConfig=true,autoOptimizeMemory=true}}
local rendering={QualityLevel='Original'};local userSettings={SavedQualityLevel='Saved'}
local function settings()return {Rendering=rendering}end
local function UserSettings()return {GetService=function()return userSettings end}end
local Enum={QualityLevel={Level01='Low'},SavedQualitySetting={QualityLevel1='LowSaved'}}
local fps=144;activeStates.setfpscap=function(value)fps=value end
local renderEnabled=true
local RunService={Set3dRenderingEnabled=function(_,value)renderEnabled=value end}
local hatch={Play='native'}
activeStates.BGSI_Lite_ApplyHatchAnimationSetting=function()hatch.Play=Config.noHatchAnim and not Config.safeMode and 'hidden' or 'native'end
local function deep(value)if type(value)~='table'then return value end;local t={};for k,v in pairs(value)do t[k]=deep(v)end;return t end
local HttpService={JSONEncode=function(_,v)return deep(v)end,JSONDecode=function(_,v)return deep(v)end}
local saves=0;local function saveConfig()saves+=1 end
local function refreshChunkerAroundPlayer()optimizer.RefreshChunks(origin)end
'''+statement('activeStates.BGSI_Lite_RestorePerformanceBaseline = function')+'\n'+statement('activeStates.BGSI_Lite_ApplyPerformanceSettings = function')+'\n'+statement('activeStates.BGSI_Lite_SetSafeMode = function')+r'''
optimizer.Destroy()
optimizer=installVisual({Root=root,Fidelity='Performance',Active=function()return true end,Now=function()return now end,
 LowDetail=function()return low end,PatchChunker=installPatch,DistanceCap=function()return not Config.safeMode and Config.chunkerRenderDistance or nil end,
 Position=function()return origin end,Sample=function()return {}end})
activeStates.BGSI_Lite_MemoryOptimizer=optimizer
optimizer.InstallChunker(native)
activeStates.BGSI_Lite_ApplyPerformanceSettings();while optimizer.Pending()do optimizer.Step()end
chunk:Update(origin);assert(chunk.RenderDistance==1)
activeStates.BGSI_Lite_ApplyHatchAnimationSetting();assert(hatch.Play=='hidden')
activeStates.BGSI_Lite_SetSafeMode(true)
assert(Config.safeMode and not Config.autoHatch and Config.autoOptimizeMemory and not Config.disableRendering)
assert(not low.Enabled and scenery.RenderFidelity=='Precise' and chunk.RenderDistance==2 and chunk._loaded[nearby])
assert(renderEnabled and rendering.QualityLevel=='Original' and userSettings.SavedQualityLevel=='Saved' and fps==144 and hatch.Play=='native','Safe Mode restores complete original visuals, FPS and animations')
activeStates.BGSI_Lite_SetSafeMode(false);while optimizer.Pending()do optimizer.Step()end
assert(Config.autoHatch and Config.noHatchAnim and Config.disableRendering and low.Enabled and scenery.RenderFidelity=='Performance' and fps==30)
activeStates.BGSI_Lite_SetSafeMode(true);Config.autoOptimizeMemory=false;activeStates.BGSI_Lite_SetSafeMode(false)
assert(not low.Enabled and scenery.RenderFidelity=='Precise','An optimization preference changed in Safe Mode is preserved')
optimizer.Destroy();optimizer.Destroy();assert(root.DescendantAdded:Count()==0 and low.Changed:Count()==0)
activeStates.BGSI_Lite_OriginalFpsCap=nil;fps=99
activeStates.BGSI_Lite_ApplyPerformanceSettings();activeStates.BGSI_Lite_RestorePerformanceBaseline()
assert(fps==99,'When FPS readback is unavailable, never introduce an override that cannot be restored')
local burstRoot=node('Workspace');burstRoot.DescendantAdded=signal()
local burst=installVisual({Root=burstRoot,Fidelity='Performance',Active=function()return true end,Now=function()return now end,LowDetail=function()return {}end})
burst.SetEnabled(true);while burst.Pending()do burst.Step()end
local last
for i=1,2200 do last=node('MeshPart',burstRoot);burstRoot.DescendantAdded:Fire(last)end
assert(last.RenderFidelity=='Precise','Large streaming bursts remain deferred, never synchronous scans')
while burst.Pending()do burst.Step()end
assert(last.RenderFidelity=='Performance' and burst.Report.meshesChanged==2200,'Coalesced rescan covers every overflow mesh')
burst.Destroy();assert(last.RenderFidelity=='Precise' and burstRoot.DescendantAdded:Count()==0)
print('Memory optimizer: reproduced native leak; native range caps/removal, live reloading/restoration, mesh batching/streaming/exclusions, owned signals, metrics, real Safe Mode graphics/FPS/hatch restore and saved preferences: PASS (offline)')
'''
code+='\n'+r'''
local eggChunkerTracker={Chunkers=setmetatable({}, {__mode='v'}),Positions=setmetatable({}, {__mode='k'}),NextId=0}
local invalidations=0
local function clearEggScanCache()invalidations+=1 end
'''+statement('function registerEggChunker(')+'\n'+statement('function isEggChunkerObject(')+r'''
local x={_chunks={},_loaded={},_chunkSize=128,RenderDistance=2}
local y={_chunks={},_loaded={},_chunkSize=128,RenderDistance=2}
registerEggChunker(x);registerEggChunker(y)
eggChunkerTracker.Chunkers[1]=nil
registerEggChunker(y);assert(eggChunkerTracker.NextId==2,'Weak registry holes cannot hide existing instances')
registerEggChunker(x);assert(eggChunkerTracker.NextId==3 and eggChunkerTracker.Chunkers[2]==y and eggChunkerTracker.Chunkers[3]==x)
local gcCalls=0
local function getgc()gcCalls+=1;return {x,y}end
local time=10;local function tick()return time end
local function findChunkerModule()return nil end
activeStates.BGSI_Lite_MemoryOptimizer={VisitChunkers=function(visitor)visitor(x);visitor(y)end}
'''+statement('function patchEggChunkerModule(')+r'''
assert(patchEggChunkerModule());time=40;assert(patchEggChunkerModule())
assert(gcCalls==0,'Tracked native Update instances replace heap discovery completely')
print('Egg scanner: weak registry, stable IDs across holes, deduplication and no heap discovery: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as directory:
    p=Path(directory)/'memory.lua';p.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
