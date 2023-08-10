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
	local cam, map, key, mouse, hud --set on init()


	function game.spawnChar()
		print("char getting spawn point from map: ")
		local charParams = { 
			name = "character", width = 128, height = 128,
			moveSpeed = 200, spellSlots = 5,
			spawnPos = map:getSpawnPoint()
		}
		game.char = character:create(charParams, hud)
		
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

	function game.init(_cam, _map, _key, _mouse, _hud)
		print("setting cam and map for game library")
		key, cam, map, hud, mouse = _key, _cam, _map, _hud, _mouse
	end

	function game.mouseClick(x, y) --mouseClick called from mouse input listener, can't pass self
		if (game.char.activeSpell) then
			if (game.char.activeSpell.params.targetType == "point") then
				local target = { x = cam.bounds.x1 + x, y = cam.bounds.y1 + y}
				game.char:beginCast( target )
			end
		end
	end

	function game:beginPlay()
		
		local function moveInput(direction)
			self.char:move(direction)
		end

		self.spawnChar()
		hud:draw(self.char)
		key.registerMoveListener(moveInput)
		key.registerSpellSelectListener(self.char.setActiveSpell)
		mouse.registerClickListener(self.mouseClick)
	end

	return game