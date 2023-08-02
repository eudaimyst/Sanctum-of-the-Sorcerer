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

	map.imageLocation = "content/map/"

	local function worldPointToTileCoords(_x, _y) --takes x y in world coords and returns tile coords
		--print("map width/height: "..map.worldWidth..", "..map.worldHeight)
		local x, y = math.floor(_x / map.tileSize), math.floor( _y / map.tileSize)
		print("worldPointToTileCoords: ".._x.." = "..x..", ".._y.." = "..y)
		return x, y
	end

	function map:clear()
		local ts = self.tileStore --readability
		for i = 1, #ts.indexedTiles do
			print("clearing tile: "..i)
			local tile = ts.indexedTiles[i]
			ts.tileRows[tile.y][tile.x] = nil
			ts.tileCols[tile.x][tile.y] = nil
			if (tile.rect) then
				tile.rect:removeSelf()
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

	function map:getTilesBetweenWorldBounds(x1, y1, x2, y2) --takes bounds in world position and returns table of tiles
		local boundMin, boundMax = {x = 0, y = 0}, {x = 0, y = 0}
		boundMin.x, boundMin.y = worldPointToTileCoords(x1-1, y1-1)
		boundMax.x, boundMax.y = worldPointToTileCoords(x2+1, y2+1)
		--local boundWidth, boundHeight = boundMax.x - boundMin.x, boundMax.y - boundMin.y
		local tileList = {}
		local boundaryTiles = { up = {}, down = {}, left = {}, right = {} } --tiles on the edge of the bounds
		for y = boundMin.y, boundMax.y do
			for x = boundMin.x, boundMax.x do
				
				local tx, ty = math.max(1, x), math.max(1, y) --clamp to 1 to prevent looking for tiles outside of map
				tx, ty = math.min(tx, self.width), math.min(ty, self.height) --clamp to map width/height
				--print("getting tile: "..tx..", "..ty.." from tileStore")
				local tile = self.tileStore.tileCols[tx][ty]
				
				--add tiles to table in direction if they are on the bounds
				if y == boundMin.y then
					boundaryTiles.up[#boundaryTiles.up+1] = tile
				elseif y == boundMax.y then
					boundaryTiles.down[#boundaryTiles.down+1] = tile
				elseif x == boundMin.x then
					boundaryTiles.left[#boundaryTiles.left+1] = tile
				elseif x == boundMax.x then
					boundaryTiles.right[#boundaryTiles.right+1] = tile
				else
					tileList[#tileList+1] = tile --only add tiles to list if they are not on edges of bounds
				end

			end
		end
		return tileList, boundaryTiles
	end

	function map:createMapTiles(_tileData, _tileSize, camDebug) --called by editor/map, creates all tile objects for maps, tileData = optional map data, tileSize = optional force tile size in pixels
		print("create map tiles called")
		
		local tileData = _tileData or self.tileData
		local tileSize = _tileSize or self.params.tileSize
		print("tileData length: "..#tileData)

		local width, height, tileset = self.params.width, self.params.height, self.params.tileset --set local vars for readability
		local halfTileSize = tileSize/2

		self.width, self.height = width, height
		self.tileSize = tileSize
		self.worldWidth, self.worldHeight = self.params.width * tileSize, self.params.height * tileSize
		self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2

		local function createTile(x, y, i) --new tile constructor
			local tile = {}
			tile.id, tile.x, tile.y = i, x, y --tile.x = tile column, tile.y = tile row
			--tile screen pos is exclusively accessed through its rect
			tile.world = { x = x * tileSize, y = y * tileSize }
			local image

			for k, v in pairs(defaultTileset) do
				if tileData[i].s == v.savestring then
					image = v.image
					--print("setting type for tile id: "..i.." to "..k)
					tile.type = k --sets the tile type string to the key name of the matching tileset entry
				end
			end

			tile.imageFile = self.imageLocation.."defaultTileset/"..image
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
				self.wallImage = {}
				for subID = 0, 3, 1 do
					subTypes[subID] = st.error --set default to error

					local searchCol = self.x+search[subID].x --columns of the tiles to search
					local searchRow = self.y+search[subID].y --rows
					print("checking wall type at col, row: "..searchCol..", "..searchRow )
					local Xtype = map.tileStore.tileCols[searchCol][self.y].type --get tile type to left/right
					local Ytype = map.tileStore.tileCols[self.x][searchRow].type --get tile type above/below
					--z=void i=innercorner o=outercorner h=horizontal v=vertical (short forms for saving)

					if (Xtype == "wall" and Ytype == "wall") then --if there is a wall on the diagonal tile to prevent inner corners repeating
						local innerWallType = map.tileStore.tileCols[searchCol][searchRow].type --store tiles type
						if (innerWallType == "wall" or innerWallType == "void") then
							subTypes[subID] = st.void --need to set "void" if theres a wall or "void" on other side of corner
						else
							subTypes[subID] = st.innerCorner --otherwise normal corner
						end
						elseif (Ytype == "void") then subTypes[subID] = st.void
						elseif (Ytype == "room") then subTypes[subID] = st.horizontal
					end
					if (Xtype == "void") then
						if (Ytype == "void") then subTypes[subID] = st.void
						elseif (Ytype == "wall") then subTypes[subID] = st.void
						elseif (Ytype == "room") then subTypes[subID] = st.horizontal
						end
					end
					if (Xtype == "room") then
						if (Ytype == "wall") then subTypes[subID] = st.void
						elseif (Ytype == "room") then subTypes[subID] =	st.outerCorner
						elseif (Ytype == "void") then subTypes[subID] = st.void
						end
					end
					--[[
					for k, v in pairs(self) do
						print("tile: "..k.." = "..tostring(v))
					end]]
					local wallImageString = map.imageLocation.."defaultTileset/dungeon_walls/"..subTypes[subID]..subID..".png"
					print(wallImageString)
					self.wallImage[subID] = wallImageString
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
				if (tile.type == "wall") then --if tile is a wall then we need to make a group for the subtiles
					self.rect = display.newGroup()
					for i = 0, 3, 1 do --four corners
						print(self.wallImage[i])
						local wallRect = display.newImageRect( self.rect, self.wallImage[i], halfTileSize, halfTileSize ) --create rect for each wall
						wallRect = util.zeroAnchors(wallRect)

						local n, r = math.modf( i / 2 ) --set wall rect position using math
						wallRect.x = r * tileSize - halfTileSize
						wallRect.y = n * halfTileSize - halfTileSize

					end
				else
					--print("creating rect for tile id: "..self.id.. " with image "..image)
					print(self.imageFile)
					self.rect = display.newImageRect( map.group, self.imageFile, tileSize, tileSize )
				end
				self.rect.x, self.rect.y = self.world.x, self.world.y --subtract map centers to center tile rects
				util.zeroAnchors(self.rect)
				self:updateRectPos()
			end

			--tile:createRect()
			return tile
		end

		local x, y = 1, 1
		for i = 1, #tileData do --for each tile in the tileData taken from the map file
			--print(x, y)
			local tile = createTile(x, y, i)
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
	end

	function map:updateTilesPos()
		for i = 1, #self.tileStore.indexedTiles do --translates all tiles in the maps tileStore	
			local tile = self.tileStore.indexedTiles[i]
			tile:updateRectPos()
			--tile:translate(-cam.bounds.x1, -cam.bounds.y1) --move tiles the opposite direction camera is moving 
		end
	end

	function map:loadMap()
		print("loading map in map.lua")
		local width, height, level, tileData = fileio.load("level")
		self.params.width, self.params.height = width, height --width and height in tiles
		--self.worldWidth, self.worldHeight = self.params.width * self.params.tileSize, self.params.height * self.params.tileSize --width and height in pixels
		--self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2 --stores center of map in world coords to move camera to this pos
		self:createMapTiles(tileData) --call function to create tiles
		self.tileData = tileData --store tileData to redraw map without reloading
		print("-----load map complete-----")
	end

	function map:init(sceneGroup, _cam)
		sceneGroup:insert(self.group)
		cam = _cam
	end

	function map:onFrame() --called from game or level editor on frame ????
	
	end

	return map
