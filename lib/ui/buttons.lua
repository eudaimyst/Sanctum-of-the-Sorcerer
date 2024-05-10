	-----------------------------------------------------------------------------------------
	--
	-- button.lua
	--
	-- creates a clickable button to be used in menus
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")

	local mouse = require("lib.input.mouse_input")
	local frame = require("lib.ui.frames")

	local fantasyFontParams = {
		normal = {
			fillColor = .17,
			shadow = { r=179/255, g=49/255, b=39/255 },
			highlight = { r=1, g=190/255, b=76/255 }
		},
		mouseOver = {
			fillColor = .8,
			shadow = { r=179/255, g=49/255, b=39/255 },
			highlight = { r=.1, g=.1, b=.1 }
		},
		pressed = {
			fillColor = .6,
			shadow = { r=179/255, g=49/255, b=39/255 },
			highlight = { r=.1, g=.1, b=.1 }
		}
	}

	local buttonThemes = {
		fantasy = {font = "fonts/KlarissaContour.ttf", fontParams = fantasyFontParams}
	}

	-- Define module
	local button_lib = { }

	function button_lib:create( params, zIndex )
		local button = display.newGroup()
		local hasActiveState = params.hasActiveState or false
		button.frameGroup = frame:create(params.theme, params.borderSize, params.width, params.height) --creates a group with the frame images
		button.framePressedGroup = frame:create(params.theme.."_pressed", params.borderSize, params.width, params.height)
		if hasActiveState then
			print("creating active state for button")
			button.frameActiveGroup = frame:create(params.theme.."_active", params.borderSize, params.width, params.height)
			button.frameActiveGroup.isVisible = false
		end
		button.listener = params.listener or nil
		local borderSize = params.borderSize or 8
		local width = params.width or 200
		local height = params.height or 60
		local label = params.label or nil
		local buttonType = buttonThemes[params.theme]
		
		local path = "content/menu/buttons/"..params.theme.."/"
		button.bgContainer = display.newContainer( button, width - borderSize, height - borderSize )
		button.bg = display.newImageRect( button.bgContainer, path.."bg.png" , 512 , 512 ) --make the button background
		button.bgOverlay = display.newImageRect( button, path.."bg_overlay.png" , width - borderSize, height - borderSize ) --make the button background
		button.bgOverlayPressed = display.newImageRect( button, path.."bg_overlay_pressed.png" , width - borderSize, height - borderSize ) --make the button background
		button.bgOverlayPressed.isVisible = false
		button.framePressedGroup.isVisible = false
		button:insert(button.frameGroup)
		button:insert(button.framePressedGroup)
		if hasActiveState then
			button:insert(button.frameActiveGroup)
		end

		if label then
			----button text
			if buttonType.fontParams then
				local options = { parent = button, text = label, x = 0, y = 1, font = buttonType.font, fontSize = height*.45 }
				button.label = display.newEmbossedText( options )
				button.label:setFillColor( buttonType.fontParams.normal.fillColor )
				button.label:setEmbossColor( { shadow = buttonType.fontParams.normal.shadow, highlight = buttonType.fontParams.normal.highlight } )
			end
		end

		function button:setActive(_b)
			local b = _b or false
			if b then
				self.frameGroup.isVisible = false
				self.framePressedGroup.isVisible = false
				self.frameActiveGroup.isVisible = true
			else
				self.frameGroup.isVisible = true
				self.framePressedGroup.isVisible = false
				self.frameActiveGroup.isVisible = false
			end
		end

		function button:mouseEnter()
			if self.label then
				transition.scaleTo( self.label, { time=100, xScale=1.05, yScale=1.05 } )
				self.label:setFillColor( buttonType.fontParams.mouseOver.fillColor )
				self.label:setEmbossColor( { shadow = buttonType.fontParams.mouseOver.shadow, highlight = buttonType.fontParams.mouseOver.highlight } )
			end
		end
		function button:mouseExit()
			if self.label then
				transition.scaleTo( self.label, { time=100, xScale=1, yScale=1 } )
				self.label:setFillColor( buttonType.fontParams.normal.fillColor )
				self.label:setEmbossColor( { shadow = buttonType.fontParams.normal.shadow, highlight = buttonType.fontParams.normal.highlight } )
			end
		end
		function button:press()
			if self.onPress then
				self:onPress() --call the onPress function if it exists to run any code the button needs to run
			end
			self.bgOverlay.isVisible = false
			self.bgOverlayPressed.isVisible = true
			self.frameGroup.isVisible = false
			self.framePressedGroup.isVisible = true
			if self.label then
				self.label:setFillColor( buttonType.fontParams.pressed.fillColor )
				self.label:setEmbossColor( { shadow = buttonType.fontParams.pressed.shadow, highlight = buttonType.fontParams.pressed.highlight } )
			end
		end
		function button:release()
			self.bgOverlay.isVisible = true
			self.bgOverlayPressed.isVisible = false
			self.frameGroup.isVisible = true
			self.framePressedGroup.isVisible = false
			if self.label then
				self.label:setFillColor( buttonType.fontParams.normal.fillColor )
				self.label:setEmbossColor( { shadow = buttonType.fontParams.normal.shadow, highlight = buttonType.fontParams.normal.highlight } )
			end
		end

		mouse:registerObject(button, zIndex or 0)
		return button
	
	end

	return button_lib