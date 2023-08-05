	-----------------------------------------------------------------------------------------
	--
	-- sc_game.lua - game scene 	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local debug = require("lib.debug")
	local mouse = require("lib.input.mouse_input")
	local key = require("lib.input.key_input")
	local map = require("lib.map")
	local cam = require("lib.camera")
	--[[
	local gameObj = require("lib.entity.game_object")
	local entity = require("lib.entity")
	]]
	local entity = require("lib.entity")
	local game = require("lib.game")

	--create scene
	local scene = composer.newScene()
	local sceneGroup

	local function  toggleDebugCam() --function used to debug camera movement on the map tiles --called by key input
		if (cam.mode == cam.modes.debug) then
			cam.mode = cam.modes.free
			--endCamDebug() TODO: move these to cam library
		else
			cam.mode = cam.modes.debug
			--initCamDebug()
		end
	end
	local function zoomMap(scrollValue)
		local zoomIn, zoomOut = 1, 2
		local zoomDir = 0
		if (scrollValue > 0) then
			zoomDir = zoomOut
		elseif (scrollValue < 0) then
			zoomDir = zoomIn
		end
		local function doZoom()
			print("do")
			map:cameraZoom(zoomDir)
		end
		local zoomTimer = timer.performWithDelay( 1, doZoom, -1 ) --starts a timer once bg has faded in
		cam:adjustZoom(zoomDir, zoomTimer) --updates the zoom value and bounds of camera
	end

	local function moveInput(direction)
	end

	local function firstFrame()

		debug.init(sceneGroup)
		mouse.init() -- registers the mouse on frame event
		mouse.registerMouseScrollListener(zoomMap)
		key.init()
		key.registerMoveListener(moveInput)
		key.registerDebugCamListener(toggleDebugCam)
		map:init(sceneGroup, cam)
		cam.init()
		print("calling game object create from scene")

		entity:setGroup(sceneGroup) --passes group to entity which gets stored for all created entities
		
		game.firstFrame()
		--gameObj:create(sceneGroup)
	end

	local function onFrame()
	end

	function scene:create( event ) -- Called when scene's view does not exist.
		sceneGroup = self.view
		display.setDefault( "background", .09, .09, .09 )
		-- We need physics started to add bodies
		physics.start()
		physics.setGravity( 0, 0 )
	end

	function scene:show( event )

		sceneGroup = self.view
		local phase = event.phase

		if phase == "will" then -- Called when scene is still off screen and is about to move on screen
			
		elseif phase == "did" then -- Called when scene is now on screen
			print("scene loaded")
			firstFrame()

			
			Runtime:addEventListener( "enterFrame", onFrame ) --listerer for every frame
		end
	end

	function scene:hide( event )

		sceneGroup = self.view
		local phase = event.phase

		if event.phase == "will" then -- Called when scene is on screen and is about to move off screen
			
		elseif phase == "did" then -- Called when scene is now off screen
			
		end
	end

	function scene:destroy( event )
		-- Called prior to removal of scene's "view" (sceneGroup)

		sceneGroup = self.view

		package.loaded[physics] = nil; physics = nil
	end

	---------------------------------------------------------------------------------
	-- Scene Listener setup
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )
	-----------------------------------------------------------------------------------------

	return scene