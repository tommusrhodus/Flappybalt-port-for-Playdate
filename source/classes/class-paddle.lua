-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite
local ftmr <const> = pd.frameTimer
local pdmath <const> = pd.math
local ease <const> = pd.easingFunctions

class('Paddle').extends(spr)

-- Init the class.
function Paddle:init(x, y, rotated)
	local image = gfx.image.new("assets/images/paddle-pd.png")

	-- Use the same image for both spikes.
	if rotated then
		image = image:rotatedImage(180)
	end

	self:setImage(image)

	-- Store the initial position of this paddle.
	self.initialPosition = {
		x = x,
		y = y
	}
	self.positionLimits = {
		math.floor(18 + (self.width / 2)),
		math.floor(382 - (self.width / 2))
	}
	self.moveTimer = nil

	-- Add this to the scene.
	self:setCollideRect(0, 0, self:getSize())
	self:moveTo(x, y)
	self:add()
	self:setUpdatesEnabled(false)
end

-- Move the paddle to a new position.
function Paddle:lerpMove(x1, y1, x2, y2, duration)
	if self.moveTimer then
		self.moveTimer:remove()
	end

	self.moveTimer = ftmr.new(duration, 0, 1, ease.inOutCubic)

	self.moveTimer.updateCallback = function(timer)
		local x = pdmath.lerp(x1, x2, timer.value)
		local y = pdmath.lerp(y1, y2, timer.value)
		self:moveTo(x, y)

		if not game.paddleMove:isPlaying() then
			game.paddleMove:play()
		end
	end

	self.moveTimer.timerEndedCallback = function()
		if self.x % 2 == 0 then
			self:moveTo(self.x - 1, self.y)
		end
	end
end

-- Reset the paddle to its initial position.
function Paddle:resetPosition()
	self:lerpMove(self.x, self.y, self.initialPosition.x, self.initialPosition.y, 40)
end

-- Randomize the paddle's position.
function Paddle:randomizePosition()
	local x = math.random(self.positionLimits[1], self.positionLimits[2])
	self:lerpMove(self.x, self.y, x, self.initialPosition.y, 40)
end
