"""Run the real Winter Altar tab and worker against a mock inventory and altar remote."""
from pathlib import Path
import subprocess
import tempfile
from tree_sitter import Language, Parser
import tree_sitter_luau

ROOT = Path(__file__).resolve().parents[1]
parser = Parser(Language(tree_sitter_luau.language()))
lite_path = ROOT / 'larplite.lua'
if not lite_path.exists():
    lite_path = ROOT / 'src/larplite.lua'
source_bytes = lite_path.read_text(encoding='utf-8').encode('utf-8')

marker = b'-- Winter Altar\n--\n-- The altar only accepts'
start = source_bytes.index(marker)
nodes = parser.parse(source_bytes).root_node.named_children
worker = next(
    n for n in nodes
    if n.text.decode().startswith('task.spawn(function()')
    and '"UseRebirthMachine", "WinterAltar"' in n.text.decode()
)
# Everything the feature is made of, verbatim: helpers, tab controls, worker loop.
feature = source_bytes[start:worker.end_byte].decode('utf-8')
helper = next(
    n.text.decode() for n in nodes
    if n.text.decode().startswith('function fireRemoteEventRepeatedly')
)

SETUP = r'''
local PETS = {
 ["Icetide Passerine"]={Rarity="Secret"},
 ["Blizzard Kitsune"]={Rarity="Secret"},
 ["OG Blizzard Bell"]={Rarity="Secret"},
 ["Ice Queen Seal"]={Rarity="Secret",Celestial=true},
 ["Fire King"]={Rarity="Secret"},
 ["Snow Mole"]={Rarity="Legendary"},
 ["Danger of the Blizzard"]={Rarity="Secret",Infinity=true},
}
local WINTER={Enabled=true,DisplayName="Winter Altar",NumPetsRequired=3,AllowCelestial=true,
 CooldownKey="NextWinterAltarUse",
 ManualPets={"Icetide Passerine","Blizzard Kitsune","OG Blizzard Bell","Ice Queen Seal"},
 SpecialCombinations={{Item="Danger of the Blizzard",
  Pets={"Ice Queen Seal","Ice Queen Seal","Ice Queen Seal"}}}}
-- Mirrors ReplicatedStorage.Shared.Utils.RebirthMachineUtil's own rules.
local MACHINES={WinterAltar=WINTER,RebirthMachine={Enabled=true,NumPetsRequired=5,
 AllowCelestial=true,CooldownKey="NextRebirthMachineUse",SpecialCombinations={}}}
local rebirthUtil={Variant={Normal=0,Shiny=1,Mythic=2,ShinyMythic=3}}
function rebirthUtil.GetMachine(_,name)return MACHINES[name]end
function rebirthUtil.IsPetEligible(_,name,pet)
 local machine,info=MACHINES[name],PETS[pet.Name]
 if not machine or not info then return false end
 if info.Rarity~="Secret" or info.Infinity or info.Void or info.AdminAbuse then return false end
 if info.Celestial and not machine.AllowCelestial then return false end
 if machine.ManualPets and table.find(machine.ManualPets,pet.Name)==nil then return false end
 return true
end
local function matches(selected,combination)
 if #selected~=#combination.Pets then return false end
 local need={}
 for _,petName in combination.Pets do need[petName]=(need[petName] or 0)+1 end
 for _,pet in selected do
  local left=need[pet.Name]
  if not left or left==0 then return false end
  need[pet.Name]=left-1
 end
 return true
end
function rebirthUtil.CanFuse(_,name,selected)
 local machine=MACHINES[name]
 if not machine then return false end
 if #selected==machine.NumPetsRequired then return true end
 for _,combination in machine.SpecialCombinations do
  if matches(selected,combination) then return true end
 end
 return false
end

local now=1000
local inventory={}
local profile={Pets=inventory,NextWinterAltarUse=0,NextRebirthMachineUse=0}
local profileReady=true
local Config={WinterAltarEnabled=false,WinterAltarPets={},RebirthVariants={"Normal"},
 RebirthMachineEnabled=false,AdminRebirthMachineEnabled=false,autoHalloweenRebirth=false,
 safeMode=false}
local saves=0
local function saveConfig()saves+=1 end
local profileStore={IsReady=function()return profileReady end,Get=function()return profile end}
local function getCurrentTimestamp()return now end
local function tick()return now end
local function isCurrentRun()return true end
local workerThread
local task={spawn=function(fn)workerThread=coroutine.create(fn)end,wait=coroutine.yield,
 defer=function(fn)fn()end}
local ReplicatedStorage={Shared={Utils={RebirthMachineUtil="RMU",AdminRebirthMachineUtil="ARMU",
 HalloweenRebirthUtil="HRU"},Data={Pets="PETS"}}}
local function require(target)
 if target=="RMU" then return rebirthUtil end
 if target=="PETS" then return PETS end
 error("unexpected require")
end
local altarModel={Name="WinterAltar"}
function altarModel:FindFirstChild()return nil end
local Workspace={FindFirstChild=function(_,name)
 if name=="WinterAltar" then return altarModel end
 return nil
end}
local CollectionService={GetTagged=function()return{}end}
local LocalPlayer={Character=nil}
local function teleportToCFrame()return false end
local activeStates={BGSI_Lite_BubbleQuestActive=false,
 BGSI_Lite_GetInstanceTargetCFrame=function()return nil end}

local fuses={}
local fuseVariants={}
-- The worker calls the remote inside pcall, so a violation is recorded rather than
-- raised - an assert here would be swallowed and reported as some later symptom.
local violations={}
local remoteFunction={InvokeServer=function(_,action,machineName,ids)
 assert(action=="UseRebirthMachine","unexpected remote action: "..tostring(action))
 assert(machineName=="WinterAltar","unexpected machine: "..tostring(machineName))
 if now<(tonumber(profile.NextWinterAltarUse) or 0) then
  table.insert(violations,"fused while the altar was cooling down")
 end
 local names,variants={},{}
 for index,id in ids do
  local pet=inventory[id]
  assert(pet,"fused an id that is not in the inventory: "..tostring(id))
  names[index]=pet.Name
  variants[index]=(pet.Shiny and "Shiny" or "").. (pet.Mythic and "Mythic" or "")
  if variants[index]=="" then variants[index]="Normal" end
 end
 table.insert(fuses,names)
 table.insert(fuseVariants,variants)
 profile.NextWinterAltarUse=now+1200
 return "King Snowball"
end}
local remoteEvent={FireServer=function()end}

-- Tab control stubs: capture what the real controls were handed.
local dropdownValues,dropdownDefault,toggleDefault,statusText,refreshButton={},nil,nil,nil,nil
local dropdownCallback
local scriptStateGB={}
function scriptStateGB:AddSection()end
function scriptStateGB:AddDropdown(flag,properties)
 assert(flag=="WinterAltarPets",flag)
 dropdownValues=properties.Values
 dropdownDefault=properties.Default
 dropdownCallback=properties.Callback
 assert(properties.Multi==true,"altar pets must be multi-select")
 local control={}
 function control:SetValues(values)dropdownValues=values end
 return control
end
function scriptStateGB:AddButton(properties)refreshButton=properties.Callback end
function scriptStateGB:AddToggle(flag,properties)
 assert(flag=="AutoWinterAltar",flag)
 toggleDefault=properties.Default
 return{}
end
function scriptStateGB:AddParagraph(properties)
 statusText=properties.Content
 local control={}
 function control:SetDesc(content)statusText=content end
 return control
end
local function addPet(id,name,extra)
 local pet={Id=id,Name=name}
 for key,value in (extra or {})do pet[key]=value end
 inventory[id]=pet
 return pet
end
local function pump()
 local ok,err=coroutine.resume(workerThread)
 assert(ok,tostring(err))
end
local function select(...)
 Config.WinterAltarPets={...}
end
'''

CHECKS = r'''
-- 1. The dropdown offers only supported pets this account owns, deduped and sorted.
addPet(1,"Icetide Passerine")
addPet(2,"Icetide Passerine")
addPet(3,"Ice Queen Seal")
addPet(4,"Ice Queen Seal")
addPet(5,"Ice Queen Seal")
addPet(6,"Fire King")
addPet(7,"Snow Mole")
addPet(8,"OG Blizzard Bell",{Locked=true})
addPet(9,"Blizzard Kitsune",{XL=true})
addPet(10,"Danger of the Blizzard")
refreshButton()
assert(#dropdownValues==2,"expected 2 options, got "..#dropdownValues)
assert(dropdownValues[1]=="Ice Queen Seal" and dropdownValues[2]=="Icetide Passerine",
 "unsupported, locked, XL or unowned pets leaked into the dropdown: "..table.concat(dropdownValues,", "))
assert(toggleDefault==false,"auto altar must default to off")

-- 2. Nothing fuses while the toggle is off, even with a full selection.
select("Ice Queen Seal")
pump();pump()
assert(#fuses==0,"converted with Auto Winter Altar off")
assert(statusText:find("Ready"),"status should report readiness, got "..tostring(statusText))

-- 3. The guaranteed recipe wins over a mixed fuse: with both names selected and enough
-- of each in the inventory, the three Ice Queen Seals go in rather than any mixture.
addPet(11,"Icetide Passerine")
Config.WinterAltarEnabled=true
select("Ice Queen Seal","Icetide Passerine")
pump()
assert(#fuses==1,"expected one conversion, got "..#fuses)
assert(#fuses[1]==3,"expected three pets, got "..#fuses[1])
for _,name in fuses[1] do
 assert(name=="Ice Queen Seal",
  "expected the guaranteed Ice Queen Seal recipe, got "..table.concat(fuses[1],", "))
end

-- 4. The altar cooldown is respected, and the status says how long is left.
now+=5
pump()
assert(#violations==0,table.concat(violations,"; "))
assert(#fuses==1,"fused again during the cooldown")
assert(statusText:find("Cooldown"),"status should show the cooldown, got "..tostring(statusText))

-- 5. After the cooldown, a mixed selection converts exactly three owned pets.
now+=1200
select("Icetide Passerine","Ice Queen Seal")
pump()
assert(#fuses==2,"expected a second conversion once the cooldown expired")
assert(#fuses[2]==3,"expected three pets per conversion, got "..#fuses[2])
for _,name in fuses[2] do
 assert(name=="Icetide Passerine" or name=="Ice Queen Seal","fused an unselected pet: "..name)
end

-- 6. Variant choice is honoured: Shiny uses only shiny pets, and never mixes variants.
now+=1200
inventory={} ;profile.Pets=inventory
addPet(21,"Blizzard Kitsune",{Shiny=true})
addPet(22,"Blizzard Kitsune",{Shiny=true})
addPet(23,"Blizzard Kitsune",{Shiny=true})
addPet(24,"Blizzard Kitsune")
addPet(25,"Blizzard Kitsune",{Mythic=true})
Config.RebirthVariants={"Shiny"}
select("Blizzard Kitsune")
pump()
assert(#fuses==3,"expected a shiny conversion")
for index,name in fuses[3] do
 assert(name=="Blizzard Kitsune",name)
 assert(fuseVariants[3][index]=="Shiny",
  "the altar needs one variant; got "..table.concat(fuseVariants[3],", "))
end

-- 7. Too few pets of the chosen variant means no conversion, even when pets of other
-- variants would make up the count.
now+=1200
inventory={} ;profile.Pets=inventory
addPet(31,"Blizzard Kitsune",{Shiny=true})
addPet(32,"Blizzard Kitsune",{Shiny=true})
addPet(33,"Blizzard Kitsune")
addPet(34,"Blizzard Kitsune",{Mythic=true})
pump()
assert(#fuses==3,"converted with fewer than three pets of the chosen variant")

-- 8. With nothing selected the worker idles and says so.
select()
pump()
assert(statusText=="Select altar pets to begin.","idle status missing, got "..tostring(statusText))
assert(#fuses==3,"converted with no pets selected")

-- 9. The saved selection is what the dropdown restores, and callbacks persist it.
dropdownCallback({"Ice Queen Seal","Icetide Passerine"})
assert(saves>0,"selecting pets must save the config")
assert(Config.WinterAltarPets[1]=="Ice Queen Seal","selection not stored")

-- 10. The placeholder option is never treated as a pet.
Config.WinterAltarPets={"(None owned)"}
pump()
assert(statusText=="Select altar pets to begin.","placeholder was treated as a selection")
assert(#fuses==3,"placeholder triggered a conversion")

-- 11. Eligibility comes from the game's own rule, not just the supported-name list:
-- when the altar stops allowing Celestials, the Celestial pet leaves the dropdown.
inventory={} ;profile.Pets=inventory
addPet(41,"Ice Queen Seal")
addPet(42,"Blizzard Kitsune")
refreshButton()
assert(#dropdownValues==2,"expected both pets while Celestials are allowed")
WINTER.AllowCelestial=false
refreshButton()
assert(#dropdownValues==1 and dropdownValues[1]=="Blizzard Kitsune",
 "a pet the altar rejects stayed selectable: "..table.concat(dropdownValues,", "))
WINTER.AllowCelestial=true
assert(#violations==0,table.concat(violations,"; "))
print("Winter Altar: dropdown contents, eligibility, recipe preference, cooldown, variants, idle states: PASS")
'''


def main():
    code = SETUP + helper + '\n' + feature + '\n' + CHECKS
    with tempfile.TemporaryDirectory() as directory:
        path = Path(directory) / 'winter_altar.lua'
        path.write_text(code, encoding='utf-8')
        luau = ROOT / '.tools/luau/luau.exe'
        import os
        luau = os.environ.get('LUAU', str(luau))
        result = subprocess.run([luau, str(path)], capture_output=True, text=True)
        assert result.returncode == 0, result.stdout + result.stderr
        print(result.stdout.strip())


if __name__ == '__main__':
    main()
