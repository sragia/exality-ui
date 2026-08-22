---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesDriver
local driver = EXUI:GetModule('np-driver')

driver.oUFDriver = nil
driver.eventFrame = nil

local function wrapProtectedNamePlateApis()
    if driver.protectedApisWrapped then
        return
    end
    if C_NamePlateManager and C_NamePlateManager.SetNamePlateHitTestInsets then
        C_NamePlateManager.SetNamePlateHitTestInsets = function() end
    end
    driver.protectedApisWrapped = true
end

local function callWithoutNamePlateSize(fn)
    local namePlate = C_NamePlate
    if not namePlate or not namePlate.SetNamePlateSize then
        return fn()
    end
    local orig = namePlate.SetNamePlateSize
    namePlate.SetNamePlateSize = function() end
    local ok, result = pcall(fn)
    namePlate.SetNamePlateSize = orig
    if not ok then
        error(result)
    end
    return result
end

local function disableOUFDriverSize(oUFDriver)
    if not oUFDriver then
        return
    end
    oUFDriver.SetSize = function(self, width, height)
        self.plateWidth = width
        self.plateHeight = height or width
    end
    if oUFDriver.UnregisterEvent then
        oUFDriver:UnregisterEvent('PLAYER_LOGIN')
    end
end

driver.ApplySize = function(self)
    local width, height = npCore:GetPlateSize()
    if NamePlateDriverFrame then
        NamePlateDriverFrame.baseNamePlateWidth = width
        NamePlateDriverFrame.baseNamePlateHeight = height
    end
    if self.oUFDriver then
        self.oUFDriver.plateWidth = width
        self.oUFDriver.plateHeight = height
    end
    npCore:ForEachPlate(function(frame)
        self:ApplyFrameSize(frame)
    end)
end

driver.ApplyFrameSize = function(self, frame)
    if not frame or frame:IsForbidden() then
        return
    end
    local plate = frame:GetParent()
    local width, height = npCore:GetPlateSize()
    frame:ClearAllPoints()
    frame:SetSize(width, height)
    if plate then
        frame:SetPoint('BOTTOM', plate, 'BOTTOM')
    end
end

local function hookBlizzardPlateSize()
    if driver.blizzardSizeHooked or not NamePlateDriverFrame then
        return
    end
    local function reapply()
        driver:ApplySize()
    end
    if NamePlateDriverFrame.UpdateNamePlateOptions then
        hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateOptions', reapply)
    end
    if NamePlateDriverFrame.UpdateNamePlateSize then
        hooksecurefunc(NamePlateDriverFrame, 'UpdateNamePlateSize', reapply)
    end
    driver.blizzardSizeHooked = true
end

driver.HideBlizzardPlate = function(self, plate)
    if not plate or plate:IsForbidden() then
        return
    end
    local blizzard = plate.UnitFrame
    if not blizzard or blizzard:IsForbidden() then
        return
    end
    if not blizzard._exuiSuppressed then
        blizzard._exuiSuppressed = true
        blizzard:HookScript('OnShow', function(selfFrame)
            selfFrame:Hide()
        end)
    end
    blizzard:Hide()
    if blizzard.HealthBarsContainer then
        blizzard.HealthBarsContainer:Hide()
    end
    if blizzard.healthBar then
        blizzard.healthBar:Hide()
    end
    if blizzard.name then
        blizzard.name:Hide()
    end
    if blizzard.castBar then
        blizzard.castBar:Hide()
    end
end

driver.OnPlateAdded = function(self, frame, event, unit)
    if not frame or frame:IsForbidden() then
        return
    end
    local plate = frame:GetParent()
    self:HideBlizzardPlate(plate)
    if plate and plate.SetClipsChildren then
        plate:SetClipsChildren(false)
    end
    frame:SetClipsChildren(false)
    self:ApplyFrameSize(frame)
    frame.db = npCore:GetDB()
    npCore:BindPlateUnit(frame)
end

driver.OnPlateRemoved = function(self, frame)
    if not frame then
        return
    end
    EXUI:GetModule('np-element-target-highlight'):OnPlateRemoved(frame)
    local apply = EXUI:GetModule('np-auras-apply')
    if apply and apply.DetachFrame then
        apply:DetachFrame(frame)
    end
end

driver.OnTargetChanged = function(self)
    EXUI:GetModule('np-element-target-highlight'):OnTargetChanged()
end

driver.Enable = function(self)
    if self.oUFDriver then
        return
    end

    wrapProtectedNamePlateApis()
    hookBlizzardPlateSize()

    local oUF = EXUI.oUF
    oUF:RegisterStyle(npCore.STYLE_NAME, npCore.Style)

    local previous = oUF:GetActiveStyle()
    oUF:SetActiveStyle(npCore.STYLE_NAME)
    self.oUFDriver = callWithoutNamePlateSize(function()
        return oUF:SpawnNamePlates('ExalityUI')
    end)
    disableOUFDriverSize(self.oUFDriver)
    if previous then
        oUF:SetActiveStyle(previous)
    else
        oUF:SetActiveStyle('ExalityUI')
    end

    self.oUFDriver:SetAddedCallback(function(frame, event, unit)
        driver:OnPlateAdded(frame, event, unit)
    end)
    self.oUFDriver:SetRemovedCallback(function(frame, event, unit)
        driver:OnPlateRemoved(frame, event, unit)
    end)
    self.oUFDriver:SetTargetCallback(function()
        driver:OnTargetChanged()
    end)

    self:ApplySize()
    self:RegisterSupportEvents()
    npCore.enabled = true
    npCore:ScanCoTank()
end

driver.RegisterSupportEvents = function(self)
    if self.eventFrame then
        return
    end
    local frame = CreateFrame('Frame')
    frame:RegisterEvent('GROUP_ROSTER_UPDATE')
    frame:RegisterEvent('PLAYER_ENTERING_WORLD')
    frame:RegisterEvent('PLAYER_REGEN_ENABLED')
    frame:RegisterEvent('PLAYER_TARGET_CHANGED')
    frame:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
    frame:RegisterEvent('UNIT_CLASSIFICATION_CHANGED')
    frame:RegisterEvent('QUEST_LOG_UPDATE')
    frame:RegisterEvent('INSTANCE_ENCOUNTER_ENGAGE_UNIT')
    frame:RegisterEvent('UNIT_FACTION')
    frame:RegisterEvent('DUEL_FINISHED')
    frame:RegisterEvent('UNIT_SPELLCAST_START')
    frame:RegisterEvent('UNIT_SPELLCAST_STOP')
    frame:RegisterEvent('UNIT_SPELLCAST_CHANNEL_START')
    frame:RegisterEvent('UNIT_SPELLCAST_CHANNEL_STOP')
    frame:RegisterEvent('UNIT_SPELLCAST_INTERRUPTED')
    frame:RegisterEvent('UNIT_SPELLCAST_FAILED')
    frame:SetScript('OnEvent', function(_, event, unit)
        if event == 'PLAYER_TARGET_CHANGED' then
            EXUI:GetModule('np-element-target-highlight'):OnTargetChanged()
        elseif event == 'UPDATE_MOUSEOVER_UNIT' then
            EXUI:GetModule('np-element-target-highlight'):OnMouseoverChanged()
        elseif event == 'GROUP_ROSTER_UPDATE' or event == 'PLAYER_ENTERING_WORLD' then
            hookBlizzardPlateSize()
            driver:ApplySize()
            npCore.rosterDirty = true
            if not InCombatLockdown() then
                npCore:ScanCoTank()
                npCore.rosterDirty = false
                npCore:UpdateAllPlates()
            end
        elseif event == 'PLAYER_REGEN_ENABLED' then
            if npCore.rosterDirty then
                npCore:ScanCoTank()
                npCore.rosterDirty = false
            end
            npCore:UpdateAllPlates()
        elseif event == 'UNIT_CLASSIFICATION_CHANGED' or event == 'QUEST_LOG_UPDATE' then
            npCore:RefreshPlateHealthColors()
        elseif event == 'INSTANCE_ENCOUNTER_ENGAGE_UNIT' then
            npCore:RefreshPlateHealthColors()
        elseif event == 'UNIT_FACTION' then
            if not unit or UnitIsUnit(unit, 'player') then
                npCore:RefreshPlateFriendship()
            else
                npCore:RefreshPlateFriendship(unit)
            end
        elseif event == 'DUEL_FINISHED' then
            npCore:RefreshPlateFriendship()
        elseif event:find('SPELLCAST', 1, true) then
            npCore:UpdateHealthColorForUnit(unit)
        end
    end)
    self.eventFrame = frame
end
