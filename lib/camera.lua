	-----------------------------------------------------------------------------------------
	--
	-- camera.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gv = require("lib.global.variables")
	local easing = require("lib.corona.easing")

	-- Define module
	local cam = {}
	local halfScreenWidth, halfScreenHeight = display.contentWidth / 2, display.contentHeight / 2

	cam.modes = {
		follow = { target = nil },
		free = { },
		debug = { tileSize = 10, scale = 0, scaledBounds = {x1 = 0, y1 = 0, x2 = 0, y2 = 0} }
	}
	cam.mode = cam.modes.free
	cam.bounds = {x1 = 0, y1 = 0, x2 = display.actualContentWidth, y2 = display.actualContentHeight}
	cam.midPoint = {x = halfScreenWidth, y = halfScreenHeight}
	cam.delta = {x = 0, y = 0}
	cam.zoom = 1
	cam.moveSpeed = 1
	cam.screenTiles = {} --holds references to all tiles displayed on screen within bounds
	cam.boundaryTiles = {} --holds references to tiles that are on the boundary of the screen

	function cam:updateBounds()
		self.bounds.x1 = self.midPoint.x - halfScreenWidth / self.zoom
		self.bounds.y1 = self.midPoint.y - halfScreenHeight / self.zoom
		self.bounds.x2 = self.midPoint.x + halfScreenWidth / self.zoom
		self.bounds.y2 = self.midPoint.y + halfScreenHeight / self.zoom
		if cam.mode == cam.modes.debug then
			for k, v in pairs(self.bounds) do --scales the cam bounds to the camDebugTileSize
				self.mode.scaledBounds[k] = v / self.mode.debugScale
			end
		end
	end

	function cam:adjustZoom(zoomDir, zoomSpeed, zoomTime) --zoomDir is a boolean, 1 = zoom in, 2 = zoom out, speed is a float
		local z
		local function cancelZoomTimer()
			timer.cancel("zoomTimer")
		end
		if (zoomDir == 1) then
			z = zoomSpeed
		elseif (zoomDir == 2) then
			z = -zoomSpeed
		end
		transition.cancel("zoomTimer") --cancel any existing zoomTimer
		transition.to(self, {time = zoomTime, transition = easing.inOutSine, onComplete = cancelZoomTimer(), zoom = self.zoom + z })
		self:updateBounds()
	end

	function cam:moveToPoint(x, y)
		self.midPoint.x = x
		self.midPoint.y = y
		self:updateBounds()
	end

	function cam:directionalMove(direction)
		cam.delta.x, cam.delta.y = direction.x * gv.frame.dt * cam.moveSpeed, direction.y * gv.frame.dt * cam.moveSpeed
		self.midPoint.x = self.midPoint.x + cam.delta.x
		self.midPoint.y = self.midPoint.y + cam.delta.y
		self:updateBounds()
	end

	function cam:setMode(modeStr, target)
		if modeStr == "follow" then
			self.mode = self.modes.follow
			self.target = target
		elseif modeStr == "free" then
			self.mode = self.modes.free
			self.target = nil
		else debug:error("camera.setMode: modeStr not recognised")
		end
	end

	function cam.init()

	end


	return cam