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

	local function updateLight(entity) --
		
	end

	function lightEmitter.attachToEntity(entity, _params)
		local light = {x = entity.world.x, y = entity.world.y, radius = 800, intensity = 2, exponent = .1, active = false, path = nil}
		if _params then
			if _params.radius then light.radius = _params.radius end
			if _params.intensity then light.intensity = _params.intensity end
			if _params.exponent then light.exponent = _params.exponent end
		end
		entity:addOnFrameMethod(updateLight)
		lightEmitter.store[#lightEmitter.store+1] = light
		entity.light = light
	end

	return lightEmitter