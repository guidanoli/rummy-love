local utils = {}

function utils:shuffleInPlace (t)
    for i = #t, 2, -1 do
        local j = math.random(i)
        t[i], t[j] = t[j], t[i]
    end
end

function utils:orderOpenEnded (a, b)
    if a < b then
        return a + 1, b
    else
        return b, a - 1
    end
end

return utils
