---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsLayout
local layout = EXUI:GetModule('action-bars-layout')

layout.Apply = function(self, barFrame, config, buttons)
    local numShown = math.min(config.numButtons or #buttons, #buttons)
    local buttonsPerRow = math.max(1, config.buttonsPerRow or numShown)
    local paddingX = config.paddingX or 2
    local paddingY = config.paddingY or 2
    local btnW = config.width or 36
    local btnH = config.height or 36
    local isHorizontal = config.orientation ~= 'vertical'
    local growRight = config.growHorizontal ~= 'left'
    local growUp = config.growVertical ~= 'up'

    local rows = math.ceil(numShown / buttonsPerRow)
    local cols = math.min(buttonsPerRow, numShown)

    local totalW, totalH
    if isHorizontal then
        totalW = cols * btnW + (cols - 1) * paddingX
        totalH = rows * btnH + (rows - 1) * paddingY
    else
        totalW = rows * btnW + (rows - 1) * paddingX
        totalH = cols * btnH + (cols - 1) * paddingY
    end

    EXUI:SetSize(barFrame, totalW, totalH)

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

            local xOff = col * (btnW + paddingX)
            local yOff = row * (btnH + paddingY)
            if not growRight then
                xOff = -xOff
            end
            if not growUp then
                yOff = -yOff
            end

            EXUI:SetSize(button, btnW, btnH)
            button:ClearAllPoints()
            EXUI:SetPoint(button, startAnchor, barFrame, startAnchor, xOff, yOff)
            button:Show()
        else
            button:Hide()
        end
    end
end
