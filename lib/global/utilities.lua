	-----------------------------------------------------------------------------------------
	--
	-- utilities.lua
	--
	-----------------------------------------------------------------------------------------\

	--common modules
	local gc = require("lib.global.constants")

	local mAtan2 = math.atan2
	local mSqrt = math.sqrt
	local mPi = 3.1415926535898
	local mAbs = math.abs
	local mPow = math.pow
	local mCeil = math.ceil

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

	function util.deltaToAngle(x, y)
		local angle = mAtan2(y, x) * 180 / mPi
		if (angle < 0) then
			angle = angle + 360
		end
		return angle
	end

	-- This code converts a delta position (the difference between two points in space) to an angle, 
	-- which is useful for determining where a player is facing when moving from one point to another.
	function util.deltaPosToAngle(pos1X, pos1Y, pos2X, pos2Y)
		local angle = mAtan2(pos2Y - pos1Y, pos2X - pos1X) * 180 / mPi
		if (angle < 0) then
			angle = angle + 360
		end
		return angle
	end

	-- returns true if two objects overlap, false otherwise
	function util.checkOverlap(o1minX, o1maxX, o1minY, o1maxY, o2minX, o2maxX, o2minY, o2maxY)
		-- check if the two objects overlap in the x direction
		if (o1minX > o2minX and o1minX < o2maxX)
		or (o1maxX > o2minX and o1maxX < o2maxX)
		or (o1minX < o2minX and o1maxX > o2maxX)
		or (o1minX > o2minX and o1maxX < o2maxX) then
			-- check if the two objects overlap in the y direction
			if (o1minY > o2minY and o1minY < o2maxY) then
				-- if they overlap in both directions, return true
				return true
			elseif (o1maxY > o2minY and o1maxY < o2maxY) then
				return true
			elseif (o1minY < o2minY and o1maxY > o2maxY) then
				return true
			elseif (o1minY > o2minY and o1maxY < o2maxY) then
				return true
			end
		end
		-- if we didn't return true, the objects do not overlap
		return false
	end

	function util.sortBounds(x1, x2, y1, y2)
		local t
		if (x1 > x2) then t = x2; x2 = x1; x1 = t end
		if (y1 > y2) then t = y2; y2 = y1; y1 = t end
		return x1, x2, y1, y2
	end

	function util.withinBounds(x, y, minX, maxX, minY, maxY)
		if x >= minX and x <= maxX
		and y >= minY and y <= maxY
		then
			return true
		else
			return false
		end
	end

	function util.compareFuzzy(pos1x, pos1y, pos2x, pos2y, _fuzzyDistance)
		local fuzzyDistance = _fuzzyDistance or 10
		if pos1x <= pos2x + fuzzyDistance and pos1x >= pos2x - fuzzyDistance
		and pos1y <= pos2y + fuzzyDistance and pos1y >= pos2y - fuzzyDistance then
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
		local distance = mAbs( mSqrt( mPow( pos1x - pos2x, 2 ) + mPow( pos1y - pos2y, 2 ) ) )
		return distance
	end

	function util.normalizeXY(x, y) --takes a table with x, y and returns a table with x, y normalised to 1 unit vector
		local magnitude = mSqrt(mPow(x, 2) + mPow( y, 2 ))
		return x / magnitude, y / magnitude
	end

	function util.deltaPos(pos1X, pos1Y, pos2X, pos2Y)
		return pos2X - pos1X, pos2Y - pos1Y
	end

	function util.factorPos(posX, posY, factor)
		return posX * factor, posY * factor
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