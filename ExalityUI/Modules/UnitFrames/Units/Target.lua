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
        ['sizeWidth'] = 200,
        ['sizeHeight'] = 40,
        ['positionAnchorPoint'] = 'TOPLEFT',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = 100,
        ['positionYOff'] = -100,
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
        -- Debuffs
        ['debuffsEnable'] = true,
        ['debuffsAnchorPoint'] = 'BOTTOMLEFT',
        ['debuffsRelativeAnchorPoint'] = 'TOPLEFT',
        ['debuffsXOff'] = 0,
        ['debuffsYOff'] = 2,
        ['debuffsIconWidth'] = 20,
        ['debuffsIconHeight'] = 20,
        ['debuffsOnlyShowPlayer'] = false,
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
    frame.Buffs = EXUI:GetModule('uf-element-buffs'):Create(frame)
    frame.Debuffs = EXUI:GetModule('uf-element-debuffs'):Create(frame)

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
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB

    frame:ClearAllPoints()
    frame:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    frame:SetSize(db.sizeWidth, db.sizeHeight)

    frame.Power:SetPoint('BOTTOMLEFT')
    frame.Power:SetPoint('BOTTOMRIGHT')
    frame.Power:SetFrameLevel(frame.Health:GetFrameLevel() + 1)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('target')
