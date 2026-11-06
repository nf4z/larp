"""Config discovery: schemas, Windows/root API quirks, metadata-only UI, rescan and unavailable APIs."""
from pathlib import Path
import subprocess,tempfile
ROOT=Path(__file__).resolve().parents[1]
module=(ROOT/'testhub_src/config-discovery.lua').read_text(encoding='utf-8')
code=r'''
local install=(function()
'''+module+r'''
end)()
local files={
    ['1rzHubLiteConfig_111.json']='larp-own',
    ['1rzHubLiteConfig_222.json']='larp-other',
    ['qtrzip_settings.json']='qtrzip',
    ['custom_config.json']='custom',
    ['bad_settings.json']='bad',
    ['unknown_config.json']='unknown',
    ['huge_settings.json']=string.rep('x',1024*1024+1),
    ['not_a_config.png']='ignore',
}
local decoded={
    ['larp-own']={autoHatch=true,selectedEgg='SECRET_VALUE',webhookURL='SECRET_URL'},
    ['larp-other']={autoBubble=false,autoOpenMystery=true,webhookURL='SECRET_URL'},
    ['qtrzip']={auto={autoBubble=true},eggs={selectedEgg='SECRET_VALUE'},webhook={hatchURL='SECRET_URL'}},
    ['custom']={autoHatch=true,selectedEgg='SECRET_VALUE'},
    ['unknown']={someValue='SECRET_VALUE'},
}
local listing={}
for name in pairs(files) do table.insert(listing,[[C:\Game\workspace\]]..name) end
local readCount=0
local ctx={UserId=111,List=function(root) if root=='.' then return {} end;return listing end,
    Read=function(path) readCount+=1;assert(not path:find('\\',1,true),'relative API');assert(files[path],'missing');return files[path] end,
    IsFile=function(path) return files[path]~=nil end,
    Decode=function(raw) assert(decoded[raw],'malformed JSON');return decoded[raw] end}
local detector=install(ctx)
local records,note=detector:Scan()
assert(#records==7 and note==nil and records[1].Name=='qtrzip_settings.json' and records[2].Name=='1rzHubLiteConfig_111.json')
local map={};for _,record in ipairs(records) do map[record.Name]=record end
assert(map['1rzHubLiteConfig_111.json'].Kind=='Larplite' and map['1rzHubLiteConfig_222.json'].Account=='222')
assert(map['qtrzip_settings.json'].Kind=='@qtrzip' and #map['qtrzip_settings.json'].Sections==3 and map['qtrzip_settings.json'].Count==3)
assert(map['custom_config.json'].Kind=='Larplite')
assert(map['unknown_config.json'].Issue=='Unrecognized config format.')
assert(map['bad_settings.json'].Issue=='Invalid JSON settings object.')
assert(map['huge_settings.json'].Issue)
local function noValues(value)
    if type(value)=='table' then for k,v in pairs(value) do assert(k~='data' and k~='Raw' and k~='Values');noValues(v) end
    elseif type(value)=='string' then assert(not value:find('SECRET',1,true),'Never retain config values') end
end
noValues(records)
local previous=readCount
listing={'qtrzip_settings.json',[[C:\Game\workspace\qtrzip_settings.json]]}
assert(#detector:Scan()==1 and readCount==previous+1,'Deduplicate alternative root listings')
ctx.List=nil
local fallback,note=detector:Scan();assert(#fallback==2 and note:find('listing unavailable',1,true))
ctx.Read=nil;local none,why=detector:Scan();assert(#none==0 and why:find('unavailable',1,true))
-- UI metadata/rescan keeps valid selection and never applies settings or displays secrets.
ctx.Read=function(path) return assert(files[path]) end;ctx.IsFile=nil
listing={'qtrzip_settings.json','1rzHubLiteConfig_111.json','1rzHubLiteConfig_222.json'}
ctx.List=function() return listing end
local controls={}
local tab={}
for _,kind in ipairs({'Section','Paragraph','Dropdown','Button'}) do tab[kind]=function(_,props)
    local c={Props=props,Desc=props.Desc,Values=props.Values}
    function c:SetDesc(value) self.Desc=value end
    function c:Refresh(values) self.Values=values end
    function c:Select(value) self.Value=value end
    controls[props.Title]=c;return c
end end
ctx.Tab=tab
local ui=install(ctx)
assert(#ui.Records==3 and controls['Config File'].Value=='qtrzip_settings.json')
assert(controls.Format.Desc:find('active settings file',1,true))
controls['Config File'].Props.Callback('1rzHubLiteConfig_222.json')
assert(controls.Account.Desc=='Other account: 222')
controls['Rescan Configs'].Props.Callback();assert(controls['Config File'].Value=='1rzHubLiteConfig_222.json')
listing={'qtrzip_settings.json'};controls['Rescan Configs'].Props.Callback();assert(controls['Config File'].Value=='qtrzip_settings.json')
for _,c in pairs(controls) do if c.Desc then noValues(c.Desc) end end
assert(decoded['qtrzip'].webhook.hatchURL=='SECRET_URL' and decoded['larp-own'].selectedEgg=='SECRET_VALUE','Discovery does not alter configs')
print('Detected Configs: Larplite/account and nested qtrzip schemas, Windows/root fallback, metadata only, invalid/oversized JSON, API errors and selection-preserving rescan: PASS (offline)')
'''
with tempfile.TemporaryDirectory() as directory:
    p=Path(directory)/'configs.lua';p.write_text(code,encoding='utf-8')
    result=subprocess.run([str(ROOT/'.tools/luau/luau.exe'),str(p)],text=True,capture_output=True)
    assert result.returncode==0,result.stdout+result.stderr
    print(result.stdout.strip())
