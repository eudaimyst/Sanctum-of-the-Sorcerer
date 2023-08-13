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
    local entity = require("lib.entity")

    local displayData = { --the display of each attack is broken up into 3 parts
        start = {textures = {}, emitters = {}}, --when the attack entity is created
        middle = {textures = {}, emitters = {}}, --while the attack exists
        finish = {textures = {}, emitters = {}}, --when the attack timer has reached its duration
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

        local attack = entity:create()
        attack:setParams(attackParams.default, _params)
        
        function attack:loadDisplay()

        end

        function attack:activate()
            print("attack "..self.name.." set to active")
        end

        function attack:fire()
            print("attack "..self.name.." fired")
            --print(json.prettify(self))
             
        end
        print(json.prettify(attack))
        attack.displayData = attack:loadDisplay() --set display type table from string name for key
        attack.icon = basePath.."/"..attack.name.."/icon.png"


        return attack
    end

	return lib_attack