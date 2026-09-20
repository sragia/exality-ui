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
optionsFields.fieldCache = {}
optionsFields.layoutRoot = nil
optionsFields.widgetLayouts = {}
optionsFields.optionGroupExpandSession = {}

local LAYOUT_TYPES = {
    section = true,
    optionGroup = true,
    row = true,
    stack = true,
    columns = true,
}

local BOTTOM_ALIGN_FIELD_TYPES = {
    range = true,
    dropdown = true,
    checkbox = true,
    ['tri-state-checkbox'] = true,
    toggle = true,
    ['color-picker'] = true,
    button = true,
    ['edit-box'] = true,
    editbox = true,
    ['anchor-point'] = true,
}

optionsFields.Init = function(self)
    EXUI.utils.addObserver(self)

    optionsController:Observe('selectedModule', function(value)
        self:Refresh()
    end)
end

optionsFields.Create = function(self, container)
    self.host = container
    local scroll = EXFrames:GetFrame('smooth-scroll-frame'):Create(container)
    scroll:SetAllPoints()
    scroll.child.exuiAutoSizeHeight = true
    self.pageScroll = scroll
    self.baseContainer = scroll.child
    self.container = scroll.child

    self:Refresh()
end

optionsFields.ShowPageScroll = function(self)
    if self.pageScroll then
        self.pageScroll:Show()
    end
end

optionsFields.HidePageScroll = function(self)
    if self.pageScroll then
        self.pageScroll:Hide()
    end
end

optionsFields.RequestFieldsRefresh = function(self)
    if self._buildingChrome then
        return
    end
    self:RefreshFields()
end

optionsFields.AttachSplitView = function(self)
    if not self.splitView then
        return
    end
    if self.tabs then
        if self.tabs.scrollFrame then
            self.tabs.scrollFrame:Hide()
        end
        local parent = self.tabs.panel or self.tabs
        self.splitView:SetParent(parent)
        self.splitView:ClearAllPoints()
        self.splitView:SetAllPoints(parent)
    else
        self:HidePageScroll()
        local parent = self.host or self.baseContainer
        self.splitView:SetParent(parent)
        self.splitView:ClearAllPoints()
        self.splitView:SetAllPoints(parent)
    end
    if self.splitView.ApplyPanelLayout then
        self.splitView:ApplyPanelLayout()
    end
    self.splitView:UpdateScroll()
end

optionsFields.AddSplitView = function(self, module)
    self.splitView = EXFrames:GetFrame('split-options-frame'):Create()
    self:AttachSplitView()

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
        self:RequestFieldsRefresh()
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
    local selected = optionsController:GetSelectedModule()
    if selected and selected.module and selected.module.TeardownOptionsChrome then
        selected.module:TeardownOptionsChrome()
    end
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
    local selected = optionsController:GetSelectedModule()
    if selected and selected.module and selected.module.TeardownOptionsChrome then
        selected.module:TeardownOptionsChrome()
    end

    if (self.innerTabs) then
        self.innerTabs:Destroy()
        self.innerTabs = nil
    end

    local rightPanel = self.splitView.rightPanel
    self.innerTabs = EXFrames:GetFrame('tabs-frame'):Create({ scrollable = true })
    self.innerTabs:SetParent(rightPanel)
    self.innerTabs:SetPoint('TOPLEFT', rightPanel, 'TOPLEFT', 5, -5)
    self.innerTabs:SetPoint('BOTTOMRIGHT', rightPanel, 'BOTTOMRIGHT', -5, 5)

    if (self.splitView.scrollFrame) then
        self.splitView.scrollFrame:Hide()
    end
    self.container = self.innerTabs.container
    self.container.exuiAutoSizeHeight = true
    if self.innerTabs.UpdateScroll then
        self.innerTabs:UpdateScroll()
    end

    local tabs = module:GetSectionTabs(self.currItemID)
    self.innerTabs:AddTabs(tabs)
    self.innerTabs:SetOnTabChange(function(id)
        self.currTabID = id
        self:RequestFieldsRefresh()
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

    if module.UpdateOptionsChrome then
        pcall(module.UpdateOptionsChrome, module, self)
    end
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
            if self.tabs.scrollFrame then
                self.tabs.scrollFrame:Show()
            end
            self.container = self.tabs.container
        else
            self:ShowPageScroll()
            self.container = self.baseContainer
        end
    end

    self:RequestFieldsRefresh()
end

optionsFields.AddTabs = function(self, module)
    local scrollable = not module.useSplitView or module.splitViewTabID
    self.tabs = EXFrames:GetFrame('tabs-frame'):Create(scrollable and { scrollable = true } or nil)
    self:HidePageScroll()
    self.tabs:SetParent(self.host or self.baseContainer)
    self.tabs:SetAllPoints()
    self.container = self.tabs.container

    local tabs = module:GetTabs()
    self.tabs:AddTabs(tabs)


    self.tabs:SetOnTabChange(function(id)
        self.currTabID = id
        local selected = optionsController:GetSelectedModule()
        local currentModule = selected and selected.module
        if currentModule and currentModule.splitViewTabID then
            self:RefreshSplitViewForTab()
        elseif currentModule and currentModule.useSplitView then
            self.currItemID = nil
            self:ClearInnerTabs()
            if self.splitView then
                self.splitView:Destroy()
                self.splitView = nil
            end
            self:ClearLayout()
            self:AddSplitView(currentModule)
            if currentModule.useInnerTabs and self.splitView then
                if self:HasInnerTabs(currentModule, self.currItemID) then
                    if not self.innerTabs then
                        self:AddInnerTabs(currentModule)
                    end
                else
                    self:ClearInnerTabs()
                    self:UseSplitViewContainer()
                end
            end
        else
            self:RequestFieldsRefresh()
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

optionsFields.GetContentWidth = function(self)
    local function usable(width)
        return type(width) == 'number' and width >= 64
    end

    if self.splitView and self.splitView.rightPanel then
        local width = self.splitView.rightPanel:GetWidth()
        if usable(width) then
            return math.max(1, width - 20)
        end
    end
    if self.innerTabs and self.innerTabs.panel then
        local width = self.innerTabs.panel:GetWidth()
        if usable(width) then
            return math.max(1, width - 20)
        end
    end
    if self.tabs and self.tabs.panel then
        local width = self.tabs.panel:GetWidth()
        if usable(width) then
            return math.max(1, width - 20)
        end
    end
    if self.pageScroll and self.pageScroll:IsShown() then
        local width = self.pageScroll:GetWidth()
        if usable(width) then
            return width
        end
    end
    if self.host then
        local width = self.host:GetWidth()
        if usable(width) then
            return math.max(1, width)
        end
    end
    if self.container then
        local width = self.container:GetWidth()
        if usable(width) then
            return width
        end
    end
    return 640
end

optionsFields.UpdateActiveScroll = function(self)
    local root = self.layoutRoot
    if self.tabs and self.tabs.scrollable and self.tabs.UpdateScroll and self.container == self.tabs.container then
        self.tabs:UpdateScroll()
    elseif self.innerTabs and self.innerTabs.scrollable and self.innerTabs.UpdateScroll and self.container == self.innerTabs.container then
        self.innerTabs:UpdateScroll()
    elseif self.splitView and self.container == self.splitView.container and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    elseif self.pageScroll and self.pageScroll:IsShown() and root then
        self.pageScroll:UpdateScrollChild(self:GetContentWidth(), root:GetHeight())
    end
end

optionsFields.LayoutMountedOptionsHost = function(self, host)
    if not host or not host.layoutRoot or not host.container then
        return
    end
    local width = host.getWidth and host.getWidth() or host.container:GetWidth()
    self:LayoutMountedOptionsRoot(host.container, host.layoutRoot, width)
    if host.updateScroll then
        host.updateScroll()
    end
end

optionsFields.LayoutMountedFields = function(self)
    local root = self.layoutRoot
    if not root then
        return
    end
    local width = self:GetContentWidth()
    if self.container and self.container.SetWidth then
        self.container:SetWidth(width)
    end
    root:SetWidth(width)
    root:Layout()
    if self.container and self.container.exuiAutoSizeHeight then
        self.container:SetHeight(root:GetHeight())
    end
    self:UpdateActiveScroll()
end

optionsFields.ResolveOptionIDs = function(self, module)
    if not self.currItemID and module.GetSplitViewItems then
        local items = module:GetSplitViewItems()
        if items then
            for _, item in ipairs(items) do
                if item.ID and item.type ~= 'category' then
                    self.currItemID = item.ID
                    break
                end
            end
        end
    end
    if not self.currTabID and module.useInnerTabs and module.GetSectionTabs then
        local tabs = module:GetSectionTabs(self.currItemID)
        if tabs and tabs[1] then
            self.currTabID = tabs[1].ID
        end
    end
    if not self.currTabID and module.useTabs and module.GetTabs then
        local tabs = module:GetTabs()
        if tabs and tabs[1] then
            self.currTabID = tabs[1].ID
        end
    end
end

optionsFields.Refresh = function(self)
    self._refreshingFields = false
    local module = optionsController:GetSelectedModule()
    if not module then
        return
    end
    local currentModule = module.module
    local moduleKey = currentModule and currentModule.GetName and currentModule:GetName()
    if self._moduleKey ~= moduleKey then
        self.currTabID = nil
        self.currItemID = nil
        self._moduleKey = moduleKey
    end

    self:InvalidateFieldCache()
    for _, registered in pairs(optionsController:GetAllModules()) do
        if registered.module and registered.module.TeardownOptionsChrome then
            registered.module:TeardownOptionsChrome()
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
    self:ShowPageScroll()

    self._buildingChrome = true
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
                    if not self.innerTabs then
                        self:AddInnerTabs(currentModule)
                    else
                        self.container = self.innerTabs.container
                    end
                else
                    self:ClearInnerTabs()
                    self:UseSplitViewContainer()
                end
            end
        end
    end
    self._buildingChrome = false
    self:RefreshFields()
end

optionsFields.RefreshOptions = function(self)
    self:InvalidateFieldCache(self:GetFieldCacheKey())
    self:RefreshFields()
end

optionsFields.RefreshOptionsDelayed = function(self, delay)
    delay = delay or 0.2
    if self._refreshOptionsTimer then
        self._refreshOptionsTimer:Cancel()
    end
    self._refreshOptionsTimer = C_Timer.NewTimer(delay, function()
        self._refreshOptionsTimer = nil
        self:RefreshOptions()
    end)
end

optionsFields._fieldCacheKeyOverride = nil

optionsFields.GetFieldCacheKey = function(self)
    if self._fieldCacheKeyOverride then
        return self._fieldCacheKeyOverride
    end
    local module = optionsController:GetSelectedModule()
    if not module or not module.module or not module.module.GetName then
        return nil
    end
    local moduleName = module.module:GetName()
    if not moduleName then
        return nil
    end
    local groupID = module.module.currGroupID or ''
    return string.format('%s:%s:%s:%s', moduleName, self.currItemID or '', self.currTabID or '', groupID)
end

optionsFields.GetOptionGroupExpandSessionKey = function(self, mountPath, label)
    local cacheKey = self:GetFieldCacheKey() or ''
    return string.format('%s|%s|%s', cacheKey, mountPath or '', label or '')
end

optionsFields.InvalidateFieldCache = function(self, key)
    local destroyed = {}
    local function destroyField(field)
        if not field or destroyed[field] then
            return
        end
        destroyed[field] = true
        if field.Destroy then
            field:Destroy()
        end
    end

    if key then
        self.fieldCache[key] = nil
        return
    end

    for _, field in pairs(self.fields) do
        destroyField(field)
    end
    for _, cached in pairs(self.fieldCache) do
        for _, field in ipairs(cached) do
            destroyField(field)
        end
    end
    self.fieldCache = {}
    self.fields = {}
    self:ClearLayout()
end

optionsFields.IsLayoutNode = function(self, field)
    return type(field) == 'table' and LAYOUT_TYPES[field.type]
end

optionsFields.FieldLayoutSpec = function(self, field)
    local spec
    if field._widthPercent then
        spec = { flex = field._widthPercent }
    elseif field.width and not field.flex then
        spec = { width = field.width }
    else
        spec = { flex = field.flex or 1 }
    end
    local align = field.align
    if not align and field.type and BOTTOM_ALIGN_FIELD_TYPES[field.type] then
        align = 'bottom'
    end
    if align then
        spec.align = align
    end
    return spec
end

optionsFields.LayoutMountSpec = function(self, node)
    if type(node.widthPercent) == 'number' then
        return { widthPercent = node.widthPercent }
    end
    return { flex = node.flex or 1 }
end

optionsFields.WrapPercentRows = function(self, fields)
    local rows = {}
    local current = nil
    local running = 100
    for _, field in ipairs(fields) do
        local perc = field.width or 25
        if not current or (running - perc) < 0 then
            current = { type = 'row', children = {} }
            table.insert(rows, current)
            running = 100
        end
        field._widthPercent = perc
        table.insert(current.children, field)
        running = running - perc
    end
    return rows
end

optionsFields.ExpandOptions = function(self, fields)
    local expanded = {}
    for _, field in ipairs(fields or {}) do
        if type(field) == 'function' then
            local result = field()
            if result then
                for _, item in ipairs(self:ExpandOptions(result)) do
                    table.insert(expanded, item)
                end
            end
        else
            table.insert(expanded, field)
        end
    end
    return expanded
end

optionsFields.AdaptToTree = function(self, fields)
    local result = {}
    local pending = {}
    local function flush()
        if #pending == 0 then
            return
        end
        for _, row in ipairs(self:WrapPercentRows(pending)) do
            table.insert(result, row)
        end
        wipe(pending)
    end
    for _, field in ipairs(fields) do
        if self:IsLayoutNode(field) then
            flush()
            if field.children then
                local children = self:ExpandOptions(field.children)
                if field.type == 'section' or field.type == 'optionGroup' then
                    if field.type == 'section' then
                        field.type = 'optionGroup'
                        field.collapsible = field.collapsible ~= false
                        if field.expanded == nil then
                            field.expanded = true
                        end
                    end
                    field.children = self:AdaptToTree(children)
                else
                    field.children = children
                end
            end
            table.insert(result, field)
        else
            table.insert(pending, field)
        end
    end
    flush()
    return result
end

-- Module options may still declare `type = 'title'`; NormalizeOptions converts them to optionGroup trees.
local function isSubTitleField(field)
    if field.type ~= 'title' then
        return false
    end
    if field.accent then
        return true
    end
    if field.size and field.size <= 14 then
        return true
    end
    return false
end

local function titleFieldToOptionGroup(field)
    local group = {
        type = 'optionGroup',
        label = field.label,
        collapsible = true,
        expanded = field.expanded ~= nil and field.expanded or true,
        children = {},
    }
    if field.depends then
        group.depends = field.depends
    end
    if field.accent then
        group.accent = field.accent
    end
    if field.size then
        group.titleSize = field.size
    end
    if field.flex then
        group.flex = field.flex
    elseif field.width == 100 then
        group.flex = 1
    elseif field.width then
        group.width = field.width
    end
    return group
end

optionsFields.ConvertTitleFieldsToGroups = function(self, fields)
    local out = {}
    local stack = {}

    local function currentList()
        if #stack == 0 then
            return out
        end
        return stack[#stack].children
    end

    for _, field in ipairs(fields or {}) do
        if type(field) == 'table' and field.type == 'title' then
            local group = titleFieldToOptionGroup(field)
            if isSubTitleField(field) and #stack > 0 then
                table.insert(stack[#stack].children, group)
            else
                while #stack > 0 do
                    table.remove(stack)
                end
                table.insert(out, group)
            end
            table.insert(stack, group)
        elseif type(field) == 'table' and self:IsLayoutNode(field) then
            if field.children then
                field.children = self:ConvertTitleFieldsToGroups(field.children)
            end
            table.insert(currentList(), field)
        elseif type(field) == 'table' then
            table.insert(currentList(), field)
        end
    end

    return out
end

optionsFields.NormalizeOptions = function(self, fields)
    local expanded = self:ExpandOptions(fields)
    local grouped = self:ConvertTitleFieldsToGroups(expanded)
    return self:AdaptToTree(grouped)
end

optionsFields.ClearLayout = function(self)
    if self.layoutRoot then
        self.layoutRoot:Destroy()
        self.layoutRoot = nil
    end
end

optionsFields.CreateLayoutFrame = function(self, parent, options)
    return EXFrames:GetFrame('layout-frame'):Create(parent, options)
end

optionsFields.PrepareOptionGroupForMount = function(self, group, parentLayout)
    if not group or not group.SetBodyLayout then
        return
    end
    local bodyLayout = group.bodyLayout
    if not bodyLayout then
        return
    end
    if bodyLayout == parentLayout then
        group.bodyLayout = nil
        return
    end
    group:SetBodyLayout(nil)
end

optionsFields.CreateOptionGroupBodyLayout = function(self, group, parentLayout, options)
    local body = group.GetBody and group:GetBody()
    if not body or not group.SetBodyLayout then
        return nil
    end
    local layout = EXFrames:GetFrame('layout-frame'):CreateDedicated(body, options)
    if layout and layout ~= parentLayout and layout ~= group and group:SetBodyLayout(layout, parentLayout) then
        return layout
    end
    if layout and layout.Destroy then
        layout:Destroy()
    end
    return nil
end

local function wouldReparentCycle(groupFrame, parentLayout)
    if not groupFrame or not parentLayout or not groupFrame.GetBody then
        return false
    end
    if groupFrame == parentLayout then
        return true
    end
    local body = groupFrame:GetBody()
    local p = parentLayout
    while p do
        if p == groupFrame or p == body then
            return true
        end
        p = p:GetParent()
    end
    return false
end

local function cachedFieldMatchesNode(frame, node, parentLayout, mountPath)
    if not frame or not node or not node.type then
        return false
    end
    local optionData = frame.optionData
    local frameType = optionData and optionData.type
    if frameType ~= node.type then
        return false
    end
    if node.type == 'optionGroup' then
        if wouldReparentCycle(frame, parentLayout) then
            return false
        end
        if mountPath and frame._mountPath then
            return frame._mountPath == mountPath
        end
        return optionData and optionData.label == node.label
    end
    if node.name then
        return optionData and optionData.name == node.name
    end
    return true
end

optionsFields.AcquireField = function(self, node, cachedFields, parentLayout, mountPath)
    if node.type ~= 'optionGroup' and cachedFields then
        for i, frame in ipairs(cachedFields) do
            if cachedFieldMatchesNode(frame, node, parentLayout, mountPath) then
                return table.remove(cachedFields, i)
            end
        end
    end
    return self:GetField(node)
end

optionsFields.ShouldMountOptionNode = function(self, node)
    if not node or type(node) ~= 'table' then
        return false
    end
    if node.depends and not node.depends() then
        return false
    end
    if node.type == 'optionGroup' or node.type == 'section' then
        for _, child in ipairs(node.children or {}) do
            if self:ShouldMountOptionNode(child) then
                return true
            end
        end
        return false
    end
    if self:IsLayoutNode(node) then
        for _, child in ipairs(node.children or {}) do
            if self:ShouldMountOptionNode(child) then
                return true
            end
        end
        return false
    end
    return true
end

optionsFields.MountTree = function(self, parentLayout, nodes, builtFields, cachedFields, mountPath, onLayoutRequest)
    mountPath = mountPath or ''
    if not onLayoutRequest then
        onLayoutRequest = function()
            self:LayoutMountedFields()
        end
    end
    for index, node in ipairs(nodes) do
        if self:IsLayoutNode(node) then
            if self:ShouldMountOptionNode(node) then
                if node.type == 'optionGroup' or node.type == 'section' then
                    if node.type == 'section' then
                        node.type = 'optionGroup'
                    end
                    local pathKey = mountPath == '' and tostring(index) or (mountPath .. '/' .. index)
                    local group = self:AcquireField(node, cachedFields, parentLayout, pathKey)
                    if group then
                        group._mountPath = pathKey
                        group.onLayoutRequest = onLayoutRequest
                        self:PrepareOptionGroupForMount(group, parentLayout)
                        local layoutOptions = {
                            direction = 'stack',
                            gap = node.gap or 10,
                        }
                        local innerLayout = self:CreateOptionGroupBodyLayout(group, parentLayout, layoutOptions)
                        if not innerLayout then
                            innerLayout = EXFrames:GetFrame('layout-frame'):CreateDedicated(group:GetBody(), layoutOptions)
                            if innerLayout == parentLayout
                                or not group:SetBodyLayout(innerLayout, parentLayout) then
                                if innerLayout and innerLayout.Destroy then
                                    innerLayout:Destroy()
                                end
                                innerLayout = nil
                            end
                        end
                        if innerLayout and innerLayout ~= parentLayout and not wouldReparentCycle(group, parentLayout) then
                            self:MountTree(innerLayout, node.children or {}, builtFields, cachedFields, pathKey, onLayoutRequest)
                            group.expandSessionKey = self:GetOptionGroupExpandSessionKey(pathKey, node.label)
                            group:SetOptionData(node)
                            table.insert(builtFields, group)
                            parentLayout:Add(group, self:LayoutMountSpec(node))
                            group:Layout()
                        end
                    end
                elseif node.type == 'columns' then
                    local count = node.count or 2
                    local stack = self:CreateLayoutFrame(parentLayout, { direction = 'stack', gap = node.gap or 10 })
                    local row
                    local index = 0
                    for _, child in ipairs(node.children or {}) do
                        if self:ShouldMountOptionNode(child) then
                            if index % count == 0 then
                                row = self:CreateLayoutFrame(stack, { direction = 'row', gap = node.gap or 10 })
                                stack:Add(row, { flex = 1 })
                            end
                            self:MountTree(row, { child }, builtFields, cachedFields, mountPath .. '/' .. index, onLayoutRequest)
                            index = index + 1
                        end
                    end
                    if index > 0 then
                        parentLayout:Add(stack, { flex = 1 })
                    else
                        stack:Destroy()
                    end
                else
                    local direction = node.type == 'row' and 'row' or 'stack'
                    local childLayout = self:CreateLayoutFrame(parentLayout, {
                        direction = direction,
                        gap = node.gap or 10,
                    })
                    self:MountTree(childLayout, node.children or {}, builtFields, cachedFields, mountPath, onLayoutRequest)
                    parentLayout:Add(childLayout, { flex = 1 })
                end
            end
        elseif self:ShouldMountOptionNode(node) then
            local fieldFrame = self:AcquireField(node, cachedFields, parentLayout, mountPath)
            if fieldFrame then
                self:CreateOrUpdateTooltip(fieldFrame, node.tooltip)
                if fieldFrame.SetOptionData then
                    fieldFrame.suppressOnChange = true
                    fieldFrame:SetOptionData(node)
                    fieldFrame.suppressOnChange = false
                end
                fieldFrame:Show()
                table.insert(builtFields, fieldFrame)
                parentLayout:Add(fieldFrame, self:FieldLayoutSpec(node))
            end
        end
    end
end

optionsFields.LayoutMountedOptionsRoot = function(self, container, layoutRoot, width)
    if not layoutRoot or not container then
        return
    end
    width = math.max(1, width or container:GetWidth() or 600)
    if container.SetWidth then
        container:SetWidth(width)
    end
    layoutRoot:SetWidth(width)
    layoutRoot:Layout()
    if container.exuiAutoSizeHeight then
        container:SetHeight(layoutRoot:GetHeight())
    end
end

--- Mount normalized option trees (title → optionGroup, rows, etc.) on a scroll container.
---@param cacheKeyOverride? string Session key prefix for option-group expand state
---@param mountHost? table Optional relayout target for expand/collapse (container, layoutRoot, getWidth, updateScroll)
optionsFields.MountOptionsOnContainer = function(self, container, rawFields, width, builtFields, cacheKeyOverride, mountHost)
    builtFields = builtFields or {}
    width = math.max(1, width or 600)
    local prevOverride = self._fieldCacheKeyOverride
    self._fieldCacheKeyOverride = cacheKeyOverride
    local tree = self:NormalizeOptions(rawFields or {})
    if container.SetWidth then
        container:SetWidth(width)
    end
    local root = self:CreateLayoutFrame(container, {
        direction = 'stack',
        gap = 10,
    })
    root:SetPoint('TOPLEFT')
    root:SetWidth(width)
    local onLayoutRequest
    if mountHost then
        mountHost.container = mountHost.container or container
        onLayoutRequest = function()
            mountHost.layoutRoot = root
            self:LayoutMountedOptionsHost(mountHost)
        end
    end
    self:MountTree(root, tree, builtFields, nil, '', onLayoutRequest)
    self._fieldCacheKeyOverride = prevOverride
    if mountHost then
        mountHost.layoutRoot = root
    end
    root:Layout()
    if container.exuiAutoSizeHeight then
        container:SetHeight(root:GetHeight())
    end
    return root
end

optionsFields.LayoutWidgets = function(self, container, widgets, gap, offsetX, offsetY)
    local existing = self.widgetLayouts[container]
    if existing then
        existing:Destroy()
        self.widgetLayouts[container] = nil
    end

    local descriptors = {}
    for _, widget in ipairs(widgets) do
        local optionData = widget.optionData or { width = 25 }
        widget.optionData = optionData
        optionData._widget = widget
        table.insert(descriptors, optionData)
    end

    local tree = self:WrapPercentRows(descriptors)
    local root = self:CreateLayoutFrame(container, {
        direction = 'stack',
        gap = gap or 10,
        padding = { offsetX or 10, offsetY or 10, offsetX or 10, offsetY or 10 },
    })
    root:SetPoint('TOPLEFT')
    root:SetWidth(math.max(1, container:GetWidth()))

    for _, row in ipairs(tree) do
        local rowLayout = self:CreateLayoutFrame(root, { direction = 'row', gap = gap or 10 })
        for _, field in ipairs(row.children) do
            local widget = field._widget
            if widget then
                rowLayout:Add(widget, self:FieldLayoutSpec(field))
            end
        end
        root:Add(rowLayout, { flex = 1 })
    end
    root:Layout()
    self.widgetLayouts[container] = root
    if container.exuiAutoSizeHeight then
        container:SetHeight(root:GetHeight())
    end
    return root
end

optionsFields.HideActiveFields = function(self)
    for _, field in ipairs(self.fields) do
        field:Hide()
    end
end

optionsFields.IsFieldInCache = function(self, field)
    for _, cached in pairs(self.fieldCache) do
        for _, cachedField in ipairs(cached) do
            if cachedField == field then
                return true
            end
        end
    end
    return false
end

optionsFields.ReleaseField = function(self, field)
    if self:IsFieldInCache(field) then
        if field.SetBodyLayout then
            field:SetBodyLayout(nil)
        end
        field:Hide()
        return
    end
    if field.Destroy then
        field:Destroy()
    else
        field:Hide()
    end
end

optionsFields.CreateOrUpdateTooltip = function(self, field, tooltipInfo)
    if (not field.Tooltip and tooltipInfo) then
        local tooltip = tooltip:Create(field, {
            text = tooltipInfo.text,
        })
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
    if self._refreshingFields then
        return
    end
    self._refreshingFields = true
    local ok, err = pcall(self._RefreshFields, self)
    self._refreshingFields = false
    if not ok then
        error(err)
    end
end

optionsFields._RefreshFields = function(self)
    local module = optionsController:GetSelectedModule()
    if (not module) then
        return
    end

    local currentModule = module.module
    if (not currentModule or not currentModule.GetOptions) then
        return
    end

    if currentModule.UpdateOptionsChrome then
        pcall(currentModule.UpdateOptionsChrome, currentModule, self)
    end

    self:ResolveOptionIDs(currentModule)

    local oldFields = self.fields or {}
    local newFields = {}

    if self.splitView and self.container == self.splitView.container and self.splitView.UpdateScroll then
        self.splitView:UpdateScroll()
    end

    self:ClearLayout()

    local cacheKey = self:GetFieldCacheKey()
    local cachedCopy
    if cacheKey and self.fieldCache[cacheKey] then
        cachedCopy = {}
        for _, fieldFrame in ipairs(self.fieldCache[cacheKey]) do
            if fieldFrame.SetBodyLayout and fieldFrame.header then
                if fieldFrame.Destroy then
                    fieldFrame:Destroy()
                end
            else
                table.insert(cachedCopy, fieldFrame)
            end
        end
    end

    local rawFields = currentModule:GetOptions(self.currTabID, self.currItemID) or {}
    local tree = self:NormalizeOptions(rawFields)
    local width = self:GetContentWidth()
    if self.container and self.container.SetWidth then
        self.container:SetWidth(width)
    end
    local root = self:CreateLayoutFrame(self.container, {
        direction = 'stack',
        gap = 10,
    })
    root:SetPoint('TOPLEFT')
    root:SetWidth(width)
    self:MountTree(root, tree, newFields, cachedCopy)
    self.layoutRoot = root
    self:LayoutMountedFields()

    if cacheKey and #newFields > 0 then
        self.fieldCache[cacheKey] = newFields
    end

    self.fields = newFields

    for _, oldField in ipairs(oldFields) do
        local keep = false
        for _, newField in ipairs(newFields) do
            if oldField == newField then
                keep = true
                break
            end
        end
        if not keep then
            self:ReleaseField(oldField)
        end
    end
    C_Timer.After(0, function()
        if self.layoutRoot then
            self:LayoutMountedFields()
        end
        if EXFrames.RefreshPixelPerfect then
            EXFrames:RefreshPixelPerfect()
        end
    end)
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
            return EXFrames:GetFrame('simple-button'):Create()
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
        ['optionGroup'] = function()
            return EXFrames:GetFrame('option-group'):Create()
        end,
        ['description'] = function()
            local f = EXFrames:GetFrame('description'):Create()
            return f
        end,
        ['disclaimer'] = function()
            local f = EXFrames:GetFrame('disclaimer'):Create()
            return f
        end,
        ['edit-box'] = function()
            local f = EXFrames:GetFrame('edit-box-input'):Create({})
            f:SetHeight(40)
            return f
        end,
        ['spell-id-input'] = function()
            local f = EXFrames:GetFrame('spell-id-input'):Create({})
            return f
        end,
        ['cooldowns-spell-id-input'] = function()
            local f = EXUI:GetModule('cooldowns-spell-id-input'):Create({})
            return f
        end,
        ['cooldowns-item-id-input'] = function()
            local f = EXUI:GetModule('cooldowns-item-id-input'):Create({})
            return f
        end,
        ['checkbox'] = function()
            local f = EXFrames:GetFrame('checkbox'):Create()
            return f
        end,
        ['tri-state-checkbox'] = function()
            local f = EXFrames:GetFrame('tri-state-checkbox'):Create()
            return f
        end,
        ['custom-texts-list-item'] = function()
            local f = EXUI:GetModule('custom-texts-list-item'):Create()
            return f
        end,
        ['resource-color-curve'] = function()
            local f = EXUI:GetModule('options-resource-color-curve'):Create()
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
