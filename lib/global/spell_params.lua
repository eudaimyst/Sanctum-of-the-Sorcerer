	-----------------------------------------------------------------------------------------
	--
	-- spell_data
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")

    local windupPos, castPos
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

    local function scaleTable(t)
        --scales char hand locations to match scaled character image TODO: use actual values to support zooming
        local i = {w = 192, h = 192}
        local c = {w = 128, h = 128}
        local s = {x = c.h/i.h, y = c.h/i.h}
        for k, v in pairs(t) do
            v.x = i.w * .5 - v.x
            v.y = i.h * .5 - v.y
            --print("unscaled\n"..k..":  ".."x: "..v.x.." y: "..v.y)
            v.x = math.round(v.x * s.x)
            v.y = math.round(v.y * s.y)
            --print("scaled\n"..k..":  ".."x: "..v.x.." y: "..v.y)
        end
        return t
    end

    local castProj = { frames = 12, windupStartFrame = 4, windupEndFrame = 7, attackFrame = 10,
        windupPos = scaleTable({ 
            down = { x = 73, y = 72 },
            down_left = { x = 124, y = 85 },
            down_right = { x = 62, y = 85 },
            left = { x = 128, y = 86 },
            right = { x = 58, y = 94 },
            up = { x = 112, y = 106 },
            up_left = { x = 134, y = 99 },
            up_right = { x = 80, y = 110 }
        } ),
        attackPos = scaleTable({
            down = { x = 85, y = 124 },
            down_left = { x = 34, y = 105 },
            down_right = { x = 145, y = 115 },
            left = { x = 32, y = 85 },
            right = { x = 160, y = 91 },
            up = { x = 105, y = 58 },
            up_left = { x = 55, y = 64 },
            up_right = { x = 145, y = 70 }
        } ) }

    local castRaise = { frames = 17, windupStartFrame = 7, windupEndFrame = 8, attackFrame = 12,
        windupPos = scaleTable({ 
            down = { x = 90, y = 114 },
            down_left = { x = 68, y = 137 },
            down_right = { x = 117, y = 142 },
            left = { x = 62, y = 120 },
            right = { x = 120, y = 126 },
            up = { x = 99, y = 114 },
            up_left = { x = 74, y = 112 },
            up_right = { x = 123, y = 119 }
        } ),
        attackPos = scaleTable({
            down = { x = 88, y = 24 },
            down_left = { x = 88, y = 28 },
            down_right = { x = 88, y = 32 },
            left = { x = 92, y = 34 },
            right = { x = 97, y = 35 },
            up = { x = 103, y = 18 },
            up_left = { x = 94, y = 19 },
            up_right = { x = 105, y = 21 }
        } ) }

    params.animations = { cast_proj = castProj, cast_raise = castRaise } --this table is used for loading textures, the key names are the folder names for the animations

    params.fireBolt = {
        animation = "cast_proj",
        name = "fireBolt",
        displayType = "projectile", --"image", "emitter"
        windupTime = 1,
        duration = 100, --lifetime of the attack
        displayParams = { [1] = {speed = 600, spins = false, endScale = 1} }, --number of images/emitters to display and their properties
        windupGlow = true,
        element = gc.elements.fire
    }
    params.earthBolt = {
        animation = "cast_raise",
        name = "earthBolt",
        displayType = "projectile", --"image", "emitter"
        windupTime = 0,
        --duration = 100, --lifetime of the attack
        displayParams = { [1] = {speed = 300, spins = false, endScale = 1} }, --number of images/emitters to display and their properties
        windupGlow = true,
        element = gc.elements.earth
    }
    params.iceStorm = {
        animation = "cast_raise",
        name = "iceStorm",
        windupGlow = true,
        displayType = "aoe",
        displayParams = {},
        isChanneled = true,
        element = gc.elements.ice
    }
    params.iceStormCast = {
        animation = "cast_raise",
        name = "iceStorm",
        windupGlow = true,
        displayType = "aoe",
        isChanneled = true,
        element = gc.elements.ice
    }
    params.airBolt = {
        animation = "cast_proj",
        name = "airBolt",
        displayType = "projectile", --"image", "emitter"
        displayParams = { [1] = {speed = 600, spins = false, endScale = 1} }, --number of images/emitters to display and their properties
        windupGlow = true,
        element = gc.elements.air
    }

    for _, v in pairs(params) do --add the animData to each spell based off its animation name for easy access
        if (v.animation) then
            v.animData = params.animations[v.animation]
        end
    end
	
	return params