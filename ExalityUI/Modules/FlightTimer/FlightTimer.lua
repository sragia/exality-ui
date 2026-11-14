---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUITweaksAndBugfixes
local tweaksAndBugfixes = EXUI:GetModule('tweaks-and-bugfixes')

---@class EXUIFlightTimer
local flightTimer = EXUI:GetModule('flight-timer')

local DEFAULT_SPEED = 32
local TICK = 0.2
local START_TIMEOUT_TICKS = 25
local STOP_RADIUS = 0.015
local LANDING_RADIUS = 0.03
local OVERDUE_FACTOR = 1.25

flightTimer.isEnabled = false
flightTimer.session = nil

local function HopKey(fromID, toID)
    return fromID .. ':' .. toID
end

local function MapDistance(x1, y1, x2, y2)
    local dx, dy = x1 - x2, y1 - y2
    return math.sqrt(dx * dx + dy * dy)
end

local function GetSeed(fromID, toID)
    local seed = EXUI.flightTimerSeed
    return seed and fromID and toID and seed[fromID * 10000 + toID]
end

flightTimer.GetSpeed = function(self)
    if (self.speed) then return self.speed end

    local totalDistance, totalTime = 0, 0
    for key, seconds in pairs(data:GetFlightTimes().hops) do
        local fromID, toID = key:match('^(%d+):(%d+)$')
        local seed = GetSeed(tonumber(fromID), tonumber(toID))
        if (seed and seconds > seed[2]) then
            totalDistance = totalDistance + seed[1]
            totalTime = totalTime + seconds - seed[2]
        end
    end

    self.speed = totalTime > 30 and (totalDistance / totalTime) or DEFAULT_SPEED
    return self.speed
end

flightTimer.BuildEstimates = function(self, nodes)
    local learned = data:GetFlightTimes().hops
    local estimates, missing = {}, {}
    local knownSeconds, knownDistance = 0, 0

    for i = 1, #nodes - 1 do
        local from, to = nodes[i], nodes[i + 1]
        local seconds = from.id and to.id and learned[HopKey(from.id, to.id)]
        if (not seconds) then
            local seed = GetSeed(from.id, to.id)
            if (seed) then
                seconds = seed[1] / self:GetSpeed() + seed[2]
            end
        end

        local mapDistance = from.x and to.x and MapDistance(from.x, from.y, to.x, to.y)
        if (seconds) then
            estimates[i] = seconds
            if (mapDistance) then
                knownSeconds = knownSeconds + seconds
                knownDistance = knownDistance + mapDistance
            end
        elseif (mapDistance) then
            missing[i] = mapDistance
        end
    end

    if (knownDistance > 0) then
        for i, mapDistance in pairs(missing) do
            estimates[i] = mapDistance * knownSeconds / knownDistance
        end
    end

    return estimates
end

flightTimer.BuildRoute = function(self, slot)
    local numRoutes = GetNumRoutes(slot)
    if (not numRoutes or numRoutes < 1) then return end

    local taxiMapID = GetTaxiMapID and GetTaxiMapID()
    local nodeInfo = {}
    if (taxiMapID) then
        for _, info in ipairs(C_TaxiMap.GetAllTaxiNodes(taxiMapID) or {}) do
            nodeInfo[info.slotIndex] = info
        end
    end

    local slots = { TaxiGetNodeSlot(slot, 1, true) }
    for i = 1, numRoutes do
        table.insert(slots, TaxiGetNodeSlot(slot, i, false))
    end

    local nodes = {}
    for _, nodeSlot in ipairs(slots) do
        local info = nodeInfo[nodeSlot]
        local node = { name = TaxiNodeName(nodeSlot) }
        if (info) then
            node.id = info.nodeID
            node.x, node.y = info.position:GetXY()
        end
        table.insert(nodes, node)
    end

    return { nodes = nodes, taxiMapID = taxiMapID }
end

flightTimer.GetArrival = function(self, session, nodeIndex)
    local time = session.hopStart
    for hop = session.hopIndex, nodeIndex - 1 do
        local estimate = session.estimates[hop]
        if (not estimate) then return nil end
        time = time + estimate
    end
    return time
end

flightTimer.GetPlayerPosition = function(self, session)
    if (not session.taxiMapID) then return end
    local position = C_Map.GetPlayerMapPosition(session.taxiMapID, 'player')
    if (position) then
        return position:GetXY()
    end
end

flightTimer.StartSession = function(self, route, isPreview, hopStart)
    self:StopSession()

    self.session = {
        nodes = route.nodes,
        taxiMapID = route.taxiMapID,
        estimates = route.estimates or self:BuildEstimates(route.nodes),
        hopIndex = 1,
        hopStart = hopStart or GetTime(),
        durations = {},
        isPreview = isPreview,
    }
    self.display:Show(self.session)

    if (not isPreview) then
        self.ticker = C_Timer.NewTicker(TICK, function() self:OnFlightTick() end)
    end
end

flightTimer.StopSession = function(self)
    if (self.ticker) then
        self.ticker:Cancel()
        self.ticker = nil
    end
    self.session = nil
    self.display:Hide()
end

flightTimer.StartPreview = function(self)
    self:StartSession({
        nodes = { { name = 'Departure' }, { name = 'Halfway Point' }, { name = 'Destination' } },
        estimates = { 45, 75 },
    }, true, GetTime() - 15)
end

flightTimer.ArriveAtStop = function(self, session, time, isDetected)
    if (isDetected and not session.isStartGuessed) then
        session.durations[session.hopIndex] = time - session.hopStart
    end
    session.hopIndex = session.hopIndex + 1
    session.hopStart = time
    session.isStartGuessed = not isDetected
    session.closest = nil
    session.closestTime = nil
end

flightTimer.OnFlightTick = function(self)
    local session = self.session
    if (not session) then return end

    if (not UnitOnTaxi('player')) then
        self:FinishFlight(session)
        return
    end

    local nextIndex = session.hopIndex + 1
    if (nextIndex >= #session.nodes) then return end

    local now = GetTime()
    local nextNode = session.nodes[nextIndex]
    local x, y
    if (nextNode.x) then
        x, y = self:GetPlayerPosition(session)
    end

    if (x) then
        local distance = MapDistance(x, y, nextNode.x, nextNode.y)
        if (distance < STOP_RADIUS and (not session.closest or distance < session.closest)) then
            session.closest = distance
            session.closestTime = now
        elseif (session.closest and distance > session.closest) then
            self:ArriveAtStop(session, session.closestTime, true)
            return
        end
    end

    local estimate = session.estimates[session.hopIndex]
    if (estimate and not session.closest and now - session.hopStart > estimate * OVERDUE_FACTOR) then
        self:ArriveAtStop(session, now)
    end
end

flightTimer.FinishFlight = function(self, session)
    local destination = session.nodes[#session.nodes]
    local landed = session.hopIndex == #session.nodes - 1
    if (landed and destination.x) then
        local x, y = self:GetPlayerPosition(session)
        landed = x ~= nil and MapDistance(x, y, destination.x, destination.y) < LANDING_RADIUS
    end
    if (landed and not session.isStartGuessed) then
        session.durations[session.hopIndex] = GetTime() - session.hopStart
    end

    local hops = data:GetFlightTimes().hops
    for hop, seconds in pairs(session.durations) do
        local from, to = session.nodes[hop], session.nodes[hop + 1]
        if (from.id and to.id and seconds > 0) then
            local key = HopKey(from.id, to.id)
            local value = hops[key] and (hops[key] + seconds) / 2 or seconds
            hops[key] = math.floor(value * 10 + 0.5) / 10
        end
    end
    self.speed = nil

    self:StopSession()
end

flightTimer.OnTakeTaxiNode = function(self, slot)
    if (not self.isEnabled) then return end

    local route = self:BuildRoute(slot)
    if (not route) then return end

    if (self.startTicker) then
        self.startTicker:Cancel()
    end
    local ticks = 0
    self.startTicker = C_Timer.NewTicker(TICK, function(ticker)
        ticks = ticks + 1
        if (UnitOnTaxi('player')) then
            ticker:Cancel()
            self.startTicker = nil
            self:StartSession(route)
        elseif (ticks >= START_TIMEOUT_TICKS) then
            ticker:Cancel()
            self.startTicker = nil
        end
    end)
end

flightTimer.Enable = function(self)
    self.isEnabled = true
    if (not self.isHooked) then
        hooksecurefunc('TakeTaxiNode', function(slot) self:OnTakeTaxiNode(slot) end)
        self.isHooked = true
    end
    self.display:Create()
    self.display:RegisterEditor()
end

flightTimer.Disable = function(self)
    self.isEnabled = false
    if (self.startTicker) then
        self.startTicker:Cancel()
        self.startTicker = nil
    end
    self:StopSession()
    self.display:UnregisterEditor()
end

tweaksAndBugfixes:RegisterTweak('flight-timer', {
    name = 'Flight timer',
    type = 'tweak',
    description =
    'Shows a bar with flight progress, intermediate stops and time left while on a flight path. Times get more accurate as you fly. Can be moved in the editor.',
    enable = function()
        flightTimer:Enable()
    end,
    disable = function()
        flightTimer:Disable()
    end,
})
