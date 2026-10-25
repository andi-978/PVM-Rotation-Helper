-- Explicit item reminders on a selected ability, with native client item art.
local E = require("lib/equipment")
local U = require("lib/util")
local P = {}
local styles = { "All", "Melee", "Ranged", "Magic", "Necromancy" }
function P.render(a, w, parent, width, height)
    local selectedIndex = a.selected or a.insertAfter
    local step = selectedIndex and a:currentPhase().steps[selectedIndex]
    if not step or step.ability ~= E.SPECIAL and step.ability ~= E.FINALITY then
        a.equipmentPicker = false
        return false
    end
    local kinds = { "Special attack weapons" }
    if step.ability == E.FINALITY then kinds[#kinds + 1] = "Finality amulets" end
    local allowed = false
    for _, kind in ipairs(kinds) do allowed = allowed or a.equipmentKind == kind end
    if not allowed then a.equipmentKind = kinds[1] end
    a.equipmentStyle, a.equipmentTier = a.equipmentStyle or "All", a.equipmentTier or 0
    local iconSize = a.nativeIconSize or 30
    local headerHeight = math.max(28, iconSize)
    local kindTop, filterTop, searchTop, resultsTop = headerHeight + 6, headerHeight + 40, headerHeight + 72, headerHeight + 100
    w:button(parent, 0, 0, 38, 28, "<-", function() a.equipmentPicker = false end, true)
    w:icon(parent, 46, 0, iconSize, step.ability)
    local offset, clearX = 54 + iconSize, width - w:buttonWidth("Clear reminders")
    local chain = w:layer(parent, offset, 0, math.max(1, clearX - offset - 8), headerHeight + 4)
    local entries = {}
    for _, objectID in ipairs(step.switches or {}) do entries[#entries + 1] = {objectID = objectID} end
    for _, reminder in ipairs(step.reminders or {}) do entries[#entries + 1] = reminder end
    if step.specialWeapon then entries[#entries + 1] = {objectID = step.specialWeapon} end
    if step.eof then entries[#entries + 1] = {objectID = step.eof} end
    local pitch = iconSize + 8
    for index, reminder in ipairs(entries) do
        if reminder.objectID then w:itemIcon(chain, (index - 1) * pitch, 0, iconSize, reminder.objectID)
        elseif reminder.prayer then w:prayerIcon(chain, (index - 1) * pitch + 2, 2, iconSize, reminder.prayer)
        else w:spellIcon(chain, (index - 1) * pitch + 2, 2, iconSize, reminder.spell) end
    end
    local maximum = math.max(0, #entries * pitch - chain.width)
    chain:SetScrollSize(math.max(chain.width, #entries * pitch), chain.height)
    if maximum > 0 then
        local scroll = 0
        chain.clickthrough = false
        w:wheel(chain, function(_, delta)
            scroll = U.clamp(scroll + delta * pitch, 0, maximum); chain:SetScrollPos(scroll, 0)
        end)
    end
    w:button(parent, clearX, 0, 126, 28, "Clear reminders", function()
        a:change(function(_, p)
            local item = p.phases[a.phase].steps[selectedIndex]
            item.switches, item.reminders, item.specialWeapon, item.eof = nil, nil, nil, nil
        end)
    end, false, #entries > 0)
    local third = 220
    for index, kind in ipairs(kinds) do
        w:button(parent, (index - 1) * (third + 6), kindTop, third, 28,
            (kind == a.equipmentKind and "• " or "") .. a:t(kind), function()
                a.equipmentKind, a.equipmentPage = kind, 1
                a.equipmentStylePicker, a.equipmentTierPicker = false, false
            end, true)
    end
    local control = 170
    w:button(parent, 0, filterTop, control, 26, a.equipmentStyle, function()
        a.equipmentStylePicker = not a.equipmentStylePicker; a.equipmentTierPicker = false
    end, false, a.equipmentKind ~= "Finality amulets")
    w:button(parent, control + 6, filterTop, control, 26, E.tierLabel(a, a.equipmentTier), function()
        a.equipmentTierPicker = not a.equipmentTierPicker; a.equipmentStylePicker = false
    end, true, a.equipmentKind ~= "Finality amulets")
    local resultRoot, resultScope
    local function paint()
        if resultScope then resultScope.active = false end
        if resultRoot then w:clearIcons(resultRoot); resultRoot:Destroy() end
        local previousScope = w.callbackScope
        resultScope = {active = true, parent = previousScope}
        w.callbackScope = resultScope
        resultRoot = w:layer(parent, 0, resultsTop, width, math.max(1, height - resultsTop))
        local parent = resultRoot
        local height = height - resultsTop
        local tier = a.equipmentKind ~= "Finality amulets" and a.equipmentTier or 0
        local found = E.search(a.equipmentQuery, a.equipmentKind, a.equipmentStyle,
            tier > 0 and tier or nil, tier > 0 and math.min(120, tier + 9) or nil, true, a.state.settings.language)
        local size = a.nativeIconSize or 30
        local pitch, rowHeight = size + 14, size + 10
        local columns, rows = math.max(1, math.floor(width / pitch)), math.max(1, math.floor((height - 66) / rowHeight))
        local perPage = columns * rows
        local pages = math.max(1, math.ceil(#found / perPage))
        a.equipmentPage = U.clamp(a.equipmentPage or 1, 1, pages)
        w:text(parent, 0, height - 58, width, 26, a:t("%d results", #found), w.colour.muted)
        local first = (a.equipmentPage - 1) * perPage + 1
        for index = first, math.min(#found, first + perPage - 1) do
            local item, cell = found[index], index - first
            w:itemIcon(parent, (cell % columns) * pitch, 4 + math.floor(cell / columns) * rowHeight, size, item.objectID, function()
                E.attach(a, item.objectID, a.equipmentKind)
            end)
        end
        w:pager(parent, 0, height - 28, width, a.equipmentPage, pages,
            function(page) a.equipmentPage = page end, "Equipment page %d/%d")
        w.callbackScope = previousScope
    end
    local search = w:field(parent, 0, searchTop, width, 26, nil, "equipmentSearch", a.equipmentQuery or "", 80, function(value)
        a.equipmentQuery, a.equipmentPage = value, 1
        paint()
    end)
    a.equipmentQuery = search.content
    paint()
    if a.equipmentStylePicker or a.equipmentTierPicker then
        local isTier = a.equipmentTierPicker
        local choices, lookup = {}, {}
        for _, choice in ipairs(isTier and E.tiers or styles) do
            local label = isTier and E.tierLabel(a, choice) or choice
            choices[#choices + 1], lookup[label] = label, choice
        end
        local selected = isTier and E.tierLabel(a, a.equipmentTier) or a.equipmentStyle
        local function close() a.equipmentStylePicker, a.equipmentTierPicker = false, false end
        w:dropdown(parent, isTier and control + 6 or 0, filterTop, control, choices, selected, function(label)
            if isTier then a.equipmentTier = lookup[label] else a.equipmentStyle = lookup[label] end
            close(); a.equipmentPage = 1
        end)
    end
    return true
end
return P
