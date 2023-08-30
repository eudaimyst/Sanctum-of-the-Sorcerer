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
    local util = require("lib.global.utilities")
    local map --set by init

    -- Define module
	local lib_entity = {}
    lib_entity.store = {}
    lib_entity.parentGroup = nil --set by setGroup function
    local entityCount = 0

    local function updateRect(self) --calculate the entities position on the screen based off its world coords
        --needs to be called after cam bounds has been updated on frame or jitters
        if (self.rect) then --do not updateScreenPos if entity has no rect (ie, is not on screen)
            self.rect.xScale, self.rect.yScale = cam.zoom, cam.zoom
            self.rect.x, self.rect.y = (self.world.x - cam.bounds.x1) * cam.zoom , (self.world.y - cam.bounds.y1) * cam.zoom
        end
    end

    function lib_entity.entityFactory(entity)
		--print("adding entity functions")

        function entity:updateLightValue()
            local tile = map:getTileAtPoint(self.world)
            --print(self.id, tile.id, tile.lightValue)
            self.lightValue = tile.lightValue
        end

        function entity:destroySelf() --called to remove the entity, its group and reference to it
            local function doDestruction()
                print("destroying entity with id: "..self.id)
                self.group:removeSelf()
                self.group = nil
                self.onFrameMethods = nil
                lib_entity.store[self.id] = nil

                self = nil
            end
            if ( self.onDestroy ) then
                self:onDestroy()
            end
            print("entity "..self.id.." marked for destruction")
            self.markedForDestruction = true
            timer.performWithDelay( 0, doDestruction ) --use a timer as we should not destroy the entity while iterating through the onFrame functions
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

        function entity:addOnFrameMethod(method) --adds a function to the onFrameFuncs table which is called each frame
            --self.method = util.deepcopy(method)
            self.onFrameMethods[#self.onFrameMethods+1] = method
        end
    end

    function lib_entity:storeObject(entity)
    end

    function lib_entity:create(_x, _y, _receivesLighting, _updateRectOnFrame) --store = any store be it gameObjects, enemies etc...
        entityCount = entityCount + 1
        --print("creating entity with id "..entityCount)
        local updateRectOnFrame = _updateRectOnFrame or true --default to true, pass nil if handling own rect updates
        --(ie tiles as we dont want to call 10,000 unecessary functions on frame)

        local entity = { id = entityCount,
            world = {x = _x or 0, y = _y or 0}, screen = {x = 0, y = 0},
            group = nil, attack = nil,
            onFrameMethods = {}, markedForDestruction = nil,
            receivesLighting = _receivesLighting or true
        }
        
        entity.group = display.newGroup() --create a new display group for this entity that will be used for all display objects

        if (self.sceneGroup == nil) then
            print("ERROR: parentGroup is nil, set parentGroup with lib_entity:setGroup(group) from scene")
        else
            self.sceneGroup:insert(entity.group)
        end

        lib_entity.entityFactory(entity) --adds functions to entity
        lib_entity:storeObject(entity) --stores the entity
        self.store[entityCount] = entity --stores the object in this modules store of object

        if (updateRectOnFrame) then
            entity:addOnFrameMethod(updateRect)
        end
        --print("entity created with id: " .. entity.id)
        return entity
    end

    function lib_entity:init(sceneGroup, _map) --sets the group for the entity (all modules that extend the entity class will use this)
        lib_entity.sceneGroup = sceneGroup
        map = _map
    end

	return lib_entity