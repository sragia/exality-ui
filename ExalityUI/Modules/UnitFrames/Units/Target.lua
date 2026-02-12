---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesTarget
local target = EXUI:GetModule('uf-unit-target')

target.unit = 'target'

target.Init = function(self)
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
        ['positionXOff'] = 201,
        ['positionYOff'] = -198,
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 13,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'BOTTOMRIGHT',
        ['nameRelativeAnchorPoint'] = 'BOTTOMRIGHT',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = -3,
        ['nameYOffset'] = 4,
        ['nameMaxWidth'] = 70,
        -- Health Text
        ['healthEnable'] = true,
        ['healthFont'] = 'DMSans',
        ['healthFontSize'] = 11,
        ['healthFontFlag'] = 'OUTLINE',
        ['healthFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthAnchorPoint'] = 'LEFT',
        ['healthRelativeAnchorPoint'] = 'LEFT',
        ['healthXOffset'] = 2,
        ['healthYOffset'] = -11,
        ['healthTag'] = '[curhp:formatted]',
        -- Health Percentage
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 18,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthpercAnchorPoint'] = 'LEFT',
        ['healthpercRelativeAnchorPoint'] = 'LEFT',
        ['healthpercXOffset'] = 2,
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
        -- Raid Roles
        ['raidRolesEnable'] = true,
        ['raidRolesAnchorPoint'] = 'RIGHT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPRIGHT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Combat Indicator
        ['combatIndicatorEnable'] = true,
        ['combatIndicatorScale'] = 1,
        ['combatIndicatorAnchorPoint'] = 'LEFT',
        ['combatIndicatorRelativeAnchorPoint'] = 'TOPLEFT',
        ['combatIndicatorXOff'] = 0,
        ['combatIndicatorYOff'] = 0,
        -- Cast Bar
        ['castbarEnable'] = true,
        ['castbarAnchorToFrame'] = true,
        ['castbarAnchorPoint'] = 'TOP',
        ['castbarRelativeAnchorPoint'] = 'BOTTOM',
        ['castbarXOff'] = 0,
        ['castbarYOff'] = -23,
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
        ['debuffsRelativeAnchorPoint'] = 'BOTTOMRIGHT',
        ['debuffsXOff'] = 1,
        ['debuffsYOff'] = 0,
        ['debuffsIconWidth'] = 40,
        ['debuffsIconHeight'] = 40,
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
        ['debuffsSpacing'] = 1,
        ['debuffsNum'] = 32,
        ['debuffsColNum'] = 6,
        ['debuffsAnchorToBuffs'] = false,
        ['debuffsCountFont'] = 'DMSans',
        ['debuffsCountFontSize'] = 17,
        ['debuffsCountFontFlag'] = 'OUTLINE',
        ['debuffsCountFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['debuffsCountAnchorPoint'] = 'CENTER',
        ['debuffsCountRelativeAnchorPoint'] = 'TOPRIGHT',
        ['debuffsCountXOff'] = -5,
        ['debuffsCountYOff'] = -3,
        ['debuffsDurationFont'] = 'DMSans',
        ['debuffsDurationFontSize'] = 19,
        ['debuffsDurationFontFlag'] = 'OUTLINE',
        -- Buffs
        ['buffsEnable'] = true,
        ['buffsAnchorPoint'] = 'BOTTOMLEFT',
        ['buffsRelativeAnchorPoint'] = 'TOPLEFT',
        ['buffsXOff'] = 0,
        ['buffsYOff'] = 2,
        ['buffsIconWidth'] = 30,
        ['buffsIconHeight'] = 30,
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
        -- Offline Text
        ['offlineEnable'] = false,
        ['offlineFont'] = 'DMSans',
        ['offlineFontSize'] = 10,
        ['offlineFontFlag'] = 'OUTLINE',
        ['offlineFontColor'] = { r = 171 / 255, g = 0, b = 0, a = 1 },
        ['offlineAnchorPoint'] = 'TOP',
        ['offlineRelativeAnchorPoint'] = 'TOP',
        ['offlineXOffset'] = 0,
        ['offlineYOffset'] = -2,
        ['offlineTag'] = '[offline]',
        -- Phase Indicator
        ['phaseIndicatorEnable'] = false,
        ['phaseIndicatorAnchorPoint'] = 'CENTER',
        ['phaseIndicatorRelativeAnchorPoint'] = 'CENTER',
        ['phaseIndicatorXOff'] = 0,
        ['phaseIndicatorYOff'] = 0,
        ['phaseIndicatorScale'] = 1,
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
        -- Summon Indicator
        ['summonEnable'] = false,
        ['summonAnchorPoint'] = 'TOP',
        ['summonRelativeAnchorPoint'] = 'TOP',
        ['summonXOff'] = 0,
        ['summonYOff'] = 0,
        ['summonScale'] = 1,
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

target.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.RaidRoles = EXUI:GetModule('uf-element-raid-roles'):Create(frame)
    frame.CombatIndicator = EXUI:GetModule('uf-element-combat-indicator'):Create(frame)
    frame.Castbar = EXUI:GetModule('uf-element-cast-bar'):Create(frame)
    frame.Buffs = EXUI:GetModule('uf-element-buffs'):Create(frame, 'HELPFUL', 'target')
    frame.Debuffs = EXUI:GetModule('uf-element-debuffs'):Create(frame, 'HARMFUL', 'target')
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.Offline = EXUI:GetModule('uf-element-offline'):Create(frame)
    frame.PhaseIndicator = EXUI:GetModule('uf-element-phase-indicator'):Create(frame)
    frame.PrivateAuras = EXUI:GetModule('uf-element-private-auras'):Create(frame)
    frame.SummonIndicator = EXUI:GetModule('uf-element-summon-indicator'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)
    frame.Auras = EXUI:GetModule('uf-element-auras'):Create(frame, 'target')

    editor:RegisterFrameForEditor(frame, 'Target', function(frame)
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

target.Update = function(self, frame)
    local db = core:GetDBForUnit(self.unit)
    if (not db.enable) then
        frame:Disable()
        return;
    end
    frame:Enable()
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB

    frame:ClearAllPoints()
    frame:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    frame:SetSize(db.sizeWidth, db.sizeHeight)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('target')
