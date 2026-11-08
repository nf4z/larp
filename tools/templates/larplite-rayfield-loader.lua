	local rayfieldFile = "RayfieldGen2.lua"
	local libraryEnvironment=_LarpLiteExternalEnvironment or getfenv()
	local installRayfieldRuntime=(function()
__RAYFIELD_RUNTIME__
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
