	-----------------------------------------------------------------------------------------
	--
	-- utilities.lua
	--
	-----------------------------------------------------------------------------------------\

	--common modules
	local gc = require("lib.global.constants")

	--shared modules --all can call each other

	-- Define module
	local util = {}

	function util.removeObject ( o ) --called by transitions to remove object on complete
		if (o) then --if object still exists
		    o:removeSelf()
		end
	end

	function util.zeroAnchors(rect) --takes a display object and sets anchors to 0
		rect.anchorX = 0
		rect.anchorY = 0
		return rect
	end

	function util.printkv(table)
		if (table) then
			for k, v in pairs(table) do
				print(tostring(table), k, v)
			end
		else
			print("attempting to printkv but no table")
		end
	end

	--This function takes an angle and returns the direction that is closest to that angle.
	--It is used by the movePlayer() function to determine which direction the
	--player should move in. The angle is in degrees.
	function util.angleToDirection(a)
		--special case for right
		if (a >= 337.5 or a < 22.5) then
			return gc.move.right
		end
		for _,direction in pairs( gc.move ) do
			if (a >= direction.angle - 22.5 and a < direction.angle + 22.5) then
				return direction
			end
		end
		--if we get here then the angle is not in the move table
		--so we need to do some error handling
		print("Error: angleToDirection() could not find direction for angle: ",a)
		return nil
	end

	-- This code converts a delta position (the difference between two points in space) to an angle, 
	-- which is useful for determining where a player is facing when moving from one point to another.
	function util.deltaPosToAngle(pos1, _pos2)
		local pos2 = _pos2 or { x = 0, y = 0 }
		if not pos1 or not pos2 then
			print("ERROR: deltaPosToAngle() called with invalid parameters")
			return nil
		end
		local angle = math.atan2(pos2.y - pos1.y, pos2.x - pos1.x) * 180 / math.pi
		if (angle < 0) then
			angle = angle + 360
		end
		return angle
	end

	function util.compareFuzzy(pos1, pos2, _fuzzyDistance)
		local fuzzyDistance = _fuzzyDistance or 10
		
		if pos1.x <= pos2.x + fuzzyDistance and pos1.x >= pos2.x - fuzzyDistance
		and pos1.y <= pos2.y + fuzzyDistance and pos1.y >= pos2.y - fuzzyDistance then
			return true
		else
			return false
		end
	end

	function util.setEmitterColors(params, color)
		params.startColorRed = color.r
		params.startColorGreen = color.g
		params.startColorBlue = color.b
		params.finishColorRed = color.r
		params.finishColorGreen = color.g
		params.finishColorBlue = color.b
	end


	-- This function will calculate the distance between two points.
	-- @return Returns the distance between the two points.
	function util.getDistance(pos1x, pos1y, pos2x, pos2y)
		local distance = math.abs( math.sqrt( math.pow( pos1x - pos2x, 2 ) + math.pow( pos1y - pos2y, 2 ) ) )
		return distance
	end

	function util.normalizeXY(pos) --takes a table with x, y and returns a table with x, y normalised to 1 unit vector
		if pos then
			local magnitude = math.sqrt(math.pow(pos.x, 2) + math.pow( pos.y, 2 ))
			return { x = pos.x / magnitude, y = pos.y / magnitude }
		else
			print("ERROR: util.normalized pass with no position")
		end
	end

	function util.deltaPos(pos1, pos2)
		return { x = pos2.x - pos1.x, y = pos2.y - pos1.y }
	end

	function util.factorPos(pos, factor)
		return { x = pos.x * factor, y = pos.y * factor }
	end

	--https://copyprogramming.com/howto/how-to-get-an-actual-copy-of-a-table-in-lua#how-to-get-an-actual-copy-of-a-table-in-lua
	--deepcopy function to copy enemydata to a new variable
	function util.deepcopy(orig)
	    local orig_type = type(orig)
	    local copy
	    if orig_type == 'table' then
	        copy = {}
	        for orig_key, orig_value in next, orig, nil do
	            copy[util.deepcopy(orig_key)] = util.deepcopy(orig_value)
	        end
	        setmetatable(copy, util.deepcopy(getmetatable(orig)))
	    else -- number, string, boolean, etc
	        copy = orig
	    end
	    return copy
	end

	return util