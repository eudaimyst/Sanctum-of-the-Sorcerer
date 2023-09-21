	-----------------------------------------------------------------------------------------
	--
	-- animation.lua
	--
	-----------------------------------------------------------------------------------------

	--common modules
	local gc = require("lib.global.constants")
	local gv = require("lib.global.variables")
	local util = require("lib.global.utilities")


	-- Define module
	local lib_animation = {	}

	local _anim --recycled
	
	function lib_animation.animUpdateLoop(object) --called on each game render frame
		_anim = object.currentAnim
		--update rect image on first render frame of loop
		if object.animFrame > _anim.frames then --if animation is changed and frame is greater than the number of frames in the animation, reset frame
			object.animFrame = 1
		end
		if (object.frameTimer == 0) then
			object:updateRectImage()
		end
		object.frameTimer = object.frameTimer + gv.frame.dts --add frame delta to timer

		if (object.attackWindingUp) then --windup frame has been reached
			object.windupTimer = object.windupTimer + gv.frame.dts --add frame delta to timer
			if (object.windupTimer >= object.currentAttack.windupTime) then --timer is greater than the animations rate
				object.attackWindingUp = false
				object.windupTimer = 0 --reset windup timer for next windup
				object.animFrame = _anim.windupEndFrame --jump to the final frame of the windup
				lib_animation.nextAnimFrame(object, _anim)
				return --return out of function to prevent nextAnimFrame from being called twice
			end
		end
		--print(self.state, self.frameTimer, self.currentAnim.rate)
		if object.currentAttack then
			if object.frameTimer >= (1 / object.attackSpeed) / _anim.frames then --timer is greater than the animations rate
				lib_animation.nextAnimFrame(object, _anim)
			end
		else
			if object.frameTimer >= 1 / _anim.rate then --timer is greater than the animations rate
				lib_animation.nextAnimFrame(object, _anim)
			end
		end
	end

	function lib_animation.nextAnimFrame(object, anim) --called to set next frame of animation	
		--print(self.name..".animFrame: " .. self.animFrame .. " / " .. anim.frames)

		if (object.state == "attack") then --attack sub state has finished and looping anim
			lib_animation.nextAttackAnimFrame(object, anim) --returns true if animation is complete
		end
		if (object.animFrame == anim.frames) then --animation is over
			if (anim.loop) then --animation is looping
				object.animFrame = 1 --reset the frame count for the next animation
			end
		else
			object.animFrame = object.animFrame + 1 --animation not over, increment anim frame
		end
		object.frameTimer = 0 --reset the frame timer for the next animFrame
	end

	function lib_animation.nextAttackAnimFrame(object, anim) --called from nextAnimFrame when in attack state
		if (object.currentAttack.windupGlow) then --windup position logic
			print("attack has windupglow")
			if (object.animFrame == 1) then
				print("calling start startWindupGlow")
				object:startWindupGlow() --starts windup glow
			end
			if (object.animFrame == anim.windupStartFrame) then --reached windup start frame
				object.attackWindingUp = true --sets attack winding up to true
			end
			if (object.animFrame == anim.windupEndFrame) then --reached attack frame
				if (object.attackWindingUp == true) then
					object.animFrame = anim.windupStartFrame --sets anim frame to windup start to loop
				end
			end
		end
		if (object.animFrame == anim.attackFrame) then
			print("firing attack")
			object.currentAttack:fire(object) --fires the attack
		end
		if (object.animFrame == anim.frames) then --post has finished
			object.currentAttack = nil --set current attack to nil, picked up by updateState on next loop
			if (object.attackCompletelistener) then
				object:attackCompletelistener() --calls complete listener for enemies
			end
		end
	end

	function lib_animation.beginAttackAnim(object, attack) --called from extended objects to start attack animations
		object.currentAttack = attack --set to nil once attack is complete, used to determin whether puppet is in attacking state
		print(object.id, "start attack anim for", object.currentAttack.name)
		object.animFrame = 1
		object.frameTimer = 0
		object.attackTimer = 0
	end

	function lib_animation.beginDeathAnim(object)
		print(object.id, "start death anim")
		object.animFrame = 1
		object.frameTimer = 0
	end

	return lib_animation