---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMDefaults
local defaults = EXUI:GetModule('cdm-defaults')

---@class EXUICDMSources
local sources = EXUI:GetModule('cdm-sources')

---@class EXUICDMLayout
local layout = EXUI:GetModule('cdm-layout')

---@class EXUICDMCatalog
local catalog = EXUI:GetModule('cdm-catalog')

---@class EXUICDMDesigner
local designer = EXUI:GetModule('cdm-designer')

-- Miniature of a group's layout (not shown for free groups): click a child to open it, drag to reorder, "+" to add one.
-- In Custom Lines mode, dropping above or below every line starts a new one.

local PADDING = 10
local ADD_SIZE = 24
local MIN_HEIGHT = 70
local GROUP_TILE = 36
local NEW_LINE_MARGIN = 6

local bindDrag

local ART = [[Interface/Addons/ExalityUI/Assets/Images/Designer/]]
local TEX = {
    panelBg = ART .. 'panel-bg.png',
    panelBorder = ART .. 'panel-border.png',
    iconMask = ART .. 'icon-mask.png',
    iconBorder = ART .. 'icon-border.png',
    dropBg = ART .. 'drop-bg.png',
    dropIcon = ART .. 'drop-icon.png',
    addBg = ART .. 'add-bg.png',
    addIcon = ART .. 'add-icon.png',
}
-- Slice margins in texture pixels; the panel border carries a 7px shadow outside its line.
local CORNER = 6
local PANEL_BORDER_SLICE = 13
local PANEL_SHADOW = 7
local DROP_ICON_SIZE = 29
local OUTLINE_COLOR = { 0.3, 0.3, 0.3, 1 }

local function sliced(texture, file, margin)
    texture:SetTexture(file)
    texture:SetTextureSliceMargins(margin, margin, margin, margin)
    texture:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
end

-- isIcon follows the shared Shape code: Forever squeezes icons under a sliced mask, so icon masks
-- stretch whole there. Other masks (bar fills) stay sliced.
local function roundedMask(parent, anchor, isIcon)
    local mask = parent:CreateMaskTexture()
    mask:SetTexture(TEX.iconMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    if isIcon and EXUI.IsForever() then
        mask:ClearTextureSlice()
    else
        mask:SetTextureSliceMargins(CORNER, CORNER, CORNER, CORNER)
        mask:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
    mask:SetAllPoints(anchor or parent)
    return mask
end

local function cdm()
    return EXUI:GetModule('cdm')
end

local function changed()
    cdm():Refresh()
    optionsFields:RefreshItemList()
    optionsFields:RefreshOptions()
end

local function tileSize(node)
    if node.kind == 'group' then
        return GROUP_TILE, GROUP_TILE
    end
    local look = node.display == 'bar' and data:ResolveBar(node) or data:ResolveIcon(node)
    return look.width, look.height
end


------------------------------------------------------------
-- Adding children

local function addChild(groupID, configure)
    local group = data:GetNode(groupID)
    local _, node = data:Create('item', groupID)
    if group.layout.mode == 'custom' then
        node.line = data:LastLine(groupID)
    end
    configure(node)
    changed()
end

local function showAddMenu(anchor, groupID)
    EXFrames:GetFrame('list-menu-frame'):ToggleAt(anchor, {
        {
            text = 'Cooldown from Cooldown Manager',
            onClick = function()
                catalog:ShowPicker(anchor, function(entry)
                    addChild(groupID, function(node)
                        for key, value in pairs(entry.source) do
                            node.source[key] = value
                        end
                        node.name = entry.name
                    end)
                end, false, true)
                return false
            end,
        },
        {
            text = 'Aura from Cooldown Manager',
            onClick = function()
                catalog:ShowPicker(anchor, function(entry)
                    addChild(groupID, function(node)
                        local ids = {}
                        for _, spellID in ipairs(entry.spellIDs) do
                            ids[#ids + 1] = tostring(spellID)
                        end
                        node.source.type = 'aura'
                        node.source.spellIDs = CopyTable(entry.spellIDs)
                        node.source.input = table.concat(ids, ', ')
                        node.name = entry.name
                    end)
                end, true, true)
                return false
            end,
        },
        { isDivider = true },
        {
            text = 'Empty Cooldown',
            onClick = function()
                addChild(groupID, function() end)
            end,
        },
        {
            text = 'Empty Buff / Debuff',
            onClick = function()
                addChild(groupID, function(node)
                    node.source.type = 'aura'
                    node.name = 'New Aura'
                end)
            end,
        },
        {
            text = 'Group',
            onClick = function()
                local _, node = data:Create('group', groupID)
                if data:GetNode(groupID).layout.mode == 'custom' then
                    node.line = data:LastLine(groupID)
                end
                changed()
            end,
        },
    }, 'drawer')
end

------------------------------------------------------------
-- Dragging

local function cursorPosition()
    local x, y = GetCursorPosition()
    return x, y
end

local function tileCenter(tile)
    local x, y = tile:GetCenter()
    local scale = tile:GetEffectiveScale()
    return x * scale, y * scale
end

local function tileBounds(tile)
    local scale = tile:GetEffectiveScale()
    return tile:GetLeft() * scale, tile:GetRight() * scale, tile:GetBottom() * scale, tile:GetTop() * scale
end

-- Nested groups without their own layout preview as a grid.
local function settingsFor(group)
    if layout:IsFree(group) then
        local settings = CopyTable(defaults.LAYOUT)
        settings.mode = 'grid'
        return settings
    end
    return group.layout
end

-- Aura Rows only show Buff / Debuff items, so nothing else can be dropped into them.
local function acceptsDrop(groupID, dragged)
    if data:Contains(dragged, groupID) then
        return false
    end
    if not layout:IsAuraRow(data:GetNode(groupID)) then
        return true
    end
    local node = data:GetNode(dragged)
    return node.kind == 'item' and node.source.type == 'aura'
        and node.source.unit == data:GetNode(groupID).layout.flowUnit
end

local DROP_HOLD_MARGIN = 10

local function isNear(tile, margin)
    local left, right, bottom, top = tileBounds(tile)
    local x, y = GetCursorPosition()
    return x >= left - margin and x <= right + margin and y >= bottom - margin and y <= top + margin
end

-- The deepest group box under the cursor takes the drop. The current target is kept while the cursor is
-- still near it, so the box growing around the placeholder cannot make the target flip back and forth.
local function dropParent(frame, dragged)
    local current = frame.dragDrop and frame.dragDrop.parentID
    local margin = DROP_HOLD_MARGIN * frame:GetEffectiveScale()
    local best, bestDepth = frame.groupID, 0
    for _, tile in ipairs(frame.childTiles) do
        if tile.isGroup and tile.depth > bestDepth and acceptsDrop(tile.childID, dragged)
            and (tile:IsMouseOver() or (tile.childID == current and isNear(tile, margin))) then
            best, bestDepth = tile.childID, tile.depth
        end
    end
    return best
end

-- Where the dragged child lands: its new group, the sibling it goes next to (or a new line), and the side.
-- Custom lines pick the line under the cursor first, so short lines next to long ones still take drops.
local function findDrop(frame, dragged)
    local parentID = dropParent(frame, dragged)
    local settings = settingsFor(data:GetNode(parentID))
    local horizontal = settings.direction == 'horizontal'
    local x, y = GetCursorPosition()
    local main, cross = horizontal and x or y, horizontal and y or x

    local lines, order = {}, {}
    for _, tile in ipairs(frame.childTiles) do
        if tile.parentID == parentID then
            local key = settings.mode == 'custom' and tile.line or 1
            local line = lines[key]
            if not line then
                line = { key = key, tiles = {} }
                lines[key] = line
                order[#order + 1] = line
            end
            local left, right, bottom, top = tileBounds(tile)
            local low, high = horizontal and bottom or left, horizontal and top or right
            line.low = line.low and math.min(line.low, low) or low
            line.high = line.high and math.max(line.high, high) or high
            table.insert(line.tiles, tile)
        end
    end
    local drop = { parentID = parentID }
    if #order == 0 then
        return drop
    end

    local candidates
    if settings.mode == 'custom' then
        local minCross, maxCross = math.huge, -math.huge
        local closest, closestGap
        for _, line in ipairs(order) do
            minCross = math.min(minCross, line.low)
            maxCross = math.max(maxCross, line.high)
            local gap = cross < line.low and line.low - cross or (cross > line.high and cross - line.high or 0)
            if not closestGap or gap < closestGap then
                closest, closestGap = line, gap
            end
        end
        local margin = NEW_LINE_MARGIN * frame:GetEffectiveScale()
        -- Screen y grows up and x grows right; which side is "after" depends on the grow direction.
        local lastSideHigh = horizontal and settings.growY == 'UP' or (not horizontal and settings.growX == 'RIGHT')
        if cross > maxCross + margin then
            drop.newLine = lastSideHigh and 'after' or 'before'
        elseif cross < minCross - margin then
            drop.newLine = lastSideHigh and 'before' or 'after'
        end
        candidates = closest.tiles
    else
        candidates = {}
        for _, line in ipairs(order) do
            for _, tile in ipairs(line.tiles) do
                candidates[#candidates + 1] = tile
            end
        end
    end

    local nearest, nearestDistance
    for _, tile in ipairs(candidates) do
        local cx, cy = tileCenter(tile)
        local distance
        if settings.mode == 'custom' then
            distance = math.abs((horizontal and cx or cy) - main)
        else
            distance = (cx - x) ^ 2 + (cy - y) ^ 2
        end
        if not nearestDistance or distance < nearestDistance then
            nearest, nearestDistance = tile, distance
        end
    end
    drop.targetID = nearest.childID
    local cx, cy = tileCenter(nearest)
    if horizontal then
        drop.before = (x < cx) ~= (settings.growX == 'LEFT')
    else
        drop.before = (y > cy) ~= (settings.growY == 'UP')
    end
    return drop
end

-- Index among the new siblings (without the dragged child) and, for custom lines, the line it lands on.
local function dropPlacement(draggedID, drop)
    local parentID = drop.parentID
    local siblings = data:GetChildren(parentID, draggedID)
    local custom = data:GetNode(parentID).layout.mode == 'custom'
    if not drop.targetID then
        return #siblings + 1, custom and data:LastLine(parentID) or nil
    end
    local index = #siblings + 1
    for position, sibling in ipairs(siblings) do
        if sibling.id == drop.targetID then
            index = drop.before and position or position + 1
        end
    end
    if not custom then
        return index, nil
    end
    if drop.newLine == 'after' then
        return #siblings + 1, data:LastLine(parentID) + 1
    elseif drop.newLine == 'before' then
        local first = math.huge
        for _, sibling in ipairs(siblings) do
            first = math.min(first, sibling.node.line or 1)
        end
        return 1, (first == math.huge and 1 or first) - 1
    end
    return index, data:GetNode(drop.targetID).line or 1
end

-- Reorder first: it clears the line when the parent changes.
local function applyDrop(draggedID, drop)
    local index, line = dropPlacement(draggedID, drop)
    data:Reorder(draggedID, drop.parentID, index)
    data:GetNode(draggedID).line = line
    changed()
end

local function ensureGhost()
    if designer.Ghost then
        return designer.Ghost
    end
    local ghost = CreateFrame('Frame', nil, UIParent)
    ghost:SetFrameStrata('TOOLTIP')
    ghost:SetSize(28, 28)
    ghost:SetAlpha(0.8)
    ghost.Icon = ghost:CreateTexture(nil, 'ARTWORK')
    ghost.Icon:SetAllPoints()
    ghost.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    ghost.Icon:AddMaskTexture(roundedMask(ghost, ghost.Icon, true))
    ghost.Outline = ghost:CreateTexture(nil, 'OVERLAY')
    ghost.Outline:SetAllPoints()
    sliced(ghost.Outline, TEX.iconBorder, CORNER)
    ghost.Outline:SetVertexColor(unpack(EXFrames.Theme.accent))
    ghost:SetScript('OnUpdate', function(self)
        local x, y = GetCursorPosition()
        local scale = self:GetEffectiveScale()
        self:ClearAllPoints()
        self:SetPoint('CENTER', UIParent, 'BOTTOMLEFT', x / scale, y / scale)
    end)
    ghost:Hide()
    designer.Ghost = ghost
    return ghost
end

------------------------------------------------------------
-- Tiles

local function createTile(parent)
    local tile = CreateFrame('Button', nil, parent)
    tile:RegisterForClicks('LeftButtonUp', 'MiddleButtonUp')
    tile:RegisterForDrag('LeftButton')
    tile.Background = tile:CreateTexture(nil, 'BACKGROUND')
    tile.Background:SetAllPoints()
    sliced(tile.Background, TEX.iconMask, CORNER)
    tile.Background:SetVertexColor(0, 0, 0, 0.6)
    tile.Icon = tile:CreateTexture(nil, 'ARTWORK')
    tile.Icon:AddMaskTexture(roundedMask(tile, tile.Icon, true))
    tile.Bar = tile:CreateTexture(nil, 'ARTWORK')
    tile.Bar:AddMaskTexture(roundedMask(tile, tile, false))
    tile.Outline = tile:CreateTexture(nil, 'OVERLAY')
    tile.Outline:SetAllPoints()
    sliced(tile.Outline, TEX.iconBorder, CORNER)
    tile.Outline:SetVertexColor(unpack(OUTLINE_COLOR))
    tile:SetScript('OnEnter', function(self)
        self.Outline:SetVertexColor(unpack(EXFrames.Theme.accent))
    end)
    tile:SetScript('OnLeave', function(self)
        self.Outline:SetVertexColor(unpack(self:IsMouseOver() and EXFrames.Theme.accent or OUTLINE_COLOR))
    end)
    return tile
end

local function styleBarTile(tile, node, width, height)
    local look = data:ResolveBar(node)
    local horizontal = look.orientation == 'horizontal'
    local size = math.min(horizontal and height or width, horizontal and width or height)
    local used = math.min(size + look.gap, (horizontal and width or height) - 1)
    tile.Icon:SetShown(look.iconPosition ~= 'none')
    tile.Icon:SetSize(size, size)
    tile.Icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    tile.Bar:ClearAllPoints()
    if look.iconPosition == 'none' then
        tile.Bar:SetAllPoints()
    elseif look.iconPosition == 'start' then
        tile.Icon:SetPoint('TOPLEFT')
        tile.Bar:SetPoint('TOPLEFT', horizontal and used or 0, horizontal and 0 or -used)
        tile.Bar:SetPoint('BOTTOMRIGHT')
    else
        tile.Icon:SetPoint('BOTTOMRIGHT')
        tile.Bar:SetPoint('TOPLEFT')
        tile.Bar:SetPoint('BOTTOMRIGHT', horizontal and -used or 0, horizontal and 0 or used)
    end
    tile.Bar:SetTexture(EXUI.const.textures.frame.solidBg)
    tile.Bar:SetVertexColor(look.color.r, look.color.g, look.color.b, look.color.a)
    tile.Bar:Show()
end

local function styleTile(tile, node, width, height)
    tile:SetSize(width, height)
    tile:SetAlpha(1)
    tile.Outline:SetVertexColor(unpack(tile:IsMouseOver() and EXFrames.Theme.accent or OUTLINE_COLOR))
    tile.Icon:ClearAllPoints()
    tile.Icon:Show()
    tile.Bar:Hide()
    tile.Background:SetVertexColor(0, 0, 0, 0.6)
    if tile.Inner then
        tile.Inner:Hide()
    end
    tile.Icon:SetTexture((sources:GetTexture(node.source)))
    if node.display == 'bar' then
        styleBarTile(tile, node, width, height)
        return
    end
    tile.Icon:SetAllPoints()
    tile.Icon:SetTexCoord(EXUI.utils.getTexCoords(width, height, 8))
end

------------------------------------------------------------
-- Rendering (nested groups are boxes with their children laid out inside, recursively)

local GROUP_PAD = 6
-- Custom Lines boxes get room past their lines so a nested new line can be aimed at.
local NEW_LINE_ROOM = NEW_LINE_MARGIN + 6
local renderChildren

-- Pooled tiles; the dragged one is reserved so it keeps its parent and stays shown.
local function nextTile(self, parent)
    while true do
        self.used = self.used + 1
        local tile = self.tiles[self.used]
        if not tile then
            tile = createTile(parent)
            bindDrag(self, tile)
            self.tiles[self.used] = tile
        end
        if not tile.reserved then
            tile:SetParent(parent)
            tile:Show()
            return tile
        end
    end
end

local function styleGroupTile(self, tile, id, node, depth)
    tile:SetAlpha(1)
    tile.Outline:SetVertexColor(unpack(tile:IsMouseOver() and EXFrames.Theme.accent or OUTLINE_COLOR))
    tile.Background:SetVertexColor(1, 1, 1, 0.06)
    tile.Icon:Hide()
    tile.Icon:SetTexture(node.icon or defaults.QUESTION_MARK_ICON)
    tile.Bar:Hide()
    if not tile.Inner then
        tile.Inner = CreateFrame('Frame', nil, tile)
    end
    local settings = settingsFor(node)
    local padX, padY = GROUP_PAD, GROUP_PAD
    if settings.mode == 'custom' then
        if settings.direction == 'horizontal' then
            padY = padY + NEW_LINE_ROOM
        else
            padX = padX + NEW_LINE_ROOM
        end
    end
    tile.Inner:ClearAllPoints()
    tile.Inner:SetPoint('TOPLEFT', padX, -padY)
    tile.Inner:Show()
    local width, height = renderChildren(self, tile.Inner, id, depth + 1)
    width = math.max(width, GROUP_TILE - GROUP_PAD * 2)
    height = math.max(height, GROUP_TILE - GROUP_PAD * 2)
    tile.Inner:SetSize(width, height)
    tile:SetSize(width + padX * 2, height + padY * 2)
    return width + padX * 2, height + padY * 2
end

-- Lays out one group's children in container; returns width, height, largest row size and the settings.
function renderChildren(self, container, groupID, depth)
    local settings = settingsFor(data:GetNode(groupID))
    local horizontal = settings.direction == 'horizontal'
    local cells = {}
    local rowSize = 0
    local ownIndex, ownLine
    for _, child in ipairs(data:GetChildren(groupID)) do
        if child.id == self.dragging then
            ownIndex, ownLine = #cells + 1, child.node.line
        else
            local tile = nextTile(self, container)
            tile.childID, tile.parentID, tile.depth = child.id, groupID, depth
            tile.line = child.node.line or 1
            tile.isGroup = child.node.kind == 'group'
            local width, height
            if tile.isGroup then
                width, height = styleGroupTile(self, tile, child.id, child.node, depth)
            else
                width, height = tileSize(child.node)
                styleTile(tile, child.node, width, height)
            end
            rowSize = math.max(rowSize, horizontal and height or width)
            self.childTiles[#self.childTiles + 1] = tile
            cells[#cells + 1] = { frame = tile, width = width, height = height, line = child.node.line }
        end
    end

    local index, line
    if self.dragging then
        if self.dragDrop and self.dragDrop.parentID == groupID then
            index, line = dropPlacement(self.dragging, self.dragDrop)
        elseif not self.dragDrop and ownIndex then
            index, line = ownIndex, ownLine
        end
    end
    if index then
        local width, height = self.dragSize[1], self.dragSize[2]
        self.Placeholder:SetParent(container)
        self.Placeholder:SetSize(width, height)
        local iconSize = math.min(DROP_ICON_SIZE, width, height)
        self.Placeholder.Icon:SetSize(iconSize, iconSize)
        self.Placeholder:Show()
        table.insert(cells, math.min(index, #cells + 1), {
            frame = self.Placeholder, width = width, height = height, line = line,
        })
    end

    local width, height = 0, 0
    if #cells > 0 then
        width, height = layout:Arrange(container, cells, settings)
    end
    return width, height, rowSize, settings
end

------------------------------------------------------------
-- Field frame

local function configure(frame)
    frame.PanelBg = frame:CreateTexture(nil, 'BACKGROUND')
    frame.PanelBg:SetAllPoints()
    sliced(frame.PanelBg, TEX.panelBg, CORNER)
    frame.PanelBorder = frame:CreateTexture(nil, 'BORDER')
    frame.PanelBorder:SetPoint('TOPLEFT', -PANEL_SHADOW, PANEL_SHADOW)
    frame.PanelBorder:SetPoint('BOTTOMRIGHT', PANEL_SHADOW, -PANEL_SHADOW)
    sliced(frame.PanelBorder, TEX.panelBorder, PANEL_BORDER_SLICE)
    frame.Canvas = CreateFrame('Frame', nil, frame)
    local side = PADDING * 2 + ADD_SIZE
    frame.Canvas:SetPoint('TOPLEFT', side, -PADDING)
    frame.Canvas:SetPoint('BOTTOMRIGHT', -side, PADDING)
    frame.Inner = CreateFrame('Frame', nil, frame.Canvas)
    frame.Inner:SetPoint('CENTER')
    frame.tiles = {}
    frame.childTiles = {}

    frame.AddButton = CreateFrame('Button', nil, frame)
    frame.AddButton:SetSize(ADD_SIZE, ADD_SIZE)
    frame.AddButton:SetPoint('TOPRIGHT', -PADDING, -PADDING)
    local addBg = frame.AddButton:CreateTexture(nil, 'BACKGROUND')
    addBg:SetAllPoints()
    addBg:SetTexture(TEX.addBg)
    addBg:SetVertexColor(0.85, 0.85, 0.85, 1)
    local addIcon = frame.AddButton:CreateTexture(nil, 'ARTWORK')
    addIcon:SetAllPoints()
    addIcon:SetTexture(TEX.addIcon)
    frame.AddButton:SetScript('OnEnter', function() addBg:SetVertexColor(1, 1, 1, 1) end)
    frame.AddButton:SetScript('OnLeave', function() addBg:SetVertexColor(0.85, 0.85, 0.85, 1) end)
    frame.AddButton:SetScript('OnClick', function(button)
        showAddMenu(button, frame.groupID)
    end)

    frame.Refresh = function(self)
        self.groupID = self.optionData and self.optionData.groupID
        wipe(self.childTiles)
        self.used = 0
        self.Placeholder:Hide()
        local group = data:GetNode(self.groupID)
        if group and self.frameWidth then
            local width, height, rowSize, settings = renderChildren(self, self.Inner, self.groupID, 1)
            width, height = math.max(1, width), math.max(1, height)
            self.Inner:SetSize(width, height)
            local available = math.max(1, self.frameWidth - (PADDING * 2 + ADD_SIZE) * 2)
            local scale = self.dragging and self.dragScale or math.min(1, available / width)
            self.dragScale = scale
            self.Inner:SetScale(scale)
            -- One empty row of room above and below, so dropping onto a new line is easy to aim.
            local spare = rowSize > 0 and (rowSize + settings.spacingY) * scale or 0
            if not self.dragging then
                self:SetHeight(math.max(MIN_HEIGHT, (height * scale + spare * 2) + PADDING * 2))
            end
        end
        -- Only leftover tiles are hidden; the dragged one stays (hiding it would end the drag).
        for index = self.used + 1, #self.tiles do
            if not self.tiles[index].reserved then
                self.tiles[index]:Hide()
            end
        end
    end

    frame.Placeholder = CreateFrame('Frame', nil, frame.Inner)
    frame.Placeholder.Fill = frame.Placeholder:CreateTexture(nil, 'BACKGROUND')
    frame.Placeholder.Fill:SetAllPoints()
    sliced(frame.Placeholder.Fill, TEX.dropBg, CORNER)
    frame.Placeholder.Icon = frame.Placeholder:CreateTexture(nil, 'ARTWORK')
    frame.Placeholder.Icon:SetSize(DROP_ICON_SIZE, DROP_ICON_SIZE)
    frame.Placeholder.Icon:SetPoint('CENTER')
    frame.Placeholder.Icon:SetTexture(TEX.dropIcon)
    frame.Placeholder:Hide()

    -- Recomputed every frame while dragging; the preview only re-lays out when the drop spot changes.
    frame.TrackDrop = function(self)
        local drop = self:IsMouseOver() and findDrop(self, self.dragging) or nil
        local key = drop and (drop.parentID .. tostring(drop.targetID) .. tostring(drop.before)
            .. tostring(drop.newLine)) or 'none'
        if key ~= self.dropKey then
            self.dropKey = key
            self.dragDrop = drop
            self:Refresh()
        end
    end

    frame.SetOptionData = function(self, option)
        self.optionData = option
        self:Refresh()
    end

    frame.SetFrameWidth = function(self, width)
        self.frameWidth = width
        self:SetWidth(width)
        self:Refresh()
    end

    frame:SetScript('OnHide', function(self)
        self:CancelDrag()
    end)

    -- Pinned by the corner the root grows from while dragging, so content changes do not move tiles
    -- under the cursor.
    frame.PinInner = function(self)
        local settings = data:GetNode(self.groupID).layout
        local vertical = settings.growY == 'UP' and 'BOTTOM' or 'TOP'
        local horizontal = settings.growX == 'LEFT' and 'RIGHT' or 'LEFT'
        local scale = self.Inner:GetEffectiveScale()
        local canvasScale = self.Canvas:GetEffectiveScale()
        local innerX = horizontal == 'LEFT' and self.Inner:GetLeft() or self.Inner:GetRight()
        local innerY = vertical == 'TOP' and self.Inner:GetTop() or self.Inner:GetBottom()
        local canvasX = horizontal == 'LEFT' and self.Canvas:GetLeft() or self.Canvas:GetRight()
        local canvasY = vertical == 'TOP' and self.Canvas:GetTop() or self.Canvas:GetBottom()
        local point = vertical .. horizontal
        self.Inner:ClearAllPoints()
        self.Inner:SetPoint(point, self.Canvas, point, (innerX * scale - canvasX * canvasScale) / scale,
            (innerY * scale - canvasY * canvasScale) / scale)
    end

    frame.UnpinInner = function(self)
        self.Inner:ClearAllPoints()
        self.Inner:SetPoint('CENTER')
    end

    frame.CancelDrag = function(self)
        if not self.dragging then
            return
        end
        self:UnpinInner()
        self.dragging = nil
        self.dragDrop = nil
        self.dropKey = nil
        self:SetScript('OnUpdate', nil)
        if designer.Ghost then
            designer.Ghost:Hide()
        end
        for _, tile in ipairs(self.tiles) do
            tile.reserved = nil
            tile:SetAlpha(1)
        end
        self:Refresh()
    end

    frame.configured = true
end

-- The click that can follow a drag is swallowed once; the next mouse down clears the flag.
function bindDrag(frame, tile)
    tile:SetScript('OnMouseDown', function(self)
        self.justDragged = nil
    end)
    tile:SetScript('OnClick', function(self, mouseButton)
        if self.justDragged then
            self.justDragged = nil
            return
        end
        if mouseButton == 'MiddleButton' then
            if frame.dragging then
                return
            end
            data:Delete(self.childID)
            changed()
            return
        end
        optionsFields:SetItemID(self.childID)
    end)
    tile:SetScript('OnDragStart', function(self)
        frame.dragging = self.childID
        frame.dragSize = { self:GetSize() }
        frame:PinInner()
        self.reserved = true
        self:SetAlpha(0)
        local ghost = ensureGhost()
        ghost.Icon:SetTexture(self.Icon:GetTexture())
        ghost:Show()
        frame:Refresh()
        frame:SetScript('OnUpdate', frame.TrackDrop)
    end)
    tile:SetScript('OnDragStop', function(self)
        local draggedID = frame.dragging
        if not draggedID then
            return
        end
        self.justDragged = true
        local drop = frame.dragDrop
        frame:CancelDrag()
        if drop then
            applyDrop(draggedID, drop)
        end
    end)
end

-- Layout settings only rebuild the real frames, so open previews follow every rebuild.
function designer:RefreshShown()
    if not self.pool then
        return
    end
    local resized = false
    for frame in self.pool:EnumerateActive() do
        if frame:IsVisible() and not frame.dragging then
            local height = frame:GetHeight()
            frame:Refresh()
            resized = resized or frame:GetHeight() ~= height
        end
    end
    -- Fields below are placed from the old height, so they need one relayout when it changes.
    if resized then
        optionsFields:LayoutMountedFields()
    end
end

function designer:Create()
    if not self.pool then
        self.pool = CreateFramePool('Frame', UIParent)
    end
    local frame = self.pool:Acquire()
    if not frame.configured then
        configure(frame)
    end
    frame.frameWidth = nil
    frame.dragging = nil
    frame.Destroy = function(selfFrame)
        designer.pool:Release(selfFrame)
    end
    frame:Show()
    return frame
end
