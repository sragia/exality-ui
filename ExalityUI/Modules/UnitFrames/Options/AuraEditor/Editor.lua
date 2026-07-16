---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIUnitFramesAuras
local ufAuras = EXUI:GetModule('uf-auras')

---@class EXUIUnitFramesAurasDefaults
local ufAuraDefaults = EXUI:GetModule('uf-auras-defaults')

---@class EXUIUFAuraEditorContainerOptions
local containerOptions = EXUI:GetModule('uf-aura-editor-container-options')

---@class EXUIUFAuraEditorVisualOptions
local visualOptions = EXUI:GetModule('uf-aura-editor-visual-options')

---@class EXUIUFAuraEditorConditionsOptions
local conditionsOptions = EXUI:GetModule('uf-aura-editor-conditions-options')

---@class EXUIUFAuraEditorLoadOptions
local loadOptions = EXUI:GetModule('uf-aura-editor-load-options')

---@class EXUIUFAuraEditorGroupNav
local groupNav = EXUI:GetModule('uf-aura-editor-group-nav')

---@class EXUIUnitFramesAurasPreview
local ufPreview = EXUI:GetModule('uf-auras-preview')

---@class EXUIUnitFramesAuraEditor
local editor = EXUI:GetModule('uf-aura-editor')

editor.window = nil
editor.splitView = nil
editor.innerTabs = nil
editor.unitSelector = nil
editor.fields = {}
editor.currItemID = nil
editor.currTabID = nil
editor.contextUnit = nil
editor._suppressItemChange = false
editor._suppressUnitChange = false

local SECTION_TABS = {
    { ID = 'container', label = 'Container' },
    { ID = 'visual', label = 'Visual' },
    { ID = 'conditions', label = 'Conditions' },
    { ID = 'load', label = 'Load' },
}

function editor:CreateWindow()
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 920, 650 },
        title = 'Unit Frame Aura Editor',
    })
    return window
end

function editor:GetOptions(tabID, displayID)
    if not displayID then
        return {}
    end
    if tabID == 'container' then
        return containerOptions:GetOptions(displayID)
    elseif tabID == 'visual' then
        return visualOptions:GetOptions(displayID, ufAuras.currGroupID)
    elseif tabID == 'conditions' then
        return conditionsOptions:GetOptions(displayID, ufAuras.currGroupID)
    elseif tabID == 'load' then
        return loadOptions:GetOptions(displayID, ufAuras.currGroupID)
    end
    return {}
end

function editor:ClearFields()
    for _, field in ipairs(self.fields) do
        if field.Destroy then
            field:Destroy()
        else
            field:Hide()
            field:SetParent(nil)
        end
    end
    wipe(self.fields)
end

function editor:GetFieldsContainer()
    return self.innerTabs and self.innerTabs.container or (self.splitView and self.splitView.container)
end

function editor:GetFieldsLayoutWidth()
    if self.innerTabs and self.innerTabs.panel then
        return math.max(1, self.innerTabs.panel:GetWidth() - 30)
    end
    if self.splitView and self.splitView.rightPanel then
        return math.max(1, self.splitView.rightPanel:GetWidth() - 30)
    end
    return 600
end

function editor:PopulateFields()
    self:ClearFields()
    if not self.currItemID or not self.currTabID then
        return
    end

    local container = self:GetFieldsContainer()
    if not container then
        return
    end

    -- Size the scroll child from the panel width before laying out fields.
    if self.innerTabs and self.innerTabs.UpdateScroll then
        self.innerTabs:UpdateScroll()
    end
    local layoutWidth = self:GetFieldsLayoutWidth()
    if container.SetWidth and (not container:GetWidth() or container:GetWidth() < 50) then
        container:SetWidth(layoutWidth)
    end

    local options = self:GetOptions(self.currTabID, self.currItemID)
    for _, option in ipairs(options) do
        if not option.depends or option.depends() then
            local field = optionsFields:GetField(option)
            if field then
                optionsFields:CreateOrUpdateTooltip(field, option.tooltip)
                field:SetOptionData(option)
                field:SetParent(container)
                table.insert(self.fields, field)
            end
        end
    end

    EXUI.utils.organizeFramesInGrid('uf-aura-editor-fields', self.fields, 10, container, 10, 10)

    if self.innerTabs and self.innerTabs.UpdateScroll then
        self.innerTabs:UpdateScroll()
    elseif self.splitView and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    end
end

function editor:RelayoutFields()
    if not self.window or not self.window:IsShown() then
        return
    end
    if not self.fields or #self.fields == 0 then
        return
    end
    local container = self:GetFieldsContainer()
    if not container then
        return
    end
    EXUI.utils.organizeFramesInGrid('uf-aura-editor-fields', self.fields, 10, container, 10, 10)
    if self.innerTabs and self.innerTabs.UpdateScroll then
        self.innerTabs:UpdateScroll()
    elseif self.splitView and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    end
end

function editor:ClearInnerTabs()
    if self.innerTabs then
        self.innerTabs:Destroy()
        self.innerTabs = nil
    end
end

function editor:AddInnerTabs()
    self:ClearInnerTabs()
    if not self.splitView then
        return
    end

    self.innerTabs = EXFrames:GetFrame('tabs-frame'):Create({ scrollable = true })
    self.innerTabs:SetParent(self.splitView.rightPanel)
    self.innerTabs:SetPoint('TOPLEFT', self.splitView.rightPanel, 'TOPLEFT', 5, -5)
    self.innerTabs:SetPoint('BOTTOMRIGHT', self.splitView.rightPanel, 'BOTTOMRIGHT', -5, 5)
    if self.splitView.scrollFrame then
        self.splitView.scrollFrame:Hide()
    end

    self.innerTabs:AddTabs(SECTION_TABS)
    self.innerTabs:SetOnTabChange(function(id)
        self.currTabID = id
        self:PopulateFields()
    end)

    local found = false
    for _, tab in ipairs(SECTION_TABS) do
        if tab.ID == self.currTabID then
            self.innerTabs:onTabClick(tab.ID)
            found = true
            break
        end
    end
    if not found then
        self.currTabID = SECTION_TABS[1].ID
        self.innerTabs:onTabClick(self.currTabID)
    end
end

function editor:GetUnitOptions()
    local options = {}
    for index, unitKey in ipairs(ufAuraDefaults.UNIT_ORDER) do
        options[unitKey] = {
            label = ufAuraDefaults.UNIT_OPTIONS[unitKey] or unitKey,
            order = index,
        }
    end
    return options
end

function editor:UpdateTitle()
    if not self.window then
        return
    end
    local unitLabel = ufAuraDefaults.UNIT_OPTIONS[self.contextUnit]
        or EXUI.utils.capitalize(self.contextUnit)
        or self.contextUnit
    self.window:SetTitle('Unit Frame Aura Editor — ' .. unitLabel)
end

function editor:SetContextUnit(unit)
    if not unit or unit == self.contextUnit then
        return
    end

    -- Tear down previous unit's force-show / suppressed live auras.
    ufPreview:Clear()

    self.contextUnit = unit
    ufAuras.contextUnit = unit
    ufPreview:SetContext(unit)
    self.currItemID = nil
    if self.splitView then
        self.splitView.activeID = nil
    end
    self.currTabID = self.currTabID or 'container'
    self:UpdateTitle()
    self:SyncUnitSelector()
    self:Refresh()
end

function editor:SyncUnitSelector()
    if not self.unitSelector or not self.contextUnit then
        return
    end
    self._suppressUnitChange = true
    self.unitSelector:SetValue('value', self.contextUnit)
    self._suppressUnitChange = false
end

function editor:EnsureUnitSelector()
    if self.unitSelector or not self.window or not self.window.close then
        return
    end

    local dropdown = EXFrames:GetFrame('dropdown'):Create({
        label = '',
        width = 130,
        height = 28,
    })
    dropdown:SetParent(self.window)
    dropdown:SetFrameStrata(self.window:GetFrameStrata())
    dropdown:SetFrameLevel(self.window.close:GetFrameLevel() + 1)
    dropdown:SetOptionData({
        label = '',
        getOptions = function()
            return editor:GetUnitOptions()
        end,
        currentValue = function()
            return editor.contextUnit
        end,
        onChange = function(value)
            if editor._suppressUnitChange then
                return
            end
            editor:SetContextUnit(value)
        end,
    })
    if dropdown.SetLabel then
        dropdown:SetLabel('')
    end
    if dropdown.label then
        dropdown.label:Hide()
    end
    if dropdown.inputArea then
        dropdown.inputArea:ClearAllPoints()
        dropdown.inputArea:SetAllPoints()
    end
    dropdown:ClearAllPoints()
    dropdown:SetSize(EXFrames:ScalePixel(130, self.window), EXFrames:ScalePixel(28, self.window))
    dropdown:SetPoint('TOP', self.window.close, 'TOP', 0, 0)
    dropdown:SetPoint('RIGHT', self.window.close, 'LEFT', EXFrames:ScalePixel(-6, self.window), 0)
    self.unitSelector = dropdown
end

function editor:EnsureSplitView()
    if self.splitView then
        return
    end

    self.splitView = EXFrames:GetFrame('split-options-frame'):Create()
    self.splitView:SetParent(self.window.container)
    self.splitView:SetAllPoints()
    if self.splitView.SetLeftWidth then
        self.splitView:SetLeftWidth(170)
    end

    self.splitView:AddExtraButton({
        text = 'Create Display',
        color = { 249 / 255, 95 / 255, 9 / 255, 1 },
        onClick = function()
            local displayID = ufAuras:CreateNewDisplay(self.contextUnit)
            ufAuras:RefreshDisplay(displayID)
            self:Refresh(displayID)
        end,
    })

    self.splitView:SetOnItemChange(function(id)
        if self._suppressItemChange then
            self.currItemID = id
            return
        end
        self.currItemID = id
        groupNav:EnsureGroupSelected(id)
        self.currTabID = self.currTabID or 'container'
        -- Keep the selected section tab; only rebuild fields for the new display.
        if not self.innerTabs then
            self:AddInnerTabs()
        else
            self:PopulateFields()
        end
        ufPreview:Sync(id)
    end)
end

function editor:SetActiveItemSilent(id)
    if not self.splitView or not id then
        return
    end
    self._suppressItemChange = true
    self.splitView.activeID = id
    for _, item in ipairs(self.splitView.items or {}) do
        if not item.isCategory then
            item:SetActive(item.ID == id)
        end
    end
    self.currItemID = id
    self._suppressItemChange = false
end

function editor:RefreshItemList()
    if not self.splitView then
        return
    end
    local items = ufAuras:GetSplitViewItems(self.contextUnit)
    local keepID = self.currItemID
    self.splitView:AddItems(items)

    local selectID = nil
    if keepID then
        for _, item in ipairs(items) do
            if item.type ~= 'category' and item.ID == keepID then
                selectID = keepID
                break
            end
        end
    end
    if not selectID and self.splitView.activeID then
        for _, item in ipairs(items) do
            if item.type ~= 'category' and item.ID == self.splitView.activeID then
                selectID = self.splitView.activeID
                break
            end
        end
    end
    if not selectID then
        for _, item in ipairs(items) do
            if item.type ~= 'category' then
                selectID = item.ID
                break
            end
        end
    end

    if selectID then
        -- Silent highlight only — do not rebuild tabs/fields (avoids zero-width layout).
        self:SetActiveItemSilent(selectID)
    else
        self.currItemID = nil
        self.splitView.activeID = nil
    end
end

function editor:RefreshOptions()
    -- Defer one frame so tab/scroll containers have real widths after dependency toggles.
    if self._pendingOptionsRefresh then
        return
    end
    self._pendingOptionsRefresh = true
    C_Timer.After(0, function()
        self._pendingOptionsRefresh = false
        if self.window and self.window:IsShown() then
            self:PopulateFields()
        end
    end)
end

function editor:Refresh(selectID)
    if not self.window then
        return
    end
    self:EnsureSplitView()
    if selectID then
        self.currItemID = selectID
    end
    self:RefreshItemList()
    if self.currItemID then
        groupNav:EnsureGroupSelected(self.currItemID)
        if not self.innerTabs then
            self:AddInnerTabs()
        else
            self:PopulateFields()
        end
    else
        self:ClearInnerTabs()
        self:ClearFields()
    end
    ufPreview:Sync(self.currItemID)
end

function editor:Show(contextUnit)
    if not self.window then
        self.window = self:CreateWindow()
    end

    ufPreview:HookEditorWindow(self.window)
    self:EnsureSplitView()
    self:EnsureUnitSelector()

    if contextUnit and contextUnit ~= self.contextUnit then
        if self.contextUnit then
            ufPreview:Clear()
        end
        self.contextUnit = contextUnit
        ufAuras.contextUnit = contextUnit
        ufPreview:SetContext(contextUnit)
        self.currItemID = nil
        if self.splitView then
            self.splitView.activeID = nil
        end
    elseif not self.contextUnit then
        self.contextUnit = contextUnit
        ufAuras.contextUnit = contextUnit
        ufPreview:SetContext(contextUnit)
    end

    self.currTabID = self.currTabID or 'container'
    self:UpdateTitle()
    self:SyncUnitSelector()
    self.window:ShowWindow()
    -- Layout after show so right panel / scroll child have real widths.
    self:Refresh(self.currItemID)
end
