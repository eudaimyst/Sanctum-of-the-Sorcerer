	-----------------------------------------------------------------------------------------
	--
	-- Level_editor2.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")
	local easing = require("lib.corona.easing")
	local json = require("json")

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local editor = require("lib.editor")
	local map = require("lib.map")
	local mouse = require("lib.input.mouse_input")
	local key = require("lib.input.key_input")
	local cam = require("lib.camera")
	local debug = require("lib.debug")

	--create scene
	local scene = composer.newScene()
	local sceneGroup

	local camDebugRect --holds rect to visualise camera bounds

	local function loadMap()
		print("load map pressed")
		if map:loadMap("level1", true) then
			--cam:moveToPoint(map.worldWidth / 2, map.worldHeight / 2)
			map:updateTilesPos()
			cam:moveToPoint(map.worldWidth / 2, map.worldHeight / 2)
			map:refreshCamTiles()
			map.showTiles(cam.screenTiles)
		end
	end

	local function saveMap()
		print("save map pressed")
		--map:saveMap()
	end

	local function initCamDebug()
		if map:clear() then --completely remove the current map
			local debugTileSize = 10
			local debugScale = map.params.tileSize / debugTileSize
			cam.mode.debugScale, cam.mode.debugTileSize = debugScale, debugTileSize --stores values in cam
			print("init cam debug")

			map:createMapTiles()
			map.showTiles(map.tileStore.indexedTiles)

			cam.debugRect = display.newRect(sceneGroup, 0, 0, 0, 0)
			util.zeroAnchors(cam.debugRect)
			cam.debugRect:setFillColor(1, 1, 1, 1)

			function cam.debugRect:updatePos() --called from movemap when camDebugMode is enabled
				local cb = cam.mode.scaledBounds --readability
				--moves the rect to the scaled cam bounds
				self.x, self.y, self.width, self.height = cb.x1, cb.y1, cb.x2 - cb.x1, cb.y2 - cb.y1
			end
			cam.debugRect:updatePos()
		end
	end

	local function endCamDebug()
		if (map:clear()) then
			print("end cam debug")
			cam.debugRect:removeSelf()
			cam.debugRect = nil
			map:createMapTiles()
			map:updateTilesPos()
		end
	end

	local function  toggleDebugCam() --function used to debug camera movement on the map tiles --called by key input
		if (cam.mode == cam.modes.debug) then
			cam.mode = cam.modes.free
			endCamDebug()
		else
			cam.mode = cam.modes.debug
			initCamDebug()
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

	local function moveMap(direction) --called by keyinput lib
		--print("moveMap called")

		if (#map.tileStore.indexedTiles > 0) then
			debug.updateText( "camBoundMin", math.floor(cam.bounds.x1)..","..math.floor(cam.bounds.y1) )
			debug.updateText( "camBoundMax", math.floor(cam.bounds.x2)..","..math.floor(cam.bounds.y2) )
			debug.updateText( "#camTiles", #cam.screenTiles )
			cam:directionalMove(direction) --call function to update cam co-ords
			map:cameraMove(direction)
		else
			print("no map to move")
		end
	end

	local function createWindows()

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


	end

	local function firstFrame(sceneGroup)

		debug.init(sceneGroup)
		mouse.init() -- registers the mouse on frame event
		mouse.registerMouseScrollListener(zoomMap)
		key.init()
		key.registerMoveListener(moveMap)
		key.registerDebugCamListener(toggleDebugCam)
		map:init(sceneGroup, cam)
		cam.init()

		createWindows()
		
	end

	local function onFrame()
		--print(cam.bounds.x1..","..cam.bounds.y1.."||"..cam.bounds.x2..","..cam.bounds.y2)
		key.onFrame() --calls checks for movement
	end

	function scene:create( event )
		display.setDefault( "background", .09, .09, .09 )
		-- Called when scene's view does not exist.

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

			print("scene loaded")

			firstFrame(sceneGroup)

			--add listerer for every frame to process all game logic
			Runtime:addEventListener( "enterFrame", onFrame )
		end
	end

	function scene:hide( event )
		sceneGroup = self.view

		local phase = event.phase

		if event.phase == "will" then
			-- Called when scene is on screen and is about to move off screen

		elseif phase == "did" then
			-- Called when scene is now off screen
		end

	end

	function scene:destroy( event )

		-- Called prior to removal of scene's "view" (sceneGroup)
		
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