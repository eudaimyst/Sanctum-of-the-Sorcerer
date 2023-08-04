	-----------------------------------------------------------------------------------------
	--
	-- sc_game.lua - game scene
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")

	--create scene
	local scene = composer.newScene()

	local group = display.newGroup( )

	local function firstFrame()

	end

	local function onFrame()

	end

	function scene:create( event )
		display.setDefault( "background", .09, .09, .09 )
		-- Called when scene's view does not exist.
		--
		-- INSERT code here to initialize scene
		-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.
		-- create scene group 

		local sceneGroup = self.view
		-- We need physics started to add bodies
		physics.start()
		physics.setGravity( 0, 0 )

	end

	function scene:show( event )
		local sceneGroup = self.view
		local phase = event.phase

		if phase == "will" then
			-- Called when scene is still off screen and is about to move on screen
		elseif phase == "did" then
			-- Called when scene is now on screen
			--
			-- INSERT code here to make scene come alive
			-- e.g. start timers, begin animation, play audio, etc.

			print("scene loaded")

			firstFrame()

			--add listerer for every frame to process all game logic
			Runtime:addEventListener( "enterFrame", onFrame )
		end
	end

	function scene:hide( event )
		local sceneGroup = self.view

		local phase = event.phase

		if event.phase == "will" then
			-- Called when scene is on screen and is about to move off screen
			--
			-- INSERT code here to pause scene
			-- e.g. stop timers, stop animation, unload sounds, etc.)
		elseif phase == "did" then
			-- Called when scene is now off screen
		end

	end

	function scene:destroy( event )

		-- Called prior to removal of scene's "view" (sceneGroup)
		--
		-- INSERT code here to cleanup scene
		-- e.g. remove display objects, remove touch listeners, save state, etc.
		local sceneGroup = self.view

		package.loaded[physics] = nil
		physics = nil
	end

	---------------------------------------------------------------------------------

	-- Listener setup
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )

	-----------------------------------------------------------------------------------------

	return scene