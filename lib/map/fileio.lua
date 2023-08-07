	-----------------------------------------------------------------------------------------
	--
	-- map/fileio.lua --for loading and saving map files
	--
	-----------------------------------------------------------------------------------------
	-- Common modules
	local json = require("json") --for encoding/decoding

	-- Define module
	local fileio = {}

	function fileio.save(width, height, indexedTileStore, spawnPoint, level, _fileName)
		print("-----------------map save begin -------------------")
		local fileName = _fileName or "level"
		local tileSet = level.tileset
		local mapSaveData = { [1] = width, [2] = height, [3] = spawnPoint, [4] = level.name }

		local filePath = system.pathForFile( fileName..".json", system.DocumentsDirectory )

		for i = 1, #indexedTileStore do
			local tileSaveData = {}
			local tile = indexedTileStore[i] --stores the data for each tile
			for j = 1, #tileSet do
				if tile.typeName == tileSet[j].name then
					tileSaveData.s = tileSet[j].savestring
					tileSaveData.c = tileSet[j].collision 
					mapSaveData[#mapSaveData+1] = tileSaveData --adds the tile to the map save data
				end
			end
		end

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