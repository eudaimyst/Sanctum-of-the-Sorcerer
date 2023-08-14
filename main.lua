-----------------------------------------------------------------------------------------
--
-- main.lua
--
-----------------------------------------------------------------------------------------

--require("mobdebug").start() --for zerobrane debugging

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )
native.setProperty( "mouseCursorVisible", false )
print("mouse cursor visible: "..tostring(native.getProperty( "mouseCursorVisible" )))

-- include the Corona "composer" module
local composer = require "composer"

-- load menu screen
--composer.gotoScene( "scenes.sc_menu" ) --skip menu for today
composer.gotoScene( "scenes.sc_game" )
--composer.gotoScene( "scenes.sc_map_generator" )
--composer.gotoScene( "scenes.sc_level_editor" )