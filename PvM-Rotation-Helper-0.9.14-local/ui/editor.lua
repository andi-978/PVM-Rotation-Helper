-- Edit phase steps and attach passive reminders to their next ability.
local U = require("lib/util")
local Model = require("lib/model")
local Picker = require("ui/ability_picker")
local X = require("lib/interaction")
local EquipmentPicker = require("ui/equipment_picker")
local Rotation = require("ui/rotation")
local Equipment = require("lib/equipment")
local E = {}
local function reminderExists(phase, source)
    if type(source) ~= "table" or not U.integer(source.position, 1, 8) then return false end
    local owner
    if source.kind == "tailReminders" then
        if source.index ~= #phase.steps + 1 then return false end
        owner = phase
    elseif source.kind == "reminders" or source.kind == "switches" then
        if not U.integer(source.index, 1, #phase.steps) then return false end
        owner = phase.steps[source.index]
    end
    return owner ~= nil and owner[source.kind] ~= nil and owner[source.kind][source.position] ~= nil
end
function E.render(a, w, body, width, height)
    local phase = a:currentPhase()
    if a.selectedReminder and not reminderExists(phase, a.selectedReminder) then
        a.selectedReminder, a.revealReminder = nil, nil
    end
    -- The assisted cursor is cleared by Stop/focus loss. The editor's green
    -- insertion mark remains and is still a valid details/delete target.
    local selectedIndex = a.selected or a.insertAfter
    local selected = selectedIndex and phase.steps[selectedIndex]
    if a.equipmentPicker and selected then
        if EquipmentPicker.render(a, w, body, width, height) then return end
    end
    if a.editingStep and selected then
        local rightX, right = 0, width
        local index = selectedIndex
        local iconSize = a.nativeIconSize or 30
        local textX, fieldsTop = 54 + iconSize, math.max(34, iconSize) + 8
        w:button(body, rightX, 0, 38, 28, "‹", function() a.editingStep = false end)
        w:icon(body, rightX + 46, 0, iconSize, selected.ability)
        w:text(body, rightX + textX, 0, right - textX, 34, a:abilityName(selected.ability), w.colour.gold)
        local key = w:field(body, rightX, fieldsTop, right - 90, 26, "Key label", "stepKey", selected.key, 30)
        local repeats = w:field(body, width - 82, fieldsTop, 82, 26, "Repeats", "stepRepeat", selected.repeats, 2)
        local caption = w:field(body, rightX, fieldsTop + 62, right, 26, "Caption", "stepCaption", selected.caption, 160)
        w:button(body, rightX, fieldsTop + 128, right, 26, selected.breakAfter and "Row break: ON" or "Row break: OFF", function()
            a:change(function(_, p) p.phases[a.phase].steps[index].breakAfter = not p.phases[a.phase].steps[index].breakAfter end)
        end)
        w:button(body, rightX, height - 32, right, 28, "Save", function()
            if a:change(function(_, p)
                local step = p.phases[a.phase].steps[index]
                step.key, step.caption, step.repeats = key.content, caption.content, tonumber(repeats.content)
            end) then a.editingStep, a.drafts.stepKey, a.drafts.stepCaption, a.drafts.stepRepeat = false, nil, nil, nil end
        end)
        return
    end
    w:button(body, 0, 0, 28, 28, "‹", function() a:switchPhase(-1) end, true, a.phase > 1)
    local phaseName = a:phaseName(phase)
    local headingWidth = math.min(140, math.ceil(w:textWidth(phaseName)) + 12)
    local heading = w:text(body, 36, 3, headingWidth, 25, phaseName, w.colour.gold)
    heading.maxLines = 1
    local nextX = 44 + headingWidth
    w:button(body, nextX, 0, 28, 28, "›", function() a:switchPhase(1) end, true, a.phase < #a:profile().phases)
    local actionsX = nextX + 48
    local phasesBottom = w:buttonRow(body, actionsX, 0, width - actionsX, {
        { label = "Add phase", enabled = #a:profile().phases < Model.LIMIT.phases, click = function()
        if a:change(function(_, p)
            assert(#p.phases < Model.LIMIT.phases, "Maximum 12 phases.")
            local used, number = {}, #p.phases + 1
            for _, existing in ipairs(p.phases) do used[a:phaseName(existing)] = true end
            while used[a:t("Phase %d", number)] do number = number + 1 end
            p.phases[#p.phases + 1] = { name = a:t("Phase %d", number), steps = {} }
        end) then a.phase = #a:profile().phases; a:resetContext() end
        end },
        { label = "Delete phase", enabled = a.phase > 1, click = function()
        local index = a.phase
        a:confirm("Delete this phase and its steps?", function()
            a:deletePhase(index)
        end)
        end },
    })
    local controlsBottom = w:buttonRow(body, actionsX, phasesBottom + 6, width - actionsX, {
        { label = "Edit details", enabled = selected ~= nil and not a.selectedReminder, click = function()
            if not a.selectedReminder then a.editingStep = true end
        end },
        { label = a.selectedReminder and "Delete reminder" or "Delete step", enabled = a.selectedReminder ~= nil or selected ~= nil, click = function()
            if a.selectedReminder then Equipment.removeReminder(a, a.selectedReminder) else a:deleteStep(selectedIndex) end
        end },
    })
    local iconsTop = controlsBottom + 10
    local steps = phase.steps
    local cells = Rotation.cells(steps, phase.tailReminders)
    local iconSize = a.nativeIconSize or 30
    -- One complete native-sized row and its pager must never share pixels.
    local maximumBlock = math.max(iconSize + 40, math.min(116, math.max(60, height - 244)))
    local rows = Rotation.pack(cells, width, iconSize + 24, iconSize)
    local rowHeight = iconSize + 12
    local perPage = math.max(1, math.floor((maximumBlock - 24) / rowHeight))
    -- Reserve only occupied rows and the shared pager/count line. Short
    -- rotations should give their spare vertical space to the catalogue.
    local block = math.min(perPage, math.max(1, #rows)) * rowHeight + 24
    local pages = math.max(1, math.ceil(#rows / perPage))
    if a.revealStep and a.selected then
        for rowIndex, row in ipairs(rows) do
            for _, slot in ipairs(row) do
                local visual = cells[slot.cell]
                if visual.index == a.selected and (visual.ability or visual.legacyAbility) then
                    a.stepListPage = math.ceil(rowIndex / perPage)
                end
            end
        end
        a.revealStep = false
    end
    if a.revealReminder and a.selectedReminder then
        local selected = a.selectedReminder
        for rowIndex, row in ipairs(rows) do
            for _, slot in ipairs(row) do
                local visual = cells[slot.cell]
                if visual.reminderKind == selected.kind and visual.reminderPosition == selected.position
                    and (visual.index or #steps + 1) == selected.index then a.stepListPage = math.ceil(rowIndex / perPage) end
            end
        end
        a.revealReminder = nil
    end
    a.stepListPage = U.clamp(a.stepListPage, 1, pages)
    local function drop(after, payload, target, position)
        if payload.reminderSource then
            Equipment.moveReminder(a, payload.reminderSource, target or #steps + 1, position)
        elseif payload.index then
            -- Moving onto a later icon takes its position (after that icon),
            -- rather than inserting before the immediate neighbour unchanged.
            local boundary = after >= payload.index and math.min(#steps, after + 1) or after
            a:moveStepTo(payload.index, boundary)
        elseif payload.objectID or payload.spell or payload.prayer then
            local reminder = {objectID = payload.objectID, spell = payload.spell, prayer = payload.prayer}
            Equipment.queue(a, reminder, target or #steps + 1, position)
        else a:addAbility(payload.ability, after) end
    end
    -- Empty sequence space remains a drop target without another button.
    local appendArea = w:layer(body, 0, iconsTop, width, math.max(1, block - 24))
    X.target(a, appendArea, function(payload) drop(#steps, payload) end)
    local first = (a.stepListPage - 1) * perPage + 1
    for rowIndex = first, math.min(#rows, first + perPage - 1) do for _, slot in ipairs(rows[rowIndex]) do
        local position = slot.cell
        local visual = cells[position]
        local index = visual.index
        local step = steps[index]
        local x, y = slot.x, iconsTop + (rowIndex - first) * rowHeight
        local c
        local reminderSource = visual.reminderKind and {index = index or #steps + 1, kind = visual.reminderKind, position = visual.reminderPosition}
        local function select()
            if reminderSource then
                a.selectedReminder, a.pending = reminderSource, true
                return
            end
            a:chooseStep(index)
        end
        local payload = reminderSource and {reminderSource = reminderSource}
            or {ability = step and step.ability, index = index}
        if visual.objectID then
            c = w:itemIcon(body, x, y, iconSize, visual.objectID, select, payload)
        elseif visual.spell then c = w:spellButton(body, x, y, iconSize, visual.spell, select, payload)
        elseif visual.prayer then c = w:prayerButton(body, x, y, iconSize, visual.prayer, select, payload)
        else c = w:abilityButton(body, x, y, iconSize, step.ability, select, payload) end
        if c and visual.ability and (step.ability == Equipment.SPECIAL or step.ability == Equipment.FINALITY) then
            w:contextMenu(c, select, function()
                a:chooseStep(index)
                a.equipmentPicker, a.equipmentKind = true, "Special attack weapons"
            end)
        end
        if c then X.target(a, c, function(payload)
            drop((index or #steps + 1) - 1, payload, index or #steps + 1, visual.reminderKind ~= "switches" and visual.reminderPosition or nil)
        end) end
        local selectedReminder = a.selectedReminder
        if reminderSource and selectedReminder and U.equal(reminderSource, selectedReminder) then
            w:rect(body, x, y, iconSize + 4, iconSize + 4, 0x55E39BFF, 2)
        end
        -- The insertion boundary survives passive selection, but its ability
        -- must not compete with the selected reminder for the editor mark.
        if not selectedReminder and (visual.ability or visual.legacyAbility) and a.insertAfter == index then
            w:rect(body, x, y, iconSize + 4, iconSize + 4, 0x55E39BFF, 2)
        end
        if position < #cells and not visual.joinedNext then w:text(body, x + iconSize + 7, y + math.floor(iconSize / 2) - 8, 16, 22, "›", 0xEFCA78FF) end
    end end
    if #cells == 0 then w:text(body, 0, iconsTop + 4, width, 44, a:t("Click or drag abilities below.")) end
    w:pager(body, 0, iconsTop + block - 24, width - 48, a.stepListPage, pages, function(page) a.stepListPage = page end, "Steps page %d/%d")
    w:text(body, width - 74, iconsTop + block - 22, 74, 22, a:t("%d steps", #steps), 0xEFCA78FF)
    local top = iconsTop + block + 10
    local catalogueHeight = math.max(iconSize + 184, height - top)
    local total = top + catalogueHeight
    body:SetScrollSize(width, math.max(height, total))
    a.editorScroll = U.clamp(a.editorScroll or 0, 0, math.max(0, total - height))
    body:SetScrollPos(0, a.editorScroll)
    if total > height then
        body.clickthrough = false
        w:wheel(body, function(_, delta)
            a.editorScroll = U.clamp(a.editorScroll + delta * 30, 0, total - height)
            body:SetScrollPos(0, a.editorScroll)
        end)
    end
    local catalogue = w:layer(body, 0, top, width, catalogueHeight)
    Picker.render(a, w, catalogue, width, catalogueHeight, function(ability) a:addAbility(ability) end)
end
return E
