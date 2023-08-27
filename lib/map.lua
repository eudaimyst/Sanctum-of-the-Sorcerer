	-----------------------------------------------------------------------------------------
	--
	-- map.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local util = require("lib.global.utilities")
	local fileio = require( "lib.map.fileio")
	local tiles = require("lib.map.tiles")
	local json = require("json")

	local defaultTileset = { --this is the default tileset data FOR THE SCENE ONLY (map generator has its own fix is TODO)
		void = { savestring = "v", image = "void.png"},
		wall = { savestring = "x", image = "dungeon_wall.png"},
		floor = { savestring = "f", image = "dungeon_floor.png"},
		water = { savestring = "w", image = "void.png"},
		blocker = { savestring = "b", image = "dungeon_wall.png"}
	}
	local decalData = {
		win = "window/window.png"
	}
	local decalTextures = {}

	local wallSubTypes = { void = "void_", innerCorner = "inner_corner_", outerCorner = "outer_corner_",
		horizontal = "horizontal_", vertical = "vertical_", error = "error_" }

	-- Define module
	local map = {}
	local cam = {} --set by init from scene

	map.group = display.newGroup()
	map.tileGroup = display.newGroup()
	map.decalGroup = display.newGroup()
	map.group:insert(map.tileGroup)
	map.group:insert(map.decalGroup)

	map.tileStore = { tileRows = {}, tileCols = {}, indexedTiles = {}} --set by loadMap
	map.decalStore = {}
	map.startTileID = 0 --tile for character to start on, accessed by game loadMap
	map.tileData = {}

	map.params = { width = 10, height = 10, tileStore = {}, tileSize = 128, tileset = defaultTileset }

	local mapImageFolder = "content/map/"

	local function worldPointToTileCoords(_x, _y) --takes x y in world coords and returns tile coords
		--print("map width/height: "..map.worldWidth..", "..map.worldHeight)
		local x, y = math.floor(_x / map.tileSize), math.floor( _y / map.tileSize)
		--print("worldPointToTileCoords: ".._x.." = "..x..", ".._y.." = "..y)
		return x, y
	end
	
	local function hideTiles(tileList)
		for i = 1, #tileList do
			if (tileList[i].rect) then
				tileList[i]:destroyRect()
			end
			tileList[i].rect = nil
		end
	end
	map.hidetiles = hideTiles

	local function  showTiles(tileList)
		for i = 1, #tileList do
			if (not tileList[i].rect) then
				--print("showing tile for id "..i.." at world x, y: "..tileList[i].world.x, tileList[i].world.y)
				tileList[i]:createRect()
				tileList[i]:updateRectPos()
			end
		end
	end
	map.showTiles = showTiles
	
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

	local function clampToMapSize(_x, _y) --takes tile pos and returns clamped tile pos
		local x, y
		x, y = math.max(1, _x), math.max(1, _y) --clamp to 1 to prevent looking for tiles outside of map
		x, y = math.min(x, map.width), math.min(y, map.height) --clamp to map width/height
		return x, y
	end

	function map:getTileAtPoint(pos) --takes pos table with x, y and returns tile at that world pos
		--print("get tile: ", pos.x, pos.y)
		if (pos) then
			local x, y = worldPointToTileCoords(pos.x, pos.y)
			return self.tileStore.tileCols[x][y]
		else
			print("no point passed, can not get tile")
		end
	end

	function map:getTilesBetweenWorldBounds(x1, y1, x2, y2) --takes bounds in world position and returns table of tiles
		local cMin, cMax = {x = 0, y = 0}, {x = 0, y = 0} --bounds of the cam
		cMin.x, cMin.y = worldPointToTileCoords(x1, y1)
		cMax.x, cMax.y = worldPointToTileCoords(x2, y2)
		local bMin, bMax = {x = 0, y = 0}, {x = 0, y = 0} --bounds of the cam
		bMin.x, bMin.y = worldPointToTileCoords(x1 - self.tileSize, y1 - self.tileSize)
		bMax.x, bMax.y = worldPointToTileCoords(x2 + self.tileSize, y2 + self.tileSize)
		--local boundWidth, boundHeight = boundMax.x - boundMin.x, boundMax.y - boundMin.y
		local tileList = {}
		local tileListCols = {} --stores tiles in a col/row format for lighting
		local boundaryTiles = { up = {}, down = {}, left = {}, right = {} } --tiles on the edge of the bounds
		local tx, ty --used for clamping
		for y = cMin.y, cMax.y do
			for x = cMin.x, cMax.x do
				tx, ty = clampToMapSize(x, y)
				--print("getting tile: "..tx..", "..ty.." from tileStore")
				tileList[#tileList+1] = self.tileStore.tileCols[tx][ty]
				if x == cMin.x then
					tileListCols[#tileListCols+1] = {}
				end
				tileListCols[#tileListCols][x-cMin.x+1] = self.tileStore.tileCols[tx][ty]
			end
		end
		for y = bMin.y, bMax.y do
			tx, ty = clampToMapSize(bMin.x, y)
			boundaryTiles.left[#boundaryTiles.left+1] = self.tileStore.tileCols[tx][ty]
			tx, ty = clampToMapSize(bMax.x, y)
			boundaryTiles.right[#boundaryTiles.right+1] = self.tileStore.tileCols[tx][ty]
		end
		for x = bMin.x, bMax.x do
			tx, ty = clampToMapSize(x, bMin.y)
			boundaryTiles.up[#boundaryTiles.up+1] = self.tileStore.tileCols[tx][ty]
			tx, ty = clampToMapSize(x, bMax.y)
			boundaryTiles.down[#boundaryTiles.down+1] = self.tileStore.tileCols[tx][ty]
		end
		--print(#tileList.." tiles between bounds ", x1, y1, x2, y2)
		for k, v in pairs(boundaryTiles) do
			--print("boundary "..k.." has "..#v.." tiles")
		end
		return tileList, boundaryTiles, tileListCols
	end

	function map:createTexturesFromTileset(tileset)--preloads the tile textures
		for k, tileData in pairs(tileset) do
			print("creating tileset for texture: "..k)
			local fName = mapImageFolder.."default_tileset/"..tileset[k].image
			
			print(fName)
			tileData.texture = graphics.newTexture( { type = "image", filename = fName, baseDir = system.ResourceDirectory } )
		end
	end

	function map:createDecalTextures()
		local decalDir = mapImageFolder.."decals/"
		print("loading decal textures")
		for k, v in pairs(decalData) do
			local path = decalDir..v
			print(k, v, "path=", path)
			decalTextures[k] = graphics.newTexture( { type = "image", filename = path, baseDir = system.ResourceDirectory } )
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
		local tileSize
		local tileStore = {}
		self.tileStore = tileStore
		local tileStoreCols, tileStoreRows, tileStoreIndex = {}, {}, {}
		tileStore.tileCols, tileStore.rows, tileStore.indexedTiles = tileStoreCols, tileStoreRows, tileStoreIndex

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
		self.tileset = defaultTileset
		self.worldWidth, self.worldHeight = self.params.width * tileSize, self.params.height * tileSize
		self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2
		local width, height, tileset = self.width, self.height, self.tileset --set local vars for readability
		local halfTileSize = tileSize/2

		self:createSavestringLookup(defaultTileset) --takes a tileset and makes a lookup table from savestring to tile type
		--print(json.prettify(self.saveStringLookup))
		self:createTexturesFromTileset(defaultTileset) --preloads the tile textures
		self:createDecalTextures()

		tiles:init(self, cam, defaultTileset, wallSubTypes, mapImageFolder) --initialise the tile module

		local x, y = 1, 1
		local createTile = tiles.createTile
		for i = 1, #tileData do --for each tile in the tileData taken from the map file
			--print(x, y)
			local data = tileData[i]
			local tile = createTile(tiles, i, x, y, data.c, data.s)
			if y == 1 then tileStoreCols[x] = {} end --create the tileCols 
			if x == 1 then tileStoreRows[y] = {} end --create the tileRows 
			tileStoreCols[x][y] = tile --store the tile in the correct position in tileCols
			tileStoreRows[y][x] = tile
			tileStoreIndex[i] = tile --also store the tile in an indexed table

			if x >= width then --reached the end of tile creation for the row
				x, y = 1, y + 1 --increase the counter for the y axis and reset the x
			else
				x = x + 1 --increase the counter for the x axis
			end
		end

		for i = 1, #tileStoreIndex do --set subtypes, must be after all tiles created to get neighbour tiles
			local tile = tileStoreIndex[i]
			if tile.type == "wall" then
				tile:setWallSubType()
			end
		end
		print(#self.tileStore.indexedTiles.." map tiles created \n ----map creation complete----")
	end

	function map:updateTilesPos()
		for i = 1, #self.tileStore.indexedTiles do --
			self.tileStore.indexedTiles[i]:updateRectPos()
		end
	end

	function map:createDecals()
		for i = 1, #self.decalSavedata do
			local decalData = self.decalSavedata[i]
			for decalName, saveData in pairs(decalData) do
				local decal = {}
				print(json.prettify(saveData))
				print(decalName, decalName, decalName)
				print(decalTextures[decalName].filename)
				decal.texture = { filename = decalTextures[decalName].filename, baseDir = decalTextures[decalName].baseDir }
				display.newImageRect(self.decalGroup, decalTextures[decalName].filename, decalTextures[decalName].baseDir, 128, 128);
				decal.rect.x = saveData.x * self.tileSize
				decal.rect.y = saveData.y * self.tileSize
				decal.rect.rotation = saveData.angle
				map.decalStore[#map.decalStore+1] = decal
			end
		end
	end

	function map:getSpawnPoint()
		if self.spawnPoint then
			return self.spawnPoint
		else
			return { x = self.params.width*self.params.tileSize / 2, y = self.params.width*self.params.tileSize / 2 }
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
	
	function map:refreshCamTiles(bounds, tileSize) --gets and updates all tiles within cam bounds, default bounds/spacing are cam bounds/tilesize unscaled

		local cb = bounds or cam.bounds
		local s = tileSize or self.tileSize * 2	--buffer size
		cam.screenTiles, cam.boundaryTiles, cam.screenTileCols = self:getTilesBetweenWorldBounds( cb.x1-s, cb.y1-s, cb.x2+s, cb.y2+s ) --get cam tiles within cam borders

	end

	function map:updateDebugTiles(direction) --when camera is in debug mode this called to update tiles rather than move them
		--[[print("scaled")
		for k, v in pairs(cam.mode.scaledBounds) do
			print(k, v)
		end]]
		self:refreshCamTiles(cam.mode.scaledBounds, cam.mode.tileSize) --updates cam tiles to new cam bounds
		
		if direction.y > 0 then
			setColor(cam.boundaryTiles.up, "white")
		elseif direction.y < 0 then
			setColor(cam.boundaryTiles.down, "white")
		end
		if direction.x > 0 then
			setColor(cam.boundaryTiles.left, "white")
		elseif direction.x < 0 then
			setColor(cam.boundaryTiles.right, "white")
		end
		setColor(cam.screenTiles, "green")
		for _, tileList in pairs(cam.boundaryTiles) do --set color to red for tiles on cam bound edges
			setColor(tileList, "red")
		end
	end

	function map:cameraMove(direction) --called when the camera moves in a direction to hide/show tiles at camera boundary
		if (cam.mode == cam.modes.debug) then --if debug mode is on for camera, we do not move / destroy tiles, only update their display
			self:updateDebugTiles(direction)
		else
			self:refreshCamTiles() --gets camera screen and boundary tiles

			--hide tiles at opposite direction of movement, show tiles in direction of movement
			if direction.y > 0 then
				hideTiles(cam.boundaryTiles.up); showTiles(cam.boundaryTiles.down)
			elseif direction.y < 0 then
				hideTiles(cam.boundaryTiles.down); showTiles(cam.boundaryTiles.up)
			end
			if direction.x > 0 then
				hideTiles(cam.boundaryTiles.left); showTiles(cam.boundaryTiles.right)
			elseif direction.x < 0 then
				hideTiles(cam.boundaryTiles.right); showTiles(cam.boundaryTiles.left)
			end
			for _, tile in pairs(cam.screenTiles) do
				if (tile.rect) then --tiles already has rect
					tile:updateRectPos() --update the tiles rect based off cam bounds  
				end
			end
		end
	end

	function map:cameraZoom(zoomDir) --1 = zoom in, 2 = zoom out
		self:refreshCamTiles()
		cam:updateBounds()
		print("zooming")
		if (zoomDir == 1) then
			for _, tileList in pairs(cam.boundaryTiles) do
				hideTiles(tileList)
			end
		elseif (zoomDir == 2) then
			for _, tileList in pairs(cam.boundaryTiles) do
				print("showing "..#cam.boundaryTiles.." tiles")
				showTiles(tileList)
			end
		end
		for _, tile in pairs(cam.screenTiles) do
			if (tile.rect) then --tiles already has rect
				tile:updateRectPos() --update the tiles rect based off cam bounds  
			end
		end
	end

	function map:init(sceneGroup, _cam)
		sceneGroup:insert(self.group)
		cam = _cam
	end

	return map
