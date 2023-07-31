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

	map.group = display.newGroup()

	map.tileStore = { tileRows = {}, tileCols = {}, indexedTiles = {}} --set by loadMap
	map.startTileID = 0 --tile for character to start on, accessed by game loadMap

	-- include json for save/loading map
	map.params = { width = 10, height = 10, tileStore = {}, tileSize = 128, tileset = defaultTileset }
	map.worldWidth, map.worldHeight = map.params.width * map.params.tileSize, map.params.height * map.params.tileSize
	map.centerX, map.centerY = map.worldWidth/2, map.worldHeight/2

	map.imageLocation = "content/map/"

	local function worldPointToTileCoords(_x, _y) --takes x y in world coords and returns tile coords
		local x, y = math.round(_x / map.params.tileSize), math.round(_y / map.params.tileSize)
		print("worldPointToTileCoords: ".._x.." = "..x..", ".._y.." = "..y)
		return x, y
	end

	function map:getTilesBetweenWorldBounds(x1, y1, x2, y2) --takes bounds in world position and returns table of tiles
		local boundMin, boundMax = {x = 0, y = 0}, {x = 0, y = 0}
		boundMin.x, boundMin.y = worldPointToTileCoords(x1, y1)
		boundMax.x, boundMax.y = worldPointToTileCoords(x2, y2)
		local boundWidth, boundHeight = boundMax.x - boundMin.x, boundMax.y - boundMin.y
		local tileList = {}
		for y = boundMin.y, boundMin.y + boundHeight do
			for x = boundMin.x, boundMin.x + boundWidth do
				local tile = map.tileStore.tileCols[x][y]
				tileList[#tileList+1] = tile
			end
		end
		return tileList
	end

	function map:createMapTiles(tileData) --called by editor/map, creates all tile objects for maps

		local width, height, tileSize, tileset, fileName = self.params.width, self.params.height, self.params.tileSize, self.params.tileset, "level"

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
					self.rect.x, self.rect.y = self.rect.x + x, self.rect.y + y
				end
			end

			function tile:destroyRect()
			end

			function tile:createRect()
				--print("creating rect for tile id: "..self.id.. " with image "..image)
				self.rect = display.newImageRect( map.group, self.imageFile, tileSize, tileSize )
				self.rect.x, self.rect.y = self.world.x - map.centerX, self.world.y - map.centerY --subtract map centers to center tile rects
				util.zeroAnchors(self.rect)
				--self.rect.isVisible = false
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
		local width, height, level, tileData = fileio.load("level")
		self.params.width, self.params.height = width, height
		self.worldWidth, self.worldHeight = self.params.width * self.params.tileSize, self.params.height * self.params.tileSize
		self.centerX, self.centerY = self.worldWidth/2, self.worldHeight/2
		self:createMapTiles(tileData)
		print("-----load map complete-----")
	end

	function map:init()

	end

	function map:onFrame() --called from game or level editor on frame ????
	
	end

	return map
