-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

--require("mobdebug").start() --for zerobrane debugging

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

-- include the Corona "composer" module
local composer = require "composer"

-- load menu screen
--composer.gotoScene( "scenes.sc_menu" ) --skip menu for today
composer.gotoScene( "scenes.sc_game" )
--composer.gotoScene( "scenes.sc_map_generator" )
--composer.gotoScene( "scenes.sc_level_editor" )

--[[
local charHands = { --used to determine hands position for character when casting spells, access using movedir image string as key
up_right = { x = 80, y = 110 },
down = { x = 73, y = 72 },
down_left = { x = 124, y = 85 },
down_right = { x = 62, y = 85 },
left = { x = 128, y = 86 },
right = { x = 58, y = 94 },
up = { x = 112, y = 106 },
up_left = { x = 134, y = 99 }
}
local i = {w = 192, h = 192}
local c = {w = 128, h = 128}
local s = {x = c.h/i.h, y = c.h/i.h}

for k, v in pairs(charHands) do
	v.x = i.w * .5 - v.x
	v.y = i.h * .5 - v.y
	print("unscaled")
	print(k..":  ".."x: "..v.x.." y: "..v.y)
	print("scaled")
	v.x = math.round(v.x * s.x)
	v.y = math.round(v.y * s.y)
	print(k..":  ".."x: "..v.x.." y: "..v.y)
end]]