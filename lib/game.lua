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
	

	local directions = { gc.move.down, gc.move.downLeft, gc.move.left, gc.move.upLeft, gc.move.up, gc.move.upRight, gc.move.right, gc.move.downRight }

	
	local puppetDir = {}
	local function spinPuppet(event)
		if (not puppetDir[event.source.params.id]) then
			puppetDir[event.source.params.id] = 1
		end
		puppetDir[event.source.params.id] = puppetDir[event.source.params.id] + 1
		if puppetDir[event.source.params.id] == #directions + 1 then
			puppetDir[event.source.params.id] = 1
		end
		event.source.params.puppet:setMoveDirection(directions[puppetDir[event.source.params.id]])
	end

	function game.firstFrame()
		
		local params = { spawnPos = {} }
		params.spawnPos.x, params.spawnPos.y = display.actualContentWidth / 2 + 100, display.actualContentHeight / 2
		local p = puppet:create(params)
		local spinTimer = timer.performWithDelay(500, spinPuppet, 0)
		spinTimer.params = { puppet = p, id = p.id }
		
		params = { spawnPos = {} }
		params.spawnPos.x, params.spawnPos.y = display.actualContentWidth / 2, display.actualContentHeight / 2
		local char = character:create(params)
		local charSpin = timer.performWithDelay(500, spinPuppet, 0)
		charSpin.params = { puppet = char, id = char.id }
		
		--create test directional objects
		
		params = { spawnPos = {} }
		params.spawnPos.x, params.spawnPos.y = display.actualContentWidth / 2, display.actualContentHeight / 2
		params.directional = true
		params.width, params.height = 64, 64
		--params.name = "default_directional"
		for i = 1, #directions do
			params.spawnPos.x = 200 + i*64
			local obj = gameObj:create(params)
			obj:setMoveDirection(directions[i])
		end

	end

	
	

	return game