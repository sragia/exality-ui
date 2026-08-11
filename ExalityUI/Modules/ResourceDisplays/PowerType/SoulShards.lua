---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

---@class EXUIResourceDisplaysSegmentBase
local segmentBase = EXUI:GetModule('resource-displays-segment-base')

local soulShards = EXUI:GetModule('resource-displays-soul-shards')
local RDCore = EXUI:GetModule('resource-displays-core')
local textElement = EXUI:GetModule('resource-displays-elements-text')

local SEGMENT_CONFIG = {
    prefix = 'ss',
    label = 'Soul Shards',
    poolKey = 'SoulShardsFrames',
    widthKey = 'ssWidth',
    heightKey = 'ssHeight',
    spacingKey = 'ssSpacing',
    textureKey = 'ssBarTexture',
    colorKey = 'ssColor',
    colorsKey = 'ssColors',
    backgroundKey = 'ssBackgroundColor',
    borderKey = 'ssBorderColor',
    partialColorKey = 'ssPartialColor',
    individualColorCount = 5,
}

local function applySoulShardValues(frame, ssCount)
    local db = frame.db
    local interpolation = helpers:GetInterpolation(db.fillAnimation or db.smoothFill)
    local ssFullCount = math.floor(ssCount / 10)
    local ssRemainingCount = ssCount % 10

    for _, segment in ipairs(frame.ActiveFrames) do
        local value = 0
        if segment.index <= ssFullCount then
            value = 10
        elseif segment.index - 1 == ssFullCount then
            value = ssRemainingCount
        end

        local color = helpers:GetSegmentColor(db, segment.index, 'ssColor', 'ssColors', nil, false)
        if value > 0 and value < 10 then
            if not (db.individualSegmentColors and db.ssColors and db.ssColors[segment.index]) then
                color = db.ssPartialColor or color
            end
        end

        segment.StatusBar:SetMinMaxValues(0, 10)
        if segment.StatusBar:GetValue() ~= value then
            segment.StatusBar:SetValue(value, interpolation)
        end
        if color then
            segment.StatusBar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        end
    end

    if db.showText and frame.Text then
        frame.Text:SetText(helpers:FormatShardText(db.ssShardTextFormat, ssCount))
        frame.Text:Show()
    elseif frame.Text then
        frame.Text:Hide()
    end
end

local function applySoulShardPreview(frame)
    if not preview:ShouldUsePreview(frame) then
        return false
    end
    local ssCount = preview:GetMockValue('Soul Shards')
    local maxShards = preview:GetMockMax('Soul Shards') / 10

    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return maxShards
    end, Enum.PowerType.SoulShards, function(f)
        for _, segment in ipairs(f.ActiveFrames) do
            segment.StatusBar:SetMinMaxValues(0, 10)
        end
        applySoulShardValues(f, ssCount)
    end)

    if frame.db.showText and frame.Text then
        textElement:Update(frame)
    end
    return true
end

soulShards.Create = function(self, frame)
    frame.IsActive = function(self) return soulShards:IsActive(self) end
    frame.SoulShardsFrames = {}
    frame.ActiveFrames = {}
    frame.Text = textElement:Create(frame)

    frame._segmentOnEvent = function(self, event, unit, powerType)
        if applySoulShardPreview(self) then
            return
        end
        if (unit == 'player' and powerType == 'SOUL_SHARDS') or event == 'TRAIT_CONFIG_UPDATED' then
            local maxSoulShards = UnitPowerMax('player', Enum.PowerType.SoulShards, true)
            if maxSoulShards / 10 ~= #self.ActiveFrames then
                self:Update()
                return
            end
            applySoulShardValues(self, UnitPower('player', Enum.PowerType.SoulShards, true))
        end
    end

    frame.OnEvent = frame._segmentOnEvent
    helpers:WireSegmentEnableDisable(frame, { 'UNIT_POWER_UPDATE', 'TRAIT_CONFIG_UPDATED', 'PLAYER_ENTERING_WORLD' })
    frame:SetScript('OnEvent', function(self, event, unit, powerType)
        self:OnEvent(event, unit, powerType)
    end)
end

soulShards.Update = function(frame)
    local db = frame.db
    if applySoulShardPreview(frame) then
        return
    end

    segmentBase:UpdateSegmentRow(frame, SEGMENT_CONFIG, function()
        return UnitPowerMax('player', Enum.PowerType.SoulShards, true) / 10
    end, Enum.PowerType.SoulShards, function(f)
        for _, segment in ipairs(f.ActiveFrames) do
            segment.StatusBar:SetMinMaxValues(0, 10)
        end
        applySoulShardValues(f, UnitPower('player', Enum.PowerType.SoulShards, true))
    end)

    if db.showText and frame.Text then
        textElement:Update(frame)
    elseif frame.Text then
        frame.Text:Hide()
    end
end

soulShards.IsActive = function(self, frame)
    local db = frame.db
    return db.enable and UnitPowerMax('player', Enum.PowerType.SoulShards, true) > 0
end

soulShards.GetOptions = function(self, displayID)
    local options = segmentBase:GetCommonOptions(displayID, SEGMENT_CONFIG, RDCore)
    table.insert(options, {
        type = 'dropdown',
        label = 'Shard Text Format',
        name = 'ssShardTextFormat',
        getOptions = function()
            return {
                decimal = 'Decimal (2.5)',
                tenths = 'Tenths (2)',
            }
        end,
        depends = function()
            return RDCore:GetValueForDisplay(displayID, 'showText')
        end,
        currentValue = function()
            return RDCore:GetValueForDisplay(displayID, 'ssShardTextFormat') or 'decimal'
        end,
        onChange = function(value)
            RDCore:UpdateValueForDisplay(displayID, 'ssShardTextFormat', value)
            RDCore:RefreshDisplayByID(displayID)
        end,
        width = 25,
    })
    tAppendAll(options, textElement:GetOptions(displayID))
    return options
end

soulShards.UpdateDefault = function(self, displayID)
    core:UpdateDefaultValuesForDisplay(displayID, {
        ssWidth = 30,
        ssHeight = 16,
        ssSpacing = -1,
        ssColor = { r = 140 / 255, g = 3 / 255, b = 252 / 255, a = 1 },
        ssPartialColor = { r = 83 / 255, g = 0, b = 150 / 255, a = 1 },
        ssBackgroundColor = { r = 0, g = 0, b = 0, a = 0.5 },
        ssBorderColor = { r = 0, g = 0, b = 0, a = 1 },
        fillAnimation = false,
        textAnchorPoint = 'CENTER',
        textRelativeAnchorPoint = 'CENTER',
        textXOff = 0,
        textYOff = 0,
        textColor = { r = 1, g = 1, b = 1, a = 1 },
        showText = false,
        ssShardTextFormat = 'decimal',
        font = 'DMSans',
        fontSize = 12,
        fontFlag = 'OUTLINE',
        ssBarTexture = 'ExalityUI Status Bar',
    })
end

core:RegisterPowerType({
    name = 'Soul Shards',
    control = soulShards,
    selfControlledSize = true,
})
