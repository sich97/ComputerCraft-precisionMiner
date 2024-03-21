bedrockID = 7
diamondID = 56

CubeSizeBuffer = 2

globalLogger = {}

function move(logger, direction)
    -- TODO: Move the detection of and mining of diamonds/coal into this function (check all directions on every move) (passing a parameter for wheter or not already looking for diamonds or coal to avoid regression - remember to update all move calls afterwards)
    -- TODO: Add sand/gravel protection (the move function can assume the path is clear - and if it isn't then it should be sand/gravel)
    -- TODO: Add logging
    if direction == "up" then
        turtle.up()
    elseif direction == "forward" then
        turtle.forward()
    elseif direction == "back" then
        turtle.back()
    elseif direction == "down" then
        turtle.down()
    end
end

function turn(logger, direction)
    -- TODO: Add logging
    if direction == "right" then
        turtle.turnRight()
    elseif direction == "left" then
        turtle.turnLeft()
    end
end

function mine(logger, direction)
    -- TODO: Add logging
    -- TODO: Add sand/gravel protection (by pausing a little bit after mining up or forward)
    -- TODO: Handle refueling
    if direction == "forward" then
        turtle.dig()
    elseif direction == "up" then
        turtle.digUp()
    elseif direction == "down" then
        turtle.digDown()
    end
end

function mineCircle(logger, radius, knownClearRadius, targetID)
    local hasMinedTarget = false

    -- Go to the left-most boundry of the mining area
    turn(localLogger, "left")
    for i=0,knownClearRadius do
        move(localLogger, "forward")
    end
    turn(localLogger, "right")
    
    -- Go to the forward-most boundry of the mining area
    for i=0,knownClearRadius do
        move(localLogger, "forward")
    end

    -- Mine circle for each radius not yet clear
    for i=0,radius-knownClearRadius do

        -- Get into position
        if turtle.inspect() == targetID then
            hasMinedTarget = true
        end
        mine(localLogger, "forward")
        move(localLogger, "forward")
        turn(localLogger, "right")

        -- Mine circle
        for i=0,3 do
            for i=0,radius*2+1 do
                if turtle.inspect() == targetID then
                    hasMinedTarget = true
                end
                mine(localLogger, "forward")
                move(localLogger, "forward")
            end
        end
    end
    -- TODO: Backtrack to centre (or maybe not backtrack but use a priori instead - just remember to achieve the correct pre-function conditions)
    return hasMinedTarget
end


function expandCube(existingAreaRadius, localLogger, targetID)
    local hasMinedTarget = false

    -- Move to the top y-level of the existing box
    for i=0,existingAreaRadius do
        move(localLogger, "up")
    end

    -- Dig and move one extra y level up
    if turtle.inspectUp() == targetID then
        hasMinedTarget = true
    end
    mine(localLogger, "up")
    move(localLogger, "up")

    -- Mine circle at top y-level
    hasMinedTarget = mineCircle(localLogger, existingAreaRadius+1, 0, targetID)

    -- For every y-level except bottom
    for i=0,existingAreaRadius+1 do
        move(localLogger, "down")
        hasMinedTarget = mineCircle(localLogger, existingAreaRadius+1, existingAreaRadius, targetID)
    end

    -- Dig and move one extra y level down
    if turtle.inspectUp() == targetID then
        hasMinedTarget = true
    end
    mine(localLogger, "down")
    move(localLogger, "down")

    -- Mine circle at bottom y-level
    hasMinedTarget = mineCircle(localLogger, existingAreaRadius+1, 0, targetID)


    -- Move back to centre of cube
    for i=0,existingAreaRadius+1 do
        move(localLogger, "up")

    return hasMinedTarget
end


function mineCube(targetID)
    localLogger = {}
    local expansionsWithoutHittingTarget = 0
    local totalExpansions = 0
    while expansionsWithoutHittingTarget<CubeSizeBuffer do
        if expandCube(totalExpansions, localLogger, targetID) then
            expansionsWithoutHittingTarget = 0
        else
            expansionsWithoutHittingTarget = expansionsWithoutHittingTarget + 1
        end
    end
    -- TODO: Don't forget to fill the hole if enough coal available
end


function findBedrock(targetID)
    local hasFoundBedrock = false
    while hasFoundBedrock == false do
        if turtle.detectDown() then
            if turtle.inspectDown() == bedrockID then
                hasFoundBedrock = turtle
            elseif turtle.inspectDown() == targetID then
                mineDiamonds()
                mine(globalLogger, "down")
                move(globalLogger, "down")
            end
        else
            move(globalLogger, "down")
        end
    end
    -- TODO: Don't remember in the parent function to move up to the desirec y-level for strip mining
end