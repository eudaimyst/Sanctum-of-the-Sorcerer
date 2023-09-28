	-----------------------------------------------------------------------------------------
	--
	-- locale.lua
	--
	-- for accessing localised text, will load from lua files, for now just stores english
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")


	-- Define module
	local locale = { }

	local languages = { "en", "fr", "de", "es", "it", "pt", "ru", "zh" }
	local currentLanguage = "en"

	locale.en = {
		play = "Play game",
		mapgen = "Map generator",
		options = "Options",
		quit = "Quit",
		quitConfirm = "Are you sure you want to quit?",
		yes = "Yes",
		no = "No",
	}

	function locale.get(key)
		if locale[currentLanguage][key] == nil then
			print("ERROR: locale key "..key.." not found in "..currentLanguage)
			return "lang_err"
		end
		return locale[currentLanguage][key]
	end


	return locale