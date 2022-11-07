local constants = require "rummy.constants"

local Card = {}
Card.__index = Card

function Card:__tostring()
    local rankName = constants.rankNames[self.rank]
    return ("%s of %s"):format(rankName, self.suit)
end

local validators = {
    where = function (w)
        assert(constants.where[w] == true)
    end,
    pos = function (p)
        assert(type(p) == 'number')
        assert(p > 0)
    end,
    x = function (x)
        assert(type(x) == 'number')
        assert(x >= 0)
    end,
    y = function (y)
        assert(type(y) == 'number')
        assert(y >= 0)
    end,
    animation = function (a)
        assert(type(a) == 'table')
        assert(constants.animations[a.name] == true)
        assert(type(a.time) == 'number')
        assert(type(a.duration) == 'number')
    end,
    selected = function (s)
        assert(type(s) == 'boolean')
    end,
}

function Card:__newindex(key, value)
    local validator = validators[key]
    if validator == nil then
        error(("invalid key '%s'"):format(key))
    else
        validator(value)
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
    assert(constants.where[t.where] == true)
end

return Card
