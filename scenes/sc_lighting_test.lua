	-----------------------------------------------------------------------------------------
	--
	-- FILE NAME.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d
	local composer = require("composer")
	local physics = require("physics")
	local mouse = require("lib.input.mouse_input")

	--common modules
	local util = require("lib.global.utilities")

	--create scene
	local scene = composer.newScene()

	local sceneGroup = display.newGroup( )


	local function onMouseClick(x, y)
		print("set light location to "..x, y)
	end


	local function firstFrame()
		mouse.registerClickListener(onMouseClick)
		local tileGroup = display.newGroup()
		sceneGroup:insert(tileGroup)
		local tileSize = 100
		local tileCount = {x = math.ceil(display.actualContentWidth/tileSize), y = math.ceil(display.actualContentHeight/tileSize)}
		local tileStore = {}
		for row = 1, tileCount.y do
			for col = 1, tileCount.x do
				local tile = display.newRect( (col-1) * tileSize, (row-1) * tileSize, tileSize, tileSize )
				util.zeroAnchors(tile)
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
				if row == 1 then tileStore[col] = {} end
				tileStore[col][row] = tile
			end
		end
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