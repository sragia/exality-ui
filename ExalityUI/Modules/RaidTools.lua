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

raidToolsModule.brezzFrame = nil
raidToolsModule.readyCheckFrame = nil
raidToolsModule.pullTimerFrame = nil
raidToolsModule.showStatus = false

raidToolsModule.useTabs = true
raidToolsModule.useSplitView = false

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

raidToolsModule.GetOrder = function(self)
    return 30
end

raidToolsModule.GetDefaults = function(self)
    return {
        brezzEnabled = false,
        brezzAnchor = 'CENTER',
        brezzRelativePoint = 'CENTER',
        brezzXOff = 0,
        brezzYOff = 0,
        brezzSize = 100,
        brezzFont = 'DMSans',
        brezzFontSize = 24,
        readyCheckEnabled = false,
        readyCheckAnchor = 'CENTER',
        readyCheckRelativePoint = 'CENTER',
        readyCheckXOff = 0,
        readyCheckYOff = 0,
        readyCheckWidth = 100,
        readyCheckHeight = 30,
        readyCheckFont = 'DMSans',
        readyCheckFontSize = 14,
        readyCheckBackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
        pullTimerEnabled = false,
        pullTimerAnchor = 'CENTER',
        pullTimerRelativePoint = 'CENTER',
        pullTimerXOff = 0,
        pullTimerYOff = 0,
        pullTimerWidth = 100,
        pullTimerHeight = 30,
        pullTimerFont = 'DMSans',
        pullTimerFontSize = 14,
        pullTimerSeconds = 10,
        pullTimerBackgroundColor = { r = 0, g = 0, b = 0, a = 0.8 },
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
                onObserve = function(value, oldValue)
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
                onChange = function(f, value)
                    data:SetDataByKey('brezzSize', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'spacer',
                width = 83
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
                onChange = function(f, value)
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
                onChange = function(f, value)
                    data:SetDataByKey('brezzYOff', value)
                    self:CreateOrRefreshBrezz()
                end
            },
            {
                type = 'spacer',
                width = 50
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
                onChange = function(f, value)
                    data:SetDataByKey('brezzFontSize', value)
                    self:CreateOrRefreshBrezz()
                end
            },
        }
    end
    if (currTabID == 'readyCheck') then
        return {
            {
                type = 'toggle',
                name = 'readyCheckEnabled',
                label = 'Enable',
                onObserve = function(value, oldValue)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onObserve = function(value, oldValue)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
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
                onChange = function(f, value)
                    data:SetDataByKey('pullTimerYOff', value)
                    self:CreateOrRefreshPullTimer()
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

raidToolsModule.CreateBrezz = function(self)
    self.brezzFrame = CreateFrame('Frame', nil, UIParent, "BackdropTemplate")
    self.brezzFrame.inCombat = false

    local cooldown = CreateFrame('Cooldown', nil, self.brezzFrame)
    cooldown:SetPoint('TOPLEFT', -1, 1)
    cooldown:SetPoint('BOTTOMRIGHT', 1, -1)
    cooldown:SetSwipeColor(0, 0, 0, 0.6)
    cooldown:SetSwipeTexture(EXUI.const.textures.frame.bg)
    self.brezzFrame.cooldown = cooldown

    self.brezzFrame:SetBackdrop(EXUI.const.backdrop.DEFAULT)
    self.brezzFrame:SetBackdropColor(0, 0, 0, 0.4)
    self.brezzFrame:SetBackdropBorderColor(0, 0, 0, 1)

    local elementFrame = CreateFrame('Frame', nil, self.brezzFrame)
    elementFrame:SetAllPoints()
    elementFrame:SetFrameLevel(cooldown:GetFrameLevel() + 10)

    local texture = self.brezzFrame:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture([[Interface/ICONS/spell_nature_reincarnation]])
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 0.8)
    texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)

    local text = elementFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 24, 'OUTLINE')
    text:SetPoint('CENTER', elementFrame, 'TOPRIGHT', -5, -2)
    text:SetText('1')
    text:SetVertexColor(1, 1, 1, 1)
    self.brezzFrame.text = text
    self.brezzFrame.timer = 0

    self.brezzFrame.onUpdate = function(self, elapsed)
        self.timer = self.timer + elapsed
        if (self.timer >= 1) then
            self.timer = 0
            local charges = C_Spell.GetSpellCharges(20484)
            if (not charges) then
                self:Hide()
                return;
            end
            self.cooldown:SetCooldown(charges.cooldownStartTime, charges.cooldownDuration)
            self.text:SetText(charges.currentCharges)
            self:Show()
        end
    end

    self.brezzFrame:RegisterEvent('ENCOUNTER_START')
    self.brezzFrame:RegisterEvent('ENCOUNTER_END')
    self.brezzFrame:RegisterEvent('CHALLENGE_MODE_START')
    self.brezzFrame:RegisterEvent('CHALLENGE_MODE_COMPLETED')
    self.brezzFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    self.brezzFrame.CheckVisibility = function(self)
        local isInMPlus = C_ChallengeMode.IsChallengeModeActive()
        local isInEncounter = self.inEncounter
        local isInCombat = InCombatLockdown()
        return isInMPlus or (isInEncounter and isInCombat)
    end
    self.brezzFrame:SetScript('OnEvent', function(self, event, ...)
        if (event == 'ENCOUNTER_START') then
            self.inEncounter = true
        elseif (event == 'ENCOUNTER_END') then
            self.inEncounter = false
        end

        if (self:CheckVisibility()) then
            self:Show()
            self:SetScript('OnUpdate', self.onUpdate)
        else
            self:Hide()
            self:SetScript('OnUpdate', nil)
        end
    end)

    local cdFont = CreateFont('ExalityUI_Brezz_CD_Font')
    cdFont:SetFont(EXUI.const.fonts.DEFAULT, 14, 'OUTLINE')

    self.brezzFrame.cdFont = cdFont
    self.brezzFrame.cooldown:SetCountdownFont('ExalityUI_Brezz_CD_Font')


    self.brezzFrame:SetSize(100, 100)

    local editorOnShow = function(frame)
        frame.editor:SetEditorAsMovable()
    end

    editor:RegisterFrameForEditor(self.brezzFrame, 'Brezz', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('brezzAnchor', point)
        data:SetDataByKey('brezzRelativePoint', relativePoint)
        data:SetDataByKey('brezzXOff', xOfs)
        data:SetDataByKey('brezzYOff', yOfs)
        raidToolsModule:CreateOrRefreshBrezz()
    end, editorOnShow)
end

raidToolsModule.CreateOrRefreshBrezz = function(self)
    local isEnabled = data:GetDataByKey('brezzEnabled')
    if (not self.brezzFrame and isEnabled) then self:CreateBrezz() end
    if (not isEnabled) then
        if (self.brezzFrame) then
            self.brezzFrame:SetScript('OnUpdate', nil)
            self.brezzFrame:Hide()
        end
        return;
    end

    self.brezzFrame:ClearAllPoints()
    self.brezzFrame:SetPoint(data:GetDataByKey('brezzAnchor'), data:GetDataByKey('brezzXOff'),
        data:GetDataByKey('brezzYOff'))
    self.brezzFrame:SetSize(data:GetDataByKey('brezzSize'), data:GetDataByKey('brezzSize'))

    local brezzFont = LSM:Fetch('font', data:GetDataByKey('brezzFont'))
    if (type(brezzFont) ~= 'string') then
        brezzFont = EXUI.const.fonts.DEFAULT
    end
    local brezzFontName = tostring(brezzFont)
    local brezzFontSize = tonumber(data:GetDataByKey('brezzFontSize')) or 24
    self.brezzFrame.cdFont:SetFont(brezzFontName, 14, 'OUTLINE')
    ---@diagnostic disable-next-line:param-type-mismatch
    self.brezzFrame.text:SetFont(brezzFontName, brezzFontSize, 'OUTLINE')
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

raidToolsModule.CreateOrRefreshAll = function(self)
    self:CreateOrRefreshBrezz()
    self:CreateOrRefreshReadyCheck()
    self:CreateOrRefreshPullTimer()
end
