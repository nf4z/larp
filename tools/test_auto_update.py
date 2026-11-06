"""Exercise update polling, staging, cancellation and actual reload/rollback scheduling offline."""
from pathlib import Path
import json,tempfile,subprocess,hashlib
ROOT=Path(__file__).resolve().parents[1]
module=(ROOT/'testhub_src/auto-update.lua').read_text(encoding='utf-8')
source=(ROOT/'bgsiscript').read_text(encoding='utf-8')
a=source.index('        Queue=function(chunk,rollback,revision)')
b=source.index('\n        end,\n    })',a)+len('\n        end')
queue=source[a:b].strip().removeprefix('Queue=')
code=r'''
local jobs={}
local task={spawn=function(fn) local thread=coroutine.create(fn);table.insert(jobs,thread);return thread end,wait=function() coroutine.yield() end}
local install=(function()
'''+module+r'''
end)()
local oldSource='local runtime = {Starting = true, Revision = 19, ScriptVersion = "v104"};return runtime'
local newSource='local runtime = {Starting = true, Revision = 20, ScriptVersion = "v105"};return runtime'
local function fixture()
    local state={active=true,fetches=0,queued=0,saves=0,controls={},compiled=0}
    local tab={}
    for _,kind in ipairs({'Section','Paragraph','Toggle','Button'}) do tab[kind]=function(_,props)
        local control={Props=props};function control:SetDesc(value) self.Desc=value end
        state.controls[props.Title]=control;return control
    end end
    local ctx={Settings={},Tab=tab,Version='v104',Revision=19,CurrentPath='releases/bgsiscript/v104-r19.lua',
        Active=function() return state.active end,Save=function() state.saves+=1 end,
        Manifest=function() return state.manifest end,
        Fetch=function(path) state.fetches+=1;if state.fetchHook then state.fetchHook(path) end;return path== 'releases/bgsiscript/v105-r20.lua' and state.nextSource or oldSource end,
        Compile=function(text) state.compiled+=1;return loadstring(text) end,
        CanApply=function(_,manual) return manual or not state.cooldown end,
        Queue=function(new,old,revision) state.queued+=1;assert(type(new)=='function' and type(old)=='function' and revision==20);return true end}
    state.manifest={schema=1,version='v104',revision=19,path=ctx.CurrentPath}
    state.nextSource=newSource
    state.ctx=ctx;state.updater=install(ctx)
    return state
end
local function newer(s) s.manifest={schema=1,version='v105',revision=20,path='releases/bgsiscript/v105-r20.lua'} end
local s=fixture();assert(s.ctx.Settings.enabled==true)
local ok,reason=s.updater:Check(false);assert(ok and reason=='current' and s.fetches==0 and s.queued==0)
s.manifest.revision=18;s.manifest.version='v103';s.manifest.path='releases/bgsiscript/v103-r18.lua'
assert(s.updater:Check(false) and s.fetches==0,'Never downgrade')
s=fixture();newer(s);local ok,reason=s.updater:Check(false)
assert(ok and reason=='queued' and s.fetches==2 and s.compiled==2 and s.queued==1 and s.saves==1,'Stage release and rollback before queueing')
s=fixture();newer(s);s.controls['Auto Update'].Props.Callback(false)
assert(not s.ctx.Settings.enabled and s.saves==1);local ok,why=s.updater:Check(false);assert(ok and why=='disabled' and s.fetches==0)
s.controls['Check For Updates'].Props.Callback();assert(s.queued==1,'Manual check works with automation disabled')
s=fixture();newer(s);s.nextSource='local runtime = {Starting = true, Revision = 20, ScriptVersion = "v105"}; !!!'
assert(not s.updater:Check(false) and s.queued==0 and s.fetches==1,'Compile failure leaves current script alone')
s=fixture();newer(s);s.nextSource=oldSource
assert(not s.updater:Check(false) and s.compiled==0 and s.queued==0,'Reject stale or mismatched release bytes')
s=fixture();newer(s);s.fetchHook=function(path) if path==s.ctx.CurrentPath then error('backup offline') end end
assert(not s.updater:Check(false) and s.queued==0,'Do not unload without a staged rollback')
s=fixture();newer(s);s.fetchHook=function() s.ctx.Settings.enabled=false end
local ok,reason=s.updater:Check(false);assert(ok and reason=='cancelled' and s.queued==0)
s=fixture();newer(s);s.fetchHook=function() s.active=false end
local ok,reason=s.updater:Check(true);assert(ok and reason=='cancelled' and s.queued==0,'Unloading during download cancels reload')
s=fixture();newer(s);s.cooldown=true
local ok,reason=s.updater:Check(false);assert(ok and reason=='cooldown' and s.fetches==0)
assert(s.updater:Check(true) and s.queued==1,'Manual check overrides failed-release cooldown')
s=fixture();newer(s);s.ctx.Busy=function() return true end
local ok,reason=s.updater:Check(false);assert(ok and reason=='pending' and s.fetches==0 and s.queued==0 and s.updater.RetryDelay==5)
s=fixture();newer(s);s.ctx.Busy=function() return s.fetches>0 end
local ok,reason=s.updater:Check(true);assert(ok and reason=='pending' and s.queued==0,'Do not interrupt accepted hatch work arriving during download')
s=fixture();s.manifest={}
for _=1,4 do assert(not s.updater:Check(false)) end
assert(s.updater.RetryDelay==900 and not s.updater.Busy,'Failures back off and release busy lock')
s=fixture();newer(s);local original=s.ctx.Manifest
s.ctx.Manifest=function() local ok,why=s.updater:Check(true);assert(not ok and why=='busy');return original() end
assert(s.updater:Check(true) and s.queued==1,'No overlapping checks')
'''
# The real scheduler is extracted from bgsiscript rather than reimplemented in the test.
code+=r'''
local function schedulerFixture()
    local deferred={}
    local selected,closed=false,false
    local function window()
        return {Opened=false,Native={Position=42},Tabs={{Title='Eggs',Page={Visible=true}}},TabsByTitle={Eggs={Select=function() selected=true end}},Close=function() closed=true end}
    end
    local runtime={Active=true,Revision=19,UI={Window=window()}}
    local private={HubSettings={updates={enabled=true},auto={keep=true}}}
    local actualGlobals={_BGSI_TestHub=runtime}
    local realTask={defer=function(fn) table.insert(deferred,fn) end}
    local warnings={}
    local function warn(value) table.insert(warnings,value) end
    local queue=
'''+queue+r'''
    return {runtime=runtime,globals=actualGlobals,queue=queue,window=window,
        flush=function() assert(#deferred==1);deferred[1]() end,
        restored=function() return selected and closed end,warnings=warnings}
end
local f=schedulerFixture();local ran=0
assert(f.queue(function() assert(f.globals._BGSI_UpdateSettings.settings.auto.keep and f.globals._BGSI_UpdateSettings.revision==20);ran+=1;f.runtime.Active=false;f.globals._BGSI_TestHub={Revision=20,Active=true,UI={Window=f.window()}} end,function() error('rollback should not run') end,20))
assert(ran==0,'Replacement must be deferred on the original scheduler')
f.flush();assert(f.globals._BGSI_UpdateSettings==nil);assert(ran==1 and f.restored() and f.globals._BGSI_TestHub.UI.Window.Native.Position==42)
f=schedulerFixture();local failedUnload=false
f.queue(function()
    f.globals._BGSI_UpdateSettings.settings.auto.keep=false;f.runtime.Active=false;f.globals._BGSI_TestHub={Revision=20,Active=true,Unload=function() failedUnload=true end};error('release startup failed')
end,function() assert(f.globals._BGSI_UpdateSettings.revision==19 and f.globals._BGSI_UpdateSettings.settings.auto.keep);f.globals._BGSI_TestHub={Revision=19,Active=true,UI={Window=f.window()}} end,20)
f.flush();assert(failedUnload and f.globals._BGSI_TestHub.Revision==19 and f.globals._BGSI_AutoUpdateFailure.revision==20 and f.restored())
f=schedulerFixture();f.queue(function() error('header failed before unloading') end,function() assert(not f.runtime.UpdateQueued);f.globals._BGSI_TestHub=f.runtime end,20)
f.flush();assert(not f.runtime.UpdateQueued and f.runtime.Active)
f=schedulerFixture();f.queue(function() error('must not run') end,function() error('must not run') end,20)
f.runtime.Active=false;f.flush();assert(#f.warnings==0,'Unload cancels a queued update')
f=schedulerFixture();local restored=false
f.queue(function() return nil end,function() restored=true;f.globals._BGSI_TestHub=f.runtime end,20);f.flush();assert(restored,'A non-initializing release rolls back')
print('Auto-update: manifest-only polling, staged source/rollback, no downgrade, toggles/manual checks, errors/backoff, overlap/unload cancellation and real reload/rollback scheduler: PASS (offline)')
'''
manifest=json.loads((ROOT/'bgsiscript-version.json').read_text())
assert (ROOT/manifest['path']).read_bytes()==(ROOT/'bgsiscript').read_bytes()
assert hashlib.sha256((ROOT/'bgsiscript').read_bytes()).hexdigest()==manifest['sha256']
with tempfile.TemporaryDirectory() as directory:
    p=Path(directory)/'updates.lua';p.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
    if result.returncode:
        import re
        match=re.search(r'updates.lua:(\d+)',result.stderr)
        if match:
            n=int(match[1]);print('\n'.join(f'{i+1}: {line[:180]}' for i,line in enumerate(code.splitlines()) if abs(i+1-n)<3))
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
