
    -----------------------------------------------------------------------------------------
	--
	-- game_object.lua
	-- Features:
    ------------------
    -- Static or animated display objects, which can move from its location to a point, optionally following an eased path
    -- Contains:
    ------------------
    -- Display Object both static and animated which is added to the entities group
    -- Movement logic, both directional and to a specified world co-ords
    -- No thinkers, will not move by default unless extended and a function is called, or by an external source
    -- Gameplay Data like HP, level, element etc…
    -- Extends OnDestroyed and OnCreated with relevant game mechanics, ie spawning loot for a barrel
    -- Functions that update the displayGroup to the camera bounds
    -- OnInteract(), OnTakeDamage()

	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
    local gv = require("lib.global.variables")
	--local util = require("lib.global.utilities")
    local entity = require("lib.game.entity")
    local cam = require("lib.camera")
    local map = require("lib.map")
    local util = require("lib.global.utilities")
    local json = require("json")
    local lfs = require("lfs")
    local collision = require("lib.game.entity.game_object.collision")

	-- Define module
	local lib_gameObject = {}

    local defaultParams = {
        name = "default",
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        moveSpeed = 100, colWidth = 50, colHeight = 50,
        width = 96, height = 96, xOffset = 0, yOffset = 0, --display data
        image = "default.png", path = "content/game_objects/", fName = "",
        spawnPos = { x = 0, y = 0 },
        directional = false, moveDirection = gc.move.down, facingDirection = gc.move.down,
        isMoving = false,
        lightValue = 0,
        moveTarget = nil --target position relative to the game object
    }

    local t_dir, t_nTarget, t_tile --recycled
    --recycled move() vars
    local t_moveTileX, t_moveTileY, t_moveFactor, t_worldX, t_worldY
    local t_posDelta, t_newPos = {x=0,y=0}, {x=0,y=0}
    local t_xCheckPos, t_yCheckPos = {x=0,y=0}, {x=0,y=0}
    local t_xOff, t_yOff
    local selfRect, selfCol, selfWorld, hcw, hch --recycled

    local function gameObjOnFrame(self)
        --todo: check if char not name for performance
        if self.name ~= "character" then --isMoving for char is set false earlier as needs gets set true by keyinput in game.lua
            self.isMoving = false --resets moving variable to be changed by gameObject:move() if called
        end
    
        t_xOff, t_yOff = self.xOffset, self.yOffset --locals for performance
        selfWorld = self.world

        if self.moveTarget then
            self:move(self.moveTargetdir)
        end

        if self.col then --object has been registered for collisions
            --if self.name == "character" then print("updating col for character") end
            collision.updatePos(self)
        end
        
        if self.rect then --object is on screen
            selfRect = self.rect
            selfRect.x = selfRect.x + t_xOff --doesnt need to be done on frame
            selfRect.y = selfRect.y + t_yOff
            t_tile = map:getTileAtPoint(selfWorld)
            --print(self.id, tile.id, tile.lightValue)
            self.lightValue = t_tile.lightValue
        end
    end

    function lib_gameObject.factory(gameObject)
		--print("adding gameObject functions")

        function gameObject:takeDamage(source, val)
            self.currentHP = self.currentHP - val
            print("--------DAMAGE--------")
            print(self.name, self.id, "took", val, "damage from", source.name, source.id)
            if self.onTakeDamage then
                self:onTakeDamage()
            end
        end

        function gameObject:dealDamage(target, val)
            target:takeDamage(self, val)
            if self.onDealDamage then
                self:onDealDamage()
            end
        end

        function gameObject:setMoveTarget(pos) --once move target is set, then onFrame will know to call the move function to the constructed moveTarget
            --print(json.prettify(self))
            --print("move target:",self.id, self.world.x, self.world.y)
            if (util.compareFuzzy(self.world, pos)) then
                print(self.id, " already at target position")
                if self.reachedMoveTarget then
                    self:reachedMoveTarget()
                end
                return
            end
            self.moveTarget = pos
            --directions were originally intended to be constants and not intended to have their values changed
            --TODO: come up with a proper direction framework that is not accessed as constants
            t_dir = util.deepcopy(util.angleToDirection(util.deltaPosToAngle(self.world, self.moveTarget))) 
            t_nTarget = util.normalizeXY(util.deltaPos(self.world, self.moveTarget))
            t_dir.x, t_dir.y = t_nTarget.x, t_nTarget.y
            self.moveTargetdir = t_dir
            --print(self.id, "target dir: ", dir.x, dir.y)
        end

        function gameObject:move(dir) --called each frame from key_input by scene, also onFrame if moveTarget is set
            local function setColDirMultiplier(dirAxis)
                if dirAxis < 0 then return -1
                else return 1
                end
            end

            if (self.currentAttack) then --todo:add check if attack allows moving
                return
            end
            self.isMoving = true --prevents spell casting, set to false in onFrame method
            self:setMoveDirection(dir) --sets move direction and updates the facing direction

            --------calculate the new position to move to
            t_worldX, t_worldY = self.world.x, self.world.y
            t_moveFactor = self.moveSpeed * gv.frame.dts
            t_posDelta.x, t_posDelta.y = self.moveDirection.x * t_moveFactor, self.moveDirection.y * t_moveFactor --moveDir gets recreated for enemies
            t_newPos.x, t_newPos.y = t_worldX + t_posDelta.x, t_worldY + t_posDelta.y

            --------check for wall collisions at the new position
            hcw, hch = self.halfColWidth, self.halfColHeight
            --we check each direction seperately so we can null the movement in that direction easily without affecting the other
            --todo: look into if we only need one tile check (probably can)
            local colMultX = setColDirMultiplier(self.moveDirection.x) --inverts the collision multiplier depending on direction of movement
            local colMultY = setColDirMultiplier(self.moveDirection.y)
            t_xCheckPos.x, t_xCheckPos.y = t_newPos.x + hcw * colMultX, t_worldY --x and y positions to check for tiles
            t_yCheckPos.x, t_yCheckPos.y = t_worldX, t_newPos.y + hch * colMultY
            t_moveTileX = map:getTileAtPoint( t_xCheckPos ) --get the tile at new position (plus collision)
            t_moveTileY = map:getTileAtPoint( t_yCheckPos )
            self.hitWall = false
            if (t_moveTileX.col == 1) then --if the tile we want to move to has collision
                t_newPos.x = t_worldX --nil the movement vector in the direction of the tile
                self.hitWall = true --set a flag, checked by enemy idle state
            end
            if (t_moveTileY.col == 1) then --
                t_newPos.y = t_worldY
                self.hitWall = true
            end
            --------check for entity collisions at the new position
            if self.col then
                local colCheckX = {  minX = t_newPos.x - hcw, maxX = t_newPos.x + hcw,
                                    minY = t_worldY - hch, maxY = t_worldY + hch }
                local colCheckY = {  minX = t_worldX - hcw, maxX = t_worldX + hcw,
                                    minY = t_newPos.y - hch, maxY = t_newPos.y + hch }
                if collision.checkCollisionAtBounds(self, colCheckX.minX, colCheckX.maxX, colCheckX.minY, colCheckX.maxY) then
                    t_newPos.x = t_worldX --nil the movement vector in the direction of the collision
                end
                if collision.checkCollisionAtBounds(self, colCheckY.minX, colCheckY.maxX, colCheckY.minY, colCheckY.maxY) then
                    t_newPos.y = t_worldY --nil the movement vector in the direction of the collision
                end
            end

            ------set the new position
            self.world.x, self.world.y = t_newPos.x, t_newPos.y
            --check if reached move target
            if util.compareFuzzy(self.world, self.moveTarget) then
                self.moveTarget = nil --mark as nil to stop moving
            end
        end

        function gameObject:loadTextures() --called when created
            if (self.directional) then
                self.textures = {}
                
                for dir, _ in pairs(gc.move) do
                    self.textures[dir] = graphics.newTexture({type="image", filename=self.path..self.name.."/"..dir..".png", baseDir=system.ResourceDirectory})
                end
                self.texture = self.textures[self.facingDirection] --sets initial texture from current direction in stored table
            else
                self.texture = graphics.newTexture({type="image", filename=self.path..self.name..".png", baseDir=system.ResourceDirectory}) --set initial texture
            end
            
        end

        function gameObject:setMoveDirection(dir) --sets move direction and forces updating facing direction
            self.moveDirection = dir
            self:setFacingDirection(dir)
        end

        function gameObject:setFacingDirection(dir) --sets facing direction and re-creates rect
            self.facingDirection = dir
            self:updateRectImage()
        end

        function gameObject:updateRectImage() --called to update image of rect, override by puppets
            --print(json.prettify(self.textures))
            if (self.rect) then
                local texture
                local s_dir = self.facingDirection.image
                local dirTex = self.textures[s_dir]
                if (self.directional) then
                    --print(self.facingDirection.image)
                    texture = dirTex
                    else
                    texture = self.texture
                end
                self:destroyRect()
                self:makeRect()
                self.rect:setFillColor(self.lightValue)
            --print("updated rect image")
            else
                print("WARNING: rect doesn't exist game obj", self.id)
            end
        end

		function gameObject:makeRect() --makes game objects rect if doesn't exist, overriden by puppet
            if (self.rect) then
                print("calling gameObj:makeRect when it already exists", self.id)
                return
            end
            self.rect = display.newImageRect(self.group, self.texture.filename, self.texture.baseDir, self.width, self.height)
            self.rect.x, self.rect.y = self.world.x + self.xOffset, self.world.y + self.yOffset
            --collision.registerObject(self)
		end

		function gameObject:destroyRect() --destroys rect if exists
            if (self.rect) then
                self.rect:removeSelf()
                self.rect = nil
                --collision.deregisterObject(self)
            end
		end

        function gameObject:deregisterCollision() --called from entity when destroying self, should use a onDestroy call instead
            collision.deregisterObject(self)
        end
    end
    
    function lib_gameObject:create(_params) --creates gameObject
        --print("creating gameObject")

        local gameObject = entity:create() --creates the entity using the entity module and bases the object off of it
        
		gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
        gameObject.halfColWidth, gameObject.halfColHeight = gameObject.colWidth/2, gameObject.colHeight/2
        gameObject.world.x, gameObject.world.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        lib_gameObject.factory(gameObject) --adds functions to gameObject
        
        --gameObject:loadTextures()

        gameObject:addOnFrameMethod(gameObjOnFrame)
        

        return gameObject
    end

	return lib_gameObject