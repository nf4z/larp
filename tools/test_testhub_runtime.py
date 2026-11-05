"""Exercise ownership, pending jobs, cancellation, restoration, and repeated unload."""
from pathlib import Path
import subprocess
import tempfile
ROOT = Path(__file__).resolve().parents[1]
runtime = (ROOT / 'testhub_src/runtime.lua').read_text(encoding='utf-8')
code = r'''
local jobs, cancelled = {}, {}
local function enqueue(fn,...)
    local co=coroutine.create(fn)
    jobs[co]=table.pack(...)
    return co
end
local task={spawn=enqueue,defer=enqueue,delay=function(_,fn,...) return enqueue(fn,...) end,
    cancel=function(co) cancelled[co]=true;jobs[co]=nil;coroutine.close(co) end,
    wait=function() coroutine.yield() end}
local created={}
local Instance={new=function(class)
    local object={ClassName=class,Destroyed=false}
    function object:Destroy() self.Destroyed=true end
    table.insert(created,object);return object
end}
local runtime,private,actualGlobals={},{},{}
actualGlobals._BGSI_TestHub=runtime
local warns={}
local function warn(message) table.insert(warns,message) end
''' + runtime + r'''
local calls=0
local function pump(co)
    local arguments=jobs[co];jobs[co]=nil
    local ok,err=coroutine.resume(co,table.unpack(arguments,1,arguments.n));assert(ok,tostring(err))
end
local worker=ownedTask.spawn(function() calls+=1;task.wait();calls+=100 end)
pump(worker);assert(calls==1 and runtime.Threads[worker])
local pending=ownedTask.delay(10,function() calls+=1000 end)
local deferred=ownedTask.defer(function() calls+=10000 end)
local complete=ownedTask.spawn(function(a,b) assert(a==12 and b==34);calls+=1 end,12,34)
pump(complete);assert(runtime.Threads[complete]==nil)
local listeners={}
local signal={Connect=function(_,fn)
    table.insert(listeners,fn)
    return {Disconnect=function(self) self.disconnected=true end}
end}
local conn=runtime.Connect(signal,function() calls+=1 end)
listeners[1]();assert(calls==3)
local native={Material='original',Parent=nil,Enabled=true,Play=function() return 'game' end}
local originalPlay=native.Play
runtime.Set(native,'Material','plastic');runtime.Set(native,'Material','smooth')
runtime.Set(native,'Parent','temporary');runtime.Set(native,'Enabled',false)
runtime.Remember(native,'Play');native.Play=function() return 'hub' end
local object=ownedInstance.new('ScreenGui')
local destroyed=0
runtime.UI={Destroy=function() destroyed+=1 end}
private.HubSettings={auto={enabled=true}};private.Window={};private.getgenv=function() return private end
runtime.Unload()
assert(not runtime.Active and actualGlobals._BGSI_TestHub==nil)
assert(cancelled[worker] and cancelled[pending] and cancelled[deferred])
assert(next(runtime.Threads)==nil and next(runtime.Connections)==nil)
assert(conn.disconnected and object.Destroyed and destroyed==1)
assert(native.Material=='original' and native.Parent==nil and native.Enabled and native.Play==originalPlay)
assert(next(runtime.Restore)==nil and next(runtime.Instances)==nil)
assert(private.RdotAfishingStop and private.RdotAfishingConfig.Mode=='Off')
assert(private.getgenv()==private and private.Window==nil and private.WindUI==nil)
assert(ownedTask.spawn(function() error('must not run') end)==nil)
listeners[1]();assert(calls==3)
runtime.Set(native,'Material','must not apply');assert(native.Material=='original')
runtime.Unload();assert(destroyed==1 and #warns==0)
print('Runtime unload: active/pending tasks, callbacks, instances, original properties/hooks, repeat/reload isolation: PASS')
'''
with tempfile.TemporaryDirectory() as directory:
    path=Path(directory)/'runtime.lua';path.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(path)],capture_output=True,text=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
