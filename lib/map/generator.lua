	-----------------------------------------------------------------------------------------
	--
	-- map/generator.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local json = require("json") --for prettify

	--mapgen functions module
	local genFuncs = require("lib.map.gen_functions")

	for k, v in pairs(genFuncs) do
		print("mapgen functions: ", k, v)
	end

	-- Local variables
	local mapgenIndex = 1 --used for iterating map generator

	-- Define module
	local mapgen = { params = {} }

	local defaultTileset = {
		[1] = {name = "void", colour = {0, 0, 0}, savestring = "v", collision = "false"},
		[2] = {name = "wall", colour = {.6, 0, 0}, savestring = "x", collision = "false"},
		[3] = {name = "floor", colour = {.2, .6, .2}, savestring = "f", collision = "true"},
		[4] = {name = "water", colour = {.2, .2, .6}, savestring = "w", collision = "true"},
		[5] = {name = "blocker", colour = {.4, .4, .4}, savestring = "b", collision = "false"}
	}

	mapgen.levels = {
		{ name = "Castle", method = genFuncs.pointsExpand, tileset = defaultTileset }, --value is what the param is set to when dropdown is selected
		{ name = "Dungeon", method = genFuncs.rogue, tileset = defaultTileset },
		{ name = "Sewers", method = genFuncs.rogue, tileset = defaultTileset },
		{ name = "Goblin town", method = genFuncs.wfc, tileset = defaultTileset },
		{ name = "Caverns", method = genFuncs.noise, tileset = defaultTileset },
		{ name = "Lava", method = genFuncs.noise, tileset = defaultTileset },
		{ name = "Cultist hideout", method = genFuncs.wfc, tileset = defaultTileset },
		{ name = "Lair", method = genFuncs.mixed, tileset = defaultTileset } }
	for i = 1, #mapgen.levels do
		mapgen.levels[i].tileset = defaultTileset --until we make more tilesets for the level
	end

	for k, v in pairs(mapgen.levels) do
		print("mapgen.levels kvs: ", k, v)
	end

	mapgen.defaultParams = { width = 100, height = 100, tileSize = 10, level = mapgen.levels[1], tilesPerFrame = 500} --default paramaters for map generator if run without being passed

	mapgen.defaultParams.level.method:init()
	for k, v in pairs(mapgen.defaultParams.level.method.params) do
		mapgen.defaultParams[k] = v
	end

	mapgen.tileStore = { tileColumns = {}, tileRows = {}, indexedTiles = {} }
	mapgen.index = 1 --used for iterating map generator to draw variable number of tiles per frame 
	mapgen.run = false
	mapgen.paused = false

	function mapgen:init(sceneGroup) --sets generator params to passed params or defaults for each default param defined
		for param, value in pairs(self.defaultParams) do
			self.params[param] = value
		end
		self.group = display.newGroup()
		sceneGroup:insert( self.group )
		for i = 1, #mapgen.levels do
			print(json.prettify(mapgen.levels[i]))
			mapgen.levels[i].method:init()
		end
	end

	function mapgen:updateParam(param, value)
		self.params[param] = value
		for k, v in pairs(self.params.level.method.params) do
			if (param == k) then
				self.params.level.method.params[k] = value
			end
		end
	end

	function mapgen:onFrame()
		for i = 1, self.params.tilesPerFrame do --only run until #of tiles generated (for performance)
			if (self.run) then --gen set to run
				if self.yPos <= self.params.height then --for each row inclusive otherwise it's one short
					if self.xPos <= self.params.width then --for each tile in the row
						if (self.yPos == 1) then
							self.tileStore.tileColumns[self.xPos] = { } --initiate the store for this column
						end
						if (self.xPos == 1) then
							self.tileStore.tileRows[self.yPos] = { } --initiate the store for this row
						end
						self:makeTile(self.xPos, self.yPos)
						self.index = self.index + 1
						self.xPos = self.xPos + 1
					else
						self.yPos = self.yPos + 1
						self.xPos = 1
					end
				else
					--mapgen complete
					self.run = false
					self.completeListener() --calls function in scene
				end
			end
		end
	end

	function mapgen:startTileGen(completeListener) --called by scene when button is pressed
		local tileCount = #self.tileStore.indexedTiles
		if ( tileCount == 0 or self.paused) then
			local p = self.params
			self.group.x = display.contentWidth / 2 - (p.width + 1) * p.tileSize / 2
			self.group.y = display.contentHeight / 2 - (p.height + 1) * p.tileSize / 2
			self.completeListener = completeListener
			if (self.paused) then --if mapgen has been previously paused we do not reset the index but continue genration
				self.paused = false
			end
			if (tileCount == 0) then
				self.index = 1
				self.xPos = 1
				self.yPos = 1
			end
			self.run = true
		end
	end
	function mapgen:pauseTileGen()
		self.paused = true
		self.run = false
	end
	function mapgen:deleteMap()
		if (not self.run) then --cant clear tiles while tileGen running
			local ts = self.tileStore
			for i = 1, #ts.indexedTiles do
				local tile = ts.indexedTiles[i]
				ts.tileRows[tile.y][tile.x] = nil
				ts.tileColumns[tile.x][tile.y] = nil
				ts.indexedTiles[i].rect:removeSelf()
				ts.indexedTiles[i] = nil
			end
			for i = 1, #ts.tileRows do
				ts.tileRows[i] = nil
			end
			for i = 1, #ts.tileColumns do
				ts.tileColumns[i] = nil
			end
		end
	end

	function mapgen:runGenFunc()
		print("level print")
		--print(json.prettify( self.params.level ))
		self.params.level.method:startGen(nil, self.tileStore, self.params.level.tileset)
	end

	function mapgen:makeTile(x, y)
		local tile = {x = x, y = y, id = mapgen.index, size = self.tileSize, typeName = "void"}
		local size, width, height, index = self.params.tileSize, self.params.width, self.params.height, self.index
		tile.rect = display.newRect( self.group, x * size, y * size, size, size )
		tile.rect:setFillColor( x / width, y / height, index / (width * height) )

		self.tileStore.indexedTiles[self.index] = tile

		self.tileStore.tileRows[y][x] = tile --rows/columns stores an array of each
		self.tileStore.tileColumns[x][y] = tile --then places tile within that array at its pos
	end


	return mapgen