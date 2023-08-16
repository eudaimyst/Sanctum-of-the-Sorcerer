	-----------------------------------------------------------------------------------------
	--
	-- map/generator.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local json = require("json") --for prettify
	local util = require("lib.global.utilities")

	--mapgen functions module
	local genFuncs = require("lib.map.gen_functions")

	for k, v in pairs(genFuncs) do
		print("mapgen functions: ", k, v)
	end

	-- Define module
	local mapgen = { params = {} }

	local defaultTileset = { --this is the default tileset data FOR THE MAP GENERATOR ONLY
		[1] = {name = "void", colour = {0, 0, 0}, savestring = "v", collision = 1 },
		[2] = {name = "wall", colour = {.6, 0, 0}, savestring = "x", collision = 1 },
		[3] = {name = "floor", colour = {.2, .6, .2}, savestring = "f", collision = 0 },
		[4] = {name = "water", colour = {.2, .2, .6}, savestring = "w", collision = 0 },
		[5] = {name = "blocker", colour = {.4, .4, .4}, savestring = "b", collision = 1 }
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
	mapgen.rooms = {} --stores room data for gen funcs that use them
	mapgen.edgeRooms = { up = {}, down = {}, left = {}, right = {} }
	local sides = { "up", "down", "left", "right" }
	local oppEdges = { up = "down", down = "up", left = "right", right = "left" }
	local roomStartEndPoints = { up = {axis = "y", side = "min", midAxis = "x"}, down = {axis = "y", side = "max", midAxis = "x"},
								 left = {axis = "x", side = "min", midAxis = "y"}, right = {axis = "x", side = "max", midAxis = "y"} }
	mapgen.index = 1 --used for iterating map generator to draw variable number of tiles per frame 
	mapgen.run = false
	mapgen.paused = false

	function mapgen:createRoom(id, x1, y1, x2, y2, edge)
		local room = {}
		room.worldBounds = { min = { x = x1, y = y1 }, max = { x = x2, y = y2 } }
		room.midPoint = { x = (x1 + x2) / 2, y = (y1 + y2) / 2 }
		room.id = id
		if (edge) then
			self.edgeRooms[edge][#self.edgeRooms[edge] + 1] = room --store the rooms which are on the map edges
		end
		for i = 1, #self.rooms do
			if (self.rooms[i].id == id) then --as we pass the same id for edge rooms, if it already exists we dont want to duplicate it
				return
			end
		end
		self.rooms[#self.rooms+1] = room
	end

	--[[ params = width, height, tiles, saveTileSize, rooms, startRoom, endRoom, treasureRoom, startPoint, endPoint, level ]]
	function mapgen:getSaveParams()
		local saveParams = {width = self.params.width, height = self.params.height,
		tiles = self.tileStore.indexedTiles, saveTileSize = self.params.tileSize,
		rooms = self.rooms, startRoom = self.startRoom.id, endRoom = self.endRoom.id, treasureRoom = self.treasureRoom.id,
		startPoint = self.startPoint, endPoint = self.endPoint, level = self.params.level}
		return saveParams
	end

	--Creates a start and end point for the map, returns them and the rooms

	function mapgen:setStartEnd()
		local rand = math.random
		local i = rand(#sides)
		local side = sides[i] --pick a side
		local oppSide = oppEdges[side] --get the opposite side
		local sideRooms = self.edgeRooms[side] --get the rooms in the chosen side
		local oppSideRooms = self.edgeRooms[oppSide]
		local startRoom = sideRooms[math.ceil(#sideRooms/2)] --get the middle room from the chosen side
		local endRoomSide = rand(0, 1) --multiplier to determine which corner end room to pick
		local endRoom = oppSideRooms[ ( ( (#oppSideRooms-1) * endRoomSide ) + 1) ] --pick a room from the chosen side
		local treasureRoom = oppSideRooms[ ( ( (#oppSideRooms-1) * (1 - endRoomSide) ) + 1) ] --pick a room from the opposite side
		local function getStartEndPoint(room, pointData)
			local point = {}
			point[pointData.axis] = room.worldBounds[pointData.side][pointData.axis]
			point[pointData.midAxis] = room.worldBounds.max[pointData.midAxis] - (room.worldBounds.max[pointData.midAxis] - room.worldBounds.min[pointData.midAxis]) / 2
			return point
		end
		local startPoint = getStartEndPoint(startRoom, roomStartEndPoints[side])
		local endPoint = getStartEndPoint(endRoom, roomStartEndPoints[oppSide])
		local startRect = display.newRect( self.group, startPoint.x, startPoint.y, 10, 10 )
		startRect:setFillColor( 1, 0, 1 )
		local endRect = display.newRect( self.group, endPoint.x, endPoint.y, 10, 10 )
		endRect:setFillColor( 0, 1, 1 )
		local treasureRect = display.newRect( self.group, treasureRoom.midPoint.x, treasureRoom.midPoint.y, 20, 20 )
		treasureRect:setFillColor( 1, 1, 0 )
		return startPoint, endPoint, startRoom, endRoom, treasureRoom
	end

	function mapgen:setRoomDifficulty(room)
		local small, big = {x = 0, y = 0}, {x = 0, y = 0}
		local midPoint, startRoomMid = room.midPoint, self.startPoint
		if (midPoint.x < startRoomMid.x)
		then small.x = midPoint.x; big.x = startRoomMid.x
		else small.x = startRoomMid.x; big.x = midPoint.x end
		if (midPoint.y < startRoomMid.y)
		then small.y = midPoint.y; big.y = startRoomMid.y
		else small.y = startRoomMid.y; big.y = midPoint.y end
		room.difficulty = 1 - (small.x / big.x + small.y / big.y) / 2
	end

	function mapgen:generateEnemies()
		--[[
		print("------mapgen params at enemy generation-----------")
		print(json.prettify(self))
		]]
		mapgen.startPoint, mapgen.endPoint, mapgen.startRoom, mapgen.endRoom, mapgen.treasureRoom = self:setStartEnd()

		local enemies = {}
		local tileSize = self.params.tileSize
		local enemySize = tileSize / 5
		for i = 1, #self.rooms do
			local room = self.rooms[i]
			self:setRoomDifficulty(room)
			local bounds = room.worldBounds
			
			room.area = (bounds.max.x - bounds.min.x) * (bounds.max.y - bounds.min.y)
			for j = 1, math.floor(room.area/1000 * room.difficulty * 2) do
				local randPoint = {	x = math.random(bounds.min.x, bounds.max.x),
									y = math.random(bounds.min.y, bounds.max.y) }
				local enemy = display.newRect( self.group, randPoint.x, randPoint.y, enemySize, enemySize )
				enemy:setFillColor( 1, 0, 0 )
				enemies[#enemies+1] = enemy
			end
		end
		--return enemies
		mapgen.enemies = enemies
	end

	function mapgen:init(sceneGroup) --sets generator params to passed params or defaults for each default param defined
		for param, value in pairs(self.defaultParams) do
			self.params[param] = value
		end
		self.group = display.newGroup()
		sceneGroup:insert( self.group )
		for i = 1, #mapgen.levels do
			mapgen.levels[i].method:init()
		end
		print("------------------------------------mapgen params---")
		print(json.prettify(self.params))
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
			self.group.x = display.contentWidth / 2 - (self.params.width + 1) * self.params.tileSize / 2
			self.group.y = display.contentHeight / 2 - (self.params.height + 1) * self.params.tileSize / 2
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

	function mapgen:runGenFunc(completeListener)
		print("level print")
		--print(json.prettify( self.params.level ))
		self.params.level.method:startGen(nil, self, completeListener)
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