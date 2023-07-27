	-----------------------------------------------------------------------------------------
	--
	-- menu.lua
	--
	-----------------------------------------------------------------------------------------

	local composer = require( "composer" )
	local scene = composer.newScene()
	local physics = require("physics")
	local json = require("json")
	local easing = require("lib.corona.easing")

	local util = require("lib.global.utilities")

	--------------------------------------------

	-- forward declarations and other locals
	local buttonSpacing = 20
	local titleImage = "content/menu_title.png"

	local sceneGroup

	local halfScreenX, halfScreenY = display.actualContentWidth / 2, display.actualContentHeight / 2

	local function onPlay()
		--composer.gotoScene( "game" )
	end

	local function onLevelEditor()
		composer.gotoScene( "scenes.sc_level_editor" )
	end

	local function onMapGenerator()
		composer.gotoScene( "scenes.sc_map_generator" )
	end

	local function onParticleDesigner()
		composer.gotoScene( "scenes.sc_particle_editor" )
	end

	local function onOptions()

	end

	local function onKeyEvent( event )
		print("key pressed")
	    if (event.keyName == "enter" and event.phase == "down") then
			onMapGenerator()
	    end
	    return false --return false to indicate app is not overriding the received key for the os
	end

	local buttonData = {
		{ label = "Play Game", width = 240, height = 56, listener = onPlay, position = 0 },
		{ label = "Level Editor", width = 266, height = 56, listener = onLevelEditor, position = 2 },
		{ label = "Map Generator", width = 300, height = 56, listener = onMapGenerator, position = 3 },
		{ label = "Particle Designer", width = 340, height = 56, listener = onParticleDesigner, position = 4 },
		{ label = "Options", width = 226, height = 56, listener = onOptions, position = 5 },
	}

	local buttonStore = {} --any button created gets stored here

	local buttonGroup
	local function createButtons()

		buttonGroup = display.newGroup()
		sceneGroup:insert( buttonGroup )

		buttonSpacing = 68
		buttonOffsetY = 60

		local normalFramePath = "content/ui/button_frame_normal/" --set path for files
		local pressedFramePath = "content/ui/button_frame_pressed/"
		--set paths for button frame images
		local imagePaths = {  normalFrame = {}, pressedFrame = {} } --initiate variable to hold full file strings
		local fileStrings = { "top", "bot", "left", "right", "topleft", "topright", "botleft", "botright" } --for finding file paths
		local frameImageSize = { size = 64, corner = 14, length = 36, offset = 25 } --dimensions for parts of frame image
		local f = frameImageSize --for readability
		local frameImageOffsets = { --for positioning frame
			top = { x = 0, y = -f.offset, w = f.length, h = f.corner },
			bot = { x = 0, y = f.offset, w = f.length, h = f.corner },
			left = { x = -f.offset, y = 0, w = f.corner, h = f.length },
			right = { x = f.offset, y = 0, w = f.corner, h = f.length }, 
			topleft = { x = -f.offset, y = -f.offset, w = f.corner, h = f.corner },
			topright = { x = f.offset, y = -f.offset, w = f.corner, h = f.corner },
			botleft = { x = -f.offset, y = f.offset, w = f.corner, h = f.corner },
			botright = { x = f.offset, y = f.offset, w = f.corner, h = f.corner } }

		for _, file in ipairs( fileStrings ) do
			imagePaths.normalFrame[file] = normalFramePath..file..".png" --concat table variables to paths
			imagePaths.pressedFrame[file] = pressedFramePath..file..".png"
			--print(imagePaths.normalFrame[file])
			--print(imagePaths.pressedFrame[file])
		end

		--local maskTest = display.newRect( buttonGroup, halfScreenX, halfScreenY, display.actualContentWidth / 1.5, display.actualContentHeight / 1.5) --rect for testing mask on group
		--maskTest:setFillColor( 1 )

		local buttonGroupMask = graphics.newMask( "content/menu_button_mask.png" )
		buttonGroup:setMask( buttonGroupMask )

		buttonGroup.maskX, buttonGroup.maskY = halfScreenX, halfScreenY

		buttonGroup.maskScaleX = display.actualContentWidth/128 / 3
		buttonGroup.maskScaleY = display.actualContentHeight/128

		local function createButton(data)

			print(data)

			local button = display.newGroup()
			button.listener = data.listener
			button.label = data.label
			buttonGroup:insert(button)

			button.normalFrame = {}
			button.pressedFrame = {} --create button and define pressed and normal frames

			button.offsets = {} --holds frameoffsets for created button 

			for k, baseOffset in pairs(frameImageOffsets) do 
				button.offsets[k] = {} --at the key of the base offset, make an empty table in the button
				local offset = button.offsets[k] --for readability we store this empty table as a local variable

				for k1, v1 in pairs (baseOffset) do
					offset[k1] = v1 --copy values in offsets for each side in frameImageOffsets, to a new key in button offset
				end

				local frame = frameImageSize --readability

				local width = data.width - frame.size
				local height = data.height - frame.size

				if k == "top" then offset.y = baseOffset.y - height / 2 ; offset.w = width - frame.corner 
				elseif k == "bot" then offset.y = baseOffset.y + height / 2 ; offset.w = width - frame.corner 
				elseif k == "left" then	offset.x = -width / 2 ; offset.h = height + frame.length
				elseif k == "right" then offset.x = width / 2 ; offset.h = height + frame.length
				elseif k == "topleft" then offset.x = -width / 2 ; offset.y = baseOffset.y - height / 2
				elseif k == "topright" then	offset.x = width / 2 ; offset.y = baseOffset.y - height / 2
				elseif k == "botleft" then offset.x = -width / 2 ; offset.y = baseOffset.y + height / 2
				elseif k == "botright" then	offset.x = width / 2 ; offset.y = baseOffset.y + height / 2
				end
			end

			----button background
			button.bg = display.newImageRect( button, "content/ui/parchment.png" , 512 , 512 ) --make the button background
			buttonMask = graphics.newMask( "content/ui/button_mask_wide.png" ) --add a mask
			button.bg:setMask(buttonMask)
			button.bg.maskScaleX = 1 / 281 * (data.width - frameImageSize.length - frameImageSize.corner) --set scale to the data width divided by the button base size
			button.bg.maskScaleY = 1 / 63 * (data.height)


			----button overlays
			local overlayX, overlayY = data.width - frameImageSize.corner * 4, data.height - frameImageSize.corner --image size of overlays normalised to the button size

			button.overlayNormal = display.newImageRect( button, normalFramePath.."overlay_horizontal.png", overlayX, overlayY) --overlay button with image size
			button.overlayPressed = display.newImageRect( button, pressedFramePath.."overlay_horizontal.png", overlayX, overlayY) --overlay button with image size

			----button text

			local options = { parent = button, text = data.label, x = 0, y = 1, font = "fonts/KlarissaContour.ttf", fontSize = 24 }
			button.text = display.newEmbossedText( options )
			button.text:setFillColor( .17 )

			button.text:setEmbossColor( { shadow = { r=179/255, g=49/255, b=39/255 }, highlight = { r=1, g=190/255, b=76/255 } } )

			----button frame
			for k, path in pairs( imagePaths.normalFrame ) do
				button.normalFrame[k] = display.newImageRect( button, path, button.offsets[k].w , button.offsets[k].h ) --add button using paths and offsets of k
				button.normalFrame[k].x, button.normalFrame[k].y = button.offsets[k].x, button.offsets[k].y
				button.normalFrame[k].scaleX =  1 / 281 * (data.width - frameImageSize.length - frameImageSize.corner)
				button.normalFrame[k].scaleY = 1 / 63 * (data.height)
			end

			for k, path in pairs( imagePaths.pressedFrame ) do
				button.pressedFrame[k] = display.newImageRect( button, path, button.offsets[k].w , button.offsets[k].h ) --add paths and offsets
				button.pressedFrame[k].x, button.pressedFrame[k].y = button.offsets[k].x, button.offsets[k].y
				button.pressedFrame[k].scaleX =  1 / 281 * (data.width - frameImageSize.length - frameImageSize.corner)
				button.pressedFrame[k].scaleY = 1 / 63 * (data.height)
				button.pressedFrame[k].isVisible = false
			end

			function button:press() --hide normal frame images
				for _, image in pairs( button.pressedFrame ) do
					--print("frame keys: "..image)
					image.isVisible = true
				end
				button.overlayPressed.isVisible = true
				button.overlayNormal.isVisible = false
				button.bg:setFillColor( 0.9 )
				button.text:setFillColor( .6 )
				button.text:setEmbossColor( { shadow = { r=179/255, g=49/255, b=39/255 }, highlight = { r=.1, g=.1, b=.1 } } )
			end

			function button:release() --hide pressed frame images
				for _, image in pairs( button.pressedFrame ) do
					image.isVisible = false
				end
				button.overlayPressed.isVisible = false
				button.overlayNormal.isVisible = true
				button.bg:setFillColor( 1 )
				button.text:setFillColor( .8 )
				button.text:setEmbossColor( { shadow = { r=179/255, g=49/255, b=39/255 }, highlight = { r=.1, g=.1, b=.1 } } )
			end

			function button:mouseEnter()
				transition.scaleTo( self.text, { time=100, xScale=1.01, yScale=1.01 } )
				button.text:setFillColor( .8 )
				button.text:setEmbossColor( { shadow = { r=179/255, g=49/255, b=39/255 }, highlight = { r=.1, g=.1, b=.1 } } )
			end

			function button:mouseExit()
				transition.scaleTo( self.text, { time=100, xScale=1, yScale=1 } )
				button.text:setFillColor( .17 )
				button.text:setEmbossColor( { shadow = { r=179/255, g=49/255, b=39/255 }, highlight = { r=1, g=190/255, b=76/255 } } )
			end

			----button movement and position
			local moveSpeed = 1000 --time for movement
			local fadeSpeed = 200
			local moveDistance = 600
			local fadeDelay = 300 --delay fade in
			local finalX, finalY = halfScreenX, halfScreenY + (buttonSpacing * data.position) --sets final position based on button position in data
			button.x, button.y = finalX - moveDistance, finalY --set initial pos to final pos minus slide in from left
			button.alpha = 0 --sets initial alpha to fade in



			function button:enable()
					button.collision = display.newRect( sceneGroup, finalX, finalY, data.width - frameImageSize.length - frameImageSize.corner * 2, data.height - frameImageSize.corner )
					--button.collision.scaleX = 1 / 281 * (data.width - frameImageSize.length - frameImageSize.corner) --set scale to the data width divided by the button base size
					--button.collision.scaleY = 1 / 63 * (data.height)
					button.collision:setFillColor( 1, 1, 1, 0 )
					button.collision.button = button
					physics.addBody( button.collision, "static" )
			end

			function button:slideIn()
				transition.moveTo( self, { time = moveSpeed, x = finalX, y = finalY, transition = easing.outSine } ) --moves button to position
				transition.fadeIn( self, { time = fadeSpeed, delay = fadeDelay, onComplete = self:enable(), transition = easing.outCubic } ) --fades in button

			end

			return button
		end

		for k, data in pairs(buttonData) do --for each data in button data
			buttonStore[k] = createButton(data) --create button and store reference
		end

		local function slideButton ( event ) --event to
			event.source.params.button:slideIn()
		end

		local slideInDelay = 300
		local i = 0 --iterator sets delay time higher for each button
		for _, button in ipairs(buttonStore) do --for each button in the store
			print("setting timer to slide in")
			local slideTimer = timer.performWithDelay( i * slideInDelay, slideButton, "menu" ) --add a timer to call slide method on each button after delay
			slideTimer.params = { button = button }
			i = i + 1
		end
	end

	local hoveredButton
	local clickedButton
	local mouse = { x = 0, y = 0, old = { x = 0, y = 0 } }
	-- Called when a mouse event has been received.
	local function onMouseEvent( event )
		mouse.old.x, mouse.old.y= mouse.x, mouse.y
		mouse.x, mouse.y = event.x, event.y

		if event.isPrimaryButtonDown then
			print("clicked")
			print(hoveredButton)
			if hoveredButton then
				hoveredButton:press()
				clickedButton = hoveredButton
			end
		else
			if clickedButton then
				if (clickedButton == hoveredButton) then
					clickedButton:release()
					clickedButton.listener()
				end
				clickedButton = nil
			end
		end

		local ray = physics.rayCast( mouse.old.x, mouse.old.y, mouse.x, mouse.y, "any" )
		if (not clickedButton) then
			if ray then
				if  ray[1].object.button then
					local button = ray[1].object.button
					print("mouse enter button "..button.label)
					button:mouseEnter()
					hoveredButton = button
					print(hoveredButton)
				end
			end
		end
		local ray2 = physics.rayCast( mouse.x, mouse.y, mouse.old.x, mouse.old.y, "any" )
		if ray2 then
			if  ray2[1].object.button then
				local button = ray2[1].object.button
				print("mouse exit button "..button.label)
				button:mouseExit()
				hoveredButton = nil
				print(hoveredButton)
			end
		end
	end

	local function createTitle() -- create title image, called by createBackground after fadein
		local titleRect = display.newImageRect( sceneGroup, titleImage, 785, 226 )
		local moveDistance = 300 --distance for movement
		local moveSpeed = 300 --time for movement
		local fadeDelay = moveSpeed / 2 --delay fade in by half the move speed
		titleRect.x, titleRect.y = halfScreenX, 241 - moveDistance --final position minus the distance to move
		titleRect.alpha = 0 --sets initial alpha to fade in
		transition.fadeIn( titleRect, { time = moveSpeed, delay = fadeDelay, transition = easing.outCubic } ) --fades in image title
		transition.moveTo( titleRect, { time = moveSpeed, x = halfScreenX, y = 241, onComplete = createButtons, transition = easing.inOutCirc } ) --moves title to position
	end


	local function createMenu() --fade in the background image then create the tile

		local background = display.newGroup()
		local easingList = { easing.inBounce, easing.outBounce, easing.inOutBounce, easing.outInBounce, easing.outInElastic, easing.inOutQuart, easing.outInBack, easing.inOutCubic } --random easings for flicker
		local fadeInTime = 300
		local images = {} --table that holds rects
		local emitters = {}

		local function setBloomParams(image)
			image.fill.effect = "filter.bloom"
			local effect = image.fill.effect
			effect.levels.white = 1
			effect.levels.black = .1
			effect.blur.horizontal.blurSize = 0
			effect.blur.horizontal.sigma = 10
			effect.blur.vertical.blurSize = 0
			effect.blur.vertical.sigma = 10
			effect.levels.gamma = .3
			effect.add.alpha = .4
		end

		local function createBackgroundImages()
			--position in table determines heirarchy (first = behind)
			local imageData = {
				{x = 498, y = 54, w = 213, h =219 , image = "arcane_orb", emitters = { "arcane", "glow.arcane", "smallparticles" } },
				{x = 286, y = 49, w = 215, h = 226, image = "shadow_orb", emitters = { "shadow", "glow.shadow", "smallparticles" } },
				{x = 617, y = 140, w = 263, h = 271, image = "earth_orb", emitters = { "glow.earth", "smallparticles" } },
				{x = 132, y = 142, w = 256, h = 273, image = "wind_orb", emitters = { "glow.wind", "smallparticles" } },
				{x = 587, y = 323, w = 323, h = 344, image = "ice_orb", emitters = { "ice", "glow.ice", "smallparticles" } },
				{x = 85, y = 258, w = 351, h = 409, image = "lightning_orb", emitters = { "lightning", "glow.lightning", "smallparticles" } },
				{x = 315, y = 359, w = 365, h = 411, image = "fire_orb", emitters = { "fire", "glow.fire", "smallparticles" } },
			}

			for i = 1, #imageData do
				local data = imageData[i] --readability
				local image = display.newImageRect( background, "content/menu/"..data.image..".png", data.w, data.h )
				images[i] = image
				setBloomParams(image)
				util.zeroAnchors(image)
				image.x, image.y = data.x, data.y

				local function runGlow()
					image:runGlow()
				end
				function image:runGlow()
					local easing = easingList[ math.random( 1, #easingList) ] --pick a random easing function
					if (self.doGlow) then
						self.glowTime = math.random(2000, 2500)
						transition.to( self.fill.effect.levels, { time = self.glowTime, onComplete = runGlow, transition = easing, gamma = .6 } ) --flickers the image
						self.doGlow = false
					else
						self.glowTime = 4000
						transition.to( self.fill.effect.levels, { time = self.glowTime, onComplete = runGlow, transition = easing, gamma = .3 } ) --flickers the image
						self.doGlow = true
					end

				end
				image.doGlow = true
				image.glowTime = 1000
				image.glowTimer = timer.performWithDelay( image.glowTime, image:runGlow(), 1, "menu" ) --starts a timer once bg has faded in

				for j = 1, #data.emitters do
					local file, errorString = io.open(  system.pathForFile(system.ResourceDirectory).."/content/particles/params/"..data.emitters[j]..".json", "r" ) -- Open the file handle
				    --print(errorString)
				    local p = json.decode( file:read( "*a" ) )
				    io.close( file ) -- Close the file handle
					local scaleFactor = data.w/350
					if (string.find(data.emitters[j], "smallparticles") or string.find(data.emitters[j], "glow")) then
						if (string.find(data.emitters[j], "glow")) then
							p.startParticleSize = p.startParticleSize*scaleFactor
							p.finishParticleSize = p.finishParticleSize*scaleFactor
						end
						if (string.find(data.emitters[j], "smallparticles")) then
							p.startParticleSize = p.startParticleSize*(data.w/215)
							p.finishParticleSize = p.finishParticleSize*(data.h/215)
						end
						p.speed = p.speed * scaleFactor
						p.gravityy = p.gravityy * scaleFactor * .8
						p.sourcePositionVariancex = data.w/2.8
						p.sourcePositionVariancey = data.h/4
						p.maxParticles = p.maxParticles * scaleFactor
					end

					local emitter = display.newEmitter( p )
					background:insert(emitter)
					emitters[i] = emitter
					emitter.scaleX, emitter.scaleY = 3, 3
					emitter.x, emitter.y = data.x + data.w/2, data.y + data.h*3/5
				end
			end
		end



		background.anchorChildren = true
		sceneGroup:insert( background )
		util.zeroAnchors(background)
		local bgw, bgh = 829, 732 --hardcode the total size of the background as cant use contentWidth/Height with emitters(?)
		background.x, background.y = halfScreenX - bgw/2, halfScreenY - bgh/2 + 150 --positions group of background images

		background.alpha = 0 --starts faded out

		createBackgroundImages()
		--initial fade in
		transition.fadeIn( background, { time = fadeInTime, onComplete = createTitle } ) --fades the image in then calls function to create tile
		--glow effect

	end

	function scene:create( event )
		sceneGroup = self.view

		display.setDefault( "background", .09, .09, .09 )

		-- Called when the scene's view does not exist.
		--
		-- INSERT code here to initialize the scene
		-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.
		-- all display objects must be inserted into group

		createMenu() --call function to create menu

	end

	function scene:show( event )
		sceneGroup = self.view
		local phase = event.phase

		print("scene loaded")
		physics.start( )
		physics.setGravity( 0, 0 )

		if phase == "will" then
			-- Called when the scene is still off screen and is about to move on screen
		elseif phase == "did" then
			-- Called when the scene is now on screen
			--
			-- INSERT code here to make the scene come alive
			-- e.g. start timers, begin animation, play audio, etc.
			--add listener for input
			Runtime:addEventListener( "key", onKeyEvent )
			Runtime:addEventListener( "mouse", onMouseEvent )
		end
	end

	function scene:hide( event )
		sceneGroup = self.view
		local phase = event.phase
		if event.phase == "will" then
			-- Called when the scene is on screen and is about to move off screen
			--
			-- INSERT code here to pause the scene
			-- e.g. stop timers, stop animation, unload sounds, etc.)
			timer.cancel( "menu" ) --cancels all running timers
			transition.cancelAll() --cancels all transitions

			Runtime:removeEventListener( "key", onKeyEvent )
			Runtime:removeEventListener( "mouse", onMouseEvent )

		elseif phase == "did" then
			-- Called when the scene is now off screen
			composer.removeHidden()
		end
	end

	function scene:destroy( event )
		--local sceneGroup = self.view
		-- Called prior to the removal of scene's "view" (sceneGroup)
		--
		-- INSERT code here to cleanup the scene
		-- e.g. remove display objects, remove touch listeners, save state, etc.
		sceneGroup = self.view

	end

	---------------------------------------------------------------------------------

	-- Listener setup
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )

	-----------------------------------------------------------------------------------------

	return scene
