---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsLayout
local layout = EXUI:GetModule('action-bars-layout')

layout.Apply = function(self, barFrame, config, buttons)
    local numShown = math.min(config.numButtons or #buttons, #buttons)
    local buttonsPerRow = math.max(1, config.buttonsPerRow or numShown)
    local paddingX = config.paddingX
    if paddingX == nil then
        paddingX = 2
    end
    local paddingY = config.paddingY
    if paddingY == nil then
        paddingY = 2
    end
    local btnW = config.width or 36
    local btnH = config.height or 36
    local isHorizontal = config.orientation ~= 'vertical'
    local growRight = config.growHorizontal ~= 'left'
    local growUp = config.growVertical ~= 'up'

    local rows = math.ceil(numShown / buttonsPerRow)
    local cols = math.min(buttonsPerRow, numShown)

    -- Snap cell size and padding once, then build the grid from those values.
    -- Snapping each offset independently causes cumulative 1-2px gaps at 0 padding.
    local snappedBtnW = EXUI:ScalePixel(btnW, barFrame)
    local snappedBtnH = EXUI:ScalePixel(btnH, barFrame)
    local snappedPadX = EXUI:ScalePixel(paddingX, barFrame)
    local snappedPadY = EXUI:ScalePixel(paddingY, barFrame)
    local stepX = snappedBtnW + snappedPadX
    local stepY = snappedBtnH + snappedPadY

    local totalW, totalH
    if isHorizontal then
        totalW = cols * snappedBtnW + math.max(0, cols - 1) * snappedPadX
        totalH = rows * snappedBtnH + math.max(0, rows - 1) * snappedPadY
    else
        totalW = rows * snappedBtnW + math.max(0, rows - 1) * snappedPadX
        totalH = cols * snappedBtnH + math.max(0, cols - 1) * snappedPadY
    end

    barFrame:SetSize(totalW, totalH)

    local anchorX = growRight and 'LEFT' or 'RIGHT'
    local anchorY = growUp and 'BOTTOM' or 'TOP'
    local startAnchor = anchorY .. anchorX

    for i = 1, #buttons do
        local button = buttons[i]
        if i <= numShown then
            local row, col
            if isHorizontal then
                row = math.floor((i - 1) / buttonsPerRow)
                col = (i - 1) % buttonsPerRow
            else
                col = math.floor((i - 1) / buttonsPerRow)
                row = (i - 1) % buttonsPerRow
            end

            local xOff = col * stepX
            local yOff = row * stepY
            if not growRight then
                xOff = -xOff
            end
            if not growUp then
                yOff = -yOff
            end

            button:SetSize(snappedBtnW, snappedBtnH)
            button:ClearAllPoints()
            button:SetPoint(startAnchor, barFrame, startAnchor, xOff, yOff)
            button:Show()
        else
            button:Hide()
        end
    end
end
