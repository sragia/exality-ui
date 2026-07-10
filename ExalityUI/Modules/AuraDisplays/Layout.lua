---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysConfigResolver
local resolver = EXUI:GetModule('aura-displays-config-resolver')

---@class EXUIAuraDisplaysLayout
local layout = EXUI:GetModule('aura-displays-layout')

function layout:ApplyContainerLayout(container, display)
    if not container then
        return
    end

    if container.SetAuraLayoutAnchorPoint then
        container:SetAuraLayoutAnchorPoint(display.containerAnchorPoint or 'TOPLEFT')
    end

    if container.SetAuraLayoutGrowthDirection then
        local horizontal = resolver:GetGrowthDirection(display.horizontalGrowth or 'RIGHT')
        local vertical = resolver:GetGrowthDirection(display.verticalGrowth or 'DOWN')
        container:SetAuraLayoutGrowthDirection(horizontal, vertical)
    end

    if container.SetAuraLayoutPadding then
        container:SetAuraLayoutPadding(
            display.paddingLeft or 0,
            display.paddingRight or 0,
            display.paddingTop or 0,
            display.paddingBottom or 0
        )
    end

    if container.SetAuraLayoutRowWidth then
        local rowWidth = display.rowWidth
        if not rowWidth or rowWidth <= 0 then
            rowWidth = math.huge
        end
        container:SetAuraLayoutRowWidth(rowWidth)
    end
end

function layout:ApplyDisplayPosition(frame, display)
    frame:ClearAllPoints()
    frame:SetPoint(display.anchorPoint, UIParent, display.relativePoint, display.XOff or 0, display.YOff or 0)
    frame:SetFrameStrata(display.frameStrata or 'LOW')
    frame:SetFrameLevel(display.frameLevel or 10)
end

function layout:ApplyItemEnchantmentLayout(container, containerConfig)
    if not container or not container.SetItemEnchantmentLayout then
        return
    end
    local placement = containerConfig.itemEnchantPlacement == 'AfterAuraGroups' and 1 or 0
    container:SetItemEnchantmentLayout({
        placement = placement,
        elementSpacingX = containerConfig.itemEnchantSpacingX or 0,
        elementSpacingY = containerConfig.itemEnchantSpacingY or 0,
        gapX = containerConfig.itemEnchantGapX or 0,
        gapY = containerConfig.itemEnchantGapY or 0,
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
    local groupLayout = resolver:GetGroupLayout(groupVisual)
    local elementWidth = groupLayout.elementWidth or groupVisual.iconWidth or 32
    local elementHeight = groupLayout.elementHeight or groupVisual.iconHeight or 32

    local anchorPoint = display.containerAnchorPoint or 'TOPLEFT'
    local horizontalDirection = resolver:GetGrowthDirection(display.horizontalGrowth or 'RIGHT')
    local verticalDirection = resolver:GetGrowthDirection(display.verticalGrowth or 'DOWN')

    local paddingLeft = display.paddingLeft or 0
    local paddingRight = display.paddingRight or 0
    local paddingTop = display.paddingTop or 0
    local paddingBottom = display.paddingBottom or 0

    local maxRowWidth = display.rowWidth
    if not maxRowWidth or maxRowWidth <= 0 then
        maxRowWidth = math.huge
    end

    local elementSpacingX = groupLayout.elementSpacingX or 0
    local elementSpacingY = groupLayout.elementSpacingY or 0

    local flowDown = verticalDirection == -1
    local flowRight = horizontalDirection == 1

    local startPaddingX = flowRight and paddingLeft or paddingRight
    local endPaddingX = flowRight and paddingRight or paddingLeft
    local startPaddingY = flowDown and paddingTop or paddingBottom
    local endPaddingY = flowDown and paddingBottom or paddingTop

    local cursorX = startPaddingX * horizontalDirection
    local cursorY = startPaddingY * verticalDirection
    local rowUsedWidth = 0
    local rowHeight = 0
    local layoutWidth = startPaddingX + endPaddingX
    local layoutHeight = startPaddingY + endPaddingY

    local function advanceToNextRow(rowGapY)
        cursorX = startPaddingX * horizontalDirection
        cursorY = cursorY + ((rowHeight + rowGapY) * verticalDirection)
        rowUsedWidth = 0
        rowHeight = 0
    end

    for _, element in ipairs(elements) do
        local nextRowWidth = rowUsedWidth > 0 and rowUsedWidth + elementWidth or elementWidth
        if rowUsedWidth > 0 and nextRowWidth > maxRowWidth then
            advanceToNextRow(elementSpacingY)
            nextRowWidth = elementWidth
        end

        element:SetSize(elementWidth, elementHeight)
        element:ClearAllPoints()
        element:SetPoint(anchorPoint, container, anchorPoint, cursorX, cursorY)

        cursorX = cursorX + ((elementWidth + elementSpacingX) * horizontalDirection)
        rowUsedWidth = nextRowWidth + elementSpacingX
        rowHeight = math.max(rowHeight, elementHeight)

        layoutWidth = math.max(layoutWidth, startPaddingX + rowUsedWidth - elementSpacingX + endPaddingX)
        layoutHeight = math.max(layoutHeight, math.abs(cursorY) + elementHeight + endPaddingY)
    end

    container:SetSize(math.max(layoutWidth, 1), math.max(layoutHeight, 1))
end
