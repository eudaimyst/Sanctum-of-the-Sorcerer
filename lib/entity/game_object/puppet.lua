
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

	--common modules
	local gc = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local gameObject = require("lib.entity.game_object")

	-- Define module
	local lib_puppet = {}

	local defaultAttackAnimation = {
		pre = { frames = {}, rate = 10, loop = true, duration = .5 },
		main = { frames = {}, rate = 10, loop = false, duration = .5 },
		post = { frames = {}, rate = 10, loop = false, duration = .5 },
	}

	local defaultAnimations = {
		idle = { frames = {}, rate = 3, loop = true, duration = .5 },
		walk = { frames = {}, rate = 10, loop = true, duration = .5 },
		sneak = { frames = {}, rate = 5, loop = true, duration = .5 },
		sprint = { frames = {}, rate = 10, loop = true, duration = .5 },
		death = {
			pre = { frames = {}, rate = 10, loop = false, duration = .5 },
			main = { frames = {}, rate = 3, loop = true, duration = .5 },
			post = { frames = {}, rate = 10, loop = false, duration = .5 }, },
		attacks = { defaultAttackAnimation },
		spells = { defaultAttackAnimation },
	}

    local defaultParams = {
		attackList = {}, spellList = {}, animations = {},
		isAttacking = false, isCasting = false, isDead = false,
		state = "idle", currentFrame = 0,
	}

	function lib_puppet:create(_params) --creates the game object
		print("creating puppet")

		local puppet = gameObject:create(_params, true) --creates game object for puppet
		puppet.directional = true --all puppets are directional
		puppet.path = "content/game_objects/puppets/" --path for puppets
		puppet.width, puppet.height = 64, 128 --width and height of default puppet

		if (not _params) then --if no params passed use default anaimations
			defaultParams.animations = util.deepcopy(defaultAnimations)
		elseif (not _params.animations) then --params passed but no animations defined in params
			defaultParams.animations = util.deepcopy(defaultAnimations)
		end
		puppet:setParams(defaultParams, _params) --adds puppet params

 		---@diagnostic disable-next-line: duplicate-set-field (deliberately overriding updateFileName for puppet)
		function puppet:updateFileName()
            print("updating puppets file name")
			self.fName = self.path..self.name.."/"..self.state.."/"..self.facingDirection.image.."/"..self.currentFrame..".png"
		end
        puppet:updateFileName() --sets initial fName
        puppet:makeRect() --creates rect on object creation (remove when camera starts to call this)

        
        print("puppet created with id: " .. puppet.objID)
		return puppet
	end

	return lib_puppet