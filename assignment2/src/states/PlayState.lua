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
    self.level = params.level

    self.allballs = {}
    table.insert(self.allballs, params.ball)

    self.recoverPoints = params.recoverPoints

    -- give ball random starting velocity
    self.allballs[1].dx = math.random(-200, 200)
    self.allballs[1].dy = math.random(-50, -60)

    -- choose random starting point position for the power up icon
    local maxy = 0
    local minx = VIRTUAL_WIDTH
    local maxx = 0

    maxy, minx, maxx = PowerUp:maxmin(self.bricks)

    -- initialize the power up with the limits choosen above
    power = PowerUp(math.random(minx,maxx), maxy, math.random(9,10))

    num_balls = 1
end

local max_score = 0

local timer = 0
local powertimer = 30


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

    timer = timer + dt

    if timer > powertimer then
       
        power:update(dt)

        if power:collides(self.paddle) then
            
            if power.type_number == 9 then
                num_balls = num_balls + 2

                self.ball2 = Ball()
                self.ball2:powertwo(self.paddle.x, self.paddle.y, self.paddle.width)
                table.insert(self.allballs,self.ball2)

                self.ball3 = Ball()
                self.ball3:powertwo(self.paddle.x, self.paddle.y, self.paddle.width)
                table.insert(self.allballs,self.ball3)

                powertimer = timer + 45

                maxy, minx, maxx = power:maxmin(self.bricks)
                -- initialize the power up with the limits choosen above
                power = PowerUp(math.random(minx,maxx), maxy, math.random(9,10))
            else
                for k, ball in pairs(self.allballs) do
                    self.allballs[k].skin = 7
                end

                powertimer = timer + 45

                maxy, minx, maxx = power:maxmin(self.bricks)
                -- initialize the power up with the limits choosen above
                power = PowerUp(math.random(minx,maxx), maxy, math.random(9,10))
            end
        end
        -- or self.allballs[k].y >= VIRTUAL_HEIGHT-5
        if power.y > VIRTUAL_HEIGHT  then
            powertimer = timer + 45

            maxy, minx, maxx = power:maxmin(self.bricks)        
            -- initialize the power up with the limits choosen above
            power = PowerUp(math.random(minx,maxx), maxy, math.random(9,10))

        end
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    
    for k, ball in pairs(self.allballs) do
        self.allballs[k]:update(dt)
    end

    for k, ball in pairs(self.allballs) do
        if self.allballs[k]:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            self.allballs[k].y = self.paddle.y - 8
            self.allballs[k].dy = -self.allballs[k].dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if self.allballs[k].x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                self.allballs[k].dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.allballs[k].x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif self.allballs[k].x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                self.allballs[k].dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.allballs[k].x))
            end

            gSounds['paddle-hit']:play()
        end
    end
    -- detect collision across all bricks with the ball
    for l, brick in pairs(self.bricks) do

        for k, ball in pairs(self.allballs) do
            -- only check collision if we're in play
            if brick.inPlay and self.allballs[k]:collides(brick) then
                
                if brick.color == 6 then
                    if brick.tier == 1 then
                        if ball.skin == 7 then
                            -- add to score
                            self.score = self.score + (brick.tier * 200 + brick.color * 25)

                            -- trigger the brick's hit function, which removes it from play
                            brick:hit()
                        end
                    else
                        -- add to score
                        self.score = self.score + (brick.tier * 200 + brick.color * 25)

                        -- trigger the brick's hit function, which removes it from play
                        brick:hit()
                    end
                else
                    -- add to score
                    self.score = self.score + (brick.tier * 200 + brick.color * 25)

                    brick:hit()
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)
                    
                    self.paddle.size = math.min(4, self.paddle.size + 1)
                    self.paddle.width = 32*self.paddle.size

                    -- multiply recover points by 2
                    self.recoverPoints = math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
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
                        ball = self.allballs[1],
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
                if self.allballs[k].x + 2 < brick.x and self.allballs[k].dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.allballs[k].dx = -self.allballs[k].dx
                    self.allballs[k].x = brick.x - 8
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif self.allballs[k].x + 6 > brick.x + brick.width and self.allballs[k].dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    self.allballs[k].dx = -self.allballs[k].dx
                    self.allballs[k].x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif self.allballs[k].y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    self.allballs[k].dy = -self.allballs[k].dy
                    self.allballs[k].y = brick.y - 8
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    self.allballs[k].dy = -self.allballs[k].dy
                    self.allballs[k].y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(self.allballs[k].dy) < 150 then
                    self.allballs[k].dy = self.allballs[k].dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end
    end

    for k, ball in pairs(self.allballs) do
        -- if ball goes below bounds, revert to serve state and decrease health
        if self.allballs[k].y >= VIRTUAL_HEIGHT then
            if num_balls > 1 then
                num_balls = num_balls - 1
                table.remove(self.allballs, k)
            else
                self.health = self.health - 1
                self.paddle.size = math.max(1, self.paddle.size - 1)
                self.paddle.width = 32*self.paddle.size
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
        end
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
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

    for k, ball in pairs(self.allballs) do
        self.allballs[k]:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    if timer > powertimer then
        power:render()
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