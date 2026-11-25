---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUILootSprite
local sprite = EXUI:GetModule('loot-sprite')

---@class EXUILootItemCard
local itemCard = EXUI:GetModule('loot-item-card')

local FONT = EXUI.const.fonts.DEFAULT
local THEME = EXUI.const.theme
local ICON_SIZE = 40
local ICON_LEFT = 9
local ICON_ZOOM = 0.075
local COUNTER_ICON = 14
local COUNTER_GAP = 8
local DOT_SIZE = 4

itemCard.width, itemCard.height = sprite:GetBodySize('itemBg')

local COUNTERS = {
    { state = 'need',     atlas = 'lootroll-icon-need',     label = 'Need' },
    { state = 'greed',    atlas = 'lootroll-icon-greed',    label = 'Greed' },
    { state = 'transmog', atlas = 'lootroll-icon-transmog', label = 'Transmog', retailOnly = true },
    { state = 'pass',     atlas = 'lootroll-icon-pass',     label = 'Pass' },
}

local STATE_ATLAS = {}
for _, info in ipairs(COUNTERS) do
    STATE_ATLAS[info.state] = info.atlas
end

local function ColorizeName(player)
    local color = player.class and C_ClassColor.GetClassColor(player.class)
    return color and color:WrapTextInColorCode(player.name) or player.name
end

local function ShowPlayersTooltip(owner, title, players)
    GameTooltip:SetOwner(owner, 'ANCHOR_TOP')
    GameTooltip:AddLine(title)
    for _, player in ipairs(players) do
        GameTooltip:AddLine(ColorizeName(player))
    end
    GameTooltip:Show()
end

local function OnCounterEnter(counter)
    if (counter.players and #counter.players > 0) then
        ShowPlayersTooltip(counter, counter.label, counter.players)
    end
end

local function CreateCounterText(parent)
    local text = parent:CreateFontString(nil, 'OVERLAY')
    text:SetFont(FONT, 11, 'OUTLINE')
    text:SetTextColor(unpack(THEME.text))
    return text
end

local function CreateCounter(parent, info)
    local counter = CreateFrame('Frame', nil, parent)
    counter:SetHeight(COUNTER_ICON)
    counter.label = info.label

    local icon = counter:CreateTexture(nil, 'ARTWORK')
    icon:SetAtlas(info.atlas)
    icon:SetSize(COUNTER_ICON, COUNTER_ICON)
    icon:SetPoint('LEFT')

    local text = CreateCounterText(counter)
    text:SetPoint('LEFT', icon, 'RIGHT', 3, 0)
    counter.text = text

    counter.SetPlayers = function(self, players)
        self.players = players
        self.text:SetText(#players)
        self:SetWidth(COUNTER_ICON + 3 + self.text:GetStringWidth())
    end

    counter:SetScript('OnEnter', OnCounterEnter)
    counter:SetScript('OnLeave', GameTooltip_Hide)
    return counter
end

local function CreateWaitingCounter(parent)
    local counter = CreateFrame('Frame', nil, parent)
    counter:SetHeight(COUNTER_ICON)
    counter.label = 'Waiting on'

    local dots = {}
    for i = 1, 3 do
        local dot = counter:CreateTexture(nil, 'ARTWORK')
        dot:SetAtlas('lootroll-pendingdot')
        dot:SetSize(DOT_SIZE, DOT_SIZE)
        dot:SetAlpha(0)
        if (i == 1) then
            dot:SetPoint('LEFT')
        else
            dot:SetPoint('LEFT', dots[i - 1], 'RIGHT', 2, 0)
        end
        dots[i] = dot
    end

    local anim = counter:CreateAnimationGroup()
    anim:SetLooping('REPEAT')
    for i, dot in ipairs(dots) do
        local fadeIn = anim:CreateAnimation('Alpha')
        fadeIn:SetTarget(dot)
        fadeIn:SetFromAlpha(0)
        fadeIn:SetToAlpha(1)
        fadeIn:SetDuration(0.15)
        fadeIn:SetStartDelay(i == 1 and 0.3 or 0.15)
        fadeIn:SetOrder(i)
    end
    for _, dot in ipairs(dots) do
        local fadeOut = anim:CreateAnimation('Alpha')
        fadeOut:SetTarget(dot)
        fadeOut:SetFromAlpha(1)
        fadeOut:SetToAlpha(0)
        fadeOut:SetDuration(0.15)
        fadeOut:SetStartDelay(0.4)
        fadeOut:SetOrder(4)
    end
    counter.anim = anim

    local text = CreateCounterText(counter)
    text:SetPoint('LEFT', dots[3], 'RIGHT', 5, 0)
    counter.text = text

    counter.SetPlayers = function(self, players)
        self.players = players
        self.text:SetText(#players)
        self:SetWidth(DOT_SIZE * 3 + 4 + 5 + self.text:GetStringWidth())
        if (not self.anim:IsPlaying()) then
            self.anim:Play()
        end
    end

    counter:SetScript('OnHide', function(self) self.anim:Stop() end)
    counter:SetScript('OnEnter', OnCounterEnter)
    counter:SetScript('OnLeave', GameTooltip_Hide)
    return counter
end

local function SortRolls(a, b)
    if (a.order and b.order) then
        return a.order < b.order
    end
    if ((a.roll or 0) ~= (b.roll or 0)) then
        return (a.roll or 0) > (b.roll or 0)
    end
    return a.name < b.name
end

local function OnResultEnter(hover)
    local card = hover:GetParent()
    if (not card.rollPlayers) then return end

    local list = {}
    for _, player in pairs(card.rollPlayers) do
        table.insert(list, player)
    end
    if (#list == 0) then return end
    table.sort(list, SortRolls)

    GameTooltip:SetOwner(hover, 'ANCHOR_TOP')
    GameTooltip:AddLine('Rolls')
    for _, player in ipairs(list) do
        local atlas = STATE_ATLAS[player.state]
        local icon = atlas and CreateAtlasMarkup(atlas, COUNTER_ICON, COUNTER_ICON) .. ' ' or ''
        GameTooltip:AddDoubleLine(icon .. ColorizeName(player), player.roll or '', 1, 1, 1, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function OnIconEnter(iconFrame)
    local card = iconFrame:GetParent()
    GameTooltip:SetOwner(iconFrame, 'ANCHOR_RIGHT')
    if (card.link) then
        GameTooltip:SetHyperlink(card.link)
    else
        GameTooltip:AddLine(card.Name:GetText())
    end
    GameTooltip:Show()
end

local function OnIconClick(iconFrame)
    local card = iconFrame:GetParent()
    if (card.link and IsModifiedClick()) then
        HandleModifiedItemClick(card.link)
    end
end

local cardMethods = {}

cardMethods.SetItem = function(self, texture, name, quality, count, link)
    self.link = link
    self.Icon:SetTexture(texture)
    self.Icon:SetTexCoord(ICON_ZOOM, 1 - ICON_ZOOM, ICON_ZOOM, 1 - ICON_ZOOM)
    self.Name:SetText(name)

    local r, g, b = C_Item.GetItemQualityColor(quality or Enum.ItemQuality.Common)
    self.Name:SetTextColor(r, g, b)
    self.IconBorder:SetVertexColor(r, g, b)

    self.Count:SetText(count and count > 1 and count or '')
end

cardMethods.SetCounts = function(self, counts)
    local previous
    for _, counter in ipairs(self.counters) do
        local players = counts[counter.state] or {}
        local shown = #players > 0 and not (counter.retailOnly and EXUI.IsForever())
        counter:SetShown(shown)
        if (shown) then
            counter:SetPlayers(players)
            counter:ClearAllPoints()
            if (previous) then
                counter:SetPoint('LEFT', previous, 'RIGHT', COUNTER_GAP, 0)
            else
                counter:SetPoint('LEFT', self.CounterRow, 'LEFT')
            end
            previous = counter
        end
    end
end

cardMethods.SetResult = function(self, winner, allPassed, players)
    local done = winner ~= nil or allPassed
    self.CounterRow:SetShown(not done)
    self.Result:SetShown(done)
    self.ResultHover:SetShown(done)
    self.rollPlayers = done and players or nil
    if (winner) then
        local atlas = winner.state and STATE_ATLAS[winner.state]
        local icon = atlas and CreateAtlasMarkup(atlas, COUNTER_ICON, COUNTER_ICON) .. ' ' or ''
        self.Result:SetText(icon .. ColorizeName(winner))
    elseif (allPassed) then
        self.Result:SetText('All passed')
    end

    if (done) then
        self.Status:SetText('Done')
        self.Status:SetTextColor(unpack(THEME.success))
    end
    return done
end

cardMethods.SetDoneTint = function(self, done)
    if (done) then
        self.Bg:SetVertexColor(0, 1, 0, 1)
    else
        self.Bg:SetVertexColor(1, 1, 1)
    end
end

cardMethods.SetTimeLeft = function(self, seconds)
    if (not seconds) then
        self.Status:SetText('')
        return
    end
    seconds = math.ceil(seconds)
    self.Status:SetFormattedText('%02d:%02d', math.floor(seconds / 60), seconds % 60)
    self.Status:SetTextColor(unpack(THEME.textMuted))
end

itemCard.Create = function(self, parent)
    local card = CreateFrame('Frame', nil, parent)
    card:SetSize(self.width, self.height)
    Mixin(card, cardMethods)

    local bg = card:CreateTexture(nil, 'BACKGROUND')
    sprite:Place(bg, 'itemBg', card)
    card.Bg = bg

    local border = card:CreateTexture(nil, 'BORDER')
    sprite:Place(border, 'itemBorder', card)
    border:SetVertexColor(unpack(THEME.border))

    local iconFrame = CreateFrame('Button', nil, card)
    iconFrame:SetSize(ICON_SIZE, ICON_SIZE)
    iconFrame:SetPoint('LEFT', ICON_LEFT, 0)
    iconFrame:SetScript('OnEnter', OnIconEnter)
    iconFrame:SetScript('OnLeave', GameTooltip_Hide)
    iconFrame:SetScript('OnClick', OnIconClick)

    local iconBg = iconFrame:CreateTexture(nil, 'BACKGROUND')
    sprite:Place(iconBg, 'iconBg', iconFrame)

    local icon = iconFrame:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    local mask = iconFrame:CreateMaskTexture()
    mask:SetTexture(sprite.iconMask, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    card.Icon = icon

    local iconBorder = iconFrame:CreateTexture(nil, 'OVERLAY')
    sprite:Place(iconBorder, 'iconBorder', iconFrame, 1)
    card.IconBorder = iconBorder

    local count = iconFrame:CreateFontString(nil, 'OVERLAY')
    count:SetFont(FONT, 11, 'OUTLINE')
    count:SetPoint('BOTTOMRIGHT', -2, 2)
    card.Count = count

    local name = card:CreateFontString(nil, 'OVERLAY')
    name:SetFont(FONT, 14, 'OUTLINE')
    name:SetPoint('BOTTOMLEFT', iconFrame, 'BOTTOMRIGHT', 10, 0)
    name:SetWidth(self.width - ICON_LEFT - ICON_SIZE - 20)
    name:SetJustifyH('LEFT')
    name:SetWordWrap(false)
    card.Name = name

    local counterRow = CreateFrame('Frame', nil, card)
    counterRow:SetHeight(COUNTER_ICON)
    counterRow:SetPoint('TOPLEFT', iconFrame, 'TOPRIGHT', 10, 0)
    counterRow:SetWidth(self.width - ICON_LEFT - ICON_SIZE - 70)
    card.CounterRow = counterRow

    card.counters = {}
    for _, info in ipairs(COUNTERS) do
        local counter = CreateCounter(counterRow, info)
        counter.state = info.state
        counter.retailOnly = info.retailOnly
        table.insert(card.counters, counter)
    end
    local waiting = CreateWaitingCounter(counterRow)
    waiting.state = 'waiting'
    table.insert(card.counters, waiting)

    local result = card:CreateFontString(nil, 'OVERLAY')
    result:SetFont(FONT, 12, 'OUTLINE')
    result:SetPoint('TOPLEFT', iconFrame, 'TOPRIGHT', 10, 0)
    result:SetTextColor(unpack(THEME.textMuted))
    result:Hide()
    card.Result = result

    local resultHover = CreateFrame('Frame', nil, card)
    resultHover:SetPoint('TOPLEFT', result, 'TOPLEFT', -2, 2)
    resultHover:SetPoint('BOTTOMRIGHT', result, 'BOTTOMRIGHT', 2, -2)
    resultHover:SetScript('OnEnter', OnResultEnter)
    resultHover:SetScript('OnLeave', GameTooltip_Hide)
    resultHover:Hide()
    card.ResultHover = resultHover

    local status = card:CreateFontString(nil, 'OVERLAY')
    status:SetFont(FONT, 10, 'OUTLINE')
    status:SetPoint('TOPRIGHT', -8, -7)
    card.Status = status

    return card
end
