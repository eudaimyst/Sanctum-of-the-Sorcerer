	-----------------------------------------------------------------------------------------
	--
	-- map.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local util = require("lib.global.utilities")
	local fileio = require( "lib.map.fileio")
	local tiles = require("lib.entity.tile")
	local json = require("json")
	local decal = require("lib.entity.decal")
	local cam -- set by init from scene
	local game

	local defaultTileset = { --this is the default tileset data FOR THE SCENE ONLY (map generator has its own fix is TODO)
		void = { savestring = "v", image = "void.png"},
		wall = { savestring = "x", image = "dungeon_wall.png"},
		floor = { savestring = "f", image = "dungeon_floor.png"},
		water = { savestring = "w", image = "void.png"},
		blocker = { savestring = "b", image = "dungeon_wall.png"}
	}

	local wallSubTypes = { void = "void_", innerCorner = "inner_corner_", outerCorner = "outer_corner_",
		horizontal = "horizontal_", vertical = "vertical_", error = "error_" }

	-- Define module
	local map = {}

	map.group = display.newGroup()
	map.tileGroup = display.newGroup()
	map.decalGroup = display.newGroup()
	map.group:insert(map.tileGroup)
	map.group:insert(map.decalGroup)

	map.tileStore = { tileRows = {}, tileCols = {}, indexedTiles = {}} --set by loadMap
	map.startTileID = 0 --tile for character to start on, accessed by game loadMap
	map.tileData = {}
	
	map.params = { width = 10, height = 10, tileStore = {}, tileSize = 128, tileset = defaultTileset }

	--locals for performance,
	local mfloor = math.floor

	local camTiles = {} --tiles within camera bounds
	local lastFrameCamTiles = {} --tiles within cameraBounds on previous frame
	local tileSize = 0  --set by createMapTiles from params 
	local tStoreCols, tStoreIndex = {}, {} --set by createMaptiles

	local mapImageFolder = "content/map/"

	local function worldPointToTileCoords(_x, _y) --takes x y in world coords and returns tile coords
		--print("worldPointToTileCoords:", _x, _y)
		local x, y = mfloor(_x / tileSize), mfloor( _y / tileSize)
		--clamp the returned tile coords to the map size
		if x > map.width then x = map.width; print("WARNING: point outside bounds (worldPointToTileCoords)")
		elseif x < 1 then x = 1; print("WARNING: point outside bounds (worldPointToTileCoords)")
		end
		if y > map.height then y = map.height; print("WARNING: point outside bounds (worldPointToTileCoords)")
		elseif y < 1 then y = 1; print("WARNING: point outside bounds (worldPointToTileCoords)")
		end
		--print("result:", x, y)
		return x, y
	end
	
	local function setColor(tileList, color)
		local c = { r = 1, g = 1, b = 1, a = 1 }
		if (color == "red") then
			c.r = 1; c.g = .5; c.b = .5
		elseif (color == "green") then
			c.r = .5; c.g = 1; c.b = .5
		end
		for i = 1, #tileList do
			if (tileList[i].rect.numChildren) then
				for j = 1, tileList[i].rect.numChildren do
					tileList[i].rect[j]:setFillColor(c.r, c.g, c.b, c.a)
				end
			else
				tileList[i].rect:setFillColor(c.r, c.g, c.b, c.a)
			end
		end
	end
	map.setColor = setColor

	function map.getTileStore()
		return tStoreIndex, tStoreCols
	end

	function map.getCamTiles()
		return camTiles
	end


	function map:getTileAtPoint(pos) --takes pos table with x, y and returns tile at that world pos
		--print("get tile: ", pos.x, pos.y)
		if (pos) then
			local x, y = worldPointToTileCoords(pos.x, pos.y)
			return tStoreCols[x][y]
		else
			print("no point passed, can not get tile")
		end
	end

	function map:getTilesBetweenWorldBounds(x1, y1, x2, y2) --takes bounds in world position and returns table of tiles
		local tileMinX, tileMinY = worldPointToTileCoords(x1, y1)
		local tileMaxX, tileMaxY = worldPointToTileCoords(x2, y2)
		local tileBoundWidth = tileMaxX - tileMinX
		local tileBoundHeight = tileMaxY - tileMinY
		local tileList = {}
		local counter = 1
		for x = 1, tileBoundWidth do
			local column = tStoreCols[tileMinX + x]
			for y = 1, tileBoundHeight do
				--print("getting tile from store:", x, y)
				tileList[counter] = column[tileMinY + y]
				counter = counter + 1
			end
		end
		return tileList
	end

	function map:getSpawnPoint()
		if self.spawnPoint then
			return self.spawnPoint
		else
			return { x = self.params.width*self.params.tileSize / 2, y = self.params.width*self.params.tileSize / 2 }
		end
	end

	function map:createTexturesFromTileset(tileset)--preloads the tile textures
		for k, tileData in pairs(tileset) do
			print("creating tileset for texture: "..k)
			local fName = mapImageFolder.."default_tileset/"..tileset[k].image
			
			print(fName)
			tileData.texture = graphics.newTexture( { type = "image", filename = fName, baseDir = system.ResourceDirectory } )
		end
	end
	
	function map:createSavestringLookup(tileset) --takes a tileset and makes a lookup table from savestring to tile type
		map.saveStringLookup = {}
		for k, v in pairs(tileset) do
			map.saveStringLookup[v.savestring] = k
		end
	end

	function map:createMapTiles(_tileData) --called by editor/map, creates all tile objects for maps, tileData = optional map data, tileSize = optional force tile size in pixels
		print("create map tiles called")
		
		local tileData = _tileData or self.tileData
		local tileStore = {}
		self.tileStore = tileStore
		tStoreCols, tStoreIndex = {}, {}

		if (cam.mode == cam.modes.debug) then --if debugging cam tiles have different size
			print("camdebug tilesize = "..cam.mode.debugTileSize)
			tileSize = cam.mode.debugTileSize
		else
			tileSize = self.params.tileSize
		end
		print("tileData length: "..#tileData)

		--TODO: clean this up by copying all params to module
		self.width, self.height = self.params.width, self.params.height
		self.tileSize = self.params.tileSize
		tileSize = self.tileSize
		self.tileset = defaultTileset
		self.worldWidth, self.worldHeight = self.params.width * tileSize, self.params.height * tileSize
		self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2
		local width, height, tileset = self.width, self.height, self.tileset --set local vars for readability
		local halfTileSize = tileSize/2

		self:createSavestringLookup(defaultTileset) --takes a tileset and makes a lookup table from savestring to tile type
		--print(json.prettify(self.saveStringLookup))
		self:createTexturesFromTileset(defaultTileset) --preloads the tile textures

		tiles:init(game, self, cam, defaultTileset, wallSubTypes, mapImageFolder) --initialise the tile module

		local x, y = 1, 1
		local createTile = tiles.createTile
		for i = 1, #tileData do --for each tile in the tileData taken from the map file
			--print(x, y)
			local data = tileData[i]
			local tile = createTile(tiles, i, x, y, data.c, data.s)
			if y == 1 then tStoreCols[x] = {} end --create the tileCols 
			tStoreCols[x][y] = tile --store the tile in the correct position in tileCols
			tStoreIndex[i] = tile --also store the tile in an indexed table

			if x >= width then --reached the end of tile creation for the row
				x, y = 1, y + 1 --increase the counter for the y axis and reset the x
			else
				x = x + 1 --increase the counter for the x axis
			end
		end

		for i = 1, #tStoreIndex do --set subtypes, must be after all tiles created to get neighbour tiles
			local tile = tStoreIndex[i]
			if tile.type == "wall" then
				tile:setWallSubType()
			end
		end
		print(#tStoreIndex.." map tiles created \n ----map creation complete----")
	end

	function map:createDecals()
		for i = 1, #self.decalSavedata do
			local decalData = self.decalSavedata[i]
			for decalName, saveData in pairs(decalData) do
				decal:create(decalName, saveData, tileSize)
			end
		end
	end



	function map:loadMap(_fName, isResource)
		print("loadMap called from map lib")
		local filePath
		if (isResource) then
			--local fName = _fName
			filePath = system.pathForFile( system.ResourceDirectory ).."/levels/".._fName..".json"
			print("filePath: "..filePath)
		else
			filePath = system.pathForFile( _fName..".json", system.DocumentsDirectory )
		end

		local saveData = fileio.load(filePath)
		--[[ saveData = width, height, tiles, saveTileSize, rooms, startRoom, endRoom, treasureRoom, startPoint, endPoint, level ]]

		self.params.width, self.params.height = saveData.width, saveData.height --width and height in tiles
		self.spawnPoint = {x = saveData.startPoint.x / saveData.saveTileSize * self.params.tileSize, y = saveData.startPoint.y / saveData.saveTileSize * self.params.tileSize}
		print("spawnPoint set to map: "..self.spawnPoint.x..", "..self.spawnPoint.y)
		self.worldWidth, self.worldHeight = saveData.width * self.params.tileSize, saveData.height * self.params.tileSize --width and height in pixels
		self.enemies = saveData.enemies
		self.decalSavedata = saveData.decals
		
		self:createMapTiles(saveData.tiles) --call function to create tiles
		self.tileData = saveData.tiles --store tileData to redraw map without reloading
		print("-----load map complete-----")
		return true
	end

	local t_tile --temp tile reference
	function map:refreshCamTiles() --gets all tiles within cams bounds and updates their rect
		local cb = cam.bounds
		--get cam tiles within cam borders
		camTiles = self:getTilesBetweenWorldBounds( cb.x1-tileSize, cb.y1-tileSize,
													cb.x2+tileSize, cb.y2+tileSize )
		print(#camTiles)
		t_tile = nil
		for i = 1, #camTiles do
			t_tile = camTiles[i]
			t_tile.onScreenCheck = true
			if (t_tile.rect) then --tile already has rect
				t_tile:updateRectPos() --update the tiles rect based off cam bounds  
			else
				--print("created rect for tile", tempTile.id)
				t_tile:createRect()
			end
		end
		for i = 1, #lastFrameCamTiles do
			t_tile = lastFrameCamTiles[i]
			if (t_tile.onScreenCheck == false) then
				if (t_tile.rect) then --tiles already has rect
					t_tile:destroyRect() --destroy the tiles rect
				end
			end
			t_tile.onScreenCheck = false
		end
		lastFrameCamTiles = {}
		for i = 1, #camTiles do
			lastFrameCamTiles[i] = camTiles[i]
		end
	end

	function map:cameraZoom() --1 = zoom in, 2 = zoom out
		cam:updateBounds()
		self:refreshCamTiles()
		--print("zooming")
	end

	function map:clear()
		local ts = self.tileStore --readability
		for i = 1, #ts.indexedTiles do
			--print("clearing tile: "..i)
			ts.tileRows[ts.indexedTiles[i].y][ts.indexedTiles[i].x] = nil
			ts.tileCols[ts.indexedTiles[i].x][ts.indexedTiles[i].y] = nil
			if (ts.indexedTiles[i].rect) then
				ts.indexedTiles[i].rect:removeSelf()
				ts.indexedTiles[i].rect = nil
			end
			ts.indexedTiles[i] = nil
		end
		for i = 1, #ts.tileRows do
			ts.tileRows[i] = nil
		end
		for i = 1, #ts.tileCols do
			ts.tileCols[i] = nil
		end
		return true
	end

	function map:init(sceneGroup, _cam, _game)
		sceneGroup:insert(self.group)
		cam, game = _cam, _game
		decal:init(self)
	end

	return map
