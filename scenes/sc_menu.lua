-----------------------------------------------------------------------------------------
--
-- menu.lua
--
-----------------------------------------------------------------------------------------

local composer = require("composer")
local scene = composer.newScene()
local physics = require("physics")
local json = require("json")
local easing = require("lib.corona.easing")
local lang = require("lib.global.locale")

local mouse = require("lib.input.mouse_input")
local button_lib = require("lib.ui.buttons")

local util = require("lib.global.utilities")

--------------------------------------------

-- forward declarations and other locals

local buttonSpacing = 68
local buttonOffsetY = 60

local titleImage = "content/menu/title.png"
local sceneGroup
local halfScreenX, halfScreenY = display.contentWidth / 2, display.contentHeight / 2

local buttonStore = {} --any button created gets stored here

local Menu = {}        -- object for cleanup - everything here will be cleaned up when menu is hidden.

local function addToCleanup(obj)
	Menu[#Menu + 1] = obj
end

local function onPlay()
	composer.gotoScene("scenes.sc_game")
end

local function onQuit()
	native.requestExit()
end

local function onLevelEditor()
	composer.gotoScene("scenes.sc_level_editor")
end

local function onMapGenerator()
	composer.gotoScene("scenes.sc_map_generator")
end

local function onParticleDesigner()
	composer.gotoScene("scenes.sc_particle_editor")
end

local function onOptions()
	mouse:deinit()
	local function optionsClosedListener()
		mouse:init()
		for i = 1, #buttonStore do
			mouse:registerObject(buttonStore[i])
		end
	end
	composer.showOverlay("scenes.sc_options_overlay",
		{ effect = "fade", time = 200, params = { closedListener = optionsClosedListener } })
end

local function onKeyEvent(event)
	print("key pressed")
	if (event.keyName == "enter" and event.phase == "down") then
		onMapGenerator()
	end
	return false --return false to indicate app is not overriding the received key for the OS
end

--[[ local buttonData = {
		{ label = "Play Game", width = 240, height = 56, listener = onPlay, position = 0 },
		{ label = "Level Editor", width = 266, height = 56, listener = onLevelEditor, position = 2 },
		{ label = "Map Generator", width = 300, height = 56, listener = onMapGenerator, position = 3 },
		{ label = "Particle Designer", width = 340, height = 56, listener = onParticleDesigner, position = 4 },
		{ label = "Options", width = 226, height = 56, listener = onOptions, position = 5 },
	} ]]
local buttonData = {
	{ label = lang.get("play"),    borderSize = 14, width = 240, height = 56, theme = "fantasy", listener = onPlay,         position = 1 },
	{ label = lang.get("options"), borderSize = 14, width = 220, height = 56, theme = "fantasy", listener = onOptions,      position = 2 },
	{ label = lang.get("mapgen"),  borderSize = 14, width = 300, height = 56, theme = "fantasy", listener = onMapGenerator, position = 3 },
	{ label = lang.get("quit"),    borderSize = 14, width = 200, height = 56, theme = "fantasy", listener = onQuit,         position = 5 }
}

local buttonGroup

local function createButtons()
	for i = 1, #buttonData do
		local data = buttonData[i]
		local button = button_lib:create(data)
		sceneGroup:insert(button)
		button.x = halfScreenX
		button.y = halfScreenY + (buttonSpacing * data.position) - buttonOffsetY
		buttonStore[i] = button
	end
end

--[[
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
	end ]]


local function createTitle() -- create title image, called by createBackground after fadein
	local titleRect = display.newImageRect(sceneGroup, titleImage, 785, 226)
	local moveDistance = 300 --distance for movement
	local moveSpeed = 300    --time for movement
	local fadeDelay = moveSpeed /
		2                    --delay fade in by half the move speed
	titleRect.x, titleRect.y = halfScreenX,
		241 -
		moveDistance                                                                                         --final position minus the distance to move
	titleRect.alpha = 0                                                                                      --sets initial alpha to fade in
	transition.fadeIn(titleRect, { time = moveSpeed, delay = fadeDelay, transition = easing.outCubic })      --fades in image title
	transition.moveTo(titleRect,
		{ time = moveSpeed, x = halfScreenX, y = 241, onComplete = createButtons, transition = easing.inOutCirc }) --moves title to position
end


local function createMenu() --fade in the background image then create the tile
	local background = display.newGroup()
	local easingList = { easing.inBounce, easing.outBounce, easing.inOutBounce, easing.outInBounce, easing.outInElastic,
		easing.inOutQuart, easing.outInBack, easing.inOutCubic } --random easings for flicker
	local fadeInTime = 300
	local images = {}                                      --table that holds rects
	local emitters = {}

	addToCleanup(background)

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
			{ x = 498, y = 54,  w = 213, h = 219, image = "arcane_orb",    emitters = { "arcane", "glow.arcane", "smallparticles" } },
			{ x = 286, y = 49,  w = 215, h = 226, image = "shadow_orb",    emitters = { "shadow", "glow.shadow", "smallparticles" } },
			{ x = 617, y = 140, w = 263, h = 271, image = "earth_orb",     emitters = { "glow.earth", "smallparticles" } },
			{ x = 132, y = 142, w = 256, h = 273, image = "wind_orb",      emitters = { "glow.wind", "smallparticles" } },
			{ x = 587, y = 323, w = 323, h = 344, image = "ice_orb",       emitters = { "ice", "glow.ice", "smallparticles" } },
			{ x = 85,  y = 258, w = 351, h = 409, image = "lightning_orb", emitters = { "lightning", "glow.lightning", "smallparticles" } },
			{ x = 315, y = 359, w = 365, h = 411, image = "fire_orb",      emitters = { "fire", "glow.fire", "smallparticles" } },
		}

		for i = 1, #imageData do
			local data = imageData[i] --readability
			local image = display.newImageRect(background, "content/menu/" .. data.image .. ".png", data.w, data.h)
			images[i] = image
			setBloomParams(image)
			util.zeroAnchors(image)
			image.x, image.y = data.x, data.y

			local function runGlow()
				image:runGlow()
			end
			function image:runGlow()
				local easing = easingList[math.random(1, #easingList)] --pick a random easing function
				if (self.doGlow) then
					self.glowTime = math.random(2000, 2500)
					transition.to(self.fill.effect.levels,
						{ time = self.glowTime, onComplete = runGlow, transition = easing, gamma = .6 }) --flickers the image
					self.doGlow = false
				else
					self.glowTime = 4000
					transition.to(self.fill.effect.levels,
						{ time = self.glowTime, onComplete = runGlow, transition = easing, gamma = .3 }) --flickers the image
					self.doGlow = true
				end
			end

			image.doGlow = true
			image.glowTime = 1000
			image.glowTimer = timer.performWithDelay(image.glowTime, image:runGlow(), 1, "menu") --starts a timer once bg has faded in

			for j = 1, #data.emitters do
				local file, errorString = io.open(
					system.pathForFile(system.ResourceDirectory) .. "/content/particles/params/" .. data.emitters[j] ..
					".json", "r") -- Open the file handle
				--print(errorString)
				if file then
					local p = json.decode(file:read("*a"))
					io.close(file) -- Close the file handle
					local scaleFactor = data.w / 350
					if (string.find(data.emitters[j], "smallparticles") or string.find(data.emitters[j], "glow")) then
						if (string.find(data.emitters[j], "glow")) then
							p.startParticleSize = p.startParticleSize * scaleFactor
							p.finishParticleSize = p.finishParticleSize * scaleFactor
						end
						if (string.find(data.emitters[j], "smallparticles")) then
							p.startParticleSize = p.startParticleSize * (data.w / 215)
							p.finishParticleSize = p.finishParticleSize * (data.h / 215)
						end
						p.speed = p.speed * scaleFactor
						p.gravityy = p.gravityy * scaleFactor * .8
						p.sourcePositionVariancex = data.w / 2.8
						p.sourcePositionVariancey = data.h / 4
						p.maxParticles = p.maxParticles * scaleFactor
					end

					local emitter = display.newEmitter(p)
					background:insert(emitter)
					emitters[i] = emitter
					emitter.scaleX, emitter.scaleY = 3, 3
					emitter.x, emitter.y = data.x + data.w / 2, data.y + data.h * 3 / 5
				end
			end
		end
	end

	background.anchorChildren = true
	sceneGroup:insert(background)
	util.zeroAnchors(background)
	local bgw, bgh = 829,
		732           --hardcode the total size of the background as cant use contentWidth/Height with emitters(?)
	background.x, background.y = halfScreenX - bgw / 2, halfScreenY - bgh / 2 +
		150           --positions group of background images

	background.alpha = 0 --starts faded out

	createBackgroundImages()
	--initial fade in
	transition.fadeIn(background, { time = fadeInTime, onComplete = createTitle }) --fades the image in then calls function to create tile
	--glow effect
end

function scene:create(event)
	sceneGroup = self.view

	display.setDefault("background", .09, .09, .09)

	-- Called when the scene's view does not exist.
	--
	-- INSERT code here to initialize the scene
	-- e.g. add display objects to 'sceneGroup', add touch listeners, etc.
	-- all display objects must be inserted into group

	createMenu() --call function to create menu
end

function scene:show(event)
	sceneGroup = self.view
	local phase = event.phase

	print("scene loaded")
	physics.start()
	physics.setGravity(0, 0)

	if phase == "will" then
		-- Called when the scene is still off screen and is about to move on screen
	elseif phase == "did" then
		-- Called when the scene is now on screen
		--
		-- INSERT code here to make the scene come alive
		-- e.g. start timers, begin animation, play audio, etc.
		--add listener for input
		mouse:init()

		Runtime:addEventListener("key", onKeyEvent)
	end
end

function scene:hide(event)
	sceneGroup = self.view
	local phase = event.phase
	if event.phase == "will" then
		-- Called when the scene is on screen and is about to move off screen
		--
		-- INSERT code here to pause the scene
		-- e.g. stop timers, stop animation, unload sounds, etc.)
		timer.cancel("menu") --cancels all running timers
		transition.cancelAll() --cancels all transitions

		mouse:deinit()
		Runtime:removeEventListener("key", onKeyEvent)

		for i = 1, #Menu do
			Menu[i] = nil --for cleaning up the scene when the Menu is hidden.
		end
	elseif phase == "did" then
		-- Called when the scene is now off screen
		composer.removeHidden()
	end
end

function scene:destroy(event)
	--local sceneGroup = self.view
	-- Called prior to the removal of scene's "view" (sceneGroup)
	--
	-- INSERT code here to cleanup the scene
	-- e.g. remove display objects, remove touch listeners, save state, etc.
	sceneGroup = self.view
end

---------------------------------------------------------------------------------

-- Listener setup
scene:addEventListener("create", scene)
scene:addEventListener("show", scene)
scene:addEventListener("hide", scene)
scene:addEventListener("destroy", scene)

-----------------------------------------------------------------------------------------

return scene
