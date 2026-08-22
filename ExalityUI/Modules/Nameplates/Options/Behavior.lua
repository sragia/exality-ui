---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesOptionsBehavior
local behavior = EXUI:GetModule('np-options-behavior')

function behavior:GetMenu()
    return {
        {
            id = 'stacking',
            name = 'Stacking',
            options = function()
                return {
                    helpers.CVarToggle('Stack Enemies', 'stackEnemies'),
                    helpers.CVarToggle('Stack Friendlies', 'stackFriendlies'),
                    helpers.CVarRange('Overlap Horizontal', 'overlapH', 0.1, 3, 0.05, 50),
                    helpers.CVarRange('Overlap Vertical', 'overlapV', 0.1, 3, 0.05, 50),
                }
            end,
        },
        {
            id = 'visibility',
            name = 'Visibility',
            options = function()
                return {
                    helpers.CVarToggle('Always Show Nameplates', 'showAll'),
                    { type = 'title', label = 'Enemy',    width = 100, size = 18 },
                    helpers.CVarToggle('Enemies', 'showEnemies'),
                    helpers.CVarToggle('Minions', 'showEnemyMinions'),
                    helpers.CVarToggle('Minor', 'showEnemyMinus'),
                    helpers.CVarToggle('Pets', 'showEnemyPets'),
                    helpers.CVarToggle('Guardians', 'showEnemyGuardians'),
                    helpers.CVarToggle('Totems', 'showEnemyTotems'),
                    { type = 'title', label = 'Friendly', width = 100, size = 18 },
                    helpers.CVarToggle('Players', 'showFriendlyPlayers'),
                    helpers.CVarToggle('Minions', 'showFriendlyPlayerMinions'),
                    helpers.CVarToggle('NPCs', 'showFriendlyNpcs'),
                }
            end,
        },
        {
            id = 'offscreen',
            name = 'Off-screen',
            options = function()
                return {
                    helpers.CVarToggle('Show Off-screen', 'showOffscreen'),
                    helpers.CVarDropdown('Target Radial', 'targetRadialPosition', function()
                        return {
                            [0] = 'Off',
                            [1] = 'Target only',
                            [2] = 'All in combat',
                        }
                    end, 50),
                    helpers.CVarRange('Target Behind Distance', 'targetBehindMaxDistance', 0, 60, 1, 50),
                }
            end,
        },
        {
            id = 'distance',
            name = 'Distance',
            options = function()
                return {
                    helpers.CVarRange('NPC Distance', 'maxDistance', 1, 100, 1, 50),
                    helpers.CVarRange('Player Distance', 'playerMaxDistance', 1, 100, 1, 50),
                }
            end,
        },
        {
            id = 'scale',
            name = 'Scale',
            options = function()
                return {
                    helpers.CVarRange('Target Scale', 'selectedScale', 0.5, 2, 0.05, 50),
                    helpers.CVarRange('Min Scale', 'minScale', 0.5, 2, 0.05, 50),
                    helpers.CVarRange('Max Scale', 'maxScale', 0.5, 2, 0.05, 50),
                    helpers.CVarRange('Occluded Alpha', 'occludedAlphaMult', 0, 1, 0.05, 50),
                }
            end,
        },
    }
end
