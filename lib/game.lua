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
	local cam, map, key, hud --set on init()


	function game.spawnChar()
		print("char getting spawn point from map: ")
		local charParams = { 
			name = "character", width = 128, height = 128,
			moveSpeed = 200, spellSlots = 5,
			spawnPos = map:getSpawnPoint()
		}
		game.char = character:create(charParams)
		
		cam:setMode("follow", game.char)
	end

	function game:onFrame()

		gameObject:clearMovement() --sets isMoving to false for all game objects, before being set by key input

		key:onFrame() --processes key inputs
		cam:onFrame() --processes camera movement
		map:cameraMove(game.char.moveDirection) --move map tiles, destroy boundaryTiles, create new tiles
		
		self.char:updateRectPos() --updates game char position on screen, game object function
		game.char:updateAnimationFrames() --changes chars current frame based on animation timer
	
	end

	function game.init(_cam, _map, _key, _hud)
		print("setting cam and map for game library")
		key, cam, map, hud = _key, _cam, _map, _hud
	end

	function game.beginPlay()
		
		local function moveInput(direction)
			game.char:move(direction)
		end

		game.spawnChar()
		hud:draw(game.char)
		key.registerMoveListener(moveInput)
	end

	return game