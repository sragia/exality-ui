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
core.groupUnits = {}
core.groupUnitMap = {}
core.frames = {}
core.forcedFrames = {}

core.Init = function(self)
    self:AddTags()
    EXUI.oUF:RegisterStyle("ExalityUI", self.SharedStyle)
    EXUI.oUF:Factory(self.Factory)
end

core.RegisterUnit = function(self, unit, isGroup, numUnits)
    if (isGroup) then
        self.groupUnits[unit] = numUnits
        for i = 1, numUnits do
            self.groupUnitMap[unit .. i] = unit
        end
    else
        table.insert(self.units, unit)
    end
end

core.SharedStyle = function(frame, unit)
    local frameFactory = nil
    if (not core.groupUnitMap[unit]) then
        frameFactory = EXUI:GetModule('uf-unit-' .. unit)
    else
        frameFactory = EXUI:GetModule('uf-unit-' .. core.groupUnitMap[unit])
    end

    if (frameFactory and frameFactory.Create) then
        frameFactory:Create(frame, unit)
    end
end

core.Factory = function(oUF)
    oUF:SetActiveStyle("ExalityUI")

    for _, unit in ipairs(core.units) do
        core:CreateOrUpdate(oUF, unit)
    end

    for group, numUnits in pairs(core.groupUnits) do
        core:CreateOrUpdateGroup(oUF, group, numUnits)
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

core.CreateOrUpdateGroup = function(self, oUF, group, numUnits)
    for i = 1, numUnits do
        local unit = group .. i
        local frame = core.frames[unit]
        if (not frame) then
            frame = oUF:Spawn(unit, 'ExalityUI_' .. unit, 'SecureUnitButtonTemplate, PingableUnitFrameTemplate')
            core.frames[unit] = frame
            frame.index = i
        end

        if not frame.Update then
            frame.Update = function() EXUI:GetModule('uf-unit-' .. group):Update(frame) end
        end

        frame:Update()
    end
end

core.Base = function(self, frame)
    local elementFrame = CreateFrame('Frame', '$parent_ElementFrame', frame, 'BackdropTemplate')
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 100)
    -- Add Border
    elementFrame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    elementFrame:SetBackdropBorderColor(0, 0, 0, 1)
    elementFrame:SetBackdropColor(0, 0, 0, 0)

    frame.ElementFrame = elementFrame

    if (not self.groupUnitMap[frame.unit]) then
        frame.db = self:GetDBForUnit(frame.unit)
    else
        frame.db = self:GetDBForUnit(self.groupUnitMap[frame.unit])
    end

    self:AddTooltip(frame)

    frame:RegisterForClicks('AnyUp')
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

    if (frame.RaidTargetIndicator) then
        EXUI:GetModule('uf-element-raid-target-indicator'):Update(frame)
    end

    if (frame.RaidRoles) then
        EXUI:GetModule('uf-element-raid-roles'):Update(frame)
    end

    if (frame.CombatIndicator) then
        EXUI:GetModule('uf-element-combat-indicator'):Update(frame)
    end

    if (frame.Castbar) then
        EXUI:GetModule('uf-element-cast-bar'):Update(frame)
    end

    if (frame.Buffs) then
        EXUI:GetModule('uf-element-buffs'):Update(frame)
    end

    if (frame.Debuffs) then
        EXUI:GetModule('uf-element-debuffs'):Update(frame)
    end

    frame:UpdateTags()
    frame:UpdateAllElements('RefreshUnit')
end

core.AddTooltip = function(self, frame)
    frame:SetScript('OnEnter', function(self)
        if (GameTooltip:IsForbidden()) then return end

        GameTooltip:SetOwner(self, 'ANCHOR_NONE')
        GameTooltip_SetDefaultAnchor(GameTooltip, self)
        GameTooltip:SetUnit(self.unit)
        self.UpdateTooltip = function(self)
            GameTooltip:SetUnit(frame.unit)
        end
    end)
    frame:SetScript('OnLeave', function(self)
        if (GameTooltip:IsForbidden()) then return end
        self.UpdateTooltip = nil
        GameTooltip:Hide()
    end)
end

core.UpdateFrameForUnit = function(self, unit)
    if (not self.groupUnits[unit]) then
        local frame = core.frames[unit]
        if (frame) then
            frame:Update()
        end
    else
        for i = 1, self.groupUnits[unit] do
            local frame = core.frames[unit .. i]
            if (frame) then
                frame:Update()
            end
        end
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
        if (db[unit][key] == nil) then
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

-- For Options. Force Show frames for editting
core.ForceShow = function(self, unit)
    if (InCombatLockdown()) then return end

    if (self.groupUnits[unit]) then
        for i = 1, self.groupUnits[unit] do
            local frame = self.frames[unit .. i]
            if (frame) then
                self.forcedFrames[unit .. i] = frame
                self:ForceFrame(frame)
            end
        end
    elseif (self.frames[unit]) then
        local frame = self.frames[unit]
        if (frame) then
            self.forcedFrames[unit] = frame
            self:ForceFrame(frame)
        end
    end
end

core.ForceFrame = function(self, frame)
    if (frame.isFake) then return end
    frame.originalUnit = frame.unit
    frame.unit = 'player'
    frame.isFake = true

    frame:EnableMouse(false)
    frame:Show()

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame, true)

    if (frame.Update) then
        frame:Update()
    end
end


core.Unforce = function(self, unit)
    if (InCombatLockdown()) then return end

    if (self.groupUnits[unit]) then
        for i = 1, self.groupUnits[unit] do
            local frame = self.frames[unit .. i]
            if (frame) then
                self.forcedFrames[unit .. i] = nil
                self:UnforceFrame(frame)
            end
        end
    elseif (self.frames[unit]) then
        local frame = self.frames[unit]
        if (frame) then
            self.forcedFrames[unit] = nil
            self:UnforceFrame(frame)
        end
    end
end

core.UnforceFrame = function(self, frame)
    if (not frame.isFake) then return end
    frame.unit = frame.originalUnit
    frame:EnableMouse(true)
    frame.isFake = false

    UnregisterUnitWatch(frame)
    RegisterUnitWatch(frame)
end

core.UnforceAll = function(self)
    for _, frame in pairs(self.forcedFrames) do
        if (frame) then
            self:UnforceFrame(frame)
        end
    end
    self.forcedFrames = {}
end
