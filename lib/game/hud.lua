	-----------------------------------------------------------------------------------------
	--
	-- module.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")

	local game, map, sceneGroup, char

	-- Define module
	local hud = {}
		hud.group = display.newGroup()
		hud.spellButtons = {}

		function hud.makeButton(x, y, w, _h)
			local h = _h or w --if height not specified, make it a square
			local button = {}
			function button:drawRect()
				self.rect = display.newRect(hud.group, 0, 0, w, h)
				util.zeroAnchors(self.rect)
				self.rect:setFillColor(0, 0, 0,.3)
				self.rect:setStrokeColor(0)
				self.rect.strokeWidth = 2
				self.rect.x = x
				self.rect.y = y
			end
			button:drawRect()
			return button
		end

		function hud.makeFrame()
			local frame = {}
			function frame:drawRect()
				self.rect = display.newRect(hud.group, 0, 0, 0, 0)
				util.zeroAnchors(self.rect)
				self.rect:setFillColor(0, 0, 0,.3)
				self.rect:setStrokeColor(0)
				self.rect.strokeWidth = 1
			end
			function frame:move(x, y)
				self.rect.x = x
				self.rect.y = y
			end
			function frame:resize(w, h)
				self.rect.width = w
				self.rect.height = h
			end
			frame:drawRect()
			return frame
		end

		function hud.assignSpells()
			print ("assigning "..#hud.spellButtons.." spells")
			for i = 1, #hud.spellButtons do
				hud.spellButtons[i]:assignSpell(game.char.spells[i])
			end
		end

		function hud.setActiveSpell(slot, b)
			hud.spellButtons[slot]:setActive(b)
		end

		function hud:draw(_char)
			local scaleOffsetW = (display.contentWidth - display.viewableContentWidth) / 2
			local scaleOffsetH = (display.contentHeight - display.viewableContentHeight) / 2
			char = _char
			local function drawGameOverlay()
				hud.gameOverlay = display.newRect(hud.group, 0, 9, display.contentWidth - scaleOffsetW, display.contentHeight - scaleOffsetH)
				util.zeroAnchors(hud.gameOverlay)
				hud.gameOverlay:setFillColor(1,1,1,0)
			end

			local function drawSpellButtonFrame(numButtons, buttonSize, buttonPadding)
				local function drawSpellButton(frameRect, pos)
					
					local x = frameRect.x + buttonPadding + (pos - 1) * (buttonSize + buttonPadding*2)
					local y = frameRect.y + buttonPadding
					
					local spellButton = hud.makeButton( x, y, buttonSize)

					function spellButton:setActive(b) --b = bool; true = active, false = inactive 
						if (b) then
							self.rect:setStrokeColor(1, 1, 0, 1)
						else
							self.rect:setStrokeColor(0)
						end
					end
					
					function spellButton:assignSpell(spell)
						print(spell.name, spell.icon)
						self.icon = display.newImageRect(hud.group, spell.icon, buttonSize, buttonSize)
						local c = spell.element.c
						self.icon:setFillColor(c.r, c.g, c.b)
						util.zeroAnchors(self.icon)
						self.icon.x = self.rect.x
						self.icon.y = self.rect.y
					end
					return spellButton
				end

				hud.spellButtonFrame = hud.makeFrame()
				local w = numButtons * (buttonSize + (buttonPadding * 2) )
				local h = buttonSize + buttonPadding * 2
				hud.spellButtonFrame:resize(w, h)
				local x = (hud.gameOverlay.width  - hud.spellButtonFrame.rect.width + scaleOffsetW) * .5
				local y = (hud.gameOverlay.height - hud.spellButtonFrame.rect.height - 10)
				hud.spellButtonFrame:move(x, y)
				for i = 1, numButtons do
					hud.spellButtons[i] = drawSpellButton(hud.spellButtonFrame.rect, i)
				end
			end
			print("drawing hud")
			drawGameOverlay()
			drawSpellButtonFrame(#char.spells, 48, 10)
			self.assignSpells()
		end

		function hud.init(_sceneGroup, _map, _game )
			print("initialising hud")
			sceneGroup = _sceneGroup
			map = _map
			game = _game
		end

	return hud