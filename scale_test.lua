local group = display.newGroup()

local inset

local contentText = "contentWidth: "..display.contentWidth.."\ncontentHeight: "..display.contentHeight
local viewableText = "viewableContentWidth: "..display.viewableContentWidth.."\nviewableContentHeight: "..display.viewableContentHeight
local contentWidthText = display.newText(contentText, display.contentCenterX, display.contentCenterY, native.systemFont, 20)
contentWidthText.x = contentWidthText.x - contentWidthText.width
contentWidthText:setFillColor(1, 0, 0)
local viewableWidthText = display.newText(viewableText, display.contentCenterX, display.contentCenterY, native.systemFont, 20)
viewableWidthText.x = viewableWidthText.x + viewableWidthText.width
viewableWidthText:setFillColor(0, 1, 0)

local offset = { tl = {x = 30, y = 30}, tr = {x = -30, y = 30}, bl = {x = 30, y = -30}, br = {x = -30, y = -30} }
local scale = { tl = {x = 0, y = 0}, tr = {x = 1, y = 0}, bl = {x = 0, y = 1}, br = {x = 1, y = 1} }
local corners = {"tl", "tr", "bl", "br"}
local circles = {}

circles.contentCircle = {}
circles.viewableCircle = {}
for _, k in ipairs(corners) do
	circles.contentCircle[k] = display.newCircle(group, 0, 0, 40)
	circles.contentCircle[k].x = display.contentWidth * scale[k].x + offset[k].x
	circles.contentCircle[k].y = display.contentHeight * scale[k].y + offset[k].y
	circles.contentCircle[k]:setFillColor(1, 0, 0)
	circles.viewableCircle[k] = display.newCircle(group, 0, 0, 20)
	circles.viewableCircle[k].x = display.viewableContentWidth * scale[k].x + offset[k].x
	circles.viewableCircle[k].y = display.viewableContentHeight * scale[k].y + offset[k].y
	circles.viewableCircle[k]:setFillColor(0, 1, 0)
end
local scaleOffsetW = (display.contentWidth - display.viewableContentWidth) / 2
local scaleOffsetH = (display.contentHeight - display.viewableContentHeight) / 2

local scaleTest = display.newText("scaleOffsetW: "..scaleOffsetW.."\nscaleOffsetH: "..scaleOffsetH, display.contentCenterX, display.contentCenterY + 100, native.systemFont, 20)
scaleTest:setFillColor(1, 1, 1)

for _, k in ipairs(corners) do
	circles.viewableCircle[k].x = (circles.viewableCircle[k].x + scaleOffsetW )
	circles.viewableCircle[k].y = (circles.viewableCircle[k].y + scaleOffsetH)
end
