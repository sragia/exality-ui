---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsStateDriver
local stateDriver = EXUI:GetModule('action-bars-state-driver')

local fmt = string.format
local table_concat = table.concat
local table_insert = table.insert

-- Retail stance metadata (Exality-owned; maps stance id -> bonus bar index).
local STANCE_ENTRIES = {
    DRUID = {
        { id = 'bear', index = 3, type = 'bonusbar' },
        { id = 'cat', index = 1, type = 'bonusbar' },
        { id = 'prowl', index = false, type = 'bonusbar' },
        { id = 'moonkin', index = 4, type = 'bonusbar' },
    },
    ROGUE = {
        { id = 'stealth', index = 1, type = 'bonusbar' },
    },
    EVOKER = {
        { id = 'soar', index = 1, type = 'bonusbar' },
    },
}

local ON_STATE_PAGE = [[
	if newstate == "possess" or newstate == "dragon" or newstate == "11" then
		if HasVehicleActionBar() then
			newstate = GetVehicleBarIndex()
		elseif HasOverrideActionBar() then
			newstate = GetOverrideBarIndex()
		elseif HasTempShapeshiftActionBar() then
			newstate = GetTempShapeshiftBarIndex()
		elseif HasBonusActionBar() then
			newstate = GetBonusBarIndex()
		else
			newstate = nil
		end
		if not newstate then
			newstate = 12
		end
	end
	self:SetAttribute("state", newstate)
	control:ChildUpdate("state", newstate)
]]

local APPLY_CURRENT_PAGE = [[
	newstate = self:GetAttribute("state-page") or 0
]] .. ON_STATE_PAGE

local PAGE_RESOLVE_EVENTS = {
    UPDATE_POSSESS_BAR = true,
    UPDATE_VEHICLE_ACTIONBAR = true,
    UPDATE_OVERRIDE_ACTIONBAR = true,
    UPDATE_BONUS_ACTIONBAR = true,
}

stateDriver.pendingUpdate = false
stateDriver.pendingForceApply = false

local function getBar1Frame()
    local barMod = EXUI:GetModule('action-bars-bar')
    return barMod:Get('bar1')
end

stateDriver.RefreshButtons = function(self, frame)
    for _, button in ipairs(frame.buttons or {}) do
        if button.UpdateAction then
            button:UpdateAction(true)
        end
    end
end

stateDriver.ForceApplyCurrentPage = function(self, frame)
    frame = frame or getBar1Frame()
    if not frame or not frame.header or frame.barId ~= 'bar1' then
        return
    end

    if InCombatLockdown() then
        self.pendingForceApply = true
        return
    end

    frame.header:Execute(APPLY_CURRENT_PAGE)
    self:RefreshButtons(frame)
    self.pendingForceApply = false
end

stateDriver.GetStancePage = function(self, statesConfig, stanceId)
    local playerClass = select(2, UnitClass('player'))
    local classConfig = statesConfig and statesConfig.stance and statesConfig.stance[playerClass]
    if not classConfig then
        return 0
    end
    return classConfig[stanceId] or 0
end

stateDriver.BuildDriverString = function(self, statesConfig)
    statesConfig = statesConfig or {}
    local playerClass = select(2, UnitClass('player'))

    if statesConfig.enabled == false then
        return '0'
    end

    local parts = {}

    if statesConfig.possess ~= false then
        table_insert(parts, '[overridebar][vehicleui][possessbar][shapeshift]possess;[bonusbar:5]dragon')
    end

    for _, mod in ipairs({ 'ctrl', 'alt', 'shift' }) do
        local page = statesConfig[mod]
        if page and page ~= 0 then
            table_insert(parts, fmt('[mod:%s]%s', mod, page))
        end
    end

    if statesConfig.actionbar then
        for i = 2, 6 do
            table_insert(parts, fmt('[bar:%s]%s', i, i))
        end
    end

    local entries = STANCE_ENTRIES[playerClass]
    if entries then
        local classStances = statesConfig.stance and statesConfig.stance[playerClass] or {}
        for _, entry in ipairs(entries) do
            local page = classStances[entry.id]
            if page and page ~= 0 and entry.index then
                if playerClass == 'DRUID' and entry.id == 'cat' then
                    local prowlPage = classStances.prowl
                    if prowlPage and prowlPage ~= 0 then
                        table_insert(parts, fmt('[bonusbar:%s,stealth:1]%s', entry.index, prowlPage))
                    end
                end
                local barType = entry.type or 'bonusbar'
                table_insert(parts, fmt('[%s:%s]%s', barType, entry.index, page))
            end
        end
    end

    table_insert(parts, tostring(statesConfig.default or 0))
    return table_concat(parts, ';')
end

stateDriver.ApplyToFrame = function(self, frame, statesConfig)
    if not frame or not frame.header or frame.barId ~= 'bar1' then
        return
    end

    statesConfig = statesConfig or {}

    if InCombatLockdown() then
        self.pendingUpdate = true
        frame.exuiPendingStateConfig = statesConfig
        return
    end

    local header = frame.header
    local driver = self:BuildDriverString(statesConfig)

    header:SetAttribute('_onstate-page', ON_STATE_PAGE)
    UnregisterStateDriver(header, 'page')
    header:SetAttribute('state-page', '0')
    RegisterStateDriver(header, 'page', driver)
    self:ForceApplyCurrentPage(frame)

    frame.exuiPendingStateConfig = nil
end

stateDriver.RefreshBar1 = function(self)
    local frame = getBar1Frame()
    if not frame then
        return
    end

    local db = EXUI:GetModule('action-bars'):GetDB()
    local barDb = db.bars and db.bars.bar1
    local statesConfig = barDb and barDb.states
    self:ApplyToFrame(frame, statesConfig)
end

stateDriver.OnRegenEnabled = function(self)
    if not self.pendingUpdate and not self.pendingTalentUpdate and not self.pendingForceApply then
        return
    end
    if InCombatLockdown() then
        return
    end

    local pendingDriver = self.pendingUpdate or self.pendingTalentUpdate
    self.pendingUpdate = false
    self.pendingTalentUpdate = false

    if pendingDriver then
        local barMod = EXUI:GetModule('action-bars-bar')
        for _, frame in pairs(barMod.instances) do
            if frame.exuiPendingStateConfig and frame.barId == 'bar1' then
                self:ApplyToFrame(frame, frame.exuiPendingStateConfig)
            end
        end
        self:RefreshBar1()
        return
    end

    self:ForceApplyCurrentPage()
end

stateDriver.Init = function(self)
    if self.initialized then
        return
    end
    self.initialized = true

    local f = CreateFrame('Frame')
    f:RegisterEvent('PLAYER_REGEN_ENABLED')
    f:RegisterEvent('PLAYER_ENTERING_WORLD')
    f:RegisterEvent('PLAYER_TALENT_UPDATE')
    f:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
    f:RegisterEvent('UPDATE_POSSESS_BAR')
    f:RegisterEvent('UPDATE_VEHICLE_ACTIONBAR')
    f:RegisterEvent('UPDATE_OVERRIDE_ACTIONBAR')
    f:RegisterEvent('UPDATE_BONUS_ACTIONBAR')
    f:SetScript('OnEvent', function(_, event)
        if event == 'PLAYER_REGEN_ENABLED' then
            stateDriver:OnRegenEnabled()
            return
        end

        if PAGE_RESOLVE_EVENTS[event] then
            stateDriver:ForceApplyCurrentPage()
            return
        end

        if InCombatLockdown() then
            if event == 'PLAYER_ENTERING_WORLD'
                or event == 'PLAYER_TALENT_UPDATE'
                or event == 'PLAYER_SPECIALIZATION_CHANGED' then
                stateDriver.pendingTalentUpdate = true
            else
                stateDriver.pendingForceApply = true
            end
            return
        end

        if event == 'PLAYER_ENTERING_WORLD' then
            stateDriver:RefreshBar1()
            C_Timer.After(0, function()
                stateDriver:ForceApplyCurrentPage()
            end)
        elseif event == 'PLAYER_TALENT_UPDATE' or event == 'PLAYER_SPECIALIZATION_CHANGED' then
            stateDriver:ForceApplyCurrentPage()
        end
    end)
    self.eventFrame = f
end

stateDriver.Shutdown = function(self)
    if self.eventFrame then
        self.eventFrame:UnregisterAllEvents()
        self.eventFrame = nil
    end
    self.initialized = false
end
