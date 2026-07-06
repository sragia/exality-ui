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

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsBar
local barMod = EXUI:GetModule('action-bars-bar')

barMod.instances = {}

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
    for i = 1, numButtons do
        local button
        if def.barType == 'action' then
            button = buttonMod:CreateActionButton(barId, i, header, config)
        elseif def.barType == 'stance' then
            button = specialButton:CreateStanceButton(barId, i, header, config)
        elseif def.barType == 'pet' then
            button = specialButton:CreatePetButton(barId, i, header, config)
        elseif def.barType == 'possess' then
            button = specialButton:CreatePossessButton(barId, i, header, config)
        elseif def.barType == 'override' then
            button = buttonMod:CreateActionButton(barId, i, header, config)
        end
        if button then
            buttonMod:RegisterWithKeybind(button)
            table.insert(frame.buttons, button)
        end
    end

    if def.barType == 'override' then
        local leaveBtn = CreateFrame('Button', frame:GetName() .. '_LeaveVehicle', frame, 'SecureActionButtonTemplate')
        leaveBtn:SetAttribute('type', 'macro')
        leaveBtn:SetAttribute('macro', '/leavevehicle')
        leaveBtn:SetSize(32, 32)
        leaveBtn:SetPoint('TOP', frame, 'BOTTOM', 0, -4)
        local leaveTex = leaveBtn:CreateTexture(nil, 'ARTWORK')
        leaveTex:SetAllPoints()
        leaveTex:SetTexture('Interface\\Icons\\Spell_Shadow_SoulLeech_3')
        frame.leaveButton = leaveBtn
    end

    self:Configure(frame, db)
    self:SetupVisibility(frame, config)
    self:RegisterEditor(frame, barId)

    if barId == 'bar1' and frame.header then
        stateDriver:Init()
        stateDriver:ApplyToFrame(frame, config.states)
    end

    if def.barType == 'stance' or def.barType == 'pet' or def.barType == 'possess' then
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
        local point, _, relativePoint, xOfs, yOfs = movedFrame:GetPoint(1)
        local currentDb = actionBars:GetDB()
        local barDb = currentDb.bars[barId]
        barDb.anchorPoint = point
        barDb.relativeAnchor = relativePoint
        barDb.xOffset = xOfs
        barDb.yOffset = yOfs
        actionBars.Data:SetDB(currentDb)
        EXUI:SetPoint(frame, point, UIParent, relativePoint, xOfs, yOfs)
    end, function()
        frame._exuiSavedAlpha = frame:GetAlpha()
        frame:SetAlpha(1)
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
    local config = configResolver:GetBarConfig(db, barId)

    if not config.enable then
        frame:Hide()
        return
    end

    EXUI:SetPoint(frame, config.anchorPoint, UIParent, config.relativeAnchor, config.xOffset, config.yOffset)

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
            specialButton:ApplyStyle(button, barId, config)
            EXUI:SetSize(button, config.width, config.height)
        elseif barId == 'stance' and button:IsShown() then
            EXUI:SetSize(button, config.width, config.height)
        end
    end

    if config.visibility ~= 'hidden' then
        if barId == 'stance' then
            specialButton:ApplyStanceBarVisibility(frame, config)
        else
            frame:Show()
            if frame.editor and frame.editor:IsShown() then
                frame:SetAlpha(1)
            else
                self:UpdateVisibilityAlpha(frame, config, frame.isHovering)
            end
        end
    else
        frame:Hide()
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
        local cfg = configResolver:GetBarConfig(
            EXUI:GetModule('action-bars'):GetDB(),
            frame.barId
        )
        barMod:UpdateVisibilityAlpha(frame, cfg, state)
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
