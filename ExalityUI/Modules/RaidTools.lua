---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

local LSM = LibStub:GetLibrary("LibSharedMedia-3.0", true)

----------------

---@class EXUIRaidToolsModule
local raidToolsModule = EXUI:GetModule('raid-tools-module')

local REBIRTH_SPELL_ID = 20484
local BREZZ_TIMER_GAP = 6

local BATTLE_RES_DIFFICULTIES = {
    [8]   = true, -- Mythic+
    [14]  = true, -- Normal Raid
    [15]  = true, -- Heroic Raid
    [16]  = true, -- Mythic Raid
    [17]  = true, -- Looking For Raid
    [23]  = true, -- Mythic+ (seen in some game builds)
    [33]  = true, -- Timewalking Raid
    [233] = true, -- Flexible Mythic Raid
}

local BREZZ_VISIBILITY_OPTIONS = {
    mplus_or_raid = 'M+ & Raid Encounters',
    mplus = 'Mythic+ Only',
    raid = 'Raid Encounters Only',
    always = 'Always (In Content)',
}

local BREZZ_TIMER_POSITION_OPTIONS = {
    left = 'Left',
    right = 'Right',
    top = 'Top',
    bottom = 'Bottom',
}

raidToolsModule.brezzFrame = nil
raidToolsModule.brezzEncounterActive = false
raidToolsModule.brezzEditorShowing = false
raidToolsModule.readyCheckFrame = nil
raidToolsModule.pullTimerFrame = nil
raidToolsModule.encounterTimerFrame = nil
raidToolsModule.showStatus = false

raidToolsModule.useTabs = true
raidToolsModule.useSplitView = false

local EncounterTimerType = {
    ENCOUNTER = 'encounter',
    COMBAT = 'combat',
}

raidToolsModule.Init = function(self)
    optionsController:RegisterModule(self)
    data:UpdateDefaults(self:GetDefaults())
    self:CreateOrRefreshAll()
    local event = CreateFrame('Frame')
    event:RegisterEvent('GROUP_JOINED')
    event:RegisterEvent('PARTY_LEADER_CHANGED')
    event:RegisterEvent('GROUP_ROSTER_UPDATE')
    event:SetScript('OnEvent', function(self, event, ...)
        raidToolsModule:HandleChecks()
    end)
    raidToolsModule:HandleChecks()
end

raidToolsModule.GetName = function(self)
    return 'Raid Tools'
end

raidToolsModule.GetCategory = function(self)
    return 'Quality of Life'
end

raidToolsModule.GetOrder = function(self)
    return 10
end

raidToolsModule.GetProfileExportSpec = function(self)
    local keys = {}
    for k in pairs(self:GetDefaults()) do
        keys[#keys + 1] = k
    end
    return { id = 'raid-tools', keys = keys }
end

raidToolsModule.GetDefaults = function(self)
    return {
        brezzEnabled = true,
        brezzAnchor = 'LEFT',
        brezzRelativePoint = 'LEFT',
        brezzXOff = 16,
        brezzYOff = -295,
        brezzSize = 41,
        brezzTimerPosition = 'right',
        brezzVisibility = 'mplus_or_raid',
        brezzFont = 'DMSans',
        brezzFontSize = 24,
        readyCheckEnabled = true,
        readyCheckAnchor = 'BOTTOMLEFT',
        readyCheckRelativePoint = 'BOTTOMLEFT',
        readyCheckXOff = 16,
        readyCheckYOff = 391.00,
        readyCheckWidth = 120,
        readyCheckHeight = 30,
        readyCheckFont = 'DMSans',
        readyCheckFontSize = 14,
        readyCheckBackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        pullTimerEnabled = true,
        pullTimerAnchor = 'LEFT',
        pullTimerRelativePoint = 'LEFT',
        pullTimerXOff = 16,
        pullTimerYOff = -331,
        pullTimerWidth = 120,
        pullTimerHeight = 30,
        pullTimerFont = 'DMSans',
        pullTimerFontSize = 14,
        pullTimerSeconds = 10,
        pullTimerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        encounterTimerEnabled = false,
        encounterTimerAnchor = 'BOTTOMLEFT',
        encounterTimerRelativePoint = 'BOTTOMLEFT',
        encounterTimerXOff = 15,
        encounterTimerYOff = 359.79,
        encounterTimerFont = 'DMSans',
        encounterTimerFontSize = 14,
        encounterTimerFontFlag = 'OUTLINE',
        encounterTimerFontColor = { r = 1, g = 1, b = 1, a = 1 },
        encounterTimerType = EncounterTimerType.ENCOUNTER, -- encounter, combat
        encounterTimerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        encounterTimerBorderColor = { r = 0, g = 0, b = 0, a = 1 },
    }
end

raidToolsModule.GetTabs = function(self)
    return {
        {
            ID = 'brezz',
            label = 'Battle Ress',
        },
        {
            ID = 'readyCheck',
            label = 'Ready Check',
        },
        {
            ID = 'pullTimer',
            label = 'Pull Timer',
        },
        {
            ID = 'encounterTimer',
            label = 'Encounter Timer',
        }
    }
end


raidToolsModule.GetOptions = function(self, currTabID)
    if (currTabID == 'brezz') then
        return {
            {
                type = 'toggle',
                name = 'brezzEnabled',
                label = 'Enable',
                onChange = function(value)
                    data:SetDataByKey('brezzEnabled', value)
                    self:CreateOrRefreshBrezz()
                end,
                currentValue = function()
                    return data:GetDataByKey('brezzEnabled')
                end,
                width = 100,
            },
            {
                type = 'range',
                name = 'brezzSize',
                label = 'Size',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('brezzSize')
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzSize', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'spacer',
                width = 84
            },
            {
                type = 'dropdown',
                name = 'brezzTimerPosition',
                label = 'Timer Position',
                getOptions = function()
                    return BREZZ_TIMER_POSITION_OPTIONS
                end,
                currentValue = function()
                    return data:GetDataByKey('brezzTimerPosition') or 'right'
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzTimerPosition', value)
                    self:CreateOrRefreshBrezz()
                end,
                width = 33
            },
            {
                type = 'spacer',
                width = 67
            },
            {
                type = 'dropdown',
                name = 'brezzVisibility',
                label = 'Visibility',
                getOptions = function()
                    return BREZZ_VISIBILITY_OPTIONS
                end,
                currentValue = function()
                    return data:GetDataByKey('brezzVisibility') or 'mplus_or_raid'
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzVisibility', value)
                    self:CreateOrRefreshBrezz()
                end,
                width = 33
            },
            {
                type = 'spacer',
                width = 67
            },
            {
                type = 'range',
                name = 'brezzXOff',
                label = 'X Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('brezzXOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzXOff', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'range',
                name = 'brezzYOff',
                label = 'Y Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('brezzYOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzYOff', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'spacer',
                width = 68
            },
            {
                type = 'dropdown',
                name = 'brezzFont',
                label = 'Font',
                getOptions = function()
                    local fonts = LSM:List('font')
                    local options = {}
                    for _, font in ipairs(fonts) do
                        options[font] = font
                    end
                    return options
                end,
                isFontDropdown = true,
                currentValue = function()
                    return data:GetDataByKey('brezzFont')
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzFont', value)
                    self:CreateOrRefreshBrezz()
                end,
                width = 33
            },
            {
                type = 'range',
                name = 'brezzFontSize',
                label = 'Font Size',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('brezzFontSize')
                end,
                onChange = function(value)
                    data:SetDataByKey('brezzFontSize', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'spacer',
                width = 51
            },
        }
    end
    if (currTabID == 'readyCheck') then
        return {
            {
                type = 'toggle',
                name = 'readyCheckEnabled',
                label = 'Enable',
                onChange = function(value)
                    data:SetDataByKey('readyCheckEnabled', value)
                    self:CreateOrRefreshReadyCheck()
                end,
                currentValue = function()
                    return data:GetDataByKey('readyCheckEnabled')
                end,
                width = 100,
            },
            {
                type = 'range',
                name = 'readyCheckWidth',
                label = 'Width',
                min = 10,
                max = 300,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('readyCheckWidth')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckWidth', value)
                    self:CreateOrRefreshReadyCheck()
                end
            },
            {
                type = 'range',
                name = 'readyCheckHeight',
                label = 'Height',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('readyCheckHeight')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckHeight', value)
                    self:CreateOrRefreshReadyCheck()
                end
            },
            {
                type = 'color-picker',
                name = 'readyCheckBackgroundColor',
                label = 'Background Color',
                currentValue = function()
                    return data:GetDataByKey('readyCheckBackgroundColor')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckBackgroundColor', value)
                    self:CreateOrRefreshReadyCheck()
                end,
                width = 16
            },
            {
                type = 'spacer',
                width = 52
            },
            {
                type = 'dropdown',
                name = 'readyCheckFont',
                label = 'Font',
                getOptions = function()
                    local fonts = LSM:List('font')
                    local options = {}
                    for _, font in ipairs(fonts) do
                        options[font] = font
                    end
                    return options
                end,
                isFontDropdown = true,
                currentValue = function()
                    return data:GetDataByKey('readyCheckFont')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckFont', value)
                    self:CreateOrRefreshReadyCheck()
                end,
                width = 33
            },
            {
                type = 'range',
                name = 'readyCheckFontSize',
                label = 'Font Size',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('readyCheckFontSize')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckFontSize', value)
                    self:CreateOrRefreshReadyCheck()
                end
            },
            {
                type = 'spacer',
                width = 50
            },
            {
                type = 'range',
                name = 'readyCheckXOff',
                label = 'X Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('readyCheckXOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckXOff', value)
                    self:CreateOrRefreshReadyCheck()
                end
            },
            {
                type = 'range',
                name = 'readyCheckYOff',
                label = 'Y Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('readyCheckYOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('readyCheckYOff', value)
                    self:CreateOrRefreshReadyCheck()
                end
            },
        }
    end
    if (currTabID == 'pullTimer') then
        return {
            {
                type = 'toggle',
                name = 'pullTimerEnabled',
                label = 'Enable',
                onChange = function(value)
                    data:SetDataByKey('pullTimerEnabled', value)
                    self:CreateOrRefreshPullTimer()
                end,
                currentValue = function()
                    return data:GetDataByKey('pullTimerEnabled')
                end,
                width = 100,
            },
            {
                type = 'range',
                name = 'pullTimerWidth',
                label = 'Width',
                min = 10,
                max = 300,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerWidth')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerWidth', value)
                    self:CreateOrRefreshPullTimer()
                end
            },
            {
                type = 'range',
                name = 'pullTimerHeight',
                label = 'Height',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerHeight')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerHeight', value)
                    self:CreateOrRefreshPullTimer()
                end
            },
            {
                type = 'color-picker',
                name = 'pullTimerBackgroundColor',
                label = 'Background Color',
                currentValue = function()
                    return data:GetDataByKey('pullTimerBackgroundColor')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerBackgroundColor', value)
                    self:CreateOrRefreshPullTimer()
                end,
                width = 16
            },
            {
                type = 'range',
                name = 'pullTimerSeconds',
                label = 'Seconds',
                min = 5,
                max = 20,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerSeconds')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerSeconds', value)
                end
            },
            {
                type = 'spacer',
                width = 36
            },
            {
                type = 'dropdown',
                name = 'pullTimerFont',
                label = 'Font',
                getOptions = function()
                    local fonts = LSM:List('font')
                    local options = {}
                    for _, font in ipairs(fonts) do
                        options[font] = font
                    end
                    return options
                end,
                isFontDropdown = true,
                currentValue = function()
                    return data:GetDataByKey('pullTimerFont')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerFont', value)
                    self:CreateOrRefreshPullTimer()
                end,
                width = 33
            },
            {
                type = 'range',
                name = 'pullTimerFontSize',
                label = 'Font Size',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerFontSize')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerFontSize', value)
                    self:CreateOrRefreshPullTimer()
                end
            },
            {
                type = 'spacer',
                width = 50
            },
            {
                type = 'range',
                name = 'pullTimerXOff',
                label = 'X Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerXOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerXOff', value)
                    self:CreateOrRefreshPullTimer()
                end
            },
            {
                type = 'range',
                name = 'pullTimerYOff',
                label = 'Y Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('pullTimerYOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('pullTimerYOff', value)
                    self:CreateOrRefreshPullTimer()
                end
            },
        }
    end

    if (currTabID == 'encounterTimer') then
        return {
            {
                type = 'toggle',
                name = 'encounterTimerEnabled',
                label = 'Enable',
                onChange = function(value)
                    data:SetDataByKey('encounterTimerEnabled', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerEnabled')
                end,
                width = 100,
            },
            {
                type = 'button',
                name = 'encounterTimerDisplayTest',
                label = 'Display Test',
                onClick = function()
                    self.encounterTimerFrame:DisplayTest()
                end,
                color = { 219 / 255, 73 / 255, 0, 1 },
                width = 20,
            },
            {
                type = 'spacer',
                width = 80
            },
            {
                type = 'dropdown',
                name = 'encounterTimerType',
                label = 'Type',
                getOptions = function()
                    return {
                        [EncounterTimerType.ENCOUNTER] = 'Encounter',
                        [EncounterTimerType.COMBAT] = 'Combat',
                    }
                end,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerType')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerType', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 33
            },
            {
                type = 'spacer',
                width = 67
            },
            {
                type = 'dropdown',
                name = 'encounterTimerFont',
                label = 'Font',
                getOptions = function()
                    local fonts = LSM:List('font')
                    local options = {}
                    for _, font in ipairs(fonts) do
                        options[font] = font
                    end
                    return options
                end,
                isFontDropdown = true,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerFont')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerFont', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 25
            },
            {
                type = 'range',
                name = 'encounterTimerFontSize',
                label = 'Font Size',
                min = 10,
                max = 100,
                step = 1,
                width = 16,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerFontSize')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerFontSize', value)
                    self:CreateOrRefreshEncounterTimer()
                end
            },
            {
                type = 'dropdown',
                name = 'encounterTimerFontFlag',
                label = 'Font Flag',
                getOptions = function()
                    return EXUI.const.fontFlags
                end,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerFontFlag')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerFontFlag', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 25
            },
            {
                type = 'spacer',
                width = 34
            },
            {
                type = 'color-picker',
                name = 'encounterTimerFontColor',
                label = 'Font Color',
                currentValue = function()
                    return data:GetDataByKey('encounterTimerFontColor')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerFontColor', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 16
            },
            {
                type = 'color-picker',
                name = 'encounterTimerBackgroundColor',
                label = 'Background Color',
                currentValue = function()
                    return data:GetDataByKey('encounterTimerBackgroundColor')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerBackgroundColor', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 16
            },
            {
                type = 'color-picker',
                name = 'encounterTimerBorderColor',
                label = 'Border Color',
                currentValue = function()
                    return data:GetDataByKey('encounterTimerBorderColor')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerBorderColor', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 16
            },
            {
                type = 'spacer',
                width = 52
            },
            {
                type = 'anchor-point',
                name = 'encounterTimerAnchor',
                label = 'Anchor Point',
                currentValue = function()
                    return data:GetDataByKey('encounterTimerAnchor')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerAnchor', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 23
            },
            {
                type = 'anchor-point',
                name = 'encounterTimerRelativePoint',
                label = 'Relative Anchor Point',
                currentValue = function()
                    return data:GetDataByKey('encounterTimerRelativePoint')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerRelativePoint', value)
                    self:CreateOrRefreshEncounterTimer()
                end,
                width = 23
            },
            {
                type = 'spacer',
                width = 54
            },
            {
                type = 'range',
                name = 'encounterTimerXOff',
                label = 'X Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 23,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerXOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerXOff', value)
                    self:CreateOrRefreshEncounterTimer()
                end
            },
            {
                type = 'range',
                name = 'encounterTimerYOff',
                label = 'Y Offset',
                min = -1000,
                max = 1000,
                step = 1,
                width = 23,
                currentValue = function()
                    return data:GetDataByKey('encounterTimerYOff')
                end,
                onChange = function(value)
                    data:SetDataByKey('encounterTimerYOff', value)
                    self:CreateOrRefreshEncounterTimer()
                end
            },
        }
    end

    return {
    }
end

raidToolsModule.HandleChecks = function(self, recheck)
    local combat = InCombatLockdown()
    local leader = UnitIsGroupLeader('player')
    local assist = UnitIsGroupAssistant('player')
    local shouldShow = assist or leader

    if (recheck and not combat and shouldShow) then
        self.showStatus = true
        self:CreateOrRefreshReadyCheck()
        self:CreateOrRefreshPullTimer()
    elseif (recheck and shouldShow) then
        C_Timer.After(3, function() self:HandleChecks(true) end)
    elseif (combat and self.showStatus and not shouldShow) then
        C_Timer.After(3, function() self:HandleChecks(true) end)
    elseif (shouldShow) then
        self.showStatus = true
        self:CreateOrRefreshReadyCheck()
        self:CreateOrRefreshPullTimer()
    elseif (not shouldShow and not combat) then
        self.showStatus = false
        self:CreateOrRefreshReadyCheck()
        self:CreateOrRefreshPullTimer()
    end
end

local function FormatBrezzTimer(remaining)
    if remaining <= 0 then return '00:00' end
    local minutes = math.floor(remaining / 60)
    local seconds = math.floor(remaining % 60)
    return string.format('%02d:%02d', minutes, seconds)
end

local function ApplyBrezzTimerPosition(frame)
    local timerPos = data:GetDataByKey('brezzTimerPosition') or 'right'
    local text = frame.timerText
    text:ClearAllPoints()
    if timerPos == 'left' then
        text:SetPoint('RIGHT', frame, 'LEFT', -BREZZ_TIMER_GAP, 0)
        text:SetJustifyH('RIGHT')
    elseif timerPos == 'top' then
        text:SetPoint('BOTTOM', frame, 'TOP', 0, BREZZ_TIMER_GAP)
        text:SetJustifyH('CENTER')
    elseif timerPos == 'bottom' then
        text:SetPoint('TOP', frame, 'BOTTOM', 0, -BREZZ_TIMER_GAP)
        text:SetJustifyH('CENTER')
    else
        text:SetPoint('LEFT', frame, 'RIGHT', BREZZ_TIMER_GAP, 0)
        text:SetJustifyH('LEFT')
    end
end

raidToolsModule.IsBrezzInActiveContent = function(self)
    local _, _, diffID = GetInstanceInfo()
    if not BATTLE_RES_DIFFICULTIES[diffID] then return false end

    local visibility = data:GetDataByKey('brezzVisibility') or 'mplus_or_raid'
    if visibility == 'always' then
        return true
    end

    local isInMPlus = C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive()
    if visibility == 'mplus' then
        return isInMPlus
    end

    if visibility == 'raid' then
        return self.brezzEncounterActive and IsInRaid()
    end

    if isInMPlus then return true end
    return self.brezzEncounterActive and IsInRaid()
end

raidToolsModule.UpdateBrezzDisplay = function(self)
    if not self.brezzFrame then return end
    local frame = self.brezzFrame

    local chargesInfo = C_Spell.GetSpellCharges(REBIRTH_SPELL_ID)
    if chargesInfo then
        local charges = chargesInfo.currentCharges
        local maxCharges = chargesInfo.maxCharges
        local cooldownStart = chargesInfo.cooldownStartTime
        local fullDuration = chargesInfo.cooldownDuration

        frame.chargesText:SetText(tostring(charges))
        frame.icon:SetVertexColor(charges == 0 and 0.35 or 1, charges == 0 and 0.35 or 1, charges == 0 and 0.35 or 1, 1)

        if charges < maxCharges and fullDuration > 0 and cooldownStart > 0 then
            local remaining = fullDuration - (GetTime() - cooldownStart)
            frame.timerText:SetText(remaining > 0 and FormatBrezzTimer(remaining) or '')
        else
            frame.timerText:SetText('')
        end
    else
        frame.chargesText:SetText('')
        frame.timerText:SetText('')
        frame.icon:SetVertexColor(1, 1, 1, 1)
    end
end

raidToolsModule.ApplyBrezzLayout = function(self)
    if not self.brezzFrame then return end
    local frame = self.brezzFrame
    local size = data:GetDataByKey('brezzSize') or 41

    EXUI:SetSize(frame, size, size)

    local brezzFont = LSM:Fetch('font', data:GetDataByKey('brezzFont'))
    if type(brezzFont) ~= 'string' then
        brezzFont = EXUI.const.fonts.DEFAULT
    end
    local brezzFontName = tostring(brezzFont)
    local chargeFontSize = tonumber(data:GetDataByKey('brezzFontSize')) or 24
    local timerFontSize = math.max(9, math.floor(size * 0.35))

    ---@diagnostic disable-next-line:param-type-mismatch
    frame.chargesText:SetFont(brezzFontName, chargeFontSize, 'OUTLINE')
    frame.timerText:SetFont(brezzFontName, timerFontSize, 'OUTLINE')

    ApplyBrezzTimerPosition(frame)
end

raidToolsModule.UpdateBrezzVisibility = function(self)
    if not self.brezzFrame then return end

    if self.brezzEditorShowing then
        self.brezzFrame:Show()
        return
    end

    if not data:GetDataByKey('brezzEnabled') then
        self.brezzFrame:Hide()
        return
    end

    if not self:IsBrezzInActiveContent() then
        self.brezzFrame:Hide()
        return
    end

    self.brezzFrame:Show()
end

raidToolsModule.CreateBrezz = function(self)
    local size = data:GetDataByKey('brezzSize') or 41

    self.brezzFrame = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    self.brezzFrame:SetClampedToScreen(true)
    self.brezzFrame:Hide()

    self.brezzFrame:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    self.brezzFrame:SetBackdropColor(0, 0, 0, 0.4)
    self.brezzFrame:SetBackdropBorderColor(0, 0, 0, 1)

    local icon = self.brezzFrame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    local spellInfo = C_Spell.GetSpellInfo(REBIRTH_SPELL_ID)
    if spellInfo then
        icon:SetTexture(spellInfo.iconID)
    end
    if icon.SetMaskTexture then
        icon:SetMaskTexture(EXUI.const.textures.frame.iconMask)
    else
        local mask = self.brezzFrame:CreateMaskTexture()
        mask:SetTexture(EXUI.const.textures.frame.iconMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        mask:SetAllPoints(icon)
        icon:AddMaskTexture(mask)
    end
    self.brezzFrame.icon = icon

    local chargesText = self.brezzFrame:CreateFontString(nil, 'OVERLAY')
    chargesText:SetPoint('CENTER')
    chargesText:SetFont(EXUI.const.fonts.DEFAULT, 24, 'OUTLINE')
    chargesText:SetTextColor(1, 1, 1, 1)
    chargesText:SetText('')
    self.brezzFrame.chargesText = chargesText

    local timerText = self.brezzFrame:CreateFontString(nil, 'OVERLAY')
    timerText:SetFont(EXUI.const.fonts.DEFAULT, math.max(9, math.floor(size * 0.35)), 'OUTLINE')
    timerText:SetTextColor(1, 1, 1, 1)
    timerText:SetText('')
    self.brezzFrame.timerText = timerText

    local timeSinceUpdate = 0
    self.brezzFrame:SetScript('OnUpdate', function(_, elapsed)
        timeSinceUpdate = timeSinceUpdate + elapsed
        if timeSinceUpdate < 0.5 then return end
        timeSinceUpdate = 0
        raidToolsModule:UpdateBrezzDisplay()
    end)

    self.brezzFrame:RegisterEvent('ENCOUNTER_START')
    self.brezzFrame:RegisterEvent('ENCOUNTER_END')
    self.brezzFrame:RegisterEvent('CHALLENGE_MODE_START')
    self.brezzFrame:RegisterEvent('CHALLENGE_MODE_COMPLETED')
    self.brezzFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.brezzFrame:SetScript('OnEvent', function(_, event)
        if event == 'ENCOUNTER_START' then
            raidToolsModule.brezzEncounterActive = true
        elseif event == 'ENCOUNTER_END' then
            raidToolsModule.brezzEncounterActive = false
        elseif event == 'PLAYER_ENTERING_WORLD' then
            raidToolsModule.brezzEncounterActive = IsEncounterInProgress()
        end
        raidToolsModule:UpdateBrezzVisibility()
    end)

    ApplyBrezzTimerPosition(self.brezzFrame)

    editor:RegisterFrameForEditor(self.brezzFrame, 'Brezz', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('brezzAnchor', point)
        data:SetDataByKey('brezzRelativePoint', relativePoint)
        data:SetDataByKey('brezzXOff', xOfs)
        data:SetDataByKey('brezzYOff', yOfs)
        raidToolsModule:CreateOrRefreshBrezz()
    end, function(frame)
        raidToolsModule.brezzEditorShowing = true
        raidToolsModule.brezzFrame:Show()
        frame.editor:SetEditorAsMovable()
    end, function()
        raidToolsModule.brezzEditorShowing = false
        raidToolsModule:UpdateBrezzVisibility()
    end)
end

raidToolsModule.CreateOrRefreshBrezz = function(self)
    local isEnabled = data:GetDataByKey('brezzEnabled')
    if not self.brezzFrame and isEnabled then self:CreateBrezz() end
    if not isEnabled then
        if self.brezzFrame then
            self.brezzFrame:Hide()
        end
        return
    end

    self.brezzFrame:ClearAllPoints()
    EXUI:SetPoint(self.brezzFrame, data:GetDataByKey('brezzAnchor'), UIParent,
        data:GetDataByKey('brezzRelativePoint'), data:GetDataByKey('brezzXOff'),
        data:GetDataByKey('brezzYOff'))

    self:ApplyBrezzLayout()
    self.brezzEncounterActive = IsEncounterInProgress()
    self:UpdateBrezzDisplay()
    self:UpdateBrezzVisibility()
end

raidToolsModule.CreateReadyCheck = function(self)
    self.readyCheckFrame = CreateFrame('Button', nil, UIParent, "BackdropTemplate")
    self.readyCheckFrame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    self.readyCheckFrame:SetBackdropColor(0, 0, 0, 0.4)
    self.readyCheckFrame:SetBackdropBorderColor(0, 0, 0, 1)

    local readyBg = data:GetDataByKey('readyCheckBackgroundColor')
    if (type(readyBg) == 'table') then
        self.readyCheckFrame:SetBackdropColor(readyBg.r or 0, readyBg.g or 0, readyBg.b or 0, readyBg.a or 1)
    else
        self.readyCheckFrame:SetBackdropColor(0, 0, 0, 0.8)
    end

    local text = self.readyCheckFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('CENTER')
    text:SetText('Ready Check')
    text:SetVertexColor(1, 1, 1, 1)
    self.readyCheckFrame.text = text

    self.readyCheckFrame:SetScript('OnEnter', function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    self.readyCheckFrame:SetScript('OnLeave', function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end)

    self.readyCheckFrame:SetScript('OnClick', function(self)
        DoReadyCheck()
    end)

    local editorOnShow = function(frame)
        frame:SetPoint(data:GetDataByKey('readyCheckAnchor'), data:GetDataByKey('readyCheckXOff'),
            data:GetDataByKey('readyCheckYOff'))
        frame:SetSize(data:GetDataByKey('readyCheckWidth'), data:GetDataByKey('readyCheckHeight'))
        frame:Show()
    end

    local editorOnHide = function(frame)
        frame:Hide()
        raidToolsModule:CreateOrRefreshReadyCheck()
    end

    editor:RegisterFrameForEditor(self.readyCheckFrame, 'Ready Check', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('readyCheckAnchor', point)
        data:SetDataByKey('readyCheckRelativePoint', relativePoint)
        data:SetDataByKey('readyCheckXOff', xOfs)
        data:SetDataByKey('readyCheckYOff', yOfs)
    end, editorOnShow, editorOnHide)
end

raidToolsModule.CreateOrRefreshReadyCheck = function(self)
    local isEnabled = data:GetDataByKey('readyCheckEnabled')
    if (not self.readyCheckFrame and isEnabled) then self:CreateReadyCheck() end
    if (not self.showStatus) then
        if (self.readyCheckFrame) then
            self.readyCheckFrame:Hide()
        end
        return
    end
    if (not isEnabled) then
        if (self.readyCheckFrame) then
            self.readyCheckFrame:Hide()
        end
        return;
    end
    self.readyCheckFrame:Show()
    self.readyCheckFrame:ClearAllPoints()
    EXUI:SetPoint(
        self.readyCheckFrame,
        data:GetDataByKey('readyCheckAnchor'),
        UIParent,
        data:GetDataByKey('readyCheckAnchor'),
        data:GetDataByKey('readyCheckXOff'),
        data:GetDataByKey('readyCheckYOff')
    )
    EXUI:SetSize(self.readyCheckFrame, data:GetDataByKey('readyCheckWidth'), data:GetDataByKey('readyCheckHeight'))
    local readyBg = data:GetDataByKey('readyCheckBackgroundColor')
    if (type(readyBg) == 'table') then
        self.readyCheckFrame:SetBackdropColor(readyBg.r or 0, readyBg.g or 0, readyBg.b or 0, readyBg.a or 1)
    else
        self.readyCheckFrame:SetBackdropColor(0, 0, 0, 0.8)
    end
    local readyFont = LSM:Fetch('font', data:GetDataByKey('readyCheckFont'))
    if (type(readyFont) ~= 'string') then
        readyFont = EXUI.const.fonts.DEFAULT
    end
    local readyFontName = tostring(readyFont)
    local readyFontSize = tonumber(data:GetDataByKey('readyCheckFontSize')) or 14
    self.readyCheckFrame.text:SetFont(readyFontName, readyFontSize, 'OUTLINE')
end

raidToolsModule.CreatePullTimer = function(self)
    self.pullTimerFrame = CreateFrame('Button', nil, UIParent, "BackdropTemplate")
    self.pullTimerFrame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    self.pullTimerFrame:SetBackdropColor(0, 0, 0, 0.4)
    self.pullTimerFrame:SetBackdropBorderColor(0, 0, 0, 1)

    self.pullTimerFrame:SetClipsChildren(true)
    self.pullTimerFrame:RegisterForClicks('LeftButtonDown', 'RightButtonDown')

    local pullBg = data:GetDataByKey('pullTimerBackgroundColor')
    if (type(pullBg) == 'table') then
        self.pullTimerFrame:SetBackdropColor(pullBg.r or 0, pullBg.g or 0, pullBg.b or 0, pullBg.a or 1)
    else
        self.pullTimerFrame:SetBackdropColor(0, 0, 0, 0.8)
    end

    local text = self.pullTimerFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('CENTER')
    text:SetText('Pull Timer')
    text:SetVertexColor(1, 1, 1, 1)
    self.pullTimerFrame.text = text

    self.pullTimerFrame:SetScript('OnEnter', function(self)
        self:SetBackdropBorderColor(1, 1, 1, 1)
    end)
    self.pullTimerFrame:SetScript('OnLeave', function(self)
        self:SetBackdropBorderColor(0, 0, 0, 1)
    end)

    self.pullTimerFrame:SetScript('OnClick', function(self, button)
        if (button == 'LeftButton') then
            local seconds = tonumber(data:GetDataByKey('pullTimerSeconds')) or 10
            seconds = math.min(math.max(seconds, 5), 20)
            C_PartyInfo.DoCountdown(seconds)
        elseif (button == 'RightButton') then
            C_PartyInfo.DoCountdown(0)
        end
    end)

    local editorOnShow = function(frame)
        frame:Show()
        frame:SetPoint(data:GetDataByKey('pullTimerAnchor'), data:GetDataByKey('pullTimerXOff'),
            data:GetDataByKey('pullTimerYOff'))
        frame:SetSize(data:GetDataByKey('pullTimerWidth'), data:GetDataByKey('pullTimerHeight'))
    end

    local editorOnHide = function(frame)
        frame:Hide()
        raidToolsModule:CreateOrRefreshPullTimer()
    end

    editor:RegisterFrameForEditor(self.pullTimerFrame, 'Pull Timer', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('pullTimerAnchor', point)
        data:SetDataByKey('pullTimerRelativePoint', relativePoint)
        data:SetDataByKey('pullTimerXOff', xOfs)
        data:SetDataByKey('pullTimerYOff', yOfs)
    end, editorOnShow, editorOnHide)
end

raidToolsModule.CreateOrRefreshPullTimer = function(self)
    local isEnabled = data:GetDataByKey('pullTimerEnabled')
    if (not self.pullTimerFrame and isEnabled) then self:CreatePullTimer() end
    if (not self.showStatus) then
        if (self.pullTimerFrame) then
            self.pullTimerFrame:Hide()
        end
        return
    end
    if (not isEnabled) then
        if (self.pullTimerFrame) then
            self.pullTimerFrame:Hide()
        end
        return;
    end
    self.pullTimerFrame:Show()
    self.pullTimerFrame:ClearAllPoints()
    EXUI:SetPoint(
        self.pullTimerFrame,
        data:GetDataByKey('pullTimerAnchor'),
        UIParent,
        data:GetDataByKey('pullTimerAnchor'),
        data:GetDataByKey('pullTimerXOff'),
        data:GetDataByKey('pullTimerYOff')
    )
    EXUI:SetSize(self.pullTimerFrame, data:GetDataByKey('pullTimerWidth'), data:GetDataByKey('pullTimerHeight'))
    local pullBg = data:GetDataByKey('pullTimerBackgroundColor')
    if (type(pullBg) == 'table') then
        self.pullTimerFrame:SetBackdropColor(pullBg.r or 0, pullBg.g or 0, pullBg.b or 0, pullBg.a or 1)
    else
        self.pullTimerFrame:SetBackdropColor(0, 0, 0, 0.8)
    end
    local pullFont = LSM:Fetch('font', data:GetDataByKey('pullTimerFont'))
    if (type(pullFont) ~= 'string') then
        pullFont = EXUI.const.fonts.DEFAULT
    end
    local pullFontName = tostring(pullFont)
    local pullFontSize = tonumber(data:GetDataByKey('pullTimerFontSize')) or 14
    ---@diagnostic disable-next-line:param-type-mismatch
    self.pullTimerFrame.text:SetFont(pullFontName, pullFontSize, 'OUTLINE')
end

raidToolsModule.CreateEncounterTimer = function(self)
    local frame = CreateFrame('Frame', nil, UIParent, "BackdropTemplate")
    frame:SetBackdrop(EXUI.const.backdrop.pixelPerfect())
    frame:SetBackdropColor(0, 0, 0, 0.4)
    frame:SetBackdropBorderColor(0, 0, 0, 1)

    local text = frame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('LEFT', 12, 0)
    text:SetJustifyH('LEFT')
    text:SetText('00:00.00')
    text:SetVertexColor(1, 1, 1, 1)
    frame.Text = text


    frame.startTime = 0
    frame.isRunning = false
    frame.isEnabled = false
    frame.encounterType = EncounterTimerType.ENCOUNTER

    frame.Update = function(self)
        if (not self.isRunning or not self.isEnabled) then return end
        local elapsed = GetTime() - self.startTime
        local minutes = math.floor(elapsed / 60)
        local seconds = elapsed % 60
        local milliseconds = (elapsed - math.floor(elapsed)) * 100
        self.Text:SetText(string.format('%02d:%02d.%02d', minutes, seconds, milliseconds))
    end

    frame.Start = function(self)
        if (not self.isEnabled and not self.isPreview) then return end
        self.isRunning = true
        self.startTime = GetTime()
        self:Show()
        self:SetScript('OnUpdate', self.Update)
    end

    frame.Stop = function(self)
        self.isRunning = false
        self:Hide()
    end

    frame.OnEvent = function(self, event)
        if (event == 'ENCOUNTER_START' or event == 'PLAYER_REGEN_DISABLED') then
            self:Start()
        elseif (event == 'ENCOUNTER_END' or event == 'PLAYER_REGEN_ENABLED') then
            self:Stop()
        elseif (event == 'PLAYER_ENTERING_WORLD' and self.isRunning and not InCombatLockdown()) then
            self:Stop()
        end
    end

    frame.RegisterEvents = function(self)
        self:UnregisterAllEvents()
        if (self.encounterType == EncounterTimerType.ENCOUNTER) then
            self:RegisterEvent('ENCOUNTER_START')
            self:RegisterEvent('ENCOUNTER_END')
        elseif (self.encounterType == EncounterTimerType.COMBAT) then
            self:RegisterEvent('PLAYER_REGEN_ENABLED')
            self:RegisterEvent('PLAYER_REGEN_DISABLED')
        end
        self:RegisterEvent('PLAYER_ENTERING_WORLD')
    end

    frame.DisplayTest = function(self)
        if (self.isRunning) then
            self.isPreview = false
            self:Stop()
        else
            self.isPreview = true
            self:Start()
        end
    end
    frame:SetScript('OnEvent', frame.OnEvent)

    editor:RegisterFrameForEditor(frame, 'Encounter Timer', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('encounterTimerAnchor', point)
        data:SetDataByKey('encounterTimerRelativePoint', relativePoint)
        data:SetDataByKey('encounterTimerXOff', xOfs)
        data:SetDataByKey('encounterTimerYOff', yOfs)
    end, function() frame:DisplayTest() end, function() frame:DisplayTest() end)

    self.encounterTimerFrame = frame
    frame:Hide()
end

raidToolsModule.CreateOrRefreshEncounterTimer = function(self)
    if (not self.encounterTimerFrame) then self:CreateEncounterTimer() end

    local isEnabled = data:GetDataByKey('encounterTimerEnabled')
    self.encounterTimerFrame.isEnabled = isEnabled
    self.encounterTimerFrame.encounterType = data:GetDataByKey('encounterTimerType')

    self.encounterTimerFrame:RegisterEvents()

    self.encounterTimerFrame.Text:SetFont(LSM:Fetch('font', data:GetDataByKey('encounterTimerFont')),
        data:GetDataByKey('encounterTimerFontSize'), data:GetDataByKey('encounterTimerFontFlag'))
    self.encounterTimerFrame.Text:SetVertexColor(data:GetDataByKey('encounterTimerFontColor').r,
        data:GetDataByKey('encounterTimerFontColor').g, data:GetDataByKey('encounterTimerFontColor').b,
        data:GetDataByKey('encounterTimerFontColor').a)
    self.encounterTimerFrame:SetBackdropColor(data:GetDataByKey('encounterTimerBackgroundColor').r,
        data:GetDataByKey('encounterTimerBackgroundColor').g, data:GetDataByKey('encounterTimerBackgroundColor').b,
        data:GetDataByKey('encounterTimerBackgroundColor').a)
    self.encounterTimerFrame:SetBackdropBorderColor(data:GetDataByKey('encounterTimerBorderColor').r,
        data:GetDataByKey('encounterTimerBorderColor').g, data:GetDataByKey('encounterTimerBorderColor').b,
        data:GetDataByKey('encounterTimerBorderColor').a)
    self.encounterTimerFrame:ClearAllPoints()
    EXUI:SetPoint(self.encounterTimerFrame, data:GetDataByKey('encounterTimerAnchor'), UIParent,
        data:GetDataByKey('encounterTimerRelativePoint'), data:GetDataByKey('encounterTimerXOff'),
        data:GetDataByKey('encounterTimerYOff'))
    self.encounterTimerFrame.Text:SetText('00:00.00')
    local width = self.encounterTimerFrame.Text:GetStringWidth()
    local height = self.encounterTimerFrame.Text:GetStringHeight()
    EXUI:SetSize(self.encounterTimerFrame, width + 18, height + 16)
end

raidToolsModule.CreateOrRefreshAll = function(self)
    self:CreateOrRefreshBrezz()
    self:CreateOrRefreshReadyCheck()
    self:CreateOrRefreshPullTimer()
    self:CreateOrRefreshEncounterTimer()
end
