	-----------------------------------------------------------------------------------------
	--
	-- light_emitter.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")


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
		return light
	end

	function lightEmitter.attachToEntity(entity, _params)
		entity:addOnFrameMethod(updateLightPos)
		entity.light = createLight(_params)
		entity.light.x, entity.light.y = entity.world.x, entity.world.y
	end

	return lightEmitter