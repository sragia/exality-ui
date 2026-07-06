---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkinsBigWigs
local bigWigs = EXUI:GetModule('big-wigs')

bigWigs.skinApplied = false

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

        bar.EXUI.Border = EXUI:AddPixelPerfectBorder(bar, 1, { layer = 'OVERLAY', register = false })
    end
    bar.EXUI.Border:SetBorderColor(0, 0, 0, 1)
    bar.candyBarBar:SetStatusBarTexture(EXUI.const.textures.frame.statusBar)
    bar.candyBarBackground:SetVertexColor(0, 0, 0, 0.7)
    bar.candyBarDuration:ClearAllPoints()
    bar.candyBarDuration:SetPoint('RIGHT', -5, 0)
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
