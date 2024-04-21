-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite

class('Spike').extends(spr)

-- Init the class.
function Spike:init(x, y, rotated)
	local image = gfx.image.new("assets/images/spike-pd.png")

	-- Use the same image for both spikes.
	if rotated then
		image = image:rotatedImage(180)
	end

	-- Place the spike and turn off updates, this is static.
	self:setImage(image)
	self:setUpdatesEnabled(false)
	self:setCollideRect(0,0, self:getSize())
	self:setCenter(0, 0)
	self:moveTo(x, y)
	self:add()
end

