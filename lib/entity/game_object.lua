
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
    lib_gameObject.store = {}

    local defaultParams = {
        name = "default",
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        moveSpeed = 100,
        width = 96, height = 96, xOffset = 0, yOffset = 0, --display data
        image = "default.png", path = "content/game_objects/", fName = "",
        spawnPos = { x = 0, y = 0 },
        directional = false, moveDirection = gc.move.down, facingDirection = gc.move.down,
        isMoving = false,
        moveTarget = nil --target position relative to the game object
    }

    local function gameObjOnFrame(self)
        if self.moveTarget then
            self:move(self.moveTarget)
            if util.compareFuzzy(self.world, self.moveTarget) then
                self.moveTarget = nil --mark as nil to stop moving
				print (self.name, self.id, "has reached its move target")
            end
        end
    end

    function lib_gameObject.gameObjectFactory(gameObject)
		print("adding gameObject functions")

        function gameObject:setMoveTarget(pos) --once move target is set, then onFrame will know to call the move function to the constructed moveTarget
            --print(json.prettify(self))
            --print("move target:",self.id, self.world.x, self.world.y)
            local normalTarget = util.normalizeXY(util.deltaPos(self.world, pos))
            local angle = util.deltaPosToAngle(self.world, pos)
            --directions were originally intended to be constants and not intended to have their values changed
            --TODO: come up with a proper direction framework that is not accessed as constants
            local dir = util.deepcopy(util.angleToDirection(angle)) 
            dir.x, dir.y = normalTarget.x, normalTarget.y
            --print(self.id, "target dir: ", dir.x, dir.y)
            self.moveTarget = dir
        end

        function gameObject:move(dir) --called each frame from key_input by scene, also onFrame if moveTarget is set
            
            if (self.currentAttack) then --puppets use this logic for movement
                print("can't move while attacking")
                return
            end
            if self.name == "character" then
                --print("moving "..self.name.." with id "..self.id.." in dirrection: "..dir.image)
            end
            self.isMoving = true
            self:setMoveDirection(dir) --sets move direction and updates the facing direction
            
            local posDelta = { x = self.moveDirection.x * self.moveSpeed * gv.frame.dts, y = self.moveDirection.y * self.moveSpeed * gv.frame.dts }
            local newPos = { x = self.world.x + posDelta.x, y = self.world.y + posDelta.y }
            local newTileX = map:getTileAtPoint( { x = newPos.x, y = self.world.y  } )
            local newTileY = map:getTileAtPoint( { x = self.world.x, y = newPos.y  } )
            if newTileX.col == 1 then newPos.x = self.world.x end
            if newTileY.col == 1 then newPos.y = self.world.y end
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
                self.rect.fill = {
                    type = "image",
                    filename = texture.filename,     -- "filename" property required
                    baseDir = texture.baseDir       -- "baseDir" property required
                }
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

    function lib_gameObject:storeObject(gameObject) --stores gameObject
        gameObject.objID = #self.store + 1 --creates the object id --NOTE: Different to entity id
        self.store[gameObject.objID] = gameObject --stores the object in this modules store of object
    end

    function lib_gameObject:create(_params) --creates gameObject
        print("creating gameObject")

        local gameObject = entity:create() --creates the entity using the entity module and bases the object off of it
        
		print("setting gameObject params") --entity function
        gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
		--print("GAME OBJECT PARAMS:--------\n" .. json.prettify(gameObject) .. "\n----------------------")

        gameObject.world.x, gameObject.world.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        lib_gameObject.gameObjectFactory(gameObject) --adds functions to gameObject
        lib_gameObject:storeObject(gameObject) --stores gameObject

        --gameObject:loadTextures()

        gameObject:addOnFrameMethod(gameObjOnFrame)

        print("gameObject created with id: " .. gameObject.objID)
        return gameObject
    end

    function lib_gameObject:clearMovement()
        for _, obj in ipairs(self.store) do
            obj.isMoving = false
        end
    end

	return lib_gameObject