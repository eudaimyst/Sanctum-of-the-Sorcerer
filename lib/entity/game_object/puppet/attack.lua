	-----------------------------------------------------------------------------------------
	--
	-- attack.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
    local attackParams = require("lib.global.attack_params")
    local json = require("json")
    local entity = require("lib.entity")
    local lfs = require("lfs")
    local map = require("lib.map")

    local basePath = "content/spells"

    local data = { --not being used
        timer = 0, currentPhase = "pre",
        cooldownTimer = 0, onCooldown = false,
        durationTimer = 0,
        origin = { x = 0, y = 0 }, --position at start of attack
        delta = { x = 0, y = 0 }, --between start and end
        target = { x = 0, y = 0 }, --position for targeted attacks
    }
    --{ width=64, height=64, numFrames = 1 }
	-- Define module
	local lib_attack = { } 

    function lib_attack:new(_params, _puppet) --takes params for the new attack and the puppet that is casting it (puppet used for loading anims)

        local attack = {}
        for k, v in pairs(data) do
            attack[k] = v
        end
        for k, v in pairs(attackParams.default) do
            if _params[k] then
                attack[k] = _params[k]
            else
                attack[k] = v
            end
        end
        
        function attack:loadDisplay() --called from end of new() - loads display for spell, whether image or emitter
            print("---------------loading display for "..self.name)
            -- Get raw path to the app documents directory
            local path = system.pathForFile( "content/spells/"..self.name, system.ResourceDirectory )
            attack.textures = {}
            attack.emitterParams = {}
            for file in lfs.dir( path ) do
                if (file ~= "." and file ~= "..") then
                    for i, _ in pairs(attack.displayParams) do
                        if (file == i..".png") then
                            print( "Found image file: " .. file )
                            attack.textures[i] = graphics.newTexture( { type = "image", filename = "content/spells/"..self.name.."/"..file, baseDir = system.ResourceDirectory } );
                        end
                        if (file == i..".json") then
                            print( "Found emitter file: " .. file )
                            local f, err = io.open( path.."/"..file, "r" )
                            local data
                            if (f) then
                                data = f:read( "*a" )
                                if (data) then
                                    print("data: "..data)
                                end
                                f:close()
                                attack.emitterParams[i] = json.decode( data )
                                print(json.prettify(attack.emitterParams[i]))
                            else
                                print("could not open file, error: "..err)
                            end
                        end
                    end
                end
            end
        end

        function attack:activate() --TODO: called by ? for ?
            print("attack "..self.name.." set to active")
        end

        function attack:deactivate() --TODO: called by ? for ?
            print("attack "..self.name.." set to inactive")
        end

        function attack:createProjectile(origin, target) --called by attack:fire() for projectile attacks
            print("creating attack projectile")
            local projectile = entity:create(origin.x, origin.y)
            attack.projectile = projectile
            projectile.speed = attack.displayParams[1].speed
            projectile.normal = attack.normal

            function projectile:updateDisplayPos()
                for i = 1, #self.rects do
                    self.rects[i].x, self.rects[i].y = self.screen.x, self.screen.y
                end
                for i = 1, #self.emitters do
                    self.emitters[i].x, self.emitters[i].y = self.screen.x, self.screen.y
                    --print("setting emitter "..i.." to "..self.screen.x..", "..self.screen.y)
                end
            end

            function projectile:projectile_onFrame()
                attack.durationTimer = attack.durationTimer + gv.frame.dts
                self.world.x = self.world.x + self.normal.x * self.speed * gv.frame.dts
                self.world.y = self.world.y + self.normal.y * self.speed * gv.frame.dts
                if (map:getTileAtPoint(self.world).col == 1) then
                    attack.durationTimer = 0
                    self:destroySelf()
                    for i = 1, #self.emitters do
                        self.emitters[i]:stop()
                    end
                end
                if (attack.durationTimer > attack.duration) then
                    attack.durationTimer = 0
                    self:destroySelf() --calls entity destroy method
                end
                self:updateDisplayPos()
            end

            function projectile:createDisplay(origin)
                local x, y = origin.x, origin.y
                print("drawing "..#attack.textures.." textures")
                self.rects = {}
                self.emitters = {}
                for i = 1, #attack.textures do
                    local texture = attack.textures[i]
                    local rect = display.newImageRect( self.group, texture.filename, texture.baseDir, 64, 64 );
                    rect.x, rect.y = x, y
                    self.rects[#self.rects+1] = rect
                end
                print("drawing "..#attack.emitterParams.." emitters")
                for i = 1, #attack.emitterParams do
                    local emitterParams = attack.emitterParams[i]
                    local emitter = display.newEmitter( emitterParams )
                    emitter.duration = attack.maxDistance / attack.displayParams[i].speed
                    emitter.x, emitter.y = x, y
                    emitter:start()
                    self.emitters[#self.emitters+1] = emitter
                end
            end
            projectile:createDisplay(origin)

            projectile:addOnFrameMethod(projectile.projectile_onFrame)
            return projectile
        end

        function attack:fire(puppet) --called from puppet when attack anim is complete
            local origin = { x = self.origin.x - puppet.finishWindupAttackOffset.x + puppet.xOffset, y = self.origin.y - puppet.finishWindupAttackOffset.y + puppet.yOffset}
            local target = { x = self.target.x, y = self.target.y }
            print(origin, target)
            if (self.displayType == "projectile") then
                attack.projectile = self:createProjectile(origin, target)
            end
            print("---------------------attack "..self.name.." fired")
        end

        attack.displayData = attack:loadDisplay() --set display type table from string name for key
        attack.icon = basePath.."/"..attack.name.."/icon.png"

        return attack
    end

	return lib_attack