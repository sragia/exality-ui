---@class ExalityUI
local EXUI = select(2, ...)

local EXFrames = EXUI.EXFrames

---@class EXUIChatUtil
local util = EXUI:GetModule('chat-util')

---@class EXUIChatFormat
local formatter = EXUI:GetModule('chat-format')

---@class EXUIChatHistory
local history = EXUI:GetModule('chat-history')

---@class EXUIChatComposer
local composer = EXUI:GetModule('chat-composer')

---@class EXUIChatWindow
local window = EXUI:GetModule('chat-window')

---@class EXUIChatMessages
local messages = EXUI:GetModule('chat-messages')

local Chat = util.Chat
local FontPath = util.FontPath
local IsSecret = util.IsSecret
local HasText = util.HasText

local FADE_DURATION = 0.6

local ACTION = {
    CHANNEL_JOIN = 'joined channel.',
    CHANNEL_LEAVE = 'left channel.',
}

messages.rows = {}

local function MeasureWidth(text)
    if not window.frame or IsSecret(text) or type(text) ~= 'string' then
        return nil
    end
    local measure = messages.lineMeasure
    if not measure then
        measure = window.frame:CreateFontString(nil, 'OVERLAY')
        measure:Hide()
        messages.lineMeasure = measure
    end
    measure:SetFont(FontPath(), 13, 'OUTLINE')
    measure:SetWordWrap(false)
    measure:SetText(text)
    local width
    if measure.GetUnboundedStringWidth then
        width = measure:GetUnboundedStringWidth()
    else
        width = measure:GetStringWidth()
    end
    if IsSecret(width) or type(width) ~= 'number' or width ~= width or width < 0 then
        return nil
    end
    return width
end

local function PlaceSenderHit(row, channel, plainName, messageRight)
    local hit = row.senderHit
    local proxy = row.nameProxy
    if not HasText(plainName) then
        hit:Hide()
        proxy:Hide()
        return
    end
    local lead, tail = 0, 0
    if type(channel) == 'string' then
        if messageRight then
            tail = MeasureWidth(formatter.TAG_GAP .. channel) or 0
        else
            lead = MeasureWidth(channel .. formatter.TAG_GAP) or 0
        end
    end
    proxy:SetFont(FontPath(), 13, 'OUTLINE')
    proxy:SetWordWrap(false)
    proxy:SetText(plainName)
    proxy:ClearAllPoints()
    if messageRight then
        proxy:SetPoint('BOTTOMRIGHT', row.text, 'BOTTOMRIGHT', -tail, 0)
    else
        proxy:SetPoint('TOPLEFT', row.text, 'TOPLEFT', lead, 0)
    end
    proxy:SetAlpha(0)
    proxy:Show()
    hit:ClearAllPoints()
    if IsSecret(plainName) then
        hit:SetSize(120, 18)
        hit:EnableMouse(false)
        if messageRight then
            hit:SetPoint('TOPRIGHT', row.text, 'TOPRIGHT', -tail, 0)
        else
            hit:SetPoint('TOPLEFT', row.text, 'TOPLEFT', lead, 0)
        end
    else
        hit:EnableMouse(true)
        hit:SetPoint('TOPLEFT', proxy, 'TOPLEFT', -1, 1)
        hit:SetPoint('BOTTOMRIGHT', proxy, 'BOTTOMRIGHT', 1, -1)
    end
    hit:Show()
end

function messages:RowHeight()
    local size = 13
    if Chat():GetTimestampPlace() == 'inline' then
        local stamp = Chat():GetTimestampFontSize()
        if stamp > size then
            size = stamp
        end
    end
    return size + 6
end

function messages:TimestampWidth()
    local pattern = Chat():GetTimestampPattern()
    local size = Chat():GetTimestampFontSize()
    if not pattern or not window.frame then
        return 8
    end
    local key = pattern .. '\0' .. size
    if self.stampKey == key and self.stampWidth then
        return self.stampWidth
    end
    local ok, sample = pcall(date, pattern, 1609459200)
    if not ok or type(sample) ~= 'string' then
        sample = ''
    end
    sample = sample:gsub('%d', '4')
    if not self.stampMeasure then
        self.stampMeasure = window.frame:CreateFontString(nil, 'OVERLAY')
        self.stampMeasure:Hide()
    end
    self.stampMeasure:SetFont(FontPath(), size, 'OUTLINE')
    self.stampMeasure:SetText(sample)
    local width = self.stampMeasure:GetStringWidth()
    if not width or width < 1 then
        width = size * 4
    end
    self.stampKey = key
    self.stampWidth = width
    return self.stampWidth
end

function messages:CreateRow(parent)
    local nativeLinks = false
    local row
    local created, templated = pcall(CreateFrame, 'Frame', nil, parent, 'InlineHyperlinkFrameTemplate')
    if created then
        row = templated
        nativeLinks = true
    else
        row = CreateFrame('Frame', nil, parent)
    end
    row:SetHeight(self:RowHeight())

    local time = row:CreateFontString(nil, 'OVERLAY')
    time:SetFont(FontPath(), 12, 'OUTLINE')
    time:SetJustifyH('RIGHT')
    time:SetJustifyV('TOP')
    time:SetWordWrap(false)
    row.time = time

    local text = row:CreateFontString(nil, 'OVERLAY')
    text:SetFont(FontPath(), 13, 'OUTLINE')
    text:SetJustifyH('LEFT')
    text:SetJustifyV('TOP')
    text:SetWordWrap(true)
    text:SetNonSpaceWrap(true)
    if text.SetIndentedWordWrap then
        text:SetIndentedWordWrap(false)
    end
    row.text = text

    local nameProxy = row:CreateFontString(nil, 'OVERLAY')
    nameProxy:SetFont(FontPath(), 13, 'OUTLINE')
    nameProxy:SetWordWrap(false)
    nameProxy:SetAlpha(0)
    nameProxy:Hide()
    row.nameProxy = nameProxy

    local senderHit = CreateFrame('Button', nil, row)
    senderHit:RegisterForClicks('AnyUp')
    senderHit:SetScript('OnClick', function(_, button)
        composer:ClickName(row.line, button)
    end)
    senderHit:SetScript('OnMouseWheel', function(_, delta)
        messages:Scroll(delta)
    end)
    senderHit:Hide()
    row.senderHit = senderHit

    local editing = window.frame and window.frame.editor and window.frame.editor:IsShown()
    row:EnableMouse(not editing)
    senderHit:EnableMouse(not editing)
    row:SetHyperlinksEnabled(true)
    if row.SetHyperlinkPropagateToParent then
        row:SetHyperlinkPropagateToParent(true)
    end
    if nativeLinks then
        row:SetScript('OnHyperlinkClick', nil)
    else
        row:SetScript('OnHyperlinkClick', function(_, link, linkText, button)
            composer:ClickLink(link, linkText, button)
        end)
        row:SetScript('OnHyperlinkEnter', function(self, link)
            composer:ShowLinkTooltip(self, link)
        end)
        row:SetScript('OnHyperlinkLeave', function()
            GameTooltip:Hide()
        end)
    end
    row:SetScript('OnMouseWheel', function(_, delta)
        messages:Scroll(delta)
    end)
    window:BindMoveTarget(row)

    local span = CreateFrame('Frame', nil, parent)
    span:EnableMouse(false)
    span:SetFrameLevel(parent:GetFrameLevel() + 1)
    row:SetFrameLevel(parent:GetFrameLevel() + 2)
    senderHit:SetFrameLevel(row:GetFrameLevel() + 5)
    span:Hide()
    row.span = span

    return row
end

function messages:FillRow(row, line)
    local pattern = Chat():GetTimestampPattern()
    local timeSize = Chat():GetTimestampFontSize()
    local font = FontPath()
    local r, g, b
    if line.plain then
        r, g, b = 1, 1, 1
    else
        r, g, b = util.MessageColor(line.chatType, line.channel)
    end
    local tr, tg, tb = Chat():GetTimestampColor()

    row.line = line
    if line.marker then
        row.time:Hide()
        row.senderHit:Hide()
        row.nameProxy:Hide()
        row.text:SetFont(font, 13, 'OUTLINE')
        if row.text.SetIndentedWordWrap then
            row.text:SetIndentedWordWrap(false)
        end
        row.text:SetWordWrap(true)
        row.text:SetText(line.message or '')
        local mr, mg, mb = 0.62, 0.58, 0.52
        local muted = EXFrames and EXFrames.Theme and EXFrames.Theme.textMuted
        if muted then
            mr, mg, mb = muted[1], muted[2], muted[3]
        end
        row.text:SetTextColor(mr, mg, mb)
        row.stampPlace = 'none'
        row.insetLeft = 0
        row.insetRight = 0
        row.textJustify = Chat():GetMessageAlign() == 'right' and 'RIGHT' or 'LEFT'
        row.text:SetJustifyH(row.textJustify)
        return
    end
    row.time:SetFont(font, timeSize, 'OUTLINE')
    row.text:SetFont(font, 13, 'OUTLINE')
    row.text:SetTextColor(r, g, b)
    if row.text.SetIndentedWordWrap then
        row.text:SetIndentedWordWrap(false)
    end
    row.text:SetWordWrap(true)
    row.text:SetNonSpaceWrap(true)
    local action = ACTION[line.chatType]
    if not row:IsShown() then
        row:Show()
    end

    local place = Chat():GetTimestampPlace()
    local stacked = place == 'above' or place == 'below'
    local messageRight = Chat():GetMessageAlign() == 'right'
    local stampRight = Chat():GetTimestampAlign() == 'right'
    local insetLeft = 0
    local insetRight = 0
    row.textJustify = messageRight and 'RIGHT' or 'LEFT'
    if pattern then
        local ok, stamp = pcall(date, pattern, util.LineWhen(line))
        if ok and type(stamp) == 'string' then
            if stacked or stampRight then
                stamp = stamp:gsub('%s+$', '')
            end
            row.time:SetText(stamp)
        else
            row.time:SetText('')
        end
        row.time:SetTextColor(tr, tg, tb)
        row.time:Show()
        row.stampWidth = self:TimestampWidth()
        row.stampRight = stampRight
        if stacked then
            row.time:SetJustifyH(stampRight and 'RIGHT' or 'LEFT')
            row.time:SetJustifyV('TOP')
            row.stampPlace = place
        else
            row.time:SetJustifyH('RIGHT')
            row.time:SetJustifyV('BOTTOM')
            row.stampPlace = 'beside'
            local reserved = row.stampWidth + 1
            if stampRight then
                insetRight = reserved
            else
                insetLeft = reserved
            end
        end
    else
        row.time:Hide()
        row.stampPlace = 'none'
    end
    row.insetLeft = insetLeft
    row.insetRight = insetRight

    local channelName
    local noticeLine = line.chatType == 'CHANNEL_NOTICE' or line.chatType == 'CHANNEL_NOTICE_USER'
    if not noticeLine and not IsSecret(line.channel) and type(line.channel) == 'string' and line.channel ~= '' then
        channelName = '[' .. line.channel .. ']'
    elseif not line.motd and Chat():ShowChannelTags() then
        local tag = util.TypeTag(line.chatType)
        if tag then
            channelName = '[' .. tag .. ']'
        end
    end

    local body = action
    if not action then
        if HasText(line.message) then
            body = line.message
        else
            body = ''
        end
    end
    local statusLine = formatter.IsStatusLine(line.chatType)
    local keepLinks = false
    if statusLine and not action then
        body, keepLinks = formatter.StatusTextWithPlayerLinks(body)
    end

    local hasSender = false
    if not statusLine and line.chatType ~= 'TEXT_EMOTE' then
        if IsSecret(line.sender) then
            hasSender = true
        elseif line.sender ~= nil and line.sender ~= '' then
            hasSender = true
        end
    end
    local plainName
    local linkedName
    if hasSender then
        plainName = util.ShortName(line.sender)
        linkedName = formatter.NameLink(line, plainName)
    end
    formatter.SetLineText(row.text, channelName, linkedName, body, messageRight, action, keepLinks)
    row.text:SetJustifyH(row.textJustify)
    PlaceSenderHit(row, channelName, plainName, messageRight)
end

function messages:PlaceRow(row, anchorRow)
    local text = row.text
    local time = row.time
    local span = row.span
    local clip = window.clip
    if not text or not span or not clip then
        return
    end
    local left = row.insetLeft or 0
    local right = row.insetRight or 0
    local place = row.stampPlace
    local showStamp = place ~= 'none' and time and time:IsShown()
    local gap = anchorRow and 6 or 0

    text:ClearAllPoints()
    if time then
        time:ClearAllPoints()
    end
    span:ClearAllPoints()

    if place == 'below' and showStamp then
        if anchorRow and anchorRow.span then
            time:SetPoint('BOTTOMLEFT', anchorRow.span, 'TOPLEFT', 0, gap)
            time:SetPoint('BOTTOMRIGHT', anchorRow.span, 'TOPRIGHT', 0, gap)
        else
            time:SetPoint('BOTTOMLEFT', clip, 'BOTTOMLEFT', 0, 0)
            time:SetPoint('BOTTOMRIGHT', clip, 'BOTTOMRIGHT', 0, 0)
        end
        time:SetJustifyH(row.stampRight and 'RIGHT' or 'LEFT')
        text:SetPoint('BOTTOMLEFT', time, 'TOPLEFT', left, 2)
        text:SetPoint('BOTTOMRIGHT', time, 'TOPRIGHT', -right, 2)
        span:SetPoint('TOPLEFT', text, 'TOPLEFT', -left, 0)
        span:SetPoint('BOTTOMRIGHT', time, 'BOTTOMRIGHT', 0, 0)
    else
        local target = clip
        local pointL, pointR = 'BOTTOMLEFT', 'BOTTOMRIGHT'
        if anchorRow and anchorRow.span then
            target = anchorRow.span
            pointL, pointR = 'TOPLEFT', 'TOPRIGHT'
        end
        text:SetPoint('BOTTOMLEFT', target, pointL, left, gap)
        text:SetPoint('BOTTOMRIGHT', target, pointR, -right, gap)
        if place == 'above' and showStamp then
            time:SetPoint('BOTTOMLEFT', text, 'TOPLEFT', -left, 2)
            time:SetPoint('BOTTOMRIGHT', text, 'TOPRIGHT', right, 2)
            time:SetJustifyH(row.stampRight and 'RIGHT' or 'LEFT')
            span:SetPoint('TOPLEFT', time, 'TOPLEFT', 0, 0)
            span:SetPoint('BOTTOMRIGHT', text, 'BOTTOMRIGHT', right, 0)
        else
            if place == 'beside' and showStamp then
                time:SetWidth(row.stampWidth or 8)
                time:SetJustifyH('RIGHT')
                time:SetJustifyV('BOTTOM')
                if row.stampRight then
                    time:SetPoint('BOTTOMRIGHT', text, 'TOPRIGHT', right, -13)
                else
                    time:SetPoint('BOTTOMLEFT', text, 'TOPLEFT', -left, -13)
                end
            end
            span:SetPoint('TOPLEFT', text, 'TOPLEFT', -left, 0)
            span:SetPoint('BOTTOMRIGHT', text, 'BOTTOMRIGHT', right, 0)
        end
    end

    span:Show()
    row:ClearAllPoints()
    row:SetPoint('TOPLEFT', span, 'TOPLEFT', 0, 0)
    row:SetPoint('BOTTOMRIGHT', span, 'BOTTOMRIGHT', 0, 0)
    text:SetJustifyH(row.textJustify or 'LEFT')
end

function messages:AcquireRow()
    for _, row in ipairs(self.rows) do
        if not row.boundLine then
            return row
        end
    end
    local row = self:CreateRow(window.clip)
    self.rows[#self.rows + 1] = row
    return row
end

function messages:ReleaseLine(line)
    local row = line and line.row
    if not row then
        return
    end
    if row.boundLine == line then
        row.boundLine = nil
    end
    row.line = nil
    row.placed = nil
    row:Hide()
    if row.span then
        row.span:Hide()
    end
    line.row = nil
end

function messages:EnsureLineRow(line)
    if not window.clip or not line then
        return nil
    end
    local row = line.row
    if row and row.boundLine == line then
        return row
    end
    row = self:AcquireRow()
    if row.boundLine and row.boundLine.row == row then
        row.boundLine.row = nil
    end
    row.boundLine = line
    line.row = row
    self:FillRow(row, line)
    return row
end

function messages:Layout(keepRows)
    if not window.clip or self.layingOut then
        return
    end
    self.fadeGateAt = nil
    self.layingOut = true
    local ok, err = pcall(self.LayoutNow, self, keepRows)
    self.layingOut = false
    if not ok and not self.layoutFailed then
        self.layoutFailed = true
        if geterrorhandler then
            geterrorhandler()(err)
        end
    end
end

function messages:LayoutNow(keepRows)
    local lines = history:MatchingLines()
    local tab = history:ActiveTab()
    local limit = window.clip:GetHeight()
    if IsSecret(limit) or type(limit) ~= 'number' or limit < 1 then
        limit = self:RowHeight()
    end
    local total = #lines
    local scroll = tab.scroll or 0
    if scroll < 0 then
        scroll = 0
    end
    local maxScroll = total - 1
    if maxScroll < 0 then
        maxScroll = 0
    end
    if scroll > maxScroll then
        scroll = maxScroll
    end

    local minRow = self:RowHeight()
    if minRow < 1 then
        minRow = 1
    end
    local slots = math.floor(limit / minRow) + 2
    if slots < 2 then
        slots = 2
    end
    local anchor
    local placedCount = 0
    local holding = scroll > 0
    for _, row in ipairs(self.rows) do
        row.placed = nil
    end
    local last = total - scroll
    for index = last, 1, -1 do
        local line = lines[index]
        if line then
            local alpha = 1
            if not holding then
                alpha = self:LineAlpha(line)
                if alpha <= 0 then
                    break
                end
            end
            if placedCount >= slots then
                break
            end
            local existing = line.row and line.row.boundLine == line
            local row = self:EnsureLineRow(line)
            if not row then
                break
            end
            row.placed = true
            row.line = line
            if existing and not keepRows then
                self:FillRow(row, line)
            end
            self:PlaceRow(row, anchor)
            row.fadeAlpha = alpha
            row:SetAlpha(alpha)
            row:SetShown(alpha > 0)
            anchor = row
            placedCount = placedCount + 1
        end
    end

    for _, row in ipairs(self.rows) do
        if not row.placed then
            if row.boundLine and row.boundLine.row == row then
                row.boundLine.row = nil
            end
            row.boundLine = nil
            row.line = nil
            row.fadeAlpha = 1
            row:SetAlpha(1)
            row:Hide()
            if row.span then
                row.span:Hide()
            end
        end
    end

    tab.scroll = scroll
    if window.scrollButton then
        window.scrollButton:SetShown(scroll > 0)
    end
end

function messages:Scroll(delta)
    local tab = history:ActiveTab()
    if delta > 0 then
        tab.scroll = (tab.scroll or 0) + 1
    else
        tab.scroll = (tab.scroll or 0) - 1
        if tab.scroll < 0 then
            tab.scroll = 0
        end
    end
    self:ResetFade()
    self:Layout()
end

function messages:ScrollToBottom()
    local tab = history:ActiveTab()
    if tab then
        tab.scroll = 0
    end
    self:ResetFade()
    self:Layout()
end

function messages:ResetFade()
    self.fadeReset = GetTime()
    self.fadeGateAt = nil
end

-- Skips the per-frame pass until the next visible line starts fading; Layout/ResetFade clear the gate.
function messages:RefreshFade(delay)
    delay = delay or Chat():GetHideAfter()
    local now = GetTime()
    if self.fadeGateAt and self.fadeDelay == delay and now < self.fadeGateAt then
        return
    end
    self.fadeDelay = delay
    local tab = history:ActiveTab()
    local scrolled = tab and (tab.scroll or 0) > 0
    local gate = math.huge
    local collapsed = false
    for _, row in ipairs(self.rows) do
        if row.placed and row.line then
            local alpha = self:LineAlpha(row.line, delay, scrolled, now)
            if alpha <= 0 then
                collapsed = true
            else
                if row.fadeAlpha ~= alpha then
                    row.fadeAlpha = alpha
                    row:SetAlpha(alpha)
                end
                if alpha < 1 then
                    gate = now
                elseif not scrolled then
                    local clock = self:LineClock(row.line)
                    if clock and clock + delay - FADE_DURATION < gate then
                        gate = clock + delay - FADE_DURATION
                    end
                end
            end
        end
    end
    self.fadeGateAt = gate
    if collapsed then
        self:Layout()
    end
end

function messages:LineClock(line)
    local clock = line and line.clock
    if type(clock) ~= 'number' then
        return nil
    end
    local reset = self.fadeReset
    if type(reset) == 'number' and reset > clock then
        clock = reset
    end
    return clock
end

function messages:LineAlpha(line, delay, scrolled, now)
    delay = delay or Chat():GetHideAfter()
    if delay <= 0 then
        return 1
    end
    if scrolled == nil then
        local tab = history:ActiveTab()
        scrolled = tab and (tab.scroll or 0) > 0
    end
    if scrolled then
        return 1
    end
    local clock = self:LineClock(line)
    if not clock then
        return 1
    end
    local age = (now or GetTime()) - clock
    if age >= delay then
        return 0
    end
    if age > delay - FADE_DURATION then
        return (delay - age) / FADE_DURATION
    end
    return 1
end

function messages:SetMouse(enabled)
    for _, row in ipairs(self.rows) do
        row:EnableMouse(enabled)
        row.senderHit:EnableMouse(enabled)
    end
end
