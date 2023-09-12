	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local puppet = require("lib.game.entity.game_object.puppet")
	local attack = require("lib.game.entity.game_object.puppet.attack")
	local spellParams = require("lib.global.spell_params")
	local util = require("lib.global.utilities")
	local json = require("json")
	local lights = require("lib.game.entity.light_emitter")
	local gv = require("lib.global.variables")

	local hud, map, cam --set on create

	local dt = gv.frame.dt--recycled delta time

	-- Define module
	local lib_character = {
		animations = { --used for loading textures in game module
			idle = { frames = 4, rate = .8 },
			walk = { frames = 4, rate = 4 }}}
	
	local defaultParams = {
		name = "character",
		width = 128,
		currentHP = 100,
		maxHP = 100,
		height = 128,
		yOffset = -32,
		moveSpeed = 180,
		spellSlots = 5,
		--colWidth = 40, colHeight = 40,
		spawnPos = {x=display.contentWidth/2, y=display.contentHeight/2},
		animations = lib_character.animations --used for puppet anim module
	}

	local char

	function lib_character.factory(char) --adds methods to the character entity
		function char:addSpell(spell, slot) --adds spell with passed params to the slot
			print("adding spell: "..spell.name)
			self.animations[spell.animation] = spell.animData
			if (slot) then
				self.spells[slot] = attack:new(spell, self)
			else
				self.spells[#char.spells+1] = attack:new(spell, self)
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

		function char:onTakeDamage()
			hud:updateHealth(self.currentHP, self.maxHP)

		end

		function char:beginCast( target ) --called from game.lua on mouseclick from mouse listener
			local spell = self.activeSpell

			local angle = util.deltaPosToAngle( self.world, target ) --sets the angle of the character to the target
			local dir = util.angleToDirection(angle)
			self:setFacingDirection( dir ) --sets the direction of the character to the angle direction
			local dir_s = dir.image --gets the direction string for the animation

			local windupOffset = spell.animData.attackPos[dir_s] --gets the windup pos from the animation data
			local spellOrigin = { 	x = self.world.x + self.xOffset - windupOffset.x, --spell origin including offsets
									y = self.world.y + self.yOffset - windupOffset.y}
			local delta = util.deltaPos(spellOrigin, target) --gets the difference between the characters position and the target position

			if (spell) then
				if (not self.currentAttack) then --already casting
					if (not spell.onCooldown) then --on cooldown, can't cast
						spell.origin = spellOrigin
						if (target) then
							if (spell.displayType == "projectile") then
								local n = util.normalizeXY(delta)
								spell.normal = n --sets the normal used for its movement
								spell.target = util.factorPos(n, spell.maxDistance) --sets the target to the max distance of the spell
							end
						end
						self:beginAttackAnim(spell) --defined in puppet, shared with enemies
					end
				end
			end
		end
	end

	function lib_character:create(_params, _hud, _map, _cam)
		hud, map, cam = _hud, _map, _cam
		print("creating character entity")

		char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        char:setParams(defaultParams, _params)
		self.factory(char)

		char:makeRect() --creates rect on creation
		char:loadWindupGlow() --creates windup glow emitter on creation
		char.spells = {}
		for _, v in pairs(spellParams) do --temp function to add all spells from spell params
			if v.name then
				char:addSpell(v)
			end
		end

		lights.attachToEntity(char)

		return char
	end
	
	function lib_character:onFrame()
	end


	return lib_character