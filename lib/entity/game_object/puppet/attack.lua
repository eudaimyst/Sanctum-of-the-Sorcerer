	-----------------------------------------------------------------------------------------
	--
	-- attack.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
    local attackParams = require("lib.global.attack_params")
    local json = require("json")

    local displayTypes = {
        image = { fPath = "", width = 64, height = 64, rotates = false },
        emitter = { fPath = ""},
    }

    local basePath = "content/spells"

    local data = {
        timer = 0, currentPhase = "pre",
        cooldownTimer = 0, onCooldown = false,
        origin = { x = 0, y = 0 }, --position at start of attack
        delta = { x = 0, y = 0 }, --between start and end
        target = { x = 0, y = 0 }, --position for targeted attacks
    }

	-- Define module
	local lib_attack = { }

    function lib_attack:new(_params)

        local attack = util.deepcopy(data)
        attack.params = util.deepcopy(attackParams.default)
        
        if _params then
            for k,v in pairs(_params) do
                attack.params[k] = v
            end
        end
        
        attack.params.displayType = util.deepcopy(displayTypes[attack.params.displayType]) --set display type table from string name for key
        attack.params.icon = basePath.."/"..attack.params.name.."/icon.png"

        function attack:activate()
            print("attack "..self.params.name.." set to active")
        end

        function attack:fire()
            print("attack "..self.params.name.." fired")
            print(json.prettify(self))
             
        end

        return attack
    end

	return lib_attack