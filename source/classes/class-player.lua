-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite
local ftmr <const> = pd.frameTimer
local disp <const> = pd.display

class('Player').extends(spr)

-- Init the class.
function Player:init()
	-- PD version is 1.5x the size of the original.
	-- Adjust these values to change how the physics feel.
	self.scaleFactor = {
		x = 1.25,
		y = 1.4
	}

	self.acceleration = {
		x = 0,
		y = 0
	}
	self.velocity = {
		x = 0,
		y = 0
	}
	self.moving = false
	self.flipX = false
	self.frames = 4
	self.frameTimer = nil
	self.drawWidth = 12
	self.drawHeight = 15
	self.image = gfx.image.new("assets/images/dove-pd.png")

	self:resetImage()
	self:add()
	self:moveTo(200, 120)
	self:setUpdatesEnabled(false)

	-- Collisions aren't pixel perfect, so give some wiggle room.
	self:setCollideRect(1, 1, self.drawWidth - 2, self.drawHeight - 2)

	-- Feather particles.
	self.particles = ParticleImage(self.x, self.y)
	self.particles:setImage(gfx.image.new("assets/images/feather-pd.png"))
	self.particles:setMode(0)
	self.particles:setLifespan(80)
	self.particles:setSpeed(1, 2)
end

-- Reset the player image to the first frame.
function Player:resetImage(frame)
	if nil == frame then
		frame = 1
	end

	self:setImage(self:getImage(frame))
end

-- Get the player image at a specific frame.
function Player:getImage(frame)
	if nil == frame then
		frame = 1
	end

	local image = gfx.image.new(self.drawWidth, self.drawHeight)
	local flipped = self.flipX and gfx.kImageFlippedY or gfx.kImageUnflipped
	local rect = pd.geometry.rect.new(0, (frame - 1) * self.drawHeight, self.drawWidth, self.drawHeight)

	gfx.pushContext(image)
	self.image:draw(0, 0, flipped, rect)
	gfx.popContext()
	return image
end

-- The main player interaction, flap the wings!
function Player:flap()
	-- Leave if the player is not visible.
	if not self:isVisible() then
		return
	end

	-- This happens when the player first presses the A button.
	if not self.moving then
		self.moving = true
		self:setUpdatesEnabled(true)

		if game.audio ~= "SFX" then
			game.song:setVolume(0.8, 0.8, 1)
			game.song:setRate(1)
		end

		-- Set horizontal movement.
		self.velocity.y = -80 * self.scaleFactor.y;
		self.acceleration.x = 500 * self.scaleFactor.x;
	end

	-- Reset the frame timer.
	if self.frameTimer then
		self.frameTimer:remove()
	end

	-- Restart animation.
	self.frameTimer = ftmr.new(20, 1, self.frames + 0.99)

	self.frameTimer.updateCallback = function(thisTimer)
		self:resetImage(math.floor(thisTimer.value))
	end

	self.frameTimer.timerEndedCallback = function()
		self:resetImage(1)
	end

	-- Flap!
	game.flapSound:play()
	self.velocity.x = -280 * self.scaleFactor.x;
end

-- Kill the player.
function Player:kill()
	-- Reset vars.
	self.acceleration.x = 0;
	self.acceleration.y = 0;
	self.velocity.x = 0;
	self.velocity.y = 0;
	self.moving = false
	self.flipX = false
	self:resetImage()
	self:remove()
	self:setUpdatesEnabled(false)
	self:setVisible(false)

	-- Audio.
	if game.audio ~= "SFX" then
		game.song:setVolume(0.3, 0.3, 1)
		game.song:setRate(0.75)
	end

	-- Kill effects.
	game.killSound:play()
	game.killBoom:play()
	self:screenShake(35, 6)
	self:screenFlash(50)
	self:launchFeathers(self.x, self.y, 10)

	-- Reset game state.
	game.paddleLeft:resetPosition()
	game.paddleRight:resetPosition()
	game:updateHighScore()
	game:updateScore(0)
end

-- Revive the player.
function Player:revive()
	self:add()
	self:setVisible(true)
	self:moveTo(200, 120)
end

-- Launch feathers when the player dies.
function Player:launchFeathers(x, y, count)
	self.particles:moveTo(x, y)
	self.particles:add(count)

	local featherTimer = ftmr.new(80, function()
		self.particles:clearParticles()
	end)

	featherTimer.updateCallback = function()
		self.particles:update()
	end
end

-- Flash the screen when the player dies.
function Player:screenFlash(frames)
	local screenFlash = ftmr.new(frames, 0, 1)

	screenFlash.updateCallback = function(thisTimer)
		gfx.setColor(gfx.kColorWhite)
		gfx.setDitherPattern(thisTimer.value)
		gfx.fillRect(0, 0, 400, 240)
	end

	-- Bring the player back to life after the screen flash.
	screenFlash.timerEndedCallback = function()
		self:revive()
	end
end

-- Shake the screen when the player dies.
function Player:screenShake(shakeTime, shakeMagnitude)
	local shakeTimer = ftmr.new(shakeTime, shakeMagnitude, 0)
	-- Every frame when the timer is active, we shake the screen
	shakeTimer.updateCallback = function(thisTimer)
		local magnitude = math.floor(thisTimer.value)
		local shakeX = math.random(-magnitude, magnitude)
		local shakeY = math.random(-magnitude, magnitude)
		disp.setOffset(shakeX, shakeY)
	end
	-- Resetting the display offset at the end of the screen shake
	shakeTimer.timerEndedCallback = function()
		disp.setOffset(0, 0)
	end
end

-- Update loop for the player.
function Player:update()
	local dt = game.deltaTime

	-- Update velocity based on acceleration.
	self.velocity.x += self.acceleration.x * dt
	self.velocity.y += self.acceleration.y * dt

	-- Move the player based on current velocity.
	local _, _, collisions, numberOfCollisions = self:moveWithCollisions(
		self.x + self.velocity.x * dt,
		self.y + self.velocity.y * dt
	)

	-- If we're here, we've hit something.
	for i = 1, numberOfCollisions do
		if collisions[i].other:getTag() == 1 then
			game:updateScore()
			self.flipX = not self.flipX
			self.velocity.y = -self.velocity.y
			self:resetImage()

			-- Left or right bumper?
			local normal = collisions[i].normal
			collisions[i].other:flash()

			-- Update the bumper positions.
			if normal.y == 1 then
				game.paddleLeft:randomizePosition()
			else
				game.paddleRight:randomizePosition()
			end

			game.bounceSound:play()
		else
			self:kill()
		end
	end
end
