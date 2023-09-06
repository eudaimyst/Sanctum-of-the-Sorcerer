
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

	-- Define module
	local lib_gameObject = {}

    local defaultParams = {
        name = "default",
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        moveSpeed = 100,
        width = 96, height = 96, xOffset = 0, yOffset = 0, --display data
        image = "default.png", path = "content/game_objects/", fName = "",
        spawnPos = { x = 0, y = 0 },
        directional = false, moveDirection = gc.move.down, facingDirection = gc.move.down,
        isMoving = false,
        lightValue = 0,
        moveTarget = nil --target position relative to the game object
    }

    local dts = gv.frame.dts --local ref for performance

    local t_dir, t_nTarget, t_tile --recycled
    --recycled move() vars
    local t_moveTileX, t_moveTileY, t_moveFactor, t_worldX, t_worldY
    local t_posDelta, t_newPos = {x=0,y=0}, {x=0,y=0}
    local t_xCheckPos, t_yCheckPos = {x=0,y=0}, {x=0,y=0}
            
    local function gameObjOnFrame(self)
        if self.name ~= "character" then --isMoving for char is set false earlier as needs gets set true by keyinput in game.lua
            self.isMoving = false --resets moving variable to be changed by gameObject:move() if called
        end
        if self.moveTarget then
            self:move(self.moveTargetdir)
        end
        if self.rect then
            self.rect.x = self.rect.x + self.xOffset
            self.rect.y = self.rect.y + self.yOffset
            t_tile = map:getTileAtPoint(self.world)
            --print(self.id, tile.id, tile.lightValue)
            self.lightValue = t_tile.lightValue
        end
    end

    function lib_gameObject.gameObjectFactory(gameObject)
		--print("adding gameObject functions")

        function gameObject:takeDamage(source, val)
            self.currentHP = self.currentHP - val
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
            
            if (self.currentAttack) then --puppets use this logic for movement
                print("can't move while attacking")
                return
            end
            --[[ if self.name == "character" then
                print("character is moving", gv.frame.current)
            end ]]
            self.isMoving = true
            self:setMoveDirection(dir) --sets move direction and updates the facing direction
            t_worldX, t_worldY = self.world.x, self.world.y
            t_moveFactor = self.moveSpeed * gv.frame.dts
            t_posDelta.x, t_posDelta.y = self.moveDirection.x * t_moveFactor, self.moveDirection.y * t_moveFactor
            t_newPos.x, t_newPos.y = t_worldX + t_posDelta.x, t_worldY + t_posDelta.y
            t_xCheckPos.x, t_xCheckPos.y = t_newPos.x, t_worldY
            t_yCheckPos.x, t_yCheckPos.y = t_worldX, t_newPos.y
            t_moveTileX = map:getTileAtPoint( t_xCheckPos )
            t_moveTileY = map:getTileAtPoint( t_yCheckPos )
            if (t_moveTileX.col == 1) then --if hitting a wall check reset the move target to recalculate move direction
                t_newPos.x = self.world.x
                if (self.moveTarget) then
                    self:setMoveTarget(self.moveTarget)
                end
            end
            if (t_moveTileY.col == 1) then
                t_newPos.y = self.world.y
                if (self.moveTarget) then
                    self:setMoveTarget(self.moveTarget)
                end
            end
            self.world.x, self.world.y = t_newPos.x, t_newPos.y
            if util.compareFuzzy(self.world, self.moveTarget) then
                self.moveTarget = nil --mark as nil to stop moving
                if self.reachedMoveTarget then
                    self:reachedMoveTarget()
                end
				--print (self.name, self.id, "has reached its move target")
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

		function gameObject:makeRect() --makes game objects rect if doesn't exist
            if (self.rect) then
                print("calling gameObj:makeRect when it already exists", self.id)
                return
            end
            self.rect = display.newImageRect(self.group, self.texture.filename, self.texture.baseDir, self.width, self.height)
            self.rect.x, self.rect.y = self.world.x + self.xOffset, self.world.y + self.yOffset
		end

		function gameObject:destroyRect() --destroys rect if exists
            if (self.rect) then
                self.rect:removeSelf()
                self.rect = nil
            end
		end
    end

    function lib_gameObject:create(_params) --creates gameObject
        --print("creating gameObject")

        local gameObject = entity:create() --creates the entity using the entity module and bases the object off of it
        
		--print("setting gameObject params") --entity function
        gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
		--print("GAME OBJECT PARAMS:--------\n" .. json.prettify(gameObject) .. "\n----------------------")

        gameObject.world.x, gameObject.world.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        lib_gameObject.gameObjectFactory(gameObject) --adds functions to gameObject

        --gameObject:loadTextures()

        gameObject:addOnFrameMethod(gameObjOnFrame)

        print("gameObject created with id: ", gameObject.objID)
        return gameObject
    end

	return lib_gameObject