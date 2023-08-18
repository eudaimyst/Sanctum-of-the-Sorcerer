	-----------------------------------------------------------------------------------------
	--
	-- enemy.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local puppet = require("lib.entity.game_object.puppet")

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}

	
	function lib_enemy:create(_params)
		print("creating enemy entity")
		
		local enemy = puppet:create(_params)
		lib_enemy.enemyStore[#lib_enemy.enemyStore+1] = enemy

		function enemy:enemyOnFrame()
			--self:updateRectPos() --updates game char position on screen, game object function
		end
		enemy:addOnFrameMethod(enemy.enemyOnFrame)

	end

	return lib_enemy