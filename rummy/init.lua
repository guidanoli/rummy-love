local inspect = require "inspect"
local constants = require "rummy.constants"
local utils = require "rummy.utils"
local selection = require "rummy.selection"
local Game = require "rummy.game"
local Meld = require "rummy.meld"

local rummy = {}

rummy.debug = os.getenv "DEBUG" ~= nil

-- local function deepCopy (o)
--     if type(o) == 'table' then
--         local t = {}
--         for k, v in pairs(o) do
--             k = deepCopy(k)
--             v = deepCopy(v)
--             t[k] = v
--         end
--         return t
--     else
--         return o
--     end
-- end
-- 
-- local function saveState ()
--     local stateCopy = deepCopy(state)
--     table.insert(history, stateCopy)
-- end
-- 
-- local function restorePrevState ()
--     if #history > 0 then
--         state = table.remove(history)
--         updatePending = true
--     else
--         print("No previous state to restore")
--     end
-- end

function rummy:clearHistory ()
    self.history = {}
end

function rummy:isPositionInsideCard (x, y, w, h, card)
    return (x >= card.x) and
           (x <= (card.x + w)) and
           (y >= card.y) and
           (y <= (card.y + h))
end

local function orderRenderingOrder (card1, card2)
    return card1.pos < card2.pos
end

function rummy:updateCardRenderingOrder ()
    table.sort(self.cardRenderingOrder, orderRenderingOrder)
end

function rummy:getCardAtPosition (x, y)
    for i = #self.cardRenderingOrder, 1, -1 do
        local card = self.cardRenderingOrder[i]
        local w, h = self:getCardImage(card):getDimensions()
        if self:isPositionInsideCard(x, y, w, h, card) then
            return card
        end
    end
end

function rummy:moveSelectionSmoothly (sel)
    for card in pairs(sel) do
        self:moveCardSmoothly(card)
    end
end

function rummy:moveCardSmoothly (card)
    card.animation = {
        name = 'smooth',
        time = 0,
        duration = 1,
        xi = card.x,
        yi = card.y,
    }
end

function rummy:isShiftPressed ()
    return self.pressedKeys.lshift or
           self.pressedKeys.rshift
end

function rummy:getSelectionFromShiftClick (card2)
    local card1 = self.lastSelectedCard
    if card1 ~= nil then
        return self.game:getCardsBetween(card1, card2)
    else
        return selection:fromCard(card2)
    end
end

function rummy:getSelectionFromClick (card)
    if self:isShiftPressed() then
        return self:getSelectionFromShiftClick(card)
    else
        return selection:fromCard(card)
    end
end

function rummy:onCardLeftClick (card)
    if card.where == 'stock' then
        if self.game:isValid() then
            self.game:addCardToHand(card)
            self:moveCardSmoothly(card)
            self:clearHistory()
            self.updatePending = true
        end
    else
        if not card.animation then
            local selection = self:getSelectionFromClick (card)
            for card in pairs(selection) do
                card.selected = not card.selected
            end
            self.lastSelectedCard = card
            self.updatePending = true
        end
    end
end

-- local function removeEmptyGames ()
--     local gpos = 1
--     for _, game in pairs(getGames()) do
--         if #game > 0 then
--             setGame(gpos, game)
--             gpos = gpos + 1
--         end
--     end
-- end
-- 
-- local function removeCardFromGame (card)
--     local game = getGame(card.gpos)
--     table.remove(game, card.pos)
--     setGame(card.gpos, game)
--     moveCardToLimbo(card)
-- end
-- 
-- local function removeCardFromHand (card)
--     local hand = getPlayerHand()
--     table.remove(hand, card.pos)
--     setPlayerHand(hand)
--     moveCardToLimbo(card)
-- end
-- 
-- local function addCardToGame (card, gpos)
--     local game = getGame(gpos)
--     table.insert(game, card)
--     setGame(gpos, game)
--     self:moveCardSmoothly(card)
-- end
-- 
-- local function addGameToTable (game)
--     local games = getGames()
--     table.insert(games, game)
--     setGames(games)
--     for _, card in ipairs(game) do
--         self:moveCardSmoothly(card)
--     end
-- end

function rummy:clearSelection ()
    for card in self.game:iterCards() do
        card.selected = false
    end
    self.lastSelectedCard = nil
end

-- local function moveCardsFromGameToGame (selection, destGamePos)
--     saveState()
--     for _, card in ipairs(selection) do
--         removeCardFromGame(card)
--         addCardToGame(card, destGamePos)
--     end
--     removeEmptyGames()
--     unselectCards(selection)
--     checkNextTurn()
-- end
-- 
-- local function moveCardsFromHandToGame (selection, destGamePos)
--     local n = #selection
--     if not state.hasPlacedCard and (n == 1 or n == 3) then
--         saveState()
--         state.hasPlacedCard = true
--         for _, card in ipairs(selection) do
--             removeCardFromHand(card)
--             addCardToGame(card, destGamePos)
--         end
--         unselectCards(selection)
--         checkNextTurn()
--     end
-- end
-- 
-- local function onCardRightClick (card)
--     if card.where == 'game' then
--         local selection = getSelectionFromClick()
--         if #selection > 0 then
--             local selectionOrigin = getWhere(selection)
--             if selectionOrigin == 'game' then
--                 moveCardsFromGameToGame(selection, card.gpos)
--             elseif selectionOrigin == 'hand' then
--                 moveCardsFromHandToGame(selection, card.gpos)
--             else
--                 print("Selected cards don't have a common origin")
--                 for _, card in ipairs(selection) do
--                     print('*', card.rank, 'of', card.suit, 'from', card.where)
--                 end
--             end
--         else
--             print('No cards selected')
--         end
--     elseif card.where == 'hand' then
--         print("Can't move cards to hand")
--     elseif card.where == 'stock' then
--         print("Can't move cards to stock")
--     end
-- end
-- 
-- local function moveCardsFromGameToTable (selection)
--     saveState()
--     for _, card in ipairs(selection) do
--         removeCardFromGame(card)
--     end
--     addGameToTable(selection)
--     removeEmptyGames()
--     unselectCards(selection)
--     checkNextTurn()
-- end

function rummy:moveCardsFromHandToTable (sel)
    local cards = self.game:getCards()
    if self.game:newMeldFromSelection(sel, cards.hand) then
        self:moveSelectionSmoothly(sel)
        self:clearSelection()
        self:clearHistory()
        self.updatePending = true
    end
end

function rummy:onTableRightClick (sel, where)
    if where == 'game' then
        -- self:moveCardsFromGameToTable(sel)
    elseif where == 'hand' then
        self:moveCardsFromHandToTable(sel)
    end
end

function rummy:getCardImageDimensions ()
    local anySuit = next(constants.suits)
    local anyRank = next(constants.ranks)
    local anyCardImage = self.images.card[anySuit][anyRank]
    return anyCardImage:getDimensions()
end

function rummy:updateCardPositions ()
    local W, H = love.graphics.getDimensions()
    local w, h = self:getCardImageDimensions()
    local margin = 10
    local stockX = margin
    local stockY = margin
    local selectionLift = h / 4
    local xCardDist = w / 4
    local xMeldDist = margin
    local yMeldDist = margin + selectionLift

    local function update (card, x, y)
        if card.selected then
            y = y - selectionLift
        end
        if card.animation then
            if card.animation.name == 'smooth' then
                card.animation.xf = x
                card.animation.yf = y
            end
        else
            card.x = x
            card.y = y
        end
    end

    local cards = self.game:getCards()

    for _, card in ipairs(cards.stock) do
        update(card, stockX, stockY)
    end

    do
        local x = stockX
        local y = stockY + self.images.stock:getHeight() + margin + selectionLift
        for _, meld in ipairs(cards.melds) do
            for i = 1, 2 do
                for _, card in ipairs(meld) do
                    update(card, x, y)
                    x = x + xCardDist
                end
                if x + (w - xCardDist) + margin > W then
                    x = stockX
                    y = y + h + yMeldDist
                else
                    break
                end
            end
            x = x + (w - xCardDist) + xMeldDist
        end
    end

    do
        local x = stockX
        local y = H - margin - h
        for _, card in ipairs(cards.hand) do
            update(card, x, y)
            x = x + xCardDist
        end
    end
end

function rummy:updateCardAnimations (dt)
    for card in self.game:iterCards() do
        if card.animation then
            if card.animation.time + dt >= card.animation.duration then
                card.animation.time = card.animation.duration
                self:updateCardAnimation(card)
                card.animation = nil
            else
                card.animation.time = card.animation.time + dt
                self:updateCardAnimation(card)
            end
        end
    end
end

function rummy:updateCardAnimation (card)
    if card.animation.name == 'smooth' then
        local xi = card.animation.xi
        local yi = card.animation.yi
        local xf = card.animation.xf
        local yf = card.animation.yf
        if xi and yi and xf and yf then
            local t = card.animation.time / card.animation.duration
            local p = (math.sin((t - 0.5) * math.pi) + 1) / 2
            card.x = xi * (1 - p) + xf * p
            card.y = yi * (1 - p) + yf * p
        end
    end
end

function rummy:getCardImage (card)
    if card.where == 'stock' then
        return self.images.stock
    else
        return self.images.card[card.suit][card.rank]
    end
end

function rummy:load ()
    love.window.setMode(1280, 720)
    love.window.setTitle("Rummy")

    math.randomseed(os.time())
    self.game = Game:new()

    self.history = {}

    self.images = {}
    self.images.stock = love.graphics.newImage('images/vstock/red.png')
    self.images.card = {}
    for suit in pairs(constants.suits) do
        self.images.card[suit] = {}
        local folder = 'images/' .. suit
        for rank in pairs(constants.ranks) do
            local filename = folder .. '/' .. rank .. '.png'
            self.images.card[suit][rank] = love.graphics.newImage(filename)
        end
    end

    self.updatePending = true

    self.cardRenderingOrder = {}
    for card in self.game:iterCards() do
        table.insert(self.cardRenderingOrder, card)
    end

    self.pressedKeys = {}
end
 
function rummy:draw ()
    local drawnStock = false
    for _, card in ipairs(self.cardRenderingOrder) do
        if not (card.where == 'stock' and drawnStock) then
            local img = self:getCardImage(card)
            love.graphics.draw(img, card.x, card.y)
            if card.where == 'stock' then
                drawnStock = true
            end
        end
    end
end

function rummy:mousepressed (x, y, button)
    if button == 1 then
        local card = self:getCardAtPosition(x, y)
        if card ~= nil then
            self:onCardLeftClick(card)
        end
    elseif button == 2 then
        local card = self:getCardAtPosition(x, y)
        local sel = self.game:getSelection()
        local where = selection:getWhere(sel)
        if where ~= nil then
            if card == nil then
                self:onTableRightClick(sel, where)
            else
                -- onCardRightClick(card)
            end
        end
    end
end
 
function rummy:keypressed (key)
    self.pressedKeys[key] = true
    if key == 'c' then
        self:clearSelection()
        self.updatePending = true
    elseif key == 'i' then
        if self.debug then
            print(inspect(self.game))
        end
    end
end

function rummy:keyreleased (key)
    self.pressedKeys[key] = nil
end

function rummy:update (dt)
    if self.updatePending then
        self:updateCardPositions()
        self:updateCardRenderingOrder()
        self.updatePending = false
    end

    self:updateCardAnimations(dt)
end

return rummy
