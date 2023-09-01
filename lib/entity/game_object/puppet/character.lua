	-----------------------------------------------------------------------------------------
	--
	-- character.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local puppet = require("lib.entity.game_object.puppet")
	local attack = require("lib.entity.game_object.puppet.attack")
	local spellParams = require("lib.global.spell_params")
	local util = require("lib.global.utilities")
	local json = require("json")
	local lights = require("lib.entity.light_emitter")
	local gv = require("lib.global.variables")

	local hud, map, cam --set on create

	local dt = gv.frame.dt--recycled delta time

	-- Define module
	local lib_character = { animations = { --used for loading textures
		idle = { frames = 4, rate = .8 },
		walk = { frames = 4, rate = 4 },
	} }	

	local char

	--character visibility variableds and functions

	local visUpdateRate = 200 --ms
	local visUpdateTimer = 0
	local visPointCounter = 1
	local visTilePoints = {}
	
	local function setVisiblityPoints(tileSize) --called when character is created
		for vis_y = 1, display.contentHeight / tileSize do
			for vis_x = 1, display.contentWidth / tileSize do
				visTilePoints[visPointCounter] = {x = vis_x, y = vis_y}
				visPointCounter = visPointCounter + 1
			end
		end
	end

	local function updateVisibility()
		for i = 1, visPointCounter do

			local visPoint = visTilePoints[i]
			local rayFinishX, rayFinishY = visPoint.x + cam.bounds.x1, visPoint.y + cam.bounds.y1
			local rayStartX, rayStartY = char.world.x, char.world.y
			local rayLength = util.getDistance(rayStartX, rayStartY, rayFinishX, rayFinishY)
			local rayCheckCount = math.ceil(rayLength/map.halfTileSize)
			local rayDelta = util.deltaPos({x = rayStartX, y = rayStartY}, {x=rayFinishX, y = rayFinishY})
			local rayNormal = util.normalizeXY( rayDelta )
			for i2 = 1, rayCheckCount do
				local checkPos = {x = rayNormal.x * map.halfTileSize, y = rayNormal.y * map.halfTileSize}
				local tile = map.getTileAtPoint(checkPos)
				if tile.type == "void" then
					



		end

	end

	function lib_character:create(_params, _hud, _map, _cam)
		hud, map, cam = _hud, _map, _cam
		setVisiblityPoints(map.tileSize)
		print("creating character entity")
		_params.animations = self.animations --adds the modules defined in the character.lua file to the params to be loaded by puppet module

		char = puppet:create(_params)
		--print("CHARACTER PARAMS:--------\n" .. json.prettify(char) .. "\n----------------------")
        
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

		function char:beginCast( target ) --called from game.lua on mouseclick from mouse listener
			local spell = self.activeSpell

			local angle = util.deltaPosToAngle( self.world, target ) --sets the angle of the character to the target
			local dir = util.angleToDirection(angle)
			self:setFacingDirection( dir ) --sets the direction of the character to the angle direction
			local dir_s = dir.image --gets the direction string for the animation

			local attackPos = spell.animData.attackPos[dir_s] --gets the windup pos from the animation data
			local offsetPos = { x = self.world.x - attackPos.x, y = self.world.y - attackPos.y}
			local delta = util.deltaPos(offsetPos, target) --gets the difference between the characters position and the target position

			local function animCompleteListener() --called when animation is complete
				self.currentAttack:fire(self)
				self.currentAttack = nil
			end


			if (spell) then
				if (not self.currentAttack) then
					if (not spell.onCooldown) then
						spell.origin = offsetPos
						if (target) then
							if (spell.displayType == "projectile") then
								local n = util.normalizeXY(delta)
								spell.normal = n --sets the normal used for its movement
								spell.target = util.factorPos(n, spell.maxDistance) --sets the target to the max distance of the spell
							end
						end
						self:beginAttackAnim(spell, animCompleteListener) --defined in puppet, shared with enemies
					end
				end
			end
		end

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
		visUpdateTimer = visUpdateTimer + dt
		if visUpdateTimer > visUpdateRate then
			visUpdateTimer = 0
			updateVisibility()
		end
	end


	return lib_character