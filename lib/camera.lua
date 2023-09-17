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
	cam.bounds = {x1 = 0, y1 = 0, x2 = display.contentWidth, y2 = display.contentHeight}
	cam.midPoint = {x = halfScreenWidth, y = halfScreenHeight}
	cam.delta = {x = 0, y = 0}
	cam.zoom = 1
	cam.targetZoom = 1
	cam.zoomSpeed = .05
	cam.zoomTime = 300
	cam.moveSpeed = 1

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
 
	function cam:adjustZoom(zoomDir, zoomTimer) --zoomDir is a boolean, 1 = zoom in, 2 = zoom out, speed is a float
		local function cancelZoomTimer()
			print("cancelling zoom timer")
			cam.zoom = cam.targetZoom
			timer.cancel(zoomTimer)
		end
		if (zoomDir == 1) then
			cam.targetZoom = cam.targetZoom + cam.zoomSpeed
		elseif (zoomDir == 2) then
			cam.targetZoom = cam.targetZoom - cam.zoomSpeed
		end
		local zoomTrans = transition.to(self, {time = cam.zoomTime, transition = easing.inOutSine, onComplete = cancelZoomTimer, zoom = cam.targetZoom } )
		self:updateBounds()
	end

	function cam:moveToPoint(x, y)
		cam.delta.x, cam.delta.y = x - self.midPoint.x, y - self.midPoint.y
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

	function cam:getBounds()
		return self.bounds.x1, self.bounds.x2, self.bounds.y1, self.bounds.y2
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

	function cam:followUpdate()
		self:moveToPoint(self.target.x, self.target.y)
	end

	function cam:onFrame()
		--print("target x, y: ", self.target.x, self.target.y)
		if (self.mode == self.modes.follow) and (self.target) then
			cam:followUpdate()
		end
	end

	function cam.init()

	end


	return cam