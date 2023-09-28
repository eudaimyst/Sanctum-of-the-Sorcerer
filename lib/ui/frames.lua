	-----------------------------------------------------------------------------------------
	--
	-- frame.lua
	--
	-- loads imageSheet and creates a group containing images for a frame
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")


	local themes = { --sheet is created from this data, image filename is based off the key
		fantasy = {textureSize = 64, textureCorner = 14},
		fantasy_pressed = {textureSize = 64, textureCorner = 14}
	}

	local function makeSheetOptions(cornerSize, edgeSize)
		local framesData = {}
		local positions = { 0, cornerSize, cornerSize + edgeSize}
		local lengths = { cornerSize, edgeSize, cornerSize }
		local ix, iy = 1, 1
		for i = 1, 9 do
			framesData[i] = {x = positions[ix], y = positions[iy], width = lengths[ix], height = lengths[iy]}
			print("frame "..i..": "..framesData[i].x..", "..framesData[i].y..", "..framesData[i].width..", "..framesData[i].height)
			ix = ix + 1
			if ix == 4 then
				iy = iy + 1
				ix = 1
			end
		end
		local options = {
			frames = framesData
		}
		return options
	end

	for k, v in pairs(themes) do
		local path = "content/menu/frames/"..k..".png"
		print("making frame imageSheet options for "..k.." at path "..path.."\n---------------------------")
		local options = makeSheetOptions(v.textureCorner, v.textureSize - v.textureCorner * 2)
		v.sheet = graphics.newImageSheet( path, options )
	end

	-- Define module
	local frame_lib = {	}

	local _sheet, _ix, _iy, _xPos, _yPos, _xLength, _yLength --recycled
	function frame_lib:create(theme, borderSize, width, height)
		local halfWidth, halfHeight = width/2, height/2
		local frame = display.newGroup()
		--create rects for frame from the themes sheet
		_sheet, _ix, _iy = themes[theme].sheet, 1, 1
		_xPos = { 0, borderSize, width - borderSize}
		_yPos = { 0, borderSize, height - borderSize}
		_xLength = { borderSize, width - borderSize*2, borderSize }
		_yLength = { borderSize, height - borderSize*2, borderSize }
		for i = 1, 9 do
			local rect = display.newImageRect( _sheet, i, _xLength[_ix], _yLength[_iy] )
			util.zeroAnchors(rect)
			rect.x, rect.y = _xPos[_ix] - halfWidth, _yPos[_iy] - halfHeight
			frame:insert(rect)
			_ix = _ix + 1
			if _ix == 4 then
				_iy = _iy + 1
				_ix = 1
			end
		end
		return frame
	end

	return frame_lib