local addonName = ...

---@class ExalityUI
local EXUI = select(2, ...)

local initIndx = 0

EXUI.modules = {}

---Get and Initialize a module
---@param self ExalityUI
---@param id any
---@return unknown
EXUI.GetModule = function(self, id)
    if (not self.modules[id]) then
        initIndx = initIndx + 1
        self.modules[id] = {
            _index = initIndx
        }
    end

    return self.modules[id]
end

EXUI.InitModules = function(self)
    for _, module in EXUI.utils.spairs(self.modules, function(t, a, b) return t[a]._index < t[b]._index end) do
        if (module.Init) then
            module:Init()
        end
    end
end

EXUI.handler = CreateFrame('Frame')
EXUI.handler:RegisterEvent('ADDON_LOADED')
EXUI.handler:RegisterEvent('PLAYER_LOGOUT')

EXUI.handler.eventHandlers = {
    --[[
    [event] = {
        [id] = function(event, ...)
    }
    ]]
}

---Register a new event handler
---@param self ExalityUI
---@param event string | string[]
---@param id any
---@param func function
EXUI.RegisterEventHandler = function(self, event, id, func)
    if (type(event) ~= 'table') then
        event = { event }
    end

    for _, event in ipairs(event) do
        if (not self.handler:IsEventRegistered(event)) then
            self.handler:RegisterEvent(event)
        end
        self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
        self.handler.eventHandlers[event][id] = func
    end
end

EXUI.UnregisterEventHandler = function(self, event, id)
    if (type(event) ~= 'table') then
        event = { event }
    end
    for _, event in ipairs(event) do
        self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
        self.handler.eventHandlers[event][id] = nil
        if (not next(self.handler.eventHandlers[event])) then
            self.handler:UnregisterEvent(event)
        end
    end
end

EXUI.handler:SetScript('OnEvent', function(self, event, ...)
    if (event == 'ADDON_LOADED' and ... == addonName) then
        EXUI:InitModules()
    elseif (event == 'PLAYER_LOGOUT') then
        EXUI:GetModule('data'):Save()
    end

    if (self.eventHandlers[event]) then
        for id, func in pairs(self.eventHandlers[event]) do
            func(event, ...)
        end
    end
end)


--- Callbacks
--[[
    {
        events = { 'event1', 'event2' },
        func = function(event, ...)
    }
]]
EXUI.callbacks = {}

EXUI.RegisterCallback = function(self, config)
    table.insert(EXUI.callbacks, config)
end

EXUI.Callback = function(self, event, ...)
    for _, callback in ipairs(self.callbacks) do
        if (FindInTable(callback.events, event)) then
            callback.func(event, ...)
        end
    end
end
