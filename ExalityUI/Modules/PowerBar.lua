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

---@class EXUIPowerBarModule
local powerBarModule = EXUI:GetModule('power-bar-module')

powerBarModule.powerBar = nil

powerBarModule.powerTypeLabels = {
    [Enum.PowerType.Mana] = 'Mana',
    [Enum.PowerType.Rage] = 'Rage',
    [Enum.PowerType.Focus] = 'Focus',
    [Enum.PowerType.Energy] = 'Energy',
    [Enum.PowerType.ComboPoints] = 'Combo Points',
    [Enum.PowerType.RunicPower] = 'Runic Power',
    [Enum.PowerType.HolyPower] = 'Holy Power',
    [Enum.PowerType.Maelstrom] = 'Maelstrom',
    [Enum.PowerType.Chi] = 'Chi',
    [Enum.PowerType.Insanity] = 'Insanity',
    [Enum.PowerType.ArcaneCharges] = 'Arcane Charges',
    [Enum.PowerType.Fury] = 'Fury',
    [Enum.PowerType.Pain] = 'Pain',
    [Enum.PowerType.ComboPoints] = 'Combo Points'
}

powerBarModule.usesTicks = {
    [Enum.PowerType.HolyPower] = true,
    [Enum.PowerType.ComboPoints] = true,
}

powerBarModule.Init = function(self)
    optionsController:RegisterModule(self)
    data:UpdateDefaults(self:GetDefaults())
    self:CreateOrRefresh()
end

powerBarModule.GetName = function(self)
    return 'Power Bar'
end

powerBarModule.GetDefaults = function(self)
    return {
        powerBarEnabled = false,
        powerBarTexture = 'ExalityUI Status Bar',
        powerBarWidth = 200,
        powerBarHeight = 20,
        powerBarXOff = 0,
        powerBarYOff = 0,
        powerBarAnchor = 'CENTER',
        powerBarRelativePoint = 'CENTER',
        powerBarBackgroundColor = {r = 0, g = 0, b = 0, a = 1},
        powerBarColor = {r = 1, g = 1, b = 1, a = 1},
        powerBarPowerType = '',
        powerBarPowerTextEnabled = true,
        powerBarPowerTextFont = 'DMSans',
        powerBarPowerTextSize = 11,
        powerBarPowerTextColor = {r = 1, g = 1, b = 1, a = 1},
        powerBarPowerTextAnchor = 'CENTER',
        powerBarPowerTextRelativePoint = 'CENTER',
        powerBarPowerTextXOff = 0,
        powerBarPowerTextYOff = 0,
        powerBarTicksColor = {r = 1, g = 1, b = 1, a = 1},
        powerBarTicksWidth = 2,
    }
end

powerBarModule.GetOptions = function(self)
    return {
        {
            label = 'Enable',
            name = 'powerBarEnabled',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('powerBarEnabled', value)
                self:CreateOrRefresh()
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarEnabled')
            end,
            width = 100,
        },
        {
            type = 'dropdown',
            name = 'powerBarPowerType',
            label = 'Power Type',
            getOptions = function()
                local options = {
                    [''] = 'Default'
                }
                for enum, value in pairs(Enum.PowerType) do
                    options[value] = self.powerTypeLabels[value] or enum
                end
                
                return options
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerType')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarPowerType', value)
                self:CreateOrRefresh()
            end,
            width = 33
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            label = 'Texture',
            name = 'powerBarTexture',
            type = 'dropdown',
            getOptions = function()
                local list = LSM:List('statusbar')
                local options = {}
                for _, texture in pairs(list) do
                    options[texture] = texture
                end
                return options
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarTexture')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarTexture', value)
                self:CreateOrRefresh()
            end,
            width = 33
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            label = 'Bar Color',
            name = 'powerBarColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('powerBarColor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarColor', value)
                self:CreateOrRefresh()
            end,
            width = 16
        },
        {
            label = 'Background Color',
            name = 'powerBarBackgroundColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('powerBarBackgroundColor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarBackgroundColor', value)
                self:CreateOrRefresh()
            end,
            width = 16
        },
        {
            type = 'title',
            label = 'Positioning & Size',
            width = 100
        },
        {
            label = 'Width',
            name = 'powerBarWidth',
            type = 'range',
            min = 1,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarWidth')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('powerBarWidth', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Height',
            name = 'powerBarHeight',
            type = 'range',
            min = 1,
            max = 300,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarHeight')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('powerBarHeight', value)
                self:CreateOrRefresh()
            end
        },
        {
            type = 'spacer',
            width = 60
        },
        {
            type = 'dropdown',
            label = 'Anchor Point',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarAnchor', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            type = 'dropdown',
            label = 'Anchored Point',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarRelativePoint')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarRelativePoint', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'X Offset',
            name = 'powerBarXOff',
            type = 'range',
            min = -1000,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('powerBarXOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Y Offset',
            name = 'powerBarYOff',
            type = 'range',
            min = -1000,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarYOff')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('powerBarYOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            type = 'spacer',
            width = 20
        },
        {
            type = 'title',
            label = 'Power Text',
            width = 100
        },
        {
            label = 'Enable',
            name = 'powerBarPowerTextEnabled',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('powerBarPowerTextEnabled', value)
                self:CreateOrRefresh()
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextEnabled')
            end,
            width = 100,
        },
        {
            label = 'Font',
            name = 'powerBarPowerTextFont',
            type = 'dropdown',
            getOptions = function()
                local fonts = LSM:List('font')
                table.sort(fonts)
                local options = {}
                for _, font in ipairs(fonts) do
                    options[font] = font
                end
                return options
            end,
            isFontDropdown = true,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextFont')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarPowerTextFont', value)
                self:CreateOrRefresh()
            end,
            width = 33
        },
        {
            label = 'Text Size',
            name = 'powerBarPowerTextSize',
            type = 'range',
            min = 1,
            max = 30,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('powerBarPowerTextSize', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Text Color',
            name = 'powerBarPowerTextColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextColor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarPowerTextColor', value)
                self:CreateOrRefresh()
            end,
            width = 100
        },
        {
            label = 'Anchor',
            name = 'powerBarPowerTextAnchor',
            type = 'dropdown',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarPowerTextAnchor', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'Anchored Point',
            name = 'powerBarPowerTextRelativePoint',
            type = 'dropdown',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextRelativePoint')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarPowerTextRelativePoint', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'X Offset',
            name = 'powerBarPowerTextXOff',
            type = 'range',
            min = -400,
            max = 400,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('powerBarPowerTextXOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Y Offset',
            name = 'powerBarPowerTextYOff',
            type = 'range',
            min = -400,
            max = 400,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarPowerTextYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('powerBarPowerTextYOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            type = 'title',
            label = 'Ticks',
            width = 100
        },
        {
            type = 'description',
            label = 'Only visible for selected power types',
            width = 100
        },
        {
            label = 'Color',
            name = 'powerBarTicksColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('powerBarTicksColor')
            end,
            onChange = function(value)
                data:SetDataByKey('powerBarTicksColor', value)
                self:CreateOrRefresh()
            end,
            width = 16
        },
        {
            label = 'Width',
            name = 'powerBarTicksWidth',
            type = 'range',
            min = 1,
            max = 10,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('powerBarTicksWidth')
            end,
            onChange = function(f, value)
                data:SetDataByKey('powerBarTicksWidth', value)
                self:CreateOrRefresh()
            end
        }
    }
end

powerBarModule.GetOrder = function(self)
    return 20
end

powerBarModule.Create = function(self)
    local powerBar = CreateFrame('Frame', nil, UIParent)
    powerBar.activeTicks = {}
    local statusBar = CreateFrame('StatusBar', nil, powerBar)
    local defaultTexture = LSM:Fetch('statusbar', 'ExalityUI Status Bar')
    local bgTexture = powerBar:CreateTexture(nil, 'BACKGROUND')
    bgTexture:SetTexture(defaultTexture)
    bgTexture:SetAllPoints()
    bgTexture:SetVertexColor(0, 0, 0, 1)
    powerBar.bgTexture = bgTexture

    statusBar:SetStatusBarTexture(defaultTexture)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(50)
    statusBar:SetPoint('TOPLEFT', 1, -1)
    statusBar:SetPoint('BOTTOMRIGHT', -1, 1)
    statusBar:SetStatusBarTexture(1, 1, 1, 1)

    powerBar.tickPool = CreateFramePool('Frame', statusBar)

    local powerText = statusBar:CreateFontString(nil, 'OVERLAY')
    powerText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    powerText:SetPoint('CENTER')
    powerText:SetWidth(0)
    powerText:SetText('0')
    statusBar.powerText = powerText

    statusBar:RegisterUnitEvent('UNIT_POWER_FREQUENT', 'player')

    statusBar.OnChange = function(self)
        if (self.powerType == '') then
            self.powerType = nil
        end
        local power = UnitPower('player', self.powerType)
        self:SetValue(power)
        self.powerText:SetText(AbbreviateNumbers(power))
        self:SetMinMaxValues(0, UnitPowerMax('player', self.powerType))
    end

    statusBar:SetScript('OnEvent', statusBar.OnChange)

    powerBar:SetPoint('CENTER')

    powerBar.statusBar = statusBar

    powerBar.SetPowerType = function(self, powerType)
        statusBar.powerType = powerType
    end
    
    powerBar.UpdateTicks = function(self)
        
        for _, tick in pairs(self.activeTicks) do
            self.tickPool:Release(tick)
        end
        self.activeTicks = {}
        
        if (not self.statusBar.powerType or not powerBarModule.usesTicks[self.statusBar.powerType]) then
            return;
        end
        
        local maxPower = UnitPowerMax('player', self.statusBar.powerType)
        for i = 1, maxPower - 1 do
            local tick = self.tickPool:Acquire()
            if (not tick.configured) then
                local bg = tick:CreateTexture(nil, 'BACKGROUND')
                bg:SetTexture(EXUI.const.textures.frame.solidBg)
                bg:SetAllPoints()
                tick.bg = bg
                
                tick.configured = true
            end

            tick:SetWidth(data:GetDataByKey('powerBarTicksWidth') or 2)
            if (data:GetDataByKey('powerBarTicksColor')) then
                local color = data:GetDataByKey('powerBarTicksColor')
                tick.bg:SetVertexColor(color.r, color.g, color.b, color.a)
            else
                tick.bg:SetVertexColor(1, 1, 1, 1)
            end
            local xOfs = i * (self.statusBar:GetWidth() / maxPower)
            tick:Show()
            tick:SetPoint('TOP', self.statusBar, 'TOPLEFT', xOfs, 0)
            tick:SetPoint('BOTTOM', self.statusBar, 'BOTTOMLEFT', xOfs, 0)
            table.insert(self.activeTicks, tick)
        end
    end

    powerBar.UpdatePowerText = function(self, font, size, r, g, b, a)
        self.statusBar.powerText:SetFont(font, size, 'OUTLINE')
        self.statusBar.powerText:SetVertexColor(r, g, b, a)
    end

    powerBar.UpdatePowerTextAnchor = function(self, point, relativePoint, xOfs, yOfs)
        self.statusBar.powerText:ClearAllPoints()
        self.statusBar.powerText:SetPoint(point, self.statusBar, relativePoint, xOfs, yOfs)
    end
    
    powerBar.ChangeColor = function(self, color)
        self.statusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    end

    editor:RegisterFrameForEditor(powerBar, 'Power Bar', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('powerBarAnchor', point)
        data:SetDataByKey('powerBarRelativePoint', relativePoint)
        data:SetDataByKey('powerBarXOff', xOfs)
        data:SetDataByKey('powerBarYOff', yOfs)
     end)
    self.powerBar = powerBar

end

powerBarModule.CreateOrRefresh = function(self)
    local isEnabled = data:GetDataByKey('powerBarEnabled')
    if (not self.powerBar and isEnabled) then self:Create() end 
    if (not isEnabled) then
        if (self.powerBar) then
            self.powerBar:Hide()
        end
        return;
    end
    self.powerBar:SetPowerType(data:GetDataByKey('powerBarPowerType'))
    self.powerBar:Show()
    self.powerBar.statusBar:SetStatusBarTexture(LSM:Fetch('statusbar', data:GetDataByKey('powerBarTexture')))

    self.powerBar:SetWidth(data:GetDataByKey('powerBarWidth'))
    self.powerBar:SetHeight(data:GetDataByKey('powerBarHeight'))
    self.powerBar:ClearAllPoints()
    self.powerBar:SetPoint(
        data:GetDataByKey('powerBarAnchor'), 
        UIParent,
        data:GetDataByKey('powerBarRelativePoint'), 
        data:GetDataByKey('powerBarXOff'), 
        data:GetDataByKey('powerBarYOff')
    )
    local bgColor = data:GetDataByKey('powerBarBackgroundColor')
    self.powerBar.bgTexture:SetVertexColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    self.powerBar:ChangeColor(data:GetDataByKey('powerBarColor'))
    self.powerBar.statusBar:OnChange()
    if (data:GetDataByKey('powerBarPowerTextEnabled')) then
        self.powerBar:UpdatePowerText(
            LSM:Fetch('font', data:GetDataByKey('powerBarPowerTextFont')),
            data:GetDataByKey('powerBarPowerTextSize'),
            data:GetDataByKey('powerBarPowerTextColor').r,
            data:GetDataByKey('powerBarPowerTextColor').g,
            data:GetDataByKey('powerBarPowerTextColor').b,
            data:GetDataByKey('powerBarPowerTextColor').a
        )
        self.powerBar:UpdatePowerTextAnchor(
            data:GetDataByKey('powerBarPowerTextAnchor'),
            data:GetDataByKey('powerBarPowerTextRelativePoint'),
            data:GetDataByKey('powerBarPowerTextXOff'),
            data:GetDataByKey('powerBarPowerTextYOff')
        )
        self.powerBar.statusBar.powerText:Show()
    else
        self.powerBar.statusBar.powerText:Hide()
    end

    self.powerBar:UpdateTicks()
end