local constants = require "rummy.constants"
local utils = require "rummy.utils"
local selection = require "rummy.selection"
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

function Game:getCardSet ()
    return self.cards
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
            local meld = melds[card.meldpos]
            if meld == nil then
                meld = {}
                melds[card.meldpos] = meld
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
            if card1.meldpos == card2.meldpos then
                local meld = cards.melds[card1.meldpos]
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
    local sel = {}
    for card in self:iterCards() do
        if card.selected then
            sel[card] = true
        end
    end
    return sel
end

-- Subtract meld2 from meld1
-- Moves meld2 to its own meld
-- Ensure meld1 and meld2 are valid melds
-- Returns updated meld1
-- Arguments:
--   meld1 : Meld
--   meld2 : Meld
-- Returns:
--   [0] : Meld
function Game:subtract (meld1, meld2)
    local newmeld1 = Meld:subtract(meld1, meld2)
    Meld:updatePos(meld2)
    local cards = self:getCards()
    local meldpos = #cards.melds + 1
    for _, card in ipairs(meld2) do
        card.where = 'meld'
        card.meldpos = meldpos
    end
    return newmeld1
end

function Game:updateMeldPos ()
    local cards = self:getCards()
    local sortedPos = utils:sortedKeys(cards.melds)
    for newPos, oldPos in ipairs(sortedPos) do
        local meld = cards.melds[oldPos]
        for _, card in pairs(meld) do
            card.meldpos = newPos
        end
    end
end

function Game:clone ()
    return utils:deepCopy(self)
end

-- Get the common origin of a selection
-- If there is one, returns the meld too
-- Otherwise, returns nil
-- Arguments:
--   sel : Selection
-- Returns:
--   [0] : string?
--   [1] : Meld?
function Game:getWhere (sel)
    local where = selection:getWhere(sel)
    local cards = self:getCards()
    local meld
    if where == 'meld' then
        local card = next(sel)
        meld = cards.melds[card.meldpos]
    elseif where == 'hand' then
        meld = cards.hand
    elseif where == 'stock' then
        meld = cards.stock
    end
    return where, meld
end

return Game
