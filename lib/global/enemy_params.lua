	-----------------------------------------------------------------------------------------
	--
	-- enemy_params.lua
	--
	-----------------------------------------------------------------------------------------
	local attackParams = require("lib.global.attack_params")
	-- Define module
	local e = {}

		e.rat = {
			name = "rat", moveSpeed = 200, width = 164, height = 164, yOffset = 0,
			attacks = {attack_spin = attackParams.swipe},
			animations = {
			idle = { frames = 2, rate = .5 },
			walk = { frames = 4, rate = 4 }, }
		}

	return e