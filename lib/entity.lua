	-----------------------------------------------------------------------------------------
	-- entity.lua
	-- Features:
    -----------------
    -- Base class which handles the basic logic that is shared across literally every gameplay element that is on the map, which is not static on the map itself (like decals).
    -----------------
    -- Contains:
    -- Creation factory to create entities which are returned to the games entities store
    -- World co-ords
    -- General references to the game state,so that subclasses can access them
    -- Display group for subclasses to add display objects to
    -- OnDestroyed(), OnCreated()

	-----------------------------------------------------------------------------------------
	
    local cam = require("lib.camera")

    -- Define module
	local lib_entity = {}
    lib_entity.store = {}
    lib_entity.parentGroup = nil --set by setGroup function

    function lib_entity.entityFactory(entity)
		print("adding entity functions")

        function entity:destroySelf() --called to remove the entity, its group and reference to it
            self.group:removeSelf()
            self.group = nil
            lib_entity.store[self.id] = nil

            if ( self.onDestroy ) then
                self:onDestroy()
            end
            self = nil
        end

        function entity:setParams(defaultParams, _params) --copies the params from the passed or default params table to the entity
            print("setting entity params")
            if (_params) then --if passed a table of params
                for param, defaultValue in pairs(defaultParams) do --for each param in the default params
                    if (_params[param]) then --if passed param exists
                        self[param] = _params[param] --overide the default param
                    else
                        self[param] = defaultValue --set the default value
                    end
                end
            else --no params passed
                for param, defaultValue in pairs(defaultParams) do  --for each param in the default params
                    self[param] = defaultValue --set the default value
                end
            end
        end

        function entity:entityOnFrame() --this function Must have a unique name for any module that creates an entity
            self.screen.x, self.screen.y = self.world.x - cam.bounds.x1, self.world.y - cam.bounds.y1 --calculate the entities position on the screen based off its world coords
        end

        function entity:addOnFrameMethod(method) --adds a function to the onFrameFuncs table which is called each frame
            self.onFrameMethods[#self.onFrameMethods+1] = method
        end

        entity:addOnFrameMethod(entity.entityOnFrame)

    end

    function lib_entity:storeObject(entity)
        entity.id = #self.store + 1 --creates the object id --NOTE: Different to entity id
        self.store[entity.id] = entity --stores the object in this modules store of object
    end

    function lib_entity:create(_x, _y) --store = any store be it gameObjects, enemies etc...
        print("creating entity")

        local entity = { isPuppet = false, isGameObject = false,
            world = {x = 0, y = 0}, screen = {x = 0, y = 0},
            group = nil, attack = nil, onFrameMethods = {}
        }
        if _x then entity.world.x = _x end
        if _y then entity.world.y = _y end 
        
        entity.group = display.newGroup() --create a new display group for this entity that will be used for all display objects

        if (self.sceneGroup == nil) then
            print("ERROR: parentGroup is nil, set parentGroup with lib_entity:setGroup(group) from scene")
        else
            self.sceneGroup:insert(entity.group)
        end

        lib_entity.entityFactory(entity) --adds functions to entity
        lib_entity:storeObject(entity) --stores the entity

        print("entity created with id: " .. entity.id)
        return entity
    end

    function lib_entity:init(sceneGroup) --sets the group for the entity (all modules that extend the entity class will use this)
        lib_entity.sceneGroup = sceneGroup
    end

	return lib_entity