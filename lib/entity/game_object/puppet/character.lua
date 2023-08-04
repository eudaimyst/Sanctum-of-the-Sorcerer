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
	local character = {}

	function character:create()
		print("creating character object")
		local c = puppet:create()
		return c
	end

	return character