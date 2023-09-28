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
	function util.getObjectBounds(_object) --returns xMin, xMax, yMin, yMax
		return _object.x - _object.width * _object.anchorX, --xMin
		_object.x + _object.width * (1 - _object.anchorX), --xMax
		_object.y - _object.height * _object.anchorY, --yMin
		_object.y + _object.height * (1 - _object.anchorY) --yMax
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

	local _angle
	function util.deltaToAngle(x, y)
		_angle = mAtan2(y, x) * 180 / mPi
		if (_angle < 0) then
			_angle = _angle + 360
		end
		return _angle
	end

	-- This code converts a delta position (the difference between two points in space) to an angle, 
	-- which is useful for determining where a player is facing when moving from one point to another.
	function util.deltaPosToAngle(pos1X, pos1Y, pos2X, pos2Y)
		_angle = mAtan2(pos2Y - pos1Y, pos2X - pos1X) * 180 / mPi
		if (_angle < 0) then
			_angle = _angle + 360
		end
		return _angle
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

	local _t
	function util.sortBounds(x1, x2, y1, y2)
		if (x1 > x2) then _t = x2; x2 = x1; x1 = _t end
		if (y1 > y2) then _t = y2; y2 = y1; y1 = _t end
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

	local _fuzzyDistance
	function util.compareFuzzy(pos1x, pos1y, pos2x, pos2y, fuzzyDistance)
		_fuzzyDistance = fuzzyDistance or 10
		if pos1x <= pos2x + _fuzzyDistance and pos1x >= pos2x - _fuzzyDistance
		and pos1y <= pos2y + _fuzzyDistance and pos1y >= pos2y - _fuzzyDistance then
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
	local _dist
	function util.getDistance(pos1x, pos1y, pos2x, pos2y)
		_dist = mAbs( mSqrt( mPow( pos1x - pos2x, 2 ) + mPow( pos1y - pos2y, 2 ) ) )
		return _dist
	end
	local _mag
	function util.normalizeXY(x, y) --takes a table with x, y and returns a table with x, y normalised to 1 unit vector
		_mag = mSqrt(mPow(x, 2) + mPow( y, 2 ))
		return x / _mag, y / _mag
	end

	function util.deltaPos(pos1X, pos1Y, pos2X, pos2Y)
		return pos2X - pos1X, pos2Y - pos1Y
	end

	function util.factorPos(posX, posY, factor)
		return posX * factor, posY * factor
	end

	--https://copyprogramming.com/howto/how-to-get-an-actual-copy-of-a-table-in-lua#how-to-get-an-actual-copy-of-a-table-in-lua
	--deepcopy function to copy enemydata to a new variable
	local _orig_type
	function util.deepcopy(orig)
	    _orig_type = type(orig)
		local copy
	    if _orig_type == 'table' then
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