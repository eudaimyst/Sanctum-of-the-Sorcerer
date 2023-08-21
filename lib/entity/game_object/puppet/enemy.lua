	-----------------------------------------------------------------------------------------
	--
	-- enemy.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local puppet = require("lib.entity.game_object.puppet")
	local json = require("json");

	local game, cam --set by game module on init

	local gameChar = nil --set by game module
	local actions = { "moveIdle", "moveToAttack", "leash"}

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}
	local wakeupDistance = 4000 --enemies wake up when the char gets this close
	local decisionRate = 3 --time in seconds between making decisions

	local decisionTimer = 0
	local decisionRate = 500 --(ms) how often to decide next action to take
	local makeDecision = nil

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
		--calculating distance is expensive so we will do it once then pass it around where needed
		local distance = util.getDistance(self.world.x, self.world.y, gameChar.world.x, gameChar.world.y)
		
		if (self.rect) then
			self:updateRectPos() --updates enemy position on screen, game object function
			self:updateRectImage()
		end
		self:updateSleep(distance)
		if self.isAsleep == false then
			if (makeDecision) then
				--print(tostring(makeDecision))
				self:makeDecision(distance)
			end
		end

	end

	function lib_enemy:create(_params) --called by game module to create enemy from saveData
		--print("creating enemy entity at: " .. _params.world.x .. ", " .. _params.world.y .. "")
		local enemy = puppet:create(_params)
		for k, v in pairs(_params) do
			enemy[k] = v
		end
		local spawnPos = _params.spawnPos
		enemy.spawnPos = spawnPos
		enemy.world.x, enemy.world.y = spawnPos.x, spawnPos.y
		enemy.isVislbe, enemy.isAsleep = false, true
		enemy.currentAction = nil
		enemy.timeInCombat = 0
		
		function enemy:wakeup() --called on frame when wakeupDistance is met
			print("enemy "..self.id.." is waking up")
			self.isAsleep = false
		end

		function enemy:updateSleep(distance)
			
			if (self.isAsleep == true) then
				if (gameChar) then
					if ( distance < wakeupDistance ) then
						print("waking up enemy "..self.id)
						self.isAsleep = false
					end
				end
			else --enemy is awake
				if ( distance > wakeupDistance ) then
					print("putting enemy "..self.id.." to sleep")
					self.isAsleep = true
				end
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
		end

		function enemy:moveToAttack()

		end

		function enemy:moveIdle()
			local function getWanderPoint()
				return math.random(-self.wanderDistance, self.wanderDistance)
			end
			local newTargetPos = { x = getWanderPoint(), y = getWanderPoint() }
			self.moveTarget = newTargetPos 
		end

		function enemy:makeDecision(distance) --called from enemies onFrame if decisionTimer > decisionRate
			print("enemy "..self.id.." is deciding action")
			if (self.currentAction) then
				if ( self.currentAction == self.moveToIdle) then
					if (distance < self.sightRange ) then
						self.currentAction = self.moveToAttack
					end
				elseif (self.currentAction == self.moveToAttack) then
					if (self.timeInCombat > self.leashTime) then
						self.currentAction = self.moveIdle
					end
				end
			else
				print("distance, sightRange: "..distance, tostring(self.sightRange))
				if (distance < self.sightRange ) then
					self.currentAction = self.moveToAttack
				else
					self.currentAction = self.moveToIdle
				end
			end

		end

		enemy:addOnFrameMethod(enemyOnFrame)
	end

	function lib_enemy:onFrame() --if called before each enemy on frame, they'll make decision this frame, otherwise next frame
		makeDecision = nil --force makeDecision to be false unless decisionTimer is reached
		decisionTimer = decisionTimer + gv.frame.dt
		if decisionTimer > decisionRate then
			makeDecision = true --enemies check this to determine whether to make their next decision
			print("makeDecision: "..tostring(makeDecision) )
			decisionTimer = 0
		end
			
	end

	function lib_enemy:setGameChar(char)
		gameChar = char
	end

	function lib_enemy.init(_game, _cam)
		game, cam = _game, _cam
	end

	return lib_enemy