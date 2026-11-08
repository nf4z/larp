-- Extracted from the supplied November 7 game file: ReplicatedStorage.Shared.Utils.Chunker.
local t1 = {}

t1.__index = t1

function t1.new(p1, p2) -- line: 40
	-- upvalues: Signal (copy), t1 (copy)
	local Folder = Instance.new("Folder")

	Folder.Name = "Chunker"
	Folder.Parent = workspace.Rendered

	return (setmetatable({
		Mode = "2D",
		_chunks = {},
		_loaded = {},
		_chunkSize = p1,
		_folder = Folder,
		Loaded = Signal.new(),
		Unloaded = Signal.new(),
		RenderDistance = p2 or 1
	}, t1))
end
function t1.ToCoord(p3, p4) -- line: 61
	local vector3 = Vector3.new(math.round(p4.X / p3._chunkSize + 0.5), math.round(p4.Y / p3._chunkSize + 0.5), (math.round(p4.Z / p3._chunkSize + 0.5)))

	if p3.Mode == "2D" then
		return vector3 * Vector3.new(1, 0, 1)
	end

	return vector3
end
function t1.Add(p5, p6, p7) -- line: 73
	local v13 = p5:ToCoord(p6)
	local v14 = p5._chunks[v13]

	if not v14 then
		v14 = {}
		p5._chunks[v13] = v14
	end

	if table.find(v14, p7) then
		return
	end

	local v15 = p5._loaded[v13] ~= nil

	if typeof(p7) == "Instance" then
		p7.Parent = v15 and p5._folder or nil
	end

	if v15 then
		p5.Loaded:Fire(p7, v13)
	end

	table.insert(v14, p7)
end
function t1.Remove(p8, p9, p10) -- line: 94
	local v19 = p8:ToCoord(p9)
	local v20 = p8._chunks[v19]

	if not v20 then
		return
	end

	for v21, v22 in v20 do
		if v22 == p10 then
			v20[v21] = nil
			p8.Unloaded:Fire(p10, v19)

			break
		end
	end

	if not next(v20) then
		table.clear(v20)
		p8._chunks[v19] = nil
	end
end
function t1.GetChunk(p11, p12) -- line: 115
	return p11._chunks[p12]
end
function t1.GetChunkFromPosition(p13, p14) -- line: 119
	return p13:GetChunk(p13:ToCoord(p14))
end
function t1.IsLoaded(p15, p16) -- line: 123
	return p15._loaded[p16] ~= nil
end
function t1.IsValueLoaded(p17, p18) -- line: 127
	for v31 in p17._loaded do
		local v32 = p17._chunks[v31]

		if v32 then
			for _, v34 in v32 do
				if v34 == p18 then
					return true
				end
			end
		end
	end

	return false
end
function t1.Update(p19, p20) -- line: 142
	local v37 = p19:ToCoord(p20)
	local v38 = p19.RenderDistance - 1
	local t2 = {}

	if p19.Mode == "2D" then
		for i = -v38, v38 do
			for j = -v38, v38 do
				t2[v37 + Vector3.new(i, 0, j)] = true
			end
		end
	else
		for i = -v38, v38 do
			for j = -v38, v38 do
				for k = -v38, v38 do
					t2[v37 + Vector3.new(i, j, k)] = true
				end
			end
		end
	end

	for v45 in t2 do
		local Chunk = p19:GetChunk(v45)

		if Chunk and not p19._loaded[v45] then
			for _, v48 in Chunk do
				if typeof(v48) == "Instance" then
					v48.Parent = p19._folder
				end

				p19.Loaded:Fire(v48, v45)
			end

			p19._loaded[v45] = true
		end
	end

	for v49 in p19._loaded do
		local Chunk = p19:GetChunk(v49)

		if Chunk and not t2[v49] then
			for _, v52 in Chunk do
				if typeof(v52) == "Instance" then
					v52.Parent = nil
				end

				p19.Unloaded:Fire(v52, v37)
			end

			p19._loaded[v49] = nil
		end
	end
end

return t1
