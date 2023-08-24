	-----------------------------------------------------------------------------------------
	--
	-- tiles.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local lighting = require("lib.entity.light_emitter")
	local json = require("json")

	local mceil = math.ceil

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

	function lib_tile:createTile(_id, _column, _row, _collision, _string)
		local tile = {}
		local i, x, y, c, s = _id, _column, _row, _collision, _string
		--print(i, x, y, c, s)
		tile.id, tile.x, tile.y = i, x, y --tile.x = tile column, tile.y = tile row
		tile.col = c
		--tile screen pos is exclusively accessed through its rect
		tile.world = { x = x * tileSize, y = y * tileSize }
		tile.mid = { x = x * tileSize + halfTileSize, y = y * tileSize + halfTileSize }
		
		local stringLookup = map.saveStringLookup
		--print("tile string lookup:")
		--print(json.prettify(stringLookup))
		--print("looking for string in key"..s)
		--print('setting tile type to string '..stringLookup[s])
		local type = stringLookup[s] --sets the tile type string to the key name of the matching tileset entry
		tile.type = type
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

		function tile:updateLighting()
			if (self.rect) then --bypass if not rect
				for ii = 1, #lighting.store then
					local light = lighting.store[ii]

					local midx, midy = self.mid.x, self.mid.y
					local dist = util.getDistance(light.x, light.y, midx, midy)
					if dist > light.radius then
						self.lightValue = 0
					else
						print("updating blockers")
						self.lightBlockers = 0
						local rayStart = {x = light.x, y = light.y}
						local rayEnd = {x = midx, y = midy}
						local rayDelta = {x = rayEnd.x - rayStart.x, y = rayEnd.y - rayStart.y}
						local rayNormal = util.normalizeXY(rayDelta)
						local raySegment = {x = rayNormal.x * tileSize/2, y = rayNormal.y * tileSize/4}
						local segmentLength = util.getDistance(0, 0, raySegment.x, raySegment.y)
						local segments = mceil(dist / segmentLength)
						for i = 1, segments do
							local checkPos = {x = rayStart.x + rayNormal.x * segmentLength * i, y = rayStart.y + rayNormal.y * segmentLength * i}
							local checkTile = getTileAtPoint(checkPos.x, checkPos.y)
							if checkTile then
								if checkTile.col == true then
									--found a light blocker
									self.lightBlockers = self.lightBlockers + 1
								end
							end
						end
						local rad = light.radius + tileSize
						local mod = (2 - self.lightBlockers) / 2
						self.lightValue = light.intensity * ( ( 1 - (dist / rad) ^ light.exponent ) * light.intensity * mod )
					end
				end
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
	return lib_tile