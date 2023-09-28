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

	function windows_lib:create(params)
			--set default window params if not provided
		if params == nil then params = defaultWindowParams
		else
			for k, v in pairs(defaultWindowParams) do
				if not params[k] then
					params[k] = v
				end
			end
		end
		local window = display.newGroup()
		local frameBorderSize = 8
		window.bg = display.newRect( window, 0, 0, params.width - frameBorderSize, params.height - frameBorderSize )
		window.frame = frames:create(params.theme, frameBorderSize, params.width, params.height)
		window.titleButton = buttons:create({theme = params.theme, borderSize = frameBorderSize, width = 200, height = 40, label = params.title})
		window.titleButton.y = -params.height/2 + frameBorderSize
		window:insert(window.frame)
		window:insert(window.titleButton)
		window.bg:setFillColor( .09, .09, .09 )
		window.x, window.y = params.x, params.y
		
		return window
	end


	return windows_lib