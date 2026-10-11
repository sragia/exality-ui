---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

local NODE_SIZE = 40
local BORDER_SIZE = NODE_SIZE * (96 / 82)
local APEX_NODE_SIZE = 52
local APEX_BORDER_SIZE = APEX_NODE_SIZE * (96 / 82)
local APEX_OVERHANG = (APEX_BORDER_SIZE - APEX_NODE_SIZE) / 2
local STEP_ICON = 16
local STEP_BORDER = STEP_ICON * (96 / 82)
local STEP_COUNT = 3
local STEP_INSET = 6
local STEP_DROP = 4
local STEP_POINTS = {
    { 'TOPLEFT', -APEX_OVERHANG + STEP_INSET, APEX_OVERHANG - STEP_DROP },
    { 'TOP', 0, APEX_OVERHANG },
    { 'TOPRIGHT', APEX_OVERHANG - STEP_INSET, APEX_OVERHANG - STEP_DROP },
}
local FIT_PAD = 20
local HERO_GAP = 48
local CHOICE_GAP = 8
local UNPICKED_COLOR = 0.4
local LINE_COLOR = { 0xfc / 255, 0xcc / 255, 0x10 / 255 }
local LINE_AVAILABLE = { 0x9b / 255, 0xd2 / 255, 0x08 / 255 }
local LINE_INACTIVE = { 0.28, 0.28, 0.28 }

local TEX = {
    available = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-available.png]],
    invalid = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-invalid.png]],
    selected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-selected.png]],
    unselected = [[Interface/Addons/ExalityUI/Assets/Images/Talents/border-unselected.png]],
    countBg = [[Interface/Addons/ExalityUI/Assets/Images/Talents/count-bg.png]],
    multiLeft = [[Interface/Addons/ExalityUI/Assets/Images/Talents/multi-left.png]],
    multiRight = [[Interface/Addons/ExalityUI/Assets/Images/Talents/multi-right.png]],
    mask = [[Interface/Addons/ExalityUI/Assets/Images/Talents/talent-mask.png]],
    hover = [[Interface/Addons/ExalityUI/Assets/Images/Talents/hover-glow.png]],
    search = [[Interface/Addons/ExalityUI/Assets/Images/Talents/search-icon.png]],
}

---@class EXUITalentsTree
local tree = EXUI:GetModule('talents-tree')

tree.clip = nil
tree.canvas = nil
tree.nodes = {}
tree.edges = {}
tree.nodeByID = {}

local HOVER_FADE = 0.12

local function PrepareHover(highlight)
    highlight:SetAlpha(0)
    highlight:Show()
    local group = highlight:CreateAnimationGroup()
    local anim = group:CreateAnimation('Alpha')
    anim:SetDuration(HOVER_FADE)
    group:SetScript('OnFinished', function()
        highlight:SetAlpha(highlight.hoverTarget or 0)
    end)
    highlight.hoverTarget = 0
    highlight.HoverGroup = group
    highlight.HoverAnim = anim
end

local function SetHover(highlight, shown)
    local target = shown and 1 or 0
    local group = highlight.HoverGroup
    local anim = highlight.HoverAnim
    local from = highlight:GetAlpha()
    if (group:IsPlaying()) then
        local progress = group:GetProgress() or 0
        from = anim:GetFromAlpha() + (anim:GetToAlpha() - anim:GetFromAlpha()) * progress
        group:Stop()
    end
    highlight.hoverTarget = target
    if (math.abs(from - target) < 0.01) then
        highlight:SetAlpha(target)
        return
    end
    highlight:SetAlpha(from)
    anim:SetFromAlpha(from)
    anim:SetToAlpha(target)
    anim:SetSmoothing(shown and 'IN' or 'OUT')
    group:Play()
end

local function ThemeColor(color, alpha)
    return color[1], color[2], color[3], alpha or color[4] or 1
end

local function EntryVisual(configID, entryID)
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if (not entryInfo or not entryInfo.definitionID) then
        return nil
    end

    local definition = C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    if (not definition) then
        return nil
    end

    local name = definition.overrideName
    local icon = definition.overrideIcon
    local spellID = definition.spellID
    if (spellID) then
        local spell = C_Spell.GetSpellInfo(spellID)
        if (spell) then
            name = name or spell.name
            icon = icon or spell.iconID
        end
    end

    return {
        entryID = entryID,
        name = name,
        icon = icon,
        spellID = spellID,
        maxRanks = entryInfo.maxRanks or 1,
        entryType = entryInfo.type,
    }
end

local function HasNodeFlag(flags, flag)
    if (not flags or not flag or not bit or not bit.band) then
        return false
    end
    return bit.band(flags, flag) ~= 0
end

local function IsApexNode(nodeInfo, firstVisual)
    if (not nodeInfo or not firstVisual or nodeInfo.type ~= Enum.TraitNodeType.Tiered) then
        return false
    end
    if (not Enum.TraitNodeFlag or not HasNodeFlag(nodeInfo.flags, Enum.TraitNodeFlag.ShowTierTrack)) then
        return false
    end
    local entryType = firstVisual.entryType
    local capstoneCircle = Enum.TraitNodeEntryType and Enum.TraitNodeEntryType.SpendCapstoneCircle
    local capstoneSquare = Enum.TraitNodeEntryType and Enum.TraitNodeEntryType.SpendCapstoneSquare
    return (capstoneCircle and entryType == capstoneCircle) or (capstoneSquare and entryType == capstoneSquare)
end

local function StepSpends(nodeInfo, visuals)
    local remaining = nodeInfo.currentRank or 0
    local spends = {}
    local previousComplete = true
    for index, visual in ipairs(visuals) do
        local maxRanks = visual.maxRanks or 1
        if (maxRanks < 1) then
            maxRanks = 1
        end
        local spent = math.min(remaining, maxRanks)
        local complete = spent >= maxRanks
        spends[index] = {
            spent = spent,
            active = previousComplete and not complete,
        }
        if (not complete) then
            previousComplete = false
        end
        remaining = math.max(remaining - maxRanks, 0)
    end
    return spends
end

local function SelectedEntryID(nodeInfo)
    local active = nodeInfo.activeEntry
    if (active and active.entryID) then
        return active.entryID
    end
    return nil
end

local function SetNodePosition(node, x, y)
    node.posX = x
    node.posY = y
    node:ClearAllPoints()
    node:SetPoint('CENTER', node:GetParent(), 'TOPLEFT', x, y)
end

local function PlaceNode(node, x, y)
    node.layoutX = x
    node.layoutY = y
    SetNodePosition(node, x, y)
end

local CAMELOT_BASE_PAN_X = 49
local CAMELOT_BASE_PAN_Y = 24
local CAMELOT_CLASS_PAN_X = 60
local CAMELOT_CLASS_PAN_Y = 31
local HEADER_ICON = 32
local HEADER_GAP = 8
local FOREVER_TALENT_DROP = 28
local FOREVER_COLUMN_PAD = 36

local function ForeverPan()
    local classPanX, classPanY = CAMELOT_CLASS_PAN_X, CAMELOT_CLASS_PAN_Y
    local classID = select(3, UnitClass('player'))
    if (classID and ClassTalentUtil and ClassTalentUtil.GetVisualsForClassID) then
        local visuals = ClassTalentUtil.GetVisualsForClassID(classID)
        if (visuals and visuals.panOffset) then
            classPanX = visuals.panOffset.x or classPanX
            classPanY = visuals.panOffset.y or classPanY
        end
    end
    return CAMELOT_BASE_PAN_X - classPanX, CAMELOT_BASE_PAN_Y - classPanY
end

local function ExpandBounds(minX, minY, maxX, maxY, left, bottom, right, top)
    minX = minX and math.min(minX, left) or left
    maxX = maxX and math.max(maxX, right) or right
    minY = minY and math.min(minY, bottom) or bottom
    maxY = maxY and math.max(maxY, top) or top
    return minX, minY, maxX, maxY
end

local function FitToClip(self)
    if (EXUI.IsForever()) then
        if (self.FitForever) then
            self:FitForever()
        end
        return
    end
    local minX, minY, maxX, maxY
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown()) then
            local halfW = node:GetWidth() / 2
            local halfH = node:GetHeight() / 2
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                node.posX - halfW, node.posY - halfH, node.posX + halfW, node.posY + halfH)
        end
    end
    for index = 1, self.headerCount or 0 do
        local header = self.headers and self.headers[index]
        if (header and header:IsShown() and header.left) then
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                header.left, header.bottom, header.right, header.top)
        end
    end
    local background = self.background
    if (background and background:IsShown() and background.left) then
        minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
            background.left, background.bottom, background.right, background.top)
    end

    if (not minX or not self.clip) then
        return
    end

    local clipWidth = self.clip:GetWidth()
    local clipHeight = self.clip:GetHeight()
    if (clipWidth <= 1 or clipHeight <= 1) then
        return
    end

    local contentWidth = math.max(maxX - minX, 1)
    local contentHeight = math.max(maxY - minY, 1)
    local scale = math.min((clipWidth - FIT_PAD * 2) / contentWidth, (clipHeight - FIT_PAD * 2) / contentHeight)
    self.canvas:SetScale(scale)

    local visualWidth = contentWidth * scale
    local visualHeight = contentHeight * scale
    local panX = (clipWidth - visualWidth) / 2 - minX * scale
    local panY = -((clipHeight - visualHeight) / 2) - maxY * scale
    self.canvas:ClearAllPoints()
    self.canvas:SetPoint('TOPLEFT', self.clip, 'TOPLEFT', panX, panY)
end

local function ApexTooltipTitle(name, rank, total)
    local formatString = TALENT_BUTTON_TOOLTIP_CAPSTONE_TRACK_TITLE_FORMAT
    if (total > 0 and type(formatString) == 'string') then
        return formatString:format(name, rank, total)
    end
    return name
end

local function AddApexEntryRanks(tooltip, entryID, spent, maxRanks)
    local previewNext = spent > 0 and spent < maxRanks
    local startRank = math.max(spent, 1)
    local endRank = previewNext and (spent + 1) or startRank
    for rank = startRank, endRank do
        if (rank ~= startRank and GameTooltip_AddBlankLineToTooltip) then
            GameTooltip_AddBlankLineToTooltip(tooltip)
        end
        local purchased = rank <= spent
        local previewTitle = TALENT_BUTTON_TOOLTIP_CAPSTONE_RANK_NEXT_STAGE_PREVIEW_TITLE
        if (previewNext and not purchased and type(previewTitle) == 'string' and GameTooltip_AddHighlightLine) then
            GameTooltip_AddHighlightLine(tooltip, previewTitle)
        end
        if (tooltip.AppendInfo) then
            tooltip:AppendInfo('GetTraitEntry', entryID, rank)
        end
    end
end

local function ShowApexTooltip(button)
    local node = button.ownerNode
    local nodeInfo = node and node.nodeInfo
    local visuals = node and node.apexVisuals
    if (not nodeInfo or not visuals or not visuals[1]) then
        return
    end

    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    local name = visuals[1].name or button.entryName or ''
    local total = nodeInfo.totalMaxRanks or nodeInfo.maxRanks or 0
    local rank = nodeInfo.currentRank or 0
    local title = ApexTooltipTitle(name, rank, total)
    if (GameTooltip_SetTitle) then
        GameTooltip_SetTitle(GameTooltip, title)
    else
        GameTooltip:SetText(title)
    end

    local spellID = visuals[1].spellID
    if (spellID and C_Spell.IsSpellPassive(spellID) and SPELL_PASSIVE and GameTooltip_AddHighlightLine) then
        GameTooltip_AddHighlightLine(GameTooltip, SPELL_PASSIVE)
        GameTooltip_AddBlankLineToTooltip(GameTooltip)
    end

    local spends = StepSpends(nodeInfo, visuals)
    for index, visual in ipairs(visuals) do
        local spend = spends[index]
        local spent = spend and spend.spent or 0
        local maxRanks = visual.maxRanks or 1
        if (maxRanks < 1) then
            maxRanks = 1
        end
        if (index > 1 and GameTooltip_AddBlankLineToTooltip) then
            GameTooltip_AddBlankLineToTooltip(GameTooltip)
        end
        local rankLabel = TOOLTIP_TALENT_RANK_CAPSTONE
        if (type(rankLabel) == 'string' and GameTooltip_AddHighlightLine) then
            GameTooltip_AddHighlightLine(GameTooltip, rankLabel:format(index))
        end
        AddApexEntryRanks(GameTooltip, visual.entryID, spent, maxRanks)
    end
    GameTooltip:Show()
end

local function ShowEntryTooltip(button)
    if (button.ownerNode and button.ownerNode.isApex and not button.isStep) then
        ShowApexTooltip(button)
        return
    end
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    if (button.spellID) then
        GameTooltip:SetSpellByID(button.spellID)
    elseif (button.entryName) then
        GameTooltip:SetText(button.entryName)
    end
    GameTooltip:Show()
end

local HideChoicePopup
local ToggleChoicePopup

local function OnEntryClick(button, mouseButton)
    local configID = button.configID
    local nodeID = button.nodeID
    if (not configID or not nodeID) then
        return
    end

    local canEdit = C_ClassTalents.CanEditTalents()
    if (not canEdit) then
        return
    end

    if (mouseButton == 'LeftButton' and IsModifiedClick('CHATLINK') and button.spellID) then
        local link = C_Spell.GetSpellLink(button.spellID)
        if (link and ChatFrameUtil) then
            ChatFrameUtil.InsertLink(link)
        end
        return
    end

    if (tree.viewOnly) then
        return
    end

    local function CommitIfForever()
        if (not EXUI.IsForever() or not C_ClassTalents or not C_ClassTalents.CommitConfig) then
            return
        end
        C_ClassTalents.CommitConfig()
    end

    if (mouseButton == 'RightButton') then
        HideChoicePopup()
        C_Traits.RefundRank(configID, nodeID)
        CommitIfForever()
        return
    end

    if (button.isChoiceOption) then
        if (button.isSelected and button.canPurchase) then
            C_Traits.PurchaseRank(configID, nodeID)
        else
            C_Traits.SetSelection(configID, nodeID, button.entryID)
        end
        HideChoicePopup()
        CommitIfForever()
        return
    end

    if (button.isChoice) then
        ToggleChoicePopup(button.ownerNode)
        return
    end

    HideChoicePopup()
    C_Traits.PurchaseRank(configID, nodeID)
    CommitIfForever()
end

local function ConfigureEntryButton(button)
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:SetScript('OnClick', OnEntryClick)
    button:SetScript('OnEnter', function(self)
        SetHover(self.Highlight, true)
        ShowEntryTooltip(self)
    end)
    button:SetScript('OnLeave', function(self)
        SetHover(self.Highlight, false)
        GameTooltip:Hide()
    end)
end

local function CreateTalentButton(parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(NODE_SIZE, NODE_SIZE)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    button.Icon = icon

    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)

    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetSize(BORDER_SIZE, BORDER_SIZE)
    border:SetPoint('CENTER')
    button.Border = border

    local highlight = button:CreateTexture(nil, 'ARTWORK', nil, 1)
    highlight:SetAllPoints(icon)
    highlight:SetTexture(TEX.hover)
    highlight:SetBlendMode('ADD')
    highlight:AddMaskTexture(mask)
    PrepareHover(highlight)
    button.Highlight = highlight

    local searchIcon = button:CreateTexture(nil, 'OVERLAY', nil, 4)
    searchIcon:SetTexture(TEX.search)
    searchIcon:SetSize(18, 18)
    searchIcon:SetPoint('TOPRIGHT', 4, 4)
    searchIcon:Hide()
    button.SearchIcon = searchIcon

    local arrowLeft = button:CreateTexture(nil, 'OVERLAY', nil, 1)
    arrowLeft:SetTexture(TEX.multiLeft)
    arrowLeft:SetSize(16, 17)
    arrowLeft:SetPoint('LEFT', -8, 0)
    arrowLeft:Hide()
    button.ArrowLeft = arrowLeft

    local arrowRight = button:CreateTexture(nil, 'OVERLAY', nil, 1)
    arrowRight:SetTexture(TEX.multiRight)
    arrowRight:SetSize(16, 17)
    arrowRight:SetPoint('RIGHT', 8, 0)
    arrowRight:Hide()
    button.ArrowRight = arrowRight

    local countBg = button:CreateTexture(nil, 'OVERLAY', nil, 2)
    countBg:SetTexture(TEX.countBg)
    countBg:SetSize(18, 18)
    countBg:SetPoint('BOTTOMRIGHT', 2, -2)
    countBg:Hide()
    button.CountBg = countBg

    local rank = button:CreateFontString(nil, 'OVERLAY')
    rank:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    rank:SetPoint('CENTER', countBg, 'CENTER', 0, 0)
    button.Rank = rank

    ConfigureEntryButton(button)
    return button
end

local function CreateNode(parent)
    local node = CreateFrame('Frame', nil, parent)
    node:SetSize(NODE_SIZE, NODE_SIZE)
    local button = CreateTalentButton(node)
    button:SetAllPoints()
    button.ownerNode = node
    node.button = button
    return node
end

local function IsRefundInvalid(nodeInfo)
    if (not nodeInfo or (nodeInfo.ranksPurchased or 0) <= 0) then
        return false
    end
    if (not nodeInfo.meetsEdgeRequirements) then
        return true
    end
    if (not nodeInfo.canPurchaseRank and nodeInfo.isCascadeRepurchasable) then
        return true
    end
    return false
end

local function CanAffordNode(configID, nodeInfo)
    local costs = C_Traits.GetNodeCost(configID, nodeInfo.ID)
    if (not costs) then
        return true
    end
    local currencyMap = tree.currencyMap
    for _, cost in ipairs(costs) do
        local have = currencyMap and currencyMap[cost.ID] or 0
        if (have < (cost.amount or 0)) then
            return false
        end
    end
    return true
end

local function CanPickNode(configID, nodeInfo, allowSwap)
    if (tree.viewOnly) then
        return false
    end
    if (not nodeInfo or IsRefundInvalid(nodeInfo)) then
        return false
    end
    if (not nodeInfo.meetsEdgeRequirements or not nodeInfo.isAvailable) then
        return false
    end
    if (allowSwap and (nodeInfo.currentRank or 0) > 0) then
        return true
    end
    if (not nodeInfo.canPurchaseRank) then
        return false
    end
    return CanAffordNode(configID, nodeInfo)
end

local function LineState(node)
    local info = node and node.nodeInfo
    if (info and (info.currentRank or 0) > 0) then
        return 'picked'
    end
    if (node and node.configID and CanPickNode(node.configID, info, false)) then
        return 'available'
    end
    return 'unpicked'
end

local function LineColor(source, target)
    local sourceState = LineState(source)
    local targetState = LineState(target)
    if (sourceState == 'picked' and targetState == 'picked') then
        return LINE_COLOR
    end
    if ((sourceState == 'picked' and targetState == 'available') or (targetState == 'picked' and sourceState == 'available')) then
        return LINE_AVAILABLE
    end
    return LINE_INACTIVE
end

local function ApplyTalentButton(button, visual, nodeInfo, picked, showArrows, canPick)
    button.Icon:SetTexture(visual.icon or 134400)
    local invalid = IsRefundInvalid(nodeInfo)
    local dimmed = not invalid and not picked and not canPick
    button.Icon:SetDesaturated(dimmed or invalid)
    if (invalid) then
        button.Icon:SetVertexColor(0.85, 0.15, 0.15)
    elseif (dimmed) then
        button.Icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
    else
        button.Icon:SetVertexColor(1, 1, 1)
    end

    local border = TEX.unselected
    if (invalid) then
        border = TEX.invalid
    elseif (canPick) then
        border = TEX.available
    elseif (picked) then
        border = TEX.selected
    end
    button.Border:SetTexture(border)
    button.Border:SetVertexColor(1, 1, 1)
    local arrowsDimmed = border == TEX.unselected
    local arrowR, arrowG, arrowB = 1, 1, 1
    if (arrowsDimmed) then
        arrowR, arrowG, arrowB = 0.2, 0.2, 0.2
    end
    button.ArrowLeft:SetShown(showArrows)
    button.ArrowLeft:SetDesaturated(arrowsDimmed)
    button.ArrowLeft:SetVertexColor(arrowR, arrowG, arrowB)
    button.ArrowRight:SetShown(showArrows)
    button.ArrowRight:SetDesaturated(arrowsDimmed)
    button.ArrowRight:SetVertexColor(arrowR, arrowG, arrowB)
    button:SetHitRectInsets(showArrows and -10 or 0, showArrows and -10 or 0, 0, 0)

    button.entryID = visual.entryID
    button.spellID = visual.spellID
    button.entryName = visual.name
    button.isSelected = picked
end

local function ApplyRank(button, nodeInfo)
    local theme = EXUI.const.theme
    local rank = nodeInfo.currentRank or 0
    local maxRanks = nodeInfo.maxRanks or 0
    if (rank > 0 and maxRanks > 1) then
        local rankText = tostring(rank)
        button.CountBg:Show()
        button.Rank:SetText(rankText)
        if ((nodeInfo.ranksIncreased or 0) > 0) then
            button.Rank:SetTextColor(ThemeColor(theme.inProgress))
        else
            button.Rank:SetTextColor(1, 1, 1)
        end
        button.Rank:Show()
    else
        button.CountBg:Hide()
        button.Rank:Hide()
    end
end

HideChoicePopup = function()
    local popup = tree.choicePopup
    if (not popup) then
        return
    end
    popup:Hide()
    popup.node = nil
end

ToggleChoicePopup = function(node)
    local popup = tree.choicePopup
    if (not popup or not node or not node.choiceVisuals) then
        return
    end
    if (popup:IsShown() and popup.node == node) then
        HideChoicePopup()
        return
    end

    local visuals = node.choiceVisuals
    local count = #visuals
    popup:SetSize((count * NODE_SIZE) + ((count - 1) * CHOICE_GAP), NODE_SIZE)
    popup:ClearAllPoints()
    popup:SetPoint('BOTTOM', node, 'TOP', 0, 8)
    local level = popup:GetParent():GetFrameLevel() + 50
    popup:SetFrameLevel(level)

    local nodeInfo = node.nodeInfo
    local selectedID = node.selectedEntryID
    for index, button in ipairs(popup.buttons) do
        local visual = visuals[index]
        if (not visual) then
            button:Hide()
        else
            local picked = selectedID == visual.entryID and (nodeInfo.currentRank or 0) > 0
            local canPick = not picked and CanPickNode(node.configID, nodeInfo, true)
            ApplyTalentButton(button, visual, nodeInfo, picked, false, canPick)
            button.CountBg:Hide()
            button.Rank:Hide()
            button.configID = node.configID
            button.nodeID = nodeInfo.ID
            button.isChoice = false
            button.isChoiceOption = true
            button.canPurchase = CanPickNode(node.configID, nodeInfo, false)
            button:SetFrameLevel(level + 1)
            button:ClearAllPoints()
            button:SetPoint('LEFT', (index - 1) * (NODE_SIZE + CHOICE_GAP), 0)
            button:Show()
        end
    end

    popup.node = node
    popup:Show()
end

local function AcquireNode(self)
    local node = self.nodes[self.nodeCount]
    if (not node) then
        node = CreateNode(self.canvas)
        self.nodes[self.nodeCount] = node
    end
    node:Show()
    return node
end

local function AcquireEdge(self)
    local edge = self.edges[self.edgeCount]
    if (not edge) then
        edge = self.canvas:CreateLine(nil, 'BACKGROUND')
        edge:SetThickness(2)
        self.edges[self.edgeCount] = edge
    end
    edge:Show()
    return edge
end

local function ShouldDrawNode(nodeInfo)
    if (not nodeInfo or not nodeInfo.isVisible) then
        return false
    end
    if (nodeInfo.type == Enum.TraitNodeType.SubTreeSelection) then
        return false
    end
    if (nodeInfo.subTreeID and not nodeInfo.subTreeActive) then
        return false
    end
    return true
end

local function CreateStepButton(parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetSize(STEP_BORDER, STEP_BORDER)
    button.isStep = true
    button:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    button:SetScript('OnEnter', function(self)
        ShowEntryTooltip(self)
    end)
    button:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
    button:SetScript('OnClick', function(self, mouseButton)
        if (self.ownerButton) then
            OnEntryClick(self.ownerButton, mouseButton)
        end
    end)

    local icon = button:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(STEP_ICON, STEP_ICON)
    icon:SetPoint('CENTER')
    button.Icon = icon

    local mask = button:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)

    local border = button:CreateTexture(nil, 'OVERLAY')
    border:SetSize(STEP_BORDER, STEP_BORDER)
    border:SetPoint('CENTER')
    border:SetTexture(TEX.unselected)
    button.Border = border
    button:Hide()
    return button
end

local function EnsureSteps(node)
    if (node.steps) then
        return node.steps
    end
    local steps = {}
    for index = 1, STEP_COUNT do
        local step = CreateStepButton(node)
        local anchor = STEP_POINTS[index]
        step:SetPoint('CENTER', node, anchor[1], anchor[2], anchor[3])
        step.ownerButton = node.button
        steps[index] = step
    end
    node.steps = steps
    return steps
end

local function HideSteps(node)
    if (not node.steps) then
        return
    end
    for index = 1, #node.steps do
        node.steps[index]:Hide()
    end
end

local function UpdateSteps(node)
    if (not node.isApex or not node.apexVisuals or not node.nodeInfo or not node.configID) then
        HideSteps(node)
        return
    end

    local steps = EnsureSteps(node)
    local spends = StepSpends(node.nodeInfo, node.apexVisuals)
    local canBuy = CanPickNode(node.configID, node.nodeInfo, false)
    local level = node.button and (node.button:GetFrameLevel() + 2) or (node:GetFrameLevel() + 5)
    for index = 1, STEP_COUNT do
        local step = steps[index]
        local visual = node.apexVisuals[index]
        local spend = spends[index]
        if (not visual or not spend) then
            step:Hide()
        else
            step.Icon:SetTexture(visual.icon or 134400)
            step.spellID = visual.spellID
            step.entryName = visual.name
            local filled = spend.spent > 0
            local available = not filled and spend.active and canBuy
            if (filled) then
                step.Border:SetTexture(TEX.selected)
                step.Icon:SetDesaturated(false)
                step.Icon:SetVertexColor(1, 1, 1)
            elseif (available) then
                step.Border:SetTexture(TEX.available)
                step.Icon:SetDesaturated(false)
                step.Icon:SetVertexColor(1, 1, 1)
            else
                step.Border:SetTexture(TEX.unselected)
                step.Icon:SetDesaturated(true)
                step.Icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
            end
            step:SetFrameLevel(level)
            step:Show()
        end
    end
end

local function UpdateNode(self, node, configID, nodeInfo)
    local selectedID = SelectedEntryID(nodeInfo)
    local visuals = {}
    for _, entryID in ipairs(nodeInfo.entryIDs) do
        local visual = EntryVisual(configID, entryID)
        if (visual) then
            visuals[#visuals + 1] = visual
        end
    end
    if (#visuals == 0) then
        HideSteps(node)
        node:Hide()
        return false
    end

    local isApex = IsApexNode(nodeInfo, visuals[1])
    local isChoice = nodeInfo.type == Enum.TraitNodeType.Selection and #visuals > 1
    local shown = visuals[1]
    if (not isApex and selectedID) then
        for _, visual in ipairs(visuals) do
            if (visual.entryID == selectedID) then
                shown = visual
                break
            end
        end
    end

    local nodeSize = isApex and APEX_NODE_SIZE or NODE_SIZE
    local borderSize = isApex and APEX_BORDER_SIZE or BORDER_SIZE
    if (EXUI.IsForever() and not isApex) then
        nodeSize = 32
        borderSize = nodeSize * (96 / 82)
    end
    node.baseSize = nodeSize
    node.baseBorder = borderSize
    node:SetScale(1)
    node:SetSize(nodeSize, nodeSize)
    node.button.Border:SetSize(borderSize, borderSize)
    node.nodeID = nodeInfo.ID
    node.configID = configID
    node.nodeInfo = nodeInfo
    node.selectedEntryID = selectedID
    node.choiceVisuals = isChoice and visuals or nil
    node.shownVisual = shown
    node.isChoice = isChoice
    node.isApex = isApex
    node.apexVisuals = isApex and visuals or nil
    node.subTreeID = nodeInfo.subTreeID
    node.rawX = nodeInfo.posX
    node.rawY = nodeInfo.posY
    node.groupIDs = nil
    if (nodeInfo.groupIDs) then
        local groupIDs = {}
        for _, groupID in ipairs(nodeInfo.groupIDs) do
            groupIDs[#groupIDs + 1] = groupID
        end
        if (#groupIDs > 0) then
            node.groupIDs = groupIDs
        end
    end
    local x = nodeInfo.posX / 10
    local y = -nodeInfo.posY / 10
    if (EXUI.IsForever()) then
        local panX, panY = ForeverPan()
        x = x - panX
        y = y + panY
    end
    PlaceNode(node, x, y)

    local button = node.button
    local picked = (nodeInfo.currentRank or 0) > 0
    local canPick = CanPickNode(configID, nodeInfo, false)
    ApplyTalentButton(button, shown, nodeInfo, picked, isChoice, canPick)
    ApplyRank(button, nodeInfo)
    UpdateSteps(node)
    button.configID = configID
    button.nodeID = nodeInfo.ID
    button.isChoice = isChoice
    button.isChoiceOption = false
    button.canPurchase = CanPickNode(configID, nodeInfo, false)

    return true
end

local function PaintNode(node)
    local button = node.button
    local nodeInfo = node.nodeInfo
    local shown = node.shownVisual
    if (not button or not nodeInfo or not shown or not node.configID) then
        return
    end
    local picked = (nodeInfo.currentRank or 0) > 0
    local canPick = CanPickNode(node.configID, nodeInfo, false)
    ApplyTalentButton(button, shown, nodeInfo, picked, node.isChoice, canPick)
    ApplyRank(button, nodeInfo)
    UpdateSteps(node)
end

tree.GetHeroOptions = function(self, configID, specID)
    local options = {}
    if (not configID) then
        return options
    end

    local subTreeIDs = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, specID)
    if (not subTreeIDs) then
        return options
    end

    local nodeIDs = self.nodeIDs
    for _, subTreeID in ipairs(subTreeIDs) do
        local subTreeInfo = C_Traits.GetSubTreeInfo(configID, subTreeID)
        if (subTreeInfo) then
            local nodeID, entryID
            for _, candidateID in ipairs(nodeIDs or {}) do
                local nodeInfo = C_Traits.GetNodeInfo(configID, candidateID)
                if (nodeInfo and nodeInfo.type == Enum.TraitNodeType.SubTreeSelection) then
                    for _, candidateEntryID in ipairs(nodeInfo.entryIDs) do
                        local entryInfo = C_Traits.GetEntryInfo(configID, candidateEntryID)
                        if (entryInfo and entryInfo.subTreeID == subTreeID) then
                            nodeID = candidateID
                            entryID = candidateEntryID
                            break
                        end
                    end
                end
                if (nodeID) then
                    break
                end
            end

            options[#options + 1] = {
                subTreeID = subTreeID,
                name = subTreeInfo.name or 'Hero',
                nodeID = nodeID,
                entryID = entryID,
                isActive = subTreeInfo.isActive,
            }
        end
    end

    return options
end

local function BoundsOf(nodes)
    local minX, maxX, minY, maxY
    for _, node in ipairs(nodes) do
        local left = node.posX - node:GetWidth() / 2
        local right = node.posX + node:GetWidth() / 2
        minX = minX and math.min(minX, left) or left
        maxX = maxX and math.max(maxX, right) or right
        minY = minY and math.min(minY, node.posY) or node.posY
        maxY = maxY and math.max(maxY, node.posY) or node.posY
    end
    return minX, maxX, minY, maxY
end

local function LayoutHeroColumn(self, configID)
    local classNodes = {}
    local specNodes = {}
    local heroNodes = {}
    local splitXs = {}

    for index = 1, self.nodeCount do
        local node = self.nodes[index]
        if (node:IsShown() and node.subTreeID) then
            heroNodes[#heroNodes + 1] = node
        elseif (node:IsShown()) then
            splitXs[#splitXs + 1] = node.posX
        end
    end

    if (#heroNodes == 0 or #splitXs < 2) then
        return
    end

    table.sort(splitXs)
    local split
    local bestGap = 0
    for index = 2, #splitXs do
        local gap = splitXs[index] - splitXs[index - 1]
        if (gap > bestGap) then
            bestGap = gap
            split = (splitXs[index] + splitXs[index - 1]) / 2
        end
    end

    if (not split or bestGap < 80) then
        local currencies = C_Traits.GetTreeCurrencyInfo(configID, self.treeID, false)
        local specCurrency = currencies and currencies[2] and currencies[2].traitCurrencyID
        for index = 1, self.nodeCount do
            local node = self.nodes[index]
            if (node:IsShown() and not node.subTreeID) then
                local costs = C_Traits.GetNodeCost(configID, node.nodeID)
                local currencyID = costs and costs[1] and costs[1].ID
                if (currencyID == specCurrency) then
                    specNodes[#specNodes + 1] = node
                else
                    classNodes[#classNodes + 1] = node
                end
            end
        end
    else
        for index = 1, self.nodeCount do
            local node = self.nodes[index]
            if (node:IsShown() and not node.subTreeID) then
                if (node.posX <= split) then
                    classNodes[#classNodes + 1] = node
                else
                    specNodes[#specNodes + 1] = node
                end
            end
        end
    end

    if (#classNodes == 0 or #specNodes == 0) then
        return
    end

    local classLeft, classRight, classBottom, classTop = BoundsOf(classNodes)
    local specLeft, _, specBottom, specTop = BoundsOf(specNodes)
    if (not classLeft or not specLeft) then
        return
    end

    local heroMinX, heroMaxX, heroMinY, heroMaxY
    local heroLocal = {}
    for _, node in ipairs(heroNodes) do
        local subTree = C_Traits.GetSubTreeInfo(configID, node.subTreeID)
        local localX = node.posX
        local localY = node.posY
        if (subTree) then
            localX = (node.rawX - subTree.posX) / 10
            localY = -(node.rawY - subTree.posY) / 10
        end
        heroLocal[node] = { localX, localY }
        heroMinX = heroMinX and math.min(heroMinX, localX) or localX
        heroMaxX = heroMaxX and math.max(heroMaxX, localX) or localX
        heroMinY = heroMinY and math.min(heroMinY, localY) or localY
        heroMaxY = heroMaxY and math.max(heroMaxY, localY) or localY
    end

    local heroSpan = (heroMaxX - heroMinX) + NODE_SIZE
    local needed = heroSpan + HERO_GAP
    local gap = specLeft - classRight
    if (gap < needed) then
        local shift = needed - gap
        for _, node in ipairs(specNodes) do
            PlaceNode(node, node.posX + shift, node.posY)
        end
        specLeft = specLeft + shift
    end

    local centerX = (classRight + specLeft) / 2
    local heroMidX = (heroMinX + heroMaxX) / 2
    local treeMidY = (math.max(classTop, specTop) + math.min(classBottom, specBottom)) / 2
    local heroMidY = (heroMinY + heroMaxY) / 2

    for _, node in ipairs(heroNodes) do
        local localPos = heroLocal[node]
        PlaceNode(node, centerX + (localPos[1] - heroMidX), treeMidY + (localPos[2] - heroMidY))
    end
end

tree.Create = function(self, parent)
    local clip = CreateFrame('Frame', nil, parent)
    clip:SetClipsChildren(true)
    self.clip = clip

    local canvas = CreateFrame('Frame', nil, clip)
    canvas:SetSize(4000, 4000)
    self.canvas = canvas

    local popup = CreateFrame('Frame', nil, canvas)
    popup:SetFrameLevel(40)
    popup:Hide()
    popup.buttons = {}
    for index = 1, 3 do
        local button = CreateTalentButton(popup)
        button.isChoiceOption = true
        popup.buttons[index] = button
    end
    self.choicePopup = popup

    clip:SetScript('OnSizeChanged', function()
        FitToClip(self)
    end)

    return clip
end

tree.EnsureSearch = function(self)
    if (self.searchController or not C_AddOns.LoadAddOn('Blizzard_PlayerSpells')) then
        return
    end
    if (not SpellSearchControllerMixin or not TraitSearchSourceMixin) then
        return
    end

    local source = CreateAndInitFromMixin(TraitSearchSourceMixin,
        function()
            return self:GetSearchableNodes()
        end,
        function(entryID)
            return self:GetDefinitionInfoForEntry(entryID)
        end,
        function(entryID)
            return self:GetSubTreeInfoForEntry(entryID)
        end
    )
    local sources = {}
    sources[SpellSearchUtil.SourceType.Trait] = source
    self.searchController = CreateAndInitFromMixin(SpellSearchControllerMixin, sources)
end

tree.GetSearchableNodes = function(self)
    local map = {}
    local configID = self.searchConfigID
    local nodeIDs = self.nodeIDs
    if (not configID or not nodeIDs) then
        return map
    end

    local available = {}
    if (self.searchSpecID) then
        local subTreeIDs = C_ClassTalents.GetHeroTalentSpecsForClassSpec(configID, self.searchSpecID)
        if (subTreeIDs) then
            for _, subTreeID in ipairs(subTreeIDs) do
                available[subTreeID] = true
            end
        end
    end

    for _, nodeID in ipairs(nodeIDs) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        if (info and info.type ~= Enum.TraitNodeType.SubTreeSelection) then
            if (not info.subTreeID or available[info.subTreeID]) then
                map[nodeID] = info
            end
        end
    end
    return map
end

tree.GetDefinitionInfoForEntry = function(self, entryID)
    local configID = self.searchConfigID
    if (not configID or not entryID) then
        return nil
    end
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if (entryInfo and entryInfo.definitionID) then
        return C_Traits.GetDefinitionInfo(entryInfo.definitionID)
    end
    return nil
end

tree.GetSubTreeInfoForEntry = function(self, entryID)
    local configID = self.searchConfigID
    if (not configID or not entryID) then
        return nil
    end
    local entryInfo = C_Traits.GetEntryInfo(configID, entryID)
    if (entryInfo and entryInfo.subTreeID) then
        return C_Traits.GetSubTreeInfo(configID, entryInfo.subTreeID)
    end
    return nil
end

tree.ApplySearch = function(self)
    self.matchedSubTrees = {}
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown()) then
            PaintNode(node)
        end
        if (node.button) then
            node.button.SearchIcon:Hide()
            if (not node.button:IsMouseOver()) then
                local highlight = node.button.Highlight
                highlight.HoverGroup:Stop()
                highlight.hoverTarget = 0
                highlight:SetAlpha(0)
            end
        end
    end

    local searching = self.searchText ~= nil and self.searchController ~= nil
    if (not searching) then
        return
    end

    local nodes = self:GetSearchableNodes()
    local matches = {}
    for nodeID, info in pairs(nodes) do
        local matchType = self.searchController:GetMatchTypeForSourceTypeEntry(SpellSearchUtil.SourceType.Trait, nodeID)
        if (matchType) then
            matches[nodeID] = true
            if (info.subTreeID) then
                self.matchedSubTrees[info.subTreeID] = true
            end
        end
    end

    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        local button = node.button
        if (button and node:IsShown()) then
            local match = node.nodeID and matches[node.nodeID]
            if (match) then
                button.Border:SetTexture(TEX.available)
                button.Border:SetVertexColor(1, 1, 1)
                button.SearchIcon:Show()
            else
                button.SearchIcon:Hide()
                button.Icon:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
                button.Border:SetVertexColor(UNPICKED_COLOR, UNPICKED_COLOR, UNPICKED_COLOR)
            end
        end
    end
end

tree.SetSearchText = function(self, text)
    text = strtrim(text or '')
    if (text == '') then
        self.searchText = nil
        if (self.searchController) then
            self.searchController:ClearActiveSearchResults()
        end
    else
        self:EnsureSearch()
        self.searchText = text
        if (self.searchController) then
            self.searchController:ActivateSearchFilter(SpellSearchUtil.FilterType.Text, text)
        end
    end
    self:ApplySearch()
    local talents = EXUI:GetModule('talents-window')
    if (talents.ApplyHeroSearch) then
        talents:ApplyHeroSearch()
    end
end

local function HideHeaders(self)
    self.headerCount = 0
    if (not self.headers) then
        return
    end
    for _, header in ipairs(self.headers) do
        header:Hide()
    end
end

local function AcquireHeader(self)
    self.headers = self.headers or {}
    self.headerCount = (self.headerCount or 0) + 1
    local header = self.headers[self.headerCount]
    if (header) then
        return header
    end
    header = CreateFrame('Frame', nil, self.canvas)
    header:SetSize(180, 44)
    local icon = header:CreateTexture(nil, 'ARTWORK')
    icon:SetSize(HEADER_ICON, HEADER_ICON)
    icon:SetPoint('LEFT', 0, 0)
    header.Icon = icon
    local mask = header:CreateMaskTexture()
    mask:SetAllPoints(icon)
    mask:SetTexture(TEX.mask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    icon:AddMaskTexture(mask)
    local border = header:CreateTexture(nil, 'OVERLAY')
    local borderSize = HEADER_ICON * (96 / 82)
    border:SetSize(borderSize, borderSize)
    border:SetPoint('CENTER', icon, 'CENTER')
    border:SetTexture(TEX.selected)
    header.Border = border
    local name = header:CreateFontString(nil, 'OVERLAY')
    name:SetFont(EXFrames.assets.font.default(), 14, 'OUTLINE')
    name:SetPoint('LEFT', border, 'RIGHT', 6, 8)
    name:SetJustifyH('LEFT')
    name:SetTextColor(1, 1, 1, 1)
    header.Name = name
    local points = header:CreateFontString(nil, 'OVERLAY')
    points:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    points:SetPoint('LEFT', border, 'RIGHT', 6, -8)
    points:SetJustifyH('LEFT')
    points:SetTextColor(1, 0.82, 0, 1)
    header.Points = points
    self.headers[self.headerCount] = header
    return header
end

local function NodeInGroup(node, groupID)
    local groupIDs = node.groupIDs
    if (not groupIDs) then
        return false
    end
    for _, id in ipairs(groupIDs) do
        if (id == groupID) then
            return true
        end
    end
    return false
end

local function PlaceHeader(self, displayInfo, spent, nodes)
    if (not nodes or #nodes == 0) then
        return
    end
    local left, _, _, top = BoundsOf(nodes)
    if (not left or not top) then
        return
    end
    local topEdge = top
    local leftEdge = left
    for _, node in ipairs(nodes) do
        local nodeScale = node:GetScale() or 1
        topEdge = math.max(topEdge, node.posY + node:GetHeight() * nodeScale / 2)
        leftEdge = math.min(leftEdge, node.posX - node:GetWidth() * nodeScale / 2)
    end
    left = leftEdge
    top = topEdge
    local header = AcquireHeader(self)
    header.Icon:SetTexture((displayInfo and displayInfo.icon) or 134400)
    header.Name:SetText((displayInfo and displayInfo.displayName) or '')
    header.Points:SetText(tostring(spent or 0))
    local textWidth = header.Name:GetStringWidth()
    if (textWidth < 40) then
        textWidth = 40
    end
    local borderSize = HEADER_ICON * (96 / 82)
    local width = borderSize + 6 + textWidth
    local height = math.max(44, borderSize)
    header:SetSize(width, height)
    header:ClearAllPoints()
    local headerGap = HEADER_GAP + FOREVER_TALENT_DROP
    header:SetPoint('BOTTOMLEFT', self.canvas, 'TOPLEFT', left, top + headerGap)
    header.left = left
    header.right = left + width
    header.bottom = top + headerGap
    header.top = top + headerGap + height
    header:Show()
end

local function ColumnNodes(self)
    local nodes = {}
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown()) then
            nodes[#nodes + 1] = node
        end
    end
    table.sort(nodes, function(a, b)
        return a.posX < b.posX
    end)
    local columns = {}
    local current = {}
    local lastX
    for _, node in ipairs(nodes) do
        if (lastX and node.posX - lastX > 80 and #current > 0) then
            columns[#columns + 1] = current
            current = {}
        end
        current[#current + 1] = node
        lastX = node.posX
    end
    if (#current > 0) then
        columns[#columns + 1] = current
    end
    return columns
end

local function LayoutTreeHeaders(self, configID, treeID)
    HideHeaders(self)
    if (not EXUI.IsForever() or not configID or not treeID or not C_Traits.GetGroupDisplayInfoByTreeID) then
        return
    end
    local displayInfos = C_Traits.GetGroupDisplayInfoByTreeID(treeID)
    if (not displayInfos or #displayInfos == 0) then
        return
    end
    table.sort(displayInfos, function(a, b)
        return (a.orderIndex or 0) < (b.orderIndex or 0)
    end)

    local currencyByGroup = {}
    if (C_Traits.GetGroupCurrencyInfo) then
        local groupIDs = {}
        for _, info in ipairs(displayInfos) do
            groupIDs[#groupIDs + 1] = info.groupID
        end
        local groupInfos = C_Traits.GetGroupCurrencyInfo(configID, groupIDs)
        if (groupInfos) then
            for _, groupInfo in ipairs(groupInfos) do
                currencyByGroup[groupInfo.traitNodeGroupID] = groupInfo
            end
        end
    end

    local function SpentFor(groupID)
        local groupInfo = currencyByGroup[groupID]
        local currency = groupInfo and groupInfo.currencyInfos and groupInfo.currencyInfos[1]
        return currency and currency.spent or 0
    end

    local placed = false
    for _, displayInfo in ipairs(displayInfos) do
        local nodes = {}
        for index = 1, self.nodeCount or 0 do
            local node = self.nodes[index]
            if (node:IsShown() and NodeInGroup(node, displayInfo.groupID)) then
                nodes[#nodes + 1] = node
            end
        end
        if (#nodes > 0) then
            PlaceHeader(self, displayInfo, SpentFor(displayInfo.groupID), nodes)
            placed = true
        end
    end
    if (placed) then
        return
    end

    local columns = ColumnNodes(self)
    for index, nodes in ipairs(columns) do
        local displayInfo = displayInfos[index] or displayInfos[1]
        local spent = displayInfo and SpentFor(displayInfo.groupID) or 0
        PlaceHeader(self, displayInfo, spent, nodes)
    end
end

local function ApplyForeverNodeScale(node, scale)
    node:SetScale(1)
    local size = (node.baseSize or NODE_SIZE) * scale
    node:SetSize(size, size)
    local button = node.button
    if (button and button.Border) then
        local border = (node.baseBorder or BORDER_SIZE) * scale
        button.Border:SetSize(border, border)
    end
end

local function NodeExtent(node)
    local size = node.baseSize or NODE_SIZE
    local border = node.baseBorder or size
    if (border > size) then
        size = border
    end
    return size / 2
end

local function GroupBounds(nodes)
    local minX, minY, maxX, maxY
    for _, node in ipairs(nodes) do
        if (node.layoutX and node.layoutY) then
            local extent = NodeExtent(node)
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                node.layoutX - extent, node.layoutY - extent, node.layoutX + extent, node.layoutY + extent)
        end
    end
    return minX, minY, maxX, maxY
end

local function MergeClosestTrees(trees)
    while (#trees > 3) do
        local bestIndex = 1
        local bestGap = math.huge
        for index = 1, #trees - 1 do
            local _, _, leftMax = GroupBounds(trees[index])
            local rightMin = GroupBounds(trees[index + 1])
            local gap = (rightMin or 0) - (leftMax or 0)
            if (gap < bestGap) then
                bestGap = gap
                bestIndex = index
            end
        end
        local merged = {}
        for _, node in ipairs(trees[bestIndex]) do
            merged[#merged + 1] = node
        end
        for _, node in ipairs(trees[bestIndex + 1]) do
            merged[#merged + 1] = node
        end
        trees[bestIndex] = merged
        table.remove(trees, bestIndex + 1)
    end
    return trees
end

local function CollectForeverTrees(self)
    local trees = {}
    local assigned = {}
    local displayInfos = self.treeID and C_Traits.GetGroupDisplayInfoByTreeID and
        C_Traits.GetGroupDisplayInfoByTreeID(self.treeID)
    if (displayInfos and #displayInfos > 0) then
        table.sort(displayInfos, function(a, b)
            return (a.orderIndex or 0) < (b.orderIndex or 0)
        end)
        for _, info in ipairs(displayInfos) do
            local nodes = {}
            for index = 1, self.nodeCount or 0 do
                local node = self.nodes[index]
                if (node:IsShown() and node.layoutX and not assigned[node] and NodeInGroup(node, info.groupID)) then
                    assigned[node] = true
                    nodes[#nodes + 1] = node
                end
            end
            if (#nodes > 0) then
                trees[#trees + 1] = nodes
            end
        end
    end

    local loose = {}
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown() and node.layoutX and not assigned[node]) then
            loose[#loose + 1] = node
        end
    end

    if (#trees >= 2) then
        table.sort(trees, function(a, b)
            local leftA = GroupBounds(a)
            local leftB = GroupBounds(b)
            return (leftA or 0) < (leftB or 0)
        end)
        MergeClosestTrees(trees)
        for _, node in ipairs(loose) do
            local best = trees[1]
            local bestDist = math.huge
            for _, group in ipairs(trees) do
                local minX, _, maxX = GroupBounds(group)
                local center = ((minX or 0) + (maxX or 0)) / 2
                local dist = math.abs(node.layoutX - center)
                if (dist < bestDist) then
                    bestDist = dist
                    best = group
                end
            end
            best[#best + 1] = node
        end
        return trees
    end

    local nodes = loose
    if (#nodes < 2) then
        return nil
    end
    table.sort(nodes, function(a, b)
        return a.layoutX < b.layoutX
    end)
    local gaps = {}
    for index = 1, #nodes - 1 do
        gaps[#gaps + 1] = { index = index, gap = nodes[index + 1].layoutX - nodes[index].layoutX }
    end
    table.sort(gaps, function(a, b)
        return a.gap > b.gap
    end)
    local cuts = {}
    for index = 1, math.min(2, #gaps) do
        if (gaps[index].gap > 0) then
            cuts[#cuts + 1] = gaps[index].index
        end
    end
    table.sort(cuts)
    trees = {}
    local startIndex = 1
    for _, cut in ipairs(cuts) do
        local group = {}
        for index = startIndex, cut do
            group[#group + 1] = nodes[index]
        end
        trees[#trees + 1] = group
        startIndex = cut + 1
    end
    local tail = {}
    for index = startIndex, #nodes do
        tail[#tail + 1] = nodes[index]
    end
    if (#tail > 0) then
        trees[#trees + 1] = tail
    end
    if (#trees < 2) then
        return nil
    end
    return trees
end

tree.FitForever = function(self)
    if (not self.canvas or not self.clip) then
        return
    end
    local clipWidth = self.clip:GetWidth()
    local clipHeight = self.clip:GetHeight()
    if (clipWidth <= 1 or clipHeight <= 1) then
        return
    end

    local minX, minY, maxX, maxY
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown() and node.layoutX and node.layoutY) then
            local half = (node.baseSize or NODE_SIZE) / 2
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                node.layoutX - half, node.layoutY - half, node.layoutX + half, node.layoutY + half)
        end
    end
    if (not minX) then
        return
    end

    local pad = 20
    local headerRoom = 56
    local trees = CollectForeverTrees(self)
    local scale

    self.canvas:SetScale(1)
    self.canvas:ClearAllPoints()
    self.canvas:SetPoint('TOPLEFT', self.clip, 'TOPLEFT', 0, 0)

    if (trees and #trees >= 2) then
        local bounds = {}
        local maxTreeW = 1
        local maxTreeH = 1
        for index, group in ipairs(trees) do
            local groupMinX, groupMinY, groupMaxX, groupMaxY = GroupBounds(group)
            bounds[index] = { groupMinX, groupMinY, groupMaxX, groupMaxY }
            maxTreeW = math.max(maxTreeW, (groupMaxX or 0) - (groupMinX or 0))
            maxTreeH = math.max(maxTreeH, (groupMaxY or 0) - (groupMinY or 0))
        end
        local slotWidth = clipWidth / #trees
        scale = math.min((slotWidth - pad * 2) / maxTreeW, (clipHeight - pad * 2 - headerRoom) / maxTreeH) * 0.82
        local visualHeight = maxTreeH * scale
        local topInset = (clipHeight - visualHeight - headerRoom) / 2
        if (topInset < pad) then
            topInset = pad
        end
        for index, group in ipairs(trees) do
            local groupMinX, _, _, groupMaxY = bounds[index][1], bounds[index][2], bounds[index][3], bounds[index][4]
            local treeWidth = (bounds[index][3] - bounds[index][1]) * scale
            local slotLeft = (index - 1) * slotWidth
            local originX = slotLeft + (slotWidth - treeWidth) / 2
            for _, node in ipairs(group) do
                if (node:IsShown() and node.layoutX and node.layoutY) then
                    ApplyForeverNodeScale(node, scale)
                    local x = originX + (node.layoutX - groupMinX) * scale
                    local y = -(topInset + headerRoom + FOREVER_TALENT_DROP) + (node.layoutY - groupMaxY) * scale
                    SetNodePosition(node, x, y)
                end
            end
        end
    else
        local contentWidth = math.max(maxX - minX, 1)
        local contentHeight = math.max(maxY - minY, 1)
        scale = math.min((clipWidth - pad * 2) / contentWidth, (clipHeight - pad * 2 - headerRoom) / contentHeight) * 0.82
        local visualWidth = contentWidth * scale
        local visualHeight = contentHeight * scale
        local originX = (clipWidth - visualWidth) / 2
        if (originX < pad) then
            originX = pad
        end
        local topInset = (clipHeight - visualHeight - headerRoom) / 2
        if (topInset < pad) then
            topInset = pad
        end
        for index = 1, self.nodeCount or 0 do
            local node = self.nodes[index]
            if (node:IsShown() and node.layoutX and node.layoutY) then
                ApplyForeverNodeScale(node, scale)
                local x = originX + (node.layoutX - minX) * scale
                local y = -(topInset + headerRoom + FOREVER_TALENT_DROP) + (node.layoutY - maxY) * scale
                SetNodePosition(node, x, y)
            end
        end
    end

    if (self.edges) then
        local thickness = math.max(1, 2 * scale)
        for index = 1, self.edgeCount or 0 do
            local edge = self.edges[index]
            if (edge) then
                edge:SetThickness(thickness)
            end
        end
    end

    LayoutTreeHeaders(self, self.layoutConfigID, self.treeID)
    for index = 1, self.headerCount or 0 do
        local header = self.headers and self.headers[index]
        if (header) then
            header:SetScale(1)
        end
    end
end

local function ForeverColumns(self)
    local grouped = {}
    local groupOrder = {}
    local loose = {}
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown() and node.layoutX) then
            local groupID = node.groupIDs and node.groupIDs[1]
            if (groupID) then
                if (not grouped[groupID]) then
                    grouped[groupID] = {}
                    groupOrder[#groupOrder + 1] = groupID
                end
                grouped[groupID][#grouped[groupID] + 1] = node
            else
                loose[#loose + 1] = node
            end
        end
    end
    if (#groupOrder >= 2) then
        table.sort(groupOrder, function(a, b)
            local function LeftOf(id)
                local left
                for _, node in ipairs(grouped[id]) do
                    left = left and math.min(left, node.layoutX) or node.layoutX
                end
                return left or 0
            end
            return LeftOf(a) < LeftOf(b)
        end)
        local columns = {}
        for _, groupID in ipairs(groupOrder) do
            columns[#columns + 1] = grouped[groupID]
        end
        return columns
    end

    local nodes = loose
    if (#nodes == 0) then
        for index = 1, self.nodeCount or 0 do
            local node = self.nodes[index]
            if (node:IsShown() and node.layoutX) then
                nodes[#nodes + 1] = node
            end
        end
    end
    table.sort(nodes, function(a, b)
        return a.layoutX < b.layoutX
    end)
    local columns = {}
    local current = {}
    local lastX
    for _, node in ipairs(nodes) do
        if (lastX and node.layoutX - lastX > 80 and #current > 0) then
            columns[#columns + 1] = current
            current = {}
        end
        current[#current + 1] = node
        lastX = node.layoutX
    end
    if (#current > 0) then
        columns[#columns + 1] = current
    end
    return columns
end

local function LayoutForeverColumns(self)
    if (not self.clip) then
        return
    end
    local clipWidth = self.clip:GetWidth()
    local clipHeight = self.clip:GetHeight()
    if (clipWidth <= 1 or clipHeight <= 1) then
        return
    end
    local columns = ForeverColumns(self)
    local count = #columns
    if (count == 0) then
        return
    end
    local columnWidth = clipWidth / count
    local headerRoom = 56
    for index, nodes in ipairs(columns) do
        local minX, minY, maxX, maxY
        for _, node in ipairs(nodes) do
            local halfW = node:GetWidth() / 2
            local halfH = node:GetHeight() / 2
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                node.layoutX - halfW, node.layoutY - halfH, node.layoutX + halfW, node.layoutY + halfH)
        end
        if (minX) then
            local contentWidth = math.max(maxX - minX, 1)
            local contentHeight = math.max(maxY - minY, 1)
            local availWidth = math.max(columnWidth - FOREVER_COLUMN_PAD * 2, 1)
            local availHeight = math.max(clipHeight - FOREVER_COLUMN_PAD * 2 - headerRoom, 1)
            local scale = math.min(availWidth / contentWidth, availHeight / contentHeight)
            local scaledWidth = contentWidth * scale
            local scaledHeight = contentHeight * scale
            local originX = (index - 1) * columnWidth + (columnWidth - scaledWidth) / 2
            local originY = -headerRoom - FOREVER_COLUMN_PAD - (availHeight - scaledHeight) / 2
            for _, node in ipairs(nodes) do
                local x = originX + (node.layoutX - minX) * scale
                local y = originY + (node.layoutY - maxY) * scale
                SetNodePosition(node, x, y)
            end
        end
    end
end

tree.EnsureBackground = function(self)
    if (self.background or not self.canvas) then
        return
    end
    local texture = self.canvas:CreateTexture(nil, 'BACKGROUND')
    texture:Hide()
    self.background = texture
end

tree.SetBackground = function(self, atlas)
    self.backgroundAtlas = atlas
    if (not EXUI.IsForever()) then
        return
    end
    self:EnsureBackground()
    if (not self.background) then
        return
    end
    if (not atlas or not C_Texture.GetAtlasInfo(atlas)) then
        self.background:Hide()
        self.background.left = nil
        return
    end
    self.background:Show()
end

tree.SetViewOnly = function(self, viewOnly)
    self.viewOnly = viewOnly and true or false
end

local function LayoutForeverBackground(self)
    local texture = self.background
    if (not EXUI.IsForever() or not texture or not texture:IsShown()) then
        if (texture) then
            texture.left = nil
        end
        return
    end
    local info = self.backgroundAtlas and C_Texture.GetAtlasInfo(self.backgroundAtlas)
    if (not info) then
        texture:Hide()
        texture.left = nil
        return
    end

    local minX, minY, maxX, maxY
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown()) then
            local halfW = node:GetWidth() / 2
            local halfH = node:GetHeight() / 2
            minX, minY, maxX, maxY = ExpandBounds(minX, minY, maxX, maxY,
                node.posX - halfW, node.posY - halfH, node.posX + halfW, node.posY + halfH)
        end
    end
    if (not minX) then
        texture:Hide()
        texture.left = nil
        return
    end

    local artWidth = info.width or 0
    local artHeight = info.height or 0
    local contentWidth = math.max(maxX - minX, 1)
    local drawWidth = contentWidth
    local drawHeight = contentWidth
    if (artWidth >= 1 and artHeight >= 1) then
        drawHeight = contentWidth * (artHeight / artWidth)
    else
        drawHeight = math.max(maxY - minY, 1)
    end
    local centerX = (minX + maxX) / 2
    local centerY = (minY + maxY) / 2
    texture:ClearAllPoints()
    texture:SetSize(drawWidth, drawHeight)
    texture:SetPoint('CENTER', self.canvas, 'TOPLEFT', centerX, centerY)
    local file = info.file or info.filename
    if (file) then
        texture:SetTexture(file)
        texture:SetTexCoord(info.leftTexCoord or 0, info.rightTexCoord or 1, info.topTexCoord or 0, info.bottomTexCoord or 1)
    else
        texture:SetAtlas(self.backgroundAtlas)
    end
    texture:SetVertexColor(1, 1, 1, 1)
    texture.left = centerX - drawWidth / 2
    texture.right = centerX + drawWidth / 2
    texture.bottom = centerY - drawHeight / 2
    texture.top = centerY + drawHeight / 2
end

tree.Refresh = function(self, configID, treeID, specID)
    if (not self.canvas) then
        return
    end

    HideChoicePopup()

    self.nodeCount = 0
    self.edgeCount = 0
    self.nodeByID = {}

    local nodeIDs = (configID and treeID) and C_Traits.GetTreeNodes(treeID) or nil
    self.nodeIDs = nodeIDs
    self.treeID = treeID
    self.currencyMap = {}
    if (configID and treeID) then
        local currencies = C_Traits.GetTreeCurrencyInfo(configID, treeID, false)
        if (currencies) then
            for _, info in ipairs(currencies) do
                self.currencyMap[info.traitCurrencyID] = info.quantity or 0
            end
        end
    end

    if (nodeIDs) then
        for _, nodeID in ipairs(nodeIDs) do
            local nodeInfo = C_Traits.GetNodeInfo(configID, nodeID)
            if (ShouldDrawNode(nodeInfo)) then
                self.nodeCount = self.nodeCount + 1
                local node = AcquireNode(self)
                if (UpdateNode(self, node, configID, nodeInfo)) then
                    self.nodeByID[nodeID] = node
                end
            end
        end

        if (configID and not EXUI.IsForever()) then
            LayoutHeroColumn(self, configID)
        end

        for _, nodeID in ipairs(nodeIDs) do
            local source = self.nodeByID[nodeID]
            local nodeInfo = source and C_Traits.GetNodeInfo(configID, nodeID)
            if (nodeInfo and nodeInfo.visibleEdges) then
                for _, edgeInfo in ipairs(nodeInfo.visibleEdges) do
                    local target = self.nodeByID[edgeInfo.targetNode]
                    if (target) then
                        self.edgeCount = self.edgeCount + 1
                        local edge = AcquireEdge(self)
                        local color = LineColor(source, target)
                        edge:SetColorTexture(color[1], color[2], color[3], 1)
                        edge:SetStartPoint('CENTER', source)
                        edge:SetEndPoint('CENTER', target)
                    end
                end
            end
        end
    end

    for index = self.nodeCount + 1, #self.nodes do
        self.nodes[index]:Hide()
    end
    for index = self.edgeCount + 1, #self.edges do
        self.edges[index]:Hide()
    end

    self.layoutConfigID = configID
    if (not EXUI.IsForever()) then
        LayoutTreeHeaders(self, configID, treeID)
    end
    if (self.background) then
        self.background:Hide()
        self.background.left = nil
    end
    FitToClip(self)
    self.searchConfigID = configID
    self.searchSpecID = specID
    if (self.searchText and self.searchController) then
        self.searchController:UpdateActiveSearchResults()
    end
    self:ApplySearch()
end
