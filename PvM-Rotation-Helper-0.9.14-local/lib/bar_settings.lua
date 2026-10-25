-- Read-only import from an OPEN native Controls/Action Bar settings pane.
-- Exact visible labels identify bar/slot; arbitrary numeric vars are not decoded.
local Keys = require("lib/keybinds")
local L = require("lib/locator")
local U = require("lib/util")
local S = {}
function S.read(env)
    local roots, seen, nodes, count = {}, {}, {}, 0
    pcall(function() for key, value in pairs(env.id.Component) do
        local name, id = U.namedID(env.id.Component, key, value)
        if name and id > 0 and
            (name:find("SETTINGS", 1, true) or name:find("KEYBIND", 1, true) or name:find("CONTROLS", 1, true)) then
            local ok, root = pcall(function()
                local c = env.ui.Interfaces:GetComponent(id)
                if not c or c.interfaceID ~= math.floor(id / 65536) or c.staticID ~= id % 65536 then return nil end
                for _ = 1, 14 do
                    if not c.parent or c.parent.interfaceID ~= c.interfaceID then break end
                    c = c.parent
                end
                return c
            end)
            if ok and root and not seen[root] then seen[root] = true; roots[#roots + 1] = root end
        end
    end end)
    -- As with bars, named Interface access does not depend on pairs(id.Component).
    for _, name in ipairs({ "SETTINGS_CONTROLS", "SETTINGS_KEYBINDS", "SETTINGS_ACTIONBAR" }) do
        local iface = L.lookup(env.id.Interface, name)
        if iface then
            local ok, root = pcall(function()
                local value = env.ui.Interfaces:GetComponent(iface, 0)
                if value and value.interfaceID == iface then return value end
            end)
            if ok and root and not seen[root] then
                seen[root] = true; roots[#roots + 1] = root
            end
        end
    end
    local function visit(c, depth)
        if depth > 14 or count >= 4096 or seen[c] == "visited" then return end
        seen[c], count = "visited", count + 1
        pcall(function()
            if not c.visibleGlobal then return end
            local kind = c.type
            if kind == env.ui.ComponentType.LABEL or kind == env.ui.ComponentType.BUTTON then
                local text = kind == env.ui.ComponentType.BUTTON and c.label or c.content
                if type(text) == "string" and #text <= 120 then
                    local xy = c.xyGlobal
                    if U.finite(xy.x) and U.finite(xy.y) and U.finite(c.width) and c.width >= 0
                        and U.finite(c.height) and c.height >= 0 then
                        nodes[#nodes + 1] = { text = text:gsub("<[^>]*>", ""):gsub("%s+", " "),
                            x = xy.x, y = xy.y, width = c.width, height = c.height, interfaceID = c.interfaceID, kind = kind }
                    end
                end
            end
            if kind == env.ui.ComponentType.LAYER or kind == env.ui.ComponentType.PANEL
                or kind == env.ui.ComponentType.GRID or kind == env.ui.ComponentType.GROUP_BOX then
                c:IterateStaticComponents(function(child) visit(child, depth + 1); return false end)
                c:IterateDynamicComponents(function(child) visit(child, depth + 1); return false end)
            end
        end)
    end
    for _, root in ipairs(roots) do visit(root, 0) end
    local result = { keys = {}, visible = {} }
    local conflicts = {}
    for _, label in ipairs(nodes) do
        local bar, slot
        slot = label.text:match("^Main Action Bar: Slot (%d+)$")
        if slot then bar = 1 else
            local additional; additional, slot = label.text:match("^Additional Action Bar (%d+): Slot (%d+)$")
            if additional and tonumber(additional) >= 1 and tonumber(additional) <= 4 then bar = tonumber(additional) + 1 end
        end
        local additional = label.text:match("^[Aa]dditional action bar (%d+)$")
        if (bar and tonumber(slot) >= 1 and tonumber(slot) <= 14) or additional then
            local candidates, values, empty = {}, {}, false
            for _, value in ipairs(nodes) do
                if value.interfaceID == label.interfaceID
                    and value.x >= label.x + label.width - 4 and value.x <= label.x + label.width + 260
                    and math.abs(value.y + value.height / 2 - label.y - label.height / 2) <= 5 then
                    -- Game-cache UI may expose a text label rather than the
                    -- high-level Button type. Count repeated text only once.
                    if value.text == "" and value.kind == env.ui.ComponentType.BUTTON then empty = true
                    elseif value.text ~= "" then values[value.text] = true end
                end
            end
            for value in pairs(values) do candidates[#candidates + 1] = value end
            if #candidates == 0 and empty then candidates[1] = "" end
            if #candidates == 1 then
                if bar and (candidates[1] == "" or Keys.parse(candidates[1], env.gameKeys)) then
                    result.keys[bar], conflicts[bar] = result.keys[bar] or {}, conflicts[bar] or {}
                    local index, value = tonumber(slot), candidates[1]
                    local previous = result.keys[bar][index]
                    if previous ~= nil and previous ~= value then result.keys[bar][index], conflicts[bar][index] = nil, true
                    elseif not conflicts[bar][index] then result.keys[bar][index] = value end
                elseif additional then
                    local index = tonumber(additional) + 1
                    if index >= 2 and index <= 5 then
                        if candidates[1] == "Bar not displayed" then result.visible[index] = false
                        else
                            local preset = tonumber(candidates[1]:match("^(%d+): Action Bar Preset %d+$"))
                            if preset and preset >= 1 and preset <= 18 then
                                result.visible[index] = true
                            end
                        end
                    end
                end
            end
        end
    end
    return result
end
return S
