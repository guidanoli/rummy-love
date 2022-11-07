local constants = require "rummy.constants"
local utils = require "rummy.utils"
local Card = require "rummy.card"
local Meld = require "rummy.meld"

local Game = {}
Game.__index = Game
Game.__name = 'Game'

-- Create a new game where player has 9 cards and
-- all the other cards are in the stock.
-- Uses the current random seed to shuffle the cards.
function Game:new ()
    local game = {
        cards = self:_newCards(),
    }
    setmetatable(game, self)
    game:_dealCards()
    return game
end

function Game:_newCards ()
    local cards = {}
    for suit in pairs(constants.suits) do
        for rank in pairs(constants.ranks) do
            local card = Card:new{
                suit = suit,
                rank = rank,
                where = 'stock',
            }
            table.insert(cards, card)
        end
    end
    utils.shuffleInPlace(cards)
    local cardSet = {}
    for pos, card in ipairs(cards) do
        card.pos = pos
        cardSet[card] = true
    end
    return cardSet
end

function Game:_dealCards ()
    local cards = self:getCards()
    local hand = {}
    for i = 1, 9 do
        local card = table.remove(cards.stock)
        card.where = 'hand'
        hand[i] = card
    end
    self:sortMeld(hand)
end

function Game:iterCards ()
    return pairs(self.cards)
end

function Game:getCards ()
    local stock = {}
    local hand = {}
    local melds = {}
    for card in self:iterCards() do
        if card.where == 'stock' then
            stock[card.pos] = card
        elseif card.where == 'hand' then
            hand[card.pos] = card
        elseif card.where == 'meld' then
            local meld = melds[card.meld]
            if meld == nil then
                meld = {}
                melds[card.meld] = meld
            end
            meld[card.pos] = card
        else
            error("invalid where")
        end
    end
    return {
        stock = stock,
        hand = hand,
        melds = melds,
    }
end

function Game:sortCards ()
    local cards = self:getCards()
    self:sortMeld(cards.hand, 'hand')
    for _, meld in pairs(cards.meld) do
        self:sortMeld(meld, 'meld')
    end
end

local function compareCards (card1, card2)
    if card1.rank == card2.rank then
        return card1.suit < card2.suit
    else
        return card1.rank < card2.rank
    end
end

function Game:sortMeld (meld, where)
    table.sort(meld, compareCards)
    for pos, card in pairs(meld) do
        card.pos = pos
        if where ~= nil then
            card.where = where
        end
    end
end

function Game:isValid ()
    local cards = self:getCards()
    for _, meld in pairs(cards.melds) do
        if not Meld:isValid(meld) then
            return false
        end
    end
    return true
end

function Game:addCardToHand (card)
    local cards = self:getCards()
    table.insert(cards.hand, card)
    self:sortMeld(cards.hand, 'hand')
end

return Game
