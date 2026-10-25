-- Passive spell reminders only. This module never casts, advances a rotation,
-- observes game input, reads an inventory, writes storage or discovers arbitrary
-- Structs. Artwork comes from the current named Jagex Struct's params;
-- display/search names use only the selected plugin language's static facts.
-- API: https://developer.runescape.com/rs/game/config/structtype.html
-- Facts/provenance: data/spells.lua and the own spell-fact snapshot.
local source = {}
for _, item in ipairs(require("data/spells")) do source[#source + 1] = item end
local U = require("lib/util")
local I18n = require("lib/i18n")
-- The eleven named incantations are already evidenced in our own beta ability
-- export. Keep their old ability identities readable, but insert passive spell
-- reminders. Unknown levels stay unset until a readable current Param exists.
local incantations, suffixes = {}, {}
for _, suffix in ipairs({"TELEPORT_UNDERWORLD_HUB", "LESSER_BONE_SHIELD", "GREATER_BONE_SHIELD", "LIFE_TRANSFER",
    "THREADS_OF_FATE", "INVOKE_DEATH", "DARKNESS", "SPLIT_SOUL", "INVOKE_LORD_OF_BONES", "TELEPORT_UNGAEL", "INVOKE_ARISEN_FLESH"}) do
    suffixes["COMBATV2_ABILITY_NECROMANCY_" .. suffix] = true
end
for _, item in ipairs(require("data/abilities")) do
    if suffixes[item.id] then
        incantations[item.id] = true
        source[#source + 1] = {id = item.id, name = item.name, book = "Necromancy", spellType = "Incantation"}
    end
end
local S = { items = {}, byID = {}, books = { "All spellbooks", "Standard", "Ancient", "Lunar", "Necromancy" },
    types = { "All types", "Combat", "Skilling", "Incantation" } }

local function param(api, id, name)
    local ok, value = pcall(function()
        local spell = api.Struct[id]
        local key = api.Param[name]
        if spell and (spell.configName == nil or spell.configName == id) and key and spell:HasParam(key) then return spell:GetParamValue(key) end
    end)
    if ok then return value end
end

function S.isIncantation(id) return incantations[id] == true end

function S.lookup(id) return type(id) == "string" and S.byID[id] or nil end

function S.resolve(id, api)
    if not S.lookup(id) then return nil end
    local value = param(api, id, "COMBATV2_ABILITY_ICON")
    return U.integer(value, 1, 2147483647) and value or nil
end

function S.name(id, language)
    local item = S.lookup(type(id) == "table" and id.id or id)
    if not item then return "?" end
    return I18n.name("spells", item.id, language)
end

function S.refresh(api)
    S.items, S.byID = {}, {}
    local available = 0
    for _, original in ipairs(source) do
        local item = U.copy(original)
        local level = param(api, item.id, "COMBATV2_ABILITY_LEVEL_REQ")
        if U.integer(level, 1, 120) then item.level = level end
        S.items[#S.items + 1], S.byID[item.id] = item, item
        item.available = S.resolve(item.id, api) ~= nil
        if item.available then available = available + 1 end
    end
    S.available = available
    return available
end

-- Selectable results require an actually readable positive current icon.
-- With no api argument, use the last explicit refresh's availability snapshot;
-- callers can pass api to recheck each candidate without mutating identities.
-- The Spells picker excludes incantations already offered under Necromancy;
-- ordinary searches/lookups retain them for saved references and other callers.
function S.search(query, book, spellType, api, language, excludeIncantations)
    local found = {}
    if book and book ~= "All spellbooks" and book ~= "Standard" and book ~= "Ancient" and book ~= "Lunar" and book ~= "Necromancy" then return found end
    query = U.fold(query or "")
    for _, item in ipairs(S.items) do
        if (not excludeIncantations or not S.isIncantation(item.id))
            and (api and S.resolve(item.id, api) ~= nil or not api and item.available)
            and (not book or book == "All spellbooks" or item.book == "All" and book ~= "Necromancy" or item.book == book)
            and (not spellType or spellType == "All types" or item.spellType == spellType)
            and I18n.matches("spells", item.id, language, query) then
            found[#found + 1] = item
        end
    end
    table.sort(found, function(first, second)
        if (first.level or 121) ~= (second.level or 121) then return (first.level or 121) < (second.level or 121) end
        if first.book ~= second.book then return first.book < second.book end
        return first.name == second.name and first.id < second.id or first.name < second.name
    end)
    return found
end

function S.availableTypes(book, api, excludeIncantations)
    local choices = { "All types" }
    for _, kind in ipairs(S.types) do
        if kind ~= "All types" and #S.search("", book, kind, api, nil, excludeIncantations) > 0 then choices[#choices + 1] = kind end
    end
    return choices
end

S.refresh({})
return S
