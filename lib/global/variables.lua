local vars = {}
local prevFrameTime = 0

vars.frame = {dt = 0, dts = 0, fps = 0} --holds all data related to current frame, dt = delta time

local function onFrame(event)
    local dt = event.time - prevFrameTime --set delta time
    local dts = dt / 1000 --set delta time in seconds
    local fps = 1000 / dt
    vars.frame.dt, vars.frame.dts, vars.frame.fps = dt, dts, fps --set to module
    prevFrameTime = event.time --store current frame time to be accessed on next frame
end

Runtime:addEventListener( "enterFrame", onFrame )

return vars