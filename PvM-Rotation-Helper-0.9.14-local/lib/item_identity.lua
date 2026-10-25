-- Reviewed canonical IDs map only through positively evidenced config names.
-- Numeric catalogue IDs are never used as native Obj lookups or artwork IDs.
-- Obj metadata is static for a loaded client; reinitialization refreshes this
-- snapshot. Rendering/searching do not re-read native configs or Params.
local U = require("lib/util")
local I = {}
local matches, reviewed, failed = {}, 0, 0
local states = {"CERT", "CERTIFICATE", "NOTED", "LENT", "LOAN", "LOANED", "AUGMENTED", "UNSTRUNG",
    "UNFINISHED", "BROKEN", "DAMAGED", "UNCHARGED", "DEGRADED", "DEPLETED", "INACTIVE", "UNPOWERED"}
local function normal(name)
    return U.fold(name:gsub("<nbsp>", " ")):gsub("%s+", " "):match("^%s*(.-)%s*$")
end
local function role(item)
    return item.potion and "potion" or item.eof and "eof" or item.ammunition and "ammunition" or item.weapon and "weapon" or nil
end
local function read(api, ids, objects, item)
    if not objects or not item.configName then return nil end
    local ok, result = pcall(function()
        local cfg = objects[item.configName]
        if not cfg then
            local nativeID = ids and ids.Obj and ids.Obj[item.configName]
            if U.integer(nativeID, 1, 1000000) then cfg = objects.FromID(nativeID) end
        end
        if not cfg or cfg.configName ~= item.configName or not U.integer(cfg.id, 1, 1000000) or not U.named(cfg.name, 200) then return nil end
        local upper = "_" .. cfg.configName:upper() .. "_"
        for _, token in ipairs(states) do if upper:find("_" .. token .. "_", 1, true) then return nil end end
        if cfg.quests then for _ in pairs(cfg.quests) do return nil end end
        -- The exact reviewed config name establishes the item identity and its
        -- catalogue role. interfaceOpNames contains localized display strings,
        -- not a language-independent role code; English verbs cannot validate
        -- an otherwise verified German/French/Portuguese configuration.
        local style, tier
        for _, group in ipairs({"Melee", "Ranged", "Magic", "Necromancy"}) do
            local key = api.Param and api.Param["COMBATV2_" .. group:upper() .. "_WEAPON"]
            if key and cfg:HasParam(key) and cfg:GetParamValue(key) == 1 then
                if style then return nil end
                style = group
            end
        end
        if style and item.style ~= style then return nil end
        local key = api.Param and api.Param.COMBATV2_ITEM_TIER
        if key and cfg:HasParam(key) then
            local value = cfg:GetParamValue(key)
            if not U.integer(value, 0, 120) then return nil end
            if value > 0 then tier = value end
        end
        if item.needsTier and (not U.integer(item.tier, 1, 120) or tier ~= item.tier)
            or tier and item.tier and tier ~= item.tier then return nil end
        return cfg.id
    end)
    if not ok then failed = failed + 1 end
    matches[item.id] = ok and result or nil
    return ok and result or nil
end
function I.initialize(api, ids, reviewedItems, bindings)
    matches, reviewed, failed = {}, 0, 0
    local items, names = {}, {}
    for _, source in ipairs(reviewedItems or {}) do
        local kind = role(source)
        if U.integer(source.objectID, 1, 1000000) and U.named(source.name, 200) and kind and not source.excluded and not items[source.objectID] then
            local binding = type(bindings) == "table" and bindings[source.objectID] or nil
            local item = {id = source.objectID, name = source.name, style = source.style, tier = source.tier,
                configName = U.named(binding, 200) and binding or nil}
            items[item.id], reviewed = item, reviewed + 1
            local name = normal(item.name); names[name] = (names[name] or 0) + 1
        end
    end
    local supported, objects = pcall(function() return api and api.Obj end)
    if not supported then failed = 1 end
    for _, item in pairs(items) do
        item.needsTier = names[normal(item.name)] > 1
        read(api, ids, supported and objects or nil, item)
    end
end
function I.resolve(canonical)
    return U.integer(canonical, 1, 1000000) and matches[canonical] or nil
end
function I.counts()
    local resolved = 0; for _ in pairs(matches) do resolved = resolved + 1 end
    return {reviewed = reviewed, resolved = resolved, unresolved = reviewed - resolved, failed = failed}
end
return I
