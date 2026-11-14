-- Generated from larplite.lua; rebuild with tools/build_modules.py.
return {
function(...)
loaderOptions = ...
if type(loaderOptions) ~= "table" then
	loaderOptions = rawget(getfenv(), "_LarpLiteLoaderOptions") or {}
end
if type(getgenv) == "function" then
	local globalEnv = getgenv()
	local previousHubCleanup = rawget(globalEnv, "_1rzHubLiteCleanup")
	if type(previousHubCleanup) == "function" then
		local cleanupOk, cleanupError = pcall(previousHubCleanup)
		if not cleanupOk then
			warn("[1rzHub Lite] Previous instance cleanup failed: " .. tostring(cleanupError))
		end
		globalEnv._1rzHubLiteCleanup = nil
	end
	pcall(function()
		local previousRayfieldWindow = rawget(globalEnv, "RayfieldGen2Window")
		if previousRayfieldWindow and not previousRayfieldWindow.unloaded then
			if type(previousRayfieldWindow.Unload) == "function" then
				local unloadOk, unloadError = pcall(function()
					previousRayfieldWindow:Unload()
				end)
				if not unloadOk then
					warn("[1rzHub Lite] Previous window failed to unload: " .. tostring(unloadError))
				end
			end
		end
	end)
	globalEnv.RayfieldGen2Window = nil
	-- Unload above may only flag the old window for removal rather than tearing it down
	-- synchronously - give it a frame before this run builds its own window, so the two
	-- don't ever exist on screen at the same time.
	pcall(function()
		game:GetService("RunService").Heartbeat:Wait()
	end)
	-- Keep a direct reference instead of allocating a snapshot of the entire GC heap.
	local previousConfig = rawget(globalEnv, "_1rzHubLiteActiveConfig")
	if type(previousConfig) == "table" then
		previousConfig.webhookEnabled = false
	end
	local previousCleanup = rawget(globalEnv, "_1rzHubLitePetViewerCleanup")
	if type(previousCleanup) == "function" then
		pcall(previousCleanup)
		globalEnv._1rzHubLitePetViewerCleanup = nil
	end
	globalEnv._1rzHubLite_Loaded = true
	-- Cached resolver callbacks belong to one module environment, never a previous run.
	globalEnv.BGSI_Lite_WebhookPetIconResolver = nil
	globalEnv._1rzHubLite_LoadComplete = false
	globalEnv.LoadedMobileUI = false
end
if not game:IsLoaded() then
	game.Loaded:Wait()
end
Players = game:GetService("Players")
ReplicatedStorage = game:GetService("ReplicatedStorage")
Workspace = game:GetService("Workspace")
HttpService = game:GetService("HttpService")
RunService = game:GetService("RunService")
VirtualInputManager = game:GetService("VirtualInputManager")
CollectionService = game:GetService("CollectionService")
CoreGui = game:GetService("CoreGui")
TeleportService = game:GetService("TeleportService")
UserInputService = game:GetService("UserInputService")
LocalPlayer = Players.LocalPlayer
activeStates = (getgenv and getgenv()) or {}
activeStates.BGSI_Lite_LegacyPickupLoopWarning=activeStates.BGSI_Lite_ScriptVersion~=nil
	and activeStates.BGSI_Lite_PickupLoopLifecycleVersion~=1
activeStates.BGSI_Lite_PickupLoopLifecycleVersion=1
activeStates.BGSI_Lite_ScriptVersion = "2026.11.14.53"
activeStates.BGSI_Lite_ObbyDifficultyOptions = { "Easy", "Medium", "Hard" }
activeStates.BGSI_Lite_PriorityEventOptions = {
	"Luck Event",
	"Shiny Event",
	"Mythic Event",
	"Celestial Event",
	"Secret Event",
	"Infinity Event",
	"XL Event",
	"Super Palooza",
}
activeStates.BGSI_Lite_FallUpgradeOptions = {
	{ value = "Currency", label = "Extra Currency" },
	{ value = "Luck", label = "Luck" },
	{ value = "SecretLuck", label = "Secret Luck" },
	{ value = "InfinityLuck", label = "Infinity Luck" },
	{ value = "AutoRebirth", label = "Auto Rebirth" },
}
activeStates.BGSI_Lite_DashboardLogSequence = tonumber(activeStates.BGSI_Lite_DashboardLogSequence) or 0
activeStates.BGSI_Lite_LogDashboardAction = function(message, level)
	activeStates.BGSI_Lite_DashboardLogSequence += 1
	activeStates.BGSI_Lite_PendingDashboardLog = {
		id = activeStates.BGSI_Lite_DashboardLogSequence,
		message = tostring(message),
		level = tostring(level or "info"),
	}
end
end,
function(...)
activeStates.BGSI_Lite_ReleaseNotes = activeStates.BGSI_Lite_ReleaseHistory[1].notes
currentRunToken = {}
activeStates._1rzHubLiteRunToken = currentRunToken
function isCurrentRun()
	return activeStates._1rzHubLiteRunToken == currentRunToken
end
pcall(function()
	local openUi = CoreGui:FindFirstChild("OpenUI")
	if openUi then
		openUi:Destroy()
	end
end)
configAccountId = tostring(LocalPlayer.UserId or "0"):gsub("[^%w%-_]", "_")
configFile = "1rzHubLiteConfig_" .. configAccountId .. ".json"
sharedConfigFile = "1rzHubLiteConfig.json"
defaultConfig = {
	safeMode = false,
	safeModeSavedConfig = {},
	autoCollectPresentRain = false,
	autoHalloweenChest = false,
	autoClaimCompHatches = false,
	autoClaimCompBubbles = false,
	autoTrickOrTreat = false,
	autoFallRebirth = false,
	autoFallLeaves = false,
	autoFallUpgrades = false,
	fallUpgradePriority = "Currency",
	autoFallElixir = true,
	autoFallChest = false,
	selectedWorldChest = "Giant Chest",
	selectedWorldChests = {},
	autoClaimWorldChest = false,
	selectedChest = "golden-chest",
	autoChestSummon = false,
	autoChest = false,
	selectedEgg = "",
	selectedEggLocationPriorities = {},
	selectedRiftEgg = "",
	autoRiftEgg = false,
	autoRiftEggSpawn = false,
	selectedInventoryEgg = "",
	autoHatchInventoryEgg = false,
	autoHatch = false,
	adaptiveHatch = true,
	healthRecoveryEnabled = true,
	accountRole = "Balanced",
	autoSkipIntro = true,
	noHatchAnim = false,
	autoSpamR = false,
	autoBounty = false,
	spawnRift = false,
	autoLuckEgg = false,
	autoHopLuckEgg = false,
	autoHopTargetRifts = false,
	targetRiftIds = {},
	autoSpecialRift = false,
	potionType = "Speed",
	potionLevel = 1,
	selectedPotions = {},
	potionSelectionMigrated = false,
	potionUseAmount = 10,
	potionAuto = false,
	potionMaintainSeconds = 30,
	autoEventPotions = false,
	autoEnchant = false,
	autoPowerOrbEquipped = false,
	equippedTargetEnchant = "secret-hunter",
	equippedTargetEnchant2 = "ultra-roller",
	equippedTargetEnchantLevel = 0,
	equippedReenchantThreshold = 0,
	equippedEnchantCurrency = "Auto (Secret = Crystals,Normal = Gems)",
	autoSetupTeamEnabled = false,
	autoSetupTeamIncludeSupers = false,
	autoSetupTeamAABlessingSupers = false,
	autoSetupTeamSuperCounts = {
		["luck-boost"] = 0,
		["luck-boost-plus"] = 0,
		["hatch-blessing"] = 0,
		["hatch-blessing-plus"] = 0,
		["bubble-machine"] = 0,
		["bubble-machine-plus"] = 0,
		["burst-blessing"] = 0,
		["burst-blessing-plus"] = 0,
		["shiny-blessing"] = 0,
		["shiny-blessing-plus"] = 0,
		["mythic-blessing"] = 0,
		["mythic-blessing-plus"] = 0,
		["infinity-blessing"] = 0,
		["infinity-blessing-plus"] = 0,
		["duplication"] = 0,
		["duplication-plus"] = 0,
	},
	autoPlaytime = false,
	autoClaimPrizes = false,
	autoDailyRewards = true,
	autoWheelSpin = true,
	autoUpgradeMastery = false,
	autoCollectCoins = false,
	autoUseFragments = false,
	autoInventoryCleanup = true,
	inventoryCleanupMinCopies = 10,
	autoDeleteLowRarityEggPets = true,
	autoBuyFragments = true,
	selectedFragments = {},
	dashboardSyncEnabled = true,
	dashboardSyncAutoEnabled = false,
	dashboardEndpoint = "https://larplite.xyz",
	dashboardIngestToken = "",
	dashboardBestHatchName = "",
	dashboardBestHatchChance = 0,
	fleetFollowMaster = true,
	fleetAutoPush = true,
	autoCollectCarnivalCoins = false,
	autoCarnivalChest = false,
	autoBuyShops = false,
	autoGuessThatPet = false,
	selectedShops = {},
	selectedShopItems = {},
	shopInterval = 1,
	autoBubble = false,
	autoSell = false,
	selectedObby = "Easy",
	autoObby = false,
	autoObbyCycle = true,
	autoObbyChest = false,
	obbyChestUseThreeKeys = true,
	selectedMysteryBox = "Mystery Box",
	selectedMysteryBoxes = {},
	autoOpenMystery = false,
	autoOpenMysteryDelay = 0.2,
	autoCondenseMysteryBoxes = false,
	condenserGemReserve = 0,
	autoGemGenie = false,
	optimisedGemGenie = false,
	gemGenieTargetItem = "Shadow Crystal",
	autoSeason = false,
	autoChallengePassQuests = false,
	autoClaimChallengePassRewards = false,
	autoResetChallengePass = false,
	autoDailyHourlyChallenge = false,
	skipTicketPearlQuests = false,
	skipBubblingQuests = false,
	bubbleQuestSwitchTeams = true,
	questStallTimeoutSeconds = 60,
	autoShadowLeviathanQuest = false,
	autoRerollShadowLeviathanQuest = false,
	shadowLeviathanTargetItem = "",
	optimisedShadowLeviathanQuest = false,
	autoGuildQuests = false,
	autoClaimGuildRewards = false,
	autoAcceptGuildInvites = false,
	serverAntiAfk = false,
	serverAutoRejoin = false,
	serverJoinLeaveAlerts = false,
	autoGlobalIncentive = false,
	autoClaimGlobalIncentive = false,
	autoClosePopups = true,
	AutoPurchaseEvents = false,
	PriorityEvents = {
		"Luck Event",
		"Shiny Event",
		"Mythic Event",
		"Celestial Event",
		"Secret Event",
		"Infinity Event",
		"XL Event",
		"Super Palooza",
	},
	MinimumCrystalReserve = 0,
	EventPurchaseQuantity = 1,
	MaximumEventPurchasesPerSession = 8,
	EventPurchaseCooldown = 60,
	ExtendAlreadyActiveEvents = false,
	MaximumRejectedEventAttempts = 3,
	AutoStartInfiniteTrack = true,
	DreamerShrineEnabled = false,
	DreamerShrineAmount = 15,
	shrineAuto = false,
	shrineLevel = 1,
	shrinePotion = "Lucky",
	shrineAmount = 500,
	autoHalloweenShrine = false,
	halloweenShrinePotion = "Lucky/6",
	halloweenShrineReroll = false,
	halloweenShrineTarget = "Secret",
	halloweenShrineTargets = {},
	webhookEnabled = false,
	webhookURL = "",
	webhookMinimumChance = "",
	webhookShowUserInfo = false,
	webhookSimulationSuperDefault = true,
	webhookSendEasySecrets = true,
	-- Optional user-authorized hatch telemetry endpoint. Keep the Discord webhook secret on the backend.
	hatchTelemetryEnabled = true,
	hatchTelemetryEndpoint = "",
	-- Separate live-status webhook. This is intentionally independent from the hatching webhook.
	LiveWebhookEnabled = false,
	LiveWebhookURL = "",
	-- Persistent Discord message IDs keyed by webhook URL so live status edits the same message after reloads.
	LiveWebhookMessageIds = {},
	webhookHidePlayerName = false,
	webhookPingEnabled = false,
	webhookPingUserId = "",
	webhookLowCurrencyEnabled = false,
	webhookLowCoinsBelow = "",
	webhookLowGemsBelow = "",
	webhookLowPearlsBelow = "",
	webhookLowTicketsBelow = "",
	webhookLowCurrencyCooldownMinutes = 30,
	selectedTicketTeam = "",
	selectedPearlTeam = "",
	selectedTicketReturnTeam = "",
	selectedPearlReturnTeam = "",
	autoCurrencyTeams = false,
	webhookRarities = {
		Secret = true,
		Legendary = false,
		Epic = false,
		Rare = false,
		Unique = false,
		Common = false,
	},
	RebirthPetName = "Classic Overlord",
	AdminRebirthPetName = "Man Face Lord",
	RebirthVariants = {
		"Normal",
	},
	RebirthMachineEnabled = false,
	fishingAuto = false,
	fishingAutoProgress = true,
	fishingInstantReel = false,
	fishingAutoClaimIndex = true,
	fishingIndexSweep = false,
	fishingAutoEquipBestRod = true,
	fishingAutoSellWhenFull = false,
	CrystalAltarEnabled = false,
	SkyAltarEnabled = false,
	WinterAltarEnabled = false,
	WinterAltarPets = {},
	AdminRebirthMachineEnabled = false,
	AutoCarnivalRebirth = false,
	autoHalloweenRebirth = false,

	disableRendering = false,
	autoOptimizeMemory = true,
	optimizeMeshDetail = false,
	setfps = 60,
	renderDistance = 250,
	chunkerRenderDistance = 2,
	lastSeenScriptVersion = "",

	autoUpdateScript = true,
	autoUpdateIntervalSeconds = 300,
}
activeStates.BGSI_Lite_SafeModePreservedKeys = {
	autoOptimizeMemory = true,
	optimizeMeshDetail = true,
	safeMode = true,
	safeModeSavedConfig = true,
	dashboardSyncEnabled = true,
	dashboardSyncAutoEnabled = true,
	autoSetupTeamEnabled = true,
	autoSetupTeamIncludeSupers = true,
	autoSetupTeamAABlessingSupers = true,
	autoSetupTeamSuperCounts = true,
}
function copyLoaderValue(value)
	if type(value) ~= "table" then return value end
	local copy = {}
	for key, item in pairs(value) do copy[key] = copyLoaderValue(item) end
	return copy
end
function applyLoaderSettings(target, settings)
	if type(settings) ~= "table" then return end
	for key, value in pairs(settings) do
		if defaultConfig[key] ~= nil and typeof(value) == typeof(defaultConfig[key]) then
			target[key] = copyLoaderValue(value)
		else
			warn("[LarpLite] Ignoring unknown or incorrectly typed inline setting: " .. tostring(key))
		end
	end
end
applyLoaderSettings(defaultConfig, loaderOptions.Defaults)
legacyConfigFile = "1rzHubConfig.json"
Config = nil
function isAutomationBlocked()
	return not isCurrentRun() or (Config and Config.safeMode == true)
end
function loadConfig()
	local loadedConfig = copyLoaderValue(defaultConfig)
	local scriptStateBB = {}
	local loadedAccountConfig = false
	local function mergeConfigFile(fileName, allowSharedLiveIds)
		if not (isfile and isfile(fileName)) then
			return false
		end
		local decodeOk, savedConfig = pcall(function()
			return HttpService:JSONDecode(readfile(fileName))
		end)
		if not decodeOk or type(savedConfig) ~= "table" then
			return false
		end
		if savedConfig.autoSpamR == nil and type(savedConfig.autoSpamE) == "boolean" then
			savedConfig.autoSpamR = savedConfig.autoSpamE
		end
		if savedConfig.halloweenShrineTargets==nil and type(savedConfig.halloweenShrineTarget)=="string"then
			savedConfig.halloweenShrineTargets={savedConfig.halloweenShrineTarget}
		end
		for loopSlotCL, scriptStateOE in pairs(loadedConfig) do
			if savedConfig[loopSlotCL] ~= nil and typeof(savedConfig[loopSlotCL]) == typeof(scriptStateOE) then
				if loopSlotCL ~= "LiveWebhookMessageIds" or allowSharedLiveIds then
					loadedConfig[loopSlotCL] = savedConfig[loopSlotCL]
					scriptStateBB[loopSlotCL] = true
				end
			end
		end
		return true
	end

	loadedAccountConfig = mergeConfigFile(configFile, true)
	-- First run after this update: migrate the old shared config into this account's file.
	-- Live webhook message IDs are intentionally not migrated because they were shared across accounts.
	if not loadedAccountConfig then
		mergeConfigFile(sharedConfigFile, false)
	end
	if isfile and isfile(legacyConfigFile) then
		local scriptStateZF, scriptStateQX = pcall(function()
			return HttpService:JSONDecode(readfile(legacyConfigFile))
		end)
		if scriptStateZF and type(scriptStateQX) == "table" then
			if scriptStateQX.autoSpamR == nil and type(scriptStateQX.autoSpamE) == "boolean" then
				scriptStateQX.autoSpamR = scriptStateQX.autoSpamE
			end
			if scriptStateQX.halloweenShrineTargets==nil and type(scriptStateQX.halloweenShrineTarget)=="string"then
				scriptStateQX.halloweenShrineTargets={scriptStateQX.halloweenShrineTarget}
			end
			for loopSlotAL, scriptStateAN in pairs(loadedConfig) do
				if
					not scriptStateBB[loopSlotAL]
					and scriptStateQX[loopSlotAL] ~= nil
					and typeof(scriptStateQX[loopSlotAL]) == typeof(scriptStateAN)
				then
					loadedConfig[loopSlotAL] = scriptStateQX[loopSlotAL]
					scriptStateBB[loopSlotAL] = true
				end
			end
		end
	end
	-- Move the former default donations to the new full-capacity amounts while
	-- leaving explicitly chosen non-default amounts alone.
	if loadedConfig.DreamerShrineAmount == 1 then loadedConfig.DreamerShrineAmount = 15 end
	if loadedConfig.shrineAmount == 10 then loadedConfig.shrineAmount = 500 end
	if loadedConfig.RebirthPetName == "Man Face Lord" then loadedConfig.RebirthPetName = "Classic Overlord" end
	applyLoaderSettings(loadedConfig, loaderOptions.Config)
	local inlineTargets=type(loaderOptions.Config)=="table"and loaderOptions.Config.halloweenShrineTargets
	local inlineTarget=type(loaderOptions.Config)=="table"and loaderOptions.Config.halloweenShrineTarget
	local defaultTargets=type(loaderOptions.Defaults)=="table"and loaderOptions.Defaults.halloweenShrineTargets
	if type(inlineTargets)~="table"and type(inlineTarget)=="string"then
		loadedConfig.halloweenShrineTargets={inlineTarget}
	elseif not scriptStateBB.halloweenShrineTargets and type(inlineTargets)~="table"
		and not(type(defaultTargets)=="table"and not scriptStateBB.halloweenShrineTarget)then
		loadedConfig.halloweenShrineTargets={loadedConfig.halloweenShrineTarget}
	end
	return loadedConfig
end
function saveConfig()
	if not writefile or activeStates.BGSI_Lite_ConfigResetPending == true then
		return
	end
	if Config and Config.safeMode == true and type(Config.safeModeSavedConfig) == "table" then
		for configKey, defaultValue in pairs(defaultConfig) do
			if
				type(defaultValue) == "boolean"
				and not activeStates.BGSI_Lite_SafeModePreservedKeys[configKey]
				and Config[configKey] == true
			then
				Config.safeModeSavedConfig[configKey] = true
				Config[configKey] = false
			end
		end
	end
	pcall(function()
		writefile(configFile, HttpService:JSONEncode(Config))
	end)
end
webhookHatchTrackerFile = "1rzHubLiteWebhookHatchTracker.json"
function loadWebhookHatchTracker()
	local tracker = {}
	if isfile and isfile(webhookHatchTrackerFile) then
		local ok, savedTracker = pcall(function()
			return HttpService:JSONDecode(readfile(webhookHatchTrackerFile))
		end)
		if ok and type(savedTracker) == "table" then
			for petName, hatchCount in pairs(savedTracker) do
				if type(petName) == "string" then
					local numericCount = tonumber(hatchCount)
					if numericCount and numericCount > 0 then
						tracker[petName] = math.floor(numericCount)
					end
				end
			end
		end
	end
	return tracker
end
function saveWebhookHatchTracker()
	if not writefile then
		return
	end
	local tracker = activeStates and activeStates.BGSI_Lite_WebhookHatchTracker
	if type(tracker) ~= "table" then
		return
	end
	local mergedTracker = loadWebhookHatchTracker()
	for petName, hatchCount in pairs(tracker) do
		if type(petName) == "string" then
			local numericCount = tonumber(hatchCount)
			if numericCount and numericCount > 0 then
				mergedTracker[petName] = math.max(tonumber(mergedTracker[petName]) or 0, math.floor(numericCount))
			end
		end
	end
	for petName, hatchCount in pairs(mergedTracker) do
		tracker[petName] = hatchCount
	end
	pcall(function()
		writefile(webhookHatchTrackerFile, HttpService:JSONEncode(mergedTracker))
	end)
	local refreshedTracker = loadWebhookHatchTracker()
	for petName, hatchCount in pairs(refreshedTracker) do
		tracker[petName] = math.max(tonumber(tracker[petName]) or 0, hatchCount)
	end
end
function safeRequireTable(moduleLoaderFunction)
	local success, module = pcall(moduleLoaderFunction)
	return success and type(module) == "table" and module or nil
end
function getChunkerModule()
	local ChunkerModule = safeRequireTable(function()
		local shared = ReplicatedStorage:WaitForChild("Shared", 5)
		local utils = shared:WaitForChild("Utils", 5)
		return require(utils:WaitForChild("Chunker", 5))
	end)
	if not ChunkerModule then
		ChunkerModule = safeRequireTable(function()
			return require(ReplicatedStorage.Shared.Utils.Chunker)
		end)
	end
	if not ChunkerModule then
		ChunkerModule = safeRequireTable(function()
			local shared = ReplicatedStorage:WaitForChild("Shared", 5)
			local framework = shared:WaitForChild("Framework", 5)
			local classes = framework:WaitForChild("Classes", 5)
			return require(classes:WaitForChild("Chunker", 5))
		end)
	end
	if not ChunkerModule then
		ChunkerModule = safeRequireTable(function()
			return require(ReplicatedStorage.Shared.Framework.Classes.Chunker)
		end)
	end

	return ChunkerModule
end
function refreshChunkerAroundPlayer()
	local character = LocalPlayer.Character
	local humanoidRootPart = character and character:FindFirstChild("HumanoidRootPart")
	local playerPosition = humanoidRootPart and humanoidRootPart.Position
	local optimizer=activeStates.BGSI_Lite_MemoryOptimizer
	if optimizer then optimizer.RefreshChunks(playerPosition) end
	if not playerPosition then return end
	local ChunkerModule = getChunkerModule()
	if not ChunkerModule or type(ChunkerModule.Update) ~= "function" then return end

	for _, entryName in ipairs({
		"Instance",
		"Singleton",
		"Client",
		"Chunker",
		"Active",
	}) do
		local chunkerInstance = rawget(ChunkerModule, entryName)
		if type(chunkerInstance) == "table" and type(chunkerInstance.Update) == "function" then
			pcall(function()
				chunkerInstance:Update(playerPosition)
			end)
		end
	end
end
Config = loadConfig()
activeStates._1rzHubLiteActiveConfig = Config
activeStates.BGSI_Lite_ConfigResetPending = false
pcall(function()
	if writefile then
		writefile(configFile, HttpService:JSONEncode(Config))
	end
end)
do
	local dashboardDefaultHost = "https://larplite.xyz"
	local configuredDashboardEndpoint = tostring(Config.dashboardEndpoint or ""):match("^%s*(.-)%s*$") or ""
	local isDefaultHost = configuredDashboardEndpoint:gsub("/+$", ""):lower():match("^https?://larplite%.xyz$")
		or configuredDashboardEndpoint:gsub("/+$", ""):lower() == "larplite.xyz"
	if configuredDashboardEndpoint == "" or isDefaultHost then
		if Config.dashboardEndpoint ~= dashboardDefaultHost then
			Config.dashboardEndpoint = dashboardDefaultHost
			saveConfig()
		end
	end
end
do
	local SHARED_KEY_FILE = "LarpLiteFleet_dashboard_key.txt"
	local LOCK_FILE = "LarpLiteFleet_dashboard_key.lock"
	local function validKey(value)
		local key = string.lower(tostring(value or ""):match("^%s*(.-)%s*$") or "")
		return (#key == 64 and key:match("^%x+$")) and key or nil
	end
	local function canUseFiles()
		return type(readfile) == "function" and type(writefile) == "function" and type(isfile) == "function"
	end
	local function readShared()
		if not canUseFiles() then
			return nil
		end
		local ok, content = pcall(function()
			return isfile(SHARED_KEY_FILE) and readfile(SHARED_KEY_FILE) or ""
		end)
		return ok and validKey(content) or nil
	end
	local function dashboardBaseUrl()
		local endpoint = tostring(Config.dashboardEndpoint or ""):match("^%s*(.-)%s*$") or ""
		endpoint = endpoint:gsub("/api/.*$", ""):gsub("/+$", "")
		if endpoint == "" then
			endpoint = "https://larplite.xyz"
		end
		if not endpoint:match("^https?://") then
			endpoint = "https://" .. endpoint
		end
		return endpoint
	end
	activeStates.BGSI_Lite_ValidDashboardKey = validKey
	activeStates.BGSI_Lite_ShareDashboardKey = function(key)
		key = validKey(key)
		if key and canUseFiles() then
			pcall(writefile, SHARED_KEY_FILE, key)
		end
	end
	local requestInFlight = false
	local lastRequestAt = -math.huge
	activeStates.BGSI_Lite_EnsureFleetDashboardKey = function(requestFunction)
		local sharedKey = readShared()
		if sharedKey then
			if Config.dashboardIngestToken ~= sharedKey then
				Config.dashboardIngestToken = sharedKey
				saveConfig()
			end
			return sharedKey
		end
		local ownKey = validKey(Config.dashboardIngestToken)
		if ownKey then
			activeStates.BGSI_Lite_ShareDashboardKey(ownKey)
			return ownKey
		end
		if requestInFlight or type(requestFunction) ~= "function" or tick() - lastRequestAt < 60 then
			return nil
		end
		requestInFlight = true
		lastRequestAt = tick()
		-- One account asks; the others see the lock and wait for the shared file instead
		-- of each minting a key of their own.
		if canUseFiles() then
			local lockOk, lockAge = pcall(function()
				return isfile(LOCK_FILE) and (os.time() - (tonumber(readfile(LOCK_FILE)) or 0)) or math.huge
			end)
			if lockOk and lockAge < 30 then
				requestInFlight = false
				lastRequestAt = tick() - 55
				return nil
			end
			pcall(writefile, LOCK_FILE, tostring(os.time()))
			task.wait(0.3 + math.random() * 0.7)
			if readShared() then
				requestInFlight = false
				return activeStates.BGSI_Lite_EnsureFleetDashboardKey(requestFunction)
			end
		end
		local issuedKey
		pcall(function()
			local response = requestFunction({
				Url = dashboardBaseUrl() .. "/api/v1/ingest-key",
				Method = "POST",
				Headers = { ["Content-Type"] = "application/json" },
				Body = "{}",
				Timeout = 10,
			})
			local body = type(response) == "table" and tostring(response.Body or response.body or "") or ""
			local decoded = HttpService:JSONDecode(body)
			issuedKey = type(decoded) == "table" and validKey(decoded.ingestToken) or nil
		end)
		requestInFlight = false
		if canUseFiles() and type(delfile) == "function" then
			pcall(delfile, LOCK_FILE)
		end
		if not issuedKey then
			return nil
		end
		-- If another account won a race, its key wins so the fleet stays on one key.
		sharedKey = readShared()
		if sharedKey then
			issuedKey = sharedKey
		else
			activeStates.BGSI_Lite_ShareDashboardKey(issuedKey)
		end
		Config.dashboardIngestToken = issuedKey
		saveConfig()
		print("[" .. LocalPlayer.Name .. "] Account Dashboard key ready. Copy it from the Leader tab.")
		return issuedKey
	end
end
do
	local presetKey = string.lower(tostring(rawget(activeStates, "LarpliteKey") or ""):match("^%s*(.-)%s*$") or "")
	if #presetKey == 64 and presetKey:match("^%x+$") and Config.dashboardIngestToken ~= presetKey then
		Config.dashboardIngestToken = presetKey
		saveConfig()
		activeStates.BGSI_Lite_ShareDashboardKey(presetKey)
	end
end
if Config.dashboardSyncAutoEnabled ~= true then
	Config.dashboardSyncEnabled = true
	Config.dashboardSyncAutoEnabled = true
	saveConfig()
end
Config.SkyAltarEnabled = Config.SkyAltarEnabled == true
Config.WinterAltarEnabled = Config.WinterAltarEnabled == true
if type(Config.WinterAltarPets) ~= "table" then
	Config.WinterAltarPets = {}
end
Config.chunkerRenderDistance = math.max(1, math.floor(tonumber(Config.chunkerRenderDistance) or 2))
Config.setfps = math.max(1, math.floor(tonumber(Config.setfps) or 60))
_G.BGSI_CHUNK_RENDER_DISTANCE = Config.chunkerRenderDistance
pcall(function()
	if activeStates.BGSI_Lite_OriginalQualityLevel == nil then
		activeStates.BGSI_Lite_OriginalQualityLevel = settings().Rendering.QualityLevel
	end
end)
pcall(function()
	if activeStates.BGSI_Lite_OriginalSavedQualityLevel == nil then
		activeStates.BGSI_Lite_OriginalSavedQualityLevel =
			UserSettings():GetService("UserGameSettings").SavedQualityLevel
	end
end)
pcall(function()
	if activeStates.BGSI_Lite_OriginalFpsCap==nil then
		local getter=rawget(activeStates,"getfpscap") or rawget(activeStates,"get_fps_cap")
		local ok,value=false,nil
		if type(getter)=="function" then ok,value=pcall(getter) end
		if not ok or type(value)~="number" then
			ok,value=pcall(function() return UserSettings():GetService("UserGameSettings").FramerateCap end)
		end
		if ok and type(value)=="number" and value==value and value>=0 and value<math.huge then
			activeStates.BGSI_Lite_OriginalFpsCap=value
		end
	end
end)
do
    if activeStates.BGSI_Lite_MemoryOptimizer then pcall(activeStates.BGSI_Lite_MemoryOptimizer.Destroy) end
    local patchChunker=(function()
-- Preserve native chunk ranges and remove loaded flags for coordinates with no data.
return function(module,ctx)
    if type(module)~="table" or type(module.Update)~="function" then return nil end
    if module._BGSI_MEMORY_PATCH then module._BGSI_MEMORY_PATCH.Destroy() end
    local update=module._BGSI_CHUNKER_TRUE_UPDATE or module.Update
    local remove=module._BGSI_CHUNKER_TRUE_REMOVE or module.Remove
    module._BGSI_CHUNKER_TRUE_UPDATE=update
    module._BGSI_CHUNKER_TRUE_REMOVE=remove
    local tracked=setmetatable({}, {__mode="k"})
    local live=true
    local patch={}
    local function enabled() return live and ctx.Active() and ctx.Enabled() end
    local function sweep(self)
        if type(self._loaded)~="table" or type(self._chunks)~="table" then return end
        for coord in pairs(self._loaded) do
            if self._chunks[coord]==nil then self._loaded[coord]=nil;ctx.Pruned(1) end
        end
    end
    local function wrappedUpdate(self,position,...)
        if type(self)=="table" and live and ctx.Active() then
            local record=tracked[self]
            if not record then
                record={distance=self._BGSI_LITE_ORIGINAL_RENDER_DISTANCE or self.RenderDistance,swept=-math.huge}
                tracked[self]=record
            end
            local limit=ctx.DistanceCap()
            local original=tonumber(record.distance)
            local desired=limit and original and math.min(original,math.max(1,math.floor(limit))) or record.distance
            self.RenderDistance=desired;record.applied=desired
            if enabled() and ctx.Now()-record.swept>=30 then record.swept=ctx.Now();sweep(self) end
        end
        return update(self,position,...)
    end
    local function wrappedRemove(self,position,...)
        local results=table.pack(remove(self,position,...))
        if enabled() and type(self)=="table" and type(self._loaded)=="table" and type(self._chunks)=="table" then
            local coord=self:ToCoord(position)
            if self._loaded[coord]~=nil and self._chunks[coord]==nil then self._loaded[coord]=nil;ctx.Pruned(1) end
        end
        return table.unpack(results,1,results.n)
    end
    function patch.Refresh(position)
        if not live or not ctx.Active() then return end
        for self,record in pairs(tracked) do
            if position then pcall(wrappedUpdate,self,position)
            else self.RenderDistance=record.distance;record.applied=record.distance end
        end
    end
    function patch.Visit(visitor)
        if live then for self in pairs(tracked) do visitor(self) end end
    end
    function patch.Destroy()
        if not live then return end
        live=false
        if module.Update==wrappedUpdate then module.Update=update end
        if module.Remove==wrappedRemove then module.Remove=remove end
        local position
        if ctx.Position then local ok,value=pcall(ctx.Position);if ok then position=value end end
        for self,record in pairs(tracked) do
            if self.RenderDistance==record.applied then self.RenderDistance=record.distance end
            self._BGSI_LITE_ORIGINAL_RENDER_DISTANCE=nil
            if position then pcall(update,self,position) end
        end
        table.clear(tracked)
        if module._BGSI_MEMORY_PATCH==patch then module._BGSI_MEMORY_PATCH=nil end
    end
    module.Update=wrappedUpdate
    if type(remove)=="function" then module.Remove=wrappedRemove end
    module._BGSI_MEMORY_PATCH=patch
    return patch
end

    end)()
    local install=(function()
-- Visual-only changes. Never delete game content, clear native pools, or change physics.
return function(ctx)
    local live,enabled,meshEnabled=true,false,false
    local originals=setmetatable({}, {__mode="k"})
    local stack,added={},{}
    local addedHead,addedTail=1,0
    local rescan=false
    local pending=setmetatable({}, {__mode="k"})
    local connection,lowConnection
    local low,lowOriginal,writingLow
    local lowPending,lowEpoch={},0
    local report={meshesChanged=0,chunkKeysFreed=0}
    local patch,chunkModule
    local api={Report=report}
    local function setLow(value)
        if not low or low.Enabled==value then return end
        writingLow=true
        if lowConnection then lowPending[#lowPending+1]=value end
        low.Enabled=value
        if low.Changed then
            local ok=pcall(low.Changed.Fire,low.Changed,value)
            if not ok then table.clear(lowPending) end
        end
        writingLow=false
    end
    local function inspect(instance)
        if not enabled or not live or not instance:IsA("MeshPart") or not instance:IsDescendantOf(ctx.Root) then return end
        local parent=instance.Parent
        while parent and parent~=ctx.Root do
            if parent:IsA("GuiBase2d") or parent:IsA("LayerCollector") or parent:IsA("ViewportFrame") then return end
            if parent:IsA("Model") and parent:FindFirstChildOfClass("Humanoid") then return end
            parent=parent.Parent
        end
        if originals[instance] then return end
        local ok,before=pcall(function() return instance.RenderFidelity end)
        if ok and before~=ctx.Fidelity then
            local success=pcall(function() instance.RenderFidelity=ctx.Fidelity end)
            if success then originals[instance]=before;report.meshesChanged+=1 end
        end
    end
    local function enqueue(instance)
        if not enabled or not meshEnabled or not instance:IsA("MeshPart") or pending[instance] then return end
        -- Coalesce large streaming bursts into one incremental rescan, never a frame spike.
        if addedTail-addedHead>=2047 then rescan=true;return end
        pending[instance]=true;addedTail+=1;added[addedTail]=instance
    end
    function api.SetEnabled(value)
        value=value==true
        local meshes=value and (not ctx.MeshDetail or ctx.MeshDetail()==true)
        if not live or (value==enabled and meshes==meshEnabled) then return end
        if enabled and value then api.SetEnabled(false) end
        enabled=value
        meshEnabled=meshes
        if value then
            local ok,result=pcall(ctx.LowDetail)
            if ok and type(result)=="table" and type(result.Enabled)=="boolean" then
                low=result;lowOriginal=low.Enabled
                lowEpoch+=1;local epoch=lowEpoch
                table.clear(lowPending)
                if low.Changed and type(low.Changed.Connect)=="function" then
                    lowConnection=low.Changed:Connect(function(value)
                        if epoch~=lowEpoch or not enabled then return end
                        if #lowPending>0 and lowPending[1]==value then table.remove(lowPending,1);return end
                        if not writingLow then lowOriginal=low.Enabled end
                    end)
                end
                setLow(true)
            end
            if meshEnabled then
                connection=ctx.Root.DescendantAdded:Connect(enqueue)
                stack={ctx.Root}
            end
        else
            lowEpoch+=1;table.clear(lowPending)
            if connection then connection:Disconnect();connection=nil end
            if lowConnection then lowConnection:Disconnect();lowConnection=nil end
            if low then setLow(lowOriginal);low=nil end
            for instance,before in pairs(originals) do
                pcall(function() if instance.RenderFidelity==ctx.Fidelity then instance.RenderFidelity=before end end)
            end
            table.clear(originals);table.clear(stack);table.clear(added);table.clear(pending)
            addedHead=1;addedTail=0;rescan=false;report.meshesChanged=0
        end
    end
    function api.Step()
        if not live or not enabled or not meshEnabled or not ctx.Active() then return end
        local started=ctx.Now()
        for _=1,128 do
            local instance
            if addedHead<=addedTail then
                instance=added[addedHead];added[addedHead]=nil;addedHead+=1;pending[instance]=nil
                inspect(instance)
            else
                if addedTail>0 then table.clear(added);addedHead=1;addedTail=0 end
                if #stack==0 and rescan then stack={ctx.Root};rescan=false end
                instance=table.remove(stack)
                if not instance then break end
                if instance==ctx.Root or instance:IsDescendantOf(ctx.Root) then
                    inspect(instance)
                    if not instance:IsA("GuiBase2d") and not instance:IsA("LayerCollector") then
                        for _,child in ipairs(instance:GetChildren()) do stack[#stack+1]=child end
                    end
                end
            end
            if ctx.Now()-started>=0.002 then break end
        end
    end
    function api.InstallChunker(module)
        if patch and module==chunkModule then return true end
        if patch then patch.Destroy() end
        patch=ctx.PatchChunker(module,{
            Active=function() return live and ctx.Active() end,
            Enabled=function() return enabled end,DistanceCap=ctx.DistanceCap,Now=ctx.Now,Position=ctx.Position,
            Pruned=function(count) report.chunkKeysFreed+=count end,
        })
        chunkModule=module
        return patch~=nil
    end
    function api.Sample()
        if not live then return report end
        local ok,stats=pcall(ctx.Sample)
        if ok and type(stats)=="table" then
            report.totalMB=stats.totalMB;report.luaMB=stats.luaMB
            report.texturesMB=stats.texturesMB;report.meshesMB=stats.meshesMB
            report.vmMB=stats.vmMB
        end
        if api.OnReport then pcall(api.OnReport,report) end
        return report
    end
    function api.RefreshChunks(position)
        if live and patch then patch.Refresh(position) end
    end
    function api.VisitChunkers(visitor)
        if live and patch then patch.Visit(visitor) end
    end
    function api.Pending() return rescan or #stack>0 or addedHead<=addedTail end
    function api.Destroy()
        if not live then return end
        api.SetEnabled(false);live=false
        if patch then patch.Destroy();patch=nil end
        api.OnReport=nil;chunkModule=nil
    end
    return api
end

    end)()
    local statsService=game:GetService("Stats")
    local historyFile="LarpLiteMemory_"..configAccountId..".json"
    local samples=activeStates.BGSI_Lite_MemorySamples
    if type(samples)~="table" then
        samples={}
        if type(readfile)=="function" and type(isfile)=="function" then
            local ok,data=pcall(function()
                if not isfile(historyFile) then return nil end
                local text=readfile(historyFile)
                if type(text)~="string" or #text>131072 then return nil end
                return HttpService:JSONDecode(text)
            end)
            if ok and type(data)=="table" and data.schema==1 and type(data.samples)=="table" then samples=data.samples end
        end
    end
    local history=(function()
-- Bounded numeric diagnostics, sampled once per minute or on a mode transition.
return function(ctx)
    local history=ctx.History
    if type(history)~="table" then history={} end
    local clean={}
    local function valid(value) return type(value)=="number" and value==value and math.abs(value)<math.huge end
    for _,row in ipairs(history) do
        if type(row)=="table" and valid(row.time) and type(row.version)=="string" and type(row.mode)=="string" then
            local entry={time=row.time,version=row.version:sub(1,80),mode=row.mode:sub(1,40)}
            for _,key in ipairs({"runSeconds","totalMB","luaMB","vmMB","texturesMB","meshesMB"}) do
                if valid(row[key]) then entry[key]=row[key] end
            end
            clean[#clean+1]=entry
        end
    end
    while #clean>120 do table.remove(clean,1) end
    table.clear(history);for i,row in ipairs(clean) do history[i]=row end
    local started,nextAt,lastMode=ctx.Now(),-math.huge,nil
    local api={Samples=history}
    function api.Record(report)
        local now,mode=ctx.Now(),ctx.Mode()
        if now<nextAt and mode==lastMode then return false end
        nextAt=now+60;lastMode=mode
        local row={time=ctx.Time(),version=ctx.Version,mode=mode,runSeconds=math.max(0,now-started)}
        for _,key in ipairs({"totalMB","luaMB","vmMB","texturesMB","meshesMB"}) do if valid(report[key]) then row[key]=report[key] end end
        history[#history+1]=row
        if #history>120 then table.remove(history,1) end
        if ctx.Save then pcall(ctx.Save,{schema=1,samples=history}) end
        return true
    end
    return api
end

    end)()({History=samples,Version=activeStates.BGSI_Lite_ScriptVersion,Now=os.clock,Time=os.time,
        Mode=function()
            if activeStates._1rzHubLite_LoadComplete~=true then return "loading" end
            if Config.safeMode then return "safe" end
            if not Config.autoOptimizeMemory then return "off" end
            return Config.optimizeMeshDetail and "low-detail+mesh" or "native-low-detail"
        end,
        Save=type(writefile)=="function" and function(data) writefile(historyFile,HttpService:JSONEncode(data)) end or nil,
    })
    activeStates.BGSI_Lite_MemorySamples=history.Samples
    local optimizer=install({
        Root=Workspace,Fidelity=Enum.RenderFidelity.Performance,Active=isCurrentRun,Now=os.clock,
        PatchChunker=patchChunker,
        MeshDetail=function() return Config.optimizeMeshDetail==true end,
        Position=function()
            local character=LocalPlayer.Character
            local root=character and character:FindFirstChild("HumanoidRootPart")
            return root and root.Position
        end,
        DistanceCap=function()
            if Config.safeMode~=true and Config.disableRendering~=true then
                return math.max(1,math.floor(tonumber(Config.chunkerRenderDistance) or 2))
            end
        end,
        LowDetail=function() return require(ReplicatedStorage.Client.LowDetail) end,
        Sample=function()
            local result={}
            local ok,total=pcall(statsService.GetTotalMemoryUsageMb,statsService)
            if ok then result.totalMB=total end
            if type(gcinfo)=="function" then
                local success,value=pcall(gcinfo)
                if success and type(value)=="number" then result.vmMB=value/1024 end
            end
            for key,name in pairs({luaMB="LuaHeap",texturesMB="GraphicsTexture",meshesMB="GraphicsMeshParts"}) do
                local success,value=pcall(function()
                    if not statsService.MemoryTrackingEnabled then return nil end
                    return statsService:GetMemoryUsageMbForTag(Enum.DeveloperMemoryTag[name])
                end)
                if success then result[key]=value end
            end
            return result
        end,
    })
    activeStates.BGSI_Lite_MemoryOptimizer=optimizer
    task.spawn(function()
        local nextSample=0
        while isCurrentRun() do
            local ok,reason=pcall(function()
                optimizer.Step()
                if os.clock()>=nextSample then nextSample=os.clock()+5;history.Record(optimizer.Sample()) end
            end)
            if not ok then warn("[LarpLite] Memory optimizer: "..tostring(reason)) end
            task.wait(optimizer.Pending() and 0.03 or 1)
        end
        optimizer.Destroy()
    end)
end
activeStates.BGSI_Lite_RestorePerformanceBaseline = function()
		pcall(function()
			if activeStates.BGSI_Lite_OriginalQualityLevel ~= nil then
				settings().Rendering.QualityLevel = activeStates.BGSI_Lite_OriginalQualityLevel
			end
		end)
		pcall(function()
			if activeStates.BGSI_Lite_OriginalSavedQualityLevel ~= nil then
				UserSettings():GetService("UserGameSettings").SavedQualityLevel =
					activeStates.BGSI_Lite_OriginalSavedQualityLevel
			end
		end)
		pcall(function()
			local fpsCapFunction = rawget(activeStates, "setfpscap") or rawget(activeStates, "set_fps_cap")
			if type(fpsCapFunction) == "function" and type(activeStates.BGSI_Lite_OriginalFpsCap)=="number" then
				fpsCapFunction(activeStates.BGSI_Lite_OriginalFpsCap)
			end
		end)
	pcall(function() RunService:Set3dRenderingEnabled(true) end)
end
activeStates.BGSI_Lite_ApplyPerformanceSettings = function()
	if activeStates.BGSI_Lite_MemoryOptimizer then
		activeStates.BGSI_Lite_MemoryOptimizer.SetEnabled(Config.autoOptimizeMemory==true and Config.safeMode~=true)
	end
	if Config.safeMode == true then
		activeStates.BGSI_Lite_RestorePerformanceBaseline()
		return
	end
	pcall(function()
		if activeStates.BGSI_Lite_OriginalQualityLevel~=nil then settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end
	end)
	pcall(function()
		if activeStates.BGSI_Lite_OriginalSavedQualityLevel~=nil then UserSettings():GetService("UserGameSettings").SavedQualityLevel = Enum.SavedQualitySetting.QualityLevel1 end
	end)
	pcall(function()
		local fpsCapFunction = rawget(activeStates, "setfpscap") or rawget(activeStates, "set_fps_cap")
		if type(fpsCapFunction) == "function" and type(activeStates.BGSI_Lite_OriginalFpsCap)=="number" then
			fpsCapFunction(Config.setfps)
		end
	end)
end
activeStates.BGSI_Lite_SetSafeMode = function(enabled)
	enabled = enabled == true
	if enabled and Config.safeMode ~= true then
		local snapshotOk, snapshot = pcall(function()
			return HttpService:JSONDecode(HttpService:JSONEncode(Config))
		end)
		Config.safeModeSavedConfig = snapshotOk and type(snapshot) == "table" and snapshot or {}
		Config.safeModeSavedConfig.safeMode = nil
		Config.safeModeSavedConfig.safeModeSavedConfig = nil
	end
	if enabled then
		Config.safeMode = true
		for configKey, defaultValue in pairs(defaultConfig) do
			if
				type(defaultValue) == "boolean"
				and not activeStates.BGSI_Lite_SafeModePreservedKeys[configKey]
			then
				Config[configKey] = false
			end
		end
		Config.disableRendering = false
		activeStates.BGSI_Lite_ActiveQuest = nil
		activeStates.BGSI_Lite_SeasonActive = false
		activeStates.BGSI_Lite_ChallengePassActive = false
		activeStates.BGSI_Lite_GlobalIncentiveActive = false
		activeStates.BGSI_Lite_GemGenieActive = false
		activeStates.BGSI_Lite_TicketPickupActive = false
		activeStates.BGSI_Lite_CarnivalPickupActive = false
		activeStates.BGSI_Lite_LuckEggActive = false
		activeStates.BGSI_Lite_SpecialRiftActive = false
		activeStates.BGSI_Lite_IdleHatchFallbackActive = false
	else
		local savedConfig = type(Config.safeModeSavedConfig) == "table" and Config.safeModeSavedConfig or {}
		for configKey, savedValue in pairs(savedConfig) do
			if
				defaultConfig[configKey] ~= nil
				and not activeStates.BGSI_Lite_SafeModePreservedKeys[configKey]
				and typeof(savedValue) == typeof(defaultConfig[configKey])
			then
				Config[configKey] = savedValue
			end
		end
		Config.safeMode = false
		Config.safeModeSavedConfig = {}
	end
	_G.BGSI_CHUNK_RENDER_DISTANCE = Config.chunkerRenderDistance
	pcall(function()
		RunService:Set3dRenderingEnabled(enabled or not Config.disableRendering)
	end)
	pcall(function()
		if type(activeStates.BGSI_Lite_ApplyHatchAnimationSetting) == "function" then
			activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
		end
	end)
	activeStates.BGSI_Lite_ApplyPerformanceSettings()
	refreshChunkerAroundPlayer()
	saveConfig()
end
if Config.safeMode == true then
	activeStates.BGSI_Lite_SetSafeMode(true)
else
	activeStates.BGSI_Lite_ApplyPerformanceSettings()
end
activeStates.BGSI_Lite_ActivateIntroButton = function(button)
	if not button or not button:IsA("GuiButton") or not button.Visible then
		return false
	end
	if type(firesignal) == "function" then
		local fired = pcall(function()
			firesignal(button.Activated)
		end)
		if fired then
			return true
		end
	end
	local activated = pcall(function()
		button:SetAttribute("ButtonActivated", true)
		task.wait()
		button:SetAttribute("Pressed", true)
		task.wait()
		button:SetAttribute("Pressed", false)
		task.wait()
		button:SetAttribute("ButtonActivated", false)
	end)
	if activated then
		return true
	end
	return pcall(function()
		button:Activate()
	end)
end
activeStates.BGSI_Lite_SkipIntro = function()
	if Config.autoSkipIntro ~= true or Config.safeMode == true then
		return false
	end
	local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	if not playerGui then
		return false
	end
	local intro = playerGui:FindFirstChild("Intro")
	if not intro or not intro.Enabled then
		return false
	end
	local play = intro:FindFirstChild("Play")
	local playButton = play and play:FindFirstChild("Button")
	if play and play.Visible then
		return activeStates.BGSI_Lite_ActivateIntroButton(playButton)
	end
	local graphics = intro:FindFirstChild("Graphics")
	local content = graphics and graphics:FindFirstChild("Content")
	local low = content and content:FindFirstChild("Low")
	local lowAction = low and low:FindFirstChild("Action")
	local lowButton = lowAction and lowAction:FindFirstChild("Button")
	if graphics and graphics.Visible then
		return activeStates.BGSI_Lite_ActivateIntroButton(lowButton)
	end
	return false
end
task.spawn(function()
	local introDeadline = tick() + 180
	local introFound = false
	repeat
		local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local intro = playerGui and playerGui:FindFirstChild("Intro")
		if intro then
			introFound = true
		elseif introFound then
			break
		end
		activeStates.BGSI_Lite_SkipIntro()
		task.wait(0.1)
	until tick() >= introDeadline or not isCurrentRun()
end)
activeStates.BGSI_Lite_CloseRareHatchPopup = function()
	if Config.safeMode == true then
		return false
	end
	local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
	local afkReveal = screenGui and screenGui:FindFirstChild("AFKReveal")
	local closeButton = afkReveal and afkReveal:FindFirstChild("Close")
	if
		not afkReveal
		or afkReveal.Visible ~= true
		or not closeButton
		or not closeButton:IsA("GuiButton")
		or closeButton.Visible ~= true
	then
		return false
	end
	pcall(function()
		closeButton:Activate()
	end)
	return true
end
task.spawn(function()
	while isCurrentRun() do
		task.wait(0.05)
		activeStates.BGSI_Lite_CloseRareHatchPopup()
	end
end)
function installChunkerRenderDistanceHook()
	local ChunkerModule = getChunkerModule()
	local optimizer=activeStates.BGSI_Lite_MemoryOptimizer
	return optimizer and optimizer.InstallChunker(ChunkerModule) or false
end
task.defer(function()
	for _ = 1, 40 do
		if installChunkerRenderDistanceHook() then
			refreshChunkerAroundPlayer()
			return
		end
		task.wait(0.5)
	end
	warn("[1rzHub Lite] Chunker render-distance hook could not find the Chunker module.")
end)
for loopSlotBI, scriptStateAAX in pairs(defaultConfig) do
	if Config[loopSlotBI] == nil then
		Config[loopSlotBI] = scriptStateAAX
	end
end
activeStates.AutoGuessThatPet = Config.autoGuessThatPet
activeStates.BGSI_Lite_FleetUiControls = {}
activeStates.BGSI_Lite_RegisterFleetUiControl = function(flag, control, properties, kind)
	if type(flag) == "string" and type(control) == "table" then
		control.FleetMulti = type(properties) == "table" and properties.Multi == true
		control.FleetInput = kind == "input"
		activeStates.BGSI_Lite_FleetUiControls[flag] = control
	end
	return control
end
activeStates.BGSI_Lite_RefreshFleetUiControls = function(source)
	if type(source) ~= "table" then return end
	local keysByLowerName = {}
	for configKey in pairs(defaultConfig) do
		keysByLowerName[string.lower(configKey)] = configKey
	end
	local alternateKeys = {
		AdminRebirthMachinePetName = "AdminRebirthPetName",
		AutoAdminRebirthMachine = "AdminRebirthMachineEnabled",
		AutoDailyHourly = "autoDailyHourlyChallenge",
		AutoRebirthMachine = "RebirthMachineEnabled",
		AutoSellBubble = "autoSell",
		AutoWinterAltar = "WinterAltarEnabled",
		AutoSetupTeamKeepUpdated = "autoSetupTeamEnabled",
		AutoShrine = "shrineAuto",
		HalloweenShrinePotion = "halloweenShrinePotion",
		AutoUsePotions = "potionAuto",
		DreamShrine = "DreamerShrineEnabled",
		DreamShrineAmount = "DreamerShrineAmount",
		EnchantCurrency = "equippedEnchantCurrency",
		GemGenieTarget = "gemGenieTargetItem",
		LowCoins = "webhookLowCoinsBelow",
		LowCurrencyCooldown = "webhookLowCurrencyCooldownMinutes",
		LowCurrencyEnabled = "webhookLowCurrencyEnabled",
		LowGems = "webhookLowGemsBelow",
		LowPearls = "webhookLowPearlsBelow",
		LowTickets = "webhookLowTicketsBelow",
		PearlPetTeam = "selectedPearlTeam",
		PearlReturnPetTeam = "selectedPearlReturnTeam",
		QuestStallTimeout = "questStallTimeoutSeconds",
		RebirthMachinePetName = "RebirthPetName",
		ReenchantThreshold = "equippedReenchantThreshold",
		SelectedRiftChest = "selectedChest",
		SelectEgg = "selectedEgg",
		SelectInventoryEgg = "selectedInventoryEgg",
		SelectRiftEgg = "selectedRiftEgg",
		ShadowLeviathanTarget = "shadowLeviathanTargetItem",
		ShopBuyInterval = "shopInterval",
		TargetEnchant1 = "equippedTargetEnchant",
		TargetEnchant2 = "equippedTargetEnchant2",
		TargetEnchantLevel = "equippedTargetEnchantLevel",
		TargetRiftHopIds = "targetRiftIds",
		TicketPetTeam = "selectedTicketTeam",
		TicketReturnPetTeam = "selectedTicketReturnTeam",
		WebhookHideName = "webhookHidePlayerName",
	}
	for flag, control in pairs(activeStates.BGSI_Lite_FleetUiControls) do
		local value
		local superKey = flag:match("^AutoSetupTeamSuperCount_(.+)$")
		if superKey then
			local counts = source.autoSetupTeamSuperCounts
			value = type(counts) == "table" and counts[superKey] or nil
		elseif flag == "RebirthMachineVariant" then
			value = type(source.RebirthVariants) == "table" and source.RebirthVariants[1] or nil
		else
			local configKey = alternateKeys[flag] or keysByLowerName[string.lower(flag)]
			value = configKey and source[configKey] or nil
		end
		if value~=nil and type(control.FleetValueTransform)=="function"then value=control.FleetValueTransform(value)end
		if control.FleetMulti and type(value) == "table" then
			local selectedValues = {}
			for key, selected in pairs(value) do
				if type(key) == "number" and type(selected) == "string" then
					table.insert(selectedValues, selected)
				elseif type(key) == "string" and selected == true then
					table.insert(selectedValues, key)
				end
			end
			value = selectedValues
		elseif control.FleetInput and value ~= nil then
			value = tostring(value)
		end
		if value ~= nil and control.Native and type(control.Native.Set) == "function" then
			pcall(control.Native.Set, control.Native, value, true)
		end
	end
end
Interface = nil
do
	local rayfieldFile = "RayfieldGen2.lua"
	local libraryEnvironment=_LarpLiteExternalEnvironment or getfenv()
	local installRayfieldRuntime=(function()
-- Rayfield alone gets this compatibility environment; executor globals are untouched.
return function(ctx)
    local original=ctx.Environment
    local dataModel=ctx.Game
    local known=ctx.Services or {}
    local typeOf=original.typeof or typeof
    local clone=original.cloneref
    local function instance(value) return value~=nil and typeOf(value)=="Instance" end
    local function resolve(name)
        if instance(known[name]) then return known[name] end
        for _,method in ipairs({"GetService","FindService","FindFirstChild"}) do
            local ok,value=pcall(function() return dataModel[method](dataModel,name) end)
            if ok and instance(value) then known[name]=value;return value end
        end
        error("[LarpLite] Rayfield service unavailable: "..tostring(name),2)
    end
    local function safeClone(value)
        if value==nil or not instance(value) or type(clone)~="function" then return value end
        local ok,result=pcall(clone,value)
        if ok and instance(result) then return result end
        return value
    end
    local environment=setmetatable({_LarpLiteUiService=resolve,cloneref=safeClone},{__index=original})
    return {
        Environment=environment,
        Prepare=function(text)
            -- Covers both parenthesized and string-literal calls in Rayfield's two service helpers.
            return (text:gsub("game%s*:%s*GetService", "_LarpLiteUiService"))
        end,
    }
end

	end)()
	setfenv(installRayfieldRuntime,libraryEnvironment)
	local rayfieldRuntime=installRayfieldRuntime({Environment=libraryEnvironment,Game=game,
		Services={Players=Players,ReplicatedStorage=ReplicatedStorage,Workspace=Workspace,
			HttpService=HttpService,RunService=RunService,CoreGui=CoreGui,UserInputService=UserInputService}})
	local function compileRayfield(text)
		if type(text)~="string" or #text<=10000 or not text:find("CreateDropdown",1,true) or not text:find("CreateStat",1,true) then return nil end
		local chunk=loadstring(rayfieldRuntime.Prepare(text),"@LarpLite/Rayfield")
		if type(chunk)~="function" then return nil end
		setfenv(chunk,rayfieldRuntime.Environment)
		return chunk
	end
	local rayfieldChunk
	if type(isfile)=="function" and type(readfile)=="function" then
		local ok,cached=pcall(function() if isfile(rayfieldFile) then return readfile(rayfieldFile) end end)
		if ok then rayfieldChunk=compileRayfield(cached) end
	end
	if not rayfieldChunk then
		local text=game:HttpGet("https://sirius.menu/gen2")
		rayfieldChunk=assert(compileRayfield(text),"[LarpLite] Invalid Rayfield Gen2 source")
		if type(writefile)=="function" then pcall(writefile,rayfieldFile,text) end
	end
	local Rayfield=rayfieldChunk()
	rayfieldChunk=nil

	local rayfieldWindow

	local function getDefaultValue(properties)
		local defaultValue = properties.Default
		if properties.Multi then
			if type(defaultValue) ~= "table" then
				return defaultValue and { tostring(defaultValue) } or {}
			end
			local selectedValues = {}
			for key, value in pairs(defaultValue) do
				if type(key) == "number" and type(value) == "string" then
					table.insert(selectedValues, value)
				elseif value == true and type(key) == "string" then
					table.insert(selectedValues, key)
				end
			end
			return selectedValues
		end
		if type(defaultValue) == "table" then
			return defaultValue[1]
		end
		if type(defaultValue) == "number" and type(properties.Values) == "table" then
			return properties.Values[defaultValue]
		end
		return defaultValue
	end

	local function wrapValueElement(element)
		local wrappedElement = {
			Native = element,
		}
		function wrappedElement:SetValue(value)
			self.Native:Set(value)
		end
		-- 1.2.0: locking dims a control, blocks input, and stops its callback from firing.
		function wrappedElement:Lock(reason)
			self.Native:Lock(reason)
		end
		function wrappedElement:Unlock()
			self.Native:Unlock()
		end
		function wrappedElement:IsLocked()
			return self.Native:IsLocked()
		end
		return wrappedElement
	end

	local function wrapTextElement(element)
		local wrappedElement = {
			Native = element,
		}
		function wrappedElement:Set(text)
			self.Native:Set(text)
		end
		function wrappedElement:SetTitle(title)
			self.Native:SetTitle(title)
		end
		return wrappedElement
	end

	local function wrapDividerElement(element)
		local wrappedElement = {
			Native = element,
		}
		function wrappedElement:Set(text)
			self.Native:Set(text)
		end
		return wrappedElement
	end

	local function wrapProgressElement(element)
		local wrappedElement = {
			Native = element,
		}
		function wrappedElement:Set(value)
			self.Native:Set(value)
		end
		function wrappedElement:Get()
			return self.Native:Get()
		end
		function wrappedElement:GetPercentage()
			return self.Native:GetPercentage()
		end
		function wrappedElement:SetRange(min, max)
			self.Native:SetRange(min, max)
		end
		function wrappedElement:SetText(text)
			self.Native:SetText(text)
		end
		function wrappedElement:SetIndeterminate(state)
			self.Native:SetIndeterminate(state)
		end
		return wrappedElement
	end

	local function wrapConsoleElement(element)
		local wrappedElement = {
			Native = element,
		}
		function wrappedElement:Get()
			return self.Native:Get()
		end
		function wrappedElement:Set(text)
			self.Native:Set(text)
		end
		function wrappedElement:Append(line)
			self.Native:Append(line)
		end
		function wrappedElement:Clear()
			self.Native:Clear()
		end
		function wrappedElement:Copy()
			return self.Native:Copy()
		end
		function wrappedElement:SetHeight(height)
			self.Native:SetHeight(height)
		end
		return wrappedElement
	end

	local function normalizeDropdownOptions(values)
		local normalizedOptions = {}
		local seenOptions = {}
		for _, value in ipairs(type(values) == "table" and values or {}) do
			if type(value) == "string" and value ~= "" and not seenOptions[value] then
				seenOptions[value] = true
				table.insert(normalizedOptions, value)
			end
		end
		return normalizedOptions
	end

	-- Per-option dropdown icons.
	--
	-- Rayfield's Dropdown only supports one icon for the whole control (next to its
	-- title) - individual options in the list are plain strings, no icon slot. Rather than
	-- rebuild the option list rendering ourselves, this hooks Dropdown:_rebindOption -
	-- a real method on the shared Dropdown class table (every dropdown is
	-- setmetatable(self, Dropdown), so patching it once via getmetatable affects every
	-- dropdown that exists now and every one created later) that Rayfield already calls
	-- whenever a recycled row gets pointed at a different option name (scrolling,
	-- searching, :Refresh()). Patching it means a row's icon updates in lockstep with
	-- Rayfield's own row-recycling instead of drifting out of sync with it.
	--
	-- The name -> icon lookup itself is built once, lazily, from the game's own data
	-- modules and cached in activeStates.BGSI_Lite_ItemIconLookup - after that first
	-- build every row just does one table read, no re-scanning ever.
	local function buildGlobalItemIconLookup()
		local lookup = {}
		local function setIcon(name, iconValue)
			if type(name) ~= "string" or name == "" or lookup[name] then
				return
			end
			local assetId = type(iconValue) == "string" and iconValue:match("(%d+)") or nil
			if assetId then
				lookup[name] = assetId
			end
		end
		if type(eggDataModule) == "table" then
			for eggName, eggInfo in pairs(eggDataModule) do
				if type(eggInfo) == "table" then
					setIcon(eggName, eggInfo.Image)
				end
			end
		end
		if type(giftData) == "table" then
			for itemName, itemInfo in pairs(giftData) do
				if type(itemInfo) == "table" then
					setIcon(itemName, itemInfo.Icon)
				end
			end
		end
		if type(enchantData) == "table" then
			for enchantName, enchantInfo in pairs(enchantData) do
				if type(enchantInfo) == "table" then
					setIcon(enchantName, enchantInfo.Icon)
				end
			end
		end
		local chestDataOk, chestDataModule = pcall(function()
			return require(ReplicatedStorage.Shared.Data.Chests)
		end)
		if chestDataOk and type(chestDataModule) == "table" then
			for chestName, chestInfo in pairs(chestDataModule) do
				if type(chestInfo) == "table" then
					setIcon(chestName, chestInfo.Icon)
				end
			end
		end
		if type(riftData) == "table" then
			for riftName, riftInfo in pairs(riftData) do
				if type(riftInfo) == "table" then
					setIcon(riftName, riftInfo.Icon)
				end
			end
		end
		if type(petRarityData) == "table" then
			for petName, petInfo in pairs(petRarityData) do
				if type(petInfo) == "table" and type(petInfo.Images) == "table" then
					setIcon(petName, petInfo.Images[1] or petInfo.Images.Normal)
				end
			end
		end
		return lookup
	end
	activeStates.BGSI_Lite_ResolveItemIconAssetId = function(name)
		if type(name) ~= "string" or name == "" then
			return nil
		end
		if not activeStates.BGSI_Lite_ItemIconLookup then
			activeStates.BGSI_Lite_ItemIconLookup = buildGlobalItemIconLookup()
		end
		return activeStates.BGSI_Lite_ItemIconLookup[name]
	end
	-- Creates or updates one row's icon in place - never recreated once built, only its
	-- Image/Visible flipped, so a recycled row is a cheap property write, not a new
	-- Instance every time it's pointed at a different (or the same) option again.
	activeStates.BGSI_Lite_ApplyDropdownRowIcon = function(rowData, optionName)
		if type(rowData) ~= "table" or not rowData.container then
			return
		end
		local iconAssetId = activeStates.BGSI_Lite_ResolveItemIconAssetId(optionName)
		if iconAssetId then
			if rowData.bgsiIcon then
				pcall(function()
					rowData.bgsiIcon.Image = "rbxassetid://" .. iconAssetId
					rowData.bgsiIcon.Visible = true
				end)
			else
				local createOk, iconLabel = pcall(function()
					local newIconLabel = Instance.new("ImageLabel")
					newIconLabel.Name = "BGSI_LiteOptionIcon"
					newIconLabel.Image = "rbxassetid://" .. iconAssetId
					newIconLabel.Size = UDim2.fromOffset(16, 16)
					newIconLabel.BackgroundTransparency = 1
					newIconLabel.BorderSizePixel = 0
					newIconLabel.ZIndex = 5
					newIconLabel.LayoutOrder = 0.5
					newIconLabel.Parent = rowData.container
					return newIconLabel
				end)
				if createOk and iconLabel then
					rowData.bgsiIcon = iconLabel
				end
			end
		elseif rowData.bgsiIcon then
			pcall(function()
				rowData.bgsiIcon.Visible = false
			end)
		end
	end
	-- Covers rows that don't go through _rebindOption: brand new rows a dropdown just
	-- built for the first time (initial creation, or :Refresh growing the list).
	activeStates.BGSI_Lite_RefreshDropdownIcons = function(nativeDropdown)
		if type(nativeDropdown) ~= "table" or type(nativeDropdown._optionFrames) ~= "table" then
			return
		end
		for _, rowData in ipairs(nativeDropdown._optionFrames) do
			activeStates.BGSI_Lite_ApplyDropdownRowIcon(rowData, rowData.name)
		end
	end
	activeStates.BGSI_Lite_PatchDropdownRebindForIcons = function(nativeDropdown)
		local dropdownClass = getmetatable(nativeDropdown)
		if type(dropdownClass) ~= "table" or dropdownClass._BGSI_LiteRebindPatched then
			return
		end
		dropdownClass._BGSI_LiteRebindPatched = true
		local originalRebindOption = dropdownClass._rebindOption
		if type(originalRebindOption) ~= "function" then
			return
		end
		dropdownClass._rebindOption = function(self, data, name, index)
			originalRebindOption(self, data, name, index)
			pcall(activeStates.BGSI_Lite_ApplyDropdownRowIcon, data, name)
		end
	end

	local function wrapDropdown(element)
		local wrappedElement = wrapValueElement(element)
		function wrappedElement:SetValues(values)
			self.Native:Refresh(normalizeDropdownOptions(values))
			activeStates.BGSI_Lite_RefreshDropdownIcons(self.Native)
		end
		function wrappedElement:Refresh(values)
			self.Native:Refresh(normalizeDropdownOptions(values))
			activeStates.BGSI_Lite_RefreshDropdownIcons(self.Native)
		end
		return wrappedElement
	end

	local tabMethods = {}
	function tabMethods:AddSection(title)
		return self.Native:CreateSection({ name = title })
	end
	function tabMethods:AddButton(properties)
		return self.Native:CreateButton({
			name = properties.Title,
			description = properties.Description,
			callback = properties.Callback,
		})
	end
	function tabMethods:AddToggle(flag, properties)
		return activeStates.BGSI_Lite_RegisterFleetUiControl(flag, wrapValueElement(self.Native:CreateToggle({
			name = properties.Title,
			description = properties.Description,
			value = properties.Default == true,
			flag = flag,
			forgetState = true,
			callback = properties.Callback,
		})), properties)
	end
	function tabMethods:AddSlider(flag, properties)
		local wrappedSlider = wrapValueElement(self.Native:CreateSlider({
			name = properties.Title,
			description = properties.Description,
			range = { properties.Min or 0, properties.Max or 100 },
			increment = 10 ^ -(properties.Rounding or 0),
			value = properties.Default,
			suffix = properties.Suffix,
			flag = flag,
			forgetState = true,
			callback = properties.Callback,
		}))
		function wrappedSlider:SetRange(minimum, maximum)
			if type(self.Native.SetRange) == "function" then
				self.Native:SetRange(minimum, maximum)
				return true
			end
			if type(self.Native.range) == "table" and type(self.Native.Set) == "function" then
				self.Native.range = { minimum, maximum }
				self.Native:Set(self.Native.value, true)
				return true
			end
			return false
		end
		return activeStates.BGSI_Lite_RegisterFleetUiControl(flag, wrappedSlider, properties)
	end
	function tabMethods:AddDropdown(flag, properties)
		local dropdownOptions = normalizeDropdownOptions(properties.Values)
		local nativeDropdown = self.Native:CreateDropdown({
			name = properties.Title,
			description = properties.Description,
			options = dropdownOptions,
			value = getDefaultValue(properties),
			multiSelect = properties.Multi == true,
			placeholder = properties.Placeholder,
			flag = flag,
			forgetState = true,
			callback = properties.Callback,
		})
		pcall(activeStates.BGSI_Lite_PatchDropdownRebindForIcons, nativeDropdown)
		activeStates.BGSI_Lite_RefreshDropdownIcons(nativeDropdown)
		return activeStates.BGSI_Lite_RegisterFleetUiControl(flag, wrapDropdown(nativeDropdown), properties)
	end
	function tabMethods:AddInput(flag, properties)
		return activeStates.BGSI_Lite_RegisterFleetUiControl(flag, wrapValueElement(self.Native:CreateInput({
			name = properties.Title,
			description = properties.Description,
			value = tostring(properties.Default or ""),
			placeholder = properties.Placeholder,
			numeric = properties.Numeric == true,
			flag = flag,
			forgetState = true,
			callback = properties.Callback,
		})), properties, "input")
	end
	function tabMethods:AddParagraph(properties)
		local paragraphContent = tostring(properties.Content or "")
		local paragraphElement
		paragraphElement = self.Native:CreateInput({
			name = properties.Title,
			value = paragraphContent,
			forgetState = true,
			callback = function()
				if paragraphElement then
					paragraphElement:Set(paragraphContent, true)
				end
			end,
		})
		local wrappedParagraph = {}
		function wrappedParagraph:SetDesc(content)
			paragraphContent = tostring(content or "")
			paragraphElement:Set(paragraphContent, true)
		end
		return wrappedParagraph
	end
	-- A button per version doesn't scale - a script with a hundred releases behind it
	-- meant a hundred stacked buttons in the sidebar. Instead: the last few versions
	-- shown right on the tab as a quick skim, and everything else behind one button
	-- that opens a single scrollable changelog popup.
	function tabMethods:AddReleaseHistory(releaseHistory)
		self:AddSection("Update History")

		local recentCount = math.min(3, #releaseHistory)
		for index = 1, recentCount do
			local release = releaseHistory[index]
			local titles = {}
			for _, note in ipairs(release.notes) do
				table.insert(titles, "•  " .. tostring(note.title))
			end
			self:AddText({
				Title = "v" .. tostring(release.version) .. "  ·  " .. tostring(release.releasedAt),
				Content = table.concat(titles, "\n"),
			})
		end

		local maxFullHistoryVersions = 30
		self.Native:CreateButton({
			name = "Full Changelog",
			description = tostring(#releaseHistory) .. " versions",
			icon = "scroll-text",
			callback = function()
				local boxes = {}
				local shownCount = math.min(maxFullHistoryVersions, #releaseHistory)
				for index = 1, shownCount do
					local release = releaseHistory[index]
					table.insert(boxes, {
						title = "v" .. tostring(release.version),
						description = tostring(release.releasedAt),
						icon = "tag",
					})
					for _, note in ipairs(release.notes) do
						table.insert(boxes, {
							title = tostring(note.title),
							description = tostring(note.description or ""),
							icon = note.icon,
						})
					end
				end
				if #releaseHistory > shownCount then
					table.insert(boxes, {
						title = (#releaseHistory - shownCount) .. " earlier version"
							.. ((#releaseHistory - shownCount) == 1 and "" or "s")
							.. " not shown",
						description = "",
						icon = "ellipsis",
					})
				end
				Interface:Popup({
					Title = "Changelog",
					SubTitle = tostring(#releaseHistory) .. " versions",
					Boxes = boxes,
					Options = {
						{
							text = "Close",
							style = "primary",
						},
					},
				})
			end,
		})
	end
	function tabMethods:AddChangelog()
		self:AddReleaseHistory(activeStates.BGSI_Lite_ReleaseHistory)
	end
	function tabMethods:AddStat(properties)
		return wrapValueElement(self.Native:CreateStat({
			name = properties.Title,
			description = properties.Description,
			icon = properties.Icon,
			value = tonumber(properties.Default) or 0,
			prefix = properties.Prefix,
			suffix = properties.Suffix,
			compact = properties.Compact == true,
			changeMode = properties.ChangeMode or "absolute",
			changeBaseline = properties.ChangeBaseline or "previous",
			numberEasing = properties.NumberEasing ~= false,
		}))
	end
	-- 1.2.0: a title, a body, or both. Either half can be left out.
	function tabMethods:AddText(properties)
		properties = properties or {}
		return wrapTextElement(self.Native:CreateText({
			name = properties.Title,
			text = properties.Content or properties.Text,
			icon = properties.Icon,
		}))
	end
	-- 1.2.0: a rule between sections. Optionally labelled, optionally line-less (a pure spacer).
	function tabMethods:AddDivider(properties)
		properties = properties or {}
		return wrapDividerElement(self.Native:CreateDivider({
			text = properties.Text,
			line = properties.Line,
			spacing = properties.Spacing,
		}))
	end
	-- 1.2.0: a range bar, a stepped bar (pass Steps), or an indeterminate sweep (pass Indeterminate).
	function tabMethods:AddProgress(properties)
		properties = properties or {}
		local range
		if type(properties.Range) == "table" then
			range = properties.Range
		elseif properties.Min or properties.Max then
			range = { properties.Min or 0, properties.Max or 100 }
		end
		return wrapProgressElement(self.Native:CreateProgress({
			name = properties.Title,
			description = properties.Description,
			range = range,
			steps = properties.Steps,
			value = properties.Default,
			text = properties.Text,
			indeterminate = properties.Indeterminate == true,
			format = properties.Format,
		}))
	end
	-- 1.2.0: a fixed-height scrolling log block (the old "Code" element, renamed).
	function tabMethods:AddConsole(properties)
		properties = properties or {}
		return wrapConsoleElement(self.Native:CreateConsole({
			name = properties.Title,
			description = properties.Description,
			text = properties.Content,
			height = properties.Height,
			follow = properties.Follow ~= false,
			maxLines = properties.MaxLines,
		}))
	end

	local windowMethods = {}
	function windowMethods:AddTab(properties)
		local nativeTab = self.Native:CreateTab({
			name = properties.Title,
			icon = properties.Icon,
		})
		local wrappedTab = setmetatable({ Native = nativeTab }, { __index = tabMethods })
		table.insert(self.Tabs, wrappedTab)
		return wrappedTab
	end
	-- 1.2.0: a heading in the sidebar rail that groups the tabs created after it.
	-- Sidebar layout only; a no-op on the top-strip layout.
	function windowMethods:AddSection(title)
		return self.Native:CreateSection({ name = title })
	end
	function windowMethods:SelectTab(index)
		local tab = self.Tabs[index]
		if tab then
			self.Native:Navigate(tab.Native)
		end
	end
	function windowMethods:Minimize()
		self.Native:ToggleHide()
	end
	function windowMethods:Destroy()
		self.Native:Unload()
	end

	Interface = {}
	function Interface:CreateWindow(properties)
		rayfieldWindow = Rayfield:CreateWindow({
			name = properties.Title,
			subtitle = properties.SubTitle,
			theme = "default",
			showName = "LarpLite",
			-- Rayfield Gen2 1.2.0: tabs run down a sidebar instead of across the top.
			sidebarLayout = true,
		})
		activeStates.RayfieldGen2Window = rayfieldWindow
		return setmetatable({ Native = rayfieldWindow, Tabs = {} }, { __index = windowMethods })
	end
	function Interface:CreateCompetitionPopup(properties)
		if not rayfieldWindow or rayfieldWindow.unloaded then return nil end
		local shell=rayfieldWindow:Popup({title="Live Competition",subtitle="Both teams / Top 100",options={{text="Close"}}})
		if not shell or not shell.card then return nil end
		local card=shell.card
		for _, child in ipairs(card:GetChildren()) do
			if child:IsA("UIListLayout") or child:IsA("UIPadding") then child:Destroy() end
		end
		card.Size=UDim2.fromOffset(780,550);card.AutomaticSize=Enum.AutomaticSize.None
		local header=card:FindFirstChild("Header");local footer=card:FindFirstChild("Footer")
		if header then header.Position=UDim2.fromOffset(18,12);header.Size=UDim2.new(1,-36,0,44) end
		if footer then footer.Position=UDim2.new(0,18,1,-50);footer.Size=UDim2.new(1,-36,0,34) end
		local function make(class,props,theme)
			props.Parent=props.Parent or card
			return rayfieldWindow:Create(class,props,theme)
		end
		local function bind(signal,callback)
			local c=rayfieldWindow:Connect(signal,callback);table.insert(shell._connections,c);return c
		end
		local scale=make("UIScale",{Scale=1})
		local popup={Shell=shell,Metric="Hatches",Columns={},Rows={Pink={},Blue={}}}
		function popup:IsOpen() return not shell._closed and shell.screenGui.Parent~=nil end
		function popup:Close() self.Snapshot=nil;shell:Close() end
		for index,team in ipairs({"Pink","Blue"}) do
			local column=make("Frame",{Name=team,Position=UDim2.new((index-1)*0.5,index==1 and 18 or 8,0,108),Size=UDim2.new(0.5,-26,1,-170),BorderSizePixel=0}, {BackgroundColor3="NeutralButton"})
			make("UICorner",{CornerRadius=UDim.new(0,8),Parent=column})
			local title=make("TextLabel",{Text=team,Position=UDim2.fromOffset(10,6),Size=UDim2.new(1,-20,0,26),TextSize=18,
				BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=column}, {FontFace="TitleFont",TextColor3="ContentColor"})
			local total=make("TextLabel",{Text="",Position=UDim2.fromOffset(10,34),Size=UDim2.new(1,-20,0,22),TextSize=13,
				BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,TextTruncate=Enum.TextTruncate.AtEnd,Parent=column}, {FontFace="Font",TextColor3="ContentColor"})
			local list=make("ScrollingFrame",{Name="Ranks",Position=UDim2.fromOffset(6,62),Size=UDim2.new(1,-12,1,-68),
				BackgroundTransparency=1,BorderSizePixel=0,AutomaticCanvasSize=Enum.AutomaticSize.Y,CanvasSize=UDim2.new(),
				ScrollBarThickness=4,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=column})
			make("UIListLayout",{Padding=UDim.new(0,3),SortOrder=Enum.SortOrder.LayoutOrder,Parent=list})
			local empty=make("TextLabel",{Text="Waiting for live standings...",BackgroundTransparency=1,TextSize=14,
				Size=UDim2.new(1,0,0,38),Parent=list}, {FontFace="Font",TextColor3="ContentColor"})
			popup.Columns[team]={Title=title,Total=total,List=list,Empty=empty}
		end
		local function number(value)
			return (string.format("%.0f",math.max(0,tonumber(value) or 0)):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))
		end
		function popup:Update(snapshot,competition)
			if not self:IsOpen() then return end
			self.Snapshot=snapshot;self.Competition=competition or self.Competition
			for _,team in ipairs({"Pink","Blue"}) do
				local col=self.Columns[team];local definition=self.Competition and self.Competition.Teams[team]
				col.Title.Text=definition and definition.Name or team
				local entries=snapshot and snapshot.Boards and snapshot.Boards[team] and snapshot.Boards[team][self.Metric] or {}
				local total=snapshot and snapshot.Totals and snapshot.Totals[team] and snapshot.Totals[team][self.Metric] or 0
				col.Total.Text=number(total).." "..self.Metric
				col.Empty.Visible=#entries==0;col.Empty.Text=snapshot and "No contributions yet" or "Waiting for live standings..."
				for rank=1,math.min(100,#entries) do
					local row=self.Rows[team][rank]
					if not row then
						local host=make("Frame",{Name="Rank"..rank,BackgroundTransparency=1,Size=UDim2.new(1,-4,0,30),LayoutOrder=rank,Parent=col.List})
						local function text(name,x,w,alignment)
							return make("TextLabel",{Name=name,BackgroundTransparency=1,Position=x,Size=w,TextSize=13,RichText=false,
								TextTruncate=Enum.TextTruncate.AtEnd,TextXAlignment=alignment,Parent=host}, {FontFace="Font",TextColor3="ContentColor"})
						end
						row={Frame=host,Rank=text("Rank",UDim2.fromOffset(2,0),UDim2.new(0,32,1,0),Enum.TextXAlignment.Left),
							Name=text("Username",UDim2.fromOffset(36,0),UDim2.new(0.53,-38,1,0),Enum.TextXAlignment.Left),
							Score=text("Score",UDim2.new(0.53,2,0,0),UDim2.new(0.47,-6,1,0),Enum.TextXAlignment.Right)}
						self.Rows[team][rank]=row
					end
					local entry=entries[rank];row.Frame.Visible=true;row.Rank.Text="#"..rank
					row.Name.Text=tostring(entry.Name or entry.UserId or "Player");row.Score.Text=number(entry.Score)
				end
				for rank=math.min(100,#entries)+1,#self.Rows[team] do self.Rows[team][rank].Frame.Visible=false end
			end
		end
		for index,metric in ipairs({"Hatches","Bubbles"}) do
			local control=make("TextButton",{Text=metric,Position=UDim2.fromOffset(18+(index-1)*146,64),Size=UDim2.fromOffset(136,32),
				TextSize=14,BorderSizePixel=0,AutoButtonColor=true}, {FontFace="Font",TextColor3="ContentColor",BackgroundColor3="NeutralButton"})
			make("UICorner",{CornerRadius=UDim.new(0,6),Parent=control})
			bind(control.Activated,function()popup.Metric=metric;popup:Update(popup.Snapshot,popup.Competition)end)
		end
		local function fit()
			local viewport=Workspace.CurrentCamera and Workspace.CurrentCamera.ViewportSize or Vector2.new(900,650)
			scale.Scale=math.max(0.25,math.min(1,(viewport.X-24)/780,(viewport.Y-48)/550))
		end
		fit();if Workspace.CurrentCamera then bind(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"),fit) end
		local originalClose=shell.Close
		shell.Close=function(self)
			popup.Snapshot=nil;table.clear(popup.Rows.Pink);table.clear(popup.Rows.Blue)
			originalClose(self)
		end
		return popup
	end
	function Interface:Notify(properties)
		if rayfieldWindow then
			rayfieldWindow:Notify({
				title = properties.Title,
				content = properties.Content,
				duration = properties.Duration,
			})
		end
	end
	function Interface:Popup(properties)
		if rayfieldWindow and type(rayfieldWindow.Popup) == "function" then
			return rayfieldWindow:Popup({
				title = properties.Title,
				subtitle = properties.SubTitle,
				content = properties.Content,
				boxes = properties.Boxes,
				options = properties.Options,
				dismissable = properties.Dismissable ~= false,
			})
		end
		Interface:Notify({
			Title = properties.Title,
			Content = properties.Content or properties.SubTitle or "Updated successfully.",
			Duration = 8,
		})
		return nil
	end
	function Interface:Destroy()
		if rayfieldWindow and not rayfieldWindow.unloaded then
			rayfieldWindow:Unload()
		end
	end
end
activeStates.RayfieldGen2 = Interface
profileStore = require(ReplicatedStorage.Client.Framework.Services.LocalData)
timeModule = require(ReplicatedStorage.Shared.Framework.Utilities.Math.Time)
questModule = require(ReplicatedStorage.Shared.Utils.Stats.QuestUtil)
enchantModule, enchantData, petRarityData, eggDataModule, riftData, bountyUtil, potionData, giftData, itemUtil = nil, nil, nil, nil, nil, nil, nil, nil, nil
carnivalRebirthUtil, carnivalRemoteModule, sharedConstants = nil, nil, nil
pcall(function()
	enchantModule = require(ReplicatedStorage.Shared.Utils.EnchantUtil)
end)
pcall(function()
	enchantData = require(ReplicatedStorage.Shared.Data.Enchants)
end)
pcall(function()
	petRarityData = require(ReplicatedStorage.Shared.Data.Pets)
end)
activeStates.BGSI_Lite_GetHatchPetValue = function(pet, valueKeys)
	local visited = {}
	local function scanValue(candidate, depth)
		if type(candidate) ~= "table" or visited[candidate] or depth > 4 then
			return nil
		end
		visited[candidate] = true
		for _, valueKey in ipairs(valueKeys) do
			if candidate[valueKey] ~= nil then
				return candidate[valueKey]
			end
		end
		for _, nestedKey in ipairs({ "Pet", "Data", "Info", "Item", "Reward" }) do
			local nestedValue = candidate[nestedKey]
			if type(nestedValue) == "table" then
				local foundValue = scanValue(nestedValue, depth + 1)
				if foundValue ~= nil then
					return foundValue
				end
			end
		end
		return nil
	end
	return scanValue(pet, 0)
end
activeStates.BGSI_Lite_GetHatchPetName = function(pet)
	local petName = activeStates.BGSI_Lite_GetHatchPetValue(pet, { "Name", "PetName" })
	if type(petName) == "string" and petName ~= "" then
		return petName
	end
	if type(pet) == "table" and type(pet.Pet) == "string" and pet.Pet ~= "" then
		return pet.Pet
	end
	return "Unknown"
end
activeStates.BGSI_Lite_GetHatchPetFlag = function(pet, flagName)
	return activeStates.BGSI_Lite_GetHatchPetValue(pet, { flagName, "Is" .. flagName }) == true
end
activeStates.BGSI_Lite_ResolvePetRarity = function(pet, petInfo)
	local raritySources = {
		activeStates.BGSI_Lite_GetHatchPetValue(pet, { "Rarity", "rarity" }),
		type(petInfo) == "table" and petInfo.Rarity or nil,
	}
	local rarityFlags = {
		Celestial = activeStates.BGSI_Lite_GetHatchPetFlag(pet, "Celestial")
			or (type(petInfo) == "table" and petInfo.Celestial == true),
		Infinity = activeStates.BGSI_Lite_GetHatchPetFlag(pet, "Infinity")
			or (type(petInfo) == "table" and petInfo.Infinity == true),
		Void = activeStates.BGSI_Lite_GetHatchPetFlag(pet, "Void")
			or (type(petInfo) == "table" and petInfo.Void == true),
		Secret = activeStates.BGSI_Lite_GetHatchPetFlag(pet, "Secret")
			or (type(petInfo) == "table" and petInfo.Secret == true),
	}
	for _, rarityName in ipairs({ "Celestial", "Infinity", "Void", "Secret" }) do
		if rarityFlags[rarityName] then
			return rarityName
		end
		for _, raritySource in ipairs(raritySources) do
			if string.find(string.lower(tostring(raritySource or "")), string.lower(rarityName), 1, true) then
				return rarityName
			end
		end
	end
	return tostring(raritySources[1] or raritySources[2] or raritySources[3] or raritySources[4] or "Unknown")
end
pcall(function()
	eggDataModule = require(ReplicatedStorage.Shared.Data.Eggs)
end)
pcall(function()
	riftData = require(ReplicatedStorage.Shared.Data.Rifts)
end)
pcall(function()
	bountyUtil = require(ReplicatedStorage.Shared.Utils.Stats.BountyUtil)
end)
pcall(function()
	activeStates.BGSI_Lite_SecretBountyUtil = require(ReplicatedStorage.Shared.Utils.Stats.SecretBountyUtil)
end)
pcall(function()
	potionData = require(ReplicatedStorage.Shared.Data.Potions)
end)
pcall(function()
	giftData = require(ReplicatedStorage.Shared.Data.Powerups)
end)
pcall(function()
	itemUtil = require(ReplicatedStorage.Shared.Utils.Stats.ItemUtil)
end)
pcall(function()
	activeStates.BGSI_Lite_MasteryData = require(ReplicatedStorage.Shared.Data.Mastery)
	activeStates.BGSI_Lite_IndexUtil = require(ReplicatedStorage.Shared.Utils.IndexUtil)
	activeStates.BGSI_Lite_XLIndexTasks = require(ReplicatedStorage.Shared.Data.XLIndexTasks)
	activeStates.BGSI_Lite_WorldData = require(ReplicatedStorage.Shared.Data.Worlds)
end)
pcall(function()
	carnivalRebirthUtil = require(ReplicatedStorage.Shared.Utils.CarnivalRebirthUtil)
end)
pcall(function()
	carnivalRemoteModule = require(ReplicatedStorage.Shared.Framework.Network.Remote)
end)
pcall(function()
	sharedConstants = require(ReplicatedStorage.Shared.Constants)
end)
function getCurrentTimestamp()
	if type(timeModule) == "table" and type(timeModule.now) == "function" then
		local ok, result = pcall(timeModule.now)
		if ok and type(result) == "number" then
			return result
		end
	end
	return os.time()
end
networkRemote =
	ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"):WaitForChild("Network"):WaitForChild("Remote")
remoteEvent = networkRemote:WaitForChild("RemoteEvent")
remoteFunction = networkRemote:WaitForChild("RemoteFunction")
activeStates.BGSI_Lite_FireGameRemote = function(actionName, ...)
	if Config.safeMode == true then
		return nil
	end
	if carnivalRemoteModule and type(carnivalRemoteModule.FireServer) == "function" then
		return carnivalRemoteModule:FireServer(actionName, ...)
	end
	return remoteEvent:FireServer(actionName, ...)
end
do
	local gameGuiFrame
	local observedScreenGui

	pcall(function()
		gameGuiFrame = require(ReplicatedStorage.Client.Gui.GuiFrame)
	end)

	local function closeGamePrompt(prompt)
		if
			not isCurrentRun()
			or Config.autoClosePopups ~= true
			or typeof(prompt) ~= "Instance"
			or prompt.Name ~= "Prompt"
		then
			return
		end
		task.defer(function()
			if not isCurrentRun() or Config.autoClosePopups ~= true or not prompt.Parent then
				return
			end
			local externalClose = prompt:FindFirstChild("ExternalClose")
			if externalClose and externalClose:IsA("BindableFunction") then
				pcall(externalClose.Invoke, externalClose)
			end
		end)
	end

	local function observeScreenGui(screenGui)
		if observedScreenGui == screenGui or typeof(screenGui) ~= "Instance" then
			return
		end
		observedScreenGui = screenGui
		if activeStates.BGSI_Lite_GamePromptChildConnection then
			activeStates.BGSI_Lite_GamePromptChildConnection:Disconnect()
		end
		activeStates.BGSI_Lite_GamePromptChildConnection = screenGui.ChildAdded:Connect(closeGamePrompt)
		local existingPrompt = screenGui:FindFirstChild("Prompt")
		if existingPrompt then
			closeGamePrompt(existingPrompt)
		end
	end

	local playerGui = LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		local screenGui = playerGui:FindFirstChild("ScreenGui")
		if screenGui then
			observeScreenGui(screenGui)
		end
		activeStates.BGSI_Lite_PlayerGuiChildConnection = playerGui.ChildAdded:Connect(function(child)
			if child.Name == "ScreenGui" then
				observeScreenGui(child)
			end
		end)
	end

	if
		type(gameGuiFrame) == "table"
		and gameGuiFrame.Changed
		and type(gameGuiFrame.Changed.Connect) == "function"
	then
		activeStates.BGSI_Lite_GamePopupFrameConnection = gameGuiFrame.Changed:Connect(function(frameName)
			local closeRebirthMachine = frameName == "RebirthMachine" and Config.RebirthMachineEnabled == true
				or frameName == "AdminRebirthMachine" and Config.AdminRebirthMachineEnabled == true
				or frameName == "WinterAltar" and Config.WinterAltarEnabled == true
			if
				(Config.autoClosePopups == true or closeRebirthMachine)
				and type(frameName) == "string"
				and (closeRebirthMachine or string.find(string.lower(frameName), "prompt", 1, true))
			then
				task.defer(function()
					if
						isCurrentRun()
						and (Config.autoClosePopups == true or closeRebirthMachine)
						and type(gameGuiFrame.GetCurrentlyOpen) == "function"
						and gameGuiFrame:GetCurrentlyOpen() == frameName
					then
						gameGuiFrame:Close()
					end
				end)
			end
		end)
	end
end
do
	-- Event Board purchases and the Infinite Track transition are requests only.
	-- The game server owns validation, deductions, timers, rewards, persistence,
	-- and stat modifiers; these helpers never send authoritative values.
	local eventBoard = {}
	local eventDefinitions
	local specialEventUtil
	local seasonUtil
	local eventPurchaseSuccessConnection
	local automationHeartbeatConnection
	local eventPurchaseState = {
		AcceptedPurchases = 0,
		RejectedAttempts = 0,
		ConsecutiveRejections = 0,
		LastAttemptAt = 0,
		Pending = nil,
		DisabledAfterRejections = false,
	}
	local infiniteTransitionState = {
		Locked = false,
		PendingSince = 0,
		TransitionedSeasonID = nil,
		Status = "WaitingForData",
	}
	local EVENT_SLOT_DURATION = 1800
	local PURCHASE_RESPONSE_TIMEOUT = 10
	local INFINITE_RESPONSE_TIMEOUT = 15
	local schedulerAccumulator = 0
	local lastAutoPurchaseEvents = Config.AutoPurchaseEvents == true
	local lastAutoStartInfiniteTrack = Config.AutoStartInfiniteTrack == true
	eventBoard.SpecialEventDuration = EVENT_SLOT_DURATION
	eventBoard.GlobalPurchaseTime = 900

	pcall(function()
		eventDefinitions = require(ReplicatedStorage.Shared.Data.SpecialEvents)
	end)
	pcall(function()
		specialEventUtil = require(ReplicatedStorage.Shared.Utils.SpecialEventUtil)
	end)
	pcall(function()
		seasonUtil = require(ReplicatedStorage.Shared.Utils.Stats.SeasonUtil)
	end)

	local function logAutomation(message, level)
		if type(activeStates.BGSI_Lite_LogDashboardAction) == "function" then
			activeStates.BGSI_Lite_LogDashboardAction(message, level)
		end
	end

	local function getServerTime()
		return getCurrentTimestamp()
	end

	local function getPlayerData()
		if not profileStore:IsReady() then
			return nil
		end
		local ok, playerData = pcall(profileStore.Get, profileStore)
		return ok and type(playerData) == "table" and playerData or nil
	end

	local function getEventDefinition(eventName)
		if type(eventName) ~= "string" or type(eventDefinitions) ~= "table" then
			return nil
		end
		local definition = eventDefinitions[eventName]
		return type(definition) == "table" and definition or nil
	end

	local function getEventCost(eventName)
		local definition = getEventDefinition(eventName)
		local cost = definition and tonumber(definition.TicketCost)
		return cost and math.max(0, math.floor(cost)) or nil
	end

	local function getBoostCrystalBalance(playerData)
		if type(playerData) ~= "table" or type(itemUtil) ~= "table" then
			return nil
		end
		local ok, amount = pcall(function()
			return itemUtil:GetOwnedAmount(playerData, {
				Type = "Powerup",
				Name = "Boost Crystal",
			})
		end)
		return ok and tonumber(amount) and math.max(0, math.floor(amount)) or nil
	end

	function eventBoard.GetSeed(offset)
		local positiveOffset = math.max(1, math.floor(tonumber(offset) or 1))
		return math.floor((getServerTime() + (positiveOffset - 1) * EVENT_SLOT_DURATION) / EVENT_SLOT_DURATION)
	end

	function eventBoard.SeedHasEvent(seed)
		seed = tonumber(seed)
		return seed ~= nil and math.floor(seed) % 2 == 0
	end

	function eventBoard.GetEventFromSeed(seed)
		seed = tonumber(seed)
		if not seed then
			return nil
		end
		seed = math.floor(seed)
		if type(specialEventUtil) == "table" and type(specialEventUtil.GetEventFromSeed) == "function" then
			local ok, eventName = pcall(specialEventUtil.GetEventFromSeed, specialEventUtil, seed)
			if ok and getEventDefinition(eventName) then
				return eventName
			end
		end
		return nil
	end

	function eventBoard.GetCurrentScheduledEvent()
		return eventBoard.GetEventFromSeed(eventBoard.GetSeed())
	end

	function eventBoard.GetScheduledSlotStart(seed)
		return math.floor(tonumber(seed) or eventBoard.GetSeed()) * EVENT_SLOT_DURATION
	end

	function eventBoard.GetScheduledSlotEnd(seed)
		return eventBoard.GetScheduledSlotStart(seed) + EVENT_SLOT_DURATION
	end

	function eventBoard.GetPurchasedExpiration(eventName)
		if not getEventDefinition(eventName) then
			return nil
		end
		local playerData = getPlayerData()
		local timers = playerData and playerData.SpecialEventTimers
		return type(timers) == "table" and tonumber(timers[eventName]) or nil
	end

	function eventBoard.IsEventActive(eventName)
		if not getEventDefinition(eventName) then
			return false
		end
		local serverTime = getServerTime()
		local scheduled = eventBoard.GetCurrentScheduledEvent()
		if scheduled == eventName and serverTime < eventBoard.GetScheduledSlotEnd(eventBoard.GetSeed()) then
			return true
		end
		return (eventBoard.GetPurchasedExpiration(eventName) or 0) > serverTime
	end

	function eventBoard.GetActiveEvents()
		local activeEvents = {}
		if type(eventDefinitions) ~= "table" then
			return activeEvents
		end
		for eventName in pairs(eventDefinitions) do
			if eventBoard.IsEventActive(eventName) then
				table.insert(activeEvents, eventName)
			end
		end
		table.sort(activeEvents, function(left, right)
			local leftDefinition = eventDefinitions[left]
			local rightDefinition = eventDefinitions[right]
			return (tonumber(leftDefinition.LayoutOrder) or math.huge)
				< (tonumber(rightDefinition.LayoutOrder) or math.huge)
		end)
		return activeEvents
	end

	function eventBoard.GetRemainingTime(eventName)
		if not getEventDefinition(eventName) then
			return 0
		end
		local serverTime = getServerTime()
		local expiration = eventBoard.GetPurchasedExpiration(eventName) or 0
		if eventBoard.GetCurrentScheduledEvent() == eventName then
			expiration = math.max(expiration, eventBoard.GetScheduledSlotEnd(eventBoard.GetSeed()))
		end
		return math.max(0, expiration - serverTime)
	end

	function eventBoard.CanAffordEvent(player, eventName, quantity)
		if player ~= nil and player ~= LocalPlayer then
			return false
		end
		local cost = getEventCost(eventName)
		local balance = getBoostCrystalBalance(getPlayerData())
		local count = tonumber(quantity) or 1
		return cost ~= nil and cost > 0 and balance ~= nil
			and count >= 1 and count == math.floor(count) and balance >= cost * count
	end

	local function rejectPendingPurchase(reason)
		local pending = eventPurchaseState.Pending
		if not pending then
			return
		end
		eventPurchaseState.Pending = nil
		eventPurchaseState.RejectedAttempts += 1
		eventPurchaseState.ConsecutiveRejections += 1
		if eventPurchaseState.ConsecutiveRejections >= math.max(
			1,
			math.floor(tonumber(Config.MaximumRejectedEventAttempts) or 3)
		) then
			eventPurchaseState.DisabledAfterRejections = true
			Config.AutoPurchaseEvents = false
			saveConfig()
		end
		logAutomation(
			("Event purchase rejected for %s: %s"):format(tostring(pending.EventName), tostring(reason)),
			"warning"
		)
	end

	function eventBoard.PurchaseEvent(player, eventName, quantity)
		if player ~= nil and player ~= LocalPlayer then
			return false, "invalid-player"
		end
		if Config.safeMode == true then
			return false, "safe-mode"
		end
		if type(eventName) ~= "string" then
			return false, "invalid-event-name"
		end
		if not getEventDefinition(eventName) then
			return false, "unknown-event"
		end
		quantity = tonumber(quantity) or 1
		if quantity < 1 or quantity ~= math.floor(quantity) then
			return false, "invalid-quantity"
		end
		if eventPurchaseState.Pending then
			return false, "transaction-locked"
		end
		local now = getServerTime()
		if now - eventPurchaseState.LastAttemptAt < 1 then
			return false, "rate-limited"
		end
		if not eventBoard.CanAffordEvent(LocalPlayer, eventName, quantity) then
			return false, "insufficient-boost-crystals"
		end

		eventPurchaseState.LastAttemptAt = now
		eventPurchaseState.Pending = {
			EventName = eventName,
			Quantity = quantity,
			SentAt = now,
		}
		local sent, sendError = pcall(function()
			if carnivalRemoteModule and type(carnivalRemoteModule.FireServer) == "function" then
				carnivalRemoteModule:FireServer("PurchaseEventBoard", eventName, quantity)
			else
				remoteEvent:FireServer("PurchaseEventBoard", eventName, quantity)
			end
		end)
		if not sent then
			rejectPendingPurchase(sendError or "request-failed")
			return false, "request-failed"
		end
		logAutomation(("Requested Event Board purchase: %s x%d"):format(eventName, quantity), "info")
		return true
	end

	function eventBoard.ApplyEventModifiers(baseStats)
		local modifiedStats = table.clone(type(baseStats) == "table" and baseStats or {})
		local modifiers = {
			["Luck Event"] = { "Luck", 1.25 },
			["Shiny Event"] = { "ShinyChance", 1.25 },
			["Mythic Event"] = { "MythicChance", 1.25 },
			["Celestial Event"] = { "CelestialLuck", 1.25 },
			["Secret Event"] = { "SecretLuck", 1.1 },
			["Infinity Event"] = { "InfinityLuck", 1.25 },
			["XL Event"] = { "XLChance", 1.25 },
			["Super Palooza"] = { "SuperLegendaryChance", 2 },
		}
		for _, eventName in ipairs(eventBoard.GetActiveEvents()) do
			local modifier = modifiers[eventName]
			if modifier and type(modifiedStats[modifier[1]]) == "number" then
				modifiedStats[modifier[1]] *= modifier[2]
			end
		end
		return modifiedStats
	end

	local function getCurrentSeason()
		if type(seasonUtil) ~= "table" or type(seasonUtil.GetCurrentSeason) ~= "function" then
			return nil
		end
		local ok, currentSeason = pcall(seasonUtil.GetCurrentSeason, seasonUtil)
		return ok and type(currentSeason) == "table" and currentSeason or nil
	end

	local function getSeasonID(currentSeason)
		return currentSeason and (currentSeason.ID or currentSeason.Id or currentSeason.Name) or nil
	end

	local function getInfiniteEligibility()
		local currentSeason = getCurrentSeason()
		local playerData = getPlayerData()
		local season = playerData and playerData.Season
		if not currentSeason or type(currentSeason.Track) ~= "table" then
			return false, "NoCurrentSeason"
		end
		if type(season) ~= "table" then
			return false, "SeasonDataNotLoaded"
		end
		if season.IsInfinite == true then
			return false, "AlreadyInfinite"
		end
		if (tonumber(season.Level) or 0) < #currentSeason.Track then
			return false, "StandardTrackIncomplete"
		end
		return true, currentSeason
	end

	local function beginSeasonInfinite()
		if infiniteTransitionState.Locked then
			return false, "transition-locked"
		end
		local eligible, currentSeasonOrReason = getInfiniteEligibility()
		if not eligible then
			infiniteTransitionState.Status = currentSeasonOrReason
			return false, currentSeasonOrReason
		end
		if Config.AutoStartInfiniteTrack ~= true then
			if infiniteTransitionState.Status ~= "EligibleAutoStartDisabled" then
				logAutomation(
					"Season Infinite Track is eligible; automatic transition is disabled.",
					"info"
				)
			end
			infiniteTransitionState.Status = "EligibleAutoStartDisabled"
			return false, "auto-start-disabled"
		end
		if Config.safeMode == true then
			infiniteTransitionState.Status = "EligibleSafeMode"
			return false, "safe-mode"
		end

		infiniteTransitionState.Locked = true
		infiniteTransitionState.PendingSince = getServerTime()
		infiniteTransitionState.Status = "TransitionRequested"
		local sent, sendError = pcall(function()
			if carnivalRemoteModule and type(carnivalRemoteModule.FireServer) == "function" then
				carnivalRemoteModule:FireServer("BeginSeasonInfinite")
			else
				remoteEvent:FireServer("BeginSeasonInfinite")
			end
		end)
		if not sent then
			infiniteTransitionState.Locked = false
			infiniteTransitionState.Status = "TransitionRequestFailed"
			logAutomation("Infinite Track transition request failed: " .. tostring(sendError), "warning")
			return false, "request-failed"
		end
		infiniteTransitionState.TransitionedSeasonID = getSeasonID(currentSeasonOrReason)
		logAutomation("Requested automatic Season Infinite Track transition.", "info")
		return true
	end

	local function evaluateInfiniteTransition()
		if not isCurrentRun() then
			return
		end
		local playerData = getPlayerData()
		local season = playerData and playerData.Season
		if type(season) == "table" and season.IsInfinite == true then
			infiniteTransitionState.Locked = false
			infiniteTransitionState.PendingSince = 0
			infiniteTransitionState.Status = "Infinite"
			infiniteTransitionState.TransitionedSeasonID = getSeasonID(getCurrentSeason())
			activeStates.BGSI_Lite_InfiniteTrackStatus = infiniteTransitionState.Status
			activeStates.BGSI_Lite_TransitionedSeasonID = infiniteTransitionState.TransitionedSeasonID
			return
		end
		if not infiniteTransitionState.Locked then
			beginSeasonInfinite()
		end
		activeStates.BGSI_Lite_InfiniteTrackStatus = infiniteTransitionState.Status
	end

	local function runEventAutoPurchase()
		if
			Config.AutoPurchaseEvents ~= true
			or Config.safeMode == true
			or eventPurchaseState.DisabledAfterRejections
			or eventPurchaseState.Pending
		then
			return
		end
		if eventPurchaseState.AcceptedPurchases >= math.max(
			0,
			math.floor(tonumber(Config.MaximumEventPurchasesPerSession) or 0)
		) then
			return
		end
		local now = getServerTime()
		if now - eventPurchaseState.LastAttemptAt < math.max(1, tonumber(Config.EventPurchaseCooldown) or 60) then
			return
		end
		local playerData = getPlayerData()
		local balance = getBoostCrystalBalance(playerData)
		if balance == nil then
			return
		end
		local reserve = math.max(0, math.floor(tonumber(Config.MinimumCrystalReserve) or 0))
		local requestedQuantity = math.max(1, math.floor(tonumber(Config.EventPurchaseQuantity) or 1))
		local priorities = type(Config.PriorityEvents) == "table" and Config.PriorityEvents or {}
		local seen = {}
		for _, eventName in ipairs(priorities) do
			if type(eventName) == "string" and not seen[eventName] then
				seen[eventName] = true
				local cost = getEventCost(eventName)
				local active = eventBoard.IsEventActive(eventName)
				local affordableQuantity = cost and cost > 0 and math.floor((balance - reserve) / cost) or 0
				if affordableQuantity >= 1 and (not active or Config.ExtendAlreadyActiveEvents == true) then
					eventBoard.PurchaseEvent(LocalPlayer, eventName, math.min(requestedQuantity, affordableQuantity))
					return
				end
			end
		end
	end

	local function schedulerStep(deltaTime)
		if not isCurrentRun() then
			if automationHeartbeatConnection then
				automationHeartbeatConnection:Disconnect()
				automationHeartbeatConnection = nil
			end
			return
		end
		schedulerAccumulator += deltaTime
		if schedulerAccumulator < 1 then
			return
		end
		schedulerAccumulator %= 1
		local now = getServerTime()
		local autoPurchaseEnabled = Config.AutoPurchaseEvents == true
		if autoPurchaseEnabled and not lastAutoPurchaseEvents then
			eventPurchaseState.ConsecutiveRejections = 0
			eventPurchaseState.DisabledAfterRejections = false
		end
		lastAutoPurchaseEvents = autoPurchaseEnabled
		local autoStartInfiniteEnabled = Config.AutoStartInfiniteTrack == true
		if autoStartInfiniteEnabled and not lastAutoStartInfiniteTrack then
			task.defer(evaluateInfiniteTransition)
		end
		lastAutoStartInfiniteTrack = autoStartInfiniteEnabled
		if autoStartInfiniteEnabled then
			evaluateInfiniteTransition()
		end
		if
			eventPurchaseState.Pending
			and now - eventPurchaseState.Pending.SentAt >= PURCHASE_RESPONSE_TIMEOUT
		then
			rejectPendingPurchase("authoritative-confirmation-timeout")
		end
		if
			infiniteTransitionState.Locked
			and now - infiniteTransitionState.PendingSince >= INFINITE_RESPONSE_TIMEOUT
		then
			infiniteTransitionState.Locked = false
			infiniteTransitionState.PendingSince = 0
			infiniteTransitionState.Status = "TransitionConfirmationTimeout"
			activeStates.BGSI_Lite_InfiniteTrackStatus = infiniteTransitionState.Status
			logAutomation("Infinite Track transition was not confirmed by replicated Season data.", "warning")
		end
		runEventAutoPurchase()
		activeStates.BGSI_Lite_EventPurchaseState = eventPurchaseState
	end

	if carnivalRemoteModule and type(carnivalRemoteModule.Event) == "function" then
		pcall(function()
			eventPurchaseSuccessConnection = carnivalRemoteModule.Event("EventPurchaseSuccess"):Connect(function(player, eventName, quantity)
				if not isCurrentRun() or player ~= LocalPlayer then
					return
				end
				local pending = eventPurchaseState.Pending
				if not pending or pending.EventName ~= eventName then
					return
				end
				eventPurchaseState.Pending = nil
				eventPurchaseState.AcceptedPurchases += 1
				eventPurchaseState.ConsecutiveRejections = 0
				eventPurchaseState.DisabledAfterRejections = false
			logAutomation(("Event Board purchase accepted: %s x%d"):format(eventName, tonumber(quantity) or pending.Quantity or 1), "success")
			end)
		end)
	end

	pcall(function()
		profileStore:ConnectDataChanged("Season", function()
			task.defer(evaluateInfiniteTransition)
		end)
	end)
	if type(seasonUtil) == "table" and seasonUtil.Changed and type(seasonUtil.Changed.Connect) == "function" then
		pcall(function()
			seasonUtil.Changed:Connect(function()
				task.defer(evaluateInfiniteTransition)
			end)
		end)
	end
	automationHeartbeatConnection = RunService.Heartbeat:Connect(schedulerStep)
	activeStates.BGSI_Lite_EventBoard = eventBoard
	activeStates.BGSI_Lite_EventPurchaseState = eventPurchaseState
	activeStates.BGSI_Lite_BeginSeasonInfinite = beginSeasonInfinite
	activeStates.BGSI_Lite_InfiniteTransitionState = infiniteTransitionState
	activeStates.BGSI_Lite_EventPurchaseSuccessConnection = eventPurchaseSuccessConnection
	activeStates.BGSI_Lite_EventAutomationHeartbeatConnection = automationHeartbeatConnection
	task.defer(evaluateInfiniteTransition)
end
activeStates.BGSI_Lite_GetPetInventoryUsage = function(playerData)
	if type(activeStates.BGSI_Lite_PetStorageStatsUtil) ~= "table" then
		pcall(function()
			activeStates.BGSI_Lite_PetStorageStatsUtil = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
		end)
	end
	local usageOk, petUsage = pcall(function()
		return activeStates.BGSI_Lite_PetStorageStatsUtil:GetUsedPetStorage(playerData)
	end)
	if usageOk and type(petUsage) == "number" then
		return math.max(0, math.floor(petUsage))
	end
	local petAmount = 0
	for _, pet in ipairs(type(playerData) == "table" and type(playerData.Pets) == "table" and playerData.Pets or {}) do
		if type(pet) == "table" then
			petAmount += math.max(1, math.floor(tonumber(pet.Amount or pet.Count) or 1))
		end
	end
	return petAmount
end
activeStates.BGSI_Lite_GetPetInventoryCapacity = function(playerData)
	if type(activeStates.BGSI_Lite_PetStorageStatsUtil) ~= "table" then
		pcall(function()
			activeStates.BGSI_Lite_PetStorageStatsUtil = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
		end)
	end
	local capacityOk, petCapacity = pcall(function()
		return activeStates.BGSI_Lite_PetStorageStatsUtil:GetMaxPetStorage(playerData)
	end)
	return capacityOk and type(petCapacity) == "number" and math.max(0, math.floor(petCapacity)) or nil
end
activeStates.BGSI_Lite_IsPetEquipped = function(playerData, petId)
	for _, team in pairs(type(playerData) == "table" and type(playerData.Teams) == "table" and playerData.Teams or {}) do
		for _, equippedPetId in pairs(type(team) == "table" and type(team.Pets) == "table" and team.Pets or {}) do
			if tostring(equippedPetId) == tostring(petId) then
				return true
			end
		end
	end
	return false
end
activeStates.BGSI_Lite_IsPetInventoryFull = function(playerData)
	local petCapacity = activeStates.BGSI_Lite_GetPetInventoryCapacity(playerData)
	if petCapacity and petCapacity > 0 then
		return activeStates.BGSI_Lite_GetPetInventoryUsage(playerData) >= petCapacity
	end
	local inventoryFullOk, inventoryFull = pcall(function()
		return activeStates.BGSI_Lite_PetStorageStatsUtil:IsInventoryFull(playerData)
	end)
	return inventoryFullOk and inventoryFull == true
end
activeStates.BGSI_Lite_GetDisposablePetRank = function(pet)
	if type(pet) ~= "table" or pet.Super == true or pet.IsSuper == true or pet.SuperLegendary == true then
		return nil
	end
	if pet.Locked == true or pet.IsLocked == true then
		return nil
	end
	if
		pet.Shiny == true
		or pet.IsShiny == true
		or pet.Mythic == true
		or pet.IsMythic == true
		or pet.XL == true
		or pet.IsXL == true
		or (tonumber(pet.XP) or 0) > 0
		or next(type(pet.Enchants) == "table" and pet.Enchants or (type(pet.Enchantments) == "table" and pet.Enchantments or {})) ~= nil
	then
		return nil
	end
	local petInfo = type(petRarityData) == "table" and petRarityData[pet.Name] or nil
	local rarity = activeStates.BGSI_Lite_ResolvePetRarity(pet, petInfo)
	return ({ Common = 1, Unique = 2, Rare = 3, Epic = 4, Legendary = 5 })[rarity]
end
activeStates.BGSI_Lite_FindPetById = function(playerData, petId)
	for _, pet in ipairs(type(playerData) == "table" and type(playerData.Pets) == "table" and playerData.Pets or {}) do
		if type(pet) == "table" and tostring(pet.Id or "") == tostring(petId) then
			return pet
		end
	end
	return nil
end
activeStates.BGSI_Lite_CleanupFullPetInventory = function()
	if Config.autoInventoryCleanup ~= true or activeStates.BGSI_Lite_PetInventoryCleanupActive then
		return false
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" then
		return false
	end
	-- Used to require the pet inventory to be literally full before trimming anything,
	-- which meant a high-count non-Super duplicate stack (Legendary and below - Super
	-- Legendary/Celestial/Infinity/Void/Secret never qualify as disposable to begin
	-- with, see BGSI_Lite_GetDisposablePetRank) just sat there forever as long as any
	-- free slot remained. The candidate selection below already only touches stacks
	-- whose count exceeds the configured minimum, so it's already scoped to "high
	-- counts" - there's no need to also wait for the inventory to fill up first.
	local minimumCopies = math.max(2, math.floor(tonumber(Config.inventoryCleanupMinCopies) or 10))
	local candidateGroups = {}
	for _, pet in ipairs(type(playerData) == "table" and type(playerData.Pets) == "table" and playerData.Pets or {}) do
		local petRank = activeStates.BGSI_Lite_GetDisposablePetRank(pet)
		local petId = type(pet) == "table" and tostring(pet.Id or "") or ""
		if petRank and petId ~= "" and not activeStates.BGSI_Lite_IsPetEquipped(playerData, petId) then
			local petName = tostring(pet.Name or "")
			local petAmount = math.max(1, math.floor(tonumber(pet.Amount or pet.Count) or 1))
			local candidateKey = petName .. "|" .. tostring(petRank)
			local candidateGroup = candidateGroups[candidateKey]
			if not candidateGroup then
				candidateGroup = { name = petName, rank = petRank, amount = 0, pets = {} }
				candidateGroups[candidateKey] = candidateGroup
			end
			candidateGroup.amount += petAmount
			table.insert(candidateGroup.pets, { id = petId, amount = petAmount })
		end
	end
	local candidates = {}
	for _, candidateGroup in pairs(candidateGroups) do
		if candidateGroup.amount > minimumCopies then
			table.sort(candidateGroup.pets, function(leftPet, rightPet)
				return leftPet.amount < rightPet.amount
			end)
			table.insert(candidates, candidateGroup)
		end
	end
	table.sort(candidates, function(leftCandidate, rightCandidate)
		if leftCandidate.rank ~= rightCandidate.rank then
			return leftCandidate.rank < rightCandidate.rank
		end
		if leftCandidate.amount ~= rightCandidate.amount then
			return leftCandidate.amount > rightCandidate.amount
		end
		return leftCandidate.name < rightCandidate.name
	end)
	if not candidates[1] then
		return false
	end
	activeStates.BGSI_Lite_BlockedCleanupPets = type(activeStates.BGSI_Lite_BlockedCleanupPets) == "table"
			and activeStates.BGSI_Lite_BlockedCleanupPets
		or {}
	for petId, blockedAt in pairs(activeStates.BGSI_Lite_BlockedCleanupPets) do
		if tick() - (tonumber(blockedAt) or 0) >= 60 then
			activeStates.BGSI_Lite_BlockedCleanupPets[petId] = nil
		end
	end
	activeStates.BGSI_Lite_PetInventoryCleanupActive = true
	local deletedAmount = 0
	local cleanupOk = pcall(function()
		for _, selectedCandidate in ipairs(candidates) do
			local remainingCopies = selectedCandidate.amount
			for _, candidatePet in ipairs(selectedCandidate.pets) do
				if not isCurrentRun() then
					return
				end
				playerData = profileStore:IsReady() and profileStore:Get() or nil
				local livePet = activeStates.BGSI_Lite_FindPetById(playerData, candidatePet.id)
				local amountBeforeDelete = livePet
						and math.max(1, math.floor(tonumber(livePet.Amount or livePet.Count) or 1))
					or 0
				-- How many copies of this stack may go without dropping the total below
				-- the configured minimum. The old check only allowed deleting a stack
				-- whole, so a single stack larger than the minimum could never be
				-- trimmed at all - the usual case, and the reason cleanup looked dead
				-- even before the remote call itself was wrong.
				local deletableAmount = math.min(amountBeforeDelete, remainingCopies - minimumCopies)
				if
					livePet
					and livePet.Name == selectedCandidate.name
					and activeStates.BGSI_Lite_GetDisposablePetRank(livePet)
					and not activeStates.BGSI_Lite_IsPetEquipped(playerData, candidatePet.id)
					and deletableAmount >= 1
					and activeStates.BGSI_Lite_BlockedCleanupPets[candidatePet.id] == nil
				then
					-- The game fires DeletePet with three arguments: the 36-character pet
					-- id, how many copies to delete, and whether the pet was picked from a
					-- team. This used to send only the id, so the server saw no amount and
					-- deleted nothing at all.
					local deleteId = string.sub(tostring(candidatePet.id), 1, 36)
					local amountAfterDelete = amountBeforeDelete
					for _ = 1, 3 do
						remoteEvent:FireServer("DeletePet", deleteId, deletableAmount, false)
						local deleteDeadline = tick() + 4
						repeat
							task.wait(0.1)
							playerData = profileStore:IsReady() and profileStore:Get() or nil
							livePet = activeStates.BGSI_Lite_FindPetById(playerData, candidatePet.id)
							amountAfterDelete = livePet
									and math.max(1, math.floor(tonumber(livePet.Amount or livePet.Count) or 1))
								or 0
						until amountAfterDelete < amountBeforeDelete or tick() >= deleteDeadline
						if amountAfterDelete < amountBeforeDelete then
							break
						end
						task.wait(0.5)
					end
					if amountAfterDelete < amountBeforeDelete then
						local removedAmount = amountBeforeDelete - amountAfterDelete
						deletedAmount += removedAmount
						remainingCopies -= removedAmount
					else
						activeStates.BGSI_Lite_BlockedCleanupPets[candidatePet.id] = tick()
					end
				end
			end
		end
	end)
	activeStates.BGSI_Lite_PetInventoryCleanupActive = false
	activeStates.BGSI_Lite_LastPetInventoryCleanup = cleanupOk and tick() or tick() - 15
	return cleanupOk and deletedAmount > 0
end
task.spawn(function()
	while isCurrentRun() do
		task.wait(5)
		if
			Config.autoInventoryCleanup == true
			and tick() - (tonumber(activeStates.BGSI_Lite_LastPetInventoryCleanup) or 0) >= 20
		then
			pcall(activeStates.BGSI_Lite_CleanupFullPetInventory)
		end
	end
end)
activeStates.BGSI_Lite_ApplyLowRarityEggAutoDelete = function()
	if Config.autoDeleteLowRarityEggPets ~= true then
		return false
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	local eggName = tostring(activeStates.BGSI_Lite_CurrentEggName or "")
	if eggName == "" or eggName == "None" then
		eggName = tostring(Config.selectedEgg or "")
	end
	local eggInfo = type(eggDataModule) == "table" and eggDataModule[eggName] or nil
	local eggPool = type(eggInfo) == "table" and (eggInfo.Pool or eggInfo.Pets) or nil
	if type(playerData) ~= "table" or type(eggPool) ~= "table" then
		return false
	end
	local changed = false
	local seenPetNames = {}
	for petKey, petEntry in pairs(eggPool) do
		local poolItem = type(petEntry) == "table" and petEntry.Item or nil
		local petName = type(poolItem) == "table"
				and poolItem.Type == "Pet"
				and poolItem.Name
			or type(petEntry) == "table" and (petEntry.Pet or petEntry.Name)
			or (type(petEntry) == "string" and petEntry)
			or (type(petKey) == "string" and petKey)
		if type(petName) == "string" and petName ~= "" and not seenPetNames[petName] then
			seenPetNames[petName] = true
			local petInfo = type(petRarityData) == "table" and petRarityData[petName] or nil
			local rarity = activeStates.BGSI_Lite_ResolvePetRarity({ Name = petName }, petInfo)
			if
				(rarity == "Common" or rarity == "Rare" or rarity == "Epic")
				and (type(playerData.AutoDelete) ~= "table" or playerData.AutoDelete[petName] == nil)
			then
				pcall(remoteEvent.FireServer, remoteEvent, "SetAutoDelete", petName, true)
				changed = true
				task.wait(0.08)
			end
		end
	end
	activeStates.BGSI_Lite_LastAutoDeleteEggName = eggName
	activeStates.BGSI_Lite_LastAutoDeleteEggAt = tick()
	return changed
end
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.autoDeleteLowRarityEggPets and 5 or 0.85)
		local currentAutoDeleteEgg = tostring(activeStates.BGSI_Lite_CurrentEggName or "")
		if currentAutoDeleteEgg == "" or currentAutoDeleteEgg == "None" then
			currentAutoDeleteEgg = tostring(Config.selectedEgg or "")
		end
		if
			Config.autoDeleteLowRarityEggPets
			and (
				tostring(activeStates.BGSI_Lite_LastAutoDeleteEggName or "")
					~= currentAutoDeleteEgg
				or tick() - (tonumber(activeStates.BGSI_Lite_LastAutoDeleteEggAt) or 0) >= 30
			)
		then
			pcall(activeStates.BGSI_Lite_ApplyLowRarityEggAutoDelete)
		end
	end
end)
hatchEffectModule, scriptStateID = nil, nil
pcall(function()
	hatchEffectModule = require(ReplicatedStorage.Client.Effects.HatchEgg)
	if hatchEffectModule and type(hatchEffectModule.Play) == "function" then
		if type(rawget(hatchEffectModule, "_BGSI_LITE_ORIGINAL_PLAY")) ~= "function" then
			hatchEffectModule._BGSI_LITE_ORIGINAL_PLAY = hatchEffectModule.Play
		end
		scriptStateID = hatchEffectModule._BGSI_LITE_ORIGINAL_PLAY
	end
end)
activeStates.BGSI_Lite_HideHatchInterface = function(hatchController)
	local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
	local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
	local hatchingFrame = screenGui and screenGui:FindFirstChild("Hatching")
	local hudFrame = screenGui and screenGui:FindFirstChild("HUD")
	if hatchingFrame then
		hatchingFrame.Visible = false
	end
	if hudFrame then
		hudFrame.Visible = true
	end
	if type(hatchController) == "table" then
		hatchController.animationPlaying = false
	end
end
activeStates.BGSI_Lite_NoHatchAnimationPlay = function(self)
	activeStates.BGSI_Lite_HideHatchInterface(self)
end
activeStates.BGSI_Lite_ApplyHatchAnimationSetting = function()
	if not hatchEffectModule or type(scriptStateID) ~= "function" then
		return false
	end
	if Config.noHatchAnim == true then
		hatchEffectModule.Play = activeStates.BGSI_Lite_NoHatchAnimationPlay
		activeStates.BGSI_Lite_HideHatchInterface(hatchEffectModule)
	else
		hatchEffectModule.Play = scriptStateID
	end
	return true
end
if type(activeStates.BGSI_Lite_ApplyHatchAnimationSetting) == "function" then
	activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
end
LocalPlayer.CharacterAdded:Connect(function()
	if Config.healthRecoveryEnabled ~= true then
		return
	end
	task.wait(1)
	activeStates.BGSI_Lite_ForceAutoHatchTeleport = Config.autoHatch == true
	if type(activeStates.BGSI_Lite_ApplyHatchAnimationSetting) == "function" then
		activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
	end
end)
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.healthRecoveryEnabled == true and 0.5 or 1)
		if
			Config.noHatchAnim == true
			and hatchEffectModule
			and hatchEffectModule.Play ~= activeStates.BGSI_Lite_NoHatchAnimationPlay
		then
			if type(activeStates.BGSI_Lite_ApplyHatchAnimationSetting) == "function" then
				activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
			end
		end
		if Config.healthRecoveryEnabled == true then
			local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
			local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
			if screenGui == nil and playerGui then
				screenGui = playerGui:WaitForChild("ScreenGui", 3)
				if screenGui and type(activeStates.BGSI_Lite_ApplyHatchAnimationSetting) == "function" then
					activeStates.BGSI_Lite_ApplyHatchAnimationSetting()
				end
			end
		end
	end
end)
function teleportToCFrame(targetCFrame)
	if isAutomationBlocked() or typeof(targetCFrame) ~= "CFrame" or not LocalPlayer then
		return false
	end
	local playerCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
	local teleportHumanoidRootPart = playerCharacter:FindFirstChild("HumanoidRootPart")
		or playerCharacter:WaitForChild("HumanoidRootPart", 5)
	if not teleportHumanoidRootPart then
		return false
	end
	teleportHumanoidRootPart.CFrame = targetCFrame
	return true
end
activeStates.BGSI_Lite_GetInstanceTargetCFrame = function(targetInstance, preferredPartName)
	if typeof(targetInstance) ~= "Instance" then
		return nil
	end
	if type(preferredPartName) == "string" and preferredPartName ~= "" then
		local preferredPart = targetInstance:FindFirstChild(preferredPartName, true)
		if preferredPart and preferredPart:IsA("BasePart") then
			return preferredPart.CFrame
		end
	end
	if targetInstance:IsA("BasePart") then
		return targetInstance.CFrame
	end
	local pivotSucceeded, pivotCFrame = pcall(targetInstance.GetPivot, targetInstance)
	if pivotSucceeded and typeof(pivotCFrame) == "CFrame" then
		return pivotCFrame
	end
	local basePart = targetInstance:FindFirstChildWhichIsA("BasePart", true)
	return basePart and basePart.CFrame or nil
end
activeStates.BGSI_Lite_GetRiftTargetCFrame = function(riftModel)
	if typeof(riftModel) ~= "Instance" then
		return nil
	end
	local riftType = tostring(riftModel:GetAttribute("Type") or "")
	if riftType == "Egg" then
		local eggRoot = riftModel:FindFirstChild("Root", true)
		if eggRoot and eggRoot:IsA("BasePart") then
			return eggRoot.CFrame
		end
		local eggPlatform = riftModel:FindFirstChild("EggPlatformSpawn")
		return activeStates.BGSI_Lite_GetInstanceTargetCFrame(eggPlatform)
			or activeStates.BGSI_Lite_GetInstanceTargetCFrame(riftModel, "Output")
	elseif riftType == "Chest" then
		local chestModel = riftModel:FindFirstChild("Chest")
		return activeStates.BGSI_Lite_GetInstanceTargetCFrame(chestModel, "Prompt")
			or activeStates.BGSI_Lite_GetInstanceTargetCFrame(riftModel, "Output")
	elseif riftType == "Gift" then
		local giftModel = riftModel:FindFirstChild("Gift")
		return activeStates.BGSI_Lite_GetInstanceTargetCFrame(giftModel, "Prompt")
			or activeStates.BGSI_Lite_GetInstanceTargetCFrame(riftModel, "Output")
	end
	return activeStates.BGSI_Lite_GetInstanceTargetCFrame(riftModel, "Output")
end
function getMaxHatchAmount()
	local scriptStateVM
	pcall(function()
		if profileStore:IsReady() then
			local scriptStateJE = profileStore:Get()
			if not activeStates.BGSI_Lite_HatchStatsUtil then
				activeStates.BGSI_Lite_HatchStatsUtil =
					require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
			end
			local hatchStatsUtil = activeStates.BGSI_Lite_HatchStatsUtil
			if hatchStatsUtil and type(hatchStatsUtil.GetMaxEggHatches) == "function" then
				scriptStateVM = hatchStatsUtil:GetMaxEggHatches(scriptStateJE)
			end
		end
	end)
	if type(scriptStateVM) == "number" and scriptStateVM >= 1 then
		activeStates.BGSI_Lite_CachedMaxHatch = math.clamp(math.floor(scriptStateVM), 1, 12)
	end
	return activeStates.BGSI_Lite_CachedMaxHatch or 1
end
fallbackUtilityE = nil
function safeGetChildren(targetObject)
	return fallbackUtilityE and fallbackUtilityE(targetObject) or {}
end
sharedEnv = activeStates
sharedEnv._1rzHubLiteEggChunkerTracker = sharedEnv._1rzHubLiteEggChunkerTracker
	or sharedEnv.EggChunkerTracker
	or {
		Chunkers = {},
		Positions = setmetatable({}, {
			__mode = "k",
		}),
		Patched = false,
	}
sharedEnv.EggChunkerTracker = sharedEnv._1rzHubLiteEggChunkerTracker
eggChunkerTracker = sharedEnv._1rzHubLiteEggChunkerTracker
eggChunkerTracker.Chunkers = setmetatable(eggChunkerTracker.Chunkers or {}, {__mode="v"})
eggChunkerTracker.NextId=tonumber(eggChunkerTracker.NextId) or 0
for index in pairs(eggChunkerTracker.Chunkers) do
	if type(index)=="number" then eggChunkerTracker.NextId=math.max(eggChunkerTracker.NextId,index) end
end
eggChunkerTracker.Positions = eggChunkerTracker.Positions or setmetatable({}, {
	__mode = "k",
})
autoPatchEnabled = true
defaultTeleportHeight = 5
infinityEggHeight = 10
cachedEggLookup, cachedEggList, cacheTime = nil, nil, 0
function clearEggScanCache()
	cachedEggLookup, cachedEggList, cacheTime = nil, nil, 0
end
function findChunkerModule()
	local sharedFolder = ReplicatedStorage:FindFirstChild("Shared")
	local scriptStateAAO = sharedFolder and sharedFolder:FindFirstChild("Framework")
	local scriptStateABJ = scriptStateAAO and scriptStateAAO:FindFirstChild("Classes")
	local chunkerModule = scriptStateABJ and scriptStateABJ:FindFirstChild("Chunker")
	if chunkerModule and chunkerModule:IsA("ModuleScript") then
		return chunkerModule
	end
	local utilsFolder = sharedFolder and sharedFolder:FindFirstChild("Utils")
	local scriptStateZQ = utilsFolder and utilsFolder:FindFirstChild("Chunker")
	if scriptStateZQ and scriptStateZQ:IsA("ModuleScript") then
		return scriptStateZQ
	end
	for loopSlotBF, scriptStateQH in ipairs(ReplicatedStorage:GetDescendants()) do
		if scriptStateQH:IsA("ModuleScript") and scriptStateQH.Name == "Chunker" then
			return scriptStateQH
		end
	end
	return nil
end
function registerEggChunker(scriptStateFJ)
	if type(scriptStateFJ) ~= "table" then
		return
	end
	for loopSlotS, scriptStateZH in pairs(eggChunkerTracker.Chunkers) do
		if scriptStateZH == scriptStateFJ then
			return
		end
	end
	eggChunkerTracker.NextId+=1
	eggChunkerTracker.Chunkers[eggChunkerTracker.NextId]=scriptStateFJ
	clearEggScanCache()
end
function isEggChunkerObject(scriptStateFO)
	return type(scriptStateFO) == "table"
		and type(rawget(scriptStateFO, "_chunks")) == "table"
		and type(rawget(scriptStateFO, "_loaded")) == "table"
		and rawget(scriptStateFO, "_chunkSize") ~= nil
		and rawget(scriptStateFO, "RenderDistance") ~= nil
end
function patchEggChunkerModule()
	local scriptStateED = findChunkerModule()
	local scriptStateLO, chunkerInstance = false, nil
	if scriptStateED then
		scriptStateLO, chunkerInstance = pcall(require, scriptStateED)
	end
	if scriptStateLO and type(chunkerInstance) == "table" and not eggChunkerTracker.Patched then
		eggChunkerTracker.Patched = true
		local scriptStateQI = chunkerInstance.new
		if type(scriptStateQI) == "function" then
			chunkerInstance.new = function(...)
				local newChunker = scriptStateQI(...)
				registerEggChunker(newChunker)
				return newChunker
			end
		end
		local scriptStateEU = chunkerInstance.Add
		if type(scriptStateEU) == "function" then
			chunkerInstance.Add = function(self, scriptStateRQ, eggKey, ...)
				registerEggChunker(self)
				if scriptStateRQ ~= nil and eggKey ~= nil then
					eggChunkerTracker.Positions[eggKey] = scriptStateRQ
					clearEggScanCache()
				end
				return scriptStateEU(self, scriptStateRQ, eggKey, ...)
			end
		end
	end
	-- One discovery pass finds existing instances; native new/Add hooks track later ones.
	local optimizer=activeStates.BGSI_Lite_MemoryOptimizer
	if optimizer then optimizer.VisitChunkers(registerEggChunker) end
	return next(eggChunkerTracker.Chunkers)~=nil or (scriptStateLO and type(chunkerInstance) == "table")
end
scriptStateTU = nil
function getEggDataLookup()
	if scriptStateTU then
		return scriptStateTU
	end
	local scriptStateWU = {}
	local eggData = eggDataModule
	if type(eggData) ~= "table" or next(eggData) == nil then
		pcall(function()
			eggData = require(ReplicatedStorage.Shared.Data.Eggs)
		end)
	end
	if type(eggData) == "table" then
		for scriptStateACX in pairs(eggData) do
			if type(scriptStateACX) == "string" then
				scriptStateWU[scriptStateACX] = true
			end
		end
	end
	pcall(function()
		local scriptStateER = ReplicatedStorage:FindFirstChild("Assets")
		local eggsFolder = scriptStateER and scriptStateER:FindFirstChild("Eggs")
		if eggsFolder then
			for loopSlotDW, scriptStateAA in ipairs(eggsFolder:GetChildren()) do
				scriptStateWU[scriptStateAA.Name] = true
			end
		end
	end)
	scriptStateTU = scriptStateWU
	return scriptStateWU
end
function getEggDisplayName(scriptStateII)
	if typeof(scriptStateII) == "Instance" then
		return scriptStateII.Name
	end
	if type(scriptStateII) == "table" then
		return rawget(scriptStateII, "Name")
			or rawget(scriptStateII, "name")
			or rawget(scriptStateII, "Egg")
			or rawget(scriptStateII, "egg")
	end
	if scriptStateII ~= nil then
		return tostring(scriptStateII)
	end
	return nil
end
function isValidEggInstance(scriptStateZO)
	local scriptStateCF = getEggDisplayName(scriptStateZO)
	if type(scriptStateCF) ~= "string" or scriptStateCF == "" then
		return false
	end
	if autoPatchEnabled and scriptStateCF == "Egg" then
		return false
	end
	if getEggDataLookup()[scriptStateCF] then
		return true
	end
	if typeof(scriptStateZO) == "Instance" then
		if CollectionService:HasTag(scriptStateZO, "Egg") then
			return true
		end
		return string.find(string.lower(scriptStateZO.Name), "egg", 1, true) ~= nil
	end
	return string.find(string.lower(scriptStateCF), "egg", 1, true) ~= nil
end
function toVector3(inputValue)
	if typeof(inputValue) == "Vector3" then
		return inputValue
	end
	if typeof(inputValue) == "CFrame" then
		return inputValue.Position
	end
	return nil
end
function getEggPosition(scriptStateMN)
	local cachedPosition = toVector3(eggChunkerTracker.Positions[scriptStateMN])
	if cachedPosition then
		return cachedPosition
	end
	if typeof(scriptStateMN) ~= "Instance" then
		return nil
	end
	local rootCFrame = activeStates.BGSI_Lite_GetInstanceTargetCFrame(scriptStateMN, "Root")
	if rootCFrame then
		return rootCFrame.Position
	end
	local scriptStateADZ, scriptStateABX = pcall(function()
		if scriptStateMN:IsA("Model") then
			return scriptStateMN:GetPivot().Position
		elseif scriptStateMN:IsA("BasePart") then
			return scriptStateMN.Position
		end
	end)
	if scriptStateADZ and typeof(scriptStateABX) == "Vector3" then
		return scriptStateABX
	end
	return nil
end
function getChunkWorldBounds(scriptStateDI, scriptStateOT)
	local scriptStateGW = rawget(scriptStateDI, "_chunkSize") or 1
	local scriptStateABB, scriptStateQY, scriptStateHI = scriptStateGW, scriptStateGW, scriptStateGW
	if typeof(scriptStateGW) == "Vector3" then
		scriptStateABB, scriptStateQY, scriptStateHI = scriptStateGW.X, scriptStateGW.Y, scriptStateGW.Z
	end
	return Vector3.new(
		((scriptStateOT.X or 0) - 0.5) * scriptStateABB,
		((scriptStateOT.Y or 0) - 0.5) * scriptStateQY,
		((scriptStateOT.Z or 0) - 0.5) * scriptStateHI
	)
end
function scoreEggScanResult(scriptStateVU)
	return (scriptStateVU.exact and 1000 or 0) + (scriptStateVU.loaded and 100 or 0)
end
function roundToThreeDecimals(scriptStateLJ)
	scriptStateLJ = tonumber(scriptStateLJ) or 0
	return math.floor(scriptStateLJ * 1000 + (scriptStateLJ >= 0 and 0.5 or -0.5)) / 1000
end
function makeEggLocationKey(scriptStatePJ, scriptStateCC, scriptStateVG, scriptStateNF)
	local scriptStateABF = scriptStateNF and scriptStateNF.X or 0
	local scriptStateFC = scriptStateNF and scriptStateNF.Y or 0
	local scriptStateZR = scriptStateNF and scriptStateNF.Z or 0
	return table.concat({
		tostring(scriptStatePJ or ""),
		tostring(scriptStateVG or 0),
		tostring(scriptStateABF),
		tostring(scriptStateFC),
		tostring(scriptStateZR),
		tostring(roundToThreeDecimals(scriptStateCC and scriptStateCC.X or 0)),
		tostring(roundToThreeDecimals(scriptStateCC and scriptStateCC.Y or 0)),
		tostring(roundToThreeDecimals(scriptStateCC and scriptStateCC.Z or 0)),
	}, "|")
end
function sortEggScanResults(scriptStatePZ)
	table.sort(scriptStatePZ, function(scriptStateADX, scriptStateJN)
		local scriptStateOZ, scriptStateAAU = scoreEggScanResult(scriptStateADX), scoreEggScanResult(scriptStateJN)
		if scriptStateOZ ~= scriptStateAAU then
			return scriptStateOZ > scriptStateAAU
		end
		return tostring(scriptStateADX.key or "") < tostring(scriptStateJN.key or "")
	end)
	return scriptStatePZ
end
function scanRenderedEggs(scriptStateMJ)
	if not scriptStateMJ and cachedEggLookup and tick() - cacheTime < 2 then
		return cachedEggLookup, cachedEggList
	end
	patchEggChunkerModule()
	local scanResults, bestResults = {}, {}
	for loopSlotG, chunker in pairs(eggChunkerTracker.Chunkers) do
		local chunks = rawget(chunker, "_chunks")
		local loadedChunks = rawget(chunker, "_loaded")
		if type(chunks) == "table" then
			for loopSlotDJ, chunkData in pairs(chunks) do
				if type(chunkData) == "table" then
					for loopSlotCT, eggInstance in pairs(chunkData) do
						if isValidEggInstance(eggInstance) then
							local eggName = getEggDisplayName(eggInstance)
							local exactPosition = getEggPosition(eggInstance)
							local eggPosition = exactPosition or getChunkWorldBounds(chunker, loopSlotDJ)
							local scanResult = {
								name = eggName,
								position = eggPosition,
								instance = eggInstance,
								key = makeEggLocationKey(eggName, eggPosition, loopSlotG, loopSlotDJ),
								exact = exactPosition ~= nil,
								loaded = loadedChunks and loadedChunks[loopSlotDJ] ~= nil or false,
								chunker = loopSlotG,
								chunk = loopSlotDJ,
							}
							table.insert(scanResults, scanResult)
							local scriptStateUB = bestResults[eggName]
							if
								not scriptStateUB
								or scoreEggScanResult(scanResult) > scoreEggScanResult(scriptStateUB)
							then
								bestResults[eggName] = scanResult
							end
						end
					end
				end
			end
		end
	end
	table.sort(scanResults, function(resultA, resultB)
		if resultA.name == resultB.name then
			return scoreEggScanResult(resultA) > scoreEggScanResult(resultB)
		end
		return string.lower(resultA.name) < string.lower(resultB.name)
	end)
	cachedEggLookup, cachedEggList, cacheTime = bestResults, scanResults, tick()
	return bestResults, scanResults
end
fallbackUtilityE = function(scriptStateAB)
	local scriptStateUH = scanRenderedEggs(scriptStateAB == true)
	local loopSlotBB = {}
	for scriptStateACQ in pairs(scriptStateUH) do
		table.insert(loopSlotBB, scriptStateACQ)
	end
	table.sort(loopSlotBB, function(loopSlotR, scriptStateKJ)
		return string.lower(loopSlotR) < string.lower(scriptStateKJ)
	end)
	return loopSlotBB
end
function getEggLocationsByName(eggName, forceRescan)
	if type(eggName) ~= "string" or eggName == "" then
		return {}
	end
	local scriptStateSO, scriptStateXE = scanRenderedEggs(forceRescan == true)
	local scriptStateFN = {}
	for loopSlotBQ, scriptStateLA in ipairs(scriptStateXE) do
		if scriptStateLA.name == eggName then
			table.insert(scriptStateFN, scriptStateLA)
		end
	end
	return sortEggScanResults(scriptStateFN)
end
function getEggLocationByKey(loopSlotAV, scriptStatePE, scriptStateES)
	if type(scriptStatePE) ~= "string" or scriptStatePE == "" then
		return nil
	end
	for loopSlotAI, scriptStateAEZ in ipairs(getEggLocationsByName(loopSlotAV, scriptStateES)) do
		if scriptStateAEZ.key == scriptStatePE then
			return scriptStateAEZ
		end
	end
	return nil
end
function chooseBestEggLocation(scriptStateAAH)
	local scriptStateAET = type(Config.selectedEggLocationPriorities) == "table"
			and Config.selectedEggLocationPriorities
		or {}
	local scriptStateABK = scriptStateAET[scriptStateAAH]
	local scriptStateJB = getEggLocationsByName(scriptStateAAH, false)
	local scriptStateVE = getEggLocationByKey(scriptStateAAH, scriptStateABK, false)
	if scriptStateVE then
		return scriptStateVE
	end
	if #scriptStateJB == 0 then
		scriptStateJB = getEggLocationsByName(scriptStateAAH, true)
		scriptStateVE = getEggLocationByKey(scriptStateAAH, scriptStateABK, true)
		if scriptStateVE then
			return scriptStateVE
		end
	end
	if #scriptStateJB == 0 then
		return nil
	end
	return scriptStateJB[1]
end
function makeEggTeleportPosition(scriptStateNG)
	if type(scriptStateNG) ~= "table" or typeof(scriptStateNG.position) ~= "Vector3" then
		return nil
	end
	local heightOffset = (scriptStateNG.name == "Infinity Egg") and infinityEggHeight or defaultTeleportHeight
	return {
		X = scriptStateNG.position.X,
		Y = scriptStateNG.position.Y + heightOffset,
		Z = scriptStateNG.position.Z,
	}
end
function countScannedEggs()
	local scriptStateYU, scriptStateHF = scanRenderedEggs(true)
	local scriptStateSG = 0
	for scriptStateCT in pairs(scriptStateYU) do
		scriptStateSG = scriptStateSG + 1
	end
	return scriptStateSG, #scriptStateHF
end
scanNotificationInProgress = false
function refreshEggScanNotification(scriptStateNT)
	if scanNotificationInProgress then
		return
	end
	scanNotificationInProgress = true
	local scriptStateMS, scriptStateAEF, scriptStateVI = pcall(countScannedEggs)
	scanNotificationInProgress = false
	if not scriptStateNT then
		if scriptStateMS then
			Interface:Notify({
				Title = "Egg scan",
				Content = scriptStateAEF > 0
						and ("Done - found " .. scriptStateAEF .. " egg(s) from " .. scriptStateVI .. " chunker location(s).")
					or "Done - no egg locations found yet.",
				Duration = 6,
			})
		else
			Interface:Notify({
				Title = "Egg scan",
				Content = "Failed: " .. tostring(scriptStateAEF),
				Duration = 5,
			})
		end
	end
end
function getSelectedEggTeleportPosition(scriptStateADY)
	if type(scriptStateADY) ~= "string" or scriptStateADY == "" then
		return nil
	end
	local scriptStateABC = chooseBestEggLocation(scriptStateADY)
	local scriptStateMH = makeEggTeleportPosition(scriptStateABC)
	if scriptStateMH then
		return scriptStateMH
	end
	return nil
end
task.defer(function()
	for loopSlotCG = 1, 20 do
		if patchEggChunkerModule() then
			return
		end
		task.wait(0.5)
	end
end)
teleportOffsetY = 3
function teleportToEggByName(scriptStateABE)
	if isAutomationBlocked() then
		return false
	end
	local selectedEggLocation = chooseBestEggLocation(scriptStateABE)
	local selectedEggInstance = selectedEggLocation and selectedEggLocation.instance
	local eggPlate = typeof(selectedEggInstance) == "Instance"
			and selectedEggInstance:FindFirstChild("Plate", true)
		or nil
	if eggPlate and eggPlate:IsA("BasePart") and eggPlate:IsDescendantOf(Workspace) then
		local character = LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local standingHeight = (humanoid and humanoid.HipHeight or 2)
			+ (rootPart and rootPart.Size.Y / 2 or 1)
		local plateTarget = eggPlate.CFrame * CFrame.new(0, eggPlate.Size.Y / 2 + standingHeight + 0.05, 0)
		if rootPart and (rootPart.Position - plateTarget.Position).Magnitude <= 4 then
			return true
		end
		return teleportToCFrame(plateTarget)
	end

	local scriptStateAEM = getSelectedEggTeleportPosition(scriptStateABE)
	if not scriptStateAEM then
		clearEggScanCache()
		patchEggChunkerModule()
		scriptStateAEM = getSelectedEggTeleportPosition(scriptStateABE)
	end
	if not scriptStateAEM then
		return false
	end
	local eggTarget = CFrame.new(scriptStateAEM.X, scriptStateAEM.Y + teleportOffsetY, scriptStateAEM.Z)
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	if rootPart and (rootPart.Position - eggTarget.Position).Magnitude <= 14 then
		return true
	end
	return teleportToCFrame(eggTarget)
end
lastFiredForNextEggOpenAt = -1
function fireHatchEgg(scriptStateQC)
	if activeStates.BGSI_Lite_InventoryEggBusy then return false end
	if isAutomationBlocked() or activeStates.BGSI_Lite_BubbleQuestActive == true
		or activeStates.BGSI_Lite_TrickOrTreatActive == true
		or type(scriptStateQC) ~= "string" or scriptStateQC == "" then
		return false
	end
	-- A pending bounty summon must not keep hatching the normal egg via the
	-- cooldown callback (or any other ordinary hatch loop).
	if Config.spawnRift == true and not isPriorityAutomationActive()
		and (activeStates.BGSI_Lite_BountyRiftReady ~= true
			or scriptStateQC ~= activeStates.BGSI_Lite_LastBountyRiftEgg) then
		return false
	end

	-- A stale NextEggOpenAt callback can otherwise keep hatching after Auto Hatch is
	-- turned off. Only allow hatch requests while an actual hatch-related automation
	-- is enabled, or while a priority quest is deliberately running a hatch task.
	local hatchAutomationEnabled = activeStates.BGSI_Lite_IsEggAutomationActive()
	if not hatchAutomationEnabled then
		activeStates.BGSI_Lite_LastHatchRequestedEgg = nil
		activeStates.BGSI_Lite_ForceAutoHatchTeleport = false
		return false
	end

	local requestTime = tick()
	local nextEggOpenAt = tonumber(LocalPlayer:GetAttribute("NextEggOpenAt")) or 0
	if getCurrentTimestamp() < nextEggOpenAt then
		return false
	end
	if nextEggOpenAt == lastFiredForNextEggOpenAt then
		return false
	end
	lastFiredForNextEggOpenAt = nextEggOpenAt
	activeStates.BGSI_Lite_LastHatchAttemptAt = requestTime

	local hatchRequestSucceeded = pcall(function()
		local hatchAmount = 1
		local amountOk, resolvedAmount = pcall(getMaxHatchAmount)
		if amountOk and tonumber(resolvedAmount) and tonumber(resolvedAmount) > 0 then
			hatchAmount = math.max(1, math.floor(tonumber(resolvedAmount)))
		end
		remoteEvent:FireServer("HatchEgg", scriptStateQC, hatchAmount)
	end)
	if hatchRequestSucceeded then
		activeStates.BGSI_Lite_LastHatchRequestAt = requestTime
		activeStates.BGSI_Lite_LastHatchRequestedEgg = scriptStateQC
	end
	return hatchRequestSucceeded
end
pcall(function()
	LocalPlayer:GetAttributeChangedSignal("NextEggOpenAt"):Connect(function()
		local eggName = activeStates.BGSI_Lite_LastHatchRequestedEgg
		if type(eggName) ~= "string" or eggName == "" or not isCurrentRun() then
			return
		end
		task.spawn(function()
			local nextEggOpenAt = tonumber(LocalPlayer:GetAttribute("NextEggOpenAt")) or 0
			local waitSeconds = nextEggOpenAt - getCurrentTimestamp()
			if waitSeconds > 0 then
				task.wait(waitSeconds)
			end
				if
				isCurrentRun()
				and activeStates.BGSI_Lite_IsEggAutomationActive()
			then
				fireHatchEgg(eggName)
			end
		end)
	end)
end)
function getBountyTaskRequirement(scriptStateVB)
	if not scriptStateVB then
		return 1
	end
	if questModule and type(questModule.GetRequirement) == "function" then
		local scriptStateJK, scriptStateLK = pcall(function()
			return questModule:GetRequirement(scriptStateVB)
		end)
		if scriptStateJK and type(scriptStateLK) == "number" then
			return scriptStateLK
		end
	end
	if type(scriptStateVB) == "table" then
		local scriptStateWW = tonumber(scriptStateVB.Amount or scriptStateVB.amount)
		if scriptStateWW then
			return scriptStateWW
		end
		if type(scriptStateVB.Item) == "table" then
			local scriptStateZJ = tonumber(scriptStateVB.Item.Amount or scriptStateVB.Item.amount)
			if scriptStateZJ then
				return scriptStateZJ
			end
		end
	end
	return 1
end
function getBountyTaskProgress(scriptStateL, loopSlotC)
	if not scriptStateL or not loopSlotC then
		return 0
	end
	local scriptStatePF = 0
	if questModule then
		pcall(function()
			if type(questModule.GetTaskProgress) == "function" then
				local scriptStateADQ = questModule:GetTaskProgress(scriptStateL, loopSlotC)
				if type(scriptStateADQ) == "number" and scriptStateADQ > scriptStatePF then
					scriptStatePF = scriptStateADQ
				end
			end
		end)
	end
	if scriptStateL.Progress and type(scriptStateL.Progress) == "table" then
		for loopSlotT, scriptStateLI in ipairs({
			loopSlotC,
			tostring(loopSlotC),
			tonumber(loopSlotC),
		}) do
			local scriptStateJL = scriptStateL.Progress[scriptStateLI]
			if type(scriptStateJL) == "number" and scriptStateJL > scriptStatePF then
				scriptStatePF = scriptStateJL
			end
		end
	end
	local scriptStateNZ = scriptStateL.Tasks and scriptStateL.Tasks[loopSlotC]
	if type(scriptStateNZ) == "table" then
		if scriptStateNZ.Completed == true then
			scriptStatePF = math.max(scriptStatePF, getBountyTaskRequirement(scriptStateNZ))
		end
		for loopSlotBU, scriptStateOD in ipairs({
			"Progress",
			"Current",
			"Count",
			"Value",
		}) do
			local scriptStateIV = scriptStateNZ[scriptStateOD]
			if type(scriptStateIV) == "number" and scriptStateIV > scriptStatePF then
				scriptStatePF = scriptStateIV
			end
		end
	end
	return scriptStatePF
end
activeStates.BGSI_Lite_QuestNoProgressTimeout = math.clamp(tonumber(Config.questStallTimeoutSeconds) or 60, 30, 300)
activeStates.BGSI_Lite_QuestStallRetryDelay = 120
activeStates.BGSI_Lite_StalledQuestTasks = activeStates.BGSI_Lite_StalledQuestTasks or {}
activeStates.BGSI_Lite_ActiveQuest = nil
activeStates.BGSI_Lite_GetQuestTaskKey = function(questData, taskIndex)
	local questId = type(questData) == "table"
		and (questData.Id or questData.ID or questData.Name or questData.Type)
	local questTask = type(questData) == "table" and type(questData.Tasks) == "table"
		and questData.Tasks[taskIndex]
	local taskId = type(questTask) == "table"
		and (questTask.Id or questTask.ID or questTask.Name or questTask.Type)
	return tostring(questId or "quest") .. ":" .. tostring(taskIndex) .. ":" .. tostring(taskId or "task")
end
activeStates.BGSI_Lite_SetActiveQuest = function(questData, taskIndex, progress, state)
	if type(questData) ~= "table" then
		return
	end
	local questTask = type(questData.Tasks) == "table" and questData.Tasks[taskIndex]
	if type(questTask) ~= "table" then
		return
	end
	local requirement = math.max(0, tonumber(getBountyTaskRequirement(questTask)) or 0)
	progress = math.max(0, tonumber(progress) or getBountyTaskProgress(questData, taskIndex))
	local taskKey = activeStates.BGSI_Lite_GetQuestTaskKey(questData, taskIndex)
	local currentQuest = activeStates.BGSI_Lite_ActiveQuest
	if type(currentQuest) == "table" and currentQuest.taskKey == taskKey then
		currentQuest.progress = progress
		currentQuest.requirement = requirement
		currentQuest.state = state or (requirement > 0 and progress >= requirement and "complete" or "active")
		currentQuest.updatedAt = os.time()
		return
	end
	local questId = tostring(questData.Id or questData.ID or questData.Name or "quest")
	local taskId = tostring(questTask.Id or questTask.ID or questTask.Name or questTask.Type or taskIndex)
	local title = tostring(questTask.Title or questTask.Name or questTask.Description or questTask.Type or "Quest task")
	if questModule and type(questModule.FormatTask) == "function" then
		local formattedOk, formattedTitle = pcall(function()
			return questModule:FormatTask(questTask)
		end)
		if formattedOk and type(formattedTitle) == "string" and formattedTitle ~= "" then
			title = formattedTitle
		end
	end
	title = title:gsub("<.->", ""):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
	local loweredQuestId = string.lower(questId)
	local questKind = "quest"
	if string.find(loweredQuestId, "gem%-genie") then
		questKind = "gem-genie"
	elseif string.find(loweredQuestId, "daily%-challenge") or string.find(loweredQuestId, "hourly%-challenge") then
		questKind = "season"
	elseif string.find(loweredQuestId, "global%-incentive") then
		questKind = "global"
	elseif string.find(loweredQuestId, "bubble%-challenge") then
		questKind = "challenge"
	elseif string.find(loweredQuestId, "^guild%-") then
		questKind = "guild"
	end
	activeStates.BGSI_Lite_ActiveQuest = {
		kind = questKind,
		id = questId .. ":" .. taskId,
		title = title,
		progress = progress,
		requirement = requirement,
		state = state or (requirement > 0 and progress >= requirement and "complete" or "active"),
		updatedAt = os.time(),
		taskKey = taskKey,
	}
end
activeStates.BGSI_Lite_ClearActiveQuest = function(questData, taskIndex)
	local activeQuest = activeStates.BGSI_Lite_ActiveQuest
	if type(activeQuest) ~= "table" then
		return
	end
	if questData and taskIndex and activeQuest.taskKey ~= activeStates.BGSI_Lite_GetQuestTaskKey(questData, taskIndex) then
		return
	end
	if activeQuest.state == "stalled" then
		local stalledTaskKey = activeQuest.taskKey
		task.delay(15, function()
			local currentQuest = activeStates.BGSI_Lite_ActiveQuest
			if type(currentQuest) == "table" and currentQuest.taskKey == stalledTaskKey then
				activeStates.BGSI_Lite_ActiveQuest = nil
			end
		end)
		return
	end
	activeStates.BGSI_Lite_ActiveQuest = nil
end
activeStates.BGSI_Lite_IsQuestTaskDeferred = function(questData, taskIndex)
	local taskKey = activeStates.BGSI_Lite_GetQuestTaskKey(questData, taskIndex)
	local stalledTask = activeStates.BGSI_Lite_StalledQuestTasks[taskKey]
	if type(stalledTask) ~= "table" then
		return false
	end
	local currentProgress = getBountyTaskProgress(questData, taskIndex)
	if currentProgress > (tonumber(stalledTask.Progress) or 0) or tick() >= (tonumber(stalledTask.RetryAt) or 0) then
		activeStates.BGSI_Lite_StalledQuestTasks[taskKey] = nil
		return false
	end
	return true
end
activeStates.BGSI_Lite_RecordQuestProgress = function(watchState, questData, taskIndex, progress)
	activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
	activeStates.BGSI_Lite_QuestNoProgressTimeout = math.clamp(
		tonumber(Config.questStallTimeoutSeconds) or 60,
		30,
		300
	)
	progress = tonumber(progress) or 0
	activeStates.BGSI_Lite_SetActiveQuest(questData, taskIndex, progress, "active")
	if type(watchState) ~= "table" then
		watchState = { Progress = progress, ChangedAt = tick() }
	elseif progress > (tonumber(watchState.Progress) or 0) then
		watchState.Progress = progress
		watchState.ChangedAt = tick()
	end
	if tick() - (tonumber(watchState.ChangedAt) or tick()) < activeStates.BGSI_Lite_QuestNoProgressTimeout then
		return watchState, false
	end
	local taskKey = activeStates.BGSI_Lite_GetQuestTaskKey(questData, taskIndex)
	activeStates.BGSI_Lite_StalledQuestTasks[taskKey] = {
		Progress = progress,
		RetryAt = tick() + activeStates.BGSI_Lite_QuestStallRetryDelay,
	}
	activeStates.BGSI_Lite_SetActiveQuest(questData, taskIndex, progress, "stalled")
	if string.find(string.lower(taskKey), "gem-genie", 1, true) then
		pcall(function()
			remoteEvent:FireServer("RerollGenie")
		end)
	end
	warn(
		"[1rzHub Lite] Quest task made no progress for "
			.. tostring(activeStates.BGSI_Lite_QuestNoProgressTimeout)
			.. " seconds; moving to the next task:",
		taskKey
	)
	return watchState, true
end
function makeIndexList(scriptStateMG)
	if type(scriptStateMG) ~= "table" then
		return {}
	end
	if #scriptStateMG > 0 then
		local scriptStateC = {}
		for loopSlotCJ = 1, #scriptStateMG do
			scriptStateC[loopSlotCJ] = loopSlotCJ
		end
		return scriptStateC
	end
	local scriptStateA = {}
	for scriptStateADP in pairs(scriptStateMG) do
		local scriptStateNN = tonumber(scriptStateADP)
		if scriptStateNN and scriptStateNN >= 1 then
			table.insert(scriptStateA, scriptStateNN)
		end
	end
	table.sort(scriptStateA)
	return scriptStateA
end
function normalizeBountyTask(scriptStateXW)
	if type(scriptStateXW) ~= "table" then
		return scriptStateXW
	end
	local scriptStateOU = scriptStateXW.Item
	if type(scriptStateOU) == "table" and type(scriptStateOU.Task) == "table" then
		return scriptStateOU.Task
	end
	if type(scriptStateXW.Task) == "table" then
		return scriptStateXW.Task
	end
	return scriptStateXW
end
function isCoinOrCollectBountyTask(shopItemEntry)
	shopItemEntry = normalizeBountyTask(shopItemEntry)
	if type(shopItemEntry) ~= "table" then
		return false
	end
	local scriptStateNC = shopItemEntry.Type or shopItemEntry.type
	if type(scriptStateNC) == "string" then
		local scriptStateZA = string.lower(scriptStateNC)
		if
			scriptStateZA == "collect"
			or scriptStateZA == "coins"
			or scriptStateZA == "coin"
			or string.find(scriptStateZA, "ticket", 1, true)
			or string.find(scriptStateZA, "pearl", 1, true)
		then
			return true
		end
	end
	local scriptStateAAW = shopItemEntry.Item
	if type(scriptStateAAW) == "table" and (scriptStateAAW.Type == "Currency") then
		return true
	end
	local scriptStateAAWTable = type(scriptStateAAW) == "table" and scriptStateAAW or {}
	for _, scriptStateAAC in ipairs({
		shopItemEntry.Currency,
		shopItemEntry.Name,
		shopItemEntry.Title,
		shopItemEntry.Description,
		scriptStateAAWTable.Currency,
		scriptStateAAWTable.Name,
	}) do
		if type(scriptStateAAC) == "string" then
			local scriptStateAAA = string.lower(scriptStateAAC)
			if string.find(scriptStateAAA, "ticket", 1, true) or string.find(scriptStateAAA, "pearl", 1, true) then
				return true
			end
		end
	end
	return false
end
function getBountyCurrencyName(scriptStateADE)
	scriptStateADE = normalizeBountyTask(scriptStateADE)
	if type(scriptStateADE) ~= "table" then
		return nil
	end
	local scriptStateAAW = type(scriptStateADE.Item) == "table" and scriptStateADE.Item or {}
	local scriptStateN = scriptStateAAW.Currency or scriptStateADE.Currency
	if type(scriptStateN) == "string" and string.find(string.lower(scriptStateN), "ticket", 1, true) then
		return "tickets"
	end
	if type(scriptStateN) == "string" and string.find(string.lower(scriptStateN), "pearl", 1, true) then
		return "pearls"
	end
	if scriptStateAAW.Type == "Currency" and type(scriptStateN) == "string" then
		return string.lower(scriptStateN)
	end
	-- Quest templates differ across Season, Guild, Genie, and event systems.
	-- A nil first field stops ipairs over the optional fields below, so inspect
	-- the shared recursive task text before falling back to generic collection.
	local taskText = activeStates.BGSI_Lite_GetBountyTaskSearchText(scriptStateADE)
	if taskText:find("ticket", 1, true) then return "tickets" end
	if taskText:find("pearl", 1, true) then return "pearls" end
	for _, scriptStateAAA in ipairs({
		scriptStateADE.Type,
		scriptStateADE.Name,
		scriptStateADE.Title,
		scriptStateADE.Description,
		scriptStateAAW.Type,
		scriptStateAAW.Name,
	}) do
		if type(scriptStateAAA) == "string" and string.find(string.lower(scriptStateAAA), "ticket", 1, true) then
			return "tickets"
		end
		if type(scriptStateAAA) == "string" and string.find(string.lower(scriptStateAAA), "pearl", 1, true) then
			return "pearls"
		end
	end
	return nil
end
function getBountyTaskType(scriptStateADT)
	scriptStateADT = normalizeBountyTask(scriptStateADT)
	if type(scriptStateADT) ~= "table" then
		return ""
	end
	return string.lower(tostring(scriptStateADT.Type or scriptStateADT.type or ""))
end
activeStates.BGSI_Lite_GetBountyTaskSearchText = function(scriptStateTask, seenTasks, depth)
	scriptStateTask = normalizeBountyTask(scriptStateTask)
	if type(scriptStateTask) ~= "table" then
		return string.lower(tostring(scriptStateTask or ""))
	end
	seenTasks = seenTasks or {}
	depth = tonumber(depth) or 0
	if seenTasks[scriptStateTask] or depth > 3 then
		return ""
	end
	seenTasks[scriptStateTask] = true
	local taskTextParts = {}
	for _, taskTextKey in ipairs({
		"Type",
		"type",
		"Name",
		"name",
		"Title",
		"title",
		"Description",
		"description",
		"Text",
		"text",
		"DisplayName",
		"displayName",
		"Objective",
		"objective",
		"Task",
		"task",
	}) do
		local taskTextValue = rawget(scriptStateTask, taskTextKey)
		if type(taskTextValue) == "string" then
			table.insert(taskTextParts, taskTextValue)
		elseif type(taskTextValue) == "table" then
			table.insert(
				taskTextParts,
				activeStates.BGSI_Lite_GetBountyTaskSearchText(taskTextValue, seenTasks, depth + 1)
			)
		end
	end
	if type(scriptStateTask.Item) == "table" then
		table.insert(
			taskTextParts,
			activeStates.BGSI_Lite_GetBountyTaskSearchText(scriptStateTask.Item, seenTasks, depth + 1)
		)
	end
	return string.lower(table.concat(taskTextParts, " "))
end
function isBubbleBountyTask(scriptStateCR)
	local scriptStateOV = getBountyTaskType(scriptStateCR)
	local taskSearchText = activeStates.BGSI_Lite_GetBountyTaskSearchText(scriptStateCR)
	return scriptStateOV == "bubble"
		or scriptStateOV == "bubbles"
		or string.find(scriptStateOV, "bubble", 1, true) ~= nil
		or string.find(taskSearchText, "bubble", 1, true) ~= nil
end
activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest = function(scriptStateTask)
	if Config.skipTicketPearlQuests ~= true or not isCoinOrCollectBountyTask(scriptStateTask) then
		return false
	end
	local currencyName = getBountyCurrencyName(scriptStateTask)
	if currencyName == "tickets" or currencyName == "pearls" then
		return true
	end
	local taskSearchText = activeStates.BGSI_Lite_GetBountyTaskSearchText(scriptStateTask)
	return string.find(taskSearchText, "ticket", 1, true) ~= nil or string.find(taskSearchText, "pearl", 1, true) ~= nil
end
activeStates.BGSI_Lite_ShouldSkipBubblingQuest = function(scriptStateTask)
	if Config.skipBubblingQuests ~= true or not isBubbleBountyTask(scriptStateTask) then
		return false
	end
	return true
end
activeStates.BGSI_Lite_HasSkippedTicketOrPearlTask = function(scriptStateQuest)
	if type(scriptStateQuest) ~= "table" or type(scriptStateQuest.Tasks) ~= "table" then
		return false
	end
	for _, taskIndex in ipairs(makeIndexList(scriptStateQuest.Tasks)) do
		local questTask = scriptStateQuest.Tasks[taskIndex]
		if
			type(questTask) == "table"
			and activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(questTask)
			and getBountyTaskProgress(scriptStateQuest, taskIndex) < getBountyTaskRequirement(questTask)
		then
			return true
		end
	end
	return false
end
activeStates.BGSI_Lite_HasSkippedBubblingTask = function(scriptStateQuest)
	if type(scriptStateQuest) ~= "table" or type(scriptStateQuest.Tasks) ~= "table" then
		return false
	end
	for _, taskIndex in ipairs(makeIndexList(scriptStateQuest.Tasks)) do
		local questTask = scriptStateQuest.Tasks[taskIndex]
		if
			type(questTask) == "table"
			and activeStates.BGSI_Lite_ShouldSkipBubblingQuest(questTask)
			and getBountyTaskProgress(scriptStateQuest, taskIndex) < getBountyTaskRequirement(questTask)
		then
			return true
		end
	end
	return false
end
activeStates.BGSI_Lite_HasActionableUnfinishedQuestTask = function(scriptStateQuest)
	if type(scriptStateQuest) ~= "table" or type(scriptStateQuest.Tasks) ~= "table" then
		return false
	end
	for _, taskIndex in ipairs(makeIndexList(scriptStateQuest.Tasks)) do
		local questTask = scriptStateQuest.Tasks[taskIndex]
		if
			type(questTask) == "table"
			and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(questTask)
			and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(questTask)
			and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateQuest, taskIndex)
			and getBountyTaskProgress(scriptStateQuest, taskIndex) < getBountyTaskRequirement(questTask)
		then
			return true
		end
	end
	return false
end
function isHatchBountyTask(scriptStateRF)
	local scriptStateXZ = getBountyTaskType(scriptStateRF)
	if scriptStateXZ == "hatchegggroup" then
		return false
	end
	local taskSearchText = activeStates.BGSI_Lite_GetBountyTaskSearchText(scriptStateRF)
	return scriptStateXZ == "hatch"
		or string.find(scriptStateXZ, "hatch", 1, true) ~= nil
		or string.find(taskSearchText, "hatch", 1, true) ~= nil
		or (string.find(taskSearchText, "open", 1, true) ~= nil and string.find(taskSearchText, "egg", 1, true) ~= nil)
end
activeStates.BGSI_Lite_IsSpecificEggName = function(eggName)
	if type(eggName) ~= "string" then
		return false
	end
	local trimmedEggName = eggName:gsub("^%s+", ""):gsub("%s+$", "")
	if trimmedEggName == "" or trimmedEggName == "Egg" or trimmedEggName == "Eggs" then
		return false
	end
	if string.sub(trimmedEggName, 1, 1) == "(" then
		return false
	end
	return true
end
function getBountyEggName(scriptStateBO)
	local scriptStateLL = normalizeBountyTask(scriptStateBO) or scriptStateBO
	if type(scriptStateLL) == "table" then
		local scriptStateDG = scriptStateLL.Egg or scriptStateLL.egg or scriptStateLL.EggName
		if activeStates.BGSI_Lite_IsSpecificEggName(scriptStateDG) then
			return scriptStateDG
		end
		if type(scriptStateLL.Item) == "table" then
			local scriptStateB = scriptStateLL.Item.Name or scriptStateLL.Item.Egg
			if activeStates.BGSI_Lite_IsSpecificEggName(scriptStateB) then
				return scriptStateB
			end
		end
		if scriptStateLL.Rarity then
			if type(scriptStateLL.Rarity) == "string" and string.lower(scriptStateLL.Rarity) == "unique" then
				return "Void Egg"
			end
			return "Infinity Egg"
		end
	end
	return activeStates.BGSI_Lite_IsSpecificEggName(Config.selectedEgg) and Config.selectedEgg or "Common Egg"
end
gemShopSlots = nil
function getGemShopSlots()
	if type(gemShopSlots) == "table" then
		return gemShopSlots
	end
	local loopSlotI = {}
	local scriptStateYM, scriptStateBE = pcall(function()
		return require(ReplicatedStorage.Shared.Data.Shops)
	end)
	if not scriptStateYM or type(scriptStateBE) ~= "table" then
		gemShopSlots = loopSlotI
		return loopSlotI
	end
	local function addGemShopSlotIfValid(scriptStateXV, scriptStateLW, scriptStateKE)
		if type(scriptStateKE) ~= "table" then
			return
		end
		local scriptStateUG = scriptStateKE.Cost or (type(scriptStateKE.Item) == "table" and scriptStateKE.Item.Cost)
		if type(scriptStateUG) ~= "table" then
			return
		end
		local scriptStateAL = scriptStateUG.Currency
		local scriptStateGA = tonumber(scriptStateUG.Amount)
		if
			type(scriptStateAL) == "string"
			and string.lower(scriptStateAL) == "gems"
			and scriptStateGA
			and scriptStateGA > 0
		then
			table.insert(loopSlotI, {
				shop = scriptStateXV,
				slot = scriptStateLW,
				amount = scriptStateGA,
			})
		end
	end
	for loopSlotAF, scriptStateYG in pairs(scriptStateBE) do
		if type(loopSlotAF) == "string" and type(scriptStateYG) == "table" then
			for loopSlotDD, scriptStateUM in ipairs({
				"PermanentItems",
				"RandomItems",
				"Items",
				"Slots",
			}) do
				if type(scriptStateYG[scriptStateUM]) == "table" then
					for loopSlotCD, scriptStateAAY in pairs(scriptStateYG[scriptStateUM]) do
						addGemShopSlotIfValid(loopSlotAF, loopSlotCD, scriptStateAAY)
					end
				end
			end
		end
	end
	table.sort(loopSlotI, function(loopSlotBC, scriptStateCH)
		return loopSlotBC.amount < scriptStateCH.amount
	end)
	gemShopSlots = loopSlotI
	return loopSlotI
end
function getCurrentCoins()
	local scriptStateRY = 0
	pcall(function()
		if profileStore:IsReady() then
			local scriptStateWE = profileStore:Get() or {}
			scriptStateRY = tonumber(scriptStateWE.Coins) or 0
		end
	end)
	return scriptStateRY
end
function getCurrentGems()
	local scriptStateBN = 0
	pcall(function()
		if profileStore:IsReady() then
			local scriptStateHO = profileStore:Get() or {}
			scriptStateBN = tonumber(scriptStateHO.Gems) or 0
			if scriptStateBN <= 0 and type(scriptStateHO.Currencies) == "table" then
				scriptStateBN = tonumber(scriptStateHO.Currencies.Gems) or 0
			end
		end
	end)
	return scriptStateBN
end
gemReserveThreshold = 4999000000000
function hatchEggForDuration(scriptStateTY, scriptStateMI)
	local scriptStateAFN = tick() + (scriptStateMI or 5)
	pcall(function()
		teleportToEggByName(scriptStateTY)
	end)
	local scriptStateAEP = tick()
	while tick() < scriptStateAFN do
		if tick() - scriptStateAEP >= 2 then
			pcall(function()
				teleportToEggByName(scriptStateTY)
			end)
			scriptStateAEP = tick()
		end
		fireHatchEgg(scriptStateTY)
		task.wait(0.1)
	end
end
function spendGemsDownToReserve(scriptStateACD, scriptStateEM)
	local scriptStateQN = getGemShopSlots()
	if #scriptStateQN == 0 then
		return 0
	end
	local scriptStateNX = getCurrentGems()
	local scriptStateWP = math.max(0, scriptStateNX - math.max(0, scriptStateACD or 0))
	local scriptStateAX = tick() + (scriptStateEM or 30)
	while tick() < scriptStateAX do
		local scriptStateJR = getCurrentGems()
		if scriptStateJR <= scriptStateWP then
			break
		end
		local scriptStateHQ = false
		for loopSlotBN = #scriptStateQN, 1, -1 do
			local scriptStateZV = scriptStateQN[loopSlotBN]
			if scriptStateJR >= scriptStateZV.amount then
				pcall(function()
					remoteEvent:FireServer("BuyShopItem", scriptStateZV.shop, scriptStateZV.slot, false)
				end)
				scriptStateHQ = true
				task.wait(0.5)
				scriptStateJR = getCurrentGems()
				if scriptStateJR <= scriptStateWP then
					break
				end
			end
		end
		if not scriptStateHQ then
			break
		end
		task.wait(0.05)
	end
	return scriptStateNX - getCurrentGems()
end
scriptStateAAN = CFrame.new(11, 15973, 45)
scriptStateZG = CFrame.new(2286, 3158, 850)
function teleportToCurrencyArea(scriptStateIG)
	return teleportToCFrame(scriptStateIG == "gems" and scriptStateZG or scriptStateAAN)
end
function spamClaimGiantChest(scriptStateAAP)
	local scriptStateAEI = tick() + (scriptStateAAP or 5)
	while tick() < scriptStateAEI do
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local cooldownEndsAt = playerData
			and type(playerData.Cooldowns) == "table"
			and tonumber(playerData.Cooldowns["Giant Chest"])
			or 0
		if cooldownEndsAt > getCurrentTimestamp() then
			return
		end
		pcall(remoteEvent.FireServer, remoteEvent, "ClaimChest", "Giant Chest", true)
		task.wait(0.5)
	end
end
scriptStateHD = 200
scriptStateCE = nil
function installPickupRangeHook()
	if not isCurrentRun() then return false end
	if not scriptStateCE then
		pcall(function()
			scriptStateCE = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
		end)
	end
	local statsModule = scriptStateCE
	if type(statsModule) ~= "table" or type(statsModule.GetPickupRange) ~= "function" then
		return false
	end
	if rawget(statsModule, "_BGSI_LITE_GetPickupRangeOrig") == nil then
		statsModule._BGSI_LITE_GetPickupRangeOrig = statsModule.GetPickupRange
	end
	local prior=rawget(statsModule,"_BGSI_LITE_PickupRangeHook")
	if prior and prior.Owner==currentRunToken and statsModule.GetPickupRange==prior.Fn then return true end
	local hook={Owner=currentRunToken}
	hook.Fn = function(self, scriptStateEA)
		local scriptStateAFF = statsModule._BGSI_LITE_GetPickupRangeOrig
		local scriptStateOA = scriptStateAFF(self, scriptStateEA)
		if type(scriptStateOA) ~= "number" or scriptStateOA ~= scriptStateOA then
			return scriptStateOA
		end
		if not isCurrentRun() or Config.safeMode==true then return scriptStateOA end
		local runtimeStates = (getgenv and getgenv()) or activeStates
		local featureActive = runtimeStates.BGSI_Lite_GemGenieActive
			or runtimeStates.BGSI_Lite_SeasonActive
			or runtimeStates.BGSI_Lite_GlobalIncentiveActive
		if runtimeStates.BGSI_Lite_TicketPickupActive or runtimeStates.BGSI_Lite_CarnivalPickupActive then
			return math.max(scriptStateOA, 1000000)
		end
		if Config.autoCollectCoins == true or featureActive then
			return math.max(scriptStateOA, scriptStateHD)
		end
		return scriptStateOA
	end
	function hook.Destroy()
		if statsModule.GetPickupRange==hook.Fn then statsModule.GetPickupRange=statsModule._BGSI_LITE_GetPickupRangeOrig end
		if statsModule._BGSI_LITE_PickupRangeHook==hook then statsModule._BGSI_LITE_PickupRangeHook=nil end
	end
	statsModule.GetPickupRange=hook.Fn
	statsModule._BGSI_LITE_PickupRangeHook=hook
	activeStates.BGSI_Lite_PickupRangeHook=hook
	return true
end
task.defer(function()
	for loopSlotCP = 1, 40 do
		if not isCurrentRun() then return end
		if installPickupRangeHook() then
			return
		end
		task.wait(0.5)
	end
	warn("[1rzHub Lite] Pickup range hook failed — StatsUtil not found.")
end)
task.spawn(function()
	while isCurrentRun() do
		task.wait(2)
		if isCurrentRun() then pcall(installPickupRangeHook) end
	end
end)
function useGoldenOrbs(scriptStateKH, scriptStateAAT)
	scriptStateKH = scriptStateKH or 4
	scriptStateAAT = scriptStateAAT or 0.4
	for loopSlotBH = 1, scriptStateKH do
		pcall(function()
			remoteEvent:FireServer("UseGoldenOrb")
		end)
		task.wait(scriptStateAAT)
	end
end
function runCurrencyOrbPrep(scriptStateEV, scriptStateDJ)
	teleportToCurrencyArea(scriptStateEV)
	task.wait(0.15)
	if scriptStateEV == "gems" then
		local scriptStateHL = getCurrentGems()
		local scriptStateACN = math.max(100000, tonumber(scriptStateDJ) or 0)
		if scriptStateHL > scriptStateACN then
			spendGemsDownToReserve(scriptStateACN, 60)
			teleportToCurrencyArea(scriptStateEV)
			task.wait(0.15)
		end
	else
		local scriptStateZD = getCurrentCoins()
		if scriptStateZD >= gemReserveThreshold then
			hatchEggForDuration("Rainbow Egg", 4)
			teleportToCurrencyArea(scriptStateEV)
			task.wait(0.15)
		end
	end
	task.spawn(useGoldenOrbs, 4, 1)
	spamClaimGiantChest(5)
end
function runHatchBountyTask(scriptStateWT, scriptStateI, scriptStateDF, scriptStateAAJ)
	pcall(activeStates.BGSI_Lite_ApplyCurrencyTeam, "hatch")
	local scriptStateUA = 0
	local questProgressWatch
	local scriptStateStalled
	local activeQuestData
	local lastTeleportedEgg
	local teleportConfirmed = false
	local teleportFailures = 0
	local lastTeleportWarnAt = 0
	while scriptStateAAJ() do
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		local scriptStateVL = scriptStateWT()
		if not scriptStateVL then
			break
		end
		activeQuestData = scriptStateVL
		local scriptStateIF = scriptStateVL.Tasks and scriptStateVL.Tasks[scriptStateI]
		local scriptStateVR = scriptStateDF
		if scriptStateIF then
			scriptStateVR = getBountyTaskRequirement(scriptStateIF)
		end
		local scriptStateSP = getBountyTaskProgress(scriptStateVL, scriptStateI)
		questProgressWatch, scriptStateStalled = activeStates.BGSI_Lite_RecordQuestProgress(
			questProgressWatch,
			scriptStateVL,
			scriptStateI,
			scriptStateSP
		)
		if scriptStateStalled then
			activeStates.BGSI_Lite_ClearActiveQuest(scriptStateVL, scriptStateI)
			return false, "NoProgress"
		end
		if type(scriptStateVR) == "number" and scriptStateSP >= scriptStateVR then
			break
		end
		if scriptStateVL.Completed then
			break
		end
		if type(scriptStateIF) == "table" and scriptStateIF.Completed then
			break
		end
		local scriptStateYV = getBountyEggName(scriptStateIF or {})
		if scriptStateYV ~= lastTeleportedEgg then
			lastTeleportedEgg = scriptStateYV
			teleportConfirmed = false
			teleportFailures = 0
			scriptStateUA = 0
		end
		-- Once a teleport has actually confirmed the character is at this egg, a 3s
		-- refresh is plenty (matches the old cadence, covers normal drift). Until then,
		-- retry every 0.5s instead of quietly waiting out the full 3s per attempt - a
		-- streaming hiccup should cost a fraction of a second of retries, not stall the
		-- whole task.
		local retryInterval = teleportConfirmed and 3 or 0.5
		if tick() - scriptStateUA >= retryInterval then
			local teleportOk, teleportLanded = pcall(teleportToEggByName, scriptStateYV)
			scriptStateUA = tick()
			if teleportOk and teleportLanded then
				teleportConfirmed = true
				teleportFailures = 0
			elseif not teleportConfirmed then
				teleportFailures += 1
				if teleportFailures >= 6 and tick() - lastTeleportWarnAt >= 10 then
					lastTeleportWarnAt = tick()
					warn(
						'[1rzHub Lite] Quest hatch can\'t find/reach "'
							.. tostring(scriptStateYV)
							.. '" yet - still retrying (this clears itself once the egg streams in, or the 60s stall timeout will move on)'
					)
				end
			end
		end
		-- Firing HatchEgg before a teleport has ever actually landed for this egg just
		-- wastes calls the server will reject anyway - wait for real confirmation first.
		if teleportConfirmed then
			fireHatchEgg(scriptStateYV)
		end
		task.wait(0.1)
	end
	activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, scriptStateI)
end
activeStates.BGSI_Lite_FindSellBubbleStation = function()
	-- No caching here on purpose: a station that's still Parented but simply far away
	-- (e.g. after changing worlds) used to get reused forever since ".Parent ~= nil" was
	-- the only invalidation check - teleporting to a stale, wrong-world kiosk meant Sell
	-- was silently rejected for being out of range, bubbles capped out at max storage,
	-- and Blow then refuses to fire at all once storage is full (it sells instead) - the
	-- whole bubble task would just stop making progress. Recomputing the nearest tagged
	-- Sell instance fresh every call is cheap enough given Sell is already throttled to
	-- roughly one call every 0.35s+, and it can never go stale.
	local ok, tagged = pcall(function()
		return CollectionService:GetTagged("Activation")
	end)
	if not ok or type(tagged) ~= "table" then
		return nil
	end
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local closest, closestDistance
	for _, taggedInstance in ipairs(tagged) do
		if taggedInstance.Name == "Sell" then
			local targetCFrame = activeStates.BGSI_Lite_GetInstanceTargetCFrame(taggedInstance, "Root")
			if targetCFrame then
				if not rootPart then
					closest = taggedInstance
					break
				end
				local distance = (targetCFrame.Position - rootPart.Position).Magnitude
				if not closestDistance or distance < closestDistance then
					closest = taggedInstance
					closestDistance = distance
				end
			end
		end
	end
	return closest
end
activeStates.BGSI_Lite_SellBubble = function()
	local attemptTime = tick()
	if attemptTime - (tonumber(activeStates.BGSI_Lite_LastBubbleSellAttemptAt) or 0) < 0.1 then
		return false
	end
	local pendingSellAt = tonumber(activeStates.BGSI_Lite_BubbleSellPendingAt) or 0
	if pendingSellAt > 0 and attemptTime - pendingSellAt < 0.35 then
		return false
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	local bubbleAmount = playerData and type(playerData.Bubble) == "table"
		and math.max(0, tonumber(playerData.Bubble.Amount) or 0)
		or 0
	if bubbleAmount <= 0 then
		return false
	end
	-- Sell requires actually being near the world Sell kiosk, unlike Blow. Snap the real
	-- HumanoidRootPart to the kiosk, fire, then snap straight back to wherever the
	-- player actually was - all with no task.wait between, so both moves land inside
	-- the same frame the game renders and the trip is at most a single-frame flicker,
	-- not a lasting teleport away from wherever the player is actually farming.
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local originalCFrame = rootPart and rootPart.CFrame
	local sellStation = activeStates.BGSI_Lite_FindSellBubbleStation()
	local sellStationCFrame = sellStation
		and activeStates.BGSI_Lite_GetInstanceTargetCFrame(sellStation, "Root")
	-- Guaranteed fallback if the live tag scan ever comes up empty (e.g. it hasn't
	-- streamed in yet): the real position of workspace.Worlds["The Overworld"].Sell.Root,
	-- confirmed by parsing the game's own place file binary data directly (decoding its
	-- INST/PROP/PRNT chunks) rather than guessing.
	if not sellStationCFrame then
		sellStationCFrame = CFrame.new(77.556, 6.216, -113.065)
	end
	if rootPart and sellStationCFrame then
		rootPart.CFrame = sellStationCFrame
	end
	local sellSucceeded = pcall(remoteEvent.FireServer, remoteEvent, "SellBubble")
	if rootPart and sellStationCFrame and originalCFrame then
		rootPart.CFrame = originalCFrame
	end
	if sellSucceeded then
		activeStates.BGSI_Lite_LastBubbleSellAttemptAt = attemptTime
		activeStates.BGSI_Lite_BubbleSellPendingAt = attemptTime
		activeStates.BGSI_Lite_LastBubbleSellAt = attemptTime
	end
	return sellSucceeded
end
activeStates.BGSI_Lite_GetBubbleState = function()
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" or type(playerData.Bubble) ~= "table" then
		return nil
	end
	if type(activeStates.BGSI_Lite_BubbleStatsUtil) ~= "table" then
		pcall(function()
			activeStates.BGSI_Lite_BubbleStatsUtil =
				require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
		end)
	end
	local bubblePower = 0
	local bubbleStorage = math.huge
	if type(activeStates.BGSI_Lite_BubbleStatsUtil) == "table" then
		pcall(function()
			bubblePower = math.max(0, tonumber(activeStates.BGSI_Lite_BubbleStatsUtil:GetBubblePower(playerData)) or 0)
			bubbleStorage =
				math.max(0, tonumber(activeStates.BGSI_Lite_BubbleStatsUtil:GetBubbleStorage(playerData)) or 0)
		end)
	end
	return {
		Amount = math.max(0, tonumber(playerData.Bubble.Amount) or 0),
		Power = bubblePower,
		Storage = bubbleStorage,
		Infinite = type(playerData.Passes) == "table" and playerData.Passes["Infinity Gum"] == true,
	}
end
activeStates.BGSI_Lite_BlowBubble = function()
	local attemptTime = tick()
	local requestInterval = math.clamp(
		tonumber(activeStates.BGSI_Lite_BubbleRequestInterval) or 0.5,
		0.5,
		0.55
	)
	if attemptTime - (tonumber(activeStates.BGSI_Lite_LastBubbleAttemptAt) or 0) < requestInterval then
		return false
	end
	local pendingRequestAt = tonumber(activeStates.BGSI_Lite_BubbleRequestPendingAt) or 0
	if pendingRequestAt > 0 and attemptTime - pendingRequestAt < math.max(0.7, requestInterval + 0.15) then
		return false
	end
	local bubbleState = activeStates.BGSI_Lite_GetBubbleState()
	if not bubbleState then
		return false
	end
	-- Used to defer entirely when a hatch was about to land, to avoid competing with
	-- HatchEgg for the shared RemoteEvent. That's no longer necessary: fireHatchEgg now
	-- fires at most once per real cooldown window instead of flooding it, so there's
	-- nothing left for a BlowBubble/SellBubble call to actually collide with.
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if
		type(playerData) == "table"
		and type(playerData.Settings) == "table"
		and playerData.Settings["Bubble Lock"] == true
		and attemptTime - (tonumber(activeStates.BGSI_Lite_LastBubbleUnlockAt) or 0) >= 2
	then
		activeStates.BGSI_Lite_LastBubbleUnlockAt = attemptTime
		pcall(remoteEvent.FireServer, remoteEvent, "SetSetting", "Bubble Lock", false)
	end
	-- The game only blocks a blow once storage is actually full (HUD.lua: BubbleStorage
	-- <= Bubble.Amount). The Amount + Power comparison it makes first just shows the
	-- "bubble full" popup. Using that as the block meant any account whose Bubble Power
	-- exceeds its storage could never blow at all: at 0 bubbles Sell had nothing to sell
	-- and Blow refused to fire, so bubble quests stalled out.
	if
		not bubbleState.Infinite
		and bubbleState.Storage > 0
		and bubbleState.Amount >= bubbleState.Storage
	then
		activeStates.BGSI_Lite_SellBubble()
		return false
	end
	local blowSucceeded = pcall(remoteEvent.FireServer, remoteEvent, "BlowBubble")
	if blowSucceeded then
		activeStates.BGSI_Lite_LastBubbleAttemptAt = attemptTime
		activeStates.BGSI_Lite_LastBubbleBlowAt = attemptTime
		activeStates.BGSI_Lite_BubbleRequestPendingAt = attemptTime
	end
	return blowSucceeded
end
activeStates.BGSI_Lite_BubbleRequestPendingAt = 0
activeStates.BGSI_Lite_BubbleSellPendingAt = 0
activeStates.BGSI_Lite_BubbleRequestInterval = 0.5
activeStates.BGSI_Lite_LastBubbleAttemptAt = 0
activeStates.BGSI_Lite_LastBubbleObservedAmount = nil
activeStates.BGSI_Lite_ObserveBubbleAmount = function(playerData)
	if not isCurrentRun() or type(playerData) ~= "table" or type(playerData.Bubble) ~= "table" then
		return
	end
	local bubbleAmount = math.max(0, tonumber(playerData.Bubble.Amount) or 0)
	local previousAmount = tonumber(activeStates.BGSI_Lite_LastBubbleObservedAmount)
	activeStates.BGSI_Lite_LastBubbleObservedAmount = bubbleAmount
	if previousAmount == nil then
		return
	end
	if bubbleAmount > previousAmount then
		local acceptedAt = tick()
		local previousAcceptedAt = tonumber(activeStates.BGSI_Lite_LastBubbleAcceptedAt)
		if previousAcceptedAt and previousAcceptedAt > 0 then
			local acceptedInterval = acceptedAt - previousAcceptedAt
			if acceptedInterval >= 0.3 and acceptedInterval <= 2 then
				local smoothedInterval = tonumber(activeStates.BGSI_Lite_AcceptedBubbleInterval) or acceptedInterval
				smoothedInterval = smoothedInterval * 0.7 + acceptedInterval * 0.3
				activeStates.BGSI_Lite_AcceptedBubbleInterval = smoothedInterval
				activeStates.BGSI_Lite_BubbleRequestInterval = math.clamp(smoothedInterval * 0.9, 0.5, 0.55)
			end
		end
		activeStates.BGSI_Lite_LastBubbleAcceptedAt = acceptedAt
		activeStates.BGSI_Lite_BubbleRequestPendingAt = 0
	elseif bubbleAmount < previousAmount then
		activeStates.BGSI_Lite_BubbleRequestPendingAt = 0
		activeStates.BGSI_Lite_BubbleSellPendingAt = 0
		activeStates.BGSI_Lite_LastBubbleSellObservedAt = tick()
	end
end
pcall(function()
	if profileStore:IsReady() then
		activeStates.BGSI_Lite_ObserveBubbleAmount(profileStore:Get())
	end
	profileStore:ConnectDataChanged("Bubble", activeStates.BGSI_Lite_ObserveBubbleAmount)
end)
function runBubbleBountyTask(scriptStateIO, scriptStatePW, scriptStateKN, scriptStateFF)
	if activeStates.BGSI_Lite_BubbleQuestActive == true then return false, "Busy" end
	local switchTeams = Config.bubbleQuestSwitchTeams == true
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	local previousTeam = type(playerData) == "table" and playerData.TeamEquipped or nil
	local character = LocalPlayer.Character
	local rootPart = character and character:FindFirstChild("HumanoidRootPart")
	local previousCFrame = rootPart and rootPart.CFrame
	local lastSellTime = 0
	local lastStationTravel = 0
	local questProgressWatch
	local activeQuestData
	local failureReason
	local questOwner = {}
	activeStates.BGSI_Lite_BubbleQuestOwner = questOwner
	activeStates.BGSI_Lite_BubbleQuestActive = true
	local ok, errorMessage = pcall(function()
		if switchTeams then
			local equipTeam = activeStates.BGSI_Lite_EquipPetTeamByKey
			if type(equipTeam) == "function" and not equipTeam("Bubbles") then
				pcall(activeStates.BGSI_Lite_ApplyCurrencyTeam, "bubble")
			end
		end
		while isCurrentRun() and scriptStateFF() and Config.safeMode ~= true do
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			local quest = scriptStateIO()
			if not quest then break end
			activeQuestData = quest
			local taskData = quest.Tasks and quest.Tasks[scriptStatePW]
			local requirement = taskData and getBountyTaskRequirement(taskData) or scriptStateKN
			local progress = getBountyTaskProgress(quest, scriptStatePW)
			questProgressWatch, failureReason = activeStates.BGSI_Lite_RecordQuestProgress(
				questProgressWatch, quest, scriptStatePW, progress)
			if failureReason then
				failureReason = "NoProgress"
				break
			end
			if type(requirement) == "number" and progress >= requirement then break end
			local station = activeStates.BGSI_Lite_FindSellBubbleStation()
			local stationCFrame = station and activeStates.BGSI_Lite_GetInstanceTargetCFrame(station, "Root")
			if not stationCFrame then stationCFrame = CFrame.new(77.556, 6.216, -113.065) end
			local currentRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
			if stationCFrame and currentRoot and tick() - lastStationTravel >= 2
				and (currentRoot.Position - stationCFrame.Position).Magnitude > 12 then
				teleportToCFrame(stationCFrame * CFrame.new(0, 3, 0))
				lastStationTravel = tick()
			end
			local bubbleState = activeStates.BGSI_Lite_GetBubbleState()
			if bubbleState and bubbleState.Amount > 0
				and (bubbleState.Amount >= bubbleState.Storage or tick() - lastSellTime >= 2) then
				activeStates.BGSI_Lite_SellBubble()
				lastSellTime = tick()
			end
			activeStates.BGSI_Lite_BlowBubble()
			task.wait(0.5)
		end
	end)
	if not ok then
		failureReason = "HandlerError"
		warn("[LarpLite] Bubbling quest failed:", tostring(errorMessage))
	end
	if isCurrentRun() then
		pcall(activeStates.BGSI_Lite_SellBubble)
		if switchTeams then
			local equipTeam = activeStates.BGSI_Lite_EquipPetTeamByKey
			if type(equipTeam) == "function" then
				local restoredOk, restored = pcall(equipTeam, "Hatch")
				if (not restoredOk or not restored) and previousTeam ~= nil then pcall(equipTeam, previousTeam) end
			end
		end
		if previousCFrame then pcall(teleportToCFrame, previousCFrame) end
	end
	if activeStates.BGSI_Lite_BubbleQuestOwner == questOwner then
		activeStates.BGSI_Lite_BubbleQuestActive = false
		activeStates.BGSI_Lite_BubbleQuestOwner = nil
	end
	if Config.autoHatch == true then activeStates.BGSI_Lite_ForceAutoHatchTeleport = true end
	activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, scriptStatePW)
	if failureReason then return false, failureReason end
end
activeStates.BGSI_Lite_GetNotificationText = function(notification)
	if type(notification) == "string" then
		return notification
	end
	if type(notification) ~= "table" then
		return ""
	end
	for _, notificationKey in ipairs({ "Text", "Message", "Content", "Title" }) do
		if type(notification[notificationKey]) == "string" and notification[notificationKey] ~= "" then
			return notification[notificationKey]
		end
	end
	return ""
end
do
	local ticketFarmCFrame = CFrame.new(9913.1104, 26.3498, 185.9215)
	local pearlFarmCFrame = CFrame.new(-23666.748048675, 7.887024402618408, -2.196840524673462)
	local ticketCollectPickupRemote

	local pickupFireCooldowns = {}
	local pickupFireLastCleanup = 0
	local function shouldFirePickup(pickupId)
		local pickupKey = tostring(pickupId or "")
		if pickupKey == "" then
			return false
		end
		local now = tick()
		if now - (pickupFireCooldowns[pickupKey] or 0) < 3 then
			return false
		end
		pickupFireCooldowns[pickupKey] = now
		if now - pickupFireLastCleanup > 20 then
			pickupFireLastCleanup = now
			for cachedPickupKey, firedAt in pairs(pickupFireCooldowns) do
				if now - firedAt > 15 then
					pickupFireCooldowns[cachedPickupKey] = nil
				end
			end
		end
		return true
	end

	local function getPetTeamState()
		local scriptStateTeamData
		pcall(function()
			if profileStore:IsReady() then
				scriptStateTeamData = profileStore:Get()
			end
		end)
		return type(scriptStateTeamData) == "table" and scriptStateTeamData or nil
	end
	activeStates.BGSI_Lite_GetPetTeamState = getPetTeamState

	local function resolvePetTeamKey(scriptStateSelectedTeam)
		if scriptStateSelectedTeam == nil or tostring(scriptStateSelectedTeam) == "" then
			return nil
		end
		local scriptStateTeamData = getPetTeamState()
		local scriptStateTeams = scriptStateTeamData and scriptStateTeamData.Teams
		if type(scriptStateTeams) ~= "table" then
			return nil
		end
		for scriptStateTeamKey, scriptStateTeam in pairs(scriptStateTeams) do
			local scriptStateTeamName = type(scriptStateTeam) == "table"
					and (scriptStateTeam.Name or scriptStateTeam.TeamName)
				or nil
			if
				tostring(scriptStateTeamKey) == tostring(scriptStateSelectedTeam)
				or (scriptStateTeamName and tostring(scriptStateTeamName) == tostring(scriptStateSelectedTeam))
			then
				return scriptStateTeamKey
			end
		end
		return nil
	end

	local function equipPetTeam(scriptStateTargetTeam)
		if isAutomationBlocked() then
			return false
		end
		local scriptStateResolvedTeam = resolvePetTeamKey(scriptStateTargetTeam)
		if scriptStateResolvedTeam == nil then
			return false
		end
		local scriptStateTeamData = getPetTeamState()
		if scriptStateTeamData and tostring(scriptStateTeamData.TeamEquipped) == tostring(scriptStateResolvedTeam) then
			return true
		end
		local scriptStateTeamPayloads = {
			scriptStateResolvedTeam,
			tonumber(scriptStateResolvedTeam),
			tostring(scriptStateResolvedTeam),
			{ Team = scriptStateResolvedTeam },
			{ TeamIndex = tonumber(scriptStateResolvedTeam) or scriptStateResolvedTeam },
			{ Index = tonumber(scriptStateResolvedTeam) or scriptStateResolvedTeam },
		}
		for _, scriptStateTeamAction in ipairs({
			"EquipTeam",
			"EquipPetTeam",
			"SetTeam",
			"SelectTeam",
			"SetEquippedTeam",
			"SetTeamEquipped",
			"ChangeTeam",
			"SwitchTeam",
		}) do
			for _, scriptStateTeamPayload in ipairs(scriptStateTeamPayloads) do
				if scriptStateTeamPayload ~= nil then
					pcall(function()
						remoteEvent:FireServer(scriptStateTeamAction, scriptStateTeamPayload)
					end)
					pcall(function()
						remoteFunction:InvokeServer(scriptStateTeamAction, scriptStateTeamPayload)
					end)
					pcall(function()
						if not carnivalRemoteModule then
							carnivalRemoteModule = require(ReplicatedStorage.Shared.Framework.Network.Remote)
						end
						if carnivalRemoteModule and type(carnivalRemoteModule.FireServer) == "function" then
							carnivalRemoteModule:FireServer(scriptStateTeamAction, scriptStateTeamPayload)
						end
					end)
					local scriptStateDeadline = tick() + 0.35
					repeat
						task.wait(0.05)
						scriptStateTeamData = getPetTeamState()
						if
							scriptStateTeamData
							and tostring(scriptStateTeamData.TeamEquipped) == tostring(scriptStateResolvedTeam)
						then
							return true
						end
					until tick() >= scriptStateDeadline
				end
			end
		end
		return false
	end
	activeStates.BGSI_Lite_EquipPetTeamByKey = equipPetTeam

	local function equipReturnPetTeam(scriptStateReturnTeam, scriptStatePreviousTeam)
		if type(scriptStateReturnTeam) == "string" and scriptStateReturnTeam ~= "" then
			return equipPetTeam(scriptStateReturnTeam)
		end
		if scriptStatePreviousTeam ~= nil then
			return equipPetTeam(scriptStatePreviousTeam)
		end
		return false
	end

	-- Coins/tickets/pearls/gems all spawn as Model instances parented directly under
	-- workspace.Rendered.Pickups (confirmed straight from the game's own pickup-spawning
	-- code: `Rendered = workspace.Rendered.Pickups`, then every spawned pickup gets
	-- `v6.Parent = Rendered` with `v6.Name = <its collect id>`). Scanning that folder
	-- directly is a stable, cheap, always-correct list of exactly what's currently
	-- collectible - unlike scanning getgc(true) for any live table with an
	-- "_activePickups" field, which is slow (walks every live table in the whole game),
	-- rate-limited to keep that cost down, and not even reliably the right table (the
	-- tutorial UI keeps its own unrelated table under that same field name, so a GC scan
	-- can match the wrong one). This also confirms the official client's own remote
	-- signature: CollectPickup:FireServer(pickupInstance.Name).
	local function getPickupsFolder()
		local pickupsFolder
		pcall(function()
			pickupsFolder = workspace.Rendered.Pickups
		end)
		return pickupsFolder
	end

	local function collectEveryActivePickup()
		if tick() - (activeStates.BGSI_Lite_LastPickupScanAt or 0) < 0.1 then
			return
		end
		activeStates.BGSI_Lite_LastPickupScanAt = tick()

		local pickupsFolder = getPickupsFolder()
		if not pickupsFolder then
			return
		end
		if not ticketCollectPickupRemote then
			local scriptStateRemote = ReplicatedStorage:FindFirstChild("CollectPickup", true)
			if scriptStateRemote and scriptStateRemote:IsA("RemoteEvent") then
				ticketCollectPickupRemote = scriptStateRemote
			end
		end

		pcall(function()
			for _, pickupInstance in ipairs(pickupsFolder:GetChildren()) do
				local pickupId = pickupInstance.Name
				if shouldFirePickup(pickupId) then
					pcall(function()
						if ticketCollectPickupRemote then
							ticketCollectPickupRemote:FireServer(pickupId)
						else
							remoteEvent:FireServer("CollectPickup", pickupId)
						end
					end)
				end
			end
		end)
	end

	local function getPickupRemote(remoteName)
		local remotesFolder = ReplicatedStorage:FindFirstChild("Remotes")
		local pickupsRemoteFolder = remotesFolder and remotesFolder:FindFirstChild("Pickups")
		local exactRemote = pickupsRemoteFolder and pickupsRemoteFolder:FindFirstChild(remoteName)
		if exactRemote then
			return exactRemote
		end
		return ReplicatedStorage:FindFirstChild(remoteName, true)
	end

	local function getCollectPickupRemote()
		if not ticketCollectPickupRemote then
			local scriptStateRemote = getPickupRemote("CollectPickup")
			if scriptStateRemote and scriptStateRemote:IsA("RemoteEvent") then
				ticketCollectPickupRemote = scriptStateRemote
			end
		end
		return ticketCollectPickupRemote
	end

	local function fireCollectPickupRemote(pickupId)
		if pickupId == nil or not shouldFirePickup(pickupId) then
			return
		end
		local collectPickupRemote = getCollectPickupRemote()
		pcall(function()
			if collectPickupRemote then
				collectPickupRemote:FireServer(pickupId)
			else
				remoteEvent:FireServer("CollectPickup", pickupId)
			end
		end)
	end

	local function getCharacterRootPart()
		local character = LocalPlayer and LocalPlayer.Character
		return character and character:FindFirstChild("HumanoidRootPart") or nil
	end

	local cachedCarnivalZoneParts, cachedCarnivalZoneAt = nil, 0
	local function getCarnivalPickupFolders()
		local carnivalFolder = Workspace:FindFirstChild("Carnival")
		local pickupsFolder = carnivalFolder and carnivalFolder:FindFirstChild("Pickups")
		local zoneFolder = pickupsFolder and pickupsFolder:FindFirstChild("Zone")
		return carnivalFolder, pickupsFolder, zoneFolder
	end

	local function getRenderedPickupsFolder()
		local renderedFolder = Workspace:FindFirstChild("Rendered")
		return renderedFolder and renderedFolder:FindFirstChild("Pickups") or nil
	end

	local function getRenderedChunkerFolders()
		local renderedFolder = Workspace:FindFirstChild("Rendered")
		local chunkerFolders = {}
		if not renderedFolder then
			return chunkerFolders
		end
		for _, renderedChild in ipairs(renderedFolder:GetChildren()) do
			if renderedChild.Name == "Chunker" then
				table.insert(chunkerFolders, renderedChild)
			end
		end
		return chunkerFolders
	end

	local function getPickupSearchFolders()
		local _, carnivalPickupsFolder = getCarnivalPickupFolders()
		local renderedPickupsFolder = getRenderedPickupsFolder()
		local pickupFolders = {}
		if carnivalPickupsFolder then
			table.insert(pickupFolders, carnivalPickupsFolder)
		end
		if renderedPickupsFolder and renderedPickupsFolder ~= carnivalPickupsFolder then
			table.insert(pickupFolders, renderedPickupsFolder)
		end
		for _, chunkerFolder in ipairs(getRenderedChunkerFolders()) do
			table.insert(pickupFolders, chunkerFolder)
		end
		return pickupFolders
	end

	local function getCarnivalPickupZoneParts()
		if cachedCarnivalZoneParts and tick() - cachedCarnivalZoneAt < 2 then
			return cachedCarnivalZoneParts
		end
		local _, _, zoneFolder = getCarnivalPickupFolders()
		local zoneParts = {}
		if zoneFolder then
			for _, descendant in ipairs(zoneFolder:GetDescendants()) do
				if descendant:IsA("BasePart") then
					table.insert(zoneParts, descendant)
				end
			end
		end
		cachedCarnivalZoneParts, cachedCarnivalZoneAt = zoneParts, tick()
		return zoneParts
	end

	local function isPositionInsidePart(position, part)
		if typeof(position) ~= "Vector3" or not part or not part:IsA("BasePart") then
			return false
		end
		local localPosition = part.CFrame:PointToObjectSpace(position)
		local halfSize = part.Size * 0.5
		return math.abs(localPosition.X) <= halfSize.X
			and math.abs(localPosition.Y) <= halfSize.Y
			and math.abs(localPosition.Z) <= halfSize.Z
	end

	local function isPositionInsideCarnivalPickupZone(position)
		if typeof(position) ~= "Vector3" then
			return false
		end
		for _, zonePart in ipairs(getCarnivalPickupZoneParts()) do
			if isPositionInsidePart(position, zonePart) then
				return true
			end
		end
		return false
	end

	activeStates.BGSI_Lite_IsCharacterInCarnivalPickupZone = function()
		local character = LocalPlayer and LocalPlayer.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")
		return rootPart and isPositionInsideCarnivalPickupZone(rootPart.Position) or false
	end

	local function getInstancePosition(pickupInstance)
		if typeof(pickupInstance) ~= "Instance" then
			return nil
		end
		if pickupInstance:IsA("BasePart") then
			return pickupInstance.Position
		end
		if pickupInstance:IsA("Model") then
			local ok, pivot = pcall(function()
				return pickupInstance:GetPivot()
			end)
			if ok and typeof(pivot) == "CFrame" then
				return pivot.Position
			end
			local primaryPart = pickupInstance.PrimaryPart or pickupInstance:FindFirstChildWhichIsA("BasePart", true)
			return primaryPart and primaryPart.Position or nil
		end
		if pickupInstance:IsA("Attachment") then
			return pickupInstance.WorldPosition
		end
		local childPart = pickupInstance:FindFirstChildWhichIsA("BasePart", true)
		return childPart and childPart.Position or nil
	end

	local function vectorFromNumericTable(positionTable)
		if type(positionTable) ~= "table" then
			return nil
		end
		local x = tonumber(rawget(positionTable, "X") or rawget(positionTable, "x") or rawget(positionTable, 1))
		local y = tonumber(rawget(positionTable, "Y") or rawget(positionTable, "y") or rawget(positionTable, 2))
		local z = tonumber(rawget(positionTable, "Z") or rawget(positionTable, "z") or rawget(positionTable, 3))
		if x and y and z then
			return Vector3.new(x, y, z)
		end
		return nil
	end

	local function getPickupPosition(pickup, seen, depth)
		depth = depth or 0
		if pickup == nil or depth > 5 then
			return nil
		end
		if typeof(pickup) == "Vector3" then
			return pickup
		end
		if typeof(pickup) == "CFrame" then
			return pickup.Position
		end
		if typeof(pickup) == "Instance" then
			return getInstancePosition(pickup)
		end
		if type(pickup) ~= "table" then
			return nil
		end
		seen = seen or {}
		if seen[pickup] then
			return nil
		end
		seen[pickup] = true

		local numericVector = vectorFromNumericTable(pickup)
		if numericVector then
			return numericVector
		end

		for _, key in ipairs({
			"Position",
			"position",
			"Pos",
			"pos",
			"Location",
			"location",
			"WorldPosition",
			"worldPosition",
			"SpawnPosition",
			"spawnPosition",
		}) do
			local position = rawget(pickup, key)
			local resolvedPosition = getPickupPosition(position, seen, depth + 1)
			if resolvedPosition then
				return resolvedPosition
			end
		end

		for _, key in ipairs({
			"CFrame",
			"cframe",
			"CF",
			"cf",
			"Pivot",
			"pivot",
		}) do
			local cframe = rawget(pickup, key)
			local resolvedPosition = getPickupPosition(cframe, seen, depth + 1)
			if resolvedPosition then
				return resolvedPosition
			end
		end

		for _, key in ipairs({
			"Instance",
			"instance",
			"Model",
			"model",
			"Object",
			"object",
			"Part",
			"part",
			"Root",
			"root",
			"RootPart",
			"rootPart",
			"PrimaryPart",
			"primaryPart",
			"BasePart",
			"basePart",
			"Hitbox",
			"hitbox",
			"Pickup",
			"pickup",
			"Visual",
			"visual",
			"Display",
			"display",
			"Data",
			"data",
			"Info",
			"info",
		}) do
			local nestedPosition = getPickupPosition(rawget(pickup, key), seen, depth + 1)
			if nestedPosition then
				return nestedPosition
			end
		end
		return nil
	end

	local function isPickupInCarnivalZone(pickup)
		return isPositionInsideCarnivalPickupZone(getPickupPosition(pickup))
	end

	local function getPickupIdsFromInstance(pickupInstance)
		local pickupIds, seenIds = {}, {}
		local function addPickupId(pickupId)
			if pickupId == nil then
				return
			end
			local idText = tostring(pickupId)
			if idText ~= "" and not seenIds[idText] then
				seenIds[idText] = true
				table.insert(pickupIds, pickupId)
			end
		end
		for _, attributeName in ipairs({
			"Id",
			"ID",
			"Guid",
			"GUID",
			"PickupId",
			"PickupID",
			"PickupGuid",
			"PickupGUID",
		}) do
			addPickupId(pickupInstance:GetAttribute(attributeName))
		end
		addPickupId(pickupInstance.Name)
		return pickupIds
	end

	local function looksLikePickupId(pickupId)
		if type(pickupId) ~= "string" then
			return false
		end
		return string.match(pickupId, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$")
				~= nil
			or string.match(pickupId, "^%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x%x$") ~= nil
	end

	local function findPickupInstanceById(pickupId)
		if pickupId == nil then
			return nil
		end
		local _, _, zoneFolder = getCarnivalPickupFolders()
		local pickupIdText = tostring(pickupId)
		for _, pickupsFolder in ipairs(getPickupSearchFolders()) do
			for _, descendant in ipairs(pickupsFolder:GetDescendants()) do
				if descendant ~= zoneFolder and not (zoneFolder and descendant:IsDescendantOf(zoneFolder)) then
					if descendant.Name == pickupIdText then
						return descendant
					end
					for _, attributeName in ipairs({
						"Id",
						"ID",
						"Guid",
						"GUID",
						"PickupId",
						"PickupID",
						"PickupGuid",
						"PickupGUID",
					}) do
						if tostring(descendant:GetAttribute(attributeName)) == pickupIdText then
							return descendant
						end
					end
				end
			end
		end
		return nil
	end

	local function collectVisibleRenderedPickups(maxPickups, carnivalOnly)
		local pickupsFolder = getRenderedPickupsFolder()
		local rootPart = getCharacterRootPart()
		if not pickupsFolder or not rootPart then
			return 0
		end

		local originalCFrame = rootPart.CFrame
		local collectedCount = 0
		maxPickups = math.max(1, math.floor(tonumber(maxPickups) or 10))
		local carnivalZoneParts = carnivalOnly and getCarnivalPickupZoneParts() or nil

		for _, pickupInstance in ipairs(pickupsFolder:GetChildren()) do
			if collectedCount >= maxPickups then
				break
			end

			local pickupId = pickupInstance.Name
			local pickupPosition = getPickupPosition(pickupInstance)
			if
				type(pickupId) == "string"
				and pickupId ~= ""
				and pickupPosition
				and (not carnivalOnly or #carnivalZoneParts == 0 or isPositionInsideCarnivalPickupZone(pickupPosition))
				and shouldFirePickup(pickupId)
			then
				pcall(function()
					rootPart.CFrame = CFrame.new(pickupPosition + Vector3.new(0, 3, 0))
				end)
				task.wait()
				local collectPickupRemote = getCollectPickupRemote()
				pcall(function()
					if collectPickupRemote then
						collectPickupRemote:FireServer(pickupId)
					else
						remoteEvent:FireServer("CollectPickup", pickupId)
					end
				end)
				pcall(function()
					pickupInstance:Destroy()
				end)
				collectedCount = collectedCount + 1
				task.wait(0.03)
			end
		end

		if collectedCount > 0 and rootPart.Parent then
			pcall(function()
				rootPart.CFrame = originalCFrame
			end)
		end
		return collectedCount
	end


	activeStates.BGSI_Lite_CollectCarnivalZonePickups = nil
	activeStates.BGSI_Lite_CollectVisibleRenderedPickups = collectVisibleRenderedPickups

	local ticketPickupTaskRunning = false
	local pearlPickupTaskRunning = false

	local function teleportToWorldPortal(worldName)
		if isAutomationBlocked() or type(worldName) ~= "string" or worldName == "" then
			return
		end
		pcall(function()
			remoteEvent:FireServer("Teleport", "Workspace.Worlds." .. worldName .. ".PortalSpawn")
		end)
	end

	local function getRenderedGiftFolders()
		local giftFolders, seenGiftFolders = {}, {}
		local function addGiftFolder(giftFolder)
			if typeof(giftFolder) == "Instance" and not seenGiftFolders[giftFolder] then
				seenGiftFolders[giftFolder] = true
				table.insert(giftFolders, giftFolder)
			end
		end
		local renderedFolder = Workspace:FindFirstChild("Rendered")
		addGiftFolder(renderedFolder and renderedFolder:FindFirstChild("Gifts"))
		addGiftFolder(Workspace:FindFirstChild("Gifts"))
		return giftFolders
	end

	local function getGiftClaimIds(giftInstance)
		local giftIds, seenGiftIds = {}, {}
		local function addGiftId(giftId)
			if giftId == nil then
				return
			end
			local giftIdText = tostring(giftId)
			if giftIdText ~= "" and not seenGiftIds[giftIdText] then
				seenGiftIds[giftIdText] = true
				table.insert(giftIds, giftId)
			end
		end
		if typeof(giftInstance) ~= "Instance" then
			return giftIds
		end
		addGiftId(giftInstance.Name)
		for _, attributeName in ipairs({
			"Id",
			"ID",
			"Guid",
			"GUID",
			"GiftId",
			"GiftID",
			"PickupId",
			"PickupID",
		}) do
			addGiftId(giftInstance:GetAttribute(attributeName))
		end
		for _, childName in ipairs({
			"Id",
			"ID",
			"Guid",
			"GUID",
			"GiftId",
			"GiftID",
		}) do
			local childValue = giftInstance:FindFirstChild(childName)
			if childValue and childValue:IsA("ValueBase") then
				addGiftId(childValue.Value)
			end
		end
		return giftIds
	end

	local function fireGiftClaimRemote(giftId)
		if giftId == nil or tostring(giftId) == "" then
			return
		end
		for _, claimAction in ipairs({
			"ClaimGift",
			"OpenGift",
			"CollectGift",
			"PickupGift",
		}) do
			pcall(function()
				remoteEvent:FireServer(claimAction, giftId)
			end)
			pcall(function()
				remoteEvent:FireServer(claimAction, giftId, true)
			end)
			pcall(function()
				remoteEvent:FireServer(claimAction, giftId, false)
			end)
		end
	end

	local function claimAllRenderedGifts()
		local giftFolders = getRenderedGiftFolders()
		if #giftFolders == 0 then
			return 0
		end
		local claimedGifts = 0
		for _, giftFolder in ipairs(giftFolders) do
			for _, giftInstance in ipairs(giftFolder:GetChildren()) do
				for _, giftId in ipairs(getGiftClaimIds(giftInstance)) do
					fireGiftClaimRemote(giftId)
				end
				claimedGifts = claimedGifts + 1
			end
		end
		return claimedGifts
	end

	local function claimRenderedGiftsForDuration(durationSeconds)
		local claimedGifts = 0
		local claimUntil = tick() + math.max(0.1, tonumber(durationSeconds) or 1)
		repeat
			claimedGifts = claimedGifts + claimAllRenderedGifts()
			task.wait(0.1)
		until tick() >= claimUntil
		return claimedGifts
	end

	local function useMysteryBoxesForPearls()
		local selectedBox = type(Config.selectedMysteryBox) == "string"
				and Config.selectedMysteryBox ~= ""
				and Config.selectedMysteryBox
			or "Mystery Box"
		pcall(function()
			remoteEvent:FireServer("UseGift", selectedBox, 50)
		end)
		return claimRenderedGiftsForDuration(1.5)
	end

	local function runTicketPickupTask(
		scriptStateGetQuest,
		scriptStateTaskIndex,
		scriptStateRequirement,
		scriptStateShouldContinue
	)
		while ticketPickupTaskRunning and scriptStateShouldContinue() do
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			task.wait(0.2)
		end
		if not scriptStateShouldContinue() then
			return
		end
		-- Re-check right here too, not just inside the work loop below: this call can sit
		-- waiting above for a different in-progress ticket run to finish, and by the time
		-- it wakes up Skip may have been turned on in the meantime. Without this, it would
		-- still barrel through the portal teleport, team equip, and farm-spot teleport
		-- below before the in-loop check ever got a chance to stop it.
		do
			local scriptStateEntryQuest = scriptStateGetQuest()
			local scriptStateEntryTask = type(scriptStateEntryQuest) == "table"
				and scriptStateEntryQuest.Tasks
				and scriptStateEntryQuest.Tasks[scriptStateTaskIndex]
			if
				type(scriptStateEntryTask) == "table"
				and activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateEntryTask)
			then
				return
			end
		end
		ticketPickupTaskRunning = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		local scriptStateTeamData = getPetTeamState()
		local scriptStatePreviousTeam = scriptStateTeamData and scriptStateTeamData.TeamEquipped or nil
		activeStates.BGSI_Lite_TicketPickupActive = true
		pcall(installPickupRangeHook)
		teleportToWorldPortal("Minigame Paradise")
		task.wait(0.35)
		pcall(activeStates.BGSI_Lite_ApplyCurrencyTeam, "tickets")
		if
			Config.autoCurrencyTeams ~= true
			and type(Config.selectedTicketTeam) == "string"
			and Config.selectedTicketTeam ~= ""
		then
			local scriptStateTeamEquipDeadline = tick() + 6
			repeat
				if equipPetTeam(Config.selectedTicketTeam) then
					break
				end
				task.wait(0.35)
			until tick() >= scriptStateTeamEquipDeadline
		end
		teleportToCFrame(ticketFarmCFrame)
		local scriptStateLastTeleport = 0
		local questProgressWatch
		local activeQuestData
		pcall(function()
			while scriptStateShouldContinue() do
				activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
				local scriptStateQuest = scriptStateGetQuest()
				if not scriptStateQuest then
					break
				end
				activeQuestData = scriptStateQuest
				local scriptStateTask = scriptStateQuest.Tasks and scriptStateQuest.Tasks[scriptStateTaskIndex]
				-- Ticket/pearl pickup used to keep running for as long as the outer
				-- shouldContinue() said so, which has nothing to do with Skip Ticket and
				-- Pearl Quests - it just means "the enclosing feature is still on". Once this
				-- loop was dispatched into, flipping Skip on mid-task did nothing until the
				-- whole task finished on its own. Re-checking every iteration lets Skip
				-- actually interrupt a pickup run that's already in progress.
				if
					type(scriptStateTask) == "table"
					and activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateTask)
				then
					break
				end
				local scriptStateNeeded = scriptStateTask and getBountyTaskRequirement(scriptStateTask)
					or scriptStateRequirement
				local scriptStateProgress = getBountyTaskProgress(scriptStateQuest, scriptStateTaskIndex)
				local scriptStateStalled
				questProgressWatch, scriptStateStalled = activeStates.BGSI_Lite_RecordQuestProgress(
					questProgressWatch,
					scriptStateQuest,
					scriptStateTaskIndex,
					scriptStateProgress
				)
				if scriptStateStalled then
					break
				end
				if
					scriptStateProgress >= scriptStateNeeded
					or scriptStateQuest.Completed == true
					or (type(scriptStateTask) == "table" and scriptStateTask.Completed == true)
				then
					break
				end
				if tick() - scriptStateLastTeleport >= 2 then
					teleportToCFrame(ticketFarmCFrame)
					scriptStateLastTeleport = tick()
				end
				collectEveryActivePickup()
				task.wait(0.1)
			end
		end)
		activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, scriptStateTaskIndex)
		activeStates.BGSI_Lite_TicketPickupActive = false
		equipReturnPetTeam(Config.selectedTicketReturnTeam, scriptStatePreviousTeam)
		ticketPickupTaskRunning = false
	end
	activeStates.BGSI_Lite_RunTicketPickupTask = runTicketPickupTask

	local function runPearlMysteryBoxTask(
		scriptStateGetQuest,
		scriptStateTaskIndex,
		scriptStateRequirement,
		scriptStateShouldContinue
	)
		while pearlPickupTaskRunning and scriptStateShouldContinue() do
			activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
			task.wait(0.2)
		end
		if not scriptStateShouldContinue() then
			return
		end
		-- Same entry re-check as the ticket pickup task: Skip could have been turned on
		-- while this call was waiting above for a different in-progress pearl run to
		-- finish, and without this it would still teleport and equip a team below before
		-- the in-loop check got a chance to stop it.
		do
			local scriptStateEntryQuest = scriptStateGetQuest()
			local scriptStateEntryTask = type(scriptStateEntryQuest) == "table"
				and scriptStateEntryQuest.Tasks
				and scriptStateEntryQuest.Tasks[scriptStateTaskIndex]
			if
				type(scriptStateEntryTask) == "table"
				and activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateEntryTask)
			then
				return
			end
		end
		pearlPickupTaskRunning = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		local scriptStateTeamData = getPetTeamState()
		local scriptStatePreviousTeam = scriptStateTeamData and scriptStateTeamData.TeamEquipped or nil
		teleportToWorldPortal("Seven Seas")
		task.wait(0.35)
		pcall(activeStates.BGSI_Lite_ApplyCurrencyTeam, "pearls")
		if
			Config.autoCurrencyTeams ~= true
			and type(Config.selectedPearlTeam) == "string"
			and Config.selectedPearlTeam ~= ""
		then
			local scriptStateTeamEquipDeadline = tick() + 6
			repeat
				if equipPetTeam(Config.selectedPearlTeam) then
					break
				end
				task.wait(0.35)
			until tick() >= scriptStateTeamEquipDeadline
		end
		teleportToCFrame(pearlFarmCFrame)
		local questProgressWatch
		local activeQuestData
		pcall(function()
			while scriptStateShouldContinue() do
				activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
				local scriptStateQuest = scriptStateGetQuest()
				if not scriptStateQuest then
					break
				end
				activeQuestData = scriptStateQuest
				local scriptStateTask = scriptStateQuest.Tasks and scriptStateQuest.Tasks[scriptStateTaskIndex]
				-- Same live re-check as the ticket pickup loop above: relying only on
				-- shouldContinue() meant flipping Skip on mid-task never interrupted a pearl
				-- run already in progress.
				if
					type(scriptStateTask) == "table"
					and activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateTask)
				then
					break
				end
				local scriptStateNeeded = scriptStateTask and getBountyTaskRequirement(scriptStateTask)
					or scriptStateRequirement
				local scriptStateProgress = getBountyTaskProgress(scriptStateQuest, scriptStateTaskIndex)
				local scriptStateStalled
				questProgressWatch, scriptStateStalled = activeStates.BGSI_Lite_RecordQuestProgress(
					questProgressWatch,
					scriptStateQuest,
					scriptStateTaskIndex,
					scriptStateProgress
				)
				if scriptStateStalled then
					break
				end
				if
					scriptStateProgress >= scriptStateNeeded
					or scriptStateQuest.Completed == true
					or (type(scriptStateTask) == "table" and scriptStateTask.Completed == true)
				then
					break
				end
				teleportToCFrame(pearlFarmCFrame)
				useMysteryBoxesForPearls()
				local scriptStateUpdatedQuest = scriptStateGetQuest()
				local scriptStateUpdatedTask = scriptStateUpdatedQuest
					and scriptStateUpdatedQuest.Tasks
					and scriptStateUpdatedQuest.Tasks[scriptStateTaskIndex]
				local scriptStateUpdatedNeeded = scriptStateUpdatedTask
						and getBountyTaskRequirement(scriptStateUpdatedTask)
					or scriptStateNeeded
				if
					not scriptStateUpdatedQuest
					or getBountyTaskProgress(scriptStateUpdatedQuest, scriptStateTaskIndex) >= scriptStateUpdatedNeeded
					or scriptStateUpdatedQuest.Completed == true
					or (type(scriptStateUpdatedTask) == "table" and scriptStateUpdatedTask.Completed == true)
				then
					break
				end
				task.wait(math.clamp(tonumber(Config.autoOpenMysteryDelay) or 0.2, 0.1, 2))
			end
		end)
		activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, scriptStateTaskIndex)
		equipReturnPetTeam(Config.selectedPearlReturnTeam, scriptStatePreviousTeam)
		pearlPickupTaskRunning = false
	end
	activeStates.BGSI_Lite_RunPearlMysteryBoxTask = runPearlMysteryBoxTask
end
function runCollectCurrencyBountyTask(scriptStateSM, scriptStateOX, scriptStateMZ, scriptStateSS, scriptStateF)
	if type(scriptStateF) == "string" and string.find(string.lower(scriptStateF), "ticket", 1, true) then
		activeStates.BGSI_Lite_RunTicketPickupTask(scriptStateSM, scriptStateOX, scriptStateMZ, scriptStateSS)
		return
	end
	if type(scriptStateF) == "string" and string.find(string.lower(scriptStateF), "pearl", 1, true) then
		activeStates.BGSI_Lite_RunPearlMysteryBoxTask(scriptStateSM, scriptStateOX, scriptStateMZ, scriptStateSS)
		return
	end
	teleportToCurrencyArea(scriptStateF)
	task.wait(0.2)
	pcall(activeStates.BGSI_Lite_ApplyCurrencyTeam, scriptStateF)
	local shopItemLoopCount = 0
	local scriptStateSK = tick()
	local questProgressWatch
	local activeQuestData
	while scriptStateSS() do
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		local scriptStateBL = scriptStateSM()
		if not scriptStateBL then
			break
		end
		activeQuestData = scriptStateBL
		local scriptStateYF = scriptStateBL.Tasks and scriptStateBL.Tasks[scriptStateOX]
		local scriptStateAP = scriptStateMZ
		if scriptStateYF then
			scriptStateAP = getBountyTaskRequirement(scriptStateYF)
		end
		local scriptStateUX = getBountyTaskProgress(scriptStateBL, scriptStateOX)
		local scriptStateStalled
		questProgressWatch, scriptStateStalled = activeStates.BGSI_Lite_RecordQuestProgress(
			questProgressWatch,
			scriptStateBL,
			scriptStateOX,
			scriptStateUX
		)
		if scriptStateStalled then
			activeStates.BGSI_Lite_ClearActiveQuest(scriptStateBL, scriptStateOX)
			return false, "NoProgress"
		end
		if type(scriptStateAP) == "number" and scriptStateUX >= scriptStateAP then
			break
		end
		local scriptStateFP = math.max(0, (scriptStateAP or 0) - scriptStateUX)
		if tick() - scriptStateSK >= 8 then
			teleportToCurrencyArea(scriptStateF)
			scriptStateSK = tick()
		end
		if scriptStateF == "gems" then
			local scriptStatePR = getCurrentGems()
			if scriptStatePR > math.max(100000, scriptStateFP) then
				spendGemsDownToReserve(scriptStateFP, 30)
				teleportToCurrencyArea(scriptStateF)
			end
		else
			if getCurrentCoins() >= gemReserveThreshold then
				hatchEggForDuration("Rainbow Egg", 4)
				teleportToCurrencyArea(scriptStateF)
			end
		end
		pcall(function()
			remoteEvent:FireServer("UseGoldenOrb")
		end)
		if tick() - shopItemLoopCount >= 0.4 then
			pcall(function()
				remoteEvent:FireServer("ClaimChest", "Giant Chest", true)
				remoteEvent:FireServer("ClaimChest", "Giant Chest")
			end)
			shopItemLoopCount = tick()
		end
		task.wait(1.2)
	end
	activeStates.BGSI_Lite_ClearActiveQuest(activeQuestData, scriptStateOX)
end
activeStates.BGSI_Lite_RunQuestTask = function(getQuest, taskIndex, fallbackRequirement, shouldContinue)
	if type(getQuest) ~= "function" or type(shouldContinue) ~= "function" or not shouldContinue() then
		return false, "Stopped"
	end
	local questData = getQuest()
	local questTask = type(questData) == "table" and type(questData.Tasks) == "table"
		and questData.Tasks[taskIndex]
	if type(questTask) ~= "table" then
		return false, "MissingTask"
	end
	local requirement = tonumber(getBountyTaskRequirement(questTask)) or tonumber(fallbackRequirement) or 1
	local progress = getBountyTaskProgress(questData, taskIndex)
	if questData.Completed == true or questTask.Completed == true or progress >= requirement then
		activeStates.BGSI_Lite_ClearActiveQuest(questData, taskIndex)
		return false, "Completed"
	end
	if activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(questTask) then
		return false, "Skipped"
	end
	if activeStates.BGSI_Lite_ShouldSkipBubblingQuest(questTask) then
		return false, "Skipped"
	end
	if activeStates.BGSI_Lite_IsQuestTaskDeferred(questData, taskIndex) then
		return false, "Deferred"
	end

	local handler
	local currencyName
	if isCoinOrCollectBountyTask(questTask) then
		handler = runCollectCurrencyBountyTask
		currencyName = getBountyCurrencyName(questTask)
	elseif isHatchBountyTask(questTask) then
		handler = runHatchBountyTask
	elseif isBubbleBountyTask(questTask) then
		handler = runBubbleBountyTask
	end
	if not handler then
		local taskKey = activeStates.BGSI_Lite_GetQuestTaskKey(questData, taskIndex)
		if type(activeStates.BGSI_Lite_StalledQuestTasks[taskKey]) ~= "table" then
			warn("[1rzHub Lite] Unsupported quest task deferred:", taskKey)
		end
		activeStates.BGSI_Lite_StalledQuestTasks[taskKey] = {
			Progress = progress,
			RetryAt = tick() + 300,
		}
		return false, "Unsupported"
	end

	local ok, result, reason
	if handler == runCollectCurrencyBountyTask then
		ok, result, reason = pcall(handler, getQuest, taskIndex, requirement, shouldContinue, currencyName)
	else
		ok, result, reason = pcall(handler, getQuest, taskIndex, requirement, shouldContinue)
	end
	if not ok then
		activeStates.BGSI_Lite_ClearActiveQuest(questData, taskIndex)
		warn("[1rzHub Lite] Quest task handler failed:", tostring(result))
		return false, "HandlerError"
	end
	return result, reason
end
activeStates.BGSI_Lite_GemGenieActive = false
activeStates.BGSI_Lite_SeasonActive = false
activeStates.BGSI_Lite_GlobalIncentiveActive = false
activeStates.BGSI_Lite_ChallengePassActive = false
activeStates.BGSI_Lite_ObbyActive = false
activeStates.BGSI_Lite_ObbyChestActive = false
activeStates.BGSI_Lite_ObbyCycleIndex = math.clamp(tonumber(activeStates.BGSI_Lite_ObbyCycleIndex) or 1, 1, 3)
activeStates.BGSI_Lite_ObbyCompletedAt = tonumber(activeStates.BGSI_Lite_ObbyCompletedAt) or 0
activeStates.BGSI_Lite_RiftEggActive = false
activeStates.BGSI_Lite_TicketPickupActive = false
activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
activeStates.BGSI_Lite_NormalAutomationPaused = false
activeStates.BGSI_Lite_TrickOrTreatActive = false
activeStates.BGSI_Lite_BubbleQuestActive = false
activeStates.BGSI_Lite_BubbleQuestOwner = nil
function isPriorityAutomationActive()
	return activeStates.BGSI_Lite_GemGenieActive
		or activeStates.BGSI_Lite_BubbleQuestActive
		or activeStates.BGSI_Lite_SeasonActive
		or activeStates.BGSI_Lite_GlobalIncentiveActive
		or activeStates.BGSI_Lite_ChallengePassActive
		or activeStates.BGSI_Lite_ObbyActive
		or activeStates.BGSI_Lite_ObbyChestActive
		or activeStates.BGSI_Lite_GuildQuestActive
		or activeStates.BGSI_Lite_TrickOrTreatActive
end
activeStates.BGSI_Lite_IsEggAutomationActive = function()
	return Config.autoHatch == true
		or Config.autoBounty == true
		or Config.spawnRift == true
		or Config.autoLuckEgg == true
		or Config.autoRiftEgg == true
		or Config.autoSpecialRift == true
		or Config.autoHatchInventoryEgg == true
		or isPriorityAutomationActive()
end
activeStates.BGSI_Lite_ShouldMaintainHatching = function()
	return Config.autoHatch == true and activeStates.BGSI_Lite_TrickOrTreatActive ~= true
		and Config.spawnRift ~= true
		and activeStates.BGSI_Lite_NormalAutomationPaused ~= true
		and activeStates.BGSI_Lite_BubbleQuestActive ~= true
end
function clearDisabledPriorityStates()
	if activeStates.BGSI_Lite_GemGenieActive and Config.autoGemGenie ~= true then
		activeStates.BGSI_Lite_GemGenieActive = false
	end
	if activeStates.BGSI_Lite_SeasonActive and Config.autoDailyHourlyChallenge ~= true then
		activeStates.BGSI_Lite_SeasonActive = false
	end
	if activeStates.BGSI_Lite_GlobalIncentiveActive and Config.autoGlobalIncentive ~= true then
		activeStates.BGSI_Lite_GlobalIncentiveActive = false
	end
	if activeStates.BGSI_Lite_ChallengePassActive and Config.autoChallengePassQuests ~= true then
		activeStates.BGSI_Lite_ChallengePassActive = false
	end
	if activeStates.BGSI_Lite_ObbyActive and Config.autoObby ~= true then
		activeStates.BGSI_Lite_ObbyActive = false
	end
	if
		activeStates.BGSI_Lite_ObbyChestActive
		and (
			type(activeStates.BGSI_Lite_ShouldOpenObbyChest) ~= "function"
			or not activeStates.BGSI_Lite_ShouldOpenObbyChest()
		)
	then
		activeStates.BGSI_Lite_ObbyChestActive = false
	end
	if activeStates.BGSI_Lite_RiftEggActive and Config.autoRiftEgg ~= true then
		activeStates.BGSI_Lite_RiftEggActive = false
	end
	if activeStates.BGSI_Lite_BountyRiftActive and Config.spawnRift ~= true then
		activeStates.BGSI_Lite_BountyRiftActive = false
	end
	if activeStates.BGSI_Lite_SpecialRiftActive and Config.autoSpecialRift ~= true then
		activeStates.BGSI_Lite_SpecialRiftActive = false
	end
	if activeStates.BGSI_Lite_GuildQuestActive and Config.autoGuildQuests ~= true then
		activeStates.BGSI_Lite_GuildQuestActive = false
	end
	if activeStates.BGSI_Lite_TrickOrTreatActive
		and (Config.autoTrickOrTreat ~= true
			or tick() - (tonumber(activeStates.BGSI_Lite_TrickOrTreatStartedAt) or 0) > 20) then
		activeStates.BGSI_Lite_TrickOrTreatActive = false
	end
	if not isPriorityAutomationActive() then
		activeStates.BGSI_Lite_ClearActiveQuest()
	end
end
pauseInProgress = false
function pauseNormalAutomation()
	if pauseInProgress then
		return
	end
	pauseInProgress = true
	activeStates.BGSI_Lite_NormalAutomationPaused = true
end
function resumeNormalAutomation()
	if not pauseInProgress then
		activeStates.BGSI_Lite_NormalAutomationPaused = false
		return
	end
	pauseInProgress = false
	if Config.autoHatch then
		activeStates.BGSI_Lite_ForceAutoHatchTeleport = true
	end
	activeStates.BGSI_Lite_NormalAutomationPaused = false
end
task.spawn(function()
	while isCurrentRun() do
		task.wait(1)
		clearDisabledPriorityStates()
		local lastQuestWork = tonumber(activeStates.BGSI_Lite_LastQuestAutomationAt) or 0
		local priorityStale = isPriorityAutomationActive() and tick() - lastQuestWork > 15
		if priorityStale then
			activeStates.BGSI_Lite_GemGenieActive = false
			activeStates.BGSI_Lite_SeasonActive = false
			activeStates.BGSI_Lite_GlobalIncentiveActive = false
			activeStates.BGSI_Lite_ChallengePassActive = false
			activeStates.BGSI_Lite_ObbyActive = false
			activeStates.BGSI_Lite_ObbyChestActive = false
			activeStates.BGSI_Lite_GuildQuestActive = false
		end
		if not isPriorityAutomationActive() then
			resumeNormalAutomation()
		end
	end
end)
scriptStateOG = Interface:CreateWindow({
	Title = "LarpLite - BGSI",
	SubTitle = "free",
	TabWidth = 100,
	Size = UDim2.fromOffset(500, 300),
	Acrylic = false,
	Theme = "Dark",
	MinimizeKey = Enum.KeyCode.LeftControl,
})
do
	local scriptStateACM = "https://i.postimg.cc/Y9BqDMrR/images.png"
	local scriptStateQB = "1rzHubMobileUI.png"
	local scriptStateMY = "rbxassetid://7229442422"
	local function isImageFileBytes(scriptStateQE)
		if type(scriptStateQE) ~= "string" or #scriptStateQE < 24 then
			return false
		end
		if string.sub(scriptStateQE, 1, 8) == "\137PNG\r\n\26\n" then
			return true
		end
		if string.sub(scriptStateQE, 1, 2) == "\255\216" then
			return true
		end
		return false
	end
	local function downloadImageBytes(scriptStateRB)
		local scriptStatePD = request
			or http_request
			or (type(syn) == "table" and rawget(syn, "request"))
			or rawget((getgenv and getgenv()) or _G, "http_request")
		if type(scriptStatePD) ~= "function" then
			local httpTable = rawget((getgenv and getgenv()) or _G, "http")
			scriptStatePD = type(httpTable) == "table" and rawget(httpTable, "request") or nil
		end
		if scriptStatePD then
			local scriptStateIQ, scriptStateYB = pcall(function()
				return scriptStatePD({
					Url = scriptStateRB,
					Method = "GET",
					Headers = {
						["User-Agent"] = "Mozilla/5.0",
						["Accept"] = "image/*",
					},
				})
			end)
			if scriptStateIQ and type(scriptStateYB) == "table" then
				local scriptStateBD = scriptStateYB.Body or scriptStateYB.body
				if type(scriptStateBD) == "string" and isImageFileBytes(scriptStateBD) then
					return scriptStateBD
				end
			end
		end
		local scriptStateCX, scriptStateHN = pcall(function()
			return game:HttpGet(scriptStateRB)
		end)
		if scriptStateCX and isImageFileBytes(scriptStateHN) then
			return scriptStateHN
		end
		return nil
	end
	local function getCustomAssetLoader()
		local scriptStateAJ = getcustomasset or getsynasset
		if type(scriptStateAJ) == "function" then
			return scriptStateAJ
		end
		if type(syn) == "table" then
			if type(rawget(syn, "getcustomasset")) == "function" then
				return rawget(syn, "getcustomasset")
			end
			if type(rawget(syn, "getsynasset")) == "function" then
				return rawget(syn, "getsynasset")
			end
		end
		return nil
	end
	local function getMobileButtonImage()
		local scriptStateYN = writefile and isfile and readfile
		local scriptStateUD = getCustomAssetLoader()
		if not scriptStateYN then
			return scriptStateACM
		end
		if not isfile(scriptStateQB) then
			local scriptStateTN = downloadImageBytes(scriptStateACM)
			if scriptStateTN then
				pcall(writefile, scriptStateQB, scriptStateTN)
			end
		end
		if scriptStateUD and isfile(scriptStateQB) then
			local scriptStateHP, scriptStateADN = pcall(scriptStateUD, scriptStateQB)
			if scriptStateHP and type(scriptStateADN) == "string" and scriptStateADN ~= "" then
				return scriptStateADN
			end
		end
		return scriptStateMY
	end
	if not getgenv().LoadedMobileUI then
		getgenv().LoadedMobileUI = true
		local scriptStateMA = getMobileButtonImage()
		local scriptStateMV = Instance.new("ScreenGui")
		scriptStateMV.Name = "OpenUI"
		scriptStateMV.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		scriptStateMV.Parent = CoreGui
		local scriptStatePI = Instance.new("ImageButton")
		scriptStatePI.Parent = scriptStateMV
		scriptStatePI.BackgroundColor3 = Color3.fromRGB(105, 105, 105)
		scriptStatePI.BackgroundTransparency = 0.8
		scriptStatePI.Position = UDim2.new(0.9, 0, 0.1, 0)
		scriptStatePI.Size = UDim2.new(0, 50, 0, 50)
		scriptStatePI.Image = scriptStateMA
		scriptStatePI.ImageTransparency = 0
		scriptStatePI.Draggable = true
		scriptStatePI.MouseButton1Click:Connect(function()
			local scriptStateFR = getgenv()._1rzHubToggleRayfield
			if type(scriptStateFR) == "function" then
				local scriptStateLC = pcall(scriptStateFR)
				if scriptStateLC then
					return
				end
			end
			pcall(function()
				scriptStateOG:Minimize()
			end)
		end)
	end
	getgenv()._1rzHubToggleRayfield = function()
		scriptStateOG:Minimize()
	end
end
scriptStateOG:AddSection("General")
end,
function(...)
scriptStateOG:AddSection("Hatching")
end,
function(...)
riftsTabStub = nil
riftsTabStub = setmetatable({}, {
	__index = function()
		return function()
			return riftsTabStub
		end
	end,
})
end,
function(...)
scriptStateOG:AddSection("Automation")
end,
function(...)
winterAltarMachineName = "WinterAltar"
winterAltarNoPetsOption = "(None owned)"
winterAltarUtil = nil
pcall(function()
	winterAltarUtil = require(ReplicatedStorage.Shared.Utils.RebirthMachineUtil)
end)
winterAltarPetDropdown = nil
winterAltarStatusText = nil
winterAltarSupportedNames = {}
if type(winterAltarUtil) == "table" then
	local machineOk, machine = pcall(winterAltarUtil.GetMachine, winterAltarUtil, winterAltarMachineName)
	if machineOk and type(machine) == "table" and type(machine.ManualPets) == "table" then
		for _, petName in ipairs(machine.ManualPets) do
			if type(petName) == "string" then
				winterAltarSupportedNames[petName] = true
			end
		end
	end
end
function isWinterAltarPetUsable(pet)
	if type(pet) ~= "table" or type(pet.Name) ~= "string" or pet.Id == nil then
		return false
	end
	if next(winterAltarSupportedNames) ~= nil and not winterAltarSupportedNames[pet.Name] then
		return false
	end
	if pet.Locked == true or pet.XL == true then
		return false
	end
	if type(winterAltarUtil) ~= "table" then
		return false
	end
	local eligibilityOk, eligible = pcall(
		winterAltarUtil.IsPetEligible, winterAltarUtil, winterAltarMachineName, pet
	)
	return eligibilityOk and eligible == true
end
function getWinterAltarOwnedPetNames()
	local ownedNames = {}
	if not profileStore or not profileStore:IsReady() then
		return ownedNames
	end
	local playerData = profileStore:Get()
	if type(playerData) ~= "table" or type(playerData.Pets) ~= "table" then
		return ownedNames
	end
	local seenNames = {}
	for _, pet in pairs(playerData.Pets) do
		if isWinterAltarPetUsable(pet) and not seenNames[pet.Name] then
			seenNames[pet.Name] = true
			table.insert(ownedNames, pet.Name)
		end
	end
	table.sort(ownedNames)
	return ownedNames
end
function getSelectedWinterAltarNames()
	local selectedNames = {}
	local configured = Config.WinterAltarPets
	if type(configured) ~= "table" then
		return selectedNames
	end
	for key, value in pairs(configured) do
		if type(key) == "number" and type(value) == "string" and value ~= winterAltarNoPetsOption then
			selectedNames[value] = true
		elseif type(key) == "string" and value == true and key ~= winterAltarNoPetsOption then
			selectedNames[key] = true
		end
	end
	return selectedNames
end
winterAltarListedNames = ""
winterAltarIdleStatusShown = false
function refreshWinterAltarPetList(force)
	local ownedNames = getWinterAltarOwnedPetNames()
	local listSignature = table.concat(ownedNames, "\0")
	if force ~= true and listSignature == winterAltarListedNames then
		return ownedNames
	end
	winterAltarListedNames = listSignature
	fireRemoteEventRepeatedly(
		winterAltarPetDropdown,
		#ownedNames > 0 and ownedNames or { winterAltarNoPetsOption }
	)
	return ownedNames
end
end,
function(...)
task.spawn(function()
	local halloweenRebirthUtil
	local rebirthMachineUtil
	local adminRebirthMachineUtil
	local petsData
	pcall(function()
		halloweenRebirthUtil = require(ReplicatedStorage.Shared.Utils.HalloweenRebirthUtil)
	end)
	pcall(function()
		rebirthMachineUtil = require(ReplicatedStorage.Shared.Utils.RebirthMachineUtil)
	end)
	pcall(function()
		adminRebirthMachineUtil = require(ReplicatedStorage.Shared.Utils.AdminRebirthMachineUtil)
		petsData = require(ReplicatedStorage.Shared.Data.Pets)
	end)
	local lastMachineAttempt = 0
	local lastAdminAttempt = 0
	local lastWinterAttempt = 0
	local lastWinterRefresh = 0
	local function invokeMachine(actionName, ...)
		local ok, result = pcall(remoteFunction.InvokeServer, remoteFunction, actionName, ...)
		return ok and result ~= nil and result ~= false
	end
	local function fuseAtMachine(activation, actionName, ...)
		local arguments = table.pack(...)
		if invokeMachine(actionName, table.unpack(arguments, 1, arguments.n)) then
			return true
		end
		local root = activation and activation:FindFirstChild("Root")
		local center = activeStates.BGSI_Lite_GetInstanceTargetCFrame(activation)
		if not center then return false end
		local character = LocalPlayer.Character
		local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
		local original = playerRoot and playerRoot.CFrame
		local targets = {}
		if root and root:IsA("BasePart") then
			local radius = root.Size.Y / 2 + 2
			local position = root.Position + root.CFrame.RightVector * radius + Vector3.new(0, 2, 0)
			table.insert(targets, CFrame.lookAt(position, Vector3.new(root.Position.X, position.Y, root.Position.Z)))
		end
		table.insert(targets, center * CFrame.new(0, 2, 0))
		activeStates.BGSI_Lite_RebirthMachineBusy = true
		local fused = false
		for _, target in ipairs(targets) do
			if teleportToCFrame(target) then
				task.wait(0.3)
				fused = invokeMachine(actionName, table.unpack(arguments, 1, arguments.n))
				if fused then break end
			end
		end
		if original then teleportToCFrame(original) end
		activeStates.BGSI_Lite_RebirthMachineBusy = false
		return fused
	end
	while isCurrentRun() do
		task.wait(2.5)
		if Config.safeMode ~= true and activeStates.BGSI_Lite_BubbleQuestActive ~= true
			and profileStore:IsReady() then
			local playerData = profileStore:Get()
			if type(playerData) ~= "table" then continue end
			local machine = type(rebirthMachineUtil) == "table"
				and rebirthMachineUtil:GetMachine("RebirthMachine")
			if Config.RebirthMachineEnabled == true and type(playerData.Pets) == "table"
				and type(machine) == "table" and machine.Enabled == true
				and getCurrentTimestamp() >= (tonumber(playerData[machine.CooldownKey]) or 0)
				and tick() - lastMachineAttempt >= 5 then
				local targetName = tostring(Config.RebirthPetName or "")
				local variant = type(Config.RebirthVariants) == "table" and Config.RebirthVariants[1] or "Normal"
				local shiny = variant == "Shiny" or variant == "Shiny Mythic"
				local mythic = variant == "Mythic" or variant == "Shiny Mythic"
				local ids = {}
				local selectedPets = {}
				for _, pet in pairs(playerData.Pets) do
					if type(pet) == "table" and (targetName == "" or pet.Name == targetName)
						and pet.Locked ~= true
						and (pet.Shiny == true) == shiny and (pet.Mythic == true) == mythic
						and pet.XL ~= true and pet.Id ~= nil
						and rebirthMachineUtil:IsPetEligible("RebirthMachine", pet) then
						table.insert(ids, pet.Id)
						table.insert(selectedPets, pet)
						if #ids == 5 then break end
					end
				end
				if #ids == 5 and rebirthMachineUtil:CanFuse("RebirthMachine", selectedPets) then
					lastMachineAttempt = tick()
					local activation = Workspace:FindFirstChild("Worlds")
					local overworld = activation and activation:FindFirstChild("The Overworld")
					local islands = overworld and overworld:FindFirstChild("Islands")
					local outerSpace = islands and islands:FindFirstChild("Outer Space")
					local island = outerSpace and outerSpace:FindFirstChild("Island")
					local machineModel = island and island:FindFirstChild("RebirthMachine")
					local machineActivation = machineModel and machineModel:FindFirstChild("Activation")
					fuseAtMachine(machineActivation, "UseRebirthMachine", "RebirthMachine", ids)
				end
			end
			if Config.AdminRebirthMachineEnabled == true and type(playerData.Pets) == "table"
				and type(adminRebirthMachineUtil) == "table" and type(petsData) == "table"
				and getCurrentTimestamp() >= (tonumber(playerData.NextAdminRebirthMachineUse) or 0)
				and tick() - lastAdminAttempt >= 5 then
				local targetName = tostring(Config.AdminRebirthPetName or "")
				local variant = type(Config.RebirthVariants) == "table" and Config.RebirthVariants[1] or "Normal"
				local shiny = variant == "Shiny" or variant == "Shiny Mythic"
				local mythic = variant == "Mythic" or variant == "Shiny Mythic"
				local ids = {}
				for _, pet in pairs(playerData.Pets) do
					local petInfo = type(pet) == "table" and petsData[pet.Name]
					if type(petInfo) == "table" and (targetName == "" or pet.Name == targetName)
						and pet.Locked ~= true and pet.XL ~= true and pet.Id ~= nil
						and (pet.Shiny == true) == shiny and (pet.Mythic == true) == mythic
						and petInfo.Rarity == "Secret" and petInfo.AdminAbuse == true
						and not petInfo.Infinity and not petInfo.Celestial and not petInfo.Void then
						table.insert(ids, pet.Id)
						if #ids == adminRebirthMachineUtil.NUM_SECRETS_REQUIRED then break end
					end
				end
				if #ids == adminRebirthMachineUtil.NUM_SECRETS_REQUIRED then
					lastAdminAttempt = tick()
					local activation
					for _, candidate in ipairs(CollectionService:GetTagged("Activation")) do
						if candidate.Parent and candidate.Parent.Name == "AdminRebirthMachine" then
							activation = candidate
							break
						end
					end
					fuseAtMachine(activation, "UseAdminRebirthMachine", ids)
				end
			end
			-- Winter Altar: three pets of one variant per use. A special combination (three
			-- Ice Queen Seals) returns a guaranteed pet instead of a weighted roll, so it is
			-- preferred whenever the selection and inventory can cover one.
			if tick() - lastWinterRefresh >= 20 then
				lastWinterRefresh = tick()
				pcall(refreshWinterAltarPetList)
			end
			local winterMachine = type(rebirthMachineUtil) == "table"
				and rebirthMachineUtil:GetMachine("WinterAltar")
			local winterSelection = getSelectedWinterAltarNames()
			if next(winterSelection) == nil then
				-- Nothing selected: no reason to walk the inventory on every pass.
				if winterAltarStatusText and winterAltarIdleStatusShown ~= true then
					winterAltarIdleStatusShown = true
					pcall(winterAltarStatusText.SetDesc, winterAltarStatusText, "Select altar pets to begin.")
				end
			elseif type(winterMachine) == "table" and winterMachine.Enabled == true
				and type(playerData.Pets) == "table" then
				winterAltarIdleStatusShown = false
				local requiredCount = tonumber(winterMachine.NumPetsRequired) or 3
				local selectedNames = winterSelection
				local variant = type(Config.RebirthVariants) == "table" and Config.RebirthVariants[1] or "Normal"
				local shiny = variant == "Shiny" or variant == "Shiny Mythic"
				local mythic = variant == "Mythic" or variant == "Shiny Mythic"
				local candidatesByName = {}
				local candidateTotal = 0
				for _, pet in pairs(playerData.Pets) do
					if type(pet) == "table" and selectedNames[pet.Name]
						and (pet.Shiny == true) == shiny and (pet.Mythic == true) == mythic
						and isWinterAltarPetUsable(pet) then
						local byName = candidatesByName[pet.Name]
						if not byName then
							byName = {}
							candidatesByName[pet.Name] = byName
						end
						table.insert(byName, pet)
						candidateTotal += 1
					end
				end
				local cooldownAt = tonumber(playerData[winterMachine.CooldownKey]) or 0
				local secondsLeft = math.max(cooldownAt - getCurrentTimestamp(), 0)
				if winterAltarStatusText then
					local statusLines
					if secondsLeft > 0 then
						statusLines = string.format(
							"Cooldown %d:%02d  ·  %d ready (%s)",
							secondsLeft // 60, secondsLeft % 60, candidateTotal, variant
						)
					else
						statusLines = string.format("Ready  ·  %d available (%s)", candidateTotal, variant)
					end
					pcall(winterAltarStatusText.SetDesc, winterAltarStatusText, statusLines)
				end
				if Config.WinterAltarEnabled == true and secondsLeft <= 0
					and tick() - lastWinterAttempt >= 5 then
					local ids = {}
					local selectedPets = {}
					local function takeFromName(petName)
						local available = candidatesByName[petName]
						local pet = available and table.remove(available)
						if not pet then return false end
						table.insert(ids, pet.Id)
						table.insert(selectedPets, pet)
						return true
					end
					for _, combination in ipairs(type(winterMachine.SpecialCombinations) == "table"
						and winterMachine.SpecialCombinations or {}) do
						if #ids == 0 and type(combination.Pets) == "table" then
							local takenBack = {}
							local complete = true
							for _, petName in ipairs(combination.Pets) do
								if selectedNames[petName] and takeFromName(petName) then
									table.insert(takenBack, selectedPets[#selectedPets])
								else
									complete = false
									break
								end
							end
							if not complete then
								for _, pet in ipairs(takenBack) do
									table.insert(candidatesByName[pet.Name], pet)
								end
								table.clear(ids)
								table.clear(selectedPets)
							end
						end
					end
					if #ids == 0 then
						for petName in pairs(selectedNames) do
							while #ids < requiredCount and takeFromName(petName) do end
							if #ids >= requiredCount then break end
						end
					end
					if #ids > 0 and rebirthMachineUtil:CanFuse("WinterAltar", selectedPets) then
						lastWinterAttempt = tick()
						fuseAtMachine(Workspace:FindFirstChild("WinterAltar"), "UseRebirthMachine", "WinterAltar", ids)
					end
				end
			elseif winterAltarStatusText and winterAltarIdleStatusShown ~= true then
				winterAltarIdleStatusShown = true
				pcall(winterAltarStatusText.SetDesc, winterAltarStatusText, "Altar unavailable in this game version.")
			end
			if Config.autoHalloweenRebirth == true and type(halloweenRebirthUtil) == "table"
				and type(halloweenRebirthUtil.GetRebirthCost) == "function"
				and playerData.Halloween26AutoRebirthEnabled ~= true then
				local ok, cost = pcall(halloweenRebirthUtil.GetRebirthCost,
					halloweenRebirthUtil, (tonumber(playerData.Halloween26Rebirths) or 0) + 1)
				if ok and tonumber(cost) and (tonumber(playerData.Candycorn26) or 0) >= cost then
					pcall(remoteEvent.FireServer, remoteEvent, "HalloweenRebirth")
				end
			end
		end
	end
end)
end,
function(...)
scriptStateOG:AddSection("Integrations")
end,
function(...)
pcall(function()
	RunService:Set3dRenderingEnabled(Config.safeMode == true or not Config.disableRendering)
end)
pcall(activeStates.BGSI_Lite_ApplyPerformanceSettings)
end,
function(...)
if type(getgenv) == "function" then
	getgenv()._1rzHubLiteCleanup = function()
		if activeStates._1rzHubLiteRunToken==currentRunToken then
			pcall(function()
				if activeStates.BGSI_Lite_MemoryOptimizer then activeStates.BGSI_Lite_MemoryOptimizer.Destroy() end
				activeStates.BGSI_Lite_RestorePerformanceBaseline()
				activeStates.BGSI_Lite_MemoryOptimizer=nil
				activeStates.BGSI_Lite_WebhookPetIconResolver=nil
				if activeStates.BGSI_Lite_PickupRangeHook then activeStates.BGSI_Lite_PickupRangeHook.Destroy();activeStates.BGSI_Lite_PickupRangeHook=nil end
				pcall(clearEggScanCache)
			end)
		end
		pcall(function()
			if activeStates and activeStates.RayfieldGen2 and type(activeStates.RayfieldGen2.Destroy) == "function" then
				activeStates.RayfieldGen2:Destroy()
			end
		end)
		pcall(function()
			if
				activeStates
				and activeStates.RayfieldGen2Window
				and type(activeStates.RayfieldGen2Window.Unload) == "function"
			then
				activeStates.RayfieldGen2Window:Unload()
			end
		end)
		pcall(function()
			local openUi = CoreGui:FindFirstChild("OpenUI")
			if openUi then
				openUi:Destroy()
			end
		end)
		pcall(function()
			if
				hatchEffectModule
				and hatchEffectModule.Play == activeStates.BGSI_Lite_NoHatchAnimationPlay
				and type(scriptStateID) == "function"
			then
				hatchEffectModule.Play = scriptStateID
			end
		end)
		if activeStates then
			if activeStates._1rzHubLiteRunToken == currentRunToken then
				activeStates._1rzHubLiteRunToken = nil
			end
			pcall(function()
				if activeStates.BGSI_Lite_WebhookConnection then
					activeStates.BGSI_Lite_WebhookConnection:Disconnect()
					activeStates.BGSI_Lite_WebhookConnection = nil
				end
			end)
			pcall(function()
				if activeStates.BGSI_Lite_EventPurchaseSuccessConnection then
					activeStates.BGSI_Lite_EventPurchaseSuccessConnection:Disconnect()
					activeStates.BGSI_Lite_EventPurchaseSuccessConnection = nil
				end
			end)
			pcall(function()
				if activeStates.BGSI_Lite_EventAutomationHeartbeatConnection then
					activeStates.BGSI_Lite_EventAutomationHeartbeatConnection:Disconnect()
					activeStates.BGSI_Lite_EventAutomationHeartbeatConnection = nil
				end
			end)
			for _, connectionKey in ipairs({
				"BGSI_Lite_CompSnapshotConnection",
				"BGSI_Lite_GamePromptChildConnection",
				"BGSI_Lite_GamePopupFrameConnection",
				"BGSI_Lite_PlayerGuiChildConnection",
			}) do
				pcall(function()
					local connection = activeStates[connectionKey]
					if connection then
						connection:Disconnect()
						activeStates[connectionKey] = nil
					end
				end)
			end
			pcall(function()
				if activeStates.BGSI_Lite_CompPopup then activeStates.BGSI_Lite_CompPopup:Close();activeStates.BGSI_Lite_CompPopup=nil end
			end)
			activeStates.RayfieldGen2 = nil
			activeStates.RayfieldGen2Window = nil
			activeStates.BGSI_Lite_EventBoard = nil
			activeStates.BGSI_Lite_BeginSeasonInfinite = nil
			activeStates.BGSI_Lite_HasLiveFourXLuckEgg = nil
			activeStates.BGSI_Lite_HideHatchInterface = nil
			activeStates.BGSI_Lite_NoHatchAnimationPlay = nil
			activeStates.BGSI_Lite_ApplyHatchAnimationSetting = nil
			activeStates._1rzHubToggleRayfield = nil
			activeStates.LoadedMobileUI = false
			activeStates._1rzHubLite_Loaded = false
			activeStates._1rzHubLite_LoadComplete = false
		end
	end
end
end,
function(...)
scriptStateOG:SelectTab(1)
Interface:Notify({
	Title = "1rzHub Lite",
	Content = "Loading...",
	Duration = 3,
})
do
	local function getDebugGui()
		local scriptStateEG = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local scriptStateIT = scriptStateEG and scriptStateEG:FindFirstChild("ScreenGui")
		return scriptStateIT and scriptStateIT:FindFirstChild("_debug") or nil
	end
	local function getDebugTagsContainer()
		local scriptStateAG = getDebugGui()
		return scriptStateAG and scriptStateAG:FindFirstChild("Tags") or nil
	end
	local function getOrCreateDebugLabel(debugTagsContainer, labelName, layoutOrder)
		if not debugTagsContainer or typeof(debugTagsContainer) ~= "Instance" then
			return nil
		end
		local scriptStateEK = debugTagsContainer
		local scriptStateRD = tostring(labelName or "BGSI_Lite_Label")
		local scriptStateADJ = tonumber(layoutOrder) or 0
		local scriptStateABL = scriptStateEK:FindFirstChild(scriptStateRD)
		if scriptStateABL then
			return scriptStateABL:FindFirstChild("Label")
		end
		local scriptStateGZ
		for loopSlotCV, scriptStateAFJ in ipairs(scriptStateEK:GetChildren()) do
			if
				scriptStateAFJ:IsA("Frame")
				and scriptStateAFJ:FindFirstChild("Label")
				and not string.find(scriptStateAFJ.Name, "^BGSI_")
			then
				scriptStateGZ = scriptStateAFJ
				break
			end
		end
		if scriptStateGZ then
			local scriptStateXS = scriptStateGZ:Clone()
			scriptStateXS.Name = scriptStateRD
			scriptStateXS.LayoutOrder = scriptStateADJ
			scriptStateXS.Parent = scriptStateEK
			local scriptStateCM = scriptStateXS:FindFirstChild("Label")
			if scriptStateCM and scriptStateCM:IsA("TextLabel") then
				scriptStateCM.Text = ""
				scriptStateCM.RichText = true
				return scriptStateCM
			end
		end
		local giftSortedList = Instance.new("Frame")
		giftSortedList.Name = scriptStateRD
		giftSortedList.BackgroundTransparency = 1
		giftSortedList.LayoutOrder = scriptStateADJ
		giftSortedList.Size = UDim2.fromOffset(220, 20)
		giftSortedList.Parent = scriptStateEK
		local scriptStateAAQ = Instance.new("TextLabel")
		scriptStateAAQ.Name = "Label"
		scriptStateAAQ.BackgroundTransparency = 1
		scriptStateAAQ.Font = Enum.Font.GothamBold
		scriptStateAAQ.RichText = true
		scriptStateAAQ.Size = UDim2.fromScale(1, 1)
		scriptStateAAQ.Text = ""
		scriptStateAAQ.TextColor3 = Color3.new(1, 1, 1)
		scriptStateAAQ.TextSize = 14
		scriptStateAAQ.TextXAlignment = Enum.TextXAlignment.Left
		scriptStateAAQ.TextYAlignment = Enum.TextYAlignment.Center
		scriptStateAAQ.Parent = giftSortedList
		local scriptStateAM = Instance.new("UIStroke")
		scriptStateAM.Color = Color3.new(0, 0, 0)
		scriptStateAM.Thickness = 1
		scriptStateAM.Parent = scriptStateAAQ
		return scriptStateAAQ
	end
	local function formatNumberWithCommas(scriptStateHB)
		scriptStateHB = tonumber(scriptStateHB)
		if not scriptStateHB then
			return "-"
		end
		local scriptStateXB = tostring(math.floor(scriptStateHB))
		while true do
			local scriptStateUR, scriptStateZI = scriptStateXB:gsub("^(-?%d+)(%d%d%d)", "%1,%2")
			scriptStateXB = scriptStateUR
			if scriptStateZI == 0 then
				break
			end
		end
		return scriptStateXB
	end
	local function formatOneInChance(scriptStateNM)
		scriptStateNM = tonumber(scriptStateNM)
		if not scriptStateNM or scriptStateNM <= 0 then
			return "-"
		end
		local scriptStateJJ = 1 / scriptStateNM
		local scriptStateABY = math.floor(scriptStateJJ + 0.5)
		if math.abs(scriptStateJJ - scriptStateABY) < 1e-06 then
			return formatNumberWithCommas(scriptStateABY)
		end
		return string.format("%.2f", scriptStateJJ)
	end
	local function resizeDebugLabelToText(scriptStatePB)
		if not scriptStatePB or not scriptStatePB.Parent then
			return
		end
		local scriptStateLB = scriptStatePB.Parent
		local scriptStateYJ = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local scriptStateAH = scriptStateYJ and scriptStateYJ:FindFirstChild("ScreenGui")
		local scriptStateJP = scriptStateAH and scriptStateAH:FindFirstChild("UIScale")
		local scriptStateDK = (scriptStateJP and scriptStateJP.Scale) or 1
		local scriptStateCY =
			math.max(130, math.floor((scriptStatePB.TextBounds.X / math.max(scriptStateDK, 0.001)) + 20))
		local scriptStateLX = scriptStateLB.Size.Y.Offset > 0 and scriptStateLB.Size.Y.Offset or 20
		scriptStateLB.Size = UDim2.fromOffset(scriptStateCY, scriptStateLX)
	end
	local function makeDebugLabelClickable(scriptStateJX, scriptStateOW, scriptStatePT)
		local scriptStateFA = scriptStateJX and scriptStateJX.Parent
		if not scriptStateFA or scriptStateFA:FindFirstChild(scriptStateOW) then
			return
		end
		local scriptStateFG = Instance.new("TextButton")
		scriptStateFG.Name = scriptStateOW
		scriptStateFG.AutoButtonColor = false
		scriptStateFG.BackgroundTransparency = 1
		scriptStateFG.Position = UDim2.fromOffset(0, 0)
		scriptStateFG.Size = UDim2.fromScale(1, 1)
		scriptStateFG.Text = ""
		scriptStateFG.ZIndex = (scriptStateJX.ZIndex or 1) + 1
		scriptStateFG.Parent = scriptStateFA
		scriptStateFG.MouseButton1Click:Connect(scriptStatePT)
	end
	local function getPlayerDataSnapshot()
		local scriptStateU
		pcall(function()
			if profileStore and profileStore.IsReady and profileStore:IsReady() then
				scriptStateU = profileStore:Get()
			end
		end)
		return type(scriptStateU) == "table" and scriptStateU or {}
	end
	local function findNestedNumericStat(scriptStateBG, scriptStateLV, scriptStateKD)
		if type(scriptStateBG) ~= "table" or type(scriptStateLV) ~= "table" then
			return nil
		end
		scriptStateKD = tonumber(scriptStateKD) or 0
		local scriptStateSZ = {}
		for loopSlotDR, scriptStateSW in ipairs(scriptStateLV) do
			scriptStateSZ[string.lower(tostring(scriptStateSW))] = true
		end
		for loopSlotAB, scriptStateAEO in pairs(scriptStateBG) do
			if type(loopSlotAB) == "string" and scriptStateSZ[string.lower(loopSlotAB)] then
				if type(scriptStateAEO) == "number" then
					return scriptStateAEO
				end
				if type(scriptStateAEO) == "string" and tonumber(scriptStateAEO) then
					return tonumber(scriptStateAEO)
				end
			end
		end
		if scriptStateKD <= 0 then
			return nil
		end
		for loopSlotDS, scriptStateEO in pairs(scriptStateBG) do
			if type(scriptStateEO) == "table" then
				local scriptStateJH = findNestedNumericStat(scriptStateEO, scriptStateLV, scriptStateKD - 1)
				if type(scriptStateJH) == "number" then
					return scriptStateJH
				end
			end
		end
		return nil
	end
	local function getNestedStatValue(scriptStateSI, scriptStateDM)
		local scriptStateMR = findNestedNumericStat(scriptStateSI, scriptStateDM, 6)
		return type(scriptStateMR) == "number" and scriptStateMR or 0
	end
	local scriptStateEX = {
		Common = 0.0002,
		Unique = 0.00028571428571428574,
		Rare = 0.0013333333333333333,
		Epic = 0.004,
		Legendary = 0.05,
		Secret = 0.2,
	}
	local rebirthRarityList = {
		"Legendary",
		"Epic",
		"Rare",
		"Unique",
		"Common",
	}
	local scriptStateEP = 0.04
	local scriptStateAFL = {
		"",
		"Shiny ",
		"Mythic ",
		"Shiny Mythic ",
		"Mythic Shiny ",
		"XL ",
		"XL Shiny ",
		"XL Mythic ",
		"XL Shiny Mythic ",
		"XL Mythic Shiny ",
	}
	local scriptStateM = {
		Common = 1,
		Unique = 2,
		Rare = 3,
		Epic = 4,
		Legendary = 5,
		Mythic = 6,
		Secret = 7,
		Infinity = 8,
	}
	local function getXLChanceForRarity(scriptStateAAF, scriptStateJO)
		local scriptStateLG = scriptStateEX[scriptStateAAF]
		if type(scriptStateLG) ~= "number" then
			return nil, 0
		end
		local scriptStateBA = getNestedStatValue(scriptStateJO, {
			"XLChance",
			"xl_chance",
			"xlpetchance",
			"xleggchance",
		})
		return (scriptStateLG / 100) * math.max(0, 1 + scriptStateBA), scriptStateBA
	end
	local function getSuperLegendaryChance(scriptStateY)
		local scriptStateQO = getNestedStatValue(scriptStateY, {
			"SuperChance",
			"SuperLegendaryChance",
			"super_legendary_chance",
		})
		return (scriptStateEP / 100) * math.max(0, 1 + scriptStateQO), scriptStateQO
	end
	local function countDiscoveredPetVariants(scriptStateMT, scriptStateABP)
		if type(scriptStateMT) ~= "table" or type(scriptStateABP) ~= "string" then
			return 0
		end
		local scriptStateNS = 0
		for loopSlotAO, scriptStateFT in ipairs(scriptStateAFL) do
			local scriptStateAAC = scriptStateMT[scriptStateFT .. scriptStateABP]
			if type(scriptStateAAC) == "number" then
				scriptStateNS = scriptStateNS + math.max(0, math.floor(scriptStateAAC))
			elseif scriptStateAAC == true then
				scriptStateNS = scriptStateNS + 1
			end
		end
		return scriptStateNS
	end
	local function getPetsForSelectedEgg(scriptStateTA)
		local scriptStateSV = {}
		if type(scriptStateTA) ~= "string" or scriptStateTA == "" or type(petRarityData) ~= "table" then
			return scriptStateSV
		end
		for loopSlotCR, scriptStateEB in pairs(petRarityData) do
			if
				type(loopSlotCR) == "string"
				and type(scriptStateEB) == "table"
				and scriptStateEB.Egg == scriptStateTA
			then
				table.insert(scriptStateSV, {
					name = loopSlotCR,
					chance = tonumber(scriptStateEB.Chance) or 0,
					rank = scriptStateM[scriptStateEB.Rarity] or 50,
				})
			end
		end
		table.sort(scriptStateSV, function(scriptStateEN, scriptStateBQ)
			if scriptStateEN.chance ~= scriptStateBQ.chance then
				return scriptStateEN.chance > scriptStateBQ.chance
			end
			if scriptStateEN.rank ~= scriptStateBQ.rank then
				return scriptStateEN.rank < scriptStateBQ.rank
			end
			return scriptStateEN.name < scriptStateBQ.name
		end)
		return scriptStateSV
	end
	task.spawn(function()
		local scriptStateAW
		for loopSlotCN = 1, 60 do
			scriptStateAW = getDebugTagsContainer()
			if scriptStateAW then
				break
			end
			task.wait(1)
		end
		if not scriptStateAW then
			return
		end
		local rebirthLayoutOffset = 1000
		local scriptStateDZ = 64
		local scriptStateZT = #rebirthRarityList
		local scriptStateTV = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_ShowOthers", -10000)
		local rebirthSelectedEggHatched =
			getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_SelectedEggHatched", rebirthLayoutOffset + 1)
		local rebirthPetLabels = {}
		for loopSlotDB = 1, scriptStateDZ do
			rebirthPetLabels[loopSlotDB] = getOrCreateDebugLabel(
				scriptStateAW,
				"BGSI_Lite_EggPetRow_" .. loopSlotDB,
				rebirthLayoutOffset + 1 + loopSlotDB
			)
			if rebirthPetLabels[loopSlotDB] then
				rebirthPetLabels[loopSlotDB].TextSize =
					math.max(7, math.floor((rebirthPetLabels[loopSlotDB].TextSize or 14) * 0.72))
			end
		end
		local scriptStateCO = rebirthLayoutOffset + scriptStateDZ + 2
		local scriptStateQT = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_SecretsHatched", scriptStateCO)
		scriptStateCO = scriptStateCO + 1
		local rebirthGemGenieQuests = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_GemGenieQuests", scriptStateCO)
		scriptStateCO = scriptStateCO + 1
		local rebirthRebirthFuses = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_RebirthFuses", scriptStateCO)
		scriptStateCO = scriptStateCO + 1
		local scriptStateNL = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_SeasonPassQuests", scriptStateCO)
		scriptStateCO = scriptStateCO + 1
		local scriptStateAEA = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_OldSailorQuests", scriptStateCO)
		scriptStateCO = scriptStateCO + 1
		local rebirthXLChance = getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_XLChance", 8)
		local scriptStateAF = {}
		for loopSlotBD = 1, scriptStateZT do
			scriptStateAF[loopSlotBD] =
				getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_XLChanceRow_" .. loopSlotBD, 8 + loopSlotBD)
			if scriptStateAF[loopSlotBD] then
				scriptStateAF[loopSlotBD].TextSize =
					math.max(7, math.floor((scriptStateAF[loopSlotBD].TextSize or 14) * 0.72))
			end
		end
		local scriptStateGU =
			getOrCreateDebugLabel(scriptStateAW, "BGSI_Lite_SuperLegendaryChance", 8 + scriptStateZT + 1)
		local scriptStateX = {
			rebirthSelectedEggHatched,
			scriptStateQT,
			rebirthGemGenieQuests,
			rebirthRebirthFuses,
			scriptStateNL,
			scriptStateAEA,
			rebirthXLChance,
			scriptStateGU,
		}
		local rebirthShowOthers = false
		local scriptStateAEY = false
		local scriptStateKF = false
		local scriptStateVP = 0
		local scriptStateBM = 0
		local function setDebugLabelText(debugLabel, labelText)
			if not debugLabel or typeof(debugLabel) ~= "Instance" then
				return
			end
			if not (debugLabel:IsA("TextLabel") or debugLabel:IsA("TextButton")) then
				return
			end
			local debugTextObject = debugLabel :: any
			debugTextObject.RichText = true
			debugTextObject.Text = tostring(labelText or "")
			local scriptStateACY = debugTextObject
			resizeDebugLabelToText(scriptStateACY)
			task.defer(function()
				resizeDebugLabelToText(scriptStateACY)
			end)
		end
		local function rebirthUpdateLabelsVisibility()
			for loopSlotDI, rebirthOtherLabel in ipairs(scriptStateX) do
				if rebirthOtherLabel and rebirthOtherLabel.Parent then
					rebirthOtherLabel.Parent.Visible = rebirthShowOthers
				end
			end
			for loopSlotDU, rebirthPetLabel in ipairs(rebirthPetLabels) do
				if rebirthPetLabel and rebirthPetLabel.Parent then
					rebirthPetLabel.Parent.Visible = rebirthShowOthers
						and scriptStateAEY
						and loopSlotDU <= scriptStateVP
				end
			end
			for loopSlotBR, rebirthRarityLabel in ipairs(scriptStateAF) do
				if rebirthRarityLabel and rebirthRarityLabel.Parent then
					rebirthRarityLabel.Parent.Visible = rebirthShowOthers
						and scriptStateKF
						and loopSlotBR <= scriptStateBM
				end
			end
		end
		local function rebirthUpdateShowOthersButton()
			setDebugLabelText(
				scriptStateTV,
				rebirthShowOthers
						and '<stroke color = "#000000" joins = "round" thickness = "2">Hide Others</stroke>'
					or '<stroke color = "#000000" joins = "round" thickness = "2">Show Others</stroke>'
			)
		end
		makeDebugLabelClickable(scriptStateTV, "BGSI_Lite_ShowOthersClick", function()
			rebirthShowOthers = not rebirthShowOthers
			rebirthUpdateLabelsVisibility()
			rebirthUpdateShowOthersButton()
		end)
		makeDebugLabelClickable(rebirthSelectedEggHatched, "BGSI_Lite_SelectedEggClick", function()
			scriptStateAEY = not scriptStateAEY
			rebirthUpdateLabelsVisibility()
		end)
		makeDebugLabelClickable(rebirthXLChance, "BGSI_Lite_XLChanceClick", function()
			scriptStateKF = not scriptStateKF
			rebirthUpdateLabelsVisibility()
		end)
		rebirthUpdateShowOthersButton()
		rebirthUpdateLabelsVisibility()
		while isCurrentRun() do
			task.wait(1)
			local scriptStateXA = getPlayerDataSnapshot()
			local rebirthSelectedEgg = tostring(Config.selectedEgg or "")
			local scriptStateAS = type(scriptStateXA.EggsOpened) == "table" and scriptStateXA.EggsOpened or {}
			local scriptStateMX = type(scriptStateXA.QuestsCompleted) == "table" and scriptStateXA.QuestsCompleted or {}
			local rebirthEggDisplayName = rebirthSelectedEgg ~= "" and rebirthSelectedEgg:gsub("%s*Egg$", "")
				or "Selected Egg"
			local scriptStateABV = rebirthSelectedEgg ~= "" and tonumber(scriptStateAS[rebirthSelectedEgg]) or nil
			setDebugLabelText(
				rebirthSelectedEggHatched,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">%s Eggs Hatched <b><font color = "#ffe942">%s</font></b> <font color = "#888888">%s</font></stroke>',
					rebirthEggDisplayName,
					formatNumberWithCommas(scriptStateABV or 0),
					scriptStateAEY and "v" or ">"
				)
			)
			local scriptStateWS = getPetsForSelectedEgg(rebirthSelectedEgg)
			local rebirthDiscoveredPets = type(scriptStateXA.Discovered) == "table" and scriptStateXA.Discovered or {}
			scriptStateVP = math.min(#scriptStateWS, scriptStateDZ)
			if rebirthSelectedEgg == "" then
				scriptStateVP = 1
				setDebugLabelText(
					rebirthPetLabels[1],
					'<stroke color = "#000000" joins = "round" thickness = "1.5">  Select an egg to list pets.</stroke>'
				)
			elseif #scriptStateWS == 0 then
				scriptStateVP = 1
				setDebugLabelText(
					rebirthPetLabels[1],
					'<stroke color = "#000000" joins = "round" thickness = "1.5">  No PetsData rows for this egg.</stroke>'
				)
			else
				for loopSlotCY = 1, scriptStateVP do
					setDebugLabelText(
						rebirthPetLabels[loopSlotCY],
						string.format(
							'<stroke color = "#000000" joins = "round" thickness = "1.5">  %s <b><font color = "#cfe9ff">%s</font></b></stroke>',
							scriptStateWS[loopSlotCY].name,
							formatNumberWithCommas(
								countDiscoveredPetVariants(rebirthDiscoveredPets, scriptStateWS[loopSlotCY].name)
							)
						)
					)
				end
			end
			for rebirthPetLabelIndex = scriptStateVP + 1, scriptStateDZ do
				if rebirthPetLabels[rebirthPetLabelIndex] then
					rebirthPetLabels[rebirthPetLabelIndex].Text = ""
				end
			end
			setDebugLabelText(
				scriptStateQT,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Secrets Hatched <b><font color = "#ff6bff">%s</font></b></stroke>',
					formatNumberWithCommas(scriptStateXA.SecretsHatched)
				)
			)
			setDebugLabelText(
				rebirthGemGenieQuests,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Gem Genie Quests <b><font color = "#40e0ff">%s</font></b></stroke>',
					formatNumberWithCommas(scriptStateXA.GemGenieCompletions)
				)
			)
			setDebugLabelText(
				rebirthRebirthFuses,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Rebirth Machine Fuses <b><font color = "#7cff4f">%s</font></b></stroke>',
					formatNumberWithCommas(scriptStateXA.RebirthMachineFuses)
				)
			)
			local rebirthQuestCount2 = 0
			for rebirthQuestKey, scriptStateIY in pairs(scriptStateMX) do
				if type(rebirthQuestKey) == "string" and type(scriptStateIY) == "number" then
					if
						rebirthQuestKey:match("^daily%-challenge%-") or rebirthQuestKey:match("^hourly%-challenge%-")
					then
						rebirthQuestCount2 = rebirthQuestCount2 + scriptStateIY
					end
				end
			end
			setDebugLabelText(
				scriptStateNL,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Season Pass Quests <b><font color = "#ffa500">%s</font></b></stroke>',
					formatNumberWithCommas(rebirthQuestCount2)
				)
			)
			setDebugLabelText(
				scriptStateAEA,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Old Sailor Quests <b><font color = "#4fd1c5">%s</font></b></stroke>',
					formatNumberWithCommas(scriptStateMX["sailor-bounty"])
				)
			)
			local scriptStateOQ, scriptStateDN = getXLChanceForRarity("Secret", scriptStateXA)
			local rebirthSecretBonusStr = (type(scriptStateDN) == "number" and scriptStateDN ~= 0)
					and (" +" .. tostring(math.floor(scriptStateDN * 100 + 0.5)) .. "%")
				or ""
			setDebugLabelText(
				rebirthXLChance,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">XL Chance (Secret%s) <b><font color = "#b6f7ff">1/%s</font></b> <font color = "#888888">%s</font></stroke>',
					rebirthSecretBonusStr,
					formatOneInChance(scriptStateOQ),
					scriptStateKF and "v" or ">"
				)
			)
			scriptStateBM = 0
			for loopSlotBT, scriptStateJU in ipairs(rebirthRarityList) do
				local scriptStateIR = getXLChanceForRarity(scriptStateJU, scriptStateXA)
				if type(scriptStateIR) == "number" then
					scriptStateBM = loopSlotBT
					setDebugLabelText(
						scriptStateAF[loopSlotBT],
						string.format(
							'<stroke color = "#000000" joins = "round" thickness = "1.5">  %s <b><font color = "#cfe9ff">1/%s</font></b></stroke>',
							scriptStateJU,
							formatOneInChance(scriptStateIR)
						)
					)
				end
			end
			local scriptStateAZ, rebirthSuperLegendaryBonus = getSuperLegendaryChance(scriptStateXA)
			local rebirthSuperLegendaryBonusStr = (
				type(rebirthSuperLegendaryBonus) == "number" and rebirthSuperLegendaryBonus ~= 0
			)
					and (" +" .. tostring(math.floor(rebirthSuperLegendaryBonus * 100 + 0.5)) .. "%")
				or ""
			setDebugLabelText(
				scriptStateGU,
				string.format(
					'<stroke color = "#000000" joins = "round" thickness = "2">Super Legendary Chance%s <b><font color = "#ffd166">1/%s</font></b></stroke>',
					rebirthSuperLegendaryBonusStr,
					formatOneInChance(scriptStateAZ)
				)
			)
			rebirthUpdateLabelsVisibility()
		end
	end)
end
end,
function(...)
activeStates.BGSI_Lite_LuckEggActive = false
activeStates.BGSI_Lite_SpecialRiftActive = false
function setLuckEggActive(isActive)
	isActive = isActive == true
	if activeStates.BGSI_Lite_LuckEggActive == isActive then return end
	activeStates.BGSI_Lite_LuckEggActive = isActive
	if Config.autoSetupTeamEnabled == true and Config.autoSetupTeamAABlessingSupers == true
		and type(activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh) == "function" then
		activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
	end
end
activeStates.BGSI_Lite_HasLiveFourXLuckEgg = function()
	if Config.autoLuckEgg ~= true then
		return false
	end
	local summonedEgg = Workspace:FindFirstChild("SummonedEgg")
	return summonedEgg ~= nil and summonedEgg:FindFirstChild("EggPlatformSpawn") ~= nil
end
task.spawn(function()
	local luckEggCooldown = 0
	local luckEggReadinessLogAt = 0
	while isCurrentRun() do
		task.wait(Config.autoLuckEgg and 0.1 or 0.85)
		if Config.autoLuckEgg ~= true then
			if activeStates.BGSI_Lite_LuckEggActive then
				setLuckEggActive(false)
			end
			continue
		end
		local summonedEgg = workspace:FindFirstChild("SummonedEgg")
		local scriptStateTL = summonedEgg and summonedEgg:FindFirstChild("EggPlatformSpawn")
		local luckEggName = activeStates.BGSI_Lite_FindLuckEggName and activeStates.BGSI_Lite_FindLuckEggName()
			or "4x Luck Ultra Carnival Egg"
		if isPriorityAutomationActive() or Config.safeMode == true then
			setLuckEggActive(false)
			task.wait(0.25)
			continue
		end
		if not scriptStateTL then
			if activeStates.BGSI_Lite_LuckEggActive then
				setLuckEggActive(false)
				luckEggCooldown = 0
			end
			task.wait(1)
			continue
		end
		local playerGui = LocalPlayer and LocalPlayer:FindFirstChild("PlayerGui")
		local screenGui = playerGui and playerGui:FindFirstChild("ScreenGui")
		local playerDataReady = profileStore and type(profileStore.IsReady) == "function" and profileStore:IsReady()
		local scriptStateDA = LocalPlayer and LocalPlayer.Character
		local scriptStateFV = scriptStateDA and scriptStateDA:FindFirstChild("HumanoidRootPart")
		if not playerDataReady or not screenGui or not scriptStateFV then
			setLuckEggActive(false)
			if tick() - luckEggReadinessLogAt >= 5 then
				print(
					"["
						.. LocalPlayer.Name
						.. "] 4x egg found. Waiting for client readiness: LocalData="
						.. tostring(playerDataReady)
						.. ", PlayerGui="
						.. tostring(playerGui ~= nil)
						.. ", ScreenGui="
						.. tostring(screenGui ~= nil)
						.. ", Character="
						.. tostring(scriptStateFV ~= nil)
				)
				luckEggReadinessLogAt = tick()
			end
			task.wait(0.5)
			continue
		end
		if not activeStates.BGSI_Lite_LuckEggActive then
			print("[" .. LocalPlayer.Name .. "] 4x egg client ready. Starting hatch: " .. tostring(luckEggName))
		end
		local firstFourXHatch = activeStates.BGSI_Lite_LuckEggActive ~= true
		setLuckEggActive(true)
		if firstFourXHatch and Config.autoSetupTeamEnabled == true
			and Config.autoSetupTeamAABlessingSupers == true
			and type(activeStates.BGSI_Lite_RunAutoSetupTeam) == "function" then
			local teamWaitDeadline = tick() + 10
			while activeStates.BGSI_Lite_AutoSetupTeamApplying and tick() < teamWaitDeadline do
				task.wait(0.1)
			end
			pcall(activeStates.BGSI_Lite_RunAutoSetupTeam)
			scriptStateDA = LocalPlayer and LocalPlayer.Character
			scriptStateFV = scriptStateDA and scriptStateDA:FindFirstChild("HumanoidRootPart")
			if not scriptStateFV then continue end
		end
		if tick() - luckEggCooldown >= 5 then
			local rebirthPetVariant = scriptStateTL:IsA("BasePart") and scriptStateTL
				or scriptStateTL:FindFirstChildWhichIsA("BasePart", true)
			if rebirthPetVariant then
				pcall(function()
					scriptStateFV.CFrame = rebirthPetVariant.CFrame + Vector3.new(0, 3, -5)
				end)
				luckEggCooldown = tick()
			end
		end
		fireHatchEgg(luckEggName)
	end
end)
task.spawn(function()
	local lastAutoHatchTeleportAt = 0
	local autoHatchStartedAt = 0
	local lastHatchRecoveryAt = 0
	local lastHatchProgressAt = 0
	local lastHatchSampleAt = 0
	local observedHatchCount
	local lastSelectedEgg
	activeStates.BGSI_Lite_AdaptiveHatchDelay = math.clamp(
		tonumber(activeStates.BGSI_Lite_AdaptiveHatchDelay) or 0.005,
		0.005,
		0.015
	)
	while isCurrentRun() do
		local shouldMaintainHatching = activeStates.BGSI_Lite_ShouldMaintainHatching()
		task.wait(
			shouldMaintainHatching
					and math.clamp(tonumber(activeStates.BGSI_Lite_AdaptiveHatchDelay) or 0.005, 0.005, 0.015)
				or 0.85
		)
		shouldMaintainHatching = activeStates.BGSI_Lite_ShouldMaintainHatching()
		activeStates.BGSI_Lite_IdleHatchFallbackActive =
			shouldMaintainHatching and Config.autoHatch ~= true
		if not shouldMaintainHatching then
			lastAutoHatchTeleportAt = 0
			autoHatchStartedAt = 0
			lastHatchProgressAt = 0
			lastHatchSampleAt = 0
			observedHatchCount = nil
			lastSelectedEgg = nil
			continue
		end
		if autoHatchStartedAt == 0 then
			autoHatchStartedAt = tick()
			lastHatchProgressAt = autoHatchStartedAt
		end
		clearDisabledPriorityStates()
		if
			isPriorityAutomationActive()
			or activeStates.BGSI_Lite_SpecialRiftActive
			or activeStates.BGSI_Lite_LuckEggActive
			or activeStates.BGSI_Lite_RiftEggActive
			or activeStates.BGSI_Lite_BountyRiftActive
		then
			continue
		end
		local scriptStateRX = LocalPlayer and LocalPlayer.Character
		if not scriptStateRX or not scriptStateRX:FindFirstChild("HumanoidRootPart") then
			continue
		end
		local scriptStateEL = Config.selectedEgg
		if type(scriptStateEL) ~= "string" or scriptStateEL == "" then
			continue
		end
		if lastSelectedEgg ~= scriptStateEL then
			lastSelectedEgg = scriptStateEL
			lastAutoHatchTeleportAt = 0
			lastHatchProgressAt = tick()
			observedHatchCount = nil
		end
		if tick() - lastHatchSampleAt >= 0.5 then
			lastHatchSampleAt = tick()
			local playerData
			pcall(function()
				if profileStore and profileStore:IsReady() then
					playerData = profileStore:Get()
				end
			end)
			local hatchCount = playerData
				and type(playerData.Stats) == "table"
				and tonumber(playerData.Stats.Hatches)
				or nil
			if hatchCount and observedHatchCount and hatchCount ~= observedHatchCount then
				lastHatchProgressAt = tick()
			end
			observedHatchCount = hatchCount or observedHatchCount
		end
		lastHatchProgressAt = math.max(
			lastHatchProgressAt,
			autoHatchStartedAt,
			tonumber(activeStates.BGSI_Lite_LastHatchEventAt) or 0
		)
		local controllerIsHatching = false
		if hatchEffectModule and type(hatchEffectModule.IsHatching) == "function" then
			pcall(function()
				controllerIsHatching = hatchEffectModule:IsHatching() == true
			end)
		end
		local stallTimeout = controllerIsHatching and 12 or 8
		if tick() - lastHatchProgressAt >= stallTimeout and tick() - lastHatchRecoveryAt >= 5 then
			activeStates.BGSI_Lite_ForceAutoHatchTeleport = true
			lastHatchRecoveryAt = tick()
			lastHatchProgressAt = tick()
		end
		-- ForceAutoHatchTeleport used to still be gated behind "at least 2s since the
		-- last auto-hatch teleport," which meant returning from a quest that had only
		-- run for a couple of seconds (a nearly-finished task, or one quick task away
		-- from being deferred) could sit for up to 2 more seconds doing nothing before
		-- actually teleporting back to the egg the user had selected - looking exactly
		-- like "won't return to the default egg". A forced request means "resync right
		-- now" by definition, so it now bypasses that gate entirely instead of waiting
		-- on it.
		if lastAutoHatchTeleportAt == 0 or activeStates.BGSI_Lite_ForceAutoHatchTeleport then
			activeStates.BGSI_Lite_ForceAutoHatchTeleport = false
			pcall(function()
				teleportToEggByName(scriptStateEL)
			end)
			lastAutoHatchTeleportAt = tick()
		end
		fireHatchEgg(scriptStateEL)
	end
end)
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.autoSpamR and 0 or 0.85)
		if Config.autoSpamR ~= true then
			continue
		end
		if activeStates.BGSI_Lite_ObbyChestActive then
			continue
		end
		pcall(function()
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.R, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.R, false, game)
			VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.E, false, game)
			VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.E, false, game)
		end)
	end
end)
function getLuckEggPosition(scriptStateMK)
	if type(scriptStateMK) ~= "table" then
		return nil
	end
	if type(scriptStateMK.Egg) == "string" then
		return scriptStateMK.Egg
	end
	if type(scriptStateMK.EggName) == "string" then
		return scriptStateMK.EggName
	end
	local scriptStateT = scriptStateMK.Task
	if type(scriptStateT) == "table" then
		if type(scriptStateT.Egg) == "string" then
			return scriptStateT.Egg
		end
		if type(scriptStateT.EggName) == "string" then
			return scriptStateT.EggName
		end
		if type(scriptStateT[1]) == "table" and type(scriptStateT[1].Egg) == "string" then
			return scriptStateT[1].Egg
		end
		if isHatchBountyTask(scriptStateT) then
			return getBountyEggName(scriptStateT)
		end
	end
	if type(scriptStateMK.Tasks) == "table" then
		for loopSlotP, scriptStateBV in pairs(scriptStateMK.Tasks) do
			if type(scriptStateBV) == "table" then
				if type(scriptStateBV.Egg) == "string" then
					return scriptStateBV.Egg
				end
				if type(scriptStateBV.EggName) == "string" then
					return scriptStateBV.EggName
				end
				if type(scriptStateBV.Item) == "table" and type(scriptStateBV.Item.Egg) == "string" then
					return scriptStateBV.Item.Egg
				end
				if
					type(scriptStateBV.Item) == "table"
					and type(scriptStateBV.Item.Name) == "string"
					and isHatchBountyTask(scriptStateBV)
				then
					return scriptStateBV.Item.Name
				end
				if isHatchBountyTask(scriptStateBV) then
					return getBountyEggName(scriptStateBV)
				end
			end
		end
	end
	if type(scriptStateMK.Rewards) == "table" then
		for loopSlotM, rewardItem in ipairs(scriptStateMK.Rewards) do
			if type(rewardItem) == "table" and type(rewardItem.Egg) == "string" then
				return rewardItem.Egg
			end
		end
	end
	if isHatchBountyTask(scriptStateMK) then
		return getBountyEggName(scriptStateMK)
	end
	return nil
end
activeStates.BGSI_Lite_GetPetChanceLookup = function()
	if type(activeStates.BGSI_Lite_PetChanceLookup) == "table" then
		return activeStates.BGSI_Lite_PetChanceLookup
	end
	local chanceLookup = {}
	local function toNumber(value)
		if type(value) == "number" and value == value then
			return value
		end
		if type(value) == "string" then
			return tonumber(value)
		end
		return nil
	end
	local function scanChanceTable(sourceTable, depth, seenTables)
		if depth > 12 or type(sourceTable) ~= "table" or seenTables[sourceTable] then
			return
		end
		seenTables[sourceTable] = true
		local petName = sourceTable.Pet
		local petChance = toNumber(sourceTable.Chance)
		if type(petName) == "string" and petName ~= "" and petChance then
			chanceLookup[petName] = petChance
		end
		if type(sourceTable.Pets) == "table" then
			for _, petEntry in pairs(sourceTable.Pets) do
				if type(petEntry) == "table" then
					local nestedPetName = petEntry.Pet or petEntry.Name
					local nestedPetChance = toNumber(petEntry.Chance)
					if type(nestedPetName) == "string" and nestedPetName ~= "" and nestedPetChance then
						chanceLookup[nestedPetName] = nestedPetChance
					end
				end
			end
		end
		if type(sourceTable.Name) == "string" and (type(petName) ~= "string" or petName == "") and petChance then
			local entryType = sourceTable.Type
			if
				entryType ~= "Powerup"
				and entryType ~= "Potion"
				and entryType ~= "Egg"
				and type(sourceTable.Cost) ~= "table"
			then
				if not (type(sourceTable.Interval) == "number" and type(sourceTable.Pets) == "table") then
					chanceLookup[sourceTable.Name] = petChance
				end
			end
		end
		for _, childValue in pairs(sourceTable) do
			if type(childValue) == "table" then
				scanChanceTable(childValue, depth + 1, seenTables)
			end
		end
	end
	for _, constantsLoader in ipairs({
		function()
			return require(ReplicatedStorage.Shared.Framework.Constants)
		end,
		function()
			return require(ReplicatedStorage.Shared.Constants)
		end,
		function()
			return sharedConstants
		end,
	}) do
		local ok, constantsTable = pcall(constantsLoader)
		if ok and type(constantsTable) == "table" then
			scanChanceTable(constantsTable, 0, {})
		end
	end
	if type(petRarityData) == "table" then
		for petName, petInfo in pairs(petRarityData) do
			if type(petName) == "string" and type(petInfo) == "table" then
				local petChance = toNumber(petInfo.Chance)
				if petChance and chanceLookup[petName] == nil then
					chanceLookup[petName] = petChance
				end
			end
		end
	end
	activeStates.BGSI_Lite_PetChanceLookup = chanceLookup
	return chanceLookup
end
activeStates.BGSI_Lite_ExtractBountyInfo = function(bountyData)
	if type(bountyData) ~= "table" then
		return nil
	end
	local bountyInfo = {
		Egg = getLuckEggPosition(bountyData),
	}
	local function isLikelyPetName(value)
		if type(value) ~= "string" or value == "" then
			return false
		end
		local loweredValue = string.lower(value)
		return loweredValue ~= "egg"
			and loweredValue ~= "eggs"
			and not string.find(loweredValue, " egg", 1, true)
			and not string.find(loweredValue, "quest", 1, true)
			and not string.find(loweredValue, "bounty", 1, true)
	end
	local seenTables = {}
	local function scanBountyValue(value, depth)
		if depth > 8 or type(value) ~= "table" or seenTables[value] then
			return
		end
		seenTables[value] = true
		if type(value.Egg) == "string" and value.Egg ~= "" then
			bountyInfo.Egg = value.Egg
		elseif type(value.EggName) == "string" and value.EggName ~= "" then
			bountyInfo.Egg = value.EggName
		end
		local possiblePetName = value.Pet or value.PetName or value.Name
		if isLikelyPetName(possiblePetName) then
			bountyInfo.Name = bountyInfo.Name or possiblePetName
		end
		if type(value.Item) == "table" then
			local itemName = value.Item.Pet or value.Item.PetName or value.Item.Name
			if isLikelyPetName(itemName) then
				bountyInfo.Name = bountyInfo.Name or itemName
			end
		end
		if bountyInfo.Chance == nil and type(value.Chance) == "number" then
			bountyInfo.Chance = value.Chance
			bountyInfo.ChanceSource = "rawBounty"
		end
		for _, childValue in pairs(value) do
			if type(childValue) == "table" then
				scanBountyValue(childValue, depth + 1)
			end
		end
	end
	scanBountyValue(bountyData, 0)
	local chanceLookup = activeStates.BGSI_Lite_GetPetChanceLookup()
	if type(bountyInfo.Name) == "string" and chanceLookup[bountyInfo.Name] then
		bountyInfo.Chance = chanceLookup[bountyInfo.Name]
		bountyInfo.ChanceSource = "lookup"
	end
	if type(bountyInfo.Egg) ~= "string" or bountyInfo.Egg == "" then
		return nil
	end
	return bountyInfo
end
activeStates.BGSI_Lite_UpdateBountyInfoFromQuest = function()
	if bountyUtil and type(bountyUtil.GetQuest) == "function" and type(bountyUtil.GetSeed) == "function" then
		for _, seedOffset in ipairs({
			0,
			-1,
			1,
		}) do
			local ok, bountyQuest = pcall(function()
				return bountyUtil:GetQuest(bountyUtil:GetSeed() + seedOffset)
			end)
			local bountyInfo = ok and activeStates.BGSI_Lite_ExtractBountyInfo(bountyQuest) or nil
			if type(bountyInfo) == "table" and type(bountyInfo.Egg) == "string" then
				activeStates.BGSI_Lite_LastSecretBounty = bountyInfo
				return bountyInfo.Egg
			end
		end
	end
	local ok, playerData = pcall(function()
		return profileStore:IsReady() and profileStore:Get() or nil
	end)
	if ok and type(playerData) == "table" then
		for _, questKey in ipairs({
			"Bounty",
			"BountyQuest",
			"DailyBounty",
		}) do
			local bountyInfo = activeStates.BGSI_Lite_ExtractBountyInfo(playerData[questKey])
			if type(bountyInfo) == "table" and type(bountyInfo.Egg) == "string" then
				activeStates.BGSI_Lite_LastSecretBounty = bountyInfo
				return bountyInfo.Egg
			end
		end
	end
	return nil
end
activeStates.BGSI_Lite_GetSecretBountyEgg = function(offset)
	local secretBountyUtil = activeStates.BGSI_Lite_SecretBountyUtil
	local getUpvalueFunction = getupvalue or debug and debug.getupvalue
	if type(secretBountyUtil) == "table" and type(secretBountyUtil.Get) == "function" then
		local directResults = table.pack(pcall(function()
			return secretBountyUtil:Get()
		end))
		local directInfo = directResults[1] and activeStates.BGSI_Lite_ExtractBountyInfo(directResults[2]) or nil
		if
			not directInfo
			and directResults[1]
			and type(directResults[2]) == "table"
			and type(directResults[3]) == "string"
		then
			directInfo = activeStates.BGSI_Lite_ExtractBountyInfo({
				Pet = directResults[2].Name or directResults[2].Pet,
				Chance = directResults[2].Chance,
				Egg = directResults[3],
			})
		end
		if type(directInfo) == "table" and type(directInfo.Egg) == "string" then
			activeStates.BGSI_Lite_LastSecretBounty = directInfo
			return directInfo.Egg
		end
	end
	if
		type(secretBountyUtil) ~= "table"
		or type(secretBountyUtil.Get) ~= "function"
		or type(getUpvalueFunction) ~= "function"
	then
		return nil
	end

	local function readUpvalue(upvalueIndex)
		local upvalueResult = table.pack(pcall(getUpvalueFunction, secretBountyUtil.Get, upvalueIndex))
		if not upvalueResult[1] then
			return nil
		end
		if type(upvalueResult[3]) == "table" then
			return upvalueResult[3]
		end
		return upvalueResult[2]
	end

	local pets = readUpvalue(2)
	local possibleEggs = readUpvalue(3)
	if type(pets) ~= "table" or type(possibleEggs) ~= "table" or #pets == 0 or #possibleEggs == 0 then
		return nil
	end

	local secondsInDay = tonumber(timeModule and timeModule.secondsInDay) or 86400
	local currentTime = getCurrentTimestamp()
	local seedOffset = math.floor((tonumber(offset) or 0))
	local bountySeed = (math.floor(currentTime / secondsInDay) - 1) + seedOffset
	local previousRandom = Random.new(bountySeed - 1)
	local currentRandom = Random.new(bountySeed)

	local previousPetIndex = previousRandom:NextInteger(1, #pets)
	local currentPetIndex = currentRandom:NextInteger(1, #pets)
	if currentPetIndex == previousPetIndex then
		currentPetIndex = currentPetIndex % #pets + 1
	end

	local previousEggIndex = previousRandom:NextInteger(1, #possibleEggs)
	local currentEggIndex = currentRandom:NextInteger(1, #possibleEggs)
	if previousEggIndex == currentEggIndex then
		currentEggIndex = currentEggIndex % #possibleEggs + 1
	end

	local bountyPet = pets[currentPetIndex]
	local bountyEgg = possibleEggs[currentEggIndex]
	if type(bountyEgg) ~= "string" or bountyEgg == "" then
		return nil
	end

	activeStates.BGSI_Lite_LastSecretBounty = {
		Name = type(bountyPet) == "table" and bountyPet.Name or nil,
		Chance = type(bountyPet) == "table" and bountyPet.Chance or nil,
		ChanceSource = "rawBounty",
		Egg = bountyEgg,
	}
	local chanceLookup = activeStates.BGSI_Lite_GetPetChanceLookup()
	if
		type(activeStates.BGSI_Lite_LastSecretBounty.Name) == "string"
		and chanceLookup[activeStates.BGSI_Lite_LastSecretBounty.Name]
	then
		activeStates.BGSI_Lite_LastSecretBounty.Chance = chanceLookup[activeStates.BGSI_Lite_LastSecretBounty.Name]
		activeStates.BGSI_Lite_LastSecretBounty.ChanceSource = "lookup"
	end
	return bountyEgg
end
activeStates.BGSI_Lite_FormatBountyChance = function(chanceValue, chanceSource)
	chanceValue = tonumber(chanceValue)
	if not chanceValue or chanceValue <= 0 then
		return "?"
	end
	local function formatCompactChance(numberValue)
		numberValue = tonumber(numberValue) or 0
		for _, suffixInfo in ipairs({
			{ value = 1000000000000, suffix = "t" },
			{ value = 1000000000, suffix = "b" },
			{ value = 1000000, suffix = "m" },
			{ value = 1000, suffix = "k" },
		}) do
			if numberValue >= suffixInfo.value then
				local compactValue = numberValue / suffixInfo.value
				if math.abs(compactValue - math.floor(compactValue + 0.5)) < 0.05 then
					return tostring(math.floor(compactValue + 0.5)) .. suffixInfo.suffix
				end
				return string.format("%.1f", compactValue):gsub("%.0$", "") .. suffixInfo.suffix
			end
		end
		return tostring(math.floor(numberValue + 0.5))
	end
	local oneInChance
	if chanceValue < 1 then
		oneInChance = 1 / chanceValue
	else
		oneInChance = chanceValue
	end
	if chanceSource == "rawBounty" then
		oneInChance = oneInChance * 250
	end
	if oneInChance >= 1 then
		return "1/" .. formatCompactChance(oneInChance)
	end
	return tostring(chanceValue)
end
activeStates.BGSI_Lite_FormatRotationTime = function()
	local secondsInDay = tonumber(timeModule and timeModule.secondsInDay) or 86400
	local currentTime = getCurrentTimestamp()
	local secondsRemaining = math.max(0, math.floor(secondsInDay - (currentTime % secondsInDay)))
	local hoursRemaining = math.floor(secondsRemaining / 3600)
	local minutesRemaining = math.floor((secondsRemaining % 3600) / 60)
	local secondsOnly = secondsRemaining % 60
	if hoursRemaining > 0 then
		return tostring(hoursRemaining) .. "h " .. tostring(minutesRemaining) .. "m"
	end
	if minutesRemaining > 0 then
		return tostring(minutesRemaining) .. "m " .. tostring(secondsOnly) .. "s"
	end
	return tostring(secondsOnly) .. "s"
end
activeStates.BGSI_Lite_GetBountyInfoText = function()
	if not activeStates.BGSI_Lite_GetSecretBountyEgg(0) then
		activeStates.BGSI_Lite_UpdateBountyInfoFromQuest()
	end
	local bountyInfo = activeStates.BGSI_Lite_LastSecretBounty
	if type(bountyInfo) ~= "table" or type(bountyInfo.Egg) ~= "string" then
		return "Loading..."
	end
	local bountyPetName = type(bountyInfo.Name) == "string" and bountyInfo.Name or "Unknown Pet"
	local bountyEggName = bountyInfo.Egg
	local bountyChance = activeStates.BGSI_Lite_FormatBountyChance(bountyInfo.Chance, bountyInfo.ChanceSource)
	return bountyPetName
		.. " is in "
		.. bountyEggName
		.. " ("
		.. bountyChance
		.. ")\nRotates in "
		.. activeStates.BGSI_Lite_FormatRotationTime()
end
activeStates.BGSI_Lite_UpdateBountyInfoParagraph = function()
	if not activeStates.BGSI_Lite_BountyInfoParagraph then
		return
	end
	local bountyInfoText = activeStates.BGSI_Lite_GetBountyInfoText()
	if type(activeStates.BGSI_Lite_BountyInfoParagraph.SetValue) == "function" then
		pcall(function()
			activeStates.BGSI_Lite_BountyInfoParagraph:SetValue(bountyInfoText)
		end)
	end
end
task.spawn(function()
	while isCurrentRun() do
		pcall(activeStates.BGSI_Lite_UpdateBountyInfoParagraph)
		task.wait(1)
	end
end)
scriptStateAAR = false
function stopLuckEggAutomation()
	local secretBountyEgg = activeStates.BGSI_Lite_GetSecretBountyEgg(0)
	if type(secretBountyEgg) == "string" and secretBountyEgg ~= "" then
		return secretBountyEgg
	end
	local questBountyEgg = activeStates.BGSI_Lite_UpdateBountyInfoFromQuest()
	if type(questBountyEgg) == "string" and questBountyEgg ~= "" then
		return questBountyEgg
	end
	if bountyUtil and type(bountyUtil.GetQuest) == "function" and type(bountyUtil.GetSeed) == "function" then
		for loopSlotCK, scriptStateXM in ipairs({
			0,
			-1,
			1,
		}) do
			local loopSlotBO, scriptStateAFE = pcall(function()
				return bountyUtil:GetQuest(bountyUtil:GetSeed() + scriptStateXM)
			end)
			if loopSlotBO then
				local scriptStateEH = getLuckEggPosition(scriptStateAFE)
				if type(scriptStateEH) == "string" and scriptStateEH ~= "" then
					return scriptStateEH
				end
			end
		end
	end
	local scriptStateZZ, questKey = pcall(function()
		return profileStore:IsReady() and profileStore:Get() or nil
	end)
	if scriptStateZZ and type(questKey) == "table" then
		for loopSlotAY, scriptStateSJ in ipairs({
			"Bounty",
			"BountyQuest",
			"DailyBounty",
		}) do
			local eggResult = getLuckEggPosition(questKey[scriptStateSJ])
			if type(eggResult) == "string" and eggResult ~= "" then
				return eggResult
			end
		end
	end
	if not bountyUtil and not scriptStateAAR then
		scriptStateAAR = true
		warn("[1rzHub Lite] BountyUtil module not found - Auto Bounty won't work in this game version.")
	end
	return nil
end
task.spawn(function()
	local scriptStatePN = 0
	while isCurrentRun() do
		task.wait(Config.autoBounty and 0.1 or 0.85)
		if Config.autoBounty ~= true or Config.spawnRift == true
			or activeStates.BGSI_Lite_NormalAutomationPaused == true then
			continue
		end
		if
			isPriorityAutomationActive()
			or activeStates.BGSI_Lite_SpecialRiftActive
			or activeStates.BGSI_Lite_LuckEggActive
			or activeStates.BGSI_Lite_RiftEggActive
			or activeStates.BGSI_Lite_BountyRiftActive
		then
			continue
		end
		local scriptStateCI = stopLuckEggAutomation()
		if not scriptStateCI then
			task.wait(2)
			continue
		end
		local scriptStateST = LocalPlayer and LocalPlayer.Character
		if not scriptStateST or not scriptStateST:FindFirstChild("HumanoidRootPart") then
			continue
		end
		if tick() - scriptStatePN >= 5 then
			pcall(function()
				teleportToEggByName(scriptStateCI)
			end)
			scriptStatePN = tick()
		end
		fireHatchEgg(scriptStateCI)
	end
end)
activeStates.BGSI_Lite_LastBountyRiftSpawnAt = activeStates.BGSI_Lite_LastBountyRiftSpawnAt or 0
activeStates.BGSI_Lite_BountyRiftActive = false
activeStates.BGSI_Lite_BountyRiftReady = false
activeStates.BGSI_Lite_GetRiftsFolder = function()
	local renderedFolder = Workspace:FindFirstChild("Rendered")
	return renderedFolder and renderedFolder:FindFirstChild("Rifts") or nil
end
activeStates.BGSI_Lite_RiftMatchesEgg = function(riftObject, bountyEggName)
	if not riftObject or type(bountyEggName) ~= "string" or bountyEggName == "" then
		return false
	end
	if riftObject:GetAttribute("Type") ~= "Egg" then
		return false
	end
	local wantedEgg = string.lower(bountyEggName)
	local riftInfo = type(riftData) == "table" and riftData[riftObject.Name] or nil
	if
		type(riftInfo) == "table"
		and riftInfo.Type == "Egg"
		and type(riftInfo.Egg) == "string"
		and string.lower(riftInfo.Egg) == wantedEgg
	then
		return true
	end
	for _, attributeName in ipairs({
		"Egg",
		"EggName",
	}) do
		local attributeValue = riftObject:GetAttribute(attributeName)
		if type(attributeValue) == "string" and string.lower(attributeValue) == wantedEgg then
			return true
		end
	end
	return false
end
activeStates.BGSI_Lite_FindNewSpawnedBountyRift = function(bountyEggName, riftsBefore)
	local riftsFolder = activeStates.BGSI_Lite_GetRiftsFolder()
	if not riftsFolder then
		return nil
	end
	riftsBefore = type(riftsBefore) == "table" and riftsBefore or {}
	for _, riftObject in ipairs(riftsFolder:GetChildren()) do
		if
			not riftsBefore[riftObject]
			and activeStates.BGSI_Lite_RiftMatchesEgg(riftObject, bountyEggName)
		then
			return riftObject
		end
	end
	-- Never accept an unrelated newly-rendered rift. Another player's summon,
	-- a random world rift, or a delayed render can otherwise make Auto Bounty
	-- lock onto the wrong rift.
	return nil
end
activeStates.BGSI_Lite_RememberBountyRift = function(riftObject, bountyEggName)
	if not riftObject then
		return nil
	end
	activeStates.BGSI_Lite_SpawnedBountyRiftObject = riftObject
	activeStates.BGSI_Lite_SpawnedBountyRiftEgg = bountyEggName
	activeStates.BGSI_Lite_SpawnedBountyRiftName = riftObject.Name
	return riftObject
end
activeStates.BGSI_Lite_GetBountyRiftObject = function(bountyEggName)
	if type(bountyEggName) ~= "string" or bountyEggName == "" then
		return nil
	end
	local riftsFolder = activeStates.BGSI_Lite_GetRiftsFolder()
	if not riftsFolder then
		return nil
	end
	local spawnedRiftObject = activeStates.BGSI_Lite_SpawnedBountyRiftObject
	if
		spawnedRiftObject
		and spawnedRiftObject.Parent
		and spawnedRiftObject:IsDescendantOf(riftsFolder)
		and activeStates.BGSI_Lite_SpawnedBountyRiftEgg == bountyEggName
		and (tonumber(spawnedRiftObject:GetAttribute("DespawnAt")) or math.huge) > getCurrentTimestamp()
	then
		return spawnedRiftObject
	end
	activeStates.BGSI_Lite_SpawnedBountyRiftObject = nil
	activeStates.BGSI_Lite_SpawnedBountyRiftName = nil
	-- Reuse a live 25x bounty rift after a script reload instead of paying
	-- for another summon. The game stores luck on the rendered rift.
	for _, riftObject in ipairs(riftsFolder:GetChildren()) do
		if activeStates.BGSI_Lite_RiftMatchesEgg(riftObject, bountyEggName)
			and (tonumber(riftObject:GetAttribute("DespawnAt")) or math.huge) > getCurrentTimestamp() then
			local luck = tonumber(riftObject:GetAttribute("BonusLuck")) or 0
			for _, descendant in ipairs(riftObject:GetDescendants()) do
				luck = math.max(luck, tonumber(descendant:GetAttribute("BonusLuck")) or 0)
			end
			if luck >= 25 then
				return activeStates.BGSI_Lite_RememberBountyRift(riftObject, bountyEggName)
			end
		end
	end
	return nil
end
activeStates.BGSI_Lite_GetObjectCFrame = function(riftObject)
	if not riftObject then
		return nil
	end
	local pivotSuccess, objectCFrame = pcall(function()
		return riftObject:GetPivot()
	end)
	if pivotSuccess and typeof(objectCFrame) == "CFrame" then
		return objectCFrame
	end
	local objectPart = riftObject:IsA("BasePart") and riftObject or riftObject:FindFirstChildWhichIsA("BasePart", true)
	return objectPart and objectPart.CFrame or nil
end
activeStates.BGSI_Lite_SummonBountyRift = function(forceSpawn)
	local bountyEggName = stopLuckEggAutomation()
	if type(bountyEggName) ~= "string" or bountyEggName == "" then
		return false, "no-bounty"
	end

	local existingSpawnedRift = activeStates.BGSI_Lite_GetBountyRiftObject(bountyEggName)
	if existingSpawnedRift then
		activeStates.BGSI_Lite_LastBountyRiftEgg = bountyEggName
		return true, "already-exists"
	end

	if
		forceSpawn ~= true
		and tick() - (tonumber(activeStates.BGSI_Lite_LastBountyRiftSpawnAt) or 0) < 30
	then
		return false, "cooldown"
	end

	local riftsFolder = activeStates.BGSI_Lite_GetRiftsFolder()
	if not riftsFolder then
		return false, "rifts-not-loaded"
	end
	local riftsBefore = {}
	for _, riftObject in ipairs(riftsFolder:GetChildren()) do
		riftsBefore[riftObject] = true
	end

	-- The summon menu only offers eggs in its selected world. Resolve the
	-- bounty egg through that same game data, then move there before invoking.
	local bountyWorld, worldUtil
	local dataOk, dataError = pcall(function()
		local summonCosts = require(ReplicatedStorage.Shared.Data.RiftSummonCosts)
		worldUtil = require(ReplicatedStorage.Shared.Utils.WorldUtil)
		for worldName, eggsInWorld in pairs(summonCosts.Eggs) do
			if type(eggsInWorld) == "table" and eggsInWorld[bountyEggName] ~= nil then
				bountyWorld = worldName
				break
			end
		end
	end)
	if not dataOk or not bountyWorld then
		warn("[1rzHub Lite] Bounty egg is not summonable: " .. tostring(bountyEggName)
			.. " | " .. tostring(dataError or "missing from RiftSummonCosts"))
		return false, "egg-not-summonable"
	end
	local currentWorld
	pcall(function()
		currentWorld = worldUtil:GetPlayerWorld(LocalPlayer)
	end)
	if currentWorld ~= bountyWorld then
		if not teleportToEggByName(bountyEggName) then
			return false, "egg-world-not-reached"
		end
		local worldDeadline = tick() + 3
		repeat
			task.wait(0.2)
			pcall(function()
				currentWorld = worldUtil:GetPlayerWorld(LocalPlayer)
			end)
		until currentWorld == bountyWorld or tick() >= worldDeadline
		if currentWorld ~= bountyWorld then
			return false, "egg-world-not-reached"
		end
	end

	-- InvokeServer returns (success, error/status). A successful pcall only
	-- means the remote call itself did not throw; it does NOT mean the summon
	-- was accepted by the server.
	local invokeOk, summonSuccess, summonError = pcall(function()
		return remoteFunction:InvokeServer("SummonRift", {
			Type = "Egg",
			World = bountyWorld,
			Name = bountyEggName,
			Time = 5,
			Luck = 5,
		})
	end)

	if not invokeOk then
		warn("[1rzHub Lite] Bounty Rift summon threw an error: " .. tostring(summonSuccess))
		return false, "invoke-error"
	end

	if summonSuccess ~= true then
		warn(
			"[1rzHub Lite] Bounty Rift summon rejected: "
			.. tostring(summonError or "unknown")
			.. " | egg="
			.. tostring(bountyEggName)
			.. " | world="
			.. tostring(bountyWorld)
		)
		return false, tostring(summonError or "summon-rejected")
	end

	activeStates.BGSI_Lite_LastBountyRiftSpawnAt = tick()
	activeStates.BGSI_Lite_LastBountyRiftEgg = bountyEggName

	local spawnedRift
	local spawnDeadline = tick() + 6
	repeat
		spawnedRift =
			activeStates.BGSI_Lite_FindNewSpawnedBountyRift(
				bountyEggName,
				riftsBefore
			)
		if spawnedRift then
			break
		end
		task.wait(0.25)
	until tick() >= spawnDeadline

	if not spawnedRift then
		warn(
			"[1rzHub Lite] Summon succeeded for "
			.. tostring(bountyEggName)
			.. " but no matching new rift rendered within 6 seconds."
		)
		return false, "rift-not-found"
	end

	activeStates.BGSI_Lite_RememberBountyRift(spawnedRift, bountyEggName)
	return true, "spawned"
end
task.spawn(function()
	local bountyRiftTeleportAt = 0
	while isCurrentRun() do
		task.wait(Config.spawnRift and 1 or 2)
		if not Config.spawnRift then
			activeStates.BGSI_Lite_BountyRiftActive = false
			activeStates.BGSI_Lite_BountyRiftReady = false
			continue
		end
		if activeStates.BGSI_Lite_NormalAutomationPaused == true
			or isPriorityAutomationActive() then
			activeStates.BGSI_Lite_BountyRiftActive = false
			activeStates.BGSI_Lite_BountyRiftReady = false
			continue
		end
		local bountyEggName = stopLuckEggAutomation()
		local bountyRiftObject = activeStates.BGSI_Lite_GetBountyRiftObject(bountyEggName)
		if bountyRiftObject then
			activeStates.BGSI_Lite_BountyRiftActive = true
			activeStates.BGSI_Lite_LastBountyRiftEgg = bountyEggName
			if tick() - bountyRiftTeleportAt >= 5 then
				local bountyRiftCFrame = activeStates.BGSI_Lite_GetRiftTargetCFrame(bountyRiftObject)
				if bountyRiftCFrame then
					activeStates.BGSI_Lite_BountyRiftReady = teleportToCFrame(
						bountyRiftCFrame + Vector3.new(0, 3, 0)
					) == true
				end
				bountyRiftTeleportAt = tick()
			end
			if activeStates.BGSI_Lite_BountyRiftReady then
				fireHatchEgg(bountyEggName)
			end
		else
			activeStates.BGSI_Lite_BountyRiftActive = bountyEggName ~= nil
			activeStates.BGSI_Lite_BountyRiftReady = false
			activeStates.BGSI_Lite_SummonBountyRift(false)
		end
	end
end)
end,
function(...)
task.spawn(function()
	while isCurrentRun() do
		if Config.autoHalloweenChest and Config.safeMode ~= true then
			pcall(function()
				local playerData = profileStore:IsReady() and profileStore:Get() or nil
				local cooldowns = type(playerData) == "table" and playerData.Cooldowns
				local nextClaim = type(cooldowns) == "table" and tonumber(cooldowns["Halloween Chest"])
				if nextClaim and getCurrentTimestamp() >= nextClaim then
					remoteEvent:FireServer("ClaimChest", "Halloween Chest")
				end
			end)
		end
		task.wait(5)
	end
end)
task.spawn(function()
	local markers = Workspace:WaitForChild("Markers", 600)
	local presentMarkers = markers and markers:WaitForChild("PresentRain", 600)
	if not presentMarkers then return end
	local lastAttempt = {}
	while isCurrentRun() do
		if Config.autoCollectPresentRain and Config.safeMode ~= true then
			for _, marker in ipairs(presentMarkers:GetChildren()) do
				if not Config.autoCollectPresentRain then break end
				if tick() - (lastAttempt[marker] or 0) >= 1.5 then
					local target = marker:GetAttribute("Target")
					local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
					if typeof(target) == "CFrame" and root then
						lastAttempt[marker] = tick()
						local previous = root.CFrame
						root.CFrame = target * CFrame.new(0, 2, 0)
						task.wait(0.15)
						pcall(remoteEvent.FireServer, remoteEvent, "CollectPresentRain", marker.Name)
						task.wait(0.15)
						if root.Parent then root.CFrame = previous end
					end
				end
			end
		end
		for marker in pairs(lastAttempt) do
			if marker.Parent ~= presentMarkers then lastAttempt[marker] = nil end
		end
		task.wait(0.5)
	end
end)
function getSelectedChestName()
	local loopSlotBX, scriptStateBS = pcall(function()
		return profileStore:IsReady() and profileStore:Get() or nil
	end)
	return loopSlotBX and type(scriptStateBS) == "table" and scriptStateBS or nil
end
function fireRemoteEventRepeatedly(scriptStateQA, scriptStateKI)
	if not scriptStateQA then
		return
	end
	if scriptStateQA.SetValues then
		scriptStateQA:SetValues(scriptStateKI)
	elseif scriptStateQA.Refresh then
		scriptStateQA:Refresh(scriptStateKI, false)
	end
end
function getPotionList(scriptStateCU)
	local scriptStateRZ = Workspace:FindFirstChild("Rendered")
	return scriptStateRZ and scriptStateRZ:FindFirstChild(scriptStateCU) or nil
end
function getPotionDisplayName(scriptStateABT)
	return activeStates.BGSI_Lite_GetRiftTargetCFrame(scriptStateABT)
end
end,
function(...)
function normalizeEnchantName(scriptStateTX)
	if type(scriptStateTX) ~= "string" then
		return ""
	end
	return string.lower(scriptStateTX):gsub("[%s_%-]", "")
end
function getPetEnchantList(scriptStateHJ)
	local scriptStateRI = {}
	local function addEnchantValue(scriptStateYE)
		if type(scriptStateYE) == "string" and scriptStateYE ~= "" then
			table.insert(scriptStateRI, scriptStateYE)
		elseif type(scriptStateYE) == "table" then
			local scriptStateKR = scriptStateYE.id
				or scriptStateYE.Id
				or scriptStateYE.ID
				or scriptStateYE.Name
				or scriptStateYE.name
				or scriptStateYE.Enchant
				or scriptStateYE.enchant
				or ""
			if scriptStateKR and scriptStateKR ~= "" then
				table.insert(scriptStateRI, tostring(scriptStateKR))
			end
		end
	end
	if type(scriptStateHJ) ~= "table" then
		return scriptStateRI
	end
	for _, containerKey in ipairs({ "Enchants", "Enchantments" }) do
		local enchantContainer = scriptStateHJ[containerKey]
		if type(enchantContainer) == "table" then
			for enchantKey, enchantValue in pairs(enchantContainer) do
				if type(enchantKey) == "string" and enchantValue == true then
					addEnchantValue(enchantKey)
				elseif type(enchantValue) == "table" or type(enchantValue) == "string" then
					addEnchantValue(enchantValue)
				end
			end
		elseif type(enchantContainer) == "string" then
			addEnchantValue(enchantContainer)
		end
	end
	addEnchantValue(scriptStateHJ.Enchant)
	addEnchantValue(scriptStateHJ.Enchantment)
	addEnchantValue(scriptStateHJ.Blessing)
	return scriptStateRI
end
SUPER_LEGENDARY_ENCHANT_KEY_BY_ID = {
	["super-luck"] = "luck-boost",
	["super-luck-plus"] = "luck-boost-plus",
	["super-burst"] = "burst-blessing",
	["super-burst-plus"] = "burst-blessing-plus",
	["super-shiny"] = "shiny-blessing",
	["super-shiny-plus"] = "shiny-blessing-plus",
	["super-speed"] = "hatch-blessing",
	["super-speed-plus"] = "hatch-blessing-plus",
	["super-bubble"] = "bubble-machine",
	["super-bubble-plus"] = "bubble-machine-plus",
	["super-mythic"] = "mythic-blessing",
	["super-mythic-plus"] = "mythic-blessing-plus",
	["super-infinity"] = "infinity-blessing",
	["super-infinity-plus"] = "infinity-blessing-plus",
	["super-duplication"] = "duplication",
	["super-duplication-plus"] = "duplication-plus",
}
function getAutoTeamSuperEnchantKey(enchantEntry)
	local enchantId = type(enchantEntry) == "table" and (enchantEntry.Id or enchantEntry.id) or enchantEntry
	return SUPER_LEGENDARY_ENCHANT_KEY_BY_ID[tostring(enchantId or "")]
end
function getAutoTeamLimits(playerData)
	local maxPetsEquipped = 13
	local maxSupersEquipped = math.clamp(
		math.floor(tonumber(sharedConstants and sharedConstants.MaxSupersEquipped) or 3), 0, 3
	)
	pcall(function()
		local statsModule = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
		maxPetsEquipped = math.max(1, math.floor(tonumber(statsModule:GetMaxPetsEquipped(playerData)) or 13))
	end)
	return maxPetsEquipped, maxSupersEquipped
end
function petHasAutoTeamTargetEnchants(pet)
	local targetOne = normalizeEnchantName(Config.equippedTargetEnchant or "secret-hunter")
	if targetOne == "" then
		return false
	end
	local targetTwo = normalizeEnchantName(Config.equippedTargetEnchant2 or "")
	if targetTwo == normalizeEnchantName("(None - single target)") then
		targetTwo = ""
	end
	local seenEnchantIds = {}
	for _, enchantEntry in ipairs(getPetEnchantList(pet)) do
		local enchantId = normalizeEnchantName(
			type(enchantEntry) == "table" and (enchantEntry.Id or enchantEntry.id) or enchantEntry
		)
		if enchantId ~= "" then
			seenEnchantIds[enchantId] = true
		end
	end
	if targetTwo == "" then
		return seenEnchantIds[targetOne] == true
	end
	return seenEnchantIds[targetOne] == true and seenEnchantIds[targetTwo] == true
end
function buildAutoTeamShinyRanking(playerData)
	local candidates = {}
	for _, pet in ipairs(type(playerData) == "table" and playerData.Pets or {}) do
		if activeStates.BGSI_Lite_IsShinyEnchantPet(pet) then
			local petInfo = type(petRarityData) == "table" and petRarityData[pet.Name] or nil
			local rarity = activeStates.BGSI_Lite_ResolvePetRarity(pet, petInfo)
			local rarityRank = rarity == "Celestial" and 0 or 1
			local enchantRank = petHasAutoTeamTargetEnchants(pet) and 0 or 1
			table.insert(candidates, {
				pet = pet,
				rank = rarityRank * 2 + enchantRank,
			})
		end
	end
	table.sort(candidates, function(candidateA, candidateB)
		if candidateA.rank ~= candidateB.rank then
			return candidateA.rank < candidateB.rank
		end
		return tostring(candidateA.pet.Id) < tostring(candidateB.pet.Id)
	end)
	return candidates
end
function buildAutoSetupTeamSelection(playerData)
	if type(playerData) ~= "table" or type(playerData.Pets) ~= "table" then
		return nil
	end
	local maxPetsEquipped, maxSupersEquipped = getAutoTeamLimits(playerData)
	local selectedPetIds = {}
	local selectedSet = {}
	local aaBlessingMode = Config.autoSetupTeamAABlessingSupers == true
		and activeStates.BGSI_Lite_LuckEggActive == true

	if Config.autoSetupTeamIncludeSupers or aaBlessingMode then
		local superCounts = type(Config.autoSetupTeamSuperCounts) == "table" and Config.autoSetupTeamSuperCounts or {}
		local candidatesByEnchantKey = {}
		local currentlyEquipped = {}
		local equippedTeam = type(playerData.Teams) == "table" and playerData.Teams[playerData.TeamEquipped] or nil
		for _, petId in ipairs(type(equippedTeam) == "table" and equippedTeam.Pets or {}) do
			currentlyEquipped[tostring(petId)] = true
		end
		for _, pet in ipairs(playerData.Pets) do
			local petInfo = type(petRarityData) == "table" and petRarityData[pet.Name] or nil
			local rarity = activeStates.BGSI_Lite_ResolvePetRarity(pet, petInfo)
			local isSuperLegendary = activeStates.BGSI_Lite_GetHatchPetFlag(pet, "Super") == true
				or activeStates.BGSI_Lite_GetHatchPetFlag(pet, "SuperLegendary") == true
				or rarity == "Super"
				or rarity == "Super Legendary"
			if isSuperLegendary then
				for _, enchantEntry in ipairs(getPetEnchantList(pet)) do
					local enchantKey = getAutoTeamSuperEnchantKey(enchantEntry)
					local wantedForCurrentEgg = aaBlessingMode
						and (enchantKey == "hatch-blessing-plus" or enchantKey == "hatch-blessing"
							or enchantKey == "luck-boost-plus" or enchantKey == "luck-boost")
						or (not aaBlessingMode and (tonumber(superCounts[enchantKey]) or 0) > 0)
					if enchantKey and wantedForCurrentEgg then
						candidatesByEnchantKey[enchantKey] = candidatesByEnchantKey[enchantKey] or {}
						table.insert(candidatesByEnchantKey[enchantKey], pet)
					end
				end
			end
		end
		local normalPriority = {
			"luck-boost", "luck-boost-plus", "hatch-blessing", "hatch-blessing-plus",
			"bubble-machine", "bubble-machine-plus", "burst-blessing", "burst-blessing-plus",
			"shiny-blessing", "shiny-blessing-plus", "mythic-blessing", "mythic-blessing-plus",
			"infinity-blessing", "infinity-blessing-plus", "duplication", "duplication-plus",
		}
		local priority = normalPriority
		if aaBlessingMode then
			local hasHatchBlessing = #(candidatesByEnchantKey["hatch-blessing-plus"] or {}) > 0
				or #(candidatesByEnchantKey["hatch-blessing"] or {}) > 0
			priority = hasHatchBlessing
				and { "hatch-blessing-plus", "hatch-blessing" }
				or { "luck-boost-plus", "luck-boost" }
		end
		for _, enchantKey in ipairs(priority) do
			local desiredCount = aaBlessingMode and maxSupersEquipped or superCounts[enchantKey]
			desiredCount = math.min(math.max(0, math.floor(tonumber(desiredCount) or 0)), maxSupersEquipped)
			local candidates = candidatesByEnchantKey[enchantKey] or {}
			table.sort(candidates, function(petA, petB)
				local equippedA, equippedB = currentlyEquipped[tostring(petA.Id)] == true,
					currentlyEquipped[tostring(petB.Id)] == true
				if equippedA ~= equippedB then return equippedA end
				return tostring(petA.Id) < tostring(petB.Id)
			end)
			local addedForKey = 0
			for _, candidate in ipairs(candidates) do
				if #selectedPetIds >= maxPetsEquipped or #selectedPetIds >= maxSupersEquipped then
					break
				end
				if addedForKey >= desiredCount then break end
				local petId = tostring(candidate.Id or "")
				if petId ~= "" and not selectedSet[petId] then
					selectedSet[petId] = true
					table.insert(selectedPetIds, petId)
					addedForKey += 1
				end
			end
		end
	end

	for _, candidate in ipairs(buildAutoTeamShinyRanking(playerData)) do
		if #selectedPetIds >= maxPetsEquipped then
			break
		end
		local petId = tostring(candidate.pet.Id or "")
		if petId ~= "" and not selectedSet[petId] then
			selectedSet[petId] = true
			table.insert(selectedPetIds, petId)
		end
	end

	if #selectedPetIds == 0 then
		return nil
	end
	return selectedPetIds
end
function isEquippedTeamNamedHatch()
	local ok, playerData = pcall(function()
		return profileStore:IsReady() and profileStore:Get() or nil
	end)
	if not ok or type(playerData) ~= "table" or type(playerData.Teams) ~= "table" or playerData.TeamEquipped == nil then
		return false
	end
	local team = playerData.Teams[playerData.TeamEquipped]
	local teamName = type(team) == "table" and (team.Name or team.TeamName) or nil
	return type(teamName) == "string" and teamName:lower():match("^%s*(.-)%s*$") == "hatch"
end
activeStates.BGSI_Lite_IsEquippedTeamNamedHatch = isEquippedTeamNamedHatch
function applyAutoSetupTeamSelection(selectedPetIds)
	if not isEquippedTeamNamedHatch() then
		return false
	end
	local selectedSet = {}
	for _, petId in ipairs(selectedPetIds) do
		selectedSet[tostring(petId)] = true
	end

	local function teamMatchesSelection(currentPetIds)
		if #currentPetIds ~= #selectedPetIds then
			return false
		end
		local currentSet = {}
		for _, petId in ipairs(currentPetIds) do
			currentSet[tostring(petId)] = true
		end
		for petId in pairs(selectedSet) do
			if not currentSet[petId] then
				return false
			end
		end
		return true
	end

	local function fireOneCorrectionPass()
		-- Unequip everything unwanted first, and confirm the team actually shrank before
		-- doing anything else - this is what keeps every later EquipPet from getting
		-- rejected by the game's own max-pets check.
		local currentPetIds = getEnchantablePets()
		local startingCount = #currentPetIds
		for _, petId in ipairs(currentPetIds) do
			if not selectedSet[tostring(petId)] then
				remoteEvent:FireServer("UnequipPet", tostring(petId))
				local confirmDeadline = tick() + 2
				repeat
					task.wait(0.1)
					currentPetIds = getEnchantablePets()
				until #currentPetIds < startingCount or tick() >= confirmDeadline
				startingCount = #currentPetIds
			end
		end

		local currentSet = {}
		for _, petId in ipairs(currentPetIds) do
			currentSet[tostring(petId)] = true
		end
		for _, petId in ipairs(selectedPetIds) do
			if not currentSet[tostring(petId)] then
				remoteEvent:FireServer("EquipPet", tostring(petId))
				task.wait(0.15)
			end
		end
	end

	local changed = false
	local deadline = tick() + 20
	for _ = 1, 8 do
		local currentPetIds = getEnchantablePets()
		if teamMatchesSelection(currentPetIds) then
			return changed
		end
		fireOneCorrectionPass()
		changed = true
		task.wait(0.3)
		if tick() >= deadline then
			break
		end
	end
	return changed
end
activeStates.BGSI_Lite_RunAutoSetupTeam = function()
	if Config.safeMode == true then
		return false
	end
	-- Only ever touch pets while the player is actually on the team named "Hatch" -
	-- Leaves (or anything else currently equipped) is left alone entirely.
	if not isEquippedTeamNamedHatch() then
		return false
	end
	if activeStates.BGSI_Lite_AutoSetupTeamApplying then
		return false
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	local selectedPetIds = buildAutoSetupTeamSelection(playerData)
	if not selectedPetIds then
		return false
	end
	activeStates.BGSI_Lite_AutoSetupTeamApplying = true
	local ok, applyError = pcall(applyAutoSetupTeamSelection, selectedPetIds)
	activeStates.BGSI_Lite_AutoSetupTeamApplying = false
	if not ok then error(applyError) end
	return true
end
autoSetupTeamConfigGeneration = 0
autoSetupTeamApplyQueued = false
activeStates.BGSI_Lite_AutoSetupTeamApplying = false
activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh = function()
	autoSetupTeamConfigGeneration += 1
	local requestedGeneration = autoSetupTeamConfigGeneration
	if autoSetupTeamApplyQueued then
		return
	end
	autoSetupTeamApplyQueued = true
	task.spawn(function()
		task.wait(0.1)
		while
			isCurrentRun()
			and Config.autoSetupTeamEnabled == true
			and Config.safeMode ~= true
			and isEquippedTeamNamedHatch()
		do
			if activeStates.BGSI_Lite_AutoSetupTeamApplying then
				task.wait(0.2)
			else
				local generationAtStart = autoSetupTeamConfigGeneration
				pcall(activeStates.BGSI_Lite_RunAutoSetupTeam)
				if generationAtStart == autoSetupTeamConfigGeneration and requestedGeneration == generationAtStart then
					break
				end
				requestedGeneration = autoSetupTeamConfigGeneration
				task.wait(0.1)
			end
		end
		autoSetupTeamApplyQueued = false
	end)
end
pcall(function()
	profileStore:ConnectDataChanged("Pets", function()
		if isCurrentRun() and Config.autoSetupTeamEnabled == true
			and (Config.autoSetupTeamIncludeSupers == true
				or Config.autoSetupTeamAABlessingSupers == true)
			and Config.safeMode ~= true
			and isEquippedTeamNamedHatch() then
			activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh()
		end
	end)
end)
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.autoSetupTeamEnabled and 2 or 1)
		if
			Config.autoSetupTeamEnabled
			and Config.safeMode ~= true
			and isEquippedTeamNamedHatch()
		then
			pcall(activeStates.BGSI_Lite_RunAutoSetupTeam)
		end
	end
end)
CURRENCY_TEAM_KEYWORDS = {
	{ category = "tickets", keyword = "ticket" },
	{ category = "pearls", keyword = "pearl" },
	{ category = "gems", keyword = "gem" },
	{ category = "coins", keyword = "coin" },
	{ category = "bubble", keyword = "bubble" },
	{ category = "hatch", keyword = "hatch" },
}
CURRENCY_STAT_KEY_BY_CATEGORY = {
	tickets = "Tickets",
	pearls = "Pearls",
	gems = "Gems",
	coins = "Coins",
	bubble = "Bubbles",
}
activeStates.BGSI_Lite_DetectCurrencyTeamKeys = function(playerData)
	local detected = {}
	if type(playerData) ~= "table" or type(playerData.Teams) ~= "table" then
		return detected
	end
	for teamKey, team in pairs(playerData.Teams) do
		local teamName = type(team) == "table" and tostring(team.Name or team.TeamName or teamKey)
			or tostring(teamKey)
		local lowerName = teamName:lower()
		for _, entry in ipairs(CURRENCY_TEAM_KEYWORDS) do
			if not detected[entry.category] and lowerName:find(entry.keyword, 1, true) then
				detected[entry.category] = teamKey
			end
		end
	end
	return detected
end
activeStates.BGSI_Lite_GetBestPetIdsForCurrency = function(playerData, category, slotLimit)
	if category == "hatch" then
		return buildAutoSetupTeamSelection(playerData)
	end
	local statKey = CURRENCY_STAT_KEY_BY_CATEGORY[category]
	if not statKey or type(playerData) ~= "table" or type(playerData.Pets) ~= "table" then
		return nil
	end
	local ranked = {}
	for _, pet in ipairs(playerData.Pets) do
		if type(pet) == "table" and pet.Id then
			local petInfo = type(petRarityData) == "table" and petRarityData[pet.Name] or nil
			local statValue = type(petInfo) == "table"
				and type(petInfo.Stats) == "table"
				and tonumber(petInfo.Stats[statKey])
			if statValue then
				table.insert(ranked, { id = tostring(pet.Id), value = statValue })
			end
		end
	end
	if #ranked == 0 then
		return nil
	end
	table.sort(ranked, function(leftPet, rightPet)
		return leftPet.value > rightPet.value
	end)
	local maxPetsEquipped = select(1, getAutoTeamLimits(playerData))
	local limit = math.min(tonumber(slotLimit) or maxPetsEquipped, maxPetsEquipped, #ranked)
	local selected = {}
	for i = 1, limit do
		table.insert(selected, ranked[i].id)
	end
	return selected
end
activeStates.BGSI_Lite_ApplyCurrencyTeam = function(category)
	if Config.autoCurrencyTeams ~= true or Config.safeMode == true then
		return false
	end
	-- "hatch" isn't a real currency - it's Auto Setup Team's own selection (or a
	-- saved team literally named "hatch") equipped through this second entry point.
	-- Auto Currency Teams being on for tickets/pearls/etc. said nothing about wanting
	-- that, so it stayed on and kept re-equipping a hatch team even with Auto Setup
	-- Team switched off. Auto Setup Team's own toggle is the only thing that should
	-- decide whether anything touches the hatch team.
	if category == "hatch" and Config.autoSetupTeamEnabled ~= true then
		return false
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" then
		return false
	end
	-- "hatch" never switches teams, even to a saved team that happens to be named
	-- "hatch" - the only thing that ever changes what team is equipped is the player.
	-- This only ever adjusts pets within the team already equipped, and only when
	-- that team is named "Hatch" (checked inside applyAutoSetupTeamSelection below).
	if category ~= "hatch" then
		local detected = activeStates.BGSI_Lite_DetectCurrencyTeamKeys(playerData)
		local teamKey = detected[category]
		if teamKey and type(activeStates.BGSI_Lite_EquipPetTeamByKey) == "function" then
			if activeStates.BGSI_Lite_EquipPetTeamByKey(teamKey) then
				return true
			end
		end
	end
	local bestPetIds = activeStates.BGSI_Lite_GetBestPetIdsForCurrency(playerData, category)
	if not bestPetIds or #bestPetIds == 0 then
		return false
	end
	return applyAutoSetupTeamSelection(bestPetIds)
end
end,
function(...)
function findPetEnchantSlot(scriptStateKS, scriptStateAY)
	if not scriptStateAY or scriptStateAY == "" or scriptStateAY == "(None - single target)" then
		return nil
	end
	local scriptStateRS = normalizeEnchantName(scriptStateAY)
	local scriptStateBH = scriptStateKS and (scriptStateKS.Enchants or scriptStateKS.Enchantments) or {}
	for loopSlotW = 1, 2 do
		local enchantEntry = scriptStateBH[loopSlotW] or scriptStateBH[tostring(loopSlotW)]
		local enchantId = type(enchantEntry) == "table"
			and (enchantEntry.Id or enchantEntry.id or enchantEntry.ID or enchantEntry.Name)
			or enchantEntry
		if normalizeEnchantName(enchantId) == scriptStateRS then
			return loopSlotW
		end
	end
	local scriptStateIU = getPetEnchantList(scriptStateKS)
	for loopSlotW = 1, 2 do
		if scriptStateIU[loopSlotW] and normalizeEnchantName(scriptStateIU[loopSlotW]) == scriptStateRS then
			return loopSlotW
		end
	end
	return nil
end
function getEnchantData(scriptStateABA)
	if not scriptStateABA or scriptStateABA == "" or type(enchantData) ~= "table" then
		return nil
	end
	local scriptStateOP = enchantData[scriptStateABA]
	if scriptStateOP then
		return scriptStateOP
	end
	local scriptStateYC = normalizeEnchantName(scriptStateABA)
	for loopSlotDY, scriptStateO in pairs(enchantData) do
		if
			type(loopSlotDY) == "string"
			and type(scriptStateO) == "table"
			and normalizeEnchantName(loopSlotDY) == scriptStateYC
		then
			return scriptStateO
		end
	end
	return nil
end
specialWebhookEnchantNames = {
	shinyblessing = "Shiny Blessing",
	infinityblessing = "Infinity Blessing",
	mythicblessing = "Mythic Blessing",
	burstblessing = "Burst Blessing",
	bubblemachine = "Bubble Machine",
	duplication = "Duplication",
	hatchblessing = "Hatch Blessing",
	luckboost = "Luck Boost",
}
function getWebhookEnchantDisplayName(enchantName)
	local enchantLevel = nil
	if type(enchantName) == "table" then
		enchantLevel = enchantName.Level or enchantName.level
		enchantName = enchantName.Id or enchantName.id or enchantName.ID or ""
	end
	if type(enchantName) ~= "string" or enchantName == "" then
		return nil
	end
	if enchantModule and type(enchantModule.GetFullTitle) == "function" then
		local ok, title = pcall(function()
			return enchantModule:GetFullTitle(enchantName, enchantLevel)
		end)
		if ok and type(title) == "string" and title ~= "" then
			return title
		end
	end
	local normalizedName = normalizeEnchantName(enchantName)
	if specialWebhookEnchantNames[normalizedName] then
		return specialWebhookEnchantNames[normalizedName]
	end
	local enchantInfo = getEnchantData(enchantName)
	if type(enchantInfo) == "table" then
		for _, displayKey in ipairs({
			"DisplayName",
			"Name",
			"Title",
		}) do
			if type(enchantInfo[displayKey]) == "string" and enchantInfo[displayKey] ~= "" then
				return enchantInfo[displayKey]
			end
		end
	end
	local spacedName = tostring(enchantName):gsub("([a-z])([A-Z])", "%1 %2"):gsub("[_%-]+", " ")
	return spacedName:gsub("(%a)([%w']*)", function(firstLetter, rest)
		return firstLetter:upper() .. rest:lower()
	end)
end
function getSuperLegendaryWebhookEnchantList(petData)
	local enchantNames = {}
	local seenEnchants = {}
	if type(petData) ~= "table" then
		return enchantNames
	end
	local function addEnchantEntry(enchantEntry, fallbackId)
		local enchantId
		local enchantLevel
		if type(enchantEntry) == "table" then
			enchantId = enchantEntry.Id
				or enchantEntry.id
				or enchantEntry.ID
				or enchantEntry.Name
				or enchantEntry.name
				or enchantEntry.Enchant
				or enchantEntry.enchant
			enchantLevel = enchantEntry.Level or enchantEntry.level
		elseif type(enchantEntry) == "string" then
			enchantId = enchantEntry
		elseif type(fallbackId) == "string" and (enchantEntry == true or type(enchantEntry) == "number") then
			enchantId = fallbackId
			enchantLevel = type(enchantEntry) == "number" and enchantEntry or nil
		end
		enchantId = enchantId or fallbackId
		local enchantKey = tostring(enchantId or "") .. ":" .. tostring(enchantLevel or "")
		if type(enchantId) == "string" and enchantId ~= "" and not seenEnchants[enchantKey] then
			seenEnchants[enchantKey] = true
			table.insert(enchantNames, {
				Id = enchantId,
				Level = enchantLevel,
			})
		end
	end
	local function addEnchantSource(source)
		if type(source) ~= "table" then
			return
		end
		local enchantList = source.Enchants or source.Enchantments
		if type(enchantList) == "table" then
			for enchantKey, enchantEntry in pairs(enchantList) do
				addEnchantEntry(enchantEntry, type(enchantKey) == "string" and enchantKey or nil)
			end
		end
		addEnchantEntry(source.Enchant)
		addEnchantEntry(source.Enchantment)
		addEnchantEntry(source.Blessing)
	end
	addEnchantSource(petData)
	addEnchantSource(petData.Pet)
	addEnchantSource(petData.Data)
	addEnchantSource(petData.Info)
	return enchantNames
end
activeStates.BGSI_Lite_GetWebhookPetEntryId = function(webhookPetEntry)
	if type(webhookPetEntry) ~= "table" then
		return nil
	end
	for _, idKey in ipairs({
		"Id",
		"ID",
		"id",
		"PetId",
		"PetID",
		"petId",
		"Guid",
		"GUID",
		"guid",
		"PetGuid",
		"PetGUID",
		"UUID",
		"uuid",
		"PetUUID",
		"UID",
		"uid",
		"UniqueId",
		"UniqueID",
		"Identifier",
	}) do
		local idValue = webhookPetEntry[idKey]
		if idValue ~= nil and tostring(idValue) ~= "" then
			return tostring(idValue)
		end
	end
	return activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry.Pet)
		or activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry.Data)
		or activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry.Info)
end
activeStates.BGSI_Lite_NormalizeWebhookPetName = function(petName)
	if type(petName) ~= "string" then
		return ""
	end
	local normalizedName = string.lower(petName):gsub("^%s+", ""):gsub("%s+$", "")
	local previousName
	repeat
		previousName = normalizedName
		normalizedName = normalizedName:gsub("^shiny%s+", "")
		normalizedName = normalizedName:gsub("^mythic%s+", "")
		normalizedName = normalizedName:gsub("^xl%s+", "")
	until normalizedName == previousName
	return normalizedName:gsub("[%s_%-]+", "")
end
activeStates.BGSI_Lite_DoesStoredWebhookPetMatch = function(storedPet, petName, isShiny, isMythic, isXL)
	if type(storedPet) ~= "table" then
		return false
	end
	local storedName = storedPet.Name or storedPet.PetName or storedPet.Pet
	if
		activeStates.BGSI_Lite_NormalizeWebhookPetName(storedName)
		~= activeStates.BGSI_Lite_NormalizeWebhookPetName(petName)
	then
		return false
	end
	if isShiny ~= nil and (storedPet.Shiny == true or storedPet.IsShiny == true) ~= (isShiny == true) then
		return false
	end
	if isMythic ~= nil and (storedPet.Mythic == true or storedPet.IsMythic == true) ~= (isMythic == true) then
		return false
	end
	if isXL ~= nil and (storedPet.XL == true or storedPet.IsXL == true) ~= (isXL == true) then
		return false
	end
	return true
end
activeStates.BGSI_Lite_FindStoredWebhookPet = function(
	webhookPetEntry,
	petName,
	isShiny,
	isMythic,
	isXL,
	excludedPetIds
)
	local targetPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry)
	local ok, playerData = pcall(function()
		return profileStore:IsReady() and profileStore:Get() or nil
	end)
	local petList = ok and type(playerData) == "table" and playerData.Pets or nil
	if type(petList) ~= "table" then
		return nil
	end
	if targetPetId then
		for storedPetKey, storedPet in pairs(petList) do
			if type(storedPet) == "table" then
				local storedPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(storedPet)
				if storedPetId == targetPetId then
					return storedPet, storedPetKey
				end
			end
		end
	end
	for petIndex = #petList, 1, -1 do
		local storedPet = petList[petIndex]
		local storedPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(storedPet)
		if
			(not excludedPetIds or not storedPetId or not excludedPetIds[storedPetId])
			and activeStates.BGSI_Lite_DoesStoredWebhookPetMatch(storedPet, petName, isShiny, isMythic, isXL)
		then
			return storedPet, petIndex
		end
	end
	for storedPetKey, storedPet in pairs(petList) do
		if type(storedPetKey) ~= "number" then
			local storedPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(storedPet)
			if
				(not excludedPetIds or not storedPetId or not excludedPetIds[storedPetId])
				and activeStates.BGSI_Lite_DoesStoredWebhookPetMatch(storedPet, petName, isShiny, isMythic, isXL)
			then
				return storedPet, storedPetKey
			end
		end
	end
	return nil
end
activeStates.BGSI_Lite_GetResolvedWebhookPetId = function(
	webhookPetEntry,
	petName,
	isShiny,
	isMythic,
	isXL,
	excludedPetIds
)
	local webhookPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry)
	if webhookPetId then
		return webhookPetId
	end
	local cachedStoredPet = activeStates.BGSI_Lite_LastWebhookStoredPet
	if activeStates.BGSI_Lite_DoesStoredWebhookPetMatch(cachedStoredPet, petName, isShiny, isMythic, isXL) then
		local cachedPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(cachedStoredPet)
		if cachedPetId and (not excludedPetIds or not excludedPetIds[cachedPetId]) then
			return cachedPetId
		end
	end
	for retryIndex = 1, 20 do
		local storedPet, storedPetKey = activeStates.BGSI_Lite_FindStoredWebhookPet(
			webhookPetEntry,
			petName,
			isShiny,
			isMythic,
			isXL,
			excludedPetIds
		)
		if storedPet then
			activeStates.BGSI_Lite_LastWebhookStoredPet = storedPet
			local storedPetId = activeStates.BGSI_Lite_GetWebhookPetEntryId(storedPet)
			if storedPetId then
				return storedPetId
			end
			if type(storedPetKey) == "string" and storedPetKey ~= "" then
				return storedPetKey
			end
		end
		task.wait(0.05)
	end
	return nil
end
superWebhookEnchantNames = {
	["super-luck"] = "Luck Boost", ["super-luck-plus"] = "Luck Boost+",
	["super-burst"] = "Burst Blessing", ["super-burst-plus"] = "Burst Blessing+",
	["super-shiny"] = "Shiny Blessing", ["super-shiny-plus"] = "Shiny Blessing+",
	["super-speed"] = "Hatch Blessing", ["super-speed-plus"] = "Hatch Blessing+",
	["super-bubble"] = "Bubble Machine", ["super-bubble-plus"] = "Bubble Machine+",
	["super-mythic"] = "Mythic Blessing", ["super-mythic-plus"] = "Mythic Blessing+",
	["super-infinity"] = "Infinity Blessing", ["super-infinity-plus"] = "Infinity Blessing+",
	["super-duplication"] = "Duplication", ["super-duplication-plus"] = "Duplication+",
}
function getWebhookSuperLegendaryEnchantText(webhookPetEntry, petName, isShiny, isMythic, isXL)
	local enchantNames, seenEnchantNames = {}, {}
	local function addEnchantSource(source)
		local enchantList = getSuperLegendaryWebhookEnchantList(source)
		for enchantSlot = 1, #enchantList do
			local enchantName = enchantList[enchantSlot]
			local enchantId = type(enchantName) == "table" and enchantName.Id or enchantName
			local enchantInfo = type(enchantData) == "table" and enchantData[enchantId]
			local displayName = superWebhookEnchantNames[enchantId]
				or (type(enchantInfo) == "table" and enchantInfo.DisplayName)
				or getWebhookEnchantDisplayName(enchantName)
			if displayName and not seenEnchantNames[displayName] then
				seenEnchantNames[displayName] = true
				table.insert(enchantNames, displayName)
			end
		end
	end
	if type(webhookPetEntry) == "table" then
		addEnchantSource(webhookPetEntry)
		addEnchantSource(webhookPetEntry.Pet)
		addEnchantSource(webhookPetEntry.Data)
		addEnchantSource(webhookPetEntry.Info)
	end
	if #enchantNames == 0 then
		for retryIndex = 1, 10 do
			local storedPet =
				activeStates.BGSI_Lite_FindStoredWebhookPet(webhookPetEntry, petName, isShiny, isMythic, isXL)
			if storedPet then
				activeStates.BGSI_Lite_LastWebhookStoredPet = storedPet
			end
			addEnchantSource(storedPet)
			if #enchantNames > 0 then
				break
			end
			task.wait(0.1)
		end
	end
	if #enchantNames == 0 then
		return nil, enchantNames
	end
	return "<:enchantments:1462135985759326370> Enchants: **"
		.. table.concat(enchantNames, ", ") .. "**", enchantNames
end
superEnchantBadgeFiles = {
	["Bubble Machine"] = true,
	["Bubble Machine & Bubble Machine+"] = true,
	["Bubble Machine & Burst Blessing"] = true,
	["Bubble Machine & Burst Blessing+"] = true,
	["Bubble Machine & Duplication"] = true,
	["Bubble Machine & Duplication+"] = true,
	["Bubble Machine & Faster Bubbling"] = true,
	["Bubble Machine & Faster Bubbling+"] = true,
	["Bubble Machine & Hatch Blessing"] = true,
	["Bubble Machine & Hatch Blessing+"] = true,
	["Bubble Machine & Infinity Blessing"] = true,
	["Bubble Machine & Infinity Blessing+"] = true,
	["Bubble Machine & Luck Boost"] = true,
	["Bubble Machine & Luck Boost+"] = true,
	["Bubble Machine & Mythic Blessing"] = true,
	["Bubble Machine & Mythic Blessing+"] = true,
	["Bubble Machine & Shiny Blessing"] = true,
	["Bubble Machine & Shiny Blessing+"] = true,
	["Bubble Machine & Void Luck"] = true,
	["Bubble Machine & Void Luck+"] = true,
	["Bubble Machine & XL Luck"] = true,
	["Bubble Machine & XL Luck+"] = true,
	["Bubble Machine+"] = true,
	["Bubble Machine+ & Burst Blessing"] = true,
	["Bubble Machine+ & Burst Blessing+"] = true,
	["Bubble Machine+ & Duplication"] = true,
	["Bubble Machine+ & Duplication+"] = true,
	["Bubble Machine+ & Faster Bubbling"] = true,
	["Bubble Machine+ & Faster Bubbling+"] = true,
	["Bubble Machine+ & Hatch Blessing"] = true,
	["Bubble Machine+ & Hatch Blessing+"] = true,
	["Bubble Machine+ & Infinity Blessing"] = true,
	["Bubble Machine+ & Infinity Blessing+"] = true,
	["Bubble Machine+ & Luck Boost"] = true,
	["Bubble Machine+ & Luck Boost+"] = true,
	["Bubble Machine+ & Mythic Blessing"] = true,
	["Bubble Machine+ & Mythic Blessing+"] = true,
	["Bubble Machine+ & Shiny Blessing"] = true,
	["Bubble Machine+ & Shiny Blessing+"] = true,
	["Bubble Machine+ & Void Luck"] = true,
	["Bubble Machine+ & Void Luck+"] = true,
	["Bubble Machine+ & XL Luck"] = true,
	["Bubble Machine+ & XL Luck+"] = true,
	["Burst Blessing"] = true,
	["Burst Blessing & Burst Blessing+"] = true,
	["Burst Blessing & Duplication"] = true,
	["Burst Blessing & Duplication+"] = true,
	["Burst Blessing & Faster Bubbling"] = true,
	["Burst Blessing & Faster Bubbling+"] = true,
	["Burst Blessing & Hatch Blessing"] = true,
	["Burst Blessing & Hatch Blessing+"] = true,
	["Burst Blessing & Infinity Blessing"] = true,
	["Burst Blessing & Infinity Blessing+"] = true,
	["Burst Blessing & Luck Boost"] = true,
	["Burst Blessing & Luck Boost+"] = true,
	["Burst Blessing & Mythic Blessing"] = true,
	["Burst Blessing & Mythic Blessing+"] = true,
	["Burst Blessing & Shiny Blessing"] = true,
	["Burst Blessing & Shiny Blessing+"] = true,
	["Burst Blessing & Void Luck"] = true,
	["Burst Blessing & Void Luck+"] = true,
	["Burst Blessing & XL Luck"] = true,
	["Burst Blessing & XL Luck+"] = true,
	["Burst Blessing+"] = true,
	["Burst Blessing+ & Duplication"] = true,
	["Burst Blessing+ & Duplication+"] = true,
	["Burst Blessing+ & Faster Bubbling"] = true,
	["Burst Blessing+ & Faster Bubbling+"] = true,
	["Burst Blessing+ & Hatch Blessing"] = true,
	["Burst Blessing+ & Hatch Blessing+"] = true,
	["Burst Blessing+ & Infinity Blessing"] = true,
	["Burst Blessing+ & Infinity Blessing+"] = true,
	["Burst Blessing+ & Luck Boost"] = true,
	["Burst Blessing+ & Luck Boost+"] = true,
	["Burst Blessing+ & Mythic Blessing"] = true,
	["Burst Blessing+ & Mythic Blessing+"] = true,
	["Burst Blessing+ & Shiny Blessing"] = true,
	["Burst Blessing+ & Shiny Blessing+"] = true,
	["Burst Blessing+ & Void Luck"] = true,
	["Burst Blessing+ & Void Luck+"] = true,
	["Burst Blessing+ & XL Luck"] = true,
	["Burst Blessing+ & XL Luck+"] = true,
	["Duplication"] = true,
	["Duplication & Duplication+"] = true,
	["Duplication & Faster Bubbling"] = true,
	["Duplication & Faster Bubbling+"] = true,
	["Duplication & Hatch Blessing"] = true,
	["Duplication & Hatch Blessing+"] = true,
	["Duplication & Infinity Blessing"] = true,
	["Duplication & Infinity Blessing+"] = true,
	["Duplication & Luck Boost"] = true,
	["Duplication & Luck Boost+"] = true,
	["Duplication & Mythic Blessing"] = true,
	["Duplication & Mythic Blessing+"] = true,
	["Duplication & Shiny Blessing"] = true,
	["Duplication & Shiny Blessing+"] = true,
	["Duplication & Void Luck"] = true,
	["Duplication & Void Luck+"] = true,
	["Duplication & XL Luck"] = true,
	["Duplication & XL Luck+"] = true,
	["Duplication+"] = true,
	["Duplication+ & Faster Bubbling"] = true,
	["Duplication+ & Faster Bubbling+"] = true,
	["Duplication+ & Hatch Blessing"] = true,
	["Duplication+ & Hatch Blessing+"] = true,
	["Duplication+ & Infinity Blessing"] = true,
	["Duplication+ & Infinity Blessing+"] = true,
	["Duplication+ & Luck Boost"] = true,
	["Duplication+ & Luck Boost+"] = true,
	["Duplication+ & Mythic Blessing"] = true,
	["Duplication+ & Mythic Blessing+"] = true,
	["Duplication+ & Shiny Blessing"] = true,
	["Duplication+ & Shiny Blessing+"] = true,
	["Duplication+ & Void Luck"] = true,
	["Duplication+ & Void Luck+"] = true,
	["Duplication+ & XL Luck"] = true,
	["Duplication+ & XL Luck+"] = true,
	["Faster Bubbling"] = true,
	["Faster Bubbling & Faster Bubbling+"] = true,
	["Faster Bubbling & Hatch Blessing"] = true,
	["Faster Bubbling & Hatch Blessing+"] = true,
	["Faster Bubbling & Infinity Blessing"] = true,
	["Faster Bubbling & Infinity Blessing+"] = true,
	["Faster Bubbling & Luck Boost"] = true,
	["Faster Bubbling & Luck Boost+"] = true,
	["Faster Bubbling & Mythic Blessing"] = true,
	["Faster Bubbling & Mythic Blessing+"] = true,
	["Faster Bubbling & Shiny Blessing"] = true,
	["Faster Bubbling & Shiny Blessing+"] = true,
	["Faster Bubbling & Void Luck"] = true,
	["Faster Bubbling & Void Luck+"] = true,
	["Faster Bubbling & XL Luck"] = true,
	["Faster Bubbling & XL Luck+"] = true,
	["Faster Bubbling+"] = true,
	["Faster Bubbling+ & Hatch Blessing"] = true,
	["Faster Bubbling+ & Hatch Blessing+"] = true,
	["Faster Bubbling+ & Infinity Blessing"] = true,
	["Faster Bubbling+ & Infinity Blessing+"] = true,
	["Faster Bubbling+ & Luck Boost"] = true,
	["Faster Bubbling+ & Luck Boost+"] = true,
	["Faster Bubbling+ & Mythic Blessing"] = true,
	["Faster Bubbling+ & Mythic Blessing+"] = true,
	["Faster Bubbling+ & Shiny Blessing"] = true,
	["Faster Bubbling+ & Shiny Blessing+"] = true,
	["Faster Bubbling+ & Void Luck"] = true,
	["Faster Bubbling+ & Void Luck+"] = true,
	["Faster Bubbling+ & XL Luck"] = true,
	["Faster Bubbling+ & XL Luck+"] = true,
	["Hatch Blessing"] = true,
	["Hatch Blessing & Hatch Blessing+"] = true,
	["Hatch Blessing & Void Luck"] = true,
	["Hatch Blessing & Void Luck+"] = true,
	["Hatch Blessing & XL Luck"] = true,
	["Hatch Blessing & XL Luck+"] = true,
	["Hatch Blessing+"] = true,
	["Hatch Blessing+ & Void Luck"] = true,
	["Hatch Blessing+ & Void Luck+"] = true,
	["Hatch Blessing+ & XL Luck"] = true,
	["Hatch Blessing+ & XL Luck+"] = true,
	["Infinity Blessing"] = true,
	["Infinity Blessing & Hatch Blessing"] = true,
	["Infinity Blessing & Hatch Blessing+"] = true,
	["Infinity Blessing & Infinity Blessing+"] = true,
	["Infinity Blessing & Luck Boost"] = true,
	["Infinity Blessing & Luck Boost+"] = true,
	["Infinity Blessing & Mythic Blessing"] = true,
	["Infinity Blessing & Mythic Blessing+"] = true,
	["Infinity Blessing & Shiny Blessing"] = true,
	["Infinity Blessing & Shiny Blessing+"] = true,
	["Infinity Blessing & Void Luck"] = true,
	["Infinity Blessing & Void Luck+"] = true,
	["Infinity Blessing & XL Luck"] = true,
	["Infinity Blessing & XL Luck+"] = true,
	["Infinity Blessing+"] = true,
	["Infinity Blessing+ & Hatch Blessing"] = true,
	["Infinity Blessing+ & Hatch Blessing+"] = true,
	["Infinity Blessing+ & Luck Boost"] = true,
	["Infinity Blessing+ & Luck Boost+"] = true,
	["Infinity Blessing+ & Mythic Blessing"] = true,
	["Infinity Blessing+ & Mythic Blessing+"] = true,
	["Infinity Blessing+ & Shiny Blessing"] = true,
	["Infinity Blessing+ & Shiny Blessing+"] = true,
	["Infinity Blessing+ & Void Luck"] = true,
	["Infinity Blessing+ & Void Luck+"] = true,
	["Infinity Blessing+ & XL Luck"] = true,
	["Infinity Blessing+ & XL Luck+"] = true,
	["Luck Boost"] = true,
	["Luck Boost & Hatch Blessing"] = true,
	["Luck Boost & Hatch Blessing+"] = true,
	["Luck Boost & Luck Boost+"] = true,
	["Luck Boost & Mythic Blessing"] = true,
	["Luck Boost & Mythic Blessing+"] = true,
	["Luck Boost & Shiny Blessing"] = true,
	["Luck Boost & Shiny Blessing+"] = true,
	["Luck Boost & Void Luck"] = true,
	["Luck Boost & Void Luck+"] = true,
	["Luck Boost & XL Luck"] = true,
	["Luck Boost & XL Luck+"] = true,
	["Luck Boost+"] = true,
	["Luck Boost+ & Hatch Blessing"] = true,
	["Luck Boost+ & Hatch Blessing+"] = true,
	["Luck Boost+ & Mythic Blessing"] = true,
	["Luck Boost+ & Mythic Blessing+"] = true,
	["Luck Boost+ & Shiny Blessing"] = true,
	["Luck Boost+ & Shiny Blessing+"] = true,
	["Luck Boost+ & Void Luck"] = true,
	["Luck Boost+ & Void Luck+"] = true,
	["Luck Boost+ & XL Luck"] = true,
	["Luck Boost+ & XL Luck+"] = true,
	["Mythic Blessing"] = true,
	["Mythic Blessing & Hatch Blessing"] = true,
	["Mythic Blessing & Hatch Blessing+"] = true,
	["Mythic Blessing & Mythic Blessing+"] = true,
	["Mythic Blessing & Shiny Blessing"] = true,
	["Mythic Blessing & Shiny Blessing+"] = true,
	["Mythic Blessing & Void Luck"] = true,
	["Mythic Blessing & Void Luck+"] = true,
	["Mythic Blessing & XL Luck"] = true,
	["Mythic Blessing & XL Luck+"] = true,
	["Mythic Blessing+"] = true,
	["Mythic Blessing+ & Hatch Blessing"] = true,
	["Mythic Blessing+ & Hatch Blessing+"] = true,
	["Mythic Blessing+ & Shiny Blessing"] = true,
	["Mythic Blessing+ & Shiny Blessing+"] = true,
	["Mythic Blessing+ & Void Luck"] = true,
	["Mythic Blessing+ & Void Luck+"] = true,
	["Mythic Blessing+ & XL Luck"] = true,
	["Mythic Blessing+ & XL Luck+"] = true,
	["Shiny Blessing"] = true,
	["Shiny Blessing & Hatch Blessing"] = true,
	["Shiny Blessing & Hatch Blessing+"] = true,
	["Shiny Blessing & Shiny Blessing+"] = true,
	["Shiny Blessing & Void Luck"] = true,
	["Shiny Blessing & Void Luck+"] = true,
	["Shiny Blessing & XL Luck"] = true,
	["Shiny Blessing & XL Luck+"] = true,
	["Shiny Blessing+"] = true,
	["Shiny Blessing+ & Hatch Blessing"] = true,
	["Shiny Blessing+ & Hatch Blessing+"] = true,
	["Shiny Blessing+ & Void Luck"] = true,
	["Shiny Blessing+ & Void Luck+"] = true,
	["Shiny Blessing+ & XL Luck"] = true,
	["Shiny Blessing+ & XL Luck+"] = true,
	["Void Luck"] = true,
	["Void Luck & Void Luck+"] = true,
	["Void Luck & XL Luck"] = true,
	["Void Luck & XL Luck+"] = true,
	["Void Luck+"] = true,
	["Void Luck+ & XL Luck"] = true,
	["Void Luck+ & XL Luck+"] = true,
	["XL Luck"] = true,
	["XL Luck & XL Luck+"] = true,
	["XL Luck+"] = true,
}
function getEnchantedSuperWebhookIcon(iconUrl, enchantNames)
	if type(iconUrl) ~= "string" or not iconUrl:match("^https://") or type(enchantNames) ~= "table" then
		return iconUrl
	end
	if #enchantNames < 1 or #enchantNames > 2 then
		return iconUrl
	end
	local badgeName = enchantNames[1]
	if #enchantNames == 2 then
		local forward = enchantNames[1] .. " & " .. enchantNames[2]
		local reverse = enchantNames[2] .. " & " .. enchantNames[1]
		badgeName = superEnchantBadgeFiles[forward] and forward or reverse
	end
	if not superEnchantBadgeFiles[badgeName] then
		return iconUrl
	end
	local badgePath = (badgeName .. ".png"):gsub(" ", "%%20"):gsub("&", "%%26"):gsub("%+", "%%2B")
	local badgeUrl = "https://raw.githubusercontent.com/nf4z/larp/main/enchants/"
		.. badgePath
	return "https://images.hsingh.app/?url=" .. HttpService:UrlEncode(iconUrl)
		.. "&ol=" .. HttpService:UrlEncode(badgeUrl)
		.. "&olw=32&olg=southwest&w=420&h=420&fit=fill&output=png"
end
function isSpecialEnchant(scriptStateADR)
	local scriptStateABZ = getEnchantData(scriptStateADR)
	if type(scriptStateABZ) ~= "table" then
		return false
	end
	return scriptStateABZ.Special == true or scriptStateABZ.Secret == true
end
function getEnchantMaxLevel(scriptStateSH)
	local scriptStateAAD = getEnchantData(scriptStateSH)
	if type(scriptStateAAD) ~= "table" then
		return nil
	end
	if type(scriptStateAAD.Levels) == "number" and scriptStateAAD.Levels > 0 then
		return scriptStateAAD.Levels
	end
	if type(scriptStateAAD.Buffs) == "table" then
		local enchantBuffCount = #scriptStateAAD.Buffs
		if enchantBuffCount > 0 then
			return enchantBuffCount
		end
	end
	return nil
end
function isSingleLevelEnchant(scriptStateAAS)
	if isSpecialEnchant(scriptStateAAS) then
		return true
	end
	local scriptStateAFO = getEnchantMaxLevel(scriptStateAAS)
	return type(scriptStateAFO) == "number" and scriptStateAFO == 1
end
function hasShadowCrystalCurrency()
	local potionUseSuccess, scriptStateNR = pcall(function()
		return profileStore:Get()
	end)
	if not potionUseSuccess or type(scriptStateNR) ~= "table" then
		return false
	end
	local function normalizeEnchantName(scriptStateAFH)
		return type(scriptStateAFH) == "number" and scriptStateAFH > 0
	end
	if type(scriptStateNR.Powerups) == "table" and normalizeEnchantName(scriptStateNR.Powerups["Shadow Crystal"]) then
		return true
	end
	if
		type(scriptStateNR.Currencies) == "table"
		and (
			normalizeEnchantName(scriptStateNR.Currencies["Shadow Crystals"])
			or normalizeEnchantName(scriptStateNR.Currencies["ShadowCrystals"])
		)
	then
		return true
	end
	if normalizeEnchantName(scriptStateNR.ShadowCrystals) then
		return true
	end
	return false
end
function resolveEnchantCurrency(enchantCurrencyParam, scriptStateE)
	local scriptStateEF = isSpecialEnchant(scriptStateE)
	if scriptStateEF and not hasShadowCrystalCurrency() then
		if enchantCurrencyParam == "Auto (Secret = Crystals,Normal = Reroll Orbs)" then
			return "Reroll Orbs"
		end
		return "Gems"
	end
	if enchantCurrencyParam == "Auto (Secret = Crystals,Normal = Gems)" then
		return scriptStateEF and "Shadow Crystals" or "Gems"
	end
	if enchantCurrencyParam == "Auto (Secret = Crystals,Normal = Reroll Orbs)" then
		return scriptStateEF and "Shadow Crystals" or "Reroll Orbs"
	end
	return enchantCurrencyParam
end
function getPetEnchantInfo(scriptStateZM, scriptStateAEV, scriptStateVS)
	if not scriptStateAEV or scriptStateAEV == "" or scriptStateAEV == "(None - single target)" then
		return nil
	end
	local scriptStateAAA = tonumber(scriptStateVS) or 0
	if scriptStateAAA > 0 and isSingleLevelEnchant(scriptStateAEV) then
		scriptStateAAA = 0
	end
	if scriptStateAAA <= 0 then
		return findPetEnchantSlot(scriptStateZM, scriptStateAEV)
	end
	local scriptStateJT = normalizeEnchantName(scriptStateAEV)
	local scriptStateBH = scriptStateZM and (scriptStateZM.Enchants or scriptStateZM.Enchantments) or {}
	for loopSlotDQ = 1, 2 do
		local scriptStateWF = scriptStateBH[loopSlotDQ] or scriptStateBH[tostring(loopSlotDQ)]
		if type(scriptStateWF) == "table" then
			local potionAmount = scriptStateWF.Id
				or scriptStateWF.ID
				or scriptStateWF.Name
				or scriptStateWF.Enchant
				or ""
			if normalizeEnchantName(potionAmount) == scriptStateJT then
				local scriptStateWN =
					tonumber(scriptStateWF.Level or scriptStateWF.Lv or scriptStateWF.Tier or scriptStateWF.Rank)
				local scriptStateADG = getEnchantMaxLevel(potionAmount)
				local scriptStateIK = (scriptStateADG and scriptStateADG > 0)
						and math.min(scriptStateAAA, scriptStateADG)
					or scriptStateAAA
				if scriptStateWN == nil or scriptStateWN >= scriptStateIK then
					return loopSlotDQ
				end
			end
		end
	end
	return nil
end
dualEnchantWhitelist = {
	["lathanpng"] = true,
	["arsu_121"] = true,
	["nachobus543"] = true,
	["KaiRblxALT"] = true,
	["CwCinfinite1"] = true,
	["BingusGrandFather"] = true,
	["WillsBigRightBall"] = true,
	["PraetoriusGetTheHuzz"] = true,
	["YT_JackMaBoey"] = true,
	["RattyyCattyy1"] = true,
	["KamalMohsen1999"] = true,
	["Kayzoom_99"] = true,
	["Kay_doom99"] = true,
	["Kayfoom99"] = true,
	["spiderman_skibid"] = true,
	["3neitheriteingots"] = true,
}
normalizedDualEnchantWhitelist = {}
for whitelistedName in pairs(dualEnchantWhitelist) do
	normalizedDualEnchantWhitelist[string.lower(whitelistedName)] = true
end
isDualEnchantWhitelisted = false
do
	local playerName = LocalPlayer and LocalPlayer.Name
	if type(playerName) == "string" then
		isDualEnchantWhitelisted = normalizedDualEnchantWhitelist[string.lower(playerName)] == true
	end
end
function canPetUseDualEnchantMode(scriptStateACP)
	if not scriptStateACP then
		return false
	end
	if isDualEnchantWhitelisted then
		return true
	end
	if enchantModule and type(enchantModule.GetMaxEnchantSlots) == "function" then
		local scriptStateSE, scriptStatePX = pcall(enchantModule.GetMaxEnchantSlots, enchantModule, scriptStateACP)
		if scriptStateSE and type(scriptStatePX) == "number" then
			return scriptStatePX >= 2
		end
	end
	return scriptStateACP.Shiny == true or scriptStateACP.IsShiny == true
end
function getEnchantablePets()
	local scriptStateACE, scriptStateGP = pcall(function()
		return profileStore:Get()
	end)
	if not scriptStateACE or type(scriptStateGP) ~= "table" then
		return {}
	end
	if not scriptStateGP.Teams or not scriptStateGP.TeamEquipped then
		return {}
	end
	local scriptStateTI = scriptStateGP.Teams[scriptStateGP.TeamEquipped]
	return (scriptStateTI and type(scriptStateTI.Pets) == "table") and scriptStateTI.Pets or {}
end
activeStates.BGSI_Lite_IsShinyEnchantPet = function(pet)
	if type(pet) ~= "table" or (pet.Shiny ~= true and pet.IsShiny ~= true) then
		return false
	end
	local petInfo = type(petRarityData) == "table" and petRarityData[pet.Name] or nil
	local rarity = activeStates.BGSI_Lite_ResolvePetRarity(pet, petInfo)
	return rarity == "Celestial" or rarity == "Secret"
end
function getEnchantCurrency(scriptStateVC)
	if type(profileStore.GetPetById) == "function" then
		local petLookupOk, indexedPet = pcall(profileStore.GetPetById, profileStore, scriptStateVC)
		if petLookupOk and type(indexedPet) == "table" then
			return indexedPet
		end
	end
	local scriptStateQQ, scriptStateACB = pcall(function()
		return profileStore:Get()
	end)
	if not scriptStateQQ or type(scriptStateACB) ~= "table" or type(scriptStateACB.Pets) ~= "table" then
		return nil
	end
	for loopSlotBV, scriptStateQG in ipairs(scriptStateACB.Pets) do
		if tostring(scriptStateQG.Id or "") == tostring(scriptStateVC) then
			return scriptStateQG
		end
	end
	return nil
end
function getEligibleEquippedEnchantPetIds(playerData)
	if type(playerData) ~= "table" or type(playerData.Pets) ~= "table" then
		return {}
	end
	local petById = {}
	for _, pet in ipairs(playerData.Pets) do
		local petId = tostring(pet.Id or "")
		if petId ~= "" then
			petById[petId] = pet
		end
	end
	local eligiblePetIds = {}
	for _, petId in ipairs(getEnchantablePets()) do
		local pet = petById[tostring(petId)]
		if pet and activeStates.BGSI_Lite_IsShinyEnchantPet(pet) then
			table.insert(eligiblePetIds, tostring(petId))
		end
	end
	return eligiblePetIds
end
autoEnchantThreadRunning = false
ENCHANT_REROLL_COOLDOWN = 0.25
function getShadowCrystalCount()
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" then
		return 0
	end
	return math.max(0, tonumber(playerData.Powerups and playerData.Powerups["Shadow Crystal"]) or 0)
end
function buildTargetEnchantLookup(targetEnchantOne, targetEnchantTwo)
	local targetLookup = {}
	local function addTargetEnchant(enchantName)
		if type(enchantName) == "string" and enchantName ~= "" and enchantName ~= "(None - single target)" then
			targetLookup[normalizeEnchantName(enchantName)] = true
		end
	end
	addTargetEnchant(targetEnchantOne)
	addTargetEnchant(targetEnchantTwo)
	local hasSecondEnchantTarget = type(targetEnchantTwo) == "string"
		and targetEnchantTwo ~= ""
		and targetEnchantTwo ~= "(None - single target)"
	return targetLookup, hasSecondEnchantTarget
end
activeStates.BGSI_Lite_GetPetEnchantSignature = function(petData)
	local signatureParts = {}
	local enchantList = type(petData) == "table" and (petData.Enchants or petData.Enchantments) or {}
	for enchantSlot, enchantEntry in pairs(type(enchantList) == "table" and enchantList or {}) do
		table.insert(signatureParts, table.concat({
			tostring(enchantSlot),
			tostring(type(enchantEntry) == "table" and (enchantEntry.Id or enchantEntry.id) or enchantEntry or ""),
			tostring(type(enchantEntry) == "table" and (enchantEntry.Level or enchantEntry.level) or ""),
			tostring(type(enchantEntry) == "table" and (enchantEntry.Extra or enchantEntry.extra) or ""),
		}, ":"))
	end
	table.sort(signatureParts)
	return table.concat(signatureParts, "|")
end
function getMaxEnchantSlotsForPet(petData)
	if type(petData) == "table" and (petData.Shiny == true or petData.IsShiny == true) then
		return 2
	end
	return 1
end
function isPetEnchantTargetSatisfied(petData, targetLookup, targetEnchantLevel, requireBothSlotsFilled)
	local enchantList = type(petData) == "table" and (petData.Enchants or petData.Enchantments) or {}
	local sawAnyEnchant = false
	local slotCount = 0
	local seenTargets = {}
	for _, enchantEntry in pairs(type(enchantList) == "table" and enchantList or {}) do
		sawAnyEnchant = true
		slotCount += 1
		local enchantId = type(enchantEntry) == "table"
				and (enchantEntry.Id or enchantEntry.id or enchantEntry.ID or enchantEntry.Name)
			or enchantEntry
		local enchantLevel = type(enchantEntry) == "table"
			and tonumber(enchantEntry.Level or enchantEntry.level)
			or nil
		local normalizedId = normalizeEnchantName(enchantId)
		seenTargets[normalizedId] = true
		if not targetLookup[normalizedId] then
			return false
		end
		if targetEnchantLevel > 0 and (not enchantLevel or enchantLevel < targetEnchantLevel) then
			return false
		end
	end
	if not sawAnyEnchant then
		return false
	end
	if requireBothSlotsFilled then
		for target in pairs(targetLookup) do
			if not seenTargets[target] then return false end
		end
	end
	if requireBothSlotsFilled and slotCount < getMaxEnchantSlotsForPet(petData) then
		return false
	end
	return true
end
function getProtectedEnchantSlot(petData, targetLookup, targetEnchantLevel, reenchantThreshold)
	local enchantList = type(petData) == "table" and (petData.Enchants or petData.Enchantments) or {}
	for slot, enchantEntry in pairs(type(enchantList) == "table" and enchantList or {}) do
		local enchantId = type(enchantEntry) == "table"
				and (enchantEntry.Id or enchantEntry.id or enchantEntry.ID or enchantEntry.Name)
			or enchantEntry
		local enchantLevel = type(enchantEntry) == "table"
			and tonumber(enchantEntry.Level or enchantEntry.level)
			or nil
		if
			targetLookup[normalizeEnchantName(enchantId)]
			and (targetEnchantLevel <= 0 or (enchantLevel and enchantLevel >= targetEnchantLevel))
			and (not reenchantThreshold or reenchantThreshold <= 0 or not enchantLevel or enchantLevel > reenchantThreshold)
		then
			return tonumber(slot)
		end
	end
	return nil
end
function petHasStaleTargetEnchant(petData, targetLookup, reenchantThreshold)
	if reenchantThreshold <= 0 then
		return false
	end
	local enchantList = type(petData) == "table" and (petData.Enchants or petData.Enchantments) or {}
	for _, enchantEntry in pairs(type(enchantList) == "table" and enchantList or {}) do
		local enchantId = type(enchantEntry) == "table"
				and (enchantEntry.Id or enchantEntry.id or enchantEntry.ID or enchantEntry.Name)
			or enchantEntry
		local enchantLevel = type(enchantEntry) == "table"
			and tonumber(enchantEntry.Level or enchantEntry.level)
			or nil
		if
			targetLookup[normalizeEnchantName(enchantId)]
			and enchantLevel
			and enchantLevel <= reenchantThreshold
		then
			return true
		end
	end
	return false
end
activeStates.BGSI_Lite_RerollEnchantPet = function(
	petId,
	targetEnchantOne,
	targetEnchantTwo,
	targetEnchantLevel,
	selectedEnchantCurrencyMode
)
	local rerollCooldown = math.max(
		ENCHANT_REROLL_COOLDOWN,
		tonumber(sharedConstants and sharedConstants.EnchantRerollCooldown) or ENCHANT_REROLL_COOLDOWN
	)
	local targetLookup, hasSecondEnchantTarget = buildTargetEnchantLookup(targetEnchantOne, targetEnchantTwo)
	targetEnchantLevel = math.max(0, tonumber(targetEnchantLevel) or 0)
	local reenchantThreshold = math.max(0, tonumber(Config.equippedReenchantThreshold) or 0)

	-- Targets below are refreshed before every request, including mid-pet changes.
	local function isFullyDone(currentPetData)
		if
			not isPetEnchantTargetSatisfied(
				currentPetData,
				targetLookup,
				targetEnchantLevel,
				hasSecondEnchantTarget
			)
		then
			return false
		end
		return not petHasStaleTargetEnchant(currentPetData, targetLookup, reenchantThreshold)
	end

	local confirmedPet
	while Config.autoEnchant and isCurrentRun() do
		targetEnchantOne = tostring(Config.equippedTargetEnchant or "secret-hunter")
		targetEnchantTwo = tostring(Config.equippedTargetEnchant2 or "")
		targetEnchantLevel = math.max(0, tonumber(Config.equippedTargetEnchantLevel) or 0)
		selectedEnchantCurrencyMode = Config.equippedEnchantCurrency or "Auto (Secret = Crystals,Normal = Gems)"
		targetLookup, hasSecondEnchantTarget = buildTargetEnchantLookup(targetEnchantOne, targetEnchantTwo)
		reenchantThreshold = math.max(0, tonumber(Config.equippedReenchantThreshold) or 0)
		local petData = getEnchantCurrency(petId)
		if confirmedPet then
			if petData and activeStates.BGSI_Lite_GetPetEnchantSignature(petData)
				== activeStates.BGSI_Lite_GetPetEnchantSignature(confirmedPet) then
				confirmedPet = nil
			else
				-- A late replication of an earlier roll must not overwrite a newer InvokeServer result.
				petData = confirmedPet
			end
		end
		if not petData then
			task.wait(1)
			continue
		end
		if petData.Super == true or petData.IsSuper == true or not activeStates.BGSI_Lite_IsShinyEnchantPet(petData) then
			return true
		end
		if isFullyDone(petData) then
			return true
		end

		local protectSlot = getProtectedEnchantSlot(petData, targetLookup, targetEnchantLevel, reenchantThreshold)
		local resolvedEnchantCurrency = resolveEnchantCurrency(selectedEnchantCurrencyMode, targetEnchantOne)

		if resolvedEnchantCurrency == "Shadow Crystals" then
			if getShadowCrystalCount() <= 0 then
				activeStates.BGSI_Lite_AutoEnchantBlockedUntil = tick() + 10
				return false
			end
			-- UseShadowCrystal is fire-and-forget - the game gives back no confirmation at
			-- all, unlike RerollEnchants below. Firing another reroll before the pet's own
			-- replicated data actually reflects this one's result is exactly what let the old
			-- loop "roll past" a landed target: it would blindly wait a fixed cooldown, then
			-- decide the next protect slot from data that might still be stale. Waiting here
			-- for the enchant signature to actually change makes that impossible - the next
			-- protect slot is only ever computed from a confirmed result.
			local signatureBeforeReroll = activeStates.BGSI_Lite_GetPetEnchantSignature(petData)
			local fired = pcall(remoteEvent.FireServer, remoteEvent, "UseShadowCrystal", petId, protectSlot)
			if not fired then
				task.wait(rerollCooldown)
				continue
			end
			local confirmDeadline = tick() + math.max(3, rerollCooldown * 4)
			repeat
				task.wait(0.05)
				petData = getEnchantCurrency(petId)
			until not petData
				or activeStates.BGSI_Lite_GetPetEnchantSignature(petData) ~= signatureBeforeReroll
				or tostring(Config.equippedTargetEnchant or "secret-hunter") ~= targetEnchantOne
				or tostring(Config.equippedTargetEnchant2 or "") ~= targetEnchantTwo
				or not Config.autoEnchant or not isCurrentRun()
				or tick() >= confirmDeadline
			-- Recheck the current selection before deciding whether this pet is finished.
		else
			local currencyType = resolvedEnchantCurrency == "Reroll Orbs" and "Powerup" or "Gems"
			-- RerollEnchants is a real InvokeServer call: the server hands back the pet's
			-- exact new enchant list synchronously, in the very same round trip that performed
			-- the reroll (confirmed against the game's own decompiled client code). Using that
			-- return value directly - instead of a blind cooldown then a re-fetch that might
			-- race the replication - means there is no window at all where a just-landed
			-- target could get rolled over for this currency path.
			local invokeOk, newPetIdOrStatus, newEnchants = pcall(
				remoteFunction.InvokeServer,
				remoteFunction,
				"RerollEnchants",
				petId,
				currencyType,
				protectSlot
			)
			if invokeOk and newPetIdOrStatus == "toofast" then
				task.wait(0.1)
				continue
			end
			if invokeOk and newPetIdOrStatus and type(newEnchants) == "table" then
				confirmedPet = table.clone(petData)
				confirmedPet.Enchants = newEnchants
				if tostring(newPetIdOrStatus) ~= tostring(petId) then
					petId = newPetIdOrStatus
				end
				-- Evaluate the authoritative result with the latest targets at the next iteration.
			end
		end
		task.wait(rerollCooldown)
	end
	return false
end
function getEnchantTargetList()
	if autoEnchantThreadRunning then
		return
	end
	autoEnchantThreadRunning = true
	task.spawn(function()
		while Config.autoEnchant and isCurrentRun() do
			if tick() < (tonumber(activeStates.BGSI_Lite_AutoEnchantBlockedUntil) or 0) then
				task.wait(1)
				continue
			end
			local currentPlayerData = profileStore:IsReady() and profileStore:Get() or nil
			-- Reads whatever team you already have equipped. Never equips or unequips anything.
			local eligiblePetIds = getEligibleEquippedEnchantPetIds(currentPlayerData)
			if #eligiblePetIds == 0 then
				task.wait(2)
				continue
			end
			local targetEnchantOne = tostring(Config.equippedTargetEnchant or "secret-hunter")
			local targetEnchantTwo = tostring(Config.equippedTargetEnchant2 or "ultra-roller")
			local targetEnchantLevel = tonumber(Config.equippedTargetEnchantLevel) or 0
			local selectedEnchantCurrencyMode = Config.equippedEnchantCurrency
				or "Auto (Secret = Crystals,Normal = Gems)"
			local allEnchantSuccess = true
			for petIndex, petId in ipairs(eligiblePetIds) do
				if not Config.autoEnchant or not isCurrentRun() then
					break
				end
				local enchantSuccess = activeStates.BGSI_Lite_RerollEnchantPet(
					petId,
					targetEnchantOne,
					targetEnchantTwo,
					targetEnchantLevel,
					selectedEnchantCurrencyMode
				)
				if not enchantSuccess then
					allEnchantSuccess = false
					break
				end
				if petIndex < #eligiblePetIds then
					task.wait(0.5)
				end
			end
			if allEnchantSuccess then
				task.wait(3)
			else
				task.wait(1)
			end
		end
		autoEnchantThreadRunning = false
	end)
end
if Config.autoEnchant then
	getEnchantTargetList()
end
task.spawn(function()
	local lastAutoEnchantState = false
	while isCurrentRun() do
		task.wait(0.75)
		if Config.autoEnchant and not lastAutoEnchantState then
			getEnchantTargetList()
		end
		lastAutoEnchantState = Config.autoEnchant
	end
end)
end,
function(...)
task.spawn(function()
	while isCurrentRun() do
		if Config.autoSeason then
			pcall(function()
				remoteEvent:FireServer("ClaimSeason")
			end)
		end
		task.wait(5)
	end
end)
activeStates.GetChallengePassQuestById = function(challengeQuestId)
	if type(challengeQuestId) ~= "string" or challengeQuestId == "" then
		return nil
	end
	if not profileStore:IsReady() then
		return nil
	end
	local playerData = profileStore:Get()
	if not playerData then
		return nil
	end
	if questModule and type(questModule.FindById) == "function" then
		local ok, questData = pcall(function()
			return questModule:FindById(playerData, challengeQuestId)
		end)
		if ok and type(questData) == "table" then
			return questData
		end
	end
	for _, questContainer in ipairs({
		playerData.Quests,
		playerData.ActiveQuests,
		playerData.DailyChallenges,
		playerData.HourlyChallenges,
		playerData.Challenges,
	}) do
		if type(questContainer) == "table" then
			for _, questData in pairs(questContainer) do
				if
					type(questData) == "table"
					and (questData.Id == challengeQuestId or questData.ID == challengeQuestId)
				then
					return questData
				end
			end
		end
	end
	return nil
end
activeStates.GetChallengePassQuestList = function()
	local challengeQuestList = {}
	for challengeIndex = 1, 3 do
		local challengeQuestId = "bubble-challenge-" .. tostring(challengeIndex)
		local challengeQuest = activeStates.GetChallengePassQuestById(challengeQuestId)
		if type(challengeQuest) == "table" and challengeQuest.Claimed ~= true then
			challengeQuest.Id = challengeQuest.Id or challengeQuest.ID or challengeQuestId
			table.insert(challengeQuestList, challengeQuest)
		end
	end
	return challengeQuestList
end
activeStates.HasUnfinishedChallengePassQuest = function(challengeQuestList)
	if type(challengeQuestList) ~= "table" then
		return false
	end
	for _, challengeQuest in ipairs(challengeQuestList) do
		if type(challengeQuest) == "table" and type(challengeQuest.Tasks) == "table" then
			for _, taskIndex in ipairs(makeIndexList(challengeQuest.Tasks)) do
				local challengeTask = challengeQuest.Tasks[taskIndex]
				if type(challengeTask) == "table" then
					local taskRequirement = getBountyTaskRequirement(challengeTask)
					local taskProgress = getBountyTaskProgress(challengeQuest, taskIndex)
					if
						type(taskRequirement) == "number"
						and taskProgress < taskRequirement
						and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(challengeTask)
						and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(challengeTask)
						and not activeStates.BGSI_Lite_IsQuestTaskDeferred(challengeQuest, taskIndex)
					then
						return true
					end
				end
			end
		end
	end
	return false
end
activeStates.GetChallengePassModule = function()
	if type(activeStates.BGSI_Lite_ChallengePassModule) == "table" then
		return activeStates.BGSI_Lite_ChallengePassModule
	end
	pcall(function()
		activeStates.BGSI_Lite_ChallengePassModule = require(ReplicatedStorage.Shared.Data.ChallengePass)
	end)
	return type(activeStates.BGSI_Lite_ChallengePassModule) == "table" and activeStates.BGSI_Lite_ChallengePassModule
		or nil
end
activeStates.FireChallengePassAction = function(actionName, ...)
	if type(actionName) ~= "string" or actionName == "" then
		return
	end
	local actionArgs = { ... }
	pcall(function()
		remoteEvent:FireServer(actionName, table.unpack(actionArgs))
	end)
	pcall(function()
		if not carnivalRemoteModule then
			carnivalRemoteModule = require(ReplicatedStorage.Shared.Framework.Network.Remote)
		end
		if carnivalRemoteModule and type(carnivalRemoteModule.FireServer) == "function" then
			carnivalRemoteModule:FireServer(actionName, table.unpack(actionArgs))
		end
	end)
end
activeStates.ClaimChallengePassRewards = function()
	activeStates.FireChallengePassAction("ChallengePassClaimAll")
	activeStates.FireChallengePassAction("ChallengePassClaimReward")
	for rewardIndex = 1, 25 do
		activeStates.FireChallengePassAction("ChallengePassClaimReward", rewardIndex)
	end
end
activeStates.TryResetChallengePass = function(forceAttempt)
	local now = tick()
	if now - (tonumber(activeStates.BGSI_Lite_LastChallengePassResetAttempt) or 0) < 10 then
		return
	end
	if forceAttempt ~= true and not activeStates.ShouldResetChallengePass() then
		return
	end
	activeStates.BGSI_Lite_LastChallengePassResetAttempt = now
	pcall(activeStates.ClaimChallengePassRewards)
	task.wait(0.5)
	activeStates.FireChallengePassAction("ChallengePassReset")
end
activeStates.ShouldResetChallengePass = function()
	if not profileStore:IsReady() then
		return false
	end
	local playerData = profileStore:Get()
	local challengePassData = playerData and playerData.ChallengePass
	if type(challengePassData) ~= "table" then
		return false
	end
	if
		challengePassData.CanReset == true
		or challengePassData.Completed == true
		or challengePassData.Complete == true
	then
		return true
	end
	local challengePassModule = activeStates.GetChallengePassModule()
	local finalTier = challengePassModule and tonumber(challengePassModule.FinalTier) or 15
	local currentTier = 0
	if challengePassModule and type(challengePassModule.GetTier) == "function" then
		local ok, tierResult = pcall(function()
			return challengePassModule:GetTier(tonumber(challengePassData.Points) or 0)
		end)
		if ok and type(tierResult) == "number" then
			currentTier = tierResult
		end
	end
	if currentTier <= 0 then
		currentTier = tonumber(challengePassData.Tier or challengePassData.CurrentTier or challengePassData.Level) or 0
	end
	if currentTier < finalTier then
		return false
	end
	if
		challengePassModule
		and type(challengePassModule.GetResetCost) == "function"
		and itemUtil
		and type(itemUtil.CanAfford) == "function"
	then
		local ok, resetCost = pcall(function()
			return challengePassModule:GetResetCost(tonumber(challengePassData.GemResets) or 0)
		end)
		if ok and type(resetCost) == "table" then
			local canAffordOk, canAfford = pcall(function()
				return itemUtil:CanAfford(playerData, resetCost)
			end)
			if canAffordOk and canAfford == false then
				return false
			end
		end
	end
	return true
end
task.spawn(function()
	while isCurrentRun() do
		if Config.autoClaimChallengePassRewards then
			pcall(activeStates.ClaimChallengePassRewards)
		end
		task.wait(2)
	end
end)
task.spawn(function()
	while isCurrentRun() do
		if Config.autoResetChallengePass then
			if activeStates.ShouldResetChallengePass() then
				activeStates.TryResetChallengePass(false)
				task.wait(3)
			end
		end
		task.wait(2)
	end
end)
task.spawn(function()
	while isCurrentRun() do
		clearDisabledPriorityStates()
		if Config.autoChallengePassQuests ~= true then
			if activeStates.BGSI_Lite_ChallengePassActive then
				activeStates.BGSI_Lite_ChallengePassActive = false
				resumeNormalAutomation()
			end
			task.wait(0.5)
			continue
		end
		if
			activeStates.BGSI_Lite_GemGenieActive
			or activeStates.BGSI_Lite_SeasonActive
			or activeStates.BGSI_Lite_GlobalIncentiveActive
		then
			task.wait(0.5)
			continue
		end
		activeStates.BGSI_Lite_ChallengePassActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		local challengeQuestList = activeStates.GetChallengePassQuestList()
		if not activeStates.HasUnfinishedChallengePassQuest(challengeQuestList) then
			local hasSkippedChallengeQuest = false
			for _, challengeQuest in ipairs(challengeQuestList) do
				if activeStates.BGSI_Lite_HasSkippedTicketOrPearlTask(challengeQuest) or activeStates.BGSI_Lite_HasSkippedBubblingTask(challengeQuest) then
					hasSkippedChallengeQuest = true
					break
				end
			end
			if not hasSkippedChallengeQuest then
				if Config.autoClaimChallengePassRewards or Config.autoResetChallengePass then
					pcall(activeStates.ClaimChallengePassRewards)
				end
				if Config.autoResetChallengePass then
					activeStates.TryResetChallengePass(true)
				end
			end
			activeStates.BGSI_Lite_ChallengePassActive = false
			resumeNormalAutomation()
			task.wait(Config.autoResetChallengePass and 1 or 2)
			continue
		end
		for _, challengeQuest in ipairs(challengeQuestList) do
			if Config.autoChallengePassQuests ~= true then
				break
			end
			if
				activeStates.BGSI_Lite_GemGenieActive
				or activeStates.BGSI_Lite_SeasonActive
				or activeStates.BGSI_Lite_GlobalIncentiveActive
			then
				break
			end
			local challengeQuestId = challengeQuest.Id or challengeQuest.ID
			for _, taskIndex in ipairs(makeIndexList(challengeQuest.Tasks)) do
				if Config.autoChallengePassQuests ~= true then
					break
				end
				local challengeTask = challengeQuest.Tasks[taskIndex]
				if type(challengeTask) == "table" then
					local taskRequirement = getBountyTaskRequirement(challengeTask)
					local taskProgress = getBountyTaskProgress(challengeQuest, taskIndex)
					if
						type(taskRequirement) == "number"
						and taskProgress < taskRequirement
						and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(challengeTask)
						and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(challengeTask)
						and not activeStates.BGSI_Lite_IsQuestTaskDeferred(challengeQuest, taskIndex)
					then
						local shouldContinueChallengePass = function()
							return Config.autoChallengePassQuests == true
								and not activeStates.BGSI_Lite_GemGenieActive
								and not activeStates.BGSI_Lite_SeasonActive
								and not activeStates.BGSI_Lite_GlobalIncentiveActive
						end
						local getChallengeQuest = function()
							return activeStates.GetChallengePassQuestById(challengeQuestId)
						end
						activeStates.BGSI_Lite_RunQuestTask(
							getChallengeQuest,
							taskIndex,
							taskRequirement,
							shouldContinueChallengePass
						)
					end
				end
			end
		end
		task.wait(0.5)
	end
end)
task.spawn(function()
	while isCurrentRun() do
		if Config.autoClaimGlobalIncentive then
			pcall(function()
				remoteEvent:FireServer("ClaimGlobalIncentiveQuest")
				for loopSlotDK = 1, 10 do
					remoteEvent:FireServer("ClaimGlobalIncentives", loopSlotDK)
				end
			end)
		end
		task.wait(1)
	end
end)
activeStates.BGSI_Lite_GetShadowLeviathanQuestModule = function()
	if activeStates.BGSI_Lite_ShadowLeviathanQuestModule == nil then
		local ok, questFn = pcall(require, ReplicatedStorage.Shared.Data.Quests.ShadowLeviathanQuest)
		activeStates.BGSI_Lite_ShadowLeviathanQuestModule = (ok and questFn) or false
	end
	local questFn = activeStates.BGSI_Lite_ShadowLeviathanQuestModule
	return questFn ~= false and questFn or nil
end
activeStates.BGSI_Lite_GetActiveShadowLeviathanQuest = function()
	if type(questModule) ~= "table" or type(sharedConstants) ~= "table" then
		return nil
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" then
		return nil
	end
	return questModule:FindById(playerData, sharedConstants.ShadowLeviathanQuestKey)
end
activeStates.BGSI_Lite_ShadowLeviathanCandidateHasGoodReward = function(candidateQuest)
	if type(candidateQuest) ~= "table" or type(candidateQuest.Rewards) ~= "table" then
		return false
	end
	for _, reward in ipairs(candidateQuest.Rewards) do
		if type(reward) == "table" then
			if reward.Type == "Pet" and reward.Name == "Ancient Shadow Leviathan" then
				return true
			end
			if
				reward.Type == "Powerup"
				and (
					reward.Name == "Purple Fragment"
					or reward.Name == "Green Fragment"
					or reward.Name == "Blue Fragment"
				)
			then
				return true
			end
		end
	end
	return false
end
activeStates.BGSI_Lite_RunShadowLeviathanAutomation = function()
	if Config.autoShadowLeviathanQuest ~= true or Config.safeMode == true then
		return
	end
	local questFn = activeStates.BGSI_Lite_GetShadowLeviathanQuestModule()
	if type(questFn) ~= "function" then
		return
	end
	local playerData = profileStore:IsReady() and profileStore:Get() or nil
	if type(playerData) ~= "table" or type(playerData.ShadowLeviathan) ~= "table" then
		return
	end

	local activeQuest = activeStates.BGSI_Lite_GetActiveShadowLeviathanQuest()
	if type(activeQuest) == "table" then
		for _, taskIndex in ipairs(makeIndexList(activeQuest.Tasks)) do
			if Config.autoShadowLeviathanQuest ~= true then
				break
			end
			local questTask = activeQuest.Tasks[taskIndex]
			if type(questTask) == "table" then
				local requirement = getBountyTaskRequirement(questTask)
				local progress = getBountyTaskProgress(activeQuest, taskIndex)
				if
					type(requirement) == "number"
					and progress < requirement
					and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(questTask)
					and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(questTask)
					and not activeStates.BGSI_Lite_IsQuestTaskDeferred(activeQuest, taskIndex)
				then
					activeStates.BGSI_Lite_RunQuestTask(
						activeStates.BGSI_Lite_GetActiveShadowLeviathanQuest,
						taskIndex,
						requirement,
						function()
							return Config.autoShadowLeviathanQuest == true and Config.safeMode ~= true
						end
					)
				end
			end
		end
		return
	end

	local nextAt = tonumber(playerData.ShadowLeviathan.Next) or 0
	if getCurrentTimestamp() < nextAt then
		return
	end
	local seed = tonumber(playerData.ShadowLeviathan.Seed) or 0
	local candidates = {}
	for candidateIndex = 1, 3 do
		local ok, candidate = pcall(questFn, playerData, seed + candidateIndex - 1)
		if ok and type(candidate) == "table" then
			candidates[candidateIndex] = candidate
		end
	end
	if not candidates[1] then
		return
	end

	-- Same setup as Gem Genie: Optimised mode ignores the target item and only wants a
	-- quest whose tasks are all hatch-type; otherwise pick whichever of the 3 candidates
	-- actually offers the configured target reward (checking each reward's Name/Currency/
	-- Item, same match Gem Genie's own target picker uses), falling back to whichever one
	-- offers the Leviathan pet or a good Fragment if no candidate matches the target.
	local bestIndex
	if Config.optimisedShadowLeviathanQuest == true then
		for candidateIndex = 1, 3 do
			local candidate = candidates[candidateIndex]
			if type(candidate) == "table" and type(candidate.Tasks) == "table" then
				local allHatchTasks = true
				for _, questTask in pairs(candidate.Tasks) do
					if type(questTask) == "table" and not isHatchBountyTask(questTask) then
						allHatchTasks = false
						break
					end
				end
				if allHatchTasks then
					bestIndex = candidateIndex
					break
				end
			end
		end
	elseif type(Config.shadowLeviathanTargetItem) == "string" and Config.shadowLeviathanTargetItem ~= "" then
		local targetLower = string.lower(Config.shadowLeviathanTargetItem)
		for candidateIndex = 1, 3 do
			local candidate = candidates[candidateIndex]
			if type(candidate) == "table" and type(candidate.Rewards) == "table" then
				for _, reward in ipairs(candidate.Rewards) do
					if type(reward) == "table" then
						local rewardName = reward.Name or reward.Currency or reward.Item
						if type(rewardName) == "string" and string.lower(rewardName) == targetLower then
							bestIndex = candidateIndex
							break
						end
					end
				end
			end
			if bestIndex then
				break
			end
		end
	end

	if not bestIndex then
		for candidateIndex = 1, 3 do
			if
				candidates[candidateIndex]
				and activeStates.BGSI_Lite_ShadowLeviathanCandidateHasGoodReward(candidates[candidateIndex])
			then
				bestIndex = candidateIndex
				break
			end
		end
	end

	if not bestIndex and Config.autoRerollShadowLeviathanQuest == true and type(itemUtil) == "table" then
		local rerollCost = sharedConstants.ShadowLeviathanReroll
		local ownedAmount, requiredAmount = 0, math.huge
		pcall(function()
			ownedAmount = tonumber(itemUtil:GetOwnedAmount(playerData, rerollCost)) or 0
			requiredAmount = tonumber(itemUtil:GetAmount(rerollCost)) or math.huge
		end)
		if
			ownedAmount >= requiredAmount
			and tick() - (tonumber(activeStates.BGSI_Lite_LastShadowLeviathanRerollAt) or 0) >= 2
		then
			activeStates.BGSI_Lite_LastShadowLeviathanRerollAt = tick()
			pcall(activeStates.BGSI_Lite_FireGameRemote, "RerollLeviathan")
			return
		end
	end

	pcall(activeStates.BGSI_Lite_FireGameRemote, "StartLeviathanQuest", bestIndex or 1)
end
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.autoShadowLeviathanQuest and 2 or 0.85)
		pcall(activeStates.BGSI_Lite_RunShadowLeviathanAutomation)
	end
end)
end,
function(...)
xpcall(activeStates.BGSI_Lite_InstallGuildFeatures, function(installError)
	warn("[1rzHub Lite] Guild features failed to load: " .. tostring(installError))
end)
end,
function(...)
xpcall(activeStates.BGSI_Lite_InstallServerTab, function(installError)
	warn("[1rzHub Lite] Server tab failed to load: " .. tostring(installError))
end)
function getGemGenieQuestData()
	if not profileStore:IsReady() then
		return nil
	end
	local scriptStateOO = profileStore:Get()
	if not scriptStateOO then
		return nil
	end
	local scriptStateZS = scriptStateOO.GemGenie
	if type(scriptStateZS) == "table" then
		if type(scriptStateZS.Quest) == "table" then
			local scriptStateAEQ = scriptStateZS.Quest
			if
				(scriptStateAEQ.Completed == false or scriptStateAEQ.Completed == nil)
				and type(scriptStateAEQ.Tasks) == "table"
				and next(scriptStateAEQ.Tasks)
			then
				return scriptStateAEQ
			end
		end
		if type(scriptStateZS.ActiveQuest) == "table" then
			local scriptStateUE = scriptStateZS.ActiveQuest
			if scriptStateUE.Completed == false or scriptStateUE.Completed == nil then
				return scriptStateUE
			end
		end
	end
	if questModule and type(questModule.FindById) == "function" then
		local scriptStateRJ, scriptStateRN = pcall(function()
			return questModule:FindById(scriptStateOO, "gem-genie")
		end)
		if scriptStateRJ and scriptStateRN and (scriptStateRN.Completed == false or scriptStateRN.Completed == nil) then
			return scriptStateRN
		end
	end
	return nil
end
function gemGenieNormalizeTarget(value)
	if type(value) ~= "string" then
		return ""
	end
	return string.lower((value:gsub("^%s+", ""):gsub("%s+$", "")))
end
function gemGenieValueMatchesTarget(value, target)
	local targetLower = gemGenieNormalizeTarget(target)
	if targetLower == "" then
		return false
	end
	if type(value) == "string" then
		local valueLower = gemGenieNormalizeTarget(value)
		return valueLower == targetLower
			or valueLower:gsub("%s+item$", "") == targetLower:gsub("%s+item$", "")
	end
	return false
end
function gemGenieRewardMatchesTarget(reward, target, depth, visited)
	if type(reward) ~= "table" then
		return gemGenieValueMatchesTarget(reward, target)
	end
	depth = depth or 0
	if depth > 8 then
		return false
	end
	visited = visited or {}
	if visited[reward] then
		return false
	end
	visited[reward] = true
	for key, value in pairs(reward) do
		if type(key) == "string" and type(value) == "string" then
			if
				(key == "Name" or key == "name" or key == "Item" or key == "item"
					or key == "Reward" or key == "reward" or key == "Currency" or key == "currency"
					or key == "Id" or key == "id")
				and gemGenieValueMatchesTarget(value, target)
			then
				return true
			end
		elseif type(value) == "table" and gemGenieRewardMatchesTarget(value, target, depth + 1, visited) then
			return true
		end
	end
	return false
end
function gemGenieQuestMatchesTarget(questData, target)
	if type(questData) ~= "table" or gemGenieNormalizeTarget(target) == "" then
		return false
	end
	if type(questData.Rewards) == "table" then
		for _, reward in pairs(questData.Rewards) do
			if gemGenieRewardMatchesTarget(reward, target) then
				return true
			end
		end
	end
	return gemGenieRewardMatchesTarget(questData.Reward, target)
end
function getQuestTaskByType(scriptStateQM, scriptStateJZ, scriptStateS)
	local scriptStateBI, scriptStatePY = pcall(function()
		return require(ReplicatedStorage.Shared.Data.Quests.GenieQuest)
	end)
	if not scriptStateBI or type(scriptStatePY) ~= "function" then
		return nil
	end
	for loopSlotBW = 1, 3 do
		local scriptStateTG, scriptStateYD = pcall(scriptStatePY, scriptStateQM, scriptStateJZ + (loopSlotBW - 1))
		if
			scriptStateTG
			and type(scriptStateYD) == "table"
			and type(scriptStateYD.Rewards) == "table"
			and not activeStates.BGSI_Lite_HasSkippedTicketOrPearlTask(scriptStateYD)
			and not activeStates.BGSI_Lite_HasSkippedBubblingTask(scriptStateYD)
			and gemGenieQuestMatchesTarget(scriptStateYD, scriptStateS)
		then
			return loopSlotBW, scriptStateYD
		end
	end
	return nil
end
function runGemGenieTask(loopSlotAE, scriptStateWA)
	local loopSlotAT, scriptStateLY = pcall(function()
		return require(ReplicatedStorage.Shared.Data.Quests.GenieQuest)
	end)
	if not loopSlotAT or type(scriptStateLY) ~= "function" then
		return nil
	end
	for loopSlotDV = 1, 3 do
		local scriptStateJW, scriptStateADH = pcall(scriptStateLY, loopSlotAE, scriptStateWA + (loopSlotDV - 1))
		if scriptStateJW and type(scriptStateADH) == "table" and type(scriptStateADH.Tasks) == "table" then
			local scriptStateMM = true
			for loopSlotDE, scriptStateHG in pairs(scriptStateADH.Tasks) do
				if type(scriptStateHG) == "table" and not isHatchBountyTask(scriptStateHG) then
					scriptStateMM = false
					break
				end
			end
			if scriptStateMM then
				return loopSlotDV, scriptStateADH
			end
		end
	end
	return nil
end
task.spawn(function()
	while isCurrentRun() do
		clearDisabledPriorityStates()
		if not Config.autoGemGenie then
			if activeStates.BGSI_Lite_GemGenieActive then
				activeStates.BGSI_Lite_GemGenieActive = false
				resumeNormalAutomation()
			end
			task.wait(0.5)
			continue
		end
		local scriptStateMU = getGemGenieQuestData()
		if not scriptStateMU then
			local scriptStateXX, scriptStateLE = pcall(function()
				return profileStore:Get()
			end)
			if not scriptStateXX or not scriptStateLE then
				task.wait(1)
				continue
			end
			local scriptStateH = scriptStateLE.GemGenie or {}
			local scriptStateSC = tonumber(scriptStateH.Next) or 0
			local scriptStateSB = getCurrentTimestamp()
			if scriptStateSC > scriptStateSB then
				activeStates.BGSI_Lite_GemGenieActive = false
				resumeNormalAutomation()
				task.wait(1)
				continue
			end
			local scriptStateCA = tonumber(scriptStateH.Seed) or 0
			local scriptStateGR, scriptStateXF
			if Config.optimisedGemGenie then
				scriptStateGR, scriptStateXF = runGemGenieTask(scriptStateLE, scriptStateCA)
			else
				scriptStateGR, scriptStateXF =
					getQuestTaskByType(scriptStateLE, scriptStateCA, Config.gemGenieTargetItem or "")
			end
			if scriptStateGR then
				pcall(function()
					remoteEvent:FireServer("StartGenieQuest", scriptStateGR)
				end)
				task.wait(2)
			else
				pcall(function()
					remoteEvent:FireServer("RerollGenie")
				end)
				task.wait(0.5)
			end
			continue
		end
		-- If the selected target changed while an old/random Gem Genie quest was active,
		-- do not work that old quest. Reroll it until the active quest actually rewards
		-- the item the user selected (unless Optimised mode is intentionally enabled).
		if not Config.optimisedGemGenie and type(Config.gemGenieTargetItem) == "string" and Config.gemGenieTargetItem ~= "" then
			if type(scriptStateMU.Rewards) == "table" and not gemGenieQuestMatchesTarget(scriptStateMU, Config.gemGenieTargetItem) then
				pcall(function()
					remoteEvent:FireServer("RerollGenie")
				end)
				activeStates.BGSI_Lite_GemGenieActive = false
				resumeNormalAutomation()
				task.wait(0.75)
				continue
			end
		end
		if (activeStates.BGSI_Lite_HasSkippedTicketOrPearlTask(scriptStateMU) or activeStates.BGSI_Lite_HasSkippedBubblingTask(scriptStateMU))
			and not activeStates.BGSI_Lite_HasActionableUnfinishedQuestTask(scriptStateMU)
		then
			pcall(function()
				remoteEvent:FireServer("RerollGenie")
			end)
			activeStates.BGSI_Lite_GemGenieActive = false
			resumeNormalAutomation()
			task.wait(2)
			continue
		end
		-- Hard safety net, independent of the per-task stall/skip logic above: if the
		-- exact same quest sits here with its total progress never moving forward for
		-- several minutes - whatever the reason (a task whose progress this script reads
		-- wrong, a stall that should have rerolled but didn't land, anything) - force a
		-- reroll instead of leaving the player parked on a dead quest indefinitely.
		do
			local questWatchdogId = tostring(scriptStateMU.Id or scriptStateMU.ID or scriptStateMU.Name or "")
			local totalProgress = 0
			for _, watchdogTaskIndex in ipairs(makeIndexList(scriptStateMU.Tasks)) do
				totalProgress += math.max(0, getBountyTaskProgress(scriptStateMU, watchdogTaskIndex))
			end
			if
				questWatchdogId ~= tostring(activeStates.BGSI_Lite_GemGenieWatchdogQuestId or "")
				or totalProgress > (tonumber(activeStates.BGSI_Lite_GemGenieWatchdogProgress) or -1)
			then
				activeStates.BGSI_Lite_GemGenieWatchdogQuestId = questWatchdogId
				activeStates.BGSI_Lite_GemGenieWatchdogProgress = totalProgress
				activeStates.BGSI_Lite_GemGenieWatchdogSince = tick()
			elseif tick() - (tonumber(activeStates.BGSI_Lite_GemGenieWatchdogSince) or tick()) >= 240 then
				warn(
					"[1rzHub Lite] Gem Genie quest made no progress at all for 4 minutes; forcing a reroll:",
					questWatchdogId
				)
				pcall(function()
					remoteEvent:FireServer("RerollGenie")
				end)
				activeStates.BGSI_Lite_GemGenieWatchdogQuestId = nil
				activeStates.BGSI_Lite_GemGenieWatchdogProgress = nil
				activeStates.BGSI_Lite_GemGenieActive = false
				resumeNormalAutomation()
				task.wait(2)
				continue
			end
		end
		activeStates.BGSI_Lite_GemGenieActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		for loopSlotDF, scriptStateBJ in ipairs(makeIndexList(scriptStateMU.Tasks)) do
			if not Config.autoGemGenie then
				break
			end
			local scriptStateWX = scriptStateMU.Tasks[scriptStateBJ]
			if type(scriptStateWX) == "table" then
				local scriptStateGT = getBountyTaskRequirement(scriptStateWX)
				local scriptStateJI = getBountyTaskProgress(scriptStateMU, scriptStateBJ)
				if
					scriptStateJI < scriptStateGT
					and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateWX)
					and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(scriptStateWX)
					and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateMU, scriptStateBJ)
				then
					local fallbackUtilityD = function()
						return Config.autoGemGenie == true
					end
					local fallbackUtilityB = function()
						return getGemGenieQuestData()
					end
					activeStates.BGSI_Lite_RunQuestTask(
						fallbackUtilityB,
						scriptStateBJ,
						scriptStateGT,
						fallbackUtilityD
					)
				end
			end
		end
		task.wait(0.5)
	end
end)
activeStates.BGSI_Lite_IsQuestFullyComplete = function(questData)
	if type(questData) ~= "table" then
		return false
	end
	if type(questData.Tasks) ~= "table" then
		return questData.Completed == true
	end
	local sawTask = false
	for _, taskIndex in ipairs(makeIndexList(questData.Tasks)) do
		local questTask = questData.Tasks[taskIndex]
		if type(questTask) == "table" then
			sawTask = true
			if getBountyTaskProgress(questData, taskIndex) < getBountyTaskRequirement(questTask) then
				return false
			end
		end
	end
	if sawTask then
		return true
	end
	return questData.Completed == true
end
activeStates.BGSI_Lite_ClaimSeasonChallengeQuest = function(challengeQuestId)
	if type(challengeQuestId) ~= "string" or challengeQuestId == "" then
		return
	end
	for _, actionName in ipairs({
		"ClaimQuest",
		"ClaimChallenge",
		"ClaimDailyChallenge",
		"ClaimHourlyChallenge",
		"ClaimBounty",
		"ClaimQuestReward",
		"ClaimChallengeReward",
	}) do
		pcall(function()
			remoteEvent:FireServer(actionName, challengeQuestId)
		end)
	end
end
function stopGemGenieAutomation()
	local scriptStateFE = {}
	if not profileStore:IsReady() then
		return scriptStateFE
	end
	local playerData = profileStore:Get()
	if not playerData then
		return scriptStateFE
	end
	for _, challengeType in ipairs({ "hourly", "daily" }) do
		for challengeIndex = 1, 3 do
			local challengeId = challengeType .. "-challenge-" .. tostring(challengeIndex)
			local challengeQuest
			if questModule and type(questModule.FindById) == "function" then
				local questOk, questResult = pcall(function()
					return questModule:FindById(playerData, challengeId)
				end)
				if questOk and type(questResult) == "table" then
					challengeQuest = questResult
				end
			end
			if not challengeQuest and type(playerData.Quests) == "table" then
				for _, questData in pairs(playerData.Quests) do
					if
						type(questData) == "table"
						and (questData.Id == challengeId or questData.ID == challengeId)
					then
						challengeQuest = questData
						break
					end
				end
			end
			if
				type(challengeQuest) == "table"
				and challengeQuest.Claimed ~= true
				and type(challengeQuest.Tasks) == "table"
			then
				challengeQuest.Id = challengeQuest.Id or challengeQuest.ID or challengeId
				table.insert(scriptStateFE, challengeQuest)
			end
		end
	end
	return scriptStateFE
end
function runSeasonChallengeTask(scriptStateSN)
	if not profileStore:IsReady() then
		return nil
	end
	local scriptStateDR = profileStore:Get()
	if questModule and type(questModule.FindById) == "function" then
		local scriptStateADW, scriptStateMP = pcall(function()
			return questModule:FindById(scriptStateDR, scriptStateSN)
		end)
		if scriptStateADW and scriptStateMP then
			return scriptStateMP
		end
	end
	for loopSlotAR, scriptStateHS in ipairs({
		scriptStateDR and scriptStateDR.Quests,
		scriptStateDR and scriptStateDR.ActiveQuests,
	}) do
		if type(scriptStateHS) == "table" then
			for loopSlotAP, scriptStateIJ in pairs(scriptStateHS) do
				if
					type(scriptStateIJ) == "table"
					and (scriptStateIJ.Id == scriptStateSN or scriptStateIJ.ID == scriptStateSN)
				then
					return scriptStateIJ
				end
			end
		end
	end
	return nil
end
task.spawn(function()
	while isCurrentRun() do
		if not Config.autoDailyHourlyChallenge then
			if activeStates.BGSI_Lite_SeasonActive then
				activeStates.BGSI_Lite_SeasonActive = false
				resumeNormalAutomation()
			end
			task.wait(0.5)
			continue
		end
		if activeStates.BGSI_Lite_GemGenieActive then
			task.wait(0.5)
			continue
		end
		local seasonListOk, scriptStateSA = pcall(stopGemGenieAutomation)
		if not seasonListOk or type(scriptStateSA) ~= "table" then
			activeStates.BGSI_Lite_SeasonActive = false
			resumeNormalAutomation()
			task.wait(1)
			continue
		end
		if #scriptStateSA == 0 then
			activeStates.BGSI_Lite_SeasonActive = false
			resumeNormalAutomation()
			task.wait(2)
			continue
		end
		local scriptStateWQ = false
		for loopSlotAH, scriptStateAAE in ipairs(scriptStateSA) do
			if activeStates.BGSI_Lite_IsQuestFullyComplete(scriptStateAAE) then
				scriptStateWQ = true
				break
			end
			for loopSlotAW, scriptStateTB in ipairs(makeIndexList(scriptStateAAE.Tasks)) do
				local scriptStateWO = scriptStateAAE.Tasks[scriptStateTB]
				if type(scriptStateWO) == "table" then
					local scriptStateCW = getBountyTaskRequirement(scriptStateWO)
					local scriptStateUP = getBountyTaskProgress(scriptStateAAE, scriptStateTB)
					if scriptStateUP < scriptStateCW
						and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateWO)
						and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(scriptStateWO)
						and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateAAE, scriptStateTB)
					then
						scriptStateWQ = true
						break
					end
				end
			end
			if scriptStateWQ then
				break
			end
		end
		if not scriptStateWQ then
			activeStates.BGSI_Lite_SeasonActive = false
			resumeNormalAutomation()
			task.wait(2)
			continue
		end
		activeStates.BGSI_Lite_SeasonActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		for loopSlotDL, scriptStateZC in ipairs(scriptStateSA) do
			if not Config.autoDailyHourlyChallenge then
				break
			end
			if activeStates.BGSI_Lite_GemGenieActive then
				break
			end
			local scriptStateKZ = scriptStateZC.Id or scriptStateZC.ID
			if activeStates.BGSI_Lite_IsQuestFullyComplete(scriptStateZC) then
				pcall(activeStates.BGSI_Lite_ClaimSeasonChallengeQuest, scriptStateKZ)
				task.wait(0.2)
			else
				for loopSlotBA, scriptStateAC in ipairs(makeIndexList(scriptStateZC.Tasks)) do
					if not Config.autoDailyHourlyChallenge then
						break
					end
					if activeStates.BGSI_Lite_GemGenieActive then
						break
					end
					local scriptStateDY = scriptStateZC.Tasks[scriptStateAC]
					if type(scriptStateDY) == "table" then
						local scriptStateADS = getBountyTaskRequirement(scriptStateDY)
						local scriptStateTP = getBountyTaskProgress(scriptStateZC, scriptStateAC)
						if
							scriptStateTP < scriptStateADS
							and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateDY)
							and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(scriptStateDY)
							and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateZC, scriptStateAC)
						then
							local fallbackUtilityA = function()
								return Config.autoDailyHourlyChallenge and not activeStates.BGSI_Lite_GemGenieActive
							end
							local fallbackUtilityG = function()
								return runSeasonChallengeTask(scriptStateKZ)
							end
							local taskOk = pcall(
								activeStates.BGSI_Lite_RunQuestTask,
								fallbackUtilityG,
								scriptStateAC,
								scriptStateADS,
								fallbackUtilityA
							)
							if not taskOk then
								activeStates.BGSI_Lite_ClearActiveQuest(scriptStateZC, scriptStateAC)
								break
							end
						end
					end
				end
			end
		end
		task.wait(0.5)
	end
end)
function getSeasonQuestList()
	local scriptStateAAV = {}
	if not profileStore:IsReady() then
		return scriptStateAAV
	end
	local scriptStateUQ = profileStore:Get()
	if not scriptStateUQ then
		return scriptStateAAV
	end
	local scriptStateIE = {}
	for loopSlotCM, scriptStateCV in ipairs({
		scriptStateUQ.Quests,
		scriptStateUQ.ActiveQuests,
	}) do
		if type(scriptStateCV) == "table" then
			for loopSlotAN, scriptStateACG in pairs(scriptStateCV) do
				if type(scriptStateACG) == "table" then
					local scriptStateWY = scriptStateACG.Id or scriptStateACG.ID
					if type(scriptStateWY) == "string" and scriptStateWY:sub(1, 17) == "global-incentive-" then
						if
							not scriptStateIE[scriptStateWY]
							and (scriptStateACG.Completed == false or scriptStateACG.Completed == nil)
						then
							scriptStateIE[scriptStateWY] = true
							table.insert(scriptStateAAV, scriptStateACG)
						end
					end
				end
			end
		end
	end
	return scriptStateAAV
end
function runGlobalIncentiveTask(scriptStateGG)
	if not profileStore:IsReady() then
		return nil
	end
	local scriptStateZN = profileStore:Get()
	if questModule and type(questModule.FindById) == "function" then
		local scriptStateEC, scriptStateAEW = pcall(function()
			return questModule:FindById(scriptStateZN, scriptStateGG)
		end)
		if scriptStateEC and scriptStateAEW then
			return scriptStateAEW
		end
	end
	for loopSlotAK, scriptStateQD in ipairs({
		scriptStateZN and scriptStateZN.Quests,
		scriptStateZN and scriptStateZN.ActiveQuests,
	}) do
		if type(scriptStateQD) == "table" then
			for loopSlotA, scriptStateGL in pairs(scriptStateQD) do
				if
					type(scriptStateGL) == "table"
					and (scriptStateGL.Id == scriptStateGG or scriptStateGL.ID == scriptStateGG)
				then
					return scriptStateGL
				end
			end
		end
	end
	return nil
end
task.spawn(function()
	while isCurrentRun() do
		if not Config.autoGlobalIncentive then
			if activeStates.BGSI_Lite_GlobalIncentiveActive then
				activeStates.BGSI_Lite_GlobalIncentiveActive = false
				resumeNormalAutomation()
			end
			task.wait(0.5)
			continue
		end
		if activeStates.BGSI_Lite_GemGenieActive or activeStates.BGSI_Lite_SeasonActive then
			task.wait(0.5)
			continue
		end
		local scriptStateEW = getSeasonQuestList()
		if #scriptStateEW == 0 then
			activeStates.BGSI_Lite_GlobalIncentiveActive = false
			resumeNormalAutomation()
			task.wait(3)
			continue
		end
		local scriptStateRM = false
		for loopSlotD, scriptStateAFT in ipairs(scriptStateEW) do
			for loopSlotCA, scriptStateWC in ipairs(makeIndexList(scriptStateAFT.Tasks)) do
				local scriptStateJA = scriptStateAFT.Tasks[scriptStateWC]
				if type(scriptStateJA) == "table" then
					local scriptStateLR = getBountyTaskRequirement(scriptStateJA)
					local scriptStateGF = getBountyTaskProgress(scriptStateAFT, scriptStateWC)
					if scriptStateGF < scriptStateLR
						and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateJA)
						and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(scriptStateJA)
						and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateAFT, scriptStateWC)
					then
						scriptStateRM = true
						break
					end
				end
			end
			if scriptStateRM then
				break
			end
		end
		if not scriptStateRM then
			activeStates.BGSI_Lite_GlobalIncentiveActive = false
			resumeNormalAutomation()
			task.wait(3)
			continue
		end
		activeStates.BGSI_Lite_GlobalIncentiveActive = true
		activeStates.BGSI_Lite_LastQuestAutomationAt = tick()
		pauseNormalAutomation()
		for loopSlotZ, scriptStateVX in ipairs(scriptStateEW) do
			if not Config.autoGlobalIncentive then
				break
			end
			if activeStates.BGSI_Lite_GemGenieActive or activeStates.BGSI_Lite_SeasonActive then
				break
			end
			local scriptStateHW = scriptStateVX.Id or scriptStateVX.ID
			for loopSlotK, scriptStateADB in ipairs(makeIndexList(scriptStateVX.Tasks)) do
				if not Config.autoGlobalIncentive then
					break
				end
				if activeStates.BGSI_Lite_GemGenieActive or activeStates.BGSI_Lite_SeasonActive then
					break
				end
				local scriptStateAFI = scriptStateVX.Tasks[scriptStateADB]
				if type(scriptStateAFI) == "table" then
					local scriptStateSF = getBountyTaskRequirement(scriptStateAFI)
					local scriptStateR = getBountyTaskProgress(scriptStateVX, scriptStateADB)
					if
						scriptStateR < scriptStateSF
						and not activeStates.BGSI_Lite_ShouldSkipTicketOrPearlQuest(scriptStateAFI)
						and not activeStates.BGSI_Lite_ShouldSkipBubblingQuest(scriptStateAFI)
						and not activeStates.BGSI_Lite_IsQuestTaskDeferred(scriptStateVX, scriptStateADB)
					then
						local fallbackUtilityC = function()
							return Config.autoGlobalIncentive
								and not activeStates.BGSI_Lite_GemGenieActive
								and not activeStates.BGSI_Lite_SeasonActive
						end
						local fallbackUtilityF = function()
							return runGlobalIncentiveTask(scriptStateHW)
						end
						activeStates.BGSI_Lite_RunQuestTask(
							fallbackUtilityF,
							scriptStateADB,
							scriptStateSF,
							fallbackUtilityC
						)
					end
				end
			end
		end
		task.wait(0.5)
	end
end)
end,
function(...)
task.spawn(function()
	while isCurrentRun() do
		task.wait(Config.DreamerShrineEnabled and 15 or 0.85)
		if not Config.DreamerShrineEnabled then
			continue
		end
		if not activeStates.BGSI_Lite_DreamerShrineUtil then
			pcall(function()
				activeStates.BGSI_Lite_DreamerShrineUtil =
					require(ReplicatedStorage.Shared.Utils.DreamerShrineUtil)
			end)
		end
		local dreamerShrineUtil = activeStates.BGSI_Lite_DreamerShrineUtil
		local playerData = profileStore:IsReady() and profileStore:Get() or nil
		local dreamerShrine = type(playerData) == "table" and playerData.DreamerShrine or nil
		if type(dreamerShrineUtil) ~= "table" or type(dreamerShrine) ~= "table" then
			continue
		end
		local currentTimestamp = getCurrentTimestamp()
		local donationInterval = tonumber(dreamerShrineUtil.DONATION_INTERVAL) or 3600
		if currentTimestamp < (tonumber(dreamerShrine.LastDonationTime) or 0) + donationInterval then
			continue
		end
		local blessingEndTime = tonumber(dreamerShrine.ShrineBlessingEndTime)
		if not blessingEndTime or currentTimestamp < blessingEndTime then
			continue -- An hourly donation cooldown does not mean the blessing needs renewing.
		end
		local configuredAmount = math.clamp(math.floor(tonumber(Config.DreamerShrineAmount) or 15), 1, 15)
		local ownedShards = type(activeStates.BGSI_Lite_GetInventoryItemAmount) == "function"
				and activeStates.BGSI_Lite_GetInventoryItemAmount("Dream Shard")
			or 0
		if
			ownedShards < configuredAmount
			and tick() >= (tonumber(activeStates.BGSI_Lite_NextDreamShardRestockAt) or 0)
			and type(activeStates.BGSI_Lite_SmartShopRestock) == "function"
		then
			local purchasedAmount = activeStates.BGSI_Lite_SmartShopRestock(
				"Powerup",
				"Dream Shard",
				nil,
				ownedShards <= 0
			)
			activeStates.BGSI_Lite_NextDreamShardRestockAt = tick() + (purchasedAmount > 0 and 15 or 60)
			playerData = profileStore:IsReady() and profileStore:Get() or playerData
			ownedShards = activeStates.BGSI_Lite_GetInventoryItemAmount("Dream Shard")
		end
		local donationAmount = math.min(configuredAmount, ownedShards)
		if donationAmount > 0 then
			local donationOk, donationAccepted =
				pcall(remoteFunction.InvokeServer, remoteFunction, "DonateToDreamerShrine", donationAmount)
			if
				donationOk
				and donationAccepted == true
				and type(activeStates.BGSI_Lite_LogDashboardAction) == "function"
			then
				activeStates.BGSI_Lite_LogDashboardAction(
					"Donated "
						.. tostring(donationAmount)
						.. " Dream Shard"
						.. (donationAmount == 1 and "" or "s"),
					"collect"
				)
			end
		end
	end
end)
task.spawn(function()
	local bubbleShrineUtil
	pcall(function()
		bubbleShrineUtil = require(ReplicatedStorage.Shared.Utils.ShrineUtil)
	end)
	while isCurrentRun() do
		if Config.shrineAuto then
			local playerData = profileStore:IsReady() and profileStore:Get() or nil
			local shrineState = type(playerData) == "table" and playerData.BubbleShrine
			local now = getCurrentTimestamp()
			local donationInterval = type(bubbleShrineUtil) == "table"
				and tonumber(bubbleShrineUtil.DONATION_INTERVAL) or 3600
			local blessingRemaining = type(shrineState) == "table"
				and math.max(0, (tonumber(shrineState.ShrineBlessingEndTime) or math.huge) - now) or math.huge
			if type(shrineState) == "table"
				and now >= (tonumber(shrineState.LastDonationTime) or 0) + donationInterval
				and blessingRemaining <= 0 then
			local potionItem = {
				Level = Config.shrineLevel,
				Type = "Potion",
				Name = Config.shrinePotion,
			}
			local amountOk, ownedAmount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, potionItem)
			ownedAmount = amountOk and math.max(0, math.floor(tonumber(ownedAmount) or 0)) or 0
			if
				ownedAmount <= 0
				and tick() >= (tonumber(activeStates.BGSI_Lite_NextBubbleShrineRestockAt) or 0)
				and type(activeStates.BGSI_Lite_SmartShopRestock) == "function"
			then
				local purchasedAmount = activeStates.BGSI_Lite_SmartShopRestock(
					"Potion",
					Config.shrinePotion,
					Config.shrineLevel,
					false
				)
				activeStates.BGSI_Lite_NextBubbleShrineRestockAt = tick()
					+ (purchasedAmount > 0 and 15 or 60)
				playerData = profileStore:IsReady() and profileStore:Get() or playerData
				amountOk, ownedAmount = pcall(itemUtil.GetOwnedAmount, itemUtil, playerData, potionItem)
				ownedAmount = amountOk and math.max(0, math.floor(tonumber(ownedAmount) or 0)) or 0
			end
			potionItem.Amount = math.min(
				ownedAmount,
				math.clamp(math.floor(tonumber(Config.shrineAmount) or 500), 0, 500)
			)
			if potionItem.Amount > 0 then
				pcall(remoteFunction.InvokeServer, remoteFunction, "DonateToShrine", potionItem)
			end
			end
		end
		task.wait(5)
	end
end)
function getShrinePotionName(scriptStateAFV)
	if not scriptStateAFV or scriptStateAFV == "" then
		return nil
	end
	local scriptStateAED = string.upper(scriptStateAFV):gsub("%s+", ""):gsub(",", "")
	local scriptStateOJ, scriptStateYQ = scriptStateAED:match("^(%d+%.?%d*)([KMBTQ]?)$")
	if not scriptStateOJ then
		return nil
	end
	local scriptStateNB = tonumber(scriptStateOJ)
	if not scriptStateNB then
		return nil
	end
	if scriptStateYQ == "K" then
		return scriptStateNB * 1e3
	end
	if scriptStateYQ == "M" then
		return scriptStateNB * 1e6
	end
	if scriptStateYQ == "B" then
		return scriptStateNB * 1e9
	end
	if scriptStateYQ == "T" then
		return scriptStateNB * 1e12
	end
	if scriptStateYQ == "Q" then
		return scriptStateNB * 1e15
	end
	return scriptStateNB
end
function getShrineLevelValue(loopSlotO)
	local scriptStateACS = {}
	if not loopSlotO or loopSlotO == "" then
		return scriptStateACS
	end
	for scriptStateFZ in string.gmatch(loopSlotO, "([^,]+)") do
		scriptStateFZ = scriptStateFZ:match("^%s*(.-)%s*$")
		if scriptStateFZ and scriptStateFZ ~= "" then
			table.insert(scriptStateACS, scriptStateFZ)
		end
	end
	return scriptStateACS
end
function getShrineAmountValue(scriptStateYW)
	scriptStateYW = tonumber(scriptStateYW) or 0
	local scriptStateABQ = {
		"",
		"K",
		"M",
		"B",
		"T",
		"Q",
	}
	local scriptStateEZ = 1
	while scriptStateYW >= 1000 and scriptStateEZ < #scriptStateABQ do
		scriptStateYW = scriptStateYW / 1000
		scriptStateEZ = scriptStateEZ + 1
	end
	return string.format("%.1f%s", scriptStateYW, scriptStateABQ[scriptStateEZ])
end
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
scriptStateDX = {
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
statsUtil, worldUtil = nil, nil
pcall(function()
	statsUtil = require(ReplicatedStorage.Shared.Utils.Stats.StatsUtil)
end)
pcall(function()
	worldUtil = require(ReplicatedStorage.Shared.Utils.WorldUtil)
end)
function getWebhookAvatarUrl(scriptStateWL)
	if type(scriptStateWL) ~= "number" or scriptStateWL ~= scriptStateWL then
		return "—"
	end
	return "x" .. formatWebhookNumber(scriptStateWL, 3)
end
activeStates.BGSI_Lite_GetWebhookPetStatValue = function(webhookStatValue)
	return "x" .. formatWebhookNumber(webhookStatValue, 4)
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
function getWebhookPingText()
	return getDiscordTimestamp().EggsHatched
end
activeStates.BGSI_Lite_PetChanceData = activeStates.BGSI_Lite_PetChanceData or {}
do
	for _, loader in ipairs({
		function()
			return require(ReplicatedStorage.Shared.Framework.Constants)
		end,
		function()
			return require(ReplicatedStorage.Shared.Constants)
		end,
	}) do
		local ok, value = pcall(loader)
		if ok and type(value) == "table" then
			local stack = { value }
			local seen = {}
			while #stack > 0 do
				local node = table.remove(stack)
				if type(node) == "table" and not seen[node] then
					seen[node] = true
					local petName = node.Pet
					local chance = nil
					if type(node.Chance) == "number" and node.Chance == node.Chance then
						chance = node.Chance
					elseif type(node.Chance) == "string" then
						chance = tonumber(node.Chance)
					end
					if type(petName) == "string" and petName ~= "" and chance then
						activeStates.BGSI_Lite_PetChanceData[petName] = chance
					end
					if type(node.Pets) == "table" then
						for _, petEntry in pairs(node.Pets) do
							if type(petEntry) == "table" then
								local entryName = petEntry.Pet or petEntry.Name
								local entryChance = nil
								if type(petEntry.Chance) == "number" and petEntry.Chance == petEntry.Chance then
									entryChance = petEntry.Chance
								elseif type(petEntry.Chance) == "string" then
									entryChance = tonumber(petEntry.Chance)
								end
								if type(entryName) == "string" and entryName ~= "" and entryChance then
									activeStates.BGSI_Lite_PetChanceData[entryName] = entryChance
								end
							end
						end
					end
					if
						type(node.Name) == "string"
						and (type(petName) ~= "string" or petName == "")
						and chance
					then
						local itemType = node.Type
						if
							itemType ~= "Powerup"
							and itemType ~= "Potion"
							and itemType ~= "Egg"
							and type(node.Cost) ~= "table"
						then
							if not (type(node.Interval) == "number" and type(node.Pets) == "table") then
								activeStates.BGSI_Lite_PetChanceData[node.Name] = chance
							end
						end
					end
					for _, child in pairs(node) do
						if type(child) == "table" then
							table.insert(stack, child)
						end
					end
				end
			end
		end
	end
end
function checkLowCurrencyWebhook(scriptStateAFQ, scriptStateDP)
	if type(scriptStateAFQ) == "string" and activeStates.BGSI_Lite_PetChanceData[scriptStateAFQ] then
		return activeStates.BGSI_Lite_PetChanceData[scriptStateAFQ]
	end
	if type(scriptStateDP) == "table" and type(scriptStateDP.Chance) == "number" then
		return scriptStateDP.Chance
	end
	return 100
end
function parseWebhookMinimumChance(value)
	local text = tostring(value or ""):lower():gsub("%s+", ""):gsub(",", "")
	if text == "" then return 0 end
	local numberText, suffix = text:match("^(%d*%.?%d+)([kmbt]?)$")
	local number = numberText and tonumber(numberText)
	if not number then return nil end
	local multipliers = {k = 1e3, m = 1e6, b = 1e9, t = 1e12}
	local result = number * (multipliers[suffix] or 1)
	if result ~= result or result == math.huge then return nil end
	return result
end
function meetsWebhookMinimumChance(name, info, shiny, mythic, xl, actualFinalPercent)
	local minimum = parseWebhookMinimumChance(Config.webhookMinimumChance)
	if not minimum then return false end
	if minimum == 0 then return true end
	local percent = tonumber(actualFinalPercent) or tonumber(checkLowCurrencyWebhook(name, info))
	if not percent or percent <= 0 or percent ~= percent or percent == math.huge then return false end
	local oneIn = 100 / percent
	if not actualFinalPercent then
		if shiny then oneIn = oneIn * 40 end
		if mythic then oneIn = oneIn * 100 end
		if xl then oneIn = oneIn * 400 end
	end
	-- Allow only floating-point rounding at the inclusive threshold boundary.
	return oneIn >= minimum * (1 - 1e-14)
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
function isWebhookRebirthMachineReward(petEntry, petInfo, sourceName)
	if sourceName == "Rebirth Machine" then return true end
	for _, data in pairs({entry = petEntry, info = petInfo}) do
		if type(data) == "table" then
			for _, key in ipairs({"Tag", "Origin", "Origins", "Source"}) do
				local value = data[key]
				if type(value) == "string" and value:lower():find("rebirth machine", 1, true) then
					return true
				end
			end
		end
	end
	return false
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
			webhookPetEntry.BGSI_Lite_DashboardExistingCount,
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
function sendPetWebhook(info,shiny,mythic)
    local resolver=activeStates.BGSI_Lite_WebhookPetIconResolver
    if type(resolver)~="table" or resolver.Revision~=1 or resolver.Owner~=currentRunToken then
        resolver=(function()
-- Resolve native pet image content into an HTTP image Discord can fetch.
return function(ctx)
    local cache,count={},0
    local function publicURL(value)
        return type(value)=="string" and value:match("^https?://") and value or nil
    end
    local function decode(body)
        if type(body)~="string" or body=="" then return nil end
        local ok,data=pcall(ctx.Decode,body)
        return ok and type(data)=="table" and data or nil
    end
    local function fetch(url,method,body)
        local ok,response=pcall(ctx.Request,{Url=url,Method=method or "GET",Body=body,
            Headers={Accept="application/json",["Content-Type"]="application/json"},Timeout=8})
        if ok and type(response)=="table" then
            local status=tonumber(response.StatusCode or response.Status or response.status_code)
            if (not status or (status>=200 and status<300)) and response.Success~=false then
                local data=decode(response.Body or response.body)
                if data then return data end
            end
        end
        if method=="POST" then return nil end
        for _,get in ipairs({ctx.HttpGet,ctx.GetAsync}) do
            local success,result=pcall(get,url)
            if success then local data=decode(result);if data then return data end end
        end
    end
    local function image(data,id)
        if type(data)~="table" then return nil end
        for _,entry in ipairs(type(data.data)=="table" and data.data or data) do
            if type(entry)=="table" and (entry.targetId==nil or tostring(entry.targetId)==id)
                and (entry.state==nil or entry.state=="Completed") then
                local url=publicURL(entry.imageUrl)
                if url then return url end
            end
        end
    end
    local function remember(id,url)
        if not cache[id] then
            if count>=256 then
                local oldest,age
                for key,entry in pairs(cache) do if not age or entry.used<age then oldest,age=key,entry.used end end
                if oldest then cache[oldest]=nil;count-=1 end
            end
            count+=1
        end
        cache[id]={url=url,expires=ctx.Now()+(url and 3600 or 15),used=ctx.Now()}
        return url
    end
    local function resolve(info,shiny,mythic)
        if type(info)~="table" then return nil end
        local images=info.Images
        local content
        if type(images)=="table" then
            if shiny and mythic then content=images.MythicShiny or images.ShinyMythic or images["Shiny Mythic"] or images[4]
            elseif shiny then content=images.Shiny or images[2]
            elseif mythic then content=images.Mythic or images[3]
            else content=images.Normal or images[1] end
            content=content or images.Normal or images[1]
            if not content then for i=2,4 do if images[i] then content=images[i];break end end end
            content=content or images.Shiny or images.Mythic or images.MythicShiny
        else content=images or info.Image or info.Icon end
        content=content or info.Image or info.Icon
        if content==nil then return nil end
        local text=(type(content)=="number" and content>0 and content<math.huge and string.format("%.0f",content)
            or tostring(content)):match("^%s*(.-)%s*$")
        local lower=text:lower()
        local id=lower:match("^rbxassetid://(%d+)$") or lower:match("^(%d+)$")
        if not id and lower:match("^rbxthumb://") then id=lower:match("[?&]id=(%d+)") end
        if not id and (lower:match("^https?://www%.roblox%.com/asset[/?]") or lower:match("^https?://roblox%.com/asset[/?]")) then
            id=lower:match("[?&]id=(%d+)")
        end
        if not id then return publicURL(text) end
        if not id:match("[1-9]") then return nil end
        local existing=cache[id]
        if existing and ctx.Now()<existing.expires then existing.used=ctx.Now();return existing.url end
        local url="https://thumbnails.roblox.com/v1/assets?assetIds="..id.."&size=420x420&format=Png&isCircular=false"
        for attempt=1,3 do
            local result=image(fetch(url),id)
            if result then return remember(id,result) end
            if attempt<3 then ctx.Wait(attempt*0.35) end
        end
        -- The batch endpoint can generate a missing asset thumbnail independently.
        local ok,body=pcall(ctx.Encode,{{requestId="pet-"..id,targetId=tonumber(id),type="Asset",size="420x420",format="Png",isCircular=false}})
        if ok then
            local result=image(fetch("https://thumbnails.roblox.com/v1/batch","POST",body),id)
            if result then return remember(id,result) end
        end
        return remember(id,nil)
    end
    return {Revision=1,Resolve=resolve}
end

        end)()({
            Request=function(options)
                local env=(getgenv and getgenv()) or _G
                local fn=type(request)=="function" and request or type(http_request)=="function" and http_request
                    or (type(syn)=="table" and type(rawget(syn,"request"))=="function" and rawget(syn,"request"))
                    or (type(rawget(env,"request"))=="function" and rawget(env,"request"))
                    or (type(rawget(env,"http_request"))=="function" and rawget(env,"http_request"))
                if type(fn)~="function" then
                    local http=rawget(env,"http")
                    fn=type(http)=="table" and rawget(http,"request") or nil
                end
                if type(fn)=="function" then return fn(options) end
            end,
            HttpGet=function(url) return game:HttpGet(url,true) end,
            GetAsync=function(url) return HttpService:GetAsync(url,true) end,
            Decode=function(body) return HttpService:JSONDecode(body) end,
            Encode=function(value) return HttpService:JSONEncode(value) end,
            Now=os.clock,Wait=task.wait,
        })
        resolver.Owner=currentRunToken
        activeStates.BGSI_Lite_WebhookPetIconResolver=resolver
    end
    return resolver.Resolve(info,shiny,mythic)
end
function getRebirthMachineCost(scriptStateKB)
	scriptStateKB = tostring(scriptStateKB or "")
	scriptStateKB = scriptStateKB:match("^%s*(.-)%s*$") or ""
	scriptStateKB = scriptStateKB:gsub("<@!?(%d+)>", "%1")
	scriptStateKB = scriptStateKB:gsub("%D", "")
	if #scriptStateKB < 15 then
		return nil
	end
	return scriptStateKB
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
function runRebirthFuse(scriptStateQZ, scriptStateACW, suppressPing)
	local scriptStateLH = request
		or http_request
		or (type(syn) == "table" and rawget(syn, "request"))
		or rawget((getgenv and getgenv()) or _G, "http_request")
	if type(scriptStateLH) ~= "function" then
		local httpTable = rawget((getgenv and getgenv()) or _G, "http")
		scriptStateLH = type(httpTable) == "table" and rawget(httpTable, "request") or nil
	end
	if type(scriptStateLH) ~= "function" then
		return false
	end
	local scriptStateKX = not suppressPing and Config.webhookPingEnabled and getRebirthMachineCost(Config.webhookPingUserId) or nil
	if scriptStateKX then
		scriptStateACW.content = "<@" .. scriptStateKX .. ">"
		scriptStateACW.allowed_mentions = {
			users = {
				scriptStateKX,
			},
			parse = {},
		}
	end
	local scriptStateSX, scriptStatePK = pcall(function()
		return scriptStateLH({
			Url = normalizeDiscordWebhookV2Url(scriptStateQZ),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode(buildDiscordV2WebhookPayload(scriptStateACW)),
		})
	end)
	if scriptStateSX and scriptStatePK then
		local scriptStateUJ = tonumber(scriptStatePK.StatusCode or scriptStatePK.status_code)
		if scriptStateUJ == nil or (scriptStateUJ >= 200 and scriptStateUJ < 300) then
			return true
		end
	end
	return false
end
LIVE_WEBHOOK_UPDATE_INTERVAL = 15
activeStates.BGSI_Lite_LiveWebhook = type(activeStates.BGSI_Lite_LiveWebhook) == "table"
		and activeStates.BGSI_Lite_LiveWebhook
	or {}
activeStates.BGSI_Lite_LiveWebhook.messageIds = type(activeStates.BGSI_Lite_LiveWebhook.messageIds) == "table"
		and activeStates.BGSI_Lite_LiveWebhook.messageIds
	or {}
activeStates.BGSI_Lite_LiveWebhook.startedAt = tick()
activeStates.BGSI_Lite_LiveWebhook.startingHatches = nil
activeStates.BGSI_Lite_LiveWebhook.enabled = false
activeStates.BGSI_Lite_LiveWebhook.loopToken = (tonumber(activeStates.BGSI_Lite_LiveWebhook.loopToken) or 0) + 1
function getLiveWebhookRequestFunction()
	local requestFunction = request
		or http_request
		or (type(syn) == "table" and rawget(syn, "request"))
		or rawget((getgenv and getgenv()) or _G, "http_request")

	if type(requestFunction) ~= "function" then
		local httpTable = rawget((getgenv and getgenv()) or _G, "http")
		requestFunction = type(httpTable) == "table" and rawget(httpTable, "request") or nil
	end

	return requestFunction
end
function normalizeLiveWebhookUrl(webhookUrl, waitForMessage)
	webhookUrl = tostring(webhookUrl or ""):match("^%s*(.-)%s*$") or ""
	if webhookUrl == "" then
		return webhookUrl
	end
	if webhookUrl:find("with_components=", 1, true) then
		webhookUrl = webhookUrl:gsub("with_components=[^&]*", "with_components=true", 1)
	else
		webhookUrl = webhookUrl .. (webhookUrl:find("?", 1, true) and "&" or "?") .. "with_components=true"
	end
	if waitForMessage then
		if webhookUrl:find("wait=", 1, true) then
			webhookUrl = webhookUrl:gsub("wait=[^&]*", "wait=true", 1)
		else
			webhookUrl = webhookUrl .. "&wait=true"
		end
	end
	return webhookUrl
end
function getLiveWebhookMessageUrl(webhookUrl, messageId)
	webhookUrl = tostring(webhookUrl or ""):match("^%s*(.-)%s*$") or ""
	messageId = tostring(messageId or "")
	if webhookUrl == "" or messageId == "" then
		return nil
	end

	local webhookId, webhookToken = webhookUrl:match("api%.discord%.com/api/webhooks/(%d+)/([^%?]+)")
	if not webhookId or not webhookToken then
		webhookId, webhookToken = webhookUrl:match("discord%.com/api/webhooks/(%d+)/([^%?]+)")
	end
	if not webhookId or not webhookToken then
		return nil
	end

	return string.format(
		"https://discord.com/api/webhooks/%s/%s/messages/%s?with_components=true",
		webhookId,
		webhookToken,
		messageId
	)
end
function formatLiveWebhookNumber(value)
	value = tonumber(value) or 0
	if value >= 1e12 then
		return string.format("%.2fT", value / 1e12)
	elseif value >= 1e9 then
		return string.format("%.2fB", value / 1e9)
	elseif value >= 1e6 then
		return string.format("%.2fM", value / 1e6)
	elseif value >= 1e3 then
		return string.format("%.2fK", value / 1e3)
	end
	return tostring(math.floor(value))
end
function formatLiveWebhookUptime(seconds)
	seconds = math.max(0, math.floor(tonumber(seconds) or 0))
	local hours = math.floor(seconds / 3600)
	local minutes = math.floor((seconds % 3600) / 60)
	local remainingSeconds = seconds % 60
	if hours > 0 then
		return string.format("%dh %02dm %02ds", hours, minutes, remainingSeconds)
	elseif minutes > 0 then
		return string.format("%dm %02ds", minutes, remainingSeconds)
	end
	return string.format("%ds", remainingSeconds)
end
liveWebhookHeadshotUrl = nil
liveWebhookHeadshotFetchedAt = 0
function getLiveWebhookHeadshotUrl()
	if liveWebhookHeadshotUrl and tick() - liveWebhookHeadshotFetchedAt < 1800 then
		return liveWebhookHeadshotUrl
	end

	-- Prefer Roblox's native thumbnail resolver. It returns a CDN image URL
	-- that Discord can fetch directly, avoiding the old headshot endpoint.
	local nativeOk, nativeUrl = pcall(function()
		local contentUrl = Players:GetUserThumbnailAsync(
			LocalPlayer.UserId,
			Enum.ThumbnailType.HeadShot,
			Enum.ThumbnailSize.Size420x420
		)
		return contentUrl
	end)
	if nativeOk and type(nativeUrl) == "string" and nativeUrl:match("^https?://") then
		liveWebhookHeadshotUrl = nativeUrl
		liveWebhookHeadshotFetchedAt = tick()
		return liveWebhookHeadshotUrl
	end

	local userId = tostring(LocalPlayer.UserId)
	local apiUrl = string.format(
		"https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=%s&size=420x420&format=Png&isCircular=false",
		userId
	)

	local requestFunction = getLiveWebhookRequestFunction()
	local responseBody

	if type(requestFunction) == "function" then
		local ok, response = pcall(function()
			return requestFunction({
				Url = apiUrl,
				Method = "GET",
				Headers = {
					["Accept"] = "application/json",
				},
				Timeout = 8,
			})
		end)
		if ok and type(response) == "table" then
			responseBody = response.Body or response.body
		end
	end

	if type(responseBody) ~= "string" or responseBody == "" then
		local ok, body = pcall(function()
			return HttpService:GetAsync(apiUrl)
		end)
		if ok then
			responseBody = body
		end
	end

	if type(responseBody) == "string" and responseBody ~= "" then
		local ok, decoded = pcall(function()
			return HttpService:JSONDecode(responseBody)
		end)
		if ok and type(decoded) == "table" and type(decoded.data) == "table" then
			local entry = decoded.data[1]
			if type(entry) == "table" and type(entry.imageUrl) == "string" and entry.imageUrl ~= "" then
				liveWebhookHeadshotUrl = entry.imageUrl
				liveWebhookHeadshotFetchedAt = tick()
				return liveWebhookHeadshotUrl
			end
		end
	end

	-- Fallback for executors/clients that can resolve Roblox's legacy thumbnail URL.
	return string.format(
		"https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png",
		userId
	)
end
function getLiveWebhookStats()
	local playerData
	pcall(function()
		if profileStore and profileStore:IsReady() then
			playerData = profileStore:Get()
		end
	end)

	local totalHatches = 0
	if type(playerData) == "table" and type(playerData.Stats) == "table" then
		totalHatches = tonumber(playerData.Stats.Hatches) or 0
	end

	local liveState = activeStates.BGSI_Lite_LiveWebhook
	if liveState.startingHatches == nil then
		liveState.startingHatches = totalHatches
	end

	return {
		totalHatches = totalHatches,
		sessionHatches = math.max(0, totalHatches - (tonumber(liveState.startingHatches) or totalHatches)),
		hatchRate = math.max(0, math.floor(tonumber(activeStates.BGSI_Lite_CurrentHatchRate) or 0)),
		currentEgg = tostring(activeStates.BGSI_Lite_CurrentEggName or Config.selectedEgg or "None"),
		isHatching = activeStates.BGSI_Lite_IsHatching == true,
		luck = tonumber(activeStates.BGSI_Lite_CurrentLuck) or 0,
		hatchSpeed = tonumber(activeStates.BGSI_Lite_CurrentHatchSpeed) or 0,
		fps = tonumber(activeStates.BGSI_Lite_CurrentFPS) or 0,
		serverPlayers = #Players:GetPlayers(),
		uptime = math.max(0, tick() - (tonumber(liveState.startedAt) or tick())),
		bestHatchName = tostring(activeStates.BGSI_Lite_BestHatchName or ""),
		bestHatchChance = tonumber(activeStates.BGSI_Lite_BestHatchChance) or 0,
	}
end
function buildLiveWebhookPayload()
	local stats = getLiveWebhookStats()
	local displayName = tostring(LocalPlayer.DisplayName or LocalPlayer.Name)
	local accountName = tostring(LocalPlayer.Name)
	local username = displayName .. " (" .. accountName .. ")"

	local bestHatch = "None yet"
	if stats.bestHatchName ~= "" then
		if stats.bestHatchChance > 0 then
			bestHatch = string.format("%s (1 in %s)", stats.bestHatchName, formatLiveWebhookNumber(stats.bestHatchChance))
		else
			bestHatch = stats.bestHatchName
		end
	end

	local content = table.concat({
		"# " .. username,
		"",
		"**" .. stats.currentEgg .. "**",
		"",
		"<:hatch_speed:1515078597105287380> **Hatch Speed:** `" .. string.format("%.1f%%", stats.hatchSpeed) .. "`",
		"<:luck:1462133363182796810> **Luck:** `" .. string.format("%.1f%%", stats.luck) .. "`",
		":alarm_clock: **Uptime:** `" .. formatLiveWebhookUptime(stats.uptime) .. "`",
		"<:server:1521545154626982072> **Server:** `" .. tostring(stats.serverPlayers) .. " players`",
		":star: **Best hatch:** " .. bestHatch,
		"<:hatch_speed:1515078597105287380> **Total:** `" .. formatLiveWebhookNumber(stats.totalHatches) .. "`",
	}, "\n")

	return {
		flags = 32768,
		components = {
			{
				type = 17,
				accent_color = stats.isHatching and 0x57F287 or 0xED4245,
				components = {
					{
						type = 9,
						components = {
							{
								type = 10,
								content = content,
							},
						},
						accessory = {
							type = 11,
							media = {
								url = getLiveWebhookHeadshotUrl(),
							},
							description = accountName .. " Roblox headshot",
						},
					},
					{
						type = 14,
						divider = true,
						spacing = 1,
					},
					{
						type = 10,
						content = string.format("-# Updated <t:%d:R>", os.time()),
					},
				},
			},
		},
	}
end
function postLiveWebhook(webhookUrl)
	local requestFunction = getLiveWebhookRequestFunction()
	if type(requestFunction) ~= "function" then
		return nil
	end

	local ok, response = pcall(function()
		return requestFunction({
			Url = normalizeLiveWebhookUrl(webhookUrl, true),
			Method = "POST",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode(buildLiveWebhookPayload()),
		})
	end)
	if not ok or type(response) ~= "table" then
		return nil
	end

	local statusCode = tonumber(response.StatusCode)
	if statusCode and statusCode ~= 200 and statusCode ~= 204 then
		return nil
	end
	if type(response.Body) ~= "string" or response.Body == "" then
		return nil
	end

	local decodeOk, responseBody = pcall(function()
		return HttpService:JSONDecode(response.Body)
	end)
	if not decodeOk or type(responseBody) ~= "table" or not responseBody.id then
		return nil
	end
	return tostring(responseBody.id)
end
function editLiveWebhook(webhookUrl, messageId)
	local requestFunction = getLiveWebhookRequestFunction()
	local messageUrl = getLiveWebhookMessageUrl(webhookUrl, messageId)
	if type(requestFunction) ~= "function" or not messageUrl then
		return false
	end

	local ok, response = pcall(function()
		return requestFunction({
			Url = messageUrl,
			Method = "PATCH",
			Headers = {
				["Content-Type"] = "application/json",
			},
			Body = HttpService:JSONEncode(buildLiveWebhookPayload()),
		})
	end)
	if not ok or type(response) ~= "table" then
		return false
	end

	local statusCode = tonumber(response.StatusCode)
	return statusCode == nil or statusCode == 200 or statusCode == 204
end
function stopLiveWebhook()
	local liveState = activeStates.BGSI_Lite_LiveWebhook
	liveState.enabled = false
	liveState.loopToken = (tonumber(liveState.loopToken) or 0) + 1
end
function startLiveWebhook()
	local liveState = activeStates.BGSI_Lite_LiveWebhook
	liveState.enabled = true
	liveState.startedAt = tick()
	liveState.startingHatches = nil
	Config.LiveWebhookMessageIds = type(Config.LiveWebhookMessageIds) == "table"
		and Config.LiveWebhookMessageIds
		or {}
	liveState.messageIds = Config.LiveWebhookMessageIds
	liveState.loopToken = (tonumber(liveState.loopToken) or 0) + 1
	local loopToken = liveState.loopToken

	task.spawn(function()
		while isCurrentRun()
			and liveState.enabled
			and liveState.loopToken == loopToken
			and Config.LiveWebhookEnabled
			and tostring(Config.LiveWebhookURL or "") ~= ""
		do
			local webhookEntries = getShrineLevelValue(Config.LiveWebhookURL)
			for _, webhookUrl in ipairs(webhookEntries) do
				if not liveState.enabled or liveState.loopToken ~= loopToken then
					break
				end

				webhookUrl = tostring(webhookUrl or ""):match("^%s*(.-)%s*$") or ""
				if webhookUrl ~= "" then
					-- Include the Roblox account ID in the key. Two accounts may use the same Discord
					-- webhook, but each account must own and update its own live-status message.
					local messageKey = configAccountId .. "|" .. webhookUrl
					local messageId = liveState.messageIds[messageKey]
					if messageId then
						if not editLiveWebhook(webhookUrl, messageId) then
							liveState.messageIds[messageKey] = postLiveWebhook(webhookUrl)
							if liveState.messageIds[messageKey] then
								saveConfig()
							end
						end
					else
						local newMessageId = postLiveWebhook(webhookUrl)
						if newMessageId then
							liveState.messageIds[messageKey] = newMessageId
							saveConfig()
						end
					end
				end
				task.wait(0.2)
			end
			task.wait(LIVE_WEBHOOK_UPDATE_INTERVAL)
		end
	end)
end
activeStates.BGSI_Lite_StartLiveWebhook = startLiveWebhook
activeStates.BGSI_Lite_StopLiveWebhook = stopLiveWebhook
function runRebirthMachineLoop(
	scriptStateEI,
	scriptStateOR,
	scriptStateXO,
	scriptStateBZ,
	scriptStateYR,
	scriptStateAEL
)
	if not Config.webhookEnabled or Config.webhookURL == "" then
		return
	end
	activeStates.BGSI_Lite_WebhookSendCache = type(activeStates.BGSI_Lite_WebhookSendCache) == "table"
			and activeStates.BGSI_Lite_WebhookSendCache
		or {}
	local sendCache = activeStates.BGSI_Lite_WebhookSendCache
	local now = tick()
	for cacheKey, cacheTime in pairs(sendCache) do
		if now - cacheTime > 120 then
			sendCache[cacheKey] = nil
		end
	end
	local petInfoText, chanceText = "", ""
	if type(scriptStateXO) == "table" then
		for _, field in ipairs(scriptStateXO) do
			if type(field) == "table" then
				if field.name == "Pet Info" then
					petInfoText = tostring(field.value or "")
				elseif field.name == "Chance" then
					chanceText = tostring(field.value or "")
				end
			end
		end
	end
	local duplicateKey = table.concat({
		tostring(scriptStateYR or scriptStateEI or ""),
		tostring(scriptStateOR or ""),
		tostring(scriptStateBZ or ""),
		petInfoText ~= "" and petInfoText or HttpService:JSONEncode(scriptStateXO or {}),
		chanceText,
		type(scriptStateAEL) == "table" and tostring(scriptStateAEL.footerText or "") or "",
	}, "|")
	if sendCache[duplicateKey] and now - sendCache[duplicateKey] < 90 then
		return
	end
	sendCache[duplicateKey] = now
	local scriptStateABR = getShrineLevelValue(Config.webhookURL)
	for loopSlotBY, webhookURLEntry in ipairs(scriptStateABR) do
		local scriptStateAAK = Config.webhookHidePlayerName == true
		local scriptStateGN = (scriptStateAAK and scriptStateYR) or scriptStateEI
		local scriptStateQV = type(scriptStateAEL) == "table" and scriptStateAEL or {}
		runRebirthFuse(webhookURLEntry, {
			embeds = {
				{
					title = scriptStateQV.titleText,
					description = scriptStateQV.descriptionText,
					color = scriptStateOR,
					fields = scriptStateXO,
					thumbnail = scriptStateBZ and {
						url = scriptStateBZ,
					} or nil,
					image = scriptStateQV.imageUrl and {
						url = scriptStateQV.imageUrl,
					} or nil,
					footer = {
						text = scriptStateQV.footerText or os.date("%Y-%m-%d %H:%M:%S"),
					},
					timestamp = scriptStateQV.timestamp,
				},
			},
		})
		task.wait(0.1)
	end
end
activeStates.LiteSendWebhook = runRebirthMachineLoop
function makeSimulatedHatchPet(input, forceSuper)
	local name = tostring(input or ""):match("^%s*(.-)%s*$"):gsub("%s+", " ")
	local flags = {}
	local function lookup(value)
		for petName, info in pairs(type(petRarityData) == "table" and petRarityData or {}) do
			if type(petName) == "string" and petName:lower() == value:lower() and type(info) == "table" then
				return petName, info
			end
		end
	end
	local canonical, info = lookup(name)
	while not info do
		local prefix, rest = name:match("^(%a+)%s+(.+)$")
		local flag = prefix and ({shiny = "Shiny", mythic = "Mythic", xl = "XL", super = "Super"})[prefix:lower()]
		if not flag then
			return nil, "Pet not found. Enter a name from the game's pet data."
		end
		flags[flag], name = true, rest
		canonical, info = lookup(name)
	end
	local stored = activeStates.BGSI_Lite_FindStoredWebhookPet(
		{}, canonical, flags.Shiny == true, flags.Mythic == true, flags.XL == true
	)
	local pet = stored and table.clone(stored) or {}
	pet.Name, pet.Id = canonical, "Simulation"
	pet.Shiny, pet.Mythic, pet.XL = flags.Shiny == true, flags.Mythic == true, flags.XL == true
	pet.Super = (forceSuper == true and info.Rarity == "Legendary")
		or flags.Super == true or info.Super == true or info.SuperLegendary == true
		or info.Rarity == "Super Legendary"
		or (stored and (activeStates.BGSI_Lite_GetHatchPetFlag(stored, "Super")
			or activeStates.BGSI_Lite_GetHatchPetFlag(stored, "SuperLegendary"))) or false
	if not pet.Enchants and not pet.Enchantments then
		pet.Enchants = info.Enchants or info.Enchantments
	end
	return pet, info
end
simulatedSuperEnchantWeights = {
	["super-luck"] = 20, ["super-luck-plus"] = 5,
	["super-burst"] = 45, ["super-burst-plus"] = 20,
	["super-shiny"] = 10, ["super-shiny-plus"] = 4,
	["super-speed"] = 10, ["super-speed-plus"] = 4,
	["super-bubble"] = 5, ["super-bubble-plus"] = 2,
	["super-mythic"] = 7.5, ["super-mythic-plus"] = 2.5,
	["super-infinity"] = 2, ["super-infinity-plus"] = 0.5,
	["super-duplication"] = 0.5, ["super-duplication-plus"] = 0.1,
}
function rollSimulatedSuperEnchants(pet)
	local rolled, usedFamilies = {}, {}
	local profile
	pcall(function()
		if profileStore:IsReady() then profile = profileStore:Get() end
	end)
	local fallbackPool = simulatedSuperEnchantWeights
	if type(enchantData) == "table" then
		for _, entry in pairs(enchantData) do
			if type(entry) == "table" and entry.IsSuperOnly == true
				and (tonumber(entry.Weight) or 0) > 0 then
				fallbackPool = enchantData
				break
			end
		end
	end
	for _ = 1, pet.Shiny == true and 2 or 1 do
		local enchantId
		if type(profile) == "table" and type(enchantModule) == "table"
			and type(enchantModule.GetUnusedEnchant) == "function" then
			local ok, result = pcall(function()
				return enchantModule:GetUnusedEnchant(profile, rolled, pet.Name, true)
			end)
			if ok and type(result) == "string" then enchantId = result end
		end
		if not enchantId then
			local pool, totalWeight = {}, 0
			for id, entry in pairs(fallbackPool) do
				local weight = type(entry) == "table" and entry.IsSuperOnly == true
					and tonumber(entry.Weight) or (type(entry) == "number" and entry or nil)
				local family = type(id) == "string" and id:gsub("%-plus$", "")
				if family and weight and weight > 0 and not usedFamilies[family] then
					totalWeight += weight
					table.insert(pool, {id = id, threshold = totalWeight})
				end
			end
			if totalWeight > 0 then
				local pick = math.random() * totalWeight
				for _, candidate in ipairs(pool) do
					if pick <= candidate.threshold then
						enchantId = candidate.id
						break
					end
				end
			end
		end
		if not enchantId then break end
		usedFamilies[enchantId:gsub("%-plus$", "")] = true
		table.insert(rolled, {Id = enchantId, Level = 1})
	end
	return rolled
end
function buildSimulatedHatchPayload(pet, info)
	local petName = pet.Name
	local shiny, mythic, xl = pet.Shiny == true, pet.Mythic == true, pet.XL == true
	local super = pet.Super == true
	if super then
		pet.Enchants = rollSimulatedSuperEnchants(pet)
		pet.Enchantments = nil
	end
	local sourceName, sourceIsEgg = getWebhookPetSource(pet, info)
	local finalPercent = 0
	if sourceIsEgg then
		local _, calculatedPercent = getWebhookHatchChances(petName, info, sourceName, shiny, mythic, xl, super)
		finalPercent = calculatedPercent
	end
	local finalOneIn = sourceIsEgg and finalPercent > 0 and 100 / finalPercent or 0
	local variantName = (super and "Super " or "") .. buildPetWebhookEmbed(petName, shiny, mythic, xl)
	local existCount = getPetVariantName(variantName, pet, 4)
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
		local enchantText, enchantNames = getWebhookSuperLegendaryEnchantText({Enchants = pet.Enchants}, petName, shiny, mythic, xl)
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
end,
function(...)
if Config.LiveWebhookEnabled and tostring(Config.LiveWebhookURL or "") ~= "" then
	activeStates.BGSI_Lite_StartLiveWebhook()
end
task.spawn(function()
	local scriptStateDE = {
		Coins = 0,
		Gems = 0,
		Pearls = 0,
		Tickets = 0,
	}
	while isCurrentRun() do
		task.wait(5)
		if not Config.webhookEnabled or not Config.webhookLowCurrencyEnabled then
			continue
		end
		local scriptStateJV = math.max(60, (tonumber(Config.webhookLowCurrencyCooldownMinutes) or 30) * 60)
		local scriptStateKO = getWebhookRequestFunction()
		local scriptStateKP = tick()
		local scriptStateACF = {}
		local function getAdminRebirthPetCandidate(scriptStateXL, scriptStateXD, scriptStateXC, scriptStateHE)
			local scriptStateVD = getShrinePotionName(scriptStateHE)
			if not scriptStateVD then
				return
			end
			local scriptStateYH = scriptStateKO[scriptStateXL] or 0
			if scriptStateYH >= scriptStateVD then
				return
			end
			if (scriptStateKP - (scriptStateDE[scriptStateXL] or 0)) < scriptStateJV then
				return
			end
			table.insert(scriptStateACF, {
				key = scriptStateXL,
				label = scriptStateXD,
				emoji = scriptStateXC,
				current = scriptStateYH,
				threshold = scriptStateHE,
			})
		end
		getAdminRebirthPetCandidate("Coins", "Coins", "\240\159\170\153", Config.webhookLowCoinsBelow)
		getAdminRebirthPetCandidate("Gems", "Gems", "\240\159\146\142", Config.webhookLowGemsBelow)
		getAdminRebirthPetCandidate("Pearls", "Pearls", "\226\154\170", Config.webhookLowPearlsBelow)
		getAdminRebirthPetCandidate("Tickets", "Tickets", "\240\159\142\171", Config.webhookLowTicketsBelow)
		if #scriptStateACF > 0 then
			local scriptStateYP = {
				{
					name = "Player",
					value = ("%s (%s)"):format(LocalPlayer.Name, LocalPlayer.UserId),
					inline = false,
				},
			}
			local scriptStateGI = {
				{
					name = "Player",
					value = "Player (hidden)",
					inline = false,
				},
			}
			for loopSlotBK, scriptStateFW in ipairs(scriptStateACF) do
				local scriptStateTC = {
					name = ("%s %s"):format(scriptStateFW.emoji, scriptStateFW.label),
					value = ("Current: `%s`\nBelow: `%s`"):format(
						getShrineAmountValue(scriptStateFW.current),
						tostring(scriptStateFW.threshold)
					),
					inline = true,
				}
				table.insert(scriptStateYP, scriptStateTC)
				table.insert(scriptStateGI, scriptStateTC)
			end
			runRebirthMachineLoop("Low Currency Alert", 16753920, scriptStateYP, nil, "Low Currency Alert")
			for loopSlotDT, scriptStateQR in ipairs(scriptStateACF) do
				scriptStateDE[scriptStateQR.key] = scriptStateKP
			end
		end
	end
end)
activeStates.BGSI_Lite_InstallPetWebhookListener = function()
	pcall(function()
		if activeStates.BGSI_Lite_WebhookConnection then
			activeStates.BGSI_Lite_WebhookConnection:Disconnect()
			activeStates.BGSI_Lite_WebhookConnection = nil
		end
	end)
	activeStates.BGSI_Lite_RecentPetWebhookKeys = type(activeStates.BGSI_Lite_RecentPetWebhookKeys) == "table"
			and activeStates.BGSI_Lite_RecentPetWebhookKeys
		or {}
	local recentPetWebhookKeys = activeStates.BGSI_Lite_RecentPetWebhookKeys
	local function isSuperLegendaryWebhookPet(webhookPetEntry, petData)
		local isLegendaryBasePet = type(petData) == "table" and petData.Rarity == "Legendary"
		if not isLegendaryBasePet then
			return false
		end
		return activeStates.BGSI_Lite_GetHatchPetFlag(webhookPetEntry, "Super")
	end
	local function shouldSendPetWebhookEntry(webhookPetEntry, petName, petRarity, isShiny, isMythic, isXL)
		local now = tick()
		for webhookKey, webhookSentAt in pairs(recentPetWebhookKeys) do
			if now - webhookSentAt > 120 then
				recentPetWebhookKeys[webhookKey] = nil
			end
		end
		local petId = activeStates.BGSI_Lite_GetWebhookPetEntryId(webhookPetEntry)
		if petId == nil or tostring(petId) == "" then
			return true
		end
		local webhookKey = "id|" .. tostring(petId)
		if recentPetWebhookKeys[webhookKey] and now - recentPetWebhookKeys[webhookKey] < 120 then
			return false
		end
		recentPetWebhookKeys[webhookKey] = now
		return true
	end
	local savedWebhookHatchTracker = loadWebhookHatchTracker()
	activeStates.BGSI_Lite_WebhookHatchTracker = type(activeStates.BGSI_Lite_WebhookHatchTracker) == "table"
			and activeStates.BGSI_Lite_WebhookHatchTracker
		or {}
	for petDisplayName, savedHatchCount in pairs(savedWebhookHatchTracker) do
		activeStates.BGSI_Lite_WebhookHatchTracker[petDisplayName] =
			math.max(tonumber(activeStates.BGSI_Lite_WebhookHatchTracker[petDisplayName]) or 0, savedHatchCount)
	end
	local function incrementWebhookHatchTracker(petDisplayName)
		petDisplayName = tostring(petDisplayName or "Unknown")
		local latestTracker = loadWebhookHatchTracker()
		for savedPetName, savedHatchCount in pairs(latestTracker) do
			activeStates.BGSI_Lite_WebhookHatchTracker[savedPetName] =
				math.max(tonumber(activeStates.BGSI_Lite_WebhookHatchTracker[savedPetName]) or 0, savedHatchCount)
		end
		local currentCount = math.max(
			tonumber(activeStates.BGSI_Lite_WebhookHatchTracker[petDisplayName]) or 0,
			tonumber(latestTracker[petDisplayName]) or 0
		)
		currentCount = currentCount + 1
		activeStates.BGSI_Lite_WebhookHatchTracker[petDisplayName] = currentCount
		saveWebhookHatchTracker()
		return currentCount
	end
	local function formatWebhookChancePercent(oneInChance)
		oneInChance = tonumber(oneInChance) or 0
		if oneInChance <= 0 then
			return "0%"
		end
		local chancePercent = 100 / oneInChance
		if chancePercent < 0.000001 then
			return string.format("%.3g%%", chancePercent)
		end
		return string.format("%.8f", chancePercent):gsub("0+$", ""):gsub("%.$", "") .. "%"
	end
	activeStates.BGSI_Lite_WebhookConnection = remoteEvent.OnClientEvent:Connect(
		function(scriptStateKW, scriptStateNY, ...)
			if not isCurrentRun() then
				return
			end
			local scriptStatePO
			if
				scriptStateKW == "HatchEgg"
				or scriptStateKW == "HatchPowerupEgg"
				or scriptStateKW == "ExclusiveHatch"
			then
				if type(scriptStateNY) == "table" then
					scriptStatePO = scriptStateNY.Pets
					if type(scriptStatePO) ~= "table" and #scriptStateNY > 0 then
						scriptStatePO = scriptStateNY
					end
					if
						type(scriptStatePO) ~= "table"
						and activeStates.BGSI_Lite_GetHatchPetName(scriptStateNY) ~= "Unknown"
					then
						scriptStatePO = {
							scriptStateNY,
						}
					end
				end
			elseif scriptStateKW == "ItemsReceived" then
				if type(scriptStateNY) == "table" then
					scriptStatePO = {}
					for loopSlotCF, scriptStateABW in ipairs(scriptStateNY) do
						if type(scriptStateABW) == "table" and scriptStateABW.Type == "Pet" then
							table.insert(scriptStatePO, scriptStateABW)
						end
					end
					if #scriptStatePO == 0 then
						scriptStatePO = nil
					end
				end
			end
			if not scriptStatePO or type(scriptStatePO) ~= "table" or #scriptStatePO == 0 then
				return
			end
			if
				scriptStateKW == "HatchEgg"
				or scriptStateKW == "HatchPowerupEgg"
				or scriptStateKW == "ExclusiveHatch"
				then
					local hatchAcceptedAt = tick()
				if scriptStateKW == "HatchEgg" then
					local previousHatchAcceptedAt = tonumber(activeStates.BGSI_Lite_LastHatchAcceptedAt)
					if previousHatchAcceptedAt and previousHatchAcceptedAt > 0 then
						local hatchInterval = hatchAcceptedAt - previousHatchAcceptedAt
						if hatchInterval >= 0.05 and hatchInterval <= 3 then
							local previousInterval =
								tonumber(activeStates.BGSI_Lite_AcceptedHatchInterval) or hatchInterval
							activeStates.BGSI_Lite_AcceptedHatchInterval =
								previousInterval * 0.7 + hatchInterval * 0.3
							activeStates.BGSI_Lite_AdaptiveHatchDelay = math.clamp(
								activeStates.BGSI_Lite_AcceptedHatchInterval * 0.02,
								0.005,
								0.015
							)
						end
					end
					activeStates.BGSI_Lite_LastHatchAcceptedAt = hatchAcceptedAt
				end
				activeStates.BGSI_Lite_LastHatchEventAt = hatchAcceptedAt
				local aaBlessingMode = Config.autoSetupTeamAABlessingSupers == true
					and activeStates.BGSI_Lite_LuckEggActive == true
				if Config.autoSetupTeamEnabled == true
					and (Config.autoSetupTeamIncludeSupers == true or aaBlessingMode)
					and Config.safeMode ~= true and isEquippedTeamNamedHatch() then
					local wanted = type(Config.autoSetupTeamSuperCounts) == "table"
						and Config.autoSetupTeamSuperCounts or {}
					for _, hatchedPet in ipairs(scriptStatePO) do
						local petName = activeStates.BGSI_Lite_GetHatchPetName(hatchedPet)
						local petInfo = type(petRarityData) == "table" and petRarityData[petName] or nil
						local rarity = activeStates.BGSI_Lite_ResolvePetRarity(hatchedPet, petInfo)
						if activeStates.BGSI_Lite_GetHatchPetFlag(hatchedPet, "Super") == true
							or activeStates.BGSI_Lite_GetHatchPetFlag(hatchedPet, "SuperLegendary") == true
							or rarity == "Super" or rarity == "Super Legendary" then
							for _, enchant in ipairs(getPetEnchantList(hatchedPet)) do
								local key = getAutoTeamSuperEnchantKey(enchant)
								local wantedForCurrentEgg = aaBlessingMode
									and (key == "hatch-blessing-plus" or key == "hatch-blessing"
										or key == "luck-boost-plus" or key == "luck-boost")
									or (not aaBlessingMode and (tonumber(wanted[key]) or 0) > 0)
								if key and wantedForCurrentEgg then
									task.delay(0.3, activeStates.BGSI_Lite_RequestAutoSetupTeamRefresh)
									break
								end
							end
					end
					end
				end
				if
					Config.autoBubble
					and type(activeStates.BGSI_Lite_BlowBubble) == "function"
				then
					task.defer(activeStates.BGSI_Lite_BlowBubble)
				end
				for _, hatchedPet in ipairs(scriptStatePO) do
					local petName = activeStates.BGSI_Lite_GetHatchPetName(hatchedPet)
					local petInfo = type(petRarityData) == "table" and petRarityData[petName] or {}
					local chancePercent = tonumber(checkLowCurrencyWebhook(petName, petInfo)) or 100
					local oneInChance = chancePercent > 0 and 100 / chancePercent or 0
					local shiny = activeStates.BGSI_Lite_GetHatchPetFlag(hatchedPet, "Shiny")
					local mythic = activeStates.BGSI_Lite_GetHatchPetFlag(hatchedPet, "Mythic")
					local xl = activeStates.BGSI_Lite_GetHatchPetFlag(hatchedPet, "XL")
					if shiny then oneInChance *= 40 end
					if mythic then oneInChance *= 100 end
					if xl then oneInChance *= 400 end
					if oneInChance > (tonumber(activeStates.BGSI_Lite_BestHatchChance) or 0) then
						local displayName = buildPetWebhookEmbed(petName, shiny, mythic, xl)
						if isSuperLegendaryWebhookPet(hatchedPet, petInfo) then
							displayName = "Super " .. displayName
						end
						activeStates.BGSI_Lite_BestHatchName = displayName
						activeStates.BGSI_Lite_BestHatchChance = oneInChance
					end
					-- Account Dashboard: queue rare hatches and egg discoveries for the next heartbeat.
					if Config.dashboardSyncEnabled == true and type(activeStates.BGSI_Lite_RecordEggDiscovery) == "function" then
						pcall(function()
							local isSuper = isSuperLegendaryWebhookPet(hatchedPet, petInfo)
							local rarity = activeStates.BGSI_Lite_ResolvePetRarity(hatchedPet, petInfo)
							if isSuper and rarity ~= "Celestial" then
								rarity = "Super Legendary"
							end
							local tracksPet = rarity == "Secret"
								or rarity == "Infinity"
								or rarity == "Void"
								or rarity == "Celestial"
								or isSuper
							local existingCount
							if tracksPet then
								local variantName = buildPetWebhookEmbed(petName, shiny, mythic, xl)
								if isSuper then
									variantName = "Super " .. variantName
								end
								existingCount = getPetVariantName(variantName, hatchedPet, 2)
								hatchedPet.BGSI_Lite_DashboardExistingCount = existingCount
							end
							local enchantments = {}
							if isSuper then
								local _, enchantNames =
									getWebhookSuperLegendaryEnchantText(hatchedPet, petName, shiny, mythic, xl)
								enchantments = enchantNames or {}
							end
							local eggName = tostring(activeStates.BGSI_Lite_CurrentEggName or "Unknown Egg")
							local assetId = type(activeStates.BGSI_Lite_GetDashboardPetAssetId) == "function"
									and activeStates.BGSI_Lite_GetDashboardPetAssetId(hatchedPet, petInfo)
								or nil
							activeStates.BGSI_Lite_RecordEggDiscovery(
								eggName,
								tostring(petName),
								rarity,
								assetId,
								shiny == true,
								mythic == true,
								xl == true,
								isSuper,
								enchantments,
								existingCount
							)
							local pendingHatches = activeStates.BGSI_Lite_DashboardPendingHatches
							if tracksPet and type(pendingHatches) == "table" then
								table.insert(pendingHatches, {
									eventId = HttpService:GenerateGUID(false),
									petName = tostring(petName),
									rarity = rarity,
									chance = oneInChance,
									eggName = eggName,
									imageAssetId = assetId,
									shiny = shiny == true,
									mythic = mythic == true,
									xl = xl == true,
									super = isSuper,
									enchantments = enchantments,
									existingCount = existingCount,
								})
								if #pendingHatches > 500 then
									table.remove(pendingHatches, 1)
								end
							end
						end)
					end
				end
			end
			if not Config.webhookEnabled then
				return
			end
			local resolvedWebhookPetIds = {}
			for loopSlotAA, scriptStateACH in ipairs(scriptStatePO) do
				activeStates.BGSI_Lite_LastWebhookStoredPet = nil
				if loopSlotAA > 1 then
					task.wait(0.1)
				end
				local scriptStateFL = activeStates.BGSI_Lite_GetHatchPetName(scriptStateACH)
				local scriptStateEQ = petRarityData and petRarityData[scriptStateFL] or {}
				local scriptStatePG = activeStates.BGSI_Lite_ResolvePetRarity(scriptStateACH, scriptStateEQ)
				local isSuperLegendaryPet = isSuperLegendaryWebhookPet(scriptStateACH, scriptStateEQ)
				if
					scriptStatePG ~= "Secret"
					and scriptStatePG ~= "Infinity"
					and scriptStatePG ~= "Void"
					and scriptStatePG ~= "Celestial"
					and not isSuperLegendaryPet
				then
					continue
				end
				local scriptStateLS = activeStates.BGSI_Lite_GetHatchPetFlag(scriptStateACH, "Shiny")
				local scriptStateNI = activeStates.BGSI_Lite_GetHatchPetFlag(scriptStateACH, "Mythic")
				local scriptStateKK = activeStates.BGSI_Lite_GetHatchPetFlag(scriptStateACH, "XL")
				local webhookSourceName, webhookSourceIsEgg = getWebhookPetSource(
					scriptStateACH, scriptStateEQ, scriptStateKW, scriptStateNY
				)
				if Config.webhookSendEasySecrets == false
					and scriptStateKW == "ItemsReceived"
					and isWebhookRebirthMachineReward(scriptStateACH, scriptStateEQ, webhookSourceName)
					and scriptStatePG ~= "Celestial"
					and scriptStatePG ~= "Infinity"
					and scriptStatePG ~= "Void"
				then
					continue
				end
				local webhookFinalPercent = 0
				if webhookSourceIsEgg then
					local _, calculatedPercent = getWebhookHatchChances(
						scriptStateFL, scriptStateEQ, webhookSourceName,
						scriptStateLS, scriptStateNI, scriptStateKK, isSuperLegendaryPet
					)
					webhookFinalPercent = calculatedPercent
				end
				if webhookSourceIsEgg and not meetsWebhookMinimumChance(
					scriptStateFL, scriptStateEQ, scriptStateLS, scriptStateNI, scriptStateKK, webhookFinalPercent
				) then
					continue
				end
				if
					not shouldSendPetWebhookEntry(
						scriptStateACH,
						scriptStateFL,
						scriptStatePG,
						scriptStateLS,
						scriptStateNI,
						scriptStateKK
					)
				then
					continue
				end
				local scriptStateKY
				if scriptStateLS and scriptStateNI then
					scriptStateKY = tonumber("00FF00", 16)
				elseif scriptStateNI then
					scriptStateKY = tonumber("5E03FC", 16)
				elseif scriptStateLS then
					scriptStateKY = tonumber("FFFF00", 16)
				else
					scriptStateKY = tonumber("FF0000", 16)
				end
				local scriptStateAFP = 1
				if scriptStateKK then
					scriptStateAFP = tonumber(sharedConstants and sharedConstants.XLMultiplier) or 2.5
				end
				if scriptStateLS and scriptStateNI then
					scriptStateAFP = scriptStateAFP * 2.25
				elseif scriptStateLS then
					scriptStateAFP = scriptStateAFP * 1.5
				elseif scriptStateNI then
					scriptStateAFP = scriptStateAFP * 1.75
				end
				local webhookPetDisplayName =
					buildPetWebhookEmbed(scriptStateFL, scriptStateLS, scriptStateNI, scriptStateKK)
				local webhookPetTitleName = (isSuperLegendaryPet and "Super " or "") .. webhookPetDisplayName
				local scriptStateBR = getPetVariantName(webhookPetTitleName, scriptStateACH, 8)
					or scriptStateACH.BGSI_Lite_DashboardExistingCount
				incrementWebhookHatchTracker(webhookPetTitleName)
				local webhookPetId = activeStates.BGSI_Lite_GetResolvedWebhookPetId(
					scriptStateACH,
					scriptStateFL,
					scriptStateLS,
					scriptStateNI,
					scriptStateKK,
					resolvedWebhookPetIds
				) or "Unknown"
				if webhookPetId ~= "Unknown" then
					resolvedWebhookPetIds[tostring(webhookPetId)] = true
				end
				local scriptStateAEC = webhookFinalPercent > 0 and 100 / webhookFinalPercent or 0
				local scriptStateWG = sendPetWebhook(scriptStateEQ, scriptStateLS, scriptStateNI)
				local scriptStateAEO = {}
				local webhookEnchantNames
				local webhookPlayer = Players.LocalPlayer
				local webhookPlayerName = Config.webhookHidePlayerName == true and "Player"
					or (webhookPlayer and webhookPlayer.Name or LocalPlayer.Name)
				local webhookStats = type(scriptStateEQ.Stats) == "table" and scriptStateEQ.Stats or {}
				table.insert(scriptStateAEO,
					"<:egg:1377264232915013673> Egg: **" .. webhookSourceName .. "**")
				if webhookSourceIsEgg then
					table.insert(scriptStateAEO,
						"<:four_leaf_clover:1462133363182796810> Chance: **"
							.. (scriptStateAEC > 0 and ("1 in " .. runShrineDonation(math.floor(scriptStateAEC + 0.5))) or "N/A") .. "**")
				end
				if isSuperLegendaryPet then
					local enchantText, enchantNames = getWebhookSuperLegendaryEnchantText(
						scriptStateACH, scriptStateFL, scriptStateLS, scriptStateNI, scriptStateKK
					)
					webhookEnchantNames = enchantNames
					if enchantText then table.insert(scriptStateAEO, enchantText) end
				end
				if isSuperLegendaryPet then
					scriptStateWG = getEnchantedSuperWebhookIcon(scriptStateWG, webhookEnchantNames)
				end
				local webhookStatEmojis = {
					bubbles = "<:purple_circle:1363755750828019774>",
					gems = "<:gem:1363755998401269854>",
					coins = "\240\159\170\153",
					pearls = "<:Pearl:1561761464866308219>",
					carnivalcoins = "<:circus_tent:1520159699230785707>",
					candycorn26 = "<:CandyCorn26:1561526287476985887>",
				}
				local webhookStatNames = {}
				for statName, statValue in pairs(webhookStats) do
					if type(statName) == "string" and type(statValue) == "number" then
						table.insert(webhookStatNames, statName)
					end
				end
				table.sort(webhookStatNames)
				for _, statName in ipairs(webhookStatNames) do
					local normalizedStatName = statName:lower():gsub("[^%w]", "")
					local statEmoji = webhookStatEmojis[normalizedStatName] or scriptStateDX[statName] or ""
					local statValue = activeStates.BGSI_Lite_GetWebhookPetStatValue(
						webhookStats[statName] * scriptStateAFP
					)
					local displayStatName = normalizedStatName == "candycorn26" and "Candycorn" or statName
					table.insert(scriptStateAEO, statEmoji .. " " .. displayStatName .. ": **" .. statValue .. "**")
				end
				table.insert(scriptStateAEO, "")
				table.insert(
					scriptStateAEO,
					"Exist: **" .. (scriptStateBR ~= nil and runShrineDonation(scriptStateBR) or "N/A") .. "**"
				)
				local titleVariants = {}
				if scriptStateLS then
					table.insert(titleVariants, "Shiny")
				end
				if scriptStateNI then
					table.insert(titleVariants, "Mythic")
				end
				if isSuperLegendaryPet then
					table.insert(titleVariants, "Super")
				end
				if scriptStateKK then
					table.insert(titleVariants, "XL")
				end
				local hatchTitle = webhookPlayerName .. " hatched a "
					.. (#titleVariants > 0 and table.concat(titleVariants, " ") .. " " or "")
					.. scriptStateFL
				local hatchDescription = "# **" .. hatchTitle .. "**"
				local hatchFields = {}
				if Config.webhookShowUserInfo == true then
					table.insert(hatchFields, buildWebhookUserInfoField())
				end
				table.insert(hatchFields, {name = "Pet Info", value = table.concat(scriptStateAEO, "\n"), inline = false})
				local hatchThumbnail = not scriptStateKK and scriptStateWG or nil
				local hatchImage = scriptStateKK and scriptStateWG or nil
				local hatchFooter = ""
				local hatchTimestamp = os.time()
				runRebirthMachineLoop(
					hatchTitle,
					scriptStateKY,
					hatchFields,
					hatchThumbnail,
					hatchTitle,
					{
						titleText = nil,
						descriptionText = hatchDescription,
						imageUrl = hatchImage,
						footerText = hatchFooter,
						timestamp = hatchTimestamp,
					}
				)
			end
		end
	)
end
pcall(activeStates.BGSI_Lite_InstallPetWebhookListener)
activeStates.BGSI_Lite_InstallPetWebhookListener = nil
function fetchLatestScriptSourceForAutoUpdate()
	local reloadNonce = table.concat({
		tostring(os.time()),
		tostring(math.random(100000, 999999)),
	}, "-")
	local sourceReference = "main"
	pcall(function()
		local commitMetadata = HttpService:JSONDecode(game:HttpGet(
			"https://api.github.com/repos/nf4z/larp/commits/main?reload=" .. HttpService:UrlEncode(reloadNonce),
			true
		))
		local commitSha = type(commitMetadata) == "table" and tostring(commitMetadata.sha or "") or ""
		if commitSha:match("^[%da-fA-F]+$") then
			sourceReference = commitSha
		end
	end)
	local requestOk, scriptSource = pcall(function()
		return game:HttpGet(
			"https://raw.githubusercontent.com/nf4z/larp/"
				.. sourceReference
				.. "/larp?reload="
				.. HttpService:UrlEncode(reloadNonce),
			true
		)
	end)
	if not requestOk or type(scriptSource) ~= "string" or scriptSource == "" then
		return nil, nil
	end
	local downloadedVersion = scriptSource:match('BGSI_Lite_ScriptVersion%s*=%s*"([^"]+)"')
	return scriptSource, downloadedVersion
end
activeStates.BGSI_Lite_CompareScriptVersions = function(first, second)
	local function parts(version)
		local year, month, day, revision = tostring(version):match("^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
		if not year then return nil end
		return {tonumber(year), tonumber(month), tonumber(day), tonumber(revision)}
	end
	local left, right = parts(first), parts(second)
	if not left or not right then return nil end
	for index = 1, 4 do
		if left[index] < right[index] then return -1 end
		if left[index] > right[index] then return 1 end
	end
	return 0
end
autoUpdateReloadQueued = false
activeStates.BGSI_Lite_RunAutoUpdateCheck = function(forceCheck)
	if Config.safeMode == true then
		return "error", nil, "Safe Mode is enabled"
	end
	if forceCheck ~= true and Config.autoUpdateScript ~= true then
		return "error", nil, "Auto Update is disabled"
	end
	if autoUpdateReloadQueued then
		return "queued"
	end

	local scriptSource, downloadedVersion = fetchLatestScriptSourceForAutoUpdate()
	if type(scriptSource) ~= "string" or scriptSource == "" then
		return "error", nil, "Could not download the latest script from GitHub"
	end
	if not downloadedVersion then
		return "error", nil, "The downloaded script has no version marker"
	end
	local currentVersion = tostring(activeStates.BGSI_Lite_ScriptVersion)
	local versionOrder = activeStates.BGSI_Lite_CompareScriptVersions(downloadedVersion, currentVersion)
	if downloadedVersion == currentVersion or (versionOrder and versionOrder <= 0) then
		return "up-to-date", currentVersion
	end

	-- Circuit breaker: activeStates is getgenv() itself, so these two fields survive a
	-- reload. If a script we just reloaded INTO still sees a mismatch against the exact
	-- same downloadedVersion it was supposed to have just become, something is broken
	-- (the new script errored before reaching its own version assignment, GitHub is
	-- serving something inconsistent, etc.) - reloading again would only stack another
	-- window on top of the one that never got torn down, repeating forever. Refuse to
	-- reload to a target we already just reloaded to within the last two minutes, and
	-- force-sync our version marker to it instead so the mismatch stops recurring.
	if
		activeStates.BGSI_Lite_LastAutoUpdateTarget == downloadedVersion
		and type(activeStates.BGSI_Lite_LastAutoUpdateAt) == "number"
		and tick() - activeStates.BGSI_Lite_LastAutoUpdateAt < 120
	then
		warn(
			"[1rzHub Lite] Auto-update refused to reload again: already attempted version "
				.. downloadedVersion
				.. " "
				.. tostring(math.floor(tick() - activeStates.BGSI_Lite_LastAutoUpdateAt))
				.. "s ago and this run still doesn't match it. Skipping to avoid a reload loop."
		)
		activeStates.BGSI_Lite_ScriptVersion = downloadedVersion
		return "error", downloadedVersion, "Refused repeat reload to the same version to avoid a loop"
	end

	local compiledScript, compileError = loadstring(scriptSource)
	if type(compiledScript) ~= "function" then
		warn(
			"[1rzHub Lite] Auto-update found version "
				.. downloadedVersion
				.. " but it failed to compile: "
				.. tostring(compileError)
		)
		return "error", downloadedVersion, "Downloaded version " .. downloadedVersion .. " failed to compile"
	end

	autoUpdateReloadQueued = true
	activeStates.BGSI_Lite_LastAutoUpdateTarget = downloadedVersion
	activeStates.BGSI_Lite_LastAutoUpdateAt = tick()
	print("[" .. LocalPlayer.Name .. "] Auto-update found version " .. downloadedVersion .. ". Reloading...")
	if type(activeStates.BGSI_Lite_LogDashboardAction) == "function" then
		activeStates.BGSI_Lite_LogDashboardAction("Auto-updating to version " .. downloadedVersion, "info")
	end
	pcall(function()
		Interface:Notify({
			Title = "1rzHub Lite",
			Content = "Update found (" .. downloadedVersion .. "). Reloading...",
			Duration = 5,
		})
	end)
	task.defer(compiledScript)
	return "queued", downloadedVersion
end
activeStates.BGSI_Lite_ForceReloadScript = function()
	if Config.safeMode == true then
		return "error", "Safe Mode is enabled"
	end
	if autoUpdateReloadQueued then
		return "queued"
	end

	local scriptSource, downloadedVersion = fetchLatestScriptSourceForAutoUpdate()
	if type(scriptSource) ~= "string" or scriptSource == "" then
		return "error", "Could not download the script from GitHub"
	end

	if
		downloadedVersion
		and activeStates.BGSI_Lite_LastAutoUpdateTarget == downloadedVersion
		and type(activeStates.BGSI_Lite_LastAutoUpdateAt) == "number"
		and tick() - activeStates.BGSI_Lite_LastAutoUpdateAt < 10
	then
		return "error", "Already reloading - give it a moment"
	end

	local compiledScript, compileError = loadstring(scriptSource)
	if type(compiledScript) ~= "function" then
		warn("[1rzHub Lite] Manual reload failed to compile: " .. tostring(compileError))
		return "error", "Downloaded script failed to compile"
	end

	autoUpdateReloadQueued = true
	if downloadedVersion then
		activeStates.BGSI_Lite_LastAutoUpdateTarget = downloadedVersion
	end
	activeStates.BGSI_Lite_LastAutoUpdateAt = tick()
	print("[" .. LocalPlayer.Name .. "] Manual reload requested. Reloading...")
	pcall(function()
		Interface:Notify({
			Title = "1rzHub Lite",
			Content = "Reloading script...",
			Duration = 4,
		})
	end)
	task.defer(compiledScript)
	return "queued"
end
end,
function(...)
pcall(activeStates.BGSI_Lite_FleetInit)
task.spawn(function()
	task.wait(30)
	while isCurrentRun() do
		if Config.autoUpdateScript == true and Config.safeMode ~= true then
			local checkOk, checkError = pcall(activeStates.BGSI_Lite_RunAutoUpdateCheck, false)
			if not checkOk then
				warn("[1rzHub Lite] Auto-update check failed: " .. tostring(checkError))
			end
		end
		task.wait(math.clamp(math.floor(tonumber(Config.autoUpdateIntervalSeconds) or 300), 60, 1800))
	end
end)
if tostring(Config.lastSeenScriptVersion or "") ~= tostring(activeStates.BGSI_Lite_ScriptVersion) then
	Interface:Popup({
		Title = "LarpLite updated",
		SubTitle = "Version "
			.. tostring(activeStates.BGSI_Lite_ScriptVersion)
			.. " - "
			.. tostring(activeStates.BGSI_Lite_ReleaseHistory[1].releasedAt),
		Boxes = activeStates.BGSI_Lite_ReleaseNotes,
		Options = {
			{
				text = "Continue",
				style = "primary",
			},
		},
	})
	Config.lastSeenScriptVersion = activeStates.BGSI_Lite_ScriptVersion
	saveConfig()
end
Interface:Notify({
	Title = "1rzHub Lite",
	Content = "Loaded.",
	Duration = 3,
})
if activeStates.BGSI_Lite_LegacyPickupLoopWarning then
	activeStates.BGSI_Lite_LegacyPickupLoopWarning=false
	Interface:Notify({Title="Rejoin once for a clean memory baseline",
		Content="Older versions left untracked pickup loops running. Rejoin once to clear those old tasks; this version stops its own loops on reload.",Duration=12})
end
if type(getgenv) == "function" then
	getgenv()._1rzHubLite_LoadComplete = true
end
end
}
