local Meld = {}

function Meld:hasSameSuit (meld)
    local suit
    for _, card in pairs(meld) do
        if suit == nil then
            suit = card.suit
        elseif suit ~= card.suit then
            return false
        end
    end
    return true
end

function Meld:isSequential (meld)
    local prev
    for _, card in ipairs(meld) do
        if prev ~= nil then
            if not ((prev.rank == 13 and card.rank == 1) or
                    (card.rank == prev.rank + 1)) then
                return false
            end
        end
        prev = card
    end
    return true
end

function Meld:hasNoMiddleAce (meld)
    for pos = 2, #meld - 1 do
        local card = meld[pos]
        if card.rank == 1 then
            return false
        end
    end
    return false
end

function Meld:hasNoDuplicateAce (meld)
    local n = 0
    for _, card in pairs(meld) do
        if card.rank == 1 then
            n = n + 1
        end
    end
    return n <= 1
end

function Meld:isRun (meld)
    return #meld >= 3 and
           self:hasSameSuit(meld) and
           self:isSequential(meld) and
           self:hasNoMiddleAce(meld) and
           self:hasNoDuplicateAce(meld)
end

function Meld:hasSameRank (meld)
    local rank
    for _, card in pairs(meld) do
        if rank == nil then
            rank = card.rank
        elseif rank ~= card.rank then
            return false
        end
    end
    return true
end

function Meld:hasDifferentSuits (meld)
    local hasSuit = {}
    for _, card in pairs(meld) do
        if hasSuit[card.suit] then
            return false
        else
            hasSuit[card.suit] = true
        end
    end
    return true
end

function Meld:isSet (meld)
    return #meld >= 3 and
           self:hasSameRank(meld) and
           self:hasDifferentSuits(meld)
end

function Meld:isValid (meld)
    return self:isRun(meld) or
           self:isSet(meld)
end

return Meld
