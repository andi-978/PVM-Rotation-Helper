-- Original mapping of official client key events to explicitly labelled slots.
-- No character decoding, key history, OS hooks, or gameplay input generation.
local U = require("lib/util")
local Locator = require("lib/locator")
local Native = require("lib/native_bars")
local Catalogue = require("lib/catalogue")
local I18n = require("lib/i18n")
local Languages = require("data/languages")
local B = {}
local modifiers, symbols = Languages.keyModifiers, Languages.keySymbols
local excluded = { ENTER = true, CONSOLE = true, ESCAPE = true, SLASH = true, TAB = true, SHIFT = true, CONTROL = true, ALT = true }

-- Only call on a positively identified native TEXT_n field, never arbitrary
-- labels. The compact action-bar notation uses a-/c-/s- modifier prefixes.
function B.nativeLabel(label)
    if type(label) ~= "string" then return nil end
    local text = label:gsub("<col=%x+>", ""):gsub("</col>", "")
        :gsub("<shad=%x+>", ""):gsub("</shad>", ""):match("^%s*(.-)%s*$")
    if not U.text(text, 30) or text:find("[<>]") then return nil end
    local prefix, seen = "", {}
    local names = { a = "Alt+", c = "Ctrl+", s = "Shift+" }
    while text:match("^[aAcCsS]%-") do
        local letter = text:sub(1,1):lower()
        if seen[letter] then return nil end
        seen[letter], prefix, text = true, prefix .. names[letter], text:sub(3)
    end
    return prefix .. text
end

function B.parse(label, keys)
    if type(label) ~= "string" or label == "" or not keys or label:find("<", 1, true) then return nil end
    -- Search-style accent folding changes actual keys (Ä -> A, É -> E).
    -- Normalise ASCII case only; fold accents solely for known word aliases.
    local text = label:gsub("[A-Z]", function(ch) return string.char(ch:byte() + 32) end):gsub("%s+", "")
    if text:sub(1, 1) == "+" or text:sub(-1) == "+" or text:find("++", 1, true) then return nil end
    local code, mask, seen = nil, 0, {}
    for token in text:gmatch("[^+]+") do
        local bit = modifiers[token]
        if bit then
            if seen[bit] then return nil end
            seen[bit], mask = true, mask + bit
        else
            if code then return nil end
            local name = symbols[token] or symbols[U.fold(token)]
                or token:gsub("[a-z]", function(c) return string.char(c:byte() - 32) end)
            if name:match("^%d$") then name = "_" .. name end
            if excluded[name] then return nil end
            code = keys[name]
            if not U.integer(code, 1, 65535) then return nil end
        end
    end
    if not code then return nil end
    return { code = code, modifiers = mask }
end

function B.available(env)
    local k = env.keyboard
    local complete = env.keyEvent ~= nil and type(env.keyEvent.Subscribe) == "function" and type(env.keyEvent.Unsubscribe) == "function"
        and env.gameKeys ~= nil and k ~= nil
        and type(k.IsAvailable) == "function" and type(k.IsBlocked) == "function" and type(k.IsMetaDown) == "function"
    if not complete then return false end
    local ok, available = pcall(k.IsAvailable)
    return ok and available == true
end

function B.display(label, language)
    return label:gsub("[^+]+", function(token)
        -- Normalize only recognized word aliases for display. An actual key
        -- glyph such as Ä or É must never become an unrelated ASCII key.
        local alias = U.fold(token:gsub("%s+", ""))
        local modifier = modifiers[alias]
        if modifier == 1 then return I18n.text(language, "Shift") end
        if modifier == 2 then return I18n.text(language, "Ctrl") end
        if modifier == 4 then return "Alt" end
        if symbols[alias] == "SPACE" then return I18n.text(language, "Space") end
        return token
    end)
end

function B.unblocked(env)
    return B.available(env) and env.keyboard.IsAvailable() and not env.keyboard.IsBlocked() and not env.keyboard.IsMetaDown()
end

-- Bar corrections are shared by all phases. Old hidden presets and the raw
-- detection cache cannot override a later explicit correction of a slot.
local function sameAbility(slot, ability)
    return slot and type(slot.ability) == "string" and slot.ability ~= "" and Catalogue.sameBinding(slot.ability, ability)
end

function B.profileLabels(ability, profile)
    local values, known, active = {}, false, {}
    for _, index in ipairs(profile.activeBars or {}) do active[index] = true end
    for index, bar in ipairs(profile.bars) do if bar.enabled and (not profile.activeBars or active[index]) then
        for _, slot in ipairs(bar.slots) do if sameAbility(slot, ability) then
            known = true
            if slot.key ~= "" then values[slot.key] = true end
        end end
    end end
    return values, known
end

function B.matches(step, event, env, catalogue, profile, detected)
    if not event or event.isRepeat ~= false or not U.integer(event.gameKey, 1, 65535)
        or not U.integer(event.modifiers, 0, 7) then return false end
    local expected = catalogue.resolve(step.ability, env.config)
    if not expected then return false end
    local explicit = step.key ~= "" and B.parse(step.key, env.gameKeys) or nil
    local _, imported = B.profileLabels(step.ability, profile)
    local shared = profile.activeBars and imported
    if shared then explicit = nil end
    local live, stats = Native.rows(env)
    if stats.supported > 0 then
        -- Current native slots outrank a saved import, which may describe a
        -- previous preset. Only an unreadable key field permits manual fallback.
        local found = false
        for _, row in ipairs(live) do
            local label = B.nativeLabel(row.keybind)
            if not B.parse(label, env.gameKeys) then
                local bar = profile.bars[row.barIndex]
                local slot = bar and bar.slots[row.slotNumber]
                label = sameAbility(slot, step.ability) and slot.key or label
            end
            local target = not row.identityAmbiguous and row.nativeObjectID == nil and row.spriteID == expected
            local combo = B.parse(label, env.gameKeys) or target and explicit
            if combo and combo.code == event.gameKey and combo.modifiers == event.modifiers then
                if not target then return false end
                found = true
            end
        end
        return found
    end
    -- A readable live key above is authoritative even when an older step has
    -- its own label. Only the metadata fallback uses that explicit restriction.
    if not shared and step.key ~= "" and not explicit then return false end
    if explicit and (explicit.code ~= event.gameKey or explicit.modifiers ~= event.modifiers) then return false end
    -- Explicit user assignments are useful even when the beta's component name
    -- index cannot be enumerated. They describe an attempted input, not a
    -- detected/executed ability. Reject any conflicting configured ability.
    local configured, expectedBinding = explicit ~= nil, false
    local active = {}
    for _, index in ipairs(profile.activeBars or {}) do active[index] = true end
    for index, bar in ipairs(profile.bars) do if bar.enabled and (not profile.activeBars or active[index]) then
        for _, slot in ipairs(bar.slots) do
            local combo = B.parse(slot.key, env.gameKeys)
            if combo and sameAbility(slot, step.ability) then expectedBinding = true end
            if combo and combo.code == event.gameKey and combo.modifiers == event.modifiers then
                if not sameAbility(slot, step.ability) then return false end
                configured = true
            end
        end
    end end
    if expectedBinding and not configured then return false end
    local raw = Locator.read(env)
    local origin = env.parent().xyGlobal
    local rows = {}
    for _, row in ipairs(raw) do
        rows[#rows + 1] = { spriteID = row.spriteID, keybind = row.keybind, nativeObjectID = row.nativeObjectID, identityAmbiguous = row.identityAmbiguous,
            interfaceID = row.interfaceID, x = row.x - origin.x, y = row.y - origin.y, width = row.width, height = row.height }
    end
    -- Manual corrections belong to one current interface/rectangle. Retain the
    -- row's observed sprite, object and ambiguity flags when replacing its key.
    for barIndex, bar in pairs(detected or {}) do for slotIndex, slot in pairs(bar.slots) do
        local manual = profile.bars[barIndex] and profile.bars[barIndex].slots[slotIndex]
        if manual and manual.key ~= "" then for _, row in ipairs(rows) do
            if row.interfaceID == bar.interfaceID and row.x == slot.x and row.y == slot.y
                and row.width == slot.width and row.height == slot.height then
                row.keybind = manual.key
            end
        end end
    end end
    local found = configured
    for _, row in ipairs(rows) do
        local sprite = row.spriteID
        local target = not row.identityAmbiguous and row.nativeObjectID == nil and sprite == expected
        local combo = target and explicit or B.parse(row.keybind, env.gameKeys)
        if combo and combo.code == event.gameKey and combo.modifiers == event.modifiers then
            if not target then return false end -- Same key on another/unknown ability is ambiguous.
            found = true
        end
    end
    return found
end

return B
