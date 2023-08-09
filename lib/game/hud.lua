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
				self.rect.strokeWidth = 1
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

		function hud:draw(_char)
			char = _char
			local function drawGameOverlay()
				hud.gameOverlay = display.newRect(hud.group, 0,0, display.actualContentWidth, display.actualContentHeight)
				util.zeroAnchors(hud.gameOverlay)
				hud.gameOverlay:setFillColor(0,0,0,0)
			end

			local function drawSpellButtonFrame(numButtons, buttonSize, buttonPadding)


				local function drawSpellButton(frameRect, pos)
					
					local x = frameRect.x + buttonPadding + (pos - 1) * (buttonSize + buttonPadding*2)
					local y = frameRect.y + buttonPadding
					
					local spellButton = hud.makeButton( x, y, buttonSize)
					
					function spellButton:assignSpell(spell)
						print(spell.params.name, spell.params.icon)
						self.icon = display.newImageRect(hud.group, spell.params.icon, buttonSize, buttonSize)
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
				local x = display.actualContentWidth/2 - hud.spellButtonFrame.rect.width/2
				local y = display.actualContentHeight - hud.spellButtonFrame.rect.height
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