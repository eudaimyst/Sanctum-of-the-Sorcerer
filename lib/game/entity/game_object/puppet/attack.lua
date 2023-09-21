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
    local entity = require("lib.game.entity")
    local lfs = require("lfs")
    local map = require("lib.map")
    local cam = require("lib.camera")
    local light = require("lib.game.entity.light_emitter")
    local collision = require("lib.game.entity.game_object.collision")

    local basePath = "content/spells"

	-- Define module
	local lib_attack = { }
    

    local function projOnFrame(self)
        local function destroy()
            for i = 1, #self.emitters do
                --self.emitters[i].speed = 0
                --self.emitters[i]:stop()
                --self.emitters[i]:removeSelf()
            end
            print("destroying projectile")
            self:destroySelf()
        end

        local function completeProjectile( didHitObject)
            if (didHitObject) and self.hitEmitter then
                self.hitEmitter.x, self.hitEmitter.y = (self.x - cam.bounds.x1) * cam.zoom , (self.y - cam.bounds.y1) * cam.zoom
                self.hitEmitter:start()
            end
            self.complete = true
            if #self.emitters > 0 then
                for i = 1, #self.emitters do
                    print("stopping emitter"..i)
                    self.emitters[i]:stop()
                end
                print("destroying projectile in", self.emitterLifespan)
                timer.performWithDelay(self.emitterLifespan or 0, destroy)
            else --destroy the projectile with no delay if there is no emitter
                destroy()
            end
        end

        self.durationTimer = self.durationTimer + gv.frame.dts
        print(self.id, "projectileOnFrame", self.durationTimer, "/", self.duration)
        self.x = self.x + self.normal.x * self.speed * gv.frame.dts
        self.y = self.y + self.normal.y * self.speed * gv.frame.dts
        if self.complete == false then --if spell has not already hit a wall or gone past its duration
            if (map:getTileAtPoint(self.x, self.y).col == 1) then --check if the projectile has hit a wall or gone past its duration
                completeProjectile(true)
                return
            elseif (self.durationTimer > self.duration) then
                --stop the emitter but keep it alive for the duration to keep movement going
                completeProjectile(false)
                return
            end

            local hitObjects = collision.getObjectsByDistance(10, self.x, self.y) --check for collisions
            for i = 1, #hitObjects do
                local hitObject = hitObjects[i]
                if hitObject ~= self.source then
                    local alreadyHit = false
                    for ii = 1, #self.hitObjects do
                        if hitObject == self.hitObjects[ii] then
                            alreadyHit = true
                        end
                    end
                    if alreadyHit == false then
                        self.hitObjects[#self.hitObjects+1] = hitObject
                        self.source:dealDamage(hitObject, self.damage)
                        if #hitObjects > self.passthroughCount then
                            completeProjectile(true)
                            return
                        end
                    end
                end
            end
        end

        self:updateDisplayPos()
    end

    function lib_attack:new(_params, _puppet) --takes params for the new attack and the puppet that is casting it (puppet used for loading anims)

        local attack = {}
        for k, v in pairs(attackParams.default) do
            if _params[k] then
                attack[k] = _params[k]
            else
                
                attack[k] = v
            end
        end
        
        function attack:loadDisplay() --loads spell display on creation, whether image or emitter
            print("---------------loading display for "..self.name)
            -- Get raw path to the app documents directory
            local debugPath = "/content/spells/"..self.name
            local path = system.pathForFile( system.ResourceDirectory ) --if supplying a first paramater, needs to be a file, not a folder
            path = path..debugPath
            attack.textures = {}
            attack.emitterParams = {}
            for file in lfs.dir( path ) do
                if (file ~= "." and file ~= "..") then
                    if (file == "hitEmitter.json") then
                        print("Found hit emitter")
                        attack.hitEmitterParams = json.decodeFile(path.."/"..file)
                    end
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

        function attack:createProjectile(index, source) --called by attack:fire() for projectile attacks
            print("creating attack projectile")
            local projectile = entity:create(self.origin.x, self.origin.y)
            light.attachToEntity(projectile, {radius = 400, intensity = 1, exponent = .3} )
            projectile.source = source
            projectile.isProjectile = true
            projectile.displayParams = attack.displayParams[index]
            projectile.speed = attack.displayParams[index].speed
            projectile.damage = attack.damage
            projectile.passthroughCount = attack.passthroughCount
            projectile.durationTimer = 0
            projectile.normal = {x = attack.normal.x, y = attack.normal.y}
            projectile.duration = self.duration
            projectile.hitObjects = {} --store the objects hit by the projectile so we don't register multiple hits
            projectile.complete = false --gets set to true when the projectile hits a wall or goes past its duration
            if self.hitEmitterParams then
                projectile.hitEmitter = display.newEmitter( self.hitEmitterParams )
                projectile.hitEmitter:stop()
            end
            print("projectile duration: "..projectile.duration)

            function projectile:updateDisplayPos()
                for i = 1, #self.rects do
                    self.rects[i].x, self.rects[i].y = (self.x - cam.bounds.x1) * cam.zoom , (self.y - cam.bounds.y1) * cam.zoom
                end
                for i = 1, #self.emitters do
                    self.emitters[i].x, self.emitters[i].y = (self.x - cam.bounds.x1) * cam.zoom , (self.y - cam.bounds.y1) * cam.zoom
                    --print("setting emitter "..i.." to "..self.screen.x..", "..self.screen.y)
                end
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
                    ------------------
                    --- overriding emitter params for projectiles testing
                    emitterParams.angle = util.deltaToAngle(self.normal.x, self.normal.y) + 180
                    emitterParams.speed = self.speed
                    self.emitterLifespan = emitterParams.particleLifespan * 1000 --used for destroying the projectile after the emitter has finished
                    emitterParams.duration = self.duration
                    ------------------
                    local emitter = display.newEmitter( emitterParams )
                    emitter.duration = attack.maxDistance / attack.displayParams[i].speed
                    emitter.x, emitter.y = x, y
                    emitter:start()
                    self.emitters[#self.emitters+1] = emitter
                end
            end
            projectile:createDisplay(self.origin)
            print("adding on frame method for "..projectile.id)
            projectile:addOnFrameMethod(projOnFrame)
            print(projOnFrame)
        end

        function attack:fire(puppet) --called from puppet when attack anim is complete
            if (self.displayType == "projectile") then
                for i = 1, #self.displayParams do
                    self:createProjectile(i, puppet)
                end
            elseif (self.displayType == "animation") then
                local dist = util.getDistance(puppet.x, puppet.y, puppet.attackTarget.x, puppet.attackTarget.y)
                if dist <= self.range + 20 then
                    puppet:dealDamage(puppet.attackTarget, self.damage)
                end
            end
            
            print("---------------------attack "..self.name.." fired")
        end

        attack:loadDisplay() --set display type table from string name for key
        attack.icon = basePath.."/"..attack.name.."/icon.png"

        return attack
    end

	return lib_attack