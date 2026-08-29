---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDefaults
local adDefaults = EXUI:GetModule('aura-displays-defaults')

---@class EXUINameplatesAurasDefaults
local defaults = EXUI:GetModule('np-auras-defaults')

-- One-time starter aura displays. Seeded into a profile once; never re-applied after delete.
defaults.STARTER_DISPLAYS = {
    Ym5ZfJvbzbCi = {
        enable = true,
        name = 'Buffs',
        anchorPoint = 'TOPRIGHT',
        relativePoint = 'LEFT',
        containerAnchorPoint = 'TOPRIGHT',
        XOff = -1,
        YOff = 15,
        frameStrata = 'MEDIUM',
        frameLevel = 10,
        flowLayoutAxis = 'Rows',
        horizontalGrowth = 'LEFT',
        verticalGrowth = 'UP',
        matchUnitFrameWidth = true,
        rowWidth = 140,
        paddingLeft = 0,
        paddingRight = 0,
        paddingTop = 0,
        paddingBottom = 0,
        groupOrder = { 'iPU96Mvprkhg' },
        groups = {
            iPU96Mvprkhg = {
                enable = true,
                conditions = {
                    enable = true,
                    filterTokens = {
                        { token = 'HELPFUL', negated = false },
                    },
                    maxFrameCount = 3,
                    isFromPlayerOrPlayerPet = false,
                },
                visual = {
                    iconWidth = 30,
                    iconHeight = 30,
                    iconZoom = 15,
                    stackFontSize = 14,
                    stackAnchorPoint = 'LEFT',
                    stackRelativePoint = 'TOPLEFT',
                    stackXOff = 0,
                    stackYOff = 0,
                    durationFontSize = 13,
                    durationAnchorPoint = 'BOTTOMLEFT',
                    durationRelativePoint = 'BOTTOMLEFT',
                    showDurationCooldown = false,
                    showDispelIcon = true,
                    dispelBorderStyle = 'Minimal',
                    dispelIconSize = 11,
                    dispelIconAnchorPoint = 'CENTER',
                    dispelIconRelativePoint = 'TOPRIGHT',
                    dispelIconXOff = -4,
                },
            },
        },
    },
    qSSi3lVrcllg = {
        enable = true,
        name = 'My Debuffs',
        anchorPoint = 'BOTTOMRIGHT',
        relativePoint = 'TOPRIGHT',
        containerAnchorPoint = 'BOTTOMRIGHT',
        XOff = 0,
        YOff = 0,
        frameStrata = 'LOW',
        frameLevel = 10,
        flowLayoutAxis = 'Rows',
        horizontalGrowth = 'LEFT',
        verticalGrowth = 'UP',
        matchUnitFrameWidth = true,
        rowWidth = 140,
        paddingLeft = 0,
        paddingRight = 0,
        paddingTop = 0,
        paddingBottom = 0,
        groupOrder = { 'k92reIkYHH9r' },
        groups = {
            k92reIkYHH9r = {
                enable = true,
                conditions = {
                    enable = true,
                    filterTokens = {
                        { token = 'HARMFUL', negated = false },
                        { token = 'PLAYER', negated = false },
                        { token = 'CROWD_CONTROL', negated = true },
                    },
                    maxFrameCount = 8,
                    excludeSpellIDs = '1302139, 469882, 197277',
                },
                visual = {
                    iconWidth = 30,
                    iconHeight = 25,
                    iconZoom = 15,
                    elementSpacingX = 1,
                    elementSpacingY = 1,
                    stackFontSize = 14,
                    stackAnchorPoint = 'LEFT',
                    stackRelativePoint = 'TOPLEFT',
                    stackXOff = 2,
                    stackYOff = 0,
                    durationFontSize = 12,
                    durationAnchorPoint = 'BOTTOMLEFT',
                    durationRelativePoint = 'BOTTOMLEFT',
                    durationXOff = 1,
                    durationYOff = 0,
                    showDurationCooldown = false,
                    showDispelBorder = false,
                    dispelBorderStyle = 'Minimal',
                    dispelIconSize = 13,
                    dispelIconAnchorPoint = 'CENTER',
                    dispelIconXOff = -5,
                },
            },
        },
    },
    ic8jkFvMrjHh = {
        enable = true,
        name = 'Crowd Control',
        anchorPoint = 'LEFT',
        relativePoint = 'RIGHT',
        containerAnchorPoint = 'LEFT',
        XOff = 5,
        YOff = 0,
        frameStrata = 'MEDIUM',
        frameLevel = 10,
        flowLayoutAxis = 'Rows',
        horizontalGrowth = 'RIGHT',
        verticalGrowth = 'DOWN',
        matchUnitFrameWidth = false,
        rowWidth = 174,
        paddingLeft = 0,
        paddingRight = 0,
        paddingTop = 0,
        paddingBottom = 0,
        groupOrder = { 'lrNnAdJpODck' },
        groups = {
            lrNnAdJpODck = {
                enable = true,
                conditions = {
                    enable = true,
                    filterTokens = {
                        { token = 'HARMFUL', negated = false },
                        { token = 'CROWD_CONTROL', negated = false },
                    },
                    maxFrameCount = 4,
                },
                visual = {
                    iconWidth = 40,
                    iconHeight = 40,
                    iconZoom = 15,
                    elementSpacingX = 1,
                    stackFontSize = 17,
                    stackAnchorPoint = 'TOPLEFT',
                    stackRelativePoint = 'TOPLEFT',
                    stackXOff = 1,
                    stackYOff = -1,
                    durationFontSize = 14,
                    durationAnchorPoint = 'BOTTOMLEFT',
                    durationRelativePoint = 'BOTTOMLEFT',
                    durationXOff = 1,
                    durationYOff = 1,
                    showDurationCooldown = true,
                    showDispelBorder = false,
                },
            },
        },
    },
}

function defaults:SeedStarterDisplays(db)
    if not db or db.__exuiStarterDisplaysSeeded then
        return false
    end
    db.displays = db.displays or {}
    for displayID, display in pairs(self.STARTER_DISPLAYS) do
        if not db.displays[displayID] then
            local copy = self:CopyTable(display)
            if copy.groups then
                for _, group in pairs(copy.groups) do
                    adDefaults:MergeGroupDefaults(group)
                end
            end
            db.displays[displayID] = copy
        end
    end
    db.__exuiStarterDisplaysSeeded = true
    return true
end
