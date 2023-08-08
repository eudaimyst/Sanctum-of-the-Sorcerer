	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local puppet = require("lib.entity.game_object.puppet")

	-- Define module
	local lib_character = {}

	function lib_character:create(_params)
		print("creating character entity")
		
		local char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        
		--char:updateFileName()
		char:loadTextures()
		char:makeRect() --creates rect on creation

		return char
	end

	return lib_character