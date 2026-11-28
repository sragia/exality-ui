---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUICDMLayout
local layout = EXUI:GetModule('cdm-layout')

layout.MODES = {
    row = { label = 'Single Line', order = 1 },
    grid = { label = 'Grid (wrap)', order = 2 },
    custom = { label = 'Custom Lines', order = 3 },
    auraRow = { label = 'Aura Row (collapses)', order = 4 },
    free = { label = 'Free (own positions)', order = 5 },
}

layout.DIRECTIONS = {
    horizontal = { label = 'Horizontal', order = 1 },
    vertical = { label = 'Vertical', order = 2 },
}

layout.GROW_X = {
    RIGHT = { label = 'Right', order = 1 },
    LEFT = { label = 'Left', order = 2 },
}

layout.GROW_Y = {
    DOWN = { label = 'Down', order = 1 },
    UP = { label = 'Up', order = 2 },
}

layout.ALIGN = {
    start = { label = 'Start', order = 1 },
    center = { label = 'Center', order = 2 },
    ['end'] = { label = 'End', order = 3 },
}

function layout:IsFree(groupNode)
    return groupNode.layout.mode == 'free'
end

function layout:IsAuraRow(groupNode)
    return groupNode ~= nil and groupNode.kind == 'group' and groupNode.layout.mode == 'auraRow'
end

-- Custom mode keeps each child on the line it was dragged to (cell.line); empty lines are skipped.
local function orderCells(cells, settings)
    if settings.mode ~= 'custom' then
        local wraps = settings.mode == 'grid' or settings.mode == 'auraRow'
        local perLine = wraps and math.max(1, settings.perLine) or math.huge
        local keys = {}
        for index in ipairs(cells) do
            keys[index] = math.floor((index - 1) / perLine)
        end
        return cells, keys
    end
    local order = {}
    for index, cell in ipairs(cells) do
        order[index] = { cell = cell, index = index }
    end
    table.sort(order, function(a, b)
        local aLine, bLine = a.cell.line or 1, b.cell.line or 1
        if aLine ~= bLine then
            return aLine < bLine
        end
        return a.index < b.index
    end)
    local sorted, keys = {}, {}
    for index, entry in ipairs(order) do
        sorted[index] = entry.cell
        keys[index] = entry.cell.line or 1
    end
    return sorted, keys
end

local function buildLines(cells, settings)
    local horizontal = settings.direction == 'horizontal'
    local gapMain = horizontal and settings.spacingX or settings.spacingY
    local ordered, keys = orderCells(cells, settings)
    local lines = {}
    local line
    for index, cell in ipairs(ordered) do
        if not line or keys[index] ~= line.key then
            line = { cells = {}, main = 0, cross = 0, key = keys[index] }
            lines[#lines + 1] = line
        end
        local main = horizontal and cell.width or cell.height
        local cross = horizontal and cell.height or cell.width
        line.main = line.main + (#line.cells > 0 and gapMain or 0) + main
        line.cross = math.max(line.cross, cross)
        line.cells[#line.cells + 1] = cell
        cell.lineIndex = #lines
    end
    return lines
end

-- cells: ordered { frame, width, height }. Returns the bounding width and height.
function layout:Arrange(container, cells, settings)
    local horizontal = settings.direction == 'horizontal'
    local gapMain = horizontal and settings.spacingX or settings.spacingY
    local gapCross = horizontal and settings.spacingY or settings.spacingX
    local signX = settings.growX == 'LEFT' and -1 or 1
    local signY = settings.growY == 'UP' and 1 or -1
    local point = (signY < 0 and 'TOP' or 'BOTTOM') .. (signX > 0 and 'LEFT' or 'RIGHT')

    local lines = buildLines(cells, settings)
    local longest = 0
    for _, line in ipairs(lines) do
        longest = math.max(longest, line.main)
    end

    local crossOffset = 0
    for _, line in ipairs(lines) do
        local mainOffset = 0
        if settings.align == 'center' then
            mainOffset = (longest - line.main) / 2
        elseif settings.align == 'end' then
            mainOffset = longest - line.main
        end
        for _, cell in ipairs(line.cells) do
            local x = horizontal and mainOffset or crossOffset
            local y = horizontal and crossOffset or mainOffset
            if cell.frame then
                cell.frame:ClearAllPoints()
                cell.frame:SetPoint(point, container, point, x * signX, y * signY)
            end
            mainOffset = mainOffset + (horizontal and cell.width or cell.height) + gapMain
        end
        crossOffset = crossOffset + line.cross + gapCross
    end

    local crossTotal = math.max(0, crossOffset - gapCross)
    local width = horizontal and longest or crossTotal
    local height = horizontal and crossTotal or longest
    return math.max(1, width), math.max(1, height)
end
