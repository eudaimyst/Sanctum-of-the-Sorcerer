	-----------------------------------------------------------------------------------------
	--
	-- game_object_params.lua
	--
	-----------------------------------------------------------------------------------------
	-- Define module
	local p = {}

		p.crate = {
			name = "crate", moveSpeed = nil, width = 240, height = 240, xOffset = 0, yOffset = 0,
			colWidth = 30, colHeight = 30,
			animations = {
			idle = { frames = 1, rate = .5 },
			death = { frames = 3, rate = 4 } }
		}

	return p