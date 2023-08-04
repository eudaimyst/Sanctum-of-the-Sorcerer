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
	local entity = {}
    entity.store = {}
    entity.parentGroup = nil --set by setGroup function

    function entity:create() --store = any store be it gameObjects, enemies etc...
        print("creating entity")
        local e = {}
        e.id = idCounter --unique id for each entity
        e.world = {x = 0, y = 0}
        e.group = display.newGroup() --create a new display group for this entity that will be used for all display objects
        if (self.parentGroup == nil) then
            print("ERROR: parentGroup is nil, set parentGroup with entity:setGroup(group)")
            return
        else
            self.parentGroup:insert(e.group) --
        end
        self.store[e.id] = e --stores the eneity in this modules entity store

        function e:DestroySelf()
            self.displayGroup:removeSelf()
            self.displayGroup = nil
            entity.store[self.id] = nil

            if ( self.onDestroy ) then
                self:onDestroy()
            end
            self = nil
        end

        idCounter = idCounter + 1
        print("entity created with id: " .. e.id)
        return e
    end

    function entity:Destroy(e)
        e:DestroySelf()
        return true
    end

    function entity:setGroup(group) --sets the group for the entity (all modules that extend the entity class will use this)
        entity.parentGroup = group
    end

	return entity