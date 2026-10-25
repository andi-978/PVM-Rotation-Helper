-- Our controls in official Plugins content/settings layers. The client owns the hosts.
local Widgets = require("ui/widgets")
local I18n = require("lib/i18n")
local H = {}
local function release(entry)
    if entry.scope then entry.scope.active = false end
    if entry.root then pcall(function() entry.root:Destroy() end); entry.root = nil end
    if entry.dialog then pcall(function() entry.dialog:Destroy() end); entry.dialog = nil end
end

local function settings(a, entry, w, root, width, height)
    local hint = a:t("The settings are open in the PvM Rotation Helper window.")
    local textWidth = width - 16
    local hintHeight = math.max(48, (math.ceil(w:textWidth(hint) / textWidth) + 1) * 24)
    local total = hintHeight + 48
    root:SetScrollSize(width, math.max(height, total))
    local maximum = math.max(0, total - height)
    entry.scroll = math.max(0, math.min(entry.scroll or 0, maximum))
    root:SetScrollPos(0, entry.scroll)
    if maximum > 0 then root.clickthrough = false end
    w:wheel(root, function(_, delta)
        entry.scroll = math.max(0, math.min(entry.scroll + delta * 28, maximum))
        root:SetScrollPos(0, entry.scroll)
    end)
    w:text(root, 8, 8, textWidth, hintHeight, hint)
    local buttonWidth = math.min(w:buttonWidth("PvM Rotation Helper settings"), textWidth)
    w:button(root, 8, hintHeight + 16, buttonWidth, 24, "PvM Rotation Helper settings", function()
        a:openSettings("Profiles")
    end, false, true, buttonWidth)
end
local function profileDialog(a, entry, w)
    if not entry.profilePicker then return end
    local parent = a:gameParent()
    if not parent then return end
    local width, height = math.min(420, parent.width - 24), math.min(360, parent.height - 24)
    if width < 260 or height < 120 then return end
    local previousScope = w.callbackScope
    local scope = { active = true, parent = entry.scope }
    w.callbackScope = scope
    local dialog = w:layer(parent, math.floor((parent.width - width) / 2), math.floor((parent.height - height) / 2), width, height)
    entry.dialog, dialog.clickthrough = dialog, false
    w:windowFrame(dialog, width, height, 1)
    w:text(dialog, 12, 8, width - 58, 24, a:t("Combat Rotation Profiles"), Widgets.colour.gold)
    w:button(dialog, width - 36, 4, 28, 24, "×", function() scope.active = false; entry.profilePicker = false end)
    local viewport = w:layer(dialog, 12, 40, width - 58, height - 52)
    viewport.clickthrough = false
    local total = #a.state.profiles * 32
    viewport:SetScrollSize(viewport.width, math.max(viewport.height, total))
    local maximum = math.max(0, total - viewport.height)
    entry.profileScroll = math.max(0, math.min(entry.profileScroll or 0, maximum))
    local trackHeight = height - 112
    local thumbHeight = math.min(trackHeight, math.max(16, math.floor(trackHeight * viewport.height / math.max(viewport.height, total))))
    local thumb = w:rect(dialog, width - 27, 68, 4, thumbHeight, Widgets.colour.gold)
    local function scroll(delta)
        entry.profileScroll = math.max(0, math.min(entry.profileScroll + delta, maximum))
        viewport:SetScrollPos(0, entry.profileScroll)
        thumb:SetPos(width - 27, 68 + (maximum > 0 and math.floor((trackHeight - thumb.height) * entry.profileScroll / maximum) or 0))
    end
    scroll(0)
    w:wheel(viewport, function(_, delta) scroll(delta * 32) end)
    local function scrollButton(y, direction, delta)
        local x = width - 40
        w:button(dialog, x, y, 28, 24, "", function() scroll(delta) end, true)
        -- Draw vertical chevrons with our native rectangles. Their direction
        -- stays visible even when the client font has no up/down arrow glyphs.
        for offset = 0, 4 do
            local row = direction < 0 and offset or 4 - offset
            w:rect(dialog, x + 13 - offset, y + 8 + row, 2, 2, Widgets.colour.text)
            if offset > 0 then w:rect(dialog, x + 13 + offset, y + 8 + row, 2, 2, Widgets.colour.text) end
        end
    end
    scrollButton(40, -1, -64)
    scrollButton(height - 36, 1, 64)
    for index, profile in ipairs(a.state.profiles) do
        local label = (index == a.state.activeProfile and "• " or "") .. index .. " · " .. a:profileName(profile)
        w:button(viewport, 0, (index - 1) * 32, viewport.width, 24, label, function()
            scope.active = false
            entry.profilePicker = false
            a:selectProfile(index)
        end, true, true, math.min(350, viewport.width))
    end
    w.callbackScope = previousScope
end
local function render(a, entry)
    release(entry)
    local parent = entry.parent
    local ok, width, height = pcall(function() return parent.width, parent.height end)
    if not ok or width < 100 or height < 32 then return end
    local w = Widgets.new(a)
    entry.scope = { active = true }
    w.callbackScope = entry.scope
    local root = w:layer(parent, 0, 0, width, height)
    entry.root = root
    if entry.kind == "settings" then settings(a, entry, w, root, width, height); return end
    local columns = width >= 360 and 2 or 1
    local languageRows = math.ceil(#I18n.languages / columns)
    local total = 178 + languageRows * 28 + 36
    root:SetScrollSize(width, math.max(height, total))
    entry.scroll = math.max(0, math.min(entry.scroll or 0, total - height))
    root:SetScrollPos(0, entry.scroll)
    w:wheel(root, function(_, delta)
        entry.scroll = math.max(0, math.min(entry.scroll + delta * 28, total - height))
        root:SetScrollPos(0, entry.scroll)
    end)
    local start = a.started and "Stop" or "Start"
    w:button(root, 3, 3, 100, 24, start, function()
        if a.started then a:stop() else a:start() end
    end, false, true, math.min(w:buttonWidth(start), width - 6))
    local current = a.state.activeProfile .. " · " .. a:profileName()
    w:button(root, 3, 35, 220, 24, current, function()
        entry.profilePicker = not entry.profilePicker
        entry.profileScroll = 0
    end, true, true, math.min(220, width - 6))
    w:check(root, 6, 77, width - 12, 30, "Show overlay", a:isOverlayVisible(), function()
        a:showOverlay(not a:isOverlayVisible())
    end)
    w:check(root, 6, 113, width - 12, 30, "Click-through", a.state.settings.overlayClickthrough == true, function()
        a:change(function(state) state.settings.overlayClickthrough = not state.settings.overlayClickthrough end)
    end)
    w:text(root, 6, 149, width - 12, 24, a:t("Plugin language"), Widgets.colour.gold)
    for index, language in ipairs(I18n.languages) do
        local cell = width / columns
        local x, y = ((index - 1) % columns) * cell + 6, 176 + math.floor((index - 1) / columns) * 28
        -- Re-clicking the selected language keeps it selected. Exactly one saved
        -- language controls these checks and every floating plugin window.
        w:check(root, x, y, cell - 12, 26, I18n.labels[language], a.state.settings.language == language, function()
            if a.state.settings.language ~= language then a:setLanguage(language) end
        end, true)
    end
    -- The official ribbon host may be narrower than our translated captions.
    -- Bound these buttons to its width instead of the floating-window sizing.
    w:button(root, 3, 178 + languageRows * 28, width - 6, 24, "PvM Rotation Helper settings", function()
        a:openSettings("Profiles")
    end, false, true, math.min(w:buttonWidth("PvM Rotation Helper settings"), width - 6))
    profileDialog(a, entry, w)
end
local function attach(a, kind, parent)
    if not parent then return end
    a.hubLayers = a.hubLayers or {}
    local previous = a.hubLayers[kind]
    if previous then release(previous) end
    a.hubLayers[kind] = { parent = parent, kind = kind }
    render(a, a.hubLayers[kind])
end
function H.attach(a, kind, parent)
    if kind == "content" then attach(a, kind, parent) end
end
function H.settings(a, parent)
    attach(a, "settings", parent)
end
function H.refresh(a)
    for _, entry in pairs(a.hubLayers or {}) do render(a, entry) end
end
function H.destroy(a)
    for _, entry in pairs(a.hubLayers or {}) do
        release(entry)
    end
    a.hubLayers = nil
end
return H
