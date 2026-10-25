-- Separate configuration panel and compact, movable rotation overlay.
local U = require("lib/util")
local Locator = require("lib/locator")
local Widgets = require("ui/widgets")
local Pages = require("ui/pages")
local Rotation = require("ui/rotation")
local V = {}
function V.minimumHeight(a, kind, width)
    return kind == "overlay" and Rotation.minimumHeight(a, Widgets.new(a), width) or 500
end
function V.refreshLocator(app)
    if app.locatorRoot then app.locatorRoot:Destroy(); app.locatorRoot = nil end
    if not app.started or not app.focused or app.confirmation or app.scanFailed then return end
    if not app.nativeIconSize then
        local ok, rows = pcall(Locator.read, app.env)
        if ok then
            for _, slot in ipairs(rows) do
                local mainBar = not slot.barIndex or slot.barIndex == 1
                local square = slot.width == slot.height
                if mainBar and square and slot.width >= 12 and slot.width <= 64 then
                    app.nativeIconSize = slot.width
                    app.pending = true
                    break
                end
            end
        end
    end
    local p, s = app:profile(), app.state.settings
    if p.mode ~= "beginner" or not app.selected or not app:isOverlayVisible() or not app.overlayRoot then return end
    local step = app:currentPhase().steps[app.selected]
    if not step then return end
    local parent = app.env.parent()
    if not parent then return end
    local spriteID = app.catalogue.resolve(step.ability, app.env.config)
    local automatic = Locator.matching(app.env, spriteID)
    -- Native icon positions are the source for action-bar frames. Manual
    -- catalogue corrections never create a phantom frame at a guessed position.
    local matches = {}
    local origin = parent.xyGlobal
    for _, slot in ipairs(automatic) do
        matches[#matches + 1] = { x = slot.x - origin.x, y = slot.y - origin.y, width = slot.width, height = slot.height }
    end
    if #matches == 0 then return end
    local w = Widgets.new(app)
    -- This full-screen layer and every descendant pass all mouse input through.
    local layer = w:layer(parent, 0, 0, parent.width, parent.height)
    layer.clickthrough = true
    app.locatorRoot = layer
    for _, slot in ipairs(matches) do
        local x, y = slot.x, slot.y
        if x >= 0 and y >= 0 and x + slot.width <= parent.width and y + slot.height <= parent.height then
            w:rect(layer, x, y, slot.width, slot.height, Widgets.colour.green, s.frameWidth)
        end
    end
end

-- Contents can be replaced without destroying the native corner capture.
local function fillPanel(a, w, root, width, height, collapsed)
    if collapsed then
        w:dragHandle(root, a.root, 0, 2, width - 168, 38, "panel", a:profileName())
        w:button(root, width - 160, 7, 112, 28, "Expand", function() a.minimized = false end)
        w:button(root, width - 34, 7, 28, 28, "×", function() a.panelClosed = true end)
        return
    end
    local titleWidth, profilesTop, modePreview = width - 92, 80, nil
    if a.page == "Profiles" then
        local modes = { { "beginner", "Learner" }, { "advanced", "Advanced" }, { "expert", "Expert" } }
        local labelWidth = math.ceil(w:textWidth(a:t("Mode:"))) + 8
        local groupWidth = labelWidth
        for _, entry in ipairs(modes) do groupWidth = groupWidth + w:buttonWidth(entry[2]) + 6 end
        local x, modeTop = width - 88 - groupWidth, 6
        local titlePixels = w:textWidth(a:t("PvM Rotation Helper"))
        if x - 30 < titlePixels then
            -- Long translated product names keep the whole title. The mode
            -- controls occupy their own row when the header cannot fit both.
            x, modeTop, profilesTop = 12, 78, 112
        else titleWidth = math.max(0, x - 6) end
        local modeLabel = w:text(root, x, modeTop + 4, labelWidth, 24, a:t("Mode:"), w.colour.gold)
        local controls, start = {}, x
        x = x + labelWidth
        for _, entry in ipairs(modes) do
            local size = w:buttonWidth(entry[2])
            local control = w:button(root, x, modeTop, size, 24, (a:profile().mode == entry[1] and "• " or "") .. a:t(entry[2]),
                function() a:setMode(entry[1]) end, true)
            controls[#controls + 1] = {node = control, offset = x - start}
            x = x + size + 6
        end
        modePreview = function(newWidth)
            local left, y = newWidth - 88 - groupWidth, 6
            local title, top = newWidth - 92, 80
            if left - 30 < titlePixels then left, y, top = 12, 78, 112
            else title = math.max(0, left - 6) end
            modeLabel:SetPos(left, y + 4)
            for _, control in ipairs(controls) do control.node:SetPos(left + control.offset, y) end
            return title, top
        end
    end
    local titleHandle, titleLabel = w:dragHandle(root, a.root, 0, 3, titleWidth, 34, "panel", a:t("PvM Rotation Helper"))
    local minimize = w:button(root, width - 76, 6, 28, 24, "_", function() a.minimized = true end)
    local close = w:button(root, width - 40, 6, 28, 24, "×", function() a.panelClosed = true end)
    local navigationWidth = w:buttonWidth("Combat Rotation Profiles")
    w:button(root, 12, 44, navigationWidth, 28, "Combat Rotation Profiles", function()
        a:openSettings("Profiles")
    end)
    if a.page == "Profiles" then
        w:button(root, navigationWidth + 24, 44, w:buttonWidth("Overlay Settings"), 24, "Overlay Settings", function()
            a:openSettings("OverlaySettings")
        end)
    elseif a.page == "Editor" or a.page == "Bindings" then
        local target = a.page == "Bindings" and "Rotation Editor" or "Bindings"
        w:button(root, navigationWidth + 24, 44, w:buttonWidth(target), 24, target, function()
            a:openSettings(a.page == "Bindings" and "Editor" or "Bindings")
        end)
        local contextKey = a.page == "Bindings" and "Bindings Profile:" or "Rotation Editor Profile:"
        local labelWidth = math.ceil(w:textWidth(a:t(contextKey))) + 8
        w:text(root, 12, 80, labelWidth, 24, a:t(contextKey), w.colour.gold)
        local name = w:text(root, 12 + labelWidth, 80, math.max(0, width - labelWidth - 24), 24, a:profileName())
        name.maxLines = 1
    else
        w:text(root, 12, 80, width - 24, 24, a:t("Overlay Settings"), Widgets.colour.gold)
    end
    local top = a.page == "Profiles" and profilesTop or 112
    local body = w:layer(root, 12, top, width - 24, height - top - 64)
    if a.confirmation then
        local confirmation = a.confirmation
        w:text(body, 12, 24, width - 72, 90, a:t(confirmation.message))
        w:button(body, 12, 130, 148, 30, "Confirm", function()
            if a.confirmation ~= confirmation then return end
            a.confirmation = nil
            confirmation.callback()
        end)
        w:button(body, 172, 130, 132, 30, "Cancel", function()
            if a.confirmation == confirmation then a.confirmation = nil end
        end)
    else Pages.render(a, w, body, width - 24, height - top - 64) end
    local reloadWidth = a.readOnly and w:buttonWidth("Reload saved data") or 0
    local footerWidth = width - (a.readOnly and reloadWidth + 52 or 48)
    local status = w:text(root, 12, height - 30, footerWidth, 24, w:fitText(a:t(a.status), footerWidth), Widgets.colour.muted)
    status.maxLines = 1
    a.hoverLabel = w:text(root, 12, height - 56, width - 24, 24, "", Widgets.colour.gold)
    a.hoverLabel.maxLines = 1
    local reload
    if a.readOnly then
        reload = w:button(root, width - reloadWidth - 20, height - 34, reloadWidth, 24, "Reload saved data", function()
            a:confirm("Reload saved data? Unsaved edits will be discarded.", function() a:reloadStorage() end)
        end)
    end
    local hover = a.hoverLabel
    -- During capture only these existing, fixed-count controls move. Page
    -- contents retain their layout until one complete reflow after release.
    return function(newWidth, newHeight)
        local title, bodyTop = newWidth - 92, top
        if modePreview then title, bodyTop = modePreview(newWidth) end
        titleHandle:SetSize(title, 34)
        if titleLabel then titleLabel:SetSize(math.max(0, title - 24), 29) end
        minimize:SetPos(newWidth - 76, 6); close:SetPos(newWidth - 40, 6)
        body:SetPos(12, bodyTop); body:SetSize(newWidth - 24, math.max(0, newHeight - bodyTop - 64))
        status:SetPos(12, newHeight - 30)
        status:SetSize(newWidth - (reload and reloadWidth + 52 or 48), 24)
        hover:SetPos(12, newHeight - 56); hover:SetSize(newWidth - 24, 24)
        if reload then reload:SetPos(newWidth - reloadWidth - 20, newHeight - 34) end
    end
end

-- Native-size feedback during a held corner gesture must not search catalogues,
-- traverse rotation cells, retire scopes or allocate a replacement component.
function V.previewResize(a, kind, window, width, height)
    if kind == "overlay" then return Rotation.previewResize(a, window, width, height) end
    local surface = a.panelSurface
    if not surface or surface.root ~= window then return end
    window:SetSize(width, height)
    surface.resize(width, height)
    surface.host:SetSize(width, height)
    surface.content:SetSize(width, height)
    if surface.preview then surface.preview(width, height) end
end

function V.resize(a, kind, window, width, height)
    if kind == "overlay" then return Rotation.resize(a, Widgets.new(a), window, width, height) end
    local surface = a.panelSurface
    if not surface or surface.root ~= window then return end
    window:SetSize(width, height)
    surface.resize(width, height)
    surface.host:SetSize(width, height)
    local w = Widgets.new(a)
    -- Reflow only retires this panel's controls. The independent overlay keeps
    -- its existing callbacks and native capture until its own content changes.
    if surface.scope then surface.scope.active = false end
    if surface.content then w:clearIcons(surface.content); surface.content:Destroy() end
    a.dropRegions = {}
    a.hasInputFields = false
    a.hoverOwner, a.hoverLabel = nil, nil
    surface.content = w:layer(surface.host, 0, 0, width, height)
    surface.scope = { active = true }
    local previousScope = w.callbackScope
    w.callbackScope = surface.scope
    a.layoutRoot = surface.content
    surface.preview = fillPanel(a, w, surface.content, width, height, false)
    a.layoutRoot = nil
    w.callbackScope = previousScope
end

function V.render(a)
    a:destroyUI()
    a.hasInputFields = false
    a.dropRegions, a.iconContainers, a.iconPreviews = {}, {}, {}
    local parent = a.env.parent()
    if not parent then return end
    local w, s = Widgets.new(a), a:windowSettings()
    local host = w:layer(parent, 0, 0, parent.width, parent.height)
    a.windowHost, parent = host, host
    Rotation.render(a, w, parent)
    if a.panelClosed then if not a.scanFailed then V.refreshLocator(a) end; return end
    if parent.width < 360 or parent.height < 60 then
        local root = w:layer(parent, 0, math.max(0, parent.height - 32), math.min(46, parent.width), math.min(32, parent.height))
        a.root = root
        if root.width >= 26 and root.height >= 26 then
            w:button(root, 0, 0, root.width, root.height, "Menu", function() a.panelClosed, a.minimized = false, false end)
        end
        return
    end
    local width = math.min(s.width, math.max(300, parent.width - 20))
    local height = math.min(s.height, math.max(100, parent.height - 20))
    local collapsed = a.minimized or width < 560 or height < 500
    if collapsed then width, height = math.min(360, parent.width - 10), 42 end
    local x, y = U.clamp(s.x, 0, math.max(0, parent.width - width)), U.clamp(s.y, 0, math.max(0, parent.height - height))
    local root = w:layer(parent, x, y, width, height)
    a.root, root.clickthrough = root, false
    local surface = w:windowFrame(root, width, height, s.opacity / 100)
    local contentHost = w:layer(root, 0, 0, width, height)
    local content = w:layer(contentHost, 0, 0, width, height)
    surface.root, surface.host, surface.content = root, contentHost, content
    surface.scope = { active = true }
    a.panelSurface = surface
    local previousScope = w.callbackScope
    w.callbackScope = surface.scope
    a.layoutRoot = content
    surface.preview = fillPanel(a, w, content, width, height, collapsed)
    a.layoutRoot = nil
    w.callbackScope = previousScope
    if not collapsed then w:resizeHandle(root, root, "panel", surface.border) end
    if not a.scanFailed then V.refreshLocator(a) end
end

-- Keep a reachable settings window after a drawing error instead of silently
-- removing every control. Retry remains an explicit action, never a loop.
function V.renderFailure(a)
    local parent = a.env.parent()
    if not parent or parent.width < 360 or parent.height < 240 or a.panelClosed then return end
    a.hasInputFields = false
    local w, s = Widgets.new(a), a:windowSettings()
    pcall(function() Rotation.render(a, w, parent) end)
    local width, height = math.min(580, parent.width - 20), 220
    local x, y = U.clamp(s.x, 0, parent.width - width), U.clamp(s.y, 0, parent.height - height)
    local root = w:layer(parent, x, y, width, height)
    a.root, root.clickthrough = root, false
    w:windowFrame(root, width, height, 1)
    w:dragHandle(root, root, 0, 0, width - 48, 34, "panel", a:t("PvM Rotation Helper"))
    w:button(root, width - 40, 4, 30, 28, "×", function() a.panelClosed = true end)
    w:text(root, 12, 48, width - 24, 64, a:t("Display failed. The error is in the developer console."))
    w:button(root, 12, 144, (width - 36) / 2, 30, "Retry display", function() a.pending = true end)
    w:button(root, (width + 12) / 2, 144, (width - 36) / 2, 30, "Open rotations", function() a:openSettings("Profiles") end)
end
return V
