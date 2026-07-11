---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIResourceDisplaysCore
local core = EXUI:GetModule('resource-displays-core')

---@class EXUIResourceDisplaysPreview
local preview = EXUI:GetModule('resource-displays-preview')

preview.activeDisplayID = nil
preview.enabled = false
preview.scenario = 'mid'

preview.MOCK_VALUES = {
    ['Energy'] = { empty = 0, mid = 50, full = 100 },
    ['Mana'] = { empty = 0, mid = 50, full = 100 },
    ['Rage'] = { empty = 0, mid = 50, full = 100 },
    ['Focus'] = { empty = 0, mid = 50, full = 100 },
    ['Runic Power'] = { empty = 0, mid = 50, full = 100 },
    ['Fury'] = { empty = 0, mid = 50, full = 100 },
    ['Insanity'] = { empty = 0, mid = 50, full = 100 },
    ['Astral Power'] = { empty = 0, mid = 50, full = 100 },
    ['Arcane Charges'] = { empty = 0, mid = 2, full = 4 },
    ['Combo Points'] = { empty = 0, mid = 3, full = 5 },
    ['Holy Power'] = { empty = 0, mid = 3, full = 5 },
    ['Chi'] = { empty = 0, mid = 3, full = 6 },
    ['DK Runes'] = { empty = 0, mid = 3, full = 6 },
    ['Soul Shards'] = { empty = 0, mid = 25, full = 50 },
    ['Stagger'] = { empty = 0, mid = 35, full = 80 },
    ['Maelstrom'] = { empty = 0, mid = 5, full = 10 },
    ['Soul Fragments'] = { empty = 0, mid = 15, full = 30 },
    ['Essence'] = { empty = 0, mid = 3, full = 6 },
    ['Ebon Might'] = { empty = 0, mid = 50, full = 100 },
    ['Devourer Fury'] = { empty = 0, mid = 50, full = 100 },
    ['Balance Eclipse'] = { empty = 0, mid = 50, full = 100 },
    ['Tip of the Spear'] = { empty = 0, mid = 2, full = 5 },
}

function preview:GetPreviewDisplayID()
    return optionsFields.currItemID or self.activeDisplayID
end

function preview:IsActive(displayID)
    return self.enabled and self:GetPreviewDisplayID() == displayID
end

function preview:SetActiveDisplay(displayID)
    self.activeDisplayID = displayID
end

function preview:SetEnabled(enabled)
    self.enabled = enabled
    self.scenario = 'mid'
    if not enabled then
        core:RefreshAllFrames()
        return
    end

    local previewDisplayID = self:GetPreviewDisplayID()

    for displayID, frame in pairs(core.frames) do
        if displayID ~= previewDisplayID then
            frame:Hide()
            if frame.editor then
                frame.editor:Hide()
            end
            if frame.Disable then
                frame:Disable()
            end
            core:UpdatePlaceholder(frame, false)
        end
    end

    if previewDisplayID then
        core:RefreshDisplayByID(previewDisplayID)
    end
end

function preview:GetMockValue(resourceType, scenario)
    local values = self.MOCK_VALUES[resourceType]
    if not values then
        return 50
    end
    scenario = scenario or self.scenario
    return values[scenario] or values.mid or 50
end

function preview:GetMockMax(resourceType)
    local values = self.MOCK_VALUES[resourceType]
    if not values then
        return 100
    end
    return values.full or 100
end

function preview:ShouldUsePreview(frame)
    if not frame or not frame.displayID then
        return false
    end
    if not self.enabled then
        return false
    end
    return frame.displayID == self:GetPreviewDisplayID()
end

function preview:ApplyBarPreview(frame, resourceType)
    if not self:ShouldUsePreview(frame) then
        return false
    end
    local current = self:GetMockValue(resourceType)
    local max = self:GetMockMax(resourceType)
    if frame.StatusBar then
        frame.StatusBar:SetMinMaxValues(0, max)
        frame.StatusBar:SetValue(current)
    end
    if frame.Text and frame.db and frame.db.showText then
        local helpers = EXUI:GetModule('resource-displays-helpers')
        frame.Text:SetText(helpers:FormatPowerText(frame.db.textFormat, current, max))
        frame.Text:Show()
    end
    return true
end

function preview:ApplySegmentPreview(frame, resourceType, config)
    if not self:ShouldUsePreview(frame) then
        return false
    end
    local count = self:GetMockValue(resourceType)
    local segmentBase = EXUI:GetModule('resource-displays-segment-base')
    segmentBase:UpdateSegmentRow(frame, config, function()
        return self:GetMockMax(resourceType)
    end, nil, function(f, maxCount)
        segmentBase:SetSegmentValues(f.ActiveFrames, count, nil, f.db, config)
    end)
    return true
end
