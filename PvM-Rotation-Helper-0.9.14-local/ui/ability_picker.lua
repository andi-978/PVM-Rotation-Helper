-- Visible two-row categories and scoped search shared by Editor and Bindings.
local U = require("lib/util")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local C = {}
function C.render(a, w, parent, width, height, add, assignPassive)
    local extras = {"Weapons", "Ammunition", "Potions", "Spells", "Prayers"}
    local groups = U.copy(a.catalogue.groups)
    for _, group in ipairs(extras) do groups[#groups + 1] = group end
    local function choosePassive(reference)
        if assignPassive then assignPassive(reference) else Equipment.queue(a, reference) end
    end
    local weapons, ammunition, potions, spells = a.group == "Weapons", a.group == "Ammunition", a.group == "Potions", a.group == "Spells"
    if spells and a.spellbook == "Necromancy" then a.spellbook, a.spellType = "All spellbooks", "All types" end
    local prayers = a.group == "Prayers"
    local tiered, itemGroup = weapons or ammunition, weapons or ammunition or potions
    local searchWidth = assignPassive and math.min(320, math.floor(width / 2)) or math.floor(width / 2)
    local controlsTop = 68 -- Sixteen pixels below the second category row.
    local resultRoot, popup, resultScope
    local function paint()
        if resultScope then resultScope.active = false end
        if popup then popup:Destroy(); popup = nil end
        if resultRoot then w:clearIcons(resultRoot); resultRoot:Destroy() end
        local previousScope, previousPreview = w.callbackScope, w.previewRoot
        resultScope = {active = true, parent = previousScope}
        w.callbackScope = resultScope
        resultRoot = w:layer(parent, 0, 0, width, height)
        w.previewRoot = resultRoot
        local parent = resultRoot

        -- Balance measured, full labels across exactly two rows. The compact
        -- padding fits the normal editor; very narrow translated layouts retain
        -- a horizontal native scroll viewport rather than truncating names.
        local widths, split, maximum = {}, 1, math.huge
        for i, group in ipairs(groups) do widths[i] = math.ceil(w:textWidth(a:t(group))) + 16 end
        for boundary = 1, #groups - 1 do
            local left, right = 0, 0
            for i, size in ipairs(widths) do
                if i <= boundary then left = left + size + 6 else right = right + size + 6 end
            end
            if math.max(left, right) < maximum then split, maximum = boundary, math.max(left, right) end
        end
        local band = w:layer(parent, 0, 0, width, 54)
        maximum = math.max(width, maximum - 6)
        band:SetScrollSize(maximum, 54)
        a.groupScroll = U.clamp(a.groupScroll or 0, 0, maximum - width)
        band:SetScrollPos(a.groupScroll, 0)
        if maximum > width then
            band.clickthrough = false
            w:wheel(band, function(_, delta)
                a.groupScroll = U.clamp(a.groupScroll + delta * 30, 0, maximum - width)
                band:SetScrollPos(a.groupScroll, 0)
            end)
        end
        local x, y = 0, 0
        for i, group in ipairs(groups) do
            if i == split + 1 then x, y = 0, 28 end
            local button = w:button(band, x, y, widths[i], 24, group, function()
                resultScope.active = false
                a.group, a.cataloguePage = group, 1
                a.typePicker, a.weaponTierPicker = false, false
                if group == "Ammunition" then a.weaponStyle = "All" end
            end, false, true, widths[i])
            if group == a.group then button.text.rgba = w.colour.gold; w:rect(band, x, y, widths[i], 24, w.colour.gold, 1) end
            x = x + widths[i] + 6
        end
        local filterTop, resultsTop, filterWidth = controlsTop, controlsTop + 32, 170
        local leftX, rightX, rightTop = searchWidth + 8, 0, controlsTop
        local availableTypes = spells and Spells.availableTypes(a.spellbook, a.env.config, true)
            or (itemGroup or prayers) and {} or a.catalogue.availableTypes(a.group, a.state.settings.language, a.env.config)
        if not itemGroup and not prayers then
            local selected = spells and a.spellType or a.abilityType
            local exists = false
            for _, kind in ipairs(availableTypes) do exists = exists or kind == selected end
            if not exists then if spells then a.spellType = "All types" else a.abilityType = "All types" end end
        end
        local tier = tiered and (a.weaponTier or 0) or 0
        local filter = prayers and (a.prayerbook or "All prayer books") or spells and (a.spellbook or "All spellbooks")
            or tiered and (a.weaponStyle or "All") or (a.abilityType or "All types")
        local primaryLabel = spells and (a.spellType or "All types") or filter
        local primaryWidth = w:buttonWidth(primaryLabel)
        if not potions then
            w:button(parent, leftX, filterTop, filterWidth, 26, spells and (a.spellType or "All types") or filter, function()
                if spells then a.weaponTierPicker, a.typePicker = not a.weaponTierPicker, false
                else a.typePicker, a.weaponTierPicker = not a.typePicker, false end
            end)
        end
        if tiered or spells then
            local secondaryLabel = spells and filter or Equipment.tierLabel(a, tier)
            rightX = leftX + primaryWidth + 8
            if rightX + w:buttonWidth(secondaryLabel, not spells) > width then
                rightX, rightTop, resultsTop = leftX, controlsTop + 32, controlsTop + 64
            end
            w:button(parent, rightX, rightTop, filterWidth, 26, secondaryLabel, function()
                if spells then a.typePicker, a.weaponTierPicker = not a.typePicker, false
                else a.weaponTierPicker, a.typePicker = not a.weaponTierPicker, false end
            end, not spells)
        end
        local results
        if prayers then results = Prayers.search(a.query, a.prayerbook, a.env.config, a.state.settings.language)
        elseif spells then results = Spells.search(a.query, a.spellbook, a.spellType, a.env.config, a.state.settings.language, true)
        elseif itemGroup then results = Equipment.search(a.query, potions and "Potions" or ammunition and "Ammunition" or "Weapons", tiered and a.weaponStyle or "All",
            tier > 0 and tier or nil, tier > 0 and math.min(120, tier + 9) or nil, true, a.state.settings.language)
        else results = a.catalogue.search(a.query, a.group, a.state.settings.language, a.abilityType, a.env.config) end
        local size = a.nativeIconSize or 30
        local pitch, rowHeight = size + 18, size + 10
        local columns = math.max(1, math.floor(width / pitch))
        local rows = math.max(1, math.floor((height - resultsTop - 46) / rowHeight))
        local perPage = rows * columns
        local pages = math.max(1, math.ceil(#results / perPage))
        a.cataloguePage = U.clamp(a.cataloguePage, 1, pages)
        w:text(parent, 0, height - 48, width, 20, a:t("%d results", #results), w.colour.muted)
        local first = (a.cataloguePage - 1) * perPage + 1
        for i = first, math.min(#results, first + perPage - 1) do
            local item, cell = results[i], i - first
            local x, y = (cell % columns) * pitch, resultsTop + math.floor(cell / columns) * rowHeight
            if prayers then
                w:prayerButton(parent, x, y, size, item.id, function() choosePassive({prayer = item.id}) end, {prayer = item.id})
            elseif itemGroup then
                w:itemIcon(parent, x, y, size, item.objectID, function() choosePassive({objectID = item.objectID}) end, {objectID = item.objectID})
            elseif spells or item.passive then
                w:spellButton(parent, x, y, size, item.id, function() choosePassive({spell = item.id}) end, {spell = item.id})
            else w:abilityButton(parent, x, y, size, item.id, function() add(item.id) end, {ability = item.id}) end
        end
        w:pager(parent, 0, height - 28, width, a.cataloguePage, pages, function(page) a.cataloguePage = page end,
            prayers and "Prayers page %d/%d" or spells and "Spells page %d/%d" or itemGroup and "Equipment page %d/%d" or "Abilities page %d/%d")
        local choices, selected, popupX, popupY, tierLookup = nil, filter, leftX, filterTop, {}
        if a.typePicker then
            if prayers then choices = Prayers.books
            elseif spells then
                choices, popupX, popupY = {"All spellbooks"}, rightX, rightTop
                for _, book in ipairs(Spells.books) do
                    if book ~= "All spellbooks" and #Spells.search("", book, nil, a.env.config, nil, true) > 0 then choices[#choices + 1] = book end
                end
            elseif tiered then choices = {"All", "Melee", "Ranged", "Magic", "Necromancy"}
            else choices = availableTypes end
        elseif a.weaponTierPicker then
            if spells then choices, selected = availableTypes, a.spellType
            elseif tiered then
                choices, selected, popupX, popupY = {}, Equipment.tierLabel(a, tier), rightX, rightTop
                for _, value in ipairs(Equipment.tiers) do
                    local label = Equipment.tierLabel(a, value)
                    choices[#choices + 1], tierLookup[label] = label, value
                end
            end
        end
        if choices then
            popup = w:dropdown(parent, popupX, popupY, filterWidth, choices, selected, function(choice)
                if prayers then a.prayerbook = choice
                elseif spells and a.weaponTierPicker then a.spellType = choice
                elseif tiered and a.weaponTierPicker then a.weaponTier = tierLookup[choice]
                elseif spells then a.spellbook, a.spellType = choice, "All types"
                elseif tiered then a.weaponStyle = choice else a.abilityType = choice end
                a.typePicker, a.weaponTierPicker, a.cataloguePage = false, false, 1
            end)
        end
        w.previewRoot, w.callbackScope = previousPreview, previousScope
    end
    local search = w:field(parent, 0, controlsTop, searchWidth, 26, nil, "search", a.query, 80, function(value)
        a.query, a.cataloguePage = value, 1
        paint()
    end)
    a.query = search.content
    paint()
end
return C
