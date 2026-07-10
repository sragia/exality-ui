---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsMicroMenu
local microMenu = EXUI:GetModule('action-bars-micro-menu')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

microMenu.initialized = false

local function applyFramePosition(frame, config, defaults)
    if not frame then
        return
    end

    local point = config.anchorPoint or defaults.point
    local relativePoint = config.relativeAnchor or defaults.relativePoint
    local x = config.xOffset
    if x == nil then
        x = defaults.x
    end
    local y = config.yOffset
    if y == nil then
        y = defaults.y
    end

    if frame.ClearAllPointsBase then
        frame:ClearAllPointsBase()
        frame:SetPointBase(point, UIParent, relativePoint, EXUI:ScalePixel(x, frame), EXUI:ScalePixel(y, frame))
    else
        frame:ClearAllPoints()
        EXUI:SetPoint(frame, point, UIParent, relativePoint, x, y)
    end
end

local function isEditorActive(frame)
    return frame and frame.editor and frame.editor:IsShown()
end

local function hookHoverTarget(frame, onEnter, onLeave)
    if not frame or frame.__exuiHoverHooked then
        return
    end
    frame.__exuiHoverHooked = true
    frame:HookScript('OnEnter', onEnter)
    frame:HookScript('OnLeave', function()
        C_Timer.After(0.05, onLeave)
    end)
end

microMenu.ApplyOrientation = function(self, config)
    if not MicroMenu then
        return
    end

    local isVertical = config.orientation == 'vertical'
    MicroMenu.isHorizontal = not isVertical

    if isVertical then
        MicroMenu.stride = MicroMenu.numButtons or 1
    else
        MicroMenu.stride = MicroMenu.numButtons or 12
    end

    local reversed = config.order == 'reverse'
    if reversed then
        MicroMenu.layoutFramesGoingRight = false
        MicroMenu.layoutFramesGoingUp = true
    else
        MicroMenu.layoutFramesGoingRight = true
        MicroMenu.layoutFramesGoingUp = false
    end

    MicroMenu.alwaysUpdateLayout = true
end

microMenu.ApplyLayout = function(self)
    if MicroMenu and MicroMenu:GetParent() ~= MicroMenuContainer then
        MicroMenu:SetParent(MicroMenuContainer)
    end

    if MicroMenu and MicroMenu.Layout then
        MicroMenu:Layout()
    end
    if MicroMenuContainer and MicroMenuContainer.Layout then
        MicroMenuContainer:Layout()
    end

    if MicroMenu then
        MicroMenu.alwaysUpdateLayout = nil
    end
end

microMenu.UpdateMicroVisibilityAlpha = function(self, config, isHovering)
    if not MicroMenuContainer then
        return
    end

    if config.visibility == 'hidden' then
        MicroMenuContainer:Hide()
        return
    end

    MicroMenuContainer:Show()
    if isEditorActive(MicroMenuContainer) then
        MicroMenuContainer:SetAlpha(1)
    elseif config.visibility == 'hover' then
        MicroMenuContainer:SetAlpha(isHovering and 1 or 0)
    else
        MicroMenuContainer:SetAlpha(1)
    end
end

microMenu.UpdateBagsVisibilityAlpha = function(self, config, isHovering)
    if not BagsBar then
        return
    end

    if config.enable == false or config.visibility == 'hidden' then
        BagsBar:Hide()
        return
    end

    BagsBar:Show()
    if isEditorActive(BagsBar) then
        BagsBar:SetAlpha(1)
    elseif config.visibility == 'hover' then
        BagsBar:SetAlpha(isHovering and 1 or 0)
    else
        BagsBar:SetAlpha(1)
    end
end

microMenu.ConfigureMicroMouse = function(self, config)
    if not MicroMenuContainer then
        return
    end

    local hoverMode = config.visibility == 'hover'
    MicroMenuContainer:EnableMouse(hoverMode)
    MicroMenuContainer:SetPropagateMouseClicks(not hoverMode)

    if MicroMenu then
        MicroMenu:EnableMouse(hoverMode)
    end
end

microMenu.ConfigureBagsMouse = function(self, config)
    if not BagsBar then
        return
    end

    local hoverMode = config.enable ~= false and config.visibility == 'hover'
    BagsBar:EnableMouse(hoverMode)
    BagsBar:SetPropagateMouseClicks(not hoverMode)
end

microMenu.ApplyBags = function(self, db)
    if not BagsBar then
        return
    end

    local bagsConfig = db.bags or {}

    if bagsConfig.enable == false then
        BagsBar:Hide()
        return
    end

    applyFramePosition(BagsBar, bagsConfig, {
        point = 'BOTTOMRIGHT',
        relativePoint = 'BOTTOMRIGHT',
        x = -6,
        y = 39,
    })

    BagsBar:SetScale(bagsConfig.scale or 1)
    BagsBar.exuiBagsConfig = bagsConfig
    self:ConfigureBagsMouse(bagsConfig)
    self:UpdateBagsVisibilityAlpha(bagsConfig, BagsBar.isHovering)

    if not self.bagsEditorRegistered then
        local actionBars = EXUI:GetModule('action-bars')
        editor:RegisterFrameForEditor(BagsBar, 'Bag Bar', function(movedFrame)
            local point, _, relativePoint, xOfs, yOfs = movedFrame:GetPoint(1)
            local currentDb = actionBars:GetDB()
            currentDb.bags.anchorPoint = point
            currentDb.bags.relativeAnchor = relativePoint
            currentDb.bags.xOffset = xOfs
            currentDb.bags.yOffset = yOfs
            actionBars.Data:SetDB(currentDb)
            self:ApplyBags(currentDb)
        end, function()
            if BagsBar.Layout then
                BagsBar:Layout()
            end
            BagsBar.editor:SetEditorAsMovable()
        end, function()
            BagsBar.editorMoveOverride = nil
            self:ConfigureBagsMouse(actionBars:GetDB().bags or {})
            if BagsBar.Layout then
                BagsBar:Layout()
            end
        end)
        self.bagsEditorRegistered = true
    end
end

microMenu.Apply = function(self, db)
    if not MicroMenuContainer then
        return
    end

    local config = db.microMenu or {}

    if MicroButtonAndBagsBar then
        MicroButtonAndBagsBar:Hide()
    end

    if config.enable == false then
        MicroMenuContainer:Hide()
    else
        applyFramePosition(MicroMenuContainer, config, {
            point = 'BOTTOMRIGHT',
            relativePoint = 'BOTTOMRIGHT',
            x = -4,
            y = 4,
        })

        self:ApplyOrientation(config)
        self:ApplyLayout()
        self:ConfigureMicroMouse(config)

        MicroMenuContainer:SetScale(config.scale or 1)
        MicroMenuContainer.exuiMicroConfig = config
        self:UpdateMicroVisibilityAlpha(config, MicroMenuContainer.isHovering)
    end

    self:ApplyBags(db)

    if not self.editorRegistered and config.enable ~= false then
        local actionBars = EXUI:GetModule('action-bars')
        editor:RegisterFrameForEditor(MicroMenuContainer, 'Micro Menu', function(movedFrame)
            local point, _, relativePoint, xOfs, yOfs = movedFrame:GetPoint(1)
            local currentDb = actionBars:GetDB()
            currentDb.microMenu.anchorPoint = point
            currentDb.microMenu.relativeAnchor = relativePoint
            currentDb.microMenu.xOffset = xOfs
            currentDb.microMenu.yOffset = yOfs
            actionBars.Data:SetDB(currentDb)
            self:Apply(currentDb)
        end, function()
            self:ApplyLayout()
            MicroMenuContainer.editor:SetEditorAsMovable()
        end, function()
            MicroMenuContainer.editorMoveOverride = nil
            self:ConfigureMicroMouse(actionBars:GetDB().microMenu or {})
            self:ApplyLayout()
        end)
        self.editorRegistered = true
    end
end

microMenu.SetupHover = function(self, db)
    if not MicroMenuContainer or self.hoverHooked then
        return
    end
    self.hoverHooked = true

    local actionBars = EXUI:GetModule('action-bars')
    MicroMenuContainer.isHovering = false
    if BagsBar then
        BagsBar.isHovering = false
    end

    local function microTargetsMouseOver()
        if MicroMenuContainer:IsMouseOver() then
            return true
        end
        if MicroMenu and MicroMenu:IsMouseOver() then
            return true
        end
        if QueueStatusButton and QueueStatusButton:IsMouseOver() then
            return true
        end
        if MicroMenu then
            for _, child in ipairs({ MicroMenu:GetChildren() }) do
                if child:IsMouseOver() then
                    return true
                end
            end
        end
        return false
    end

    local function bagsTargetsMouseOver()
        if not BagsBar then
            return false
        end
        if BagsBar:IsMouseOver() then
            return true
        end
        for _, child in ipairs({ BagsBar:GetChildren() }) do
            if child:IsMouseOver() then
                return true
            end
        end
        return false
    end

    local function setMicroHover(state)
        if isEditorActive(MicroMenuContainer) then
            return
        end
        MicroMenuContainer.isHovering = state
        local cfg = MicroMenuContainer.exuiMicroConfig
        if cfg then
            self:UpdateMicroVisibilityAlpha(cfg, state)
        end
    end

    local function setBagsHover(state)
        if isEditorActive(BagsBar) then
            return
        end
        if BagsBar then
            BagsBar.isHovering = state
        end
        local cfg = BagsBar and BagsBar.exuiBagsConfig
        if cfg then
            self:UpdateBagsVisibilityAlpha(cfg, state)
        end
    end

    local function onMicroEnter()
        setMicroHover(true)
    end

    local function onMicroLeave()
        if not microTargetsMouseOver() then
            setMicroHover(false)
        end
    end

    local function onBagsEnter()
        setBagsHover(true)
    end

    local function onBagsLeave()
        if not bagsTargetsMouseOver() then
            setBagsHover(false)
        end
    end

    hookHoverTarget(MicroMenuContainer, onMicroEnter, onMicroLeave)
    if MicroMenu then
        hookHoverTarget(MicroMenu, onMicroEnter, onMicroLeave)
        for _, child in ipairs({ MicroMenu:GetChildren() }) do
            hookHoverTarget(child, onMicroEnter, onMicroLeave)
        end
    end
    if QueueStatusButton then
        hookHoverTarget(QueueStatusButton, onMicroEnter, onMicroLeave)
    end

    if BagsBar then
        hookHoverTarget(BagsBar, onBagsEnter, onBagsLeave)
        for _, child in ipairs({ BagsBar:GetChildren() }) do
            hookHoverTarget(child, onBagsEnter, onBagsLeave)
        end
    end
end

microMenu.InitHousingHook = function(self)
    if self.housingHooked or not EventRegistry then
        return
    end
    self.housingHooked = true
    EventRegistry:RegisterCallback('HouseEditor.StateUpdated', function(_, active)
        if microMenu.housingActive == active then
            return
        end
        microMenu.housingActive = active
        if not active then
            local mod = EXUI:GetModule('action-bars')
            if mod.enabled then
                manager:RefreshAll()
            end
        end
    end)
end

microMenu.Init = function(self)
    self:InitHousingHook()

    if self.deferredApplyRegistered then
        return
    end
    self.deferredApplyRegistered = true

    local function reapply()
        if manager.enabled then
            self:Apply(manager:GetDB())
        end
    end

    EXUI:RegisterEventHandler('PLAYER_ENTERING_WORLD', 'action-bars-micro-menu-reapply', function()
        C_Timer.After(0, reapply)
    end)

    if EditModeManagerFrame then
        hooksecurefunc(EditModeManagerFrame, 'UpdateSystems', function()
            if manager.enabled then
                C_Timer.After(0, reapply)
            end
        end)
    end
end
