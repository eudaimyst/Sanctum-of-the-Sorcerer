	-----------------------------------------------------------------------------------------
	--
	-- map/fileio.lua --for loading and saving map files
	--
	-----------------------------------------------------------------------------------------
	-- Common modules
	local json = require("json") --for encoding/decoding

	-- Define module
	local fileio = {}

	local function stripTileData(_tileStore, tileSet)
		local tileStore = {}
		for i = 1, #_tileStore do
			local tileSaveData = {}
			local tile = _tileStore[i] --stores the data for each tile
			for j = 1, #tileSet do
				if tile.typeName == tileSet[j].name then
					tileSaveData.s = tileSet[j].savestring
					tileSaveData.c = tileSet[j].collision 
					tileStore[#tileStore+1] = tileSaveData --adds the tile to the map save data
				end
			end
		end
		return tileStore
	end

	local function stripRoomData(_rooms, tileSize)
		local rooms = {}
		for i = 1, #_rooms do
			local room = _rooms[i]
			local roomData = {}
			roomData.bounds = { min = { x = {room.worldBounds.min.x / tileSize}, y = {room.worldBounds.min.y / tileSize} },
								max = { x = {room.worldBounds.max.x / tileSize}, y = {room.worldBounds.max.y / tileSize} } }
			rooms[i] = roomData
		end
		return rooms
	end
	local numberParams = {"width", "height"}
	--[[ params = width, height, tiles, saveTileSize, rooms, startRoom, endRoom, treasureRoom, startPoint, endPoint, level ]]
	function fileio.save(params, _fileName)
		print("-----------------map save begin -------------------")
		local fileName = _fileName or "noFileNameSet_level"
		--local tileSet = level.tileset
		params.tileset = params.level.tileset
		params.name = params.level.name
		params.tiles = stripTileData(params.tiles, params.tileset)
		params.rooms = stripRoomData(params.rooms, params.saveTileSize)
		params.level = nil --we don't need to save all the level data so we destroy the reference
		params.saveTileSize = nil
		params.tileset = nil
		local mapSaveData = params

		local filePath = system.pathForFile( fileName..".json", system.DocumentsDirectory )


		--print("mapSaveData:\n-----------------\n"..json.prettify(mapSaveData))

		local file = io.open( filePath, "w" ) --open file for writing

	    if file then
			print("writing file "..fileName..".json")
	        file:write( json.encode( mapSaveData ) )  --write map data
	        io.close( file ) --close file
	    end
		print("-----------------map save complete -------------------")
	end

	function fileio.load(filePath)
		print("-----------------map load begin -------------------")
		print("filepath: "..filePath)
		local saveData

		local file = io.open( filePath, "r" ) --open file for reading
		if file then
			print("loading file: "..filePath)

	        local contents = file:read( "*a" ) --store contents in a local variable
			io.close( file )
	        saveData = json.decode( contents ) --decode json contents and store in a local table
	        --print(json.prettify(saveData)) confirms file is loading by printing contents of data
	    end
	    local width, height, level = tonumber(saveData[1]), tonumber(saveData[2]), saveData[4]
		local spawnPoint = { x = tonumber(saveData[3].x), y = tonumber(saveData[3].y) }
		print("spawnpoint x, y = "..spawnPoint.x..", "..spawnPoint.y)
	    local tileSaveData = {}
	    for i = 1, #saveData-3 do
	    	tileSaveData[i] = saveData[i+4]
	    end
		print("-----------------map load complete -------------------")
	    return width, height, spawnPoint, level, tileSaveData
	end

	return fileio