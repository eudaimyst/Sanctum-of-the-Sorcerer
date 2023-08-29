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
	local map

	local lightingUpdateRate = 50 --ms
	local lightingUpdateTimer = 0

	local lightBlockerUpdateRate = 200 --ms
	local lightBlockerUpdateTimer = 0

	-- Define module
	local lighting = {}

	local lightingRects

	local function updateLighting(rect)
	end

	local function updateBlockers(rect)
	end

	function lighting:onFrame()
		local dt = gv.frame.dt
		local camTiles = map.getCamTiles()
		
		lightingUpdateTimer = lightingUpdateTimer + dt
		lightBlockerUpdateTimer = lightBlockerUpdateTimer + dt
		
		if lightBlockerUpdateTimer > lightBlockerUpdateRate then
			lightBlockerUpdateTimer = 0
			lightingUpdateTimer = 0
			for i = 1, #lightingRects do 
				local rect = lightingRects[i]
				updateLighting(rect)
				updateBlockers(rect)
			end
		elseif lightingUpdateTimer > lightingUpdateRate then
			lightingUpdateTimer = 0
			for i = 1, #lightingRects do 
				updateLighting(lightingRects[i])
			end
		end
	end


	function lighting:addLightingUpdater(rect) --rect to update lighting on
		lightingRects[#lightingRects+1] = rect
		updateLighting(rect)
	end

	function lighting:init(_map)
		map = _map
	end

	return lighting