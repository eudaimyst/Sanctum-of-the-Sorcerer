	-----------------------------------------------------------------------------------------
	--
	-- enemy.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local puppet = require("lib.entity.game_object.puppet")
	local json = require("json");

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}

	
	local function enemyOnFrame(self)
		self:updateRectPos() --updates enemy position on screen, game object function
		self:updateRectImage()
	end

	function lib_enemy:create(_params)
		
		--print("creating enemy entity at: " .. _params.world.x .. ", " .. _params.world.y .. "")
		local enemy = puppet:create(_params)
		enemy.world.x, enemy.world.y = _params.world.x, _params.world.y
		enemy:makeRect()

		--print(json.prettify(enemy))
		lib_enemy.enemyStore[#lib_enemy.enemyStore+1] = enemy
		
		enemy:addOnFrameMethod(enemyOnFrame)

	end

	return lib_enemy