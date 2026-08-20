---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIActionBarsConfigResolver
local configResolver = EXUI:GetModule('action-bars-config-resolver')

---@class EXUIActionBarsLeaveVehicle
local leaveVehicle = EXUI:GetModule('action-bars-leave-vehicle')

---@class EXUIActionBarsManager
local manager = EXUI:GetModule('action-bars-manager')

---@class EXUIActionBarsStyle
local barStyle = EXUI:GetModule('action-bars-style')

local EXIT_UP = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Up]]
local EXIT_DOWN = [[Interface\Vehicles\UI-Vehicles-Button-Exit-Down]]
local EXIT_LEFT = 0.140625
local EXIT_RIGHT = 0.859375
local EXIT_TOP = 0.140625
local EXIT_BOTTOM = 0.859375

local DEFAULT_ANCHOR = {
    point = 'BOTTOM',
    relativePoint = 'BOTTOM',
    x = -220,
    y = 4,
}

local EVENTS = {
    'UPDATE_BONUS_ACTIONBAR',
    'UPDATE_MULTI_CAST_ACTIONBAR',
    'UNIT_ENTERED_VEHICLE',
    'UNIT_EXITED_VEHICLE',
    'VEHICLE_UPDATE',
    'PLAYER_ENTERING_WORLD',
    'PLAYER_CONTROL_LOST',
    'PLAYER_CONTROL_GAINED',
    'UPDATE_BINDINGS',
}

leaveVehicle.frame = nil
leaveVehicle.button = nil
leaveVehicle.cachedConfig = nil
leaveVehicle.editorRegistered = false
leaveVehicle.hoverHooked = false
leaveVehicle.eventsInitialized = false
leaveVehicle.landingRequested = false

local function isEditorActive(frame)
    return frame and frame.editor and frame.editor:IsShown()
end

local function canExit()
    return CanExitVehicle() or UnitOnTaxi('player')
end

local function applyFramePosition(frame, config)
    if not frame then
        return
    end

    local point = config.anchorPoint or DEFAULT_ANCHOR.point
    local relativePoint = config.relativeAnchor or DEFAULT_ANCHOR.relativePoint
    local x = config.xOffset
    if x == nil then
        x = DEFAULT_ANCHOR.x
    end
    local y = config.yOffset
    if y == nil then
        y = DEFAULT_ANCHOR.y
    end

    frame:ClearAllPoints()
    EXUI:SetPoint(frame, point, UIParent, relativePoint, x, y)
end

leaveVehicle.CanShow = function(self)
    return canExit()
end

leaveVehicle.GetFrame = function(self)
    if self.frame then
        return self.frame
    end

    local frame = CreateFrame('Frame', 'EXUIActionBar_vehicleLeave', UIParent)
    frame:SetClampedToScreen(true)
    frame:EnableMouse(false)
    frame.barId = 'vehicleLeave'
    frame.isHovering = false

    local button = CreateFrame('Button', frame:GetName() .. 'Button', frame)
    button:SetAllPoints()
    button:EnableMouse(true)
    if button.SetMotionScriptsWhileDisabled then
        button:SetMotionScriptsWhileDisabled(true)
    end
    button.exuiBarId = 'vehicleLeave'
    button.index = 1
    button.id = 1
    button.HasAction = function()
        return true
    end

    local icon = button:CreateTexture(button:GetName() .. 'Icon', 'BACKGROUND')
    icon:SetAllPoints()
    icon:SetTexture(EXIT_UP)
    icon:SetTexCoord(EXIT_LEFT, EXIT_RIGHT, EXIT_TOP, EXIT_BOTTOM)
    button.icon = icon

    button:SetPushedTexture(EXIT_DOWN)
    local pushed = button:GetPushedTexture()
    if pushed then
        pushed:SetAllPoints()
        pushed:SetTexCoord(EXIT_LEFT, EXIT_RIGHT, EXIT_TOP, EXIT_BOTTOM)
    end

    local hotkey = button:CreateFontString(button:GetName() .. 'HotKey', 'OVERLAY', 'NumberFontNormalSmallGray')
    hotkey:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 2)
    button.HotKey = hotkey

    button:SetScript('OnClick', function(btn)
        leaveVehicle:OnClicked(btn)
    end)
    button:SetScript('OnEnter', function(btn)
        leaveVehicle:OnEnter(btn)
    end)
    button:SetScript('OnLeave', GameTooltip_Hide)

    frame.buttons = { button }
    self.frame = frame
    self.button = button
    return frame
end

leaveVehicle.OnClicked = function(self, button)
    if UnitOnTaxi('player') then
        TaxiRequestEarlyLanding()
        self.landingRequested = true
        button:Disable()
        button:LockHighlight()
    else
        VehicleExit()
    end
end

leaveVehicle.OnEnter = function(self, button)
    GameTooltip:SetOwner(button, 'ANCHOR_RIGHT')
    if UnitOnTaxi('player') then
        GameTooltip_SetTitle(GameTooltip, TAXI_CANCEL)
        GameTooltip:AddLine(TAXI_CANCEL_DESCRIPTION, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, true)
    else
        GameTooltip_SetTitle(GameTooltip, LEAVE_VEHICLE)
    end
    GameTooltip:Show()
end

leaveVehicle.UpdateHotkey = function(self)
    local button = self.button
    if not button or not button.HotKey then
        return
    end

    local key = GetBindingKey('VEHICLEEXIT')
    if key then
        button.HotKey:SetText(GetBindingText(key, 1))
    else
        button.HotKey:SetText('')
    end
end

leaveVehicle.ApplyHotkeyLayout = function(self, config)
    local button = self.button
    if not button or not button.HotKey or not config then
        return
    end

    barStyle:ApplyFontString(button.HotKey, config.hotkey)

    local hotkeyConfig = config.hotkey
    if not hotkeyConfig or hotkeyConfig.enabled == false then
        return
    end

    button.HotKey:ClearAllPoints()
    button.HotKey:SetPoint(
        hotkeyConfig.anchorPoint or 'BOTTOMRIGHT',
        button,
        hotkeyConfig.relativePoint or hotkeyConfig.anchorPoint or 'BOTTOMRIGHT',
        hotkeyConfig.xOffset or -2,
        hotkeyConfig.yOffset or 2
    )
    if button.HotKey.SetJustifyH then
        button.HotKey:SetJustifyH(EXUI.utils.getJustifyHFromAnchor(hotkeyConfig.anchorPoint))
    end
    self:UpdateHotkey()
end

leaveVehicle.ApplyStyle = function(self, config)
    local frame = self.frame
    local button = self.button
    if not frame or not button or not config then
        return
    end

    EXUI:SetSize(frame, config.width, config.height)
    EXUI:SetSize(button, config.width, config.height)
    button.exuiBarConfig = config

    barStyle:Init()
    barStyle:NormalizeAbilityButtonIcon(button)

    if barStyle:ShouldUseMasque(config) then
        local group = barStyle:GetMasqueGroup('vehicleLeave', config.masqueSkin)
        if group and not button.MasqueSkinned then
            group:AddButton(button, nil, 'Action')
            button.MasqueSkinned = true
        end
    end

    barStyle:OnButtonUpdated(button, config)
    self:ApplyHotkeyLayout(config)
end

leaveVehicle.ResetClickState = function(self)
    local button = self.button
    if not button then
        return
    end
    self.landingRequested = false
    button:Enable()
    button:UnlockHighlight()
end

leaveVehicle.UpdateShownState = function(self)
    local frame = self.frame
    local config = self.cachedConfig
    if not frame then
        return
    end

    if not manager.enabled or not config or not config.enable or config.visibility == 'hidden' then
        frame:Hide()
        return
    end

    local editorOpen = isEditorActive(frame)
    if not editorOpen and not self:CanShow() then
        self:ResetClickState()
        frame:Hide()
        return
    end

    frame:Show()

    if editorOpen then
        frame:SetAlpha(1)
        self:ResetClickState()
        return
    end

    if not UnitOnTaxi('player') or not self.landingRequested then
        self:ResetClickState()
    end

    if config.visibility == 'hover' then
        frame:SetAlpha(frame.isHovering and 1 or 0)
    else
        frame:SetAlpha(1)
    end
end

leaveVehicle.RegisterEditor = function(self)
    local frame = self.frame
    if not frame or self.editorRegistered then
        return
    end

    local actionBars = EXUI:GetModule('action-bars')
    editor:RegisterFrameForEditor(frame, (self.cachedConfig and self.cachedConfig.name) or 'Leave Vehicle', function(movedFrame)
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
        local barDb = currentDb.bars.vehicleLeave
        barDb.anchorPoint = point
        barDb.relativeAnchor = relativePoint
        barDb.xOffset = xOfs
        barDb.yOffset = yOfs
        actionBars.Data:SetDB(currentDb)
        if not editor.enabled then
            self:Apply(currentDb)
        end
    end, function()
        frame._exuiSavedAlpha = frame:GetAlpha()
        frame:Show()
        frame:SetAlpha(1)
        frame.editor:SetEditorAsMovable()
    end, function()
        frame.editorMoveOverride = nil
        if frame._exuiSavedAlpha then
            frame:SetAlpha(frame._exuiSavedAlpha)
            frame._exuiSavedAlpha = nil
        end
        self:UpdateShownState()
    end)
    self.editorRegistered = true
end

leaveVehicle.SetupHover = function(self)
    local frame = self.frame
    local button = self.button
    if not frame or not button or self.hoverHooked then
        return
    end
    self.hoverHooked = true
    frame.isHovering = false

    local function setHover(state)
        if isEditorActive(frame) then
            return
        end
        frame.isHovering = state
        if self.cachedConfig then
            self:UpdateShownState()
        end
    end

    local function onLeave()
        C_Timer.After(0.05, function()
            if not frame:IsMouseOver() and not button:IsMouseOver() then
                setHover(false)
            end
        end)
    end

    button:HookScript('OnEnter', function()
        setHover(true)
    end)
    button:HookScript('OnLeave', onLeave)
end

leaveVehicle.Apply = function(self, db)
    local config = configResolver:GetBarConfig(db, 'vehicleLeave')
    local frame = self:GetFrame()
    frame.exuiBarConfig = config
    self.cachedConfig = config

    if not config.enable then
        frame:Hide()
        return
    end

    applyFramePosition(frame, config)
    self:ApplyStyle(config)
    self:RegisterEditor()
    if frame.editor then
        editor:UpdateFrameLabel(frame, config.name or 'Leave Vehicle')
    end
    self:UpdateShownState()
end

leaveVehicle.OnEvent = function(self, event, unit)
    if not manager.enabled then
        return
    end

    if (event == 'UNIT_ENTERED_VEHICLE' or event == 'UNIT_EXITED_VEHICLE') and unit ~= 'player' then
        return
    end

    if event == 'UPDATE_BINDINGS' then
        self:UpdateHotkey()
        return
    end

    self:UpdateShownState()
end

leaveVehicle.InitEvents = function(self)
    if self.eventsInitialized then
        return
    end
    self.eventsInitialized = true

    local eventFrame = CreateFrame('Frame')
    for _, event in ipairs(EVENTS) do
        eventFrame:RegisterEvent(event)
    end
    eventFrame:SetScript('OnEvent', function(_, event, ...)
        leaveVehicle:OnEvent(event, ...)
    end)
    self.eventFrame = eventFrame
end

leaveVehicle.Disable = function(self)
    if self.frame then
        self.frame:Hide()
    end
    if self.button then
        self.button.MasqueSkinned = nil
    end
    self:ResetClickState()
end

leaveVehicle.Init = function(self)
    self:GetFrame()
    self:InitEvents()
end
