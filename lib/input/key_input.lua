	-----------------------------------------------------------------------------------------
	--
	-- keyinput.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local debug = require("lib.debug")

	-- Define module
	local key = {}

	local moveListeners = {} --functions to be called when movement is processed, registered by scene
	local debugCamListener = nil --setfenv by sc_level_editor to pass a function to debug the camera movement in the editor
	local spellSelectListener = nil --used for selecting spell with number keys in game

	key.moveDirection = nil --set by combination of movement keys pressed

	local upPressed
	local downPressed
	local leftPressed
	local rightPressed

	local activeInputField = nil

	local numberKeys = { keyName = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"} }
	local numpadKeys = { --[[numpad key names go here]] keyName = { }, value = { } }
	local charKeys = { 	keyName = { "q", "w", "e", "r", "t", "y", "u", "i", "o", "p",
						"a", "s", "d", "f", "g", "h", "j", "k", "l",
						"z", "x", "c", "v", "b", "n", "m" },
						capitalValue = { "Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P",
						"A", "S", "D", "F", "G", "H", "J", "K", "L",
						"Z", "X", "C", "V", "B", "N", "M" },
					}
	local specialKeys = { keyName = {"-", "="},  capitalValue = {"_", "+"} }

	key.scrollValue = nil
	key.scroll = false
	key.char = nil --can be set during initialisation to call functions in character module

	local function movement()
	--if certain keys are pressed, set movement variables
	    if (upPressed and not leftPressed and not downPressed and not rightPressed) then
			key.moveDirection = g.move.up
	    elseif (not upPressed and leftPressed and not downPressed and not rightPressed) then
			key.moveDirection = g.move.left
	    elseif (not upPressed and not leftPressed and downPressed and not rightPressed) then
			key.moveDirection = g.move.down
	    elseif (not upPressed and not leftPressed and not downPressed and rightPressed) then
			key.moveDirection = g.move.right
	    elseif (upPressed and leftPressed and not downPressed and not rightPressed) then
			key.moveDirection = g.move.upLeft
	    elseif (upPressed and not leftPressed and not downPressed and rightPressed) then
			key.moveDirection = g.move.upRight
	    elseif (not upPressed and leftPressed and downPressed and not rightPressed) then
			key.moveDirection = g.move.downLeft
	    elseif (not upPressed and not leftPressed and downPressed and rightPressed) then
			key.moveDirection = g.move.downRight
	    elseif (upPressed and leftPressed and not downPressed and rightPressed) then
			key.moveDirection = g.move.up
	    elseif (not upPressed and leftPressed and downPressed and rightPressed) then
			key.moveDirection = g.move.down
	    elseif (upPressed and leftPressed and downPressed and not rightPressed) then
			key.moveDirection = g.move.left
	    elseif (upPressed and not leftPressed and downPressed and rightPressed) then
			key.moveDirection = g.move.right
	    else
			key.moveDirection = nil
	    end
		--print("movement key direction: "..tostring(key.moveDirection))
	end

	local function onKeyEvent( event )
		--print("key pressed")
		--process input
		if (activeInputField) then
			local inputType = activeInputField.element.data.inputType
			local inputKeys --the list of keyNames to compare the input with for the type
			if ( inputType == "text") then
				inputKeys = {charKeys, numberKeys, specialKeys}
			else
				inputKeys = {numberKeys}
			end
			for i = 1, #inputKeys do
				local keysToSend = inputKeys[i].keyName--set the default keys to keyname unless overriden
				if (inputKeys[i].value) then --a seperate table is defined to pass a diff value than keyname
					keysToSend = inputKeys[i].value
				end
				if (inputKeys[i].capitalValue) then --a diff value is required when shift held donw
					if (event.isShiftDown) then
						keysToSend = inputKeys[i].capitalValue
					end
				end
				for j = 1, #keysToSend do --just pass the keyName
					if (event.keyName == inputKeys[i].keyName[j] and event.phase == "down") then
						activeInputField:inputSent(keysToSend[j])
					end
				end
			end
			if (event.keyName == "enter" and event.phase == "down") then activeInputField:inputComplete() end
			if (event.keyName == "escape" and event.phase == "down") then activeInputField:inputCancel() end
			if (event.keyName == "deleteBack" and event.phase == "down") then activeInputField:inputDelete() end
		end

		if (spellSelectListener) then 
			for i = 1, #numberKeys.keyName do
				if (event.keyName == numberKeys.keyName[i] and event.phase == "down") then
					print("key "..numberKeys.keyName[i].." pressed")
					local selectedSlot = tonumber(numberKeys.keyName[i])
					print("")
					spellSelectListener(selectedSlot)
					selectedSlot = nil
				end
			end
		end

	    if ((event.keyName == "w" or event.keyName == "up") and event.phase == "down") then upPressed = true end
	    if ((event.keyName == "w" or event.keyName == "up")  and event.phase == "up") then upPressed = false end

	    if ((event.keyName == "s" or event.keyName == "down")  and event.phase == "down") then downPressed = true end
	    if ((event.keyName == "s" or event.keyName == "down")  and event.phase == "up") then downPressed = false end

	    if ((event.keyName == "a" or event.keyName == "left")  and event.phase == "down") then leftPressed = true end
	    if ((event.keyName == "a" or event.keyName == "left")  and event.phase == "up") then leftPressed = false end

	    if (event.isCtrlDown) then
		    if (event.keyName == "d" and event.phase == "down") then
				debug.toggleUI()
		    end
			if (event.keyName == "c" and event.phase == "down") then
				debugCamListener()
			end
		else
		    if ((event.keyName == "d" or event.keyName == "right")  and event.phase == "down") then rightPressed = true end
		    if ((event.keyName == "d" or event.keyName == "right")  and event.phase == "up") then rightPressed = false end
		end

	    if ((event.keyName == "enter") and event.phase == "down") then
			print("enter pressed")
			--enter pressed
	    end
	    if ((event.keyName == "enter") and event.phase == "up") then
			--enter released
	    end

	    if (event.keyName == "escape") then
			--escape pressed
	    end

	    movement()
	    -- IMPORTANT! Return false to indicate that this app is NOT overriding received key
	    -- This lets operating system execute its default handling of key
	    return false
	end

	function key.registerInputField(inputField)
		activeInputField = inputField
	end

	function key.deregisterInputField()
		activeInputField = nil
	end

	function key.registerMoveListener(func) --registers a passed function to be called when input event is called
		moveListeners[#moveListeners+1] = func
	end
	function key.registerDebugCamListener(func)
		debugCamListener = func
	end

	function key.registerSpellSelectListener(func)
		spellSelectListener = func
	end

	function key.init()
		Runtime:addEventListener( "key", onKeyEvent )
	end

	function key.onFrame(event) --each frame check if movement key is pressed and send direction to registered listeners
		if (key.moveDirection) then
			for i = 1, #moveListeners do
				moveListeners[i](key.moveDirection) --sends movement direction to each registered listener
			end
		end
	end
	
	--Runtime:addEventListener( "enterFrame", onFrame )

	return key