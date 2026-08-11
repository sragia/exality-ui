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
        ['useSmoothHealthColor'] = false,
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
        -- Absorbs
        ['damageAbsorbEnable'] = true,
        ['damageAbsorbShowOverIndicator'] = true,
        ['damageAbsorbShowAt'] = 'AS_EXTENSION',
        ['healAbsorbEnable'] = true,
        ['healAbsorbShowOverIndicator'] = true,
    })

    self.container:SetPoint(
        core:GetValueForUnit('arena', 'positionAnchorPoint'),
        UIParent,
        core:GetValueForUnit('arena', 'positionRelativePoint'),
        core:GetValueForUnit('arena', 'positionXOff'),
        core:GetValueForUnit('arena', 'positionYOff')
    )

    editor:RegisterFrameForEditor(self.container, 'Arena Frames', function(frame)
        core:PersistEditorFramePosition(frame, self.unit)
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
    frame.HealthPrediction = EXUI:GetModule('uf-element-healthprediction'):Create(frame)
    frame.Castbar = EXUI:GetModule('uf-element-cast-bar'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('uf-element-custom-texts'):Create(frame)

    frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', 0, 0)
end

arena.Update = function(self, frame)
    self.frames[frame.index] = frame
    local db = core:GetDBForUnit(self.unit)
    local generalDB = core:GetDBForUnit('general')
    local spacing = EXUI:ScalePixel(db.spacing, self.container)
    local containerHeight = db.sizeHeight * #self.frames + spacing * (#self.frames - 1)
    core:ApplyContainerLayout(self.container, db, db.sizeWidth, containerHeight)

    frame.db = db
    frame.generalDB = generalDB
    EXUI:SetSize(frame, db.sizeWidth, db.sizeHeight)
    frame:SetFrameLevel(self.container:GetFrameLevel() + 1)

    if (frame.index == 1) then
        frame:ClearAllPoints()
        EXUI:SetPoint(frame, 'TOPLEFT', self.container, 'TOPLEFT', 0, 0)
    else
        frame:ClearAllPoints()
        EXUI:SetPoint(frame, 'TOPLEFT', self.frames[frame.index - 1], 'BOTTOMLEFT', 0, -spacing)
    end
    core:SnapUnitFrame(frame)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('arena', true, 5)
