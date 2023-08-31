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

	local function updateLightPos(entity) --
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
	end

	--------recycled vars for updateTilesLightValues
	local a, dist, x, y
	local tile, prevTileUpdated
	local rad, exp, int

	local function createLight(_params)
		local light = { x = 0, y = 0, radius = 800, intensity = 10, exponent = .1, active = false, path = nil }
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

		function light:updateTilesLightValues()
			rad, exp, int = light.radius, light.exponent, light.intensity
			local v
			--print("light updating", light.id)

			local function checkRay(i)
				prevTileUpdated = nil --reset the prev tile checker for each ray
				a = math.rad(self.checkAngle * i)
				for j = 1, self.raySegments do
					dist = light.raySegmentLength * j
					--print("checking ray", j, "/", self.raySegments, "dist: ", dist)
					x = light.x + math.cos(a) * dist --* math.pi
					y = light.y + math.sin(a) * -dist --* math.pi
					--print("x, y", x, y)
					tile = map:getTileAtPoint({ x = x, y = y })
					if tile ~= prevTileUpdated then
						--print("updating tile ", tile.id)
						if prevTileUpdated then
							if tile.type == "wall" or tile.type == "void" then
								if prevTileUpdated.type == "wall" or prevTileUpdated.type == "void" then
									--print("found 2 walls in a row, stop checking ray")
									tile:storeLightValue(self.id, 0 )
									return
								end
							end
						end
						v = ( 1 - ( (dist / rad) ^ exp) ) * int
						--print("updating lightValue", v)
						tile:storeLightValue(self.id, v )
						prevTileUpdated = tile
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
			for i = 1, lightCounter do
				local light = lightStore[i]
				if util.withinBounds(light.x, light.y, cMinX, cMaxX, cMinY, cMaxY ) then
					--print("light within bounds, ", light.id)
					lightStore[i]:updateTilesLightValues()
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
	end

	function lightEmitter.init(_map, _cam) --pass libs to module
		map, cam = _map, _cam
		camTiles = map.getCamTiles()
	end

	return lightEmitter