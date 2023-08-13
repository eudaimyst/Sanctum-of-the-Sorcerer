	-----------------------------------------------------------------------------------------
	--
	-- spell_data
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")

	-- Define module
	local params = {}

	---------- THESE ARE FOR REFERENCE ONLY, DEFAULT VALUES FOR ATTACK.LUA TAKEN FROM ATTACK_PARAMS.LUA ------------------
    --[[
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
        windupGlow = true, --whether or not to display a glowing emitter during windup
    }]]

    params.fireBolt = {
        name = "fireBolt",
        windupGlow = true,
        element = gc.elements.fire
    }
    params.iceBolt = {
        name = "iceBolt",
        windupGlow = true,
        element = gc.elements.ice
    }
    params.earthBolt = {
        name = "earthBolt",
        windupGlow = true,
        element = gc.elements.earth
    }
    params.lightningBolt = {
        name = "lightningBolt",
        windupGlow = true,
        element = gc.elements.lightning
    }
    params.airBolt = {
        name = "airBolt",
        windupGlow = true,
        element = gc.elements.air
    }
    params.arcaneBolt = {
        name = "arcaneBolt",
        windupGlow = true,
        element = gc.elements.arcane
    }
    params.shadowBolt = {
        name = "shadowBolt",
        windupGlow = true,
        element = gc.elements.shadow
    }

	
	return params