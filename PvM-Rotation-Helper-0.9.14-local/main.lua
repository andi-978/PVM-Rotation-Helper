-- PvM Rotation Helper 0.9.14: local development entry point.
-- Optional client KeyDown processing only while explicitly active; no OS hooks.
local App = require("lib/app")
local View = require("ui/view")
local Hub = require("ui/hub")

local function parent()
    return ui.Interfaces:GetComponent(id.Component.TOPLEVEL_V2__PLUGIN_BUILD_LAYER_TOP)
end

local app = App.new({ ui = ui, id = id, db = PersistentDB,
    config = config, player = Player, parent = parent,
    menuEntryTypes = MiniMenuEntryType, menuActionTypes = MiniMenuActionType,
    clickEventAvailable = Event.MiniMenuEntrySelected ~= nil,
    keyEvent = Event.KeyDown, keyboard = Keyboard, gameKeys = GameKey, mouse = Mouse, variables = var,
    uiScale = function()
        local option = game and game.options and game.options.InterfaceScale
        local label = option and option:GetLabel(option.setting)
        local percent = type(label) == "string" and tonumber(label:match("(%d+)%%"))
        return percent and percent / 100 or 1
    end,
    report = function(message) print("[PvM Rotation Helper 0.9.14-local] " .. message) end })
app.view = View
app.hubView = Hub
local wasAvailable, refresh = false, 0

-- These optional events are absent in some older beta clients. No borrowed
-- plugin code or dependencies are used to populate the client-owned panes.
if Event.ContentLayerReady then
    Event.ContentLayerReady.Subscribe("pvm_learning_studio_hub", function(event)
        app:action(function() Hub.attach(app, "content", event.component) end)
    end)
end
if Event.SettingsLayerReady then
    Event.SettingsLayerReady.Subscribe("pvm_learning_studio_settings", function(event)
        -- The Manage gear opens the same own Profiles window as the Hub entry.
        -- Jagex also presents its native settings host; populate that host with
        -- a small own hint/opener instead of attempting to close native UI.
        app:action(function()
            app:openSettings("Profiles")
            Hub.settings(app, event and event.component)
        end)
    end)
end

Event.Draw.Subscribe("pvm_learning_studio_draw", function(event)
    -- The top-level game interface is unloaded during logout/world changes.
    -- Rebuild our own UI only after the game interface becomes available again.
    local ok, ready = pcall(function()
        local root = parent()
        return root and root.width > 0 and root.height > 0 and Player.IsAvailable()
    end)
    local available = ok and ready
    if available and not wasAvailable then app.pending = true end
    if not available and wasAvailable then
        app.focused = false
        app:stop("Game interface unavailable.")
        app:destroyUI()
        Hub.destroy(app)
    end
    wasAvailable = available
    if not available then return end
    app:draw(event)
    local delta = event and event.timeDeltaSecs or 0
    if type(delta) == "number" and delta == delta and delta >= 0 and delta < math.huge then refresh = math.min(0.25, refresh + delta) end
    if refresh >= 0.25 and app.started and app.focused and not app.scanFailed and not app.windowDrag and not app.itemDrag then
        refresh = 0
        local ok, err = pcall(function() View.refreshLocator(app) end)
        if not ok then
            app:inputFailure("scan", err)
        end
    end
end)

if Event.MiniMenuReady then
    Event.MiniMenuReady.Subscribe("pvm_learning_studio_context", function(event)
        local ok, err = pcall(function() app:onMiniMenuReady(event) end)
        if not ok then pcall(app.env.report, tostring(err)) end
    end)
end

if Event.MiniMenuEntrySelected then
    Event.MiniMenuEntrySelected.Subscribe("pvm_learning_studio_click", function(event)
        local ok, err = pcall(function() app:onActionBarSelection(event) end)
        if not ok then
            app:inputFailure("click", err)
        end
    end)
end

Event.WindowFocusChanged.Subscribe("pvm_learning_studio_focus", function(event)
    app.focused = event.hasFocus == true
    if not app.focused then
        app:stop("Focus lost. Press Start to continue.")
    else
        app.pending = true -- Regaining focus never starts scanning.
    end
end)

Event.WindowSizeChanged.Subscribe("pvm_learning_studio_size", function(event)
    if event.newWidth <= 0 or event.newHeight <= 0 then
        app.focused = false
        app:stop("Window minimised. Press Start to continue.")
    else
        -- Native positions are read anew. A normal resize must not stop a run.
        app:cancelWindowDrag()
        app.detectedBars, app.nativeIconSize = nil, nil
        app.pending = true
    end
end)

Event.GameStateChanged.Subscribe("pvm_learning_studio_state", function(event)
    -- Stop on a non-game state even if a transition briefly leaves the old
    -- logged-in interface available; those proxies can disappear next frame.
    local ok, ready = pcall(function()
        local root = parent()
        return root and root.width > 0 and root.height > 0 and Player.IsAvailable()
    end)
    local gameState = GameState and GameState.GAME or 30 -- documented GAME value
    if not ok or not ready or (event and event.newState ~= nil and event.newState ~= gameState) then
        app.focused = false
        app:stop("Game interface unavailable.")
        app:destroyUI()
        Hub.destroy(app)
    else app.pending = true end
end)

function PluginShutdown()
    app.focused = false
    app:stop("Plugin unloaded.")
    app:destroyUI()
    Hub.destroy(app)
    Event.Draw.Unsubscribe("pvm_learning_studio_draw")
    Event.WindowFocusChanged.Unsubscribe("pvm_learning_studio_focus")
    Event.WindowSizeChanged.Unsubscribe("pvm_learning_studio_size")
    Event.GameStateChanged.Unsubscribe("pvm_learning_studio_state")
    if Event.MiniMenuReady then Event.MiniMenuReady.Unsubscribe("pvm_learning_studio_context") end
    if Event.MiniMenuEntrySelected then Event.MiniMenuEntrySelected.Unsubscribe("pvm_learning_studio_click") end
    if Event.SettingsLayerReady then Event.SettingsLayerReady.Unsubscribe("pvm_learning_studio_settings") end
    if Event.ContentLayerReady then Event.ContentLayerReady.Unsubscribe("pvm_learning_studio_hub") end
end

print("[PvM Rotation Helper 0.9.14-local] Local development loaded. Instructions: README.md")
return app
