-- Read-only, slot-preserving access to the five native combat-bar interfaces.
-- Names come from the user's official `pan Component` export, 22 October 2026.
-- No numeric component IDs, screenshot OCR or packed key-code guesses.
local U = require("lib/util")
local N = {}
N.prefixes = { "TOPLEVEL_V2_COMBAT_BAR", "TOPLEVEL_V2_COMBAT_BAR2", "TOPLEVEL_V2_COMBAT_BAR3",
    "TOPLEVEL_V2_COMBAT_BAR4", "TOPLEVEL_V2_COMBAT_BAR5" }

function N.component(env, name)
    local ok, component = pcall(function()
        local packed = env.id.Component[name]
        if type(packed) ~= "number" or packed <= 0 or packed % 1 ~= 0 then return nil end
        local value = env.ui.Interfaces:GetComponent(packed)
        if value and value.interfaceID == math.floor(packed / 65536) and value.staticID == packed % 65536 then return value end
    end)
    if ok then return component end
end

function N.read(env)
    local bars, stats = {}, { readable = 0, unavailable = 0, keys = 0, supported = 0 }
    for index, prefix in ipairs(N.prefixes) do
        local root = N.component(env, prefix .. "__COMBAT_BAR_ROOT")
        if root then stats.supported = stats.supported + 1 end
        local presetOK, preset = pcall(function()
            local suffix = index == 1 and "" or tostring(index)
            return env.variables.VarPlayer["COMBATV2_ACTIONBAR_CURRENT_BAR" .. suffix].value
        end)
        -- A root can expire after component lookup. Snapshot its identity with
        -- visibility so one stale bar cannot abort the independently read bars.
        local ok, visible, interfaceID = pcall(function()
            if root then return root.visibleGlobal, root.interfaceID end
        end)
        -- In this beta even unused interface templates report visibleGlobal.
        -- CURRENT_BAR=0 means no preset displayed; decoded VarType.value avoids
        -- guessing the packed storage layout. Unavailable metadata fails closed.
        if ok and visible and U.integer(interfaceID, 1, 65535) and presetOK
            and type(preset) == "number" and preset >= 1 and preset <= 18 and preset % 1 == 0 then
            local bar = { slots = {}, interfaceID = interfaceID }
            bars[index] = bar
            for slot = 1, 14 do
                local graphic = N.component(env, prefix .. "__GRAPHIC_" .. slot)
                local label = N.component(env, prefix .. "__TEXT_" .. slot)
                local read, value = pcall(function()
                    if not graphic or not graphic.visibleGlobal or graphic.type ~= env.ui.ComponentType.SPRITE then return nil end
                    local sprite, xy = graphic.spriteID, graphic.xyGlobal
                    local x, y, width, height = xy.x, xy.y, graphic.width, graphic.height
                    if not U.integer(sprite, -1, 2147483647) or not U.finite(x) or not U.finite(y)
                        or not U.finite(width) or width < 12 or width > 160
                        or not U.finite(height) or height < 12 or height > 160 then return nil end
                    local objectOK, objectID = pcall(function() return graphic.associatedObjectID end)
                    local nativeObjectID = objectOK and type(objectID) == "number" and objectID >= 1
                        and objectID <= 2147483647 and objectID % 1 == 0 and objectID or nil
                    return { spriteID = sprite, nativeObjectID = nativeObjectID, slotNumber = slot, barIndex = index, interfaceID = interfaceID,
                        x = x, y = y, width = width, height = height }
                end)
                if read and value then
                    -- TEXT_n is the native key field. TEXT_n_COOLDOWN is a
                    -- different named component and is never read here.
                    local keyOK, key = pcall(function()
                        if label and label.type == env.ui.ComponentType.LABEL then return label.content end
                    end)
                    if keyOK and type(key) == "string" and #key <= 64 then
                        value.keybind = key
                        if key ~= "" then stats.keys = stats.keys + 1 end
                    end
                    bar.slots[slot], stats.readable = value, stats.readable + 1
                else stats.unavailable = stats.unavailable + 1 end
            end
        end
    end
    return bars, stats
end

function N.rows(env)
    local rows = {}
    local bars, stats = N.read(env)
    for _, bar in pairs(bars) do for _, slot in pairs(bar.slots) do rows[#rows + 1] = slot end end
    return rows, stats
end
return N
