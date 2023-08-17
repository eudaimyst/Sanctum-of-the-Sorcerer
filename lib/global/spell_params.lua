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
        animation = "attack", --name of animation to play, images stored in puppets content folder
        animData = attackAnim,
        displayType = "projectile", --"image", "emitter" --!!whether emitters or images are used is determined by files in folder, both are attempted laoded!!
        displayParams = { [1] = {speed = 600, spins = false, endScale = 1} }, --number of images/emitters to display and their properties
        displayScale = 1, --size of attack display normalised to 64 pixels
        element = gc.elements.fire,
        duration = 1, --lifetime of the attack
        targetType = "point", --"point", "entity", "self", "none"
        radius = -1, --circular radius of an aoe attack
        boundAngle = 30, --limits the angle of attack with radius
		shape = nil, --specified points of shape of an aoe attack
        maxDistance = 500, --max distance attack can travel
        damage = 10, --shorthand for applying an effect (TODO: change to effect)
        cooldown = 3, --time before attack can be cast again
        range = -1, --maximum distance for attack target
        channelTime = -1, --sticks between main and post for the channel duration until cancelled
        windupTime = 0.5, --how long before the attack is fired
        windupGlow = false, --whether or not to display a glowing emitter during windup 
    }]]

    --TODO: replace rate with duration
    local castProj = { --stores the frame data for loading textures and playing animation through puppet anim system
        pre = { frames = 3, rate = 20, loop = false },
        windup = { frames = 4, rate = 12, loop = true },
        main = { frames = 3, rate = 8, loop = false },
        post = { frames = 2, rate = 10, loop = false },
    }

    local castRaise = {
        pre = { frames = 5, rate = 20, loop = false },
        windup = { frames = 3, rate = 12, loop = true },
        main = { frames = 3, rate = 8, loop = false },
        post = { frames = 4, rate = 20, loop = false },
    }

    params.fireBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "fireBolt",
        windupGlow = true,
        element = gc.elements.fire
    }
    params.iceStorm = {
        animation = "cast_raise",
        animData = castRaise,
        name = "iceStorm",
        windupGlow = true,
        element = gc.elements.ice
    }
    params.earthBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "earthBolt",
        windupGlow = true,
        element = gc.elements.earth
    }
    params.lightningBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "lightningBolt",
        windupGlow = true,
        element = gc.elements.lightning
    }
    params.airBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "airBolt",
        windupGlow = true,
        element = gc.elements.air
    }
    params.arcaneBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "arcaneBolt",
        windupGlow = true,
        element = gc.elements.arcane
    }
    params.shadowBolt = {
        animation = "cast_proj", --name of animation to play, images stored in puppets content folder
        animData = castProj,
        name = "shadowBolt",
        windupGlow = true,
        element = gc.elements.shadow
    }

	
	return params