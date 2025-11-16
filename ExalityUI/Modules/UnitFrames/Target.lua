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

---@class EXUIUnitFramesTarget
local target = EXUI:GetModule('unit-frames-target')

target.frame = nil

target.DEFAULTS = {
    targetUFXOff = 110,
    targetUFYOff = -175,
    targetUFAnchor = 'TOPLEFT',
    targetUFRelativePoint = 'CENTER',
    targetUFWidth = 200,
    targetUFHeight = 40,
    targetUFNameAnchor = 'RIGHT',
    targetUFNameXOff = -5,
    targetUFNameYOff = 0,
    targetUFNameSize = 12,
    targetUFHPPercAnchor = 'LEFT',
    targetUFHPPercXOff = 5,
    targetUFHPPercYOff = 4,
    targetUFHPPercSize = 10,
    targetUFHPTextAnchor = 'LEFT',
    targetUFHPTextXOff = 5,
    targetUFHPTextYOff = -10,
    targetUFHPTextSize = 10,
}

target.Init = function(self)
    data:UpdateDefaults(self.DEFAULTS)
    self:CreateFrame()
    self:AddOptions()
end

target.CreateFrame = function(self)
    self.frame = unitCore:CreateBaseFrame(true)
    unitCore:SetupFrameForUnit(self.frame, 'target')

    self.frame:SetSize(data:GetDataByKey('targetUFWidth'), data:GetDataByKey('targetUFHeight'))
    self.frame.absorbBar:SetSize(data:GetDataByKey('targetUFWidth'), data:GetDataByKey('targetUFHeight'))


    self.frame.name:ClearAllPoints()
    print(data:GetDataByKey('targetUFNameAnchor'), data:GetDataByKey('targetUFNameXOff'), data:GetDataByKey('targetUFNameYOff'))
    self.frame.name:SetPoint(data:GetDataByKey('targetUFNameAnchor'), data:GetDataByKey('targetUFNameXOff'), data:GetDataByKey('targetUFNameYOff'))
    self.frame.hpPerc:ClearAllPoints()
    self.frame.hpPerc:SetPoint(data:GetDataByKey('targetUFHPPercAnchor'), data:GetDataByKey('targetUFHPPercXOff'), data:GetDataByKey('targetUFHPPercYOff'))
    self.frame.hpText:ClearAllPoints()
    self.frame.hpText:SetPoint(data:GetDataByKey('targetUFHPTextAnchor'), data:GetDataByKey('targetUFHPTextXOff'), data:GetDataByKey('targetUFHPTextYOff'))
    self.frame.name:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFNameSize'), 'OUTLINE')
    self.frame.hpPerc:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFHPPercSize'), 'OUTLINE')
    self.frame.hpText:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFHPTextSize'), 'OUTLINE')
    self.frame.name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFNameAnchor')))
    self.frame.hpPerc:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFHPPercAnchor')))
    self.frame.hpText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFHPTextAnchor')))

    
    self.frame.hp:SetStatusBarColor(0.1, 0.1, 0.1, 1)
    self.frame:RegisterEvent('PLAYER_TARGET_CHANGED')
    self.frame.onUpdate = function(self, event, ...)
        if (event == 'PLAYER_TARGET_CHANGED') then
            self.name:SetText(UnitName('target'))
            self.hp:SetMinMaxValues(0, UnitHealthMax('target'))
            self.hp:SetValue(UnitHealth('target'))
            self.hpText:SetText(AbbreviateNumbers(UnitHealth('target')))
            self.hpPerc:SetText(string.format('%d%%', UnitHealthPercent('target', true, true)))
            if (UnitIsPlayer('target')) then
                local _, class = UnitClass('target')
                local r, g, b = GetClassColor(class)
                self:SetBackdropColor(r, g, b, 1)
            else
                self:SetBackdropColor(204/255, 0, 37/255, 1)
            end
            local powerType = UnitPowerType('target')
            self.power:SetStatusBarColor(EXUI.utils.getPowerTypeColor(powerType))
        end
    end

    self.frame:SetPoint(
        data:GetDataByKey('targetUFAnchor'), 
        UIParent, 
        data:GetDataByKey('targetUFRelativePoint'), 
        data:GetDataByKey('targetUFXOff'), 
        data:GetDataByKey('targetUFYOff')
    )

    unitCore:HideBlizzardFrame(TargetFrame)

    editor:RegisterFrameForEditor(self.frame, 'Target Frame', function(self)
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint(1)
        data:SetDataByKey('targetUFAnchor', point)
        data:SetDataByKey('targetUFRelativePoint', relativePoint)
        data:SetDataByKey('targetUFXOff', xOfs)
        data:SetDataByKey('targetUFYOff', yOfs)
    end)
end

target.AddOptions = function(self)
    unitCore:AddOptions({
        {
            type = 'title',
            label = 'Target Frame',
            width = 100
        },
        {
            type = 'range',
            name = 'targetUFWidth',
            label = 'Width',
            min = 100,
            max = 400,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFWidth')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFWidth', value)
                self.frame:SetWidth(value)
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHeight',
            label = 'Height',
            min = 10,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHeight')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHeight', value)
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
            name = 'targetUFNameAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('targetUFNameAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('targetUFNameAnchor', value)
                self:Refresh()
            end,
            width = 16  
        },
        {
            type = 'range',
            name = 'targetUFNameSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFNameSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFNameSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFNameXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFNameXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFNameXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFNameYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFNameYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFNameYOff', value)
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
            name = 'targetUFHPPercAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('targetUFHPPercAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('targetUFHPPercAnchor', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPPercSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPPercSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPPercSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPPercXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPPercXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPPercXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPPercYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPPercYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPPercYOff', value)
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
            name = 'targetUFHPTextAnchor',
            label = 'Anchor',
            getOptions = function()
                return EXUI.const.anchorPoints
            end,
            currentValue = function()
                return data:GetDataByKey('targetUFHPTextAnchor')
            end,
            onChange = function(value)
                data:SetDataByKey('targetUFHPTextAnchor', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPTextSize',
            label = 'Size',
            min = 6,
            max = 24,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPTextSize')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPTextSize', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPTextXOff',
            label = 'X Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPTextXOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPTextXOff', value)
                self:Refresh()
            end,
            width = 16
        },
        {
            type = 'range',
            name = 'targetUFHPTextYOff',
            label = 'Y Offset',
            min = -100,
            max = 100,
            step = 1,
            currentValue = function()
                return data:GetDataByKey('targetUFHPTextYOff')
            end,
            onChange = function(f, value)
                data:SetDataByKey('targetUFHPTextYOff', value)
                self:Refresh()
            end,
            width = 16
        },
    })
end

target.Refresh = function(self)
    self.frame:SetSize(data:GetDataByKey('targetUFWidth'), data:GetDataByKey('targetUFHeight'))
    self.frame.name:ClearAllPoints()
    self.frame.name:SetPoint(data:GetDataByKey('targetUFNameAnchor'), data:GetDataByKey('targetUFNameXOff'), data:GetDataByKey('targetUFNameYOff'))
    self.frame.name:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFNameAnchor')))
    self.frame.hpPerc:ClearAllPoints()
    self.frame.hpPerc:SetPoint(data:GetDataByKey('targetUFHPPercAnchor'), data:GetDataByKey('targetUFHPPercXOff'), data:GetDataByKey('targetUFHPPercYOff'))
    self.frame.hpPerc:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFHPPercAnchor')))
    self.frame.hpText:ClearAllPoints()
    self.frame.hpText:SetPoint(data:GetDataByKey('targetUFHPTextAnchor'), data:GetDataByKey('targetUFHPTextXOff'), data:GetDataByKey('targetUFHPTextYOff'))
    self.frame.hpText:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(data:GetDataByKey('targetUFHPTextAnchor')))
    self.frame.name:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFNameSize'), 'OUTLINE')
    self.frame.hpPerc:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFHPPercSize'), 'OUTLINE')
    self.frame.hpText:SetFont(EXUI.const.fonts.DEFAULT, data:GetDataByKey('targetUFHPTextSize'), 'OUTLINE')
end