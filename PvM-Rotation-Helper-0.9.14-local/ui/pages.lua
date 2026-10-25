-- Focused pages: named profiles, rotation editor, bindings.
local U = require("lib/util")
local Model = require("lib/model")
local ManualBars = require("ui/manual_bars")
local Editor = require("ui/editor")
local Rotation = require("ui/rotation")
local P = {}
local function profiles(a, w, body, width, height)
    local left, rightX = 200, 218
    local right = width - rightX
    w:button(body, 0, 0, (left - 8) / 2, 28, "New", function()
        a.creatingProfile, a.drafts.newProfileName = true, ""
    end, false, #a.state.profiles < Model.LIMIT.profiles)
    w:button(body, w:buttonWidth("New") + 8, 0, 80, 28, "Copy", function() a:addProfile(true) end, false, #a.state.profiles < Model.LIMIT.profiles)
    local rowHeight = 28
    w:text(body, 0, 34, left, 24, a:t("Profiles:"), w.colour.gold)
    local perPage = math.max(1, math.floor((height - 66) / rowHeight))
    if #a.state.profiles > perPage then perPage = math.max(1, math.floor((height - 100) / rowHeight)) end
    local count = math.max(1, math.ceil(#a.state.profiles / perPage))
    if a.revealProfile then a.profilePage, a.revealProfile = math.ceil(a.state.activeProfile / perPage), false end
    a.profilePage = U.clamp(a.profilePage, 1, count)
    local first = (a.profilePage - 1) * perPage + 1
    for index = first, math.min(#a.state.profiles, first + perPage - 1) do
        local profile, y = a.state.profiles[index], 66 + (index - first) * rowHeight
        local button = w:button(body, 0, y, left, 24, (a.state.activeProfile == index and "• " or "") .. a:profileName(profile),
            function() a:selectProfile(index) end, true, true, left)
        w:hover(button, function() return a:profileName(profile) end)
    end
    w:pager(body, 0, height - 28, left, a.profilePage, count, function(value) a.profilePage = value end, "Rotations page %d/%d")
    if a.creatingProfile then
        local previousScope = w.callbackScope
        local scope = {active = true, parent = previousScope}
        w.callbackScope = scope
        local name = w:field(body, rightX, 0, right, 26, "Profile name", "newProfileName", "", 80)
        w:text(body, rightX, 64, right, 90, a:t("Name the rotation, then add abilities in the editor."))
        w:button(body, rightX, 168, right, 28, "Create and edit", function()
            if a.creatingProfile then a:createProfile(name.content) end
        end)
        w:button(body, rightX, 208, right, 28, "Cancel", function()
            scope.active = false
            a.creatingProfile, a.drafts.newProfileName = false, nil
        end)
        w.callbackScope = previousScope
        return
    end
    if a.renamingProfile then
        local previousScope = w.callbackScope
        local scope = {active = true, parent = previousScope}
        w.callbackScope = scope
        local name = w:field(body, rightX, 0, right, 26, "Profile name", "profileName", a:profileName(), 80)
        w:buttonRow(body, rightX, 62, right, {
        { label = "Save", click = function()
            if not a.renamingProfile then return end
            if a:change(function(_, p) p.name = name.content end) then
                scope.active = false
                a.drafts.profileName, a.renamingProfile = nil, false
            end
        end },
        { label = "Cancel", click = function()
            scope.active = false
            a.renamingProfile, a.drafts.profileName = false, nil
        end },
        })
        w.callbackScope = previousScope
        return
    end
    local nameLabel = a:t("Profile name:")
    local labelWidth = math.ceil(w:textWidth(nameLabel)) + 8
    w:text(body, rightX, 0, labelWidth, 24, nameLabel, w.colour.gold)
    local name = w:text(body, rightX + labelWidth, 0, math.max(0, right - labelWidth), 24, a:profileName())
    name.maxLines = 1
    local actionsBottom = w:buttonRow(body, rightX, 34, right, {
        { label = "Rename", click = function() a.renamingProfile = true end },
        { label = "Delete profile", click = function()
        local index = a.state.activeProfile
        a:confirm("Delete this rotation?", function() a:deleteProfile(index) end)
        end },
    })
    local editBottom = w:buttonRow(body, rightX, actionsBottom + 8, right, {
        { label = "Rotation Editor", click = function() a:openSettings("Editor") end },
        { label = "Bindings", click = function() a:openSettings("Bindings") end },
    })
    local phaseTop = editBottom + 8
    local phases = a:profile().phases
    w:text(body, rightX, phaseTop, right, 28, a:t("Phases"), w.colour.gold)
    local viewport = w:layer(body, rightX, phaseTop + 34, right, math.max(1, height - phaseTop - 34))
    viewport.clickthrough = false
    local expanded = a.expandedPhase
    local geometry = Rotation.geometry(a, right)
    local needed = #Rotation.pack(Rotation.cells(a:currentPhase().steps, a:currentPhase().tailReminders), right, geometry.cell, geometry.size) * geometry.rowHeight + 32
    local previewHeight = math.max(80, math.min(needed, 300, viewport.height - 64))
    local total = #phases * 34 + (expanded and previewHeight or 0)
    viewport:SetScrollSize(right, math.max(viewport.height, total))
    a.phaseScroll = U.clamp(a.phaseScroll or 0, 0, math.max(0, total - viewport.height))
    viewport:SetScrollPos(0, a.phaseScroll)
    w:wheel(viewport, function(_, delta)
        a.phaseScroll = U.clamp(a.phaseScroll + delta * 30, 0, math.max(0, total - viewport.height))
        viewport:SetScrollPos(0, a.phaseScroll)
    end)
    local y = 0
    for index, phase in ipairs(phases) do
        w:button(viewport, 0, y, right, 28, a:phaseName(phase), function()
            local closing = a.expandedPhase == index
            local scroll = a.phaseScroll
            if index ~= a.phase then a:switchPhase(index - a.phase) end
            a.expandedPhase = not closing and index or nil
            a.phaseScroll = scroll
            a.previewPage = 1
        end, true)
        y = y + 34
        if expanded == index then
            local preview = w:layer(viewport, 0, y, right, previewHeight)
            Rotation.draw(a, w, preview, right, previewHeight, true)
            y = y + previewHeight
        end
    end
end
local function overlaySettings(a, w, body, width)
    w:text(body, 0, 0, width, 24, a:t("Background transparency (%)"))
    local sliderWidth = math.min(320, width - 100)
    local displayed, valueField = tostring(100 - a:windowSettings().overlayOpacity), nil
    local slider = w:slider(body, 0, 28, sliderWidth, tonumber(displayed), function(value)
        displayed = tostring(value)
        if valueField then
            valueField.content, a.drafts.overlayTransparency = displayed, displayed
        end
        a:previewOverlayTransparency(value)
    end, function() a:commitOverlayAppearance() end)
    -- A programmatic slider update may also emit CHANGE on the text field.
    -- Mirrored text is already applied; only a new manual number changes it.
    a.drafts.overlayTransparency = displayed
    valueField = w:field(body, sliderWidth + 12, 40, 76, 26, nil, "overlayTransparency", displayed, 3, function(text)
        if text == displayed or text == "" then return end
        local value = text:match("^%d+$") and tonumber(text) or nil
        if not value then
            valueField.content, a.drafts.overlayTransparency = displayed, displayed
            return
        end
        value = U.clamp(value, 1, 100)
        displayed = tostring(value)
        if valueField.content ~= displayed then valueField.content = displayed end
        a.drafts.overlayTransparency = displayed
        slider:SetValue(value, false)
        a:previewOverlayTransparency(value)
    end)
    w:check(body, 0, 94, 300, 26, "Click-through", a.state.settings.overlayClickthrough == true, function()
        a:change(function(state) state.settings.overlayClickthrough = not state.settings.overlayClickthrough end)
    end)
    w:check(body, 0, 132, 300, 26, "Show overlay", a:isOverlayVisible(), function()
        a:showOverlay(not a:isOverlayVisible())
    end)
    w:check(body, 0, 170, 300, 26, "Key labels", a.state.settings.showKeys, function()
        a:change(function(state) state.settings.showKeys = not state.settings.showKeys end)
    end)
end
local pages = { Profiles = profiles, Editor = Editor.render, Bindings = ManualBars.render, OverlaySettings = overlaySettings }

function P.render(a, w, body, width, height)
    if pages[a.page] then pages[a.page](a, w, body, width, height) end
end
return P
