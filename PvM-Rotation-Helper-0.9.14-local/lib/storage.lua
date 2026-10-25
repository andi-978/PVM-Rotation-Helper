-- Versioned local storage. Validation failures never overwrite saved data.
local Model = require("lib/model")
local U = require("lib/util")
local S = {}
-- Persisted namespace identifiers are kept for compatibility with saved profiles.
S.KEY = "pvm_lernstudio_v1"
S.BACKUP = "pvm_lernstudio_previous_v1"

-- A previously saved client-added ability can outlive a temporarily missing
-- book enum. Restore only references already present in this saved record;
-- the catalogue keeps them out of new choices until current membership returns.
local function restoreSavedAbilities(value, catalogue, config)
    if not config or type(catalogue.restoreSaved) ~= "function" or type(value) ~= "table"
        or not U.array(value.profiles, Model.LIMIT.profiles) then return end
    local function restore(ability)
        if type(ability) == "string" and ability ~= "" then pcall(catalogue.restoreSaved, ability, config) end
    end
    for _, profile in ipairs(value.profiles) do if type(profile) == "table" then
        if U.array(profile.phases, Model.LIMIT.phases) then
            for _, phase in ipairs(profile.phases) do
                if type(phase) == "table" and U.array(phase.steps) then
                    for _, step in ipairs(phase.steps) do if type(step) == "table" then restore(step.ability) end end
                end
            end
        end
        if U.array(profile.bars, Model.LIMIT.bars) then
            for _, bar in ipairs(profile.bars) do
                if type(bar) == "table" and U.array(bar.slots, Model.LIMIT.slots) then
                    for _, slot in ipairs(bar.slots) do if type(slot) == "table" then restore(slot.ability) end end
                end
            end
        end
        if type(profile.bindings) == "table" then
            local count = 0
            for ability in pairs(profile.bindings) do
                count = count + 1
                if count > 4096 then break end
                restore(ability)
            end
        end
    end end
end

function S.load(db, catalogue, config)
    local ok, value = pcall(function() return db:GetStructuredData(S.KEY) end)
    if not ok then return Model.defaults(), "Storage could not be read. Reload saved data to retry.", true end
    if value == nil then
        -- A typed getter also returns nil for a type mismatch. Never interpret
        -- that as permission to replace an existing, unreadable record.
        local checked, exists = pcall(function() return db:CheckExists(S.KEY) end)
        if not checked or exists then return Model.defaults(), "Storage record is unreadable. Existing data is protected.", true end
        return Model.defaults(), nil, false
    end
    restoreSavedAbilities(value, catalogue, config)
    local original = value
    local migrated, result = pcall(Model.upgrade, value, catalogue)
    if migrated then value = result end
    local checked, valid, reason = pcall(Model.validate, value, catalogue)
    if checked and valid then return U.copy(value), nil, false, U.copy(original) end
    return Model.defaults(), checked and reason or "Stored data could not be validated. Existing data is protected.", true
end

function S.save(db, value, previous, catalogue, expected)
    local valid, reason = Model.validate(value, catalogue)
    if not valid then return false, reason end
    -- PersistentDB is shared by all beta clients on this device. Refuse a stale
    -- editor rather than overwriting another instance. The API has no atomic CAS;
    -- simultaneous writes can still race between this check and SetStructuredData.
    local checked, current = pcall(function() return db:GetStructuredData(S.KEY) end)
    if not checked then return false, "Save failed. Previous settings remain active." end
    if current == nil then
        local known, exists = pcall(function() return db:CheckExists(S.KEY) end)
        if not known then return false, "Save failed. Previous settings remain active." end
        if exists then return false, "Storage changed in another client. Reload the plugin." end
    end
    if not U.equal(current, expected) then return false, "Storage changed in another client. Reload the plugin." end
    local ok, saved = pcall(function()
        if previous and not db:SetStructuredData(S.BACKUP, U.copy(previous)) then return false end
        return db:SetStructuredData(S.KEY, U.copy(value))
    end)
    if not ok or not saved then return false, "Save failed. Previous settings remain active." end
    return true
end

return S
