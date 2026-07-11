---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIResourceDisplaysHelpers
local helpers = EXUI:GetModule('resource-displays-helpers')

helpers.TEXT_FORMATS = {
    current = 'current',
    ['current/max'] = 'current/max',
}

helpers.VISIBILITY_RULES = {
    always = 'always',
    inCombat = 'inCombat',
    withTarget = 'withTarget',
    combatOrTarget = 'combatOrTarget',
    hidden = 'hidden',
}

helpers.SEGMENT_LAYOUTS = {
    horizontal = 'horizontal',
    vertical = 'vertical',
}

function helpers:FormatPowerText(format, current, max)
    format = format or 'current'
    max = max or 0
    current = current or 0

    if format == 'current/max' then
        return string.format('%s/%s', AbbreviateNumbers(current), AbbreviateNumbers(max))
    end
    return AbbreviateNumbers(current)
end

function helpers:FormatShardText(format, tenths)
    tenths = tenths or 0
    if format == 'decimal' then
        return string.format('%.1f', tenths / 10)
    end
    return tostring(tenths / 10)
end

function helpers:FormatCooldownText(format, remaining, threshold)
    remaining = remaining or 0
    if threshold and remaining > threshold then
        return ''
    end
    format = format or 'decimal'
    if format == 'seconds' or format == 'ceil' then
        return tostring(math.ceil(remaining))
    elseif format == 'integer' then
        return tostring(math.floor(remaining + 0.5))
    end
    return string.format('%.1f', remaining)
end

function helpers:ApplyStackBarColor(bar, db, current, max)
    if not bar or not db then
        return false
    end
    current = current or 0
    max = max or 0
    if max > 0 and current >= max and db.capHighlightColor then
        local color = db.capHighlightColor
        bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        return true
    end
    if db.stackThreshold and db.stackThreshold > 0 and db.stackThresholdColor and current >= db.stackThreshold then
        local color = db.stackThresholdColor
        bar:SetStatusBarColor(color.r, color.g, color.b, color.a)
        return true
    end
    return false
end

function helpers:ShouldShowByVisibilityRule(rule)
    rule = rule or 'always'
    if rule == 'hidden' then
        return false
    end
    if rule == 'always' then
        return true
    end

    local inCombat = UnitAffectingCombat('player')
    local hasTarget = UnitExists('target')

    if rule == 'inCombat' then
        return inCombat
    elseif rule == 'withTarget' then
        return hasTarget
    elseif rule == 'combatOrTarget' then
        return inCombat or hasTarget
    end
    return true
end

function helpers:GetSegmentColor(db, index, sharedKey, colorsKey, capColorKey, isAtCap)
    if isAtCap and db[capColorKey] then
        return db[capColorKey]
    end
    if db.individualSegmentColors and db[colorsKey] and db[colorsKey][index] then
        return db[colorsKey][index]
    end
    return db[sharedKey]
end

function helpers:GetInterpolation(smoothFill)
    if smoothFill then
        return Enum.StatusBarInterpolation.ExponentialEaseOut
    end
    return Enum.StatusBarInterpolation.Immediate
end

function helpers:IsChargedSegment(index, chargedPoints)
    return chargedPoints and tContains(chargedPoints, index) or false
end

function helpers:GetChargedPowerPoints()
    if GetUnitChargedPowerPoints then
        return GetUnitChargedPowerPoints('player')
    end
    return nil
end

function helpers:IsDruidInCatForm()
    local formID = GetShapeshiftFormID and GetShapeshiftFormID()
    return formID == 1
end

function helpers:GetPrimaryResourceTypeName()
    local powerType = UnitPowerType('player')
    local map = {
        [Enum.PowerType.Mana] = 'Mana',
        [Enum.PowerType.Rage] = 'Rage',
        [Enum.PowerType.Focus] = 'Focus',
        [Enum.PowerType.Energy] = 'Energy',
        [Enum.PowerType.ComboPoints] = 'Combo Points',
        [Enum.PowerType.RunicPower] = 'Runic Power',
        [Enum.PowerType.LunarPower] = 'Astral Power',
        [Enum.PowerType.Fury] = 'Fury',
        [Enum.PowerType.Insanity] = 'Insanity',
        [Enum.PowerType.Maelstrom] = 'Maelstrom',
        [Enum.PowerType.Essence] = 'Essence',
    }
    return map[powerType]
end

function helpers:GetResourceBarNormalColor(db)
    if db.useClassColor then
        local _, class = UnitClass('player')
        local color = RAID_CLASS_COLORS[class]
        if color then
            return color
        end
    end
    return db.barColor or { r = 1, g = 1, b = 1, a = 1 }
end

function helpers:ClearResourceBarColorCurve(bar)
    if not bar then
        return
    end
    bar._lowResourceColorCurve = nil
    bar._lowResourceColorCurveSig = nil
end

function helpers:GetResourceColorCurvePoints(db)
    local points = {}
    for _, point in ipairs(db.resourceColorCurve or {}) do
        if point.percent ~= nil and point.color then
            table.insert(points, point)
        end
    end
    table.sort(points, function(a, b)
        return a.percent < b.percent
    end)
    return points
end

function helpers:GetResourceColorCurveSignature(db, normalColor)
    local parts = { tostring(db.resourceColorCurveEnabled) }
    for _, point in ipairs(self:GetResourceColorCurvePoints(db)) do
        local color = point.color or {}
        table.insert(parts, string.format(
            '%s|%s|%s|%s',
            point.percent or 0,
            color.r or 0,
            color.g or 0,
            color.b or 0
        ))
    end
    table.insert(parts, string.format('%s|%s|%s', normalColor.r or 1, normalColor.g or 1, normalColor.b or 1))
    return table.concat(parts, ':')
end

function helpers:BuildResourcePercentColorCurve(db, normalColor)
    if not C_CurveUtil or not C_CurveUtil.CreateColorCurve or not CreateColor then
        return nil
    end

    local points = self:GetResourceColorCurvePoints(db)
    if #points == 0 then
        return nil
    end

    local curve = C_CurveUtil.CreateColorCurve()
    if Enum and Enum.LuaCurveType then
        curve:SetType(Enum.LuaCurveType.Step)
    end

    if (points[1].percent or 0) > 0 then
        curve:AddPoint(0, CreateColor(normalColor.r, normalColor.g, normalColor.b, normalColor.a or 1))
    end

    for _, point in ipairs(points) do
        local fraction = math.min(math.max((point.percent or 0) / 100, 0), 1)
        local color = point.color
        if color then
            curve:AddPoint(fraction, CreateColor(color.r, color.g, color.b, color.a or 1))
        end
    end

    local last = points[#points]
    local lastFraction = math.min(math.max((last.percent or 0) / 100, 0), 1)
    if last and last.color and lastFraction < 1 then
        curve:AddPoint(1, CreateColor(last.color.r, last.color.g, last.color.b, last.color.a or 1))
    end

    return curve
end

function helpers:ApplyResourceBarColor(bar, db, current, max, normalColor, powerType)
    if not bar or not db or not db.resourceColorCurveEnabled then
        return false
    end
    if #self:GetResourceColorCurvePoints(db) == 0 then
        return false
    end
    if not C_CurveUtil or not C_CurveUtil.CreateColorCurve or not CreateColor then
        return false
    end

    normalColor = normalColor or self:GetResourceBarNormalColor(db)

    local signature = self:GetResourceColorCurveSignature(db, normalColor)
    if not bar._lowResourceColorCurve or bar._lowResourceColorCurveSig ~= signature then
        bar._lowResourceColorCurve = self:BuildResourcePercentColorCurve(db, normalColor)
        bar._lowResourceColorCurveSig = signature
    end

    local curve = bar._lowResourceColorCurve
    if not curve then
        return false
    end

    if powerType and UnitPowerPercent then
        local color = UnitPowerPercent('player', powerType, false, curve)
        if color and color.GetRGB then
            bar:SetStatusBarColor(color:GetRGB())
            return true
        end
    end

    if current ~= nil and max > 0 and (not issecretvalue or not issecretvalue(current)) then
        local color = curve:Evaluate(current / max)
        if color and color.GetRGB then
            bar:SetStatusBarColor(color:GetRGB())
            return true
        end
    end

    return false
end

function helpers:ApplyBarThresholdColor(bar, db, current, max, powerType)
    return self:ApplyResourceBarColor(bar, db, current, max, self:GetResourceBarNormalColor(db), powerType)
end

function helpers:ApplyReverseFill(bar, reverseFill)
    if not bar then
        return
    end
    if reverseFill and Enum.StatusBarFillStyle then
        bar:SetFillStyle(Enum.StatusBarFillStyle.Reverse)
    elseif Enum.StatusBarFillStyle then
        bar:SetFillStyle(Enum.StatusBarFillStyle.Standard)
    end
end

function helpers:LayoutSegments(frame, activeFrames, db, widthKey, heightKey, spacingKey)
    local width = db[widthKey] or 30
    local height = db[heightKey] or 16
    local spacing = db[spacingKey] or 2
    local layout = db.segmentLayout or 'horizontal'
    local reverse = db.segmentReverse

    local ordered = {}
    for _, segment in ipairs(activeFrames) do
        table.insert(ordered, segment)
    end
    if reverse then
        local reversed = {}
        for i = #ordered, 1, -1 do
            table.insert(reversed, ordered[i])
        end
        ordered = reversed
    end

    local prev = nil
    for _, segment in ipairs(ordered) do
        segment:ClearAllPoints()
        if not prev then
            EXUI:SetPoint(segment, 'TOPLEFT', frame, 'TOPLEFT', 0, 0)
        elseif layout == 'vertical' then
            EXUI:SetPoint(segment, 'TOP', prev, 'BOTTOM', 0, -spacing)
        else
            EXUI:SetPoint(segment, 'LEFT', prev, 'RIGHT', spacing, 0)
        end
        prev = segment
    end

    if layout == 'vertical' then
        local count = #ordered
        local totalHeight = height * count + spacing * math.max(0, count - 1)
        return width, totalHeight
    end
    local count = #ordered
    local totalWidth = width * count + spacing * math.max(0, count - 1)
    return totalWidth, height
end

function helpers:BuildIndividualColorOptions(displayID, prefix, count, sharedColorKey, colorsKey, RDCore)
    local fields = {
        {
            type = 'toggle',
            label = 'Individual Segment Colors',
            name = prefix .. 'IndividualColors',
            currentValue = function()
                return RDCore:GetValueForDisplay(displayID, 'individualSegmentColors')
            end,
            onChange = function(value)
                RDCore:UpdateValueForDisplay(displayID, 'individualSegmentColors', value)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = 100,
        },
    }

    for i = 1, count do
        table.insert(fields, {
            type = 'color-picker',
            label = 'Segment ' .. i,
            name = colorsKey .. i,
            depends = function()
                return RDCore:GetValueForDisplay(displayID, 'individualSegmentColors')
            end,
            currentValue = function()
                local colors = RDCore:GetValueForDisplay(displayID, colorsKey) or {}
                return colors[i] or RDCore:GetValueForDisplay(displayID, sharedColorKey)
            end,
            onChange = function(value)
                local colors = RDCore:GetValueForDisplay(displayID, colorsKey) or {}
                colors[i] = value
                RDCore:UpdateValueForDisplay(displayID, colorsKey, colors)
                RDCore:RefreshDisplayByID(displayID)
            end,
            width = math.floor(100 / math.min(count, 5)),
        })
    end

    return fields
end

function helpers:WireSegmentEnableDisable(frame, events)
    frame._segmentEvents = events
    frame.Enable = function(self)
        for _, event in ipairs(self._segmentEvents) do
            if event:sub(1, 5) == 'UNIT_' then
                self:RegisterUnitEvent(event, 'player')
            else
                self:RegisterEvent(event)
            end
        end
    end
    frame.Disable = function(self)
        self:UnregisterAllEvents()
    end
end

