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
			sightRange = 500, --distance from char before moving to attack
			leashTime = 5, --s how long before going back to spawnPos if out of sightRange of char
			wanderDistance = { min = 100, max = 200 }, --max distance to move when idling
			attacks = {attack_spin = attackParams.swipe},
			animations = {
			idle = { frames = 2, rate = .5 },
			walk = { frames = 4, rate = 4 }, }
		}

	return e