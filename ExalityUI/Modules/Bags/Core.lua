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

---@class EXUIBankWindow
local bankWindow = EXUI:GetModule('bags-bank-window')

---@class EXUIBagsSlots
local slots = EXUI:GetModule('bags-slots')

---@class EXUIBagsPins
local pins = EXUI:GetModule('bags-pins')

---@class EXUIBags
local bags = EXUI:GetModule('bags')

bags.enabled = false
bags.created = false
bags.eventsRegistered = false
bags.bankEventsRegistered = false
bags.originals = {}
bags.suppressing = false
bags.hidingBankFrame = false
bags.closingBank = false

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

local BANK_SHOWN_EVENTS = {
    'BAG_UPDATE_DELAYED',
    'BAG_UPDATE_COOLDOWN',
    'ITEM_LOCK_CHANGED',
    'BANK_TABS_CHANGED',
    'PLAYERBANKSLOTS_CHANGED',
    'PLAYER_ACCOUNT_BANK_TAB_SLOTS_CHANGED',
    'ACCOUNT_MONEY',
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
    return 55
end

bags.GetIcon = function()
    return [[Interface/Addons/ExalityUI/Assets/Images/Menu/bags.png]]
end

bags.GetProfileExportSpec = function()
    return { id = 'bags', keys = { 'bags' } }
end

bags.GetDefaults = function()
    return {
        enable = false,
        slotSize = 32,
        columns = 14,
        spacing = 5,
        bankSlotSize = 32,
        bankColumns = 32,
        bankSpacing = 5,
        pinnedItems = {},
        posX = nil,
        posY = nil,
        bankPosX = nil,
        bankPosY = nil,
    }
end

bags.GetLayoutSettings = function(self, which)
    if which == 'bank' then
        return {
            slotSize = self.Data:GetValue('bankSlotSize') or 32,
            columns = self.Data:GetValue('bankColumns') or 32,
            spacing = self.Data:GetValue('bankSpacing') or 5,
        }
    end
    return {
        slotSize = self.Data:GetValue('slotSize') or 32,
        columns = self.Data:GetValue('columns') or 14,
        spacing = self.Data:GetValue('spacing') or 5,
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
        {
            type = 'title',
            label = 'Bank',
            width = 100,
        },
        {
            type = 'range',
            label = 'Slot Size',
            name = 'bankSlotSize',
            min = 24,
            max = 56,
            step = 1,
            width = 33,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('bankSlotSize')
            end,
            onChange = function(value)
                self.Data:SetValue('bankSlotSize', value)
                self:RefreshBank()
            end,
        },
        {
            type = 'range',
            label = 'Max Per Row',
            name = 'bankColumns',
            min = 6,
            max = 32,
            step = 1,
            width = 33,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('bankColumns')
            end,
            onChange = function(value)
                self.Data:SetValue('bankColumns', value)
                self:RefreshBank()
            end,
        },
        {
            type = 'range',
            label = 'Spacing',
            name = 'bankSpacing',
            min = 0,
            max = 12,
            step = 1,
            width = 34,
            depends = enabled,
            currentValue = function()
                return self.Data:GetValue('bankSpacing')
            end,
            onChange = function(value)
                self.Data:SetValue('bankSpacing', value)
                self:RefreshBank()
            end,
        },
    }
end

bags.EnsureCreated = function(self)
    if self.created then
        return
    end
    window:Create()
    bankWindow:Create()
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

    self:HookBankFrame()
end

bags.HideBlizzardBank = function(self)
    if not BankFrame or not self.suppressing then
        return
    end
    self.hidingBankFrame = true
    if BankFrame:IsShown() then
        BankFrame:Hide()
    end
    if BankPanel and BankPanel:IsShown() then
        BankPanel:Hide()
    end
    self.hidingBankFrame = false
end

local BANK_INTERACTIONS = {
    Enum.PlayerInteractionType.Banker,
    Enum.PlayerInteractionType.CharacterBanker,
    Enum.PlayerInteractionType.AccountBanker,
}

bags.TakeOverBankInteraction = function(self)
    if not RegisterPlayerInteraction or self.bankInteractionTaken then
        return
    end

    local function showBank()
        if not bags.enabled then
            return
        end
        if C_Bank.AreAnyBankTypesViewable and not C_Bank.AreAnyBankTypesViewable() then
            C_Bank.CloseBankFrame()
            if UIErrorsFrame and ERR_BANK_NOT_ACCESSIBLE then
                UIErrorsFrame:AddExternalErrorMessage(ERR_BANK_NOT_ACCESSIBLE)
            end
            return
        end
        bags:OpenBank()
        bags:Open()
    end

    local function hideBank()
        bags.closingBank = true
        bags:CloseBank(true)
        bags.closingBank = false
    end

    for i = 1, #BANK_INTERACTIONS do
        RegisterPlayerInteraction(BANK_INTERACTIONS[i], {
            frame = 'EXUIBankFrame',
            showFunc = showBank,
            hideFunc = hideBank,
        })
    end
    self.bankInteractionTaken = true
end

bags.RestoreBankInteraction = function(self)
    if not RegisterPlayerInteraction or not self.bankInteractionTaken then
        return
    end
    if BankFrame_Open then
        for i = 1, #BANK_INTERACTIONS do
            RegisterPlayerInteraction(BANK_INTERACTIONS[i], {
                frame = 'BankFrame',
                showFunc = BankFrame_Open,
            })
        end
    end
    self.bankInteractionTaken = false
end

bags.HookBankFrame = function(self)
    self:TakeOverBankInteraction()

    if not BankFrame or BankFrame.exuiBankHooked then
        return
    end

    local originalOnHide = BankFrame:GetScript('OnHide')
    BankFrame:SetScript('OnHide', function(frame, ...)
        if bags.hidingBankFrame then
            return
        end
        if originalOnHide then
            originalOnHide(frame, ...)
        end
    end)

    BankFrame:HookScript('OnShow', function()
        if not bags.enabled or not bags.suppressing then
            return
        end
        bags:HideBlizzardBank()
    end)

    BankFrame.exuiBankHooked = true
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
            slots:BindPlayerSlots(window.content)
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

bags.RegisterBankEvents = function(self)
    if self.bankAlwaysRegistered then
        return
    end
    EXUI:RegisterEventHandler({ 'BANKFRAME_OPENED', 'BANKFRAME_CLOSED' }, 'bags-bank', function(event)
        if not self.enabled then
            return
        end
        if event == 'BANKFRAME_OPENED' then
            self:OpenBank()
            self:Open()
        elseif event == 'BANKFRAME_CLOSED' then
            self.closingBank = true
            bankWindow:Hide(true)
            self.closingBank = false
        end
    end)
    self.bankAlwaysRegistered = true
end

bags.UnregisterBankEvents = function(self)
    if not self.bankAlwaysRegistered then
        return
    end
    EXUI:UnregisterEventHandler({ 'BANKFRAME_OPENED', 'BANKFRAME_CLOSED' }, 'bags-bank')
    self.bankAlwaysRegistered = false
end

bags.RegisterBankShownEvents = function(self)
    if self.bankEventsRegistered then
        return
    end
    EXUI:RegisterEventHandler(BANK_SHOWN_EVENTS, 'bags-bank-shown', function(event, ...)
        if not self:IsBankOpen() then
            return
        end
        if event == 'ITEM_LOCK_CHANGED' then
            local bagID, slotID = ...
            if bagID and slotID then
                slots:UpdateLock(bagID, slotID, 'bank')
            end
            return
        elseif event == 'BAG_UPDATE_COOLDOWN' then
            slots:UpdateVisibleCooldowns('bank')
            return
        elseif event == 'ACCOUNT_MONEY' then
            bankWindow:UpdateFooter()
            return
        end
        self:RefreshBank()
    end)
    self.bankEventsRegistered = true
end

bags.UnregisterBankShownEvents = function(self)
    if not self.bankEventsRegistered then
        return
    end
    EXUI:UnregisterEventHandler(BANK_SHOWN_EVENTS, 'bags-bank-shown')
    self.bankEventsRegistered = false
end

bags.OnBankShown = function(self)
    self:RegisterBankShownEvents()
end

bags.OnBankHidden = function(self)
    self:UnregisterBankShownEvents()
    StaticPopup_Hide('BANK_MONEY_DEPOSIT')
    StaticPopup_Hide('BANK_MONEY_WITHDRAW')
    StaticPopup_Hide('CONFIRM_BUY_BANK_TAB')
    if self.closingBank then
        return
    end
    if C_Bank and C_Bank.CloseBankFrame then
        self.closingBank = true
        C_Bank.CloseBankFrame()
        self.closingBank = false
    end
end

bags.IsOpen = function(self)
    return window:IsShown()
end

bags.IsBankOpen = function(self)
    return bankWindow:IsShown()
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

bags.OpenBank = function(self)
    if not self.enabled then
        return
    end
    self:EnsureCreated()
    self:HookBankFrame()
    self:HideBlizzardBank()
    bankWindow:Show()
end

bags.CloseBank = function(self, immediate)
    bankWindow:Hide(immediate)
end

bags.Toggle = function(self)
    if self:IsOpen() then
        self:Close()
    else
        self:Open()
    end
end

bags.RefreshBank = function(self, immediate)
    if not self.enabled or not self.created or not self:IsBankOpen() then
        return
    end
    if immediate then
        self.bankLayoutPending = false
        bankWindow:LayoutIfNeeded()
        return
    end
    if self.bankLayoutPending then
        return
    end
    self.bankLayoutPending = true
    C_Timer.After(0, function()
        self.bankLayoutPending = false
        if self.enabled and self:IsBankOpen() then
            bankWindow:LayoutIfNeeded()
        end
    end)
end

bags.Refresh = function(self)
    if not self.enabled or not self.created then
        return
    end
    if self:IsOpen() then
        slots:EnsurePool(window.content)
        window:LayoutIfNeeded()
    end
    if self:IsBankOpen() then
        self:RefreshBank()
    end
end

bags.Enable = function(self)
    if self.enabled then
        return
    end
    self.enabled = true
    self:EnsureCreated()
    self:ReplaceBlizzard()
    self:RegisterBankEvents()
    slots:EnsurePool(window.content)
    slots:BindPlayerSlots(window.content)
    EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'bags-ready', function()
        if not self.enabled then
            return
        end
        self:HookBankFrame()
        slots:EnsurePool(window.content)
        slots:BindPlayerSlots(window.content)
        slots:UpdateBagBar()
        if self:IsOpen() then
            self:Refresh()
        end
    end)
    EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'bags-untaint', function()
        if not self.enabled then
            return
        end
        slots:BindPlayerSlots(window.content)
        if self:IsOpen() then
            self:Refresh()
        end
    end)
    EXUI:RegisterEventHandler('ADDON_LOADED', 'bags-bank-hook', function(_, name)
        if not self.enabled then
            return
        end
        if name == 'Blizzard_UIPanels_Game' or BankFrame then
            self:HookBankFrame()
        end
    end)
end

bags.Disable = function(self)
    if not self.enabled then
        return
    end
    self.closingBank = true
    self:CloseBank(true)
    self.closingBank = false
    self:Close(true)
    self:UnregisterBankEvents()
    self:RestoreBankInteraction()
    self:RestoreBlizzard()
    EXUI:UnregisterEventHandler('PLAYER_ENTERING_WORLD', 'bags-ready')
    EXUI:UnregisterEventHandler('PLAYER_REGEN_ENABLED', 'bags-untaint')
    EXUI:UnregisterEventHandler('ADDON_LOADED', 'bags-bank-hook')
    self.enabled = false
end
