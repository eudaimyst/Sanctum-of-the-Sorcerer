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
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
    local entity = require("lib.entity")
    local cam = require("lib.camera")

	-- Define module
	local gameObject = {}
    gameObject.store = {}

    local defaultParams = {
        currentHP = 10, maxHP = 10, level = 0, element = nil, --gameplay data
        image = "content/error.png", width = 96, height = 96, --display data
        spawnPos = { x = 0, y = 0 }
    }

    function gameObject:create(_params, x, y )
        print("creating game object")
        local obj = entity:create() --creates the entity using the entity module and bases the object off of it
        obj.objID = #self.store + 1 --creates the object id --NOTE: Different to entity id
        self.store[obj.objID] = obj --stores the object in this modules store of objects
        
        for k, v in pairs(_params or defaultParams) do --copies the params from the passed or default params table to the object
            obj[k] = v
        end
        obj.world.x, obj.world.y = x or obj.spawnPos.x, y or obj.spawnPos.y --sets the intial world point to the passed x and y or the default x and y

		function obj:makeRect( )
			self.rect = display.newImageRect(self.group, self.image, self.width, self.height) 
			self.rect.x, self.rect.y = cam.midPoint.x, cam.midPoint.y --set initial position, just cam mindpoint for now for testing
		end
		obj:makeRect( ) --make rect when object is created, probably not when map and camera are implemented

		function obj:destroyRect()
			self.rect:removeSelf()
			self.rect = nil
		end
        print("game object created with id: " .. obj.objID)
        return obj
    end

	return gameObject