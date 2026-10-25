-- Native RuneScape UI helpers. Every component belongs to this plugin.
local U = require("lib/util")
local Interaction = require("lib/interaction")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local W = {}
W.__index = W
-- Colours sampled from free areas of the user's RuneScape Settings screenshot
-- JK6QTmeRkb.png. Native controls and ability art keep their own game styles.
W.colour = { background = 0x1B1511FF, header = 0x282521FF, panel = 0x302A22FF,
    field = 0x17130FFF, text = 0xDED4C5FF, muted = 0xC2B59EFF, key = 0xD5C6A8FF,
    green = 0x55E39BFF, gold = 0xF0BE79FF, border = 0x9A7E4EFF, divider = 0x745D39FF }

function W.new(app)
    if app.hoverGeneration ~= app.formGeneration then
        app.hoverCallbacks, app.hoverGeneration, app.contextMenus, app.iconActivators = {}, app.formGeneration, {}, {}
    end
    return setmetatable({ app = app, ui = app.env.ui, ids = app.env.id }, W)
end

local function current(app, generation, scope)
    if generation ~= app.formGeneration then return false end
    for _ = 1, 16 do
        if not scope then return true end
        if not scope.active then return false end
        scope = scope.parent
    end
    return false
end

local function currentWindow(app, generation, scope, window, kind, minimized)
    if not current(app, generation, scope) then return false end
    if kind == "overlay" then
        return app.overlayRoot == window and app:isOverlayVisible() and app.state.settings.overlayClickthrough ~= true
    end
    return app.root == window and not app.panelClosed and (app.minimized == true) == minimized
end

function W:wheel(component, callback, owner)
    local generation, scope = self.app.formGeneration, self.callbackScope
    component:Subscribe(self.ui.Hook.ONSCROLLWHEEL, function(...)
        if current(self.app, generation, scope) and (not owner or owner()) then callback(...) end
    end)
    return component
end

function W:hover(component, name)
    local generation, scope = self.app.formGeneration, self.callbackScope
    self.app.hoverCallbacks = self.app.hoverCallbacks or {}
    local token = {}
    self.app.hoverCallbacks[component] = token
    local function active()
        return current(self.app, generation, scope) and self.app.hoverCallbacks[component] == token
    end
    component:Subscribe(self.ui.Hook.ONMOUSEOVER, "pvm_name", function()
        if not active() then return end
        self.app.hoverOwner = component
        if self.app.hoverLabel then
            local width = self.app.root.width - 24
            local text = self:fitText(name(), width)
            local pixels = math.min(width, math.ceil(self:textWidth(text)))
            self.app.hoverLabel:SetPos(width + 12 - pixels, self.app.hoverLabel.y)
            self.app.hoverLabel:SetSize(pixels, 24)
            self.app.hoverLabel.content = text
        end
    end)
    component:Subscribe(self.ui.Hook.ONMOUSELEAVE, "pvm_name", function()
        if active() and self.app.hoverOwner == component then
            self.app.hoverOwner = nil
            if self.app.hoverLabel then self.app.hoverLabel.content = "" end
        end
    end)
    return component
end

function W:layer(parent, x, y, width, height)
    local c = self.ui.Layer.new(parent)
    c:SetPos(math.floor(x), math.floor(y)); c:SetSize(math.floor(width), math.floor(height))
    c.clickthrough = true
    return c
end

function W:rect(parent, x, y, width, height, colour, outline)
    local c = self.ui.Rectangle.new(parent)
    c:SetPos(math.floor(x), math.floor(y)); c:SetSize(math.floor(width), math.floor(height))
    c.rgba, c.fill, c.clickthrough = colour or W.colour.panel, not outline, true
    if outline then c.outlineThickness = outline end
    return c
end

-- One frame contract for both windows. Header/body/divider do not overlap, so
-- partial opacity does not make the title bar more opaque through compositing.
-- Only these decorative components fade; controls and item art are siblings.
function W:windowFrame(root, width, height, opacity)
    local frame = {
        background = self:rect(root, 0, 36, width, math.max(0, height - 36), W.colour.background),
        header = self:rect(root, 0, 0, width, 35, W.colour.header),
        divider = self:rect(root, 0, 35, width, 1, W.colour.divider),
        border = self:rect(root, 0, 0, width, height, W.colour.border, 1),
    }
    function frame.setOpacity(value)
        for _, part in ipairs({frame.background, frame.header, frame.divider, frame.border}) do part.alpha = value end
    end
    function frame.resize(w, h)
        frame.background:SetSize(w, math.max(0, h - 36))
        frame.header:SetSize(w, 35); frame.divider:SetSize(w, 1); frame.border:SetSize(w, h)
    end
    frame.setOpacity(opacity)
    return frame
end

function W:text(parent, x, y, width, height, text, colour)
    local c = self.ui.Text.new(parent)
    c:SetPos(math.floor(x), math.floor(y)); c:SetSize(math.floor(width), math.floor(height))
    c.content, c.font, c.rgba = U.display(text), self.ids.Font.MUSEO_SANS_15PT_REGULAR, colour or W.colour.text
    c.clickthrough = true
    c.maxLines = 0
    return c
end

function W:textWidth(text)
    local ok, pixels = pcall(function()
        return self.app.env.config.Font.MUSEO_SANS_15PT_REGULAR:GetStringWidth(U.display(text), false)
    end)
    return ok and type(pixels) == "number" and pixels >= 0 and pixels < 100000 and pixels
        or (U.textLength(text) or #text) * 9
end

function W:fitText(text, width)
    text = U.display(text)
    if self:textWidth(text) <= width then return text end
    local low, high = 0, #text
    while low < high do
        local middle = math.ceil((low + high) / 2)
        if self:textWidth(U.shortText(text, middle) .. "…") <= width then low = middle else high = middle - 1 end
    end
    return U.shortText(text, low) .. "…"
end

function W:buttonWidth(label, literal)
    local text = literal and label or self.app:t(label)
    return U.clamp(math.ceil(self:textWidth(text:gsub("^• ", ""))) + 28, 40, 220)
end

function W:button(parent, x, y, width, height, label, callback, literal, enabled, fixedWidth)
    local text = U.display(literal and label or self.app:t(label))
    if text ~= "" and width > 40 then
        width, height = fixedWidth or self:buttonWidth(label, literal), 24
    end
    local c = self.ui.Button.new(parent)
    c:SetPos(math.floor(x), math.floor(y)); c:SetSize(math.floor(width), math.floor(height))
    c.stylesheetID = self.ids.StyleSheet.BUTTON_DEFAULT
    c.label, c.clickthrough = text, self.passive == true
    c.text.font, c.text.maxLines = self.ids.Font.MUSEO_SANS_15PT_REGULAR, 1
    c.text.rgba, c.text.alpha = W.colour.text, 1
    c.text.alignHorizontal, c.text.alignVertical = self.ui.AlignMode.CENTRE, self.ui.AlignMode.CENTRE
    -- clickthrough permits input below a component; it does not disable that
    -- component's own events. Passive overlays must not execute button actions.
    c.enabled = enabled ~= false and self.passive ~= true
    local generation, scope = self.app.formGeneration, self.callbackScope
    c:Subscribe(self.ui.Hook.ONBUTTONPRESSED, function()
        if current(self.app, generation, scope) and c.enabled then
            -- A later ordinary control also recovers a missing own release.
            -- The pressed icon itself resolves its gesture before its click.
            if self.app.itemDrag and self.app.itemDrag.owner ~= c then Interaction.cancelItem(self.app) end
            self.app:action(callback)
        end
    end)
    return c
end

-- Wrap controls without stretching them when their containing window grows.
function W:buttonRow(parent, x, y, width, controls)
    local used, row = 0, 0
    for _, control in ipairs(controls) do
        local size = self:buttonWidth(control.label, control.literal)
        if used > 0 and used + size > width then used, row = 0, row + 28 end
        self:button(parent, x + used, y + row, size, 24, control.label, control.click,
            control.literal, control.enabled)
        used = used + size + 8
    end
    return y + row + 24
end

function W:field(parent, x, y, width, height, label, key, initial, limit, changed)
    self.app.hasInputFields = true
    local offset = label and 24 or 0
    if label then self:text(parent, x, y, width, 22, self.app:t(label), W.colour.muted) end
    self:rect(parent, x, y + offset, width, height, W.colour.field)
    local c = self.ui.InputField.new(parent)
    c.stylesheetID = self.ids.StyleSheet.INPUT_DEFAULT
    c:SetPos(math.floor(x + 4), math.floor(y + offset)); c:SetSize(math.floor(width - 8), math.floor(height))
    c:Setup(self.ui.TextContentVisibilityMode.VISIBLE, self.ui.InputFieldFilterMode.NONE, limit or 500)
    c.alpha, c.rgba = 1, 0xFFFFFFFF
    c.text.font = self.ids.Font.MUSEO_SANS_15PT_REGULAR
    -- TextData alpha defaults are not inherited reliably from the field's tint.
    c.text.rgba, c.text.alpha, c.text.maxLines = W.colour.text, 1, 1
    c.text.alignHorizontal, c.text.alignVertical = self.ui.AlignMode.TOPLEFT, self.ui.AlignMode.CENTRE
    c.caretRGBA, c.selectionHighlightRGBA = 0xFFFFFFFF, 0x8F754A99
    c.contentMargin.left, c.contentMargin.right, c.contentMargin.top, c.contentMargin.bottom = 3, 3, 2, 2
    c.clickthrough, c.enabled = false, true
    c.content = self.app.drafts[key] ~= nil and self.app.drafts[key] or tostring(initial or "")
    local drafts, generation, scope = self.app.drafts, self.app.formGeneration, self.callbackScope
    c:Subscribe(self.ui.Hook.ONCONTENTCHANGED, function(component)
        -- Focus-loss events can arrive after another profile or form was opened.
        -- Reject stale callbacks before accessing a potentially destroyed proxy.
        if self.app.drafts ~= drafts or not current(self.app, generation, scope) then return end
        drafts[key] = component.content
        if changed then changed(component.content) end
    end)
    return c
end

-- Native checks share the saved state of all plugin windows.
function W:check(parent, x, y, width, height, label, value, callback, literal)
    local c = self.ui.Check.new(parent)
    c:SetPos(math.floor(x), math.floor(y)); c:SetSize(math.floor(width), math.floor(height))
    c.stylesheetID = self.ids.StyleSheet.CHECKBOX_DEFAULT
    c.label, c.value = U.display(literal and label or self.app:t(label)), value == true
    c.alignment, c.buttonSize, c.clickthrough = self.ui.CheckAlignMode.LEFT, 18, false
    c.text.font, c.text.rgba, c.text.alpha = self.ids.Font.MUSEO_SANS_15PT_REGULAR, W.colour.text, 1
    local generation, scope = self.app.formGeneration, self.callbackScope
    c:Subscribe(self.ui.Hook.ONBUTTONPRESSED, function()
        if not current(self.app, generation, scope) then return end
        Interaction.cancelItem(self.app)
        self.app:action(callback)
    end)
    return c
end

function W:slider(parent, x, y, width, value, changed, finished)
    self.app.hasInputFields = true
    local c = self.ui.Slider.new(parent)
    c:SetPos(x, y); c:SetSize(width, 50)
    c.stylesheetID = self.ids.StyleSheet.SLIDER_DEFAULT
    c.clickthrough = false
    assert(c:Setup(0, 100, value, 1, 1), "Slider range unavailable.")
    local generation, scope = self.app.formGeneration, self.callbackScope
    c:Subscribe(self.ui.Hook.ONSELECTIONCHANGED, function(component, _, selectedStatus)
        -- A native transition also deselects its previous entry. That entry ID
        -- is not a new slider value; replaying it makes the background jump.
        if current(self.app, generation, scope) and selectedStatus == 1 then changed(component.value) end
    end)
    c:Subscribe(self.ui.Hook.ONRELEASE, function()
        if current(self.app, generation, scope) then finished() end
    end)
    return c
end

function W:pager(parent, x, y, width, page, count, callback, labelKey)
    if count <= 1 then return end
    local maximum = math.max(1, count)
    local label = self.app:t(labelKey or "Page %d / %d", page, maximum)
    -- Reserve both arrow buttons and gaps. Very narrow profile columns use the
    -- complete numbers alone rather than truncating the end of the page count.
    local textWidth = self:textWidth(label) + 12
    if textWidth > width - 76 then label = string.format("%d/%d", page, maximum); textWidth = self:textWidth(label) + 12 end
    textWidth = math.min(width - 76, textWidth)
    self:button(parent, x, y, 32, 28, "<-", function() callback(math.max(1, page - 1)) end, true, page > 1)
    local text = self:text(parent, x + 38, y + 2, textWidth, 26, label, W.colour.muted)
    text.maxLines = 1
    self:button(parent, x + 44 + textWidth, y, 32, 28, "->", function() callback(math.min(maximum, page + 1)) end, true, page < maximum)
end

-- Keep the selector in place. A clipped, scrollable list opens strictly below
-- it, even near the footer; the popup never jumps above its source control.
function W:dropdown(parent, x, y, width, choices, selected, select, host, literal)
    -- Search can rebuild a popup without replacing the surrounding form.
    -- Retire its options independently of the still-active search input.
    local token = {}
    self.app.dropdownToken = token
    host = host or self.app.layoutRoot or self.app.root or parent
    local ok, px, py = pcall(function()
        local origin, target = parent.xyGlobal, host.xyGlobal
        return origin.x - target.x + x, origin.y - target.y + y + 28
    end)
    if not ok then host, px, py = parent, x, y + 28 end
    local options = {}
    for _, choice in ipairs(choices) do if choice ~= selected then options[#options + 1] = choice end end
    local available = math.floor(host.height - py - 36)
    if #options == 0 or available < 27 then return end
    local fullHeight = #options * 27 + 4
    local height = math.min(fullHeight, available)
    px = U.clamp(px, 0, math.max(0, host.width - width))
    local menu = self:layer(host, px, py, width, height); menu.clickthrough = false
    self:rect(menu, 0, 0, width, height, W.colour.background)
    local content = self:layer(menu, 0, 0, width, height)
    content.clickthrough = false
    content:SetScrollSize(width, fullHeight)
    local scroll, maximum = 0, math.max(0, fullHeight - height)
    local thumb
    if maximum > 0 then thumb = self:rect(menu, width - 4, 0, 3, math.max(12, math.floor(height * height / fullHeight)), W.colour.gold) end
    self:wheel(content, function(_, delta)
        scroll = U.clamp(scroll + delta * 27, 0, maximum)
        content:SetScrollPos(0, scroll)
        if thumb then thumb:SetPos(width - 4, math.floor((height - thumb.height) * scroll / maximum)) end
    end, function() return self.app.dropdownToken == token end)
    for index, choice in ipairs(options) do
        local buttonWidth = width - (maximum > 0 and 9 or 4)
        self:button(content, 2, 2 + (index - 1) * 27, buttonWidth, 24, choice, function()
            if self.app.dropdownToken == token then
                self.app.dropdownToken = nil
                select(choice)
            end
        end, literal, true, buttonWidth)
    end
    return menu
end

function W:icon(parent, x, y, size, ability)
    size = self.app.nativeIconSize or 30
    local spriteID = self.app.catalogue.resolve(ability, self.app.env.config)
    if not spriteID then
        local missing = self:text(parent, x, y, size, size, "?", W.colour.muted)
        self:hover(missing, function() return self.app:abilityName(ability) end)
        return missing
    end
    local sprite = self.ui.Sprite.new(parent)
    sprite:SetPos(math.floor(x), math.floor(y)); sprite:SetSize(size, size)
    sprite.sprite, sprite.clickthrough, sprite.alpha, sprite.rgba = spriteID, true, 1, 0xFFFFFFFF
    self:hover(sprite, function() return self.app:abilityName(ability) end)
    return sprite
end

function W:spellIcon(parent, x, y, size, spell)
    size = self.app.nativeIconSize or 30
    local spriteID = Spells.resolve(spell, self.app.env.config)
    if not spriteID then
        local missing = self:text(parent, x, y, size, size, "?", W.colour.muted)
        self:hover(missing, function() return Spells.name(spell, self.app.state.settings.language) end)
        return missing
    end
    local sprite = self.ui.Sprite.new(parent)
    sprite:SetPos(math.floor(x), math.floor(y)); sprite:SetSize(size, size)
    sprite.sprite, sprite.clickthrough, sprite.alpha, sprite.rgba = spriteID, true, 1, 0xFFFFFFFF
    self:hover(sprite, function() return Spells.name(spell, self.app.state.settings.language) end)
    return sprite
end

function W:prayerIcon(parent, x, y, size, prayer)
    size = self.app.nativeIconSize or 30
    local spriteID = Prayers.resolve(prayer, self.app.env.config)
    local icon
    if spriteID then
        icon = self.ui.Sprite.new(parent)
        icon:SetPos(math.floor(x), math.floor(y)); icon:SetSize(size, size)
        icon.sprite, icon.clickthrough, icon.alpha, icon.rgba = spriteID, true, 1, 0xFFFFFFFF
    else icon = self:text(parent, x, y, size, size, "?", W.colour.muted) end
    self:hover(icon, function() return Prayers.name(prayer, self.app.state.settings.language) end)
    return icon
end

-- A native square frame with no input/event handler. Artwork is a separate
-- full-opacity decorative sibling, so the disabled frame cannot dim the icon.
function W:passiveTile(parent, x, y, size, reminder)
    local host = self:layer(parent, x, y, size + 4, size + 4)
    local frame = self.ui.Button.new(host)
    frame:SetPos(0, 0); frame:SetSize(size + 4, size + 4)
    frame.stylesheetID, frame.label = self.ids.StyleSheet.BUTTON_DEFAULT, ""
    frame.enabled, frame.clickthrough = false, true
    if reminder.objectID then self:itemIcon(host, 0, 0, size, reminder.objectID)
    elseif reminder.prayer then self:prayerIcon(host, 2, 2, size, reminder.prayer)
    else self:spellIcon(host, 2, 2, size, reminder.spell) end
    return host
end

-- Like the working title grip, the Button refers to its collection ancestor.
-- That collection contains no visible artwork. The original sprite is a sibling.
function W:pointerGrip(parent, x, y, width, height)
    local capture = self:layer(parent, x, y, width, height)
    capture.clickthrough, capture.enabled = false, true
    local button = self.ui.Button.new(capture)
    button:SetPos(0, 0); button:SetSize(width, height)
    button.stylesheetID, button.label, button.alpha, button.clickthrough, button.enabled = -1, "", 0, false, true
    button.dragConfig.draggedComponent = self.app.windowHost or self.app.root or parent
    button.dragConfig.dragDelayTicks, button.dragConfig.deadZone = 0, 6
    button.dragConfig.renderBehaviour = self.ui.DragRenderBehaviour.OPAQUE
    return capture, button
end

-- A result refresh removes only its own icon registrations.
function W:clearIcons(host)
    local function retireHover(root)
        local hovered = self.app.hoverOwner
        for _ = 1, 16 do
            if not hovered then break end
            if hovered == root then
                self.app.hoverOwner = nil
                if self.app.hoverLabel then self.app.hoverLabel.content = "" end
                break
            end
            hovered = hovered.parent
        end
        for component in pairs(self.app.hoverCallbacks or {}) do
            local ancestor = component
            for _ = 1, 16 do
                if ancestor == root then self.app.hoverCallbacks[component] = nil; break end
                if not ancestor then break end
                ancestor = ancestor.parent
            end
        end
    end
    retireHover(host)
    for key, container in pairs(self.app.iconContainers or {}) do
        local ancestor = container
        for _ = 1, 16 do
            if ancestor == host then
                if self.app.itemDrag and self.app.itemDrag.owner == key then Interaction.cancelItem(self.app) end
                self.app.iconContainers[key] = nil
                if self.app.contextMenus then
                    self.app.contextMenus[key], self.app.contextMenus[container] = nil, nil
                    local activator = self.app.iconActivators and self.app.iconActivators[key]
                    if activator then self.app.contextMenus[activator] = nil end
                end
                if self.app.iconActivators then self.app.iconActivators[key] = nil end
                if self.app.iconPreviews then
                    local preview = self.app.iconPreviews[key]
                    if preview then retireHover(preview); preview:Destroy() end
                    self.app.iconPreviews[key] = nil
                end
                break
            end
            if not ancestor then break end
            ancestor = ancestor.parent
        end
    end
end

-- Jagex renders current item art from its own object configuration. This has no
-- inventory operation, minimenu action, downloaded image or inferred Sprite ID.
local function savedSource(payload)
    return type(payload) == "table" and (payload.index ~= nil or payload.reminderSource ~= nil)
end

function W:itemIcon(parent, x, y, size, objectID, click, payload)
    objectID = Equipment.canonicalID(objectID)
    local nativeID = Equipment.nativeID(objectID)
    -- Missing current artwork blocks new selections, but an already saved cell
    -- still needs its own select/delete/reorder gestures in the editor.
    if not nativeID and not savedSource(payload) then click, payload = nil, nil end
    local container = self:layer(parent, x, y, size + 4, size + 4)
    local function image(host, callback)
        local c
        if callback then
            c = self:button(host, 0, 0, size + 4, size + 4, "", callback, true)
            if nativeID then
                c:SetAssociatedObject(nativeID)
                c.associatedObjectQuantity = 1
                c.showAssociatedObjectText, c.showAssociatedObjectSprite = false, true
            else self:text(host, 2, 2, size, size, "?", self.colour.muted) end
            c.label = ""
        elseif nativeID then
            -- Passive rotation/reminder art is a decorative native Sprite,
            -- with no press/selection callback or button skin to consume input.
            c = self.ui.Sprite.new(host)
            c:SetPos(2, 2); c:SetSize(size, size)
            -- Sprite's optional quantity argument expects Uint64 in this beta;
            -- use its documented Int quantity property for the single reminder.
            c:SetAssociatedObject(nativeID)
            c.associatedObjectQuantity = 1
            c.associatedObjectQuantityMode = self.ui.ObjectQuantityDisplayMode.NEVER
            c.clickthrough, c.alpha, c.rgba = true, 1, 0xFFFFFFFF
        else
            c = self:text(host, 2, 2, size, size, "?", self.colour.muted)
        end
        self:hover(c, function() return Equipment.name(objectID, self.app.state.settings.language) end)
        return c
    end
    local button = image(container, (click or payload) and function()
        if click and not payload then click() end
    end or nil)
    self.app.iconContainers = self.app.iconContainers or {}
    self.app.iconContainers[button] = container
    if payload then
        -- Buttons consume raw pointer hooks in this beta. A plain own layer
        -- above the decorative button owns the complete press/release gesture.
        button.clickthrough = true
        local hit, activator = self:pointerGrip(container, 0, 0, size + 4, size + 4)
        self:hover(hit, function() return Equipment.name(objectID, self.app.state.settings.language) end)
        self:hover(activator, function() return Equipment.name(objectID, self.app.state.settings.language) end)
        self.app.iconContainers[hit] = container
        self.app.iconActivators = self.app.iconActivators or {}; self.app.iconActivators[hit] = activator
        -- The preview crosses the catalogue's clipped scroll boundary. Keep it
        -- on the window; clearIcons owns its removal during live search.
        local preview = self:layer(self.app.layoutRoot or self.app.root or self.previewRoot or parent, 0, 0, size + 4, size + 4)
        preview.hidden = true
        image(preview).clickthrough = true
        self.app.iconPreviews = self.app.iconPreviews or {}; self.app.iconPreviews[hit] = preview
        Interaction.source(self.app, hit, payload, preview, click, activator)
        return hit
    end
    return button
end

-- Only the separate preview follows the pointer. The original icon never
-- changes alpha, position or parent during a click/held gesture.
local function imageButton(w, parent, x, y, size, click, payload, image, name, available)
    available = available or savedSource(payload)
    if not available then payload = nil end
    local container = w:layer(parent, x, y, size + 4, size + 4)
    local button = w:button(container, 0, 0, size + 4, size + 4, "", not payload and click or function() end, true, available)
    image(container)
    w:hover(button, name)
    w.app.iconContainers = w.app.iconContainers or {}
    w.app.iconContainers[button] = container
    if payload then
        button.clickthrough = true
        local hit, activator = w:pointerGrip(container, 0, 0, size + 4, size + 4)
        w:hover(hit, name)
        w:hover(activator, name)
        w.app.iconContainers[hit] = container
        w.app.iconActivators = w.app.iconActivators or {}; w.app.iconActivators[hit] = activator
        local preview = w:layer(w.app.layoutRoot or w.app.root or w.previewRoot or parent, 0, 0, size + 4, size + 4)
        preview.hidden = true
        image(preview)
        w.app.iconPreviews = w.app.iconPreviews or {}; w.app.iconPreviews[hit] = preview
        Interaction.source(w.app, hit, payload, preview, click, activator)
        return hit
    end
    return button
end

-- Only our saved special/EOF controls register context actions. The native
-- menu is populated by MiniMenuReady; no game component ops are changed.
function W:contextMenu(component, select, assign)
    local app, generation, scope = self.app, self.app.formGeneration, self.callbackScope
    local container = app.iconContainers[component]
    app.contextMenus = app.contextMenus or {}
    local entry = {
        active = function() return current(app, generation, scope) and app.iconContainers[component] == container end,
        select = select, assign = assign,
    }
    app.contextMenus[component], app.contextMenus[container] = entry, entry
    local activator = app.iconActivators and app.iconActivators[component]
    if activator then app.contextMenus[activator] = entry end
end

function W:abilityButton(parent, x, y, size, ability, click, payload)
    size = self.app.nativeIconSize or 30
    return imageButton(self, parent, x, y, size, click, payload,
        function(host) self:icon(host, 2, 2, size, ability) end,
        function() return self.app:abilityName(ability) end,
        self.app.catalogue.resolve(ability, self.app.env.config) ~= nil)
end

function W:spellButton(parent, x, y, size, spell, click, payload)
    size = self.app.nativeIconSize or 30
    return imageButton(self, parent, x, y, size, click, payload,
        function(host) self:spellIcon(host, 2, 2, size, spell) end,
        function() return Spells.name(spell, self.app.state.settings.language) end,
        Spells.resolve(spell, self.app.env.config) ~= nil)
end

function W:prayerButton(parent, x, y, size, prayer, click, payload)
    size = self.app.nativeIconSize or 30
    return imageButton(self, parent, x, y, size, click, payload,
        function(host) self:prayerIcon(host, 2, 2, size, prayer) end,
        function() return Prayers.name(prayer, self.app.state.settings.language) end,
        Prayers.resolve(prayer, self.app.env.config) ~= nil)
end

-- The caption stays on the window. Native dragging may render its source at an
-- extra pointer offset, so that source must contain no visible title or skin.
-- Create the caption first, then its transparent hit region above it. The native
-- capture and DRAG/DRAGCOMPLETE lifecycle remain the same as the movable window.
function W:resizeHandle(parent, window, kind, frame)
    -- A separate transparent capture source keeps native dragging from moving
    -- any content or hiding a visible label. Only our window size is changed.
    local capture, handle = self:pointerGrip(parent, window.width - 20, window.height - 20, 20, 20)
    local function place(width, height)
        capture:SetPos(width - 20, height - 20)
    end
    place(window.width, window.height)
    local generation, scope, minimized = self.app.formGeneration, self.callbackScope, self.app.minimized == true
    local armed = true
    local function current()
        return armed and currentWindow(self.app, generation, scope, window, kind, minimized)
    end
    local function begin()
        if not current() then return end
        Interaction.beginResize(self.app, window, kind)
        local d = self.app.windowDrag
        if d and d.root == window and d.resize and (not d.owner or d.owner == handle) then
            d.owner, d.frame, d.placeGrip = handle, frame, place
            d.onFinish = function() armed = false end
        end
    end
    local function finish()
        local d = self.app.windowDrag
        if current() and d and d.resize and d.owner == handle then
            Interaction.finishWindow(self.app)
        end
    end
    handle:Subscribe(self.ui.Hook.ONDRAG, begin)
    handle:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, finish)
    handle:Subscribe(self.ui.Hook.ONRELEASE, finish)
    capture:Subscribe(self.ui.Hook.ONDRAG, begin)
    capture:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, finish)
    capture:Subscribe(self.ui.Hook.ONRELEASE, finish)
    local host = self.app.windowHost
    if host then
        host:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, "pvm_resize_" .. kind, finish)
        host:Subscribe(self.ui.Hook.ONRELEASE, "pvm_resize_" .. kind, finish)
    end
    return handle
end

function W:dragHandle(parent, window, x, y, width, height, kind, title)
    local caption = self:text(parent, x + 12, y + 5, math.max(0, width - 24), math.max(0, height - 5), title, W.colour.gold)
    caption.maxLines = 1
    local handle = self.ui.Button.new(parent)
    handle:SetPos(math.floor(x), math.floor(y)); handle:SetSize(math.floor(width), math.floor(height))
    handle.stylesheetID, handle.label, handle.alpha = -1, "", 0
    handle.clickthrough, handle.enabled = false, true
    -- The native capture belongs to the window ancestor, not the handle itself.
    -- Otherwise the beta can deliver a press without a matching drag completion.
    handle.dragConfig.draggedComponent = window
    handle.dragConfig.dragDelayTicks, handle.dragConfig.deadZone = 0, 0
    handle.dragConfig.renderBehaviour = self.ui.DragRenderBehaviour.OPAQUE
    local generation, scope, minimized = self.app.formGeneration, self.callbackScope, self.app.minimized == true
    local armed = true
    local function active() return armed and currentWindow(self.app, generation, scope, window, kind, minimized) end
    local function begin()
        if active() and not self.app.itemDrag then
            self.app.dragEvents = (self.app.dragEvents or 0) + 1
            Interaction.beginWindow(self.app, window, kind)
            local gesture = self.app.windowDrag
            if gesture and gesture.root == window and not gesture.resize and (not gesture.owner or gesture.owner == handle) then
                gesture.owner = handle
                gesture.onFinish = function() armed = false end
            end
        end
    end
    local function finish()
        local gesture = self.app.windowDrag
        if active() and gesture and gesture.root == window and not gesture.resize and gesture.owner == handle then
            Interaction.finishWindow(self.app)
        end
    end
    handle:Subscribe(self.ui.Hook.ONDRAG, begin)
    handle:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, finish)
    handle:Subscribe(self.ui.Hook.ONRELEASE, finish)
    -- Some beta builds route capture hooks to the referenced ancestor instead
    -- of the handle. Item drags reference their own icon layer, never this root.
    window:Subscribe(self.ui.Hook.ONDRAG, "pvm_window_drag", begin)
    window:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, "pvm_window_drag", finish)
    window:Subscribe(self.ui.Hook.ONRELEASE, "pvm_window_drag", finish)
    local host = self.app.windowHost
    if host then
        host:Subscribe(self.ui.Hook.ONDRAGCOMPLETE, "pvm_window_drag_" .. kind, finish)
        host:Subscribe(self.ui.Hook.ONRELEASE, "pvm_window_drag_" .. kind, finish)
    end
    return handle, caption
end

return W
