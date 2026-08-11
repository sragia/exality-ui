---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUIAuraDisplaysLayout
local layout = EXUI:GetModule('aura-displays-layout')

local FLOW_AXIS = AnchorUtil and AnchorUtil.FlowLayoutAxis
local FLOW_AXIS_HORIZONTAL = (FLOW_AXIS and FLOW_AXIS.Horizontal) or 0
local FLOW_AXIS_VERTICAL = (FLOW_AXIS and FLOW_AXIS.Vertical) or 1

function layout:GetFlowLayoutAxis(display)
    if display and display.flowLayoutAxis == 'Columns' then
        return FLOW_AXIS_VERTICAL
    end
    return FLOW_AXIS_HORIZONTAL
end

function layout:IsColumnAxis(display)
    return self:GetFlowLayoutAxis(display) == FLOW_AXIS_VERTICAL
end

function layout:ApplyContainerLayout(container, display)
    if not container then
        return
    end

    if container.SetFlowLayoutAxis then
        container:SetFlowLayoutAxis(self:GetFlowLayoutAxis(display))
    end

    if container.SetFlowLayoutAnchorPoint then
        container:SetFlowLayoutAnchorPoint(display.containerAnchorPoint or 'TOPLEFT')
    end

    if container.SetFlowLayoutGrowthDirection then
        local horizontal = resolver:GetGrowthDirection(display.horizontalGrowth or 'RIGHT')
        local vertical = resolver:GetGrowthDirection(display.verticalGrowth or 'DOWN')
        container:SetFlowLayoutGrowthDirection(horizontal, vertical)
    end

    if container.SetFlowLayoutPadding then
        container:SetFlowLayoutPadding(
            display.paddingLeft or 0,
            display.paddingRight or 0,
            display.paddingTop or 0,
            display.paddingBottom or 0
        )
    end

    if container.SetFlowLayoutMaximumLineSize then
        local rowWidth = display.rowWidth
        if not rowWidth or rowWidth <= 0 then
            rowWidth = math.huge
        end
        container:SetFlowLayoutMaximumLineSize(rowWidth)
    end
end

function layout:ApplyDisplayPosition(frame, display)
    frame:ClearAllPoints()
    frame:SetPoint(display.anchorPoint, UIParent, display.relativePoint, display.XOff or 0, display.YOff or 0)
    frame:SetFrameStrata(display.frameStrata or 'LOW')
    frame:SetFrameLevel(display.frameLevel or 10)
end

function layout:ApplyItemEnchantmentLayout(container, containerConfig, display)
    if not container or not container.SetItemEnchantmentLayout then
        return
    end
    local placement = containerConfig.itemEnchantPlacement == 'AfterAuraGroups' and 1 or 0
    local spacingX = containerConfig.itemEnchantSpacingX or 0
    local spacingY = containerConfig.itemEnchantSpacingY or 0
    local gapX = containerConfig.itemEnchantGapX or 0
    local gapY = containerConfig.itemEnchantGapY or 0
    local columns = self:IsColumnAxis(display)
    container:SetItemEnchantmentLayout({
        placement = placement,
        elementSpacing = columns and spacingY or spacingX,
        lineSpacing = columns and spacingX or spacingY,
        groupSpacing = columns and gapY or gapX,
        groupLineSpacing = columns and gapX or gapY,
        elementWidth = containerConfig.itemEnchantWidth and containerConfig.itemEnchantWidth > 0 and containerConfig.itemEnchantWidth or nil,
        elementHeight = containerConfig.itemEnchantHeight and containerConfig.itemEnchantHeight > 0 and containerConfig.itemEnchantHeight or nil,
    })
end

-- Custom flow layout for preview only. Uses configured sizes instead of reading
-- aura button dimensions, which are secret values and cannot be used from addon code.
function layout:ApplyPreviewFlowLayout(container, display, elements, groupVisual)
    if not container or not elements or #elements == 0 then
        return
    end

    groupVisual = groupVisual or {}
    local groupLayout = resolver:GetGroupLayout(groupVisual, nil, display)
    local elementWidth = groupLayout.elementWidth or groupVisual.iconWidth or 32
    local elementHeight = groupLayout.elementHeight or groupVisual.iconHeight or 32

    local anchorPoint = display.containerAnchorPoint or 'TOPLEFT'
    local horizontalDirection = resolver:GetGrowthDirection(display.horizontalGrowth or 'RIGHT')
    local verticalDirection = resolver:GetGrowthDirection(display.verticalGrowth or 'DOWN')
    local columns = self:IsColumnAxis(display)

    local paddingLeft = display.paddingLeft or 0
    local paddingRight = display.paddingRight or 0
    local paddingTop = display.paddingTop or 0
    local paddingBottom = display.paddingBottom or 0

    local maxLineSize = display.rowWidth
    if not maxLineSize or maxLineSize <= 0 then
        maxLineSize = math.huge
    end

    local elementSpacing = groupLayout.elementSpacing or 0
    local lineSpacing = groupLayout.lineSpacing or 0

    local flowDown = verticalDirection == -1
    local flowRight = horizontalDirection == 1

    local startPaddingX = flowRight and paddingLeft or paddingRight
    local endPaddingX = flowRight and paddingRight or paddingLeft
    local startPaddingY = flowDown and paddingTop or paddingBottom
    local endPaddingY = flowDown and paddingBottom or paddingTop

    local cursorX = startPaddingX * horizontalDirection
    local cursorY = startPaddingY * verticalDirection
    local lineUsed = 0
    local lineCrossSize = 0
    local layoutWidth = startPaddingX + endPaddingX
    local layoutHeight = startPaddingY + endPaddingY

    local function primarySize()
        return columns and elementHeight or elementWidth
    end

    local function crossSize()
        return columns and elementWidth or elementHeight
    end

    local function advanceToNextLine()
        if columns then
            cursorY = startPaddingY * verticalDirection
            cursorX = cursorX + ((lineCrossSize + lineSpacing) * horizontalDirection)
        else
            cursorX = startPaddingX * horizontalDirection
            cursorY = cursorY + ((lineCrossSize + lineSpacing) * verticalDirection)
        end
        lineUsed = 0
        lineCrossSize = 0
    end

    for _, element in ipairs(elements) do
        local nextLineUsed = lineUsed > 0 and lineUsed + primarySize() or primarySize()
        if lineUsed > 0 and nextLineUsed > maxLineSize then
            advanceToNextLine()
            nextLineUsed = primarySize()
        end

        element:SetSize(elementWidth, elementHeight)
        element:ClearAllPoints()
        element:SetPoint(anchorPoint, container, anchorPoint, cursorX, cursorY)

        if columns then
            cursorY = cursorY + ((elementHeight + elementSpacing) * verticalDirection)
        else
            cursorX = cursorX + ((elementWidth + elementSpacing) * horizontalDirection)
        end
        lineUsed = nextLineUsed + elementSpacing
        lineCrossSize = math.max(lineCrossSize, crossSize())

        if columns then
            layoutWidth = math.max(layoutWidth, math.abs(cursorX) + elementWidth + endPaddingX)
            layoutHeight = math.max(layoutHeight, startPaddingY + lineUsed - elementSpacing + endPaddingY)
        else
            layoutWidth = math.max(layoutWidth, startPaddingX + lineUsed - elementSpacing + endPaddingX)
            layoutHeight = math.max(layoutHeight, math.abs(cursorY) + elementHeight + endPaddingY)
        end
    end

    container:SetSize(math.max(layoutWidth, 1), math.max(layoutHeight, 1))
end
