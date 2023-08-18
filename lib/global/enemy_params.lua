	-----------------------------------------------------------------------------------------
	--
	-- enemy_params.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")

	-- Define module
	local e = {}
		e.rat = {
			name = "rat", moveSpeed = 200, width = 128, height = 128, yOffset = 0,
			colWidth = 64, colHeight = 64,
			attacks = {},
			anims = {}
		}
	return e