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
        ['sizeWidth'] = 200,
        ['sizeHeight'] = 40,
        ['positionAnchorPoint'] = 'TOPRIGHT',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = -100,
        ['positionYOff'] = -100,
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = {r = 1, g = 1, b = 1, a = 1},
        ['nameAnchorPoint'] = 'LEFT',
        ['nameTag'] = '[name]',
        ['nameRelativeAnchorPoint'] = 'LEFT',
        ['nameXOffset'] = 0,
        ['nameYOffset'] = 0,
        ['healthEnable'] = true,
        ['healthFont'] = 'DMSans',
        ['healthFontSize'] = 12,
        ['healthFontFlag'] = 'OUTLINE',
        ['healthFontColor'] = {r = 1, g = 1, b = 1, a = 1},
        ['healthAnchorPoint'] = 'RIGHT',
        ['healthRelativeAnchorPoint'] = 'RIGHT',
        ['healthXOffset'] = -5,
        ['healthYOffset'] = -10,
        ['healthTag'] = '[curhp:formatted]',
        ['healthpercEnable'] = true,
        ['healthpercFont'] = 'DMSans',
        ['healthpercFontSize'] = 16,
        ['healthpercFontFlag'] = 'OUTLINE',
        ['healthpercFontColor'] = {r = 1, g = 1, b = 1, a = 1},
        ['healthpercAnchorPoint'] = 'RIGHT',
        ['healthpercRelativeAnchorPoint'] = 'RIGHT',
        ['healthpercXOffset'] = -5,
        ['healthpercYOffset'] = 3,
        ['healthpercTag'] = '[perhp]%',
    })
end

player.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('uf-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('uf-element-health-perc'):Create(frame)

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
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB
    frame:ClearAllPoints()
    frame:SetPoint(db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    frame:SetSize(db.sizeWidth, db.sizeHeight)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('player')