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



	local camDebugMode = false
	local camTiles = {}
	local boundaryTiles = {}
	

	local function refreshCamTiles(bounds, tileSize) --gets and updates all tiles within cam bounds, default bounds/spacing are cam bounds/tilesize unscaled

		local cb = bounds or cam.bounds
		local s = tileSize or map.tileSize * 2	--buffer size
		camTiles, boundaryTiles = map:getTilesBetweenWorldBounds( cb.x1-s, cb.y1-s, cb.x2+s, cb.y2+s ) --get cam tiles within cam borders
		if (camDebugMode == false) then
			for _, tile in pairs(camTiles) do
				if (tile.rect) then
					tile:updateRectPos() --move tiles the opposite direction camera is moving 
				else
					tile:createRect()
				end
			end
		end
	end
	
	local function loadMap()
		print("load map pressed")
		map:loadMap()
		--cam:moveToPoint(map.worldWidth / 2, map.worldHeight / 2)
		map:updateTilesPos()
		cam:moveToPoint(map.worldWidth / 2, map.worldHeight / 2)
		refreshCamTiles()
	end

	local function saveMap()
		print("save map pressed")
		--map:saveMap()
	end

	local function initCamDebug()
		if (map:clear()) then
			local camDebugTileSize = 10
			local camDebugScale = map.params.tileSize / camDebugTileSize
			print("init cam debug")
			map:createMapTiles(nil, camDebugTileSize, true)
			for _, tile in ipairs(map.tileStore.indexedTiles) do
				tile:createRect()
			end

			camDebugRect = display.newRect(sceneGroup, 0, 0, 1, 1)
			util.zeroAnchors(camDebugRect)
			camDebugRect:setFillColor(1, 1, 1, 1)
			camDebugRect.tileSize = camDebugTileSize
			camDebugRect.scale = camDebugScale

			function camDebugRect:updatePos() --called from movemap when camDebugMode is enabled
				local cb = cam.bounds
				camDebugRect.scaledCB = {}
				local scaledCB = camDebugRect.scaledCB
				for k, v in pairs(cb) do --scales the cam bounds to the camDebugTileSize
					scaledCB[k] = v / camDebugScale
				end
				--moves the rect to the scaled cam bounds
				camDebugRect.x, camDebugRect.y, camDebugRect.width, camDebugRect.height = scaledCB.x1, scaledCB.y1, scaledCB.x2 - scaledCB.x1, scaledCB.y2 - scaledCB.y1
			end
			camDebugRect:updatePos()
		end
	end

	local function endCamDebug()
		if (map:clear()) then
			print("end cam debug")
			camDebugRect:removeSelf()
			map:createMapTiles(nil, nil, false)
			map:updateTilesPos()
		end
	end

	local function  toggleDebugCam() --function used to debug camera movement on the map tiles --called by key input
		if (camDebugMode == false) then
			camDebugMode = true
			initCamDebug()
			
		else
			camDebugMode = false
			endCamDebug()
		end
	end
	

	local function hideTiles(tileList)
		for i = 1, #tileList do
			local tile = tileList[i]
			tile:destroyRect()
		end
	end

	local function  showTiles(tileList)
		for i = 1, #tileList do
			local tile = tileList[i]
			tile:createRect()
		end
	end

	local function resetTiles(tileList)
		for i = 1, #tileList do
			local tile = tileList[i]
			tile.rect:setFillColor(1)
		end
	end

	local function zoomMap(scrollValue)
		local zoomSpeed = .05
		local zoomIn, zoomOut = 1, 2
		local zoomDir = 0
		if (scrollValue > 0) then
			zoomDir = zoomIn
		elseif (scrollValue < 0) then
			zoomDir = zoomOut
		end
		cam:adjustZoom(zoomDir, zoomSpeed) --updates the zoom value and bounds of camera
		
		if (camDebugMode) then --do not scale tiles if in cam debug mode
			camDebugRect:updatePos() --updates debug rect to new cam bounds
			refreshCamTiles(camDebugRect.scaledCB, camDebugRect.tileSize) --updates cam tiles to new cam bounds

			--print(#camTiles.." found between bounds: "..cam.bounds.x1..", "..cam.bounds.y1.." AND "..cam.bounds.x2..", "..cam.bounds.y2)
			if (zoomDir == zoomOut) then
				for _, tileList in pairs(boundaryTiles) do --iterate through directions in boundary tiles
					resetTiles(tileList) --reset tiles to default colour
				end
			elseif (zoomDir == zoomIn) then
				for _, tileList in pairs(boundaryTiles) do --set color to red for tiles on cam bound edges
					for i = 1, #tileList do
						local tile = tileList[i]
						tile.rect:setFillColor(1, .5, .5)
					end
				end
			end
			for i = 1, #camTiles do --set color to green for tiles within cam bounds
				local tile = camTiles[i]
				tile.rect:setFillColor(.5, 1, .5)
			end 
		else --cam debug not on
			refreshCamTiles()
		end
	end

	local function moveMap(direction) --called by keyinput lib
		--print("moveMap called")

		if (#map.tileStore.indexedTiles > 0) then
			
			debug.updateText( "camBoundMin", math.floor(cam.bounds.x1)..","..math.floor(cam.bounds.y1) )
			debug.updateText( "camBoundMax", math.floor(cam.bounds.x2)..","..math.floor(cam.bounds.y2) )
			debug.updateText( "#camTiles", #camTiles )
      
			cam:directionalMove(direction) --call function to update cam co-ords
			if (camDebugMode) then --do not translate tiles if in cam debug mode
				camDebugRect:updatePos()
				refreshCamTiles(camDebugRect.scaledCB, camDebugRect.tileSize) --updates cam tiles to new cam bounds
				local cb = camDebugRect.scaledCB
				local camTiles, boundaryTiles = map:getTilesBetweenWorldBounds(cb.x1, cb.y1, cb.x2, cb.y2) --get cam tiles within scaled cam borders
				--print(#camTiles.." found between bounds: "..cam.bounds.x1..", "..cam.bounds.y1.." AND "..cam.bounds.x2..", "..cam.bounds.y2)
				
				if direction.y > 0 then
					resetTiles(boundaryTiles.up)
				elseif direction.y < 0 then
					resetTiles(boundaryTiles.down)
				end
				if direction.x > 0 then
					resetTiles(boundaryTiles.left)
				elseif direction.x < 0 then
					resetTiles(boundaryTiles.right)
				end
				for i = 1, #camTiles do --set color to green for tiles within cam bounds
					local tile = camTiles[i]
					tile.rect:setFillColor(.5, 1, .5)
				end 
				for _, tileList in pairs(boundaryTiles) do --set color to red for tiles on cam bound edges
					for i = 1, #tileList do
						local tile = tileList[i]
						tile.rect:setFillColor(1, .5, .5)
					end
				end
			else --cam debug not on
				
				refreshCamTiles()
				
				if direction.y > 0 then
					hideTiles(boundaryTiles.up)
					showTiles(boundaryTiles.down)
				elseif direction.y < 0 then
					hideTiles(boundaryTiles.down)
					showTiles(boundaryTiles.up)
				end
				if direction.x > 0 then
					hideTiles(boundaryTiles.left)
					showTiles(boundaryTiles.right)
				elseif direction.x < 0 then
					hideTiles(boundaryTiles.right)
					showTiles(boundaryTiles.left)
				end 
			end
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