---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUINameplatesDefaults
local defaults = EXUI:GetModule('np-defaults')

---@class EXUINameplatesCore
local core = EXUI:GetModule('np-core')

core.STYLE_NAME = 'ExalityUINameplates'
core.enabled = false
core.cachedCoTank = nil
core.rosterDirty = true

core.GetDB = function(self)
    return data:GetDataByKey('nameplates')
end

core.SetDB = function(self, db)
    data:SetDataByKey('nameplates', db)
end

core.GetValue = function(self, key)
    local db = self:GetDB()
    return db[key]
end

core.SetValue = function(self, key, value)
    local db = self:GetDB()
    db[key] = value
    self:SetDB(db)
end

core.EnsureDB = function(self)
    local db = self:GetDB()
    defaults:MergeIntoDB(db)
    self:SetDB(db)
    return db
end

core.ScanCoTank = function(self)
    self.cachedCoTank = nil
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do
            local unit = 'raid' .. i
            if UnitExists(unit) and not UnitIsUnit(unit, 'player') and UnitGroupRolesAssigned(unit) == 'TANK' then
                self.cachedCoTank = unit
                return
            end
        end
        return
    end
    if IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do
            local unit = 'party' .. i
            if UnitExists(unit) and UnitGroupRolesAssigned(unit) == 'TANK' then
                self.cachedCoTank = unit
                return
            end
        end
    end
end

core.GetCoTankUnit = function(self)
    if not InCombatLockdown() then
        self:ScanCoTank()
    end
    return self.cachedCoTank
end

core.GetPlateUnit = function(self, frame)
    return frame and (frame.unit or frame.__unit)
end

core.IsFriendlyPlate = function(self, frame, unit)
    unit = unit or self:GetPlateUnit(frame)
    return unit and UnitIsFriend('player', unit) or false
end

core.UpdateHealthCurve = function(self)
    -- Nameplate curve is evaluated per-plate from DB; do not mutate oUF.colors.health
    -- (unit frames own that shared curve).
end

core.GetBorderColor = function(self, db)
    return (db and db.borderColor) or { r = 0, g = 0, b = 0, a = 1 }
end

core.GetBorderThickness = function(self, db)
    return (db and db.borderThickness) or 1
end

core.ApplyInset = function(self, child, parent, thickness)
    child:ClearAllPoints()
    local inset = (thickness and thickness > 0) and EXUI:ScalePixels(thickness, child) or 0
    if inset <= 0 then
        child:SetAllPoints(parent)
        return
    end
    child:SetPoint('TOPLEFT', parent, 'TOPLEFT', inset, -inset)
    child:SetPoint('BOTTOMRIGHT', parent, 'BOTTOMRIGHT', -inset, inset)
end

core.SetFillColor = function(self, fill, color)
    if not fill then
        return
    end
    if not color or (color.a or 1) <= 0 then
        fill:Hide()
        return
    end
    fill:Show()
    fill:SetColorTexture(color.r or 0, color.g or 0, color.b or 0, color.a or 1)
end

core.GetPlateSize = function(self, db)
    db = db or self:GetDB()
    local width = db.sizeWidth or 140
    local height = db.sizeHeight or 16
    if db.castbarEnable then
        height = height + (db.castbarHeight or 12) + (db.castbarYOff or -1)
    end
    return width, math.max(1, height)
end

core.LayoutHealthHost = function(self, frame)
    local host = frame.HealthHost
    if not host then
        return
    end
    local db = frame.db or self:GetDB()
    host:ClearAllPoints()
    host:SetPoint('TOPLEFT')
    host:SetPoint('TOPRIGHT')
    EXUI:SetHeight(host, db.sizeHeight or 16)
end

core.EnsureBorderEdges = function(self, parent)
    if parent.BorderEdges then
        return parent.BorderEdges
    end
    local edges = {}
    for _, key in ipairs({ 'Top', 'Bottom', 'Left', 'Right' }) do
        local tex = parent:CreateTexture(nil, 'BACKGROUND')
        tex:SetColorTexture(0, 0, 0, 1)
        edges[key] = tex
    end
    parent.BorderEdges = edges
    return edges
end

core.ApplyBorderEdges = function(self, parent, thickness, color)
    local edges = self:EnsureBorderEdges(parent)
    if not thickness or thickness <= 0 or not color then
        for _, tex in pairs(edges) do
            tex:Hide()
        end
        return
    end
    local px = EXUI:ScalePixels(thickness, parent)
    if px <= 0 then
        for _, tex in pairs(edges) do
            tex:Hide()
        end
        return
    end
    local r, g, b, a = color.r or 0, color.g or 0, color.b or 0, color.a or 1
    edges.Top:ClearAllPoints()
    edges.Top:SetPoint('TOPLEFT')
    edges.Top:SetPoint('TOPRIGHT')
    edges.Top:SetHeight(px)
    edges.Bottom:ClearAllPoints()
    edges.Bottom:SetPoint('BOTTOMLEFT')
    edges.Bottom:SetPoint('BOTTOMRIGHT')
    edges.Bottom:SetHeight(px)
    edges.Left:ClearAllPoints()
    edges.Left:SetPoint('TOPLEFT')
    edges.Left:SetPoint('BOTTOMLEFT')
    edges.Left:SetWidth(px)
    edges.Right:ClearAllPoints()
    edges.Right:SetPoint('TOPRIGHT')
    edges.Right:SetPoint('BOTTOMRIGHT')
    edges.Right:SetWidth(px)
    for _, tex in pairs(edges) do
        tex:SetColorTexture(r, g, b, a)
        tex:Show()
    end
end

core.ApplyHealthChrome = function(self, frame, color)
    local db = frame.db or self:GetDB()
    local fill = frame.BorderFill
    local bar = frame.Health
    local host = frame.HealthHost or frame
    if fill then
        fill:Hide()
    end
    local thickness = self:GetBorderThickness(db)
    if frame.isFriendly or thickness <= 0 then
        if bar then
            self:ApplyInset(bar, host, 0)
        end
        self:ApplyBorderEdges(host, 0)
        return
    end
    if bar then
        self:ApplyInset(bar, host, thickness)
    end
    self:ApplyBorderEdges(host, thickness, color or self:GetBorderColor(db))
end

core.ApplyCastChrome = function(self, bar, db)
    if not bar or not bar.chrome then
        return
    end
    local thickness = self:GetBorderThickness(db)
    local color = self:GetBorderColor(db)
    if thickness <= 0 then
        self:ApplyInset(bar, bar.chrome, 0)
        self:SetFillColor(bar.chrome.BorderFill, nil)
        return
    end
    self:ApplyInset(bar, bar.chrome, thickness)
    self:SetFillColor(bar.chrome.BorderFill, color)
end

core.Style = function(frame, unit)
    core:BuildPlate(frame)
    frame.Update = function(selfFrame)
        core:UpdatePlate(selfFrame)
    end
end

core.BuildPlate = function(self, frame)
    local healthHost = CreateFrame('Frame', '$parent_HealthHost', frame)
    healthHost:SetPoint('TOPLEFT')
    healthHost:SetPoint('TOPRIGHT')
    healthHost:SetHeight(16)
    frame.HealthHost = healthHost

    local elementFrame = CreateFrame('Frame', '$parent_ElementFrame', frame)
    elementFrame:SetAllPoints(healthHost)
    elementFrame:SetFrameLevel(frame:GetFrameLevel() + 100)
    frame.ElementFrame = elementFrame

    local borderFill = healthHost:CreateTexture(nil, 'BACKGROUND')
    borderFill:SetAllPoints()
    borderFill:Hide()
    frame.BorderFill = borderFill

    frame.db = self:GetDB()
    frame.IsElementPreviewEnabled = function()
        return false
    end

    frame.Health = EXUI:GetModule('np-element-health'):Create(frame)
    frame.HealthPrediction = EXUI:GetModule('np-element-health-prediction'):Create(frame)
    frame.Name = EXUI:GetModule('np-element-name'):Create(frame)
    frame.HealthText = EXUI:GetModule('np-element-health-text'):Create(frame)
    frame.HealthPerc = EXUI:GetModule('np-element-health-perc'):Create(frame)
    frame.Castbar = EXUI:GetModule('np-element-cast-bar'):Create(frame)
    frame.RaidTargetIndicator = EXUI:GetModule('np-element-raid-target'):Create(frame)
    frame.Classification = EXUI:GetModule('np-element-classification'):Create(frame)
    frame.CustomTexts = EXUI:GetModule('np-element-custom-texts'):Create(frame)
end

core.UpdatePlate = function(self, frame)
    if not frame or frame:IsForbidden() then return end
    frame.db = self:GetDB()
    frame.isFriendly = self:IsFriendlyPlate(frame)
    self:LayoutHealthHost(frame)

    EXUI:GetModule('np-element-health'):Update(frame)
    EXUI:GetModule('np-element-health-prediction'):Update(frame)
    EXUI:GetModule('np-element-name'):Update(frame)
    EXUI:GetModule('np-element-health-text'):Update(frame)
    EXUI:GetModule('np-element-health-perc'):Update(frame)
    EXUI:GetModule('np-element-cast-bar'):Update(frame)
    EXUI:GetModule('np-element-raid-target'):Update(frame)
    EXUI:GetModule('np-element-classification'):Update(frame)
    EXUI:GetModule('np-element-custom-texts'):Update(frame)
    EXUI:GetModule('np-element-target-highlight'):Update(frame)

    local apply = EXUI:GetModule('np-auras-apply')
    if apply and apply.UpdateFrame then
        apply:UpdateFrame(frame)
    end

    if frame.UpdateTags then
        frame:UpdateTags()
    end
end

core.ForEachPlate = function(self, fn)
    if not C_NamePlate or not C_NamePlate.GetNamePlates then
        return
    end
    local plates = C_NamePlate.GetNamePlates()
    for i = 1, #plates do
        local plate = plates[i]
        local unitFrame = plate.unitFrame
        if plate and not plate:IsForbidden() and unitFrame and unitFrame.isNamePlate then
            fn(unitFrame)
        end
    end
end

core.UpdateAllPlates = function(self)
    if not self.enabled then
        local preview = EXUI:GetModule('np-preview')
        if preview and preview.Refresh then
            preview:Refresh()
        end
        return
    end
    self:UpdateHealthCurve()
    EXUI:GetModule('np-driver'):ApplySize()
    self:ForEachPlate(function(frame)
        self:UpdatePlate(frame)
        if frame.UpdateAllElements then
            frame:UpdateAllElements('RefreshUnit')
        end
    end)
    local preview = EXUI:GetModule('np-preview')
    if preview and preview.Refresh then
        preview:Refresh()
    end
end

core.UpdateTargetHighlight = function(self)
    self:ForEachPlate(function(frame)
        EXUI:GetModule('np-element-target-highlight'):Update(frame)
    end)
end

core.UpdateHealthColorForUnit = function(self, unit)
    if not unit then
        return
    end
    self:ForEachPlate(function(frame)
        local plateUnit = self:GetPlateUnit(frame)
        if plateUnit and UnitIsUnit(plateUnit, unit) and frame.Health then
            EXUI:GetModule('np-element-health').PostUpdateColor(frame.Health, plateUnit)
        end
    end)
end

core.UpdateClassificationIcons = function(self)
    self:ForEachPlate(function(frame)
        local unit = frame.unit or frame.__unit
        EXUI:GetModule('np-element-classification'):UpdateIcon(frame, unit)
        if frame.Health and unit then
            EXUI:GetModule('np-element-health').PostUpdateColor(frame.Health, unit)
        end
    end)
end
