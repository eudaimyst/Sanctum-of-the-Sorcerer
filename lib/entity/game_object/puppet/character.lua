	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local puppet = require("lib.entity.game_object.puppet")
	local attack = require("lib.entity.game_object.puppet.attack")

	local hud --set on create

	-- Define module
	local lib_character = {}

	function lib_character:create(_params, _hud)
		hud = _hud
		print("creating character entity")
		
		local char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        
		function char:addSpell(spellName, slot)
			if (slot) then
				char.spells[slot] = attack:new(spellName or nil)
			else
				char.spells[#char.spells+1] = attack:new(spellName or nil)
			end
		end

		--char:updateFileName()
		char:loadTextures()
		char:makeRect() --creates rect on object creation (remove when camera starts to call this)

		char.spells = { attack:new() }

		return char
	end

	return lib_character