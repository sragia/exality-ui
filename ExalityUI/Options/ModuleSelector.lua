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

optionsModuleSelector.scrollFrame = nil
optionsModuleSelector.container = nil
optionsModuleSelector.containerParent = nil
optionsModuleSelector.buttons = {}
optionsModuleSelector.navEntries = {}
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

local COMPACT_GAP = 3
local ITEM_GAP = 3
local CATEGORY_TOP_GAP = 14
local CATEGORY_AFTER_GAP = 2
local CATEGORY_HEADER_HEIGHT = 16
local CATEGORY_TITLE_BLEND = 0.42
local menuItemFrame = EXFrames:GetFrame('menu-item')
local COMPACT_SIZE = menuItemFrame.COMPACT_SIZE or 26

local function CategoryTitleColor()
    local bright = EXFrames.Theme.white
    local muted = EXFrames.Theme.textMuted
    local t = CATEGORY_TITLE_BLEND
    return {
        bright[1] * (1 - t) + muted[1] * t,
        bright[2] * (1 - t) + muted[2] * t,
        bright[3] * (1 - t) + muted[3] * t,
        1,
    }
end

local function CreateCategoryHeader(parent, name)
    local header = CreateFrame('Frame', nil, parent)
    header:SetHeight(CATEGORY_HEADER_HEIGHT)

    local text = header:CreateFontString(nil, 'OVERLAY')
    text:SetFont(EXFrames.assets.font.default(), 11, '')
    text:SetTextColor(unpack(CategoryTitleColor()))
    text:SetPoint('LEFT', 8, 0)
    text:SetJustifyH('LEFT')
    text:SetText(name)
    header.label = text

    return header
end

local function GapBeforeNavEntry(entry, index, prevEntry)
    if index == 1 then
        return ITEM_GAP
    end
    if entry.kind == 'category' then
        return CATEGORY_TOP_GAP
    end
    if prevEntry and prevEntry.kind == 'category' then
        return CATEGORY_AFTER_GAP
    end
    return ITEM_GAP
end

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
    EXFrames:RegisterCallback({
        events = { 'menuItemClick' },
        func = function()
            optionsModuleSelector:UpdateScroll()
        end
    })
end

optionsModuleSelector.Create = function(self, scrollFrame, containerParent)
    self.scrollFrame = scrollFrame
    self.container = scrollFrame.child
    self.containerParent = containerParent or scrollFrame:GetParent()

    self:Populate()
end

optionsModuleSelector.UpdateScroll = function(self)
    local scrollFrame = self.scrollFrame
    if (not scrollFrame) then
        return
    end

    local width = math.max(1, scrollFrame:GetWidth())
    local contentHeight = 1
    if (self.isCompact) then
        local itemCount = 0
        for _, entry in ipairs(self.navEntries) do
            if (entry.kind == 'item') then
                itemCount = itemCount + 1
            end
        end
        contentHeight = COMPACT_GAP + itemCount * (COMPACT_SIZE + COMPACT_GAP)
    else
        contentHeight = 0
        local prevEntry = nil
        for index, entry in ipairs(self.navEntries) do
            contentHeight = contentHeight + GapBeforeNavEntry(entry, index, prevEntry) + entry.frame:GetHeight()
            prevEntry = entry
        end
    end

    scrollFrame:UpdateScrollChild(width, math.max(1, contentHeight))
end

optionsModuleSelector.Relayout = function(self)
    if (self.isCompact) then
        local y = COMPACT_GAP
        for _, entry in ipairs(self.navEntries) do
            if (entry.kind == 'category') then
                entry.frame:Hide()
            else
                AnchorCompactItem(entry.frame, self.container, y)
                y = y + COMPACT_SIZE + COMPACT_GAP
            end
        end
        self:UpdateScroll()
        return
    end

    local gapX = 3
    local prev = nil
    local prevEntry = nil
    for index, entry in ipairs(self.navEntries) do
        local frame = entry.frame
        if (entry.kind == 'category') then
            frame:Show()
        end

        frame:ClearAllPoints()
        local topGap = GapBeforeNavEntry(entry, index, prevEntry)
        if (not prev) then
            frame:SetPoint('TOPLEFT', self.container, 'TOPLEFT', gapX, -topGap)
            frame:SetPoint('TOPRIGHT', self.container, 'TOPRIGHT', -gapX, -topGap)
        else
            frame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -topGap)
            frame:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -topGap)
        end
        frame:Show()
        prev = frame
        prevEntry = entry
    end
    self:UpdateScroll()
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
    item:SetExpandable(false)
    item:SetOnClick(module.onClick)
    item:SetData(module.data)
    item:SetSelected(optionsController.selectedModule)
end

optionsModuleSelector.RestoreExpandedItem = function(self, item, module)
    item:SetOnClick(nil)
    item:SetExpandable(false)
    item:SetOnClick(module.onClick)
    item:SetData(module.data)
    item:SetSelected(optionsController.selectedModule)
end

optionsModuleSelector.ConfigureCompactItem = function(self, item, module)
    item:SetExpandable(false)
    item:SetOnClick(module.onClick)
    item:SetData(module.data)
    item:SetSelected(optionsController.selectedModule)
end

optionsModuleSelector.SetCompactMode = function(self, compact)
    if (self.isCompact == compact) then
        return
    end
    self.isCompact = compact
    self:HideFlyout()

    for _, entry in ipairs(self.navEntries) do
        if (entry.kind == 'category') then
            if (compact) then
                entry.frame:Hide()
            else
                entry.frame:Show()
            end
        else
            local item = entry.frame
            local module = entry.module
            item:SetCompact(compact)
            if (module) then
                if (compact) then
                    self:ConfigureCompactItem(item, module)
                else
                    self:RestoreExpandedItem(item, module)
                end
            end
        end
    end

    for _, item in ipairs(self.buttons) do
        item:SetSelected(optionsController.selectedModule)
    end

    self:Relayout()
end

optionsModuleSelector.BuildNavList = function(self)
    local tree = self:BuildTree()
    local list = {}

    for _, node in EXUI.utils.spairs(tree, function(t, a, b) return t[a].order < t[b].order end) do
        if (node.subMenu and #node.subMenu > 0) then
            table.insert(list, { kind = 'category', name = node.name })
            table.sort(node.subMenu, function(a, b) return a.order < b.order end)
            for _, sub in ipairs(node.subMenu) do
                table.insert(list, { kind = 'item', module = sub })
            end
        elseif (node.data) then
            table.insert(list, { kind = 'item', module = node })
        end
    end

    return list
end

optionsModuleSelector.Populate = function(self)
    self.navEntries = {}
    self.buttons = {}

    for _, entry in ipairs(self:BuildNavList()) do
        if (entry.kind == 'category') then
            local header = CreateCategoryHeader(self.container, entry.name)
            table.insert(self.navEntries, { kind = 'category', frame = header })
        else
            local module = entry.module
            local item = EXFrames:GetFrame('menu-item'):Create(self.container)
            self:ConfigureItem(item, module)
            if (self.isCompact) then
                item:SetCompact(true)
                self:ConfigureCompactItem(item, module)
            end
            table.insert(self.navEntries, { kind = 'item', frame = item, module = module })
            table.insert(self.buttons, item)
        end
    end

    self:Relayout()
end

optionsModuleSelector.BuildTree = function(self)
    local tree = {}
    for _, category in pairs(categoryItems) do
        tree[category.name] = {
            order = category.order,
            name = category.name,
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
