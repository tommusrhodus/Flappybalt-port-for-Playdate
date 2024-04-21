-- Import core libraries.
import "CoreLibs/object"
import "CoreLibs/graphics"
import "CoreLibs/sprites"
import "CoreLibs/frameTimer"
import "CoreLibs/math"
import "CoreLibs/easing"

-- Assign shortcuts to the core libraries.
local pd <const> = playdate
local disp <const> = pd.display
local gfx <const> = pd.graphics
local spr <const> = gfx.sprite
local tmr <const> = pd.frameTimer

-- Import custom game libraries.
import "classes/class-game"
import "classes/class-player"
import "classes/class-paddle"
import "classes/class-spike"
import "classes/class-bumper"
import "classes/class-particles"

-- Setup the game.
game = Game()

-- Unflip the display when the device is locked.
function pd.deviceWillLock()
	disp.setFlipped(false, false)
end

-- Unflip the display when the game is paused.
function pd.gameWillPause()
	disp.setFlipped(false, false)
end

-- Unflip the display when the game is terminated.
function pd.gameWillTerminate()
	disp.setFlipped(false, false)
end

-- Unflip the display when the device is sleeping.
function pd.deviceWillSleep()
	disp.setFlipped(false, false)
end

-- Maybe flip the display when the device is unlocked.
function pd.deviceDidUnlock()
	disp.setFlipped(game.flipGame, false)
end

-- Maybe flip the display when the game is resumed.
function pd.gameWillResume()
	disp.setFlipped(game.flipGame, false)
end

-- Setup the display.
disp.setRefreshRate(50)
gfx.setBackgroundColor(gfx.kColorWhite)
gfx.clear()

-- Where the magic happens.
function pd.update()
	spr.update()
	tmr.updateTimers()
end
