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

	local function updateLight(entity) --
		

	end

	function lightEmitter.attachToEntity(entity)
		local light = {}

		entity:addOnFrameMethod(updateLight)
		entity.light = light
	end

	return lightEmitter