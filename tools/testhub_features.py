"""Replace the legacy mouse-click box opener and install selected Larplite features."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
def enhance(source):
    # A donation cooldown is only a server limit. Renew after the full blessing expires.
    source=source.replace('    if remaining >= 86400 then return nil end', '    if tonumber(state.ShrineBlessingEndTime)==nil or remaining > 0 then return nil end',1)
    source=source.replace('when the cooldown is ready and the blessing timer has room.', 'only after the blessing expires.',2)
    source=source.replace('Keeps the blessing timer topped up when donations are allowed; checks immediately, then every 15 seconds.', 'Renews after the blessing expires; avoids spending items on active blessings.',2)
    source=source.replace('InfoTab:Section({ Title = "Discord" })','if type(onTestHubSetupConfigs)=="function" then onTestHubSetupConfigs(InfoTab) end\nInfoTab:Section({ Title = "Discord" })',1)
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
    competition_installer='''
    do
        local ok,err=pcall(function()
            local storage=game:GetService("ReplicatedStorage")
            local good,competition=pcall(require,storage.Shared.Data:FindFirstChild("PinkVsBlue"))
            local install=(function()
COMPETITION
            end)()
            local event=storage.Shared.Framework.Network.Remote.RemoteEvent
            install({Window=Window,Settings=getgenv().HubSettings,Save=saveHubSettings,
                Profile=require(storage.Client.Framework.Services.LocalData),
                Competition=good and competition or nil,UserId=Players.LocalPlayer.UserId,
                Active=function() return runtime.Active end,Now=os.clock,
                Signal=event.OnClientEvent,Connect=runtime.Connect,
                Fire=function(...) event:FireServer(...) end,
                Restore=function(callback) table.insert(runtime.Restore,callback) end,
                NativeOpen=function()
                    local screen=Players.LocalPlayer.PlayerGui:FindFirstChild("ScreenGui")
                    local frame=screen and screen:FindFirstChild("PinkVsBlue")
                    return frame and frame.Visible==true
                end,
                CreateLeaderboard=function() return WindUI:CreateCompetitionPopup({}) end,
            })
        end)
        if not ok then WindUI:ModuleFailed("Comp: "..tostring(err)) end
    end
'''.replace('COMPETITION',(ROOT/'testhub_src/competition.lua').read_text(encoding='utf-8'))
    shop_installer='''
    do
        local ok,err=pcall(function()
            local storage=game:GetService("ReplicatedStorage")
            local install=(function()
PENGUIN_SHOP
            end)()
            install({Window=Window,Settings=getgenv().HubSettings,Save=saveHubSettings,
                Shops=require(storage.Shared.Data.Shops),ShopUtil=require(storage.Shared.Utils.ShopUtil),
                ItemUtil=require(storage.Shared.Utils.Stats.ItemUtil),Player=Players.LocalPlayer,
                Profile=require(storage.Client.Framework.Services.LocalData),
                Active=function()return runtime.Active end,Now=os.clock,
                Fire=function(...)storage.Shared.Framework.Network.Remote.RemoteEvent:FireServer(...)end,
            })
        end)
        if not ok then WindUI:ModuleFailed("Penguin Shop: "..tostring(err)) end
    end
'''.replace('PENGUIN_SHOP',(ROOT/'testhub_src/penguin-shop.lua').read_text(encoding='utf-8'))
    source=source.replace('    print("[Hub] All repository modules initialized.")',installer+competition_installer+shop_installer+'    print("[Hub] All repository modules initialized.")')
    return source
