
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
    local entity = require("lib.entity")
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

    local function gameObjOnFrame(self)
        if self.name ~= "character" then --isMoving for char is set false earlier as needs gets set true by keyinput in game.lua
            self.isMoving = false --resets moving variable to be changed by gameObject:move() if called
        end
        
        if self.moveTarget then
            --directions were originally intended to be constants and not intended to have their values changed
            --TODO: come up with a proper direction framework that is not accessed as constants
            local dir = util.deepcopy(self.facingDirection) 
            local normalTarget = util.normalizeXY(util.deltaPos(self.world, self.moveTarget))
            dir.x, dir.y = normalTarget.x, normalTarget.y
            self:move(dir)
            if util.compareFuzzy(self.world, self.moveTarget) then
                self.moveTarget = nil --mark as nil to stop moving
				--print (self.name, self.id, "has reached its move target")
            end
        end
        if self.rect then
            self:updateLightValue()
        end
    end

    function lib_gameObject.gameObjectFactory(gameObject)
		--print("adding gameObject functions")

        function gameObject:setMoveTarget(pos) --once move target is set, then onFrame will know to call the move function to the constructed moveTarget
            --print(json.prettify(self))
            --print("move target:",self.id, self.world.x, self.world.y)
            if (util.compareFuzzy(self.world, pos)) then
                print("move target is same as current position")
                return
            end
            local angle = util.deltaPosToAngle(self.world, pos)
            self:setFacingDirection(util.angleToDirection(angle))
            --print(self.id, "target dir: ", dir.x, dir.y)
            self.moveTarget = pos
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
            
            local posDelta = { x = self.moveDirection.x * self.moveSpeed * gv.frame.dts, y = self.moveDirection.y * self.moveSpeed * gv.frame.dts }
            local newPos = { x = self.world.x + posDelta.x, y = self.world.y + posDelta.y }
            local newTileX = map:getTileAtPoint( { x = newPos.x, y = self.world.y  } )
            local newTileY = map:getTileAtPoint( { x = self.world.x, y = newPos.y  } )
            if newTileX.col == 1 then newPos.x = self.world.x; self.moveTarget = nil end
            if newTileY.col == 1 then newPos.y = self.world.y; self.moveTarget = nil end
            self.world.x, self.world.y = newPos.x, newPos.y
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
                print("GAME OBJECT UPDATE RECT IMAGE: rect for "..self.name.."doesn't exist")
            end
        end

		function gameObject:makeRect() --makes game objects rect if doesn't exist
            if (self.rect) then
                print("rect already created")
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