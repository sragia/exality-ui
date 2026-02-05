---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesArena
local arena = EXUI:GetModule('uf-unit-arena')

arena.unit = 'arena'
arena.container = nil
arena.frames = {}

arena.Init = function(self)
    self.container = CreateFrame('Frame', nil, UIParent)
    self.container:SetSize(200, 40 * 5 + 5 * 4) -- Container of all boss units
    self.container:SetFrameStrata('LOW')
    self.container:SetFrameLevel(1)

    core:SetDefaultsForUnit(self.unit, {
        -- General
        ['enable'] = false,
        ['showBlizzardFrame'] = false,
        ['overrideStatusBarTexture'] = '',
        ['overrideDamageAbsorbTexture'] = '',
        ['overrideHealAbsorbTexture'] = '',
        ['overrideHealthColor'] = false,
        ['useCustomHealthColor'] = false,
        ['customHealthColor'] = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        ['useClassColoredBackdrop'] = false,
        ['useCustomBackdropColor'] = false,
        ['customBackdropColor'] = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        ['useCustomHealthAbsorbsColor'] = false,
        ['healAbsorbColor'] = { r = 100 / 255, g = 100 / 255, b = 100 / 255, a = 0.8 },
        ['damageAbsorbColor'] = { r = 0, g = 133 / 255, b = 163 / 255, a = 1 },
        -- Container
        ['positionAnchorPoint'] = 'RIGHT',
        ['positionRelativePoint'] = 'RIGHT',
        ['positionXOff'] = -467,
        ['positionYOff'] = 103,
        ['spacing'] = 5,
        -- Individual Unit
        ['sizeWidth'] = 200,
        ['sizeHeight'] = 40,
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'LEFT',
        ['nameRelativeAnchorPoint'] = 'LEFT',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = 0,
        ['nameYOffset'] = 0,
        ['nameMaxWidth'] = 100,
        -- Health Text
        ['healthEnable'] = true,
        ['healthFont'] = 'DMSans',
        ['healthFontSize'] = 12,
        ['healthFontFlag'] = 'OUTLINE',
        ['healthFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthAnchorPoint'] = 'RIGHT',
        ['healthRelativeAnchorPoint'] = 'RIGHT',
        ['healthXOffset'] = -5,
        ['healthYOffset'] = -10,
        ['healthTag'] = '[curhp:formatted]',
        -- Health Percentage
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 16,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthpercAnchorPoint'] = 'RIGHT',
        ['healthpercRelativeAnchorPoint'] = 'RIGHT',
        ['healthpercXOffset'] = -5,
        ['healthpercYOffset'] = 3,
        ['healthpercTag'] = '[perhp]%',
        -- Power
        ['powerEnable'] = true,
        ['powerHeight'] = 5,
        -- Raid Target Indicator
        ['raidTargetIndicatorEnable'] = true,
        ['raidTargetIndicatorScale'] = 1,
        ['raidTargetIndicatorAnchorPoint'] = 'CENTER',
        ['raidTargetIndicatorRelativeAnchorPoint'] = 'TOP',
        ['raidTargetIndicatorXOff'] = 0,
        ['raidTargetIndicatorYOff'] = 0,
        ['raidRolesEnable'] = true,
        ['raidRolesAnchorPoint'] = 'RIGHT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPRIGHT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Cast Bar
        ['castbarEnable'] = false,
        ['castbarAnchorToFrame'] = true,
        ['castbarAnchorPoint'] = 'TOP',
        ['castbarRelativeAnchorPoint'] = 'BOTTOM',
        ['castbarXOff'] = 0,
        ['castbarYOff'] = 0,
        ['castbarAnchorPointUIParent'] = 'CENTER',
        ['castbarRelativeAnchorPointUIParent'] = 'CENTER',
        ['castbarXOffUIParent'] = 100,
        ['castbarYOffUIParent'] = -100,
        ['castbarMatchFrameWidth'] = true,
        ['castbarWidth'] = 200,
        ['castbarHeight'] = 20,
        ['castbarFont'] = 'DMSans',
        ['castbarFontSize'] = 12,
        ['castbarFontFlag'] = 'OUTLINE',
        ['castbarFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['castbarBackgroundColor'] = { r = 0, g = 0, b = 0, a = 0.5 },
        ['castbarBackgroundBorderColor'] = { r = 0, g = 0, b = 0, a = 1 },
        ['castbarForegroundColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['castbarEmpoweredStageWidth'] = 1,
        ['castbarEmpoweredStageColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['castbarSparkWidth'] = 1,
        ['castbarSparkColor'] = { r = 1, g = 1, b = 1, a = 1 },
        -- Debuffs
        ['debuffsEnable'] = true,
        ['debuffsAnchorPoint'] = 'BOTTOMLEFT',
        ['debuffsRelativeAnchorPoint'] = 'TOPLEFT',
        ['debuffsXOff'] = 0,
        ['debuffsYOff'] = 2,
        ['debuffsIconWidth'] = 20,
        ['debuffsIconHeight'] = 20,
        ['debuffsFilters'] = {
            HELPFUL = false,
            HARMFUL = true,
            RAID = false,
            PLAYER = true,
            INCLUDE_NAME_PLATE_ONLY = false,
            CROWD_CONTROL = false,
            BIG_DEFENSIVE = false,
            RAID_PLAYER_DISPELLABLE = false,
            RAID_IN_COMBAT = false,
            IMPORTANT = false
        },
        ['debuffsSpacing'] = 2,
        ['debuffsNum'] = 32,
        ['debuffsColNum'] = 6,
        ['debuffsAnchorToBuffs'] = true,
        ['debuffsCountFont'] = 'DMSans',
        ['debuffsCountFontSize'] = 12,
        ['debuffsCountFontFlag'] = 'OUTLINE',
        ['debuffsCountFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['debuffsCountAnchorPoint'] = 'CENTER',
        ['debuffsCountRelativeAnchorPoint'] = 'CENTER',
        ['debuffsCountXOff'] = 0,
        ['debuffsCountYOff'] = 0,
        ['debuffsDurationFont'] = 'DMSans',
        ['debuffsDurationFontSize'] = 12,
        ['debuffsDurationFontFlag'] = 'OUTLINE',
        -- Buffs
        ['buffsEnable'] = true,
        ['buffsAnchorPoint'] = 'BOTTOMLEFT',
        ['buffsRelativeAnchorPoint'] = 'TOPLEFT',
        ['buffsXOff'] = 0,
        ['buffsYOff'] = 2,
        ['buffsIconWidth'] = 20,
        ['buffsIconHeight'] = 20,
        ['buffsFilters'] = {
            HELPFUL = true,
            HARMFUL = false,
            RAID = false,
            PLAYER = false,
            INCLUDE_NAME_PLATE_ONLY = false,
            CROWD_CONTROL = false,
            BIG_DEFENSIVE = false,
            RAID_PLAYER_DISPELLABLE = false,
            RAID_IN_COMBAT = false,
            IMPORTANT = false
        },
        ['buffsSpacing'] = 2,
        ['buffsNum'] = 32,
        ['buffsColNum'] = 6,
        ['buffsAnchorToDebuffs'] = false,
        ['buffsCountFont'] = 'DMSans',
        ['buffsCountFontSize'] = 12,
        ['buffsCountFontFlag'] = 'OUTLINE',
        ['buffsCountFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['buffsCountAnchorPoint'] = 'CENTER',
        ['buffsCountRelativeAnchorPoint'] = 'CENTER',
        ['buffsCountXOff'] = 0,
        ['buffsCountYOff'] = 0,
        ['buffsDurationFont'] = 'DMSans',
        ['buffsDurationFontSize'] = 12,
        ['buffsDurationFontFlag'] = 'OUTLINE',
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = true,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
        -- Private Auras
        ['privateAurasEnable'] = false,
        ['privateAurasMaxNum'] = 5,
        ['privateAurasIconWidth'] = 20,
        ['privateAurasDisableBorder'] = false,
        ['privateAurasDisableTooltip'] = false,
        ['privateAurasIconHeight'] = 20,
        ['privateAurasSpacingX'] = 1,
        ['privateAurasSpacingY'] = 1,
        ['privateAurasGrowthX'] = 'LEFT',
        ['privateAurasGrowthY'] = 'UP',
        ['privateAurasBorderScale'] = 1,
        ['privateAurasDisableCooldownSpiral'] = false,
        ['privateAurasDisableCooldownText'] = false,
        ['privateAurasMaxCols'] = 6,
        ['privateAurasAnchorPoint'] = 'CENTER',
        ['privateAurasRelativeAnchorPoint'] = 'CENTER',
        ['privateAurasXOff'] = 0,
        ['privateAurasYOff'] = 0,
    })

    self.container:SetPoint(
        core:GetValueForUnit('arena', 'positionAnchorPoint'),
        UIParent,
        core:GetValueForUnit('arena', 'positionRelativePoint'),
        core:GetValueForUnit('arena', 'positionXOff'),
        core:GetValueForUnit('arena', 'positionYOff')
    )

    editor:RegisterFrameForEditor(self.container, 'Arena Frames', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        core:UpdateValueForUnit(self.unit, 'positionAnchorPoint', point)
        core:UpdateValueForUnit(self.unit, 'positionRelativePoint', relativePoint)
        core:UpdateValueForUnit(self.unit, 'positionXOff', xOfs)
        core:UpdateValueForUnit(self.unit, 'positionYOff', yOfs)
        core:UpdateFrameForUnit(self.unit)
    end, function(frame)
        frame.editor:SetEditorAsMovable()
    end)
end

arena.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.Buffs = EXUI:GetModule('uf-element-buffs'):Create(frame)
    frame.Debuffs = EXUI:GetModule('uf-element-debuffs'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.Castbar = EXUI:GetModule('uf-element-cast-bar'):Create(frame)
    frame.PrivateAuras = EXUI:GetModule('uf-element-private-auras'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)

    frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
end

arena.Update = function(self, frame)
    self.frames[frame.index] = frame
    local db = core:GetDBForUnit(self.unit)
    local generalDB = core:GetDBForUnit('general')
    self.container:SetSize(db.sizeWidth, db.sizeHeight * #self.frames + db.spacing * (#self.frames - 1))
    self.container:ClearAllPoints()
    self.container:SetPoint(
        db.positionAnchorPoint,
        UIParent,
        db.positionRelativePoint,
        db.positionXOff,
        db.positionYOff
    )


    frame.db = db
    frame.generalDB = generalDB
    frame:SetSize(db.sizeWidth, db.sizeHeight)
    frame:SetFrameLevel(self.container:GetFrameLevel() + 1)

    if (frame.index == 1) then
        frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
    else
        frame:SetPoint('TOPLEFT', self.frames[frame.index - 1], 'BOTTOMLEFT', 0, -db.spacing)
    end

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('arena', true, 5)
