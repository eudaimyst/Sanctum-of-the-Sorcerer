	-----------------------------------------------------------------------------------------
	--
	-- game.lua -- library of functions used for game scene
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local gameObject = require("lib.entity.game_object")
	local puppet = require("lib.entity.game_object.puppet")
	local character = require("lib.entity.game_object.puppet.character")


	-- Define module
	local game = {}
	local cam, map, key --set on init()

	function game.spawnChar()
		
		print("char getting spawn point from map: ")
		local charParams = { 
			name = "character", width = 128, height = 128,
			moveSpeed = 200,
			spawnPos = map:getSpawnPoint()
		}
		game.char = character:create(charParams)
		
		cam:setMode("follow", game.char)
			
	end

	function game:onFrame()
		
		gameObject:clearMovement() --sets isMoving to false for all game objects, before being set by key input

		key:onFrame()

		cam:onFrame()
		map:cameraMove(game.char.moveDirection)
		self.char:updateRectPos()
		
		puppet:onFrame()
	end

	function game.init(_cam, _map, _key)
		print("setting cam and map for game library")
		key = _key
		cam = _cam
		map = _map
	end

	function game.firstFrame()
		game.spawnChar()

	end

	return game