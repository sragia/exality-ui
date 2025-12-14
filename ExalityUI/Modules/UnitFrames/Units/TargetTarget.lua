---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesTargetTarget
local targettarget = EXUI:GetModule('uf-unit-targettarget')

targettarget.unit = 'targettarget'

targettarget.Init = function(self)
    core:SetDefaultsForUnit(self.unit, {
        ['sizeWidth'] = 80,
        ['sizeHeight'] = 20,
        ['positionAnchorPoint'] = 'TOPLEFT',
        ['positionRelativePoint'] = 'CENTER',
        ['positionXOff'] = 100,
        ['positionYOff'] = -100,
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
    })
end

targettarget.Create = function(self, frame)
    core:Base(frame)

    frame.Health = EXUI:GetModule('uf-element-health'):Create(frame)
    frame.Name = EXUI:GetModule('uf-element-name'):Create(frame)

    editor:RegisterFrameForEditor(frame, 'TargetTarget', function(frame)
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

targettarget.Update = function(self, frame)
    local db = core:GetDBForUnit(self.unit)
    local generalDB = core:GetDBForUnit('general')
    frame.db = db
    frame.generalDB = generalDB

    frame:ClearAllPoints()
    EXUI:SetPoint(frame, db.positionAnchorPoint, UIParent, db.positionRelativePoint, db.positionXOff, db.positionYOff)
    EXUI:SetSize(frame, db.sizeWidth, db.sizeHeight)

    core:UpdateFrame(frame)
end

EXUI:GetModule('uf-core'):RegisterUnit('targettarget')
