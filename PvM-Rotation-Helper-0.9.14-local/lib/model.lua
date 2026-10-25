-- Version 6 persists passive tail cells independently of an ability.
local U = require("lib/util")
local Equipment = require("lib/equipment")
local M = { VERSION = 6 }
M.LIMIT = { profiles = 12, phases = 12, bars = 32, slots = 28 }
M.modes = { beginner = true, advanced = true, expert = true }
M.languages = { de = true, en = true, fr = true, ["pt-BR"] = true }
local function fields(value, names)
    local allowed = {}
    for name in names:gmatch("%S+") do allowed[name] = true end
    return U.fields(value, allowed)
end
function M.newProfile(name, phaseName)
    return { name = name or "New rotation", mode = "beginner",
        phases = { { name = phaseName or "Phase 1", steps = {} } }, bindings = {}, bars = {} }
end
function M.defaults()
    return { version = M.VERSION, activeProfile = 1, profiles = { M.newProfile() },
        settings = { x = 40, y = 300, width = 720, height = 570, language = "de",
            iconSize = 36, columns = 8, opacity = 95, frameWidth = 3, locator = false,
            overlayX = 40, overlayY = 70, overlayOpacity = 65, overlayVisible = false, followClicks = false, followKeys = false, showKeys = true } }
end
function M.validSlot(slot, catalogue)
    if not fields(slot, "ability objectID spell prayer unknown key") or not U.text(slot.key, 30) then return false end
    if slot.unknown ~= nil then
        return slot.unknown == true and slot.ability == nil and slot.objectID == nil and slot.spell == nil and slot.prayer == nil
    end
    if slot.ability ~= nil then
        return slot.objectID == nil and slot.spell == nil and slot.prayer == nil
            and (slot.ability == "" or catalogue.byID[slot.ability] ~= nil)
    end
    return Equipment.validReminder({objectID = slot.objectID, spell = slot.spell, prayer = slot.prayer})
end
function M.validateProfile(p, catalogue)
    if not fields(p, "name mode phases bindings bars activeBars") or not U.named(p.name, 80)
        or not M.modes[p.mode] then return false, "Invalid profile." end
    if not U.array(p.phases, M.LIMIT.phases) or #p.phases == 0 then return false, "Invalid phases." end
    for _, phase in ipairs(p.phases) do
        if not fields(phase, "name steps tailReminders") or not U.named(phase.name, 80)
            or not U.array(phase.steps) or not Equipment.validReminders(phase.tailReminders) then return false, "Invalid phases." end
        for _, step in ipairs(phase.steps) do
            if not fields(step, "ability key caption repeats breakAfter switches reminders specialWeapon eof") or not catalogue.byID[step.ability]
                or not U.text(step.key, 30) or not U.text(step.caption, 160)
                or not U.integer(step.repeats, 1, 99) or type(step.breakAfter) ~= "boolean" or not Equipment.valid(step) then
                return false, "Invalid rotation step."
            end
        end
    end
    if type(p.bindings) ~= "table" then return false, "Invalid slot position." end
    local count = 0
    for ability, binding in pairs(p.bindings) do
        count = count + 1
        if count > #catalogue.items or not catalogue.byID[ability] or not fields(binding, "x y width height")
            or not U.integer(binding.x, 0, 16000) or not U.integer(binding.y, 0, 16000)
            or not U.integer(binding.width, 16, 160) or not U.integer(binding.height, 16, 160) then
            return false, "Invalid slot position."
        end
    end
    if not U.array(p.bars, M.LIMIT.bars) then return false, "Maximum 32 bars." end
    if p.activeBars ~= nil then
        if not U.array(p.activeBars, M.LIMIT.bars) or p.activeBars[1] ~= 1 then return false, "Invalid bar layout." end
        local seen = {}
        for _, index in ipairs(p.activeBars) do
            if not U.integer(index, 1, #p.bars) or seen[index] then return false, "Invalid bar layout." end
            seen[index] = true
        end
    end
    for _, bar in ipairs(p.bars) do
        if not fields(bar, "name x y columns width height gapX gapY enabled slots") or not U.text(bar.name, 80)
            or not U.integer(bar.x, 0, 16000) or not U.integer(bar.y, 0, 16000)
            or not U.integer(bar.columns, 1, 14) or not U.integer(bar.width, 16, 160)
            or not U.integer(bar.height, 16, 160) or not U.integer(bar.gapX, 0, 40)
            or not U.integer(bar.gapY, 0, 40) or type(bar.enabled) ~= "boolean"
            or not U.array(bar.slots, M.LIMIT.slots) or #bar.slots == 0 then return false, "Invalid bar layout." end
        for _, slot in ipairs(bar.slots) do
            if not M.validSlot(slot, catalogue) then return false, "Invalid slot assignment." end
        end
    end
    return true
end
function M.newBar()
    local bar = { name = "My bar", x = 0, y = 0, columns = 14, width = 36, height = 36,
        gapX = 1, gapY = 1, enabled = true, slots = {} }
    for i = 1, 14 do bar.slots[i] = { ability = "", key = "" } end
    return bar
end
function M.validate(state, catalogue)
    if not fields(state, "version activeProfile settings profiles") or state.version ~= M.VERSION then return false, "Unknown data version." end
    if not U.array(state.profiles, M.LIMIT.profiles) or #state.profiles == 0
        or not U.integer(state.activeProfile, 1, #state.profiles) then return false, "Invalid profile." end
    local s = state.settings
    if not fields(s, "x y width height language iconSize columns opacity frameWidth locator overlayX overlayY overlayWidth overlayHeight overlayOpacity overlayVisible overlayClickthrough followClicks followKeys showKeys")
        or not U.integer(s.x, 0, 16000) or not U.integer(s.y, 0, 16000)
        or not U.integer(s.width, 560, 1200) or not U.integer(s.height, 500, 900)
        or not M.languages[s.language] or not U.integer(s.iconSize, 24, 64)
        or not U.integer(s.columns, 2, 16) or not U.integer(s.opacity, 30, 100)
        or not U.integer(s.frameWidth, 1, 6) or type(s.locator) ~= "boolean"
        or not U.integer(s.overlayX, 0, 16000) or not U.integer(s.overlayY, 0, 16000)
        or (s.overlayWidth ~= nil and not U.integer(s.overlayWidth, 370, 1200))
        or (s.overlayHeight ~= nil and not U.integer(s.overlayHeight, 160, 900))
        or not U.integer(s.overlayOpacity, 0, 100) or type(s.overlayVisible) ~= "boolean"
        or (s.overlayClickthrough ~= nil and type(s.overlayClickthrough) ~= "boolean")
        or type(s.showKeys) ~= "boolean" or type(s.followClicks) ~= "boolean" or type(s.followKeys) ~= "boolean" or (s.followKeys and s.followClicks) then
        return false, "Invalid display settings."
    end
    for _, profile in ipairs(state.profiles) do
        local ok, reason = M.validateProfile(profile, catalogue)
        if not ok then return false, reason end
    end
    return true
end
function M.upgrade(value, catalogue)
    if type(value) == "table" and (value.version == 2 or value.version == 3 or value.version == 4 or value.version == 5) and type(value.settings) == "table"
        and type(value.profiles) == "table" then
        local nextValue = U.copy(value)
        nextValue.version = M.VERSION
        if nextValue.settings.showKeys == nil then nextValue.settings.showKeys = true end
        for _, profile in pairs(nextValue.profiles) do
            if type(profile) == "table" then profile.history = nil end
        end
        if nextValue.settings.followClicks == nil then nextValue.settings.followClicks = false end
        if nextValue.settings.followKeys == nil then nextValue.settings.followKeys = false end
        return nextValue
    end
    if type(value) ~= "table" or value.version ~= 1 then return value end
    if not U.array(value.profiles, M.LIMIT.profiles) or #value.profiles == 0
        or type(value.settings) ~= "table" then return value end
    local state = M.defaults()
    state.activeProfile, state.profiles = value.activeProfile, {}
    for _, key in ipairs({ "x", "y", "width", "iconSize", "columns", "opacity", "frameWidth", "locator" }) do
        state.settings[key] = value.settings[key]
    end
    state.settings.iconSize = 36
    for _, old in ipairs(value.profiles) do
        local p = M.newProfile(old.name)
        p.mode, p.phases = old.mode, {}
        if not U.array(old.phases, M.LIMIT.phases) then return value end
        for _, phase in ipairs(old.phases) do
            local nextPhase = { name = phase.name, steps = {} }
            if not U.array(phase.steps) then return value end
            for _, step in ipairs(phase.steps) do
                nextPhase.steps[#nextPhase.steps + 1] = { ability = step.ability, key = step.key,
                    caption = U.shortText(step.note or "", 160), repeats = 1, breakAfter = false }
            end
            p.phases[#p.phases + 1] = nextPhase
        end
        p.bindings, p.bars = U.copy(old.bindings or {}), U.copy(old.bars or {})
        state.profiles[#state.profiles + 1] = p
    end
    local valid = M.validate(state, catalogue)
    return valid and state or value
end
function M.profile(state) return state.profiles[state.activeProfile] end
return M
