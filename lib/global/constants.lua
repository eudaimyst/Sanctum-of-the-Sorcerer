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
	M.dirKeys = { --for picking a random direction
		"up", "upRight", "right", "downRight", "down", "downLeft", "left", "upLeft"
	}
	M.dirFileStrings = { --for fast iteration through direction strings when loading textures
		"up", "up_right", "right", "down_right", "down", "down_left", "left", "up_left"
	}

	M.charHandsWindup = { --used to determine hands position for character when casting spells, access using movedir image string as key
		down = { x = 73, y = 72 },
		down_left = { x = 124, y = 85 },
		down_right = { x = 62, y = 85 },
		left = { x = 128, y = 86 },
		right = { x = 58, y = 94 },
		up = { x = 112, y = 106 },
		up_left = { x = 134, y = 99 },
		up_right = { x = 80, y = 110 }
	}
	M.charHandsCast = {
		down = { x = 85, y = 124 },
		down_left = { x = 34, y = 105 },
		down_right = { x = 145, y = 115 },
		left = { x = 32, y = 85 },
		right = { x = 160, y = 91 },
		up = { x = 105, y = 58 },
		up_left = { x = 55, y = 64 },
		up_right = { x = 145, y = 70 }
	}

	local function scaleTable(t)
		--scales char hand locations to match scaled character image TODO: use actual values to support zooming
		local i = {w = 192, h = 192}
		local c = {w = 128, h = 128}
		local s = {x = c.h/i.h, y = c.h/i.h}
		for k, v in pairs(t) do
			v.x = i.w * .5 - v.x
			v.y = i.h * .5 - v.y
			--print("unscaled")
			--print(k..":  ".."x: "..v.x.." y: "..v.y)
			--print("scaled")
			v.x = math.round(v.x * s.x)
			v.y = math.round(v.y * s.y)
			--print(k..":  ".."x: "..v.x.." y: "..v.y)
		end
	end
	scaleTable(M.charHandsWindup)
	scaleTable(M.charHandsCast)
	
	
    M.elements = {
        fire = { c = { r=1, g=0.2, b=0.2, a=1 } },
        ice = { c = { r=0.2, g=0.2, b=1, a=1 } },
        earth = { c = { r=0.6, g=0.5, b=0.3, a=1 } },
        lightning = { c = { r=1, g=1, b=0.6, a=1 } },
        air = { c = { r=0.7, g=0.9, b=1, a=1 } },
        arcane = { c = { r=0.6, g=0.2, b=1, a=1 } },
        shadow = { c = { r=0.3, g=0.1, b=0.3, a=1 } },
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