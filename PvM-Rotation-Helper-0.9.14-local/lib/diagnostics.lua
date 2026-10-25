-- Explicit, bounded developer diagnostic. Only relevant API identifiers and
-- numeric settings/static config names are printed; no keyboard events,
-- personal IDs or player text fields.
local Locator = require("lib/locator")
local Keys = require("lib/keybinds")
local Native = require("lib/native_bars")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Identity = require("lib/item_identity")
local U = require("lib/util")
local D = {}
local function safeText(value, limit)
    return U.shortText(U.display(tostring(value):gsub("<nbsp>", " "):gsub("[%z\1-\31\127]", " ")), limit)
end
function D.run(a)
    if not a:gameParent() then a.status, a.pending = "Game interface unavailable.", true; return false end
    local ids, ui = a.env.id or {}, a.env.ui or {}
    local lines = { "API diagnostic: action bars / keybinds", "mode=" .. a:profile().mode .. " running=" .. tostring(a.started),
        "keyboard_available=" .. tostring(Keys.available(a.env)),
        "drag_hook_events=" .. tostring(a.dragEvents or 0) }
    lines[#lines + 1] = "catalogue_summary abilities=" .. #a.catalogue.items .. " live_ability_additions=" .. tostring(a.catalogue.added or 0)
        .. " item_ids=" .. #Equipment.items .. " complete_ability_books=" .. tostring(a.catalogue.membershipComplete or false)
    local currentSpells = Spells.search("", "All spellbooks", "All types", a.env.config)
    lines[#lines + 1] = "spell_reminders total=" .. #Spells.items .. " available_at_load=" .. tostring(Spells.available or 0)
        .. " current_icons=" .. #currentSpells
    for _, group in ipairs({ "Constitution", "Defence", "Melee", "Ranged", "Magic", "Necromancy" }) do
        local regular, currentIcons, selectable = 0, 0, 0
        for _, item in ipairs(a.catalogue.items) do if item.skill == group and not item.excluded then
            regular = regular + 1
            if a.catalogue.resolve(item.id, a.env.config) then
                currentIcons = currentIcons + 1
                if not item.obsoleteMembership then selectable = selectable + 1 end
            end
        end end
        lines[#lines + 1] = "ability_group=" .. group .. " regular=" .. regular .. " current_icons=" .. currentIcons .. " selectable=" .. selectable
    end
    lines[#lines + 1] = "drag_position_updates=" .. tostring(a.dragPositionUpdates or 0)
    lines[#lines + 1] = "key_subscribed=" .. tostring(a.keySubscribed or false) .. " text_form=" .. tostring(a.hasInputFields)
        .. " selected_step=" .. tostring(a.selected) .. " repeat=" .. tostring(a.repeatIndex)
    local function relevant(name)
        return type(name) == "string" and
            (name:find("ACTIONBAR", 1, true) or name:find("ACTION_BAR", 1, true) or name:find("KEYBIND", 1, true))
    end
    local function collect(label, ids, domain)
        local names, total = {}, 0
        local ok = pcall(function()
            for key, value in pairs(ids or {}) do
                total = total + 1
                local name, id = U.namedID(ids, key, value)
                if relevant(name) and type(id) == "number" then names[#names + 1] = { name = name, id = id } end
            end
        end)
        if not ok then lines[#lines + 1] = label .. ": index unavailable"; return end
        table.sort(names, function(x,y) return x.name < y.name end)
        lines[#lines + 1] = label .. ": " .. #names .. " relevant names; " .. total .. " enumerable entries"
        for i = 1, math.min(120, #names) do
            local item = names[i]
            local line = label .. "." .. item.name .. " id=" .. item.id
            -- Names alone do not establish encoding. Numeric values are evidence
            -- for a later reviewed mapping; they are not treated as game keys.
            if domain and (item.name:find("KEY", 1, true) or item.name:find("VISIBLE", 1, true)
                or item.name:find("DISPLAY", 1, true) or item.name:find("SELECT", 1, true)) then
                local read, value, kind = pcall(function()
                    local setting = domain[item.name]
                    return setting.value, setting.valueType
                end)
                if read and type(value) == "number" then line = line .. " value=" .. value .. " type=" .. tostring(kind) end
            end
            lines[#lines + 1] = line
        end
        if #names > 120 then lines[#lines + 1] = "Further entries omitted (limit 120)." end
    end
    collect("Component", ids.Component)
    Locator.invalidate()
    local known = Locator.lookup(ids.Component, "TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP")
    lines[#lines + 1] = "direct_plugin_layer_lookup=" .. tostring(known ~= nil)
    local roots, reason = Locator.roots(ids.Component, ui.Interfaces, ids.Interface)
    local slots, scan = Locator.scan(roots, ui.ComponentType or {}, ids.Component)
    lines[#lines + 1] = "named_bar_roots=" .. #roots .. " slots=" .. #slots .. " nodes=" .. scan.nodes
        .. " unreadable=" .. scan.unreadable .. " limited=" .. tostring(scan.limited)
    for i = 1, math.min(8, #roots) do
        local root = roots[i]
        local ok, interfaceID, staticID = pcall(function() return root.interfaceID, root.staticID end)
        if ok and U.integer(interfaceID, 0, 2147483647) and U.integer(staticID, 0, 65535) then
            lines[#lines + 1] = "bar_root interface=" .. interfaceID .. " static=" .. staticID
        else lines[#lines + 1] = "bar_root unavailable" end
    end
    if reason then lines[#lines + 1] = reason end
    if #roots == 0 then
        lines[#lines + 1] = "Named bar lookup unresolved. No game-slot frames or click progress can be verified. Manual key bindings remain usable."
    end
    local bars, stats = Native.read(a.env)
    lines[#lines + 1] = "native_readable_slots=" .. stats.readable .. " key_fields=" .. stats.keys .. " unavailable=" .. stats.unavailable
    for index = 1, 5 do
        local bar = bars[index]
        lines[#lines + 1] = "native_bar=" .. index .. " visible=" .. tostring(bar ~= nil)
        if bar then for slot = 1, 14 do
            local value = bar.slots[slot]
            if value then lines[#lines + 1] = "slot=" .. index .. ":" .. slot .. " sprite=" .. value.spriteID
                .. " key=" .. tostring(value.keybind) .. " xy=" .. value.x .. "," .. value.y
                .. " size=" .. value.width .. "," .. value.height
            end
        end end
    end
    local vars = a.env.variables or {}
    for index = 1, 5 do
        local suffix = index == 1 and "" or tostring(index)
        local name = "COMBATV2_ACTIONBAR_CURRENT_BAR" .. suffix
        local ok, value = pcall(function() return vars.VarPlayer[name].value end)
        if ok and type(value) == "number" then lines[#lines + 1] = name .. "=" .. value end
    end
    collect("VarClient", ids.VarClient, vars.VarClient)
    collect("VarPlayer", ids.VarPlayer, vars.VarPlayer)
    lines[#lines + 1] = "own_icon_presses=" .. (a.itemPressEvents or 0) .. " drags=" .. (a.itemDragEvents or 0) .. " drops=" .. (a.itemDropEvents or 0)
        .. " matched=" .. (a.itemDropMatches or 0)
    lines[#lines + 1] = "own_resize_begins=" .. (a.resizeBeginEvents or 0) .. " ends=" .. (a.resizeEndEvents or 0)
        .. " native_icon_size=" .. tostring(a.nativeIconSize or "fallback30")
    local ammo = 0
    for _, item in ipairs(Equipment.search("", "Weapons", "All", nil, nil, true)) do if item.ammunition then ammo = ammo + 1 end end
    lines[#lines + 1] = "catalogue_selectable weapons_ammo=" .. #Equipment.search("", "Weapons", "All", nil, nil, true)
        .. " ammunition=" .. ammo .. " special_weapons=" .. #Equipment.search("", "Special attack weapons", "All", nil, nil, true)
        .. " potions=" .. #Equipment.search("", "Potions", "All", nil, nil, true) .. " eof=" .. #Equipment.search("", "Finality amulets", "All", nil, nil, true)
    local identities = Identity.counts()
    lines[#lines + 1] = "native_item_identities reviewed=" .. identities.reviewed .. " resolved=" .. identities.resolved
        .. " unresolved=" .. identities.unresolved .. " failed=" .. identities.failed
    for _, line in ipairs(lines) do a.env.report(safeText(line, 512)) end
    a.status, a.pending = "Diagnostic printed in developer console.", true
end
return D
