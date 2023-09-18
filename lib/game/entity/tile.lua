	-----------------------------------------------------------------------------------------
	--
	-- tiles.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local entity = require("lib.game.entity")
	local json = require("json")
    local lighting = require("lib.game.entity.light_emitter")
	local lightStore --recycled set on update

	local mceil = math.ceil

	local game, map, cam, defaultTileset, wallSubTypes, mapImageFolder
	local tStoreIndex, tStoreCols
	local tileSize, halfTileSize
	local stringLookup --to set tile type

	local gameChar --set on init for updating light blocker
	-- Define module
	local lib_tile = {}

	function lib_tile:init(_game, _map, _cam, _defaultTileset, _wallSubTypes, _mapImageFolder)
		map, cam, defaultTileset, wallSubTypes, mapImageFolder = _map, _cam, _defaultTileset, _wallSubTypes, _mapImageFolder
		game = _game
		stringLookup = map.saveStringLookup
		tStoreIndex, tStoreCols = map.getTileStore()
		tileSize = map.tileSize
		halfTileSize = tileSize/2
		print("----tiles module initiated----")
	end

	function lib_tile:createTile(_id, _column, _row, _collision, _string)
		local tile = entity:create(_column * tileSize, _row * tileSize, nil) --pass nil to not use entity update rect method
		tile.lightValue = 0
		tile.col = _collision
		--tile screen pos is exclusively accessed through its rect
		tile.mapX, tile.mapY = _column, _row
		tile.midX, tile.midY = _column * tileSize + halfTileSize, _row * tileSize + halfTileSize
		--print("tile world pos: ", tile.mapX, tile.y) --(DEBUG:WORKING)
		tile.rect = nil
		tile.lightValues = {}
		tile.visibleToChar = nil
		
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

				local searchCol = self.mapX+search[subID].x --columns of the tiles to search
				local searchRow = self.mapY+search[subID].y --rows
				--print("checking wall type at col, row: "..searchCol..", "..searchRow.." for tile xy "..self.mapX..", "..self.y)
				local Xtype = tStoreCols[searchCol][self.mapY].type --get tile type to left/right
				local Ytype = tStoreCols[self.mapX][searchRow].type --get tile type above/below

				if (Xtype == "wall" ) then 
					if (Ytype == "wall") then
						local innerWallType = tStoreCols[searchCol][searchRow].type --store tiles type
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

		function tile:storeLightValue(lightID, lightValue, _isCharLight) --called by light depending on ray result
			if _isCharLight then
				tile.tempVisibility = true
			else
				tile.tempVisibility = nil
			end
			if tile.lightValues[lightID] then
				if lightValue > tile.lightValues[lightID] then
					tile.lightValues[lightID] = lightValue
				end
			else
				tile.lightValues[lightID] = lightValue
			end
			--print("tile, light, value", tile.id, lightID, lightValue)
			--tile.lightValue = tile.lightValue + lightValue
		end

		function tile:updateLighting() --called by light emitter on frame determined by rate on all camTiles
			self.lightValue = 0
			if (self.tempVisibility) then
				self.visibleToChar = true
			end
			if (self.visibleToChar) then
				for lightID, value in pairs(self.lightValues) do --bad expensive way to calc lightvalues for testing
					lightStore = lighting.getStore()
					local light = lightStore[lightID]
					if (light) then --check light exists
						if util.getDistance(self.midX, self.midY, light.x, light.y) <= light.radius then
							self.lightValue = self.lightValue + value
						end
					else
						lightStore[lightID] = nil --light has been destroyed so remove its lightValue
					end
				end
			else
				self.visibleToChar = nil
			end
			if self.type == "wall" then
				for i = 1, 4 do
					self.rect[i]:setFillColor(self.lightValue)
				end
			else
				self.rect:setFillColor(self.lightValue)
			end
			self.lightValues = {}
			self.tempVisibility = nil
		end

		--updates the tiles rect position to match its world position within cam bounds and scaled by camera zoom
		function tile:updateRectPos() --called by map:refreshCamTiles() when camTiles are determined
			if (self.rect) then
				self.rect.xScale, self.rect.yScale = cam.zoom, cam.zoom
				--print(self.id, self.mapX, self.mapY)
				self.rect.x, self.rect.y = (self.mapX - cam.bounds.x1) * cam.zoom , (self.mapY - cam.bounds.y1) * cam.zoom
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
			util.zeroAnchors(self.rect)
			self:updateRectPos()
		end
		--tiles by default do not have a rect, createRect is called when tile needs to be shown, ie between camera bounds on camera move
		--tile:createRect()
		return tile
	end

	return lib_tile