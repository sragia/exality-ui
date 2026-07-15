---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesFocus
local focus = EXUI:GetModule('uf-unit-focus')

focus.unit = 'focus'

focus.Init = function(self)
    core:SetDefaultsForUnit(self.unit, {
        -- General
        ['enable'] = true,
        ['showBlizzardFrame'] = false,
        ['overrideStatusBarTexture'] = '',
        ['overrideDamageAbsorbTexture'] = '',
        ['overrideHealAbsorbTexture'] = '',
        ['overrideHealthColor'] = false,
        ['useCustomHealthColor'] = false,
        ['useSmoothHealthColor'] = false,
        ['customHealthColor'] = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        ['useClassColoredBackdrop'] = false,
        ['useCustomBackdropColor'] = false,
        ['customBackdropColor'] = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
        ['useCustomHealthAbsorbsColor'] = false,
        ['healAbsorbColor'] = { r = 100 / 255, g = 100 / 255, b = 100 / 255, a = 0.8 },
        ['damageAbsorbColor'] = { r = 0, g = 133 / 255, b = 163 / 255, a = 1 },
        -- Size & Position
        ['sizeWidth'] = 130,
        ['sizeHeight'] = 30,
        ['positionAnchorPoint'] = 'BOTTOM',
        ['positionRelativePoint'] = 'BOTTOM',
        ['positionXOff'] = -582,
        ['positionYOff'] = 140,
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'CENTER',
        ['nameRelativeAnchorPoint'] = 'CENTER',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = 0,
        ['nameYOffset'] = 0,
        ['nameMaxWidth'] = 100,
        -- Health Text
        ['healthEnable'] = false,
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
        ['healthpercEnable'] = false,
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
        ['powerEnable'] = false,
        ['powerHeight'] = 5,
        -- Raid Target Indicator
        ['raidTargetIndicatorEnable'] = true,
        ['raidTargetIndicatorAnchorPoint'] = 'CENTER',
        ['raidTargetIndicatorRelativeAnchorPoint'] = 'TOP',
        ['raidTargetIndicatorXOff'] = 0,
        ['raidTargetIndicatorYOff'] = 0,
        ['raidTargetIndicatorScale'] = 0.8,
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = true,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
        -- Raid Roles
        ['raidRolesEnable'] = false,
        ['raidRolesAnchorPoint'] = 'RIGHT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPRIGHT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Phase Indicator
        ['phaseIndicatorEnable'] = false,
        ['phaseIndicatorAnchorPoint'] = 'CENTER',
        ['phaseIndicatorRelativeAnchorPoint'] = 'CENTER',
        ['phaseIndicatorXOff'] = 0,
        ['phaseIndicatorYOff'] = 0,
        ['phaseIndicatorScale'] = 1,
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
        -- Summon Indicator
        ['summonEnable'] = false,
        ['summonAnchorPoint'] = 'TOP',
        ['summonRelativeAnchorPoint'] = 'TOP',
        ['summonXOff'] = 0,
        ['summonYOff'] = 0,
        ['summonScale'] = 1,
        -- Resurrect Indicator
        ['ressurectEnable'] = false,
        ['ressurectAnchorPoint'] = 'CENTER',
        ['ressurectRelativeAnchorPoint'] = 'TOP',
        ['ressurectXOff'] = 0,
        ['ressurectYOff'] = 0,
        ['ressurectScale'] = 1,
        -- Dispel Overlay
        ['dispelOverlayEnable'] = true,
        ['dispelOverlayFilter'] = 'RAID',
        ['dispelOverlayAlpha'] = 1
    })
end

focus.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.RaidRoles = EXUI:GetModule('uf-element-raid-roles'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.PhaseIndicator = EXUI:GetModule('uf-element-phase-indicator'):Create(frame)
    frame.Offline = EXUI:GetModule('uf-element-offline'):Create(frame)
    frame.SummonIndicator = EXUI:GetModule('uf-element-summon-indicator'):Create(frame)
    frame.ResurrectIndicator = EXUI:GetModule('uf-element-ressurect-indicator'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)
    frame.DispelOverlay = EXUI:GetModule('uf-element-dispel-overlay'):Create(frame)

    editor:RegisterFrameForEditor(frame, 'Focus', function(frame)
        core:PersistEditorFramePosition(frame, self.unit)
    end, function(frame)
        frame.editor:SetEditorAsMovable()
    end)
end

focus.Update = function(self, frame)
    local db = core:GetDBForUnit(self.unit)
    if (not db.enable) then
        frame:Disable()
        return;
    end
    if (not frame.isFake) then
        frame:Enable()
    end
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB

    core:ApplyUnitFrameLayout(frame, db)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('focus')
