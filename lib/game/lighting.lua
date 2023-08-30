	-----------------------------------------------------------------------------------------
	--
	-- lighting.lua
	--
	-- used by game to update entities which receive lighting
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local lightEmitters = require("lib.entity.light_emitter")

	local mceil = math.ceil

	local store = lightEmitters.store

	local lightingUpdateRate = 50 --ms
	local lightingUpdateTimer = 0

	local updateLightingFlag = nil

	--temp values used for updating lighting (to save making new locals every call)
	local lightValue --temp lightvalue
	local light, dist, rad, exp, int, mod
	local dt --delta time set on update from gv

	-- Define module
	local lighting = {}

	function lighting:updateLighting(entity)
		lightValue = 0
		for ii = 1, #store do
			light = store[ii]
			dist = util.getDistance(light.x, light.y, entity.mid.x, entity.mid.y)
			if dist < light.radius then
				rad = light.radius
				exp, int = light.exponent, light.intensity
				lightValue = lightValue + ( 1 - (dist / rad) ^ exp ) * int
			end
		end
		if entity.type == "wall" then
			for i = 0, 3 do
				entity.rect.wallRects[i]:setFillColor(lightValue)
			end
		else
			entity.rect:setFillColor(lightValue)
		end
		entity.lightValue = lightValue
	end

	function lighting.doLightingUpdate()
		return updateLightingFlag
	end

	function lighting:onFrame()
		dt = gv.frame.dt
		updateLightingFlag = nil
		
		lightingUpdateTimer = lightingUpdateTimer + dt
		
		if lightingUpdateTimer > lightingUpdateRate then
			lightingUpdateTimer = 0
			updateLightingFlag = true
		end
	end

	return lighting