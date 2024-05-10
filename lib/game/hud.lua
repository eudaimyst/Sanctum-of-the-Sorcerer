	-----------------------------------------------------------------------------------------
	--
	-- module.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")

	local buttons = require("lib.ui.buttons")

	local game, map, sceneGroup, char

	-- Define module
	local hud = {}
		hud.group = {}
		hud.spellButtons = {}
		hud.interactsWithMouse = {} --stores objects that need to be registered with mouse_input

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
			function frame:hide()
				self.rect.isVisible = false
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

		function hud:draw(_char, gameMenuListener, spellbookListener) --takes a reference to the player character and a listener to open the game options menu, and the spell book, and returns the game overlay
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
					local x = frameRect.x + buttonPadding + (pos - 1) * (buttonSize + buttonPadding*2) + buttonSize/2
					local y = frameRect.y + buttonPadding + buttonSize/2
					--local spellButton = hud.makeButton( x, y, buttonSize)
					local spellButton = buttons:create({theme = "fantasy", borderSize = 8, width = buttonSize, height = buttonSize, hasActiveState = true}, 1)
					spellButton.slot = pos
					spellButton.x, spellButton.y = x, y
					function spellButton:onPress() --called from the button itself when clicked by mouse
						char.setActiveSpell(self.slot)
					end
					function spellButton:assignSpell(spell)
						print(spell.name, spell.icon)
						self.icon = display.newImageRect(hud.group, spell.icon, buttonSize, buttonSize)
						self:insert(self.icon)
						local c = spell.element.c
						self.icon:setFillColor(c.r, c.g, c.b)
						--util.zeroAnchors(self.icon)
						--self.icon.x = self.x
						--self.icon.y = self.y
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

			local function drawHealthFrame()
				local width = 300
				local height = 40
				hud.maxhealthWidth = width
				local sw = 4 --strokeWidth
				local cornerRadius = height / 4
				hud.healthFrame = hud.makeFrame()
				hud.healthFrame:resize(width, height)
				local x = hud.gameOverlay.x + 20
				local y = hud.gameOverlay.height - hud.healthFrame.rect.height - 20
				hud.healthFrame:move(x, y)
				hud.healthFrame:hide() --we only use the frame for positioning of the element so hide it
				local fr = hud.healthFrame.rect --readability
				hud.healthBG = display.newRoundedRect(hud.group, fr.x+scaleOffsetW, fr.y, width, height, cornerRadius)
				util.zeroAnchors(hud.healthBG)
				hud.healthBG:setFillColor(.2, .04, .01)
				hud.healthBG:setStrokeColor(0)
				hud.healthBG.strokeWidth = sw
				hud.healthBar = display.newRoundedRect(	hud.group, fr.x+scaleOffsetW + sw, fr.y + sw, width - sw, height - sw, cornerRadius)
				util.zeroAnchors(hud.healthBar)
				hud.healthBar:setFillColor(.4, .08, .02)
				local opt = {text = tostring(100), x = fr.x + scaleOffsetW + width/2, y = fr.y + height / 2 + 9, align = "center",
							 width = width, height = height, font = native.systemFont, fontSize = 24 }
				hud.healthText = display.newText( opt )
				hud.group:insert(hud.healthText)
			end

			local function drawCurrencyFrame()
				local width = 300
				local height = 200
				hud.currencyFrame = hud.makeFrame()
				local o = hud.gameOverlay
				local f = hud.currencyFrame
				f:move(o.width - width - 10, o.height - height)
				f:resize(width, height)
				local s = 48 --image size
				local gold = display.newImageRect(hud.group,"content/ui/coin.png",s,s)
				gold.x = f.rect.x + f.rect.width - s
				gold.y = f.rect.y + f.rect.height - s
				local orb = display.newImageRect(hud.group, "content/ui/orb.png",s,s)
				orb.x = gold.x
				orb.y = gold.y - s - 10
				local opt = {text = tostring(0), x = f.rect.x, y = gold.y - 12, align = "right",
							 width = (width - gold.width) - 40, height = s, font = native.systemFont, fontSize = 24 }
				hud.goldText = display.newText( opt )
				util.zeroAnchors(hud.goldText)
				hud.group:insert(hud.goldText)
				opt = 		{text = tostring(0), x = f.rect.x, y = orb.y - 12, align = "right",
							 width = (width - orb.width) - 40, height = s, font = native.systemFont, fontSize = 24 }
				hud.orbText = display.newText( opt )
				util.zeroAnchors(hud.orbText)
				hud.group:insert(hud.orbText)
			end

			local function drawOptionsButton()
				local optionsButton = buttons:create({theme = "fantasy", borderSize = 8, width = 32, height = 32, label = "O", listener = gameMenuListener}, 1)
				hud.interactsWithMouse[#hud.interactsWithMouse + 1] = optionsButton
				optionsButton.x = hud.gameOverlay.width - optionsButton.width
				optionsButton.y = hud.gameOverlay.y + optionsButton.height/2
				hud.group:insert(optionsButton)
			end

			print("drawing hud")
			drawGameOverlay()
			drawCurrencyFrame()
			drawSpellButtonFrame(#char.spells, 48, 10)
			drawOptionsButton()
			drawHealthFrame()
			self.assignSpells()
			return hud.gameOverlay
		end

		function hud:updateHealth(currentHealth, maxHealth)
			self.healthBar.width = (currentHealth/maxHealth) * self.maxhealthWidth
			self.healthText.text = currentHealth
		end
		function hud:updateGold(val)
			self.goldText.text = tostring(val)
		end
		function hud:updateOrb(val)
			self.orbText.text = tostring(val)
		end


		function hud.init(_sceneGroup, _map, _game )
			print("initialising hud")
			sceneGroup = _sceneGroup
			map = _map
			game = _game
			
			hud.group = display.newGroup()
			sceneGroup:insert(hud.group)
		end

	return hud