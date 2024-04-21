-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite
local data <const> = pd.datastore
local snd <const> = pd.sound

class('Game').extends(spr)

-- Init the class.
function Game:init()
	self.deltaTime = 0

	-- Save data.
	self.totalScore = "Press Any Button to Start"
	self.highScore = 0
	self.audio = "All"
	self.flipGame = false
	self:load()

	pd.display.setFlipped(self.flipGame, false)

	-- Game dimensions.
	self.gameBorder = 5

	-- Typography.
	self.font = gfx.font.new("assets/fonts/Nontendo-Bold")
	self.largeFont = gfx.font.new("assets/fonts/Nontendo-Bold-2x")

	-- Background.
	self.bg = gfx.image.new("assets/images/bg-pd-dither.png")

	-- Audio.
	self.song = snd.fileplayer.new("assets/audio/davidKBD-nebula-run.mp3")
	self.song:setRate(0.5)
	self.song:setVolume(0.3)
	self.song:play(0)

	self.killSound = snd.sampleplayer.new("assets/audio/hit.wav")
	self.killSound:setVolume(0.7)

	self.killBoom = snd.sampleplayer.new("assets/audio/boom.wav")
	self.killBoom:setVolume(0.4)

	self.flapSound = snd.sampleplayer.new("assets/audio/flap3.wav")
	self.flapSound:setVolume(0.7)

	self.bounceSound = snd.sampleplayer.new("assets/audio/click.wav")
	self.bounceSound:setVolume(0.2)

	self.paddleMove = snd.sampleplayer.new("assets/audio/paddle-click.wav")

	self:adjustAudioLevels()

	-- Start game update loop.
	self:setImage(self:getBackground())
	self:setCenter(0, 0)
	self:add()

	-- Add system menu options.
	self:setupMenuItems()

	-- Add moving paddles.
	self.paddleLeft = Paddle(500, 230 - self.gameBorder, false)
	self.paddleRight = Paddle(500, 10 + self.gameBorder, true)

	-- Add boundary spikes.
	self.spikeTop = Spike(0, 0, true)
	self.spikeBottom = Spike(384, 0, false)

	-- Add side bumpers.
	self.bumperLeft = Bumper(200, 236)
	self.bumperRight = Bumper(200, 4)

	-- Create the player.
	self.player = Player()
end
-- Adjust the audio levels.
function Game:adjustAudioLevels(value)
	if nil == value then
		value = self.audio
	end

	if "All" == value then
		self.song:setVolume(0.3)
		self.killSound:setVolume(0.7)
		self.killBoom:setVolume(0.4)
		self.flapSound:setVolume(0.7)
		self.bounceSound:setVolume(0.2)
		self.paddleMove:setVolume(1)
	elseif "Music" == value then
		self.killSound:setVolume(0)
		self.killBoom:setVolume(0)
		self.flapSound:setVolume(0)
		self.bounceSound:setVolume(0)
		self.paddleMove:setVolume(0)
	elseif "SFX" == value then
		self.song:setVolume(0)
		self.song:pause()
		self.killSound:setVolume(0.7)
		self.killBoom:setVolume(0.4)
		self.flapSound:setVolume(0.7)
		self.bounceSound:setVolume(0.2)
		self.paddleMove:setVolume(1)
	end
end

-- Extend the system menu with custom game items.
function Game:setupMenuItems()
	local menu = pd.getSystemMenu()

	-- Option to flip the way the game is shown.
	menu:addCheckmarkMenuItem("Flip Game", self.flipGame, function(value)
		self.flipGame = value
		self:save()
		pd.display.setFlipped(self.flipGame, false)
		self:resetImage()
	end)

	-- Audio options.
	menu:addOptionsMenuItem("Audio", { "All", "Music", "SFX" }, self.audio, function(value)
		self.audio = value
		self:adjustAudioLevels(value)
		self:save()
	end)

	-- Option to reset the high score.
	menu:addOptionsMenuItem("Del Scores", { "No", "Yes" }, "No", function(value)
		if "Yes" == value then
			self.highScore = 0
			self:save()
			self:resetImage()
		end
	end)
end

-- Update the high score.
function Game:updateHighScore()
	if self.totalScore > self.highScore then
		self.highScore = self.totalScore
		self:save()
	end
end

-- Load the game data.
function Game:load()
	local gameData = data.read("flappybalt")

	-- Save defaults and re-load if no data is found.
	if nil == gameData then
		self:save()
		self:load()
		return
	end

	-- Update vars.
	self.highScore = gameData.highScore
	self.audio = gameData.audio
	self.flipGame = gameData.flipGame
end

function Game:save()
	data.write(
		{
			highScore = self.highScore,
			audio = self.audio,
			flipGame = self.flipGame
		},
		"flappybalt"
	)
end

-- Reset the game background image.
function Game:resetImage()
	self:setImage(self:getBackground())
end

-- Get the game background image.
function Game:getBackground()
	local image = gfx.image.new(400, 240)

	gfx.pushContext(image)
	self.bg:draw(0, 0)

	-- Create and draw the current score.
	local font = "number" == type(self.totalScore) and self.largeFont or self.font
	local totalScore = gfx.imageWithText(self.totalScore .. "", 240, 28, nil, 0, nil, gfx.kTextAlignCenter, font)
	local highScore = gfx.imageWithText(self.highScore .. "", 240, 28, nil, 0, nil, gfx.kTextAlignCenter, self.largeFont)

	if self.flipGame then
		totalScore = totalScore:scaledImage(-1, 1)
		highScore = highScore:scaledImage(-1, 1)
	end

	gfx.setImageDrawMode("fillWhite")
	totalScore:drawRotated(320, 120, -90)

	if self.highScore > 0 then
		gfx.setImageDrawMode("fillBlack")
		highScore:drawRotated(70, 120, -90)
	end

	gfx.setImageDrawMode("copy")

	gfx.popContext()
	return image
end

-- Update the current score.
function Game:updateScore(value)
	if "string" == type(self.totalScore) then
		self.totalScore = 0
	end

	-- Update the score and redraw the background.
	if value then
		self.totalScore = value
	else
		self.totalScore += 1
	end
	self:resetImage()
end

-- The game loop.
function Game:update()
	-- Store frame delta time.
	self.deltaTime = pd.getElapsedTime()
	pd.resetElapsedTime()

	-- Game Controls.
	if
		pd.buttonJustPressed("A") or
		pd.buttonJustPressed("B") or
		pd.buttonJustPressed("up") or
		pd.buttonJustPressed("down") or
		pd.buttonJustPressed("left") or
		pd.buttonJustPressed("right")
	then
		self.player:flap()
	end
end
