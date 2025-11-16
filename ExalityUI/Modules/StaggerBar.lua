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

---@class EXUIStaggerBarModule
local staggerBarModule = EXUI:GetModule('stagger-bar-module')

staggerBarModule.staggerBar = nil

staggerBarModule.Init = function(self)
    optionsController:RegisterModule(self)
    data:UpdateDefaults(self:GetDefaults())
    self:CreateOrRefresh()
end

staggerBarModule.GetName = function(self)
    return 'Stagger Bar'
end

staggerBarModule.GetDefaults = function(self)
    return {
        staggerBarEnabled = false,
        staggerBarTexture = 'ExalityUI Status Bar',
        staggerBarWidth = 200,
        staggerBarHeight = 20,
        staggerBarXOff = 0,
        staggerBarYOff = 0,
        staggerBarAnchor = 'CENTER',
        staggerBarRelativePoint = 'CENTER',
        staggerBarBackgroundColor = {r = 0, g = 0, b = 0, a = 1},
        staggerBarColor = {r = 1, g = 1, b = 1, a = 1},
        staggerBarPowerTextEnabled = true,
        staggerBarPowerTextFont = 'DMSans',
        staggerBarPowerTextSize = 11,
        staggerBarPowerTextColor = {r = 1, g = 1, b = 1, a = 1},
        staggerBarPowerTextAnchor = 'CENTER',
        staggerBarPowerTextRelativePoint = 'CENTER',
        staggerBarPowerTextXOff = 0,
        staggerBarPowerTextYOff = 0,
        staggerBarBorderColor = {r = 0, g = 0, b = 0, a = 1},
    }
end

staggerBarModule.GetOptions = function(self)
    return {
        {
            label = 'Enable',
            name = 'staggerBarEnabled',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('staggerBarEnabled', value)
                self:CreateOrRefresh()
            end,
            currentValue = function()
                return data:GetDataByKey('staggerBarEnabled')
            end,
            width = 100,
        },
        {
            label = 'Texture',
            name = 'staggerBarTexture',
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
                return data:GetDataByKey('staggerBarTexture')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarTexture', value)
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
            name = 'staggerBarColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('staggerBarColor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarColor', value)
                self:CreateOrRefresh()
            end,
            width = 16
        },
        {
            label = 'Background Color',
            name = 'staggerBarBackgroundColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('staggerBarBackgroundColor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarBackgroundColor', value)
                self:CreateOrRefresh()
            end,
            width = 16
        },
        {
            label = 'Border Color',
            name = 'staggerBarBorderColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('staggerBarBorderColor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarBorderColor', value)
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
            name = 'staggerBarWidth',
            type = 'range',
            min = 1,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarWidth')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('staggerBarWidth', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Height',
            name = 'staggerBarHeight',
            type = 'range',
            min = 1,
            max = 300,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarHeight')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('staggerBarHeight', value)
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
                return data:GetDataByKey('staggerBarAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarAnchor', value)
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
                return data:GetDataByKey('staggerBarRelativePoint')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarRelativePoint', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'X Offset',
            name = 'staggerBarXOff',
            type = 'range',
            min = -1000,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('staggerBarXOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Y Offset',
            name = 'staggerBarYOff',
            type = 'range',
            min = -1000,
            max = 1000,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarYOff')
            end,
            onChange = function(f, value)
                -- Reload UI
                data:SetDataByKey('staggerBarYOff', value)
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
            name = 'staggerBarPowerTextEnabled',
            type = 'toggle',
            onObserve = function(value, oldValue)
                data:SetDataByKey('staggerBarPowerTextEnabled', value)
                self:CreateOrRefresh()
            end,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextEnabled')
            end,
            width = 100,
        },
        {
            label = 'Font',
            name = 'staggerBarPowerTextFont',
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
                return data:GetDataByKey('staggerBarPowerTextFont')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarPowerTextFont', value)
                self:CreateOrRefresh()
            end,
            width = 33
        },
        {
            label = 'Text Size',
            name = 'staggerBarPowerTextSize',
            type = 'range',
            min = 1,
            max = 30,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('staggerBarPowerTextSize', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Text Color',
            name = 'staggerBarPowerTextColor',
            type = 'color-picker',
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextColor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarPowerTextColor', value)
                self:CreateOrRefresh()
            end,
            width = 100
        },
        {
            label = 'Anchor',
            name = 'staggerBarPowerTextAnchor',
            type = 'dropdown',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarPowerTextAnchor', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'Anchored Point',
            name = 'staggerBarPowerTextRelativePoint',
            type = 'dropdown',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextRelativePoint')
            end,
            onChange = function(value)
                data:SetDataByKey('staggerBarPowerTextRelativePoint', value)
                self:CreateOrRefresh()
            end,
            width = 20
        },
        {
            label = 'X Offset',
            name = 'staggerBarPowerTextXOff',
            type = 'range',
            min = -400,
            max = 400,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('staggerBarPowerTextXOff', value)
                self:CreateOrRefresh()
            end
        },
        {
            label = 'Y Offset',
            name = 'staggerBarPowerTextYOff',
            type = 'range',
            min = -400,
            max = 400,
            step = 1,
            width = 16,
            currentValue = function()
                return data:GetDataByKey('staggerBarPowerTextYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('staggerBarPowerTextYOff', value)
                self:CreateOrRefresh()
            end
        },
    }
end

staggerBarModule.GetOrder = function(self)
    return 40
end

staggerBarModule.Create = function(self)
    local staggerBar = CreateFrame('Frame', nil, UIParent, 'BackdropTemplate')
    staggerBar.activeTicks = {}
    local statusBar = CreateFrame('StatusBar', nil, staggerBar, 'BackdropTemplate')
    local defaultTexture = LSM:Fetch('statusbar', 'ExalityUI Status Bar')
    staggerBar:SetBackdrop(
        {
            bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 } 
        }
    )
    staggerBar:SetBackdropBorderColor(0, 0, 0, 1)
    staggerBar:SetBackdropColor(0, 0, 0, 1)

    statusBar:SetStatusBarTexture(defaultTexture)
    statusBar:SetMinMaxValues(0, 100)
    statusBar:SetValue(0)
    statusBar:SetPoint('TOPLEFT', 1, -1)
    statusBar:SetPoint('BOTTOMRIGHT', -1, 1)
    statusBar:SetStatusBarTexture(1, 1, 1, 1)

    staggerBar.tickPool = CreateFramePool('Frame', statusBar)

    local staggerText = statusBar:CreateFontString(nil, 'OVERLAY')
    staggerText:SetFont(EXUI.const.fonts.DEFAULT, 11, 'OUTLINE')
    staggerText:SetPoint('CENTER')
    staggerText:SetWidth(0)
    staggerText:SetText('0')
    statusBar.staggerText = staggerText

    statusBar:RegisterUnitEvent('UNIT_ABSORB_AMOUNT_CHANGED', 'player')

    statusBar.OnChange = function(self, event)
        if (event == 'UNIT_ABSORB_AMOUNT_CHANGED') then
            local stagger = UnitStagger('player')
            self:SetValue(stagger)
            self.staggerText:SetText(AbbreviateNumbers(stagger))
            self:SetMinMaxValues(0, UnitHealthMax('player') * 3)
        end
    end

    statusBar:SetScript('OnEvent', statusBar.OnChange)

    staggerBar:SetPoint('CENTER')

    staggerBar.statusBar = statusBar

    staggerBar.UpdateStaggerText = function(self, font, size, r, g, b, a)
        self.statusBar.staggerText:SetFont(font, size, 'OUTLINE')
        self.statusBar.staggerText:SetVertexColor(r, g, b, a)
    end

    staggerBar.UpdateStaggerTextAnchor = function(self, point, relativePoint, xOfs, yOfs)
        self.statusBar.staggerText:ClearAllPoints()
        self.statusBar.staggerText:SetPoint(point, self.statusBar, relativePoint, xOfs, yOfs)
    end
    
    staggerBar.ChangeColor = function(self, color)
        self.statusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
    end

    editor:RegisterFrameForEditor(staggerBar, 'Stagger Bar', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        data:SetDataByKey('staggerBarAnchor', point)
        data:SetDataByKey('staggerBarRelativePoint', relativePoint)
        data:SetDataByKey('staggerBarXOff', xOfs)
        data:SetDataByKey('staggerBarYOff', yOfs)
     end)
    self.staggerBar = staggerBar

end

staggerBarModule.CreateOrRefresh = function(self)
    local isEnabled = data:GetDataByKey('staggerBarEnabled')
    if (not self.staggerBar and isEnabled) then self:Create() end 
    if (not isEnabled) then
        if (self.staggerBar) then
            self.staggerBar:Hide()
        end
        return;
    end
    self.staggerBar:Show()
    self.staggerBar.statusBar:SetStatusBarTexture(LSM:Fetch('statusbar', data:GetDataByKey('staggerBarTexture')))

    self.staggerBar:SetWidth(data:GetDataByKey('staggerBarWidth'))
    self.staggerBar:SetHeight(data:GetDataByKey('staggerBarHeight'))
    self.staggerBar:ClearAllPoints()
    self.staggerBar:SetPoint(
        data:GetDataByKey('staggerBarAnchor'), 
        UIParent,
        data:GetDataByKey('staggerBarRelativePoint'), 
        data:GetDataByKey('staggerBarXOff'), 
        data:GetDataByKey('staggerBarYOff')
    )
    local bgColor = data:GetDataByKey('staggerBarBackgroundColor')
    self.staggerBar:SetBackdropColor(bgColor.r, bgColor.g, bgColor.b, bgColor.a)
    local borderColor = data:GetDataByKey('staggerBarBorderColor')
    self.staggerBar:SetBackdropBorderColor(borderColor.r, borderColor.g, borderColor.b, borderColor.a)
    self.staggerBar:ChangeColor(data:GetDataByKey('staggerBarColor'))
    self.staggerBar.statusBar:OnChange()
    if (data:GetDataByKey('staggerBarPowerTextEnabled')) then
        self.staggerBar:UpdateStaggerText(
            LSM:Fetch('font', data:GetDataByKey('staggerBarPowerTextFont')),
            data:GetDataByKey('staggerBarPowerTextSize'),
            data:GetDataByKey('staggerBarPowerTextColor').r,
            data:GetDataByKey('staggerBarPowerTextColor').g,
            data:GetDataByKey('staggerBarPowerTextColor').b,
            data:GetDataByKey('staggerBarPowerTextColor').a
        )
        self.staggerBar:UpdateStaggerTextAnchor(
            data:GetDataByKey('staggerBarPowerTextAnchor'),
            data:GetDataByKey('staggerBarPowerTextRelativePoint'),
            data:GetDataByKey('staggerBarPowerTextXOff'),
            data:GetDataByKey('staggerBarPowerTextYOff')
        )
        self.staggerBar.statusBar.staggerText:Show()
    else
        self.staggerBar.statusBar.staggerText:Hide()
    end
end