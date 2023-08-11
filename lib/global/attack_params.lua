	-----------------------------------------------------------------------------------------
	--
	-- attack_params.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")

	-- Define module
	local params = {}

    params.default = { --default params, these are overriden when specified in params
        name = "default_attack", --checks this folder name for images/emitter
        displayType = "image", --"image", "emitter"
        displayScale = 1, --size of attack display normalised to 64 pixels
        element = gc.elements.fire,
        duration = 1, --lifetime of the attack
        targetType = "point", --"point", "entity", "self", "none"
        radius = -1, --circular radius of an aoe attack
		shape = nil, --specified points of shape of an aoe attack
        maxDistance = 500, --max distance attack can travel
        boundAngle = 30, --limits the angle of attack with radius
        radiates = true, --attack radiates (or travels) from origin rather than appearing at target
        damage = 10, --shorthand for applying an effect (TODO: change to effect)
        cooldown = 3, --time before attack can be cast again
        range = -1, --maximum distance for attack target
        channelTime = -1, --sticks between main and post for the channel duration until cancelled
        windupTime = 0.5, --how long before the attack is fired
        windupGlow = false, --whether or not to display a glowing emitter during windup 
    }

	return params