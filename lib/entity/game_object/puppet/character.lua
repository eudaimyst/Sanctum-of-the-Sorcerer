	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local puppet = require("lib.entity.game_object.puppet")

	-- Define module
	local lib_character = {}

	function lib_character:create(_params)
		
		print("creating character object")
		
		local char = puppet:create(_params)
		char.name = "character"
		char.width, char.height = 128, 128
        
		char:makeRect() --creates rect on object creation (remove when camera starts to call this)

		return char
	end

	return lib_character