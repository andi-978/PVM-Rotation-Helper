-- Own-component gestures only. Mouse position is read during our held icon or
-- window gesture, never while idle. No OS hooks or game input.
local U = require("lib/util")
local X = {}

local function pointer(a)
    local m = a.env.mouse
    local ok, x, y = pcall(function()
        if not m or not m.IsAvailable or not m.IsAvailable() then return nil end
        local positionRead, px, py = pcall(function()
            local point = m.GetPosition()
            return point and point.x, point and point.y
        end)
        if positionRead and type(px) == "number" and type(py) == "number" then return px, py end
        -- Both forms are documented. Older beta builds may not expose the
        -- Vector2 accessor even though the scalar accessors are available.
        if m.GetX and m.GetY then return m.GetX(), m.GetY() end
    end)
    if ok and type(x) == "number" and type(y) == "number" and x == x and y == y
        and math.abs(x) < 100000 and math.abs(y) < 100000 then return { x = x, y = y } end
end

function X.cancelWindow(a)
    local gesture = a.windowDrag
    a.windowDrag = nil
    if gesture and gesture.onFinish then
        local ok, problem = pcall(gesture.onFinish)
        if not ok then pcall(a.env.report, "Window capture cleanup: " .. tostring(problem)) end
    end
end

function X.beginWindow(a, window, kind)
    if a.windowDrag then return end
    local p = pointer(a)
    if not p then a.status, a.pending = "Window drag API unavailable.", true; return end
    local scale = 1
    if a.env.uiScale then
        local ok, value = pcall(a.env.uiScale)
        if ok and type(value) == "number" and value >= 0.5 and value <= 4 then scale = value end
    end
    a.windowDrag = { root = window, kind = kind, px = p.x, py = p.y,
        x = window.x, y = window.y, width = window.width, height = window.height, scale = scale }
end

function X.beginResize(a, window, kind)
    if a.windowDrag or a.itemDrag then return end
    X.beginWindow(a, window, kind)
    if a.windowDrag then
        a.windowDrag.resize = true
        a.resizeBeginEvents = (a.resizeBeginEvents or 0) + 1
    end
end

function X.updateWindow(a)
    local d = a.windowDrag
    if not d then return end
    local p, parent = pointer(a), a.env.parent()
    if not parent or not a.env.player.IsAvailable() then X.cancelWindow(a); return end
    -- The pointer may become unavailable just as the native release arrives.
    -- Retain the last computed size so completion can still commit it.
    if not p then return end
    local dx, dy = (p.x - d.px) / d.scale, (p.y - d.py) / d.scale
    if d.resize then
        local minWidth = d.kind == "overlay" and 370 or 560
        local maxWidth = math.max(minWidth, math.min(1200, parent.width - d.x))
        d.targetWidth = U.clamp(math.floor(d.width + dx), minWidth, maxWidth)
        local maxHeight = math.max(1, math.min(900, parent.height - d.y))
        -- The exact layout minimum is expensive for a long phase. Retain one
        -- minimum during capture; resizeWindow recomputes it at the final width.
        if not d.minimumHeight then
            d.minimumHeight = a.view and a.view.minimumHeight and a.view.minimumHeight(a, d.kind, d.width)
                or (d.kind == "overlay" and 160 or 500)
        end
        local minHeight = d.minimumHeight
        minHeight = math.min(minHeight, maxHeight)
        d.targetHeight = U.clamp(math.floor(d.height + dy), minHeight, maxHeight)
        if d.root.x ~= d.x or d.root.y ~= d.y then d.root:SetPos(d.x, d.y) end
        if d.root.width ~= d.targetWidth or d.root.height ~= d.targetHeight then d.root:SetSize(d.targetWidth, d.targetHeight) end
        if d.layoutWidth ~= d.targetWidth or d.layoutHeight ~= d.targetHeight then
            if d.frame then d.frame:SetSize(d.targetWidth, d.targetHeight) end
            if d.placeGrip then d.placeGrip(d.targetWidth, d.targetHeight) end
            -- Preview only existing geometry. A full reflow happens once after
            -- release, so native controls and catalogue queries stay idle here.
            if a.view and a.view.previewResize then a.view.previewResize(a, d.kind, d.root, d.targetWidth, d.targetHeight) end
            d.layoutWidth, d.layoutHeight = d.targetWidth, d.targetHeight
        end
        return
    end
    d.targetX = U.clamp(math.floor(d.x + dx), 0, math.max(0, parent.width - d.width))
    d.targetY = U.clamp(math.floor(d.y + dy), 0, math.max(0, parent.height - d.height))
    if d.root.x ~= d.targetX or d.root.y ~= d.targetY then
        d.root:SetPos(d.targetX, d.targetY)
        a.dragPositionUpdates = (a.dragPositionUpdates or 0) + 1
    end
end

function X.finishWindow(a)
    local d = a.windowDrag
    if not d then return end
    X.updateWindow(a)
    if a.windowDrag ~= d then return end
    X.cancelWindow(a)
    if d.resize then a.formGeneration = (a.formGeneration or 0) + 1 end
    a:action(function()
        if d.resize then
            a.resizeEndEvents = (a.resizeEndEvents or 0) + 1
            a:resizeWindow(d.kind, d.targetWidth or d.width, d.targetHeight or d.height)
        else a:moveWindow(d.kind, d.root.x, d.root.y) end
    end)
end

local function dropTarget(a, destination)
    local explicitDestination = destination ~= nil
    local p, scale = pointer(a), 1
    if a.env.uiScale then
        local ok, value = pcall(a.env.uiScale)
        if ok and type(value)=="number" and value>=0.5 and value<=4 then scale=value end
    end
    local function contains(component, requirePointer)
        if not component.visibleGlobal then return false end
        local xy = component.xyGlobal
        local left, top, right, bottom = xy.x, xy.y, xy.x + component.width, xy.y + component.height
        local parent = component.parent
        for _ = 1, 32 do
            if not parent then break end
            local ok, scrollable = pcall(function() return parent.scrollable end)
            if ok and scrollable then
                local origin = parent.xyGlobal
                left, top = math.max(left, origin.x), math.max(top, origin.y)
                right, bottom = math.min(right, origin.x + parent.width), math.min(bottom, origin.y + parent.height)
            end
            parent = parent.parent
        end
        -- visibleGlobal describes the component tree, not its scroll clip.
        -- An explicit native destination can still work without a pointer;
        -- the fallback requires the release position inside the visible part.
        return left < right and top < bottom and (not requirePointer or not p or
            p.x/scale >= left and p.y/scale >= top and p.x/scale < right and p.y/scale < bottom)
    end
    -- Native completion can hand us a child or a fresh Lua proxy. Resolve it
    -- only against components created and registered by this plugin.
    for _ = 1, 4 do
        if not destination then break end
        for _, target in ipairs(a.dropRegions or {}) do
            local ok, same = pcall(function()
                local c = target.component
                return contains(c, false) and (c == destination or
                    (c.interfaceID == destination.interfaceID and c.categoryID == destination.categoryID and c.dynamicID == destination.dynamicID))
            end)
            if ok and same then return target.callback end
        end
        local ok, parent = pcall(function() return destination.parent end)
        destination = ok and parent or nil
    end
    -- Resolve only our visible target rectangles at the release position.
    if explicitDestination or not p then return end
    for index = #(a.dropRegions or {}), 1, -1 do
        local target = a.dropRegions[index]
        local ok, inside = pcall(function()
            return contains(target.component, true)
        end)
        if ok and inside then return target.callback end
    end
end

-- An icon press belongs to our controls only. A transparent native grip owns
-- capture; the original artwork stays outside that grip. Our preview follows it.
function X.cancelItem(a)
    local gesture = a.itemDrag
    a.itemDrag = nil
    if gesture and gesture.retire then gesture.retire() end
    if gesture and gesture.visual then pcall(function() gesture.visual.hidden = true end) end
end

function X.updateItem(a)
    local gesture = a.itemDrag
    if gesture then gesture.update() end
end

function X.source(a, component, payload, visual, click, activator)
    local generation, profile, phase = a.formGeneration, a.state.activeProfile, a.phase
    local dragged, completedAt = false, nil
    local function current()
        return generation == a.formGeneration and profile == a.state.activeProfile and phase == a.phase
            and a.iconContainers and a.iconContainers[component] ~= nil
    end
    local function press(_, eventX, eventY)
        if not current() or a.windowDrag then return end
        if a.itemDrag and a.itemDrag.owner == component then return end
        X.cancelItem(a)
        completedAt = nil
        local initial = pointer(a)
        local scale = 1
        if a.env.uiScale then
            local ok, value = pcall(a.env.uiScale)
            if ok and type(value)=="number" and value>=0.5 and value<=4 then scale=value end
        end
        local xy = component.xyGlobal
        -- A queued press may be delivered after Mouse.GetPosition already
        -- reflects the release point. The hook's own press coordinates retain
        -- the true start, including short drags between two Draw frames.
        if type(eventX)=="number" and type(eventY)=="number" then
            if eventX>=0 and eventY>=0 and eventX<=component.width and eventY<=component.height then
                initial = {x=(xy.x+eventX)*scale,y=(xy.y+eventY)*scale}
            elseif eventX>=xy.x and eventY>=xy.y and eventX<=xy.x+component.width and eventY<=xy.y+component.height then
                initial = {x=eventX*scale,y=eventY*scale}
            end
        end
        if not initial then return end
        local offsetX, offsetY = initial.x / scale - xy.x, initial.y / scale - xy.y
        local gesture = {payload = payload, owner = component, visual = visual,
            retire = function() completedAt = a.inputClock or 0 end}
        dragged = false
        a.itemPressEvents = (a.itemPressEvents or 0) + 1
        gesture.update = function(allowMissingPointer)
            if a.itemDrag ~= gesture then return end
            if not current() then X.cancelItem(a); return end
            local p = pointer(a)
            if not p then
                -- Native completion may arrive after the pointer becomes
                -- unavailable. Only its explicit destination can complete the
                -- held gesture; dropTarget still checks our current registry.
                if allowMissingPointer then return end
                X.cancelItem(a); return
            end
            if not dragged and math.max(math.abs(p.x-initial.x), math.abs(p.y-initial.y)) / scale >= 6 then
                dragged = true
                a.itemDragEvents = (a.itemDragEvents or 0) + 1
            end
            if dragged and visual then
                local origin = visual.parent.xyGlobal
                visual:SetPos(math.floor(p.x/scale-origin.x-offsetX), math.floor(p.y/scale-origin.y-offsetY))
                visual.hidden = false
            end
        end
        a.itemDrag = gesture
    end
    local function release(destination)
        local gesture = a.itemDrag
        if not gesture or gesture.owner ~= component then return end
        gesture.update(destination ~= nil)
        if a.itemDrag ~= gesture then return end
        X.cancelItem(a)
        if not current() then return end
        completedAt = a.inputClock or 0
        if not dragged then
            if click then a:action(click) end
            return
        end
        a.itemDropEvents = (a.itemDropEvents or 0) + 1
        local target = dropTarget(a, destination)
        if target then
            a.itemDropMatches = (a.itemDropMatches or 0) + 1
            a:action(function() target(payload) end)
        end
        a.pending = true
    end
    component:Subscribe(a.env.ui.Hook.ONCLICK, press)
    component:Subscribe(a.env.ui.Hook.ONHOLD, function() X.updateItem(a) end)
    component:Subscribe(a.env.ui.Hook.ONRELEASE, function()
        if not activator or not (a.itemDrag and a.itemDrag.native) then release() end
    end)
    if activator then
        local function dragging(_, x, y)
            if not current() or completedAt ~= nil then return end
            if not a.itemDrag or a.itemDrag.owner ~= component then press(component, x, y) end
            local gesture = a.itemDrag
            if not gesture or gesture.owner ~= component then return end
            gesture.native = true
            if not dragged then dragged = true; a.itemDragEvents = (a.itemDragEvents or 0) + 1 end
            gesture.update()
        end
        local function complete(_, destination)
            if current() then release(destination) end
        end
        component:Subscribe(a.env.ui.Hook.ONDRAG, dragging)
        component:Subscribe(a.env.ui.Hook.ONDRAGCOMPLETE, complete)
        activator:Subscribe(a.env.ui.Hook.ONDRAG, dragging)
        activator:Subscribe(a.env.ui.Hook.ONDRAGCOMPLETE, complete)
        activator.mode = a.env.ui.TriggerMode.ONRELEASE
        -- The native Button may consume the layer's raw hooks. Complete a
        -- normal press on either release channel, then ignore its duplicate
        -- BUTTONPRESSED notification in the same frame. A previous drag must
        -- never swallow the next real click.
        activator:Subscribe(a.env.ui.Hook.ONCLICK, press)
        activator:Subscribe(a.env.ui.Hook.ONRELEASE, function()
            if not (a.itemDrag and a.itemDrag.native) then release() end
        end)
        activator:Subscribe(a.env.ui.Hook.ONBUTTONPRESSED, function()
            if not current() or completedAt == (a.inputClock or 0) then return end
            local gesture = a.itemDrag
            if gesture and gesture.owner == component then
                if gesture.native then return end
                release()
                return
            end
            X.cancelItem(a)
            dragged, completedAt = false, a.inputClock or 0
            if click then a:action(click) end
        end)
    end
end

function X.target(a, component, callback)
    a.dropRegions = a.dropRegions or {}
    local function register(node)
        a.dropRegions[#a.dropRegions + 1] = { component = node, callback = callback }
    end
    register(component)
    local container = a.iconContainers and a.iconContainers[component]
    if container then register(container) end
end

return X
