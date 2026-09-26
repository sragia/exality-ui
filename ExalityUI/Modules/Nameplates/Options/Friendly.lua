---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesOptionsFriendly
local friendly = EXUI:GetModule('np-options-friendly')

local function refreshView()
    EXUI:GetModule('nameplates'):RefreshCurrentView()
end

local function cvarToggle(label, key, refresh)
    local field = helpers.CVarToggle(label, key)
    local apply = field.onChange
    field.onChange = function(value)
        apply(value)
        npCore:UpdateAllPlates()
        if refresh then
            C_Timer.After(0, refreshView)
        end
    end
    return field
end

local function revealingToggle(label, key)
    local field = helpers.Toggle(label, key)
    local apply = field.onChange
    field.onChange = function(value)
        apply(value)
        C_Timer.After(0, refreshView)
    end
    return field
end

function friendly:GetMenu()
    local guildColor = helpers.Color('Guild', 'friendlyGuildColor', 50)
    guildColor.depends = function()
        return helpers.Get('friendlyGuildColorEnable')
    end
    local friendColor = helpers.Color('Friend', 'friendlyFriendColor', 50)
    friendColor.depends = function()
        return helpers.Get('friendlyFriendColorEnable')
    end

    return {
        {
            id = 'display',
            name = 'Display',
            options = function()
                return {
                    cvarToggle('Name Only', 'friendlyNameOnly'),
                    cvarToggle('Class Color on Name', 'friendlyNameClassColor'),
                    cvarToggle('Show Realm Name', 'friendlyShowRealm'),
                }
            end,
        },
        {
            id = 'colors',
            name = 'Colors',
            options = function()
                return {
                    revealingToggle('Color Guild Members', 'friendlyGuildColorEnable'),
                    guildColor,
                    revealingToggle('Color Friends', 'friendlyFriendColorEnable'),
                    friendColor,
                }
            end,
        },
        {
            id = 'hitbox',
            name = 'Hit Box',
            options = function()
                return {
                    helpers.Range('Width', 'friendlyHitWidth', 1, 400, 1, 50),
                    helpers.Range('Height', 'friendlyHitHeight', 1, 80, 1, 50),
                }
            end,
        },
    }
end
