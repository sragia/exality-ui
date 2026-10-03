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

local function PlaceNode(node, x, y)
    node.posX = x
    node.posY = y
    node:ClearAllPoints()
    node:SetPoint('CENTER', node:GetParent(), 'TOPLEFT', x, y)
end

local function FitToClip(self)
    local minX, minY, maxX, maxY
    for index = 1, self.nodeCount or 0 do
        local node = self.nodes[index]
        if (node:IsShown()) then
            local halfW = node:GetWidth() / 2
            local halfH = node:GetHeight() / 2
            local left = node.posX - halfW
            local right = node.posX + halfW
            local bottom = node.posY - halfH
            local top = node.posY + halfH
            minX = minX and math.min(minX, left) or left
            maxX = maxX and math.max(maxX, right) or right
            minY = minY and math.min(minY, bottom) or bottom
            maxY = maxY and math.max(maxY, top) or top
        end
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

    if (mouseButton == 'RightButton') then
        HideChoicePopup()
        C_Traits.RefundRank(configID, nodeID)
        return
    end

    if (button.isChoiceOption) then
        if (button.isSelected and button.canPurchase) then
            C_Traits.PurchaseRank(configID, nodeID)
        else
            C_Traits.SetSelection(configID, nodeID, button.entryID)
        end
        HideChoicePopup()
        return
    end

    if (button.isChoice) then
        ToggleChoicePopup(button.ownerNode)
        return
    end

    HideChoicePopup()
    C_Traits.PurchaseRank(configID, nodeID)
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
    PlaceNode(node, nodeInfo.posX / 10, -nodeInfo.posY / 10)

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
    for index = 1, self.nodeCount do
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

    for index = 1, self.nodeCount do
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

        if (configID) then
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

    FitToClip(self)
    self.searchConfigID = configID
    self.searchSpecID = specID
    if (self.searchText and self.searchController) then
        self.searchController:UpdateActiveSearchResults()
    end
    self:ApplySearch()
end
