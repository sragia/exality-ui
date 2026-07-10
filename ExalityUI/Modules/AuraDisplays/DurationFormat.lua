---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysDurationFormat
local durationFormat = EXUI:GetModule('aura-displays-duration-format')

durationFormat.FORMAT_DEFAULT = 'default'
durationFormat.FORMAT_MMSS = 'mmss'
durationFormat.FORMAT_FALLBACK = durationFormat.FORMAT_MMSS

local cachedFormatters = {}

function durationFormat:GetFormatOptions()
    return {
        [self.FORMAT_DEFAULT] = 'Default',
        [self.FORMAT_MMSS] = 'MM:SS (<3m)',
    }
end

function durationFormat:GetDefaultFormatter()
    if cachedFormatters.default then
        return cachedFormatters.default
    end
    if AuraContainerInbound and AuraContainerInbound.GetDefaultAuraDurationFormatter then
        cachedFormatters.default = AuraContainerInbound.GetDefaultAuraDurationFormatter()
    end
    return cachedFormatters.default
end

function durationFormat:BuildMMSSFormatter()
    if not C_StringUtil or not C_StringUtil.CreateNumericRuleFormatter then
        return nil
    end

    local roundingDown = Enum.NumericRuleFormatRounding and Enum.NumericRuleFormatRounding.Down or 2
    local formatter = C_StringUtil.CreateNumericRuleFormatter()
    formatter:SetBreakpoints({
        {
            threshold = 3600,
            format = '%dh',
            components = {
                { div = 3600, rounding = roundingDown },
            },
        },
        {
            threshold = 180,
            format = '%dm',
            components = {
                { div = 60, rounding = roundingDown },
            },
        },
        {
            threshold = 5,
            format = '%d:%02d',
            components = {
                { div = 60, rounding = roundingDown },
                { mod = 60, rounding = roundingDown },
            },
        },
        {
            threshold = 0,
            format = '%.1f',
        },
    })
    return formatter
end

function durationFormat:GetMMSSFormatter()
    if cachedFormatters.mmss then
        return cachedFormatters.mmss
    end
    local formatter = self:BuildMMSSFormatter()
    if formatter then
        cachedFormatters.mmss = formatter
        return formatter
    end
    return self:GetDefaultFormatter()
end

function durationFormat:GetFormatter(formatKey)
    if formatKey == self.FORMAT_MMSS then
        return self:GetMMSSFormatter()
    end
    return self:GetDefaultFormatter()
end
