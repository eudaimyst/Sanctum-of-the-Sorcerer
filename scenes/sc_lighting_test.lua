	-----------------------------------------------------------------------------------------
	--
	-- FILE NAME.lua
	--
	-----------------------------------------------------------------------------------------

	--[[
	local paint1 = {
		type = "image",
		filename = "content/map/gradient2.png"
	}
	local paint2 = {
		type = "image",
		filename = "content/map/gradient.png"
	}
	paint2.rotation = 90
	local paint = {
		type = "composite",
		paint1 = paint1,
		paint2 = paint2
	}
	paint1.rotation = -90
	tile.fill = paint
	tile.fill.effect = "composite.average"
	]]
	
	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")
	local mouse = require("lib.input.mouse_input")
	local mround = math.round
	local mfloor = math.floor
	local mceil = math.ceil

	--common modules
	local util = require("lib.global.utilities")

	--create scene
	local scene = composer.newScene()

	local sceneGroup = display.newGroup( )


	local light = {x = 0, y = 0, radius = 200}
	
	local tileSize = 100
	local tileStore = {}

	local startPos, finishPos = nil, nil

	local function getTileAtPoint(x, y)
		local tx, ty = mfloor(x/tileSize)+1, mfloor(y/tileSize)+1
		print("click tcord:", tx, ty)
		return tileStore[tx][ty]
	end

	local function getTilesBetweenLine(start, finish)
		
	end

	local function updateTileLights()
		for col = 1, #tileStore do
			for row = 1, #tileStore[col] do
				local tile = tileStore[col][row]
				--print(col, row, tile.lightValue)
				tile:setFillColor(tile.lightValue)
				tile:setStrokeColor(tile.lightValue)
			end
		end
	end

	local function onMouseClick(x, y)
		print("set light location to "..x, y)
		
		if startPos == nil then
			startPos = {x = x, y = y}
		elseif finishPos == nil then
			finishPos = {x = x, y = y}
		end
		updateTileLights()
		local tile = getTileAtPoint(x, y)
		tile:setStrokeColor(1, 1, 0)

	end

	local function createTile(col, row)
		local tile = display.newRect( (col-1) * tileSize + 2, (row-1) * tileSize + 2, tileSize - 2, tileSize - 2 )
		tile.lightValue = .3
		util.zeroAnchors(tile)
		tile:setStrokeColor(tile.lightValue)
		tile.strokeWidth = 4
		return tile
	end

	local function firstFrame()
		mouse.registerClickListener(onMouseClick)
		local tileGroup = display.newGroup()
		sceneGroup:insert(tileGroup)
		local tileCount = {x = math.ceil(display.actualContentWidth/tileSize), y = math.ceil(display.actualContentHeight/tileSize)}
		for row = 1, tileCount.y do
			for col = 1, tileCount.x do
				if row == 1 then tileStore[col] = {} end
				tileStore[col][row] = createTile(col, row)
			end
		end
		updateTileLights()
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
			mouse.init()
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

		local sceneGroup = self.view

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