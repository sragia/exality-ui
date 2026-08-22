---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIAuraDisplaysPreview
local adPreview = EXUI:GetModule('aura-displays-preview')

---@class EXUINameplatesAuras
local npAuras = EXUI:GetModule('np-auras')

---@class EXUINameplatesAurasApply
local apply = EXUI:GetModule('np-auras-apply')

---@class EXUINameplatesAurasPreview
local preview = EXUI:GetModule('np-auras-preview')

preview.activeDisplayID = nil
preview.activeStateKeys = {}
preview.contextUnit = nil

local function stateKey(displayID)
    return ('np:%s'):format(displayID)
end

local function positionPreviewContainer(container, frame, display)
    apply:AnchorContainer(container, frame, display)
    apply:ApplyFrameLayer(container, frame, display)
end

local function layoutDisplayForFrame(display, frame)
    return {
        containerAnchorPoint = display.containerAnchorPoint,
        horizontalGrowth = display.horizontalGrowth,
        verticalGrowth = display.verticalGrowth,
        paddingLeft = display.paddingLeft,
        paddingRight = display.paddingRight,
        paddingTop = display.paddingTop,
        paddingBottom = display.paddingBottom,
        rowWidth = apply:GetRowWidth(frame, display),
        anchorPoint = display.anchorPoint,
        relativePoint = display.relativePoint,
        XOff = display.XOff,
        YOff = display.YOff,
        matchUnitFrameWidth = display.matchUnitFrameWidth,
        frameStrata = display.frameStrata,
        frameLevel = display.frameLevel,
    }
end

function preview:Init()
end

function preview:GetPreviewFrame()
    local npPreview = EXUI:GetModule('np-preview')
    return npPreview and npPreview.frame
end

function preview:IsEditorOpen()
    local editor = EXUI:GetModule('np-aura-editor')
    return editor and editor.window and editor.window:IsShown()
end

function preview:HookEditorWindow(window)
    if not window or window.exuiNPAuraPreviewHooked then
        return
    end
    window.exuiNPAuraPreviewHooked = true

    local previousOnClose = window.onClose
    window.onClose = function()
        preview.activeDisplayID = nil
        preview:RefreshOnPlate(preview:GetPreviewFrame())
        if previousOnClose then
            previousOnClose()
        end
    end
end

function preview:SetContext(unitType)
    self.contextUnit = unitType
end

function preview:ClearPreviewStates()
    for key in pairs(self.activeStateKeys) do
        adPreview:HidePreview(key)
    end
    wipe(self.activeStateKeys)
end

function preview:Clear()
    self.activeDisplayID = nil
    local frame = self:GetPreviewFrame()
    if frame and frame:IsShown() then
        self:RefreshOnPlate(frame)
        return
    end
    self:ClearPreviewStates()
end

function preview:GetPreviewGroup(displayID, display)
    if self:IsEditorOpen() then
        local editor = EXUI:GetModule('np-aura-editor')
        if editor and editor.currItemID == displayID then
            local groupID = npAuras.currGroupID
            local group = groupID and display.groups and display.groups[groupID]
            if group and group.visual then
                return group
            end
        end
    end
    local firstID = display.groupOrder and display.groupOrder[1]
    return firstID and display.groups and display.groups[firstID]
end

function preview:ShouldPreviewDisplay(displayID, display)
    if not display then
        return false
    end
    if self:IsEditorOpen() and displayID == self.activeDisplayID then
        return true
    end
    return display.enable ~= false
end

function preview:ShowDisplay(frame, displayID, display)
    local group = self:GetPreviewGroup(displayID, display)
    if not group or not group.visual then
        return
    end
    local key = stateKey(displayID)
    adPreview:BuildPreviewOnFrame(
        key,
        frame,
        layoutDisplayForFrame(display, frame),
        group.visual,
        positionPreviewContainer,
        adPreview:GetPreviewCount(group)
    )
    self.activeStateKeys[key] = true
end

function preview:RefreshOnPlate(frame)
    self:ClearPreviewStates()
    if not frame or not frame:IsShown() or not npAuras:IsSupported() then
        return
    end

    for displayID, display in pairs(npAuras:GetDisplays()) do
        if self:ShouldPreviewDisplay(displayID, display) then
            self:ShowDisplay(frame, displayID, display)
        end
    end
end

function preview:GetHostExtra()
    local extraW, extraH = 0, 0
    if not npAuras:IsSupported() then
        return extraW, extraH
    end

    for displayID, display in pairs(npAuras:GetDisplays()) do
        if self:ShouldPreviewDisplay(displayID, display) then
            local group = self:GetPreviewGroup(displayID, display)
            local visual = group and group.visual or {}
            local count = adPreview:GetPreviewCount(group)
            local iconW = visual.iconWidth or 20
            local iconH = visual.iconHeight or 20
            local spacingX = visual.elementSpacingX or 1
            local spacingY = visual.elementSpacingY or 1
            local rowW = display.rowWidth
            if display.matchUnitFrameWidth ~= false or not rowW or rowW <= 0 then
                rowW = nil
            end
            local wide = rowW or ((iconW + spacingX) * math.max(1, count))
            local tall = iconH + spacingY
            if rowW and rowW > 0 then
                local perRow = math.max(1, math.floor(rowW / math.max(1, iconW + spacingX)))
                tall = (iconH + spacingY) * math.max(1, math.ceil(count / perRow))
            end

            local rel = display.relativePoint or 'TOPLEFT'
            extraW = math.max(extraW, math.abs(display.XOff or 0))
            extraH = math.max(extraH, math.abs(display.YOff or 0))
            if rel:find('RIGHT', 1, true) or rel:find('LEFT', 1, true) then
                extraW = math.max(extraW, wide + math.abs(display.XOff or 0) + 8)
            end
            if rel:find('TOP', 1, true) or rel:find('BOTTOM', 1, true) then
                extraH = math.max(extraH, tall + math.abs(display.YOff or 0) + 8)
            end
        end
    end

    return extraW, extraH
end

function preview:Sync(displayID)
    self.activeDisplayID = displayID or self.activeDisplayID
    if not self:IsEditorOpen() then
        self.activeDisplayID = displayID
    end
    local frame = self:GetPreviewFrame()
    if frame and frame:IsShown() then
        self:RefreshOnPlate(frame)
    end
end

function preview:OnDisplayChanged(displayID)
    self:Sync(displayID or self.activeDisplayID)
end
