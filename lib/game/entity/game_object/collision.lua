	-----------------------------------------------------------------------------------------
	--
	-- collision.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")


	-- Define module
	local collision = {	}
	local store = {}
	local idCounter = 1

	local t_object, t_id  --recycled

	local function cleanStore()
		local newStore = {}
		t_id = 1
		for _, v in pairs(store) do
			t_object = v
			if t_object then
				newStore[t_id] = t_object
				t_object.col.id = t_id
				t_id = t_id + 1
			end
		end
		store = newStore
	end

	local function removeFromStore(_colID)
		store[_colID] = nil
		cleanStore()
	end
	
	function collision.registerObject(object)
		t_id = #store+1
		store[t_id] = object
		object.col = { id = t_id, minX = 0, maxX = 0, minY = 0, maxY = 0, midX = 0, midY = 0, radius = 0 }
		object.col.radius = object.halfColWidth + object.halfColHeight / 2
		collision.updatePos(object)
		print(object.id, object.name, "registered to collision store at position", t_id)
	end

	function collision.deregisterObject(object)
		if object.col == nil then
			print(object.id, "object has no .col, can't deregister")
			return
		end
		removeFromStore(object.col.id)
	end

	local _objCol, _hch, _hcw, _x, _y
	function collision.updatePos(object)
		_objCol, _hcw, _hch = object.col, object.halfColWidth, object.halfColHeight --performance locals
		_x, _y = object.x, object.y
		_objCol.x, _objCol.y = _x, _y
		_objCol.minX, _objCol.maxX = _x - _hcw, _x + _hcw
		_objCol.minY, _objCol.maxY = _y - _hch, _y + _hch
	end

	local t_col
	function collision.getObjectsAtPoint(x, y)
		local objects = {}
		for i = 1, #store do
			t_object = store[i]
			t_col = t_object.col
			if util.withinBounds(x, y, t_col.minX, t_col.maxX, t_col.minY, t_col.maxY ) then
				objects[#objects+1] = t_object
			end
		end
		return objects
	end
	function collision.checkCollisionAtPoint(x, y)
		--print("checking", #store, "objects")
		for i = 1, #store do
			t_object = store[i]
			t_col = t_object.col
			if util.withinBounds(x, y, t_col.minX, t_col.maxX, t_col.minY, t_col.maxY ) then
				return true
			end
		end
		return false
	end
	function collision.checkCollisionAtBounds(source,minX,maxX,minY,maxY)
		for i = 1, #store do
			t_object = store[i]
			if t_object ~= source then 
				t_col = t_object.col
				if util.checkOverlap(minX,maxX,minY,maxY, t_col.minX,t_col.maxX,t_col.minY,t_col.maxY) then
					return true
				end
			end
		end
		return false
	end
	function collision.getObjectsByDistance(dist, x, y)
		local objects = {}
		for i = 1, #store do
			t_object = store[i]
			t_col = t_object.col
			if util.getDistance(x, y, t_col.x,t_col.y) < t_col.radius + dist then
				objects[#objects+1] = t_object
			end
		end
		return objects
	end

	return collision