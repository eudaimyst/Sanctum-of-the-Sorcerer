	-----------------------------------------------------------------------------------------
	--
	-- points_expand.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local json = require("json")

	-- Define module
	local pointsExpand = {}

	local sectionsPosX, sectionsPosY = {}, {} --x and y positions of where section lines are drawn

	local mapgen, genfuncs, setColor, setType, sortBounds

	local defaultParams = {
		numRoomsX = 6, numRoomsY = 6, --how many sections/rooms in the x and y axis
		edgeInset = 10, --inset from map edge
		roomSpacingMin = 1.1, roomSpacingMax = 1.1, --space between rooms
		spawnChance = 60, --chance of a room being in each section
		randPosOffset = 2, --max random offset from middle of section for room expansion start point
		doorWidthMin = 3, doorWidthMax = 6, --width of hallways
		doorEdgeInset = 3, --distance from room corners for doors
		maxHallwayLength = 5 --if 2 rooms are further than this the hallway is not drawn
	}

	local params = {} --local params instead of self.params
	local phase = 1 --phases of the map generation
	
	local completeListener = nil
	local roomStore = {} --created by the generator
	local tileset = {}
	local tileStore = {}
	local width, height = 0, 0
	local tCols, tRows = {}, {}

	local phaseFunctions = {} --set on startGen

	local gotoNextPhase --used to iterate through phases


	local function onFrame() --called each frame from mapgen

		gotoNextPhase = true --true to do one phase per frame, unless phase sets false (like room expand)

		if (phase <= #phaseFunctions) then
			print("running phase: "..phase)
			print("phase functions "..#phaseFunctions)
			phaseFunctions[phase](pointsExpand) --passes self to phase function of current phase
		else
			if (completeListener) then
				completeListener()
			end
			Runtime:removeEventListener( "enterFrame", onFrame )
		end
		if (gotoNextPhase) then
			phase = phase + 1 --iterate frame counters
		end
	end
	
	function pointsExpand:init(_mapgen, _genfuncs)
		print("init points expand")
		print(json.prettify(_genfuncs))
		mapgen = _mapgen
		genfuncs = _genfuncs
		setColor, setType, sortBounds = genfuncs.setColor, genfuncs.setType, util.sortBounds
	
		self.textGroup = display.newGroup()
	
	end
	
	function pointsExpand:startGen(_params, _completeListener)
		completeListener = _completeListener
		roomStore = {} --created by the generator
		tileset = mapgen.params.level.tileset
		tileStore = mapgen.tileStore
		tCols, tRows = tileStore.tileColumns, tileStore.tileRows
		width, height = #tCols, #tRows
		if (_params) then
			for k, v in pairs(defaultParams) do
				if _params[k] then
					params[k] = _params[k]
				else
					params[k] = v
				end
			end
		else
			params = defaultParams
		end
		
		phaseFunctions = {
			pointsExpand.setInsets, pointsExpand.setSections, pointsExpand.setRoomsStartPoint,
			pointsExpand.expandRooms, pointsExpand.setRoomNeighbours, pointsExpand.makeRoomWalls, pointsExpand.makeDoors,
			pointsExpand.setFinalMapColours, pointsExpand.setMapgenRooms
		}

		print("starting generation function points expand")
		print("tilecount = "..#tileStore.indexedTiles)
		Runtime:addEventListener( "enterFrame", onFrame ) --add event listenter to iterate through phases
	end
	
	function pointsExpand:setInsets()
		for i = 1, params.edgeInset do
			local columnL = tCols[i] --left and right columns
			local columnR = tCols[#tCols-(i-1)]
			local rowT = tRows[i] --top and bottom rows
			local rowB = tRows[#tRows-(i-1)]
			setColor(columnL); setColor(columnR); setColor(rowT); setColor(rowB)
		end
	end

	function pointsExpand:setSections()
		local trueW, trueH = #tCols - params.edgeInset*2, #tRows - params.edgeInset*2 --subtract the insets
		local rem
		for i = 0, params.numRoomsX do --start at 0 to draw line at start of first section
			sectionsPosX[i+1] = params.edgeInset + math.round((trueW / params.numRoomsX) * i)
		end
		for i = 0, params.numRoomsY do
			sectionsPosY[i+1] = params.edgeInset + math.round((trueH / params.numRoomsY) * i)
		end
		--visualise the cuts
		for i = 1, #sectionsPosX do
			setColor(tCols[sectionsPosX[i]], "lines")
		end
		for i = 1, #sectionsPosY do
			setColor(tRows[sectionsPosY[i]], "lines")
		end
	end

	function pointsExpand:setRoomsStartPoint()
		for i = 1, params.numRoomsX do
			for j = 1, params.numRoomsY do
				local chance = math.random(0, 100) --chance room will not spawn in this square
				if (chance < params.spawnChance) then
					local sectionHalfWidth = math.floor((sectionsPosX[i + 1] - sectionsPosX[i]) / 2)
					local sectionHalfHeight = math.floor((sectionsPosY[j + 1] - sectionsPosY[j]) / 2)
					local xRand = math.random(-params.randPosOffset, params.randPosOffset)
					local yRand = math.random(-params.randPosOffset, params.randPosOffset)
					local startPoint = { x = sectionsPosX[i] + sectionHalfWidth + xRand, y = sectionsPosY[j] + sectionHalfHeight + yRand }
					print("room start point = x,y: "..startPoint.x,startPoint.y)
					local tile = tCols [startPoint.x] [startPoint.y]
					tile.rect:setFillColor(1)
					self:createroom(startPoint) --create a room with the start point
				end
			end
		end
	end

	function pointsExpand:expandRooms()
		gotoNextPhase = true --sets default to do the next frame if all rooms are complete, otherwise will stay at false
		for i = 1, #roomStore do
			if (roomStore[i].expandComplete == false) then
				gotoNextPhase = false
				roomStore[i]:expand() --expand all rooms prior to comparison for accuracy
			end
		end
		for i = 1, #roomStore do
			if (roomStore[i].expandComplete == false) then
				roomStore[i]:compare()
			end
			roomStore[i]:draw() --unhide this to visualise the expansion of the rooms, costly redraws all rooms each frame
		end
	end

	function pointsExpand:setRoomNeighbours()
		for i = 1, #roomStore do
			roomStore[i]:draw() --draw one final time
		end
		for i = 1, #roomStore do
			roomStore[i]:setNeighbours() --set the neighbours of each room
		end
	end
	
	function pointsExpand:makeRoomWalls()
		--make room walls
		for i = 1, #roomStore do
			roomStore[i]:makeExteriorWalls()
		end
	end

	function pointsExpand:makeDoors()
		--get all the available space where doors can go
		--run on all rooms before actually making the doors so tables are set
		for i = 1, #roomStore do
			roomStore[i]:setPotentialDoorTiles()
		end
		for i = 1, #roomStore do
			roomStore[i]:getDoorSpace()
		end
		--make room doors
		for i = 1, #roomStore do
			roomStore[i]:makeDoors()
		end
	end
	
	function pointsExpand:setFinalMapColours()
		print("setting final map colours")
		for i = 1, #tileStore.indexedTiles do
			local tile = tileStore.indexedTiles[i]
			for j = 1, #tileset do
				local c = tileset[j].colour
				--print("comparing tile id "..tile.id.." that has typeName *>"..tile.typeName.."<* with *>"..tileset[j].name.."<*")
				if (tile.typeName == tileset[j].name) then
					--print("matches")
					--print (c[1], c[2], c[3])
					tile.rect:setFillColor( c[1], c[2], c[3] )
				end
			end
		end
	end

	function pointsExpand:setMapgenRooms()
		local directions = { "up", "down", "left", "right" }
		for i = 1, #roomStore do
			local room = roomStore[i]
			local tileSize = mapgen.params.tileSize
			local x1, y1 = room.bounds.x1 * tileSize + tileSize, room.bounds.y1 * tileSize + tileSize
			local x2, y2 = room.bounds.x2 * tileSize - tileSize, room.bounds.y2 * tileSize - tileSize
			local edges = {}
			for j = 1, #directions do
				local dir = directions[j]
				if (room.neighbours[dir][1] == "map") then
					edges[#edges + 1] = dir
				end
			end
			if #edges > 0 then
				for j = 1, #edges do
					mapgen:createRoom(room.id, x1 , y1, x2, y2, edges[j]) --passes relevant room data to mapgen
				end
			else
				mapgen:createRoom(room.id, x1, y1, x2, y2)
			end
		end
	end
	
	function pointsExpand:createroom(startPoint) --startpoint is a table that has x and y positions
	
		local room = {}
		print("!!!!!!!!!!!!!!!!!!!!!!!creating room!!!!!!!!!!!!!!!!!!!!!!!")
		room.expandComplete = false
		room.bounds = {x1 = startPoint.x, x2 = startPoint.x, y1 = startPoint.y, y2 = startPoint.y} --set initial bounds
		room.id = #roomStore + 1
		room.spacing = math.random(params.roomSpacingMin, params.roomSpacingMax)
		room.expansionData = {	up = {bound = "y1", boundExpand = -1, boundContract = 1, opposite = "down" },
								down = {bound = "y2", boundExpand = 1, boundContract = -1, opposite = "up" },
								left = {bound = "x1", boundExpand = -1, boundContract = 1, opposite = "right" },
								right = {bound = "x2", boundExpand = 1, boundContract = -1, opposite = "left" } }
		room.wallData = {	up = {bound1 = "x1", bound2 = "x2"}, down = {bound1 = "x1", bound2 = "x2"},
							left = {bound1 = "y1", bound2 = "y2"}, right = {bound1 = "y1", bound2 = "y2"},}
		room.expandDirComplete = {up = false, down = false, left = false, right = false}
		room.neighbours = {up = {}, down = {}, left = {}, right = {}}
		room.connectedRooms = { up = {}, down = {}, left = {}, right = {} } --stores a reference to room when hallway is created
	
		room.idText = display.newText( self.textGroup, tostring(room.id), 0, 0, native.systemFontBold, params.tileSize )
		room.idText:setFillColor( 1, 1, 0, 0 )
	
		roomStore[room.id] = room
	
		function room:makeExteriorWalls()
			width = self.bounds.x2 - self.bounds.x1
			height = self.bounds.y2 - self.bounds.y1
			self.wallTiles = { up = {}, down = {}, left = {}, right = {} }
	
			for i = 0, width do
				self.wallTiles.up[i+1] = tCols[self.bounds.x1 + i][self.bounds.y1]
				self.wallTiles.down[i+1] = tCols[self.bounds.x1 + i][self.bounds.y2]
			end
			for i = 0, height do
				self.wallTiles.left[i+1] = tCols[self.bounds.x1][self.bounds.y1 + i]
				self.wallTiles.right[i+1] = tCols[self.bounds.x2][self.bounds.y1 + i]
			end
	
			for direction, tiles in pairs(self.wallTiles) do
				--print("setting "..#tiles.." wall tiles for side "..direction.." in room#"..room.id)
				setColor(tiles, "white")
				setType(tiles, "wall")
			end
		end
	
		function room:getMidPoint()
			local midPoint = {x = 0, y = 0}
			midPoint.x = math.floor((self.bounds.x1 + self.bounds.x2)/2)
			midPoint.y = math.floor((self.bounds.y1 + self.bounds.y2)/2)
			return midPoint
		end
	
		function room:setPotentialDoorTiles()
			local edgeInset = params.doorEdgeInset
			local data = self.wallData
			self.potentialDoorTiles = { up = {}, down = {}, left = {}, right = {} } --hold the wall tiles where door can be drawn
			for direction, neighbours in pairs(self.neighbours) do
				local potentials = self.potentialDoorTiles[direction]
				local edgeWall = false --sets to true if neighbour is map
				for _, neighbour in pairs(neighbours) do
					if (neighbour == "map") then --dont draw walls on map edges
						edgeWall = true
					end
				end
				--print("room with id: "..room.id.." has "..#self.wallTiles[direction].." wall tiles on "..direction.." side")
				if (not edgeWall) then
					for i = 1, #self.wallTiles[direction] - edgeInset*2 do
						local tile = self.wallTiles[direction][i + edgeInset]
						if (tile.typeName == "wall") then
							--print("adding tile "..tile.id.." to potential door tiles")
							potentials[i] = tile
						end
					end
				end
				if #potentials > 0 then
					setColor(potentials, "grey")
				end
			end
		end
	
		function room:getDoorSpace() --gets space where doors can be stored
			local eData = self.expansionData
			local data = self.wallData
			self.doorAvailWallTiles = { up = {}, down = {}, left = {}, right = {} } --hold the wall tiles where door can be drawn
			--print("room neighbours::::::::::::::::: "..room.id)
			--[[ for k, v in pairs(self.neighbours) do
				print (k, v, "\n--------------------------")
				for k1, v1 in pairs(v) do
					print (k1, v1)
				end
			end ]]
			--print(json.prettify(self.neighbours))
			for direction, neighbours in pairs(self.neighbours) do
				--("room #"..room.id.." has "..#neighbours.." neighbours on side "..direction)
				for i = 1, #neighbours do
				local neighbour = neighbours[i]
					if (neighbour ~= "map") then --dont draw doors when rooms on map edges
	
						local oppositeDir = eData[direction].opposite
						local potentials = self.potentialDoorTiles[direction]
						local nPotentials = neighbour.potentialDoorTiles[oppositeDir]
						local availTiles = self.doorAvailWallTiles[direction]
						availTiles[i] = {} --creates an empty table to store tiles
						
						local dim --dimension of tile x or y for readability
						if (direction == "up" or direction == "down") then dim = "x" --to get x and y values from tiles
						else dim = "y" end
						--print("room has "..#potentials.." potential door tiles on side "..direction)
						--print("neighbour has "..#nPotentials.." potential door tiles on side "..oppositeDir)
						if (#potentials > 0 and #nPotentials > 0) then --neighbour has potential wall tiles
							local pos = potentials[1][dim] --bounds of wall tiles
							local pos2 = potentials[#potentials][dim]
							local nPos = nPotentials[1][dim] --bounds of neighbour wall tiles
							local nPos2 = nPotentials[#nPotentials][dim]
							local startPos = math.max(pos, nPos) --bounds of avail door space
							local endPos = math.min(pos2, nPos2)
							local len = endPos - startPos + 1 --length of avail space
							--print("overlapping length: "..len)
							if (len >= params.doorWidthMin) then
								for j = 1, len do --for each tile in potential door space
									--print(#potentials.." potentials in room "..room.id)
									--print(i + startPos - pos.."/"..#potentials)
									--print("setting wall tiles for neighbour #"..i..", "..direction..", ".. j + startPos - pos .." as available")
									availTiles[i][j] = potentials[j + startPos - pos] --store the tiles
								end
								if (availTiles) then
									--print(#availTiles[i])
									if #availTiles[i] > 0 then
										setColor(availTiles[i], "black")
									end
								end
							end
						end
					end
				end
			end
		end
	
		function room:makeDoors() --makes doors in wall tiles
	
			local function getConnections(connectedRooms)
				for _, room in pairs(connectedRooms) do
					if room == self then
						return true --returns true if neighbour is connected to room
					end
				end
				return false
			end
	
			local function getMid(p1, p2, random) --takes to points and returns the middle point between them,
				--returns a random point between them if param random is set to true
				local m --midPoint
				local t --temp to swap points
				if p2 < p1 then t = p1; p1 = p2; p2 = t end --swap p1 and p2 if p2 is smaller
				local w = math.floor(p2 -p1) --width of space
				
				m = p2 - w/2
				if (random) then
					m = m + math.random(-w/2, w/2)
				end
				return math.round(m)
			end
	
			local doorWidth = 4 --needs to be set to a param
			local doorTiles = { up = {}, down = {}, left = {}, right = {} } --hold the doorway tiles
			--[[
			print("neighbours")
			for k, v in pairs(self.neighbours) do
				print(k, v)
			end]]
			for direction, neighbours in pairs(self.neighbours) do
				local doorWallTiles = {}
				for i = 1, #neighbours do
					local neighbour = neighbours[i]
					if (neighbour ~= "map") then --dont draw hallways to map edges
						local oppositeDir = self.expansionData[direction].opposite --gets opposite direction
						--print (json.prettify(self.expansionData[direction]))
						--print (json.prettify(neighbour.connectedRooms))
						if (getConnections(neighbour.connectedRooms[oppositeDir])) then
							--print("do not draw hallway as already connected")
						else
							--print(json.prettify(self.connectedRooms))
	
							local nAvailTiles = {}
							local availTiles = self.doorAvailWallTiles[direction][i] --avail tiles in rooms direction
							if neighbour.neighbours[oppositeDir] then
								local neighboursNeighbours = neighbour.neighbours[oppositeDir]
								--print("neighbour id# "..neighbour.id.." has "..#neighboursNeighbours.." neighbours on side "..oppositeDir)
								for j = 1, #neighboursNeighbours do
									if neighboursNeighbours[j] == self then
										nAvailTiles = neighbour.doorAvailWallTiles[oppositeDir][j] --avail tiles in neighbourse opp direction
										--print("neighbour has room as neighbour")
									end
								end
							else
								--print("neighbour has no neighbours on side "..oppositeDir)
							end
	
							local x1, x2, y1, y2
							if (#availTiles > 0 and #nAvailTiles > 0) then
	
								x1, y1 = availTiles[1].x, availTiles[1].y
								x2, y2 = nAvailTiles[#nAvailTiles].x, nAvailTiles[#nAvailTiles].y
								x1, x2, y1, y2 = sortBounds(x1, x2, y1, y2)
								--print("ROOM ID: "..room.id.." DIRECTION: "..direction.." DOORWAYS AT:", x1, y1, x2, y2)
	
								if (direction == "up" or direction == "down") then
									if (x2 > availTiles[#availTiles].x) then --reduces the size of the avail tiles if the target corridor has a bigger wall space
										x2 = availTiles[#availTiles].x
									end
									local midX = getMid(x1, x2, true)
									x1, x2 = midX - math.floor(doorWidth/2), midX + math.floor(doorWidth/2) - 1
								else
									if (y2 > availTiles[#availTiles].y) then --reduces the size of the avail tiles if the target corridor has a bigger wall space
										y2 = availTiles[#availTiles].y
									end
									local midY = getMid(y1, y2, true)
									y1, y2 = midY - math.floor(doorWidth/2), midY + math.floor(doorWidth/2) - 1
								end
								--set wall tiles for hallway
								--print("drawing hallway for room "..room.id.." in direction "..direction.." at "..x1..", "..y1.." to "..x2..", "..y2.."")
								for j = x1, x2 do
									for k = y1, y2 do
										local tile = tCols[j][k]
										doorTiles[direction][#doorTiles[direction]+1] = tile
										self.connectedRooms[direction][#self.connectedRooms[direction] + 1] = neighbour --so we can check if neighbour already has hallway
										--set hallway wall tiles
										if (direction == "up" or direction == "down") then
											if (j == x1 or j == x2) then doorWallTiles[#doorWallTiles+1] = tile end
										end
										if (direction == "left" or direction == "right") then
											if (k == y1 or k == y2) then doorWallTiles[#doorWallTiles+1] = tile end
										end
										--print(j, k)
									end
								end
								setColor(doorTiles[direction], "room", room.id)
								setType(doorTiles[direction], "floor")
								--print(#doorWallTiles)
								setColor(doorWallTiles, "black")
								setType(doorWallTiles, "wall")
							end
						end
						--print("setting type for doors in room#"..room.id.."on side: "..direction.." with "..#doorTiles[direction].." tiles to floor")
					end
				end
			end
		end
	
		function room:draw()
			self.tiles = {}
			local z = 1
			local roomWidth, roomHeight = self.bounds.x2 - self.bounds.x1, self.bounds.y2 - self.bounds.y1
			--print("room #"..self.id.." bounds = ", self.bounds.x1,self.bounds.y1,self.bounds.x2,self.bounds.y2 )
			--print("room #"..self.id.." w, h = ", roomWidth, roomHeight )
			for x = 1, roomWidth do
				for y = 1, roomHeight do
					self.tiles[z] = tCols[x + self.bounds.x1 - 1 ][y + self.bounds.y1 - 1]
					self.idText.x, self.idText.y = self.tiles[z].rect:localToContent( 0, 0 )
					z = z + 1
				end
			end
			--print("iterated through draw "..z.." times")
			--print("self.id set "..#self.tiles.." tiles")
			if (self.expandComplete) then
				setColor(self.tiles, "room", self.id)
				--print("setting type for "..#self.tiles.." tiles in room#"..self.id.." to floor")
				setType(self.tiles, "floor")
			else
				setColor(self.tiles, "white")
			end
		end
	
		function room:expand() --expand All rooms prior to comparison
			for direction, data in pairs(self.expansionData) do
				if (self.expandDirComplete[direction] == false) then
					--print("expanding room with id "..self.id)
					self.bounds[data.bound] = self.bounds[data.bound] + data.boundExpand
				else
					--print("expansion complete for room# "..room.id.." in "..direction.." direction")
				end
			end
		end
		
	
		function room:compare()
			local inset = params.edgeInset
			--print ("-comparing room #"..room.id)
			for direction, _ in pairs(self.expansionData) do --for each direction of the room
				--print("--on side "..direction)
				if (self.expandDirComplete[direction] == false) then
					local data = self.expansionData[direction] --used to get data to contract room
					for i = 1, #roomStore do --get another room to compare with
						local otherRoom = roomStore[i] --croom = room to compare with
						local foundNeighbour = false
						if (room ~= otherRoom) then --dont compare with self
							local rb, cb, s = self.bounds, otherRoom.bounds, self.spacing
							 --print("spacing: "..s.." direction: "..direction.."\nroom bounds: ", rb.x1, rb.x2, rb.y1, rb.y2..
							--"\ncRoom bounds: ", cb.x1, cb.x2, cb.y1, cb.y2.."\ncomparing room "..room.id.." with "..otherRoom.id) 
							if direction == "up" or direction == "down" then
								if (rb.x1 >= cb.x1 - s) --checks if room is within compare room
								and (rb.x1 <= cb.x2 + s)
								or (rb.x2 >= cb.x1 - s)
								and (rb.x2 <= cb.x2 + s) then
									if direction == "up"
									and (rb.y1 >= cb.y2) --checks room is on the right side of the compare room
									and (rb.y1 <= cb.y2 + s) then --checks the actual room expansion
										foundNeighbour = true
									elseif direction == "down"
									and (rb.y2 <= cb.y1) --checks room is on the right side of the compare room
									and (rb.y2 >= cb.y1 - s) then --checks the actual room expansion
										foundNeighbour = true
									end
								end
							elseif direction == "left" or direction == "right" then
								if (rb.y1 >= cb.y1 - s) --checks if room is within compare room
								and (rb.y1 <= cb.y2 + s)
								or (rb.y2 >= cb.y1 - s)
								and (rb.y2 <= cb.y2 + s) then
									if direction == "left"
									and (rb.x1 >= cb.x2) --checks room is on the right side of the compare room
									and (rb.x1 <= cb.x2 + s) then --checks the actual room expansion
										foundNeighbour = true
									elseif direction == "right"
									and (rb.x2 <= cb.x1) --checks room is on the right side of the compare room
									and (rb.x2 >= cb.x1 - s) then --checks the actual room expansion
										foundNeighbour = true
									end
								end
							end
						end
						if (foundNeighbour) then
							--print ("room# "..room.id .. " expansion complete due to room# "..otherRoom.id.." on side "..direction)
							self.expandDirComplete[direction] = true
						end
					end
					--contract rooms if they have completed expansion
					if (self.expandDirComplete[direction] == true) then
						self.bounds[data.bound] = self.bounds[data.bound] + data.boundContract
					end
					--check for edge of map
					if (direction == "up" and room.bounds.y1 <= inset + self.spacing ) then
						self.expandDirComplete[direction] = true
					end
					if (direction == "down" and room.bounds.y2 > height - inset - self.spacing) then
						self.expandDirComplete[direction] = true
					end
					if (direction == "left" and room.bounds.x1 <= inset + self.spacing) then
						self.expandDirComplete[direction] = true
					end
					if (direction == "right" and room.bounds.x2 > width - inset - self.spacing) then
						self.expandDirComplete[direction] = true
					end
				end
			end
			local ec = self.expandDirComplete
			if ec.up and ec.down and ec.left and ec.right then
				--print("expand completed for room# "..room.id)
				self.expandComplete = true
			else
				self.expandComplete = false
			end
		end
	
		function room:setNeighbours() --sets neighbours after expansion is complete\
			local inset = params.edgeInset --used for map edge distance from edge of tiles
			--print ("-set neighbours for room #"..room.id)
			for direction, _ in pairs(self.expansionData) do --for each direction of the room
				--print("--on side "..direction)
				for i = 1, #roomStore do --get another room to compare with
					local otherRoom = roomStore[i] --readability
					local foundNeighbour = false
					if (room ~= otherRoom) then --dont compare with self
						local rb, cb, s = self.bounds, otherRoom.bounds, params.maxHallwayLength
						if direction == "up" or direction == "down" then
							if (rb.x1 >= cb.x1 - s) --checks if room is within compare room
							and (rb.x1 <= cb.x2 + s)
							or (rb.x2 >= cb.x1 - s)
							and (rb.x2 <= cb.x2 + s) then
								if direction == "up"
								and (rb.y1 >= cb.y2) --checks room is on the right side of the compare room
								and (rb.y1 <= cb.y2 + s) then --checks the actual room expansion
									foundNeighbour = true
								elseif direction == "down"
								and (rb.y2 <= cb.y1) --checks room is on the right side of the compare room
								and (rb.y2 >= cb.y1 - s) then --checks the actual room expansion
									foundNeighbour = true
								end
							end
						elseif direction == "left" or direction == "right" then
							if (rb.y1 >= cb.y1 - s) --checks if room is within compare room
							and (rb.y1 <= cb.y2 + s)
							or (rb.y2 >= cb.y1 - s)
							and (rb.y2 <= cb.y2 + s) then
								if direction == "left"
								and (rb.x1 >= cb.x2) --checks room is on the right side of the compare room
								and (rb.x1 <= cb.x2 + s) then --checks the actual room expansion
									foundNeighbour = true
								elseif direction == "right"
								and (rb.x2 <= cb.x1) --checks room is on the right side of the compare room
								and (rb.x2 >= cb.x1 - s) then --checks the actual room expansion
									foundNeighbour = true
								end
							end
						end
					end
					if (foundNeighbour) then
						--print ("room# "..room.id .. " neighbrour is room# "..otherRoom.id.." on side "..direction)
						self.neighbours[direction][#self.neighbours[direction]+1] = otherRoom
					end
				end
				--check for edge of map
				if (direction == "up" and room.bounds.y1 <= inset + self.spacing ) then
					self.neighbours[direction][1] = "map"
				end
				if (direction == "down" and room.bounds.y2 > height - inset - self.spacing) then
					self.neighbours[direction][1] = "map"
				end
				if (direction == "left" and room.bounds.x1 <= inset + self.spacing) then
					self.neighbours[direction][1] = "map"
				end
				if (direction == "right" and room.bounds.x2 > width - inset - self.spacing) then
					self.neighbours[direction][1] = "map"
				end
			end
		end
	
		return room
	end

	return pointsExpand
