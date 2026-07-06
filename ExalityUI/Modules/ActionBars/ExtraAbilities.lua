---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsConfigResolver
local configResolver = EXUI:GetModule('action-bars-config-resolver')

---@class EXUIActionBarsExtraAbilities
local extraAbilities = EXUI:GetModule('action-bars-extra-abilities')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

extraAbilities.anchorFrame = nil
extraAbilities.applyingLayout = false
extraAbilities.cachedConfig = nil
extraAbilities.pendingStyle = false
extraAbilities.pendingClickThrough = false

local function canModifyExtraFrames()
    return not InCombatLockdown()
end

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

extraAbilities.GetAnchorFrame = function(self)
    if not self.anchorFrame then
        local frame = CreateFrame('Frame', 'EXUIExtraAbilitiesAnchor', UIParent)
        frame:SetSize(1, 1)
        frame:SetClampedToScreen(true)
        frame:EnableMouse(false)
        frame:SetPropagateMouseClicks(true)
        self.anchorFrame = frame
    end
    return self.anchorFrame
end

extraAbilities.ConfigureClickThrough = function(self)
    if InCombatLockdown() then
        self.pendingClickThrough = true
        return
    end
    self.pendingClickThrough = false

    local function passThrough(frame)
        if not frame then
            return
        end
        frame:EnableMouse(false)
        if frame.SetPropagateMouseClicks then
            frame:SetPropagateMouseClicks(true)
        end
    end

    passThrough(self.anchorFrame)
    passThrough(ExtraAbilityContainer)
    passThrough(ExtraActionBarFrame)
    passThrough(ZoneAbilityFrame)
    if ZoneAbilityFrame then
        passThrough(ZoneAbilityFrame.SpellButtonContainer)
    end
end

extraAbilities.HookAbilityButtonHover = function(self)
    if not self.hoverHooked or not self._hoverOnEnter then
        return
    end

    if ExtraActionBarFrame and ExtraActionBarFrame.button then
        hookHoverTarget(ExtraActionBarFrame.button, self._hoverOnEnter, self._hoverOnLeave)
    end
    if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer then
        for _, child in ipairs({ ZoneAbilityFrame.SpellButtonContainer:GetChildren() }) do
            hookHoverTarget(child, self._hoverOnEnter, self._hoverOnLeave)
        end
    end
end

extraAbilities.ClearManagedContainer = function(self)
    if UIParentBottomManagedFrameContainer and ExtraAbilityContainer then
        UIParentBottomManagedFrameContainer.showingFrames[ExtraAbilityContainer] = nil
    end
end

extraAbilities.ApplyPending = function(self)
    if not manager.enabled or InCombatLockdown() or not self.cachedConfig then
        return
    end
    if not self.pendingStyle and not self.pendingLayout and not self.pendingClickThrough then
        return
    end

    local clickThroughOnly = self.pendingClickThrough and not self.pendingStyle and not self.pendingLayout

    self.pendingStyle = false
    self.pendingLayout = false
    self.pendingClickThrough = false

    if clickThroughOnly then
        self:ConfigureClickThrough()
    else
        self:ApplyStyle(self.cachedConfig)
        self:ApplyLayout()
    end
end

extraAbilities.ApplyLayout = function(self)
    if not ExtraAbilityContainer or not self.anchorFrame then
        return
    end
    if InCombatLockdown() then
        self.pendingLayout = true
        return
    end

    self.applyingLayout = true
    self:ClearManagedContainer()

    ExtraAbilityContainer:SetParent(self.anchorFrame)
    ExtraAbilityContainer:SetToplevel(false)
    if ExtraAbilityContainer.ClearAllPointsBase then
        ExtraAbilityContainer:ClearAllPointsBase()
        ExtraAbilityContainer:SetPointBase('CENTER', self.anchorFrame, 'CENTER', 0, 0)
    else
        ExtraAbilityContainer:ClearAllPoints()
        ExtraAbilityContainer:SetPoint('CENTER', self.anchorFrame, 'CENTER', 0, 0)
    end

    local config = self.cachedConfig
    if config and ExtraAbilityContainer.SetMinimumWidth then
        ExtraAbilityContainer:SetMinimumWidth(1)
        if ExtraAbilityContainer.ClearFixedSize then
            ExtraAbilityContainer:ClearFixedSize()
        end
    end

    if ExtraAbilityContainer.Layout then
        ExtraAbilityContainer:Layout()
    end

    if self.anchorFrame and ExtraAbilityContainer then
        local width = math.max(ExtraAbilityContainer:GetWidth() or 1, 1)
        local height = math.max(ExtraAbilityContainer:GetHeight() or 1, 1)
        self.anchorFrame:SetSize(width, height)
    end

    self:ConfigureClickThrough()

    self.applyingLayout = false
    self.pendingLayout = false
end

extraAbilities.StyleZoneAbilityFrame = function(self, config)
    if not ZoneAbilityFrame then
        return
    end

    if ZoneAbilityFrame.Style then
        ZoneAbilityFrame.Style:SetShown(config.showBlizzardArtwork == true)
    end

    if ZoneAbilityFrame.SpellButtonContainer then
        for _, child in ipairs({ ZoneAbilityFrame.SpellButtonContainer:GetChildren() }) do
            barStyle:StyleBlizzardAbilityButton(child, 'extra', config)
        end
    end

    local buttonSize = math.max(config.width, config.height)
    if config.showBlizzardArtwork then
        ZoneAbilityFrame:SetSize(256, 128)
    else
        ZoneAbilityFrame:SetSize(buttonSize + 8, buttonSize + 8)
    end
end

extraAbilities.StyleExtraActionFrame = function(self, config)
    if not ExtraActionBarFrame or not ExtraActionBarFrame.button then
        return
    end

    local button = ExtraActionBarFrame.button
    if button.style then
        button.style:SetShown(config.showBlizzardArtwork == true)
    end

    barStyle:StyleBlizzardAbilityButton(button, 'extra', config)

    local buttonSize = math.max(config.width, config.height)
    if config.showBlizzardArtwork then
        ExtraActionBarFrame:SetSize(256, 128)
    else
        ExtraActionBarFrame:SetSize(buttonSize + 8, buttonSize + 8)
    end
end

extraAbilities.ApplyStyle = function(self, config)
    if not config then
        return
    end
    self.cachedConfig = config

    if not canModifyExtraFrames() then
        self.pendingStyle = true
        return
    end
    self.pendingStyle = false

    barStyle:Init()

    self:StyleExtraActionFrame(config)
    self:StyleZoneAbilityFrame(config)
    self:ConfigureClickThrough()
    self:HookAbilityButtonHover()
end

extraAbilities.UpdateVisibilityAlpha = function(self, config, isHovering)
    local frame = self.anchorFrame
    if not frame then
        return
    end

    if config.visibility == 'hidden' then
        frame:Hide()
        return
    end

    frame:Show()
    if isEditorActive(frame) then
        frame:SetAlpha(1)
    elseif config.visibility == 'hover' then
        frame:SetAlpha(isHovering and 1 or 0)
    else
        frame:SetAlpha(1)
    end
end

extraAbilities.ConfigureMouse = function(self)
    self:ConfigureClickThrough()
end

extraAbilities.Apply = function(self, db)
    if not ExtraAbilityContainer then
        return
    end

    local config = configResolver:GetBarConfig(db, 'extra')
    local frame = self:GetAnchorFrame()

    if not config.enable then
        frame:Hide()
        return
    end

    applyFramePosition(frame, config, {
        point = 'BOTTOM',
        relativePoint = 'BOTTOM',
        x = 0,
        y = 160,
    })

    self:ApplyStyle(config)
    self:ApplyLayout()
    self:ConfigureClickThrough()
    self:UpdateVisibilityAlpha(config, frame.isHovering)

    if not self.editorRegistered then
        local actionBars = EXUI:GetModule('action-bars')
        editor:RegisterFrameForEditor(frame, config.name or 'Extra Abilities', function(movedFrame)
            local point, _, relativePoint, xOfs, yOfs = movedFrame:GetPoint(1)
            local currentDb = actionBars:GetDB()
            local barDb = currentDb.bars.extra
            barDb.anchorPoint = point
            barDb.relativeAnchor = relativePoint
            barDb.xOffset = xOfs
            barDb.yOffset = yOfs
            actionBars.Data:SetDB(currentDb)
            self:Apply(currentDb)
        end, function()
            frame._exuiSavedAlpha = frame:GetAlpha()
            frame:SetAlpha(1)
            self:ApplyLayout()
            frame.editor:SetEditorAsMovable()
        end, function()
            frame.editorMoveOverride = nil
            local actionBars = EXUI:GetModule('action-bars')
            self:ConfigureClickThrough()
            if frame._exuiSavedAlpha then
                frame:SetAlpha(frame._exuiSavedAlpha)
                frame._exuiSavedAlpha = nil
            end
            self:ApplyLayout()
        end)
        self.editorRegistered = true
    elseif frame.editor then
        editor:UpdateFrameLabel(frame, config.name or 'Extra Abilities')
    end
end

extraAbilities.SetupHover = function(self)
    local frame = self.anchorFrame
    if not frame or self.hoverHooked then
        return
    end
    self.hoverHooked = true
    frame.isHovering = false

    local actionBars = EXUI:GetModule('action-bars')

    local function targetsMouseOver()
        if ExtraActionBarFrame and ExtraActionBarFrame.button and ExtraActionBarFrame.button:IsMouseOver() then
            return true
        end
        if ZoneAbilityFrame and ZoneAbilityFrame.SpellButtonContainer then
            for _, child in ipairs({ ZoneAbilityFrame.SpellButtonContainer:GetChildren() }) do
                if child:IsMouseOver() then
                    return true
                end
            end
        end
        return false
    end

    local function setHover(state)
        if isEditorActive(frame) then
            return
        end
        frame.isHovering = state
        local config = configResolver:GetBarConfig(actionBars:GetDB(), 'extra')
        self:UpdateVisibilityAlpha(config, state)
    end

    local function onEnter()
        setHover(true)
    end

    local function onLeave()
        if not targetsMouseOver() then
            setHover(false)
        end
    end

    self._hoverOnEnter = onEnter
    self._hoverOnLeave = onLeave

    self:HookAbilityButtonHover()
end

extraAbilities.InitHooks = function(self)
    if self.hooksInitialized or not ExtraAbilityContainer then
        return
    end
    self.hooksInitialized = true

    hooksecurefunc(ExtraAbilityContainer, 'SetPoint', function()
        if not self.applyingLayout and self.anchorFrame and manager.enabled and canModifyExtraFrames() then
            self:ApplyLayout()
        elseif InCombatLockdown() then
            self.pendingLayout = true
        end
    end)

    if ExtraAbilityContainer.ApplySystemAnchor then
        hooksecurefunc(ExtraAbilityContainer, 'ApplySystemAnchor', function()
            self:ClearManagedContainer()
            if manager.enabled then
                if canModifyExtraFrames() then
                    self:ApplyLayout()
                else
                    self.pendingLayout = true
                end
            end
        end)
    end

    if ExtraAbilityContainer.HighlightSystem then
        hooksecurefunc(ExtraAbilityContainer, 'HighlightSystem', function()
            if ExtraAbilityContainer.Selection then
                ExtraAbilityContainer.Selection:Hide()
            end
        end)
    end

    if ExtraAbilityContainer.UpdateShownState then
        hooksecurefunc(ExtraAbilityContainer, 'UpdateShownState', function()
            if manager.enabled then
                self:ConfigureClickThrough()
            end
        end)
    end

    EXUI:RegisterEventHandler('PLAYER_REGEN_ENABLED', 'action-bars-extra-abilities-layout', function()
        extraAbilities:ApplyPending()
    end)

    if ZoneAbilityFrame and ZoneAbilityFrame.UpdateDisplayedZoneAbilities then
        hooksecurefunc(ZoneAbilityFrame, 'UpdateDisplayedZoneAbilities', function()
            C_Timer.After(0, function()
                if not manager.enabled or not extraAbilities.cachedConfig then
                    return
                end
                extraAbilities:ApplyStyle(extraAbilities.cachedConfig)
                extraAbilities:ApplyLayout()
            end)
        end)
    end

    if ZoneAbilityFrameSpellButtonMixin and ZoneAbilityFrameSpellButtonMixin.Refresh then
        hooksecurefunc(ZoneAbilityFrameSpellButtonMixin, 'Refresh', function()
            if manager.enabled and extraAbilities.cachedConfig then
                extraAbilities:ApplyStyle(extraAbilities.cachedConfig)
            end
        end)
    end

    if ExtraActionBar_Update then
        hooksecurefunc('ExtraActionBar_Update', function()
            C_Timer.After(0, function()
                if manager.enabled and extraAbilities.cachedConfig then
                    extraAbilities:ApplyStyle(extraAbilities.cachedConfig)
                end
            end)
        end)
    end
end

extraAbilities.Disable = function(self)
    if self.anchorFrame then
        self.anchorFrame:Hide()
    end
    if ExtraAbilityContainer then
        if ExtraAbilityContainer.ClearAllPointsBase then
            ExtraAbilityContainer:ClearAllPointsBase()
        else
            ExtraAbilityContainer:ClearAllPoints()
        end
        ExtraAbilityContainer:SetParent(UIParent)
        if ExtraAbilityContainer.ApplySystemAnchor then
            ExtraAbilityContainer:ApplySystemAnchor()
        end
    end
end

extraAbilities.Init = function(self)
    if not InCombatLockdown() then
        self:GetAnchorFrame()
    end
    self:InitHooks()
end
