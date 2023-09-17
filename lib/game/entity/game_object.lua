
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

    local _dir, _nTarget, _tile --recycled
    --recycled move() vars
    local _moveTileX, _moveTileY, _moveFactor, _worldX, _worldY
    local _posDelta, _newPos, _xCheckPos, _yCheckPos = {x=0,y=0}, {x=0,y=0}, {x=0,y=0}, {x=0,y=0}
    local _xOff, _yOff, _selfRect, _selfWorld, _hcw, _hch --recycled
    local _xColCheck, _yColCheck = {minX=0,maxX=0,minY=0,maxY=0}, {minX=0,maxX=0,minY=0,maxY=0}

    local function gameObjOnFrame(self)
        --todo: check if char not name for performance
        if self.name ~= "character" then --isMoving for char is set false earlier as needs gets set true by keyinput in game.lua
            self.isMoving = false --resets moving variable to be changed by gameObject:move() if called
        end
    
        _xOff, _yOff = self.xOffset, self.yOffset --locals for performance
        _selfWorld = self.world

        if self.moveTarget then
            self:move(self.moveTargetdir)
        end

        if self.col then --object has been registered for collisions
            --if self.name == "character" then print("updating col for character") end
            collision.updatePos(self)
        end
        
        if self.rect then --object is on screen
            _selfRect = self.rect
            _selfRect.x = _selfRect.x + _xOff --doesnt need to be done on frame
            _selfRect.y = _selfRect.y + _yOff
            _tile = map:getTileAtPoint(self.x, self.y)
            --print(self.id, tile.id, tile.lightValue)
            self.lightValue = _tile.lightValue
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
            --print("move target:",self.id, self.x, self.y)
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
            _dir = util.deepcopy(util.angleToDirection(util.deltaPosToAngle({x = self.x, y = self.y}, self.moveTarget))) 
            _nTarget = util.normalizeXY(util.deltaPos(self.world, self.moveTarget))
            _dir.x, _dir.y = _nTarget.x, _nTarget.y
            self.moveTargetdir = _dir
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
            _worldX, _worldY = self.x, self.y
            _moveFactor = self.moveSpeed * gv.frame.dts
            _posDelta.x, _posDelta.y = self.moveDirection.x * _moveFactor, self.moveDirection.y * _moveFactor --moveDir gets recreated for enemies
            _newPos.x, _newPos.y = _worldX + _posDelta.x, _worldY + _posDelta.y

            --------check for wall collisions at the new position
            _hcw, _hch = self.halfColWidth, self.halfColHeight
            --we check each direction seperately so we can null the movement in that direction easily without affecting the other
            --todo: look into if we only need one tile check (probably can)
            local colMultX = setColDirMultiplier(self.moveDirection.x) --inverts the collision multiplier depending on direction of movement
            local colMultY = setColDirMultiplier(self.moveDirection.y)
            _xCheckPos.x, _xCheckPos.y = _newPos.x + _hcw * colMultX, _worldY --x and y positions to check for tiles
            _yCheckPos.x, _yCheckPos.y = _worldX, _newPos.y + _hch * colMultY
            _moveTileX = map:getTileAtPoint( _xCheckPos.x, _xCheckPos.y ) --get the tile at new position (plus collision)
            _moveTileY = map:getTileAtPoint( _yCheckPos.x, _yCheckPos.y )
            self.hitWall = false
            if (_moveTileX.col == 1) then --if the tile we want to move to has collision
                _newPos.x = _worldX --nil the movement vector in the direction of the tile
                self.hitWall = true --set a flag, checked by enemy idle state
            end
            if (_moveTileY.col == 1) then --
                _newPos.y = _worldY
                self.hitWall = true
            end
            --------check for entity collisions at the new position
            if self.col then
                _xColCheck.minX, _xColCheck.maxX = _newPos.x - _hcw, _newPos.x + _hcw
                _xColCheck.minY, _xColCheck.maxY = _worldY - _hch, _worldY + _hch
                _yColCheck.minX, _yColCheck.maxX = _worldX - _hcw, _worldX + _hcw
                _yColCheck.minY, _yColCheck.maxY = _newPos.y - _hch, _newPos.y + _hch
                if collision.checkCollisionAtBounds(self, _xColCheck.minX, _xColCheck.maxX, _xColCheck.minY, _xColCheck.maxY) then
                    _newPos.x = _worldX --nil the movement vector in the direction of the collision
                end
                if collision.checkCollisionAtBounds(self, _yColCheck.minX, _yColCheck.maxX, _yColCheck.minY, _yColCheck.maxY) then
                    _newPos.y = _worldY --nil the movement vector in the direction of the collision
                end
            end

            ------set the new position
            self.x, self.y = _newPos.x, _newPos.y
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
            self.rect.x, self.rect.y = self.x + self.xOffset, self.y + self.yOffset
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
        gameObject.x, gameObject.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        lib_gameObject.factory(gameObject) --adds functions to gameObject
        
        --gameObject:loadTextures()

        gameObject:addOnFrameMethod(gameObjOnFrame)
        

        return gameObject
    end

	return lib_gameObject