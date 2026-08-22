---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesOptionsIndicators
local indicators = EXUI:GetModule('np-options-indicators')

function indicators:GetMenu()
    return {
        {
            id = 'raidtarget',
            name = 'Raid Target',
            options = function()
                return {
                    helpers.Toggle('Enable', 'raidTargetIndicatorEnable'),
                    helpers.Range('Scale', 'raidTargetIndicatorScale', 0.5, 3, 0.1, 25),
                    helpers.Anchor('Anchor Point', 'raidTargetIndicatorAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'raidTargetIndicatorRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'raidTargetIndicatorXOff', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'raidTargetIndicatorYOff', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'classification',
            name = 'Classification',
            options = function()
                return {
                    helpers.Toggle('Enable', 'classificationIconEnable'),
                    helpers.Range('Scale', 'classificationIconScale', 0.5, 3, 0.1, 25),
                    helpers.Anchor('Anchor Point', 'classificationIconAnchorPoint', 25),
                    helpers.Anchor('Relative Point', 'classificationIconRelativeAnchorPoint', 25),
                    helpers.Range('X Offset', 'classificationIconXOff', -200, 200, 1, 25),
                    helpers.Range('Y Offset', 'classificationIconYOff', -200, 200, 1, 25),
                }
            end,
        },
        {
            id = 'mouseover',
            name = 'Mouseover',
            options = function()
                local lightenToggle = helpers.Toggle('Lighten Health', 'mouseoverLightenHealth')
                lightenToggle.depends = function()
                    return helpers.Get('mouseoverHighlightEnable')
                end
                local lightenAmount = helpers.Range('Lighten Amount', 'mouseoverLightenAmount', 0.05, 0.75, 0.05, 50)
                lightenAmount.depends = function()
                    return helpers.Get('mouseoverHighlightEnable') and helpers.Get('mouseoverLightenHealth')
                end
                return {
                    helpers.Toggle('Enable', 'mouseoverHighlightEnable'),
                    helpers.Color('Border Color', 'mouseoverHighlightColor', 50),
                    lightenToggle,
                    lightenAmount,
                }
            end,
        },
        {
            id = 'targethighlight',
            name = 'Target',
            options = function()
                return {
                    helpers.Toggle('Enable', 'targetHighlightEnable'),
                    helpers.Dropdown('Style', 'targetHighlightStyle', function()
                        return {
                            border = 'Border',
                            glow = 'Glow',
                            arrows = 'Arrows',
                        }
                    end, 33),
                    helpers.Color('Color', 'targetHighlightColor', 33),
                    helpers.Toggle('Dim Others', 'targetHighlightDimOthers'),
                    helpers.Range('Dim Alpha', 'targetHighlightDimAlpha', 0.1, 1, 0.05, 50),
                }
            end,
        },
    }
end
