	-----------------------------------------------------------------------------------------
	--
	-- tiles.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local lighting = require("lib.entity.light_emitter")
	local entity = require("lib.entity")
	local json = require("json")

	local mceil = math.ceil

	local lightingUpdateRate = 50 --ms
	local lightingUpdateTimer = 0

	local lightBlockerUpdateRate = 200 --ms
	local lightBlockerUpdateTimer = 0

	local map, cam, defaultTileset, wallSubTypes, mapImageFolder
	local tileSize, halfTileSize
	-- Define module
	local lib_tile = {}

	function lib_tile:init(_map, _cam, _defaultTileset, _wallSubTypes, _mapImageFolder)
		map, cam, defaultTileset, wallSubTypes, mapImageFolder = _map, _cam, _defaultTileset, _wallSubTypes, _mapImageFolder
		tileSize = map.tileSize
		halfTileSize = tileSize/2
		print("----tiles module initiated----")
	end

	function lib_tile:onFrame() --called from game or level editor on frame ????
		local dt = gv.frame.dt
		lightingUpdateTimer = lightingUpdateTimer + dt
		lightBlockerUpdateTimer = lightBlockerUpdateTimer + dt

		if lightingUpdateTimer > lightingUpdateRate then
			lightingUpdateTimer = 0
			
			local screenTiles = cam.screenTiles
			
			if lightBlockerUpdateTimer > lightBlockerUpdateRate then
				lightBlockerUpdateTimer = 0
			
				for i = 1, #screenTiles do
					screenTiles[i]:updateLightValue(true)
				end
			else
				for i = 1, #screenTiles do
					screenTiles[i]:updateLightValue(nil)
				end
			end
		end
	end

	function lib_tile:createTile(_id, _column, _row, _collision, _string)
		local tile = entity:create(_column * tileSize, _row * tileSize, nil)
		tile.lightValue = 0
		tile.col = _collision
		--tile screen pos is exclusively accessed through its rect
		tile.x, tile.y = _column, _row
		tile.world = { x = _column * tileSize, y = _row * tileSize }
		tile.mid = { x = _column * tileSize + halfTileSize, y = _row * tileSize + halfTileSize }
		
		local stringLookup = map.saveStringLookup
		local type = stringLookup[_string] --sets the tile type string to the key name of the matching tileset entry
		tile.type = type
		tile.imageTexture = defaultTileset[type].texture --imageFileLocation for this tile

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
				self.rect.x, self.rect.y = self.screen.x, self.screen.y
			end
		end

		function tile:destroyRect()
			if (self.rect) then
				self.rect:removeSelf()
				self.rect = nil
			end
		end

		function tile:updateLightValue(updateLightBlockers)
			if (self.rect) then --bypass if not rect
				for ii = 1, #lighting.store do
					local light = lighting.store[ii]
					local lightX, lightY = light.x, light.y
					local rad = light.radius + tileSize
					local exp, int = light.exponent, light.intensity

					local midx, midy = self.mid.x, self.mid.y
					local dist = util.getDistance(light.x, light.y, midx, midy)
					if dist > light.radius then
						self.lightValue = 0
					else
						if updateLightBlockers then
							self.lightBlockers = 0
							local rayDelta = {x = midx - light.x, y = midy - light.y}
							local rayNormal = util.normalizeXY(rayDelta)
							local raySegment = {x = rayNormal.x * halfTileSize, y = rayNormal.y * halfTileSize}
							local segmentLength = util.getDistance(0, 0, raySegment.x, raySegment.y)
							local segments = mceil(dist / segmentLength)
							for i = 1, segments do
								local checkPos = {x = lightX + rayNormal.x * segmentLength * i, y = lightY + rayNormal.y * segmentLength * i}
								--print(checkPos.x, checkPos.y)
								--print("checking blockers")
								local checkTile = map:getTileAtPoint(checkPos)
								if checkTile then
									if checkTile.type == "void" then
										--found a light blocker
										self.lightBlockers = self.lightBlockers + 1
									end
								end
							end
							local mod = (2 - self.lightBlockers) / 2
							self.lightValue = ( 1 - (dist / rad) ^ exp ) * int * mod
						end
					end
				end
				if self.type == "wall" then
					for i = 0, 3 do
						self.rect.wallRects[i]:setFillColor(self.lightValue)
					end
			else
					self.rect:setFillColor(self.lightValue)
				end
			end
		end

		function tile:createRect()
			if (self.type == "wall") then --if tile is a wall then we need to make a group for the subtiles
				self.rect = display.newGroup()
				self.rect.wallRects = {}
				map.tileGroup:insert(self.rect)
				self.rect.anchorChildren = true
				for i = 0, 3 do --four corners
					local wallRect = display.newImageRect( self.rect, self.wallTexture[i].filename, self.wallTexture[i].baseDir, halfTileSize, halfTileSize ) --create rect for each wall
					self.rect.wallRects[i] = wallRect
					wallRect = util.zeroAnchors(wallRect)
					local n, r = math.modf( i / 2 ) --set wall rect position using math
					wallRect.x = r * tileSize - halfTileSize
					wallRect.y = n * halfTileSize - halfTileSize
				end
			else
				--print("creating rect for tile id: "..self.id.. " with image "..image)
				self.rect = display.newImageRect( map.tileGroup, self.imageTexture.filename, self.imageTexture.baseDir, tileSize, tileSize )
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

	return lib_tile