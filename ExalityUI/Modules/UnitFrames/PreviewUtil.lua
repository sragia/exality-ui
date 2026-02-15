---@class ExalityUI
local EXUI = select(2, ...)


---@class EXUIUnitFramesPreviewUtil
local previewUtil = EXUI:GetModule('uf-preview-util')

previewUtil.auraPool = CreateFramePool('Frame', UIParent)

previewUtil.Init = function(self)
end

local icons = {
    236265,
    135959,
    135926,
    135874,
    135875,
    135897,
    1360764,
    236279,
    236247,
    1305150,
    237545,
    135735,
    135817,
    236205,
    1100170,
    135799,
    413586,
    237537,
    136224,
    879926,
    1380372,
    7455385,
    132306
}

local function ConfigureAura(f)
    f:SetSize(16, 16)

    local cd = CreateFrame('Cooldown', '$parentEXUIPreview', f, 'CooldownFrameTemplate')
    cd:SetAllPoints()
    f.Cooldown = cd

    local icon = f:CreateTexture(nil, 'BORDER')
    icon:SetAllPoints()
    f.Icon = icon

    icon:SetTexture(icons[math.random(1, #icons)])

    local countFrame = CreateFrame('Frame', nil, f)
    countFrame:SetAllPoints(f)
    countFrame:SetFrameLevel(cd:GetFrameLevel() + 1)

    local count = countFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
    count:SetPoint('BOTTOMRIGHT', countFrame, 'BOTTOMRIGHT', -1, 0)
    if (math.random(1, 2) == 1) then
        count:SetText('1')
    else
        count:SetText('')
    end
    f.Count = count

    f:SetScript('OnShow', function(self)
        self.Cooldown:SetCooldown(GetTime(), math.random(10, 60))
    end)

    f.isConfigured = true
end

previewUtil.GetFakeAuras = function(self, parent, num)
    local frames = {}

    for i = 1, num do
        local f = self.auraPool:Acquire()
        if (not f.isConfigured) then
            ConfigureAura(f)
        end
        f:SetParent(parent)
        f:SetFrameLevel(parent:GetFrameLevel() + 1)
        f:Show()
        table.insert(frames, f)
    end

    return frames
end

previewUtil.DestroyAura = function(self, aura)
    self.auraPool:Release(aura)
end
