	-----------------------------------------------------------------------------------------
	--
	-- map.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local util = require("lib.global.utilities")
	local fileio = require( "lib.map.fileio")

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
				--print("getting tile: "..tx..", "..ty.." from tileStore")
				local tile = self.tileStore.tileCols[tx][ty]
				tileList[#tileList+1] = tile
				
				if y == boundMin.y then
					boundaryTiles.up[#boundaryTiles.up+1] = tile
				elseif y == boundMax.y then
					boundaryTiles.down[#boundaryTiles.down+1] = tile
				elseif x == boundMin.x then
					boundaryTiles.left[#boundaryTiles.left+1] = tile
				elseif x == boundMax.x then
					boundaryTiles.right[#boundaryTiles.right+1] = tile
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
			for j = 1, #defaultTileset do
				if tileData[i].s == defaultTileset[j].savestring then
					--print("found")
					image = defaultTileset[j].image
				end
			end
			tile.imageFile = self.imageLocation.."defaultTileset/"..image

			function tile:translate(x, y) --translate tile and rect
				if (self.rect) then
					self.rect.x, self.rect.y = self.world.x - cam.bounds.x1 , self.world.y - cam.bounds.y1
				end
			end

			function tile:destroyRect()
			end

			function tile:createRect()
				--print("creating rect for tile id: "..self.id.. " with image "..image)
				self.rect = display.newImageRect( map.group, self.imageFile, tileSize, tileSize )
				self.rect.x, self.rect.y = self.world.x, self.world.y --subtract map centers to center tile rects
				util.zeroAnchors(self.rect)
			end
			tile:createRect()
			return tile
		end

		local x, y = 1, 1
		for i = 1, #tileData do
			--print(x, y)
			local tile = createTile(x, y, i)
			if y == 1 then self.tileStore.tileCols[x] = {} end
			if x == 1 then self.tileStore.tileRows[y] = {} end
			self.tileStore.tileCols[x][y] = tile
			self.tileStore.tileRows[y][x] = tile
			self.tileStore.indexedTiles[i] = tile
			if x >= width then
				x, y = 1, y + 1
			else
				x = x + 1
			end
		end
	end

	function map:updateTilesPos()
		for i = 1, #self.tileStore.indexedTiles do --translates all tiles in the maps tileStore	
			local tile = self.tileStore.indexedTiles[i]
			tile:translate(-cam.bounds.x1, -cam.bounds.y1) --move tiles the opposite direction camera is moving 
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
