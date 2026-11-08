-- LarpLite modular loader. BGSI_Lite_ScriptVersion = "@VERSION@"
-- Defaults are lower priority than saved settings. Config is an explicit override.
local supplied = ...
local globalEnv = (getgenv and getgenv()) or _G
local loaderTicket = {}
globalEnv._1rzHubLiteLoaderTicket = loaderTicket
local originalEnv = getfenv()
assert(type(setfenv) == "function", "[LarpLite] This executor must support setfenv")
local function copy(value, seen)
	if type(value) ~= "table" then return value end
	seen = seen or {}
	assert(not seen[value], "[LarpLite] Loader config cannot contain cyclic tables")
	seen[value] = true
	local result = {}
	for key, item in pairs(value) do result[key] = copy(item, seen) end
	seen[value] = nil
	return result
end
local options = copy(type(supplied) == "table" and supplied or globalEnv._1rzHubLiteLoaderOptions or {})
local baseURL = "https://raw.githubusercontent.com/nf4z/larp/main/"
local modules = {
@MODULES@
}
local steps = {
@STEPS@
}
local declared = { @LOCALS@ }
-- Each run owns its helpers, so replaced functions do not accumulate in globals.
local environment = setmetatable({ _LarpLiteLoaderOptions = options, _loaderTicket = loaderTicket }, {
	__index = function(_, key)
		if declared[key] then return nil end
		return originalEnv[key]
	end,
})
local compiledModules = {}
local failures = {}
local function current() return globalEnv._1rzHubLiteLoaderTicket==loaderTicket end
local cacheRoot = "LarpLiteModules"
local useCache = options.Cache ~= false
	and type(isfile) == "function" and type(readfile) == "function"
	and type(writefile) == "function" and type(makefolder) == "function"
if useCache then
	local ok = pcall(function()
		if not isfolder or not isfolder(cacheRoot) then makefolder(cacheRoot) end
	end)
	useCache = ok
end
local function compileModule(name, spec, source)
	assert(type(source) == "string" and #source == spec.bytes, "Invalid size for module " .. name)
	local chunk, err = loadstring(source, "@LarpLite/" .. name)
	assert(type(chunk) == "function", tostring(err))
	setfenv(chunk, environment)
	local blocks = chunk()
	assert(type(blocks) == "table" and #blocks == spec.blocks, "Invalid module " .. name)
	for _, block in ipairs(blocks) do
		assert(type(block) == "function", "Invalid block in " .. name)
	end
	return blocks
end
local function fetchModule(name, spec)
	if not current() then return nil end
	local cachePath = cacheRoot .. "/" .. name .. "_" .. spec.path:match("([^/]+)$")
	if useCache then
		local ok, blocks = pcall(function()
			if isfile(cachePath) then return compileModule(name, spec, readfile(cachePath)) end
		end)
		if ok and blocks then return blocks end
	end
	local lastError
	for attempt = 1, 3 do
		if not current() then return nil end
		local ok, result = pcall(function()
			local source = game:HttpGet(baseURL .. spec.path, true)
			if not current() then return nil end
			local blocks = compileModule(name, spec, source)
			if useCache then pcall(writefile, cachePath, source) end
			return blocks
		end)
		if ok then return result end
		lastError = result
		if attempt < 3 then task.wait(0.25 * attempt) end
	end
	error("[LarpLite] Could not load " .. name .. ": " .. tostring(lastError))
end
-- Download/compile first: a failed request leaves the existing instance running.
local queue = {}
for name in pairs(modules) do table.insert(queue, name) end
table.sort(queue)
local cursor, workers = 0, 0
local moduleCount=#queue
local concurrency = math.clamp(math.floor(tonumber(options.DownloadConcurrency) or 4), 1, 8)
local budgetKB=tonumber(options.DownloadMemoryBudgetKB) or 512
if budgetKB~=budgetKB or budgetKB==math.huge or budgetKB==-math.huge then budgetKB=512 end
local budget=math.clamp(math.floor(budgetKB),128,8192)*1024
local inFlightBytes,peakBytes=0,0
local remaining={}
for name,spec in pairs(modules) do remaining[name]=spec.blocks end
local function discard()
	table.clear(compiledModules);table.clear(queue);table.clear(failures)
	table.clear(steps);table.clear(modules);table.clear(remaining)
end
for _ = 1, math.min(concurrency, #queue) do
	workers += 1
	task.spawn(function()
		while current() do
			cursor += 1
			local name = queue[cursor]
			if not name then break end
			local spec=modules[name]
			while current() and inFlightBytes>0 and inFlightBytes+spec.bytes>budget do task.wait() end
			if not current() then break end
			inFlightBytes+=spec.bytes;peakBytes=math.max(peakBytes,inFlightBytes)
			local ok, result = pcall(fetchModule, name, spec)
			inFlightBytes-=spec.bytes
			if current() then
				if ok then compiledModules[name] = result else table.insert(failures, tostring(result)) end
			end
			result=nil
		end
		workers -= 1
	end)
end
while workers > 0 do task.wait() end
-- Concurrent invocations may fetch together, but only the newest request starts.
if not current() then discard();return end
if #failures>0 then local reason=table.concat(failures,"\n");discard();error(reason,0) end
table.clear(queue)
globalEnv.BGSI_Lite_LoaderMetrics={SourceBudgetBytes=budget,PeakFetchBytes=peakBytes,Modules=moduleCount}
globalEnv._1rzHubLiteLoaderOptions = options
for _, step in ipairs(steps) do
	if not current() then discard();return end
	local blocks = compiledModules[step[1]]
	local block = blocks[step[2]]
	blocks[step[2]] = nil
	local ok, err = pcall(block)
	remaining[step[1]]-=1
	if remaining[step[1]]==0 then compiledModules[step[1]]=nil;modules[step[1]]=nil;remaining[step[1]]=nil end
	if not ok then
		discard()
		error("[LarpLite] " .. step[1] .. " block " .. step[2] .. ": " .. tostring(err), 0)
	end
end
-- Drop manifest and initialization closures; running features retain their own closures.
discard()
return { Version = "@VERSION@" }
