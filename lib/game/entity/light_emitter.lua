	-----------------------------------------------------------------------------------------
	--
	-- light_emitter.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local map, cam --set on init()
	local camTiles

	local mround = math.round
	local frame = gv.frame
	local screen = gv.screen

	local tileSize = 128
	local halfTileSize = 64
	
	local lightingUpdateRate = 200 --ms
	local lightingUpdateTimer = 0
	local dt --recycled delta time

	-- Define module
	local lightEmitter = {}
	local lightStore = {}
	local lightCounter = 0

	local characterLight

	local function updateLightPos(entity) --
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
	end

	--------recycled vars for updateTilesLightValues
	local a, dist, x, y
	local tile, prevTileUpdated
	local rad, exp, int

	local function createLight(_params)
		local light = { x = 0, y = 0, radius = 1080, intensity = 10, exponent = .1, active = false, path = nil }
		if _params then
			if _params.x then light.x = _params.x end
			if _params.y then light.y = _params.y end
			if _params.radius then light.radius = _params.radius end
			if _params.intensity then light.intensity = _params.intensity end
			if _params.exponent then light.exponent = _params.exponent end
		end
		lightCounter = lightCounter + 1
		lightStore[lightCounter] = light
		light.id = lightCounter
		--set light calc values
		local rayCount = mround( 360 / util.deltaToAngle( light.radius, tileSize ))
		light.checkAngle = 360 / rayCount
		light.rayCount = rayCount
		light.raySegments = math.ceil(light.radius / halfTileSize)
		light.raySegmentLength = light.radius / light.raySegments

		function light:destroySelf()
			lightStore[self.id] = nil
			self = nil
		end

		function light:updateTilesLightValues()
			rad, exp, int = light.radius, light.exponent, light.intensity
			local v
			--print("light updating", light.id)
			local startTile = map:getTileAtPoint({ x = light.x, y = light.y })

			local function checkRay(i)
				prevTileUpdated = nil --reset the prev tile checker for each ray
				local updatedTiles = {}
				a = math.rad(self.checkAngle * i)
				
				local function tileAlreadyUpdated(_tile)
					for j = 1, #updatedTiles do
					end
					return nil
				end

				for i2 = 1, self.raySegments do
					local w = 0 --wall count
					local skipTile = nil
					dist = light.raySegmentLength * i2
					--print("checking ray", j, "/", self.raySegments, "dist: ", dist)
					x = light.x + math.cos(a) * dist --* math.pi
					y = light.y + math.sin(a) * dist --* math.pi
					--print("x, y", x, y)
					tile = map:getTileAtPoint({ x = x, y = y })
					if tile.type == "void" then --ray checker hits a void tile so stop checking this ray
						return
					end
					--print("updating tile ", tile.id)
					for i3 = 1, #updatedTiles do
						local updatedTile = updatedTiles[i3]
						if updatedTiles[i3] == tile then --tile has already been updated by this ray
							skipTile = {}
						elseif updatedTiles[i3].type == "wall" then
							w = w + 1 --increase wall count
						end
					end
					if (not skipTile) then
						v = (( 1- ( (dist / rad) ^ exp) ) * int ) - (w * .25)
						--print("updating lightValue", v, "walls", w)
						if light == characterLight then
							tile:storeLightValue(self.id, v, true )
						else
							tile:storeLightValue(self.id, v )
						end
						updatedTiles[#updatedTiles+1] = tile
					end
				end
			end
			for i = 1, self.rayCount do
				checkRay(i)
			end
		end
		return light
	end

	local cMinX, cMaxX, cMinY, cMaxY --recycled vars
	function lightEmitter.onFrame()
		dt = frame.dt
		lightingUpdateTimer = lightingUpdateTimer + dt
		if lightingUpdateTimer > lightingUpdateRate then
			cMinX, cMaxX, cMinY, cMaxY = cam:getBounds()
			cMinX, cMaxX = cMinX - screen.halfWidth, cMaxX + screen.halfWidth
			cMinY, cMaxY = cMinY - screen.halfHeight, cMaxY + screen.halfHeight
			--print(cMinX, cMaxX, cMinY, cMaxY)
			--print("updating lights: ", #lightStore)
			lightingUpdateTimer = 0
			for _, light in pairs(lightStore) do
				if util.withinBounds(light.x, light.y, cMinX, cMaxX, cMinY, cMaxY ) then
					--print("light within bounds, ", light.id)
					light:updateTilesLightValues()
				end
			end
			camTiles = map.getCamTiles()
			for i = 1, #camTiles do
				camTiles[i]:updateLighting()
			end
		end
	end

	function lightEmitter.getStore()
		return lightStore
	end

	function lightEmitter.attachToEntity(entity, _params)
		
		entity:addOnFrameMethod(updateLightPos)
		entity.light = createLight(_params)
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
		if entity.name == "character" then
			characterLight = entity.light
		end
	end

	function lightEmitter.init(_map, _cam) --pass libs to module
		map, cam = _map, _cam
		camTiles = map.getCamTiles()
	end

	return lightEmitter