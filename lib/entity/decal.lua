	-----------------------------------------------------------------------------------------
	--
	-- decal.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local entity = require("lib.entity")
	local json = require("json")

	local map --set on init()
	local decalGroup
	
	local decalData = { --move to params when we get a good amount of decals
		win = {path = "window/window.png", scale = 0.6}
	}

	local decalTextures = {}
	local mapImageFolder = "content/map/"

	local store = {}

	-- Define module
	local lib_decal = {	}
	lib_decal.store = store

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

		local decal = entity:create(saveData.x * map.tileSize + saveData.xOff * map.tileSize, saveData.y * map.tileSize + saveData.yOff * map.tileSize )
		print("decal created at: ", decal.world.x, decal.world.y)
		
		print(json.prettify(saveData))
		print(decalName, decalName, decalName)
		print(decalTextures[decalName].filename)
		local decalTex = decalTextures[decalName]
		local decalSize = decalData[decalName].scale * tileSize
		print(tileSize, decalData[decalName].scale, decalSize)
		decal.rect = display.newImageRect(decalGroup, decalTex.filename, decalTex.baseDir, decalSize, decalSize);
		util.zeroAnchors(decal.rect)
		decal.rect.rotation = saveData.angle

		store[#store + 1] = decal

	end

	function lib_decal:init(_map)
		map = _map
		decalGroup = map.decalGroup
		loadDecalTextures()
	end

	return lib_decal