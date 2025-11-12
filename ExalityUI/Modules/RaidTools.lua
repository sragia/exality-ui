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
raidToolsModule.showStatus = false

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
    }
end

raidToolsModule.GetOptions = function(self)
    return {
        {
            type = 'title',
            label = 'Battle Ress',
            width = 100
        },
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
            onChange = function(f, value)
                data:SetDataByKey('brezzFontSize', value)
                self:CreateOrRefreshBrezz()
            end
        },
        {
            type = 'title',
            label = 'Ready Check',
            width = 100
        },
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
            type = 'spacer',
            width = 68
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
            width = 68
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

raidToolsModule.HandleChecks = function(self, recheck)
    local combat = InCombatLockdown()
    local leader = UnitIsGroupLeader('player')
    local assist = UnitIsGroupAssistant('player')
    local shouldShow = assist or leader


    if (recheck and not combat and shouldShow) then
        self.showStatus = true
        self:CreateOrRefreshReadyCheck()
    elseif (recheck and shouldShow) then
        C_Timer.After(3, function() self:HandleChecks(true) end)
    elseif (combat and self.showStatus and not shouldShow) then
        C_Timer.After(3, function() self:HandleChecks(true) end)
    elseif (shouldShow) then
        self.showStatus = true
        self:CreateOrRefreshReadyCheck()
    elseif (not shouldShow and not combat) then
        self.showStatus = false
        self:CreateOrRefreshReadyCheck()
    end
end

raidToolsModule.CreateBrezz = function(self)
    self.brezzFrame = CreateFrame('Frame', nil, UIParent)
    self.brezzFrame.inCombat = false

    local texture = self.brezzFrame:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture([[Interface/ICONS/spell_nature_reincarnation]])
    texture:SetAllPoints()
    texture:SetVertexColor(1, 1, 1, 0.8)
    texture:SetTexCoord(0.15, 0.85, 0.15, 0.85)

    local mask = self.brezzFrame:CreateMaskTexture(nil, 'BACKGROUND')
    mask:SetTexture(EXUI.const.textures.frame.roundedSquare)
    mask:SetAllPoints()
    texture:AddMaskTexture(mask)

    local text = self.brezzFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 24, 'OUTLINE')
    text:SetPoint('CENTER')
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
            self.text:SetText(charges.currentCharges)
            self:Show()
        end
    end
    
    self.brezzFrame:RegisterEvent('PLAYER_IN_COMBAT_CHANGED')
    self.brezzFrame:SetScript('OnEvent', function(self, event, ...)
        if (event == 'PLAYER_IN_COMBAT_CHANGED') then
            self.inCombat = ...
            if (self.inCombat) then
                self:Show()
                self:SetScript('OnUpdate', self.onUpdate)
            else
                self:Hide()
                self:SetScript('OnUpdate', nil)
            end
        end
    end)
    

    self.brezzFrame:SetSize(100, 100)

    editor:RegisterFrameForEditor(self.brezzFrame, 'Brezz', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('brezzAnchor', point)
        data:SetDataByKey('brezzRelativePoint', relativePoint)
        data:SetDataByKey('brezzXOff', xOfs)
        data:SetDataByKey('brezzYOff', yOfs)
    end)
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
    if (InCombatLockdown()) then
        self.brezzFrame:Show()
    else 
        self.brezzFrame:Hide()
    end

    self.brezzFrame:SetPoint(data:GetDataByKey('brezzAnchor'), data:GetDataByKey('brezzXOff'), data:GetDataByKey('brezzYOff'))
    self.brezzFrame:SetSize(data:GetDataByKey('brezzSize'), data:GetDataByKey('brezzSize'))

    self.brezzFrame.text:SetFont(LSM:Fetch('font', data:GetDataByKey('brezzFont')), data:GetDataByKey('brezzFontSize'), 'OUTLINE')
end

raidToolsModule.CreateReadyCheck = function(self)
    self.readyCheckFrame = CreateFrame('Button', nil, UIParent)
    local texture = self.readyCheckFrame:CreateTexture(nil, 'BACKGROUND')
    texture:SetTexture(EXUI.const.textures.frame.inputs.buttonBg)
    texture:SetTextureSliceMargins(10, 10, 10, 10)
    texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    texture:SetVertexColor(148 / 255, 244 / 255, 1, 1)
    texture:SetVertexColor(0, 0, 0, 0.8)
    texture:SetAllPoints()

    local text = self.readyCheckFrame:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    text:SetPoint('CENTER')
    text:SetText('Ready Check')
    text:SetVertexColor(1, 1, 1, 1)
    self.readyCheckFrame.text = text

    local hover = CreateFrame('Frame', nil, self.readyCheckFrame)
    hover:SetAllPoints()
    local hoverTexture = hover:CreateTexture(nil, 'BACKGROUND')
    hoverTexture:SetTexture(EXUI.const.textures.frame.inputs.buttonHover)
    hoverTexture:SetTextureSliceMargins(25, 25, 25, 25)
    hoverTexture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    hoverTexture:SetVertexColor(1, 1, 1, 1)
    hoverTexture:SetAllPoints()
    hover:SetAlpha(0)

    local onHover = EXUI.utils.animation.fade(hover, 0.1, 0, 1)
    local onLeave = EXUI.utils.animation.fade(hover, 0.1, 1, 0)
    self.readyCheckFrame.onHover = onHover
    self.readyCheckFrame.onLeave = onLeave

    self.readyCheckFrame:SetScript('OnEnter', function(self)
        self.onHover:Play()
    end)
    self.readyCheckFrame:SetScript('OnLeave', function(self)
        self.onLeave:Play()
    end)

    self.readyCheckFrame:SetScript('OnClick', function(self)
        DoReadyCheck()
    end)

    editor:RegisterFrameForEditor(self.readyCheckFrame, 'Ready Check', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('readyCheckAnchor', point)
        data:SetDataByKey('readyCheckRelativePoint', relativePoint)
        data:SetDataByKey('readyCheckXOff', xOfs)
        data:SetDataByKey('readyCheckYOff', yOfs)
    end)
end

raidToolsModule.CreateOrRefreshReadyCheck = function(self)
    local isEnabled = data:GetDataByKey('readyCheckEnabled')
    if (not self.showStatus) then 
        if (self.readyCheckFrame) then
            self.readyCheckFrame:Hide()
        end
        return end
    if (not self.readyCheckFrame and isEnabled) then self:CreateReadyCheck() end 
    if (not isEnabled) then
        if (self.readyCheckFrame) then
            self.readyCheckFrame:Hide()
        end
        return;
    end
    self.readyCheckFrame:Show()
    self.readyCheckFrame:SetPoint(data:GetDataByKey('readyCheckAnchor'), data:GetDataByKey('readyCheckXOff'), data:GetDataByKey('readyCheckYOff'))
    self.readyCheckFrame:SetSize(data:GetDataByKey('readyCheckWidth'), data:GetDataByKey('readyCheckHeight'))
    self.readyCheckFrame.text:SetFont(LSM:Fetch('font', data:GetDataByKey('readyCheckFont')), data:GetDataByKey('readyCheckFontSize'), 'OUTLINE')
end

raidToolsModule.CreateOrRefreshAll = function(self)
    self:CreateOrRefreshBrezz()
    self:CreateOrRefreshReadyCheck()
end