--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball = params.ball
    self.level = params.level
    self.paddleHitCount = 0
    self.aBalls = {}
    self.powerups = {}

    self.recoverPoints = 5000
    self.paddleIncrease = 250

    -- give ball random starting velocity
    self.ball.dx = math.random(-200, 200)
    self.ball.dy = math.random(-50, -60)
end

function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    self.ball:update(dt)

    -- Updating any additional balls from powerup
    for k, ball in pairs(self.aBalls) do
        ball:update(dt)
    end

    -- if the main/starting ball falls off the screen
    if self.ball.y >= VIRTUAL_HEIGHT then
        self.ball.y = VIRTUAL_HEIGHT
    end

    -- Removes any additional balls if they fall out of the screen
    for k, ball in pairs(self.aBalls) do
        if ball.y >= VIRTUAL_HEIGHT then
            table.remove(self.aBalls, k)
        end
    end

    -- Updates and handles collisions between ball and paddle
    if self.ball:collides(self.paddle) then
        self:ballPaddleCollision(self.ball)
    end

    -- Collision for additional balls. Should be the same as the main ball
    for k, ball in pairs(self.aBalls) do
        if ball:collides(self.paddle) then
           self:ballPaddleCollision(ball)
        end
    end

    -- Checks collision for the main ball and bricks
    self:ballBrickCollision(self.ball)
    
    -- Checks collisions for the additional balls
    for k, ball in pairs(self.aBalls) do
        self:ballBrickCollision(ball)
    end

    -- if ball goes below bounds, revert to serve state and decrease health
    if self.ball.y >= VIRTUAL_HEIGHT and #self.aBalls == 0 then
        self.health = self.health - 1
        self.paddle.size = math.max(1, self.paddle.size - 1)-- reduces the paddle size by 1 when health is lost
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end

     -- Allows the powerups to work as intended
     for k, powerup in pairs(self.powerups) do
        powerup:update(dt)
  
        if powerup:collides(self.paddle) then 
           if powerup.skin == 1 then 
              self:spawnAdditionalBalls()
           elseif powerup.skin == 2 then
              self.hasKeyPowerup = true
           end
  
           table.remove(self.powerups, k)
          end
      end
end

--[[
    Function that is called to for the powerup spawn. 
    This is called to when the ball hits the paddle five times
]]
function PlayState:spawnPowerup()
    local powerup = Powerup(math.random(1, 2))
    table.insert(self.powerups, powerup)
end

--[[
    Playstate function that is called to when the Ball powerup is obtained
    Spawns two additional balls that behave like the original is spawned
]]
function PlayState:spawnAdditionalBalls()
    local ballOne = Ball(math.random(7))
    ballOne.x = self.ball.x 
    ballOne.y = self.ball.y 
    ballOne.dx = math.random(-200, 200)
    ballOne.dy = math.random(-50, -60)

    local ballTwo = Ball(math.random(7))
    ballTwo.x = self.ball.x
    ballTwo.y = self.ball.y 
    ballTwo.dx = math.random(-200, 200)
    ballTwo.dy = math.random(-50, -60)

    table.insert(self.aBalls, ballOne)
    table.insert(self.aBalls, ballTwo)
end

--[[
    A playstate function that handles collisions with the ball
    This is actually the collision code originally given in the update function
    It is moved here to allow for additional balls to use this function without 
    needing to copy and paste and changing the code for them. The only change
    was changing self.ball in the collisions to ball
]]
function PlayState:ballBrickCollision(ball)
    -- detect collision across all bricks with the ball
    for k, brick in pairs(self.bricks) do
        -- only check collision if we're in play
        if brick.inPlay and ball:collides(brick) then
            -- If statement to handle the key block collision
            if brick.lockedBrick then
                if self.hasKeyPowerup then
                    brick.lockedBrick = false
                    self.hasKeyPowerup = false
                    self.score = self.score + (brick.tier * 200 + brick.color * 25) + 700
                    brick:hit()
                end
            else    
            -- add to score
            self.score = self.score + (brick.tier * 200 + brick.color * 25)

            -- trigger the brick's hit function, which removes it from play
            brick:hit()
            end

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end
            
            -- If enough points are earned, paddle sized is increased
            if self.score > self.paddleIncrease then
                -- No bigger than 4
                self.paddle.size = math.min(4, self.paddle.size + 1)

                self.paddleIncrease = self.paddleIncrease + math.min(10000, self.paddleIncrease * 2)
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if ball.x + 2 < brick.x and ball.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                ball.dx = -ball.dx
                ball.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif ball.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                ball.dy = -ball.dy
                ball.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(ball.dy) < 150 then
                ball.dy = ball.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
    end
end

--[[
    Function that handles the ball and paddle collision
    Is also just the code from update put into its own
    function with self.ball being replaced with ball
]]
function PlayState:ballPaddleCollision(ball)
     -- raise ball above paddle in case it goes below it, then reverse dy
        ball.y = self.paddle.y - 8
        ball.dy = -ball.dy

        --
        -- tweak angle of bounce based on where it hits the paddle
        --

        -- if we hit the paddle on its left side while moving left...
        if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            ball.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - ball.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            ball.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
        end

        -- Spawns powerups when the paddle hits a ball a certain amount of times
        self.paddleHitCount = self.paddleHitCount + 1

        if self.paddleHitCount >= 5 then
            self:spawnPowerup()
            self.paddleHitCount = 0
        end

        gSounds['paddle-hit']:play()
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    self.ball:render()

    renderScore(self.score)
    renderHealth(self.health)

    -- Renders in the powerups
    for k, powerup in pairs(self.powerups) do
        powerup:render()
    end

    -- Rendering in the additional balls from powerup
    for k, ball in pairs(self.aBalls) do
        ball:render()
    end

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end