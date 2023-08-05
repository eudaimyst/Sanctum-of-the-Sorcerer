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

    local idCounter = 1 --counter to give each entity a unique id
	
    -- Define module
	local lib_entity = {}
    lib_entity.store = {}
    lib_entity.parentGroup = nil --set by setGroup function

    function lib_entity:create() --store = any store be it gameObjects, enemies etc...
        print("creating entity")
        local entity = {}
        entity.id = idCounter --unique id for each entity
        entity.world = {x = 0, y = 0}
        entity.group = display.newGroup() --create a new display group for this entity that will be used for all display objects
        if (self.parentGroup == nil) then
            print("ERROR: parentGroup is nil, set parentGroup with entity:setGroup(group)")
        else
            self.parentGroup:insert(entity.group) --
        end
        self.store[entity.id] = entity --stores the eneity in this modules entity store

        function entity:DestroySelf()
            self.displayGroup:removeSelf()
            self.displayGroup = nil
            entity.store[self.id] = nil

            if ( self.onDestroy ) then
                self:onDestroy()
            end
            self = nil
        end

        --copies the params from the passed or default params table to the entity
        function entity:setParams(defaultParams, _params)
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

        idCounter = idCounter + 1
        print("entity created with id: " .. entity.id)
        return entity
    end

    function lib_entity:Destroy(entity)
        entity:DestroySelf()
        return true
    end

    function lib_entity:setGroup(group) --sets the group for the entity (all modules that extend the entity class will use this)
        lib_entity.parentGroup = group
    end

	return lib_entity