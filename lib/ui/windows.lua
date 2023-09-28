	-----------------------------------------------------------------------------------------
	--
	-- windows.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")

	local frames = require("lib.ui.frames")
	local buttons = require("lib.ui.buttons")

	local defaultWindowParams = {
		x = display.contentWidth/2,
		y = display.contentHeight/2,
		width = 500,
		height = 200,
		title = "window title",
		moveable = true,
		closeable = true,
		theme = "fantasy"
	}

	-- Define module
	local windows_lib = {}

	local function closeWindow(window)
		if window.closedListener then
			window.closedListener()
		end
		--window:removeSelf()
		--window = nil
	end

	function windows_lib:create(params, closedListener)
		--set default window params if not provided
		if params == nil then params = defaultWindowParams
		else
			for k, v in pairs(defaultWindowParams) do
				if params[k] == nil then
					params[k] = v
				end
			end
		end
		local window = display.newGroup()
		window.closedListener = closedListener or nil
		local frameBorderSize = 8
		window.bg = display.newRect( window, 0, 0, params.width - frameBorderSize, params.height - frameBorderSize )
		window.frame = frames:create(params.theme, frameBorderSize, params.width, params.height)
		window:insert(window.frame)

		window.titleButton = buttons:create({theme = params.theme, borderSize = frameBorderSize, width = 200, height = 40, label = params.title})
		window.titleButton.y = -params.height/2 + frameBorderSize
		window:insert(window.titleButton)

		function window.closeWindow()
			closeWindow(window)
		end

		if params.closeable==true then
			window.closeButton = buttons:create({theme = params.theme, borderSize = frameBorderSize, width = 32, height = 32, label = "X", listener = window.closeWindow})
			window.closeButton.x, window.closeButton.y = params.width/2 - 16 - frameBorderSize, -params.height/2 + 16 + frameBorderSize
			window:insert(window.closeButton)
		end

		window.bg:setFillColor( .09, .09, .09 )
		window.x, window.y = params.x, params.y
		
		return window
	end


	return windows_lib