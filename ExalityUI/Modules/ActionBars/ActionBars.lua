---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIActionBarsDefaults
local barDefaults = EXUI:GetModule('action-bars-defaults')

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

---@class EXUIActionBarsGlobalOptions
local globalOptions = EXUI:GetModule('action-bars-global-options')

---@class EXUIActionBarsBarOptions
local barOptions = EXUI:GetModule('action-bars-bar-options')

---@class EXUIActionBarsMicroMenuOptions
local microMenuOptions = EXUI:GetModule('action-bars-micro-menu-options')

---@class EXUIActionBarsBagsOptions
local bagsOptions = EXUI:GetModule('action-bars-bags-options')

---@class EXUIActionBarsModule
local actionBars = EXUI:GetModule('action-bars')

actionBars.Data = data:GetControlsForKey('action-bars')
actionBars.enabled = false
actionBars.useTabs = false
actionBars.useSplitView = true
actionBars.useInnerTabs = true

actionBars.GetDB = function(self)
    local db = self.Data:GetDB()
    barDefaults:MergeIntoDB(db)
    self.Data:SetDB(db)
    return db
end

actionBars.Init = function(self)
    self.Data:UpdateDefaults({ enable = false })
    local db = self:GetDB()
    self.Data:SetDB(db)

    manager:Init()
    optionsController:RegisterModule(self)

    if self.Data:GetValue('enable') then
        self:Enable()
    end
end

actionBars.GetName = function()
    return 'Action Bars'
end

actionBars.GetOrder = function()
    return 30
end

actionBars.GetSplitViewItems = function(self)
    local items = {
        { ID = 'general', label = 'General' },
    }

    for _, barId in ipairs(definitions.PLAYER_BAR_IDS) do
        table.insert(items, { ID = barId, label = definitions:Get(barId).label })
    end
    for _, barId in ipairs(definitions.SPECIAL_BAR_IDS) do
        table.insert(items, { ID = barId, label = definitions:Get(barId).label })
    end
    table.insert(items, { ID = 'microMenu', label = 'Micro Menu' })
    table.insert(items, { ID = 'bags', label = 'Bag Bar' })
    return items
end

actionBars.GetSectionTabs = function(self, itemId)
    itemId = itemId or 'general'
    if itemId == 'general' then
        return {
            { ID = 'module', label = 'Module' },
            { ID = 'buttons', label = 'Buttons' },
            { ID = 'text', label = 'Text' },
        }
    end
    if itemId == 'microMenu' or itemId == 'bags' then
        return {}
    end
    if definitions:Get(itemId) then
        return barOptions:GetSectionTabs(itemId)
    end
    return {}
end

---@param currTabID string Section tab (layout, module, etc.)
---@param currItemID string Split view item (general, bar1, etc.)
actionBars.GetOptions = function(self, currTabID, currItemID)
    local itemId = currItemID or 'general'
    local section = currTabID

    if itemId == 'general' then
        return globalOptions:GetOptions(self, section or 'module')
    end
    if itemId == 'microMenu' then
        return microMenuOptions:GetOptions(self)
    end
    if itemId == 'bags' then
        return bagsOptions:GetOptions(self)
    end
    if definitions:Get(itemId) then
        return barOptions:GetBarOptions(self, itemId, section or 'layout')
    end
    return {}
end

actionBars.Enable = function(self)
    if self.enabled then return end
    self.enabled = true
    manager:Enable()
end

actionBars.Disable = function(self)
    if not self.enabled then return end
    self.enabled = false
    manager:Disable()
end

actionBars.RefreshBars = function(self)
    if self.enabled then
        manager:RefreshAll()
    end
end

actionBars.RefreshBar = function(self, barId)
    if self.enabled then
        manager:RefreshBar(barId)
    end
end

actionBars.RefreshMicroMenu = function(self)
    if self.enabled then
        manager:ApplyMicroMenu()
    end
end

actionBars.OnEnableToggle = function(self, value)
    self.Data:SetValue('enable', value)
    if value then
        self:Enable()
    else
        self:Disable()
    end
    optionsReloadDialog:ShowDialog()
end

EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'action-bars', function()
    if actionBars.enabled then
        manager:CreateBars()
    end
end)
