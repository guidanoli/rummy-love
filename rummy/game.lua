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
    utils:shuffleInPlace(cards)
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
    Meld:sort(hand)
    Meld:updatePos(hand)
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
    local hand = cards.hand
    table.insert(hand, card)
    card.where = 'hand'
    Meld:sort(hand)
    Meld:updatePos(hand)
end

function Game:getCardsBetween (card1, card2)
    local cardsInBetween = {}
    local cards = self:getCards()
    local pos1, pos2 = utils:orderOpenEnded(card1.pos, card2.pos)
    if card1.where == card2.where then
        if card1.where == 'meld' then
            if card1.meld == card2.meld then
                local meld = cards.melds[card1.meld]
                for pos = pos1, pos2 do
                    local card = meld[pos]
                    cardsInBetween[card] = true
                end
            end
        elseif card1.where == 'hand' then
            local hand = cards.hand
            for pos = pos1, pos2 do
                local card = hand[pos]
                cardsInBetween[card] = true
            end
        end
    end
    return cardsInBetween
end

function Game:getSelection ()
    local selection = {}
    for card in self:iterCards() do
        if card.selected then
            selection[card] = true
        end
    end
    return selection
end

function Game:newMeldFromSelection (sel, originMeld)
    local meld = Meld:fromSelection(sel)
    if Meld:isValid(meld) then
        Meld:subtract(originMeld, meld)
        Meld:updatePos(meld)
        local cards = self:getCards()
        local newMeldId = #cards.melds + 1
        for _, card in ipairs(meld) do
            card.where = 'meld'
            card.meld = newMeldId
        end
        return meld
    end
end

return Game
