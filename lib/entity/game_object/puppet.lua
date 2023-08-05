
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

	local defaultAnimations = {
		idle = { frames = {}, rate = 3, loop = true, duration = .5 },
		walk = { frames = {}, rate = 10, loop = true, duration = .5 },
		sneak = { frames = {}, rate = 5, loop = true, duration = .5 },
		sprint = { frames = {}, rate = 10, loop = true, duration = .5 },
		attack = {
			pre = { frames = {}, rate = 10, loop = true, duration = .5 },
			main = { frames = {}, rate = 10, loop = false, duration = .5 },
			post = { frames = {}, rate = 10, loop = false, duration = .5 }, },
		cast = {
			pre = { frames = {}, rate = 10, loop = true, duration = .5 },
			main = { frames = {}, rate = 10, loop = false, duration = .5 },
			post = { frames = {}, rate = 10, loop = false, duration = .5 }, },
		death = {
			pre = { frames = {}, rate = 10, loop = false, duration = .5 },
			main = { frames = {}, rate = 3, loop = true, duration = .5 },
			post = { frames = {}, rate = 10, loop = false, duration = .5 }, },
	}

    local defaultParams = {
		attackList = {}, spellList = {}, animations = {},
		isAttacking = false, isCasting = false, isDead = false,
		facingDirection = gc.move.down.angle,
	}

	function lib_puppet:create(_params) --creates the game object
		print("creating puppet")
		local puppet = gameObject:create()

		if (not _params) then
			defaultParams.animations = util.deepcopy(defaultAnimations)
		elseif (not _params.animations) then
			defaultParams.animations = util.deepcopy(defaultAnimations)
		end
		puppet:setParams(defaultParams, _params) --sets the params of the object to the passed params or the default params
        
		return puppet
	end

	return lib_puppet