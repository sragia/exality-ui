local addonName = ...

---@class ExalityUI
local EXUI = select(2, ...)

local initIndx = 0

EXUI.modules = {}
EXUI.elements = {}
EXUI.dataProviders = {}

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

EXUI.RegisterElementType = function(self, id, elementData)
    self.elements[id] = elementData
end

EXUI.RegisterDataProviderType = function(self, id, dataProviderData)
    self.dataProviders[id] = dataProviderData
end

EXUI.GetElementTypeById = function(self, id)
    if (self.elements[id]) then
        return self.elements[id]
    end
    return nil
end

EXUI.GetAllElementTypes = function(self)
    return self.elements
end

EXUI.GetDataProviderTypeById = function(self, id)
    if (self.dataProviders[id]) then
        return self.dataProviders[id]
    end
    return nil
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

EXUI.RegisterEventHandler = function(self, event, id, func)
    if (not self.handler.eventHandlers[event]) then
        self.handler:RegisterEvent(event)
    end
    self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
    self.handler.eventHandlers[event][id] = func
end

EXUI.UnregisterEventHandler = function(self, event, id)
    self.handler.eventHandlers[event] = self.handler.eventHandlers[event] or {}
    self.handler.eventHandlers[event][id] = nil
    if (not next(self.handler.eventHandlers[event])) then
        self.handler:UnregisterEvent(event)
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
