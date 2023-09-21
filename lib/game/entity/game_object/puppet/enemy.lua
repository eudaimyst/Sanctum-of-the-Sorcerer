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
	local attack = require("lib.game.entity.game_object.puppet.attack")
	local json = require("json");
	local states = require("lib.game.entity.game_object.puppet.enemy.enemy_states")

	local cam --set by game module on init

	local gameChar = nil --set by game module

	-- Define module
	local lib_enemy = {}
	lib_enemy.enemyStore = {}
	local wakeupDistance = 2000 --enemies wake up when the char gets this close

	local stateUpdateTimer = 0 --timer for updating enemy state
	local stateUpdateRate = 500 --(ms) how often to updatestate
	local doStateUpdate = nil --set to true when enemy should update its state

	local function checkBounds(posX, posY, bounds)
		local px, py, cx1, cx2, cy1, cy2 = posX, posY, bounds.x1, bounds.x2, bounds.y1, bounds.y2
		if px > cx1 and px < cx2 and py > cy1 and py < cy2 then
			return true
		else
			return false
		end
	end

	local function updateOnScreen(enemy) --called on frame if enemy is not asleep
		if enemy.onScreen then -- check if enemy goes outside of camera bounds
			if not checkBounds(enemy.x, enemy.y, cam.bounds) then
				print("setting enemy "..enemy.id.." to not visible")
				enemy.onScreen = false
				enemy:destroyRect()
			end
		else --check if enemy enters cameraBounds
			if checkBounds(enemy.x, enemy.y, cam.bounds) then
				print("setting enemy "..enemy.id.." to visible")
				enemy.onScreen = true
				enemy:makeRect()
			end
		end
	end

	local function enemyOnFrame(self)
		--runs every stateUpdateRate
		if (doStateUpdate) then
			if self.enemyState.onStateUpdate then
				self.enemyState.onStateUpdate(self)
			end
		end
		--runs every frame
		if self.enemyState ~= states.sleep then --enemy is not asleep
			if self.enemyState.onFrame then
				self.enemyState.onFrame(self)
			end
			updateOnScreen(self)
		end
	end

	function lib_enemy:create(_params) --called by game module to create enemy from saveData
		--print("creating enemy entity at: " .. _params.x .. ", " .. _params.y .. "")
		local enemy = puppet:create(_params)
		for k, v in pairs(_params) do
			enemy[k] = v
		end
		local spawnPos = _params.spawnPos
		enemy.enemyState = states.sleep --start in sleeping state
		enemy.spawnPos = spawnPos
		enemy.x, enemy.y = spawnPos.x, spawnPos.y
		enemy.onScreen = false
		enemy.primedAttack = nil
		enemy.timeInCombat = 0
		enemy.attackTarget = gameChar
		enemy.wakeupDistance = wakeupDistance

		for i = 1, #_params.attacks do
			enemy.attacks[i] = attack:new(_params.attacks[i].params, enemy)
		end
		
		function enemy:wakeup() --called on frame when wakeupDistance is met
			print("enemy "..self.id.." is waking up")
			self.isAsleep = false
		end

		function enemy:setState(state) --sets the state and calls the relevant state functions
			print(self.id, "setting state to", state.name, "from", self.enemyState.name)
			
			if self.enemyState.onStateEnd then --calls the end function for the current state
				self.enemyState.onStateEnd(self)
			end

			if state.onStateStart then --calls the start function for the new state
				state.onStateStart(self)
			end
			self.enemyState = state --sets the state to the new state
		end

		enemy:addOnFrameMethod(enemyOnFrame)
	end

	function lib_enemy:onFrame() --called by game on frame, timer
		doStateUpdate = nil --force makeDecision to be false unless decisionTimer is reached
		stateUpdateTimer = stateUpdateTimer + gv.frame.dt
		if stateUpdateTimer > stateUpdateRate then
			doStateUpdate = {} --enemies check this to determine whether to make their next decision
			stateUpdateTimer = 0
		end
	end

	function lib_enemy:setGameChar(char)
		gameChar = char
	end

	function lib_enemy.init(_cam)
		cam = _cam
	end

	return lib_enemy