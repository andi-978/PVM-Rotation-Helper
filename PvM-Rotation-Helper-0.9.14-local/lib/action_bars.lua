-- Conservative native bar import. Unknown slot positions are never compressed
-- into a guessed sequence. Partial rows need explicitly numbered components.
local L = require("lib/locator")
local S = require("lib/bar_settings")
local M = require("lib/model")
local Native = require("lib/native_bars")
local Keys = require("lib/keybinds")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local U = require("lib/util")
local B = {}
local function referenceKey(reference)
    return reference.ability and "ability:" .. reference.ability
        or reference.objectID and "item:" .. reference.objectID
        or reference.spell and "spell:" .. reference.spell or "prayer:" .. reference.prayer
end
local function addIdentity(index, ambiguous, value, reference)
    if not value then return end
    local existing = index[value]
    if existing and referenceKey(existing) ~= referenceKey(reference) then ambiguous[value] = true
    else index[value] = reference end
end
-- Rebuild only on explicit Detect. Numeric object IDs are observations from
-- visible slots; persist only the matching reviewed canonical item identity.
local function identities(a)
    local sprites, ambiguousSprites, objects, ambiguousObjects = {}, {}, {}, {}
    for _, item in ipairs(a.catalogue.items) do
        if not item.passive then addIdentity(sprites, ambiguousSprites, a.catalogue.resolve(item.id, a.env.config), {ability = item.id}) end
    end
    for _, item in ipairs(Spells.items) do addIdentity(sprites, ambiguousSprites, Spells.resolve(item.id, a.env.config), {spell = item.id}) end
    for _, item in ipairs(Prayers.items) do addIdentity(sprites, ambiguousSprites, Prayers.resolve(item.id, a.env.config), {prayer = item.id}) end
    for _, item in ipairs(Equipment.items) do addIdentity(objects, ambiguousObjects, Equipment.nativeID(item.objectID), {objectID = item.objectID}) end
    return function(row)
        if row.identityAmbiguous then return {unknown = true} end
        local reference
        if row.nativeObjectID then
            if not ambiguousObjects[row.nativeObjectID] then reference = objects[row.nativeObjectID] end
        elseif not ambiguousSprites[row.spriteID] then reference = sprites[row.spriteID] end
        if reference then return U.copy(reference) end
        if row.nativeObjectID or row.spriteID ~= -1 then return {unknown = true} end
        return {ability = ""}
    end
end
local function importedSlot(row, origin, resolve, gameKeys)
    local reference = resolve(row)
    local label = Keys.nativeLabel(row.keybind)
    local keyKnown = type(row.keybind) == "string" and (label == "" or Keys.parse(label, gameKeys) ~= nil)
    reference.read, reference.empty = true, not row.identityAmbiguous and row.spriteID == -1 and not row.nativeObjectID
    reference.key, reference.keyKnown = keyKnown and label or "", keyKnown
    reference.spriteID, reference.nativeObjectID = row.spriteID, row.nativeObjectID
    reference.x, reference.y = row.x - origin.x, row.y - origin.y
    reference.width, reference.height = row.width, row.height
    return reference
end
function B.ensure(profile, count)
    for i = #profile.bars + 1, count do profile.bars[i] = M.newBar() end
    for _, bar in ipairs(profile.bars) do
        for i = #bar.slots + 1, 14 do bar.slots[i] = { ability = "", key = "" } end
    end
end
function B.detect(a)
    local parent = a:gameParent()
    if not parent then a.status, a.pending = "Game interface unavailable.", true; return false end
    local originOK, origin = pcall(function()
        local xy = parent.xyGlobal
        if U.finite(xy.x) and U.finite(xy.y) then return {x = xy.x, y = xy.y} end
    end)
    if not originOK or not origin then a.status, a.pending = "Game interface unavailable.", true; return false end
    L.invalidate()
    local native, nativeStats = Native.read(a.env)
    local roots, reason, names = {}, nil, {}
    if nativeStats.supported == 0 then
        roots, reason = L.roots(a.env.id.Component, a.env.ui.Interfaces, a.env.id.Interface)
        names = L.names(a.env.id.Component) or {}
    end
    local resolve = identities(a)
    local detected = {}
    for index, bar in pairs(native) do
        local imported = { slots = {}, interfaceID = bar.interfaceID }
        detected[index] = imported
        for slot, row in pairs(bar.slots) do
            imported.slots[slot] = importedSlot(row, origin, resolve, a.env.gameKeys)
        end
    end
    for _, root in ipairs(roots) do
        -- A root may disappear after lookup. Snapshot its identity once and
        -- allow the other independently readable bars to finish importing.
        local rootOK, interfaceID = pcall(function() return root.interfaceID end)
        if rootOK and U.integer(interfaceID, 1, 65535) then
            local index = L.barIndex(a.env.id.Interface, interfaceID)
            for _, entry in ipairs(names) do
                if math.floor(entry.value / 65536) == interfaceID then
                    local prefix = entry.name:match("^(.-)__") or entry.name
                    local additional = prefix:match("ADDITIONAL_?ACTION_?BAR_?(%d+)") or prefix:match("ACTION_?BAR_?EXTRA_?(%d+)")
                    local candidate = additional and tonumber(additional) + 1 or
                        ((prefix == "ACTIONBAR" or prefix == "ACTION_BAR" or prefix:find("MAIN_ACTIONBAR", 1, true)) and 1 or nil)
                    if candidate and candidate <= 5 then
                        if index and index ~= candidate then index = false; break end
                        index = candidate
                    end
                end
            end
            if index then
                local raw = L.scan({ root }, a.env.ui.ComponentType, a.env.id.Component)
                -- scan already reconciles all observations of a physical cell;
                -- a first-seen filter here would discard its stronger evidence.
                local cells = raw
                local minY, maxY = math.huge, -math.huge
                for _, row in ipairs(cells) do minY, maxY = math.min(minY, row.y), math.max(maxY, row.y) end
                local sameRow = maxY - minY <= 4
                -- Choose one axis for the whole collection. A pairwise row
                -- tolerance can create A<B<C<A and violates table.sort's order.
                table.sort(cells, function(x, y)
                    if sameRow then return x.x == y.x and x.y < y.y or x.x < y.x end
                    return x.y == y.y and x.x < y.x or x.y < y.y
                end)
                local numbered, zero, fourteen = true, false, false
                for _, row in ipairs(cells) do numbered = numbered and row.slotNumber ~= nil; zero = zero or row.slotNumber == 0; fourteen = fourteen or row.slotNumber == 14 end
                local slots, regular = {}, #cells == 14
                for _, row in ipairs(cells) do if row.slotAmbiguous then regular = false end end
                if regular then
                    local horizontal = math.abs(cells[1].y - cells[14].y) <= 4
                    local vertical = math.abs(cells[1].x - cells[14].x) <= 4
                    local pitch = horizontal and (cells[2].x - cells[1].x) or (cells[2].y - cells[1].y)
                    regular = (horizontal or vertical) and pitch > 12 and pitch <= 200
                    for i, row in ipairs(cells) do
                        local delta = horizontal and row.x - cells[1].x or row.y - cells[1].y
                        if math.abs(delta - (i - 1) * pitch) > 3 then regular = false end
                    end
                end
                for i, row in ipairs(cells) do
                    local slot = numbered and (zero or fourteen) and (row.slotNumber + (zero and 1 or 0)) or regular and i or nil
                    if slot and slot >= 1 and slot <= 14 and not slots[slot] then
                        slots[slot] = importedSlot(row, origin, resolve, a.env.gameKeys)
                    end
                end
                if next(slots) then detected[index] = { slots = slots, interfaceID = interfaceID } end
            end
        end
    end
    local main = detected[1]
    for index = 1, 14 do
        local slot = main and main.slots[index]
        if slot and type(slot.width) == "number" and slot.width == slot.height and slot.width >= 12 and slot.width <= 64 then
            a.nativeIconSize = slot.width
            break
        end
    end
    local settings = nativeStats.supported > 0 and { keys = {}, visible = {} } or S.read(a.env)
    local count = math.max(1, #a:profile().bars)
    for index in pairs(detected) do count = math.max(count, index) end
    for index in pairs(settings.keys) do count = math.max(count, index) end
    for index, visible in pairs(settings.visible) do if visible then count = math.max(count,index) end end
    if a:change(function(_, p)
        B.ensure(p, count)
        -- Missing metadata is not evidence that formerly detected bars closed.
        if next(detected) or next(settings.keys) or next(settings.visible) then
            p.activeBars = {1}
            for index = 2, count do
                if detected[index] or settings.visible[index] then p.activeBars[#p.activeBars + 1] = index end
            end
            for _, index in ipairs(p.activeBars) do p.bars[index].enabled = true end
        end
        for index, bar in pairs(detected) do for slot, value in pairs(bar.slots) do
            local saved = p.bars[index].slots[slot]
            if saved then
                local key = (value.key ~= "" or value.keyKnown) and value.key or saved.key
                local reference = value.unknown and {unknown = true} or value.objectID and {objectID = value.objectID}
                    or value.spell and {spell = value.spell} or value.prayer and {prayer = value.prayer} or {ability = value.ability or ""}
                reference.key = key
                p.bars[index].slots[slot] = reference
            end
        end end
        for index, keys in pairs(settings.keys) do for slot, key in pairs(keys) do
            if p.bars[index].slots[slot] then p.bars[index].slots[slot].key = key end
        end end
    end) then a.detectedBars = detected else return false end
    a.status = (next(detected) or next(settings.keys)) and "Detection finished. Empty fields remain editable." or reason or "No unambiguous bar slots found."
    a.pending = true
    return true
end
return B
