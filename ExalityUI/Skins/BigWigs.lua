---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkinsBigWigs
local bigWigs = EXUI:GetModule('big-wigs')

bigWigs.skinApplied = false

local BORDER_THICKNESS = 1

---Inset fill/icon inside the PP border. Top/sides inset; bottom stays flush (bottom border is outward).
local function ApplyBarInsets(bar)
    local inset = EXUI:GetBorderInset(bar, BORDER_THICKNESS)
    local statusbar = bar.candyBarBar
    local icon = bar.candyBarIconFrame

    local reApplyIcon, reApplyAtlas
    if (icon:IsAnchoringSecret()) then
        if (bar:IsIconAtlas()) then
            reApplyAtlas = bar:GetIconAtlas()
        else
            reApplyIcon = bar:GetIcon()
        end
        icon:SetToDefaults()
    end

    statusbar:ClearAllPoints()
    icon:ClearAllPoints()

    if (bar:IsIconVisible()) then
        local iconSize = (bar.height or bar:GetHeight()) - inset
        icon:SetWidth(iconSize)
        if (bar:GetIconPosition() == 'RIGHT') then
            icon:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', -inset, -inset)
            icon:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', -inset, 0)
            statusbar:SetPoint('TOPRIGHT', icon, 'TOPLEFT', 0, 0)
            statusbar:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMLEFT', 0, 0)
            statusbar:SetPoint('TOPLEFT', bar, 'TOPLEFT', inset, -inset)
            statusbar:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', inset, 0)
        else
            icon:SetPoint('TOPLEFT', bar, 'TOPLEFT', inset, -inset)
            icon:SetPoint('BOTTOMLEFT', bar, 'BOTTOMLEFT', inset, 0)
            statusbar:SetPoint('TOPLEFT', icon, 'TOPRIGHT', 0, 0)
            statusbar:SetPoint('BOTTOMLEFT', icon, 'BOTTOMRIGHT', 0, 0)
            statusbar:SetPoint('TOPRIGHT', bar, 'TOPRIGHT', -inset, -inset)
            statusbar:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', -inset, 0)
        end
    else
        statusbar:SetPoint('TOPLEFT', bar, 'TOPLEFT', inset, -inset)
        statusbar:SetPoint('BOTTOMRIGHT', bar, 'BOTTOMRIGHT', -inset, 0)
    end

    if (reApplyAtlas) then
        icon:SetAtlas(reApplyAtlas)
    elseif (reApplyIcon) then
        icon:SetTexture(reApplyIcon)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end

    if (bar:IsIconVisible()) then
        icon:Show()
    else
        icon:Hide()
    end
end

bigWigs.Init = function(self)
    if (BigWigsAPI and BigWigsAPI.RegisterBarStyle) then
        self:InstallSkin()
    else
        EXUI:RegisterEventHandler('ADDON_LOADED', 'BigWigs', function(event, addon)
            if (addon == 'BigWigs') then
                self:InstallSkin()
            end
        end)
    end
end

bigWigs.ApplyStyle = function(self, bar)
    if (not bar.EXUI) then
        bar.EXUI = {}

        bar.EXUI.Border = EXUI:AddPixelPerfectBorder(bar, BORDER_THICKNESS, { layer = 'OVERLAY', register = false })
    end
    bar.EXUI.Border:SetBorderColor(0, 0, 0, 1)
    bar.EXUI.Border:SetBorderThickness(BORDER_THICKNESS)
    ApplyBarInsets(bar)
    bar.candyBarBackground:SetVertexColor(0, 0, 0, 0.7)
    bar.candyBarDuration:ClearAllPoints()
    bar.candyBarDuration:SetPoint('RIGHT', bar.candyBarBar, 'RIGHT', -5, 0)
end

bigWigs.Stopped = function(self, bar)
    -- Maybe something here later?
end

bigWigs.InstallSkin = function(self)
    self.skinApplied = true

    if (BigWigsAPI and BigWigsAPI.RegisterBarStyle) then
        BigWigsAPI:RegisterBarStyle('ExalityUI', {
            apiVersion = 1,
            version = 1,
            barSpacing = 1,
            barHeight = 16,
            ApplyStyle = function(bar) self:ApplyStyle(bar) end,
            Stopped = function(bar) self:Stopped(bar) end,
            GetStyleName = function() return 'ExalityUI' end,
        })
    end
end
