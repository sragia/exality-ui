---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

core.tabs = nil
core.tabOptions = nil
core.options = {}
core.currTabId = nil
core.currItemId = nil
core.currItem = nil
core.fields = {}

core.Init = function(self)
    optionsController:RegisterModule(self, self.OptionHandler)
    ufCore:SetDefaultsForUnit('general', {
        ['useCustomHealthColor'] = false,
        ['customHealthColor'] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        ['useClassColoredBackdrop'] = false,
        ['useCustomBackdropColor'] = false,
        ['customBackdropColor'] = {r = 0.5, g = 0.5, b = 0.5, a = 1},
        ['statusBarTexture'] = 'ExalityUI Status Bar'
    })
end

core.GetName = function(self)
    return 'Unit Frames'
end

core.GetOrder = function(self)
    return 60
end

core.SetupTabs = function(self, container)
    local tabs = EXUI:GetModule('tabs-frame'):Create()
    tabs:SetParent(container)
    tabs:SetPoint('TOPLEFT', 5, 0)
    tabs:SetPoint('BOTTOMRIGHT', -5, 5)

    local tabOptions = EXUI:GetModule('split-options-frame'):Create()
    tabOptions:SetParent(tabs.container)
    tabOptions:SetPoint('TOPLEFT', tabs.container, 'TOPLEFT', 5, -5)
    tabOptions:SetPoint('BOTTOMRIGHT', tabs.container, 'BOTTOMRIGHT', -5, 5)
    tabOptions:UpdateScroll()

    self.tabs = tabs
    self.tabOptions = tabOptions
end

core.OptionHandler = function(container, shouldHide)
    if (shouldHide) then
        if (core.tabs) then
            core.tabs:Destroy()
            core.tabOptions:Destroy()
            core.tabs = nil
            core.tabOptions = nil
            for _, field in pairs(core.fields) do
                field:Destroy()
            end
            core.fields = {}
        end
        return;
    end
    if (not core.tabs) then
        core:SetupTabs(container)
    end

    local tabs = {}
    for _, option in ipairs(core.options) do
        table.insert(tabs, {
            ID = option.id,
            label = option.name
        })
    end
    core.tabs:AddTabs(tabs)
    core.tabs:SetOnTabChange(function(id) core:OnTabChange(id) end)
    core.tabs:onTabClick(tabs[1].ID)
end

core.OnTabChange = function(self, id)
    self.currTabId = id
    local _, option = FindInTableIf(self.options, function(option) return option.id == id end)
    if (option) then
        local items = {}
        for _, item in ipairs(option.menu) do
            table.insert(items, {
                ID = item.id,
                label = item.name
            })
        end

        self.tabOptions:AddItems(items)
        if (option.allowPreview) then
            local onClick = {}

            onClick.show = function(self, button)
                ufCore:ForceShow(option.id)
                button:SetText('Hide Preview')
                button:SetOnClick(onClick.hide)
            end
            onClick.hide = function(self, button)
                ufCore:Unforce(option.id)
                button:SetText('Show Preview')
                button:SetOnClick(onClick.show)
            end

            self.tabOptions:AddExtraButton({
                text = 'Show Preview',
                onClick = onClick.show,
                color = {249/255, 95/255, 9/255, 1}
            })
        else
            self.tabOptions:DisableExtraButton()
        end
        self.tabOptions:SetOnItemChange(function(id) self:OnItemChange(id) end)
        self.tabOptions:onItemClick(items[1].ID)
    end
end

core.OnItemChange = function(self, id)
    self.currItemId = id
    local _, tab = FindInTableIf(self.options, function(tab) return tab.id == self.currTabId end)
    local _, item = FindInTableIf(tab.menu, function(item) return item.id == id end)
    self.currItem = item
    self:HandleOptions()
end

core.HandleOptions = function(self)
    local container = self.tabOptions.container
    local menu = self.currItem
    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    self.fields = {}

    for _, option in ipairs(menu.options) do
        if (type(option) == 'function') then
            local fields = option(container)
            for _, field in ipairs(fields) do
                if (not field.depends or field.depends()) then
                    local fieldFrame = EXUI:GetModule('options-fields'):GetField(field)
                    if (fieldFrame) then
                        fieldFrame:SetOptionData(field)
                        fieldFrame:SetParent(container)
                        table.insert(self.fields, fieldFrame)
                    end
                end
            end
        elseif (type(option) == 'table') then
            if (not option.depends or option.depends()) then
                local fieldFrame = EXUI:GetModule('options-fields'):GetField(option)
                if (fieldFrame) then
                    fieldFrame:SetOptionData(option)
                    fieldFrame:SetParent(container)
                    table.insert(self.fields, fieldFrame)
                end
            end
        end
    end
    EXUI.utils.organizeFramesInGrid('UFfields', self.fields, 10, container, 10, 10)
end

core.AddOption = function(self, option)
    table.insert(self.options, option)
end

core.RefreshCurrentView = function(self)
    C_Timer.After(0.3, function() -- Small delay to allow inputs to finish animating
        self:HandleOptions()
    end)
end