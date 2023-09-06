	-----------------------------------------------------------------------------------------
	--
	-- attack_params.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")

	-- Define module
	local params = {}

    --stores the frame data for loading textures and playing animation through puppet anim system
    local attackAnim = { frames = 12, windupStart = 4, windupEnd = 7, attackFrame = 10 }

    --unused, instead use these examples to set displayParams
    local displayTypes = { 
        beam = { [1] = {segments = 1, segmentOffset = 0} },
        projectile = { [1] = {speed = 1, rotates = false, endScale = 1} },
        aoe = { [1] = {imageCount = 1, radiates = false} } }

    --default params, these are overriden when specified in params
    params.default = {
        name = "default_attack", --checks this folder name for images/emitter
        animation = "attack", --name of animation to play, images stored in puppets content folder
        animData = attackAnim,
        displayType = "projectile", --"image", "emitter"
        displayParams = { [1] = {speed = 100, spins = false, endScale = 1} }, --number of images/emitters to display and their properties
        displayScale = 1, --size of attack display normalised to 64 pixels
        element = gc.elements.fire,
        targetType = "point", --"point", "entity", "self", "none"
        radius = -1, --circular radius of an aoe attack
        boundAngle = 30, --limits the angle of attack with radius
		shape = nil, --specified points of shape of an aoe attack
        maxDistance = 500, --max distance attack can travel
        damage = 10, --shorthand for applying an effect (TODO: change to effect)
        cooldown = 3, --time before attack can be cast again
        range = -1, --maximum distance for attack target
        channelTime = -1, --sticks between main and post for the channel duration until cancelled
        windupTime = 0.5, --how long animation loops windup frames
        windupGlow = nil, --whether or not to display a glowing emitter during windup 
    }

    params.tailSwipe = {
        name = "tailSwipe", --checks this folder name for images/emitter
        animation = "attack_spin", --name of animation to play, images stored in puppets content folder
        displayType = "animation",
        range = 50,
        animData = { frames = 12, attackFrame = 7 },
        radius = 100,
        boundAngle = 120,
        windupTime = 0, --how long animation loops windup frames
    }

	return params