-- Resolves built-in icons from the running client, not hardcoded beta Sprite IDs.
local items = require("data/abilities")
local types = require("data/ability_types")
local I18n = require("lib/i18n")
local U = require("lib/util")
local Spells = require("lib/spells")
local K = { items = {}, byID = {}, groups = { "All", "Constitution", "Defence", "Melee", "Ranged", "Magic", "Necromancy" } }
K.types = { "All types", "Basic", "Enhanced", "Threshold", "Ultimate", "Utility" }
-- Shared action-bar slots, not interchangeable casts. These six sequences are
-- listed in the game's ability facts; each stage keeps its own icon and ID.
local families = {}
for _, stages in ipairs({
    {"STRENGTH_DISMEMBER", "MELEE_DISMEMBER_RECAST_1", "MELEE_DISMEMBER_RECAST_2"},
    {"NECROMANCY_SPECTRAL_SCYTHE", "NECROMANCY_SPECTRAL_SCYTHE_RECAST_1", "NECROMANCY_SPECTRAL_SCYTHE_RECAST_2"},
    {"NECROMANCY_CONJURE_SKELETON_WARRIOR", "NECROMANCY_COMMAND_SKELETON_WARRIOR"},
    {"NECROMANCY_CONJURE_PUTRID_ZOMBIE", "NECROMANCY_COMMAND_PUTRID_ZOMBIE"},
    {"NECROMANCY_CONJURE_VENGEFUL_GHOST", "NECROMANCY_COMMAND_VENGEFUL_GHOST"},
    {"NECROMANCY_CONJURE_PHANTOM_GUARDIAN", "NECROMANCY_COMMAND_PHANTOM_GUARDIAN"},
}) do for _, stage in ipairs(stages) do families["COMBATV2_ABILITY_" .. stage] = stages[1] end end
-- Conditional upgrades may be absent from the base display lists. Their own
-- reviewed identity/icon plus either member's live book membership keeps both
-- available. This is separate from the six input-binding sequence families.
local selectionFamilies = U.copy(families)
local names = {}
for _, item in ipairs(items) do names[item.name] = item.id end
for _, item in ipairs(items) do
    local base = item.name:match("^Greater (.+)$")
    if base and names[base] then
        selectionFamilies[item.id], selectionFamilies[names[base]] = names[base], names[base]
    end
end
function K.sameBinding(first, second)
    return first == second or families[first] ~= nil and families[first] == families[second]
end
local clientTypes = { [0] = "Basic", [1] = "Basic", [2] = "Enhanced", [3] = "Threshold", [4] = "Ultimate", [5] = "Special", [7] = "Utility" }
local unconfirmed = false
local function minigame(ability)
    return ability:match("^COMBATV2_ABILITY_CONSTITUTION_BARB_") or ability:find("_MINIGAME_", 1, true)
end
for _, original in ipairs(items) do
    local item = U.copy(original)
    K.items[#K.items + 1] = item
    K.byID[item.id] = item
    item.abilityType = types[item.id] or "Unconfirmed type"
    item.passive = Spells.isIncantation(item.id)
    item.excluded = minigame(item.id) and "minigame" or nil
    unconfirmed = unconfirmed or item.abilityType == "Unconfirmed type"
end
if unconfirmed then K.types[#K.types + 1] = "Unconfirmed type" end

-- The six player ability-book display lists provide both live membership and
-- the combat group. Do not enumerate arbitrary Structs (NPC/test abilities).
-- Unknown future type codes stay explicitly unconfirmed instead of guessed.
function K.refresh(api)
    K.items, K.byID = {}, {}
    local originalGroups, assignedGroups, membership = {}, {}, {}
    for _, item in ipairs(items) do
        local copy = U.copy(item); copy.abilityType = types[item.id] or "Unconfirmed type"
        copy.obsoleteMembership = nil
        copy.passive = Spells.isIncantation(copy.id)
        copy.excluded = minigame(copy.id) and "minigame" or nil
        K.items[#K.items + 1], K.byID[copy.id] = copy, copy
        originalGroups[item.id] = item.skill
    end
    local added, complete = 0, true
    for _, group in ipairs({"Melee","Ranged","Magic","Necromancy","Defence","Constitution"}) do
        local bookComplete = true
        local bookOK = pcall(function()
            local param, iconParam = api.Param.COMBATV2_ABILITY_NAME, api.Param.COMBATV2_ABILITY_ICON
            if not param or not iconParam then bookComplete = false; return end
            local list = api.Enum["COMBATV2_ABILITIES_" .. group:upper() .. "_ABILITY_DISPLAY_LIST"]
            local declared = list.valueCount
            if declared ~= nil and not U.integer(declared, 0, 512) then bookComplete = false end
            local count = 0
            for _, pair in pairs(list.values) do
                count = count + 1
                if count > 512 then bookComplete = false; break end
                local rowOK, rowComplete = pcall(function()
                    local cfg = pair[2]
                    if not cfg:HasParam(param) then return false end
                    local name, ability = cfg:GetParamValue(param), cfg.configName
                    if not U.text(ability, 140) or not ability:match("^COMBATV2_ABILITY_[A-Z0-9_]+$")
                        or not U.named(name, 200) then return false end
                    if not cfg:HasParam(iconParam) or not U.integer(cfg:GetParamValue(iconParam), 1, 2147483647) then return false end
                    local item = K.byID[ability]
                    if not item then
                        item = { id = ability, abilityType = "Unconfirmed type" }
                        K.items[#K.items + 1], K.byID[ability], added = item, item, added + 1
                    end
                    -- Use confirmed live membership even for bundled abilities.
                    -- If a config appears in several books, retain its original
                    -- group when advertised; otherwise use the fixed book order.
                    if not assignedGroups[ability] or originalGroups[ability] == group then item.skill = group end
                    assignedGroups[ability] = true
                    -- A book entry may be locked, equipment-dependent or only
                    -- displayed in a particular situation. That display flag
                    -- does not establish minigame provenance. Keep real book
                    -- abilities; exclude only the identified minigame families.
                    item.excluded = minigame(ability) and "minigame" or nil
                    local kind = api.Param.COMBATV2_ABILITY_ADRENALINE_TYPE
                    if kind and cfg:HasParam(kind) then
                        item.abilityType = clientTypes[cfg:GetParamValue(kind)] or "Unconfirmed type"
                    end
                    membership[ability] = true
                    return true
                end)
                if not rowOK or not rowComplete then bookComplete = false end
            end
            if declared ~= nil and declared ~= count then bookComplete = false end
        end)
        complete = complete and bookOK and bookComplete
    end
    -- An empty/transient startup snapshot cannot establish global removal.
    -- A declared native pair count also has to match the readable rows above.
    complete = complete and next(membership) ~= nil
    K.membershipComplete = complete
    if complete then
        -- Complete current books can retire a bundled picker choice while its
        -- byID record/icon remains readable for saved profiles. A displayed base
        -- also keeps its explicitly known conditional/recast family available.
        local activeFamilies = {}
        for ability in pairs(membership) do
            if selectionFamilies[ability] then activeFamilies[selectionFamilies[ability]] = true end
        end
        for _, item in ipairs(K.items) do
            if not item.passive and not membership[item.id] and not activeFamilies[selectionFamilies[item.id]] then item.obsoleteMembership = true end
        end
    end
    local unknown = false
    for _, item in ipairs(K.items) do unknown = unknown or item.abilityType == "Unconfirmed type" end
    if unknown then
        local found = false; for _, kind in ipairs(K.types) do found = found or kind == "Unconfirmed type" end
        if not found then K.types[#K.types + 1] = "Unconfirmed type" end
    end
    K.added = added
    return added
end

function K.name(item, language) return I18n.ability(type(item) == "table" and item or K.byID[item], language) end

-- Reopen a previously saved future ability even if its display-book entry is
-- temporarily unavailable. A verified named Struct is needed for readability;
-- it never establishes current picker membership. Storage bounds the traversal
-- of saved records and this cap also bounds repeated calls independently.
function K.restoreSaved(abilityID, api)
    if not U.text(abilityID, 140) or not abilityID:match("^COMBATV2_ABILITY_[A-Z0-9_]+$") then return false end
    if K.byID[abilityID] then return true end
    if #K.items >= 4096 then return false end
    local ok, item = pcall(function()
        local cfg = api.Struct[abilityID]
        local nameParam, iconParam = api.Param.COMBATV2_ABILITY_NAME, api.Param.COMBATV2_ABILITY_ICON
        if not cfg or cfg.configName ~= abilityID or not nameParam or not iconParam
            or not cfg:HasParam(nameParam) or not cfg:HasParam(iconParam) then return nil end
        local name, icon = cfg:GetParamValue(nameParam), cfg:GetParamValue(iconParam)
        if not U.named(name, 200) or not U.integer(icon, 1, 2147483647) then return nil end
        return {id = abilityID, skill = "All", abilityType = "Unconfirmed type",
            excluded = minigame(abilityID) and "minigame" or nil, obsoleteMembership = true}
    end)
    if not ok or not item then return false end
    K.items[#K.items + 1], K.byID[abilityID] = item, item
    return true
end

function K.search(query, group, language, abilityType, api)
    local found = {}
    query = U.fold(query or "")
    for _, item in ipairs(K.items) do
        if not item.excluded and not item.obsoleteMembership and (not api or K.selectable(item.id, api))
            and (not group or group == "All" or item.skill == group)
            and (not abilityType or abilityType == "All types" or item.abilityType == abilityType
                or abilityType == "Utility" and item.abilityType == "Special")
            and I18n.matches("abilities", item.id, language, query) then
            found[#found + 1] = item
        end
    end
    return found
end

function K.availableTypes(group, language, api)
    local choices = { "All types" }
    for _, kind in ipairs(K.types) do
        if kind ~= "All types" and #K.search("", group, language, kind, api) > 0 then choices[#choices + 1] = kind end
    end
    return choices
end

function K.resolve(abilityID, api)
    local item = K.byID[abilityID]
    if not item then return nil end
    local ok, result = pcall(function()
        local ability = api.Struct[item.id]
        local param = api.Param.COMBATV2_ABILITY_ICON
        if not ability or ability.configName ~= nil and ability.configName ~= item.id
            or not param or not ability:HasParam(param) then return nil end
        local value = ability:GetParamValue(param)
        if U.integer(value, 1, 2147483647) then return value end
    end)
    if ok then return result end
    return nil
end

function K.selectable(abilityID, api)
    local item = K.byID[abilityID]
    return item ~= nil and not item.excluded and not item.obsoleteMembership and K.resolve(abilityID, api) ~= nil
end

return K
