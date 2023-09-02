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
local io = require("io")
--common modules
local gc = require("lib.global.constants")
local gv = require("lib.global.variables")
local util = require("lib.global.utilities")
local gameObject = require("lib.game.entity.game_object")

local defaultAnimations = {
	idle = { frames = 4, rate = .8 },
	walk = { frames = 4, rate = 6 },
	--sneak = { frames = 1, rate = 5, loop = true },
	--sprint = { frames = 1, rate = 10, loop = true },
}

local defaultParams = {
	name = "puppet", --should be overriden by whatever creates this puppet
	isPuppet = true,
	attackList = {}, animations = defaultAnimations,
	currentAttack = nil, --set when an attack is fired
	attackSpeed = 1, --1 / this number is how long the attack anim takes to play
	state = "idle", --current state of the puppet, used to determine which animation to play, set by updateState()
	animFrame = 1, frameTimer = 0,  --animation system logic
	attackWindup = false, windupTimer = 0, attackWindingUp = false, --anim system windup logic
	attackChannel = false, channelTimer = 0, attackChanneling = false, --anim system channel logic
	isDead = false, --marks if the puppet is dead
	windupGlow = nil --stores display data for windup
}

-- Define module
local lib_puppet = {}
lib_puppet.textureStore = {}

local function puppetOnFrame(self)
	if self.rect then --dont run anim related functions if no rect
		self:updateState()
		self:animUpdateLoop() --changes puppets current frame based on animation timer
	end
end

function lib_puppet.puppetFactory(puppet)
	--print("adding puppet functions")

	function puppet:makeRect() --makes game objects rect if doesn't exist
		--print("making puppet rect, isPuppet = " .. tostring(self.isPuppet))
		if (self.rect) then
			--print("rect already created")
			return
		end
		--print(self.id.." (id): "..self.name, self.facingDirection.image, self.state, self.animFrame)
		local texture = lib_puppet.textureStore[self.name][self.facingDirection.image][self.state][self.animFrame-1]
		self.rect = display.newImageRect(self.group, texture.filename, texture.baseDir, self.width, self.height)
		self.rect.x, self.rect.y = self.world.x + self.xOffset, self.world.y + self.yOffset

	end

	function puppet:updateRectImage() --overrides gameObject function - called to update image of rect
		--print(json.prettify(self.textures))
		if (self.rect) then
			local s_dir = self.facingDirection.image
			local anim = nil
			if (self.state == "attack") then
				if (self.currentAttack) then
					anim = self.currentAttack.animation
				end
			else
				anim = self.state
			end
			--print(s_dir, anim, self.animFrame)
			if (anim) then
				local texture = lib_puppet.textureStore[self.name][s_dir][anim][self.animFrame-1]
				self.rect.fill = {
					type = "image",
					filename = texture.filename,     -- "filename" property required
					baseDir = texture.baseDir       -- "baseDir" property required
				}
				self.rect:setFillColor(self.lightValue)
			end
		else
			--print("WARNING: rect for", self.name, self.id, "doesn't exist (puppet.lua)")
		end
	end

	function puppet:updateState() --called onFrame sets state of puppet logically
		--[[ if self.name == "character" then
			print("character isMoving", self.isMoving, gv.frame.current)
		end ]]
		if (self.currentAttack) then --begin attack has been called
			self.state = "attack"
			self.currentAnim = self.currentAttack.animData --sets the appropriate animation data
		else
			if (self.isMoving) then --set the state to walk if moving (set in game object)
				self.state = "walk"
			else
				self.state = "idle"
			end
			self.currentAnim = self.animations[self.state]
		end
	end

	function puppet:animUpdateLoop() --called on each game render frame
		local anim = self.currentAnim
		--update rect image on first render frame of loop
		if self.animFrame > anim.frames then --if animation is changed and frame is greater than the number of frames in the animation, reset frame
			self.animFrame = 1
		end
		if (self.frameTimer == 0) then
			self:updateRectImage()
		end
		self.frameTimer = self.frameTimer + gv.frame.dts --add frame delta to timer

		if (self.attackWindingUp) then --windup frame has been reached
			self.windupTimer = self.windupTimer + gv.frame.dts --add frame delta to timer
			if (self.windupTimer >= self.currentAttack.windupTime) then --timer is greater than the animations rate
				self.attackWindingUp = false
				self.windupTimer = 0 --reset windup timer for next windup
				self.animFrame = anim.windupEndFrame --jump to the final frame of the windup
				self:nextAnimFrame(anim)
				return --return out of function to prevent nextAnimFrame from being called twice
			end
		end
		--print(self.state, self.frameTimer, self.currentAnim.rate)
		if self.currentAttack then
			if self.frameTimer >= 1 / self.attackSpeed / anim.frames then --timer is greater than the animations rate
				self:nextAnimFrame(anim)
			end
		else
			if self.frameTimer >= 1 / anim.rate then --timer is greater than the animations rate
				self:nextAnimFrame(anim)
			end
		end
	end

	function puppet:nextAnimFrame(anim) --called to set next frame of animation	
		--print(self.name..".animFrame: " .. self.animFrame .. " / " .. anim.frames)

		if (self.state == "attack") then --attack sub state has finished and looping anim
			self:nextAttackAnimFrame(anim) --returns true if animation is complete
		end
		if (self.animFrame == anim.frames) then --animation is over
			self.animFrame = 1 --resets the frame count for the next animation
		else
			self.animFrame = self.animFrame + 1 --animation not over, increment anim frame
		end
		self.frameTimer = 0 --reset the frame timer for the next animFrame
	end

	function puppet:nextAttackAnimFrame(anim) --called from nextAnimFrame when in attack state
		if (self.animFrame == 1) then
			self:startWindupGlow() --starts windup glow
		end
		if (self.animFrame == anim.windupStartFrame) then --reached windup start frame
			self.attackWindingUp = true --sets attack winding up to true
		end
		if (self.animFrame == anim.windupEndFrame) then --reached attack frame
			if (self.attackWindingUp == true) then
				self.animFrame = anim.windupStartFrame --sets anim frame to windup start to loop
			end
		end
		if (self.animFrame == anim.attackFrame) then
			print("firing attack")
			self.currentAttack:fire(self) --fires the attack
		end
		if (self.animFrame == anim.frames) then --post has finished
			self.currentAttack = nil --set current attack to nil, picked up by updateState on next loop
		end
	end

	function puppet:beginAttackAnim(attack, attackFrameListener) --called from entended objects to start attack animations
		self.currentAttack = attack --set to nil once attack is complete, used to determin whether puppet is in attacking state
		self.attackFrameListener = attackFrameListener --called once animation is complete
		print("start attack for " .. self.currentAttack.name)
		self.animFrame = 1
		self.frameTimer = 0
		self.attackTimer = 0
	end

	function puppet:loadWindupGlow() --called after puppet is created, loads windup data if present
		
		-- Set emitter file path
		local filePath = system.pathForFile( "content/game_objects/puppets/"..self.name.."/windup/emitter.json")
		-- Decode the file
		local emitterParams, pos, msg = json.decodeFile( filePath )
		if emitterParams then
			print( "windup emitter loaded" )
		else
			print( "windup emitter load failed at "..tostring(pos)..": "..tostring(msg) )
		end
		-- Create the emitter with the decoded parameters
		local emitter = display.newEmitter( emitterParams )
		self.group:insert(emitter)
		emitter:stop()
		--create image
		local image = display.newImageRect(self.group, "content/game_objects/puppets/"..self.name.."/windup/glow.png", 64, 64)
		image.isVisible = false
		--store the 
		self.windupGlow = { emitter = emitter, image = image }
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
			transition.moveTo( image, { x = castPos.x, y = castPos.y, time = windupToAttackTime *.75 * 1000, onComplete = destroyGlow } )
			transition.moveTo( emitter, { x = castPos.x, y = castPos.y, time = windupToAttackTime *.75 * 1000 } )
			transition.scaleTo( image, { xScale=.5, yScale=.5, time = windupToAttackTime * 1000 } )
		end
		print(image.x, image.y)
		image.alpha = 0
		image.xScale = .2
		image.yScale = .2
		--glow.blendMode = "add"
		print("time for attack glow = "..windupTime)
		transition.to(image, { time = windupTime * 1000, alpha = .8, onComplete = glowOver })
		transition.scaleTo( image, { xScale=1, yScale=1, time= windupTime * 1000 } )
		
	end

end

function lib_puppet:create(_params) --creates the game object
	--print("creating puppet")

	local puppet = gameObject:create(_params)  --creates game object for puppet
	puppet:addOnFrameMethod(puppetOnFrame)

	puppet.directional = true --all puppets are directional
	puppet.path = "content/game_objects/puppets/" --path for puppets

	puppet:setParams(defaultParams, _params) --adds puppet params
	lib_puppet.puppetFactory(puppet) --adds functions to puppet

	print("puppet created with entity id: ", puppet.id)
	return puppet
end

return lib_puppet
