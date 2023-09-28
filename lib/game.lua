-----------------------------------------------------------------------------------------
--
-- game.lua -- library of functions used for game scene
--
-----------------------------------------------------------------------------------------

--common modules
local gc = require("lib.global.constants")
local util = require("lib.global.utilities")
local gameObject = require("lib.game.entity.game_object")
local puppet = require("lib.game.entity.game_object.puppet")
local character = require("lib.game.entity.game_object.puppet.character")
local entity = require("lib.game.entity")
local enemyParams = require("lib.global.enemy_params")
local gameObjParams = require("lib.global.game_object_params")
local enemy = require("lib.game.entity.game_object.puppet.enemy")
local lfs = require("lfs")
local spellParams = require("lib.global.spell_params")
local lightEmitter = require("lib.game.entity.light_emitter")
local json = require("json")

local gamePaused = false --set to true when game is paused and prevents onFrame from running

-- Define module
local game = { char = {} }
local cam, map, key, mouse, hud --set on init()

local gameMenuListener, spellbookListener --listener functions passed from scene to load overlays when hud buttons pressed, set on init()

function game:spawnChar()
	print("char getting spawn point from map: ")
	local params = {
		spawnPos = map:getSpawnPoint()
	}
	self.char = character:create(params, hud, map, cam)
	--print(json.prettify(game.char))
	enemy:setGameChar(self.char)

	cam:setMode("follow", self.char)
end

function game.spawnEnemy(enemySaveData)
	--copilot: choose a random enemy from the enemy params
	local r = math.random()
	local params = {}
	if r > 0.5 then
		params = util.deepcopy(enemyParams.rat)
	else
		params = util.deepcopy(enemyParams.bat)
	end
	params.spawnPos = {
		x = enemySaveData.spawnPoint.x * map.tileSize / 10,
		y = enemySaveData.spawnPoint.y * map.tileSize / 10
	}
	enemy:create(params)
end

local _obj
function game.spawnObject(saveData)
	local crateParams = util.deepcopy(gameObjParams.crate)
	--print(json.prettify(crateParams))
	crateParams.spawnPos = { x = saveData.x, y = saveData.y }
	local ranDir = math.random(1, 8)
	local ranDirKey = gc.dirKeys[ranDir]
	crateParams.facingDirection = gc.move[ranDirKey]
	if map:getTileAtPoint(saveData.x, saveData.y).col == 0 then
		_obj = gameObject:create(crateParams)
		_obj:makeRect()
		--print("created crate with id: ",_obj.id, "facing dir", _obj.facingDirection.image)
		--print(json.prettify(_obj))
	end
end

function game:pause() --called whenever the game needs to be paused
	gamePaused = true
	mouse:deinit() --de-init the mouse and expect it to be reinitialised for whyever the game is paused
	
	--call pause method on all entities if it exists
	for _, e in pairs(entity.store) do
		if not e.markedForDestruction then
			if e.onPause then
				e:onPause()
			end
		end
	end
end

function game:unpause()
	gamePaused = false
	mouse:init()
	mouse:registerObject(hud.gameOverlay, 0)
	for i = 1, #hud.interactsWithMouse do
		mouse:registerObject(hud.interactsWithMouse[i], 1)
	end
	
	--call unpause method on all entities if it exists
	for _, e in pairs(entity.store) do
		if not e.markedForDestruction then
			if e.onUnpause then
				e:onUnpause()
			end
		end
	end
end

local function charSetActiveSpell(slotNum)
	if gamePaused == true then return end --do nothing if paused
	game.char.setActiveSpell(slotNum)
end

function game:beginPlay()
	local function moveInput(direction) --moveListener passed to key module
		self.char:move(direction)
		map:refreshCamTiles() --calls updateRect on tiles, creates/destroys rects
    --print("move input done")
	end

	self:spawnChar()

	for i = 1, #map.enemies do
		self.spawnEnemy(map.enemies[i])
	end
	print("creating",#map.barrelSaveData,"barrels")
	for i = 1, #map.barrelSaveData do
		self.spawnObject(map.barrelSaveData[i])
	end

	hud:draw(self.char, gameMenuListener, spellbookListener) --draws the hud and passes listener functions for buttons
	function hud.gameOverlay:press()
		print("game overlay pressed")
		game.mouseClick()
	end
	mouse:registerObject(hud.gameOverlay, 0)
	key.registerMoveListener(moveInput)
	key.registerSpellSelectListener(charSetActiveSpell)
	--mouse.registerClickListener(self.mouseClick)
end

function game:onFrame()
	--gameObject:clearMovement()	--sets isMoving to false for all game objects, before being set by key input
	if gamePaused == true then return end
	game.char.isMoving = false
	key:onFrame()               --processes key inputs
	cam:onFrame()               --processes camera movement
	lightEmitter:onFrame()		--calls lighting lib on frame for lighting update timer
	enemy:onFrame()             --calls enemy lib onFrame for decision making timer
	character:onFrame() --visibility

	for _, e in pairs(entity.store) do
		if not e.markedForDestruction then --entity will be destroyed this frame, do not run its onFrame method
			for j = 1, #e.onFrameMethods do
				e.onFrameMethods[j](e) --passes entity to onFrame function as self
			end
		end
	end
  
end

function game.init(_cam, _map, _key, _mouse, _hud, _gameMenuListener, _spellbookListener)
	gameMenuListener, spellbookListener = _gameMenuListener, _spellbookListener
	print("setting cam and map for game library")
	key, cam, map, hud, mouse = _key, _cam, _map, _hud, _mouse
	enemy.init(cam)
	lightEmitter.init(map, cam)
end

local function loadTextureFrames(i, path, table)
	if table then
		local texture = graphics.newTexture({
			type = "image",
			baseDir = system.ResourceDirectory,
			filename = path
		})
		if (texture) then
			--print(texture.filename, i, "created")
			table[i] = texture
		else
			print("ERROR: no texture created, i, path:", i, path)
		end
		return table[i]
	else
		print("ERROR: no table pased, i, path:", i, path)
	end
end

local function loadTexturesFromAnimData(path, anims) --the animdata and the animName to load to puppets texture store
	--!!!! lfs.attributes(filepath)[request_name] - TODO: check folder exists for directory
	local tex = {}
	local systemPath = system.pathForFile(path, system.ResourceDirectory)
	local dir = gc.dirFileStrings

	for i = 1, #dir do --for each direction
		local s_dir = dir[i] --local string representation of direction
		tex[s_dir] = {} --create a new table for the direction
	end

	for animName, animData in pairs(anims) do
		print("checking for folder: " .. systemPath .. animName)
		if lfs.attributes(systemPath .. animName, "mode") == "directory" then --check folder exists for animation
			print("loading textures for " .. animName)
			for i = 1, #dir do                                          --for each direction
				local s_dir = dir[i]
				tex[s_dir][animName] = {}
				local animTextures = tex[s_dir][animName]
				local animString = path .. animName .. "/" .. s_dir .. "/" --file location based off anim name
				print("adding textures for", s_dir, animName)
				if (animData.frames) then                      --if no sub animations in the anim data
					for j = 0, animData.frames - 1 do          --zero indexed animation file names
						--print("adding textures for frame: "..i)
						tex[s_dir][animName][j] = loadTextureFrames(j, animString .. j .. ".png", animTextures)
					end
				else
					for subAnimName, subAnimData in pairs(animData) do --for each sub animation (pre, main, post... etc)
						print("adding textures for", s_dir, animName, subAnimName)
						local subAnimString = animString ..
							subAnimName .. "_" --file location based off anim name and sub anim name

						tex[s_dir][animName][subAnimName] = {}
						local subAnimTextures = tex[s_dir][animName]
							[subAnimName]  --create a table for the sub animations to told the frames
						for j = 0, subAnimData.frames - 1 do --zero indexed animation file names
							--print("adding textures for frame: "..j)
							tex[s_dir][animName][subAnimName][j] = loadTextureFrames(j, subAnimString .. j .. ".png",
								subAnimTextures)
						end
					end
				end
			end
		else
			print("could not find animation folder for " .. animName)
		end
	end
	return tex
end

function game.preloadTextures() --called from scene after map loaded but before beginPlay
	-------- GameObjects --------
	print("loading game object textures")
	local textureStore = {}
	local gameObjectContent = "content/game_objects/"
	for _, _gameObject in pairs(gameObjParams) do
		local gameObjectAnims = {}
		for animName, animData in pairs(_gameObject.animations) do --add the game object animations to the list of animations to load
			gameObjectAnims[animName] = animData
		end
		textureStore[_gameObject.name] = loadTexturesFromAnimData(gameObjectContent .. _gameObject.name .. "/", gameObjectAnims)
	end
	-------- Enemies --------
	print("loading enemy textures")
	local enemyContent = "content/game_objects/puppets/enemies/"
	for _, _enemy in pairs(enemyParams) do
		local enemyAnims = {}
		for animName, animData in pairs(_enemy.animations) do --add the enemy animations to the list of animations to load
			enemyAnims[animName] = animData
		end
		for i = 1, #_enemy.attacks do
			local attackParams = _enemy.attacks[i].params
			local animName = attackParams.animation
			local animData = attackParams.animData
			print(animName)
			enemyAnims[animName] = animData
			textureStore[_enemy.name] = loadTexturesFromAnimData(enemyContent .. _enemy.name .. "/", enemyAnims)
		end
	end
	-------- Character --------
	print("loading character textures")
	local charContent = "content/game_objects/puppets/character/"
	local charAnims = {}
	for animName, animData in pairs(character.animations) do --add the character animations to the list of animations to load
		charAnims[animName] = animData
	end
	for animName, animData in pairs(spellParams.animations) do --add the spell animations to the list of animations to load
		charAnims[animName] = animData
	end
	textureStore["character"] = loadTexturesFromAnimData(charContent, charAnims)

	--set the textures store for the puppet module
	gameObject.setTextureStore(textureStore)
end

local _mouseX, _mouseY
function game.mouseClick() --called by mouse module when mouse is clicked on game overlay
	_mouseX, _mouseY = mouse:getPosition()
	if (game.char.activeSpell) then
		if (game.char.activeSpell.targetType == "point") then
			local target = { x = cam.bounds.x1 + _mouseX, y = cam.bounds.y1 + _mouseY }
			game.char:beginCast(target)
		end
	end
end

return game
