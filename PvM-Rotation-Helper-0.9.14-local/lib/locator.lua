-- Read-only Sprite-ID matching inside explicitly named action-bar components.
-- The selected ability comes exclusively from the user's manual step selection.
-- No pixel recognition, key capture, ability inference, UI modification or game inputs.
local Native = require("lib/native_bars")
local U = require("lib/util")
local L = {}
local collections = { LAYER = true, PANEL = true, GRID = true, GROUP_BOX = true,
    PAGED_LAYER = true, PAGED_CAROUSEL = true, CUTSCENE_LAYER = true }

-- Some beta ID proxies support named lookup but expose no pairs() entries.
-- These are bounded capability probes, not hardcoded numeric IDs. A probe is
-- used only when the running client resolves it to a matching native component.
L.prefixes = { { "ACTIONBAR", 1 }, { "ACTION_BAR", 1 }, { "MAIN_ACTIONBAR", 1 }, { "MAIN_ACTION_BAR", 1 } }
for i, name in ipairs(Native.prefixes) do L.prefixes[#L.prefixes + 1] = { name, i } end
for i = 1, 4 do
    L.prefixes[#L.prefixes + 1] = { "ACTIONBAR_EXTRA" .. i, i + 1 }
    L.prefixes[#L.prefixes + 1] = { "ADDITIONAL_ACTIONBAR_" .. i, i + 1 }
    L.prefixes[#L.prefixes + 1] = { "ADDITIONAL_ACTION_BAR_" .. i, i + 1 }
end

function L.lookup(index, name)
    local ok, value = pcall(function() return index and index[name] end)
    if ok and type(value) == "number" and value > 0 and value % 1 == 0 then return value end
end

function L.barIndex(interfaceIDs, interfaceID)
    local found
    for _, entry in ipairs(L.prefixes) do
        if L.lookup(interfaceIDs, entry[1]) == interfaceID then
            if found and found ~= entry[2] then return nil end
            found = entry[2]
        end
    end
    return found
end

function L.invalidate()
    L.cachedIDs, L.cachedNames, L.cachedReverse = nil, nil, nil
end

function L.names(componentIDs)
    if L.cachedIDs == componentIDs then return L.cachedNames, L.cachedReverse end
    local names, reverse, added = {}, {}, {}
    local function add(name, value)
        if added[name] then return end
        added[name] = true
        names[#names + 1] = { name = name, value = value }
        if reverse[value] ~= nil and reverse[value] ~= name then reverse[value] = false
        else reverse[value] = name end
    end
    local ok = pcall(function()
        for key, value in pairs(componentIDs) do
            local name, packed = U.namedID(componentIDs, key, value)
            if name and packed > 0 and (name:find("ACTIONBAR", 1, true) or name:find("ACTION_BAR", 1, true)) then
                add(name, packed)
            end
        end
    end)
    for _, prefix in ipairs(L.prefixes) do
        local suffixes = { "ROOT", "LAYER", "BACKGROUND", "COMBAT_BAR_ROOT" }
        for i = 0, 14 do
            suffixes[#suffixes + 1] = "SLOT_" .. i
            suffixes[#suffixes + 1] = "SLOT" .. i
            suffixes[#suffixes + 1] = "SLOT" .. i .. "_KEYBIND"
        end
        for _, suffix in ipairs(suffixes) do
            local name = prefix[1] .. "__" .. suffix
            local value = L.lookup(componentIDs, name)
            if value then add(name, value) end
        end
    end
    if not ok and #names == 0 then return nil, nil end
    table.sort(names, function(a, b) return a.name < b.name end)
    L.cachedIDs, L.cachedNames, L.cachedReverse = componentIDs, names, reverse
    return names, reverse
end

-- Prefer the exact slot reader on clients exposing the verified native names.
-- The older semantic reader remains for previously supported API layouts only.
function L.read(env)
    local rows, stats = Native.rows(env)
    if stats.supported > 0 then return rows end
    local roots = L.roots(env.id.Component, env.ui.Interfaces, env.id.Interface)
    return L.scan(roots, env.ui.ComponentType, env.id.Component)
end

function L.matching(env, spriteID)
    local result = {}
    if type(spriteID) ~= "number" or spriteID <= 0 then return result end
    for _, row in ipairs(L.read(env)) do
        if not row.identityAmbiguous and not row.nativeObjectID and row.spriteID == spriteID then result[#result + 1] = row end
    end
    return result
end

local function rootKey(component)
    return table.concat({component.interfaceID, component.staticID, component.categoryID, component.dynamicID}, ":")
end

function L.roots(componentIDs, interfaces, interfaceIDs)
    local names = L.names(componentIDs)
    local roots, seen = {}, {}
    for _, entry in ipairs(names or {}) do
        if #roots >= 96 then break end
        local success, component, key = pcall(function()
            local value = interfaces:GetComponent(entry.value)
            if not value then return nil end
            if value.interfaceID ~= math.floor(entry.value / 65536) or value.staticID ~= entry.value % 65536 then return nil end
            local prefix = entry.name:match("^(.-)__") or ""
            if prefix:find("ACTIONBAR", 1, true) or prefix:find("ACTION_BAR", 1, true) then
                -- Ascend only inside an explicitly named action-bar interface.
                for _ = 1, 12 do
                    local parent = value.parent
                    if not parent or parent.interfaceID ~= value.interfaceID then break end
                    value = parent
                end
            end
            return value, rootKey(value)
        end)
        if success and component then
            if not seen[key] then seen[key] = true; roots[#roots + 1] = component end
        end
    end
    -- The documented named Interface lookup also works without an enumerable
    -- Component index. Only inspect a positively named action-bar interface.
    for _, prefix in ipairs(L.prefixes) do
        if #roots >= 96 then break end
        local iface = L.lookup(interfaceIDs, prefix[1])
        if iface then
            local ok, component, key = pcall(function()
                local value = interfaces:GetComponent(iface, 0)
                if value and value.interfaceID == iface then return value, rootKey(value) end
            end)
            if ok and component then
                if not seen[key] then seen[key] = true; roots[#roots + 1] = component end
            end
        end
    end
    if not names and #roots == 0 then return roots, "Component index unavailable." end
    if #roots == 0 then return roots, "No named action-bar components available." end
    return roots
end

function L.scan(roots, types, componentIDs)
    local slots, labels, visited, positions, groups, count, groupCount = {}, {}, {}, {}, {}, 0, 0
    local unreadable = 0
    local _, reverse = L.names(componentIDs)
    reverse = reverse or {}
    local function observe(group, row, confidence)
        group.observations[#group.observations + 1] = {row, confidence}
        if not group.row or confidence > group.confidence then group.row, group.confidence = row, confidence end
        if row.slotNumber ~= nil then
            if group.slotNumber ~= nil and group.slotNumber ~= row.slotNumber then group.slotAmbiguous = true end
            group.slotNumber = group.slotNumber or row.slotNumber
        end
        if row.nativeObjectID then
            if group.object ~= nil and group.object ~= row.nativeObjectID then group.objectAmbiguous = true end
            if not group.object then group.object, group.objectSprite = row.nativeObjectID, row.spriteID end
        end
        if group.sprite ~= nil and group.sprite ~= row.spriteID then group.spriteAmbiguous = true end
        group.sprite = group.sprite or row.spriteID
    end
    local function addSlot(row, confidence)
        -- A native button and its inset sprite can describe one physical cell.
        -- Merge equal corners or centres only within the same named interface.
        local prefix = row.interfaceID .. ":"
        local corner = prefix .. "corner:" .. row.x .. ":" .. row.y
        local centre = prefix .. "centre:" .. (row.x + row.width / 2) .. ":" .. (row.y + row.height / 2)
        local group = positions[corner] or positions[centre]
        if not group then
            if groupCount >= 256 then return end
            group = {observations = {}, aliases = {}}
            groups[#groups + 1], groupCount = group, groupCount + 1
        end
        local other = positions[corner] and positions[centre] and positions[corner] ~= positions[centre] and positions[centre]
        if other then
            for _, observation in ipairs(other.observations) do observe(group, observation[1], observation[2]) end
            for alias in pairs(other.aliases) do positions[alias], group.aliases[alias] = group, true end
            other.retired, groupCount = true, groupCount - 1
        end
        positions[corner], positions[centre] = group, group
        group.aliases[corner], group.aliases[centre] = true, true
        observe(group, row, confidence)
    end
    local function visit(component, depth)
        if depth > 12 or count >= 2048 then return end
        local ok = pcall(function()
            local key = table.concat({ component.interfaceID, component.staticID, component.categoryID, component.dynamicID }, ":")
            if visited[key] then return end
            visited[key], count = true, count + 1
            if not component.visibleGlobal then return end
            local candidate, nativeObjectID
            local componentName = reverse[component.interfaceID * 65536 + component.staticID] or ""
            local slotNumber = tonumber(componentName:match("_SLOT_?(%d+)$"))
            if component.type == types.SPRITE then candidate = component.spriteID
            elseif component.type == types.BUTTON then candidate = component.sprite.spriteID end
            if component.type == types.SPRITE or component.type == types.BUTTON then
                local objectOK, objectID = pcall(function() return component.associatedObjectID end)
                if objectOK and U.integer(objectID, 1, 2147483647) then nativeObjectID = objectID end
            end
            if U.integer(candidate, -1, 2147483647) and (candidate > 0 or nativeObjectID or slotNumber) and component.width >= 12 and component.width <= 160
                and component.height >= 12 and component.height <= 160 then
                local xy = component.xyGlobal
                local confidence = (slotNumber ~= nil and 4 or 0) + (nativeObjectID and 2 or 0) + (component.type == types.SPRITE and 1 or 0)
                if U.finite(xy.x) and U.finite(xy.y) then
                    addSlot({x = xy.x, y = xy.y, width = component.width, height = component.height,
                        spriteID = candidate, nativeObjectID = nativeObjectID,
                        interfaceID = component.interfaceID, slotNumber = slotNumber}, confidence)
                end
            end
            if component.type == types.LABEL and U.finite(component.width) and component.width >= 0 and component.width <= 160
                and U.finite(component.height) and component.height >= 0 and component.height <= 48 then
                local packedID = component.interfaceID * 65536 + component.staticID
                local name = reverse[packedID] or ""
                -- Never trust a cached label classification after an index change.
                if name ~= "" and componentIDs[name] ~= packedID then name = "" end
                -- A cooldown number must never be guessed to be a numeric keybind.
                local keyComponent = name:find("KEYBIND", 1, true) or name:find("KEY_BIND", 1, true)
                    or name:find("HOTKEY", 1, true) or name:find("SHORTCUT", 1, true)
                    or name:find("_KEY_", 1, true) or name:match("_KEY$")
                local text = component.content
                if keyComponent and type(text) == "string" and #text > 0 and #text <= 64 then
                    local xy = component.xyGlobal
                    if U.finite(xy.x) and U.finite(xy.y) then
                        labels[#labels + 1] = { x = xy.x, y = xy.y, width = component.width,
                            height = component.height, keybind = text, interfaceID = component.interfaceID }
                    end
                end
            end
            local isCollection = false
            for name in pairs(collections) do
                if types[name] ~= nil and component.type == types[name] then isCollection = true; break end
            end
            if isCollection then
                component:IterateStaticComponents(function(child) visit(child, depth + 1); return false end)
                component:IterateDynamicComponents(function(child) visit(child, depth + 1); return false end)
            end
        end)
        -- UI components can disappear during interface changes. Skip stale proxies.
        if not ok then unreadable = unreadable + 1; return end
    end
    for _, root in ipairs(roots) do visit(root, 0) end
    for _, group in ipairs(groups) do if not group.retired then
        local row = group.row
        row.slotNumber = not group.slotAmbiguous and group.slotNumber or nil
        row.slotAmbiguous = group.slotAmbiguous or nil
        row.identityAmbiguous = group.slotAmbiguous or group.objectAmbiguous or not group.object and group.spriteAmbiguous or nil
        if row.identityAmbiguous then
            row.spriteID, row.nativeObjectID = -1, nil
        else
            row.spriteID, row.nativeObjectID = group.object and group.objectSprite or group.sprite, group.object
        end
        slots[#slots + 1] = row
    end end
    for _, slot in ipairs(slots) do
        local candidates = {}
        for _, label in ipairs(labels) do
            local cx, cy = label.x + label.width / 2, label.y + label.height / 2
            if slot.interfaceID == label.interfaceID and cx >= slot.x and cx <= slot.x + slot.width
                and cy >= slot.y and cy <= slot.y + slot.height then candidates[label.keybind] = true end
        end
        local found
        for key in pairs(candidates) do
            if found then found = nil; slot.keybindAmbiguous = true; break end
            found = key
        end
        slot.keybind = found
    end
    return slots, { nodes = count, unreadable = unreadable, limited = count >= 2048 or #slots >= 256 }
end

return L
