-- Optional local trial: match an official action-bar menu selection to the
-- expected Sprite. This reads no key state and never edits game components.
-- A selected Op is only an attempted click, not proof of ability execution.
local Locator = require("lib/locator")
local Click = {}

function Click.matches(entry, ability, env, catalogue)
    local kinds, actions = env.menuEntryTypes, env.menuActionTypes
    if not entry or not kinds or not actions or not kinds.INTERFACE or not actions.IF_BUTTONX1
        or not actions.IF_BUTTONX2 or entry.actionEntryType ~= kinds.INTERFACE then return false end
    if entry.actionType ~= actions.IF_BUTTONX1 and entry.actionType ~= actions.IF_BUTTONX2 then return false end
    local data = entry.componentData
    -- Only the first native component Op is considered. Its real meaning on
    -- each beta action-bar variant must be checked by a human in the client.
    if not data or data.opIndex ~= 1 then return false end
    local source = data.component
    if not source or not source.visibleGlobal or source.width < 12 or source.width > 160
        or source.height < 12 or source.height > 160 then return false end
    local objectOK, objectID = pcall(function() return source.associatedObjectID end)
    if objectOK and type(objectID) == "number" and objectID > 0 then return false end
    local sprite = catalogue.resolve(ability, env.config)
    if not sprite then return false end
    local xy = source.xyGlobal
    local matches = Locator.matching(env, sprite)
    for _, slot in ipairs(matches) do
        local cx, cy = slot.x + slot.width / 2, slot.y + slot.height / 2
        local sx, sy = xy.x + source.width / 2, xy.y + source.height / 2
        -- The source and Sprite must cover one another's centre, on the same
        -- named, visible action-bar interface. A label or whole-bar click fails.
        if source.interfaceID == slot.interfaceID
            and cx >= xy.x and cx < xy.x + source.width and cy >= xy.y and cy < xy.y + source.height
            and sx >= slot.x and sx < slot.x + slot.width and sy >= slot.y and sy < slot.y + slot.height then
            return true
        end
    end
    return false
end

return Click
