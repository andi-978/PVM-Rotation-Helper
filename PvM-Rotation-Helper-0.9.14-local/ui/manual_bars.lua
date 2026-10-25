-- Graphical main/additional bar corrections. Never changes the game's binds.
local M = require("lib/model")
local U = require("lib/util")
local Bars = require("lib/action_bars")
local Picker = require("ui/ability_picker")
local X = require("lib/interaction")
local Diagnostics = require("lib/diagnostics")
local Keys = require("lib/keybinds")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local B = {}
local function unknownIcon(a, w, parent, size, barIndex, slotIndex)
    local bar = a.detectedBars and a.detectedBars[barIndex]
    local observed = bar and bar.slots and bar.slots[slotIndex]
    local objectID, spriteID = observed and observed.nativeObjectID, observed and observed.spriteID
    local icon
    if U.integer(objectID, 1, 2147483647) or U.integer(spriteID, 1, 2147483647) then
        icon = w.ui.Sprite.new(parent)
        icon:SetPos(2, 2); icon:SetSize(size, size)
        if U.integer(objectID, 1, 2147483647) then
            icon:SetAssociatedObject(objectID)
            icon.associatedObjectQuantity = 1
            icon.associatedObjectQuantityMode = w.ui.ObjectQuantityDisplayMode.NEVER
        else icon.sprite = spriteID end
        icon.clickthrough, icon.alpha, icon.rgba = true, 1, 0xFFFFFFFF
    else icon = w:text(parent, 2, 2, size, size, "?", w.colour.muted) end
    w:hover(icon, function() return a:t("Unrecognized action") end)
end
function B.render(a, w, body, width, height)
    local count = math.max(1, #a:profile().bars)
    local indices = a:profile().activeBars or {}
    if #indices == 0 then
        indices = {}
        for barIndex = 1, count do indices[#indices + 1] = barIndex end
    end
    local position = 1
    for i, barIndex in ipairs(indices) do
        if barIndex == a.manualBar then position = i end
    end
    a.manualBar = indices[position]
    a.manualBar = U.clamp(a.manualBar or 1, 1, count)
    a.manualSlot = U.clamp(a.manualSlot or 1, 1, 14)
    local barIndex, slotIndex = a.manualBar, a.manualSlot
    local bar = a:profile().bars[barIndex] or M.newBar()
    local slot = bar.slots[slotIndex] or { ability = "", key = "" }
    local function change(callback)
        return a:change(function(_, p)
            Bars.ensure(p, count)
            p.activeBars = U.copy(indices)
            p.bars[barIndex].enabled = true
            callback(p.bars[barIndex], p)
        end)
    end
    w:button(body, 0, 0, 92, 24, "Diagnose", function() Diagnostics.run(a) end)
    w:button(body, w:buttonWidth("Diagnose") + 8, 0, 100, 24, "Detect", function() Bars.detect(a) end)
    -- Page every stored bar. Narrow panels need fewer tabs for translated names.
    local tabWidth = 160
    local perPage = math.max(1, math.floor((width - 68) / (tabWidth + 6)))
    local barPage = math.floor((position - 1) / perPage)
    local first = barPage * perPage + 1
    local number = math.min(perPage, #indices - first + 1)
    local margin = #indices > perPage and 34 or 0
    if #indices > perPage then
        w:button(body, 0, 36, 28, 28, "‹", function() a:selectBarSlot(indices[math.max(1, first - perPage)], a.manualSlot) end, true, first > 1)
        w:button(body, margin + number * (tabWidth + 6), 36, 28, 28, "›", function()
            a:selectBarSlot(indices[math.min(#indices, first + perPage)], a.manualSlot)
        end, true, first + perPage <= #indices)
    end
    for i = first, first + number - 1 do
        local tabIndex = indices[i]
        local label = tabIndex == 1 and a:t("Main bar") or a:t("Additional %d", tabIndex - 1)
        w:button(body, margin + (i-first)*(tabWidth + 6), 36, tabWidth, 24,
            (tabIndex == barIndex and "• " or "") .. label, function() a:selectBarSlot(tabIndex, 1) end, true, true, tabWidth)
    end
    local iconSize = a.nativeIconSize or 30
    local cell = iconSize + 8
    local columns = math.max(1, math.min(14, math.floor(width / cell)))
    local rows = math.ceil(14 / columns)
    for i = 1, 14 do
        local value, x = bar.slots[i] or { ability = "", key = "" }, ((i-1) % columns)*cell
        local y = 76 + math.floor((i-1) / columns) * (cell + 34)
        local container = w:layer(body, x, y, iconSize+4, iconSize+4)
        local c = w:button(container, 0, 0, iconSize+4, iconSize+4, "", function() a:selectBarSlot(barIndex, i) end, true)
        local name
        if value.objectID then name = function() return Equipment.name(value.objectID, a.state.settings.language) end
        elseif value.spell then name = function() return Spells.name(value.spell, a.state.settings.language) end
        elseif value.prayer then name = function() return Prayers.name(value.prayer, a.state.settings.language) end
        elseif value.ability and value.ability ~= "" then name = function() return a:abilityName(value.ability) end
        elseif value.unknown then name = function() return a:t("Unrecognized action") end end
        if name then w:hover(c, name) end
        local inset = 2
        if value.objectID then w:itemIcon(container, 0, 0, iconSize, value.objectID)
        elseif value.spell then w:spellIcon(container, inset, inset, iconSize, value.spell)
        elseif value.prayer then w:prayerIcon(container, inset, inset, iconSize, value.prayer)
        elseif value.ability and value.ability ~= "" then w:icon(container, inset, inset, iconSize, value.ability)
        elseif value.unknown then unknownIcon(a, w, container, iconSize, barIndex, i) end
        a.iconContainers = a.iconContainers or {}; a.iconContainers[c] = container
        if slotIndex == i then w:rect(body, x, y, iconSize+4, iconSize+4, 0x55E39BFF, 2) end
        w:text(body, x, y+cell+2, cell-2, 34, value.key ~= "" and Keys.display(value.key, a.state.settings.language) or "-", w.colour.key)
        X.target(a, c, function(payload)
            local reference = payload.objectID and {objectID = payload.objectID} or payload.spell and {spell = payload.spell}
                or payload.prayer and {prayer = payload.prayer} or payload.ability
            if reference and a:assignBarSlot(barIndex, i, reference) then a.manualSlot = i end
        end)
    end
    local tools = 86 + rows * (cell + 34)
    -- A normal native field: no temporary global key listener or menu mutation.
    -- Slot-specific drafts survive redraws without leaking into another slot.
    local draft = "binding_" .. barIndex .. "_" .. slotIndex
    local assignWidth, clearWidth = w:buttonWidth("Assign key binding"), w:buttonWidth("Clear slot")
    -- Key labels need a compact input, not the full width of a large window.
    -- The supported 536px body still reserves both translated fixed buttons.
    local fieldWidth = math.min(180, width - assignWidth - clearWidth - 16)
    local field = w:field(body, 0, tools, fieldWidth, 28, nil, draft, slot.key, 30)
    w:button(body, fieldWidth + 8, tools, assignWidth, 24, "Assign key binding", function()
        local label = field.content:match("^%s*(.-)%s*$")
        if label ~= "" and not Keys.parse(label, a.env.gameKeys) then
            a.status = "Use a key such as Q, Shift+W or Ctrl+1."; return
        end
        if change(function(target) target.slots[slotIndex].key = label end) then a.drafts[draft] = nil end
    end)
    w:button(body, fieldWidth + assignWidth + 16, tools, clearWidth, 24, "Clear slot", function()
        if a:clearBarSlot(barIndex, slotIndex) then a.drafts[draft] = nil end
    end)
    local top = tools + 36
    -- All manual controls stay available at the smallest supported window.
    -- Scroll the body rather than hiding its ability catalogue when bars wrap.
    local catalogueHeight = math.max(iconSize + 184, height - top)
    local total = top + catalogueHeight
    body:SetScrollSize(width, math.max(height, total))
    a.bindingsScroll = U.clamp(a.bindingsScroll or 0, 0, math.max(0, total - height))
    body:SetScrollPos(0, a.bindingsScroll)
    if total > height then
        body.clickthrough = false
        w:wheel(body, function(_, delta)
            a.bindingsScroll = U.clamp(a.bindingsScroll + delta * 30, 0, total - height)
            body:SetScrollPos(0, a.bindingsScroll)
        end)
    end
    local catalogue = w:layer(body, 0, top, width, catalogueHeight)
    Picker.render(a, w, catalogue, width, catalogueHeight, function(ability)
        a:assignBarSlot(barIndex, slotIndex, ability)
    end, function(reference)
        a:assignBarSlot(barIndex, slotIndex, reference)
    end)
end
return B
