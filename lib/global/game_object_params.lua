	-----------------------------------------------------------------------------------------
	--
	-- game_object_params.lua
	--
	-----------------------------------------------------------------------------------------
	-- Define module
	local p = {}

		p.crate = {
			name = "crate", moveSpeed = nil, width = 140, height = 140, xOffset = 0, yOffset = -0,
			colWidth = 24, colHeight = 12,
			animations = {
			idle = { frames = 1, rate = .5, loop = true },
			death = { frames = 3, rate = 15, loop = false } }
		}

	return p