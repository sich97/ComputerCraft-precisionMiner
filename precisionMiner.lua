BedrockID = 7
DiamondID = 56
CoalID = 263
BranchSpacing = 2

-- If move and can't move then assume it is gravel/sand and dig with delay

CubeSizeBuffer = 2

GlobalLogger = {}

-- TODO: Have a list of wanted items instead of just one target ID
-- TODO: Does item ID's come as strings?

function RTB(globalLog)
    local rtbLog = {}
    -- TODO: Return to base algorithm

    -- Returning rtbLog so that the miner can resume mining at location before RTB
    return rtbLog
end

function RTM(rtbLog)
    -- TODO: Replay log in reverse to return to location before RTB
end

function Replay(log, amountOfSteps, replayMove, replayTurn, replayMine, invert)
end

function StripMine(branchDirection, branchLengths, targetID)
    for i=0,BranchSpacing do
        Refuel()
        if CheckReturnFuel() == true then
            if turtle.inspect() == targetID then
                MineCube(targetID)
            end
            if turtle.inspect() then
                Mine(GlobalLogger, "forward")
            end
            turtle.Move(GlobalLogger, "forward")
            turtle.Mine(GlobalLogger, "up")
        else
            local rtbLog = RTB(GlobalLogger)
            RTM(rtbLog)
        end
    end
    Turn(GlobalLogger, branchDirection)
    MineBranch(logger, branchLengths)

     -- Ensure correct post-conditions
     Replay(GlobalLogger, 1, false, true, false, true)
end

function MineBranch(logger, branchLengths, targetID)
    -- Mine branch
    -- TODO: Add branch marker in global logger
    for i=0,branchLengths do
        Refuel()
        if CheckReturnFuel(logger) == true then
            if turtle.inspect() == targetID then
                MineCube(targetID)
            end
            if turtle.inspect() then
                Mine(logger, "forward")
            end
            turtle.Move(logger, "forward")
            turtle.Mine(logger, "up")
        else
            local rtbLog = RTB(logger)
            RTM(rtbLog)
        end
    end

    -- Return to start of branch
    turtle.turnRight()
    turtle.turnRight()
    local returnToStartOfBranchLog = {}
    for i=0,branchLengths do
        turtle.Move(returnToStartOfBranchLog, "forward")
        -- TODO: Delete everything in global logger after and including the last branch marker
    end

    -- Ensure correct post-conditions
    turtle.turnRight()
    turtle.turnRight()
end


function CheckReturnFuel(logger)
    -- Checks the Movement logs to calculate required amount of fuel to return to origin
    -- returns true if current fuel level + fuel in inventory is 125% of the required amount, and false otherwise, triggering an immediate return to base before continuing

    local fuelInventoryCount = 0
    for i=1,16 do
        if turtle.getItemDetail(i).name == CoalID then
            fuelInventoryCount = fuelInventoryCount + turtle.getItemCount(i)
        end
    end
    
    local totalFuel = fuelInventoryCount + turtle.getFuelLevel()

    local requiredAmountOfFuel = 4 -- 2 turns to face backwards and another 2 to turn around one at base
    local amountOfMovesInLog = 0 -- TODO: Count the amount of moves in log
    requiredAmountOfFuel = requiredAmountOfFuel + amountOfMovesInLog
    requiredAmountOfFuel = requiredAmountOfFuel * 1.25

    if totalFuel < 1.25 then
        return false
    else
        return true
    end
end

function Refuel()
    turtle.select(1)
    while turtle.getItemCount(1) > 0 do
        local fuelDifference = turtle.getFuelLimit() - turtle.getFuelLevel()
        if fuelDifference > 0 then
            turtle.Refuel()
        end
    end
end

function ClearInventory(targetID)
    for i=1,16 do
        local itemDetails = turtle.getItemDetail(i)
        if itemDetails.name ~= targetID then
            if itemDetails.name ~= CoalID then
                turtle.select(i)
                turtle.drop()
            end
        end
    end
    
    if turtle.getItemCount(1) > 0 then
        if turtle.getItemDetail(1).name ~= CoalID then
            turtle.select(1)
            for i=3,16 do
                if turtle.getItemCount(i) == 0 then
                    turtle.transferTo(i)
                end
            end
        end
    end

    if turtle.getItemCount(2) > 0 then
        if turtle.getItemDetail(2).name ~= targetID then
            turtle.select(2)
            for i=3,16 do
                if turtle.getItemCount(i) == 0 then
                    turtle.transferTo(i)
                end
            end
        end
    end

    for i=3,16 do
        if turtle.getItemDetail(i).name == CoalID then
            turtle.select(i)
            local spaceLeft = turtle.getItemSpace(1)
            turtle.transferTo(1, spaceLeft)
            local extraCoalLeft = turtle.getItemCount(i)
            for i=0,extraCoalLeft do
                if turtle.getFuelLevel() < turtle.getFuelLimit() then
                    turtle.Refuel()
                end
            end
            turtle.drop()
        elseif turtle.getItemDetail(i).name == targetID then
            turtle.select(i)
            for b=2,16 do
                if b ~= i then
                    local spaceLeft = turtle.getItemSpace(b)
                    if turtle.getItemDetail().name == targetID then
                        turtle.transferTo(b,spaceLeft)
                    end
                end
            end
        else
            return false
        end
    end
    return true
end

function Move(logger, direction)
    -- TODO: Move the detection of and mining of diamonds/coal into this function (check for fuel first) (check all directions on every Move) (passing a parameter for wheter or not already looking for diamonds or coal to avoid regression - remember to update all Move calls afterwards)
    -- TODO: Add sand/gravel protection (the Move function can assume the path is clear - and if it isn't then it should be sand/gravel - use turtle.dig() instead of Mine())
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

function Turn(logger, direction)
    -- TODO: Add logging
    if direction == "right" then
        turtle.TurnRight()
    elseif direction == "left" then
        turtle.TurnLeft()
    end
end

function Mine(logger, direction)
    -- TODO: Add logging
    if direction == "forward" then
        turtle.dig()
    elseif direction == "up" then
        turtle.digUp()
    elseif direction == "down" then
        turtle.digDown()
    end
end

function MineCircle(logger, radius, knownClearRadius, targetID)
    local hasMinedTarget = false

    -- Go to the left-most boundry of the mining area
    Turn(logger, "left")
    for i=0,knownClearRadius do
        Move(logger, "forward")
    end
    Turn(logger, "right")
    
    -- Go to the forward-most boundry of the mining area
    for i=0,knownClearRadius do
        Move(logger, "forward")
    end

    -- Mine circle for each radius not yet clear
    for i=0,radius-knownClearRadius do

        -- Get into position
        if turtle.inspect() == targetID then
            hasMinedTarget = true
        end
        Mine(logger, "forward")
        Move(logger, "forward")
        Turn(logger, "right")

        -- Mine circle
        for i=0,3 do
            for i=0,radius*2+1 do
                if turtle.inspect() == targetID then
                    hasMinedTarget = true
                end
                Mine(logger, "forward")
                Move(logger, "forward")
            end
        end
    end
    -- TODO: Backtrack to centre (or maybe not backtrack but use a priori instead - just remember to achieve the correct pre-function conditions)
    return hasMinedTarget
end


function ExpandCube(existingAreaRadius, logger, targetID)
    local hasMinedTarget = false

    -- Move to the top y-level of the existing box
    for i=0,existingAreaRadius do
        Move(logger, "up")
    end

    -- Dig and Move one extra y level up
    if turtle.inspectUp() == targetID then
        hasMinedTarget = true
    end
    Mine(logger, "up")
    Move(logger, "up")

    -- Mine circle at top y-level
    hasMinedTarget = MineCircle(logger, existingAreaRadius+1, 0, targetID)

    -- For every y-level except bottom
    for i=0,existingAreaRadius+1 do
        Move(logger, "down")
        hasMinedTarget = MineCircle(logger, existingAreaRadius+1, existingAreaRadius, targetID)
    end

    -- Dig and Move one extra y level down
    if turtle.inspectUp() == targetID then
        hasMinedTarget = true
    end
    Mine(logger, "down")
    Move(logger, "down")

    -- Mine circle at bottom y-level
    hasMinedTarget = MineCircle(logger, existingAreaRadius+1, 0, targetID)


    -- Move back to centre of cube
    for i=0,existingAreaRadius+1 do
        Move(logger, "up")
    end

    return hasMinedTarget
end


function MineCube(targetID)
    local localLogger = {}
    local expansionsWithoutHittingTarget = 0
    local totalExpansions = 0
    while expansionsWithoutHittingTarget<CubeSizeBuffer do
        if ExpandCube(totalExpansions, localLogger, targetID) then
            expansionsWithoutHittingTarget = 0
        else
            expansionsWithoutHittingTarget = expansionsWithoutHittingTarget + 1
        end
    end
    -- TODO: Don't forget to fill the hole if enough coal available
end


--[[
function findBedrock(targetID)
    local hasFoundBedrock = false
    while hasFoundBedrock == false do
        if turtle.detectDown() then
            if turtle.inspectDown() == BedrockID then
                hasFoundBedrock = turtle
            elseif turtle.inspectDown() == targetID then
                MineDiamonds()
                Mine(GlobalLogger, "down")
                Move(GlobalLogger, "down")
            end
        else
            Move(GlobalLogger, "down")
        end
    end
    -- TODO: Don't remember in the parent function to Move up to the desired y-level for strip mining
end
--]]

function GoToDesiredLevel(desiredLevel, currentLevel, targetID)
    local direction = "down"
    local amountOfMoves = 0
    if desiredLevel<currentLevel then
        direction = "down"
        amountOfMoves = currentLevel - desiredLevel
    elseif desiredLevel>currentLevel then
        direction = "up"
        amountOfMoves = desiredLevel - currentLevel
    end

    for i=0,amountOfMoves do
        if direction == "down" then
            if turtle.detectDown() then
                if turtle.inspectDown() == BedrockID then
                    return false
                elseif turtle.inspectDown() == targetID then
                    MineCube(targetID)
                    Mine(GlobalLogger, direction)
                    Move(GlobalLogger, direction)
                end
            else
                Move(GlobalLogger, direction)
            end
        else
            if turtle.detectUp() then
                if turtle.inspectUp() == BedrockID then
                    return false
                elseif turtle.inspectUp() == targetID then
                    MineCube(targetID)
                    Mine(GlobalLogger, direction)
                    Move(GlobalLogger, direction)
                end
            else
                Move(GlobalLogger, direction)
            end
        end
    end
end