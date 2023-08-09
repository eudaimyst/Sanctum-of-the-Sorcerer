	-----------------------------------------------------------------------------------------
	--
	-- attack.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")

    local displayTypes = {
        image = { fPath = "", width = 64, height = 64, rotates = false },
        emitter = { fPath = ""},
    }

    local defaultParams = {
        name = "default_fireball",
        displayType = "image", --"image", "emitter"
        displayScale = 1, --size of spell display normalised to 64 pixels
        element = gc.elements.fire,
        duration = 1, --lifetime of the spell
        maxDistance = 500, --max distance spell can travel
        targetType = "point", --"point", "entity", "area", "none"
        boundAngle = 30, --limits the angle of attack with radius
        radiates = false, --spell radiates from origin rather than appearing at once
        damage = 10, --shorthand for applying an effect (TODO: change to effect)
        cooldown = 3, --time before attack can be cast again
        range = -1, --maximum distance for attack target
        channelTime = -1, --sticks between main and post for the channel duration until cancelled
        phase = {
            pre = {duration = 0.2}, --plays anim to move to windup pose
            windup = {duration = 0.2}, --sticks at windup until attack is ready to fire
            main = {duration = 0.2}, --animation to fire attack when complete
            post = {duration = 0.2}, --after attack is fired before returning to idle
        },
        icon = "",
    }

    local defaultData = {
        timer = 0, currentPhase = "pre",
        cooldownTimer = 0, onCooldown = false,
        startPos = { x = 0, y = 0 }, --position at start of attack
        deltaPos = { x = 0, y = 0 }, --between start and end
        targetPos = { x = 0, y = 0 }, --position for targeted attacks
    }

	-- Define module
	local lib_attack = { }

    function lib_attack:new(_params)
        local attack = util.deepcopy(defaultData)
        attack.params = util.deepcopy(defaultParams)
        if _params then
            for k,v in pairs(_params) do
                attack[k] = v
            end
        end
        return attack
    end

	return lib_attack