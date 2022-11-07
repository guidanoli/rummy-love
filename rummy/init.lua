local constants = require "rummy.constants"
local Game = require "rummy.game"
local Meld = require "rummy.meld"

local rummy = {}

-- -- {
-- --   cards : {
-- --     [key : integer] : {
-- --       suit : string = "spades" | "diamonds" | "clubs" | "hearts",
-- --       rank : number = 1 | 2 | ... | 13,
-- --       where : string = "stock" | "hand" | "game" | "limbo",
-- --       pos : integer?,
-- --       selected : boolean,
-- --       gpos : integer?,
-- --       x : integer,
-- --       y : integer,
-- --       w : integer,
-- --       h : integer,
-- --       animation : {
-- --         name : string = "smooth",
-- --         time : float?,
-- --         duration : float?,
-- --       }?,
-- --     },
-- --   },
-- -- }
-- 
-- -- {
-- --   [key : integer] : State
-- -- }
-- local history = {}

 
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

function rummy:cleanHistory ()
    self.history = {}
end

-- local function shuffleInPlace (t)
--     for i = #t, 2, -1 do
--         local j = math.random(i)
--         t[i], t[j] = t[j], t[i]
--     end
-- end
-- 
-- local function isTrueToAll (t, f, ...)
--     for _, v in pairs(t) do
--         if not f(v, ...) then
--             return false
--         end
--     end
--     return true
-- end

function rummy:isPositionInsideCard (x, y, w, h, card)
    return (x >= card.x) and
           (x <= (card.x + w)) and
           (y >= card.y) and
           (y <= (card.y + h))
end

-- local function getAnimatedCards ()
--     local animatedCards = {}
--     for _, card in pairs(state.cards) do
--         if card.animation then
--             table.insert(animatedCards, card)
--         end
--     end
--     return animatedCards
-- end
-- 
-- local function compareCards (card1, card2)
--     if card1.rank == card2.rank then
--         return card1.suit < card2.suit
--     else
--         return card1.rank < card2.rank
--     end
-- end
-- 
-- local function sortCards (cards)
--     table.sort(cards, compareCards)
-- end
-- 
-- local function setPlayerHand (hand)
--     sortCards(hand)
--     for pos, card in ipairs(hand) do
--         card.where = 'hand'
--         card.pos = pos
--     end
-- end
-- 
-- local function setGame (gpos, game)
--     sortCards(game)
--     for pos, card in ipairs(game) do
--         card.where = 'game'
--         card.gpos = gpos
--         card.pos = pos
--     end
-- end
-- 
-- local function setGames (games)
--     for gpos, game in pairs(games) do
--         setGame(gpos, game)
--     end
-- end
 
function rummy:updateCardRenderingOrder ()
    table.sort(self.cardRenderingOrder, function (card1, card2)
        return card1.pos < card2.pos
    end)
end

function rummy:getCardAtPosition (x, y)
    local topcard
    for card in self.game:iterCards() do
        local w, h = self:getCardImage(card):getDimensions()
        if self:isPositionInsideCard(x, y, w, h, card) then
            if topcard == nil or card.pos > topcard.pos then
                topcard = card
            end
        end
    end
    return topcard
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

function rummy:onCardLeftClick (card)
    if card.where == 'stock' then
        if self.game:isValid() then
            self.game:addCardToHand(card)
            self:moveCardSmoothly(card)
            self:cleanHistory()
            self.updatePending = true
        end
    else
        -- if not card.animation then
        --     saveState()
        --     card.selected = not card.selected
        -- end
    end
end

-- local function getWhere (cards)
--     local where
--     for _, card in ipairs(cards) do
--         if where == nil then
--             where = card.where
--         elseif where ~= card.where then
--             return
--         end
--     end
--     return where
-- end
-- 
-- local function checkNextTurn ()
--     if state.hasPlacedCard and areMeldsValid() then
--         self:cleanHistory()
--     end
-- end
-- 
-- local function moveCardToLimbo (card)
--     card.where = 'limbo'
--     card.pos = 0
--     card.gpos = nil
-- end
-- 
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
-- 
-- local function unselectCards (cards)
--     for _, card in pairs(cards) do
--         card.selected = false
--     end
-- end
-- 
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
--         local selection = getSelection()
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
-- 
-- local function moveCardsFromHandToTable (selection)
--     local n = #selection
--     if not state.hasPlacedCard and (n == 1 or n == 3) then
--         saveState()
--         state.hasPlacedCard = true
--         for _, card in ipairs(selection) do
--             removeCardFromHand(card)
--         end
--         addGameToTable(selection)
--         unselectCards(selection)
--         checkNextTurn()
--     end
-- end
-- 
-- local function onTableRightClick ()
--     local selection = getSelection()
--     local selectionOrigin = getWhere(selection)
--     if selectionOrigin == 'game' then
--         moveCardsFromGameToTable(selection)
--     elseif selectionOrigin == 'hand' then
--         moveCardsFromHandToTable(selection)
--     end
-- end

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

-- local function sortedPairs(t)
-- 	local keys = {}
-- 	for key in pairs(t) do table.insert(keys, key) end
-- 	table.sort(keys, function(a, b)
-- 		local ta, tb = type(a), type(b)
-- 		if ta == tb then
-- 			if ta == 'string' or ta == 'number' then
-- 				return a < b
-- 			elseif ta == 'boolean' then
-- 				return b and not a
-- 			else
-- 				return false -- Can't compare
-- 			end
-- 		else
-- 			return ta < tb -- Arbitrary type order
-- 		end
-- 	end)
-- 	local i = 0 -- iterator variable
-- 	local iter = function() -- iterator function
-- 		i = i + 1
-- 		local key = keys[i]
-- 		if key == nil then return nil
-- 		else return key, t[key]
-- 		end
-- 	end
-- 	return iter
-- end
-- 
-- local function pretty(obj)
-- 	local function _pretty(obj, pad, visited)
-- 		if type(obj) == "table" then
-- 			if next(obj) == nil then
-- 				return "{}"
-- 			elseif visited[obj] then
-- 				return "{...}"
-- 			else
-- 				local s = "{\n"
-- 				local newpad = pad .. "    "
-- 				visited[obj] = true
-- 				for key, value in sortedPairs(obj) do
-- 					s = s .. newpad .. "[" .. _pretty(key, newpad, visited) .. "] = " .. 
-- 					                          _pretty(value, newpad, visited) .. ",\n"
-- 				end
-- 				return s .. pad .. "}"
-- 			end
-- 		elseif type(obj) == "string" then
-- 			return string.format("%q", obj)
-- 		else
-- 			return tostring(obj)
-- 		end
-- 	end
-- 
-- 	return _pretty(obj, "", {})
-- end
-- 
-- local function debugState ()
--     print(pretty(state))
-- end

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

    self.history = {}

    math.randomseed(os.time())
    self.game = Game:new()

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
        -- local card = self:getCardAtPosition(x, y)
        -- if card == nil then
        --     onTableRightClick()
        -- else
        --     onCardRightClick(card)
        -- end
    end
end
 
function rummy:keypressed (key)
    -- self.updatePending = true
    -- if key == 'e' then
    --     saveState()
    --     unselectCards(state.cards)
    -- elseif key == 'u' then
    --     restorePrevState()
    -- elseif key == 'r' then
    --     updateCardPositions()
    -- elseif key == 'd' then
    --     debugState()
    -- end
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
