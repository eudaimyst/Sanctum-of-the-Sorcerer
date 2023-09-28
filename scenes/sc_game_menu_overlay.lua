	-----------------------------------------------------------------------------------------
	--
	-- sc_game_menu_overlay.lua
	--
	-- the menu shown in-game
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local lang = require("lib.global.locale")
	local mouse = require("lib.input.mouse_input")
	local buttons = require("lib.ui.buttons")
	local windows = require("lib.ui.windows")
	--test change
	--create scene
	local scene = composer.newScene()
	local buttonSpacing = 68
	local buttonOffsetY = 60
	
	local sceneGroup
	local halfScreenX, halfScreenY = display.contentWidth / 2, display.contentHeight / 2

	local leaveGameListener, returnToGameListener --called when the player chooses to leave the game, passed from the game scene through params
	local buttonStore = {}

	local function onReturnToGame()
		returnToGameListener()
	end

	local function onOptions()
		local function optionsClosedListener()
			composer.showOverlay( "scenes.sc_game_menu_overlay", { params = {leaveGameListener = leaveGameListener, returnToGameListener = returnToGameListener} })
			mouse:init()
			for i =1, #buttonStore do
				mouse:registerObject(buttonStore[i])
			end
		end
		mouse:deinit()
		composer.showOverlay( "scenes.sc_options_overlay", { params = {closedListener = optionsClosedListener} } )
	end

	local function onLeave()
		leaveGameListener()
	end

	local function onQuit()
		native.requestExit()
	end

	
	local buttonData = {
		{ label = lang.get("options"), borderSize = 8, width = 200, height = 40, theme = "fantasy", listener = onOptions, position = 1},
		{ label = lang.get("leave"), borderSize = 8, width = 200, height = 40, theme = "fantasy", listener = onLeave, position = 2},
		{ label = lang.get("quit"), borderSize = 8, width = 200, height = 40, theme = "fantasy", listener = onQuit, position = 3},
		{ label = lang.get("returnToGame"), borderSize = 8, width = 200, height = 40, theme = "fantasy", listener = onReturnToGame, position = 4},
	}

	local function firstFrame()
		local window = windows:create({ title = lang.get("gamePausedMenuTitle"), width = 300, height = 600, closeable = false })
		sceneGroup:insert(window)
		for i = 1, #buttonData do
			local data = buttonData[i]
			local button = buttons:create( data )
			sceneGroup:insert(button)
			button.x = window.x
			button.y = window.y + (buttonSpacing * data.position) - window.height/2 + buttonOffsetY
			buttonStore[i] = button
		end
		mouse:init()
	end

	local function onFrame()

	end

	function scene:create( event ) -- Called when scene's view does not exist.
		leaveGameListener = event.params.leaveGameListener
		returnToGameListener = event.params.returnToGameListener
		sceneGroup = self.view
		display.setDefault( "background", .09, .09, .09 )
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
	end

	---------------------------------------------------------------------------------
	-- Scene Listener setup
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )
	-----------------------------------------------------------------------------------------

	return scene