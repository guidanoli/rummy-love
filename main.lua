-- Enums

local SUITS = {
    spades = true,
    diamonds = true,
    clubs = true,
    hearts = true,
}

local RANKS = {
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
}

-- Game Tables

-- {
--   cardFront : {
--     [suit : string] : {
--       [rank : integer] : Image,
--     },
--   },
--   cardBack : Image,
-- }
local images = {}

-- {
--   cards : {
--     [key : integer] : {
--       suit : string = "spades" | "diamonds" | "clubs" | "hearts",
--       rank : number = 1 | 2 | ... | 13,
--       where : string = "deck" | "hand" | "game" | "limbo",
--       pos : integer?,
--       selected : boolean,
--       gpos : integer?,
--       x : integer,
--       y : integer,
--       w : integer,
--       h : integer,
--       animation : {
--         name : string = "smooth",
--         time : float?,
--         duration : float?,
--       }?,
--     },
--   },
--   hasPlacedCard : boolean,
-- }
local state = {
    cards = {},
    hasPlacedCard = false,
}

-- {
--   [key : integer] : State
-- }
local history = {}

-- Game Constants
local margin = 10

-- Game Rendering
local updatePending = true

-- {
--   [index : integer] : integer,
-- }
local renderingOrder = {}

local function deepCopy (o)
    if type(o) == 'table' then
        local t = {}
        for k, v in pairs(o) do
            k = deepCopy(k)
            v = deepCopy(v)
            t[k] = v
        end
        return t
    else
        return o
    end
end

local function saveState ()
    local stateCopy = deepCopy(state)
    table.insert(history, stateCopy)
end

local function restorePrevState ()
    if #history > 0 then
        state = table.remove(history)
        updatePending = true
    else
        print("No previous state to restore")
    end
end

local function nextTurn ()
    history = {}
    state.hasPlacedCard = false
    print('New turn!')
end

local function shuffleInPlace (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

local function isTrueToAll (t, f, ...)
    for _, v in pairs(t) do
        if not f(v, ...) then
            return false
        end
    end
    return true
end

local function isPositionInsideCard (x, y, card)
    return (x >= card.x) and
           (x <= (card.x + card.w)) and
           (y >= card.y) and
           (y <= (card.y + card.h))
end

local function getDeck ()
    local deck = {}
    for _, card in pairs(state.cards) do
        if card.where == 'deck' then
            deck[card.pos] = card
        end
    end
    return deck
end

local function getPlayerHand ()
    local hand = {}
    for _, card in pairs(state.cards) do
        if card.where == 'hand' then
            hand[card.pos] = card
        end
    end
    return hand
end

local function getGame (gpos)
    local game = {}
    for _, card in pairs(state.cards) do
        if card.where == 'game' and card.gpos == gpos then
            game[card.pos] = card
        end
    end
    return game
end

local function getGames ()
    local games = {}
    for _, card in pairs(state.cards) do
        if card.where == 'game' then
            local game = games[card.gpos]
            if game == nil then
                game = {}
                games[card.gpos] = game
            end
            game[card.pos] = card
        end
    end
    return games
end

local function getAnimatedCards ()
    local animatedCards = {}
    for _, card in pairs(state.cards) do
        if card.animation then
            table.insert(animatedCards, card)
        end
    end
    return animatedCards
end

local function compareCards (card1, card2)
    if card1.rank == card2.rank then
        return card1.suit < card2.suit
    else
        return card1.rank < card2.rank
    end
end

local function sortCards (cards)
    table.sort(cards, compareCards)
end

local function getSelection ()
    local selection = {}
    for _, card in pairs(state.cards) do
        if card.selected then
            table.insert(selection, card)
        end
    end
    return selection
end

local function setPlayerHand (hand)
    sortCards(hand)
    for pos, card in ipairs(hand) do
        card.where = 'hand'
        card.pos = pos
    end
end

local function setGame (gpos, game)
    sortCards(game)
    for pos, card in ipairs(game) do
        card.where = 'game'
        card.gpos = gpos
        card.pos = pos
    end
end

local function setGames (games)
    for gpos, game in pairs(games) do
        setGame(gpos, game)
    end
end

local function compareCardPositionsByKey (key1, key2)
    return state.cards[key1].pos < state.cards[key2].pos
end

local function getRenderingOrder ()
    local ro = {}
    for key in pairs(state.cards) do
        table.insert(ro, key)
    end
    table.sort(ro, compareCardPositionsByKey)
    return ro
end

local function getCardAtPosition (x, y)
    local topcard
    for _, card in pairs(state.cards) do
        if isPositionInsideCard(x, y, card) then
            if topcard == nil or card.pos > topcard.pos then
                topcard = card
            end
        end
    end
    return topcard
end

local function isFromSuit (card, suit)
    return card.suit == suit
end

local function checkSameSuit (seq)
    for suit in pairs(SUITS) do
        if isTrueToAll(seq, isFromSuit, suit) then
            return true
        end
    end
    return false
end

local function checkSequential (seq)
    local prev
    for pos, card in ipairs(seq) do
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

local function checkAce (seq)
    local hasAce = false
    for pos, card in ipairs(seq) do
        if card.rank == 1 then
            if hasAce then
                return false
            else
                hasAce = true
            end
            if pos ~= 1 and pos ~= #seq then
                return false
            end
        end
    end
    return true
end

local function checkRun (seq)
    return #seq >= 3 and
           checkSameSuit(seq) and
           checkSequential(seq) and
           checkAce(seq)
end

local function isFromRank (card, rank)
    return card.rank == rank
end

local function checkSameRank (seq)
    for rank in pairs(RANKS) do
        if isTrueToAll(seq, isFromRank, rank) then
            return true
        end
    end
    return false
end

local function checkDifferentSuits (seq)
    local suitsFound = {}
    for _, card in ipairs(seq) do
        if suitsFound[card.suit] then
            return false
        else
            suitsFound[card.suit] = true
        end
    end
    return true
end

local function checkSet (seq)
    return #seq >= 3 and
           checkSameRank(seq) and
           checkDifferentSuits(seq)
end

local function checkMeld (seq)
    return checkRun(seq) or
           checkSet(seq)
end

function love.load ()
    love.window.setTitle("Rummy")
    love.window.setMode(1280, 720)

    -- Set random seed
    math.randomseed(os.time())

    -- Load images
    images.cardBack = love.graphics.newImage('images/back/red.png')
    images.cardFront = {}
    for suit in pairs(SUITS) do
        images.cardFront[suit] = {}
        for rank in pairs(RANKS) do
            local filename = 'images/' .. suit .. '/' .. rank .. '.png'
            images.cardFront[suit][rank] = love.graphics.newImage(filename)
        end
    end

    -- Shuffle deck of cards and deal 9 of them
    local width, height = images.cardBack:getDimensions()
    for suit in pairs(SUITS) do
        for rank in pairs(RANKS) do
            table.insert(state.cards, {
                suit = suit,
                rank = rank,
                where = "deck",
                selected = false,
                w = width,
                h = height,
            })
        end
    end
    shuffleInPlace(state.cards)
    for pos, card in ipairs(state.cards) do
        card.pos = pos
    end
    do
        local hand = {}
        local n = #state.cards
        for i = 1, 9 do
            hand[i] = state.cards[n - i + 1]
        end
        setPlayerHand(hand)
    end
end

function love.draw ()
    -- Draw each card
    local deckDrawn = false
    for _, key in ipairs(renderingOrder) do
        local card = state.cards[key]
        if card.where == 'deck' then
            if not deckDrawn then
                local img = images.cardBack
                love.graphics.draw(img, card.x, card.y)
                deckDrawn = true
            end
        else
            local img = images.cardFront[card.suit][card.rank]
            love.graphics.draw(img, card.x, card.y)
        end
    end
end

local function smoothPositionUpdate (card, duration)
    card.animation = {
        name = 'smooth',
        time = 0,
        duration = 1,
        xi = card.x,
        yi = card.y,
    }
end

local function addCardToHand (card)
    local hand = getPlayerHand()
    table.insert(hand, card)
    setPlayerHand(hand)
    smoothPositionUpdate(card)
end

local function checkGames ()
    for _, game in pairs(getGames()) do
        if not checkMeld(game) then
            return false
        end
    end
    return true
end

local function onCardLeftClick (card)
    if card.where == 'deck' then
        if checkGames() then
            addCardToHand(card)
            nextTurn()
        end
    else
        if not card.animation then
            saveState()
            card.selected = not card.selected
        end
    end
end

local function getWhere (cards)
    local where
    for _, card in ipairs(cards) do
        if where == nil then
            where = card.where
        elseif where ~= card.where then
            return
        end
    end
    return where
end

local function checkNextTurn ()
    if state.hasPlacedCard and checkGames() then
        nextTurn()
    end
end

local function moveCardToLimbo (card)
    card.where = 'limbo'
    card.pos = 0
    card.gpos = nil
end

local function removeEmptyGames ()
    local gpos = 1
    for _, game in pairs(getGames()) do
        if #game > 0 then
            setGame(gpos, game)
            gpos = gpos + 1
        end
    end
end

local function removeCardFromGame (card)
    local game = getGame(card.gpos)
    table.remove(game, card.pos)
    setGame(card.gpos, game)
    moveCardToLimbo(card)
end

local function removeCardFromHand (card)
    local hand = getPlayerHand()
    table.remove(hand, card.pos)
    setPlayerHand(hand)
    moveCardToLimbo(card)
end

local function addCardToGame (card, gpos)
    local game = getGame(gpos)
    table.insert(game, card)
    setGame(gpos, game)
    smoothPositionUpdate(card)
end

local function addGameToTable (game)
    local games = getGames()
    table.insert(games, game)
    setGames(games)
    for _, card in ipairs(game) do
        smoothPositionUpdate(card)
    end
end

local function unselectCards (cards)
    for _, card in pairs(cards) do
        card.selected = false
    end
end

local function moveCardsFromGameToGame (selection, destGamePos)
    saveState()
    for _, card in ipairs(selection) do
        removeCardFromGame(card)
        addCardToGame(card, destGamePos)
    end
    removeEmptyGames()
    unselectCards(selection)
    checkNextTurn()
end

local function moveCardsFromHandToGame (selection, destGamePos)
    local n = #selection
    if not state.hasPlacedCard and (n == 1 or n == 3) then
        saveState()
        state.hasPlacedCard = true
        for _, card in ipairs(selection) do
            removeCardFromHand(card)
            addCardToGame(card, destGamePos)
        end
        unselectCards(selection)
        checkNextTurn()
    end
end

local function onCardRightClick (card)
    if card.where == 'game' then
        local selection = getSelection()
        if #selection > 0 then
            local selectionOrigin = getWhere(selection)
            if selectionOrigin == 'game' then
                moveCardsFromGameToGame(selection, card.gpos)
            elseif selectionOrigin == 'hand' then
                moveCardsFromHandToGame(selection, card.gpos)
            else
                print("Selected cards don't have a common origin")
                for _, card in ipairs(selection) do
                    print('*', card.rank, 'of', card.suit, 'from', card.where)
                end
            end
        else
            print('No cards selected')
        end
    elseif card.where == 'hand' then
        print("Can't move cards to hand")
    elseif card.where == 'deck' then
        print("Can't move cards to deck")
    end
end

local function moveCardsFromGameToTable (selection)
    saveState()
    for _, card in ipairs(selection) do
        removeCardFromGame(card)
    end
    addGameToTable(selection)
    removeEmptyGames()
    unselectCards(selection)
    checkNextTurn()
end

local function moveCardsFromHandToTable (selection)
    local n = #selection
    if not state.hasPlacedCard and (n == 1 or n == 3) then
        saveState()
        state.hasPlacedCard = true
        for _, card in ipairs(selection) do
            removeCardFromHand(card)
        end
        addGameToTable(selection)
        unselectCards(selection)
        checkNextTurn()
    end
end

local function onTableRightClick ()
    local selection = getSelection()
    local selectionOrigin = getWhere(selection)
    if selectionOrigin == 'game' then
        moveCardsFromGameToTable(selection)
    elseif selectionOrigin == 'hand' then
        moveCardsFromHandToTable(selection)
    end
end

function love.mousepressed (x, y, button)
    updatePending = true
    if button == 1 then
        local card = getCardAtPosition(x, y)
        if card ~= nil then
            onCardLeftClick(card)
        end
    elseif button == 2 then
        local card = getCardAtPosition(x, y)
        if card == nil then
            onTableRightClick()
        else
            onCardRightClick(card)
        end
    end
end

local function updateCardPositions ()
    local img = images.cardBack
    local W, H = love.graphics.getDimensions()
    local w, h = img:getDimensions()
    local deckX = margin
    local deckY = margin
    local selectionLift = h / 4
    local xCardDist = w / 4
    local xGameDist = margin
    local yGameDist = margin + selectionLift

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

    do
        for _, card in ipairs(getDeck()) do
            update(card, deckX, deckY)
        end
    end

    do
        local x = deckX
        local y = deckY + h + margin + selectionLift
        for _, game in ipairs(getGames()) do
            for i = 1, 2 do
                for _, card in ipairs(game) do
                    update(card, x, y)
                    x = x + xCardDist
                end
                if x + (w - xCardDist) + margin > W then
                    x = deckX
                    y = y + h + yGameDist
                else
                    break
                end
            end
            x = x + (w - xCardDist) + xGameDist
        end
    end

    do
        local x = deckX
        local y = H - margin - h
        for _, card in ipairs(getPlayerHand()) do
            update(card, x, y)
            x = x + xCardDist
        end
    end
end

local function sortedPairs(t)
	local keys = {}
	for key in pairs(t) do table.insert(keys, key) end
	table.sort(keys, function(a, b)
		local ta, tb = type(a), type(b)
		if ta == tb then
			if ta == 'string' or ta == 'number' then
				return a < b
			elseif ta == 'boolean' then
				return b and not a
			else
				return false -- Can't compare
			end
		else
			return ta < tb -- Arbitrary type order
		end
	end)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		local key = keys[i]
		if key == nil then return nil
		else return key, t[key]
		end
	end
	return iter
end

local function pretty(obj)
	local function _pretty(obj, pad, visited)
		if type(obj) == "table" then
			if next(obj) == nil then
				return "{}"
			elseif visited[obj] then
				return "{...}"
			else
				local s = "{\n"
				local newpad = pad .. "    "
				visited[obj] = true
				for key, value in sortedPairs(obj) do
					s = s .. newpad .. "[" .. _pretty(key, newpad, visited) .. "] = " .. 
					                          _pretty(value, newpad, visited) .. ",\n"
				end
				return s .. pad .. "}"
			end
		elseif type(obj) == "string" then
			return string.format("%q", obj)
		else
			return tostring(obj)
		end
	end

	return _pretty(obj, "", {})
end

local function debugState ()
    print(pretty(state))
end

function love.keypressed (key)
    updatePending = true
    if key == 'e' then
        saveState()
        unselectCards(state.cards)
    elseif key == 'u' then
        restorePrevState()
    elseif key == 'r' then
        updateCardPositions()
    elseif key == 'd' then
        debugState()
    end
end

local function updateCardAnimation (card)
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

function love.update (dt)
    -- Update coordinates
    if updatePending then
        updateCardPositions()
        renderingOrder = getRenderingOrder()
        updatePending = false
    end
    -- Update animations
    for _, card in ipairs(getAnimatedCards()) do
        if card.animation.time + dt >= card.animation.duration then
            card.animation.time = card.animation.duration
            updateCardAnimation(card)
            card.animation = nil
        else
            card.animation.time = card.animation.time + dt
            updateCardAnimation(card)
        end
    end
end
