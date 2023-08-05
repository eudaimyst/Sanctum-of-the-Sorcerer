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

	function lib_character:create()
		print("creating character object")
		local char = puppet:create()
		return char
	end

	return lib_character