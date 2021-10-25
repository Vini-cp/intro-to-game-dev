--[[
    ScoreState Class
    Author: Colton Ogden
    cogden@cs50.harvard.edu

    A simple state used to display the player's score before they
    transition back into the play state. Transitioned to from the
    PlayState when they collide with a Pipe.
]]

ScoreState = Class{__includes = BaseState}

--[[
    When we enter the score state, we expect to receive the score
    from the play state so we know what to render to the State.
]]


--[[ 
    When a player enters the ScoreState, award them a “medal” 
    via an image displayed along with the score; this can be any image 
    or any type of medal you choose
]]

local goldmedal = love.graphics.newImage('goldmedal.png')
local wg = goldmedal:getWidth()*0.27

local silvermedal = love.graphics.newImage('silvermedal.png')
local ws = silvermedal:getWidth()*0.2

local bronzemedal = love.graphics.newImage('bronzemedal.png')
local wb = bronzemedal:getWidth()*0.2

function ScoreState:enter(params)
    self.score = params.score
    Scorevalue = 1
end

function ScoreState:update(dt)
    -- go back to play if enter is pressed
    if love.keyboard.wasPressed('enter') or love.keyboard.wasPressed('return') then
        gStateMachine:change('countdown')
        Scorevalue = 0
    end
end

function ScoreState:render()
    -- simply render the score to the middle of the screen
    love.graphics.setFont(flappyFont)
    love.graphics.printf('Oof! You lost!', 0, 64, VIRTUAL_WIDTH, 'center')

    love.graphics.setFont(mediumFont)
    love.graphics.printf('Score: ' .. tostring(self.score), 0, 100, VIRTUAL_WIDTH, 'center')

    if self.score >3 and self.score <= 5 then
        love.graphics.draw(bronzemedal, VIRTUAL_WIDTH/2-wb/2, 120, 0, 0.2, 0.2)
    elseif self.score >5 and self.score <=12 then
        love.graphics.draw(silvermedal, VIRTUAL_WIDTH/2-ws/2, 120, 0, 0.2, 0.2)
    elseif self.score > 12 then
        love.graphics.draw(goldmedal, VIRTUAL_WIDTH/2-wg/2, 120, 0, 0.27, 0.27)
    end

    love.graphics.printf('Press Enter to Play Again!', 0, 200, VIRTUAL_WIDTH, 'center')
end