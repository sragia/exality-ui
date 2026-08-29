---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIBagsWindow
local window = EXUI:GetModule('bags-window')

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBagsPins
local pins = EXUI:GetModule('bags-pins')

---@class EXUIBags
local bags = EXUI:GetModule('bags')

bags.enabled = false
bags.created = false
bags.eventsRegistered = false
bags.originals = {}
bags.suppressing = false

local PLAYER_BAG_MIN = Enum.BagIndex.Backpack
local PLAYER_BAG_MAX = Enum.BagIndex.ReagentBag

local REPLACE_GLOBALS = {
    'ToggleAllBags',
    'OpenAllBags',
    'CloseAllBags',
    'ToggleBackpack',
    'OpenBackpack',
    'CloseBackpack',
    'ToggleBag',
    'OpenBag',
    'CloseBag',
    'IsBagOpen',
    'IsAnyBagOpen',
}

local SHOWN_EVENTS = {
    'BAG_UPDATE_DELAYED',
    'BAG_UPDATE_COOLDOWN',
    'ITEM_LOCK_CHANGED',
    'BAG_CONTAINER_UPDATE',
    'PLAYER_MONEY',
    'CURRENCY_DISPLAY_UPDATE',
}

local function IsPlayerBag(id)
    if id == nil then
        return true
    end
    return id >= PLAYER_BAG_MIN and id <= PLAYER_BAG_MAX
end

local function CanOpen()
    if ContainerFrame_AllowedToOpenBags then
        return ContainerFrame_AllowedToOpenBags()
    end
    return true
end

bags.Data = data:GetControlsForKey('bags')

bags.Init = function(self)
    self.Data:UpdateDefaults(self:GetDefaults())
    optionsController:RegisterModule(self)
    if self.Data:GetValue('enable') then
        if IsLoggedIn() then
            self:Enable()
        else
            EXUI:RegisterEventHandler('PLAYER_LOGIN', 'bags-enable', function()
                if self.Data:GetValue('enable') then
                    self:Enable()
                end
            end)
        end
    end
end

bags.GetName = function()
    return 'Bags'
end

bags.GetOrder = function()
    return 35
end

bags.GetIcon = function()
    return [[Interface/Addons/ExalityUI/Assets/Images/Menu/custom-windows.png]]
end

bags.GetProfileExportSpec = function()
    return { id = 'bags', keys = { 'bags' } }
end

bags.GetDefaults = function()
    return {
        enable = false,
        slotSize = 36,
        columns = 10,
        spacing = 4,
        pinnedItems = {},
        posX = nil,
        posY = nil,
    }
end

bags.GetLayoutSettings = function(self)
    return {
        slotSize = self.Data:GetValue('slotSize') or 36,
        columns = self.Data:GetValue('columns') or 10,
        spacing = self.Data:GetValue('spacing') or 4,
    }
end

bags.GetOptions = function(self)
    local enabled = function()
        return self.Data:GetValue('enable')
    end
    return {
        {
            type = 'title',
            label = 'Bags',
            width = 100,
        },
        {
            type = 'toggle',
            label = 'Enable',
            name = 'enable',
            width = 100,
            currentValue = function()
                return self.Data:GetValue('enable')
            end,
            onChange = function(value)
                self.Data:SetValue('enable', value)
                optionsFields:RefreshOptions()
                if value then
                    self:Enable()
                else
                    self:Disable()
                end
            end,
        },
        {
            type = 'range',
            label = 'Slot Size',
            name = 'slotSize',
            min = 24,
            max = 56,
            step = 1,
            width = 33,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('slotSize')
            end,
            onChange = function(value)
                self.Data:SetValue('slotSize', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'Max Per Row',
            name = 'columns',
            min = 6,
            max = 16,
            step = 1,
            width = 33,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('columns')
            end,
            onChange = function(value)
                self.Data:SetValue('columns', value)
                self:Refresh()
            end,
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'spacing',
            min = 0,
            max = 12,
            step = 1,
            width = 34,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('spacing')
            end,
            onChange = function(value)
                self.Data:SetValue('spacing', value)
                self:Refresh()
            end,
        },
    }
end

bags.EnsureCreated = function(self)
    if self.created then
        return
    end
    window:Create()
    self.created = true
end

bags.SuppressBlizzardFrames = function(self, enabled)
    self.suppressing = enabled
    local function hideIfEnabled(frame)
        if not frame then
            return
        end
        if not frame.exuiBagsHooked then
            frame:HookScript('OnShow', function(selfFrame)
                if bags.suppressing then
                    selfFrame:Hide()
                end
            end)
            frame.exuiBagsHooked = true
        end
        if enabled and frame:IsShown() then
            frame:Hide()
        end
    end

    hideIfEnabled(ContainerFrameCombinedBags)
    local count = NUM_CONTAINER_FRAMES or 13
    for i = 1, count do
        hideIfEnabled(_G['ContainerFrame' .. i])
    end
end

bags.ReplaceBlizzard = function(self)
    if self.replaced then
        return
    end
    for i = 1, #REPLACE_GLOBALS do
        local name = REPLACE_GLOBALS[i]
        self.originals[name] = _G[name]
    end

    _G.ToggleAllBags = function()
        if not CanOpen() then
            return
        end
        self:Toggle()
    end

    _G.OpenAllBags = function(_, forceUpdate)
        if not CanOpen() then
            return
        end
        if self:IsOpen() then
            if forceUpdate then
                self:Refresh()
            end
            return
        end
        self:Open()
    end

    _G.CloseAllBags = function()
        local wasOpen = self:IsOpen()
        self:Close()
        return wasOpen
    end

    _G.ToggleBackpack = function()
        if not CanOpen() then
            return
        end
        self:Toggle()
    end

    _G.OpenBackpack = function()
        if not CanOpen() then
            return
        end
        self:Open()
    end

    _G.CloseBackpack = function()
        local wasOpen = self:IsOpen()
        self:Close()
        return wasOpen
    end

    _G.ToggleBag = function(id)
        if IsPlayerBag(id) then
            if not CanOpen() then
                return
            end
            self:Toggle()
            return
        end
        if self.originals.ToggleBag then
            return self.originals.ToggleBag(id)
        end
    end

    _G.OpenBag = function(id, force)
        if IsPlayerBag(id) then
            if not CanOpen() then
                return
            end
            self:Open()
            return
        end
        if self.originals.OpenBag then
            return self.originals.OpenBag(id, force)
        end
    end

    _G.CloseBag = function(id)
        if IsPlayerBag(id) then
            local wasOpen = self:IsOpen()
            self:Close()
            return wasOpen
        end
        if self.originals.CloseBag then
            return self.originals.CloseBag(id)
        end
    end

    _G.IsBagOpen = function(id)
        if IsPlayerBag(id) then
            return self:IsOpen()
        end
        if self.originals.IsBagOpen then
            return self.originals.IsBagOpen(id)
        end
        return false
    end

    _G.IsAnyBagOpen = function()
        if self:IsOpen() then
            return true
        end
        if self.originals.IsAnyBagOpen then
            return self.originals.IsAnyBagOpen()
        end
        return false
    end

    self:SuppressBlizzardFrames(true)
    self.replaced = true
end

bags.RestoreBlizzard = function(self)
    if not self.replaced then
        return
    end
    for i = 1, #REPLACE_GLOBALS do
        local name = REPLACE_GLOBALS[i]
        if self.originals[name] then
            _G[name] = self.originals[name]
        end
    end
    self:SuppressBlizzardFrames(false)
    self.replaced = false
end

bags.RegisterShownEvents = function(self)
    if self.eventsRegistered then
        return
    end
    EXUI:RegisterEventHandler(SHOWN_EVENTS, 'bags-shown', function(event, ...)
        if not self:IsOpen() then
            return
        end
        if event == 'ITEM_LOCK_CHANGED' then
            local bagID, slotID = ...
            if bagID and slotID then
                slots:UpdateLock(bagID, slotID)
                pins:UpdateLock(bagID, slotID)
            end
            return
        elseif event == 'BAG_UPDATE_COOLDOWN' then
            slots:UpdateVisibleCooldowns()
            pins:UpdateCooldowns()
            return
        elseif event == 'PLAYER_MONEY' or event == 'CURRENCY_DISPLAY_UPDATE' then
            window:UpdateFooter()
            return
        elseif event == 'BAG_CONTAINER_UPDATE' then
            slots:EnsurePool(window.content)
        end
        self:Refresh()
    end)
    self.eventsRegistered = true
end

bags.UnregisterShownEvents = function(self)
    if not self.eventsRegistered then
        return
    end
    EXUI:UnregisterEventHandler(SHOWN_EVENTS, 'bags-shown')
    self.eventsRegistered = false
end

bags.OnShown = function(self)
    self:RegisterShownEvents()
end

bags.OnHidden = function(self)
    self:UnregisterShownEvents()
end

bags.IsOpen = function(self)
    return window:IsShown()
end

bags.Open = function(self)
    if not self.enabled then
        return
    end
    self:EnsureCreated()
    window:Show()
end

bags.Close = function(self, immediate)
    window:Hide(immediate)
end

bags.Toggle = function(self)
    if self:IsOpen() then
        self:Close()
    else
        self:Open()
    end
end

bags.Refresh = function(self)
    if not self.enabled or not self.created then
        return
    end
    if not self:IsOpen() then
        return
    end
    slots:EnsurePool(window.content)
    window:Layout()
end

bags.Enable = function(self)
    if self.enabled then
        return
    end
    self.enabled = true
    self:EnsureCreated()
    self:ReplaceBlizzard()
    EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'bags-ready', function()
        if not self.enabled then
            return
        end
        slots:EnsurePool(window.content)
        slots:UpdateBagBar()
        if self:IsOpen() then
            self:Refresh()
        end
    end)
end

bags.Disable = function(self)
    if not self.enabled then
        return
    end
    self:Close(true)
    self:RestoreBlizzard()
    EXUI:UnregisterEventHandler('PLAYER_ENTERING_WORLD', 'bags-ready')
    self.enabled = false
end
