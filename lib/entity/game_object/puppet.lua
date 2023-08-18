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
local gameObject = require("lib.entity.game_object")

local defaultAnimations = {
	idle = { frames = 4, rate = .8 },
	walk = { frames = 4, rate = 6 },
	--sneak = { frames = 1, rate = 5, loop = true },
	--sprint = { frames = 1, rate = 10, loop = true },
}

local defaultParams = {
	isPuppet = true,
	attackList = {}, animations = defaultAnimations,
	currentAttack = nil, --set when an attack is fired
	currentFrame = 0, frameTimer = 0,  --animation system logic
	attackWindup = false, windupTimer = 0,
	attackChannel = false, channelTimer = 0,
	isDead = false,
	state = "idle",
	collisionSize = nil
}

-- Define module
local lib_puppet = {}
lib_puppet.store = {}
lib_puppet.textureStore = {}

function lib_puppet:storePuppet(puppet)
	puppet.puppetID = #self.store + 1 --creates the object id --NOTE: Different to entity id
	self.store[puppet.puppetID] = puppet --stores the object in this modules store of object
end

function lib_puppet:preloadAnimTextures()

end

function lib_puppet.puppetFactory(puppet)
	print("adding puppet functions")

	function puppet:makeRect() --makes game objects rect if doesn't exist
		print("making gameObject rect, isPuppet = " .. tostring(self.isPuppet))
		if (self.rect) then
			print("rect already created")
			return
		end
		local texture = lib_puppet.textureStore[self.name][self.facingDirection.image][self.state][self.currentFrame]
		self.rect = display.newImageRect(self.group, texture.filename, texture.baseDir, self.width, self.height)
		self.rect.x, self.rect.y = self.world.x + self.xOffset, self.world.y + self.yOffset

	end

	function puppet:updateRectImage() --called to update image of rect
		--print(json.prettify(self.textures))
		if (self.rect) then
			local s_dir = self.facingDirection.image
			print(s_dir, self.state, self.currentFrame)
			local texture = lib_puppet.textureStore[self.name][s_dir][self.state][self.currentFrame]
			self.rect.fill = {
				type = "image",
				filename = texture.filename,     -- "filename" property required
				baseDir = texture.baseDir       -- "baseDir" property required
			}
		else
			print("rect doesn't exist")
		end
	end

	function puppet:nextAttackAnimFrame()
		print(self.attackTimer .. " / " .. self.currentAttack.windupTime)
		if (self.attackTimer >= self.currentAttack.windupTime) then --timer is greater than the spells cast time
			self.currentAnim = self.animations[self.currentAttack.animation] --update the anim to the new state
		end

		print("attack state: " .. self.attackState .. " / " .. #self.attackStates)
		if (self.attackState == #self.attackStates) then --post has finished
			self.animCompleteListener()
			self.animCompleteListener = nil
			
			self.currentAttack = nil      --set current attack to nil, picked up by setState on next loop
			self.attackState = 1
			return --return out of function as we don't want to update the rect image
		end
		self.attackState = self.attackState + 1
		local attackAnim = self.attackStates[self.attackState] --store the attack states locally for readability
		self.currentAnim = self.animations[self.currentAttack.animation][attackAnim] --update the anim to the new state
	end

	function puppet:nextAnimFrame() --called to set next frame of animation	
		print("self.currentFrame: " .. self.currentFrame .. " / " .. self.currentAnim.frames)

		if self.currentFrame == self.currentAnim.frames then --reset current frame once reached anim's frame count
			self.currentFrame = 0
			print("looping: " .. tostring(self.currentAnim.loop))

			if (self.state == "attack") then --attack sub state has finished and looping anim
				self:nextAttackAnimFrame()
			end
		end

		print("updating rect from next image frame") --debug
		self:updateRectImage()
		self.currentFrame = self.currentFrame + 1
	end

	function puppet:updateState() --called by anim loop at top of each loop --controls state of puppet whether moving or attacking
		if (self.currentAttack) then --begin attack has been called
			self.state = "attack"
		elseif (self.isMoving) then --set the state to walk if moving (set in game object)
			self.state = "walk"
		else
			self.state = "idle"
		end
	end

	function puppet:firstAnimFrame()                                        --called by anim loop on first frame of new anim state
		print("first anim frame of new anim state " .. self.state)
		if (self.state == "attack") then                                    --begin attack has been called
			--print("setting currentAnim to: "..self.currentAttack.animation, self.attackStates[self.attackState])
			--print(json.prettify(self.animations))
			self.currentAnim = self.animations[self.currentAttack.animation][self.attackStates[self.attackState]] --override current anim
		elseif (self.currentFrame >= self.currentAnim.frames) then
			self.currentFrame = 0                                           --minus one as frames are zero indexed
		end
		print("updating rect from first image frame") --debug
		self:updateRectImage()
	end

	function puppet:animDirChanged() --called by game object function when direction is updated
		if (self.currentFrame >= self.currentAnim.frames) then
			self.currentFrame = 0 --minus one as frames are zero indexed
		end
	end

	function puppet:animUpdateLoop() --called on each game render frame
		self:updateState()        --update character state
		self.currentAnim = self.animations[self.state]                      --set current animation, defaults to just the name of the state
		--increase attack timer
		if (self.currentAttack) then                  --begin attack has been called
			self.attackTimer = self.attackTimer + gv.frame.dts --add frame delta to timer
		end
		--check to make sure current frame is not past animation state frames
		if (self.currentAnim.frames > 0) then       --if theres more than one frame in the anim data
			self.frameTimer = self.frameTimer + gv.frame.dts --add frame delta to timer
		end
		--print(self.state, self.frameTimer, self.currentAnim.rate)
		if self.frameTimer >= 1 / self.currentAnim.rate then --timer is greater than the animations rate
			self:nextAnimFrame()
			self.frameTimer = 0
		end
	end

	function puppet:makeWindupGlow(a, wt) -- a = attack anims to get pre/main/post time, wt = windup time

		print("adding windup glow")
		--local glowTime = wt + ( 1 / a.pre.rate * a.pre.frames) + (1 / a.main.rate * a.main.frames) + (1 / a.post.rate * a.post.frames)
		local glowTime = wt + ( (1 / a.pre.rate) * (a.pre.frames+ 1))
		local mainTime = ((1 / a.main.rate) * (a.main.frames+1)) --we need to move the rect/emitter to the cast point in the char image over this time
		print("windup, glow, main = "..wt..", "..glowTime..", "..mainTime)

		self.startWindupAttackOffset = { x = gc.charHandsWindup[self.facingDirection.image].x, y = gc.charHandsWindup[self.facingDirection.image].y }
		self.finishWindupAttackOffset = { x = gc.charHandsCast[self.facingDirection.image].x, y = gc.charHandsCast[self.facingDirection.image].y }
		local pos = { x = self.rect.x - self.startWindupAttackOffset.x, y = self.rect.y - self.startWindupAttackOffset.y } 
		local castPos = { x = self.rect.x - self.finishWindupAttackOffset.x, y = self.rect.y - self.finishWindupAttackOffset.y } 
		

		-----------------------------------------------------------------------------------------
		--
		-- emitter
		--
		-----------------------------------------------------------------------------------------
		--Read the exported Particle Designer file (JSON) into a string
		local filePath = system.pathForFile( "content/spells/windup/sparkles.json" )
		local f = io.open( filePath, "r" )
		local emitterData
		if (f) then
			emitterData = f:read( "*a" )
			f:close()
		else
			print( "ERROR: Could not read ", filePath )
		end
		 
		-- Decode the string
		local emitterParams = json.decode( emitterData )
		emitterParams.duration = glowTime + mainTime --override the loaded duration to the glow time (set earlier)
		util.setEmitterColors(emitterParams, self.currentAttack.element.c)
		
		-- Create the emitter with the decoded parameters
		local emitter = display.newEmitter( emitterParams )
		self.group:insert(emitter)
		-- Center the emitter within the content area
		emitter.x, emitter.y = pos.x, pos.y
		emitter:start()
		 
		-----------------------------------------------------------------------------------------
		--
		-- image
		--
		-----------------------------------------------------------------------------------------
		local glow = display.newImageRect(self.group, "content/particles/32_0h.png", 64, 64)
		local c = self.currentAttack.element.c
		glow:setFillColor(c.r, c.g, c.b)
		glow.x, glow.y = pos.x, pos.y
		local function destroyGlow()
			glow:removeSelf()
			emitter:removeSelf()
		end
		local function glowOver()
			--transition.fadeOut(glow, { time = mainTime * 1000, })
			transition.moveTo( glow, { x = castPos.x, y = castPos.y, time = mainTime *.75 * 1000, onComplete = destroyGlow } )
			transition.moveTo( emitter, { x = castPos.x, y = castPos.y, time = mainTime *.75 * 1000 } )
			transition.scaleTo( glow, { xScale=.5, yScale=.5, time = mainTime * 1000 } )
		end
		print(glow.x, glow.y)
		glow.alpha = 0
		glow.xScale = .2
		glow.yScale = .2
		--glow.blendMode = "add"
		print("time for attack glow = "..glowTime)
		transition.to(glow, { time = glowTime * 1000, alpha = .8, onComplete = glowOver })
		transition.scaleTo( glow, { xScale=1, yScale=1, time= glowTime * 1000 } )
		
	end

	function puppet:beginAttackAnim(attack, animCompleteListener)
		self.currentAttack = attack --set to nil once attack is complete, used to determin whether puppet is in attacking state
		self.animCompleteListener = animCompleteListener --called once animation is complete
		print("start attack for " .. self.currentAttack.name)
		if (attack.windupGlow) then
			self:makeWindupGlow(defaultAnimations.attack, attack.windupTime)
		end
		self.currentFrame = 0
		self.frameTimer = 0
		self.attackTimer = 0
		self.attackState = 1
	end

	function puppet:puppetOnFrame()
		self:updateState()
		self:animUpdateLoop() --changes puppets current frame based on animation timer
	end
	puppet:addOnFrameMethod(puppet.puppetOnFrame)
end

function lib_puppet:create(_params) --creates the game object
	print("creating puppet")

	local puppet = gameObject:create(_params)  --creates game object for puppet

	puppet.directional = true --all puppets are directional
	puppet.path = "content/game_objects/puppets/" --path for puppets

	puppet:setParams(defaultParams, _params) --adds puppet params
	lib_puppet.puppetFactory(puppet) --adds functions to puppet

	lib_puppet:storePuppet(puppet)
	print("puppet created with puppet id: " .. puppet.puppetID)
	return puppet
end

return lib_puppet
