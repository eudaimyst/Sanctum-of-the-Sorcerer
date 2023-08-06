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
	local util = require("lib.global.utilities")
    local entity = require("lib.entity")
    local cam = require("lib.camera")
    local json = require("json")

	-- Define module
	local lib_gameObject = {}
    lib_gameObject.store = {}

    local defaultParams = {
        name = "default",
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        width = 96, height = 96, xOffset = 0, yOffset = 0, --display data
        image = "default.png", path = "content/game_objects/", fName = "",
        spawnPos = { x = 0, y = 0 },
        directional = false, moveDirection = gc.move.down, facingDirection = gc.move.down
    }

    function lib_gameObject:create(_params, puppet) --_params = paramaters, puppet = bool, if true, creates a puppet object
        print("creating game object")
        --print(json.prettify(_params))

        local gameObject = entity:create() --creates the entity using the entity module and bases the object off of it
        gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
        if (not puppet) then
            if (gameObject.name == "default" and gameObject.directional) == true then
                gameObject.name = "default_directional"  --if the object is directional and has the default name, change the name to the directional default name
            end
        end

        gameObject.objID = #self.store + 1 --creates the object id --NOTE: Different to entity id
        self.store[gameObject.objID] = gameObject --stores the object in this modules store of objects
        
        gameObject.world.x, gameObject.world.y = gameObject.spawnPos.x, gameObject.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

        function gameObject:setMoveDirection(dir) --sets the move direction and forces updating facing direction
            self.moveDirection = dir
            self:setFacingDirection(dir)
        end

        function gameObject:setFacingDirection(dir) --sets facing direction and updates the recreates the rect
            self.facingDirection = dir
            self:updateFileName()
            self:destroyRect()
            self:makeRect()
        end

        function gameObject:updateFileName(puppet) --updates fileName based on current facing direction
            print("updating game objects file name")
            if (puppet) then
                print("game object is a puppet")
                self.fName = self.path..self.name.."/"..self.state.."/"..self.facingDirection.image.."/"..self.currentFrame..".png"
            else
                if (self.directional == true) then
                    self.fName = self.path..self.name.."/"..self.facingDirection.image..".png" --make rect when object is created, until map and camera are implemented
                else
                    self.fName = self.path..self.name..".png"
                end
            end
        end

        if (not puppet) then gameObject:updateFileName() end --sets initial fName

		function gameObject:makeRect() --makes the game objects rect if it doesn't have one
            if (self.rect) then
                self:destroyRect()
            end
            self.rect = display.newImageRect(self.group, self.fName, self.width, self.height)
            self.rect.x, self.rect.y = self.world.x + self.xOffset, self.world.y + self.yOffset
		end
        if (not puppet) then gameObject:makeRect() end --creates rect on object creation (remove when camera starts to call this)

		function gameObject:destroyRect() --destroys the game objects rect if it has one
            if (self.rect) then
                self.rect:removeSelf()
                self.rect = nil
            end
		end

        print("game object created with id: " .. gameObject.objID)
        return gameObject
    end

	return lib_gameObject