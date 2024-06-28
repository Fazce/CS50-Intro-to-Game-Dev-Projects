--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Daniel Nguyen

    Represents powerups that the player can pick up. Is used in
    the main program to boost the players performance either by
    allowing the user to break the bricks more faster via more balls 
    or in order to break a certain block
]]

Powerup = Class{}

function Powerup:init(skin)
    -- Setup variables for powerup boxes
    self.width = 16
    self.height = 16

    -- Variables to keep track of the powerup's velocity
    self.dx = 0
    self.dy = 50

    self.skin = skin

    self.x = math.random(VIRTUAL_WIDTH - self.width)
    self.y = -self.height

end

--[[ 
    Expects a colision target or a bounding box, which should only be the paddle
    and returns true if either are hit
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    -- Uses the same logic as the Ball class
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    return true
end

function Powerup:update(dt)
    self.x = self.x + self.dx * dt
    self.y = self.y + self.dy * dt

     -- allows the Powerup box to bounce off of the walls if it collides
     if self.x <= 0 then
        self.x = 0
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.x >= VIRTUAL_WIDTH - 8 then
        self.x = VIRTUAL_WIDTH - 8
        self.dx = -self.dx
        gSounds['wall-hit']:play()
    end

    if self.y <= 0 then
        self.y = 0
        self.dy = -self.dy
        gSounds['wall-hit']:play()
    end
end

function Powerup:render()
    -- Use gTexture for all of our sprites
    -- gFrames for powerups is used

    love.graphics.draw(gTextures['main'], gFrames['Powerup'][self.skin], self.x, self.y)
end