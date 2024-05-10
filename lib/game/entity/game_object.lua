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
local entity = require("lib.game.entity")
local cam = require("lib.camera")
local map = require("lib.map")
local util = require("lib.global.utilities")
local json = require("json")
local lfs = require("lfs")
local collision = require("lib.game.entity.game_object.collision")
local animSystem = require("lib.game.entity.game_object.animation")

-- Define module
local lib_gameObject = {}

local textureStore = {} --stores all textures for objects and children, indexed by name, direction, state, frame

local mRound = math.round

local _dir, _anim --recycled
local _nTargetX, _nTargetY, _tile
local _moveTileX, _moveTileY, _moveFactor, _worldX, _worldY
local _posDeltaX, _posDeltaY, _newPosX, _newPosY
local _xCheckPosX, _xCheckPosY, _yCheckPosX, _yCheckPosY --for checking collision on each axis
local _xOff, _yOff, _selfRect, _hcw, _hch                --recycled
local _xColCheck, _yColCheck = { minX = 0, maxX = 0, minY = 0, maxY = 0 }, { minX = 0, maxX = 0, minY = 0, maxY = 0 }
local _selfY                                             --used for zPos

local _tex                                               --recycled for makeRect

local function gameObjOnFrame(self)
	--todo: check if char not name for performance

	_xOff, _yOff = self.xOffset, self.yOffset --locals for performance

	if self.state == "death" then
		if self.rect then
			_selfRect = self.rect
			self:updateLighting()
			self:animUpdateLoop() --manually call anim update loop for death animation
			self:updateZpos()
		end
		return
	end
	if self.name ~= "character" then --isMoving for char is set false earlier as needs gets set true by keyinput in game.lua
		self.isMoving = false     --resets moving variable to be changed by gameObject:move() if called
	end

	if self.moveTargetDir then
		self:move(self.moveTargetDir)
	end

	if self.col then --object has been registered for collisions
		--if self.name == "character" then print("updating col for character") end
		collision.updatePos(self)
	end

	if self.rect then               --object is on screen
		_selfRect = self.rect
		_selfRect.x = _selfRect.x + _xOff --doesnt need to be done on frame
		_selfRect.y = _selfRect.y + _yOff
		self:updateLighting()
		self:updateZpos()
	end
end

function lib_gameObject.setTextureStore(store)
	textureStore = store
end

function lib_gameObject.factory(gameObject)
	--print("adding gameObject functions")

	function gameObject:updateZpos()
		--insert into correct zGroup based on y position
		_selfY = mRound(_selfRect.y - _yOff)
		if _selfY > 0 and _selfY <= display.contentHeight then
			entity.zGroups[_selfY]:insert(self.group)
		end
	end

	function gameObject:updateLighting()
		_tile = map:getTileAtPoint(self.x, self.y)
		--print(self.id, tile.id, tile.lightValue)
		self.lightValue = _tile.lightValue
		self.rect:setFillColor(self.lightValue)
	end

	function gameObject:animUpdateLoop()
		animSystem.animUpdateLoop(self)
	end

	function gameObject:beginAttackAnim(attack)
		animSystem.beginAttackAnim(self, attack)
	end

	function gameObject:takeDamage(source, val)
		self.currentHP = self.currentHP - val
		print("--------DAMAGE--------")
		print(self.name, self.id, "took", val, "damage from", source.name, source.id)
		if self.onTakeDamage then
			self:onTakeDamage() --used to add functionality to extended classes
		end
		if self.currentHP <= 0 then
			--print(json.prettify(self.animations))
			self.state = "death"
			self.currentAnim = self.animations[self.state]
			collision.deregisterObject(self)
			animSystem.beginDeathAnim(self)
		end
	end

	function gameObject:dealDamage(target, val)
		target:takeDamage(self, val)
		if self.onDealDamage then
			self:onDealDamage()
		end
	end

	function gameObject:setMoveTarget(posX, posY) --once move target is set, then onFrame will know to call the move function to the constructed moveTarget
		--print(json.prettify(self))
		--print("move target:",self.id, self.x, self.y)
		if (util.compareFuzzy(self.x, self.y, posX, posY)) then
			print(self.id, " already at target position")
			if self.reachedMoveTarget then
				self:reachedMoveTarget()
			end
			return
		end
		self.moveTargetX, self.moveTargetY = posX, posY
		--directions were originally intended to be constants and not intended to have their values changed
		--TODO: come up with a proper direction framework that is not accessed as constants
		_dir = util.deepcopy(util.angleToDirection(util.deltaPosToAngle(self.x, self.y, posX, posY)))
		_nTargetX, _nTargetY = util.normalizeXY(util.deltaPos(self.x, self.y, posX, posY))
		_dir.x, _dir.y = _nTargetX, _nTargetY
		self.moveTargetDir = _dir
		--print(self.id, "target dir: ", dir.x, dir.y)
	end

	function gameObject:move(dir) --called each frame from key_input by scene, also onFrame if moveTarget is set
		local function setColDirMultiplier(dirAxis)
			if dirAxis < 0 then
				return -1
			else
				return 1
			end
		end

		if (self.currentAttack) then --todo:add check if attack allows moving
			return
		end
		self.isMoving = true --prevents spell casting, set to false in onFrame method
		self:setMoveDirection(dir) --sets move direction and updates the facing direction

		--------calculate the new position to move to
		_worldX, _worldY = self.x, self.y
		_moveFactor = self.moveSpeed * gv.frame.dts
		_posDeltaX, _posDeltaY = util.factorPos(self.moveDirection.x, self.moveDirection.y, _moveFactor) --moveDir gets recreated for enemies
		_newPosX, _newPosY = _worldX + _posDeltaX, _worldY + _posDeltaY

		--------check for wall collisions at the new position
		_hcw, _hch = self.halfColWidth, self.halfColHeight
		--we check each direction seperately so we can null the movement in that direction easily without affecting the other
		--todo: look into if we only need one tile check (probably can)
		local colMultX = setColDirMultiplier(self.moveDirection.x) --inverts the collision multiplier depending on direction of movement
		local colMultY = setColDirMultiplier(self.moveDirection.y)
		_xCheckPosX, _xCheckPosY = _newPosX + _hcw * colMultX, _worldY --x and y positions to check for tiles
		_yCheckPosX, _yCheckPosY = _worldX, _newPosY + _hch * colMultY
		_moveTileX = map:getTileAtPoint(_xCheckPosX, _xCheckPosY) --get the tile at new position (plus collision)
		_moveTileY = map:getTileAtPoint(_yCheckPosX, _yCheckPosY)
		self.hitWall = false
		if (_moveTileX.col == 1) then --if the tile we want to move to has collision
			_newPosX = _worldX  --nil the movement vector in the direction of the tile
			self.hitWall = true --set a flag, checked by enemy idle state
		end
		if (_moveTileY.col == 1) then --
			_newPosY = _worldY
			self.hitWall = true
		end
		--------check for entity collisions at the new position
		if self.col then
			_xColCheck.minX, _xColCheck.maxX = _newPosX - _hcw, _newPosX + _hcw
			_xColCheck.minY, _xColCheck.maxY = _worldY - _hch, _worldY + _hch
			_yColCheck.minX, _yColCheck.maxX = _worldX - _hcw, _worldX + _hcw
			_yColCheck.minY, _yColCheck.maxY = _newPosY - _hch, _newPosY + _hch
			if collision.checkCollisionAtBounds(self, _xColCheck.minX, _xColCheck.maxX, _xColCheck.minY, _xColCheck.maxY) then
				_newPosX = _worldX --nil the movement vector in the direction of the collision
			end
			if collision.checkCollisionAtBounds(self, _yColCheck.minX, _yColCheck.maxX, _yColCheck.minY, _yColCheck.maxY) then
				_newPosY = _worldY --nil the movement vector in the direction of the collision
			end
		end

		------set the new position
		self.x, self.y = _newPosX, _newPosY
		--check if reached move target
		if self.moveTargetDir then
			if util.compareFuzzy(self.x, self.y, self.moveTargetX, self.moveTargetY) then
				self.moveTargetDir = nil --mark as nil to stop moving
			end
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

	function gameObject:updateRectImage() --called to update image of rect
		--print(json.prettify(self.textures))
		if (self.rect) then
			_dir = self.facingDirection.image
			_anim = nil
			if (self.state == "attack") then
				if (self.currentAttack) then
					_anim = self.currentAttack.animation
				end
			else
				_anim = self.state
			end
			--print(s_dir, anim, self.animFrame)
			if (_anim) then
				_tex = textureStore[self.name][_dir][_anim][self.animFrame - 1]
				self.rect.fill = {
					type = "image",
					filename = _tex.filename, -- "filename" property required
					baseDir = _tex.baseDir -- "baseDir" property required
				}
				self.rect:setFillColor(self.lightValue)
			end
		else
			--print("WARNING: rect doesn't exist game obj", self.id, self.name)
		end
	end

	function gameObject:makeRect() --makes game objects rect if doesn't exist
		if (self.rect) then
			print("calling gameObj:makeRect when it already exists", self.id)
			return
		end
		print(self.name, self.facingDirection.image, self.state, self.animFrame - 1)
		_tex = textureStore[self.name][self.facingDirection.image][self.state][self.animFrame - 1]
		self.rect = display.newImageRect(self.group, _tex.filename, _tex.baseDir, self.width, self.height)
		self.rect.x, self.rect.y = self.x + self.xOffset, self.y + self.yOffset
		if self.state ~= "death" then
			collision.registerObject(self)
		end
	end

	function gameObject:destroyRect() --destroys rect if exists
		if (self.rect) then
			self.rect:removeSelf()
			self.rect = nil
			if self.state ~= "death" then
				collision.deregisterObject(self)
			end
		end
	end
end

local defaultParams = {
	name = "default",
	currentHP = 10,
	maxHP = 10,
	level = 0,
	element = nil, --gameplay data
	moveSpeed = 100,
	colWidth = 50,
	colHeight = 50,
	width = 96,
	height = 96,
	xOffset = 0,
	yOffset = 0, --display data
	image = "default.png",
	path = "content/game_objects/",
	fName = "",
	spawnPos = { x = 0, y = 0 },
	moveTargetX = 0,
	moveTargetY = 0,
	state = "idle", --current state of the puppet, used to determine which animation to play, set by updateState()
	directional = false,
	moveDirection = gc.move.down,
	facingDirection = gc.move.down,
	isMoving = false,
	lightValue = 0,
	moveTarget = nil, --target position relative to the game object
	animations = {},
	animFrame = 1,
	frameTimer = 0, --animation system logic
	attackWindup = false,
	windupTimer = 0,
	attackWindingUp = false, --anim system windup logic
	attackChannel = false,
	channelTimer = 0,
	attackChanneling = false, --anim system channel logic
	isDead = false,        --marks if the puppet is dead
	windupGlow = nil       --stores display data for windup
}

function lib_gameObject:create(_params) --creates gameObject
	--print("creating gameObject")

	local gameObject = entity:create()        --creates the entity using the entity module and bases the object off of it

	gameObject:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
	gameObject.halfColWidth, gameObject.halfColHeight = gameObject.colWidth / 2, gameObject.colHeight / 2
	gameObject.x, gameObject.y = gameObject.spawnPos.x,
		gameObject.spawnPos
		.y                          --sets the intial world point to the passed x and y or the default x and y

	lib_gameObject.factory(gameObject) --adds functions to gameObject

	gameObject:addOnFrameMethod(gameObjOnFrame)


	return gameObject
end

return lib_gameObject
