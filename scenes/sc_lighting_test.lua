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
	local mrad = math.rad
	local mcos, msin = math.cos, math.sin
	local msqrt = math.sqrt

	--common modules
	local util = require("lib.global.utilities")
	local gv = require("lib.global.variables")

	--create scene
	local scene = composer.newScene()

	local sceneGroup = display.newGroup( )

	
	local tileSize = 100
	local tileStore = {}
	local light = nil
	local moveSpeed = .5
	local moveNormal = nil

	local startPos, finishPos = nil, nil

	local function getTileAtPoint(x, y)
		local tx, ty = mfloor(x/tileSize)+1, mfloor(y/tileSize)+1
		print("click tcord:", tx, ty)
		return tileStore[tx][ty]
	end

	local function updateTileLights()
		for col = 1, #tileStore do
			for row = 1, #tileStore[col] do
				local tile = tileStore[col][row]
				--print(col, row, tile.lightValue)
				tile:calcLightValue()
				tile:setFillColor(tile.lightValue)
				tile:setStrokeColor(tile.lightValue)
			end
		end
	end

	local function createLight(_x, _y)
		local l = {x = _x or 0, y = _y or 0, radius = 800, intensity = 1, active = false, rayCount = 12, rays = nil}

		function l:setPos(_x, _y)
			self.x, self.y = _x, _y
			if self.rays then
				self:updateRays()
			else
				self:makeRays()
			end
		end

		function l:updateRays()
			local rayCount = self.rayCount
			for i = 1, rayCount do
				local line = self.rays[i].line
				line.x, line.y = self.x, self.y
			end
		end

		function l:destroySelf()
			local rayCount = self.rayCount
			for i = 1, rayCount do
				local ray = self.rays[i]
				ray.line:removeSelf()
				ray = nil
				self.rays[i] = nil
			end
			self.rays = nil
			self = nil
		end

		function l:makeRays()
			local d = self.radius --light ray distance
			local rays = {} --stores the rays
			local rayCount = self.rayCount
			for i = 1, rayCount do
				local angle = 360 / rayCount * i
				local r = mrad(angle) --radians
				local x, y = d * mcos(r), d * msin(r)
				local ray = { startPos = {x = self.x, y = self.y}, finishPos = {x = self.x + x, y = self.y + y}, delta = {x = x, y = y } }
				print("ray", i, "start", ray.startPos.x, ray.startPos.y, "finish", ray.finishPos.x, ray.finishPos.y)
				--x = dist cos angle, y = dist sin angle
				local line = display.newLine( ray.startPos.x, ray.startPos.y, ray.finishPos.x, ray.finishPos.y )
				line.isVisible = true
				line.strokeWidth = 2
				ray.line = line
				rays[i] = ray
			end
			self.rays = rays
		end
		l:makeRays()
		return l
	end

	local function createTile(col, row)
		local x, y = (col-1) * tileSize, (row-1) * tileSize
		local tile = display.newRect( x + 2, y + 2, tileSize - 2, tileSize - 2 )
		tile.x, tile.y = x, y
		tile.mid = {x = x + tileSize / 2, y = y + tileSize / 2}
		tile.lightValue = .3
		util.zeroAnchors(tile)
		tile:setStrokeColor(tile.lightValue)
		tile.strokeWidth = 4
		function tile:calcLightValue()
			if light then
				local dist = util.getDistance(light.x, light.y, self.mid.x, self.mid.y)
				local rad = light.radius + tileSize
				tile.lightValue = light.intensity * ( ( 1 - msqrt(dist / rad) ) * light.intensity ) 
			end
		end
		return tile
	end

	local function onMouseClick(x, y)
		print("set light location to "..x, y)
		
		if startPos == nil and finishPos == nil then
			startPos = {x = x, y = y}
			light = createLight(x, y)
		elseif startPos and finishPos == nil then
			finishPos = {x = x, y = y}
		elseif startPos and finishPos then
			startPos = nil
		elseif startPos == nil and finishPos then
			startPos = nil
			finishPos = nil
			moveNormal = nil
			light:destroySelf()
			updateTileLights()
		end

		updateTileLights()
		local tile = getTileAtPoint(x, y)
		tile:setStrokeColor(1, 1, 0)
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
		if startPos and finishPos then
			if moveNormal == nil then
				moveNormal = util.normalizeXY({ x = finishPos.x - startPos.x, y = finishPos.y - startPos.y })
			end
			local nx = light.x + moveNormal.x * gv.frame.dt * moveSpeed
			local ny = light.y + moveNormal.y * gv.frame.dt * moveSpeed
			light:setPos(nx, ny)
			updateTileLights()
			if util.compareFuzzy(light, finishPos) then
				startPos = nil
			end
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