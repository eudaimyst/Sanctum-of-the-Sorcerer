
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
	local g = require("lib.global.constants")
	local util = require("lib.global.utilities")
	local gameObject = require("lib.entity.game_object")

	-- Define module
	local puppet = {}

	function puppet:create() --dont really need to do much at this point, will be expanded later
		print("creating puppet")
		local p = gameObject:create()
		return p
	end

	return puppet