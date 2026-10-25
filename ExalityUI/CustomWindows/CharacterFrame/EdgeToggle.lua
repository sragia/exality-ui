---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class ExalityFramesTooltipInput
local tooltip = EXFrames:GetFrame('tooltip')

---@class EXUICharacterFrameEdgeToggle
local edgeToggle = EXUI:GetModule('character-frame-edge-toggle')

local BUTTON_WIDTH = 38
local BUTTON_HEIGHT = 30
local BUTTON_OUTSET_X = -10
local BUTTON_ICON_OFFSET_X = 5
local ANIM_DURATION = 0.18

edgeToggle.ApplyVisual = function(self, button, hovered)
    local theme = EXUI.const.theme
    local atlas = button.atlas
    if (atlas) then
        local enabled = button:IsEnabled()
        button.bg:SetVertexColor(unpack((hovered and enabled) and theme.backgroundLight or theme.backgroundDeep))
        button.icon:SetAtlas(not enabled and atlas.disabled or (hovered and atlas.hover) or atlas.normal)
        return
    end
    if (hovered and button:IsEnabled()) then
        button.bg:SetVertexColor(unpack(theme.backgroundLight))
        button.icon:SetVertexColor(unpack(button.iconHoverColor))
    else
        button.bg:SetVertexColor(unpack(theme.backgroundDeep))
        button.icon:SetVertexColor(unpack(button.iconColor))
    end
    button.icon:SetDesaturated(not button:IsEnabled())
end

edgeToggle.AttachBehindWindow = function(self, button, window, offsetX, offsetY)
    local animDuration = 0.2
    local diveY = 20

    button.hostWindow = window
    button:SetParent(window:GetParent() or UIParent)
    button:SetFrameStrata(window:GetFrameStrata())
    button:SetFrameLevel(math.max(1, window:GetFrameLevel() - 1))
    button:ClearAllPoints()
    button:SetPoint('TOPLEFT', window, 'TOPRIGHT', offsetX, offsetY)
    button:Hide()

    local function syncLayer()
        if not window:IsShown() then
            return
        end
        button:SetFrameStrata(window:GetFrameStrata())
        button:SetFrameLevel(math.max(1, window:GetFrameLevel() - 1))
    end

    -- Match window dive/fade. No point adjustment: layout already follows the window anchor.
    local windowFadeIn = button:CreateAnimationGroup()
    local alphaIn = windowFadeIn:CreateAnimation('Alpha')
    alphaIn:SetFromAlpha(0)
    alphaIn:SetToAlpha(1)
    alphaIn:SetDuration(animDuration)
    alphaIn:SetSmoothing('IN')
    local translateIn = windowFadeIn:CreateAnimation('Translation')
    translateIn:SetOffset(0, -diveY)
    translateIn:SetDuration(animDuration)
    translateIn:SetSmoothing('IN')
    windowFadeIn:SetScript('OnFinished', function()
        button:SetAlpha(1)
    end)
    button.windowFadeIn = windowFadeIn

    local windowFadeOut = button:CreateAnimationGroup()
    local alphaOut = windowFadeOut:CreateAnimation('Alpha')
    alphaOut:SetFromAlpha(1)
    alphaOut:SetToAlpha(0)
    alphaOut:SetDuration(animDuration)
    alphaOut:SetSmoothing('OUT')
    local translateOut = windowFadeOut:CreateAnimation('Translation')
    translateOut:SetOffset(0, diveY)
    translateOut:SetDuration(animDuration)
    translateOut:SetSmoothing('OUT')
    windowFadeOut:SetScript('OnFinished', function()
        button:SetAlpha(1)
        button:Hide()
    end)
    button.windowFadeOut = windowFadeOut

    local function stopWindowAnims()
        if button.windowFadeIn then
            button.windowFadeIn:Stop()
        end
        if button.windowFadeOut then
            button.windowFadeOut:Stop()
        end
    end
    button.stopWindowAnims = stopWindowAnims

    if window.fadeIn then
        window.fadeIn:HookScript('OnPlay', function()
            if button.edgeHidden then
                return
            end
            stopWindowAnims()
            if button.fadeIn then
                button.fadeIn:Stop()
            end
            syncLayer()
            button:SetAlpha(0)
            button:Show()
            button.windowFadeIn:Play()
        end)
    end

    if window.fadeOut then
        window.fadeOut:HookScript('OnPlay', function()
            if button.edgeHidden or not button:IsShown() then
                return
            end
            stopWindowAnims()
            if button.fadeIn then
                button.fadeIn:Stop()
            end
            button.windowFadeOut:Play()
        end)
    end

    window:HookScript('OnHide', function()
        stopWindowAnims()
        button:SetAlpha(1)
        button:Hide()
    end)

    window:HookScript('OnShow', syncLayer)
end

---@param options {icon?: string|number, atlas?: {normal: string, hover: string, disabled: string}, iconSize?: number, iconHeight?: number, offsetY: number, tooltip: string, iconColor: table, iconHoverColor: table, onClick: function, onEnter?: function}
edgeToggle.Create = function(self, window, options)
    local button = CreateFrame('Button', nil, window:GetParent() or UIParent)
    button:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
    button:SetMotionScriptsWhileDisabled(true)
    button.iconColor = options.iconColor
    button.iconHoverColor = options.iconHoverColor
    button.atlas = options.atlas

    local bg = button:CreateTexture(nil, 'BACKGROUND')
    bg:SetTexture(EXUI.const.textures.characterFrame.input.buttonBg)
    bg:SetTextureSliceMargins(20, 20, 20, 20)
    bg:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    bg:SetAllPoints()
    button.bg = bg

    local icon = button:CreateTexture(nil, 'OVERLAY')
    if (options.icon) then
        icon:SetTexture(options.icon)
    end
    local iconSize = options.iconSize or 18
    icon:SetSize(iconSize, options.iconHeight or iconSize)
    icon:SetPoint('CENTER', BUTTON_ICON_OFFSET_X, 0)
    icon:SetVertexColor(1, 1, 1, 1)
    button.icon = icon

    self:AttachBehindWindow(button, window, BUTTON_OUTSET_X, options.offsetY)

    button.Tooltip = tooltip:Get({
        text = options.tooltip
    }, button)

    button:SetScript('OnEnter', function(btn)
        edgeToggle:ApplyVisual(btn, true)
        if (options.onEnter) then
            options.onEnter(btn)
        else
            btn.Tooltip:ShowTooltip()
        end
    end)
    button:SetScript('OnLeave', function(btn)
        edgeToggle:ApplyVisual(btn, false)
        btn.Tooltip:HideTooltip()
        GameTooltip:Hide()
    end)
    button:SetScript('OnClick', function(btn)
        PlaySound(SOUNDKIT.IG_CHARACTER_INFO_TAB)
        options.onClick(btn)
    end)

    button.fadeIn = EXUI.utils.animation.fade(button, ANIM_DURATION, 0, 1)

    self:ApplyVisual(button, false)
    return button
end
