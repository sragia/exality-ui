---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

local LSM = LibStub('LibSharedMedia-3.0')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

-- Preview panel docked to the side of the options window while the Styles page is open.
---@class EXUIOptionsStylePreview
local stylePreview = EXUI:GetModule('options-style-preview')

stylePreview.host = nil
stylePreview.styleID = nil

local WIDTH = 260
local HEIGHT = 330
local BORDER_COLOR = { 0.85, 0.85, 0.85, 1 }
local GLOW_COLOR = { r = 1, g = 0.82, b = 0.2, a = 1 }
local PREVIEW_ICON = 136081

local function CreateLabel(parent, sample, text)
    local label = parent:CreateFontString(nil, 'OVERLAY')
    label:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
    label:SetPoint('TOP', sample, 'BOTTOM', 0, -18)
    label:SetText(text)
    label:SetTextColor(unpack(EXFrames.Theme.textMuted))
    return label
end

-- A masked sample: mask + border sized to its frame, the shape helpers do the rest.
local function CreateSample(parent, width, height)
    local sample = CreateFrame('Frame', nil, parent)
    sample:SetSize(width, height)

    local mask = sample:CreateMaskTexture()
    mask:SetAllPoints()
    local border = sample:CreateTexture(nil, 'OVERLAY', nil, 1)
    border:SetAllPoints()
    border:SetVertexColor(unpack(BORDER_COLOR))

    sample.state = { Mask = mask, Border = border, masked = {} }
    return sample
end

local function CreateBar(sample, value)
    local bar = CreateFrame('StatusBar', nil, sample)
    bar:SetAllPoints()
    bar:SetStatusBarTexture(LSM:Fetch('statusbar', 'ExalityUI Status Bar'))
    bar:SetStatusBarColor(0.8, 0.2, 0.2, 1)
    bar:SetMinMaxValues(0, 1)
    bar:SetValue(value)
    local bg = bar:CreateTexture(nil, 'BACKGROUND')
    bg:SetAllPoints()
    bg:SetColorTexture(0.12, 0.12, 0.12, 1)
    bar.bg = bg
    sample.bar = bar
    sample.state.Border:SetParent(bar)
    return bar
end

stylePreview.CreateHost = function(self, window)
    local host = CreateFrame('Frame', nil, UIParent)
    host:SetSize(WIDTH, HEIGHT)
    host:SetPoint('TOPLEFT', window, 'TOPRIGHT', 8, 0)
    host:SetFrameStrata(window:GetFrameStrata())

    local background = EXFrames:GetFrame('panel-frame'):Create()
    background:SetParent(host)
    background:SetFrameStrata(host:GetFrameStrata())
    background:SetAllPoints()
    background:SetFrameLevel(host:GetFrameLevel())
    background:SetSubtleChrome()

    -- Everything sits on its own layer so the panel stays behind it.
    local content = CreateFrame('Frame', nil, host)
    content:SetAllPoints()
    content:SetFrameLevel(background:GetFrameLevel() + 2)

    local title = content:CreateFontString(nil, 'OVERLAY')
    title:SetFont(EXFrames.assets.font.default(), 12, 'OUTLINE')
    title:SetPoint('TOP', 0, -10)
    title:SetText('Preview')

    host.Frame = CreateSample(content, 200, 40)
    CreateBar(host.Frame, 0.7)
    host.Frame:SetPoint('TOP', 0, -50)
    CreateLabel(content, host.Frame, 'Unit Frame')

    host.Icon = CreateSample(content, 40, 40)
    host.Icon.state.isIcon = true
    local icon = host.Icon:CreateTexture(nil, 'ARTWORK')
    icon:SetAllPoints()
    icon:SetTexture(PREVIEW_ICON)
    icon:SetTexCoord(EXUI.utils.getTexCoords(1, 1, 10))
    host.Icon.icon = icon
    host.Icon:SetPoint('TOP', host.Frame, 'BOTTOM', 0, -50)
    CreateLabel(content, host.Icon, 'Icon')

    host.Plate = CreateSample(content, 200, 24)
    CreateBar(host.Plate, 0.45)
    host.Plate:SetPoint('TOP', host.Icon, 'BOTTOM', 0, -60)
    CreateLabel(content, host.Plate, 'Targeted Nameplate')

    local hint = content:CreateFontString(nil, 'OVERLAY')
    hint:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
    hint:SetPoint('BOTTOMLEFT', 10, 8)
    hint:SetPoint('BOTTOMRIGHT', -10, 8)
    hint:SetJustifyH('CENTER')
    hint:SetText('Blank or square samples usually mean a wrong file name, or new files that need a game restart.')
    hint:SetTextColor(unpack(EXFrames.Theme.textMuted))

    return host
end

stylePreview.Refresh = function(self)
    local host = self.host
    if not host or not host:IsShown() then
        return
    end
    local shape = EXUI:GetModule('uf-element-shape')
    local styleID = self.styleID

    for _, sample in ipairs({ host.Frame, host.Icon, host.Plate }) do
        local enabled = shape:SelectStyle(sample.state, styleID)
        if sample.bar then
            shape:SetBarMasked(sample.state, sample.bar, enabled)
        end
        shape:SetMasked(sample.state, sample.icon, enabled)
        sample.state.Border:SetShown(enabled)
    end

    EXUI:GetModule('np-element-target-highlight'):ApplyGlow(host.Plate, host.Plate, styleID, GLOW_COLOR)
end

stylePreview.Show = function(self, styleID)
    local window = optionsMain.window
    if not window then
        return
    end
    if not self.host then
        self.host = self:CreateHost(window)
        window:HookScript('OnHide', function()
            stylePreview:Hide()
        end)
    end
    self.styleID = styleID
    self.host:Show()
    self:Refresh()
end

stylePreview.Hide = function(self)
    if self.host then
        self.host:Hide()
    end
end

stylePreview.Init = function(self)
    optionsController:Observe('selectedModule', function(name)
        if name ~= 'Styles' then
            stylePreview:Hide()
        end
    end)
    EXUI:GetModule('styles'):RegisterCallback(function()
        stylePreview:Refresh()
    end)
end
