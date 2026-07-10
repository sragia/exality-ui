---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysUnitResolver
local unitResolver = EXUI:GetModule('aura-displays-unit-resolver')

---@class EXUIAuraDisplaysDefaults
local defaults = EXUI:GetModule('aura-displays-defaults')

unitResolver.CO_TANK = 'coTank'
unitResolver.CUSTOM = 'custom'

unitResolver.cachedCoTank = nil

function unitResolver:IsKnownUnitKey(unit)
    return unit ~= nil and defaults.UNIT_OPTIONS[unit] ~= nil
end

function unitResolver:UnitExists(unit)
    return unit == 'player' or (unit and UnitExists(unit)) == true
end

function unitResolver:ScanCoTank()
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

function unitResolver:GetCoTankUnit()
    if not InCombatLockdown() then
        self:ScanCoTank()
    end
    return self.cachedCoTank
end

function unitResolver:Resolve(containerConfig)
    containerConfig = containerConfig or {}
    local unit = containerConfig.unit or 'player'

    if unit == self.CUSTOM then
        local customUnit = strtrim(containerConfig.unitCustom or '')
        if customUnit == '' then
            return nil, false
        end
        return customUnit, self:UnitExists(customUnit)
    end

    if unit == self.CO_TANK then
        local coTank = self:GetCoTankUnit()
        if coTank and self:UnitExists(coTank) then
            return coTank, true
        end
        return nil, false
    end

    if self:IsKnownUnitKey(unit) then
        return unit, self:UnitExists(unit)
    end

    return unit, self:UnitExists(unit)
end

function unitResolver:GetContainerUnitSelection(containerConfig)
    containerConfig = containerConfig or {}
    local unit = containerConfig.unit or 'player'
    if unit == self.CUSTOM or unit == self.CO_TANK then
        return unit
    end
    if self:IsKnownUnitKey(unit) then
        return unit
    end
    return self.CUSTOM
end

function unitResolver:Init()
    if self.eventFrame then
        return
    end

    self.eventFrame = CreateFrame('Frame')
    self.eventFrame:RegisterEvent('GROUP_ROSTER_UPDATE')
    self.eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.eventFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
    self.eventFrame:SetScript('OnEvent', function()
        if InCombatLockdown() then
            return
        end
        self:ScanCoTank()
        local displayModule = EXUI:GetModule('aura-displays-display')
        if displayModule and displayModule.SyncCoTankUnits then
            displayModule:SyncCoTankUnits()
        end
    end)
end
