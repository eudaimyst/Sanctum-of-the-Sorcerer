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
			leashTime = 3, --s how long before going back to spawnPos if out of sightRange of char
			wanderDistance = { min = 100, max = 200 }, --max distance to move when idling
			attacks = { {priority = 0, params = attackParams.tailSwipe} },
			colWidth = 30, colHeight = 30,
			attackSpeed = 2,
			animations = {
			idle = { frames = 2, rate = .5, loop = true },
			walk = { frames = 4, rate = 12, loop = true },
			death = { frames = 7, rate = 15, loop = false } }
		}

		e.bat = {
			name = "bat", moveSpeed = 200, width = 128, height = 128, yOffset = 20,
			sightRange = 500, --distance from char before moving to attack
			leashTime = 3, --s how long before going back to spawnPos if out of sightRange of char
			wanderDistance = { min = 100, max = 200 }, --max distance to move when idling
			attacks = { {priority = 0, params = attackParams.dive} },
			colWidth = 30, colHeight = 30,
			attackSpeed = 2,
			animations = {
			idle = { frames = 7, rate = .5, loop = true },
			walk = { frames = 7, rate = 12, loop = true },
			death = { frames = 7, rate = 15, loop = false } }
		}

		e.rat_boss = {
			name = "rat_boss", moveSpeed = 200, width = 480, height = 480, yOffset = 0,
			sightRange = 500, --distance from char before moving to attack
			leashTime = 3, --s how long before going back to spawnPos if out of sightRange of char
			wanderDistance = { min = 100, max = 200 }, --max distance to move when idling
			attacks = { {priority = 0, params = attackParams.tailSwipe} },
			colWidth = 30, colHeight = 30,
			attackSpeed = 2,
			animations = {
			idle = { frames = 4, rate = .5, loop = true },
			walk = { frames = 4, rate = 12, loop = true },
			death = { frames = 4, rate = 15, loop = false } }
		}

	return e