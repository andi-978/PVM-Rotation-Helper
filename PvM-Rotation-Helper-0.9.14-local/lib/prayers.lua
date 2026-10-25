-- Passive user-authored prayer reminders only. No prayer state is observed and
-- no game input, switching, recommendation or progression is performed here.
-- Named Struct/Param access: https://developer.runescape.com/rs/game/config/structtype.html
local source = require("data/prayers")
local U = require("lib/util")
local P = {items = {}, byID = {}, books = {"All prayer books", "Standard prayers", "Ancient curses"}}
local positions = {en = 1, de = 2, fr = 3, ["pt-BR"] = 4}

local function param(api, id, name)
    local ok, value = pcall(function()
        local prayer, key = api.Struct[id], api.Param[name]
        if prayer and prayer.configName == id and key and prayer:HasParam(key) then return prayer:GetParamValue(key) end
    end)
    return ok and value or nil
end

function P.lookup(id) return type(id) == "string" and P.byID[id] or nil end

function P.resolve(id, api)
    if not P.lookup(id) then return nil end
    local icon = param(api, id, "COMBATV2_ABILITY_ICON")
    return U.integer(icon, 1, 2147483647) and icon or nil
end

function P.name(id, language)
    local item = P.lookup(type(id) == "table" and id.id or id)
    return item and item.names[positions[language or "en"]] or "?"
end

function P.refresh(api)
    P.items, P.byID = {}, {}
    local available = 0
    for _, original in ipairs(source) do
        local item = U.copy(original)
        P.items[#P.items + 1], P.byID[item.id] = item, item
        local level = param(api, item.id, "COMBATV2_ABILITY_LEVEL_REQ")
        if U.integer(level, 1, 120) then item.level = level end
        item.available = P.resolve(item.id, api) ~= nil
        if item.available then available = available + 1 end
    end
    return available
end

function P.search(query, book, api, language)
    local found = {}
    if book and book ~= "All prayer books" and book ~= "Standard prayers" and book ~= "Ancient curses" then return found end
    query = U.fold(query or "")
    for _, item in ipairs(P.items) do
        if (api and P.resolve(item.id, api) ~= nil or not api and item.available)
            and (not book or book == "All prayer books" or item.book == book)
            and U.fold(P.name(item.id, language)):find(query, 1, true) then found[#found + 1] = item end
    end
    table.sort(found, function(first, second)
        if first.level ~= second.level then return first.level < second.level end
        if first.book ~= second.book then return first.book < second.book end
        local a, b = P.name(first.id, language), P.name(second.id, language)
        return a == b and first.id < second.id or a < b
    end)
    return found
end

P.refresh({})
return P
