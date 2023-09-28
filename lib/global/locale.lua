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

	function locale.get(key)
		if locale[currentLanguage][key] == nil then
			print("ERROR: locale key "..key.." not found in "..currentLanguage)
			return "lang_err"
		end
		return locale[currentLanguage][key]
	end

	locale.en = {
		play = "Play game",
		mapgen = "Map generator",
		gamePausedMenuTitle = "Game Paused",
		returnToGame = "Return to game",
		options = "Options",
		quit = "Quit game",
		quitConfirm = "Are you sure you want to quit?",
		leave = "Leave dungeon",
		leaveConfirm = "Return home?",
		yes = "Yes",
		no = "No",
	}
	-- French translations
	locale.fr = {
		play = "Jouer au jeu",
		mapgen = "Générateur de carte",
		options = "Options",
		quit = "Quitter",
		quitConfirm = "Êtes-vous sûr de vouloir quitter ?",
		yes = "Oui",
		no = "Non",
	}

	-- German translations
	locale.de = {
		play = "Spiel starten",
		mapgen = "Karten Generator",
		options = "Optionen",
		quit = "Beenden",
		quitConfirm = "Sind Sie sicher, dass Sie beenden möchten?",
		yes = "Ja",
		no = "Nein",
	}

	-- Spanish translations
	locale.es = {
		play = "Jugar juego",
		mapgen = "Generador de mapas",
		options = "Opciones",
		quit = "Salir",
		quitConfirm = "¿Estás seguro de que quieres salir?",
		yes = "Sí",
		no = "No",
	}
	-- Italian translations
	locale.it = {
		play = "Gioca",
		mapgen = "Generatore di mappe",
		options = "Opzioni",
		quit = "Esci",
		quitConfirm = "Sei sicuro di voler uscire?",
		yes = "Sì",
		no = "No",
	}

	-- Portuguese translations
	locale.pt = {
		play = "Jogar",
		mapgen = "Gerador de mapas",
		options = "Opções",
		quit = "Sair",
		quitConfirm = "Tem certeza de que deseja sair?",
		yes = "Sim",
		no = "Não",
	}

	-- Russian translations
	locale.ru = {
		play = "Играть",
		mapgen = "Генератор карт",
		options = "Настройки",
		quit = "Выйти",
		quitConfirm = "Вы уверены, что хотите выйти?",
		yes = "Да",
		no = "Нет",
	}

	-- Chinese translations
	locale.zh = {
		play = "开始游戏",
		mapgen = "地图生成器",
		options = "选项",
		quit = "退出",
		quitConfirm = "您确定要退出吗？",
		yes = "是",
		no = "否",
	}


	return locale