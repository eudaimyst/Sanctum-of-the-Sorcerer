	-----------------------------------------------------------------------------------------
	--
	-- module.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")

	local objectStore = {}
	local objectCount = 0
	
	local mouseOverObject
	local clickedObject

	local mouseX, mouseY = 0, 0
	local mRound = math.round

	-- Define module
	local mouse_input = {}

	local _zIndex = 0

	local _highestZ = 0
	
	function mouse_input.getPosition()
		return mouseX, mouseY
	end

	function mouse_input.getHighestZ() --returns the highest Zindex of all objects registered to mouse_input
		for i = 1, #objectStore do
			if objectStore[i] then
				if objectStore[i].mouseZindex > _highestZ then
					_highestZ = objectStore[i].mouseZindex
				end
			end
		end
		return _highestZ
	end

	function mouse_input:registerObject(object, zIndex) --register a display object) to be checked if bounds overlap when mouse moves
		_zIndex = zIndex or 0
		if object.x == nil or object.y == nil or object.width == nil or object.height == nil or object.anchorX == nil or object.anchorY == nil then
			print("ERROR: mouse_input:registerObject() object must have x, y, width, height and anchors")
			return
		end
		objectCount = objectCount + 1
		objectStore[objectCount] = object
		object.mouseZindex = _zIndex
		object.mouseIndex = objectCount
		print("added object to mouse_input store with id", objectCount, object.x, object.y, object.width, object.height)
	end

	function mouse_input:deregisterObject(object)
		objectStore[object.mouseIndex] = nil
	end

	local _object, _bxMin, _bxMax, _byMin, _byMax --recycled
	local function onMouseEvent( event ) -- Called when a mouse event has been received.
		mouseX, mouseY = mRound(event.x), mRound(event.y)
		--print("mouseX", mouseX, "mouseY", mouseY)
		for i = 1, objectCount do
			if objectStore[i] then
				_object = objectStore[i]
			else
				_object = nil
			end
			if _object then
				_bxMin, _bxMax, _byMin, _byMax = util.getObjectBounds(_object)
				--print("comparing mouse pos", mouseX, mouseY, "with object", _object.mouseIndex, "bounds", _bxMin, _bxMax, _byMin, _byMax)
				if util.withinBounds(mouseX, mouseY, _bxMin, _bxMax, _byMin, _byMax) then
					if mouseOverObject ~= _object then --if not already hovering over this object
						if mouseOverObject then --mouseOverObject is not nil
							if mouseOverObject.mouseZindex > _object.mouseZindex then --other object has higher Zindex
								--do nothing?
							else
								mouseOverObject = _object --store reference to mouseOverObject --set this object as the new mouseOverObject
								print("mouse enter", _object.mouseIndex, "z", _object.mouseZindex)
								if _object.mouseEnter then --object has a mouse enter function
									_object:mouseEnter() --call the function
								end
							end
						else --mouseOverObject is nil so we are safe to set without checking zIndex
							mouseOverObject = _object
							print("mouse enter", _object.mouseIndex, "z", _object.mouseZindex)
							if _object.mouseEnter then --object has a mouse enter function
								_object:mouseEnter() --call the function
							end
						end
					end
					--print("setting mouseOverObject", _object.mouseIndex, tostring(_object))
				end
			end
		end
		if mouseOverObject then
			--print("check for exit on object", _object.mouseIndex, tostring(mouseOverObject))
			_bxMin, _bxMax, _byMin, _byMax = util.getObjectBounds(mouseOverObject)
			if util.withinBounds(mouseX, mouseY, _bxMin, _bxMax, _byMin, _byMax) == false then
				if mouseOverObject.mouseExit then
					mouseOverObject:mouseExit()
				end
				print("mouse exit object", mouseOverObject.mouseIndex)
				mouseOverObject = nil
			end
		end
		if event.isPrimaryButtonDown then
			--print("click")
			if mouseOverObject then
				print("clicked object", mouseOverObject.mouseIndex)
				clickedObject = mouseOverObject
				if mouseOverObject.press then --if object has a press function
					mouseOverObject:press()
				end
			end
		else
			if clickedObject then
				if (clickedObject == mouseOverObject) then
					print("mouse clicked and released over object", mouseOverObject.mouseIndex)
					if clickedObject.release then
						clickedObject:release()
					end
					if clickedObject.listener then
						clickedObject.listener()
					end

				end
				clickedObject = nil
			end
		end
	end

	function mouse_input.init() --called from scene when shown
		print("mouse input initialising")
		Runtime:addEventListener( "mouse", onMouseEvent )
	end

	function mouse_input.deinit() --called from scene when hidden
		print("mouse input de-initialising")
		for i = 1, #objectStore do --deregisters all objects in the current scene
			objectStore[i] = nil
		end
	
		mouseOverObject = nil
		clickedObject = nil
		objectStore = {}
		objectCount = 0
		Runtime:removeEventListener( "mouse", onMouseEvent )
	end

	return mouse_input