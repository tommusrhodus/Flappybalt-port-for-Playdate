-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite
local ftmr <const> = pd.frameTimer

class('Bumper').extends(spr)

-- Init the class.
function Bumper:init(x, y)
	self.width = 6
	self.height = 364
	self.velocity = 480

	self.normalImage = self:createImage()
	self.flashImage = self:createFlashImage()

	self:setImage(self.normalImage)
	self:setUpdatesEnabled(false)
	self:add()
	self:setCollideRect(0, 0, self.width, self.height)
	self:moveTo(x, y)
	self:setTag(1)
end

-- Create the standard image for the Bumper.
function Bumper:createImage()
	local image = gfx.image.new(self.height, self.width)

	gfx.pushContext(image)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(0, 0, self.height, self.width, 1)
	gfx.setColor(gfx.kColorBlack)
	gfx.drawRoundRect(0, 0, self.height, self.width, 1)
	gfx.popContext()
	return image
end

-- Create the flashing image for the Bumper.
function Bumper:createFlashImage()
	local image = gfx.image.new(self.height, self.width)

	gfx.pushContext(image)
	gfx.setColor(gfx.kColorWhite)
	gfx.fillRoundRect(0, 0, self.height, self.width, 1)
	gfx.popContext()
	return image
end

-- Change the bumper image.
function Bumper:flash()
	self:setImage(self.flashImage)

	-- Flash the bumper back to normal.
	local flashTimer = ftmr.new(8, function()
		self:setImage(self.normalImage)
	end)
end
