---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIUnitFramesCore
local unitCore = EXUI:GetModule('unit-frames-core')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

----------------

---@class EXUIUnitFramesPlayer
local player = EXUI:GetModule('unit-frames-player')

player.frame = nil

player.DEFAULTS = {
    playerUFXOff = -110,
    playerUFYOff = -175,
    playerUFAnchor = 'TOPRIGHT',
    playerUFRelativePoint = 'CENTER',
    playerUFWidth = 200,
    playerUFHeight = 40,
    playerUFNameAnchor = 'LEFT',
    playerUFNameXOff = 5,
    playerUFNameYOff = 0,
    playerUFNameSize = 12,
    playerUFHPPercAnchor = 'RIGHT',
    playerUFHPPercXOff = -5,
    playerUFHPPercYOff = 4,
    playerUFHPPercSize = 10,
    playerUFHPTextAnchor = 'RIGHT',
    playerUFHPTextXOff = -5,
    playerUFHPTextYOff = -10,
    playerUFHPTextSize = 10,
}

player.Init = function(self)
    data:UpdateDefaults(self.DEFAULTS)
    self:CreateFrame()
    self:AddOptions()
end

player.CreateFrame = function(self)
    self.frame = unitCore:CreateBaseFrame(false)
    unitCore:SetupFrameForUnit(self.frame, 'player')

    self.frame:SetSize(data:GetDataByKey('playerUFWidth'), data:GetDataByKey('playerUFHeight'))
    self.frame.absorbBar:SetSize(data:GetDataByKey('playerUFWidth'), data:GetDataByKey('playerUFHeight'))

    self.frame.name:ClearAllPoints()
    self.frame.name:SetPoint(data:GetDataByKey('playerUFNameAnchor'), data:GetDataByKey('playerUFNameXOff'), data:GetDataByKey('playerUFNameYOff'))
    self.frame.hpPerc:ClearAllPoints()
    self.frame.hpPerc:SetPoint(data:GetDataByKey('playerUFHPPercAnchor'), data:GetDataByKey('playerUFHPPercXOff'), data:GetDataByKey('playerUFHPPercYOff'))
    self.frame.hpText:ClearAllPoints()
    self.frame.hpText:SetPoint(data:GetDataByKey('playerUFHPTextAnchor'), data:GetDataByKey('playerUFHPTextXOff'), data:GetDataByKey('playerUFHPTextYOff'))
    self.frame.name:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFNameSize'), 'OUTLINE')
    self.frame.hpPerc:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFHPPercSize'), 'OUTLINE')
    self.frame.hpText:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFHPTextSize'), 'OUTLINE')
    self.frame.name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFNameAnchor')))
    self.frame.hpPerc:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFHPPercAnchor')))
    self.frame.hpText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFHPTextAnchor')))

    self.frame.hp:SetStatusBarColor(0.05, 0.05, 0.05, 1)
    local _, class = UnitClass('player')
    local r, g, b = GetClassColor(class)
    self.frame:SetBackdropColor(r, g, b, 1)

    self.frame:SetPoint(
        data:GetDataByKey('playerUFAnchor'), 
        UIParent, 
        data:GetDataByKey('playerUFRelativePoint'), 
        data:GetDataByKey('playerUFXOff'), 
        data:GetDataByKey('playerUFYOff')
    )

    editor:RegisterFrameForEditor(self.frame, 'Player Frame', function(self)
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        data:SetDataByKey('playerUFAnchor', point)
        data:SetDataByKey('playerUFRelativePoint', relativePoint)
        data:SetDataByKey('playerUFXOff', xOfs)
        data:SetDataByKey('playerUFYOff', yOfs)
    end)

    unitCore:HideBlizzardFrame(PlayerFrame)
end

player.Refresh = function(self)
    self.frame:SetSize(data:GetDataByKey('playerUFWidth'), data:GetDataByKey('playerUFHeight'))
    self.frame.name:ClearAllPoints()
    self.frame.name:SetPoint(data:GetDataByKey('playerUFNameAnchor'), data:GetDataByKey('playerUFNameXOff'), data:GetDataByKey('playerUFNameYOff'))
    self.frame.hpPerc:ClearAllPoints()
    self.frame.hpPerc:SetPoint(data:GetDataByKey('playerUFHPPercAnchor'), data:GetDataByKey('playerUFHPPercXOff'), data:GetDataByKey('playerUFHPPercYOff'))
    self.frame.hpText:ClearAllPoints()
    self.frame.hpText:SetPoint(data:GetDataByKey('playerUFHPTextAnchor'), data:GetDataByKey('playerUFHPTextXOff'), data:GetDataByKey('playerUFHPTextYOff'))
    self.frame.name:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFNameSize'), 'OUTLINE')
    self.frame.hpPerc:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFHPPercSize'), 'OUTLINE')
    self.frame.hpText:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('playerUFHPTextSize'), 'OUTLINE')
    self.frame.name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFNameAnchor')))
    self.frame.hpPerc:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFHPPercAnchor')))
    self.frame.hpText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('playerUFHPTextAnchor')))
end

player.AddOptions = function(self)
    unitCore:AddOptions({
        {
            type = 'title',
            label = 'Player Frame',
            width = 100
        },
        {
            type = 'range',
            name = 'playerUFWidth',
            label = 'Width',
            min = 100,
            max = 400,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFWidth')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFWidth', value)
                self.frame:SetWidth(value)
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHeight',
            label = 'Height',
            min = 10,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHeight')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHeight', value)
                self.frame:SetHeight(value)
            end,
            width = 16
        },
        {
            type = 'title',
            label = 'Name',
            size = 12,
            width = 100
        },
        {
            type = 'dropdown',
            name = 'playerUFNameAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('playerUFNameAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('playerUFNameAnchor', value)
                self:Refresh()
            end,
            width = 16  
        },
        {
            type = 'range',
            name = 'playerUFNameSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFNameSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFNameSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFNameXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFNameXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFNameXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFNameYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFNameYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFNameYOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'title',
            label = 'HP %',
            size = 12,
            width = 100
        },
        {
            type = 'dropdown',
            name = 'playerUFHPPercAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('playerUFHPPercAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('playerUFHPPercAnchor', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPPercSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPPercSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPPercSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPPercXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPPercXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPPercXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPPercYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPPercYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPPercYOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'title',
            label = 'HP Amount',
            size = 12,
            width = 100
        },
        {
            type = 'dropdown',
            name = 'playerUFHPTextAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('playerUFHPTextAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('playerUFHPTextAnchor', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPTextSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPTextSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPTextSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPTextXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPTextXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPTextXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'playerUFHPTextYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('playerUFHPTextYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('playerUFHPTextYOff', value)
                self:Refresh()
            end,
            width = 16
        },
    })
end