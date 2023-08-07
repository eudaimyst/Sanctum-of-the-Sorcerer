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
	local cam, map --set on init()

	function game.spawnChar()
		
		print("char getting spawn point from map: ")
		local charParams = { 
			name = "character", width = 128, height = 128,
			moveSpeed = 300,
			spawnPos = map:getSpawnPoint()
		}
		game.char = character:create(charParams)
	end

	function game.init(_cam, _map)
		print("setting cam and map for game library")
		cam = _cam
		map = _map
	end

	function game.firstFrame()
		game.spawnChar()

	end

	return game