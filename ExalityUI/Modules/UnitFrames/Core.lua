---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

----------------

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

core.units = {}
core.frames = {}

core.Init = function(self)
    self:AddTags()
    EXUI.oUF:RegisterStyle("ExalityUI", self.SharedStyle)
    EXUI.oUF:Factory(self.Factory)
end

core.RegisterUnit = function(self, unit)
    table.insert(self.units, unit)
end

core.SharedStyle = function(frame, unit)
    local frameFactory = EXUI:GetModule('uf-unit-' .. unit)

    if (frameFactory and frameFactory.Create) then
        frameFactory:Create(frame, unit)
    end
end

core.Factory = function(oUF)
    oUF:SetActiveStyle("ExalityUI")


    for _, unit in ipairs(core.units) do
        core:CreateOrUpdate(oUF, unit)
    end
end

core.CreateOrUpdate = function(self, oUF, unit)
    local frame = core.frames[unit]
    if (not frame) then
        frame = oUF:Spawn(unit, 'ExalityUI_' .. unit, 'SecureUnitButtonTemplate, PingableUnitFrameTemplate')
        core.frames[unit] = frame
    end

    if not frame.Update then
        frame.Update = function() EXUI:GetModule('uf-unit-' .. unit):Update(frame) end
    end

    frame:Update()
end

core.Base = function(self, frame)
    local elementFrame = CreateFrame('Frame', '$parent_ElementFrame', frame, 'BackdropTemplate')
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 100)
    -- Add Border
    elementFrame:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    elementFrame:SetBackdropBorderColor(0, 0, 0, 1)
    elementFrame:SetBackdropColor(0, 0, 0, 0)

    frame.ElementFrame = elementFrame
end

core.UpdateFrame = function(self, frame)
    -- Update All Elements on frame
    if (frame.Name) then
        EXUI:GetModule('uf-element-name'):Update(frame)
    end

    if (frame.HealthText) then
        EXUI:GetModule('uf-element-health-text'):Update(frame)
    end
    if (frame.HealthPerc) then
        EXUI:GetModule('uf-element-health-perc'):Update(frame)
    end

    if (frame.Power) then
        EXUI:GetModule('uf-element-power'):Update(frame)
    end

    if (frame.Health) then
        EXUI:GetModule('uf-element-health'):Update(frame)
    end

    frame:UpdateTags()
    frame:UpdateAllElements('RefreshUnit')
end

core.UpdateFrameForUnit = function(self, unit)
    local frame = core.frames[unit]
    if (frame) then
        frame:Update()
    end
end

core.UpdateAllFrames = function(self)
    for _, unit in ipairs(self.units) do
        self:UpdateFrameForUnit(unit)
    end
end

core.AddTags = function(self)
    -- currHP Formatted
    EXUI.oUF.Tags.Methods['curhp:formatted'] = function(unit)
        local currHP = UnitHealth(unit)

        return AbbreviateNumbers(currHP)
    end

    EXUI.oUF.Tags.Events['curhp:formatted'] = 'UNIT_HEALTH UNIT_MAXHEALTH'
end

-- DB Data
core.SetDefaultsForUnit = function(self, unit, defaults)
    local db = data:GetDataByKey('UF')
    db = db or {}
    db[unit] = db[unit] or {}
    for key, value in pairs(defaults) do
        if (not db[unit][key]) then
            db[unit][key] = value
        end
    end
    data:SetDataByKey('UF', db)
end

core.GetDBForUnit = function(self, unit)
    local UFDB = data:GetDataByKey('UF')
    if (not UFDB) then
        UFDB = {}
        data:SetDataByKey('UF', UFDB)
    end
    UFDB[unit] = UFDB[unit] or {}

    return UFDB[unit]
end

core.UpdateValueForUnit = function(self, unit, key, value)
    local UFDB = data:GetDataByKey('UF')
    UFDB[unit] = UFDB[unit] or {}
    UFDB[unit][key] = value
    data:SetDataByKey('UF', UFDB)
end

core.GetValueForUnit = function(self, unit, key)
    local db = self:GetDBForUnit(unit)
    return db[key]
end