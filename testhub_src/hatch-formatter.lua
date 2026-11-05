-- Generated from nf4z/larp core 2f0755df109e1b92c679 (2026.11.04.41).
-- Layout, fields, icons, numbers, colors and V2 renderer are kept from Larplite.
return function(ctx)
local LocalPlayer, Players = ctx.Player, ctx.Players
local ReplicatedStorage, HttpService, game = ctx.ReplicatedStorage, ctx.HttpService, ctx.Game
local profileStore, remoteFunction = ctx.Profile, ctx.RemoteFunction
local statsUtil, worldUtil = ctx.StatsUtil, ctx.WorldUtil
local eggDataModule, sharedConstants = ctx.Eggs, ctx.Constants
local getWebhookSuperLegendaryEnchantText = ctx.EnchantText
local getEnchantedSuperWebhookIcon = ctx.EnchantIcon
local rollSimulatedSuperEnchants = ctx.RollEnchants
local activeStates = setmetatable({
    BGSI_Lite_GetHatchPetName=ctx.GetName,
    BGSI_Lite_GetHatchPetFlag=ctx.GetFlag,
    BGSI_Lite_GetHatchPetValue=ctx.GetValue,
}, {__index=ctx.ActiveStates or {}})
local scriptStateDX = {
	Bubbles = "\240\159\159\163",
	Coins = "\240\159\170\153",
	Gems = "\240\159\146\142",
	Snowflakes = "\226\157\132\239\184\143",
	CircusTickets = "\240\159\142\159\239\184\143",
	GameTickets = "\240\159\142\171",
	Tickets = "\240\159\142\171",
	Pearls = "<:Pearl:1561761464866308219>",
	Clovers = "\240\159\141\128",
}
local runShrineDonation, formatWebhookNumber, getWebhookAvatarUrl, getWebhookRequestFunction, getDiscordTimestamp, buildWebhookUserInfoField, getWebhookHatchEggName, getWebhookPetSource, getWebhookHatchChances, getPetVariantName, buildPetWebhookEmbed, sendPetWebhook, normalizeDiscordWebhookV2Url, buildDiscordV2WebhookPayload, buildSimulatedHatchPayload
function runShrineDonation(scriptStateTR)
	scriptStateTR = tonumber(scriptStateTR) or 0
	local scriptStateCS = string.format("%.0f", math.floor(scriptStateTR))
	while true do
		local scriptStateBK
		scriptStateCS, scriptStateBK = scriptStateCS:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		if scriptStateBK == 0 then
			break
		end
	end
	return scriptStateCS
end

function formatWebhookNumber(value, decimals)
	value = tonumber(value) or 0
	if value ~= value or value == math.huge or value == -math.huge then return "0" end
	local result = string.format("%." .. tostring(decimals or 0) .. "f", value)
	if decimals and decimals > 0 then
		result = result:gsub("0+$", ""):gsub("%.$", "")
	end
	local whole, fraction = result:match("^(-?%d+)(%.?%d*)$")
	if not whole then return result end
	while true do
		local grouped, count = whole:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
		whole = grouped
		if count == 0 then break end
	end
	return whole .. fraction
end

activeStates.BGSI_Lite_GetWebhookPetStatValue=function(value) return "x"..formatWebhookNumber(value,4) end
function getWebhookAvatarUrl(scriptStateWL)
	if type(scriptStateWL) ~= "number" or scriptStateWL ~= scriptStateWL then
		return "—"
	end
	return "x" .. formatWebhookNumber(scriptStateWL, 3)
end

function getWebhookRequestFunction()
	local debugSecretLuck, debugInfinityLuck
	local scriptStateUY = {
		CurrentBubbles = 0,
		Coins = 0,
		Gems = 0,
		Pearls = 0,
		Tickets = 0,
		LuckDisplay = "—",
		SecretLuckDisplay = "—",
		InfinityLuckDisplay = "—",
	}
	if type(activeStates.BGSI_Lite_GetDebugLuckDisplays) == "function" then
		pcall(function()
			debugSecretLuck, debugInfinityLuck = activeStates.BGSI_Lite_GetDebugLuckDisplays()
		end)
	end
	if debugSecretLuck then
		scriptStateUY.SecretLuckDisplay = debugSecretLuck
	end
	if debugInfinityLuck then
		scriptStateUY.InfinityLuckDisplay = debugInfinityLuck
	end
	pcall(function()
		if not profileStore:IsReady() then
			return
		end
		local scriptStateIL = profileStore:Get() or {}
		scriptStateUY.CurrentBubbles = type(scriptStateIL.Bubble) == "table"
			and (tonumber(scriptStateIL.Bubble.Amount) or 0) or 0
		scriptStateUY.Coins = tonumber(scriptStateIL.Coins) or 0
		scriptStateUY.Gems = tonumber(scriptStateIL.Gems) or 0
		scriptStateUY.Pearls = tonumber(scriptStateIL.Pearls) or 0
		scriptStateUY.Tickets = tonumber(
			scriptStateIL.Tickets or scriptStateIL.GameTickets or scriptStateIL.CircusTickets
		) or 0
		local scriptStateAAM = "The Overworld"
		if worldUtil and type(worldUtil.GetPlayerWorld) == "function" then
			pcall(function()
				scriptStateAAM = worldUtil:GetPlayerWorld(LocalPlayer) or scriptStateAAM
			end)
		end
		if statsUtil then
			pcall(function()
				if type(statsUtil.GetLuckMultiplier) == "function" then
					local scriptStateVW = statsUtil:GetLuckMultiplier(LocalPlayer, scriptStateIL, scriptStateAAM, true)
					if type(scriptStateVW) == "number" and scriptStateVW == scriptStateVW then
						scriptStateUY.LuckDisplay = "+" .. formatWebhookNumber((scriptStateVW - 1) * 100, 2) .. "%"
					end
				end
			end)
			pcall(function()
				if not debugSecretLuck and type(statsUtil.GetSecretLuck) == "function" then
					local scriptStateAAZ = statsUtil:GetSecretLuck(scriptStateIL, nil)
					if type(scriptStateAAZ) == "number" then
						scriptStateUY.SecretLuckDisplay = getWebhookAvatarUrl(scriptStateAAZ)
					end
				end
			end)
			pcall(function()
				if not debugInfinityLuck and type(statsUtil.GetInfinityLuck) == "function" then
					local scriptStateACI = (scriptStateAAM == "Christmas World") and "Aurora Egg" or nil
					local scriptStateVQ = statsUtil:GetInfinityLuck(scriptStateIL, scriptStateACI)
					if type(scriptStateVQ) == "number" then
						scriptStateUY.InfinityLuckDisplay = getWebhookAvatarUrl(scriptStateVQ)
					end
				end
			end)
		end
	end)
	return scriptStateUY
end

function getDiscordTimestamp()
	local scriptStateXG = {
		BubblesBlown = 0,
		EggsHatched = 0,
	}
	if not LocalPlayer:FindFirstChild("leaderstats") then
		return scriptStateXG
	end
	for loopSlotAS, scriptStateAFC in ipairs(LocalPlayer.leaderstats:GetChildren()) do
		if scriptStateAFC.Name == "\240\159\159\163 Bubbles" then
			scriptStateXG.BubblesBlown = scriptStateAFC.Value
		elseif scriptStateAFC.Name == "\240\159\165\154 Hatches" then
			scriptStateXG.EggsHatched = scriptStateAFC.Value
		end
	end
	return scriptStateXG
end

function buildWebhookUserInfoField()
	local stats = getWebhookRequestFunction()
	local totals = getDiscordTimestamp()
	return {
		name = "User Info",
		value = table.concat({
			"<:purple_circle:1363755750828019774> Current Bubbles: **" .. formatWebhookNumber(stats.CurrentBubbles) .. "**",
			"\240\159\170\153 Coins: **" .. formatWebhookNumber(stats.Coins) .. "**",
			"<:gem:1363755998401269854> Gems: **" .. formatWebhookNumber(stats.Gems) .. "**",
			"<:egg:1377264232915013673> Total Eggs: **" .. formatWebhookNumber(totals.EggsHatched) .. "**",
			"\240\159\141\128 Luck: **" .. tostring(stats.LuckDisplay) .. "**",
			"\226\157\147 Secret luck: **" .. tostring(stats.SecretLuckDisplay) .. "**",
			"\226\153\190 Infinity luck: **" .. tostring(stats.InfinityLuckDisplay) .. "**",
		}, "\n"),
		inline = false,
	}
end

function getWebhookHatchEggName(petEntry, petInfo, eventName, hatchResult)
	local function eggName(value)
		if type(value) == "table" then value = value.Name or value.EggName end
		if type(value) ~= "string" then return nil end
		value = value:match("^%s*(.-)%s*$")
		if value ~= "" and value ~= "Unknown" then return value end
	end
	local explicit = eggName(activeStates.BGSI_Lite_GetHatchPetValue(petEntry, {"Egg", "EggName", "SourceEgg"}))
	if explicit then return explicit end
	if (eventName == "HatchEgg" or eventName == "HatchPowerupEgg" or eventName == "ExclusiveHatch")
		and type(hatchResult) == "table" then
		local resultEgg = eggName(hatchResult.EggName) or eggName(hatchResult.Egg)
			or (type(hatchResult.Pets) == "table" and eggName(hatchResult.Name))
		if resultEgg then return resultEgg end
	end
	local metadataEgg = type(petInfo) == "table" and eggName(petInfo.Egg)
	if metadataEgg then return metadataEgg end
	local petName = activeStates.BGSI_Lite_GetHatchPetName(petEntry)
	local candidates = {}
	for name, egg in pairs(type(eggDataModule) == "table" and eggDataModule or {}) do
		if type(egg) == "table" and type(egg.Pool) == "table" then
			for _, entry in pairs(egg.Pool) do
				local item = type(entry) == "table" and entry.Item
				if type(item) == "table" and item.Type == "Pet" and item.Name == petName then
					candidates[name] = true
				end
			end
		end
	end
	local found
	for name in pairs(candidates) do
		if found then return "Unknown" end
		found = eggName(name)
	end
	return found or "Unknown"
end

function getWebhookPetSource(petEntry, petInfo, eventName, hatchResult)
	local function originValue(value)
		if type(value) ~= "string" then return nil end
		value = value:match("^%s*(.-)%s*$")
		if value == "" or value == "Unknown" then return nil end
		local lower = value:lower()
		if lower:find("season", 1, true) or lower:find("mega shop", 1, true) then
			return "Season Pass"
		end
		if lower:find("secret bounty", 1, true) then return "Bounty" end
		if lower:find("rebirth machine", 1, true) then return "Rebirth Machine" end
		if lower:find("leaderboard", 1, true) then return "Leaderboard" end
		if lower:find("competitive", 1, true) or lower:find("comp", 1, true) then
			return "Competitive"
		end
		if lower:find("global", 1, true) or lower:find("incentive", 1, true) then
			return "Global Incentive"
		end
		if lower:find("admin", 1, true) then return "Admin Abuse Egg" end
		return value
	end
	local origin = type(petInfo) == "table" and (originValue(petInfo.Origin)
		or originValue(petInfo.Origins) or originValue(petInfo.Tag)) or nil
	if not origin and type(petEntry) == "table" then
		origin = originValue(petEntry.Origin) or originValue(petEntry.Source)
	end
	if not origin and type(petInfo) == "table" and petInfo.AdminAbuse then
		origin = "Admin Abuse Egg"
	end
	local eggName = getWebhookHatchEggName(petEntry, petInfo, eventName, hatchResult)
	if eggName ~= "Unknown" then return eggName, true end
	if origin then return origin, false end
	return "Unknown", false
end

function getWebhookHatchChances(petName, petInfo, eggName, shiny, mythic, xl, super)
	local basePercent
	local egg = type(eggDataModule) == "table" and eggDataModule[eggName]
	if type(egg) == "table" and type(egg.Pool) == "table" then
		for _, entry in pairs(egg.Pool) do
			if type(entry) == "table" and type(entry.Item) == "table"
				and entry.Item.Type == "Pet" and entry.Item.Name == petName then
				basePercent = tonumber(entry.Chance)
				break
			end
		end
	end
	if basePercent == nil and type(petInfo) == "table" then
		basePercent = tonumber(petInfo.Chance)
	end
	if type(basePercent) ~= "number" or basePercent <= 0
		or basePercent ~= basePercent or basePercent == math.huge then
		return 0, 0
	end
	local constants = type(sharedConstants) == "table" and sharedConstants or {}
	local finalPercent = basePercent
	if shiny then finalPercent *= (tonumber(constants.ShinyChance) or 2.5) / 100 end
	if mythic then finalPercent *= (tonumber(constants.MythicChance) or 1) / 100 end
	if xl then
		local rarity = type(petInfo) == "table" and petInfo.Rarity or nil
		local xlDefaults = {
			Common = 0.0002, Unique = 0.00028571428571428574,
			Rare = 0.0013333333333333333, Epic = 0.004,
			Legendary = 0.05, Secret = 0.4,
		}
		local xlChances = type(constants.XLChances) == "table" and constants.XLChances or {}
		local xlPercent = tonumber(xlChances[rarity]) or xlDefaults[rarity]
		if not xlPercent then return basePercent, 0 end
		finalPercent *= xlPercent / 100
	end
	if super then finalPercent *= (tonumber(constants.SuperChance) or 0.1) / 100 end
	return basePercent, finalPercent
end

function getPetVariantName(scriptStateSU, webhookPetEntry, maxAttempts)
	if type(scriptStateSU) ~= "string" or scriptStateSU == "" then
		return nil
	end
	-- The game's pet tooltip passes PetUtil:GetName(pet) to GetExisting.
	local remotePetName = scriptStateSU
	if type(webhookPetEntry) == "table" then
		local petName = activeStates.BGSI_Lite_GetHatchPetName(webhookPetEntry)
		if petName ~= "Unknown" then
			local variantPet = {
				Name = petName,
				Super = activeStates.BGSI_Lite_GetHatchPetFlag(webhookPetEntry, "Super"),
				XL = activeStates.BGSI_Lite_GetHatchPetFlag(webhookPetEntry, "XL"),
				Shiny = activeStates.BGSI_Lite_GetHatchPetFlag(webhookPetEntry, "Shiny"),
				Mythic = activeStates.BGSI_Lite_GetHatchPetFlag(webhookPetEntry, "Mythic"),
			}
			local nameOk, gameName = pcall(function()
				local petUtil = require(ReplicatedStorage.Shared.Utils.PetUtil)
				return petUtil:GetName(variantPet)
			end)
			if nameOk and type(gameName) == "string" and gameName ~= "" then
				remotePetName = gameName
			end
		end
	end

	local function getExistingCount(existingValue)
		if type(existingValue) == "number" then
			return math.floor(existingValue)
		end
		if type(existingValue) == "string" then
			local cleanedValue = existingValue:gsub(",", "")
			local existingCount = tonumber(cleanedValue) or tonumber(cleanedValue:match("%d+"))
			return existingCount and math.floor(existingCount) or nil
		end
		if type(existingValue) == "table" then
			local zeroCount
			for _, existingKey in ipairs({
				scriptStateSU,
				remotePetName,
				"Existing",
				"Exists",
				"Exist",
				"Count",
				"Total",
				"Amount",
				"Value",
				"existing",
				"exists",
				"exist",
				"count",
				"total",
				"amount",
				"value",
			}) do
				local existingCount = getExistingCount(existingValue[existingKey])
				if existingCount and existingCount > 0 then
					return existingCount
				elseif existingCount == 0 then
					zeroCount = 0
				end
			end
			return zeroCount
		end
		return nil
	end

	local localExistingCount
	if type(webhookPetEntry) == "table" then
		local nestedPet = type(webhookPetEntry.Pet) == "table" and webhookPetEntry.Pet or nil
		for _, existingValue in pairs({
			webhookPetEntry.Existing,
			webhookPetEntry.Exists,
			webhookPetEntry.Exist,
			webhookPetEntry.ExistCount,
			webhookPetEntry.existing,
			webhookPetEntry.exists,
			webhookPetEntry.exist,
			webhookPetEntry.existCount,
			nestedPet and nestedPet.Existing,
			nestedPet and nestedPet.Exists,
			nestedPet and nestedPet.Exist,
			nestedPet and nestedPet.ExistCount,
			nestedPet and nestedPet.existing,
			nestedPet and nestedPet.exists,
			nestedPet and nestedPet.exist,
			nestedPet and nestedPet.existCount,
		}) do
			local existingCount = getExistingCount(existingValue)
			if existingCount and existingCount > 0 then
				localExistingCount = math.max(localExistingCount or 0, existingCount)
			end
		end
	end

	if not remoteFunction then
		return localExistingCount or 0
	end
	local latestExistingCount
	local attemptCount = math.min(8, math.max(1, math.floor(tonumber(maxAttempts) or 4)))
	for existingAttempt = 1, attemptCount do
		local requestSucceeded, existingResponse = pcall(function()
			return remoteFunction:InvokeServer("GetExisting", remotePetName)
		end)
		local existingCount = requestSucceeded and getExistingCount(existingResponse) or nil
		if existingCount ~= nil then
			latestExistingCount = math.max(latestExistingCount or 0, existingCount)
		end
		if latestExistingCount and latestExistingCount > 0 then
			break
		end
		if existingAttempt < attemptCount then
			task.wait(0.5)
		end
	end
	if latestExistingCount or localExistingCount then
		return math.max(latestExistingCount or 0, localExistingCount or 0)
	end
	return 0
end

function buildPetWebhookEmbed(scriptStateHC, scriptStateRV, scriptStateHH, scriptStateVT)
	if type(scriptStateHC) ~= "string" or scriptStateHC == "" then
		return scriptStateHC
	end
	local scriptStateBT = {}
	if scriptStateVT then
		table.insert(scriptStateBT, "XL")
	end
	if scriptStateRV then
		table.insert(scriptStateBT, "Shiny")
	end
	if scriptStateHH then
		table.insert(scriptStateBT, "Mythic")
	end
	if #scriptStateBT == 0 then
		return scriptStateHC
	end
	return table.concat(scriptStateBT, " ") .. " " .. scriptStateHC
end

function sendPetWebhook(scriptStateUL, scriptStateADL, scriptStateXY)
	local scriptStateYI = scriptStateUL and scriptStateUL.Images
	if type(scriptStateYI) ~= "table" then
		return nil
	end
	local scriptStateOI
	if scriptStateADL and scriptStateXY then
		scriptStateOI = scriptStateYI[4]
			or scriptStateYI.MythicShiny
			or scriptStateYI["Shiny Mythic"]
			or scriptStateYI.ShinyMythic
	elseif scriptStateADL then
		scriptStateOI = scriptStateYI[2] or scriptStateYI.Shiny
	elseif scriptStateXY then
		scriptStateOI = scriptStateYI[3] or scriptStateYI.Mythic
	else
		scriptStateOI = scriptStateYI[1] or scriptStateYI.Normal
	end
	if not scriptStateOI then
		for loopSlotCS = 1, 4 do
			if scriptStateYI[loopSlotCS] then
				scriptStateOI = scriptStateYI[loopSlotCS]
				break
			end
		end
		if not scriptStateOI then
			scriptStateOI = scriptStateYI.Normal or scriptStateYI.Shiny or scriptStateYI.Mythic
		end
	end
	if not scriptStateOI then
		return nil
	end
	local scriptStateWR = string.match(tostring(scriptStateOI), "rbxassetid://(%d+)")
		or tostring(tonumber(scriptStateOI) or "")
	if scriptStateWR ~= "" then
		local scriptStateACO = ("https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=Png"):format(
			scriptStateWR
		)
		local scriptStateFI
		local thumbnailRequestOk = pcall(function()
			scriptStateFI = game:HttpGet(scriptStateACO)
		end)
		if not thumbnailRequestOk or not scriptStateFI or scriptStateFI == "" then
			thumbnailRequestOk = pcall(function()
				scriptStateFI = HttpService:GetAsync(scriptStateACO)
			end)
		end
		if thumbnailRequestOk and scriptStateFI and scriptStateFI ~= "" then
			local scriptStateABU, scriptStateNH = pcall(function()
				return HttpService:JSONDecode(scriptStateFI)
			end)
			if
				scriptStateABU
				and scriptStateNH
				and scriptStateNH.data
				and scriptStateNH.data[1]
				and scriptStateNH.data[1].imageUrl
			then
				return scriptStateNH.data[1].imageUrl
			end
		end
	end
	if type(scriptStateOI) == "string" and scriptStateOI:find("http") then
		return scriptStateOI
	end
	return nil
end

function normalizeDiscordWebhookV2Url(scriptStateQZ)
	scriptStateQZ = tostring(scriptStateQZ or ""):match("^%s*(.-)%s*$") or ""
	if scriptStateQZ == "" then
		return scriptStateQZ
	end
	if not scriptStateQZ:find("with_components=", 1, true) then
		scriptStateQZ = scriptStateQZ .. (scriptStateQZ:find("?", 1, true) and "&" or "?") .. "with_components=true"
	end
	if not scriptStateQZ:find("wait=", 1, true) then
		scriptStateQZ = scriptStateQZ .. "&wait=true"
	end
	return scriptStateQZ
end

function buildDiscordV2WebhookPayload(scriptStateACW)
	local sourceEmbed = type(scriptStateACW) == "table" and type(scriptStateACW.embeds) == "table"
		and scriptStateACW.embeds[1] or nil
	local components = {}
	local function addText(content)
		content = tostring(content or "")
		if content ~= "" then
			table.insert(components, {
				type = 10,
				content = content,
			})
		end
	end
	local function addSeparator()
		table.insert(components, {
			type = 14,
			divider = true,
			spacing = 1,
		})
	end

	if sourceEmbed then
		local mentionContent = scriptStateACW and tostring(scriptStateACW.content or "") or ""
		if mentionContent ~= "" then
			addText(mentionContent)
		end
		local title = tostring(sourceEmbed.title or "")
		local description = tostring(sourceEmbed.description or "")
		local thumbnailUrl = type(sourceEmbed.thumbnail) == "table" and sourceEmbed.thumbnail.url or nil
		-- Keep the hatch announcement and fields together beside the pet icon.
		-- Explicit bold announcements retain their size instead of becoming H1 headings.
		local heading = description ~= "" and description or (title ~= "" and ("# " .. title) or "")
		if heading ~= "" and not heading:match("^#") and not heading:match("^%*%*") then
			heading = "# " .. heading
		end

		local fieldLines = {}
		if type(sourceEmbed.fields) == "table" and #sourceEmbed.fields > 0 then
			for _, field in ipairs(sourceEmbed.fields) do
				if type(field) == "table" then
					local fieldName = tostring(field.name or "")
					local fieldValue = tostring(field.value or "")
					if fieldName ~= "" and fieldValue ~= "" then
						table.insert(fieldLines, "**" .. fieldName .. "**\n" .. fieldValue)
					elseif fieldValue ~= "" then
						table.insert(fieldLines, fieldValue)
					elseif fieldName ~= "" then
						table.insert(fieldLines, "**" .. fieldName .. "**")
					end
				end
			end
		end

		local sectionTextParts = {}
		if heading ~= "" then
			table.insert(sectionTextParts, heading)
		end
		if #fieldLines > 0 then
			table.insert(sectionTextParts, table.concat(fieldLines, "\n\n"))
		end
		local sectionText = table.concat(sectionTextParts, "\n")

		if sectionText ~= "" and thumbnailUrl and tostring(thumbnailUrl) ~= "" then
			table.insert(components, {
				type = 9,
				components = {
					{
						type = 10,
						content = sectionText,
					},
				},
				accessory = {
					type = 11,
					media = {
						url = tostring(thumbnailUrl),
					},
				},
			})
		elseif sectionText ~= "" then
			addText(sectionText)
		end

		local imageUrl = type(sourceEmbed.image) == "table" and sourceEmbed.image.url or nil
		if imageUrl and tostring(imageUrl) ~= "" then
			addSeparator()
			table.insert(components, {
				type = 12,
				items = {
					{
						media = {
							url = tostring(imageUrl),
						},
					},
				},
			})
		end

		local footerText = type(sourceEmbed.footer) == "table" and sourceEmbed.footer.text or nil
		local timestamp = sourceEmbed.timestamp
		local footerLine = tostring(footerText or "")
		if timestamp then
			local unixTime = tonumber(timestamp)
			if not unixTime and type(timestamp) == "string" then
				unixTime = os.time()
			end
			if unixTime then
				local discordTime = "<t:" .. tostring(math.floor(unixTime)) .. ":F>"
				footerLine = footerLine ~= "" and (footerLine .. " • " .. discordTime) or discordTime
			end
		end
		if footerLine ~= "" then
			addSeparator()
			addText("-# " .. footerLine)
		end
	else
		-- V2 does not support top-level content/embeds, so retain any plain content as Text Display.
		addText(scriptStateACW and scriptStateACW.content or "")
	end

	local payload = {
		flags = 32768,
		components = {
			{
				type = 17,
				accent_color = sourceEmbed and tonumber(sourceEmbed.color) or nil,
				components = components,
			},
		},
	}
	if scriptStateACW and type(scriptStateACW.allowed_mentions) == "table" then
		payload.allowed_mentions = scriptStateACW.allowed_mentions
	end
	return payload
end

function buildSimulatedHatchPayload(pet, info, options)
    options=options or {}
    local Config={webhookHidePlayerName=options.hideUsername==true,webhookShowUserInfo=options.showUserInfo==true}
	local petName = pet.Name
	local shiny, mythic, xl = pet.Shiny == true, pet.Mythic == true, pet.XL == true
	local super = pet.Super == true
	if super and options.simulated then
		pet.Enchants = rollSimulatedSuperEnchants(pet)
		pet.Enchantments = nil
	end
	local sourceName, sourceIsEgg = getWebhookPetSource(pet, info, options.eventName, options.hatchResult)
	local finalPercent = 0
	if sourceIsEgg then
		local _, calculatedPercent = getWebhookHatchChances(petName, info, sourceName, shiny, mythic, xl, super)
		finalPercent = calculatedPercent
	end
	local finalOneIn = sourceIsEgg and finalPercent > 0 and 100 / finalPercent or 0
	local variantName = (super and "Super " or "") .. buildPetWebhookEmbed(petName, shiny, mythic, xl)
	local existCount = getPetVariantName(variantName, pet, options.simulated and 4 or 8)
	local statMultiplier = xl and (tonumber(sharedConstants and sharedConstants.XLMultiplier) or 2.5) or 1
	if shiny and mythic then
		statMultiplier *= 2.25
	elseif shiny then
		statMultiplier *= 1.5
	elseif mythic then
		statMultiplier *= 1.75
	end
	local petLines = {
		"<:egg:1377264232915013673> Egg: **" .. sourceName .. "**",
	}
	if sourceIsEgg then
		table.insert(petLines, "<:four_leaf_clover:1462133363182796810> Chance: **"
			.. (finalOneIn > 0 and ("1 in " .. runShrineDonation(math.floor(finalOneIn + 0.5))) or "N/A") .. "**")
	end
	local simulatedEnchantNames
	if super then
		local enchantText, enchantNames = getWebhookSuperLegendaryEnchantText(pet, petName, shiny, mythic, xl)
		simulatedEnchantNames = enchantNames
		if enchantText then table.insert(petLines, enchantText) end
	end
	local statEmojis = {
		bubbles = "<:purple_circle:1363755750828019774>",
		gems = "<:gem:1363755998401269854>",
		coins = "\240\159\170\153",
		pearls = "<:Pearl:1561761464866308219>",
		carnivalcoins = "<:circus_tent:1520159699230785707>",
		candycorn26 = "<:CandyCorn26:1561526287476985887>",
	}
	local stats = type(info.Stats) == "table" and info.Stats or {}
	local statNames = {}
	for statName, statValue in pairs(stats) do
		if type(statName) == "string" and type(statValue) == "number" then
			table.insert(statNames, statName)
		end
	end
	table.sort(statNames)
	for _, statName in ipairs(statNames) do
		local normalizedStatName = statName:lower():gsub("[^%w]", "")
		local emoji = statEmojis[normalizedStatName] or scriptStateDX[statName] or ""
		local displayStatName = normalizedStatName == "candycorn26" and "Candycorn" or statName
		table.insert(petLines, emoji .. " " .. displayStatName .. ": **"
			.. activeStates.BGSI_Lite_GetWebhookPetStatValue(stats[statName] * statMultiplier) .. "**")
	end
	table.insert(petLines, "")
	table.insert(petLines, "Exist: **" .. (existCount ~= nil and runShrineDonation(existCount) or "N/A") .. "**")
	local variants = {}
	if shiny then table.insert(variants, "Shiny") end
	if mythic then table.insert(variants, "Mythic") end
	if super then table.insert(variants, "Super") end
	if xl then table.insert(variants, "XL") end
	local playerName = Config.webhookHidePlayerName == true and "Player" or LocalPlayer.Name
	local title = playerName .. " hatched a " .. (#variants > 0 and table.concat(variants, " ") .. " " or "") .. petName
	local color = shiny and mythic and tonumber("00FF00", 16)
		or mythic and tonumber("5E03FC", 16)
		or shiny and tonumber("FFFF00", 16)
		or tonumber("FF0000", 16)
	local iconUrl = sendPetWebhook(info, shiny, mythic)
	if super then
		iconUrl = getEnchantedSuperWebhookIcon(iconUrl, simulatedEnchantNames)
	end
	local fields = {}
	if Config.webhookShowUserInfo == true then
		table.insert(fields, buildWebhookUserInfoField())
	end
	table.insert(fields, {name = "Pet Info", value = table.concat(petLines, "\n"), inline = false})
	return {
		embeds = {{
			description = "# **" .. title .. "**",
			color = color,
			fields = fields,
			thumbnail = not xl and iconUrl and {url = iconUrl} or nil,
			image = xl and iconUrl and {url = iconUrl} or nil,
			footer = {text = ""},
			timestamp = os.time(),
		}},
	}
end

return {Build=buildSimulatedHatchPayload,Render=buildDiscordV2WebhookPayload,NormalizeURL=normalizeDiscordWebhookV2Url,
    GetOdds=function(pet,name,info,shiny,mythic,xl)
        local origin,isEgg=getWebhookPetSource(pet,info)
        if not isEgg then return nil,false end
        local _,percent=getWebhookHatchChances(name,info,origin,shiny,mythic,xl,ctx.GetFlag(pet,"Super"))
        return percent>0 and 100/percent or nil,percent>0
    end}
end
