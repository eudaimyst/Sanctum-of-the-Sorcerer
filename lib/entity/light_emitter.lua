	-----------------------------------------------------------------------------------------
	--
	-- light_emitter.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local map = require("lib.map")

	local mround = math.round

	local tileSize = 128
	local halfTileSize = 64

	-- Define module
	local lightEmitter = {}
	lightEmitter.store = {}

	local function updateLightPos(entity) --
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
	end

	local function createLight(_params)
		local light = { x = 0, y = 0, radius = 800, intensity = 10, exponent = .1, active = false, path = nil }
		if _params then
			if _params.x then light.x = _params.x end
			if _params.y then light.y = _params.y end
			if _params.radius then light.radius = _params.radius end
			if _params.intensity then light.intensity = _params.intensity end
			if _params.exponent then light.exponent = _params.exponent end
		end
		lightEmitter.store[#lightEmitter.store+1] = light
		--set light calc values
		local rayCount = mround( 360 / util.deltaToAngle( light.radius, tileSize ))
		light.checkAngle = 360 / rayCount
		light.rayCount = rayCount
		light.raySegments = math.ceil(light.radius / halfTileSize)
		light.raySegmentLength = light.radius / light.raySegments

		function light:updateLighting()
			local a, dist, x, y
			local tile, prevTileFound, prevTileUpdated
			local rad, exp, int = light.radius, light.exponent, light.intensity

			local function checkRay(i)
				a = math.rad(self.checkAngle * i)
				for j = 1, self.raySegments do
					dist = light.raySegmentLength * j
					x = math.cos(dist * a) * math.pi
					y = math.sin(-dist * a) * math.pi
					tile = map.getTileAtPoint({ x = x, y = y })
					if tile.updatedByLight ~= self then
						tile.updatedByLight = self
						if tile ~= prevTileUpdated then
							if tile.type == "wall" or tile.type == "void"
							and prevTileUpdated.type == "wall" or prevTileUpdated.type == "void" then
								return
							else
								tile.lightValue = tile.lightValue + ( 1 - ( (dist / rad) ^ exp) ) * int
								prevTileUpdated = tile
							end
						end
					end
				end
			end
			for i = 1, self.rayCount do
				checkRay(i)
			end
		end

		return light
	end

	function lightEmitter.attachToEntity(entity, _params)
		entity:addOnFrameMethod(updateLightPos)
		entity.light = createLight(_params)
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
	end

	return lightEmitter