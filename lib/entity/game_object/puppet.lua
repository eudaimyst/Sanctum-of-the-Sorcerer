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
local cam = require("lib.camera")

-- Define module
local lib_puppet = {}
lib_puppet.store = {}

local defaultAnimations = {
	idle = { frames = 4, rate = .8, loop = true },
	walk = { frames = 4, rate = 6, loop = true },
	sneak = { frames = 1, rate = 5, loop = true },
	sprint = { frames = 1, rate = 10, loop = true },
	death = {
		pre = { frames = 1, rate = 10, loop = false, duration = .5 },
		main = { frames = 1, rate = 3, loop = false, duration = .5 },
		post = { frames = 1, rate = 10, loop = false, duration = .5 },
	},
	attack = {
		pre = { frames = 3, rate = 20, loop = false },
		windup = { frames = 4, rate = 12, loop = true },
		main = { frames = 3, rate = 8, loop = false },
		post = { frames = 2, rate = 10, loop = false },
	}
}



local defaultParams = {
	isPuppet = true,
	attackList = {},
	animations = {},
	currentAttack = nil,
	isDead = false,
	state = "idle",
	previousState = "",
	attackState = 1,
	currentFrame = 0,
	frameTimer = 0,
	attackTimer = 0,
	width = 64,
	height = 128,
	attackStates = { "pre", "windup", "main", "post" }
}

function lib_puppet.setParams(puppet, _params)
	print("setting puppet params")

	if (not _params) then             --if no params passed use default anaimations
		defaultParams.animations = util.deepcopy(defaultAnimations)
	elseif (not _params.animations) then --params passed but no animations defined in params
		defaultParams.animations = util.deepcopy(defaultAnimations)
	end
	puppet:setParams(defaultParams, _params) --adds puppet params
	--print("PUPPET PARAMS:--------\n" .. json.prettify(puppet) .. "\n----------------------")
end

function lib_puppet:storeObject(puppet)
	puppet.puppetID = #self.store + 1 --creates the object id --NOTE: Different to entity id
	self.store[puppet.puppetID] = puppet --stores the object in this modules store of object
end

function lib_puppet.puppetFactory(puppet)
	print("adding puppet functions")

	---@diagnostic disable-next-line: duplicate-set-field (deliberately overriding updateFileName for puppet)
	function puppet:updateFileName() --sets file name referred to by display object
		print("updating puppets file name")
		self.fName = self.path ..
			self.name .. "/" .. self.state .. "/" .. self.facingDirection.image .. "/" .. self.currentFrame .. ".png"
	end

	function puppet:loadTextures() --overrides gameObject function
		print("loading puppet textures")
		self.textures = {}
		for _, dir in pairs(gc.move) do --for each direction
			--print("adding textures for direction: "..dir.image)
			self.textures[dir.image] = {}
			for animName, animData in pairs(self.animations) do --for each animation
				--print("adding textures for animName: "..animName)
				self.textures[dir.image][animName] = {}
				if (animData.frames) then --if no sub animations (walk, spring, etc...)
					for i = 0, animData.frames - 1 do --zero indexed animation file names
						--print("adding textures for frame: "..i)
						self.textures[dir.image][animName][i] = graphics.newTexture({
							type = "image",
							baseDir = system.ResourceDirectory,
							filename = self.path .. self.name .. "/" .. animName .. "/" .. dir.image .. "/" .. i ..
								".png"
						})
					end
				else
					for subAnimName, subAnimData in pairs(animData) do --for each sub animation (pre, main, post... etc)
						--print("adding textures for subAnimName: "..subAnimName)
						self.textures[dir.image][animName][subAnimName] = {}
						for i = 0, subAnimData.frames - 1 do --zero indexed animation file names
							--print("adding textures for frame: "..i)
							local texture = graphics.newTexture({
								type = "image",
								baseDir = system.ResourceDirectory,
								filename = self.path ..
									self.name .. "/" .. animName .. "/" .. dir.image .. "/" .. subAnimName .. "_" ..
									i .. ".png"
							})
							if (texture) then
								--print(texture.filename)
								self.textures[dir.image][animName][subAnimName][i] = texture
								--print(dir.image, animName, subAnimName, i)
							end
						end
					end
				end
			end
		end
		print("setting texture to ", self.facingDirection.image, self.state, self.currentFrame)
		self.texture = self.textures[self.facingDirection.image][self.state][self.currentFrame]
	end

	function puppet:nextAnimFrame() --called to set next frame of animation	
		print("self.currentFrame: " .. self.currentFrame .. " / " .. self.currentAnim.frames)

		if self.currentFrame == self.currentAnim.frames then --reset current frame once reached anim's frame count
			print("looping: " .. tostring(self.currentAnim.loop))
			if (self.currentAnim.loop == true) then    --if animation is looping
				print("anim state looping")
				self.currentFrame = 0
				if (self.state == "attack") then                        --attack sub state has finished and looping anim
					print(self.attackTimer .. " / " .. self.currentAttack.params.windupTime)
					if (self.attackTimer >= self.currentAttack.params.windupTime) then --timer is greater than the spells cast time
						self.attackState = self.attackState + 1
						self.currentAnim = self.animations[self.state]
							[self.attackStates[self.attackState]] --update the anim to the new state
					end
				end
			else
				if (self.state == "attack") then --attack sub state has finished and not looping anim
					print("attack state: " .. self.attackState .. " / " .. #self.attackStates)
					self.currentFrame = 0
					if (self.attackState == #self.attackStates) then --post has finished
						self.currentAttack = nil      --set current attack to nil, picked up by setState on next loop
						self.attackState = 1
						return
					end
					self.attackState = self.attackState + 1
					self.currentAnim = self.animations[self.state]
						[self.attackStates[self.attackState]] --update the anim to the new state
				end
			end
		end

		self:updateRectImage()
		self.currentFrame = self.currentFrame + 1
	end

	function puppet:updateState() --called by anim loop at top of each loop --controls state of puppet whether moving or attacking
		if (self.currentAttack) then --begin attack has been called
			--print("attacking: "..self.currentAttack.params.name)
			self.state = "attack"
		elseif (self.isMoving) then --set the state to walk if moving (set in game object)
			self.state = "walk"
		else
			self.state = "idle"
		end
		--print("state updated to: "..self.state)
	end

	function puppet:firstAnimFrame()                                        --called by anim loop on first frame of new anim state
		print("first anim frame of new anim state " .. self.state)
		self.currentAnim = self.animations[self.state]                      --set current animation

		if (self.state == "attack") then                                    --begin attack has been called
			self.currentAnim = self.currentAnim[self.attackStates[self.attackState]] --override current anim
		elseif (self.currentFrame >= self.currentAnim.frames) then
			self.currentFrame = 0                                           --minus one as frames are zero indexed
		end
		self:updateRectImage()
	end

	function puppet:animDirChanged() --called by game object function when direction is updated
		if (self.currentFrame >= self.currentAnim.frames) then
			self.currentFrame = 0 --minus one as frames are zero indexed
		end
	end

	function puppet:animUpdateLoop() --called on each game render frame
		self:updateState()        --update character state
		--if the animation state has changed
		if (self.state ~= self.previousState) then
			print("char state changed to " .. self.state .. " from " .. self.previousState)
			self:firstAnimFrame()
		end
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
		self.previousState = self.state --used for checking when animation changes
	end

	function puppet:makeWindupGlow(a, wt) -- a = attack anims to get pre/main/post time, wt = windup time

		print("adding windup glow")
		--local glowTime = wt + ( 1 / a.pre.rate * a.pre.frames) + (1 / a.main.rate * a.main.frames) + (1 / a.post.rate * a.post.frames)
		local glowTime = wt + ( (1 / a.pre.rate) * (a.pre.frames+ 1))
		local mainTime = ((1 / a.main.rate) * (a.main.frames+1)) --we need to move the rect/emitter to the cast point in the char image over this time
		print("windup, glow, main = "..wt..", "..glowTime..", "..mainTime)

		local pos = { 	x = self.rect.x - gc.charHandsWindup[self.facingDirection.image].x,
						y = self.rect.y - gc.charHandsWindup[self.facingDirection.image].y } 
		local castPos = { 	x = self.rect.x - gc.charHandsCast[self.facingDirection.image].x,
						y = self.rect.y - gc.charHandsCast[self.facingDirection.image].y } 
		

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
		util.setEmitterColors(emitterParams, self.currentAttack.params.element.c)
		
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
		local c = self.currentAttack.params.element.c
		glow:setFillColor(c.r, c.g, c.b)
		glow.x, glow.y = pos.x, pos.y
		local function destroyGlow()
			glow:removeSelf()
			emitter:removeSelf()
		end
		local function glowOver()
			transition.fadeOut(glow, { time = mainTime * 1000, onComplete = destroyGlow})
			transition.moveTo( glow, { x = castPos.x, y = castPos.y, time = mainTime * 1000 } )
			transition.moveTo( emitter, { x = castPos.x, y = castPos.y, time = mainTime * 1000 } )
			transition.scaleTo( glow, { xScale=.5, yScale=.5, time = mainTime * 1000 } )
		end
		print(glow.x, glow.y)
		glow.alpha = 0
		glow.xScale = .2
		glow.yScale = .2
		glow.blendMode = "add"
		print("time for attack glow = "..glowTime)
		transition.to(glow, { time = glowTime * 1000, alpha = .8, onComplete = glowOver })
		transition.scaleTo( glow, { xScale=1, yScale=1, time= glowTime * 1000 } )
		
	end

	function puppet:beginAttackAnim(attack)
		puppet.currentAttack = attack --set to nil once attack is complete, used to determin whether puppet is in attacking state
		print("start attack for " .. self.currentAttack.params.name)
		if (attack.params.windupGlow) then
			self:makeWindupGlow(defaultAnimations.attack, attack.params.windupTime)
		end
		self.currentFrame = 0
		self.frameTimer = 0
		self.attackTimer = 0
		self.attackState = 1
	end
end

function lib_puppet:create(_params) --creates the game object
	print("creating puppet")

	local puppet = gameObject:create(_params)  --creates game object for puppet

	puppet.directional = true                  --all puppets are directional
	puppet.path = "content/game_objects/puppets/" --path for puppets

	lib_puppet.setParams(puppet, _params)      --sets puppet params
	lib_puppet.puppetFactory(puppet)           --adds functions to puppet

	puppet:loadTextures()

	lib_puppet:storeObject(puppet)
	print("puppet created with puppet id: " .. puppet.puppetID)
	return puppet
end

function lib_puppet:onFrame()
	for _, puppet in pairs(self.store) do
		puppet:onFrame()
	end
end

return lib_puppet
