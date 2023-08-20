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

	local game, cam --set by game module on init

	local gameChar = nil --set by game module

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}
	local wakeupDistance = 4000 --enemies wake up when the char gets this close
	local decisionRate = 3 --time in seconds between making decisions

	local function checkBounds(pos, bounds)
		local px, py, cx1, cx2, cy1, cy2 = pos.x, pos.y, bounds.x1, bounds.x2, bounds.y1, bounds.y2
		if px > cx1 and px < cx2 and py > cy1 and py < cy2 then
			return true
		else
			return false
		end
	end

	local function enemyOnFrame(self)
		--if csx == 1 then print(json.prettify(self)) end
		--csx = csx + 1
		if (self.rect) then
			self:updateRectPos() --updates enemy position on screen, game object function
			self:updateRectImage()
		end
		self:setWakefulness()
		if not self.isAsleep then
			enemy:
		end
	end

	function lib_enemy:create(_params)
		
		--print("creating enemy entity at: " .. _params.world.x .. ", " .. _params.world.y .. "")
		local enemy = puppet:create(_params)
		enemy.world.x, enemy.world.y = _params.world.x, _params.world.y
		enemy.isVislbe, enemy.isAsleep = false, true
		
		function enemy:wakeup() --called on frame when wakeupDistance is met
			print("enemy "..self.id.." is waking up")
			self.isAsleep = false
		end

		function enemy:setWakefulness()
			local function setVisibility()
				if self.isVisible then -- check if enemy goes outside of camera bounds
					if not checkBounds(self.world, cam.bounds) then
						self.isVisible = false
						self:destroyRect()
					end
				else --check if enemy enters cameraBounds
					if checkBounds(self.world, cam.bounds) then
						self.isVisible = true
						self:makeRect()
					end
				end
			end
			if (self.isAsleep == true) then
				if (gameChar) then
					local distance = util.getDistance(self.world.x, self.world.y, gameChar.world.x, gameChar.world.y)
					if ( distance < wakeupDistance ) then
						self:wakeup()
					end
				end
			else --enemy is awake
				setVisibility()
			end
		end
		
		enemy:addOnFrameMethod(enemyOnFrame)

	end

	function lib_enemy:setGameChar(char)
		gameChar = char
	end

	function lib_enemy.init(_game, _cam)
		game, cam = _game, _cam
	end

	return lib_enemy