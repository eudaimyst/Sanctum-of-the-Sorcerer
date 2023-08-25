	-----------------------------------------------------------------------------------------
	--
	-- map/gen_functions.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local json = require("json")
	local pointsExpand = require("lib.map.genfuncs.points_expand")

	-- Define module
	local genfuncs = {run = false}

	local mapgen --stores mapgen module for use in genFuncs, set in startGen()

	local rogue, noise, wfc, mixed = {}, {}, {}, {}
	genfuncs.pointsExpand, genfuncs.rogue, genfuncs.noise, genfuncs.wfc, genfuncs.mixed = pointsExpand, rogue, noise, wfc, mixed
	--temp until other genfucs are made
	function genfuncs.rogue:init()
	end
	function genfuncs.noise:init()
	end
	function genfuncs.wfc:init()
	end
	function genfuncs.mixed:init()
	end

	function genfuncs.setColor(tiles, _color, id) --takes an array of tiles and sets their color
		--not sure why this is here, this call should be elsewhere
		--genfuncs. 
		local color = _color or "void"
		for i = 1, #tiles do
			if (color == "void") then
				tiles[i].rect.alpha =  0.3
			elseif (color == "red") then
				tiles[i].rect:setFillColor( 1, 0, 0 )
			elseif (color == "green") then
				tiles[i].rect:setFillColor( .5, 1, .3 )
			elseif (color == "yellow") then
				tiles[i].rect:setFillColor( 1, 1, 0 )
			elseif (color == "black") then
				tiles[i].rect:setFillColor( 0 )
			elseif (color == "grey") then
				tiles[i].rect:setFillColor( .3 )
			elseif (color == "white") then
				tiles[i].rect:setFillColor( 1 )
			elseif (color == "room") then
				tiles[i].rect:setFillColor(.8, .1, .1)
			elseif (color == "lines") then
				tiles[i].rect:setFillColor(1, .5, .5)
			end
		end
	end

	function genfuncs.setType(tiles, _typeName)
		--print(json.prettify(tiles))
		for i = 1, #tiles do
			tiles[i].typeName = _typeName
		end
	end

	return genfuncs