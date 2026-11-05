"""Replace the legacy mouse-click box opener and install selected Larplite features."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def enhance(source):
    # Restrict discovery to real catalog/tagged eggs, never visual lock helpers.
    source=source.replace('        local lower = name:lower()\n        -- Imported mesh', '        local lower = name:lower()\n        if lower:find("egglock", 1, true) or lower:find("template", 1, true) or lower:find("hitbox", 1, true) then return false end\n        -- Imported mesh')
    source=source.replace('\n            or lower:find("egg", 1, true) ~= nil', '')
    a=source.index('local function getInventoryEggs()')
    b=source.index('-- Shared chunk/render scanner;',a)
    source=source[:a]+'''local function getInventoryEggs()
    local eggs = {}
    local catalog = require(ReplicatedStorage.Shared.Data.Powerups)
    local current = LocalData:Get()
    for name, info in pairs(catalog) do
        if type(info)=="table" and info.Type=="Egg" and (tonumber(current and current.Powerups and current.Powerups[name]) or 0)>0 then
            table.insert(eggs,name)
        end
    end
    table.sort(eggs)
    return eggs
end

'''+source[b:]
    source=source.replace('EggsTab:Dropdown({\n    Title = "Select Inventory Egg",', 'local inventoryEggDropdown = EggsTab:Dropdown({\n    Title = "Select Inventory Egg",')
    source=source.replace('        selectedInventoryEgg = inventoryEggList[1]\n        local text', '''        if not table.find(inventoryEggList,selectedInventoryEgg) then selectedInventoryEgg=inventoryEggList[1] or "" end
        inventoryEggDropdown:Refresh(inventoryEggList)
        inventoryEggDropdown:Select(selectedInventoryEgg,true)
        eggSettings.inventoryEgg=selectedInventoryEgg;saveHubSettings()
        local text''')
    source=source.replace('eggDropdown:Select(selectedEgg)', 'eggDropdown:Select(selectedEgg,true)')
    source=source.replace('local selectedInventoryEgg = eggSettings.inventoryEgg or inventoryEggList[1] or "Dominus Egg"', 'local selectedInventoryEgg = table.find(inventoryEggList,eggSettings.inventoryEgg) and eggSettings.inventoryEgg or inventoryEggList[1] or ""')
    a=source.index('local function getBoxes()')
    b=source.index('-- ======================================\n-- FUNCTIONS',a)
    source=source[:a]+source[b:]
    a=source.index('local function startAutoBox()')
    b=source.index('local function startAutoDaily()',a)
    source=source[:a]+source[b:]
    a=source.index('AutoTab:Section({ Title = "Auto Open Box" })')
    b=source.index('AutoTab:Section({ Title = "Fishing" })',a)
    source=source[:a]+source[b:]
    source=source.replace('    if autoSettings.autoOpenBox then startAutoBox() end','')
    installer='''
    do
        local ok,err=pcall(function()
            local storage=game:GetService("ReplicatedStorage")
            local function optional(module) local good,value=pcall(require,module);return good and value or nil end
            local install=(function()
EXTRAS
            end)()
            install({Window=Window,Settings=getgenv().HubSettings,Save=saveHubSettings,
                Profile=require(storage.Client.Framework.Services.LocalData),
                Powerups=require(storage.Shared.Data.Powerups),
                ItemUtil=optional(storage.Shared.Utils.Stats.ItemUtil),
                PhysicalItem=optional(storage.Client.Effects.PhysicalItem),
                Condenser=optional(storage.Shared.Data:FindFirstChild("BoxCondenser")),
                MaxGifts=math.max(1,math.floor(tonumber(require(storage.Shared.Constants).MaxSpawnableLimit) or 25)),
                Active=function() return runtime.Active end,Now=os.clock,
                Fire=function(...) storage.Shared.Framework.Network.Remote.RemoteEvent:FireServer(...) end,
                Condense=function()
                    local player=Players.LocalPlayer
                    local root=player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                    local ok,target=pcall(function()
                        local machine=workspace.Worlds["The Overworld"].Islands.Zen.Island.BoxCondenser
                        local activation=machine:FindFirstChild("Activation") or machine
                        return activation:IsA("BasePart") and activation.CFrame or activation:GetPivot()
                    end)
                    if not root or not ok then return false,"Visit Zen Island to load the condenser." end
                    local position=root.CFrame
                    root.CFrame=target
                    local fired,reason=pcall(function() storage.Shared.Framework.Network.Remote.RemoteEvent:FireServer("CondenseMysteryBox",false) end)
                    root.CFrame=position
                    return fired,reason
                end,
                PlaceId=game.PlaceId,JobId=game.JobId,Copy=setclipboard or toclipboard,
                Join=function(id) game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId,id,Players.LocalPlayer) end,
                FindServer=function()
                    local best,cursor=nil,nil
                    for _=1,3 do
                        if not runtime.Active then return nil end
                        local url="https://games.roblox.com/v1/games/"..game.PlaceId.."/servers/Public?sortOrder=Asc&limit=100"
                        if cursor then url..="&cursor="..HttpService:UrlEncode(cursor) end
                        local page=HttpService:JSONDecode(game:HttpGet(url))
                        for _,server in ipairs(page.data or {}) do
                            if server.id~=game.JobId and server.playing<server.maxPlayers and (not best or server.playing<best.playing) then best=server end
                        end
                        cursor=page.nextPageCursor;if not cursor or best then break end
                    end
                    return best and best.id
                end,
            })
        end)
        if not ok then WindUI:ModuleFailed("Larplite extras: "..tostring(err)) end
    end
'''.replace('EXTRAS',(ROOT/'testhub_src/extras.lua').read_text(encoding='utf-8'))
    source=source.replace('    print("[Hub] All repository modules initialized.")',installer+'    print("[Hub] All repository modules initialized.")')
    return source
