---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesOptionsCastBar
local castBar = EXUI:GetModule('np-options-cast-bar')

function castBar:GetMenu()
    return {
        {
            id = 'general',
            name = 'General',
            options = function()
                return {
                    helpers.Toggle('Enable', 'castbarEnable'),
                    helpers.Range('Height', 'castbarHeight', 4, 40, 1, 50),
                    helpers.Range('Y Offset', 'castbarYOff', -40, 40, 1, 50),
                }
            end,
        },
        {
            id = 'icon',
            name = 'Icon',
            options = function()
                return {
                    helpers.Toggle('Show Icon', 'castbarShowIcon'),
                    helpers.Range('Width', 'castbarIconWidth', 4, 80, 1, 50),
                }
            end,
        },
        {
            id = 'name',
            name = 'Spell Name',
            options = function()
                return {
                    helpers.Toggle('Show Spell Name', 'castbarShowName'),
                    helpers.Range('Size', 'castbarNameFontSize', 1, 40, 1, 50),
                    { type = 'title', label = 'Position', width = 100, size = 18 },
                    helpers.Anchor('Anchor Point', 'castbarNameAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'castbarNameRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'castbarNameXOffset', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'castbarNameYOffset', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'timer',
            name = 'Timer',
            options = function()
                return {
                    helpers.Toggle('Show Timer', 'castbarShowTime'),
                    helpers.Range('Size', 'castbarTimeFontSize', 1, 40, 1, 50),
                    { type = 'title', label = 'Position', width = 100, size = 18 },
                    helpers.Anchor('Anchor Point', 'castbarTimeAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'castbarTimeRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'castbarTimeXOffset', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'castbarTimeYOffset', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'target',
            name = 'Target',
            options = function()
                return {
                    helpers.Toggle('Show Target', 'castbarShowTarget'),
                    helpers.Range('Size', 'castbarTargetFontSize', 1, 40, 1, 50),
                    { type = 'title', label = 'Position', width = 100, size = 18 },
                    helpers.Anchor('Anchor Point', 'castbarTargetAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'castbarTargetRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'castbarTargetXOffset', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'castbarTargetYOffset', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'interrupted',
            name = 'Interrupted',
            options = function()
                return {
                    helpers.Toggle('Show Interrupted', 'castbarShowInterrupt'),
                    helpers.Range('Hold Duration', 'castbarInterruptHold', 0.2, 3, 0.1, 50),
                    helpers.Color('Bar Color', 'castbarInterruptBarColor', 50),
                    helpers.FontDropdown('Font', 'castbarInterruptFont', 33),
                    helpers.Dropdown('Font Flag', 'castbarInterruptFontFlag', function()
                        return EXUI.const.fontFlags
                    end, 33),
                    helpers.Range('Size', 'castbarInterruptFontSize', 1, 40, 1, 33),
                    helpers.Color('Fallback Color', 'castbarInterruptColor', 50),
                    { type = 'title', label = 'Position', width = 100, size = 18 },
                    helpers.Anchor('Anchor Point', 'castbarInterruptAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'castbarInterruptRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'castbarInterruptXOffset', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'castbarInterruptYOffset', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'font',
            name = 'Font',
            options = function()
                return {
                    helpers.FontDropdown('Font', 'castbarFont', 33),
                    helpers.Dropdown('Font Flag', 'castbarFontFlag', function()
                        return EXUI.const.fontFlags
                    end, 33),
                    helpers.Color('Color', 'castbarFontColor', 33),
                }
            end,
        },
        {
            id = 'colors',
            name = 'Colors',
            options = function()
                return {
                    helpers.Color('Interruptible', 'castbarForegroundColor', 25),
                    helpers.Color('Uninterruptible', 'castbarUninterruptibleColor', 25),
                    helpers.Color('Interrupted', 'castbarInterruptBarColor', 25),
                    helpers.Color('Background', 'castbarBackgroundColor', 25),
                    helpers.Color('Spark', 'castbarSparkColor', 25),
                    helpers.Range('Spark Width', 'castbarSparkWidth', 1, 8, 1, 25),
                }
            end,
        },
    }
end
