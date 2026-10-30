---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIMerchantWindowSprite
local sprite = EXUI:GetModule('merchant-window-sprite')

---@class EXUIMerchantWindowPagination
local pagination = EXUI:GetModule('merchant-window-pagination')

pagination.frame = nil
pagination.dots = {}
pagination.onChange = nil
pagination.page = 1
pagination.pages = 1

local HEIGHT = 16
local CHEVRON_WIDTH = 12
local CHEVRON_HEIGHT = 20
local CHEVRON_SCALE = 0.45
local CHEVRON_GAP = 8
local DOT_SCALE = 0.6
local DOT_WIDTH = 14
local PILL_WIDTH = 22
local DOT_GAP = 4
local MAX_DOTS = 10

pagination.height = HEIGHT

local function AcquireDot(self, index)
    local dot = self.dots[index]
    if (dot) then
        return dot
    end

    dot = sprite:CreateButton(self.frame, DOT_WIDTH, HEIGHT, 'dotOff', 'dotOn', DOT_SCALE)
    dot:SetScript('OnClick', function(button)
        pagination.onChange(button.targetPage)
    end)
    if (index == 1) then
        dot:SetPoint('LEFT', self.prev, 'RIGHT', CHEVRON_GAP, 0)
    else
        dot:SetPoint('LEFT', self.dots[index - 1], 'RIGHT', DOT_GAP, 0)
    end
    self.dots[index] = dot
    return dot
end

pagination.Create = function(self, parent, onChange)
    self.onChange = onChange

    local frame = CreateFrame('Frame', nil, parent)
    frame:SetHeight(HEIGHT)
    self.frame = frame

    local prev = sprite:CreateButton(frame, CHEVRON_WIDTH, CHEVRON_HEIGHT, 'chevronOff', 'chevronOn', CHEVRON_SCALE)
    prev.dimDisabled = true
    prev:SetPoint('LEFT')
    prev:SetScript('OnClick', function()
        self:Step(-1)
    end)
    self.prev = prev

    local next = sprite:CreateButton(frame, CHEVRON_WIDTH, CHEVRON_HEIGHT, 'chevronOff', 'chevronOn', CHEVRON_SCALE,
        true)
    next.dimDisabled = true
    next:SetScript('OnClick', function()
        self:Step(1)
    end)
    self.next = next

    return frame
end

pagination.Step = function(self, delta)
    local target = self.page + delta
    if (target >= 1 and target <= self.pages) then
        self.onChange(target)
    end
end

pagination.Update = function(self, page, pages)
    self.page = page
    self.pages = pages

    self.frame:SetShown(pages > 1)
    if (pages <= 1) then
        return
    end

    local shown = math.min(pages, MAX_DOTS)
    local first = math.max(math.min(page - math.floor(shown / 2), pages - shown + 1), 1)
    local width = CHEVRON_WIDTH * 2 + CHEVRON_GAP * 2 + DOT_GAP * (shown - 1)

    for index = 1, shown do
        local dot = AcquireDot(self, index)
        local target = first + index - 1
        local isCurrent = target == page
        dot.targetPage = target
        dot:SetWidth(isCurrent and PILL_WIDTH or DOT_WIDTH)
        dot.offKey = isCurrent and 'pill' or 'dotOff'
        dot.onKey = isCurrent and 'pill' or 'dotOn'
        dot:UpdateArt()
        dot:Show()
        width = width + dot:GetWidth()
    end
    for index = shown + 1, #self.dots do
        self.dots[index]:Hide()
    end

    self.next:ClearAllPoints()
    self.next:SetPoint('LEFT', self.dots[shown], 'RIGHT', CHEVRON_GAP, 0)
    self.frame:SetWidth(width)

    self.prev:SetEnabled(page > 1)
    self.prev:UpdateArt()
    self.next:SetEnabled(page < pages)
    self.next:UpdateArt()
end
