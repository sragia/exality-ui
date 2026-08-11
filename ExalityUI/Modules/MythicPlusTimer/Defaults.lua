---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMythicPlusTimerDefaults
local defaults = EXUI:GetModule('mythic-plus-timer-defaults')

defaults.UPGRADE_THRESHOLDS = {
    plus3 = 0.60,
    plus2 = 0.80,
    plus1 = 1.00,
}

defaults.SPACING = {
    section = 4,
    bar = 2,
    bossLine = 2,
    sparkLabel = 2,
}

defaults.SKULL_TEXTURE = [[Interface/Addons/ExalityUI/Assets/Images/MythicPlusTimer/skull.png]]
defaults.BAR_TEXTURE = 'ExalityUI Noisy'
defaults.SPARK_WIDTH = 2

function defaults:CopyTable(value)
    return EXUI.utils.deepCloneTable(value)
end

local function barColorSet(fill, border, background)
    return {
        fill = { r = fill.r, g = fill.g, b = fill.b, a = fill.a or 1 },
        border = { r = border.r, g = border.g, b = border.b, a = border.a or 1 },
        background = { r = background.r, g = background.g, b = background.b, a = background.a or 1 },
    }
end

function defaults:GetDefaults()
    local theme = EXUI.const.theme
    return {
        enable = false,
        anchorPoint = 'TOPRIGHT',
        relativeAnchor = 'TOPRIGHT',
        xOffset = -20,
        yOffset = -200,
        frameStrata = 'MEDIUM',
        frameLevel = 10,
        barWidth = 250,
        timerBarHeight = 20,
        forcesBarHeight = 15,
        barBorderThickness = 1,
        barTexture = 'ExalityUI Noisy',
        hideObjectiveTracker = true,
        showDeathCounter = true,
        showMaxTimer = true,
        showBossNames = true,
        bossAlign = 'RIGHT',

        deathFont = 'DMSans',
        deathFontSize = 14,
        deathFontFlag = 'OUTLINE',
        maxTimerFont = 'DMSans',
        maxTimerFontSize = 13,
        maxTimerFontFlag = 'OUTLINE',
        deathPenaltyFont = 'DMSans',
        deathPenaltyFontSize = 13,
        deathPenaltyFontFlag = 'OUTLINE',
        elapsedFont = 'DMSans',
        elapsedFontSize = 26,
        elapsedFontFlag = 'OUTLINE',
        keyLevelFont = 'DMSans',
        keyLevelFontSize = 18,
        keyLevelFontFlag = 'OUTLINE',
        milestoneFont = 'DMSans',
        milestoneFontSize = 13,
        milestoneFontFlag = 'OUTLINE',
        forcesPercentFont = 'DMSans',
        forcesPercentFontSize = 13,
        forcesPercentFontFlag = 'OUTLINE',
        forcesRawFont = 'DMSans',
        forcesRawFontSize = 13,
        forcesRawFontFlag = 'OUTLINE',
        bossFont = 'DMSans',
        bossFontSize = 13,
        bossFontFlag = 'OUTLINE',

        timerBar = barColorSet({
            r = theme.accent[1],
            g = theme.accent[2],
            b = theme.accent[3],
            a = theme.accent[4] or 1,
        }, {
            r = theme.border[1],
            g = theme.border[2],
            b = theme.border[3],
            a = 1,
        }, {
            r = theme.backgroundDeep[1],
            g = theme.backgroundDeep[2],
            b = theme.backgroundDeep[3],
            a = 1,
        }),

        forcesBar = barColorSet({
            r = 62 / 255,
            g = 233 / 255,
            b = 1,
            a = 1,
        }, {
            r = theme.border[1],
            g = theme.border[2],
            b = theme.border[3],
            a = 1,
        }, {
            r = theme.backgroundDeep[1],
            g = theme.backgroundDeep[2],
            b = theme.backgroundDeep[3],
            a = 1,
        }),

        bossKilledColor = {
            r = 123 / 255,
            g = 1,
            b = 0,
            a = 1,
        },
        bossPendingColor = {
            r = 232 / 255,
            g = 232 / 255,
            b = 232 / 255,
            a = 222 / 255,
        },
        maxTimerColor = {
            r = 155 / 255,
            g = 140 / 255,
            b = 125 / 255,
            a = 1,
        },
        elapsedColor = {
            r = theme.white[1],
            g = theme.white[2],
            b = theme.white[3],
            a = 1,
        },
    }
end
