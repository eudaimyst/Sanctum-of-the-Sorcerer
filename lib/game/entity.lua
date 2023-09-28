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
    local collision = require("lib.game.entity.game_object.collision")

    -- Define module
	local lib_entity = {}
    lib_entity.store = {}
    lib_entity.parentGroup = nil --set by setGroup function
    lib_entity.zGroups = {}
    local entitiesGroup = {} --group that contains all entities
    local entityCount = 0

    local _selfRect, _camBounds, _camZoom --recycling
    
    local function updateRect(self) --update the rects position on screen, needs to be called after cam bounds has been updated on frame or jitters
        if (self.rect) then --do not update rect values if entity has no rect (ie, is not on screen)
            _selfRect, _camBounds, _camZoom = self.rect, cam.bounds, cam.zoom
            _selfRect.xScale, _selfRect.yScale = _camZoom, _camZoom
            _selfRect.x, _selfRect.y = (self.x - _camBounds.x1) * _camZoom , (self.y - _camBounds.y1) * _camZoom
        end
    end

    function lib_entity.entityFactory(entity)
		--print("adding entity functions")

        function entity:destroySelf() --called to remove the entity, its group and reference to it
            local function doDestruction()
                print("destroying entity", self.name, self.id)
                if self.group then
                    self.group:removeSelf()
                    self.group = nil
                end
                self.onFrameMethods = nil
                lib_entity.store[self.id] = nil
                if self.light then
                    self.light:destroySelf() --removes light from lightStore
                end
                if self.col then
                    print("entity has col, deregistering")
                    collision.deregisterObject(self)
                end
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
            --print("setting entity params")
            for k, v in pairs(defaultParams) do --for each param in the default params
                if (_params[k]) then --if passed param exists
                    self[k] = _params[k] --overide the default param
                    --print("overriding default param "..k.." with "..tostring(_params[k]))
                else
                    self[k] = v --set the default value
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
            x = _x or 0, y = _y or 0,
            group = nil, attack = nil,
            onFrameMethods = {}, markedForDestruction = nil,
            receivesLighting = _receivesLighting or true
        }
        
        entity.group = display.newGroup() --create a new display group for this entity that will be used for all display objects

        lib_entity.entityFactory(entity) --adds functions to entity
        lib_entity:storeObject(entity) --stores the entity
        self.store[entityCount] = entity --stores the object in this modules store of object

        if (updateRectOnFrame) then
            entity:addOnFrameMethod(updateRect)
        end
        --print("entity created with id: " .. entity.id)
        return entity
    end

    function lib_entity:init(sceneGroup) --sets the group for the entity (all modules that extend the entity class will use this)
        entitiesGroup = display.newGroup()
        sceneGroup:insert(entitiesGroup)
        --create groups for Z-indexing
        for i = 1, math.floor(display.contentHeight) do
            lib_entity.zGroups[i] = display.newGroup()
            entitiesGroup:insert(lib_entity.zGroups[i])
        end
    end

	return lib_entity