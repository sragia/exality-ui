---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

-------------

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

optionsFields.baseContainer = nil
optionsFields.container = nil
optionsFields.splitView = nil
optionsFields.tabs = nil
optionsFields.innerTabs = nil
optionsFields.currTabID = nil
optionsFields.currItemID = nil
optionsFields.fields = {}

optionsFields.Init = function(self)
    EXUI.utils.addObserver(self)

    optionsController:Observe('selectedModule', function(value)
        self:Refresh()
    end)
end

optionsFields.Create = function(self, container)
    self.container = container
    self.baseContainer = container

    self:Refresh()
end

optionsFields.AddSplitView = function(self, module)
    self.splitView = EXFrames:GetFrame('split-options-frame'):Create()
    if (self.tabs) then
        self.splitView:SetParent(self.tabs.container)
        self.splitView:SetAllPoints()
    else
        self.splitView:SetParent(self.baseContainer)
        self.splitView:SetAllPoints()
    end
    self.splitView:UpdateScroll()

    if (module.splitViewExtraButton) then
        self.splitView:AddExtraButton(module.splitViewExtraButton)
    else
        self.splitView:DisableExtraButton()
    end
    local items = module:GetSplitViewItems()
    self.splitView:AddItems(items)
    self.splitView:SetOnItemChange(function(id)
        self.currItemID = id
        -- Inner-tab modules (e.g. Action Bars) reuse currTabID for section tabs.
        -- Modules with outer tabs + splitViewTabID (e.g. Minimap Buttons) must keep currTabID.
        if module.useInnerTabs then
            self.currTabID = nil
        end
        if self:HasInnerTabs(module, id) then
            self:AddInnerTabs(module)
        else
            self:ClearInnerTabs()
            self:UseSplitViewContainer()
        end
        self:RefreshFields()
    end)
    if (#items > 0) then
        local found = false
        for _, item in ipairs(items) do
            if (item.ID == self.currItemID) then
                self.splitView:onItemClick(item.ID)
                found = true
                break
            end
        end
        if (not found) then
            self.splitView:onItemClick(items[1].ID)
        end
    end

    if (not module.useInnerTabs) then
        self.container = self.splitView.container
        self.container.exuiAutoSizeHeight = true
    end
end

optionsFields.HasInnerTabs = function(self, module, itemId)
    if not module.useInnerTabs or not module.GetSectionTabs then
        return false
    end
    local tabs = module:GetSectionTabs(itemId or self.currItemID)
    return tabs and #tabs > 0
end

optionsFields.ClearInnerTabs = function(self)
    if self.innerTabs then
        self.innerTabs:Destroy()
        self.innerTabs = nil
    end
    if self.splitView and self.splitView.scrollFrame then
        self.splitView.scrollFrame:Show()
    end
end

optionsFields.UseSplitViewContainer = function(self)
    if self.splitView then
        self.container = self.splitView.container
        self.container.exuiAutoSizeHeight = true
    end
end

optionsFields.AddInnerTabs = function(self, module)
    if (self.innerTabs) then
        self.innerTabs:Destroy()
        self.innerTabs = nil
    end

    local rightPanel = self.splitView.rightPanel
    self.innerTabs = EXFrames:GetFrame('tabs-frame'):Create({ scrollable = true })
    self.innerTabs:SetParent(rightPanel)
    self.innerTabs:SetPoint('TOPLEFT', rightPanel, 'TOPLEFT', 5, -5)
    self.innerTabs:SetPoint('BOTTOMRIGHT', rightPanel, 'BOTTOMRIGHT', -5, 5)

    local tabs = module:GetSectionTabs(self.currItemID)
    self.innerTabs:AddTabs(tabs)
    self.innerTabs:SetOnTabChange(function(id)
        self.currTabID = id
        self:RefreshFields()
    end)

    if (#tabs > 0) then
        local found = false
        for _, tab in ipairs(tabs) do
            if (tab.ID == self.currTabID) then
                self.innerTabs:onTabClick(tab.ID)
                found = true
                break
            end
        end
        if (not found) then
            self.currTabID = tabs[1].ID
            self.innerTabs:onTabClick(tabs[1].ID)
        end
    end

    if (self.splitView.scrollFrame) then
        self.splitView.scrollFrame:Hide()
    end
    self.container = self.innerTabs.container
end

optionsFields.RefreshSplitViewForTab = function(self)
    local module = optionsController:GetSelectedModule()
    local currentModule = module and module.module
    if (not currentModule or not currentModule.useSplitView) then
        self:RefreshFields()
        return
    end

    local splitViewTabID = currentModule.splitViewTabID
    local shouldShow = not splitViewTabID or splitViewTabID == self.currTabID

    if (shouldShow and not self.splitView) then
        self:AddSplitView(currentModule)
    elseif (not shouldShow and self.splitView) then
        self.splitView:Destroy()
        self.splitView = nil
        self.currItemID = nil
        if (self.tabs) then
            self.container = self.tabs.container
        else
            self.container = self.baseContainer
        end
    end

    self:RefreshFields()
end

optionsFields.AddTabs = function(self, module)
    self.tabs = EXFrames:GetFrame('tabs-frame'):Create({ scrollable = true })
    self.tabs:SetParent(self.baseContainer)
    self.tabs:SetAllPoints()
    self.container = self.tabs.container

    local tabs = module:GetTabs()
    self.tabs:AddTabs(tabs)


    self.tabs:SetOnTabChange(function(id)
        self.currTabID = id
        local selected = optionsController:GetSelectedModule()
        if (selected and selected.module and selected.module.splitViewTabID) then
            self:RefreshSplitViewForTab()
        else
            self:RefreshFields()
        end
    end)

    if (#tabs > 0) then
        local found = false
        for _, tab in ipairs(tabs) do
            if (tab.ID == self.currTabID) then
                self.tabs:onTabClick(tab.ID)
                found = true
                break
            end
        end
        if (not found) then
            self.tabs:onTabClick(tabs[1].ID)
        end
    end
end

optionsFields.Refresh = function(self)
    local module = optionsController:GetSelectedModule()

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    for _, module in pairs(optionsController:GetAllModules()) do
        if (module.optionHandler) then
            module.optionHandler(self.container, true)
        end
    end
    if (self.splitView) then
        self.splitView:Destroy()
        self.splitView = nil
    end

    if (self.tabs) then
        self.tabs:Destroy()
        self.tabs = nil
    end

    if (self.innerTabs) then
        self.innerTabs:Destroy()
        self.innerTabs = nil
    end

    self.container = self.baseContainer
    self.fields = {}

    if (module.optionHandler) then
        module.optionHandler(self.container)
        return;
    end
    local currentModule = module.module

    if (currentModule) then
        if (currentModule.useTabs) then
            self:AddTabs(currentModule)
        end

        if (currentModule.useSplitView) then
            local splitViewTabID = currentModule.splitViewTabID
            if ((not splitViewTabID or splitViewTabID == self.currTabID) and not self.splitView) then
                self:AddSplitView(currentModule)
            end
            if (currentModule.useInnerTabs and self.splitView) then
                if self:HasInnerTabs(currentModule, self.currItemID) then
                    self:AddInnerTabs(currentModule)
                else
                    self:ClearInnerTabs()
                    self:UseSplitViewContainer()
                end
            end
        end
    end

    self:RefreshFields()
end

optionsFields.RefreshOptions = function(self)
    C_Timer.After(0.3, function()
        self:RefreshFields()
    end)
end

optionsFields.CreateOrUpdateTooltip = function(self, field, tooltipInfo)
    if (not field.Tooltip and tooltipInfo) then
        local tooltip = tooltip:Get({
            text = tooltipInfo.text,
        }, field)
        field.Tooltip = tooltip
        field.isTooltipEnabled = true

        field.OriginalOnEnter = field:GetScript('OnEnter')
        field.OriginalOnLeave = field:GetScript('OnLeave')

        field:SetScript('OnEnter', function(self, ...)
            if (self.isTooltipEnabled) then
                self.Tooltip:ShowTooltip()
            end
            if (self.OriginalOnEnter) then
                self.OriginalOnEnter(self, ...)
            end
        end)
        field:SetScript('OnLeave', function(self, ...)
            if (self.isTooltipEnabled) then
                self.Tooltip:HideTooltip()
            end
            if (self.OriginalOnLeave) then
                self.OriginalOnLeave(self, ...)
            end
        end)
    end

    if (tooltipInfo and tooltipInfo.text and tooltipInfo.text ~= '') then
        field.Tooltip:SetText(tooltipInfo.text)
        field.isTooltipEnabled = true
    else
        field.isTooltipEnabled = false
    end
end

optionsFields.RefreshFields = function(self)
    local module = optionsController:GetSelectedModule()
    local currentModule = module.module

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    self.fields = {}

    if self.splitView and self.container == self.splitView.container and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    end

    local fields = currentModule:GetOptions(self.currTabID, self.currItemID)
    for _, field in ipairs(fields) do
        if (type(field) == 'function') then
            local funcFields = field()
            if (funcFields) then
                for _, funcField in ipairs(funcFields) do
                    local fieldFrame = self:GetField(funcField)
                    self:CreateOrUpdateTooltip(fieldFrame, funcField.tooltip)
                    if (fieldFrame) then
                        fieldFrame:SetOptionData(funcField)
                        fieldFrame:SetParent(self.container)
                        table.insert(self.fields, fieldFrame)
                    end
                end
            end
        elseif (not field.depends or field.depends()) then
            local fieldFrame = self:GetField(field)
            self:CreateOrUpdateTooltip(fieldFrame, field.tooltip)
            if (fieldFrame) then
                fieldFrame:SetOptionData(field)
                fieldFrame:SetParent(self.container)
                table.insert(self.fields, fieldFrame)
            end
        end
    end

    EXUI.utils.organizeFramesInGrid('fields', self.fields, 10, self.container, 10, 10)
    if self.tabs and self.tabs.scrollable and self.tabs.UpdateScroll and self.container == self.tabs.container then
        self.tabs:UpdateScroll()
    elseif self.innerTabs and self.innerTabs.scrollable and self.innerTabs.UpdateScroll and self.container == self.innerTabs.container then
        self.innerTabs:UpdateScroll()
    elseif self.splitView and self.container == self.splitView.container and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    end
end

optionsFields.RefreshItemList = function(self)
    if (not self.splitView) then return end
    local module = optionsController:GetSelectedModule()
    if (not module or not module.module or not module.module.GetSplitViewItems) then return end
    local items = module.module:GetSplitViewItems()
    self.splitView:AddItems(items)
end

optionsFields.SetItemID = function(self, itemID)
    if (self.splitView) then
        self.splitView:onItemClick(itemID)
    end
end

optionsFields.GetField = function(self, field)
    return EXUI.utils.switch(field.type, {
        ['editbox'] = function()
            local f = EXFrames:GetFrame('edit-box-input'):Create({
                label = 'Edit Box',
                onChange = field.onChange,
                initial = field.currentValue and field.currentValue() or nil,
            })
            f:SetHeight(40)
            return f
        end,
        ['range'] = function()
            local f = EXFrames:GetFrame('range-input'):Create()
            f:SetOnChange(field.onChange)
            return f
        end,
        ['button'] = function()
            local f = EXFrames:GetFrame('button'):Create()
            return f
        end,
        ['toggle'] = function()
            local f = EXFrames:GetFrame('toggle'):Create({
                text = field.label,
                value = field.currentValue and field.currentValue() or false,
            })
            return f
        end,
        ['dropdown'] = function()
            local f = EXFrames:GetFrame('dropdown'):Create({})
            return f
        end,
        ['spacer'] = function()
            local f = EXFrames:GetFrame('spacer'):Create()
            return f
        end,
        ['color-picker'] = function()
            local f = EXFrames:GetFrame('color-picker'):Create()
            return f
        end,
        ['title'] = function()
            local f = EXFrames:GetFrame('title'):Create()
            return f
        end,
        ['description'] = function()
            local f = EXFrames:GetFrame('description'):Create()
            return f
        end,
        ['edit-box'] = function()
            local f = EXFrames:GetFrame('edit-box-input'):Create({})
            f:SetHeight(40)
            return f
        end,
        ['checkbox'] = function()
            local f = EXFrames:GetFrame('checkbox'):Create()
            return f
        end,
        ['custom-texts-list-item'] = function()
            local f = EXUI:GetModule('custom-texts-list-item'):Create()
            return f
        end,
        ['anchor-point'] = function()
            local f = EXFrames:GetFrame('anchor-point'):Create()
            return f
        end,
        default = function()
            EXUI.utils.printOut('Unknown Field Type: ' .. field.type)
        end
    })
end
