	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local puppet = require("lib.entity.game_object.puppet")
	local attack = require("lib.entity.game_object.puppet.attack")
	local spellParams = require("lib.global.spell_params")
	local hud --set on create

	-- Define module
	local lib_character = {}

	function lib_character:create(_params, _hud)
		hud = _hud
		print("creating character entity")
		
		local char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        
		function char:addSpell(spell, slot) --adds spell with passed params to the slot
			if (slot) then
				char.spells[slot] = attack:new(spell or nil)
			else
				char.spells[#char.spells+1] = attack:new(spell or nil)
			end
		end

		function char.setActiveSpell(slot) --sets the active spell to the passed slot number, can't send self as coming from key listener
			if char.spells[slot] then
				if (char.activeSpellSlot) then
					hud.setActiveSpell(char.activeSpellSlot, false) --deactivates the current spell in the hud
				end
				char.activeSpellSlot = slot --sets the new slot
				hud.setActiveSpell(slot, true) --activates it in the hud
				char.activeSpell = char.spells[slot] --stores the active spell
				char.activeSpell:activate() --calls activate function on spell itself (for instants)
			else
				print("spell does not exist in slot #"..tostring(slot))
			end
		end

		function char:beginCast( target )
			if (self.activeSpell) then
				if (not self.currentAttack) then
					if (not self.activeSpell.onCooldown) then
						self.activeSpell.origin = self.world --set origin to characters position
						if (target) then
							self.activeSpell.target = target
							self.activeSpell.delta = { x = target.x - self.world.x, y = target.y - self.world.y }
						end
						print("start attack for "..self.activeSpell.params.name)
						self:beginAttackAnim(self.activeSpell) --defined in puppet, shared with enemies
					end
				end
			end
		end
		--char:updateFileName()
		char:loadTextures()
		char:makeRect() --creates rect on creation
		char.spells = { attack:new(spellParams.fireball), attack:new(spellParams.firewall) } --set initial spells for testing, TODO: use addSpell from spells in char params
		--char.setActiveSpell(1)

		return char
	end

	return lib_character