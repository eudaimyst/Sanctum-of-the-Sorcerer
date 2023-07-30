	-----------------------------------------------------------------------------------------
	--
	-- Level_editor2.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")
	local easing = require("lib.corona.easing")

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local editor = require("lib.editor")
	local map = require("lib.map")
	local mouse = require("lib.input.mouse_input")
	local key = require("lib.input.key_input")
	local cam = require("lib.camera")

	--create scene
	local scene = composer.newScene()
	local sceneGroup
	
	local function loadMap()
		print("load map pressed")
		map:loadMap()
	end

	local function saveMap()
		print("save map pressed")
		--map:saveMap()
	end

	local function firstFrame()

		local function updateFilename()
		end

		local t = editor.elementTypes --readability
		local editWindowSections = { --sections in the settings window that hold elements, uses index for ordering in ui
			[1] = { label = "Save / Load", collapsable = true, elements = {
					[1] = { {param = "filename", label = "File Name:", eType = t.inputField, inputListener = updateFilename } },
					[2] = { { label = "io", eType = t.toggleButtons, amount = 2, texts = { "save", "load" }, clickListener = {saveMap, loadMap} } }
			} },
		}
		local editWindowParams = {
			x = 20, y = 20, width = 300, height = 400, label = "Settings", closable = false, movable = true,
			sceneGroup = sceneGroup, sectionData = editWindowSections, object = map
		}
		local editWindow = editor.createWindow( editWindowParams, sceneGroup )

		mouse.init() -- registers the mouse on frame event
		key.init()
		cam.init(map)
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

		sceneGroup = self.view
		-- We need physics started to add bodies
		physics.start()
		physics.setGravity( 0, 0 )

	end

	function scene:show( event )
		sceneGroup = self.view
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
		sceneGroup = self.view

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
		sceneGroup = self.view

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