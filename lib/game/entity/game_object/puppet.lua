-----------------------------------------------------------------------------------------
--
-- puppet.lua
--
-- Features:
---------------
-- Controls the gameObjects display objects based off movement logic, ie when moving it will play the appropriate animation, also includes any future hardbody physics features that need to be added to a gameObject.
--
-- Contains:
---------------
-- Essentially any logic that gets shared between enemy and character, but does not belong in gameObject
-- Functions to perform Spell cast / Attacks goes here (as opposed to decided whether to do them which is in subclasses)
-- Animation / directional facing logic
-----------------------------------------------------------------------------------------
local json = require("json")
--common modules
local gv = require("lib.global.variables")
local util = require("lib.global.utilities")
local gameObject = require("lib.game.entity.game_object")
local collision = require("lib.game.entity.game_object.collision")

local defaultAnimations = {
	idle = { frames = 4, rate = .8 },
	walk = { frames = 4, rate = 6 },
	--sneak = { frames = 1, rate = 5, loop = true },
	--sprint = { frames = 1, rate = 10, loop = true },
}

local bloodParticleParams = {
	minRadius = 200,
	maxRadius = 0,
	duration = 0.2,
	tangentialAcceleration = 0,
	emitterType = 0,
	radialAcceleration = 0,
	rotatePerSecondVariance = 0,
	speed = 100,
	maxParticles = 5,
	finishColorRed = 1,
	minRadiusVariance = 0,
	startParticleSize = 5,
	angleVariance = 180,
	particleLifespan = 0.4,
	absolutePosition = false,
	textureFileName = "content/particles/splat_2.png",
	finishParticleSizeVariance = 10,
	finishColorVarianceRed = 0,
	startColorVarianceBlue = 0,
	radialAccelVariance = 0,
	startParticleSizeVariance = 5,
	startColorRed = 1,
	startColorAlpha = 1,
	finishColorVarianceAlpha = 0,
	finishColorVarianceGreen = 0,
	startColorVarianceGreen = 0,
	rotationStartVariance = 0,
	maxRadiusVariance = 0,
	startColorVarianceAlpha = 0,
	startColorVarianceRed = 0.5,
	startColorBlue = 0,
	tangentialAccelVariance = 0,
	rotatePerSecond = 0,
	finishColorVarianceBlue = 0,
	rotationStart = 0,
	angle = -90,
	finishColorGreen = 0,
	particleLifespanVariance = 0,
	blendFuncSource = 770,
	sourcePositionVariancey = 0,
	speedVariance = 0,
	blendFuncDestination = 772,
	rotationEndVariance = 30,
	finishColorBlue = 0.2,
	finishParticleSize = 120,
	gravityy = 0,
	gravityx = 0,
	rotationEnd = 0,
	sourcePositionVariancex = 0,
	startColorGreen = 0,
	finishColorAlpha = 0.8,
}

local defaultParams = {
	name = "puppet", --should be overriden by whatever creates this puppet
	isPuppet = true,
	attackList = {},
	animations = defaultAnimations,
	currentAttack = nil, --set when an attack is fired
	attackSpeed = 1,  --1 / this number is how long the attack anim takes to play
	state = "idle",   --current state of the puppet, used to determine which animation to play, set by updateState()
	animFrame = 1,
	frameTimer = 0,   --animation system logic
	attackWindup = false,
	windupTimer = 0,
	attackWindingUp = false, --anim system windup logic
	attackChannel = false,
	channelTimer = 0,
	attackChanneling = false, --anim system channel logic
	isDead = false,        --marks if the puppet is dead
	windupGlow = nil       --stores display data for windup
}

-- Define module
local lib_puppet = {}
lib_puppet.textureStore = {}

local function puppetOnFrame(self)
	if self.rect then --dont run anim related functions if no rect
		if self.state == "death" then
			--do not update state if dead
			return
		end

		self:updateState()
		self:animUpdateLoop() --game object function that interfaces with the animation library
	end
end

function lib_puppet.factory(puppet)
	--print("adding puppet functions")

	function puppet:updateState() --called onFrame sets state of puppet logically
		--[[ if self.name == "character" then
			print("character isMoving", self.isMoving, gv.frame.current)
		end ]]
		if (self.currentAttack) then              --begin attack has been called
			self.state = "attack"
			self.currentAnim = self.currentAttack.animData --sets the appropriate animation data
		else
			if (self.isMoving) then               --set the state to walk if moving (set in game object)
				self.state = "walk"
			else
				self.state = "idle"
			end
			self.currentAnim = self.animations[self.state]
		end
	end

	function puppet:loadWindupGlow() --called after puppet is created, loads windup data if present
		-- Set emitter file path
		local filePath = system.pathForFile("content/game_objects/puppets/" .. self.name .. "/windup/emitter.json")
		-- Decode the file
		local emitterParams, pos, msg = json.decodeFile(filePath)
		if emitterParams then
			print("windup emitter loaded")
		else
			print("windup emitter load failed at " .. tostring(pos) .. ": " .. tostring(msg))
		end
		-- Create the emitter with the decoded parameters
		local emitter = display.newEmitter(emitterParams)
		self.group:insert(emitter)
		emitter:stop()
		--create image
		local image = display.newImageRect(self.group, "content/game_objects/puppets/" .. self.name .. "/windup/glow.png",
			64, 64)
		image.isVisible = false
		--store the
		self.windupGlow = { emitter = emitter, image = image }
	end

	function puppet:bloodSplatterEmitter()
		print("bloodSplatterTriggered")
		local emitter = display.newEmitter(bloodParticleParams)
		self.group:insert(emitter)
		local pos = { x = self.rect.x, y = self.rect.y }
		emitter.x, emitter.y = pos.x, pos.y
		emitter:start()
		local function onTimer(event)
			-- Access "params" table by pointing to "event.source" (the timer handle)
			emitter:stop()
		end
		timer.performWithDelay(emitter.duration * 1000, onTimer)
	end

	function puppet:startWindupGlow() -- a = attack anims to get pre/main/post time, wt = windup time
		local attack = self.currentAttack
		local anim = attack.animData
		local windupOffset = anim.windupPos[self.facingDirection.image]
		local attackOffset = anim.attackPos[self.facingDirection.image]

		print("adding windup glow")
		local windupTime = attack.windupTime
		local windupToAttackTime = (anim.attackFrame) * (1 / anim.frames / self.attackSpeed)

		local pos = { x = self.rect.x - windupOffset.x, y = self.rect.y - windupOffset.y }
		local castPos = { x = self.rect.x - attackOffset.x, y = self.rect.y - attackOffset.y }


		-----------------------------------------------------------------------------------------
		--
		-- emitter
		--
		-----------------------------------------------------------------------------------------
		local emitter = self.windupGlow.emitter
		--override the loaded duration to the glow time (set earlier)
		emitter.duration = windupTime
		--set emitter colors
		util.setEmitterColors(emitter, self.currentAttack.element.c)
		emitter:stop()
		emitter.x, emitter.y = pos.x, pos.y
		emitter:start()

		-----------------------------------------------------------------------------------------
		--
		-- image
		--
		-----------------------------------------------------------------------------------------
		local image = self.windupGlow.image
		local c = self.currentAttack.element.c
		image.isVisible = true
		image:setFillColor(c.r, c.g, c.b)
		image.x, image.y = pos.x, pos.y
		local function destroyGlow()
			image.isVisible = false
			emitter:stop()
		end
		local function glowOver()
			--transition.fadeOut(glow, { time = mainTime * 1000, })
			transition.moveTo(image,
				{ x = castPos.x, y = castPos.y, time = windupToAttackTime * .75 * 1000, onComplete = destroyGlow })
			transition.moveTo(emitter, { x = castPos.x, y = castPos.y, time = windupToAttackTime * .75 * 1000 })
			transition.scaleTo(image, { xScale = .5, yScale = .5, time = windupToAttackTime * 1000 })
		end
		print(image.x, image.y)
		image.alpha = 0
		image.xScale = .2
		image.yScale = .2
		--glow.blendMode = "add"
		print("time for attack glow = " .. windupTime)
		transition.to(image, { time = windupTime * 1000, alpha = .8, onComplete = glowOver })
		transition.scaleTo(image, { xScale = 1, yScale = 1, time = windupTime * 1000 })
	end
end

function lib_puppet:create(_params) --creates the game object
	--print("creating puppet")

	local puppet = gameObject:create(_params) --creates game object for puppet
	puppet:addOnFrameMethod(puppetOnFrame)

	puppet.directional = true                  --all puppets are directional
	puppet.path = "content/game_objects/puppets/" --path for puppets
	puppet.attackTarget = nil

	puppet:setParams(defaultParams, _params) --adds puppet params
	lib_puppet.factory(puppet)            --adds functions to puppet

	print("puppet created with entity id: ", puppet.id)
	return puppet
end

return lib_puppet
