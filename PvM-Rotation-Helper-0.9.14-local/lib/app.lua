-- Controller for manual selection and explicitly enabled, validated client input.
local Model = require("lib/model")
local Storage = require("lib/storage")
local Catalogue = require("lib/catalogue")
local I18n = require("lib/i18n")
local U = require("lib/util")
local ActionClick = require("lib/action_click")
local Keybinds = require("lib/keybinds")
local Locator = require("lib/locator")
local Interaction = require("lib/interaction")
local Equipment = require("lib/equipment")
local Spells = require("lib/spells")
local Prayers = require("lib/prayers")
local App = {}
App.__index = App
local function invalidateStepControls(app)
    app.selectedReminder = nil
    app.formGeneration = (app.formGeneration or 0) + 1
    Interaction.cancelItem(app)
end

function App.new(environment)
    local self = setmetatable({}, App)
    self.env, self.catalogue = environment, Catalogue
    Catalogue.refresh(environment.config)
    Equipment.initialize(environment.config, environment.id)
    Spells.refresh(environment.config)
    Prayers.refresh(environment.config)
    self.state, self.status, self.readOnly, self.savedSnapshot = Storage.load(environment.db, Catalogue, environment.config)
    if not self.savedSnapshot and not self.readOnly then
        self.state.profiles[1].name = self:t("New rotation")
        self.state.profiles[1].phases[1].name = self:t("Phase %d", 1)
    end
    self.status = self.status or "Stopped."
    self.page, self.phase, self.selected, self.rotationPage = "Profiles", 1, nil, 1
    self.query, self.group, self.cataloguePage = "", "All", 1
    self.expandedPhase = 1
    self.profilePage, self.stepListPage = 1, 1
    self.protectionReason = self.readOnly and self.status or nil
    self.drafts, self.pending, self.minimized = {}, true, false
    self.root, self.overlayRoot, self.locatorRoot = nil, nil, nil
    self.confirmation = nil
    self.started, self.focused = false, false
    return self
end

function App:gameParent()
    local ok, parent = pcall(function()
        local parent = self.env.parent()
        if parent and parent.width > 0 and parent.height > 0 and self.env.player.IsAvailable() then return parent end
    end)
    return ok and parent or nil
end

function App:start()
    -- Start enables ongoing observations; Detect/Diagnose are explicit one-shot reads.
    if not self:gameParent() then self:stop("Game interface unavailable."); return end
    if self.phase ~= 1 then self.phase = 1; self:resetContext() end
    self.rotationPage, self.previewPage, self.stepListPage = 1, 1, 1
    self.repeatIndex = 1
    Locator.invalidate()
    self.scanFailed, self.keyFailed, self.clickFailed = false, false, false
    self.lastInput, self.inputClock = nil, 0
    self.started, self.focused, self.pending = true, true, true
    if #self:currentPhase().steps > 0 or #(self:currentPhase().tailReminders or {}) > 0 then self.overlayOverride = true end
    self.selected = nil
    if self:profile().mode ~= "expert" then self:chooseStep(1) end
    if #self:currentPhase().steps == 0 then
        self.status = #(self:currentPhase().tailReminders or {}) > 0 and "Passive reminders only." or "No steps yet. Add an ability in the editor."
    elseif self:profile().mode == "expert" then self.status = "Manual selection only"
    elseif not self.selected then self.status = "Passive reminders only."
    else self.status = "Started. Game input is followed outside text forms." end
    self:syncKeySubscription()
end

function App:stop(reason)
    self:commitOverlayAppearance()
    Interaction.cancelItem(self)
    Interaction.cancelWindow(self)
    self.itemDrag, self.lastInput = nil, nil
    self.started, self.selected = false, nil
    self.repeatIndex = 1
    self:syncKeySubscription()
    if self.locatorRoot then pcall(function() self.locatorRoot:Destroy() end); self.locatorRoot = nil end
    self.status, self.pending = reason or "Stopped.", true
end

function App:cancelWindowDrag()
    Interaction.cancelWindow(self)
end


function App:t(key, ...) return I18n.text(self.state.settings.language, key, ...) end
function App:abilityName(item) return self.catalogue.name(item, self.state.settings.language) end
function App:phaseName(phase) return I18n.phaseName((phase or self:currentPhase()).name, self.state.settings.language) end
function App:profileName(profile) return (profile or self:profile()).name end
function App:clearStepDrafts()
    self.drafts.stepKey, self.drafts.stepCaption, self.drafts.stepRepeat = nil, nil, nil
end
function App:resetContext()
    -- Queued controls from the old profile/phase may arrive before the next
    -- Draw destroys their native forms. Invalidate their callbacks immediately.
    invalidateStepControls(self)
    self.equipmentPicker, self.equipmentStylePicker, self.equipmentTierPicker = false, false, false
    self.insertAfter, self.detectedBars, self.lastInput = nil, nil, nil
    self.typePicker, self.renamingProfile, self.weaponTierPicker = false, false, false
    self.selected, self.drafts, self.confirmation = nil, {}, nil
    self.editingStep, self.creatingProfile = false, false
    self.rotationPage, self.previewPage, self.stepListPage = 1, 1, 1
    self.expandedPhase, self.phaseScroll = self.phase, 0
    self.editorScroll, self.bindingsScroll = 0, 0
    self.manualBar, self.manualSlot = 1, 1
    self.repeatIndex = 1
    if self.started and self:profile().mode ~= "expert" then self:chooseStep(1) end
end
function App:setLanguage(language)
    self:change(function(state) state.settings.language = language end)
end
function App:reloadStorage()
    self:stop()
    local state, reason, protected, snapshot = Storage.load(self.env.db, Catalogue, self.env.config)
    self.readOnly, self.protectionReason = protected, protected and reason or nil
    if protected then self.status = reason; return false end
    if snapshot == nil then
        state.profiles[1].name = I18n.text(state.settings.language, "New rotation")
        state.profiles[1].phases[1].name = I18n.text(state.settings.language, "Phase %d", 1)
    end
    self.state, self.savedSnapshot = state, snapshot
    self.phase, self.overlayOverride, self.windowOverride = 1, nil, nil
    self:resetContext()
    self.status, self.pending = "Saved data reloaded. Press Start when ready.", true
    return true
end
function App:selectProfile(index)
    if self:change(function(state) state.activeProfile = index; state.settings.overlayVisible = true end) then
        self.phase, self.overlayOverride = 1, nil; self:resetContext()
    end
end
function App:deleteProfile(index)
    if self:change(function(state)
        assert(U.integer(index, 1, #state.profiles), "Invalid profile.")
        table.remove(state.profiles, index)
        if #state.profiles == 0 then state.profiles[1] = Model.newProfile(self:t("New rotation"), self:t("Phase %d", 1)) end
        if index < state.activeProfile then state.activeProfile = state.activeProfile - 1 end
        state.activeProfile = math.min(state.activeProfile, #state.profiles)
    end) then self.phase = 1; self:resetContext() end
end
function App:deleteStep(index)
    if self:change(function(_, p)
        assert(U.integer(index, 1, #p.phases[self.phase].steps), "Invalid rotation step.")
        table.remove(p.phases[self.phase].steps, index)
    end) then
        invalidateStepControls(self)
        self.selected, self.drafts = nil, {}
        self.repeatIndex, self.lastInput = 1, nil
        self.insertAfter = math.min(index - 1, #self:currentPhase().steps)
    end
end

function App:deletePhase(index)
    if not U.integer(index, 2, #self:profile().phases) then return false end
    if not self:change(function(_, profile) table.remove(profile.phases, index) end) then return false end
    self.phase = 1
    self:resetContext()
    return true
end
function App:isOverlayVisible()
    if self.overlayOverride ~= nil then return self.overlayOverride end
    return self.state.settings.overlayVisible
end
function App:openSettings(page)
    local target = page or self.page
    if target ~= self.page or self.panelClosed or self.minimized or self.confirmation then invalidateStepControls(self) end
    self.confirmation = nil
    self.panelClosed, self.minimized = false, false
    self.page = target
    self.hasInputFields, self.pending = true, true -- conservative until the new page renders
    self:syncKeySubscription()
end
function App:showOverlay(visible)
    -- Closing must remain possible with unavailable or protected storage. Keep a
    -- transient visibility override if saving fails; never silently reopen it.
    self.overlayOverride = visible
    if not visible then
        self:stop("Overlay closed.")
        if self.overlayRoot then self.overlayRoot:Destroy(); self.overlayRoot = nil end
    end
    if self:change(function(state) state.settings.overlayVisible = visible end) then self.overlayOverride = nil end
end
function App:moveWindow(kind, x, y)
    local parent = self.env.parent()
    if not parent then return end
    local root = kind == "overlay" and self.overlayRoot or self.root
    local width, height = root and root.width or 40, root and root.height or 40
    x, y = U.clamp(math.floor(x), 0, math.max(0, parent.width - width)), U.clamp(math.floor(y), 0, math.max(0, parent.height - height))
    local xKey, yKey = kind == "overlay" and "overlayX" or "x", kind == "overlay" and "overlayY" or "y"
    local saved = self:change(function(state)
        if kind == "overlay" then state.settings.overlayX, state.settings.overlayY = x, y
        else state.settings.x, state.settings.y = x, y end
    end)
    self.windowOverride = self.windowOverride or {}
    if saved then self.windowOverride[xKey], self.windowOverride[yKey] = nil, nil
    else self.windowOverride[xKey], self.windowOverride[yKey] = x, y end
end
function App:windowSettings()
    if not self.overlayDraft and (not self.windowOverride or next(self.windowOverride) == nil) then return self.state.settings end
    -- A failed save must not trap a window in place. These positions live only
    -- in this instance; protected PersistentDB records remain untouched.
    local settings = U.copy(self.state.settings)
    for key, value in pairs(self.windowOverride or {}) do settings[key] = value end
    if self.overlayDraft then settings.overlayOpacity = self.overlayDraft.opacity end
    return settings
end

function App:previewOverlayTransparency(value)
    if not U.integer(value, 0, 100) then return end
    self.overlayDraft = { opacity = 100 - value, time = self.inputClock or 0 }
    if self.overlaySurface then
        self.overlaySurface.setOpacity((100 - value) / 100)
    end
end

function App:commitOverlayAppearance()
    local draft = self.overlayDraft
    if not draft then return true end
    self.overlayDraft = nil
    if draft.opacity == self.state.settings.overlayOpacity then return true end
    local pending = self.pending
    local saved = self:change(function(state) state.settings.overlayOpacity = draft.opacity end)
    if saved then self.pending = pending
    elseif self.overlaySurface then
        local ok, problem = pcall(self.overlaySurface.setOpacity, self.state.settings.overlayOpacity / 100)
        if not ok then pcall(self.env.report, "Overlay opacity: " .. tostring(problem)) end
    end
    return saved
end

function App:resizeWindow(kind, width, height)
    local overlay = kind == "overlay"
    local wk, hk = overlay and "overlayWidth" or "width", overlay and "overlayHeight" or "height"
    width = U.clamp(math.floor(width), overlay and 370 or 560, 1200)
    local minimum = self.view and self.view.minimumHeight and self.view.minimumHeight(self, kind, width) or (overlay and 160 or 500)
    height = U.clamp(math.floor(height), minimum, 900)
    local saved = self:change(function(state) state.settings[wk], state.settings[hk] = width, height end)
    self.windowOverride = self.windowOverride or {}
    if saved then self.windowOverride[wk], self.windowOverride[hk] = nil, nil
    else self.windowOverride[wk], self.windowOverride[hk] = width, height end
end

function App:profile() return Model.profile(self.state) end
function App:currentPhase() return self:profile().phases[self.phase] end

function App:selectBarSlot(barIndex, slotIndex)
    if not U.integer(barIndex, 1, math.max(1, #self:profile().bars)) or not U.integer(slotIndex, 1, 14) then return false end
    if self.manualBar == barIndex and self.manualSlot == slotIndex then return true end
    invalidateStepControls(self)
    self.manualBar, self.manualSlot, self.pending = barIndex, slotIndex, true
    return true
end

local function assignBarSlot(app, barIndex, slotIndex, reference, clearKey)
    if not U.integer(barIndex, 1, Model.LIMIT.bars) or not U.integer(slotIndex, 1, Model.LIMIT.slots) then return false end
    if type(reference) == "string" then reference = {ability = reference} end
    if not U.fields(reference, {ability = true, objectID = true, spell = true, prayer = true, unknown = true}) then return false end
    local replacement = {ability = reference.ability, objectID = reference.objectID, spell = reference.spell,
        prayer = reference.prayer, unknown = reference.unknown, key = ""}
    if not Model.validSlot(replacement, app.catalogue) then return false end
    if replacement.objectID then replacement.objectID = Equipment.canonicalID(replacement.objectID) end
    local saved = app:change(function(_, profile)
        for index = #profile.bars + 1, barIndex do profile.bars[index] = Model.newBar() end
        local bar = profile.bars[barIndex]
        for index = #bar.slots + 1, math.max(14, slotIndex) do bar.slots[index] = {ability = "", key = ""} end
        replacement.key = not clearKey and bar.slots[slotIndex].key or ""
        bar.slots[slotIndex], bar.enabled = replacement, true
        if not profile.activeBars then
            profile.activeBars = {}
            for index = 1, #profile.bars do profile.activeBars[#profile.activeBars + 1] = index end
        end
        local active = false
        for _, index in ipairs(profile.activeBars) do active = active or index == barIndex end
        if not active then profile.activeBars[#profile.activeBars + 1] = barIndex end
    end)
    if saved then
        local detected = app.detectedBars and app.detectedBars[barIndex]
        if detected and detected.slots then detected.slots[slotIndex] = nil end
        invalidateStepControls(app)
        app.lastInput = nil
    end
    return saved
end

function App:assignBarSlot(barIndex, slotIndex, reference)
    return assignBarSlot(self, barIndex, slotIndex, reference, false)
end

function App:clearBarSlot(barIndex, slotIndex)
    return assignBarSlot(self, barIndex, slotIndex, {ability = ""}, true)
end

function App:change(callback, message)
    if self.readOnly then
        self.status = self.protectionReason or "Storage is protected. Existing data has not been overwritten."
        self.pending = true
        return false
    end
    local candidate = U.copy(self.state)
    local ok, err = pcall(callback, candidate, Model.profile(candidate))
    if not ok then
        local message = tostring(err):match(":%d+: (.+)$") or tostring(err)
        self.status, self.pending = I18n.texts[message] and message or "Action failed.", true
        pcall(self.env.report, tostring(err)); return false
    end
    local valid, reason = Model.validate(candidate, Catalogue)
    if not valid then self.status, self.pending = reason, true; return false end
    local saved, problem = Storage.save(self.env.db, candidate, self.state, Catalogue, self.savedSnapshot)
    if not saved then
        if problem == "Storage changed in another client. Reload the plugin." then
            self.readOnly, self.protectionReason = true, problem; self:stop(problem)
        end
        self.status, self.pending = problem, true; return false
    end
    self.savedSnapshot = U.copy(candidate)
    self.state, self.status, self.pending = candidate, message or "Saved locally.", true
    return true
end

function App:action(callback)
    self:commitOverlayAppearance()
    -- A new ordinary control action also ends any abandoned native capture.
    -- This keeps a missing beta DRAGCOMPLETE event from freezing every form.
    if self.windowDrag then
        local finished, problem = pcall(Interaction.finishWindow, self)
        if not finished then Interaction.cancelWindow(self); pcall(self.env.report, tostring(problem)) end
    end
    local ok, err = pcall(callback)
    if not ok then self.status = "Action failed."; pcall(self.env.report, tostring(err)) end
    self.pending = true
    self:syncKeySubscription()
end

function App:confirm(message, callback)
    invalidateStepControls(self)
    self.confirmation = { message = message, callback = callback }
    self.pending = true
end

function App:setMode(mode)
    if self:change(function(_, p) p.mode = mode end) then
        self.selected, self.confirmation, self.editingStep = nil, nil, false
        self.repeatIndex = 1
        self:clearStepDrafts()
        self.lastInput = nil
        if self.started and mode ~= "expert" then self:chooseStep(1) end
        self:syncKeySubscription()
    end
end

function App:chooseStep(index, preserveInput)
    self.selectedReminder = nil
    if not U.integer(index, 1, #self:currentPhase().steps) then return end
    if not preserveInput then self.lastInput = nil end
    if self.started and self:profile().mode ~= "expert" then
        while self:currentPhase().steps[index] and Spells.isIncantation(self:currentPhase().steps[index].ability) do index = index + 1 end
        if index > #self:currentPhase().steps then
            self.selected, self.pending = nil, true
            self.status = "Rotation complete. Select a phase or restart."
            return
        end
    end
    self.equipmentPicker, self.equipmentStylePicker, self.equipmentTierPicker = false, false, false
    if self.selected ~= index then
        invalidateStepControls(self)
        self:clearStepDrafts(); self.editingStep = false
    end
    self.selected = index
    self.insertAfter = index
    self.repeatIndex = 1
    self.revealRotation = true
    self.status = "Manual selection only"
    self.pending = true
end

function App:inputBlocked()
    -- Form-opening flags take effect before the next Draw creates native fields.
    -- Hidden/minimised profile forms must not keep an otherwise visible run paused.
    local panelVisible = not self.panelClosed and not self.minimized
    local openingForm = self.page == "Profiles" and panelVisible
        and (self.renamingProfile or self.creatingProfile)
    local details = self.page == "Editor" and panelVisible and self.editingStep
    return self.hasInputFields or self.confirmation or details or openingForm
        or self.windowDrag or self.itemDrag
end

function App:keyActive()
    return self.started and self.focused and not self.keyFailed and self:isOverlayVisible()
        and self.overlayRoot ~= nil and self:profile().mode ~= "expert" and self.selected ~= nil
        and not self:inputBlocked()
end

function App:syncKeySubscription()
    local enabled = self:keyActive() and Keybinds.available(self.env) or false
    if enabled == (self.keySubscribed or false) then return end
    self.keySubscribed = enabled
    local ok, err = pcall(function()
        if not enabled then self.env.keyEvent.Unsubscribe("pvm_learning_studio_ability_key"); return end
        self.env.keyEvent.Subscribe("pvm_learning_studio_ability_key", function(event)
            local success, problem = pcall(self.onAbilityKey, self, event)
            if not success then self:inputFailure("key", problem) end
        end)
    end)
    if not ok then
        self.keySubscribed, self.keyFailed = false, true
        pcall(function() self.env.keyEvent.Unsubscribe("pvm_learning_studio_ability_key") end)
        self:inputFailure("key", err)
    end
end

function App:onAbilityKey(event)
    if not self:keyActive() then return end
    if not self:gameParent() then
        self:stop("Game interface unavailable."); return
    end
    if not Keybinds.unblocked(self.env) then return end
    if not event or event.isRepeat ~= false then return end
    -- Pause when opening common text/console contexts. No key codes or characters
    -- are retained, printed or persisted. A mouse-opened chat still needs testing.
    local keys, code = self.env.gameKeys, event.gameKey
    if code == keys.ENTER or code == keys.CONSOLE or code == keys.ESCAPE or code == keys.SLASH then
        self:stop("Text input opened. Press Start to continue."); return
    end
    local step = self:currentPhase().steps[self.selected]
    if step and Keybinds.matches(step, event, self.env, self.catalogue, self:profile(), self.detectedBars) then
        self:acceptInput(step.ability, "key", "Ability-key trial active. Execution is not confirmed.")
    end
end

-- Populate only the menu of an actually hovered, current control created by
-- this editor. Assignment is lower priority than Select, so left click always
-- marks the ability. Both callbacks remain bound to their original UI scope.
function App:onMiniMenuReady(event)
    if self.page ~= "Editor" or self.panelClosed or self.minimized or self.editingStep
        or self.equipmentPicker or self.confirmation or self.windowDrag or self.itemDrag
        or self.hoverGeneration ~= self.formGeneration then return end
    local hovered = self.hoverOwner
    if not hovered or not hovered.isMouseOver then return end
    local node, entry = hovered, nil
    for _ = 1, 4 do
        entry = self.contextMenus and self.contextMenus[node]
        if entry or not node then break end
        node = node.parent
    end
    if not entry or not entry.active() then return end
    local menu = event and event.miniMenu
    if not menu then return end
    local function action(callback)
        return function()
            if entry.active() and self.page == "Editor" and not self.panelClosed and not self.minimized
                and not self.confirmation and not self.editingStep and not self.equipmentPicker then
                Interaction.cancelItem(self)
                self:action(callback)
            end
        end
    end
    menu:Add(self:t("Assign"), action(entry.assign))
    menu:Add(self:t("Select"), action(entry.select))
end

function App:onActionBarSelection(event)
    -- Guard before reading the event or any native action-bar data. Expert mode
    -- remains a static reference. No clicks are logged or written to storage.
    if not self.started or not self.focused or self.clickFailed or not self.env.clickEventAvailable
        or not self.env.menuEntryTypes or not self.env.menuActionTypes
        or not self:isOverlayVisible() or not self.overlayRoot
        or self:profile().mode == "expert" or self:inputBlocked() or not self.selected then return end
    -- A transition may invalidate the client before the next Draw/focus event.
    -- Apply the same availability boundary as the key channel before the payload.
    if not self:gameParent() then
        self:stop("Game interface unavailable."); return
    end
    local step = self:currentPhase().steps[self.selected]
    if not step or not ActionClick.matches(event and event.entry, step.ability, self.env, self.catalogue) then return end
    self:acceptInput(step.ability, "click", "Click trial active. A click does not confirm execution.")
end

-- A key may also generate a menu event. Keep only a 250 ms cross-channel
-- duplicate token containing ability/channel, never the key or an input history.
function App:acceptInput(ability, channel, message)
    local last = self.lastInput
    if last and last.ability == ability and last.channel ~= channel and (self.inputClock or 0) - last.time <= 0.25 then
        return
    end
    self.lastInput = { ability = ability, channel = channel, time = self.inputClock or 0 }
    self:advanceExpected(message)
end

-- A beta API error disables only the failing channel until explicit Start.
function App:inputFailure(channel, problem)
    if channel == "key" then self.keyFailed = true
    elseif channel == "click" then self.clickFailed = true
    else self.scanFailed = true end
    if self.locatorRoot then pcall(function() self.locatorRoot:Destroy() end); self.locatorRoot = nil end
    self.status, self.pending = "Recognition unavailable. Rotation remains open; see Diagnose.", true
    pcall(self.env.report, channel .. ": " .. tostring(problem))
    self:syncKeySubscription()
end

function App:advanceExpected(message)
    local step = self:currentPhase().steps[self.selected]
    local index, repetition = self.selected, self.repeatIndex or 1
    if repetition < step.repeats then
        self.repeatIndex = repetition + 1
    elseif index < #self:currentPhase().steps then
        self:chooseStep(index + 1, true)
    else
        self.selected = nil
        self.status = "Rotation complete. Select a phase or restart."
    end
    if self.selected then
        self.status = message
        self.revealRotation = true
    end
    if self.locatorRoot then pcall(function() self.locatorRoot:Destroy() end); self.locatorRoot = nil end
    self.pending = true
    self:syncKeySubscription()
end

function App:switchPhase(delta)
    self.phase = U.clamp(self.phase + delta, 1, #self:profile().phases)
    self:resetContext()
end

function App:addProfile(duplicate, name)
    if self:change(function(s, p)
        assert(#s.profiles < Model.LIMIT.profiles, "Maximum 12 profiles.")
        local added = duplicate and U.copy(p) or Model.newProfile(name or self:t("New rotation"), self:t("Phase %d", 1))
        if duplicate then added.name = U.shortText(p.name, 60) .. " (" .. self:t("Copy") .. ")" end
        s.profiles[#s.profiles + 1] = added
        s.activeProfile = #s.profiles
    end, "Saved locally.") then
        self.phase = 1; self:resetContext()
        self.revealProfile = true
        return true
    end
    return false
end

function App:createProfile(name)
    if not U.named(name, 80) then self.status = "Enter a profile name."; return end
    if self:addProfile(false, name) then self.page = "Editor" end
end

function App:addAbility(ability, after)
    if Spells.isIncantation(ability) then return Equipment.queue(self, {spell = ability}) end
    if not Catalogue.selectable(ability, self.env.config) then
        self.status, self.pending = "Ability unavailable in this client.", true
        return false
    end
    local index = U.clamp((after or self.insertAfter or #self:currentPhase().steps) + 1, 1, #self:currentPhase().steps + 1)
    if self:change(function(_, p)
        local steps = p.phases[self.phase].steps
        local phase = p.phases[self.phase]
        local tail = index == #steps + 1 and phase.tailReminders or nil
        table.insert(steps, index, { ability = ability, key = "", caption = "", repeats = 1, breakAfter = false,
            reminders = tail and U.copy(tail) or nil })
        if tail then phase.tailReminders = nil end
    end, "Ability added.") then
        invalidateStepControls(self)
        self.selected, self.insertAfter = index, index
        self.repeatIndex, self.lastInput = 1, nil
        self.revealStep = true
        self:clearStepDrafts(); self.editingStep = false
        return true
    end
end

function App:moveStepTo(index, after)
    local steps = self:currentPhase().steps
    if not U.integer(index, 1, #steps) or not U.integer(after, 0, #steps) then return end
    local target = after >= index and after or after + 1
    if target == index then return end
    if self:change(function(_, p)
        local items = p.phases[self.phase].steps
        local step = table.remove(items, index); table.insert(items, target, step)
    end) then
        invalidateStepControls(self)
        self.selected, self.insertAfter, self.revealStep = target, target, true
        self.repeatIndex, self.lastInput = 1, nil
        self:clearStepDrafts()
    end
end

-- Display only: current shared profile assignments, with legacy step fallback.
-- Rendering this label never starts a native scan or reads keyboard input.
function App:stepKey(step)
    local profile = self:profile()
    local values, known = Keybinds.profileLabels(step.ability, profile)
    if step.key ~= "" and (not profile.activeBars or not known) then return Keybinds.display(step.key, self.state.settings.language) end
    local labels, shown = {}, {}
    for key in pairs(values) do
        local label = Keybinds.display(key, self.state.settings.language)
        if not shown[label] then labels[#labels + 1], shown[label] = label, true end
    end
    table.sort(labels)
    return #labels > 0 and table.concat(labels, " / ") or "-"
end

function App:draw(event)
    local delta = event and event.timeDeltaSecs or 0
    if type(delta) == "number" and delta == delta and delta >= 0 and delta < math.huge then self.inputClock = (self.inputClock or 0) + delta end
    if self.overlayDraft and not self.windowDrag and self.inputClock - self.overlayDraft.time >= 0.4 then self:commitOverlayAppearance() end
    if self.lastInput and self.inputClock - self.lastInput.time > 0.25 then self.lastInput = nil end

    if self.windowDrag then
        local ok, err = pcall(Interaction.updateWindow, self)
        if not ok then Interaction.cancelWindow(self); self.status, self.pending = "Window drag API unavailable.", true; pcall(self.env.report, tostring(err)) end
        return
    end
    if self.itemDrag then
        local ok, err = pcall(Interaction.updateItem, self)
        if not ok then Interaction.cancelItem(self); pcall(self.env.report, tostring(err)); self.pending=true end
        if self.itemDrag then return end -- Preserve the pressed own source until release.
    end
    if self.pending then
        self.pending = false
        local ok, err = pcall(function()
            self.view.render(self)
            if self.hubView then self.hubView.refresh(self) end
        end)
        if not ok then
            self:stop("Rendering failed. Plugin stopped.")
            pcall(self.env.report, tostring(err))
            pcall(self.env.report, self.status)
            self:destroyUI()
            self.pending = false
            if self.view.renderFailure then
                local recovered, problem = pcall(self.view.renderFailure, self)
                if not recovered then pcall(self.env.report, tostring(problem)) end
            end
        end
    end
    self:syncKeySubscription()
end

function App:destroyUI()
    Interaction.cancelItem(self)
    Interaction.cancelWindow(self)
    self.formGeneration = (self.formGeneration or 0) + 1
    self.panelSurface, self.overlaySurface, self.layoutRoot = nil, nil, nil
    self.hoverOwner, self.hoverLabel, self.contextMenus, self.iconActivators = nil, nil, nil, nil
    if self.root then pcall(function() self.root:Destroy() end); self.root = nil end
    if self.overlayRoot then pcall(function() self.overlayRoot:Destroy() end); self.overlayRoot = nil end
    if self.locatorRoot then pcall(function() self.locatorRoot:Destroy() end); self.locatorRoot = nil end
    if self.windowHost then pcall(function() self.windowHost:Destroy() end); self.windowHost = nil end
    -- Do not retain destroyed proxies or callbacks while the plugin is hidden
    -- or unloaded. The next render creates independent current registries.
    self.dropRegions, self.iconContainers, self.iconPreviews, self.hoverCallbacks = {}, {}, {}, {}
end

return App
