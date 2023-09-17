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
	local mapgen = require("lib.map.generator")
	local mapIO = require("lib.map.fileio")
	local cam = require("lib.camera")
	local hud = require("lib.game.hud")
	--[[
	local gameObj = require("lib.game.entity.game_object")
	local entity = require("lib.entity")
	]]
	local entity = require("lib.game.entity")
	local game = require("lib.game")

	--create scene
	local scene = composer.newScene()
	local sceneGroup

	local generatingMap = false

	
	local function loadMap(fName, isResource)
		if map:loadMap(fName, isResource) then
			--cam:moveToPoint(map.worldWidth / 2, map.worldHeight / 2)
			cam:moveToPoint(map.spawnPoint.x, map.spawnPoint.y)
			map:refreshCamTiles()
			map:createDecals()
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
			map:cameraZoom()
		end

		local zoomTimer = timer.performWithDelay( 1, doZoom, -1 )
		cam:adjustZoom(zoomDir, zoomTimer) --updates the zoom value and bounds of camera
	end

	local function generateGameMap()
		generatingMap = true
		local function tilesComplete() --called when tiles have finished creating
			local function genFuncComplete() --called when tile gen function has finished
				print("gen function finished")
				--
				mapgen:generateEnemies()
				---save map to file
				mapIO.save(mapgen:getSaveParams(), "game_level")
				--clear the generated map
				mapgen:deleteMap()
				--load the map
				loadMap("game_level", false)
		
				game:beginPlay() --spawns character and sets camera to follow

				generatingMap = false
			end
			print("tile generation finished")
			mapgen:runGenFunc(genFuncComplete)
		end
		mapgen:startTileGen(tilesComplete)
	end


	local function firstFrame()

		debug.init(sceneGroup)
		mouse.init()
		mouse.registerMouseScrollListener(zoomMap)
		key.init()
		map:init(sceneGroup, cam, game)
		mapgen:init(sceneGroup)
		cam.init()
		hud.init(sceneGroup, map, game)
		game.init(cam, map, key, mouse, hud)
		print("calling game object create from scene")

		entity:init(sceneGroup, map) --passes group to entity which gets stored for all created entities

		game.preloadTextures()

		generateGameMap() --uncomment to generate map on game start

		--comment this block if generating game map
		
		--[[ generatingMap = true
		loadMap("game_level", false)
		game:beginPlay() --spawns character and sets camera to follow
		generatingMap = false
		 ]]-----------------------------------------
		
	end

	local function onFrame()

		if (generatingMap) then
			mapgen:onFrame()
		else
			--[[
			debug.updateText( "entities", #entity.store)
			debug.updateText( "camBoundMin", math.floor(cam.bounds.x1)..","..math.floor(cam.bounds.y1) )
			debug.updateText( "camBoundMax", math.floor(cam.bounds.x2)..","..math.floor(cam.bounds.y2) )
			debug.updateText( "charWorldPos", game.char.x..","..game.char.y )
			-]]
			game:onFrame()
		end
		
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