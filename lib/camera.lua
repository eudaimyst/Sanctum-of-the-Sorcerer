	-----------------------------------------------------------------------------------------
	--
	-- camera.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules

	-- Define module
	local cam = {}
	local cameraModes = { follow = {}, free = {} }
	local map = nil --set by init function
	local halfScreenWidth, halfScreenHeight = display.contentWidth / 2, display.contentHeight / 2

	cam.bounds = {x1 = 0, y1 = 0, x2 = 0, y2 = 0}
	cam.midPoint = {x = 0, y = 0}
	cam.zoom = 1
	cam.mode = cameraModes.free
	cam.target = nil

	function cam:updateBounds()
		self.bounds.x1 = self.midPoint.x - halfScreenWidth / self.zoom
		self.bounds.y1 = self.midPoint.y - halfScreenHeight / self.zoom
		self.bounds.x2 = self.midPoint.x + halfScreenWidth / self.zoom
		self.bounds.y2 = self.midPoint.y + halfScreenHeight / self.zoom
	end

	function cam:moveToPoint(x, y)
		self.midPoint.x = x
		self.midPoint.y = y
		self:updateBounds()
	end

	function cam:directionalMove(direction)
		self.midPoint.x = self.midPoint.x + direction.x
		self.midPoint.y = self.midPoint.y + direction.y
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

	function cam.init(_map)
		map = _map
		cam:moveToPoint(map.centerX, map.centerY)

	end


	return cam