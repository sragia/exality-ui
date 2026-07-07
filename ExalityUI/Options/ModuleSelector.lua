---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsNavIcons
local navIcons = EXUI:GetModule('options-nav-icons')

---@class ExalityFramesPanelFrame
local panel = EXFrames:GetFrame('panel-frame')

----------------

---@class EXUIOptionsModuleSelector
local optionsModuleSelector = EXUI:GetModule('options-module-selector')

optionsModuleSelector.container = nil
optionsModuleSelector.containerParent = nil
optionsModuleSelector.buttons = {}
optionsModuleSelector.isCompact = false
optionsModuleSelector.flyout = nil
optionsModuleSelector.flyoutItems = nil
optionsModuleSelector.flyoutAnchor = nil
optionsModuleSelector.flyoutClickCatcher = nil

local categoryItems = {
    {
        name = 'Quality of Life',
        order = 80
    }
}

local COMPACT_GAP = 5
local menuItemFrame = EXFrames:GetFrame('menu-item')
local COMPACT_SIZE = menuItemFrame.COMPACT_SIZE or 26

local function AnchorCompactItem(item, parent, y)
    item:ClearAllPoints()
    item:SetSize(COMPACT_SIZE, COMPACT_SIZE)
    item:SetPoint('CENTER', parent, 'TOP', 0, -(y + COMPACT_SIZE / 2))
end

optionsModuleSelector.Init = function(self)
    EXUI.utils.addObserver(self)
    optionsController:Observe('selectedModule', function(value)
        for _, button in pairs(self.buttons) do
            button:SetSelected(value)
        end
        if (self.flyoutItems) then
            for _, item in ipairs(self.flyoutItems) do
                item:SetSelected(value)
            end
        end
    end)
end

optionsModuleSelector.Create = function(self, container, containerParent)
    self.container = container
    self.containerParent = containerParent or container:GetParent()

    self:Populate()
end

optionsModuleSelector.Relayout = function(self)
    if (self.isCompact) then
        local y = COMPACT_GAP
        for _, child in ipairs(self.buttons) do
            AnchorCompactItem(child, self.container, y)
            y = y + COMPACT_SIZE + COMPACT_GAP
        end
        return
    end

    local gap = 5
    local gapX = 3
    EXUI.utils.organizeFramesInList(self.buttons, gap, self.container, gapX)
end

optionsModuleSelector.HideFlyout = function(self)
    if (self.flyoutItems) then
        for _, item in ipairs(self.flyoutItems) do
            item:Destroy()
        end
        self.flyoutItems = nil
    end
    if (self.flyout) then
        self.flyout:Hide()
        self.flyout:SetParent(nil)
        self.flyout = nil
    end
    if (self.flyoutClickCatcher) then
        self.flyoutClickCatcher:Hide()
        self.flyoutClickCatcher:SetParent(nil)
        self.flyoutClickCatcher = nil
    end
    self.flyoutAnchor = nil
end

optionsModuleSelector.ToggleFlyout = function(self, anchorItem)
    if (self.flyoutAnchor == anchorItem) then
        self:HideFlyout()
        return
    end

    self:HideFlyout()

    local module = anchorItem._navModule
    if (not module or not module.subMenu) then
        return
    end

    local flyout = panel:Create()
    flyout:SetParent(self.containerParent)
    flyout:SetFrameStrata('FULLSCREEN_DIALOG')
    flyout:SetFrameLevel(anchorItem:GetFrameLevel() + 20)
    flyout:SetBackgroundColor(unpack(EXFrames.Theme.backgroundDeep))
    flyout:SetWidth(COMPACT_SIZE + 8)
    flyout:SetPoint('BOTTOMLEFT', anchorItem, 'TOPRIGHT', 5, 5)

    local catcher = CreateFrame('Button', nil, self.containerParent)
    catcher:SetAllPoints()
    catcher:SetFrameStrata('FULLSCREEN_DIALOG')
    catcher:SetFrameLevel(flyout:GetFrameLevel() - 1)
    catcher:RegisterForClicks('AnyUp')
    catcher:SetScript('OnClick', function()
        self:HideFlyout()
    end)
    catcher:Show()

    local items = {}
    local y = COMPACT_GAP
    table.sort(module.subMenu, function(a, b) return a.order < b.order end)
    for _, sub in ipairs(module.subMenu) do
        local item = EXFrames:GetFrame('menu-item'):Create(flyout)
        item._navModule = nil
        item:SetIcon(navIcons:Get(sub.name, sub.data))
        item:SetText(sub.name)
        item:SetData(sub.data)
        item:SetCompact(true)
        item:SetOnClick(function(clicked)
            sub.onClick(clicked)
            self:HideFlyout()
        end)
        item:SetSelected(optionsController.selectedModule)
        AnchorCompactItem(item, flyout, y)
        y = y + COMPACT_SIZE + COMPACT_GAP
        table.insert(items, item)
    end

    flyout:SetHeight(y)
    flyout:Show()

    self.flyout = flyout
    self.flyoutItems = items
    self.flyoutAnchor = anchorItem
    self.flyoutClickCatcher = catcher
end

optionsModuleSelector.ConfigureItem = function(self, item, module)
    item._navModule = module
    item:SetIcon(navIcons:Get(module.name, module.data))
    item:SetText(module.name)

    if (module.subMenu) then
        item:SetSubMenuItems(module.subMenu)
        item:SetExpandable(true)
        item:SetSelected(false)
    else
        item:SetExpandable(false)
        item:SetOnClick(module.onClick)
        item:SetData(module.data)
        item:SetSelected(optionsController.selectedModule)
    end
end

optionsModuleSelector.RestoreExpandedItem = function(self, item, module)
    item:SetOnClick(nil)
    if (module.subMenu) then
        item:SetSubMenuItems(module.subMenu)
        item:SetExpandable(true)
        item:SetSelected(false)
    else
        item:SetExpandable(false)
        item:SetOnClick(module.onClick)
        item:SetData(module.data)
        item:SetSelected(optionsController.selectedModule)
    end
end

optionsModuleSelector.ConfigureCompactItem = function(self, item, module)
    if (module.subMenu) then
        item:SetExpandable(false)
        item:SetOnClick(function(clicked)
            self:ToggleFlyout(clicked)
        end)
        item:SetSelected(false)
    else
        item:SetExpandable(false)
        item:SetOnClick(module.onClick)
        item:SetData(module.data)
        item:SetSelected(optionsController.selectedModule)
    end
end

optionsModuleSelector.SetCompactMode = function(self, compact)
    if (self.isCompact == compact) then
        return
    end
    self.isCompact = compact
    self:HideFlyout()

    for _, item in ipairs(self.buttons) do
        local module = item._navModule
        item:SetCompact(compact)
        if (module) then
            if (compact) then
                self:ConfigureCompactItem(item, module)
            else
                self:RestoreExpandedItem(item, module)
            end
        end
    end

    for _, item in ipairs(self.buttons) do
        item:SetSelected(optionsController.selectedModule)
    end

    self:Relayout()
end

optionsModuleSelector.Populate = function(self)
    local tree = self:BuildTree()

    for _, module in EXUI.utils.spairs(tree, function(t, a, b) return t[a].order < t[b].order end) do
        local item = EXFrames:GetFrame('menu-item'):Create(self.container)
        self:ConfigureItem(item, module)
        if (self.isCompact) then
            item:SetCompact(true)
            self:ConfigureCompactItem(item, module)
        end
        table.insert(self.buttons, item)
    end

    self:Relayout()
end

optionsModuleSelector.BuildTree = function(self)
    local tree = {}
    for _, category in pairs(categoryItems) do
        tree[category.name] = {
            order = category.order,
            name = category.name,
            isExpandable = true,
            onClick = nil,
            subMenu = {}
        }
    end
    local modules = optionsController:GetAllModules()
    for _, module in pairs(modules) do
        if (module.module.GetCategory) then
            local category = module.module:GetCategory()
            if (tree[category]) then
                table.insert(tree[category].subMenu, {
                    order = module.module:GetOrder(),
                    name = module.module:GetName(),
                    isExpandable = false,
                    data = module.module,
                    onClick = function(self)
                        optionsController:SetSelectedModule(self.data:GetName())
                    end
                })
            end
        else
            tree[module.module:GetName()] = {
                order = module.module:GetOrder(),
                name = module.module:GetName(),
                isExpandable = false,
                data = module.module,
                onClick = function(self)
                    optionsController:SetSelectedModule(self.data:GetName())
                end
            }
        end
    end

    return tree
end
