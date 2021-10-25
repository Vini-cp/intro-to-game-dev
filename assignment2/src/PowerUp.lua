--[[
    GD50
    Breakout Remake

    -- PowerUp Class --

    Represents a power up that can move left and right. Used in the main
    program to deflect the ball toward the bricks; if the ball passes
    the paddle, the player loses one heart. The Paddle can have a skin,
    which the player gets to choose upon starting the game.
]]

PowerUp = Class{}

--[[
    Our Paddle will initialize at the same spot every time, in the middle
    of the world horizontally, toward the bottom.
]]
function PowerUp:init(x, y, type)
    -- x is placed in the middle
    self.x = x -- VIRTUAL_WIDTH / 2 - 32

    -- y is placed a little above the bottom edge of the screen
    self.y = y -- VIRTUAL_HEIGHT - 32

    -- start us off with no velocity
    self.dy = 40

    -- dimensions
    self.width = 16
    self.height = 16

    -- power type
    self.type_number = type
end

--[[
    Expects an argument with a bounding box, be that a paddle or a brick,
    and returns true if the bounding boxes of this and the argument overlap.
]]
function PowerUp:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

function PowerUp:maxmin(bricks)
    maxy = 0
    minx = VIRTUAL_WIDTH
    maxx = 0

    for k, brick in pairs(bricks) do
        if bricks[k].y > maxy and bricks[k].inPlay then
            maxy = bricks[k].y
        end

        if bricks[k].x > maxx and bricks[k].inPlay then
            maxx = bricks[k].x
        end

        if bricks[k].x < minx and bricks[k].inPlay then
            minx = bricks[k].x
        end
    end

    return maxy, minx, maxx
end


function PowerUp:update(dt)

    self.y = self.y + self.dy * dt

end

--[[
    Render the paddle by drawing the main texture, passing in the quad
    that corresponds to the proper skin and size.
]]
function PowerUp:render()
    love.graphics.draw(gTextures['main'], gFrames['power'][self.type_number],
        self.x, self.y)
end