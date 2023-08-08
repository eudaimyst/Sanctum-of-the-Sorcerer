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
    --local json = require("json")

	-- Define module
	local lib_gameObject = {}
    lib_gameObject.store = {}

    local defaultParams = {
        name = "default", isGameObject = true,
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        moveSpeed = 100,
        width = 96, height = 96, xOffset = 0, yOffset = 0, --display data
        image = "default.png", path = "content/game_objects/", fName = "",
        spawnPos = { x = 0, y = 0 },
        directional = false, moveDirection = gc.move.down, facingDirection = gc.move.down,
        isMoving = false,
    }

    function lib_gameObject.gameObjectFactory(gameObject)
		print("adding gameObject functions")

        function gameObject:move(dir) --called each frame from key_input by scene
            self.isMoving = true
            if ( self.moveDirection ~= dir ) then --if not already moving or moving in a different direction
                self:setMoveDirection(dir)
            end

            self.world.x = self.world.x + (self.moveDirection.x * self.moveSpeed * gv.frame.dts)
            self.world.y = self.world.y + (self.moveDirection.y * self.moveSpeed * gv.frame.dts)

        end

        function gameObject:setMoveDirection(dir) --sets move direction and forces updating facing direction
            self.moveDirection = dir
            self:setFacingDirection(dir)
        end

        function gameObject:setFacingDirection(dir) --sets facing direction and re-creates rect
            self.facingDirection = dir
            self:updateFileName()
            --[[
            self:destroyRect()
            self:makeRect()
            ]]
            self:updateRectImage()
        end

        function gameObject:updateFileName() --updates fileName based on current facing direction
            print("updating gameObject file name")
            if (self.directional == true) then --if directional, add facing direction directory to file name
                self.fName = self.path..self.name.."/"..self.facingDirection.image..".png"
            else
                self.fName = self.path..self.name..".png"
            end
        end

        function gameObject:updateRectPos() --needs to be called after cam bounds has been updated on frame or jitters
            self.rect.x, self.rect.y = self.world.x + self.xOffset - cam.bounds.x1, self.world.y + self.yOffset - cam.bounds.y1
        end

        function gameObject:updateRectImage()
            self.rect.fill = {
                type = "image",
                filename = self.fName,  -- "filename" property required
                baseDir = system.ResourceDirectory;     -- "baseDir" property required
            }
        end

		function gameObject:makeRect() --makes game objects rect if doesn't exist
            print("making gameObject rect, isPuppet = " .. tostring(self.isPuppet))
            if (self.rect) then
                print("rect already created")
                return
            end
            self.rect = display.newImageRect(self.group, self.fName, self.width, self.height)
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
        
		print("setting gameObject params")
        gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
		--print("GAME OBJECT PARAMS:--------\n" .. json.prettify(gameObject) .. "\n----------------------")

        gameObject.world.x, gameObject.world.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        if (not gameObject.isPuppet) then --all puppets are directional so dont change the name
            if (gameObject.name == "default" and gameObject.directional) == true then
                gameObject.name = "default_directional"  --if the object is directional and has the default name, change the name to the directional default name
            end
        end

        lib_gameObject.gameObjectFactory(gameObject) --adds functions to gameObject
        lib_gameObject:storeObject(gameObject) --stores gameObject


        print("gameObject created with id: " .. gameObject.objID)
        return gameObject
    end

    function lib_gameObject:clearMovement()
        for _, obj in ipairs(self.store) do
            obj.isMoving = false
        end
    end

	return lib_gameObject