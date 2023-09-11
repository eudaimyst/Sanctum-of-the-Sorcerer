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
		for i = 1, #store do
			t_object = store[i]
			if t_object then
				newStore[t_id] = t_object
				t_object.colID = t_id
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
		object.colID = t_id
		print(object.id, object.name, "registered to collision store at position", t_id)
	end

	function collision.deregisterObject(object)
		if object.colID == nil then
			print(object.id, "object has no colID, can't deregister")
			return
		end
		removeFromStore(object.colID)
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
		for i = 1, #store do
			t_object = store[i]
			t_col = t_object.col
			if util.withinBounds(x, y, t_col.minX, t_col.maxX, t_col.minY, t_col.maxY ) then
				return true
			end
		end
		return false
	end

	return collision