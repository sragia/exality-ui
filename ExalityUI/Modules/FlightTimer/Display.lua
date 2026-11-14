---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUITweaksAndBugfixes
local tweaksAndBugfixes = EXUI:GetModule('tweaks-and-bugfixes')

---@class EXUIFlightTimer
local flightTimer = EXUI:GetModule('flight-timer')

local ASSETS = 'Interface\\AddOns\\ExalityUI\\Assets\\Images\\FlightTimer\\'
local BASE_BAR_WIDTH = 300
local STOP_BAR_WIDTH = 110
local MIN_SEGMENT_WIDTH = 90
local MAIN_ICON_WIDTH, MAIN_ICON_HEIGHT = 49, 57
local UPDATE_INTERVAL = 0.1

local display = {}
flightTimer.display = display

local function FormatTime(seconds)
    if (not seconds) then return '--:--' end
    seconds = math.max(0, math.floor(seconds + 0.5))
    return string.format('%02d:%02d', math.floor(seconds / 60), seconds % 60)
end

local function SplitName(name)
    local town, zone = string.match(name or '', '^(.-),%s*(.+)$')
    if (town) then
        return town, zone
    end
    return name
end

local function CreateText(parent, size, r, g, b)
    local text = parent:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    text:SetTextColor(r, g, b)
    text:SetWordWrap(false)
    return text
end

local function SetEndpointName(nameText, zoneText, icon, fullName)
    local town, zone = SplitName(fullName)
    nameText:SetText(town)
    zoneText:SetText(zone or '')
    zoneText:SetShown(zone ~= nil)
    zoneText:ClearAllPoints()
    zoneText:SetPoint('BOTTOM', icon, 'TOP', 0, 2)
    nameText:ClearAllPoints()
    if (zone) then
        nameText:SetPoint('BOTTOM', zoneText, 'TOP', 0, 1)
    else
        nameText:SetPoint('BOTTOM', icon, 'TOP', 0, 2)
    end
end

display.GetPositionValue =function(self, key, default)
    local value = tweaksAndBugfixes.Data:GetValue(key)
    if (value == nil) then return default end
    return value
end

display.UpdatePosition = function(self)
    if (not self.frame or editor:IsEditorEnabled()) then return end
    self.frame:ClearAllPoints()
    self.frame:SetPoint(
        self:GetPositionValue('flightTimerAnchor', 'TOP'),
        UIParent,
        self:GetPositionValue('flightTimerRelativeAnchor', 'TOP'),
        self:GetPositionValue('flightTimerXOff', 0),
        self:GetPositionValue('flightTimerYOff', -120)
    )
end

display.Create = function(self)
    if (self.frame) then return end

    local frame = CreateFrame('Frame', nil, UIParent)
    frame:SetSize(BASE_BAR_WIDTH + MAIN_ICON_WIDTH, 110)
    frame:SetFrameStrata('MEDIUM')
    frame:Hide()
    self.frame = frame

    local bar = frame:CreateTexture(nil, 'BACKGROUND')
    bar:SetTexture(ASSETS .. 'progress-bar.png')
    bar:SetHeight(19)
    bar:SetPoint('LEFT', frame, 'LEFT', MAIN_ICON_WIDTH / 2, 0)
    self.bar = bar

    local startIcon = frame:CreateTexture(nil, 'ARTWORK', nil, 2)
    startIcon:SetTexture(ASSETS .. 'main-icon.png')
    startIcon:SetSize(MAIN_ICON_WIDTH, MAIN_ICON_HEIGHT)
    startIcon:SetPoint('CENTER', bar, 'LEFT')

    local endIcon = frame:CreateTexture(nil, 'ARTWORK', nil, 2)
    endIcon:SetTexture(ASSETS .. 'main-icon.png')
    endIcon:SetSize(MAIN_ICON_WIDTH, MAIN_ICON_HEIGHT)
    endIcon:SetPoint('CENTER', bar, 'RIGHT')

    self.startIcon = startIcon
    self.endIcon = endIcon
    self.startName = CreateText(frame, 13, 1, 1, 1)
    self.startZone = CreateText(frame, 11, 0.7, 0.7, 0.7)
    self.endName = CreateText(frame, 13, 1, 1, 1)
    self.endZone = CreateText(frame, 11, 0.7, 0.7, 0.7)
    self.endTimer = CreateText(frame, 12, 0.8, 0.8, 0.8)
    self.endTimer:SetPoint('TOP', endIcon, 'BOTTOM', 0, -2)

    local dot = frame:CreateTexture(nil, 'ARTWORK', nil, 3)
    dot:SetTexture(ASSETS .. 'progress-dot.png')
    dot:SetSize(29, 29)
    self.dot = dot

    self.stops = {}

    frame:SetScript('OnUpdate', function(_, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if (self.elapsed < UPDATE_INTERVAL) then return end
        self.elapsed = 0
        self:Update()
    end)

    self:UpdatePosition()
end

display.GetStop = function(self, index)
    if (self.stops[index]) then return self.stops[index] end

    local icon = self.frame:CreateTexture(nil, 'ARTWORK', nil, 1)
    icon:SetTexture(ASSETS .. 'flight-point.png')
    icon:SetSize(17, 17)

    local name = CreateText(self.frame, 10, 1, 1, 1)
    name:SetPoint('TOP', icon, 'BOTTOM', 0, -2)
    name:SetWidth(STOP_BAR_WIDTH - 10)

    local zone = CreateText(self.frame, 9, 0.7, 0.7, 0.7)
    zone:SetPoint('TOP', name, 'BOTTOM', 0, -1)
    zone:SetWidth(STOP_BAR_WIDTH - 10)

    local timer = CreateText(self.frame, 10, 0.8, 0.8, 0.8)

    local stop = { icon = icon, name = name, zone = zone, timer = timer }
    self.stops[index] = stop
    return stop
end

display.RegisterEditor = function(self)
    if (editor:IsFrameRegistered(self.frame)) then return end
    editor:RegisterFrameForEditor(self.frame, 'Flight Timer', function(f)
        editor:PersistAnchoredPosition(f, function(point, relativePoint, xOff, yOff)
            tweaksAndBugfixes.Data:SetValue('flightTimerAnchor', point)
            tweaksAndBugfixes.Data:SetValue('flightTimerRelativeAnchor', relativePoint)
            tweaksAndBugfixes.Data:SetValue('flightTimerXOff', xOff)
            tweaksAndBugfixes.Data:SetValue('flightTimerYOff', yOff)
        end, function()
            self:UpdatePosition()
        end)
    end, function()
        if (not flightTimer.session) then
            flightTimer:StartPreview()
        end
    end, function()
        if (flightTimer.session and flightTimer.session.isPreview) then
            flightTimer:StopSession()
        end
    end)
end

display.UnregisterEditor = function(self)
    if (self.frame and editor:IsFrameRegistered(self.frame)) then
        editor:UnregisterFrameForEditor(self.frame)
    end
end

display.Layout = function(self, session)
    local nodes = session.nodes
    local numHops = #nodes - 1
    local barWidth = BASE_BAR_WIDTH + STOP_BAR_WIDTH * (numHops - 1)

    local total, known = 0, true
    for i = 1, numHops do
        if (session.estimates[i]) then
            total = total + session.estimates[i]
        else
            known = false
        end
    end

    local flexible = barWidth - MIN_SEGMENT_WIDTH * numHops
    self.positions = { 0 }
    for i = 1, numHops do
        local share = (known and total > 0) and (session.estimates[i] / total) or (1 / numHops)
        self.positions[i + 1] = self.positions[i] + MIN_SEGMENT_WIDTH + flexible * share
    end

    self.bar:SetWidth(barWidth)
    self.frame:SetWidth(barWidth + MAIN_ICON_WIDTH)

    SetEndpointName(self.startName, self.startZone, self.startIcon, nodes[1].name)
    SetEndpointName(self.endName, self.endZone, self.endIcon, nodes[#nodes].name)

    for i = numHops, #self.stops do
        local stop = self.stops[i]
        stop.icon:Hide()
        stop.name:Hide()
        stop.zone:Hide()
        stop.timer:Hide()
    end
    for i = 2, numHops do
        local stop = self:GetStop(i - 1)
        stop.icon:ClearAllPoints()
        stop.icon:SetPoint('CENTER', self.bar, 'LEFT', self.positions[i], 0)
        local town, zone = SplitName(nodes[i].name)
        stop.name:SetText(town)
        stop.zone:SetText(zone or '')
        stop.zone:SetShown(zone ~= nil)
        stop.timer:ClearAllPoints()
        stop.timer:SetPoint('TOP', zone and stop.zone or stop.name, 'BOTTOM', 0, -1)
        stop.icon:Show()
        stop.name:Show()
        stop.timer:Show()
    end
end

display.Show = function(self, session)
    self:Create()
    self:Layout(session)
    self:Update()
    self.frame:Show()
end

display.Hide = function(self)
    if (self.frame) then
        self.frame:Hide()
    end
end

display.Update = function(self)
    local session = flightTimer.session
    if (not session) then return end

    local now = GetTime()
    local numNodes = #session.nodes

    for i = 2, numNodes do
        local passed = session.hopIndex >= i
        local remaining = not passed and flightTimer:GetArrival(session, i)
        if (remaining) then
            remaining = remaining - now
        end

        if (i == numNodes) then
            self.endTimer:SetText(FormatTime(remaining))
        else
            local stop = self:GetStop(i - 1)
            stop.icon:SetAlpha(passed and 0.4 or 1)
            stop.name:SetAlpha(passed and 0.5 or 1)
            stop.zone:SetAlpha(passed and 0.5 or 1)
            stop.timer:SetShown(not passed)
            stop.timer:SetText(FormatTime(remaining))
        end
    end

    local hop = session.hopIndex
    local estimate = session.estimates[hop]
    local progress = 0
    if (estimate and estimate > 0) then
        progress = math.min((now - session.hopStart) / estimate, 0.98)
    end
    local x = self.positions[hop] + (self.positions[hop + 1] - self.positions[hop]) * progress
    self.dot:ClearAllPoints()
    self.dot:SetPoint('CENTER', self.bar, 'LEFT', x, 0)
end
