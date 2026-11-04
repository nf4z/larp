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
	local cachePath = cacheRoot .. "/" .. name .. "_" .. spec.path:match("([^/]+)$")
	if useCache then
		local ok, blocks = pcall(function()
			if isfile(cachePath) then return compileModule(name, spec, readfile(cachePath)) end
		end)
		if ok and blocks then return blocks end
	end
	local lastError
	for attempt = 1, 3 do
		local ok, result = pcall(function()
			local source = game:HttpGet(baseURL .. spec.path, true)
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
local concurrency = math.clamp(math.floor(tonumber(options.DownloadConcurrency) or 4), 1, 8)
for _ = 1, math.min(concurrency, #queue) do
	workers += 1
	task.spawn(function()
		while true do
			cursor += 1
			local name = queue[cursor]
			if not name then break end
			local ok, result = pcall(fetchModule, name, modules[name])
			if ok then compiledModules[name] = result else table.insert(failures, tostring(result)) end
		end
		workers -= 1
	end)
end
while workers > 0 do task.wait() end
assert(#failures == 0, table.concat(failures, "\n"))
-- Concurrent invocations may fetch together, but only the newest request starts.
if globalEnv._1rzHubLiteLoaderTicket ~= environment._loaderTicket then return end
globalEnv._1rzHubLiteLoaderOptions = options
for _, step in ipairs(steps) do
	if globalEnv._1rzHubLiteLoaderTicket ~= environment._loaderTicket then return end
	local blocks = compiledModules[step[1]]
	local block = blocks[step[2]]
	blocks[step[2]] = nil
	local ok, err = pcall(block)
	if not ok then
		error("[LarpLite] " .. step[1] .. " block " .. step[2] .. ": " .. tostring(err), 0)
	end
end
-- Drop manifest and initialization closures; running features retain their own closures.
table.clear(compiledModules)
return { Version = "@VERSION@" }
