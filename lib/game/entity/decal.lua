	-----------------------------------------------------------------------------------------
	--
	-- decal.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local entity = require("lib.game.entity")
	local lightEmitter = require("lib.game.entity.light_emitter")
	local json = require("json")

	local map --set on init()
	local decalGroup
	
	local decalData = { --move to params when we get a good amount of decals
		win = {path = "window/window.png", scale = 0.6, light = true}
	}

	local decalTextures = {}
	local mapImageFolder = "content/map/"

	local store = {}

	-- Define module
	local lib_decal = {	}
	lib_decal.store = store

	local _tile
	local function decalOnFrame(self) --added to entity methods
        if self.rect then
            _tile = map:getTileAtPoint(self.x, self.y)
            --print(self.id, tile.id, tile.lightValue)
            self.lightValue = _tile.lightValue
			self.rect:setFillColor(self.lightValue)
        end
	end

	local function loadDecalTextures()
		local decalDir = mapImageFolder.."decals/"
		print("loading decal textures")
		for k, v in pairs(decalData) do
			local path = decalDir..v["path"]
			print(k, v, "path=", path)
			decalTextures[k] = graphics.newTexture( { type = "image", filename = path, baseDir = system.ResourceDirectory } )
		end
	end

	function lib_decal:create(decalName, saveData, tileSize)
		local tStoreCols = map.getTileStoreCols()
		local tile = tStoreCols[saveData.x][saveData.y]
		local decalPosX, decalPosY = tile.midX + tileSize*saveData.xOff/2, tile.midY + tileSize*saveData.yOff/2
		--+ saveData.xOff
		local decal = entity:create( decalPosX, decalPosY )
		--print("decal created at: ", decal.x, decal.y)
		--print(json.prettify(saveData))
		decal:addOnFrameMethod(decalOnFrame)
		
		local decalTex = decalTextures[decalName]
		local decalSize = decalData[decalName].scale * tileSize
		decal.rect = display.newImageRect(decalGroup, decalTex.filename, decalTex.baseDir, decalSize, decalSize);
		--util.zeroAnchors(decal.rect)
		decal.rect.rotation = saveData.angle

		store[#store + 1] = decal

		if decalData[decalName].light then
			local lightParams = {
				x = decal.x,
				y = decal.y,
				radius = 400,
				intensity = 5,
				exponent = .1,
				--TODO: color = {1, 1, 1},
			}
			lightEmitter.attachToEntity(decal, lightParams)
		end

	end

	function lib_decal:init(_map)
		map = _map
		decalGroup = map.decalGroup
		loadDecalTextures()
	end

	return lib_decal