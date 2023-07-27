	-----------------------------------------------------------------------------------------
	--
	-- camera.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local util = require("lib.global.utilities")

	-- Define module
	local M = {}

	--M.zoomFactor = 1 --zoom factor, smaller zooms out, makes tiles smaller
	M.pos = { x = 0, y = 0 } --camera position in world co-ords, centered on middle of screen
	M.moveDelta = { x = 0, y = 0 } --per frame movement delta
	M.smoothDeltas = {}
	M.smoothDeltaFrames = 30
	M.multiplier = 0 --per frame delta * moveSpeed to prevent duplicate calculations
	M.extents = { x = 1920, y = 1080 } --extents of camera, x y dimensions of scene in world co-ords
	M.halfExtents = { x = M.extents.x / 2, y = M.extents.y / 2 } --extents of camera, x y dimensions of scene in world co-ords
	M.coords = { x1 = 0, x2 = 0, y1 = 0, y2 = 0 } --world positions of camera 4 corners, top left and bottom right, gets set on move

	M.moveTarget = {} --used to store current target so know move speed when moving camera

	function updateCoords(  ) --called when moving camera to update coord values

		M.coords.x1 = M.pos.x - M.halfExtents.x
		M.coords.x2 = M.pos.x + M.halfExtents.x
		M.coords.y1 = M.pos.y - M.halfExtents.y
		M.coords.y2 = M.pos.y + M.halfExtents.y

	end

	function M.worldtoscreen (x, y) --takes an x, y in world position and returns its screen position
		return x - M.coords.x1, y - M.coords.y1
	end

	function M.init( )

		for i = 0, M.smoothDeltaFrames do
			M.smoothDeltas[i] = { x = 0, y = 0}
		end

	end

	function M.moveCamera() --target to get move speed and direction to move


		for i = M.smoothDeltaFrames, 1, -1 do
			M.smoothDeltas[i - 1] = M.smoothDeltas[i]
		end

		if (char.character.isMoving) then
			local multipler = util.frameDeltaTime * char.moveSpeed
			M.smoothDeltas[M.smoothDeltaFrames].x = char.character.moveDirection.x * multipler
			M.smoothDeltas[M.smoothDeltaFrames].y = char.character.moveDirection.y * multipler
		else
			M.smoothDeltas[M.smoothDeltaFrames] = { x = 0, y = 0 }
		end
		
		local smoothDeltaTotal = {x = 0, y = 0}
		
		for i = 0, M.smoothDeltaFrames do
			smoothDeltaTotal.x = smoothDeltaTotal.x + M.smoothDeltas[i].x
			smoothDeltaTotal.y = smoothDeltaTotal.y + M.smoothDeltas[i].y
		end
		debug.updateText("smoothFrames", #M.smoothDeltas)
		M.moveDelta.x = smoothDeltaTotal.x / (M.smoothDeltaFrames + 1)
		M.moveDelta.y = smoothDeltaTotal.y / (M.smoothDeltaFrames + 1)
		M.pos.x = M.pos.x + M.moveDelta.x
		M.pos.y = M.pos.y + M.moveDelta.y
		
		updateCoords()

	end

	function M.setPos(pos) --set position of camera to passed table {x, y}

		M.moveDelta.x, M.moveDelta.y = pos.x - M.pos.x, pos.y - M.pos.y
		M.pos.x, M.pos.y = pos.x, pos.y --add half to passed position to center camera
		
		updateCoords()

	end

	function M.onFrame(  )
		
		M.moveCamera()

	    debug.updateText("camCoords", math.round(M.coords.x1)..", "..math.round(M.coords.y1))
	    debug.updateText("camPos", math.round(M.pos.x)..", "..math.round(M.pos.y))
	    debug.updateText("camDelta", math.round(M.moveDelta.x * 10) / 10 ..", "..math.round(M.moveDelta.y * 10) / 10 )

	end

	return M