-- Our UI translations do not change config IDs or the game client's language.
local texts = require("data/ui_text")
local names = require("data/catalogue_names")
local languages = require("data/languages")
local U = require("lib/util")
local I = { languages = { "de", "en", "fr", "pt-BR" },
    labels = languages.labels,
    texts = texts }
local positions = { de = 1, fr = 2, ["pt-BR"] = 3 }
local namePositions = { en = 1, de = 2, fr = 3, ["pt-BR"] = 4 }
local folded = {}
function I.text(language, key, ...)
    local entry, index = texts[key], positions[language]
    local value = entry and index and entry[index] or key
    if select("#", ...) > 0 then return string.format(value, ...) end
    return value
end
-- Preview and search share the same exact language. Never substitute the
-- current client's language for a missing localized entry.
function I.name(kind, identifier, language)
    local entry = names[kind] and names[kind][identifier]
    language = language or "en"
    return entry and entry[namePositions[language]] or "?"
end
function I.ability(item, language)
    if not item then return "?" end
    return I.name("abilities", item.id, language)
end
function I.matches(kind, identifier, language, query)
    local entry = names[kind] and names[kind][identifier]
    local position = namePositions[language or "en"]
    if not entry or not position then return U.fold(I.name(kind, identifier, language)):find(query, 1, true) ~= nil end
    folded[entry] = folded[entry] or {}
    folded[entry][position] = folded[entry][position] or U.fold(entry[position])
    return folded[entry][position]:find(query, 1, true) ~= nil
end
function I.phaseNumber(name)
    local number = type(name) == "string" and tonumber(name:match("(%d+)$"))
    if not U.integer(number, 1, 1000000) then return nil end
    for _, language in ipairs(I.languages) do
        if name == I.text(language, "Phase %d", number) then return number end
    end
end
function I.phaseName(name, language)
    local number = I.phaseNumber(name)
    return number and I.text(language, "Phase %d", number) or name
end
return I
