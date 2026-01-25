---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesParty
local party = EXUI:GetModule('uf-unit-party')

party.unit = 'party'
party.container = nil
party.frames = {}

party.Init = function(self)
    core:SetDefaultsForUnit(self.unit, {
        -- Header Specific
        ['sizeWidth'] = 160,
        ['sizeHeight'] = 50,
        ['positionAnchorPoint'] = 'TOPRIGHT',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = -331,
        ['positionYOff'] = 226,
        ['spacing'] = 1,
        -- Name
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['nameAnchorPoint'] = 'BOTTOMLEFT',
        ['nameRelativeAnchorPoint'] = 'BOTTOMLEFT',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = 3,
        ['nameYOffset'] = 6,
        ['nameMaxWidth'] = 60,
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
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 13,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['healthpercAnchorPoint'] = 'BOTTOMRIGHT',
        ['healthpercRelativeAnchorPoint'] = 'BOTTOMRIGHT',
        ['healthpercXOffset'] = -3,
        ['healthpercYOffset'] = 9,
        ['healthpercTag'] = '[perhp]%',
        -- Power
        ['powerEnable'] = true,
        ['powerHeight'] = 3,
        -- Debuffs
        ['debuffsEnable'] = true,
        ['debuffsAnchorPoint'] = 'TOPRIGHT',
        ['debuffsRelativeAnchorPoint'] = 'RIGHT',
        ['debuffsXOff'] = -2,
        ['debuffsYOff'] = 20,
        ['debuffsIconWidth'] = 27,
        ['debuffsIconHeight'] = 19,
        ['debuffsOnlyShowPlayer'] = false,
        ['debuffsSpacing'] = 2,
        ['debuffsNum'] = 4,
        ['debuffsColNum'] = 6,
        ['debuffsAnchorToBuffs'] = false,
        ['debuffsCountFont'] = 'DMSans',
        ['debuffsCountFontSize'] = 15,
        ['debuffsCountFontFlag'] = 'OUTLINE',
        ['debuffsCountFontColor'] = { r = 1, g = 1, b = 1, a = 1 },
        ['debuffsCountAnchorPoint'] = 'CENTER',
        ['debuffsCountRelativeAnchorPoint'] = 'TOPRIGHT',
        ['debuffsCountXOff'] = 0,
        ['debuffsCountYOff'] = 0,
        ['debuffsDurationFont'] = 'DMSans',
        ['debuffsDurationFontSize'] = 10,
        ['debuffsDurationFontFlag'] = 'OUTLINE',
        -- Buffs
        ['buffsEnable'] = false,
        ['buffsAnchorPoint'] = 'BOTTOMLEFT',
        ['buffsRelativeAnchorPoint'] = 'TOPLEFT',
        ['buffsXOff'] = 0,
        ['buffsYOff'] = 2,
        ['buffsIconWidth'] = 20,
        ['buffsIconHeight'] = 20,
        ['buffsOnlyShowPlayer'] = false,
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
        -- Raid Roles
        ['raidRolesEnable'] = true,
        ['raidRolesAnchorPoint'] = 'LEFT',
        ['raidRolesRelativeAnchorPoint'] = 'TOPLEFT',
        ['raidRolesXOff'] = 0,
        ['raidRolesYOff'] = 0,
        ['raidRolesScale'] = 1,
        -- Raid Target Indicator
        ['raidTargetIndicatorEnable'] = true,
        ['raidTargetIndicatorAnchorPoint'] = 'CENTER',
        ['raidTargetIndicatorRelativeAnchorPoint'] = 'TOP',
        ['raidTargetIndicatorXOff'] = 0,
        ['raidTargetIndicatorYOff'] = 0,
        ['raidTargetIndicatorScale'] = 1,
        -- Offline Text
        ['offlineEnable'] = true,
        ['offlineFont'] = 'DMSans',
        ['offlineFontSize'] = 10,
        ['offlineFontFlag'] = 'OUTLINE',
        ['offlineFontColor'] = { r = 171 / 255, g = 0, b = 0, a = 1 },
        ['offlineAnchorPoint'] = 'TOP',
        ['offlineRelativeAnchorPoint'] = 'TOP',
        ['offlineXOffset'] = 0,
        ['offlineYOffset'] = -2,
        ['offlineTag'] = '[offline]',
        -- Resurrect Indicator
        ['ressurectEnable'] = true,
        ['ressurectAnchorPoint'] = 'CENTER',
        ['ressurectRelativeAnchorPoint'] = 'TOP',
        ['ressurectXOff'] = 0,
        ['ressurectYOff'] = 0,
        ['ressurectScale'] = 1,
        -- Summon Indicator
        ['summonEnable'] = true,
        ['summonAnchorPoint'] = 'TOP',
        ['summonRelativeAnchorPoint'] = 'TOP',
        ['summonXOff'] = 0,
        ['summonYOff'] = 0,
        ['summonScale'] = 1,
        -- Private Auras
        ['privateAurasEnable'] = false,
        ['privateAurasMaxNum'] = 5,
        ['privateAurasIconWidth'] = 20,
        ['privateAurasIconHeight'] = 20,
        ['privateAurasSpacing'] = 1,
        ['privateAurasGrowthX'] = 'LEFT',
        ['privateAurasAnchorPoint'] = 'CENTER',
        ['privateAurasRelativeAnchorPoint'] = 'CENTER',
        ['privateAurasXOff'] = 0,
        ['privateAurasYOff'] = 0,
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = true,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
        -- Phase Indicator
        ['phaseIndicatorEnable'] = true,
        ['phaseIndicatorAnchorPoint'] = 'CENTER',
        ['phaseIndicatorRelativeAnchorPoint'] = 'CENTER',
        ['phaseIndicatorXOff'] = 0,
        ['phaseIndicatorYOff'] = 0,
        ['phaseIndicatorScale'] = 1,
    })
end

party.Create = function(self, frame, unit)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.Range = EXUI:GetModule('uf-element-range'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)
    frame.Buffs = EXUI:GetModule('uf-element-buffs'):Create(frame, 'HELPFUL|RAID')
    frame.Debuffs = EXUI:GetModule('uf-element-debuffs'):Create(frame, 'HARMFUL|RAID')
    frame.RaidTargetIndicator = EXUI:GetModule('uf-element-raid-target-indicator'):Create(frame)
    frame.RaidRoles = EXUI:GetModule('uf-element-raid-roles'):Create(frame)
    frame.PhaseIndicator = EXUI:GetModule('uf-element-phase-indicator'):Create(frame)
    frame.Offline = EXUI:GetModule('uf-element-offline'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.ReadyCheckIndicator = EXUI:GetModule('uf-element-ready-check-indicator'):Create(frame)
    frame.ResurrectIndicator = EXUI:GetModule('uf-element-ressurect-indicator'):Create(frame)
    frame.SummonIndicator = EXUI:GetModule('uf-element-summon-indicator'):Create(frame)
    frame.PrivateAuras = EXUI:GetModule('uf-element-private-auras'):Create(frame)

    frame.Update = function(self) party:Update(self) end

    self:Update(frame)
end

party.Update = function(self, frame)
    local db = frame.db
    if (not InCombatLockdown()) then
        EXUI:SetSize(frame, db.sizeWidth, db.sizeHeight)
    end

    core:UpdateFrame(frame)
end

core:RegisterPlayerGroupUnit('party', 'party', {
    showParty = true,
    showPlayer = true,
    showSolo = true,
    showRaid = false,
    yOffset = 1
})
