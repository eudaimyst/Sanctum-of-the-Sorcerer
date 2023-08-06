	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	local json = require("json")
	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local puppet = require("lib.entity.game_object.puppet")

	-- Define module
	local lib_character = {}

	function lib_character:create(_params)
		print("creating character entity")
		
		local char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        
		char:updateFileName()
		char:makeRect() --creates rect on object creation (remove when camera starts to call this)

		return char
	end

	return lib_character