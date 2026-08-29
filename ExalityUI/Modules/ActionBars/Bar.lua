---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIActionBarsDefinitions
local definitions = EXUI:GetModule('action-bars-definitions')

---@class EXUIActionBarsConfigResolver
local configResolver = EXUI:GetModule('action-bars-config-resolver')

---@class EXUIActionBarsLayout
local barLayout = EXUI:GetModule('action-bars-layout')

---@class EXUIActionBarsButton
local buttonMod = EXUI:GetModule('action-bars-button')

---@class EXUIActionBarsSpecialButton
local specialButton = EXUI:GetModule('action-bars-special-button')

---@class EXUIActionBarsStateDriver
local stateDriver = EXUI:GetModule('action-bars-state-driver')

---@class EXUIActionBarsStateController
local stateController = EXUI:GetModule('action-bars-state')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

local STATE_VISIBILITY_BARS = {
    pet = true,
    override = true,
}

barMod.instances = {}

barMod.IsStateControlledBar = function(self, barId)
    return STATE_VISIBILITY_BARS[barId] == true
end

barMod.IsBarEditorActive = function(self, frame)
    return frame and frame.editor and frame.editor:IsShown()
end

barMod.ApplyStateControlledVisibility = function(self, frame, config, db)
    local barId = frame.barId
    if not self:IsStateControlledBar(barId) then
        return false
    end

    if self:IsBarEditorActive(frame) then
        if not config.enable or config.visibility == 'hidden' then
            frame:Hide()
        else
            specialButton:UpdateAll(frame)
            frame:Show()
            frame:SetAlpha(1)
        end
        return true
    end

    if barId == 'pet' then
        stateController:UpdatePetBar(db)
    elseif barId == 'override' then
        stateController:UpdateOverrideBar(db)
    end
    return true
end

barMod.Create = function(self, barId, db)
    local def = definitions:Get(barId)
    if not def then return nil end

    local config = configResolver:GetBarConfig(db, barId)
    local frame = CreateFrame('Frame', 'EXUIActionBar_' .. barId, UIParent, 'BackdropTemplate')
    frame:SetClampedToScreen(true)
    frame:EnableMouse(true)
    frame.barId = barId
    frame.buttons = {}

    local header = CreateFrame('Frame', frame:GetName() .. 'Header', frame, 'SecureHandlerStateTemplate')
    header:SetAllPoints()
    frame.header = header

    local numButtons = def.barType == 'stance' and 0 or math.min(config.numButtons, def.numButtons or config.numButtons)
    local assignActions = def.barType ~= 'action' or config.enable
    for i = 1, numButtons do
        local button
        if def.barType == 'action' then
            button = buttonMod:CreateActionButton(barId, i, header, config, assignActions)
        elseif def.barType == 'stance' then
            button = specialButton:CreateStanceButton(barId, i, header, config)
        elseif def.barType == 'pet' then
            button = specialButton:CreatePetButton(barId, i, header, config)
        elseif def.barType == 'override' then
            button = buttonMod:CreateActionButton(barId, i, header, config)
        end
        if button then
            buttonMod:RegisterWithKeybind(button)
            table.insert(frame.buttons, button)
        end
    end

    self:Configure(frame, db)
    self:SetupVisibility(frame, config)
    self:RegisterEditor(frame, barId)

    if barId == 'bar1' and frame.header then
        stateDriver:Init()
        stateDriver:ApplyToFrame(frame, config.states)
    end

    if def.barType == 'stance' or def.barType == 'pet' then
        specialButton:InitBarEvents(frame, def.barType)
    end

    self.instances[barId] = frame
    return frame
end

barMod.RegisterEditor = function(self, frame, barId)
    if frame.editorRegistered then
        return
    end

    local actionBars = EXUI:GetModule('action-bars')
    editor:RegisterFrameForEditor(frame, configResolver:GetBarConfig(actionBars:GetDB(), barId).name or barId, function(movedFrame)
        if movedFrame:GetNumPoints() == 0 then
            return
        end
        local point, _, relativePoint, xOfs, yOfs = movedFrame:GetPoint(1)
        if not point then
            return
        end
        xOfs = xOfs or 0
        yOfs = yOfs or 0
        local currentDb = actionBars:GetDB()
        local barDb = currentDb.bars[barId]
        barDb.anchorPoint = point
        barDb.relativeAnchor = relativePoint
        barDb.xOffset = xOfs
        barDb.yOffset = yOfs
        actionBars.Data:SetDB(currentDb)
        if not editor.enabled then
            barMod:Configure(movedFrame, currentDb)
        end
    end, function()
        frame._exuiSavedAlpha = frame:GetAlpha()
        frame:SetAlpha(1)
        if barMod:IsStateControlledBar(barId) then
            specialButton:UpdateAll(frame)
        elseif barId == 'bar1' then
            stateDriver:ForceApplyCurrentPage(frame)
        end
        frame.editor:SetEditorAsMovable()
        barMod:SetEditMode(frame, true)
    end, function()
        barMod:SetEditMode(frame, false)
        frame.editorMoveOverride = nil
        if frame._exuiSavedAlpha then
            frame:SetAlpha(frame._exuiSavedAlpha)
            frame._exuiSavedAlpha = nil
        end
    end)
    frame.editorRegistered = true
end

barMod.SetEditMode = function(self, frame, enabled)
    if not frame then return end
    if frame.header then
        frame.header:EnableMouse(not enabled)
    end
    for _, button in ipairs(frame.buttons or {}) do
        if enabled then
            if button._exuiMouseEnabled == nil then
                button._exuiMouseEnabled = button:IsMouseEnabled()
            end
            button:EnableMouse(false)
        else
            button:EnableMouse(button._exuiMouseEnabled ~= false)
            button._exuiMouseEnabled = nil
        end
    end
end

barMod.Configure = function(self, frame, db)
    if not frame then return end
    local barId = frame.barId
    local def = definitions:Get(barId)
    local previousConfig = frame.exuiBarConfig
    local config = configResolver:GetBarConfig(db, barId)
    frame.exuiBarConfig = config

    if not config.enable then
        if previousConfig and previousConfig.enable and def and def.barType == 'action' then
            for _, button in ipairs(frame.buttons or {}) do
                buttonMod:ClearActionStates(button)
            end
        end
        frame:Hide()
        return
    end

    if def and def.barType == 'action' and (not previousConfig or not previousConfig.enable) then
        for i, button in ipairs(frame.buttons or {}) do
            buttonMod:EnsureActionStates(button, barId, button.id or i)
        end
    end

    EXUI:SetPoint(frame, config.anchorPoint, UIParent, config.relativeAnchor, config.xOffset or 0, config.yOffset or 0)

    if barId == 'stance' then
        frame.exuiLastConfig = config
        specialButton:UpdateStanceButtons(frame, config)
    else
        barLayout:Apply(frame, config, frame.buttons)
    end

    for i, button in ipairs(frame.buttons) do
        if button.exuiBarId and button.UpdateConfig then
            local commandName = definitions:GetCommandName(barId, button.id or i)
            buttonMod:Refresh(button, barId, config)
        elseif specialButton.ApplyStyle and barId ~= 'stance' then
            EXUI:SetSize(button, config.width, config.height)
            specialButton:ApplyStyle(button, barId, config)
        elseif barId == 'stance' and button:IsShown() then
            EXUI:SetSize(button, config.width, config.height)
        end
    end

    if config.visibility == 'hidden' then
        frame:Hide()
    elseif barId == 'stance' then
        specialButton:ApplyStanceBarVisibility(frame, config)
    elseif self:ApplyStateControlledVisibility(frame, config, db) then
        -- pet / override visibility handled by game state
    else
        frame:Show()
        if frame.editor and frame.editor:IsShown() then
            frame:SetAlpha(1)
        else
            self:UpdateVisibilityAlpha(frame, config, frame.isHovering)
        end
    end

    if frame.editorRegistered then
        editor:UpdateFrameLabel(frame, config.name or barId)
    end

    if barId == 'bar1' and config.states then
        stateDriver:ApplyToFrame(frame, config.states)
    end
end

barMod.UpdateVisibilityAlpha = function(self, frame, config, isHovering)
    local alpha
    if config.visibility == 'hidden' then
        alpha = 0
    elseif config.visibility == 'hover' then
        alpha = isHovering and 1 or 0
    else
        alpha = 1
    end

    if InCombatLockdown() then
        frame:SetAlpha(alpha)
        return
    end

    if config.visibility == 'hidden' then
        frame:Hide()
        return
    end
    frame:Show()
    frame:SetAlpha(alpha)
end

barMod.SetupVisibility = function(self, frame, config)
    if frame.visibilityHooked then return end
    frame.visibilityHooked = true
    frame.isHovering = false

    local function setHover(state)
        if frame.editor and frame.editor:IsShown() then
            return
        end
        frame.isHovering = state
        local cfg = frame.exuiBarConfig
        if cfg then
            barMod:UpdateVisibilityAlpha(frame, cfg, state)
        end
    end

    frame:HookScript('OnEnter', function() setHover(true) end)
    frame:HookScript('OnLeave', function()
        C_Timer.After(0.05, function()
            if not frame:IsMouseOver() then
                local overButton = false
                for _, btn in ipairs(frame.buttons) do
                    if btn:IsMouseOver() then
                        overButton = true
                        break
                    end
                end
                if not overButton then
                    setHover(false)
                end
            end
        end)
    end)

    for _, button in ipairs(frame.buttons) do
        button:HookScript('OnEnter', function() setHover(true) end)
        button:HookScript('OnLeave', function()
            C_Timer.After(0.05, function()
                if not frame:IsMouseOver() and not button:IsMouseOver() then
                    setHover(false)
                end
            end)
        end)
    end
end

barMod.Destroy = function(self, barId)
    local frame = self.instances[barId]
    if frame then
        frame:Hide()
        frame:SetParent(nil)
        self.instances[barId] = nil
    end
end

barMod.Get = function(self, barId)
    return self.instances[barId]
end

barMod.ShowAll = function(self, shown)
    for _, frame in pairs(self.instances) do
        if shown then
            frame:Show()
        else
            frame:Hide()
        end
    end
end
