---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsMicroMenu
local microMenu = EXUI:GetModule('action-bars-micro-menu')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

microMenu.initialized = false

microMenu.ApplyOrientation = function(self, config)
    if not MicroMenu then
        return
    end

    local isVertical = config.orientation == 'vertical'
    MicroMenu.isHorizontal = not isVertical

    if isVertical then
        MicroMenu.stride = MicroMenu.numButtons or 1
        MicroMenu.layoutFramesGoingRight = true
        MicroMenu.layoutFramesGoingUp = true
    else
        MicroMenu.stride = MicroMenu.numButtons or 12
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

microMenu.ConfigureMouse = function(self, config)
    if not MicroMenuContainer then
        return
    end

    -- The container is only a layout box; it must not capture world clicks.
    MicroMenuContainer:EnableMouse(false)
    MicroMenuContainer:SetPropagateMouseClicks(true)

    if MicroMenu then
        MicroMenu:EnableMouse(true)
    end
end

microMenu.Apply = function(self, db)
    if not MicroMenuContainer then return end

    local config = db.microMenu or {}
    local bagsConfig = db.bags or {}

    if config.enable == false then
        MicroMenuContainer:Hide()
        if MicroButtonAndBagsBar then
            MicroButtonAndBagsBar:Hide()
        end
        return
    end

    EXUI:SetPoint(
        MicroMenuContainer,
        config.anchorPoint or 'BOTTOMRIGHT',
        UIParent,
        config.relativeAnchor or 'BOTTOMRIGHT',
        config.xOffset or -4,
        config.yOffset or 4
    )

    self:ApplyOrientation(config)
    self:ApplyLayout()
    self:ConfigureMouse(config)

    local scale = config.scale or 1
    MicroMenuContainer:SetScale(scale)

    if config.visibility == 'hidden' then
        MicroMenuContainer:Hide()
    else
        MicroMenuContainer:Show()
        if config.visibility == 'hover' then
            MicroMenuContainer:SetAlpha(0)
        else
            MicroMenuContainer:SetAlpha(1)
        end
    end

    if MicroButtonAndBagsBar then
        if bagsConfig.enable == false or bagsConfig.visibility == 'hidden' then
            MicroButtonAndBagsBar:Hide()
        else
            MicroButtonAndBagsBar:Show()
            MicroButtonAndBagsBar:SetScale(bagsConfig.scale or 1)
            if bagsConfig.visibility == 'hover' then
                MicroButtonAndBagsBar:SetAlpha(0)
            else
                MicroButtonAndBagsBar:SetAlpha(1)
            end
        end
    end

    if not self.editorRegistered and MicroMenuContainer then
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
            MicroMenuContainer.editor:SetEditorAsMovable()
        end, function()
            MicroMenuContainer.editorMoveOverride = nil
            self:ConfigureMouse(actionBars:GetDB().microMenu or {})
            self:ApplyLayout()
        end)
        self.editorRegistered = true
    end
end

microMenu.SetupHover = function(self, db)
    if not MicroMenuContainer or self.hoverHooked then return end
    self.hoverHooked = true

    local function updateHover(isHover)
        local cfg = db.microMenu
        if cfg and cfg.visibility == 'hover' then
            MicroMenuContainer:SetAlpha(isHover and 1 or 0)
        end
        local bagsCfg = db.bags
        if MicroButtonAndBagsBar and bagsCfg and bagsCfg.visibility == 'hover' then
            MicroButtonAndBagsBar:SetAlpha(isHover and 1 or 0)
        end
    end

    MicroMenuContainer:HookScript('OnEnter', function() updateHover(true) end)
    MicroMenuContainer:HookScript('OnLeave', function()
        C_Timer.After(0.05, function()
            if not MicroMenuContainer:IsMouseOver() then
                updateHover(false)
            end
        end)
    end)

    if MicroMenu then
        MicroMenu:HookScript('OnEnter', function() updateHover(true) end)
        MicroMenu:HookScript('OnLeave', function()
            C_Timer.After(0.05, function()
                if not MicroMenu:IsMouseOver() and not MicroMenuContainer:IsMouseOver() then
                    updateHover(false)
                end
            end)
        end)
    end
end

microMenu.InitHousingHook = function(self)
    if self.housingHooked or not EventRegistry then return end
    self.housingHooked = true
    EventRegistry:RegisterCallback('HouseEditor.StateUpdated', function(_, active)
        if microMenu.housingActive == active then return end
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
end
