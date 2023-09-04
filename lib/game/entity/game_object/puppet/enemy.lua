	-----------------------------------------------------------------------------------------
	--
	-- enemy.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local puppet = require("lib.game.entity.game_object.puppet")
	local json = require("json");

	local game, cam --set by game module on init

	local gameChar = nil --set by game module
	local actions = { "moveIdle", "moveToAttack", "leash"}

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}
	local wakeupDistance = 2000 --enemies wake up when the char gets this close
	local decisionRate = 3 --time in seconds between making decisions

	local decisionTimer = 0
	local decisionRate = 500 --(ms) how often to decide next action to take
	local makeDecision = nil

	local moveTargetFuzzy = 10

	local function checkBounds(pos, bounds)
		local px, py, cx1, cx2, cy1, cy2 = pos.x, pos.y, bounds.x1, bounds.x2, bounds.y1, bounds.y2
		if px > cx1 and px < cx2 and py > cy1 and py < cy2 then
			return true
		else
			return false
		end
	end

	local t_dist --recycled distance
	local function enemyOnFrame(self)
		if (makeDecision) then
			t_dist = util.getDistance(self.world.x, self.world.y, gameChar.world.x, gameChar.world.y)
			self:updateSleep(t_dist) --wakes/sleeps enemy
			if self.isAsleep == false then
				--print(tostring(makeDecision))
				self.currentAction = self:makeDecision(t_dist) --makes a decision and stores the result function as currentAction
			end
		end
		if self.currentAction then --if a function has been set as the currentAction, run that function
			self:currentAction()
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
		enemy.currentAttack = nil
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
						print("setting enemy "..self.id.." to not visible")
						self.isVisible = false
						self:destroyRect()
					end
				else --check if enemy enters cameraBounds
					if checkBounds(self.world, cam.bounds) then
						print("setting enemy "..self.id.." to visible")
						self.isVisible = true
						self:makeRect()
					end
				end
			end
		end

		function enemy:decideCurrentAttack()--called from make decision if in sight range
			--todo: choose the attack with the lowest priority
			print("huh?")
			self.currentAttack = self.attacks[1].params
			print(self.id, " current attack set to ", self.currentAttack.name)
		end
		
		function enemy:beginAttack()
			--temp pretend attack is completed
			print(self.id, "attack complete")
			self.currentAction = self.moveIdle
		end

		function enemy:moveToAttack()
			--print("enemy "..self.id.." is moving to attack")
			t_dist = util.getDistance(self.world.x, self.world.y, gameChar.world.x, gameChar.world.y) --use recycled var
			if t_dist < self.currentAttack.range then
				print(self.id, "is within attackRange")
				self.currentAction = self.beginAttack
			end
			if (gameChar) then
				self:setMoveTarget( { x = gameChar.world.x, y = gameChar.world.y } ) --gameObject function
			else
				print("moveToAttack: no char found or no world coords for enemy", self.id)
			end
		end

		function enemy:moveIdle() --called on frame if this function is the currentAction set by makeDecision
			if (not self.moveTarget) then
				--print("setting idle target for "..self.id)
				local function getWanderPoint()
					local r = math.random(self.wanderDistance.min, self.wanderDistance.max)
					if math.random() > 0.5 then
						return r
					else
						return r * -1
					end
				end
				local targetPos = { x = self.spawnPos.x + getWanderPoint(), y = self.spawnPos.y + getWanderPoint() }
				--local targetPos = { x = self.spawnPos.x, y = self.spawnPos.y }
				--print(self.name, self.id, "move idle target pos:", targetPos.x, targetPos.y)
				self:setMoveTarget(targetPos) --game object function
				self.currentAction = nil -- no more action taken until enemy makesDecision again
			end
		end

		function enemy:makeDecision(distance) --called from enemies onFrame if decisionTimer > decisionRate
			--print("enemy "..self.id.." is deciding action")
			if (self.currentAction) then --makeDecision does not get called if currentAction is set
				if ( self.currentAction == self.moveToIdle) then
					if (distance < self.sightRange ) then
						print("setting current action to moveToATtack from idle")
						self:decideCurrentAttack()
						return self.moveToAttack
					end
				elseif (self.currentAction == self.moveToAttack) then
					if (self.timeInCombat > self.leashTime) then
						--print("setting current action to moveToIdle due to leashing")
						return self.moveIdle
					end
				end
			else
				--print("distance, sightRange: "..distance, tostring(self.sightRange))
				if (distance < self.sightRange ) then
					print("setting current action to moveToAttack due to sight range")
					self:decideCurrentAttack()
					return self.moveToAttack
				else
					--print("setting action to idle")
					if self.moveTarget then --already moving to a target
						return nil
					else
						return self.moveIdle
					end
				end
			end

		end

		enemy:addOnFrameMethod(enemyOnFrame)
	end

	function lib_enemy:onFrame() --called by game on frame, timer
		makeDecision = nil --force makeDecision to be false unless decisionTimer is reached
		decisionTimer = decisionTimer + gv.frame.dt
		if decisionTimer > decisionRate then
			makeDecision = true --enemies check this to determine whether to make their next decision
			--print("makeDecision: "..tostring(makeDecision) )
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