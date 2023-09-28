	-----------------------------------------------------------------------------------------
	--
	-- sc_options_menu.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")

	local lang = require("lib.global.locale")

	local windows = require("lib.ui.windows")

	--create scene
	local scene = composer.newScene()
	local sceneGroup

	local function firstFrame()
		--[[ local background = display.newRect( sceneGroup, gv.screen.halfWidth, gv.screen.halfHeight, 800, 600 )
		background:setFillColor( .09, .09, .09 )
		local optionsFrame = frame:create("fantasy", 8, 800, 600)
		optionsFrame.x, optionsFrame.y = gv.screen.halfWidth, gv.screen.halfHeight ]]
		local optionsWindow = windows:create({ title = lang.get("options"), width = 800, height = 600 })
		sceneGroup:insert(optionsWindow)
		--mouse:registerObject(optionsFrame, mouse.getHighestZ()+1)
	end

	local function onFrame()

	end

	function scene:create( event ) -- Called when scene's view does not exist.
		sceneGroup = self.view
		display.setDefault( "background", .09, .09, .09 )
		print("options menu scene created")
	end

	function scene:show( event )
		sceneGroup = self.view
		local phase = event.phase
		if phase == "will" then -- Called when scene is still off screen and is about to move on screen
			print("options menu scene off screen")
			firstFrame()
		elseif phase == "did" then -- Called when scene is now on screen
			print("options menu scene on screen")
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
	end

	---------------------------------------------------------------------------------
	-- Scene Listener setup
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )
	-----------------------------------------------------------------------------------------

	return scene