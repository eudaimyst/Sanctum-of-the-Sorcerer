
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
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")
	local gameObject = require("lib.entity.game_object")

	-- Define module
	local lib_puppet = {}
    lib_puppet.store = {}

	local defaultAttackAnimation = {
		pre = { frames = 1, rate = 10, loop = true, duration = .5 },
		main = { frames = 1, rate = 10, loop = false, duration = .5 },
		post = { frames = 1, rate = 10, loop = false, duration = .5 },
	}

	local defaultAnimations = {
		idle = { frames = 1, rate = 3, loop = true, duration = .5 },
		walk = { frames = 4, rate = 6, loop = true, duration = .5 },
		sneak = { frames = 1, rate = 5, loop = true, duration = .5 },
		sprint = { frames = 1, rate = 10, loop = true, duration = .5 },
		death = {
			pre = { frames = 1, rate = 10, loop = false, duration = .5 },
			main = { frames = 1, rate = 3, loop = true, duration = .5 },
			post = { frames = 1, rate = 10, loop = false, duration = .5 }, },
		attack = {
			pre = { frames = 1, rate = 10, loop = true, duration = .5 },
			main = { frames = 1, rate = 10, loop = false, duration = .5 },
			post = { frames = 1, rate = 10, loop = false, duration = .5 },
		}
	}

    local defaultParams = { isPuppet = true,
		attackList = {}, spellList = {}, animations = {},
		isAttacking = false, isDead = false,
		state = "idle", currentFrame = 0, frameTimer = 0,
		width = 64, height = 128
	}

	function lib_puppet.setParams(puppet, _params)
		print("setting puppet params")

		if (not _params) then --if no params passed use default anaimations
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
			self.fName = self.path..self.name.."/"..self.state.."/"..self.facingDirection.image.."/"..self.currentFrame..".png"
		end

		function puppet:nextAnimFrame() --called to set next frame of animation
			self.currentFrame = self.currentFrame + 1
			if self.currentFrame > self.animations[self.state].frames - 1 then --reset current frame once reached anim's frame count
				self.currentFrame = 0
			end
            self:updateRectImage(self.currentFrame)
		end

		function puppet:loadTextures() --overrides gameObject function
			print("loading puppet textures")
			self.textures = {}
			for _, dir in pairs(gc.move) do --for each direction
				print("adding textures for direction: "..dir.image)
				self.textures[dir.image] = {}
				for animName, animData in pairs(self.animations) do --for each animation
					print("adding textures for animName: "..animName)
					self.textures[dir.image][animName] = {}
					if (animData.frames) then --if no sub animations (walk, spring, etc...)
						for i = 0, animData.frames - 1 do --zero indexed animation file names
							print("adding textures for frame: "..i)
							self.textures[dir.image][animName][i] = graphics.newTexture( { type="image", baseDir=system.ResourceDirectory, 
							filename=self.path..self.name.."/"..animName.."/"..dir.image.."/"..i..".png"
							} )
						end
						print("setting texture to ", self.facingDirection.image, self.state, self.currentFrame)
						self.texture = self.textures[self.facingDirection.image][self.state][self.currentFrame]
					else
						for subAnimName, subAnimData in pairs(animData) do --for each sub animation (pre, main, post, idles, special... etc)
							print("adding textures for subAnimName: "..subAnimName)
							self.textures[dir.image][animName][subAnimName] = {}
							for i = 0, subAnimData.frames - 1 do --zero indexed animation file names
								print("adding textures for frame: "..i)
								self.textures[dir.image][animName][subAnimName][i] = graphics.newTexture( {
									type="image", baseDir=system.ResourceDirectory, 
									filename=self.path..self.name.."/"..animName.."/"..subAnimName.."/"..dir.image.."/"..i..".png"
								} )
							end
						end
						print("setting texture to ", self.facingDirection.image, self.state, self.subAnim, self.currentFrame)
						self.texture = self.textures[self.facingDirection.image][self.state][self.subAnim][self.currentFrame]
					end
				end
			end
		end

		function puppet:updateAnimationFrames() --called on each game render frame
			if (self.isMoving) then --set the state to walk if moving (set in game object)
				self.state = "walk"
			else
				self.state = "idle"
				--check to make sure current frame is not past animation state frames
				if (self.currentFrame > self.animations[self.state].frames) then
					self.currentFrame = self.animations[self.state].frames  --minus one as frames are zero indexed
				end
			end
			if (self.animations[self.state].frames > 0) then --if theres more than one frame in the anim data
				self.frameTimer = self.frameTimer + gv.frame.dts --add frame delta to timer
			end
			if self.frameTimer >= 1 / self.animations[self.state].rate then --timer is greater than the animations rate
				self:nextAnimFrame()
				self.frameTimer = 0
			end
		end
	end

	function lib_puppet:create(_params) --creates the game object
		print("creating puppet")

		local puppet = gameObject:create(_params) --creates game object for puppet

		puppet.directional = true --all puppets are directional
		puppet.path = "content/game_objects/puppets/" --path for puppets

		lib_puppet.setParams(puppet, _params) --sets puppet params
		lib_puppet.puppetFactory(puppet) --adds functions to puppet

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