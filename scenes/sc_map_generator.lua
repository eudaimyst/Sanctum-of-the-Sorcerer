	-----------------------------------------------------------------------------------------
	--
	-- map_generator2.lua
	--
	-----------------------------------------------------------------------------------------

	local composer = require("composer")
	local physics = require ("physics" )

	local editor = require("lib.editor")
	local mapgen = require("lib.map.generator")
	local mouse = require("lib.input.mouse_input")
	local key = require("lib.input.key_input")
	local fileio = require("lib.map.fileio")

	--create the scene
	local scene = composer.newScene()
	local sceneGroup

	local levelList = {} --used for dropdown, name and reference to the level
	for i = 1, #mapgen.levels do
		levelList[i] = {}
		levelList[i].name, levelList[i].value = mapgen.levels[i].name, mapgen.levels[i]
	end
	print("level list:")
	for k, v in pairs(levelList) do
		print(k, v)
	end


	local function firstFrame()
		mapgen:init(sceneGroup)

		local function tileGenComplete() --add window here that says gen is complete
			print("tile generation finished")
			--[[
			local completeWindowSections = {
				[1] = { label = "", collapsable = false, elements = {
					[1] = { { label = "Tile Generation Complete", eType = editor.elementTypes.toggleButtons, amount = 0 } },
					[2] = { { label = "Columns:"..#mapgen.tileStore.tileColumns, eType = editor.elementTypes.toggleButtons, amount = 0 } },
					[3] = { { label = "Rows:"..#mapgen.tileStore.tileRows, eType = editor.elementTypes.toggleButtons, amount = 0 } }
			} } }
			local w, h = 300, 120
			local completeWindowParams = {
				x = display.contentWidth/2 - w/2, y = display.contentHeight/2 - h/2, width = w, height = h, label = "",
				closable = true, movable = true, sceneGroup = sceneGroup, sectionData = completeWindowSections, object = mapgen
			}
			local window = editor.createWindow( completeWindowParams, sceneGroup )
			--]]
		end

		local function startTileGen() --draws the actual tiles for map and adds it to store
			mapgen:startTileGen(tileGenComplete)
		end

		local function deleteMap() --clears all tiles and their references ie, to change size of map]
			mapgen:deleteMap()
		end

		local function pauseTileGen() --temp stops tileGen prolly superfluous
			mapgen:pauseTileGen()
		end

		local function startGenMethod()
			mapgen:runGenFunc()
		end

		local function startEnemyGen()
			mapgen:generateEnemies()
		end

		local function startDecalGen()
			mapgen:generateDecals()
		end

		local function clearMap() --keep the tiles but remove any floor
			mapgen:clearTiles()
		end

		local function updateParam(param, value)
			mapgen:updateParam(param, value)
		end

		local function updateFilename(filename, value)

		end

		local function saveMap()
			fileio.save( mapgen:getSaveParams(), "default_generated_level")
		end

		--[[
		local defaultParams = { numRoomsX = 4, numRoomsY = 4, edgeInset = 5,
		roomSpacingMin = 3, roomSpacingMax = 6, spawnChance = 50 } ]]
		local t = editor.elementTypes --readability
		local genWindowSections = { --sections in the settings window that hold elements, uses index for ordering in ui
			[1] = { label = "Controls", collapsable = false, elements = {
					[1] = { { label = "Tile generator", eType = t.toggleButtons, amount = 3,
					texts = { "start", "pause", "delete" }, clickListener = { startTileGen, pauseTileGen, deleteMap } } }, --start, stop, pause
					[2] = { { label = "Generate floor", eType = t.toggleButtons, amount = 2,
					texts = { "start", "clear" }, clickListener = {startGenMethod, clearMap} } },
					[3] = { { label = "Generate enemies", eType = t.toggleButtons, amount = 2,
					texts = { "start", "clear" }, clickListener = {startEnemyGen, clearMap} } },
					[4] = { { label = "Generate decals", eType = t.toggleButtons, amount = 2,
					texts = { "start", "clear" }, clickListener = {startDecalGen, clearMap} } },
			} },
			[2] = { label = "Save / Load", collapsable = true, elements = {
					[1] = { {param = "filename", label = "File Name:", eType = t.inputField, inputListener = updateFilename } },
					[2] = { { label = "io", eType = t.toggleButtons, amount = 1,
					texts = { "save" }, clickListener = {saveMap} } }
			} },
			[3] = { label = "Map settings", collapsable = true, elements = {
					[1] = { {param = "width", label = "Map width:", eType = t.inputField, inputListener = updateParam }, {param = "height", label = "Height:", eType = t.inputField, inputListener = updateParam } },
					[2] = { {param = "tileSize", label = "Tile size (in pixels):", eType = t.inputField, inputListener = updateParam } },
					[3] = { {param = "level", label = "Level type:", eType = t.dropdown, table = levelList, selectListener = updateParam} },
			} },
			[4] = { label = "Castle", collapsable = true, elements = {
					[1] = { {param = "numRoomsX", label = "Number of Rooms X: ", eType = t.inputField, inputListener = updateParam},
							{param = "numRoomsY", label = "Y: ", eType = t.inputField, inputListener = updateParam} },
					[2] = { {param = "spawnChance", label = "Spawn chance: ", eType = t.inputField, inputListener = updateParam},
							{param = "edgeInset", label = "Edge inset: ", eType = t.inputField, inputListener = updateParam } },
					[3] = { {param = "roomSpacingMin", label = "Spacing Min: ", eType = t.inputField, inputListener = updateParam},
							{param = "roomSpacingMax", label = "Max: ", eType = t.inputField, inputListener = updateParam } },
					[4] = { {param = "randPosOffset", label = "Random Position Offset: ", eType = t.inputField, inputListener = updateParam} },
			} },
		}
		local genWindowParams = {
			x = 20, y = 20, width = 300, height = 400, label = "Settings", closable = false, movable = true,
			sceneGroup = sceneGroup, sectionData = genWindowSections, object = mapgen
		}
		local genWindow = editor.createWindow( genWindowParams, sceneGroup )

		mouse.init() -- registers the mouse on frame event
		key.init()

	end

	local function onFrame()
		mapgen:onFrame()
	end


	-- -----------------------------------------------------------------------------------
	-- Composer scene functions
	-- -----------------------------------------------------------------------------------
	-- create()
	function scene:create( event )
	    sceneGroup = self.view
	    -- Code here runs when the scene is first created but has not yet appeared on screen
		-- We need physics started to add bodies
		physics.start()
		physics.setGravity( 0, 0 )
	end
	-- show()
	function scene:show( event )
	    sceneGroup = self.view
	    local phase = event.phase
	    if ( phase == "will" ) then
	        -- Code here runs when the scene is still off screen (but is about to come on screen)
	    elseif ( phase == "did" ) then
	        -- Code here runs when the scene is entirely on screen
	        firstFrame()
			Runtime:addEventListener( "enterFrame", onFrame )
	    end
	end
	-- hide()
	function scene:hide( event )
	    sceneGroup = self.view
	    local phase = event.phase
	    if ( phase == "will" ) then
	        -- Code here runs when the scene is on screen (but is about to go off screen)
	    elseif ( phase == "did" ) then
	        -- Code here runs immediately after the scene goes entirely off screen
	    end
	end
	-- destroy()
	function scene:destroy( event )
	    sceneGroup = self.view
	    -- Code here runs prior to the removal of scene's view
	end
	-- -----------------------------------------------------------------------------------
	-- Scene event function listeners
	-- -----------------------------------------------------------------------------------
	scene:addEventListener( "create", scene )
	scene:addEventListener( "show", scene )
	scene:addEventListener( "hide", scene )
	scene:addEventListener( "destroy", scene )
	-- -----------------------------------------------------------------------------------

	return scene