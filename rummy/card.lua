local constants = require "rummy.constants"

local Card = {}
Card.__index = Card

function Card:__tostring()
    local rankName = constants.rankNames[self.rank]
    return ("%s of %s"):format(rankName, self.suit)
end

function Card:__newindex(key, value)
    if key == 'x' or key == 'y' then
        self:_validateCoordinate(value)
    elseif key == 'where' then
        self:_validateWhere(value)
    elseif key == 'pos' then
        self:_validatePosition(value)
    elseif key == 'animation' then
        self:_validateAnimation(value)
    else
        error(("invalid key '%s'"):format(key))
    end
    rawset(self, key, value)
end

function Card:new(t)
    self:_validateArguments(t)
    setmetatable(t, self)
    return t
end

function Card:_validateArguments(t)
    assert(constants.ranks[t.rank] == true)
    assert(constants.suits[t.suit] == true)
    self:_validateWhere(t.where)
end

function Card:_validateWhere(where)
    assert(constants.where[where] == true)
end

function Card:_validatePosition(pos)
    assert(type(pos) == 'number')
    assert(pos > 0)
end

function Card:_validateCoordinate(coord)
    assert(type(coord) == 'number')
    assert(coord >= 0)
end

function Card:_validateAnimation(animation)
    assert(type(animation) == 'table')
    assert(constants.animations[animation.name] == true)
    assert(type(animation.time) == 'number')
    assert(type(animation.duration) == 'number')
end

return Card
