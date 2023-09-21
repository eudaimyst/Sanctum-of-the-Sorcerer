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


-- Define module
local game = { char = {} }
local cam, map, key, mouse, hud --set on init()


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
	local ratParams = util.deepcopy(enemyParams.rat)
	ratParams.spawnPos = {
		x = enemySaveData.spawnPoint.x * map.tileSize / 10,
		y = enemySaveData.spawnPoint.y * map.tileSize / 10
	}
	enemy:create(ratParams)
end

local _obj
function game.spawnObject(saveData)
	local crateParams = util.deepcopy(gameObjParams.crate)
	print(json.prettify(crateParams))
	crateParams.spawnPos = { x = saveData.x, y = saveData.y }
	local ranDir = math.random(1, 8)
	local ranDirKey = gc.dirKeys[ranDir]
	crateParams.facingDirection = gc.move[ranDirKey]
	if map:getTileAtPoint(saveData.x, saveData.y).col == 0 then
		_obj = gameObject:create(crateParams)
		_obj:makeRect()
		print("created crate with id: ",_obj.id, "facing dir", _obj.facingDirection.image)
		print(json.prettify(_obj))
	end
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

	hud:draw(self.char)
	key.registerMoveListener(moveInput)
	key.registerSpellSelectListener(self.char.setActiveSpell)
	mouse.registerClickListener(self.mouseClick)
end

function game:onFrame()
	--gameObject:clearMovement()	--sets isMoving to false for all game objects, before being set by key input
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

function game.init(_cam, _map, _key, _mouse, _hud)
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

function game.mouseClick(x, y) --mouseClick called from mouse input listener, can't pass self
	if (game.char.activeSpell) then
		if (game.char.activeSpell.targetType == "point") then
			local target = { x = cam.bounds.x1 + x, y = cam.bounds.y1 + y }
			game.char:beginCast(target)
		end
	end
end

return game
