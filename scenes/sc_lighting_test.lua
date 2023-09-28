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

	--common modules
	local util = require("lib.global.utilities")
	local gv = require("lib.global.variables")
	local mouse = require("lib.input.old_mouse_input")

	local mfloor = math.floor
	local mceil = math.floor

	--create scene
	local scene = composer.newScene()

	local sceneGroup = display.newGroup( )

	
	local tileSize = 100
	local tileStore = {}
	local light = nil
	local moveSpeed = .5
	local moveNormal = nil

	local lightingUpdateRate = 50 --ms
	local lightingUpdateTimer = 0

	local blockerUpdateRate = 200 --ms
	local blockerUpdateTimer = 0

	local startPos, finishPos = nil, nil

	local function getTileAtPoint(x, y)
		local tx, ty = mfloor(x/tileSize)+1, mfloor(y/tileSize)+1
		--print("click tcord:", tx, ty)
		if tileStore[tx] then
			if tileStore[tx][ty] then
				return tileStore[tx][ty]
			else
				return nil
			end
		else
			return nil
		end
	end

	local function updateTileLights(updateBlockers)
		for col = 1, #tileStore do
			for row = 1, #tileStore[col] do
				local tile = tileStore[col][row]
				--print(col, row, tile.lightValue)
				if light then
					if tile.col == false then
						tile:calcLightValue(updateBlockers)
						tile:updateColor()
					end
				end
				tile:updateColor()
			end
		end
	end

	local function createLight(_x, _y)
		local l = {x = _x or 0, y = _y or 0, radius = 800, intensity = 2, exponent = .1, active = false, path = nil}
		function l:setPos(_x, _y)
			self.x, self.y = _x, _y
		end
		function l:destroySelf()
			self = nil
			light = nil
		end
		return l
	end
	
	--recycled vars for light calc
	local _midx, _midy, _dist
	local _rayStartX, rayStartY
	local _rayEndX, rayEndY
	local _rayDeltaX, _rayDeltaY
	local _rayNormalX, _rayNormalY
	local _raySegmentX, _raySegmentY, _segmentLength, _segments
	local _checkPosX, _checkPosY, _checkTile
	local _rad, _mod
	local function createTile(col, row)
		local x, y = (col-1) * tileSize, (row-1) * tileSize
		local tile = display.newRect( x + 2, y + 2, tileSize - 2, tileSize - 2 )
		tile.x, tile.y = x, y
		tile.midX, tile.midY = x + tileSize / 2, y + tileSize / 2
		tile.lightValue = .3
		tile.lightBlockers = 0
		tile.col = false
		util.zeroAnchors(tile)
		tile:setStrokeColor(tile.lightValue)
		tile.strokeWidth = 4

		function tile:calcLightValue(updateBlockers)
			if light then
				_midx, _midy = self.midX, self.midY
				_dist = util.getDistance(light.x, light.y, _midx, _midy)
				if _dist > light.radius then
					self.lightValue = 0
				else
					if updateBlockers then
						print("updating blockers")
						self.lightBlockers = 0
						_rayStartX, rayStartY = light.x, light.y
						_rayEndX, rayEndY = _midx, _midy
						_rayDeltaX, _rayDeltaY = _rayEndX - _rayStartX, rayEndY - rayStartY
						_rayNormalX, _rayNormalY = util.normalizeXY(_rayDeltaX, _rayDeltaY)
						_raySegmentX, _raySegmentY = _rayNormalX * tileSize/2, _rayNormalY * tileSize/4
						_segmentLength = util.getDistance(0, 0, _raySegmentX, _raySegmentY)
						_segments = mceil(_dist / _segmentLength)
						for i = 1, _segments do
							_checkPosX, _checkPosY = _rayStartX + _rayNormalX * _segmentLength * i, rayStartY + _rayNormalY * _segmentLength * i
							_checkTile = getTileAtPoint(_checkPosX, _checkPosY)
							if _checkTile then
								if _checkTile.col == true then
									--found a light blocker
									self.lightBlockers = self.lightBlockers + 1
								end
							end
						end
					end
					_rad = light.radius + tileSize
					_mod = (2 - self.lightBlockers) / 2
					self.lightValue = light.intensity * ( ( 1 - (_dist / _rad) ^ light.exponent ) * light.intensity * _mod )
				end
			end
		end

		function tile:updateColor()
			if self.col then
				self:setFillColor(1, 0, 0)
				self:setStrokeColor(1, 0, 0)
			else
				self:calcLightValue()
				if (light) then
					self:setFillColor(self.lightValue)
					self:setStrokeColor(self.lightValue)
				else
					self:setFillColor(.2)
					self:setStrokeColor(.2)
				end
			end
		end

		function tile:toggleCol()
			if self.col == false then
				self.col = true
			else
				self.col = false
			end
			self:updateColor()
		end
		return tile
	end

	local function onMouseClick(x, y)
		print("set light location to ", x, y)
		local tile = getTileAtPoint(x, y)
		tile:setStrokeColor(1, 1, 0)
		if startPos == nil and finishPos == nil then --first click
			startPos = {x = x, y = y}
			light = createLight(x, y)
			updateTileLights(true)
		elseif startPos and finishPos == nil then --second click
			finishPos = {x = x, y = y}
			if light then
				light.path = display.newLine(startPos.x,startPos.y,finishPos.x,finishPos.y) 
				light.path:setStrokeColor(0, 1, 0)
			end
		elseif startPos and finishPos then --light is moving third click
			startPos = nil
		elseif startPos == nil and finishPos then --light not moving third or fourth click
			light.path:removeSelf()
			startPos = nil
			finishPos = nil
			moveNormal = nil
			if light then
				light.path = nil
				light:destroySelf()
			end
			updateTileLights(true)
		end
	end

	local function onMouseRightClick(x, y)
		print("right click at ", x, y)
		local tile = getTileAtPoint(x, y)
		tile:toggleCol()
		updateTileLights(true)
	end

	local function firstFrame()
		mouse.registerClickListener(onMouseClick)
		mouse.registerRightClickListener(onMouseRightClick)
		local tileGroup = display.newGroup()
		sceneGroup:insert(tileGroup)
		local tileCount = {x = math.ceil(display.contentWidth/tileSize), y = math.ceil(display.contentHeight/tileSize)}
		for row = 1, tileCount.y do
			for col = 1, tileCount.x do
				if row == 1 then tileStore[col] = {} end
				tileStore[col][row] = createTile(col, row)
			end
		end
		updateTileLights(nil)
		local instructions = display.newText( {
			text = "left click = create light, move light, stop movement, destroy light\nright click = toggle wall tiles",
			font = native.systemFont,   
			fontSize = 18,
			align = "left"  -- Alignment parameter
		} );
		util.zeroAnchors(instructions)
	end

	local function onFrame()
		if startPos and finishPos then
			if moveNormal == nil then
				moveNormal = {x = nil, y = nil}
				moveNormal.x, moveNormal.y = util.normalizeXY(finishPos.x - startPos.x, finishPos.y - startPos.y)
			end
			local nx = light.x + moveNormal.x * gv.frame.dt * moveSpeed
			local ny = light.y + moveNormal.y * gv.frame.dt * moveSpeed
			light:setPos(nx, ny)
			lightingUpdateTimer = lightingUpdateTimer + gv.frame.dt
			blockerUpdateTimer = blockerUpdateTimer + gv.frame.dt
			if lightingUpdateTimer > lightingUpdateRate then
				lightingUpdateTimer = 0
				if blockerUpdateTimer > blockerUpdateRate then
					blockerUpdateTimer = 0
					updateTileLights(true)
				else
					updateTileLights(nil)
				end
			end
			if util.compareFuzzy(light.x, light.y, finishPos.x, finishPos.y) then
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