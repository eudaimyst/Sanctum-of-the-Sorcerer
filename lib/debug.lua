	-----------------------------------------------------------------------------------------
	--
	-- debug.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules - solar2d

	--common modules
	local util = require("lib.global.utilities")
	local cam = require("lib.camera")

	-- Define module
	local debug = {}

	local debugGroup = {} --stores display group

	local debugEnabled = false --whether or not to show debugUI
	local debugCam = false

	local sceneGroup

	local lineTimer = 0

	local function updateLines() --called from onFrame if debug enabled

		lineTimer = lineTimer + util.frameDeltaTime --increase local timer

		for k, debugLine in pairs ( debug.lineStore ) do --for each line in store
			--print(k, debugLine)

			if ( debugLine.displayLine ) then --check if line has been drawn
				debugLine.timer = debugLine.timer + util.frameDeltaTime --increase lines 
				if (cam ~= {}) then
					debugLine.displayLine.x = debugLine.displayLine.x - cam.moveDelta.x
					debugLine.displayLine.y = debugLine.displayLine.y - cam.moveDelta.y
				end

				if ( debugLine.timer  > debugLine.timerLength ) then --if timer has been passed
					debugLine.displayLine:removeSelf( )
					debugLine.displayLine = nil
					debug.lineStore[debugLine.id] = nil
				end

			else
				--drawLines
				debugLine.displayLine = display.newLine( debugGroup, debugLine.x1, debugLine.y1, debugLine.x2, debugLine.y2 )
				debugLine.displayLine:setStrokeColor( debugLine.r, debugLine.g, debugLine.b )
				debugLine.displayLine.alpha = debugLine.a
				debugLine.displayLine.strokeWidth = debugLine.w
			end
		end
	end

	local function createDebugText( label, value, posX, posY, width, height)

		--set defaults if not passed
		width = width or 100
		height = height or 50
		posX = posX or display.contentWidth - width - 20
		posY = posY or display.contentHeight - height - 20 - ((height + 20) * debug.debugTextStoreCounter)
		label = label or ("debug"..tostring(debug.debugTextStoreCounter))
		value = value or "value"

		local debugText = { labelRect = nil, valueRect = nil, bg = nil, group = nil}

		function debugText:updateValue(newValue)
			--print("newValue: "..newValue)
			self.value = newValue
			self.valueRect.text = tostring(newValue)
		end

		function debugText:updateLabel(newLabel)
			--print("newLabel: "..newLabel)
			self.label = label
			self.labelRect.text = tostring(newLabel)
		end

		debugText.group = display.newGroup()
		debugText.group.x, debugText.group.y = posX, posY
		debugGroup:insert(debugText.group)
		print(debugGroup.numChildren.." debug group children make")

		debugText.bg = display.newRect( debugText.group, 0, 0, width, height )
		debugText.bg.anchorX, debugText.bg.anchorY = 0, 0
		debugText.bg:setFillColor( 0 )
		debugText.bg.alpha = 0.2

							--display.newText( [parent,] text, x, y [, width, height], font [, fontSize] )
		debugText.labelRect = display.newText( debugText.group, label, 0, 0, native.systemFont, 16 )
		debugText.labelRect.anchorX, debugText.labelRect.anchorY = 0, 0
		debugText.labelRect.x = 5

		debugText.valueRect = display.newText( debugText.group, value, 0, 0, native.systemFont, 16 )
		debugText.valueRect.anchorX, debugText.valueRect.anchorY = 0, 0
		debugText.valueRect.x = 5
		debugText.valueRect.y = debugText.labelRect.contentHeight

		debug.debugTextStore[debug.debugTextStoreCounter] = debugText
		debugText.id = debug.debugTextStoreCounter --set an ID so can remove from store

		debug.debugTextStoreCounter = debug.debugTextStoreCounter + 1

		return debugText
	end

	local function updateRegText()

		while (debug.regTextStoreCounter > debug.debugTextStoreCounter) do --there is debugText object that can display text
			createDebugText() --make new debugText to hold object
		end
		local i = 0
		for k, register in pairs(debug.regTextStore) do --for each registered text
			--print("registers: "..register.label)
			if (register.label ~= debug.debugTextStore[i].labelRect.text) then
				debug.debugTextStore[i]:updateLabel(register.label)
			end
			if (register.value ~= debug.debugTextStore[i].valueRect.text) then
				debug.debugTextStore[i]:updateValue(register.value)
			end
			i = i + 1
		end
	end

	local function onFrame() --called every frame from event listener
		if (debugEnabled) then 
			--print("debug enabled")
			updateRegText()
			updateLines()
		end
	end
	
	debug.lineStore = {} --stores all debug lines to be drawn per frame
	debug.lineStoreCounter = 0

	debug.debugTextStore = {} --stores all debug texts so they can be updated
	debug.debugTextStoreCounter = 0

	debug.regTextStore = nil --stores references to variables that are updated to debugText on update
	debug.regTextStoreCounter = 0
	
	debug.fpsDisplay = {}

	function debug.drawLine( x1, y1, x2, y2, r, g, b, a, w, timerLength )

		if (debugEnabled) then --don't add any lines to store if debug is off
			--set defaults, need positions but rest is white or width of 1
			local r = r or 1
			local g = g or 1
			local b = b or 1
			local a = a or 1
			local w = w or 1
			local timerLength = timerLength or 0
			--create an object that holds line properties
			local debugLine = 	{ x1 = x1, y1 = y1, x2 = x2, y2 = y2, r = r, g = g, b = b, a = a, w = w, --position, colour and width
									timerLength = timerLength, timer = 0, displayLine = nil } --timer variables

			debugLine.id = debug.lineStoreCounter --set an id for debugLine so can remove from store
			debug.lineStore[debug.lineStoreCounter] = debugLine --store line for future reference

			debug.lineStoreCounter = debug.lineStoreCounter + 1 --increase counter for next line
		end

		return true
	end

	function debug.createFps()
		debug.fpsDisplay = createDebugText( "fps", "init", 0, 600, 100, 50 )
	end
	
	function debug.updateFps(fps)
		if (debug.fpsDisplay) then
			debug.fpsDisplay:updateValue(fps)
		end
	end

	function debug.updateText( newLabel, newValue )

		--print("update debug text: ", newLabel, newValue) 
		local i = 0

		local function createRegister()
			print("making new register")
			local register = { label = newLabel, value = newValue } --make new register
			if (debug.regTextStore == nil) then debug.regTextStore = {} end
			debug.regTextStore[debug.regTextStoreCounter] = register --add register in store


			debug.regTextStoreCounter = debug.regTextStoreCounter + 1 --increase counter for store
		end
		--print(debug.regTextStore)

		if (debug.regTextStore) then --store has registers in it
			local foundReg = false --whether regText is found in loop
			for k, register in pairs(debug.regTextStore) do --check for registers that already exist
				if (register.label == newLabel) then --register exists for this label
					--print("register exists for this label, not making")
					foundReg = true
					register.value = newValue --update registers value to new value
				end
			end
			if (not foundReg) then --if no registers are found
				createRegister()
			end
		else
			print("no registers at all")
			createRegister() --create first register
		end
	end

	function debug.showUI() --called from toggleUI
		for i = 0, 0 do
			createDebugText()
		end
	end

	function debug.hideUI() --called from toggleUI
		print(debugGroup.numChildren.." debug group children remove")

		for k, debugLine in pairs(debug.lineStore) do
			display.remove(debugLine.displayLine)
			debugLine.displayLine = nil
			debug.lineStore[debugLine.id] = nil
		end

		for k, debugText in pairs(debug.debugTextStore) do
			display.remove(debugText.group)
			debugText.group = nil
			debug.debugTextStore[debugText.id] = nil
		end

		debug.lineStore = {} --stores all debug lines to be drawn per frame
		debug.lineStoreCounter = 0

		debug.debugTextStore = {}
		debug.debugTextStoreCounter = 0
	end

	function debug.toggleUI() --called from keyinput
		if (debugEnabled) then 
			debugEnabled = false
			debug.hideUI()
			sceneGroup:remove(debugGroup)
			sceneGroup:insert(debugGroup)
		else
			debugEnabled = true
			debug.showUI()
			sceneGroup:remove(debugGroup)
			sceneGroup:insert(debugGroup)
		end
	end

	function debug.init(_sceneGroup) --called once from scene
		print("debugGroup made")
		sceneGroup = _sceneGroup
		debugGroup = display.newGroup( )

		Runtime:addEventListener( "enterFrame", onFrame )
	end

	return debug