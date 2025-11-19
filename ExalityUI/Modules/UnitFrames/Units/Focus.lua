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
        ['sizeWidth'] = 120,
        ['sizeHeight'] = 30,
        ['positionAnchorPoint'] = 'TOPLEFT',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = 100,
        ['positionYOff'] = -100,
        ['nameEnable'] = true,
        ['nameFont'] = 'DMSans',
        ['nameFontSize'] = 12,
        ['nameFontFlag'] = 'OUTLINE',
        ['nameFontColor'] = {r = 1, g = 1, b = 1, a = 1},
        ['nameAnchorPoint'] = 'CENTER',
        ['nameRelativeAnchorPoint'] = 'CENTER',
        ['nameTag'] = '[name]',
        ['nameXOffset'] = 0,
        ['nameYOffset'] = 0,
        ['powerEnable'] = true,
        ['powerHeight'] = 5,
    })
end

focus.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)
    frame.Power = EXUI:GetModule('uf-element-power'):Create(frame)

    editor:RegisterFrameForEditor(frame, 'Focus', function(frame)
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

focus.Update = function(self, frame)
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

EXUI:GetModule('uf-core'):RegisterUnit('focus')