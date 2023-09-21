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
	local collision = {}

	
	local store = {} --holds objects that contain col tables, accessed by their id

	local _object, _id  --recycled

	local function cleanStore()
		local newStore = {}
		_id = 1
		for _, v in pairs(store) do
			_object = v
			if _object then
				newStore[_id] = _object
				_object.col.id = _id
				_id = _id + 1
			end
		end
		store = newStore
		print("collision store count", #store)
	end

	local function removeFromStore(_colID)
		print("removing object with id", _colID, "from collision store")
		store[_colID] = nil
		cleanStore()
	end
	
	function collision.registerObject(object)
		_id = #store+1
		store[_id] = object
		object.col = { id = _id, minX = 0, maxX = 0, minY = 0, maxY = 0, midX = 0, midY = 0, radius = 0 }
		object.col.radius = object.halfColWidth + object.halfColHeight / 2
		collision.updatePos(object)
		print(object.id, object.name, "registered to collision store at position", _id)
	end

	function collision.deregisterObject(object)
		if object.col == nil then
			print(object.id, "object has no .col, can't deregister")
		else
			removeFromStore(object.col.id)
		end
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
			_object = store[i]
			t_col = _object.col
			if util.withinBounds(x, y, t_col.minX, t_col.maxX, t_col.minY, t_col.maxY ) then
				objects[#objects+1] = _object
			end
		end
		return objects
	end
	function collision.checkCollisionAtPoint(x, y)
		--print("checking", #store, "objects")
		for i = 1, #store do
			_object = store[i]
			t_col = _object.col
			if util.withinBounds(x, y, t_col.minX, t_col.maxX, t_col.minY, t_col.maxY ) then
				return true
			end
		end
		return false
	end
	function collision.checkCollisionAtBounds(source,minX,maxX,minY,maxY)
		for i = 1, #store do
			_object = store[i]
			if _object ~= source then 
				if _object.col then
					t_col = _object.col
					if util.checkOverlap(minX,maxX,minY,maxY, t_col.minX,t_col.maxX,t_col.minY,t_col.maxY) then
						if source.name == "character" then
							print ("character coliding with object#", _object.id, _object.name)
						end
						return true
					end
				end
			end
		end
		return false
	end
	function collision.getObjectsByDistance(dist, x, y)
		local objects = {}
		for i = 1, #store do
			_object = store[i]
			if _object.col then
				t_col = _object.col
				if util.getDistance(x, y, t_col.x,t_col.y) < t_col.radius + dist then
					objects[#objects+1] = _object
				end
			end
		end
		return objects
	end

	return collision