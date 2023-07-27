	-----------------------------------------------------------------------------------------
	--
	-- map.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local saveload = require( "lib.map.saveload")

	local defaultTileset = { --collision data is saved in map data
		[1] = {name = "void", savestring = "v", image = "void.png"},
		[2] = {name = "wall", savestring = "x", image = "dungeon_wall.png"},
		[3] = {name = "floor", savestring = "f", image = "dungeon_floor.png"},
		[4] = {name = "water", savestring = "w", image = "void.png"},
		[5] = {name = "blocker", savestring = "b", image = "dungeon_wall.png"}
	}
	--not yet implemented
	local wallAffixes = { z = "void_", i = "inner_corner_", o = "outer_corner_", h = "horizontal_", v = "vertical_", e = "error_" }

	-- Define module
	local map = {}

	map.group = display.newGroup()

	map.tileStore = { tileRows = {}, tileCols = {}, indexedTiles = {}} --set by loadMap
	map.startTileID = 0 --tile for character to start on, accessed by game loadMap

	-- include json for save/loading map
	map.params = { width = 10, height = 10, tileStore = {}, tileSize = 128, tileset = defaultTileset }
	map.imageLocation = "content/map/"


	function map:createMapTiles(tileData) --called by editor/map, creates all tile objects for maps

		local width, height, tileSize, tileset, fileName = self.params.width, self.params.height, self.params.tileSize, self.params.tileset, "level"

		local function createTile(x, y, i) --new tile constructor
			--print("creating tile with ID:"..i)
			local tile = {}
			tile.id, tile.x, tile.y = i, x, y
			tile.worldX, tile.worldY = x*tileSize, y*tileSize

			local image
			--print(i..": "..json.prettify(tileData[i]))
			--print("ts: "..json.prettify(defaultTileset))
			for j = 1, #defaultTileset do
				if tileData[i].s == defaultTileset[j].savestring then
					--print("found")
					image = defaultTileset[j].image
				end
			end
			tile.imageFile = self.imageLocation.."defaultTileset/"..image

			function tile:destroyRect()
			end

			function tile:createRect()
				print("creating rect for tile id: "..self.id.. " with image "..image)
				self.rect = display.newImageRect( map.group, self.imageFile, tileSize, tileSize )
				self.rect.x, self.rect.y = self.worldX, self.worldY
			end
			tile:createRect()

			return tile
		end

		local x, y = 1, 1
		for i = 1, #tileData do
			--print(x, y)
			local tile = createTile(x, y, i)
			if y == 1 then map.tileStore.tileCols[x] = {} end
			if x == 1 then map.tileStore.tileRows[y] = {} end
			map.tileStore.tileCols[x][y] = tile
			map.tileStore.tileRows[y][x] = tile
			map.tileStore.indexedTiles[i] = tile
			if x >= width then
				x, y = 1, y + 1
			else
				x = x + 1
			end
		end
	end

	function map:loadMap()
		print("loading map in map.lua")
		local width, height, level, tileData = saveload.load("level")
		self.params.width, self.params.height = width, height
		self:createMapTiles(tileData)
	end

	function map:init()

	end

	function map:onFrame() --called from game or level editor on frame

	end

	--[[
	function map.tilesBetweenBounds(x1, y1, x2, y2) --returns a table of tiles in a square between two tile positions
		--print("get tiles between",x1,y1,x2,y2)
		local tiles = {}
		local width = x2 - x1
		local height = y2 - y1
		local count = 0
		for xCount = 0, width, 1 do
			for yCount = 0, height, 1 do
				local index = (x1 + xCount) + (y1 * mapWidth) + (yCount * mapWidth)
				tiles[count] = map.tileStore[index]
				count = count + 1
			end
		end
		--print("getting "..count.." tiles from tile store")
		--print("total "..#tiles.." tiles added")
		return tiles
	end

	function map.getTileData() --"called by mapgen, needs data for setting tileTypes"
		return tileData
	end

	map.enemySpawners = {}
	function map.createSpawners( ) --called from first frame in game after cam has loaded to set position
		print("create "..#map.enemySpawners.." spawners")

		for i = 0, #map.enemySpawnersData do
			local spawner = map.enemySpawnersData[i]
			spawner.id = i
			spawner.rect = display.newImageRect(spawnerGroup, imageLocation.."enemy_spawner.png", tileSize, tileSize)
			--spawner.rect.isVisible = false
			spawner.rect.obj = spawner
			spawner.x, spawner.y = map.idtoworldxy(spawner.tileID)
			--print("xy: ", spawner.x, spawner.y)
			--spawner = cam.updateRect(spawner) --takes an object and automagically moves its rect to its screen position
			spawner.rect.alpha = .8
			spawner.enemiesSpawned = 0
			spawner.active = true
			spawner.timer = 0
			map.enemySpawners[i] = spawner
		end
	end

	function map.loadMap(fileName, enemyTypes)

		local function compareWallData(wallData, i) --compare passed wallData with wallaffix keys to set wall image affixes
			local saveAffixString = wallData[i]
			for affixString, imageAffix in pairs(wallAffixes) do --iterate through table of save string keys and affixes values
				if tostring(affixString) == saveAffixString then --if t save string matches tables key
					--print("affix string, save affix string, image affix: ", affixString, saveAffixString, imageAffix)
					return imageAffix --return appropriate affix
				end
			end
		end

		--set defaults
		fileName = fileName or "level"

		--set a default file path for saving/loading levels
		local filePath = system.pathForFile( fileName..".json", system.DocumentsDirectory )
		print("opening map "..fileName)
		local file = io.open( filePath, "r" ) --open file for reading
	 
	    if file then
	    	print("start loading map")
	        local contents = file:read( "*a" ) --store contents in a local variable
	       io.close( file )
	        local saveData = json.decode( contents ) --decode json contents and store in a local table

	        mapWidth = tonumber( saveData.mapWidth ) --get map size
	        mapHeight = tonumber( saveData.mapHeight )
	        map.startTileID = tonumber( saveData.startTileID ) --get id of tile to spawn player
	        --print("!!!!!!!!!!! start tile ID: "..map.startTileID)


	        local loadTileStore = {} --create tile store which stores all tile data for map

			for id, saveString in pairs(saveData.saveString) do --get all id saveStrings from savedata
		 		--print(k1,v1) --for testing
		 		
		 		local tile = {id = 0, collision = false, image = "", wallImage = {} } --create a table for tile

		 		local foundMatchingTileType = false
		 		for k, tileType in pairs(tileData) do --iterate through tileData to find matching values to laoded data
		 			if (string.sub(saveString, 1, 1) == tileType.saveString) then--compare first letter of save string to tiletype saveString
		 				tile.id = tonumber(id) --convert key to a number
		 				tile.collision = tileType.collision --set matching data
		 				tile.image = tileType.image
		 				tile.tileType = tileType
		 				--print("loaded tile id: "..id)
		 				if (tileType == tileData.wall) then --tile is a wall set wallData
			 				tile.wallData = {}
			 				for i = 2, 5, 1 do --for characters 2-5 in saveString
			 					tile.wallData[i-2] = string.sub(saveString, i, i) --store found character to index 0-3 in table
			 				end
			 			end
		 				loadTileStore[tile.id] = tile --store tile for future reference
		 				foundMatchingTileType = true
		 				--print("setting tile# "..k1.." with data "..v1.." to tileType "..k2.."collision: "..v2.collision.."image: "..v2.image)
		 			end
		 		end

		 		--concat string at load rather than when rect is made for performance
		 		if tile.tileType == tileData.wall then
					for i = 0, 3 do
						local wallString = compareWallData(tile.wallData, i) --get affixString from wallData from tile
						--print("wallString for tile "..tile.id.." at side# "..i.." is: "..wallString)
						--print(wallString)
						tile.wallImage[i] = imageLocation..tile.tileType.image..wallString..i..".png"
						--print(tile.wallImage[i])
					end
				else
		 			tile.image = imageLocation..tile.image 
				end



			end

			local function convertToNumbers(targetTable, sourceTable) --need to convert string data from json to numbers
				for k, v in pairs(sourceTable) do
					targetTable[tonumber(k)] = tonumber(v)
				end
			end

			local function storeString(targetTable, sourceTable) --if data is a string still need to store in array at index converted to number
				for k, v in pairs(sourceTable) do
					targetTable[tonumber(k)] = v
				end
			end
			
			local spawnerData = {tileID = {}, iterations = {}, timer = {}, enemyType = {} }
			
			convertToNumbers(spawnerData.tileID, saveData.spawnerTileID)
			convertToNumbers(spawnerData.iterations, saveData.spawnerIterations)
			convertToNumbers(spawnerData.timer, saveData.spawnerTimer)
			storeString(spawnerData.enemyType, saveData.spawnerEnemyType)

			for i = 0, #spawnerData.enemyType, 1 do --iterate through enemy type save data
			 	for k, v in pairs(enemies.enemyData) do --iterate through tileData to find matching values to laoded data
			 		--print("setting spawner type for spawner "..i..", to "..v.saveString..", "..v.name)
			 		if (v.saveString == spawnerData.enemyType[i]) then --if save string in enemyType are checking matches save data
			 			spawnerData.enemyType[i] = v --set enemy type
			 			--print(spawnerData.enemyType[i].name)
			 		end
			 	end
			 	--print("all spawner data loaded for spawner: "..i..", tileID: "..spawnerData.tileID[i]..", iterations: "..spawnerData.iterations[i]..", timer: "..spawnerData.timer[i]..", enemy type: "..spawnerData.enemyType[i].name)
			end

			map.enemySpawnersData = {} --merge all spawner data from multiple tables into one 
			for i = 0, #spawnerData.tileID, 1 do
				local spawner = {}
				spawner.tileID = spawnerData.tileID[i]
				spawner.iterations = spawnerData.iterations[i]
				spawner.timer = spawnerData.timer[i]
				spawner.enemyType = spawnerData.enemyType[i]
				map.enemySpawnersData[i] = spawner
			end
			
	        print("map data loaded with width: ".. mapWidth..", height: "..mapHeight..", tileCount: "..#loadTileStore..", spawnerCount: "..#map.enemySpawners)
			
			--call function to create tiles using data from load tile store and put them in map tile Store
			for i = 0, #loadTileStore do
				local tile = loadTileStore[i]
	        	map.tileStore[i] = createTile ( tile.id, tile.collision, tile.image, tile.tileType, tile.wallImage )
	    	end
	    	debug.updateText("tiles", #map.tileStore)

	    else
	    	print("no map found with name "..fileName..".json")
	    	return nil, nil, nil
	    end
	end
	]]

	return map
