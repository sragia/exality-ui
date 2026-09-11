---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIDamageMetersViews
local views = EXUI:GetModule('damage-meters-views')

---@class EXUIDamageMetersData
local meterData = EXUI:GetModule('damage-meters-data')

---@class EXUIDamageMetersBars
local bars = EXUI:GetModule('damage-meters-bars')

---@class EXUIDamageMetersSpellTooltip
local spellTooltip = EXUI:GetModule('damage-meters-spell-tooltip')

---@class EXUIDamageMetersModule
local meters = EXUI:GetModule('damage-meters')

---@class EXUIDamageMetersDefaults
local defaults = EXUI:GetModule('damage-meters-defaults')

---@class EXUIDamageMetersWindow
local windowMod = EXUI:GetModule('damage-meters-window')

local EXFrames = EXUI.EXFrames
local HEADER_HEIGHT = 22
local SESSION_ICON_SIZE = 14

local function colorRGBA(color, fallback)
    color = color or fallback
    if not color then
        return 0, 0, 0, 1
    end
    return color.r or 0, color.g or 0, color.b or 0, color.a or 1
end

local function applyButtonTexture(button, color)
    button.bg = button.bg or button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetAllPoints()
    button.bg:SetColorTexture(color[1], color[2], color[3], color[4] or 1)
end

function windowMod:Create(frame)
    if frame.meterReady then
        return frame
    end

    frame:SetMovable(true)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag('LeftButton')

    EXUI:ApplySolidBorder(frame, 1, EXUI.const.theme.border, { 0.05, 0.04, 0.03, 0.75 })
    EXUI:RegisterSnapFrame(frame)

    local header = CreateFrame('Button', nil, frame)
    header:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    header:RegisterForDrag('LeftButton')
    applyButtonTexture(header, EXUI.const.theme.backgroundDeep)
    frame.header = header

    local timer = header:CreateFontString(nil, 'OVERLAY')
    timer:SetJustifyH('RIGHT')
    frame.timer = timer

    local sessionButton = CreateFrame('Button', nil, header)
    sessionButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    sessionButton.icon = sessionButton:CreateTexture(nil, 'ARTWORK')
    sessionButton.icon:SetAllPoints()
    sessionButton.icon:SetTexture(EXUI.const.textures.frame.icons.alignRight)
    frame.sessionButton = sessionButton

    local viewButton = CreateFrame('Button', nil, header)
    viewButton:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
    viewButton.label = viewButton:CreateFontString(nil, 'OVERLAY')
    viewButton.label:SetAllPoints()
    viewButton.label:SetJustifyH('LEFT')
    viewButton.label:SetWordWrap(false)
    frame.viewButton = viewButton

    local body = CreateFrame('Button', nil, frame)
    body:RegisterForClicks('RightButtonUp')
    frame.body = body

    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scroll.hideScrollbar = true
    if scroll.scrollBar then
        scroll.scrollBar:Hide()
    end
    scroll:SetParent(body)
    scroll:ClearAllPoints()
    scroll:SetPoint('TOPLEFT', 0, 0)
    scroll:SetPoint('BOTTOMRIGHT', 0, 0)
    frame.scroll = scroll
    frame.scrollChild = scroll.child

    frame.emptyText = body:CreateFontString(nil, 'OVERLAY')
    frame.emptyText:SetPoint('CENTER')
    frame.emptyText:SetJustifyH('CENTER')
    frame.emptyText:SetWidth(200)

    frame.rows = {}
    frame.meterReady = true

    self:EnsurePinnedSelf(frame)
    self:BindScripts(frame)
    return frame
end

function windowMod:BindScripts(frame)
    local function savePosition()
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        if frame.ID then
            meters:UpdateValue(frame.ID, 'anchorPoint', point)
            meters:UpdateValue(frame.ID, 'relativePoint', relativePoint)
            meters:UpdateValue(frame.ID, 'XOff', xOfs)
            meters:UpdateValue(frame.ID, 'YOff', yOfs)
        end
    end

    local function canDrag()
        local db = frame.db
        return db and not db.locked and not db.clickThrough
    end

    local function wasDragged()
        return frame.dragStopAt and (GetTime() - frame.dragStopAt) < 0.2
    end

    local function openViewOnRightClick(anchor)
        return function(_, button)
            if button == 'RightButton' and not wasDragged() and (not frame.db or not frame.db.clickThrough) then
                self:OpenViewMenu(frame, anchor or frame.header)
            end
        end
    end

    local function bindRightClick(widget, anchor)
        if not widget then
            return
        end
        widget:EnableMouse(true)
        if widget.RegisterForClicks then
            widget:RegisterForClicks('LeftButtonUp', 'RightButtonUp')
        end
        widget:SetScript('OnMouseUp', openViewOnRightClick(anchor))
    end

    local function bindDrag(widget)
        if not widget then
            return
        end
        widget:RegisterForDrag('LeftButton')
        widget:SetScript('OnDragStart', function()
            if canDrag() then
                frame:SetMovable(true)
                frame.isDragging = true
                frame:StartMoving()
            end
        end)
        widget:SetScript('OnDragStop', function()
            if not frame.isDragging then
                return
            end
            frame:StopMovingOrSizing()
            frame.isDragging = false
            frame.dragStopAt = GetTime()
            savePosition()
        end)
    end

    bindDrag(frame)
    bindDrag(frame.header)
    bindDrag(frame.viewButton)
    bindDrag(frame.sessionButton)
    bindDrag(frame.body)
    bindDrag(frame.pinnedSelf)

    frame.header:SetScript('OnClick', function(_, button)
        if button == 'RightButton' and not wasDragged() then
            self:OpenViewMenu(frame, frame.header)
        end
    end)

    frame.viewButton:SetScript('OnClick', function(_, button)
        if wasDragged() then
            return
        end
        self:OpenViewMenu(frame, frame.viewButton)
    end)

    frame.sessionButton:SetScript('OnClick', function(_, button)
        if wasDragged() then
            return
        end
        GameTooltip:Hide()
        if button == 'RightButton' then
            self:OpenViewMenu(frame, frame.header)
            return
        end
        self:OpenSessionMenu(frame, frame.sessionButton)
    end)

    bindRightClick(frame, frame.header)
    bindRightClick(frame.scroll, frame.header)
    bindRightClick(frame.scroll and frame.scroll.content, frame.header)
    bindRightClick(frame.scrollChild, frame.header)

    frame.sessionButton:SetScript('OnEnter', function(btn)
        if not frame.db or frame.db.clickThrough then
            return
        end
        local text = EXUI.const.theme.text
        btn.icon:SetVertexColor(text[1], text[2], text[3], 1)
        GameTooltip:SetOwner(btn, 'ANCHOR_TOP')
        GameTooltip:SetText(views:GetSessionName(frame.db.sessionType, frame.db.sessionID))
        GameTooltip:Show()
    end)
    frame.sessionButton:SetScript('OnLeave', function(btn)
        local text = EXUI.const.theme.text
        btn.icon:SetVertexColor(text[1], text[2], text[3], 0.85)
        GameTooltip:Hide()
    end)

    local function forwardScroll(_, delta)
        if frame.scroll and frame.scroll.HandleMouseWheel then
            frame.scroll:HandleMouseWheel(delta)
        end
    end

    frame.body:EnableMouseWheel(true)
    frame.body:SetScript('OnMouseWheel', forwardScroll)
    frame.body:SetScript('OnClick', function(_, button)
        if button == 'RightButton' then
            self:OpenViewMenu(frame, frame.header)
        end
    end)

    frame:SetScript('OnHide', function()
        if spellTooltip.owner and (spellTooltip.owner:GetParent() == frame.scrollChild or spellTooltip.owner == frame.pinnedSelf) then
            spellTooltip:Hide()
        end
        self:HidePinnedSelf(frame)
    end)

    if frame.scroll then
        frame.scroll.onScroll = function()
            self:UpdatePinnedSelf(frame)
        end
    end
end

function windowMod:BindRow(frame, row)
    row:SetScript('OnEnter', function(btn)
        if frame.db and not frame.db.clickThrough then
            spellTooltip:ShowForSource(btn, frame.db, frame, btn.source)
        end
    end)
    row:SetScript('OnLeave', function()
        spellTooltip:Hide()
    end)
    row:SetScript('OnClick', function(btn, button)
        if button == 'RightButton' then
            self:OpenViewMenu(frame, btn)
            return
        end
        local source = btn.source
        if source and source.deathRecapID and source.deathRecapID ~= 0 and OpenDeathRecapUI then
            OpenDeathRecapUI(source.deathRecapID)
        end
    end)
    row:EnableMouseWheel(true)
    row:SetScript('OnMouseWheel', function(_, delta)
        if frame.scroll and frame.scroll.HandleMouseWheel then
            frame.scroll:HandleMouseWheel(delta)
        end
    end)
end

function windowMod:EnsurePinnedSelf(frame)
    if frame.pinnedSelf then
        return frame.pinnedSelf
    end

    local row = bars:CreateRow(frame.body)
    row:SetFrameLevel(frame.body:GetFrameLevel() + 8)
    row:Hide()
    frame.pinnedSelf = row
    self:BindRow(frame, row)
    return row
end

function windowMod:HidePinnedSelf(frame)
    if frame.pinnedSelf then
        frame.pinnedSelf:Hide()
        frame.pinnedSelf.source = nil
    end
end

function windowMod:GetVisibleRankRange(frame, db, count)
    if count <= 0 then
        return 1, 0
    end

    local barHeight = db.barHeight or 18
    local spacing = db.barSpacing or 1
    local stride = barHeight + spacing
    if stride <= 0 then
        return 1, count
    end

    local offset = 0
    local viewport = 0
    if frame.scroll then
        if frame.scroll.GetVerticalScroll then
            offset = frame.scroll:GetVerticalScroll() or 0
        end
        if frame.scroll.content then
            viewport = frame.scroll.content:GetHeight() or 0
        end
    end
    if viewport <= 0 and frame.body then
        viewport = frame.body:GetHeight() or 0
    end

    local first = math.floor(offset / stride) + 1
    local last = math.ceil((offset + viewport) / stride)
    first = math.max(1, math.min(count, first))
    last = math.max(first, math.min(count, last))
    return first, last
end

function windowMod:UpdatePinnedSelf(frame)
    local db = frame.db
    local row = frame.pinnedSelf
    if not row then
        return
    end
    if not db or db.alwaysShowSelf == false or not frame:IsShown() then
        self:HidePinnedSelf(frame)
        return
    end

    local index = frame.localPlayerIndex
    local source = frame.localPlayerSource
    local count = frame.sourceCount or 0
    if not index or not source or count <= 0 then
        self:HidePinnedSelf(frame)
        return
    end

    local _, lastVisible = self:GetVisibleRankRange(frame, db, count)
    if index <= lastVisible then
        self:HidePinnedSelf(frame)
        return
    end

    source.maxAmount = frame.sessionMaxAmount
    source.sessionTotalAmount = frame.sessionTotalAmount
    bars:UpdateRow(row, source, db, db.damageMeterType, index)

    local barHeight = db.barHeight or 18
    row:ClearAllPoints()
    EXUI:SetPoint(row, 'BOTTOMLEFT', frame.body, 'BOTTOMLEFT', 0, 0)
    EXUI:SetPoint(row, 'BOTTOMRIGHT', frame.body, 'BOTTOMRIGHT', 0, 0)
    EXUI:SetHeight(row, barHeight)
    row:Show()
end

function windowMod:EnsureRows(frame, count)
    while #frame.rows < count do
        local row = bars:CreateRow(frame.scrollChild)
        local index = #frame.rows + 1
        row:SetFrameLevel(frame.scrollChild:GetFrameLevel() + 2)
        frame.rows[index] = row
        self:BindRow(frame, row)
    end
end

function windowMod:ApplyFonts(frame, db)
    local fontPath, fontSize, fontFlag = bars:GetFont(db)
    frame.viewButton.label:SetFont(fontPath, fontSize, fontFlag)
    frame.timer:SetFont(fontPath, fontSize, fontFlag)
    frame.emptyText:SetFont(fontPath, fontSize, fontFlag)

    local text = EXUI.const.theme.text
    frame.viewButton.label:SetTextColor(text[1], text[2], text[3], 1)
    frame.sessionButton.icon:SetVertexColor(text[1], text[2], text[3], 0.85)
    frame.timer:SetTextColor(text[1], text[2], text[3], 0.8)
    frame.emptyText:SetTextColor(unpack(EXUI.const.theme.textMuted))
end

function windowMod:ShouldShow(frame, db)
    if not meters.enabled or not db or not db.enable then
        return false
    end
    if meters.editorShowing then
        return true
    end
    if meters.optionsItemID == frame.ID or meters:IsShowingTestBars(frame.ID) then
        return true
    end

    local visibility = db.visibility or 'always'
    if visibility == 'hidden' then
        return false
    end
    if visibility == 'combat' then
        return UnitAffectingCombat('player')
    end
    if visibility == 'group' then
        return IsInGroup()
    end
    return true
end

function windowMod:ApplyClickThrough(frame, db)
    local enabled = not db.clickThrough
    frame:EnableMouse(enabled)
    frame.header:EnableMouse(enabled)
    frame.body:EnableMouse(enabled)
    frame.viewButton:EnableMouse(enabled)
    frame.sessionButton:EnableMouse(enabled)
    for _, row in ipairs(frame.rows) do
        row:EnableMouse(enabled)
        row:EnableMouseWheel(enabled)
    end
    if frame.pinnedSelf then
        frame.pinnedSelf:EnableMouse(enabled)
        frame.pinnedSelf:EnableMouseWheel(enabled)
    end
    frame.body:EnableMouseWheel(enabled)
    if frame.scroll then
        frame.scroll:EnableMouse(enabled)
        frame.scroll:EnableMouseWheel(enabled)
        if frame.scroll.content then
            frame.scroll.content:EnableMouse(enabled)
        end
        if frame.scroll.scrollBar then
            frame.scroll.scrollBar:EnableMouse(enabled)
        end
    end
    if frame.scrollChild then
        frame.scrollChild:EnableMouse(enabled)
    end
    if not enabled then
        spellTooltip:Hide()
        GameTooltip:Hide()
    end
end

function windowMod:LayoutChrome(frame, db)
    local inset = EXUI:GetBorderInset(frame, 1)
    local headerHeight = db.headerHeight or HEADER_HEIGHT
    local gap = EXUI:ScalePixel(1, frame)

    EXUI:SetHeight(frame.header, headerHeight)
    frame.header:ClearAllPoints()
    EXUI:SetPoint(frame.header, 'TOPLEFT', frame, 'TOPLEFT', inset, -inset)
    EXUI:SetPoint(frame.header, 'TOPRIGHT', frame, 'TOPRIGHT', -inset, -inset)

    frame.body:ClearAllPoints()
    EXUI:SetPoint(frame.body, 'TOPLEFT', frame.header, 'BOTTOMLEFT', 0, -gap)
    EXUI:SetPoint(frame.body, 'BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -inset, inset)

    EXUI:SetSize(frame.sessionButton, SESSION_ICON_SIZE, SESSION_ICON_SIZE)
    frame.sessionButton:ClearAllPoints()
    EXUI:SetPoint(frame.sessionButton, 'RIGHT', frame.header, 'RIGHT', -4, 0)

    local showTimer = db.showTimer ~= false
    frame.timer:SetShown(showTimer)
    frame.timer:ClearAllPoints()
    if showTimer then
        EXUI:SetPoint(frame.timer, 'RIGHT', frame.sessionButton, 'LEFT', -4, 0)
    end

    local showTitle = db.showTitle ~= false
    frame.viewButton:SetShown(showTitle)
    if showTitle then
        local titleRight = showTimer and frame.timer or frame.sessionButton
        EXUI:SetHeight(frame.viewButton, 18)
        frame.viewButton:ClearAllPoints()
        EXUI:SetPoint(frame.viewButton, 'LEFT', frame.header, 'LEFT', 4, 0)
        EXUI:SetPoint(frame.viewButton, 'RIGHT', titleRight, 'LEFT', -6, 0)
    end

    if frame.scroll then
        frame.scroll:ClearAllPoints()
        EXUI:SetPoint(frame.scroll, 'TOPLEFT', frame.body, 'TOPLEFT', 0, 0)
        EXUI:SetPoint(frame.scroll, 'BOTTOMRIGHT', frame.body, 'BOTTOMRIGHT', 0, 0)
    end
end

function windowMod:Layout(frame, db)
    local width = db.width or 240
    local height = db.height or 180

    EXUI:SetSize(frame, width, height)

    local backdrop = db.backdropColor or defaults.WINDOW.backdropColor
    local br, bg, bb, ba = colorRGBA(backdrop)
    frame:SetBackdropColor(br, bg, bb, ba)
    if frame.header.bg then
        frame.header.bg:SetColorTexture(br, bg, bb, ba)
    end

    local border = db.borderColor or defaults.WINDOW.borderColor
    local cr, cg, cb, ca = colorRGBA(border)
    if frame.PPBorder then
        frame.PPBorder:SetBorderColor(cr, cg, cb, ca)
        if ca <= 0 then
            frame.PPBorder:Hide()
        else
            frame.PPBorder:Show()
        end
    end

    if not frame.isDragging then
        local posKey = table.concat({
            db.anchorPoint or 'TOPLEFT',
            db.relativePoint or 'TOPLEFT',
            tostring(db.XOff or 200),
            tostring(db.YOff or -240),
        }, ':')
        if frame._posKey ~= posKey then
            EXUI:SetPoint(frame, db.anchorPoint or 'TOPLEFT', UIParent, db.relativePoint or 'TOPLEFT', db.XOff or 200, db.YOff or -240)
            frame._posKey = posKey
        end
        EXUI:SnapFrameToPixels(frame)
    end

    self:LayoutChrome(frame, db)
    if frame.PPBorder then
        frame.PPBorder:SetBorderThickness(1)
    end

    self:ApplyFonts(frame, db)
    self:ApplyClickThrough(frame, db)
end

function windowMod:LayoutRows(frame, db, count)
    local barHeight = db.barHeight or 18
    local spacing = db.barSpacing or 1
    local previous
    for i = 1, count do
        local row = frame.rows[i]
        row:ClearAllPoints()
        EXUI:SetPoint(row, 'LEFT', frame.scrollChild, 'LEFT', 0, 0)
        EXUI:SetPoint(row, 'RIGHT', frame.scrollChild, 'RIGHT', 0, 0)
        if previous then
            EXUI:SetPoint(row, 'TOP', previous, 'BOTTOM', 0, -spacing)
        else
            EXUI:SetPoint(row, 'TOP', frame.scrollChild, 'TOP', 0, 0)
        end
        EXUI:SetHeight(row, barHeight)
        previous = row
    end

    local contentHeight = 1
    if count > 0 then
        contentHeight = count * barHeight + math.max(0, count - 1) * spacing
    end
    frame.scroll:UpdateScrollChild(nil, contentHeight)
end

function windowMod:GetHeldSession(frame, db)
    local function usable(session, sessionID)
        if not sessionID or sessionID <= 0 then
            return false
        end
        if not session or meterData:IsSessionEmpty(session) then
            return false
        end
        return not meterData:IsOverallLike(session, db.damageMeterType)
    end

    local committedID = meters.committedSessionID
    if committedID then
        local historic = meterData:GetSession(nil, committedID, db.damageMeterType)
        if usable(historic, committedID) then
            return historic, committedID
        end
    end

    local lookupID = frame.lookupSessionID
    if lookupID then
        local held = meterData:GetSession(nil, lookupID, db.damageMeterType)
        if usable(held, lookupID) then
            return held, lookupID
        end
    end

    return nil
end

function windowMod:GetCombatSession(frame, db)
    if meters:IsShowingTestBars(frame.ID) then
        frame.lookupSessionType = db.sessionType
        frame.lookupSessionID = db.sessionID
        return meterData:GetDummySession(), true
    end

    if db.sessionType == views.Session.Current then
        if meters:IsKeyOverallMode() and not meters:TryLeaveKeyOverall() then
            frame.lookupSessionType = views.Session.Overall
            frame.lookupSessionID = nil
            return meterData:GetSession(views.Session.Overall, nil, db.damageMeterType), false
        end

        if meters:IsEncounterMode() then
            local current = meterData:GetSession(views.Session.Current, nil, db.damageMeterType)
            if current and not meterData:IsSessionEmpty(current) then
                frame.lookupSessionType = views.Session.Current
                frame.lookupSessionID = nil
                return current, false
            end
            local held, heldID = self:GetHeldSession(frame, db)
            if held then
                frame.lookupSessionType = nil
                frame.lookupSessionID = heldID
                return held, false
            end
            frame.lookupSessionType = views.Session.Current
            frame.lookupSessionID = nil
            return current, false
        end

        if meters:ShouldAdoptLiveCurrent(db.damageMeterType) then
            frame.lookupSessionType = db.sessionType
            frame.lookupSessionID = nil
            return meterData:GetSession(db.sessionType, nil, db.damageMeterType), false
        end

        local held, heldID = self:GetHeldSession(frame, db)
        if held then
            frame.lookupSessionType = nil
            frame.lookupSessionID = heldID
            return held, false
        end

        frame.lookupSessionType = db.sessionType
        frame.lookupSessionID = nil
        return nil, false
    end

    frame.lookupSessionType = db.sessionType
    frame.lookupSessionID = db.sessionID
    return meterData:GetSession(db.sessionType, db.sessionID, db.damageMeterType), false
end

function windowMod:UpdateHeader(frame, db, session, isDummy)
    frame.viewButton.label:SetText(views:GetTypeName(db.damageMeterType))

    local duration = nil
    if not isDummy then
        local durationType = frame.lookupSessionType or db.sessionType
        local useLiveDuration = durationType ~= nil and not frame.lookupSessionID
        if useLiveDuration then
            duration = meterData:GetSessionDuration(durationType)
        end
        if duration == nil and session then
            duration = session.durationSeconds
        end
        if duration == nil and frame.lookupSessionID then
            local held = meterData:GetSession(nil, frame.lookupSessionID, db.damageMeterType)
            if held then
                duration = held.durationSeconds
            end
        end
    elseif session then
        duration = session.durationSeconds
    end

    local clock = meterData:FormatDuration(duration)
    if clock and clock ~= '' then
        frame.timer:SetText(clock)
    else
        frame.timer:SetText('')
    end
end

function windowMod:Refresh(frame)
    local db = frame.db
    if not db then
        self:HidePinnedSelf(frame)
        frame:Hide()
        return
    end

    self:Layout(frame, db)

    if not self:ShouldShow(frame, db) then
        self:HidePinnedSelf(frame)
        frame:Hide()
        return
    end

    frame:Show()

    local available, failureReason = meterData:IsAvailable()
    if not available and meters.optionsItemID ~= frame.ID then
        for _, row in ipairs(frame.rows) do
            row:Hide()
        end
        self:LayoutRows(frame, db, 0)
        frame.emptyText:SetText(failureReason or 'Damage meter unavailable')
        frame.emptyText:Show()
        self:UpdateHeader(frame, db, nil, false)
        frame.localPlayerIndex = nil
        frame.localPlayerSource = nil
        frame.sourceCount = 0
        self:HidePinnedSelf(frame)
        return
    end

    local session, isDummy = self:GetCombatSession(frame, db)
    self:UpdateHeader(frame, db, session, isDummy)

    local sources = session and session.combatSources or {}
    if views:IsDeaths(db.damageMeterType) and #sources > 1 then
        local reversed = {}
        for i = #sources, 1, -1 do
            reversed[#reversed + 1] = sources[i]
        end
        sources = reversed
    end
    local maxAmount = session and session.maxAmount or 0
    local totalAmount = session and session.totalAmount or 0
    local meterType = db.damageMeterType
    local shown = #sources
    frame.sourceCount = shown
    frame.sessionMaxAmount = maxAmount
    frame.sessionTotalAmount = totalAmount
    frame.localPlayerIndex = nil
    frame.localPlayerSource = nil

    self:EnsureRows(frame, shown)
    for i, source in ipairs(sources) do
        source.maxAmount = maxAmount
        source.sessionTotalAmount = totalAmount
        if source.isLocalPlayer and not frame.localPlayerIndex then
            frame.localPlayerIndex = i
            frame.localPlayerSource = source
        end
        bars:UpdateRow(frame.rows[i], source, db, meterType, i)
    end

    for i = shown + 1, #frame.rows do
        frame.rows[i]:Hide()
        frame.rows[i].source = nil
    end

    self:LayoutRows(frame, db, shown)
    self:UpdatePinnedSelf(frame)

    if shown == 0 then
        if views:IsDeaths(meterType) then
            frame.emptyText:SetText('No deaths')
        elseif meterType == views.Type.AvoidableDamageTaken then
            frame.emptyText:SetText(_G.DAMAGE_METER_AVOIDABLE_DAMAGE_NOT_ACTIVE or 'Avoidable damage is not active')
        else
            frame.emptyText:SetText('No data')
        end
        frame.emptyText:Show()
    else
        frame.emptyText:Hide()
    end
end

function windowMod:BuildViewMenu(frame)
    local db = frame.db
    local favorites = meters:GetFavoriteViews()
    local entries = {}
    local current = db.damageMeterType

    local function addView(meterType)
        local favorited = favorites[meterType]
        table.insert(entries, {
            text = views:GetTypeName(meterType),
            icon = favorited and 'auctionhouse-icon-favorite' or nil,
            color = current == meterType and EXUI.const.theme.accent or nil,
            onClick = function(_, button)
                if button == 'RightButton' then
                    meters:ToggleFavorite(meterType)
                    local listMenu = EXFrames:GetFrame('list-menu-frame')
                    listMenu:ShowAt(listMenu:GetAnchor() or frame.viewButton, self:BuildViewMenu(frame))
                    return false
                end
                meters:UpdateValue(frame.ID, 'damageMeterType', meterType)
                self:Refresh(frame)
            end,
        })
    end

    local favoriteOrder = {}
    for _, category in ipairs(views:GetCategories()) do
        for _, meterType in ipairs(category.types) do
            if favorites[meterType] then
                table.insert(favoriteOrder, meterType)
            end
        end
    end

    if #favoriteOrder > 0 then
        table.insert(entries, { text = 'Favorites', isHeader = true })
        for _, meterType in ipairs(favoriteOrder) do
            addView(meterType)
        end
    end

    for _, category in ipairs(views:GetCategories()) do
        table.insert(entries, { text = category.name, isHeader = true })
        for _, meterType in ipairs(category.types) do
            addView(meterType)
        end
    end

    table.insert(entries, { text = 'Reset All Sessions', color = EXUI.const.theme.danger, onClick = function()
        meterData:ResetAllSessions()
    end })

    return entries
end

function windowMod:OpenViewMenu(frame, anchor)
    EXFrames:GetFrame('list-menu-frame'):ToggleAt(anchor or frame.viewButton, self:BuildViewMenu(frame))
end

function windowMod:BuildSessionMenu(frame)
    local db = frame.db
    local entries = {}

    local function isSelected(sessionType, sessionID)
        if sessionType ~= nil then
            return db.sessionType == sessionType and db.sessionID == nil
        end
        return db.sessionType == nil and db.sessionID == sessionID
    end

    local function selectSession(sessionType, sessionID)
        meters:SetWindowSession(frame.ID, sessionType, sessionID)
        meters:UpdateById(frame.ID)
    end

    for _, available in ipairs(meterData:GetHistoricSessions(db.damageMeterType)) do
        local name = available.name
        if not name or name == '' then
            name = views:GetSessionName(nil, available.sessionID)
        end
        local duration = meterData:FormatDuration(available.durationSeconds)
        if duration and duration ~= '' then
            name = string.format('%s [%s]', name, duration)
        end
        table.insert(entries, {
            text = name,
            color = isSelected(nil, available.sessionID) and EXUI.const.theme.accent or nil,
            onClick = function()
                selectSession(nil, available.sessionID)
            end,
        })
    end

    table.insert(entries, {
        text = views:GetSessionName(views.Session.Current),
        color = isSelected(views.Session.Current, nil) and EXUI.const.theme.accent or nil,
        onClick = function()
            selectSession(views.Session.Current, nil)
        end,
    })
    table.insert(entries, {
        text = views:GetSessionName(views.Session.Overall),
        color = isSelected(views.Session.Overall, nil) and EXUI.const.theme.accent or nil,
        onClick = function()
            selectSession(views.Session.Overall, nil)
        end,
    })

    return entries
end

function windowMod:OpenSessionMenu(frame, anchor)
    EXFrames:GetFrame('list-menu-frame'):ToggleAt(anchor or frame.sessionButton, self:BuildSessionMenu(frame))
end
