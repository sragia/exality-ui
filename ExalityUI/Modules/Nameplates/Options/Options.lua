---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUINameplatesOptions
local options = EXUI:GetModule('np-options')

local TABS = {
    { id = 'general', name = 'General', module = 'np-options-general' },
    { id = 'behavior', name = 'Behavior', module = 'np-options-behavior' },
    { id = 'health', name = 'Health', module = 'np-options-health' },
    { id = 'castbar', name = 'Cast Bar', module = 'np-options-cast-bar' },
    { id = 'texts', name = 'Texts', module = 'np-options-texts' },
    { id = 'indicators', name = 'Indicators', module = 'np-options-indicators' },
    { id = 'auras', name = 'Auras', module = 'np-options-auras' },
}

options.tabs = nil
options.tabOptions = nil
options.fields = {}
options.currTabId = nil
options.currItemId = nil

local function findTab(id)
    for _, tab in ipairs(TABS) do
        if tab.id == id then
            return tab
        end
    end
end

local function getTabMenu(tab)
    local mod = tab and EXUI:GetModule(tab.module)
    if mod and mod.GetMenu then
        return mod:GetMenu()
    end
    return {}
end

local function findMenuItem(menu, id)
    for _, item in ipairs(menu) do
        if item.id == id then
            return item
        end
    end
end

function options:TeardownOptions()
    local preview = EXUI:GetModule('np-preview')
    if preview and preview.Hide then
        preview:Hide()
    end
    if self.tabOptions then
        self.tabOptions:Destroy()
        self.tabOptions = nil
    end
    if self.tabs then
        self.tabs:Destroy()
        self.tabs = nil
    end
    for _, field in pairs(self.fields) do
        if field.Destroy then
            field:Destroy()
        end
    end
    self.fields = {}
end

function options:GetCurrentOptions()
    local tab = findTab(self.currTabId)
    local item = findMenuItem(getTabMenu(tab), self.currItemId)
    if not item then
        return {}
    end
    if type(item.options) == 'function' then
        return item.options() or {}
    end
    return item.options or {}
end

function options:HandleOptions()
    if not self.tabOptions then
        return
    end
    local container = self.tabOptions.container
    for _, field in pairs(self.fields) do
        if field.Destroy then
            field:Destroy()
        end
    end
    self.fields = {}

    if self.tabOptions.scrollFrame then
        self.tabOptions.scrollFrame:Show()
    end
    self.tabOptions:UpdateScroll()

    for _, option in ipairs(self:GetCurrentOptions()) do
        if not option.depends or option.depends() then
            local fieldFrame = EXUI:GetModule('options-fields'):GetField(option)
            if fieldFrame then
                EXUI:GetModule('options-fields'):CreateOrUpdateTooltip(fieldFrame, option.tooltip)
                fieldFrame:SetOptionData(option)
                fieldFrame:SetParent(container)
                table.insert(self.fields, fieldFrame)
            end
        end
    end
    EXUI.utils.organizeFramesInGrid('NPfields', self.fields, 10, container, 10, 10)
    self.tabOptions:UpdateScroll()
    EXUI:GetModule('np-preview'):Refresh()
end

function options:OnItemChange(id)
    self.currItemId = id
    self:HandleOptions()
end

function options:OnTabChange(id)
    self.currTabId = id
    local menu = getTabMenu(findTab(id))
    local items = {}
    for _, item in ipairs(menu) do
        table.insert(items, { ID = item.id, label = item.name })
    end
    self.tabOptions:AddItems(items)
    self.tabOptions:SetOnItemChange(function(itemId)
        options:OnItemChange(itemId)
    end)

    local found = false
    for _, item in ipairs(items) do
        if item.ID == self.currItemId then
            self.tabOptions:onItemClick(item.ID)
            found = true
            break
        end
    end
    if not found and items[1] then
        self.tabOptions:onItemClick(items[1].ID)
    end
end

function options:RefreshCurrentView()
    C_Timer.After(0.05, function()
        if self.tabOptions then
            self:HandleOptions()
        end
    end)
end

function options:Setup(container)
    self.tabs = EXFrames:GetFrame('tabs-frame'):Create()
    self.tabs:SetParent(container)
    self.tabs:SetPoint('TOPLEFT', 5, 0)
    self.tabs:SetPoint('BOTTOMRIGHT', -5, 5)

    self.tabOptions = EXFrames:GetFrame('split-options-frame'):Create()
    self.tabOptions:SetParent(self.tabs.container)
    self.tabOptions:SetPoint('TOPLEFT', self.tabs.container, 'TOPLEFT', 5, -5)
    self.tabOptions:SetPoint('BOTTOMRIGHT', self.tabs.container, 'BOTTOMRIGHT', -5, 5)
    self.tabOptions.container.exuiAutoSizeHeight = true
    if self.tabOptions.scrollFrame then
        self.tabOptions.scrollFrame:Show()
    end

    local tabs = {}
    for _, tab in ipairs(TABS) do
        table.insert(tabs, { ID = tab.id, label = tab.name })
    end
    self.tabs:AddTabs(tabs)
    self.tabs:SetOnTabChange(function(id)
        options:OnTabChange(id)
    end)

    local found = false
    for _, tab in ipairs(tabs) do
        if tab.ID == self.currTabId then
            self.tabs:onTabClick(tab.ID)
            found = true
            break
        end
    end
    if not found then
        self.tabs:onTabClick(tabs[1].ID)
    end

    C_Timer.After(0, function()
        if options.tabOptions and options.currItemId then
            options:HandleOptions()
        end
    end)

    EXUI:GetModule('np-preview'):Show()
end

function options.OptionHandler(container, shouldHide)
    if shouldHide then
        options:TeardownOptions()
        return
    end
    options:TeardownOptions()
    options:Setup(container)
end
