	-----------------------------------------------------------------------------------------
	--
	-- map.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local util = require("lib.global.utilities")
	local fileio = require( "lib.map.fileio")

	local defaultTileset = { --this is the default tileset data FOR THE SCENE ONLY (map generator has its own fix is TODO)
		void = { savestring = "v", image = "void.png"},
		wall = { savestring = "x", image = "dungeon_wall.png"},
		floor = { savestring = "f", image = "dungeon_floor.png"},
		water = { savestring = "w", image = "void.png"},
		blocker = { savestring = "b", image = "dungeon_wall.png"}
	}
	--not yet implemented

	local wallSubTypes = { void = "void_", innerCorner = "inner_corner_", outerCorner = "outer_corner_", horizontal = "horizontal_", vertical = "vertical_", error = "error_" }

	-- Define module
	local map = {}
	local cam = {} --set by init from scene

	map.group = display.newGroup()

	map.tileStore = { tileRows = {}, tileCols = {}, indexedTiles = {}} --set by loadMap
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
		local boundaryTiles = { up = {}, down = {}, left = {}, right = {} } --tiles on the edge of the bounds
		local tx, ty --used for clamping
		for y = cMin.y, cMax.y do
			for x = cMin.x, cMax.x do
				tx, ty = clampToMapSize(x, y)
				--print("getting tile: "..tx..", "..ty.." from tileStore")
				tileList[#tileList+1] = self.tileStore.tileCols[tx][ty]
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
		return tileList, boundaryTiles
	end

	function map:createTexturesFromTileset(tileset)--preloads the tile textures
		for k, tileData in pairs(self.params.tileset) do
			print("creating tileset for texture: "..k)
			local fName = mapImageFolder.."default_tileset/"..tileset[k].image
			
			print(fName)
			tileData.texture = graphics.newTexture( { type = "image", filename = fName, baseDir = system.ResourceDirectory } )
		end
	end
	
	function map:createSavestringLookup(defaultTileset) --takes a tileset and makes a lookup table from savestring to tile type
		map.saveStringLookup = {}
		for k, v in pairs(defaultTileset) do
			map.saveStringLookup[v.savestring] = k
		end
	end

	function map:createMapTiles(_tileData) --called by editor/map, creates all tile objects for maps, tileData = optional map data, tileSize = optional force tile size in pixels
		print("create map tiles called")
		
		local tileData = _tileData or self.tileData
		local tileSize

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
		self.tileset = self.params.tileset
		self.worldWidth, self.worldHeight = self.params.width * tileSize, self.params.height * tileSize
		self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2
		local width, height, tileset = self.width, self.height, self.tileset --set local vars for readability
		local halfTileSize = tileSize/2

		self:createSavestringLookup(defaultTileset) --takes a tileset and makes a lookup table from savestring to tile type
		self:createTexturesFromTileset(defaultTileset) --preloads the tile textures

		local function createTile(x, y, i, s, c) --new tile constructor
			local tile = {}
			tile.id, tile.x, tile.y = i, x, y --tile.x = tile column, tile.y = tile row
			tile.col = c
			--tile screen pos is exclusively accessed through its rect
			tile.world = { x = x * tileSize, y = y * tileSize }
			
			local stringLookup = map.saveStringLookup
			local type = stringLookup[s]
			tile.type = type --sets the tile type string to the key name of the matching tileset entry
			tile.imageTexture = defaultTileset[type].texture --imageFileLocation for this tile
			--print("tile image file: "..tile.imageFile)

			function tile:setWallSubType() --look at neighbouring tiles to set a subtype for this tile
				local st = wallSubTypes

				local search = {
					[0] = {x = -1, y = -1}, --search left + up
					[1] = {x = 1, y = -1}, --search right + up
					[2] = {x = -1, y = 1}, --search left + down
					[3] = {x = 1, y = 1}, --search right + down
				}
				local subTypes = {} --each indice gets set to a value from wallSubTypes
				--store tiletypes for readability
				self.wallTexture = {}
				for subID = 0, 3, 1 do
					subTypes[subID] = st.error --set default to error

					local searchCol = self.x+search[subID].x --columns of the tiles to search
					local searchRow = self.y+search[subID].y --rows
					--print("checking wall type at col, row: "..searchCol..", "..searchRow.." for tile xy "..self.x..", "..self.y)
					local Xtype = map.tileStore.tileCols[searchCol][self.y].type --get tile type to left/right
					local Ytype = map.tileStore.tileCols[self.x][searchRow].type --get tile type above/below

					if (Xtype == "wall" ) then 
						if (Ytype == "wall") then
							local innerWallType = map.tileStore.tileCols[searchCol][searchRow].type --store tiles type
							if (innerWallType == "wall" or innerWallType == "void") then --if there is a wall or void on the diagonal tile to prevent inner corners repeating
								subTypes[subID] = st.void --need to set "void" if theres a wall or "void" on other side of corner
							else
								subTypes[subID] = st.innerCorner --otherwise normal corner
							end
						elseif (Ytype == "void") then subTypes[subID] = st.void
						elseif (Ytype == "floor") then subTypes[subID] = st.horizontal end
					end
					if (Xtype == "void") then
						if (Ytype == "void") then subTypes[subID] = st.void
						elseif (Ytype == "wall") then subTypes[subID] = st.void
						elseif (Ytype == "floor") then subTypes[subID] = st.vertical
						end
					end
					if (Xtype == "floor") then
						if (Ytype == "wall") then subTypes[subID] = st.vertical
						elseif (Ytype == "floor") then subTypes[subID] = st.outerCorner
						elseif (Ytype == "void") then subTypes[subID] = st.void
						end
					end

					--local wallImageString = map.imageLocation.."defaultTileset/dungeon_walls/"..subTypes[subID]..subID..".png"
					local fName = mapImageFolder.."default_tileset/dungeon_walls/"..subTypes[subID]..subID..".png"
					
					--print(fName)
					self.wallTexture[subID] = graphics.newTexture( { type = "image", filename = fName, baseDir = system.ResourceDirectory } )
					--self.wallImage[subID] = wallImageString
				end
				
				tile.subTypes = subTypes
			end

			function tile:updateRectPos() --updates the tiles rect position to match its world position within cam bounds and scaled by camera zoom
				if (self.rect) then
					self.rect.xScale, self.rect.yScale = cam.zoom, cam.zoom
					self.rect.x, self.rect.y = (self.world.x - cam.bounds.x1) * cam.zoom , (self.world.y - cam.bounds.y1) * cam.zoom
				end
			end

			function tile:destroyRect()
				if (self.rect) then
					self.rect:removeSelf()
					self.rect = nil
				end
			end

			function tile:createRect()
				if (self.type == "wall") then --if tile is a wall then we need to make a group for the subtiles
					self.rect = display.newGroup()
					map.group:insert(self.rect)
					self.rect.anchorChildren = true
					for i = 0, 3, 1 do --four corners
						local wallRect = display.newImageRect( self.rect, self.wallTexture[i].filename, self.wallTexture[i].baseDir, halfTileSize, halfTileSize ) --create rect for each wall
						wallRect = util.zeroAnchors(wallRect)
						local n, r = math.modf( i / 2 ) --set wall rect position using math
						wallRect.x = r * tileSize - halfTileSize
						wallRect.y = n * halfTileSize - halfTileSize
					end
				else
					--print("creating rect for tile id: "..self.id.. " with image "..image)
					self.rect = display.newImageRect( map.group, self.imageTexture.filename, self.imageTexture.baseDir, tileSize, tileSize )
				end
				self.rect.x, self.rect.y = self.world.x, self.world.y
				util.zeroAnchors(self.rect)
				if (cam.mode ~= cam.modes.debug) then
					self:updateRectPos()
				end
			end
			--tiles by default do not have a rect, createRect is called when tile needs to be shown, ie between camera bounds on camera move
			--tile:createRect()
			return tile
		end

		local x, y = 1, 1
		for i = 1, #tileData do --for each tile in the tileData taken from the map file
			--print(x, y)
			local data = tileData[i]
			local tile = createTile(x, y, i, data.s, data.c)
			if y == 1 then self.tileStore.tileCols[x] = {} end --create the tileCols 
			if x == 1 then self.tileStore.tileRows[y] = {} end --create the tileRows 
			self.tileStore.tileCols[x][y] = tile --store the tile in the correct position in tileCols
			self.tileStore.tileRows[y][x] = tile
			self.tileStore.indexedTiles[i] = tile --also store the tile in an indexed table

			if x >= width then --reached the end of tile creation for the row
				x, y = 1, y + 1 --increase the counter for the y axis and reset the x
			else
				x = x + 1 --increase the counter for the x axis
			end
		end

		for i = 1, #self.tileStore.indexedTiles do --set subtypes, must be after all tiles created to get neighbour tiles
			local tile = self.tileStore.indexedTiles[i]
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
		
		self:createMapTiles(saveData.tiles) --call function to create tiles
		self.tileData = saveData.tiles --store tileData to redraw map without reloading
		print("-----load map complete-----")
		return true
	end
	
	function map:refreshCamTiles(bounds, tileSize) --gets and updates all tiles within cam bounds, default bounds/spacing are cam bounds/tilesize unscaled

		local cb = bounds or cam.bounds
		local s = tileSize or self.tileSize * 2	--buffer size
		cam.screenTiles, cam.boundaryTiles = self:getTilesBetweenWorldBounds( cb.x1-s, cb.y1-s, cb.x2+s, cb.y2+s ) --get cam tiles within cam borders

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

	function map:onFrame() --called from game or level editor on frame ????
	
	end

	return map
