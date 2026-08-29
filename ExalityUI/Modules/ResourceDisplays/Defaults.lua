---@class ExalityUI

local EXUI = select(2, ...)



---@class EXUIResourceDisplaysDefaults

local defaults = EXUI:GetModule('resource-displays-defaults')



defaults.SCHEMA_VERSION = 3



function defaults:GetResourceColorCurveTemplate()

    return {

        self:CopyTable(self:CreateResourceColorCurvePoint(0)),

    }

end



function defaults:CreateResourceColorCurvePoint(percent)

    return {

        percent = percent or 0,

        color = { r = 1, g = 0.2, b = 0.2, a = 1 },

    }

end



function defaults:SanitizeResourceColorCurve(curve, display)

    if type(curve) ~= 'table' then

        return {}

    end

    local barColor = display and display.barColor or { r = 1, g = 1, b = 1, a = 1 }

    local cleaned = {}

    for _, point in ipairs(curve) do

        if type(point) ~= 'table' or point.percent == nil or point.enabled == false then

        elseif point.useBarColor then

            table.insert(cleaned, {

                percent = point.percent,

                color = self:CopyTable(point.color or barColor),

            })

        elseif point.color then

            table.insert(cleaned, {

                percent = point.percent,

                color = self:CopyTable(point.color),

            })

        end

    end

    table.sort(cleaned, function(a, b)

        return a.percent < b.percent

    end)

    for index = 2, #cleaned do

        local min = cleaned[index - 1].percent + 1

        if cleaned[index].percent < min then

            cleaned[index].percent = math.min(100, min)

        end

    end

    return cleaned

end



defaults.DISPLAY = {

    enable = true,

    name = 'New Display',

    width = 200,

    height = 20,

    anchorPoint = 'CENTER',

    relativeAnchorPoint = 'CENTER',

    XOff = 0,

    YOff = 0,

    showOverride = false,

    hasLoadConditions = false,

    onlyLoadOnPlayer = '',

    dontLoadOnPlayer = '',

    scale = 1,

    frameStrata = 'MEDIUM',

    frameLevel = 100,

    visibilityRule = 'always',

    fadeOnHide = false,

    textFormat = 'current',

    textJustify = 'CENTER',

    smoothFill = true,

    reverseFill = false,

    resourceColorCurveEnabled = false,

    resourceColorCurve = nil,

    useClassColor = false,

    segmentLayout = 'horizontal',

    segmentReverse = false,

    individualSegmentColors = false,

}



defaults.LOAD = {

    loadClasses = {},

    loadSpecs = {},

}



defaults.TYPE_SPECIFIC_KEYS = {

    'hpWidth', 'hpHeight', 'hpSpacing', 'hpColor', 'hpColors', 'hpBackgroundColor', 'hpBorderColor', 'hpBarTexture',

    'hpCapColor', 'comboPointsWidth', 'comboPointsHeight', 'comboPointsSpacing', 'comboPointsColor', 'comboPointsColors',

    'comboPointsBackgroundColor', 'comboPointsBorderColor', 'comboPointsBarTexture', 'chargedColor', 'catFormOnly',

    'chiWidth', 'chiHeight', 'chiSpacing', 'chiColor', 'chiColors', 'chiBackgroundColor', 'chiBorderColor', 'chiBarTexture',

    'runeWidth', 'runeHeight', 'runeSpacing', 'runeColor', 'runeOnCDColor', 'runeBackgroundColor', 'runeBorderColor',

    'runeBarTexture', 'runeShowText', 'runeFont', 'runeFontSize', 'runeFontFlag', 'runeTextAnchorPoint',

    'runeTextRelativeAnchorPoint', 'runeTextXOff', 'runeTextYOff', 'runeTextColor', 'runeReadyGlow', 'runeCDTextFormat',

    'runeCDTextThreshold', 'ssWidth', 'ssHeight', 'ssSpacing', 'ssColor', 'ssPartialColor', 'ssColors', 'ssBackgroundColor',

    'ssBorderColor', 'ssBarTexture', 'ssShardTextFormat', 'essenceWidth', 'essenceHeight', 'essenceSpacing', 'essenceColor',

    'essenceColors', 'essenceOnCDColor', 'essenceBackgroundColor', 'essenceBorderColor', 'essenceBarTexture', 'essenceShowText',

    'essenceFont', 'essenceFontSize', 'essenceFontFlag', 'essenceTextAnchorPoint', 'essenceTextRelativeAnchorPoint',

    'essenceTextXOff', 'essenceTextYOff', 'essenceTextColor', 'fillAnimation', 'barTexture', 'barColor', 'font', 'fontSize',

    'fontFlag', 'textAnchorPoint', 'textRelativeAnchorPoint', 'textXOff', 'textYOff', 'textColor', 'showText',

    'lightStaggerColor', 'moderateStaggerColor', 'heavyStaggerColor', 'hideWhenZero', 'staggerShowPercent',

    'staggerLightThreshold', 'staggerHeavyThreshold', 'capHighlightColor', 'stackThreshold', 'stackThresholdColor',

    'druidFormAdaptive', 'totemSpellID', 'totemSlot',

}



function defaults:CopyTable(source)

    return EXUI.utils.deepCloneTable(source)

end



function defaults:IsMetadataKey(key)

    return type(key) == 'string' and key:sub(1, 2) == '__'

end



function defaults:MergeDisplayDefaults(display)

    if type(display) ~= 'table' then

        return

    end

    for key, value in pairs(self.DISPLAY) do

        if display[key] == nil then

            display[key] = self:CopyTable(value)

        end

    end

    for key, value in pairs(self.LOAD) do

        if display[key] == nil then

            display[key] = self:CopyTable(value)

        end

    end

end



function defaults:EnsureResourceColorCurve(curve, display)

    curve = self:SanitizeResourceColorCurve(curve, display)

    if #curve == 0 then

        return self:GetResourceColorCurveTemplate()

    end

    return curve

end



function defaults:MigrateV2ToV3(db)

    for displayID, display in pairs(db) do

        if not self:IsMetadataKey(displayID) and type(display) == 'table' then

            if display.lowResourceThresholdEnabled then

                display.resourceColorCurveEnabled = true

                display.resourceColorCurve = {

                    self:CopyTable(self:CreateResourceColorCurvePoint(0)),

                }

                display.resourceColorCurve[1].color = self:CopyTable(display.lowResourceColor or { r = 1, g = 0.2, b = 0.2, a = 1 })

                local threshold = display.lowResourceThreshold or 20

                if display.lowResourceThresholdIsPercent ~= false and threshold > 0 and threshold < 100 then

                    table.insert(display.resourceColorCurve, self:CopyTable(self:CreateResourceColorCurvePoint(threshold)))

                    display.resourceColorCurve[2].color = self:CopyTable(display.barColor or { r = 1, g = 1, b = 1, a = 1 })

                end

            end

            if not display.resourceColorCurve then

                display.resourceColorCurve = self:GetResourceColorCurveTemplate()

            else

                display.resourceColorCurve = self:EnsureResourceColorCurve(display.resourceColorCurve, display)

            end

        end

    end

end



function defaults:MigrateV1ToV2(db)

    for displayID, display in pairs(db) do

        if not self:IsMetadataKey(displayID) and type(display) == 'table' then

            if display.hpWidth and not display.runeWidth then

                -- runeWidth already correct in newer saves; legacy hpWidth on runes handled in Runes.lua defaults

            end

        end

    end

end



function defaults:MergeIntoDB(db)

    if not db then

        return

    end

    if (db.__exuiDefaultsVersion or 0) < 2 then

        self:MigrateV1ToV2(db)

    end

    if (db.__exuiDefaultsVersion or 0) < 3 then

        self:MigrateV2ToV3(db)

    end

    for displayID, display in pairs(db) do

        if not self:IsMetadataKey(displayID) then

            self:MergeDisplayDefaults(display)

            if not display.resourceColorCurve then

                display.resourceColorCurve = self:GetResourceColorCurveTemplate()

            else

                display.resourceColorCurve = self:EnsureResourceColorCurve(display.resourceColorCurve, display)

            end

        end

    end

    db.__exuiDefaultsVersion = self.SCHEMA_VERSION

end



function defaults:GetPrimaryResourceForPlayer()

    local helpers = EXUI:GetModule('resource-displays-helpers')

    return helpers:GetPrimaryResourceTypeName()

end



function defaults:BuildNewDisplay(resourceType)

    local display = self:CopyTable(self.DISPLAY)

    for key, value in pairs(self.LOAD) do

        display[key] = self:CopyTable(value)

    end

    display.ID = EXUI.utils.generateRandomString(10)

    display.createdAt = time()

    display.resourceType = resourceType or self:GetPrimaryResourceForPlayer() or 'Energy'

    display.name = display.resourceType .. ' Display'

    display.resourceColorCurve = self:GetResourceColorCurveTemplate()

    return display

end



function defaults:GetDisplayDefaults()

    local merged = self:CopyTable(self.DISPLAY)

    for key, value in pairs(self.LOAD) do

        merged[key] = self:CopyTable(value)

    end

    return merged

end



function defaults:ClearTypeSpecificKeys(display)

    if type(display) ~= 'table' then

        return

    end

    for _, key in ipairs(self.TYPE_SPECIFIC_KEYS) do

        display[key] = nil

    end

end


