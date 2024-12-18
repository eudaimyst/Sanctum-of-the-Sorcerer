
local vars = {}

local prevFrameTime = 0

vars.frame = {dt = 0, dts = 0, fps = 0, current = 0, count = 0} --holds all data related to current frame, dt = delta time

local current, dt, dts, fps, framecount  --recycled
local count, timer = 0, 0
local function onFrame(event)
    current = event.time
    count = count+1
    if timer > 1000 then
        framecount = count
        count = 0
        timer = 0
    end
    timer = timer + (current - prevFrameTime)
    dt = event.time - prevFrameTime --set delta time
    dts = dt / 1000 --set delta time in seconds
    fps = 1000 / dt
    --set to module
    vars.frame.dt = dt
    vars.frame.dts = dts
    vars.frame.fps = fps
    vars.frame.current = current
    vars.frame.count = framecount
    prevFrameTime = current --store current frame time to be accessed on next frame
    --print("frame time: "..dt.."ms, "..dts.."s, "..fps.."fps")
end

vars.screen = {width = display.contentWidth, height = display.contentHeight, halfWidth = display.contentWidth/2, halfHeight = display.contentHeight/2}

Runtime:addEventListener( "enterFrame", onFrame )

return vars