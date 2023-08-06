	-----------------------------------------------------------------------------------------
	--
	-- game.lua -- library of functions used for game scene
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local character = require("lib.entity.game_object.puppet.character")
	local puppet = require("lib.entity.game_object.puppet")

	local gameObj = require("lib.entity.game_object")

	-- Define module
	local game = {}

	function game.spawnChar()
		local charParams = { 
			name = "character", width = 128, height = 128,
			moveSpeed = 300,
			spawnPos = { x = display.actualContentWidth / 2, y = display.actualContentHeight / 2}
		}
		game.char = character:create(charParams)
	end

	function game.firstFrame()
		game.spawnChar()

	end

	return game