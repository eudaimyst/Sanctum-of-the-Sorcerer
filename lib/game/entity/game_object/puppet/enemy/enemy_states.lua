	-----------------------------------------------------------------------------------------
	--
	-- enemy_states.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local json = require("json")

	local dist, selfWorld, targetWorld --recycled distance, self world pos, target pos

	
	local function updatePositions(self)
		selfWorld, targetWorld = self.world, self.attackTarget.world --todo: target into cam position and attack target for diff functions
	end
	local function updateDistance()
		--print(selfWorld.x, selfWorld.y, targetWorld.x, targetWorld.y)
		dist = util.getDistance(selfWorld.x, selfWorld.y, targetWorld.x, targetWorld.y)
	end
	
	local mrand = math.random

	local randomDistance, wanderDist, spawnPos --recycled for getWanderPoint
	local function getWanderPoint()
		randomDistance = mrand(wanderDist.min, wanderDist.max)
		if math.random() > 0.5 then
			return randomDistance
		else
			return randomDistance * -1
		end
	end


	-- Define module
	local states = {}

	local function shouldSleep(self)
		updatePositions(self)
		updateDistance()
		if (dist > self.wakeupDistance) then --put to sleep if outside of wakeupDistance
			return {} --faster true
		else
			return nil --faster false
		end
	end

	states.idle = {
		name = "idle",
		onStateStart = function(self) --called when this state is set
		end,
		onStateEnd = function(self) --called when this state is changed from this state
		end,
		onFrame = function(self) --called every fram when this state is active
			if (not self.moveTarget) then --set an idle move target if one is not set
				wanderDist, spawnPos = self.wanderDistance, self.spawnPos
				local targetPos = { x = spawnPos.x + getWanderPoint(), y = spawnPos.y + getWanderPoint() }
				self:setMoveTarget(targetPos) --game object function
			end
		end,
		onStateUpdate = function(self) --called on stateUpdateRate when this state is active
			if shouldSleep(self) then
				self:setState(states.sleep)
			end
			if (dist < self.sightRange ) then --distance and positions updated in shouldSleep
				print(self.id, "setting state from idle to combat")
				self:setState(states.combat)
			end
		end
	}

	states.combat = {
		name = "combat",
		onStateStart = function(self) --called when this state is set
			self.primedAttack = self.attacks[1]
			print(self.id, " primed attack set to ", self.primedAttack.name)
			updatePositions(self)
			self:setMoveTarget( { x = targetWorld.x, y = targetWorld.y } ) --gameObject function
		end,
		onStateEnd = function(self) --called when this state is changed from this state
		end,
		onFrame = function(self) --called every fram when this state is activet_dist = util.getDistance(self.world.x, self.world.y, gameChar.world.x, gameChar.world.y) --use recycled var
			if self.primedAttack then
				updatePositions(self)
				updateDistance()
				if dist <= self.primedAttack.range then
					print(self.id, "is within attackRange, firing", self.primedAttack.name)
					--fire attack
					self.moveTarget = nil
					self:beginAttackAnim(self.primedAttack)
					self.primedAttack = nil
				end
			end
		end,
		onStateUpdate = function(self) --called on stateUpdateRate when this state is active
			if self.primedAttack then --if an attack is primed, continue to move towards target
				updatePositions(self)
				self:setMoveTarget( { x = targetWorld.x, y = targetWorld.y } ) --gameObject function
			else --if attack has been primed stop trying to move towards target
				if self.currentAttack == nil then --current attack is set to nil when attack is complete
					self:setState(states.combat) --reset the state to re-prime an attack
				end
			end
		end
	}

	states.sleep = {
		name = "sleep",
		onStateStart = function(self) --called when this state is set
		end,
		onStateEnd = function(self) --called when this state is changed from this state
		end,
		onFrame = function(self) --called every fram when this state is active
		end,
		onStateUpdate = function(self) --called on stateUpdateRate when this state is active
			if not shouldSleep(self) then
				self:setState(states.idle)
			end
		end
	}

	states.dead = {
		name = "dead",
		onStateStart = function(self) --called when this state is set
		end,
		onStateEnd = function(self) --called when this state is changed from this state
		end,
		onFrame = function(self) --called every fram when this state is active
		end,
		onStateUpdate = function(self) --called on stateUpdateRate when this state is active
		end
	}

	return states