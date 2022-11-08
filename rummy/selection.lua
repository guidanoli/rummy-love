local selection = {}

function selection:getWhere (sel)
    local where
    for card in pairs(sel) do
        if where == nil then
            where = card.where
        elseif where ~= card.where then
            return
        end
    end
    return where
end

function selection:fromCard (card)
    return {
        [card] = true,
    }
end

return selection
