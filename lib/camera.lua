	-----------------------------------------------------------------------------------------
	--
	-- camera.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gv = require("lib.global.variables")

	-- Define module
	local cam = {}
	local cameraModes = { follow = {}, free = {} }
	local halfScreenWidth, halfScreenHeight = display.contentWidth / 2, display.contentHeight / 2

	cam.bounds = {x1 = 0, y1 = 0, x2 = display.contentWidth, y2 = display.contentHeight}
	cam.midPoint = {x = halfScreenWidth, y = halfScreenHeight}
	cam.delta = {x = 0, y = 0}
	cam.zoom = 1
	cam.mode = cameraModes.free
	cam.target = nil

	function cam:updateBounds()
		self.bounds.x1 = self.midPoint.x - halfScreenWidth / self.zoom
		self.bounds.y1 = self.midPoint.y - halfScreenHeight / self.zoom
		self.bounds.x2 = self.midPoint.x + halfScreenWidth / self.zoom
		self.bounds.y2 = self.midPoint.y + halfScreenHeight / self.zoom
	end

	function cam:adjustZoom(zoomDir, zoomSpeed) --zoomDir is a boolean, 1 = zoom in, 2 = zoom out, speed is a float
		if (zoomDir == 1) then
			self.zoom = self.zoom - zoomSpeed
		elseif (zoomDir == 2) then
			self.zoom = self.zoom + zoomSpeed
		end
		self:updateBounds()
	end

	function cam:moveToPoint(x, y)
		self.midPoint.x = x
		self.midPoint.y = y
		self:updateBounds()
	end

	function cam:directionalMove(direction)
		cam.delta.x, cam.delta.y = direction.x * gv.frame.dt, direction.y * gv.frame.dt
		self.midPoint.x = self.midPoint.x + cam.delta.x
		self.midPoint.y = self.midPoint.y + cam.delta.y
		self:updateBounds()
	end

	function cam.setMode(modeStr, target)
		if modeStr == "follow" then
			cam.mode = cameraModes.follow
			cam.target = target
		elseif modeStr == "free" then
			cam.mode = cameraModes.free
			cam.target = nil
		else debug:error("camera.setMode: modeStr not recognised")
		end
	end

	function cam.init()

	end


	return cam