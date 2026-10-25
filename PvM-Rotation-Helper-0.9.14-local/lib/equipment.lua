-- Item, spell and prayer annotations are visual reminders. No inventory or
-- equipment observations, game actions or independent progression triggers.
local U = require("lib/util")
local Legacy = require("data/equipment_legacy")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local Identity = require("lib/item_identity")
local I18n = require("lib/i18n")
local E = { items = {}, byID = {} }
for _, source in ipairs({require("data/equipment"), require("data/potions"), require("data/ammunition")}) do
    for _, item in ipairs(source) do
        if not E.byID[item.objectID] then
            E.items[#E.items + 1], E.byID[item.objectID] = item, item
        end
    end
end
local builtins = E.items
E.SPECIAL = "COMBATV2_ABILITY_CONSTITUTION_SPECIAL_ATTACK"
E.FINALITY = "COMBATV2_ABILITY_CONSTITUTION_ALCHEMICAL_HYDRIX_AMULET"
E.tiers = { 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120 }
function E.tierLabel(a, tier)
    return tier == 0 and a:t("All tiers") or (tier == 120 and "T120" or ("T" .. tier .. "–" .. (tier + 9)))
end

-- Persistence refers only to our reviewed canonical IDs and recorded legacy
-- IDs. A current client number cannot establish a saved item's identity.
function E.lookup(objectID)
    if not U.integer(objectID, 1, 1000000) then return nil end
    if E.byID[objectID] then return E.byID[objectID] end
    if Legacy.aliases[objectID] then return E.byID[Legacy.aliases[objectID]] end
    if Legacy.blocked[objectID] ~= nil then
        return { objectID = objectID, name = "?", special = Legacy.blocked[objectID], excluded = "legacy-only" }
    end
end
function E.canonicalID(objectID) return Legacy.aliases[objectID] or objectID end
function E.initialize(api, ids)
    E.items, E.byID = {}, {}
    for _, item in ipairs(builtins) do E.items[#E.items + 1], E.byID[item.objectID] = item, item end
    Identity.initialize(api, ids, E.items, require("data/item_names"))
end
function E.nativeID(objectID)
    local canonical = E.canonicalID(objectID)
    return E.byID[canonical] and Identity.resolve(canonical) or nil
end

function E.search(query, kind, style, minimum, maximum, currentOnly, language)
    local results = {}
    query = U.fold(query or "")
    for _, item in ipairs(E.items) do
        local matches = kind == "Finality amulets" and item.eof
            or kind == "Special attack weapons" and item.weapon and item.specialVerified and not item.potion
            or kind == "Weapons" and item.weapon and not item.ammunition and not item.potion and not item.eof and (not item.tier or item.tier >= 10 and item.tier <= 120)
            or kind == "Ammunition" and item.ammunition and not item.excluded
            or kind == "Potions" and item.potion
        if not item.excluded and matches and (style == "All" or not style or item.style == style or item.eof)
            and (not minimum or item.tier and item.tier >= minimum)
            and (not maximum or item.tier and item.tier <= maximum)
            and I18n.matches("items", item.objectID, language, query)
            and (not currentOnly or E.nativeID(item.objectID)) then results[#results + 1] = item end
    end
    return results
end

function E.name(objectID, language)
    objectID = E.canonicalID(objectID)
    local item = E.lookup(objectID)
    if not item then return "?" end
    return I18n.name("items", objectID, language)
end

function E.valid(step)
    if step.switches ~= nil then
        if not U.array(step.switches, 3) then return false end
        local seen = {}
        for _, objectID in ipairs(step.switches) do
            if not E.lookup(objectID) or seen[objectID] then return false end
            seen[objectID] = true
        end
    end
    if step.reminders ~= nil then
        if not U.array(step.reminders, 8) then return false end
        local seen = {}
        for _, reminder in ipairs(step.reminders) do
            if not E.validReminder(reminder) then return false end
            local key = reminder.prayer and ("prayer:" .. reminder.prayer)
                or reminder.spell and ("spell:" .. reminder.spell) or ("item:" .. E.canonicalID(reminder.objectID))
            if seen[key] then return false end
            seen[key] = true
        end
    end
    if step.specialWeapon ~= nil then
        local item = E.lookup(step.specialWeapon)
        if not item or not item.special or (step.ability ~= E.SPECIAL and step.ability ~= E.FINALITY) then return false end
    end
    if step.eof ~= nil then
        local item = E.byID[step.eof]
        if not item or not item.eof or step.ability ~= E.FINALITY then return false end
    end
    return true
end

function E.validReminder(reminder)
    if not U.fields(reminder, {objectID = true, spell = true, prayer = true}) then return false end
    if reminder.prayer ~= nil then
        return reminder.objectID == nil and reminder.spell == nil and Prayers.lookup(reminder.prayer) ~= nil
    end
    if reminder.spell ~= nil then return reminder.objectID == nil and Spells.lookup(reminder.spell) ~= nil end
    return E.lookup(reminder.objectID) ~= nil
end

local function containsReminder(reminders, reminder)
    for position, existing in ipairs(reminders or {}) do
        if reminder.spell and existing.spell == reminder.spell
            or reminder.prayer and existing.prayer == reminder.prayer
            or reminder.objectID and existing.objectID and E.canonicalID(existing.objectID) == E.canonicalID(reminder.objectID) then return position end
    end
    return false
end

local function selectable(reminder, api)
    if not E.validReminder(reminder) then return false end
    if reminder.spell then return Spells.resolve(reminder.spell, api) ~= nil end
    if reminder.prayer then return Prayers.resolve(reminder.prayer, api) ~= nil end
    local item = E.byID[reminder.objectID]
    return item and not item.excluded and E.canonicalID(reminder.objectID) == reminder.objectID
        and (item.weapon or item.ammunition or item.potion) and not item.eof and E.nativeID(reminder.objectID) ~= nil
end

-- Each click commits a passive cell at the current insertion boundary. Tail
-- cells survive reloads even when no following ability exists yet. Selection
-- changes never move previously inserted cells.
function E.queue(a, reminder, targetIndex, position)
    if not selectable(reminder, a.env.config) then return false end
    if position ~= nil and not U.integer(position, -2147483648, 2147483647) then return false end
    local phase = a:currentPhase()
    local after = U.clamp(a.insertAfter or #phase.steps, 0, #phase.steps)
    local index = targetIndex or after + 1
    if not U.integer(index, 1, #phase.steps + 1) then return false end
    local tail = index > #phase.steps
    local owner = tail and phase or phase.steps[index]
    local key = tail and "tailReminders" or "reminders"
    local function select(kind, position)
        a.selectedReminder = {index = index, kind = kind, position = position}
        a.revealReminder, a.pending = true, true
        a.formGeneration = (a.formGeneration or 0) + 1
    end
    local existing = containsReminder(owner[key], reminder)
    if existing then select(key, existing); return true end
    for position, id in ipairs(owner.switches or {}) do
        if reminder.objectID and E.canonicalID(id) == reminder.objectID then select("switches", position); return true end
    end
    local committedPosition
    local saved = a:change(function(_, profile)
        local phase = profile.phases[a.phase]
        local owner = tail and phase or phase.steps[index]
        owner[key] = owner[key] or {}
        assert(#owner[key] < 8, "Maximum eight reminders per step.")
        committedPosition = U.clamp(position or #owner[key] + 1, 1, #owner[key] + 1)
        table.insert(owner[key], committedPosition, U.copy(reminder))
    end)
    if saved then
        select(key, committedPosition)
        a.lastInput = nil
    end
    return saved
end

function E.validReminders(reminders)
    return E.valid({reminders = reminders})
end

-- A source describes exactly one visual cell, never its owning ability. Legacy
-- switches remain readable and can be moved into the current reminder format.
local function sourceChain(phase, source)
    if type(source) ~= "table" or not U.integer(source.position, 1, 8) then return nil end
    local owner
    if source.kind == "tailReminders" then
        if source.index ~= #phase.steps + 1 then return nil end
        owner = phase
    elseif source.kind == "reminders" or source.kind == "switches" then
        if not U.integer(source.index, 1, #phase.steps) then return nil end
        owner = phase.steps[source.index]
    else return nil end
    local chain = owner[source.kind]
    return chain and chain[source.position] ~= nil and chain or nil
end

function E.removeReminder(a, source)
    if not sourceChain(a:currentPhase(), source) then return false end
    local saved = a:change(function(_, profile)
        local chain = assert(sourceChain(profile.phases[a.phase], source))
        table.remove(chain, source.position)
    end)
    if saved then
        a.selectedReminder = nil
        a.formGeneration = (a.formGeneration or 0) + 1
    end
    return saved
end

function E.moveReminder(a, source, targetIndex, position)
    local phase = a:currentPhase()
    if not sourceChain(phase, source) or not U.integer(targetIndex, 1, #phase.steps + 1) then return false end
    if position ~= nil and not U.integer(position, -2147483648, 2147483647) then return false end
    local saved = a:change(function(_, profile)
        local phase = profile.phases[a.phase]
        local from = assert(sourceChain(phase, source))
        local reminder = table.remove(from, source.position)
        if source.kind == "switches" then reminder = {objectID = E.canonicalID(reminder)}
        elseif reminder.objectID then reminder = {objectID = E.canonicalID(reminder.objectID)} end
        local owner = targetIndex > #phase.steps and phase or phase.steps[targetIndex]
        local key = targetIndex > #phase.steps and "tailReminders" or "reminders"
        owner[key] = owner[key] or {}
        local chain = owner[key]
        local at = position or #chain + 1
        if chain == from and position and source.position < position then at = at - 1 end
        at = U.clamp(at, 1, #chain + 1)
        local duplicate = containsReminder(chain, reminder)
        for _, id in ipairs(owner.switches or {}) do
            duplicate = duplicate or reminder.objectID ~= nil and E.canonicalID(id) == reminder.objectID
        end
        if not duplicate then
            assert(#chain < 8, "Maximum eight reminders per step.")
            table.insert(chain, at, reminder)
        end
    end)
    if saved then
        a.selectedReminder, a.lastInput = nil, nil
        a.formGeneration = (a.formGeneration or 0) + 1
    end
    return saved
end

function E.attach(a, objectID, kind)
    if kind ~= "Special attack weapons" and kind ~= "Finality amulets" then return false end
    local item = E.byID[objectID]
    if not item or item.excluded or E.canonicalID(objectID) ~= objectID or not E.nativeID(objectID) then return false end
    if kind == "Special attack weapons" and (not item.weapon or not item.specialVerified)
        or kind == "Finality amulets" and not item.eof then return false end
    local index = a.selected or a.insertAfter
    if not index then
        a.status = "Select an ability step first."; return false
    end
    local current = a:currentPhase().steps[index]
    if not current then return false end
    if kind == "Special attack weapons" and current.ability ~= E.SPECIAL and current.ability ~= E.FINALITY
        or kind == "Finality amulets" and current.ability ~= E.FINALITY then
        a.status = "Select Weapon Special Attack or Finality first."; return false
    end
    local saved = a:change(function(_, profile)
        local step = profile.phases[a.phase].steps[index]
        if kind == "Special attack weapons" then
            step.specialWeapon = objectID
        elseif kind == "Finality amulets" then step.eof = objectID end
    end)
    if saved then a:clearStepDrafts(); a.lastInput, a.repeatIndex = nil, 1 end
    return saved
end
return E
