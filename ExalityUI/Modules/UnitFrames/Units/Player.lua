---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesPlayer
local player = EXUI:GetModule('uf-unit-player')

player.unit = 'player'

player.Init = function(self)
    core:SetDefaultsForUnit(self.unit, {
        -- General
        ['enable'] = true,
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
        -- Size & Position
        ['sizeWidth'] = 200,
        ['sizeHeight'] = 40,
        ['positionAnchorPoint'] = 'CENTER',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = -201,
        ['positionYOff'] = -198,
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 13,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'BOTTOMLEFT',
        ['nameTag'] = '[name]',
        ['nameRelativeAnchorPoint'] = 'BOTTOMLEFT',
        ['nameXOffset'] = 3,
        ['nameYOffset'] = 2,
        ['nameMaxWidth'] = 100,
        -- Health
        ['healthEnable'] = true,
        ['healthFont'] = 'DMSans',
        ['healthFontSize'] = 11,
        ['healthFontFlag'] = 'OUTLINE',
        ['healthFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthAnchorPoint'] = 'RIGHT',
        ['healthRelativeAnchorPoint'] = 'RIGHT',
        ['healthXOffset'] = -1,
        ['healthYOffset'] = -11,
        ['healthTag'] = '[curhp:formatted]',
        -- Health Percentage
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 18,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthpercAnchorPoint'] = 'RIGHT',
        ['healthpercRelativeAnchorPoint'] = 'RIGHT',
        ['healthpercXOffset'] = -2,
        ['healthpercYOffset'] = 3,
        ['healthpercTag'] = '[perhp]%',
        -- Raid Target Indicator
        ['raidTargetIndicatorEnable'] = true,
        ['raidTargetIndicatorAnchorPoint'] = 'CENTER',
        ['raidTargetIndicatorRelativeAnchorPoint'] = 'TOP',
        ['raidTargetIndicatorXOff'] = 0,
        ['raidTargetIndicatorYOff'] = 0,
        ['raidTargetIndicatorScale'] = 1,
        -- Raid Roles
        ['raidRolesEnable'] = true,
        ['raidRolesAnchorPoint'] = 'LEFT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPLEFT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Combat Indicator
        ['combatIndicatorEnable'] = true,
        ['combatIndicatorAnchorPoint'] = 'RIGHT',
        ['combatIndicatorRelativeAnchorPoint'] = 'TOPRIGHT',
        ['combatIndicatorXOff'] = 0,
        ['combatIndicatorYOff'] = 0,
        ['combatIndicatorScale'] = 1,
        -- Cast Bar
        ['castbarEnable'] = true,
        ['castbarAnchorToFrame'] = false,
        ['castbarAnchorPoint'] = 'TOP',
        ['castbarRelativeAnchorPoint'] = 'BOTTOM',
        ['castbarXOff'] = 0,
        ['castbarYOff'] = 0,
        ['castbarAnchorPointUIParent'] = 'CENTER',
        ['castbarRelativeAnchorPointUIParent'] = 'CENTER',
        ['castbarXOffUIParent'] = 0,
        ['castbarYOffUIParent'] = -349,
        ['castbarMatchFrameWidth'] = false,
        ['castbarWidth'] = 300,
        ['castbarHeight'] = 35,
        ['castbarFont'] = 'DMSans',
        ['castbarFontSize'] = 14,
        ['castbarFontFlag'] = 'OUTLINE',
        ['castbarFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['castbarBackgroundColor'] = { r = 0, g = 0, b = 0, a = 0.5 },
        ['castbarBackgroundBorderColor'] = { r = 0, g = 0, b = 0, a = 1 },
        ['castbarForegroundColor'] = { r = 0.35, g = 0.17, b = 0, a = 1 },
        ['castbarBarTexture'] = 'ExalityUI Status Bar',
        ['castbarEmpoweredStageWidth'] = 1,
        ['castbarEmpoweredStageColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['castbarSparkWidth'] = 1,
        ['castbarSparkColor'] = { r = 1, g = 1, b = 1, a = 1 },
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = true,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
        -- Debuffs
        ['debuffsEnable'] = false,
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
        ['buffsEnable'] = false,
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
            RAID_IN_COMBAT = false
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
        -- Power
        ['powerEnable'] = false,
        ['powerHeight'] = 5,
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
        -- Custom Auras
        ['aurasEnable'] = false,
        ['aurasAnchorPoint'] = 'CENTER',
        ['aurasRelativeAnchorPoint'] = 'CENTER',
        ['aurasXOff'] = 0,
        ['aurasYOff'] = 0,
        ['aurasIconWidth'] = 20,
        ['aurasIconHeight'] = 20,
        ['aurasFilters'] = {
            HELPFUL = false,
            HARMFUL = false,
            RAID = false,
            PLAYER = false,
            INCLUDE_NAME_PLATE_ONLY = false,
            CROWD_CONTROL = false,
            BIG_DEFENSIVE = false,
            RAID_PLAYER_DISPELLABLE = false,
            RAID_IN_COMBAT = false
        },
        ['aurasSpacing'] = 2,
        ['aurasNum'] = 32,
        ['aurasColNum'] = 6,
        ['aurasAnchorToDebuffs'] = false,
        ['aurasCountFont'] = 'DMSans',
        ['aurasCountFontSize'] = 12,
        ['aurasCountFontFlag'] = 'OUTLINE',
        ['aurasCountFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['aurasCountAnchorPoint'] = 'CENTER',
        ['aurasCountRelativeAnchorPoint'] = 'CENTER',
        ['aurasCountXOff'] = 0,
        ['aurasCountYOff'] = 0,
        ['aurasDurationFont'] = 'DMSans',
        ['aurasDurationFontSize'] = 12,
        ['aurasDurationFontFlag'] = 'OUTLINE',
    })
end

player.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.RaidRoles = EXUI:GetModule('uf-element-raid-roles'):Create(frame)
    frame.CombatIndicator = EXUI:GetModule('uf-element-combat-indicator'):Create(frame)
    frame.Castbar = EXUI:GetModule('uf-element-cast-bar'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.Buffs = EXUI:GetModule('uf-element-buffs'):Create(frame, 'HELPFUL', 'player')
    frame.Debuffs = EXUI:GetModule('uf-element-debuffs'):Create(frame, 'HARMFUL', 'player')
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.PrivateAuras = EXUI:GetModule('uf-element-private-auras'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)
    frame.Auras = EXUI:GetModule('uf-element-auras'):Create(frame, 'player')

    editor:RegisterFrameForEditor(frame, 'Player', function(frame)
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

player.Update = function(self, frame)
    local db = core:GetDBForUnit('player')
    if (not db.enable) then
        frame:Disable()
        return
    end
    if (not frame.isFake) then
        frame:Enable()
    end
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB
    frame:ClearAllPoints()
    frame:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    frame:SetSize(db.sizeWidth, db.sizeHeight)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('player')
