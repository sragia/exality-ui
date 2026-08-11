---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIBuffFrameSkin
local buffFrameSkin = EXUI:GetModule('skin-BuffFrame')

local function SuppressFrame(frame)
    if not frame then
        return
    end

    if frame.UnregisterAllEvents then
        frame:UnregisterAllEvents()
    end
    if frame.SetScript then
        frame:SetScript('OnUpdate', nil)
    end

    frame:Hide()

    hooksecurefunc(frame, 'Show', frame.Hide)
    hooksecurefunc(frame, 'SetShown', function(self, shown)
        if shown then
            self:Hide()
        end
    end)
end

local function HideDefaultAuraFrames()
    if BuffFrame and CVarCallbackRegistry and CVarCallbackRegistry.UnregisterCallback then
        CVarCallbackRegistry:UnregisterCallback('consolidateBuffs', BuffFrame)
        CVarCallbackRegistry:UnregisterCallback('collapseExpandBuffs', BuffFrame)
    end

    SuppressFrame(BuffFrame)
    SuppressFrame(DebuffFrame)
end

buffFrameSkin.Init = function(self)
    if not skins:IsEnabled('BuffFrame') then
        return
    end

    if BuffFrame or DebuffFrame then
        HideDefaultAuraFrames()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-BuffFrame', function(_, addon)
        if addon ~= 'Blizzard_BuffFrame' then
            return
        end
        HideDefaultAuraFrames()
    end)
end
