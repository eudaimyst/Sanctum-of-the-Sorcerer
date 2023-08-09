	-----------------------------------------------------------------------------------------
	--
	-- globals.lua
	--
	-----------------------------------------------------------------------------------------

	-- Define module
	local M = {}

	--x and y and angle in degrees values for moving things 
	M.move = {
		up = {x = 0, y = -1, angle = 270, image = "up"},
		upRight = {x = .666, y = -.666, angle = 315, image = "up_right"},
		right = {x = 1, y = 0, angle = 0, image = "right"},
		downRight = {x = .666,y = .666, angle = 45, image = "down_right"},
		down = {x = 0,y = 1, angle = 90, image = "down"},
		downLeft = {x = -.666,y = .666, angle = 135, image = "down_left"},
		left = {x = -1,y = 0, angle = 180, image = "left"},
		upLeft = {x = -.666,y = -.666, angle = 225, image = "up_left"},
	}
	
    M.elements = {
        fire = { c = { r=1, g=0.2, b=0.2, a=1 } },
        water = { c = { r=0.2, g=0.2, b=1, a=1 } },
        earth = { c = { r=0.6, g=0.5, b=0.3, a=1 } },
        air = { c = { r=0.7, g=0.9, b=1, a=1 } },
        arcane = { c = { r=0.6, g=0.2, b=1, a=1 } },
        dark = { c = { r=0.3, g=0.1, b=0.3, a=1 } },
		physical = { c = { r=0.5, g=0.5, b=0.5, a=1 } },
    }

	--xpamounts needed for leveling up
	M.xpAmount = {}
	M.xpAmount[0] = 100
	M.xpAmount[1] = 250
	M.xpAmount[2] = 425
	M.xpAmount[3] = 800
	M.xpAmount[4] = 1050
	M.xpAmount[5] = 1350
	M.xpAmount[6] = 1800
	M.xpAmount[7] = 2300
	M.xpAmount[8] = 2800 

	--always return module
	return M