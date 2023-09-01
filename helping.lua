	local physics = require("physics")

	local group = display.newGroup()
	local moveLeft, moveRight, player, player2
	local holdingLeft, holdingRight = false, false
	physics.start(true)
	physics.setGravity(0,0)
	physics.setDrawMode( "hybrid" )   -- Shows collision engine outlines only

	moveLeft = display.newRect(group,100,100,100,100)
	moveLeft:setFillColor(1,0,0)
	moveRight = display.newRect(group,200,100,100,100)
	moveRight:setFillColor(0,1,0)
	player = display.newRect(group,150,300,100,100)
	player:setFillColor(0,0,1)
	physics.addBody(player,"dynamic", { friction=0.5, bounce=0.3 } );
	player.isSensor = true
	player2 = display.newRect(group,300,300,100,100)
	player:setFillColor(0,0,1)
	physics.addBody(player2,"static", { friction=0.5, bounce=0.3 } );

	local function MovingLeft()
		player.x = player.x - 1
	end
	
	local function MovingRight()
		player.x = player.x + 1
	end
	
	local function ConfirmTouchLeft(event)
		if(event.phase == "moved" or event.phase == "began")then
			holdingLeft = true
			print("touched")
		end
		if(event.phase == "ended")then
			holdingLeft = false
			print("untouched")
		end
	end
	
	local function ConfirmTouchRight(event)
		if(event.phase == "moved" or event.phase == "began")then
			holdingRight = true
			print("touched")
		end
		if(event.phase == "ended")then
			holdingRight = false
			print("untouched")
		end
	end
	
	local function PressAndHold()
		if player.removePhysics then
			physics.removeBody(player)
			player.removePhysics = nil
		end
		if(holdingLeft == true) then
			MovingLeft()
		elseif(holdingRight == true) then
			MovingRight()
		end
	end

	local function onLocalCollision( self, event )
		--physics.removeBody(event.target)
		event.target.removePhysics = true
		print( event.target )        --the first object in the collision
		print( event.other )         --the second object in the collision
		print( event.selfElement )   --the element (number) of the first object which was hit in the collision
		print( event.otherElement )  --the element (number) of the second object which was hit in the collision
	end
	player.collision = onLocalCollision
	player:addEventListener( "collision" )
	
	-- Listeners
	Runtime:addEventListener("enterFrame", PressAndHold)
	moveLeft:addEventListener("touch", ConfirmTouchLeft)
	moveRight:addEventListener("touch", ConfirmTouchRight) 