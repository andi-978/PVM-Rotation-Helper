-- A static, manually navigated icon sequence on our own movable overlay.
local U = require("lib/util")
local Spells = require("lib/spells")
local R = {}
function R.cells(steps, tail)
    local cells = {}
    for index, step in ipairs(steps) do
        for position, objectID in ipairs(step.switches or {}) do cells[#cells + 1] = { index = index, objectID = objectID, reminderKind = "switches", reminderPosition = position } end
        for position, reminder in ipairs(step.reminders or {}) do
            cells[#cells + 1] = {index = index, objectID = reminder.objectID, spell = reminder.spell, prayer = reminder.prayer,
                reminderKind = "reminders", reminderPosition = position}
        end
        if step.specialWeapon then cells[#cells + 1] = { index = index, objectID = step.specialWeapon, joinedNext = true } end
        if step.eof then cells[#cells + 1] = { index = index, objectID = step.eof, joinedNext = true } end
        if Spells.isIncantation(step.ability) then
            cells[#cells + 1] = {index = index, spell = step.ability, legacyAbility = true, breakAfter = step.breakAfter}
        else cells[#cells + 1] = { index = index, ability = step.ability, breakAfter = step.breakAfter } end
    end
    for position, reminder in ipairs(tail or {}) do
        cells[#cells + 1] = {objectID = reminder.objectID, spell = reminder.spell, prayer = reminder.prayer,
            reminderKind = "tailReminders", reminderPosition = position}
    end
    return cells
end
-- Pack complete joined groups before choosing a row. A special weapon and its
-- following ability never split across rows/pages; their gap is only 2 pixels.
function R.pack(cells, width, cellWidth, size)
    local rows, row, used, first = {}, {}, 0, 1
    while first <= #cells do
        local last, span = first, 0
        while cells[last].joinedNext do last = last + 1 end
        for index = first, last do span = span + (cells[index].joinedNext and size + 6 or cellWidth) end
        if used + span > width and #row > 0 then rows[#rows + 1], row, used = row, {}, 0 end
        for index = first, last do
            row[#row + 1] = { cell = index, x = used }
            used = used + (cells[index].joinedNext and size + 6 or cellWidth)
        end
        if cells[last].breakAfter then rows[#rows + 1], row, used = row, {}, 0 end
        first = last + 1
    end
    if #row > 0 then rows[#rows + 1] = row end
    return rows
end
function R.geometry(a, width)
    local size = a.nativeIconSize or 30
    local cell, caption = size + 22, false
    for _, step in ipairs(a:currentPhase().steps) do
        caption = caption or step.caption ~= ""
        if a.state.settings.showKeys then
            cell = math.max(cell, math.min(160, (U.textLength(a:stepKey(step)) or 1) * 7 + 10))
        end
    end
    local columns = math.max(1, math.min(a.state.settings.overlayWidth and 24 or a.state.settings.columns, math.floor(width / cell)))
    return { size = size, columns = columns, cell = cell,
        rowHeight = size + 12 + (a.state.settings.showKeys and 34 or 0) + (caption and 32 or 0),
        key = a.state.settings.showKeys, caption = caption }
end
function R.draw(a, w, parent, width, height, preview)
    local phase = a:currentPhase()
    if #phase.steps == 0 and #(phase.tailReminders or {}) == 0 then
        w:text(parent, 8, 12, width - 16, 80, a:t("No steps yet. Add an ability in the editor."))
        return
    end
    local g = R.geometry(a, width)
    local cells = R.cells(phase.steps, phase.tailReminders)
    local rows = R.pack(cells, width, g.cell, g.size)
    local pagerSpace = #rows > 1 and #rows * g.rowHeight > height and 32 or 0
    local needed = g.rowHeight + pagerSpace
    if height < needed then
        -- Small previews and short client viewports retain full-size art. A
        -- native clipped viewport scrolls the whole row, including its pager.
        parent:SetScrollSize(width, needed)
        parent:SetScrollPos(0, 0)
        if not w.passive then
            parent.clickthrough = false
            local scroll, maximum = 0, needed - height
            w:wheel(parent, function(_, delta)
                scroll = U.clamp(scroll + delta * 30, 0, maximum)
                parent:SetScrollPos(0, scroll)
            end)
        end
        height = needed
    end
    local perPage = math.max(1, math.floor((height - pagerSpace) / g.rowHeight))
    local pages = math.max(1, math.ceil(#rows / perPage))
    if not preview and a.revealRotation and a.selected then
        for rowIndex, row in ipairs(rows) do
            for _, slot in ipairs(row) do if cells[slot.cell].index == a.selected and cells[slot.cell].ability then a.rotationPage = math.ceil(rowIndex / perPage) end end
        end
        a.revealRotation = false
    end
    local page = U.clamp(preview and (a.previewPage or 1) or a.rotationPage, 1, pages)
    if preview then a.previewPage = page else a.rotationPage = page end
    local first = (page - 1) * perPage + 1
    for rowIndex = first, math.min(#rows, first + perPage - 1) do
        for _, slot in ipairs(rows[rowIndex]) do
            local cell = slot.cell
            local visual, index = cells[cell], cells[cell].index
            local step = phase.steps[index]
            local x, rowY = slot.x + 3, (rowIndex - first) * g.rowHeight + 3
            -- Every icon in the row shares the caption band, including passive
            -- reminders and joined special weapons. Keys stay below the art.
            local y = rowY + (g.caption and 32 or 0)
            if visual.objectID or visual.spell or visual.prayer then w:passiveTile(parent, x, y, g.size, visual)
            else
                if not a.started then
                    w:button(parent, x, y, g.size + 4, g.size + 4, "", function() a:chooseStep(index) end)
                end
                w:icon(parent, x + 2, y + 2, g.size, step.ability)
            end
            if cell < #cells and not visual.joinedNext then w:text(parent, x + g.size + 6, y + math.floor(g.size / 2) - 8, 14, 22, "›", 0xD2BC85FF) end
            if visual.ability and step.repeats > 1 then
                w:rect(parent, x + g.size - 17, y - 2, 24, 18, w.colour.panel)
                local count = a.started and a:profile().mode ~= "expert" and a.selected == index
                    and ((a.repeatIndex or 1) .. "/" .. step.repeats) or ("×" .. step.repeats)
                w:text(parent, x + g.size - 16, y - 2, 38, 20, count, w.colour.gold)
            end
            if (visual.ability or visual.legacyAbility) and step.caption ~= "" then
                local caption = w:text(parent, x - 2, rowY, g.cell - 3, 30, step.caption, w.colour.gold)
                caption.maxLines = 2
            end
            if visual.ability and g.key then w:text(parent, x - 2, y + g.size + 6, g.cell - 3, 32, a:stepKey(step), w.colour.key) end
            if visual.ability and a.started and a.focused and a:profile().mode ~= "expert" and a.selected == index then
                w:rect(parent, x, y, g.size + 4, g.size + 4, 0x58DCADFF, a.state.settings.frameWidth)
            end
        end
    end
    if pages > 1 then
        w:pager(parent, 0, height - 28, math.min(width, 240), page, pages, function(value)
            if preview then a.previewPage = value else a.rotationPage = value end
        end, "Rotation page %d/%d")
    end
end
local function navigationHeight(a, w, width)
    if #a:profile().phases <= 1 then return 0 end
    return w:buttonWidth("Previous phase") + w:buttonWidth("Next phase") + 8 > width - 20 and 62 or 34
end
function R.minimumHeight(a, w, width)
    local g = R.geometry(a, math.max(1, width - 20))
    local rows = R.pack(R.cells(a:currentPhase().steps, a:currentPhase().tailReminders), math.max(1, width - 20), g.cell, g.size)
    return math.max(160, 48 + navigationHeight(a, w, width) + g.rowHeight + (#rows > 1 and 32 or 0))
end
local function fill(a, w, root, width, height)
    local phaseNavigation = navigationHeight(a, w, width)
    local title = a:profileName() .. " · " .. a:phaseName()
    local titleHandle, titleLabel
    if w.passive then titleLabel = w:text(root, 12, 8, width - 24, 24, title)
    else titleHandle, titleLabel = w:dragHandle(root, a.overlayRoot, 0, 3, width, 30, "overlay", title) end
    local previous, following, previousWidth, nextWidth
    if phaseNavigation > 0 then
        -- Manual phase changes remain explicit clickable exceptions while the
        -- rest of the overlay passes mouse input through to the game.
        local passive = w.passive
        w.passive = false
        previousWidth, nextWidth = w:buttonWidth("Previous phase"), w:buttonWidth("Next phase")
        previous = w:button(root, 10, 38, previousWidth, 24, "Previous phase", function() a:switchPhase(-1) end, false, a.phase > 1)
        following = w:button(root, phaseNavigation == 62 and 10 or 18 + previousWidth,
            phaseNavigation == 62 and 66 or 38, nextWidth, 24, "Next phase", function() a:switchPhase(1) end, false, a.phase < #a:profile().phases)
        w.passive = passive
    end
    local content = w:layer(root, 10, 42 + phaseNavigation, width - 20, height - 48 - phaseNavigation)
    R.draw(a, w, content, width - 20, height - 48 - phaseNavigation, false)
    -- Existing icon rows/captions keep native pixel sizes during capture. The
    -- full row packing, paging and scoped controls are rebuilt once on release.
    return function(newWidth, newHeight)
        local navigation = 0
        if previous then
            navigation = previousWidth + nextWidth + 8 > newWidth - 20 and 62 or 34
            following:SetPos(navigation == 62 and 10 or 18 + previousWidth, navigation == 62 and 66 or 38)
        end
        if titleHandle then titleHandle:SetSize(newWidth, 30) end
        if titleLabel then titleLabel:SetSize(math.max(0, newWidth - 24), titleHandle and 25 or 24) end
        content:SetPos(10, 42 + navigation)
        content:SetSize(newWidth - 20, math.max(0, newHeight - 48 - navigation))
    end
end

function R.previewResize(a, window, width, height)
    local surface = a.overlaySurface
    if not surface or surface.root ~= window then return end
    window:SetSize(width, height)
    surface.resize(width, height)
    surface.host:SetSize(width, height)
    surface.content:SetSize(width, height)
    if surface.preview then surface.preview(width, height) end
end

function R.resize(a, w, window, width, height)
    local surface = a.overlaySurface
    if not surface or surface.root ~= window then return end
    local parent = a.env.parent()
    local available = parent and math.max(1, parent.height - window.y) or 900
    height = math.min(available, math.max(height, R.minimumHeight(a, w, width)))
    window:SetSize(width, height)
    surface.resize(width, height)
    surface.host:SetSize(width, height)
    if surface.scope then surface.scope.active = false end
    if surface.content then w:clearIcons(surface.content); surface.content:Destroy() end
    surface.content = w:layer(surface.host, 0, 0, width, height)
    surface.scope = { active = true }
    local previousScope = w.callbackScope
    w.callbackScope = surface.scope
    w.passive = a.state.settings.overlayClickthrough == true
    window.clickthrough = w.passive
    surface.preview = fill(a, w, surface.content, width, height)
    w.callbackScope = previousScope
    w.passive = nil
end

function R.render(a, w, parent)
    local s = a:windowSettings()
    if not a:isOverlayVisible() then return end
    -- A tiny viewport cannot contain readable rotation cells. Restore the full
    -- sequence when the user enlarges the client; controls remain in the Hub.
    if parent.width < 370 or parent.height < 180 then
        local width, height = math.min(180, parent.width), math.min(32, parent.height)
        local root = w:layer(parent, 0, 0, width, height)
        a.overlayRoot = root
        root.clickthrough = s.overlayClickthrough == true
        if width >= 32 and height >= 26 then
            w:text(root, 2, 2, width - 4, 24, a:t("Rotation"))
        end
        return
    end
    local maxWidth = parent.width - 16
    local g = R.geometry(a, maxWidth)
    local width = math.min(maxWidth, s.overlayWidth or math.max(370, g.columns * g.cell + 20))
    local rowCount = math.max(1, #R.pack(R.cells(a:currentPhase().steps, a:currentPhase().tailReminders), width - 20, g.cell, g.size))
    local phaseNavigation = navigationHeight(a, w, width)
    local height = math.min(parent.height - 20, math.max(R.minimumHeight(a, w, width),
        s.overlayHeight or (84 + phaseNavigation + rowCount * g.rowHeight)))
    local x, y = U.clamp(s.overlayX, 0, math.max(0, parent.width - width)), U.clamp(s.overlayY, 0, math.max(0, parent.height - height))
    local root = w:layer(parent, x, y, width, height)
    a.overlayRoot = root
    root.clickthrough = s.overlayClickthrough == true
    local surface = w:windowFrame(root, width, height, s.overlayOpacity / 100)
    local contentHost = w:layer(root, 0, 0, width, height)
    local content = w:layer(contentHost, 0, 0, width, height)
    surface.root, surface.host, surface.content = root, contentHost, content
    a.overlaySurface = surface
    surface.scope = { active = true }
    local previousScope = w.callbackScope
    w.callbackScope = surface.scope
    w.passive = s.overlayClickthrough == true
    surface.preview = fill(a, w, content, width, height)
    w.callbackScope = previousScope
    if not w.passive then w:resizeHandle(root, root, "overlay", surface.border) end
    w.passive = nil
end
return R
