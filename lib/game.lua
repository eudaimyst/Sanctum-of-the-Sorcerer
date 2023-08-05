	-----------------------------------------------------------------------------------------
	--
	-- game.lua -- library of functions used for game scene
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local character = require("lib.entity.game_object.puppet.character")

	local gameObj = require("lib.entity.game_object")

	-- Define module
	local game = {}
	
	function game.firstFrame()
		game.char = character:create()
	end

	
	

	return game