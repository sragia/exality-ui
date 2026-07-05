---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIData
local data = EXUI:GetModule('data')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsEditor
local editor = EXUI:GetModule('editor')

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

local LSM = LibStub('LibSharedMedia-3.0', true)
local ldbi = LibStub('LibDBIcon-1.0')

-----------------------------------

---@class EXUIMinimapModule
local minimap = EXUI:GetModule('minimap')

minimap.useTabs = true
minimap.useSplitView = true
minimap.splitViewTabID = 'buttons'

minimap.enabled = false
minimap.drawerOpen = false
minimap.clockTicker = nil
minimap.hybridHooked = false
minimap.ldbCallbackRegistered = false
minimap.ldbDragHooked = {}
minimap.repositioningMissions = false
minimap.configuringAddonCompartment = false

local MASK_TEXTURE = [[Interface\BUTTONS\WHITE8X8]]
local SQUARE_SHAPE = 'SQUARE'
local MINIMAP_BUTTON_ICON_SIZE = 20
local MINIMAP_MAIL_ICON_SIZE = 16
local MINIMAP_DIFFICULTY_FONT_SIZE = 11
local MINIMAP_DIFFICULTY_TEXT_PAD_X = 6
local MINIMAP_ICON_BG_PAD = 4
local MINIMAP_BUTTON_BG_SLICE = 6
local INSTANCE_DIFFICULTY_EVENTS = {
    'PLAYER_DIFFICULTY_CHANGED',
    'INSTANCE_GROUP_SIZE_CHANGED',
    'UPDATE_INSTANCE_INFO',
    'GROUP_ROSTER_UPDATE',
}
local MISSIONS_CORNER_OFFSET = 12
local ORBIT_BUTTON_FRAME_LEVEL = 10
local MINIMAP_BORDER_FRAME_LEVEL = 0
local MINIMAP_OVERLAY_FRAME_STRATA = 'MEDIUM'
local MINIMAP_OVERLAY_FRAME_LEVEL = 30
local LIST_MENU_ROW_HEIGHT = 24
local LIST_MENU_PADDING = 6
local LIST_MENU_ROW_GAP = 2
local LIST_MENU_MIN_WIDTH = 180
local LIST_MENU_MAX_WIDTH = 320
local LIST_MENU_ICON_COLUMN = 28
local LIST_MENU_TEXT_PADDING = 12
local LIST_MENU_GAP = 4
local MINIMAP_CHROME_TEXTURES = {
    [136430] = true,
    [136467] = true,
    ["Interface\\Minimap\\MiniMap-TrackingBorder"] = true,
    ["Interface\\Minimap\\UI-Minimap-Background"] = true,
}

local VISIBILITY_OPTIONS = {
    always = 'Always',
    hover = 'On Hover',
    hidden = 'Hidden',
}

local PLACEMENT_OPTIONS = {
    outside = 'Outside',
    drawer = 'In Drawer',
    hidden = 'Hidden',
}

local BLIZZ_BUTTON_LABELS = {
    missions = 'Expansion Button',
    difficulty = 'Instance Difficulty',
    calendar = 'Calendar',
    mail = 'Mail',
}

local BLIZZ_OPTION_DROPDOWN_WIDTH = 70
local BLIZZ_OPTION_ANGLE_WIDTH = 30

local DEFAULT_BLIZZ_ANGLES = {
    missions = 190,
    difficulty = 150,
    calendar = 35,
    mail = 20,
}

local ZONE_PVP_COLORS = {
    sanctuary = { 0.41, 0.8, 0.94, 1 },
    arena = { 1.0, 0.1, 0.1, 1 },
    friendly = { 0.1, 1.0, 0.1, 1 },
    hostile = { 1.0, 0.1, 0.1, 1 },
    contested = { 1.0, 0.7, 0.0, 1 },
    normal = { 1, 0.82, 0, 1 },
}

local function GetBlizzButton(key)
    if (key == 'missions') then
        return ExpansionLandingPageMinimapButton or GarrisonLandingPageMinimapButton
    end
    if (key == 'difficulty') then return MinimapCluster.InstanceDifficulty end
    if (key == 'calendar') then return GameTimeFrame end
    if (key == 'mail') then return MinimapCluster.IndicatorFrame and MinimapCluster.IndicatorFrame.MailFrame end
    if (key == 'tracking') then
        if (MinimapCluster.Tracking and MinimapCluster.Tracking.Button) then
            return MinimapCluster.Tracking.Button
        end
        return MinimapCluster.Tracking
    end
end

local MINIMAP_SHAPES = {
    ['ROUND'] = { true, true, true, true },
    ['SQUARE'] = { false, false, false, false },
    ['CORNER-TOPLEFT'] = { false, false, false, true },
    ['CORNER-TOPRIGHT'] = { false, false, true, false },
    ['CORNER-BOTTOMLEFT'] = { false, true, false, false },
    ['CORNER-BOTTOMRIGHT'] = { true, false, false, false },
    ['SIDE-LEFT'] = { false, true, false, true },
    ['SIDE-RIGHT'] = { true, false, true, false },
    ['SIDE-TOP'] = { false, false, true, true },
    ['SIDE-BOTTOM'] = { true, true, false, false },
    ['TRICORNER-TOPLEFT'] = { false, true, true, true },
    ['TRICORNER-TOPRIGHT'] = { true, false, true, true },
    ['TRICORNER-BOTTOMLEFT'] = { true, true, false, true },
    ['TRICORNER-BOTTOMRIGHT'] = { true, true, true, false },
}

local function GetMinimapBorderOrbitOffset()
    if (not minimap.enabled) then return 0 end
    local borderSize = minimap.Data:GetValue('borderSize') or 0
    if (borderSize <= 0) then return 0 end
    return EXUI:ScalePixels(borderSize, Minimap)
end

local function NudgeOrbitButtonOutward(button)
    local offset = GetMinimapBorderOrbitOffset()
    if (offset <= 0 or not button) then return end

    local mx, my = Minimap:GetCenter()
    local bx, by = button:GetCenter()
    if (not mx or not bx) then return end

    local dx, dy = bx - mx, by - my
    local dist = math.sqrt((dx * dx) + (dy * dy))
    if (dist <= 0) then return end

    local scale = (dist + offset) / dist
    button:ClearAllPoints()
    button:SetPoint('CENTER', Minimap, 'CENTER', dx * scale, dy * scale)
end

local function SetButtonToPosition(button, position)
    if (not button) then return end
    if (ldbi.SetButtonToPosition) then
        ldbi:SetButtonToPosition(button, position)
        NudgeOrbitButtonOutward(button)
        return
    end

    local angle = math.rad(position or 225)
    local x, y = math.cos(angle), math.sin(angle)
    local q = 1
    if (x < 0) then q = q + 1 end
    if (y > 0) then q = q + 2 end
    local minimapShape = GetMinimapShape and GetMinimapShape() or 'ROUND'
    local quadTable = MINIMAP_SHAPES[minimapShape]
    local radius = ldbi.radius or 5
    local borderOffset = GetMinimapBorderOrbitOffset()
    local w = (Minimap:GetWidth() / 2) + radius + borderOffset
    local h = (Minimap:GetHeight() / 2) + radius + borderOffset
    if (quadTable and quadTable[q]) then
        x, y = x * w, y * h
    else
        local diagRadiusW = math.sqrt(2 * (w ^ 2)) - 10
        local diagRadiusH = math.sqrt(2 * (h ^ 2)) - 10
        x = math.max(-w, math.min(x * diagRadiusW, w))
        y = math.max(-h, math.min(y * diagRadiusH, h))
    end
    button:ClearAllPoints()
    button:SetPoint('CENTER', Minimap, 'CENTER', x, y)
end

local function GetButtonAngle(btn)
    if (not btn) then return nil end
    local pos = btn.db and btn.db.minimapPos or btn.minimapPos
    if (pos) then
        return math.floor(pos + 0.5) % 360
    end
    local mx, my = Minimap:GetCenter()
    local bx, by = btn:GetCenter()
    if (not mx or not bx) then return nil end
    return math.floor(math.deg(math.atan2(by - my, bx - mx)) + 0.5) % 360
end

local function GetOrbitButtonParent()
    return minimap.orbitButtonLayer or Minimap
end

local function PrepareOrbitButton(btn)
    if (not btn) then return end
    local orbitParent = GetOrbitButtonParent()
    if (btn:GetParent() ~= orbitParent) then
        btn:SetParent(orbitParent)
    end
    if (btn.SetFixedFrameStrata) then
        btn:SetFixedFrameStrata(true)
    end
    if (btn.SetFrameStrata) then
        btn:SetFrameStrata('LOW')
    end
    if (btn.SetFixedFrameLevel) then
        btn:SetFixedFrameLevel(true)
    end
    btn:SetFrameLevel(1)
    if (btn.EnableMouse) then
        btn:EnableMouse(true)
    end
    if (btn.RegisterForClicks) then
        btn:RegisterForClicks('AnyUp')
    end
end

local function PrepareBlizzOrbitButton(btn)
    PrepareOrbitButton(btn)
    btn:SetFrameLevel(2)
end

local function GetMinimapCursorOffset(frame)
    local scale = frame:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x, y = x / scale, y / scale
    local cx, cy = frame:GetCenter()
    return x - cx, y - cy
end

local function IsInsideMinimap(frame)
    local x, y = GetMinimapCursorOffset(frame)
    local shape = GetMinimapShape and GetMinimapShape() or 'ROUND'
    if (shape == SQUARE_SHAPE) then
        local halfW, halfH = frame:GetWidth() / 2, frame:GetHeight() / 2
        return math.abs(x) <= halfW and math.abs(y) <= halfH
    end
    return (x * x + y * y) <= ((frame:GetWidth() / 2) ^ 2)
end

local function IsMinimapChromeTexture(tex)
    if (not tex) then return false end
    return MINIMAP_CHROME_TEXTURES[tex] or MINIMAP_CHROME_TEXTURES[tostring(tex)]
end

local function ForEachButtonTexture(btn, fn)
    local function scan(frame, depth)
        if (not frame or depth > 2) then return end
        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if (region and region:IsObjectType('Texture')) then
                fn(region)
            end
        end
        for i = 1, frame:GetNumChildren() do
            scan(select(i, frame:GetChildren()), depth + 1)
        end
    end
    scan(btn, 0)
end

local function IsExuiMailTexture(tex, btn)
    return tex == btn.exuiBg or tex == btn.exuiIcon
end

local function SuppressMailChromeTexture(tex, btn)
    if (not tex or not tex.IsObjectType or not tex:IsObjectType('Texture')) then return end
    if (IsExuiMailTexture(tex, btn)) then return end
    tex:Hide()
    tex:SetAlpha(0)
    if (tex._exuiMailChromeHooked) then return end
    tex._exuiMailChromeHooked = true
    hooksecurefunc(tex, 'Show', function(region)
        if (minimap.enabled and not IsExuiMailTexture(region, btn)) then
            region:Hide()
            region:SetAlpha(0)
        end
    end)
    if (tex.SetTexture) then
        hooksecurefunc(tex, 'SetTexture', function(region)
            if (minimap.enabled and not IsExuiMailTexture(region, btn)) then
                region:Hide()
                region:SetAlpha(0)
            end
        end)
    end
    if (tex.SetAtlas) then
        hooksecurefunc(tex, 'SetAtlas', function(region)
            if (minimap.enabled and not IsExuiMailTexture(region, btn)) then
                region:Hide()
                region:SetAlpha(0)
            end
        end)
    end
end

local function HideBlizzMailChrome(btn)
    if (not btn) then return end

    local namedIcons = {
        MiniMapMailIcon,
        btn.MailIcon,
        btn.Icon,
        btn.icon,
    }
    for _, icon in ipairs(namedIcons) do
        SuppressMailChromeTexture(icon, btn)
    end

    local function scan(frame, depth)
        if (not frame or depth > 6) then return end
        for i = 1, frame:GetNumRegions() do
            local region = select(i, frame:GetRegions())
            if (region and region:IsObjectType('Texture')) then
                SuppressMailChromeTexture(region, btn)
            end
        end
        for i = 1, frame:GetNumChildren() do
            scan(select(i, frame:GetChildren()), depth + 1)
        end
    end
    scan(btn, 0)
end

local function HideBlizzDifficultyChrome(btn)
    if (not btn) then return end

    local contentModes = btn.ContentModes or { btn.Default, btn.Guild, btn.ChallengeMode }
    for _, frame in ipairs(contentModes) do
        if (frame) then
            frame:Hide()
            if (not frame._exuiDifficultyChromeHooked) then
                frame._exuiDifficultyChromeHooked = true
                hooksecurefunc(frame, 'Show', function(contentFrame)
                    if (minimap.enabled) then
                        contentFrame:Hide()
                    end
                end)
            end
        end
    end
end

local function GetMinimapButtonBgTexture()
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.textures.ui.buttonBg) then
        return EXUI.EXFrames.assets.textures.ui.buttonBg
    end
    return EXUI.const.textures.frame.inputs.buttonBg
end

local function ApplyMinimapButtonBgTexture(tex, width, height)
    tex:SetTexture(GetMinimapButtonBgTexture())
    local slice = EXUI:ScalePixel(MINIMAP_BUTTON_BG_SLICE)
    if (tex.SetTextureSliceMargins) then
        tex:SetTextureSliceMargins(slice, slice, slice, slice)
        tex:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    end
    tex:SetSize(width, height or width)
end

local function GetFontDropdownOptions()
    local options = {}
    if (not LSM) then return options end
    for _, font in ipairs(LSM:List('font')) do
        options[font] = font
    end
    return options
end

local function PackColor(color)
    return { r = color.r or color[1], g = color.g or color[2], b = color.b or color[3], a = color.a or color[4] or 1 }
end

local function UnpackColor(color)
    if (type(color) == 'table') then
        return color.r or color[1] or 1, color.g or color[2] or 1, color.b or color[3] or 1, color.a or color[4] or 1
    end
    return 1, 1, 1, 1
end

minimap.FindButtonIcon = function(self, btn)
    if (btn.icon) then return btn.icon end
    if (btn.Icon) then return btn.Icon end

    local icon
    ForEachButtonTexture(btn, function(tex)
        if (tex == btn.exuiBg or IsMinimapChromeTexture(tex:GetTexture())) then return end
        local layer = tex.GetDrawLayer and tex:GetDrawLayer() or 'ARTWORK'
        if (layer == 'ARTWORK' or layer == 'OVERLAY' or not icon) then
            icon = tex
        end
    end)
    return icon
end

minimap.IsLdbMinimapButton = function(self, btn)
    if (not btn) then return false end
    for _, name in ipairs(ldbi:GetButtonList()) do
        if (ldbi:GetMinimapButton(name) == btn) then
            return true
        end
    end
    return false
end

local function UnpackThemeColor(color)
    if (not color) then return 1, 1, 1, 1 end
    return color[1], color[2], color[3], color[4] or 1
end

minimap.GetMinimapButtonBgColor = function(self)
    return UnpackThemeColor(EXUI.const.theme.minimap.buttonBg)
end

minimap.GetButtonScale = function(self)
    return self.Data:GetValue('buttonScale') or 1
end

minimap.GetButtonAppearanceColor = function(self)
    local color = self.Data:GetValue('buttonBgColor')
    if (color) then
        return UnpackColor(color)
    end
    return self:GetMinimapButtonBgColor()
end

minimap.IsButtonBackgroundEnabled = function(self)
    return self.Data:GetValue('buttonBgEnable') ~= false
end

minimap.GetScaledMinimapIconSize = function(self, baseSize)
    return EXUI:ScalePixel(baseSize * self:GetButtonScale())
end

minimap.ApplyButtonBackground = function(self, btn, bgTex, bgWidth, bgHeight)
    if (not btn or not bgTex) then return end

    if (self:IsButtonBackgroundEnabled()) then
        local r, g, b, a = self:GetButtonAppearanceColor()
        self:ApplyMinimapButtonBackground(bgTex, bgWidth, r, g, b, a, bgHeight)
        bgTex:Show()
        bgTex:SetAlpha(1)
    else
        bgTex:Hide()
    end
end

minimap.ApplyMinimapButtonBackground = function(self, tex, width, r, g, b, a, height)
    ApplyMinimapButtonBgTexture(tex, width, height)
    tex:SetVertexColor(r, g, b, a)
end

minimap.StyleMinimapButton = function(self, btn)
    if (not btn or not self:IsLdbMinimapButton(btn)) then return end

    if (btn.overlay) then btn.overlay:Hide() end

    btn.exuiIcon = self:FindButtonIcon(btn)

    ForEachButtonTexture(btn, function(tex)
        if (tex == btn.exuiBg or tex == btn.exuiIcon) then return end
        if (IsMinimapChromeTexture(tex:GetTexture())) then
            tex:Hide()
        end
    end)

    if (not btn.exuiIcon) then return end

    local icon = btn.exuiIcon
    local iconSize = self:GetScaledMinimapIconSize(MINIMAP_BUTTON_ICON_SIZE)
    local bgPad = self:GetScaledMinimapIconSize(MINIMAP_ICON_BG_PAD)
    local bgSize = iconSize + bgPad * 2

    if (not btn.exuiBg) then
        local bg = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
        btn.exuiBg = bg
    end
    btn.exuiBg:ClearAllPoints()
    btn.exuiBg:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    self:ApplyButtonBackground(btn, btn.exuiBg, bgSize)

    icon:Show()
    icon:ClearAllPoints()
    icon:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    icon:SetSize(iconSize, iconSize)
    if (icon.SetMaskTexture) then
        icon:SetMaskTexture(EXUI.const.textures.frame.iconMask)
    end

    ForEachButtonTexture(btn, function(tex)
        if (tex ~= btn.exuiBg and tex ~= icon) then
            tex:Hide()
        end
    end)

    btn._exuiStyled = true
end

minimap.StyleBlizzMailButton = function(self, btn)
    if (not btn) then return end

    PrepareBlizzOrbitButton(btn)

    HideBlizzMailChrome(btn)

    local iconSize = self:GetScaledMinimapIconSize(MINIMAP_MAIL_ICON_SIZE)
    local bgPad = self:GetScaledMinimapIconSize(MINIMAP_ICON_BG_PAD)
    local bgSize = self:GetScaledMinimapIconSize(MINIMAP_BUTTON_ICON_SIZE) + bgPad * 2

    if (not btn.exuiBg) then
        btn.exuiBg = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
    end
    btn.exuiBg:ClearAllPoints()
    btn.exuiBg:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    self:ApplyButtonBackground(btn, btn.exuiBg, bgSize)

    if (not btn.exuiIcon) then
        btn.exuiIcon = btn:CreateTexture(nil, 'OVERLAY', nil, 7)
    end
    btn.exuiIcon:ClearAllPoints()
    btn.exuiIcon:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    btn.exuiIcon:SetSize(iconSize, iconSize)
    btn.exuiIcon:SetTexture(EXUI.const.textures.minimap.mail)
    btn.exuiIcon:SetVertexColor(1, 1, 1, 1)
    if (btn.exuiIcon.SetMaskTexture) then
        btn.exuiIcon:SetMaskTexture(EXUI.const.textures.frame.iconMask)
    end
    btn.exuiIcon:Show()
    btn.exuiIcon:SetAlpha(1)

    local frameSize = self:IsButtonBackgroundEnabled() and bgSize or iconSize
    EXUI:SetSize(btn, frameSize, frameSize)
    PrepareBlizzOrbitButton(btn)
    HideBlizzMailChrome(btn)
end

minimap.IsInActiveDelve = function(self)
    if (not C_DelvesUI or not C_DelvesUI.HasActiveDelve) then return false end
    local _, _, _, mapID = UnitPosition('player')
    return mapID and C_DelvesUI.HasActiveDelve(mapID)
end

minimap.GetInstanceDifficultyLabel = function(self)
    if (C_GameRules and C_GameRules.IsGameRuleActive and Enum and Enum.GameRule
        and C_GameRules.IsGameRuleActive(Enum.GameRule.InstanceDifficultyBannerDisabled)) then
        return nil
    end

    local _, instanceType, difficulty, _, _, _, _, _, instanceGroupSize, _, hasWorldTier = GetInstanceInfo()
    if (instanceType == 'interior' or instanceType == 'neighborhood') then
        return nil
    end

    local _, _, isHeroic, isChallengeMode, displayHeroic, displayMythic = GetDifficultyInfo(difficulty)
    local isLFR = select(8, GetDifficultyInfo(difficulty))
    local inDelve = self:IsInActiveDelve()
    local showBanner = false

    if (isChallengeMode) then
        showBanner = true
    elseif (hasWorldTier and C_DelvesUI and C_DelvesUI.GetWorldTierDifficultyForActivePlayer and Enum
        and Enum.WorldTierDifficulty) then
        local worldTier = C_DelvesUI.GetWorldTierDifficultyForActivePlayer()
        showBanner = worldTier ~= Enum.WorldTierDifficulty.Normal
    elseif (instanceType ~= 'none') then
        showBanner = true
    end

    if (not showBanner) then return nil end

    if (isChallengeMode) then
        if (C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo) then
            local level = C_ChallengeMode.GetActiveKeystoneInfo()
            if (level and level > 0) then
                return 'M+' .. level
            end
        end
        return 'M+'
    end

    local prefix
    if (hasWorldTier and C_DelvesUI and C_DelvesUI.GetWorldTierDifficultyForActivePlayer and Enum
        and Enum.WorldTierDifficulty) then
        local worldTier = C_DelvesUI.GetWorldTierDifficultyForActivePlayer()
        if (worldTier == Enum.WorldTierDifficulty.Heroic) then
            prefix = 'HC'
        elseif (worldTier == Enum.WorldTierDifficulty.Mythic) then
            prefix = 'M'
        else
            return nil
        end
    elseif (isLFR) then
        prefix = 'LFR'
    elseif (displayMythic) then
        prefix = 'M'
    elseif (isHeroic or displayHeroic) then
        prefix = 'HC'
    else
        prefix = 'N'
    end

    if (instanceGroupSize and instanceGroupSize > 0 and not inDelve) then
        return prefix .. instanceGroupSize
    end
    return prefix
end

minimap.GetInstanceDifficultyBgColor = function(self, label)
    local quality
    if (label:sub(1, 3) == 'LFR') then
        quality = 1 -- common
    elseif (label:sub(1, 2) == 'HC') then
        quality = 4 -- epic
    elseif (label:sub(1, 1) == 'M') then
        quality = 5 -- legendary
    elseif (label:sub(1, 1) == 'N') then
        quality = 3 -- rare
    else
        quality = 3
    end

    local r, g, b = 1, 1, 1
    if (C_Item and C_Item.GetItemQualityColor) then
        r, g, b = C_Item.GetItemQualityColor(quality)
    elseif (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality]) then
        local info = ITEM_QUALITY_COLORS[quality]
        if (info.color and info.color.GetRGB) then
            r, g, b = info.color:GetRGB()
        else
            r, g, b = info.r or 1, info.g or 1, info.b or 1
        end
    end

    local _, _, _, a = self:GetButtonAppearanceColor()
    return r, g, b, a
end

minimap.GetInstanceDifficultyTooltipLines = function(self)
    local _, instanceType, difficulty, _, maxPlayers, _, _, _, instanceGroupSize, lfgID, hasWorldTier = GetInstanceInfo()
    if (instanceType == 'none' or instanceType == 'interior' or instanceType == 'neighborhood') then
        return nil
    end

    local isLFR = select(8, GetDifficultyInfo(difficulty))
    local difficultyName

    if (hasWorldTier and DifficultyUtil and DifficultyUtil.GetWorldTierDifficultyName) then
        difficultyName = DifficultyUtil.GetWorldTierDifficultyName()
    elseif (DifficultyUtil and DifficultyUtil.GetDifficultyName) then
        difficultyName = DifficultyUtil.GetDifficultyName(difficulty)
    else
        difficultyName = select(1, GetDifficultyInfo(difficulty))
    end

    if (not difficultyName or difficultyName == '') then
        return nil
    end

    local title = DUNGEON_DIFFICULTY_BANNER_TOOLTIP and DUNGEON_DIFFICULTY_BANNER_TOOLTIP:format(difficultyName)
        or difficultyName
    local lines = {}

    if (isLFR and lfgID and RAID_FINDER) then
        table.insert(lines, RAID_FINDER)
    end

    if (maxPlayers and maxPlayers > 0) then
        local countText = DUNGEON_DIFFICULTY_BANNER_TOOLTIP_PLAYER_COUNT
            and DUNGEON_DIFFICULTY_BANNER_TOOLTIP_PLAYER_COUNT:format(instanceGroupSize or 0, maxPlayers)
            or string.format('%d / %d', instanceGroupSize or 0, maxPlayers)
        table.insert(lines, countText)
    end

    local diffBtn = GetBlizzButton('difficulty')
    if (diffBtn and diffBtn.IsGuildGroup and diffBtn:IsGuildGroup() and InGuildParty) then
        local _, numGuildPresent, numGuildRequired, xpMultiplier = InGuildParty()
        if (GUILD_GROUP) then
            table.insert(lines, GUILD_GROUP)
        end
        if (numGuildRequired and numGuildPresent and instanceGroupSize and GUILD_ACHIEVEMENTS_ELIGIBLE) then
            local guildName = GetGuildInfo('player') or ''
            if (xpMultiplier and xpMultiplier < 1 and GUILD_ACHIEVEMENTS_ELIGIBLE_MINXP) then
                table.insert(lines, GUILD_ACHIEVEMENTS_ELIGIBLE_MINXP:format(numGuildRequired, instanceGroupSize,
                    guildName, xpMultiplier * 100))
            elseif (xpMultiplier and xpMultiplier > 1 and GUILD_ACHIEVEMENTS_ELIGIBLE_MAXXP) then
                table.insert(lines, GUILD_ACHIEVEMENTS_ELIGIBLE_MAXXP:format(guildName, xpMultiplier * 100))
            else
                local required = numGuildRequired
                if (instanceType == 'party' and maxPlayers == 5) then
                    required = 4
                end
                table.insert(lines, GUILD_ACHIEVEMENTS_ELIGIBLE:format(required, instanceGroupSize, guildName))
            end
        end
    end

    return title, lines
end

minimap.ShowInstanceDifficultyTooltip = function(self, anchor)
    local title, lines = self:GetInstanceDifficultyTooltipLines()
    if (not title) then return end

    GameTooltip:SetOwner(anchor, 'ANCHOR_BOTTOMLEFT', 8, 8)
    if (GameTooltip_SetTitle) then
        GameTooltip_SetTitle(GameTooltip, title)
    else
        GameTooltip:SetText(title, 1, 1, 1)
    end

    for _, line in ipairs(lines or {}) do
        if (GameTooltip_AddColoredLine and line == GUILD_GROUP) then
            GameTooltip_AddColoredLine(GameTooltip, line, GREEN_FONT_COLOR)
        elseif (GameTooltip_AddNormalLine) then
            GameTooltip_AddNormalLine(GameTooltip, line, true)
        else
            GameTooltip:AddLine(line, 1, 1, 1, true)
        end
    end

    GameTooltip:Show()
end

minimap.SetupInstanceDifficultyTooltip = function(self, btn)
    if (not btn or btn._exuiDifficultyTooltipSetup) then return end
    btn._exuiDifficultyTooltipSetup = true
    btn:SetScript('OnEnter', function(frame)
        minimap:ShowInstanceDifficultyTooltip(frame)
    end)
    btn:SetScript('OnLeave', function()
        GameTooltip:Hide()
    end)
end

minimap.StyleBlizzDifficultyButton = function(self, btn, label)
    if (not btn) then return end

    label = label or self:GetInstanceDifficultyLabel()
    PrepareBlizzOrbitButton(btn)
    HideBlizzDifficultyChrome(btn)
    self:SetupInstanceDifficultyTooltip(btn)

    if (not label) then
        btn:Hide()
        return
    end

    local textPadX = self:GetScaledMinimapIconSize(MINIMAP_DIFFICULTY_TEXT_PAD_X)
    local minHeight = self:GetScaledMinimapIconSize(MINIMAP_BUTTON_ICON_SIZE)
    local bgPad = self:GetScaledMinimapIconSize(MINIMAP_ICON_BG_PAD)
    local fontSize = self:GetScaledMinimapIconSize(MINIMAP_DIFFICULTY_FONT_SIZE)

    if (not btn.exuiText) then
        btn.exuiText = btn:CreateFontString(nil, 'OVERLAY', nil, 7)
        btn.exuiText:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    end

    local fontPath = [[Interface/Addons/ExalityUI/Assets/Fonts/DMSans.ttf]]
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.font) then
        fontPath = EXUI.EXFrames.assets.font.default()
    end
    btn.exuiText:SetFont(fontPath, fontSize, 'OUTLINE')
    btn.exuiText:SetTextColor(1, 1, 1, 1)
    btn.exuiText:SetText(label)
    btn.exuiText:Show()

    local textWidth = btn.exuiText:GetStringWidth() or 0
    local bgWidth = math.max(textWidth + textPadX * 2, minHeight + bgPad * 2)
    local bgHeight = minHeight + bgPad * 2

    if (not btn.exuiBg) then
        btn.exuiBg = btn:CreateTexture(nil, 'BACKGROUND', nil, -1)
    end
    btn.exuiBg:ClearAllPoints()
    btn.exuiBg:SetPoint('CENTER', btn, 'CENTER', 0, 0)
    if (self:IsButtonBackgroundEnabled()) then
        local r, g, b, a = self:GetInstanceDifficultyBgColor(label)
        self:ApplyMinimapButtonBackground(btn.exuiBg, bgWidth, r, g, b, a, bgHeight)
        btn.exuiBg:Show()
        btn.exuiBg:SetAlpha(1)
    else
        btn.exuiBg:Hide()
    end

    local frameWidth = self:IsButtonBackgroundEnabled() and bgWidth or math.max(textWidth, minHeight)
    local frameHeight = self:IsButtonBackgroundEnabled() and bgHeight or minHeight
    EXUI:SetSize(btn, frameWidth, frameHeight)
    btn:Show()
    PrepareBlizzOrbitButton(btn)
    HideBlizzDifficultyChrome(btn)
end

minimap.Data = data:GetControlsForKey('minimap')

minimap.GetDefaults = function(self)
    return {
        enable = false,
        size = 200,
        borderSize = 1,
        borderColor = { r = 38 / 255, g = 41 / 255, b = 34 / 255, a = 1 },
        anchorPoint = 'TOPRIGHT',
        relativeAnchor = 'TOPRIGHT',
        xOffset = -10,
        yOffset = -10,
        zoneEnable = true,
        zoneVisibility = 'always',
        zoneAnchor = 'BOTTOM',
        zoneRelativeAnchor = 'TOP',
        zoneXOff = 0,
        zoneYOff = 3,
        zoneFont = 'DMSans',
        zoneFontSize = 12,
        zoneFontFlag = 'OUTLINE',
        zoneBgEnable = true,
        zoneBgColor = { r = 0, g = 0, b = 0, a = 0.5 },
        clockEnable = true,
        clockVisibility = 'always',
        clockAnchor = 'TOPLEFT',
        clockRelativeAnchor = 'BOTTOMLEFT',
        clockXOff = 0,
        clockYOff = -4,
        clockFont = 'DMSans',
        clockFontSize = 12,
        clockFontFlag = 'OUTLINE',
        clockBgEnable = true,
        clockBgColor = { r = 0, g = 0, b = 0, a = 0.65 },
        drawerEnable = true,
        drawerAnchor = 'BOTTOM',
        drawerRelativeAnchor = 'TOP',
        drawerXOff = 0,
        drawerYOff = -4,
        addonCompartmentShow = false,
        addonCompartmentAnchor = 'TOPRIGHT',
        addonCompartmentRelativeAnchor = 'TOPRIGHT',
        addonCompartmentXOff = -4,
        addonCompartmentYOff = -4,
        blizzButtons = {
            missions = 'outside',
            difficulty = 'outside',
            calendar = 'outside',
            mail = 'outside',
        },
        blizzButtonAngles = {
            missions = 190,
            difficulty = 150,
            calendar = 35,
            mail = 20,
        },
        buttonScale = 1,
        buttonBgEnable = true,
        buttonBgColor = { r = 11 / 255, g = 18 / 255, b = 13 / 255, a = 1 },
        ldbButtons = {},
    }
end

minimap.Init = function(self)
    self.Data:UpdateDefaults(self:GetDefaults())
    local db = self.Data:GetDB()
    local blizzButtons = db.blizzButtons
    if (blizzButtons and blizzButtons.addonCompartment) then
        if (blizzButtons.addonCompartment ~= 'hidden') then
            db.addonCompartmentShow = true
        end
        blizzButtons.addonCompartment = nil
        if (db.blizzButtonAngles) then
            db.blizzButtonAngles.addonCompartment = nil
        end
        if (blizzButtons.craftingOrder) then
            blizzButtons.craftingOrder = nil
            if (db.blizzButtonAngles) then
                db.blizzButtonAngles.craftingOrder = nil
            end
        end
        self.Data:SetDB(db)
    elseif (blizzButtons and blizzButtons.craftingOrder) then
        blizzButtons.craftingOrder = nil
        if (db.blizzButtonAngles) then
            db.blizzButtonAngles.craftingOrder = nil
        end
        self.Data:SetValue('blizzButtons', blizzButtons)
    end
    if (blizzButtons and blizzButtons.tracking) then
        blizzButtons.tracking = nil
        if (db.blizzButtonAngles) then
            db.blizzButtonAngles.tracking = nil
        end
        self.Data:SetValue('blizzButtons', blizzButtons)
    end
    self:SyncLdbButtons()
    optionsController:RegisterModule(self)

    if (self.Data:GetValue('enable')) then
        self:Enable()
    end
end

minimap.GetName = function(self)
    return 'Minimap'
end

minimap.GetOrder = function(self)
    return 45
end

minimap.GetTabs = function(self)
    return {
        { ID = 'general', label = 'General' },
        { ID = 'zone',    label = 'Zone Text' },
        { ID = 'clock',   label = 'Clock' },
        { ID = 'buttons', label = 'Buttons' },
    }
end

minimap.GetSplitViewItems = function(self)
    local items = {
        { ID = '__buttonGeneral__',   label = 'General' },
        { ID = '__drawer__',           label = 'Button Drawer' },
        { ID = '__addonCompartment__', label = 'Addon Compartment' },
        { ID = '__blizzard__',         label = 'Blizzard Buttons' },
    }
    local ldbButtons = self.Data:GetValue('ldbButtons') or {}
    local names = {}
    for name in pairs(ldbButtons) do
        table.insert(names, name)
    end
    table.sort(names)
    for _, name in ipairs(names) do
        table.insert(items, { ID = name, label = name })
    end
    return items
end

minimap.SyncLdbButtons = function(self)
    local ldbButtons = self.Data:GetValue('ldbButtons') or {}
    local changed = false
    for _, name in ipairs(ldbi:GetButtonList()) do
        if (not ldbButtons[name]) then
            local btn = ldbi:GetMinimapButton(name)
            ldbButtons[name] = {
                placement = 'drawer',
                angle = GetButtonAngle(btn) or 180,
            }
            changed = true
        elseif (ldbButtons[name].angle == nil) then
            local btn = ldbi:GetMinimapButton(name)
            local angle = GetButtonAngle(btn)
            if (angle) then
                ldbButtons[name].angle = angle
                changed = true
            end
        end
    end
    if (changed) then
        self.Data:SetValue('ldbButtons', ldbButtons)
    end
end

minimap.GetLdbButtonAngle = function(self, name, cfg)
    if (cfg and cfg.angle) then
        return cfg.angle
    end
    local btn = ldbi:GetMinimapButton(name)
    return GetButtonAngle(btn) or 180
end

minimap.SaveLdbButtonAngle = function(self, name)
    local ldbButtons = self.Data:GetValue('ldbButtons') or {}
    local cfg = ldbButtons[name]
    if (not cfg or cfg.placement ~= 'outside') then return end

    local btn = ldbi:GetMinimapButton(name)
    local angle = GetButtonAngle(btn)
    if (not angle) then return end

    if (cfg.angle == angle) then return end
    cfg.angle = angle
    self.Data:SetValue('ldbButtons', ldbButtons)
end

minimap.SetupLdbDragSave = function(self, name, btn)
    if (not btn or self.ldbDragHooked[name]) then return end
    self.ldbDragHooked[name] = true

    local origDragStop = btn:GetScript('OnDragStop')
    btn:SetScript('OnDragStop', function(frame, ...)
        if (origDragStop) then
            origDragStop(frame, ...)
        end
        minimap:SaveLdbButtonAngle(name)
    end)
end

minimap.ConfigureIfEnabled = function(self)
    if (self.enabled) then
        self:Configure()
    end
end

minimap.RefreshOptionsView = function(self)
    optionsFields:RefreshOptions()
end

minimap.HandleToggleChange = function(self, key, value)
    self.Data:SetValue(key, value)
    self:ConfigureIfEnabled()
    self:RefreshOptionsView()
end

minimap.GetReloadEnableField = function(self)
    return {
        type = 'toggle',
        label = 'Enable',
        name = 'enable',
        onChange = function(value)
            self.Data:SetValue('enable', value)
            self:RefreshOptionsView()
            optionsReloadDialog:ShowDialog()
        end,
        currentValue = function()
            return self.Data:GetValue('enable')
        end,
        width = 100,
    }
end

minimap.GetFontFields = function(self, prefix, onChange)
    return {
        {
            type = 'dropdown',
            label = 'Font',
            name = prefix .. 'Font',
            getOptions = GetFontDropdownOptions,
            isFontDropdown = true,
            currentValue = function()
                return self.Data:GetValue(prefix .. 'Font')
            end,
            onChange = function(value)
                self.Data:SetValue(prefix .. 'Font', value)
                onChange()
            end,
            width = 33,
        },
        {
            type = 'range',
            label = 'Font Size',
            name = prefix .. 'FontSize',
            min = 8,
            max = 32,
            step = 1,
            currentValue = function()
                return self.Data:GetValue(prefix .. 'FontSize')
            end,
            onChange = function(value)
                self.Data:SetValue(prefix .. 'FontSize', value)
                onChange()
            end,
            width = 16,
        },
        {
            type = 'dropdown',
            label = 'Font Flag',
            name = prefix .. 'FontFlag',
            getOptions = function()
                return EXUI.const.fontFlags
            end,
            currentValue = function()
                return self.Data:GetValue(prefix .. 'FontFlag')
            end,
            onChange = function(value)
                self.Data:SetValue(prefix .. 'FontFlag', value)
                onChange()
            end,
            width = 20,
        },
    }
end

minimap.GetPositionFields = function(self, prefix, onChange, splitRows)
    local anchorWidth = 23
    local offsetWidth = 16
    local fields = {
        {
            type = 'anchor-point',
            label = 'Anchor Point',
            name = prefix .. 'Anchor',
            currentValue = function()
                return self.Data:GetValue(prefix .. 'Anchor')
            end,
            onChange = function(value)
                self.Data:SetValue(prefix .. 'Anchor', value)
                onChange()
            end,
            width = anchorWidth,
        },
        {
            type = 'anchor-point',
            label = 'Relative Anchor Point',
            name = prefix .. 'RelativeAnchor',
            currentValue = function()
                return self.Data:GetValue(prefix .. 'RelativeAnchor')
            end,
            onChange = function(value)
                self.Data:SetValue(prefix .. 'RelativeAnchor', value)
                onChange()
            end,
            width = anchorWidth,
        },
    }
    if (splitRows) then
        table.insert(fields, {
            type = 'spacer',
            width = 100 - (anchorWidth * 2),
        })
    end
    table.insert(fields, {
        type = 'range',
        label = 'X Offset',
        name = prefix .. 'XOff',
        min = -500,
        max = 500,
        step = 1,
        currentValue = function()
            return self.Data:GetValue(prefix .. 'XOff')
        end,
        onChange = function(value)
            self.Data:SetValue(prefix .. 'XOff', value)
            onChange()
        end,
        width = offsetWidth,
    })
    table.insert(fields, {
        type = 'range',
        label = 'Y Offset',
        name = prefix .. 'YOff',
        min = -500,
        max = 500,
        step = 1,
        currentValue = function()
            return self.Data:GetValue(prefix .. 'YOff')
        end,
        onChange = function(value)
            self.Data:SetValue(prefix .. 'YOff', value)
            onChange()
        end,
        width = offsetWidth,
    })
    if (splitRows) then
        table.insert(fields, {
            type = 'spacer',
            width = 100 - (offsetWidth * 2),
        })
    end
    return fields
end

minimap.GetOptions = function(self, currTabID, currItemID)
    if (currTabID == 'general') then
        return {
            self:GetReloadEnableField(),
            {
                type = 'description',
                width = 100,
                label = 'Enabling or disabling the minimap module requires a UI reload.',
                depends = function() return true end,
            },
            {
                type = 'title',
                label = 'Size & Position',
                width = 100,
                depends = function() return self.Data:GetValue('enable') end,
            },
            {
                type = 'range',
                label = 'Size',
                name = 'size',
                min = 100,
                max = 400,
                step = 1,
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('size') end,
                onChange = function(value)
                    self.Data:SetValue('size', value)
                    self:ConfigureIfEnabled()
                end,
                width = 20,
            },
            {
                type = 'range',
                label = 'Border Size',
                name = 'borderSize',
                min = 0,
                max = 10,
                step = 1,
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('borderSize') end,
                onChange = function(value)
                    self.Data:SetValue('borderSize', value)
                    self:ConfigureIfEnabled()
                end,
                width = 20,
            },
            {
                type = 'color-picker',
                label = 'Border Color',
                name = 'borderColor',
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('borderColor') end,
                onChange = function(value)
                    self.Data:SetValue('borderColor', PackColor(value))
                    self:ConfigureIfEnabled()
                end,
                width = 20,
            },
            {
                type = 'spacer',
                width = 40,
                depends = function() return self.Data:GetValue('enable') end,
            },
            {
                type = 'anchor-point',
                label = 'Anchor Point',
                name = 'anchorPoint',
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('anchorPoint') end,
                onChange = function(value)
                    self.Data:SetValue('anchorPoint', value)
                    self:ConfigureIfEnabled()
                end,
                width = 23,
            },
            {
                type = 'anchor-point',
                label = 'Relative Anchor Point',
                name = 'relativeAnchor',
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('relativeAnchor') end,
                onChange = function(value)
                    self.Data:SetValue('relativeAnchor', value)
                    self:ConfigureIfEnabled()
                end,
                width = 23,
            },
            {
                type = 'range',
                label = 'X Offset',
                name = 'xOffset',
                min = -1000,
                max = 1000,
                step = 1,
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('xOffset') end,
                onChange = function(value)
                    self.Data:SetValue('xOffset', value)
                    self:ConfigureIfEnabled()
                end,
                width = 16,
            },
            {
                type = 'range',
                label = 'Y Offset',
                name = 'yOffset',
                min = -1000,
                max = 1000,
                step = 1,
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('yOffset') end,
                onChange = function(value)
                    self.Data:SetValue('yOffset', value)
                    self:ConfigureIfEnabled()
                end,
                width = 16,
            },
        }
    end

    if (currTabID == 'zone') then
        local zoneDepends = function()
            return self.Data:GetValue('enable') and self.Data:GetValue('zoneEnable')
        end
        local fields = {
            {
                type = 'toggle',
                label = 'Enable Zone Text',
                name = 'zoneEnable',
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('zoneEnable') end,
                onChange = function(value)
                    self:HandleToggleChange('zoneEnable', value)
                end,
                width = 100,
            },
            {
                type = 'dropdown',
                label = 'Visibility',
                name = 'zoneVisibility',
                getOptions = function() return VISIBILITY_OPTIONS end,
                depends = zoneDepends,
                currentValue = function() return self.Data:GetValue('zoneVisibility') end,
                onChange = function(value)
                    self.Data:SetValue('zoneVisibility', value)
                    self:ConfigureIfEnabled()
                end,
                width = 33,
            },
            {
                type = 'title',
                label = 'Position',
                width = 100,
                depends = zoneDepends,
            },
        }
        for _, field in ipairs(self:GetPositionFields('zone', function() self:ConfigureIfEnabled() end, true)) do
            field.depends = zoneDepends
            table.insert(fields, field)
        end
        for _, field in ipairs(self:GetFontFields('zone', function() self:ConfigureIfEnabled() end)) do
            field.depends = zoneDepends
            table.insert(fields, field)
        end
        table.insert(fields, {
            type = 'spacer',
            width = 31,
            depends = zoneDepends,
        })
        table.insert(fields, {
            type = 'toggle',
            label = 'Text Background',
            name = 'zoneBgEnable',
            depends = zoneDepends,
            currentValue = function() return self.Data:GetValue('zoneBgEnable') end,
            onChange = function(value)
                self:HandleToggleChange('zoneBgEnable', value)
            end,
            width = 100,
        })
        table.insert(fields, {
            type = 'color-picker',
            label = 'Background Color',
            name = 'zoneBgColor',
            depends = zoneDepends,
            currentValue = function() return self.Data:GetValue('zoneBgColor') end,
            onChange = function(value)
                self.Data:SetValue('zoneBgColor', PackColor(value))
                self:ConfigureIfEnabled()
            end,
            width = 20,
        })
        return fields
    end

    if (currTabID == 'clock') then
        local clockDepends = function()
            return self.Data:GetValue('enable') and self.Data:GetValue('clockEnable')
        end
        local fields = {
            {
                type = 'toggle',
                label = 'Enable Clock',
                name = 'clockEnable',
                depends = function() return self.Data:GetValue('enable') end,
                currentValue = function() return self.Data:GetValue('clockEnable') end,
                onChange = function(value)
                    self:HandleToggleChange('clockEnable', value)
                end,
                width = 100,
            },
            {
                type = 'dropdown',
                label = 'Visibility',
                name = 'clockVisibility',
                getOptions = function() return VISIBILITY_OPTIONS end,
                depends = clockDepends,
                currentValue = function() return self.Data:GetValue('clockVisibility') end,
                onChange = function(value)
                    self.Data:SetValue('clockVisibility', value)
                    self:ConfigureIfEnabled()
                end,
                width = 33,
            },
            {
                type = 'title',
                label = 'Position',
                width = 100,
                depends = clockDepends,
            },
        }
        for _, field in ipairs(self:GetPositionFields('clock', function() self:ConfigureIfEnabled() end, true)) do
            field.depends = clockDepends
            table.insert(fields, field)
        end
        for _, field in ipairs(self:GetFontFields('clock', function() self:ConfigureIfEnabled() end)) do
            field.depends = clockDepends
            table.insert(fields, field)
        end
        table.insert(fields, {
            type = 'spacer',
            width = 31,
            depends = clockDepends,
        })
        table.insert(fields, {
            type = 'toggle',
            label = 'Text Background',
            name = 'clockBgEnable',
            depends = clockDepends,
            currentValue = function() return self.Data:GetValue('clockBgEnable') end,
            onChange = function(value)
                self:HandleToggleChange('clockBgEnable', value)
            end,
            width = 100,
        })
        table.insert(fields, {
            type = 'color-picker',
            label = 'Background Color',
            name = 'clockBgColor',
            depends = clockDepends,
            currentValue = function() return self.Data:GetValue('clockBgColor') end,
            onChange = function(value)
                self.Data:SetValue('clockBgColor', PackColor(value))
                self:ConfigureIfEnabled()
            end,
            width = 20,
        })
        return fields
    end

    if (currTabID == 'buttons') then
        if (currItemID == '__buttonGeneral__') then
            local buttonDepends = function()
                return self.Data:GetValue('enable')
            end
            return {
                {
                    type = 'title',
                    label = 'Minimap Button Appearance',
                    width = 100,
                    depends = buttonDepends,
                },
                {
                    type = 'range',
                    label = 'Button Scale',
                    name = 'buttonScale',
                    min = 0.5,
                    max = 2,
                    step = 0.05,
                    depends = buttonDepends,
                    currentValue = function()
                        return self:GetButtonScale()
                    end,
                    onChange = function(value)
                        self.Data:SetValue('buttonScale', value)
                        self:ConfigureIfEnabled()
                    end,
                    width = 33,
                },
                {
                    type = 'description',
                    label = 'Applies to LibDBIcon minimap buttons and the mail indicator.',
                    width = 100,
                    depends = buttonDepends,
                },
                {
                    type = 'toggle',
                    label = 'Button Background',
                    name = 'buttonBgEnable',
                    depends = buttonDepends,
                    currentValue = function()
                        return self:IsButtonBackgroundEnabled()
                    end,
                    onChange = function(value)
                        self:HandleToggleChange('buttonBgEnable', value)
                    end,
                    width = 100,
                },
                {
                    type = 'color-picker',
                    label = 'Background Color',
                    name = 'buttonBgColor',
                    depends = buttonDepends,
                    currentValue = function()
                        return self.Data:GetValue('buttonBgColor')
                    end,
                    onChange = function(value)
                        self.Data:SetValue('buttonBgColor', PackColor(value))
                        self:ConfigureIfEnabled()
                    end,
                    width = 20,
                },
            }
        end

        if (currItemID == '__drawer__') then
            local fields = {
                {
                    type = 'toggle',
                    label = 'Enable Button Drawer',
                    name = 'drawerEnable',
                    depends = function() return self.Data:GetValue('enable') end,
                    currentValue = function() return self.Data:GetValue('drawerEnable') end,
                    onChange = function(value)
                        self:HandleToggleChange('drawerEnable', value)
                    end,
                    width = 100,
                },
                {
                    type = 'title',
                    label = 'Drawer Position',
                    width = 100,
                    depends = function() return self.Data:GetValue('enable') and self.Data:GetValue('drawerEnable') end,
                },
            }
            for _, field in ipairs(self:GetPositionFields('drawer', function() self:ConfigureIfEnabled() end)) do
                field.depends = function()
                    return self.Data:GetValue('enable') and self.Data:GetValue('drawerEnable')
                end
                table.insert(fields, field)
            end
            return fields
        end

        if (currItemID == '__addonCompartment__') then
            local fields = {
                {
                    type = 'toggle',
                    label = 'Show Addon Compartment',
                    name = 'addonCompartmentShow',
                    depends = function() return self.Data:GetValue('enable') end,
                    currentValue = function() return self.Data:GetValue('addonCompartmentShow') end,
                    onChange = function(value)
                        self:HandleToggleChange('addonCompartmentShow', value)
                    end,
                    width = 100,
                },
                {
                    type = 'title',
                    label = 'Position',
                    width = 100,
                    depends = function()
                        return self.Data:GetValue('enable') and self.Data:GetValue('addonCompartmentShow')
                    end,
                },
            }
            for _, field in ipairs(self:GetPositionFields('addonCompartment', function() self:ConfigureIfEnabled() end)) do
                field.depends = function()
                    return self.Data:GetValue('enable') and self.Data:GetValue('addonCompartmentShow')
                end
                table.insert(fields, field)
            end
            return fields
        end

        if (currItemID == '__blizzard__') then
            local fields = {
                {
                    type = 'title',
                    label = 'Blizzard Minimap Buttons',
                    width = 100,
                    depends = function() return self.Data:GetValue('enable') end,
                },
            }
            for key, label in EXUI.utils.spairs(BLIZZ_BUTTON_LABELS, function(t, a, b) return t[a] < t[b] end) do
                local hasAngle = key ~= 'missions'
                table.insert(fields, {
                    type = 'dropdown',
                    label = label,
                    name = 'blizz_' .. key,
                    getOptions = function() return PLACEMENT_OPTIONS end,
                    depends = function() return self.Data:GetValue('enable') end,
                    currentValue = function()
                        local blizzButtons = self.Data:GetValue('blizzButtons') or {}
                        return blizzButtons[key] or 'outside'
                    end,
                    onChange = function(value)
                        local blizzButtons = self.Data:GetValue('blizzButtons') or {}
                        blizzButtons[key] = value
                        self.Data:SetValue('blizzButtons', blizzButtons)
                        self:ConfigureIfEnabled()
                        self:RefreshOptionsView()
                    end,
                    width = BLIZZ_OPTION_DROPDOWN_WIDTH,
                })
                if (hasAngle) then
                    table.insert(fields, {
                        type = 'range',
                        label = label .. ' Angle',
                        name = 'blizz_angle_' .. key,
                        min = 0,
                        max = 360,
                        step = 1,
                        depends = function()
                            local blizzButtons = self.Data:GetValue('blizzButtons') or {}
                            return self.Data:GetValue('enable') and blizzButtons[key] == 'outside'
                        end,
                        currentValue = function()
                            local angles = self.Data:GetValue('blizzButtonAngles') or {}
                            return angles[key] or DEFAULT_BLIZZ_ANGLES[key] or 180
                        end,
                        onChange = function(value)
                            local angles = self.Data:GetValue('blizzButtonAngles') or {}
                            angles[key] = value
                            self.Data:SetValue('blizzButtonAngles', angles)
                            self:ConfigureIfEnabled()
                        end,
                        width = BLIZZ_OPTION_ANGLE_WIDTH,
                    })
                end
                table.insert(fields, {
                    type = 'spacer',
                    width = 100 - BLIZZ_OPTION_DROPDOWN_WIDTH - (hasAngle and BLIZZ_OPTION_ANGLE_WIDTH or 0),
                    depends = function() return self.Data:GetValue('enable') end,
                })
            end
            return fields
        end

        if (currItemID) then
            return {
                {
                    type = 'title',
                    label = currItemID,
                    width = 100,
                    depends = function() return self.Data:GetValue('enable') end,
                },
                {
                    type = 'dropdown',
                    label = 'Placement',
                    name = 'ldb_placement_' .. currItemID,
                    getOptions = function() return PLACEMENT_OPTIONS end,
                    depends = function() return self.Data:GetValue('enable') end,
                    currentValue = function()
                        local ldbButtons = self.Data:GetValue('ldbButtons') or {}
                        return ldbButtons[currItemID] and ldbButtons[currItemID].placement or 'drawer'
                    end,
                    onChange = function(value)
                        local ldbButtons = self.Data:GetValue('ldbButtons') or {}
                        ldbButtons[currItemID] = ldbButtons[currItemID] or { angle = 180 }
                        ldbButtons[currItemID].placement = value
                        self.Data:SetValue('ldbButtons', ldbButtons)
                        self:ConfigureIfEnabled()
                        self:RefreshOptionsView()
                    end,
                    width = 33,
                },
                {
                    type = 'range',
                    label = 'Orbit Angle',
                    name = 'ldb_angle_' .. currItemID,
                    min = 0,
                    max = 360,
                    step = 1,
                    depends = function()
                        local ldbButtons = self.Data:GetValue('ldbButtons') or {}
                        return self.Data:GetValue('enable') and ldbButtons[currItemID] and
                            ldbButtons[currItemID].placement == 'outside'
                    end,
                    currentValue = function()
                        local ldbButtons = self.Data:GetValue('ldbButtons') or {}
                        return ldbButtons[currItemID] and ldbButtons[currItemID].angle or 180
                    end,
                    onChange = function(value)
                        local ldbButtons = self.Data:GetValue('ldbButtons') or {}
                        ldbButtons[currItemID] = ldbButtons[currItemID] or { placement = 'drawer' }
                        ldbButtons[currItemID].angle = value
                        self.Data:SetValue('ldbButtons', ldbButtons)
                        self:ConfigureIfEnabled()
                    end,
                    width = 16,
                },
            }
        end
    end

    return {}
end

--------------------------------
-- Runtime
--------------------------------

minimap.ApplySquareShape = function(self)
    Minimap:SetMaskTexture(MASK_TEXTURE)
    if (HybridMinimap and HybridMinimap.MapCanvas and HybridMinimap.CircleMask) then
        self:ApplyHybridMinimap()
    end
    GetMinimapShape = function()
        return SQUARE_SHAPE
    end
end

minimap.ApplyHybridMinimap = function(self)
    if (not HybridMinimap or not HybridMinimap.MapCanvas or not HybridMinimap.CircleMask) then return end
    if (HybridMinimap.SetFixedFrameStrata) then
        HybridMinimap:SetFixedFrameStrata(true)
        HybridMinimap:SetFrameStrata('BACKGROUND')
    end
    if (HybridMinimap.SetFixedFrameLevel) then
        HybridMinimap:SetFixedFrameLevel(true)
        HybridMinimap:SetFrameLevel(1)
    end
    HybridMinimap.MapCanvas:SetUseMaskTexture(false)
    HybridMinimap.CircleMask:SetTexture(MASK_TEXTURE)
    HybridMinimap.MapCanvas:SetUseMaskTexture(true)
    if (HybridMinimap.MapCanvas.EnableMouse) then
        HybridMinimap.MapCanvas:EnableMouse(false)
    end
end

minimap.SetupMinimapFrame = function(self)
    if (self.minimapFrameSetup) then return end
    self.minimapFrameSetup = true

    self.hiddenParent = CreateFrame('Frame')
    self.hiddenParent:Hide()
    self.suppressedFrames = {}
    self.noopLayout = function() end
    self.hiddenParent.Layout = self.noopLayout
    Minimap.Layout = self.noopLayout

    Minimap:SetParent(UIParent)
    if (Minimap.SetFixedFrameStrata) then
        Minimap:SetFixedFrameStrata(true)
        Minimap:SetFixedFrameLevel(true)
    end
    if (Minimap.GetFrameStrata and Minimap:GetFrameStrata() ~= 'LOW') then
        Minimap:SetFrameStrata('LOW')
    end
    if (Minimap.GetFrameLevel and Minimap:GetFrameLevel() ~= 2) then
        Minimap:SetFrameLevel(2)
    end

    Minimap:SetArchBlobRingScalar(0)
    Minimap:SetArchBlobRingAlpha(0)
    Minimap:SetQuestBlobRingScalar(0)
    Minimap:SetQuestBlobRingAlpha(0)

    Minimap:EnableMouse(true)

    self.borderContainer = CreateFrame('Frame', nil, Minimap)
    if (self.borderContainer.SetFixedFrameStrata) then
        self.borderContainer:SetFixedFrameStrata(true)
        self.borderContainer:SetFrameStrata('BACKGROUND')
    end
    if (self.borderContainer.SetFixedFrameLevel) then
        self.borderContainer:SetFixedFrameLevel(true)
        self.borderContainer:SetFrameLevel(MINIMAP_BORDER_FRAME_LEVEL)
    end
    self.borderContainer:EnableMouse(false)
    self.border = EXUI:AddPixelPerfectBorder(self.borderContainer, 1, { layer = 'BACKGROUND' })

    self.orbitButtonLayer = CreateFrame('Frame', nil, Minimap)
    self.orbitButtonLayer:SetAllPoints(Minimap)
    if (self.orbitButtonLayer.SetFixedFrameStrata) then
        self.orbitButtonLayer:SetFixedFrameStrata(true)
        self.orbitButtonLayer:SetFrameStrata('LOW')
    end
    if (self.orbitButtonLayer.SetFixedFrameLevel) then
        self.orbitButtonLayer:SetFixedFrameLevel(true)
        self.orbitButtonLayer:SetFrameLevel(ORBIT_BUTTON_FRAME_LEVEL)
    end
    self.orbitButtonLayer:EnableMouse(false)
    self.orbitButtonLayer.Layout = self.noopLayout

    if (ldbi.SetButtonToPosition and not self.ldbPositionHooked) then
        self.ldbPositionHooked = true
        hooksecurefunc(ldbi, 'SetButtonToPosition', function(_, button)
            if (not minimap.enabled) then return end
            PrepareOrbitButton(button)
            NudgeOrbitButtonOutward(button)
        end)
    end

    self:SetupBlizzButtonFixes()

    self.eventFrame = CreateFrame('Frame')
    self.eventFrame:SetScript('OnEvent', function(_, event, ...)
        if (event == 'ADDON_LOADED') then
            local addon = ...
            if (addon == 'Blizzard_HybridMinimap') then
                minimap:ApplyHybridMinimap()
            elseif (addon == 'Blizzard_TimeManager') then
                minimap:SuppressBlizzClockFrames()
            elseif (addon == 'Blizzard_Minimap') then
                minimap:SuppressMinimapZoomControls()
                minimap:SetupAddonCompartmentFixes()
                minimap:SetupBlizzButtonFixes()
                minimap:ApplyButtons()
                minimap:SetupMinimapMouseHandler()
            end
        elseif (event == 'PLAYER_ENTERING_WORLD') then
            minimap:RefreshRuntime()
        end
    end)
    self.eventFrame:RegisterEvent('ADDON_LOADED')
    self.eventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')

    self:CreateZoneText()
    self:CreateClock()
    self:CreateDrawer()
    self:CreateAddonCompartment()
    self:RegisterEditorFrames()
    self:SetupHoverVisibility()
end

minimap.PlaceOrbitButton = function(self, btn, angle)
    if (not btn) then return end
    local guard = not self.applyingLdbButton
    if (guard) then
        self.applyingLdbButton = true
    end
    PrepareOrbitButton(btn)
    if (not btn:IsShown()) then
        btn:Show()
    end
    SetButtonToPosition(btn, angle)
    PrepareOrbitButton(btn)
    if (guard) then
        self.applyingLdbButton = false
    end
end

minimap.RepositionMissionsButton = function(self)
    if (self.repositioningMissions) then return end
    local btn = GetBlizzButton('missions')
    if (not btn) then return end
    local db = self.Data:GetDB()
    local blizzButtons = db.blizzButtons or {}
    if (blizzButtons.missions ~= 'outside') then return end

    self.repositioningMissions = true
    PrepareOrbitButton(btn)
    btn:Show()
    btn:ClearAllPoints()
    local borderOffset = GetMinimapBorderOrbitOffset()
    EXUI:SetPoint(btn, 'CENTER', Minimap, 'BOTTOMLEFT', MISSIONS_CORNER_OFFSET + borderOffset,
        MISSIONS_CORNER_OFFSET + borderOffset)
    self.repositioningMissions = false
end

minimap.SetupBlizzButtonFixes = function(self)
    local missionsBtn = GetBlizzButton('missions')
    if (missionsBtn and not self.missionsHooksSetup) then
        self.missionsHooksSetup = true
        if (ExpansionLandingPageMinimapButton) then
            hooksecurefunc(ExpansionLandingPageMinimapButton, 'SetParent', function(_, parent)
                if (minimap.repositioningMissions) then return end
                local blizzButtons = minimap.Data:GetDB().blizzButtons or {}
                local orbitParent = GetOrbitButtonParent()
                if (blizzButtons.missions ~= 'outside' or parent == orbitParent) then return end
                minimap.repositioningMissions = true
                ExpansionLandingPageMinimapButton:SetParent(orbitParent)
                PrepareOrbitButton(ExpansionLandingPageMinimapButton)
                ExpansionLandingPageMinimapButton:ClearAllPoints()
                local borderOffset = GetMinimapBorderOrbitOffset()
                EXUI:SetPoint(ExpansionLandingPageMinimapButton, 'CENTER', Minimap, 'BOTTOMLEFT',
                    MISSIONS_CORNER_OFFSET + borderOffset, MISSIONS_CORNER_OFFSET + borderOffset)
                minimap.repositioningMissions = false
            end)
            hooksecurefunc(ExpansionLandingPageMinimapButton, 'UpdateIconForGarrison', function()
                if (minimap.repositioningMissions) then return end
                minimap:RepositionMissionsButton()
            end)
            hooksecurefunc(ExpansionLandingPageMinimapButton, 'SetLandingPageIconOffset', function()
                if (minimap.repositioningMissions) then return end
                minimap:RepositionMissionsButton()
            end)
        end
        if (GarrisonLandingPageMinimapButton_UpdateIcon) then
            hooksecurefunc('GarrisonLandingPageMinimapButton_UpdateIcon', function()
                if (minimap.repositioningMissions) then return end
                minimap:RepositionMissionsButton()
            end)
        end
    end

    if (not self.trackingSetup) then
        local trackingBtn = GetBlizzButton('tracking')
        if (trackingBtn and trackingBtn.SetMenuAnchor and AnchorUtil) then
            self.trackingSetup = true
            trackingBtn:SetMenuAnchor(AnchorUtil.CreateAnchor('CENTER', Minimap, 'CENTER'))
        end
    end

    if (not self.mailHooksSetup) then
        local mailBtn = GetBlizzButton('mail')
        if (mailBtn) then
            self.mailHooksSetup = true
            hooksecurefunc(mailBtn, 'Show', function()
                if (minimap.enabled and not minimap.applyingBlizzButton) then
                    minimap:ApplyBlizzButton('mail')
                end
            end)
            if (not self.mailEventRegistered and self.eventFrame) then
                self.mailEventRegistered = true
                self.eventFrame:RegisterEvent('UPDATE_PENDING_MAIL')
                local origOnEvent = self.eventFrame:GetScript('OnEvent')
                self.eventFrame:SetScript('OnEvent', function(frame, event, ...)
                    if (event == 'UPDATE_PENDING_MAIL' and minimap.enabled) then
                        minimap:ApplyBlizzButton('mail')
                    end
                    if (origOnEvent) then
                        origOnEvent(frame, event, ...)
                    end
                end)
            end
            if (MinimapMailFrameUpdate) then
                hooksecurefunc('MinimapMailFrameUpdate', function()
                    if (minimap.enabled) then
                        minimap:ApplyBlizzButton('mail')
                    end
                end)
            end
        end
    end

    if (not self.difficultyHooksSetup) then
        local diffBtn = GetBlizzButton('difficulty')
        if (diffBtn) then
            self.difficultyHooksSetup = true
            if (diffBtn.Update) then
                hooksecurefunc(diffBtn, 'Update', function()
                    if (minimap.enabled and not minimap.applyingBlizzButton) then
                        minimap:ApplyBlizzButton('difficulty')
                    end
                end)
            end
            if (not self.difficultyEventsRegistered and self.eventFrame) then
                self.difficultyEventsRegistered = true
                for _, event in ipairs(INSTANCE_DIFFICULTY_EVENTS) do
                    self.eventFrame:RegisterEvent(event)
                end
                local origOnEvent = self.eventFrame:GetScript('OnEvent')
                self.eventFrame:SetScript('OnEvent', function(frame, event, ...)
                    if (minimap.enabled) then
                        for _, diffEvent in ipairs(INSTANCE_DIFFICULTY_EVENTS) do
                            if (event == diffEvent) then
                                if (not minimap.difficultyRefreshPending) then
                                    minimap.difficultyRefreshPending = true
                                    C_Timer.After(0.3, function()
                                        minimap.difficultyRefreshPending = false
                                        if (minimap.enabled) then
                                            minimap:ApplyBlizzButton('difficulty')
                                        end
                                    end)
                                end
                                break
                            end
                        end
                    end
                    if (origOnEvent) then
                        origOnEvent(frame, event, ...)
                    end
                end)
            end
        end
    end
end

minimap.PingMinimap = function(self, frame)
    if (not IsInsideMinimap(frame)) then return end
    local x, y = GetCursorPosition()
    x = x / frame:GetEffectiveScale()
    y = y / frame:GetEffectiveScale()
    local cx, cy = frame:GetCenter()
    Minimap:PingLocation(x - cx, y - cy)
end

minimap.OpenTrackingMenu = function(self)
    if (not MinimapCluster or not MinimapCluster.Tracking) then return end

    local trackingBtn = MinimapCluster.Tracking.Button
    if (not trackingBtn) then return end

    local generator = trackingBtn.menuGenerator
    if (not generator) then return end

    if (MenuUtil and MenuUtil.CreateContextMenu) then
        MenuUtil.CreateContextMenu(Minimap, generator)
        return
    end

    if (not self.trackingSetup and trackingBtn.SetMenuAnchor and AnchorUtil) then
        trackingBtn:SetMenuAnchor(AnchorUtil.CreateAnchor('CENTER', Minimap, 'CENTER'))
        self.trackingSetup = true
    end

    if (trackingBtn.Enable) then
        trackingBtn:Enable(true)
    end
    if (trackingBtn.SetMenuOpen) then
        trackingBtn:SetMenuOpen(true)
    elseif (trackingBtn.OpenMenu) then
        trackingBtn:OpenMenu()
    end
end

minimap.SetupMinimapMouseHandler = function(self)
    Minimap:SetScript('OnMouseUp', function(frame, button)
        if (not minimap.enabled) then return end

        if (button == 'RightButton') then
            if (IsInsideMinimap(frame)) then
                minimap:OpenTrackingMenu()
            end
            return
        end

        if (button == 'LeftButton') then
            minimap:PingMinimap(frame)
        end
    end)
end

minimap.ClearMinimapMouseHandler = function(self)
    Minimap:SetScript('OnMouseUp', nil)
end

minimap.SuppressTrackingButton = function(self)
    if (not MinimapCluster or not MinimapCluster.Tracking) then return end

    local tracking = MinimapCluster.Tracking
    if (self.trackingSuppressed) then
        tracking:EnableMouse(false)
        tracking:SetAlpha(0)
        tracking:Hide()
        return
    end

    self.trackingSuppressed = true
    tracking:EnableMouse(false)
    tracking:SetAlpha(0)
    tracking:Hide()
    hooksecurefunc(tracking, 'Show', function(f)
        if (minimap.enabled) then
            f:EnableMouse(false)
            f:SetAlpha(0)
            f:Hide()
        end
    end)
end

minimap.ConfigureClickHijack = function(self)
    self:SetupMinimapMouseHandler()
end

minimap.SetupHoverVisibility = function(self)
    if (not self.enabled) then return end

    Minimap:HookScript('OnEnter', function()
        minimap:UpdateHoverVisibility(true)
    end)
    Minimap:HookScript('OnLeave', function()
        minimap:UpdateHoverVisibility(false)
    end)
end

minimap.UpdateHoverVisibility = function(self, isHovering)
    local db = self.Data:GetDB()

    if (self.zoneFrame and db.zoneEnable) then
        if (db.zoneVisibility == 'hover') then
            self.zoneFrame:SetAlpha(isHovering and 1 or 0)
        end
    end
    if (self.clockFrame and db.clockEnable) then
        if (db.clockVisibility == 'hover') then
            self.clockFrame:SetAlpha(isHovering and 1 or 0)
        end
    end
end

minimap.CLOCK_TEXT_PADDING = { x = 8, y = 4 }

minimap.GetClockSampleText = function(self)
    if (GetCVarBool('timeMgrUseMilitaryTime')) then
        return '99:99'
    end
    return '12:59'
end

minimap.LayoutClockFrame = function(self)
    if (not self.clockFrame or not self.clockFrame.text) then return end
    local db = self.Data:GetDB()
    local text = self.clockFrame.text
    local padX = EXUI:ScalePixel(self.CLOCK_TEXT_PADDING.x)
    local padY = EXUI:ScalePixel(self.CLOCK_TEXT_PADDING.y)
    local fontSize = db.clockFontSize or 12

    local savedText = text:GetText()
    text:SetText(self:GetClockSampleText())
    local textWidth = text:GetUnboundedStringWidth()
    if (textWidth <= 0) then
        textWidth = text:GetStringWidth()
    end
    if (savedText and savedText ~= '') then
        text:SetText(savedText)
    end

    EXUI:SetWidth(self.clockFrame, textWidth + padX * 2)
    EXUI:SetHeight(self.clockFrame, fontSize + padY * 2)

    text:ClearAllPoints()
    text:SetPoint('CENTER', self.clockFrame, 'CENTER', 0, 0)
    text:SetJustifyH('CENTER')
    text:SetJustifyV('MIDDLE')
end

minimap.ApplyTextBackground = function(self, frame, enabled, color)
    if (not frame.bg) then
        frame.bg = frame:CreateTexture(nil, 'BACKGROUND')
        frame.bg:SetAllPoints()
    end
    if (enabled) then
        frame.bg:Show()
        frame.bg:SetTexture(EXUI.const.textures.frame.solidBg)
        frame.bg:SetVertexColor(UnpackColor(color))
    else
        frame.bg:Hide()
    end
end

minimap.ApplyFontString = function(self, fontString, fontKey, sizeKey, flagKey)
    local font = self.Data:GetValue(fontKey)
    local fontSize = self.Data:GetValue(sizeKey) or 12
    local fontFlag = self.Data:GetValue(flagKey)
    if (fontFlag == '' or fontFlag == 'NONE') then fontFlag = nil end

    local fontPath = [[Interface/Addons/ExalityUI/Assets/Fonts/DMSans.ttf]]
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.font) then
        fontPath = EXUI.EXFrames.assets.font.default()
    end
    if (LSM) then
        fontPath = LSM:Fetch('font', font) or fontPath
    end
    fontString:SetFont(fontPath, fontSize, fontFlag)
end

local function PrepareMinimapOverlayFrame(frame)
    if (not frame) then return end
    if (frame.SetFixedFrameStrata) then
        frame:SetFixedFrameStrata(true)
    end
    frame:SetFrameStrata(MINIMAP_OVERLAY_FRAME_STRATA)
    if (frame.SetFixedFrameLevel) then
        frame:SetFixedFrameLevel(true)
    end
    frame:SetFrameLevel(MINIMAP_OVERLAY_FRAME_LEVEL)
end

minimap.CreateZoneText = function(self)
    if (self.zoneFrame) then return end

    local zoneFrame = CreateFrame('Button', nil, UIParent)
    PrepareMinimapOverlayFrame(zoneFrame)
    local zoneText = zoneFrame:CreateFontString(nil, 'OVERLAY')
    zoneText:SetAllPoints(zoneFrame)
    zoneText:SetJustifyH('CENTER')
    zoneFrame.text = zoneText

    if (MinimapCluster) then
        MinimapCluster:UnregisterEvent('ZONE_CHANGED')
        MinimapCluster:UnregisterEvent('ZONE_CHANGED_INDOORS')
        MinimapCluster:UnregisterEvent('ZONE_CHANGED_NEW_AREA')
    end

    zoneFrame:RegisterEvent('ZONE_CHANGED')
    zoneFrame:RegisterEvent('ZONE_CHANGED_INDOORS')
    zoneFrame:RegisterEvent('ZONE_CHANGED_NEW_AREA')
    zoneFrame:SetScript('OnEvent', function()
        minimap:UpdateZoneText()
    end)

    self.zoneFrame = zoneFrame
end

minimap.UpdateZoneText = function(self)
    if (not self.zoneFrame or not self.zoneFrame.text) then return end
    local db = self.Data:GetDB()
    if (not db.zoneEnable) then return end
    if (not self.zoneFrame.text:GetFont()) then return end

    local text = GetMinimapZoneText()
    self.zoneFrame.text:SetText(text)

    local pvpType
    if (C_PvP and C_PvP.GetZonePVPInfo) then
        pvpType = C_PvP.GetZonePVPInfo()
    end
    local color = ZONE_PVP_COLORS[pvpType] or ZONE_PVP_COLORS.normal
    self.zoneFrame.text:SetTextColor(color[1], color[2], color[3], color[4])
end

minimap.ConfigureZoneText = function(self)
    if (not self.zoneFrame) then return end
    local db = self.Data:GetDB()

    if (not db.zoneEnable or db.zoneVisibility == 'hidden') then
        self.zoneFrame:Hide()
        return
    end

    if (self.zoneFrame:GetParent() ~= UIParent) then
        self.zoneFrame:SetParent(UIParent)
    end
    PrepareMinimapOverlayFrame(self.zoneFrame)

    self.zoneFrame:Show()
    self.zoneFrame:ClearAllPoints()
    EXUI:SetPoint(self.zoneFrame, db.zoneAnchor, Minimap, db.zoneRelativeAnchor, db.zoneXOff, db.zoneYOff)
    EXUI:SetWidth(self.zoneFrame, db.size)
    EXUI:SetHeight(self.zoneFrame, db.zoneFontSize + 4)

    self:ApplyFontString(self.zoneFrame.text, 'zoneFont', 'zoneFontSize', 'zoneFontFlag')
    self:ApplyTextBackground(self.zoneFrame, db.zoneBgEnable, db.zoneBgColor)

    if (db.zoneVisibility == 'always') then
        self.zoneFrame:SetAlpha(1)
    elseif (db.zoneVisibility == 'hover') then
        self.zoneFrame:SetAlpha(Minimap:IsMouseOver() and 1 or 0)
    end

    self:UpdateZoneText()
end

minimap.CreateClock = function(self)
    if (self.clockFrame) then return end

    local clockFrame = CreateFrame('Button', nil, UIParent)
    PrepareMinimapOverlayFrame(clockFrame)
    local clockText = clockFrame:CreateFontString(nil, 'OVERLAY')
    clockFrame.text = clockText

    clockFrame:SetScript('OnClick', function()
        if (TimeManagerFrame) then
            if (TimeManagerFrame:IsShown()) then
                TimeManagerFrame:Hide()
            else
                TimeManagerFrame:Show()
            end
        end
    end)

    self.clockFrame = clockFrame
end

minimap.UpdateClockText = function(self)
    if (not self.clockFrame or not self.clockFrame.text) then return end
    local db = self.Data:GetDB()
    if (not db.clockEnable) then return end
    local fontPath = self.clockFrame.text:GetFont()
    if (not fontPath) then return end
    local hour, minute
    if (GetCVarBool('timeMgrUseLocalTime')) then
        hour, minute = tonumber(date('%H')), tonumber(date('%M'))
    else
        hour, minute = GetGameTime()
    end
    if (GetCVarBool('timeMgrUseMilitaryTime')) then
        self.clockFrame.text:SetFormattedText(TIMEMANAGER_TICKER_24HOUR, hour, minute)
    else
        if (hour == 0) then hour = 12 elseif (hour > 12) then hour = hour - 12 end
        self.clockFrame.text:SetFormattedText(TIMEMANAGER_TICKER_12HOUR, hour, minute)
    end
    self:LayoutClockFrame()
    self:ApplyTextBackground(self.clockFrame, self.Data:GetValue('clockBgEnable'), self.Data:GetValue('clockBgColor'))
end

minimap.StartClockTicker = function(self)
    if (self.clockTicker) then
        self.clockTicker:Cancel()
        self.clockTicker = nil
    end

    local prevMin = -1
    local function warmup()
        local _, minute
        if (GetCVarBool('timeMgrUseLocalTime')) then
            _, minute = tonumber(date('%H')), tonumber(date('%M'))
        else
            _, minute = GetGameTime()
        end
        if (prevMin == -1) then
            prevMin = minute
        elseif (minute ~= prevMin) then
            self.clockTicker = C_Timer.NewTicker(60, function()
                minimap:UpdateClockText()
            end)
            return
        end
        minimap:UpdateClockText()
        C_Timer.After(0.1, warmup)
    end
    warmup()
end

minimap.ConfigureClock = function(self)
    if (not self.clockFrame) then return end
    local db = self.Data:GetDB()

    if (not db.clockEnable or db.clockVisibility == 'hidden') then
        self.clockFrame:Hide()
        if (self.clockTicker) then
            self.clockTicker:Cancel()
            self.clockTicker = nil
        end
        return
    end

    if (self.clockFrame:GetParent() ~= UIParent) then
        self.clockFrame:SetParent(UIParent)
    end
    PrepareMinimapOverlayFrame(self.clockFrame)

    self.clockFrame:Show()
    self.clockFrame:ClearAllPoints()
    EXUI:SetPoint(self.clockFrame, db.clockAnchor, Minimap, db.clockRelativeAnchor, db.clockXOff, db.clockYOff)

    self:ApplyFontString(self.clockFrame.text, 'clockFont', 'clockFontSize', 'clockFontFlag')
    self:UpdateClockText()

    if (db.clockVisibility == 'always') then
        self.clockFrame:SetAlpha(1)
    elseif (db.clockVisibility == 'hover') then
        self.clockFrame:SetAlpha(Minimap:IsMouseOver() and 1 or 0)
    end

    self:StartClockTicker()

    C_Timer.After(0, function()
        if (minimap.enabled and minimap.clockFrame) then
            minimap:UpdateClockText()
        end
    end)
    C_Timer.After(1, function()
        if (minimap.enabled and minimap.clockFrame) then
            minimap:ApplyFontString(minimap.clockFrame.text, 'clockFont', 'clockFontSize', 'clockFontFlag')
            minimap:UpdateClockText()
        end
    end)
end

minimap.CreateDrawer = function(self)
    if (self.drawerButton) then return end

    self.drawerButton = CreateFrame('Button', nil, Minimap)
    EXUI:SetSize(self.drawerButton, 22, 22)
    self.drawerButton:SetFrameLevel(25)

    local drawerBgSize = EXUI:ScalePixel(22)
    local bg = self.drawerButton:CreateTexture(nil, 'BACKGROUND')
    bg:SetPoint('CENTER')
    self:ApplyMinimapButtonBackground(bg, drawerBgSize, self:GetMinimapButtonBgColor())
    self.drawerButton.bg = bg

    local icon = self.drawerButton:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('CENTER')
    icon:SetSize(EXUI:ScalePixel(14), EXUI:ScalePixel(14))
    icon:SetTexture(EXUI.const.textures.minimap.drawerOpen)
    if (icon.SetMaskTexture) then
        icon:SetMaskTexture(EXUI.const.textures.frame.iconMask)
    end
    icon:SetVertexColor(1, 1, 1, 1)
    self.drawerButton.icon = icon

    local accent = EXUI.const.colors.accent
    self.drawerButton:SetScript('OnEnter', function(btn)
        btn.icon:SetVertexColor(accent[1], accent[2], accent[3], accent[4] or 1)
    end)
    self.drawerButton:SetScript('OnLeave', function(btn)
        btn.icon:SetVertexColor(1, 1, 1, 1)
    end)

    self.drawerButton:SetScript('OnClick', function(btn)
        minimap:ToggleDrawerMenu(btn)
    end)
end

local function HideBlizzAddonCompartmentChrome(frame)
    if (not frame) then return end
    ForEachButtonTexture(frame, function(tex)
        tex:Hide()
        tex:SetAlpha(0)
    end)
    if (frame.Text) then
        frame.Text:Hide()
    end
end

local function SortAddonCompartmentEntries(addonData1, addonData2)
    local text1 = addonData1.text or ''
    local text2 = addonData2.text or ''
    if (C_StringUtil and C_StringUtil.StripHyperlinks) then
        text1 = C_StringUtil.StripHyperlinks(text1)
        text2 = C_StringUtil.StripHyperlinks(text2)
    end
    return strcmputf8i(text1, text2) < 0
end

local function GetListMenuFont()
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.font) then
        return EXUI.EXFrames.assets.font.default()
    end
    return GameFontNormal:GetFont()
end

local function GetListMenuPanelBgTexture()
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.textures.ui.panelBg) then
        return EXUI.EXFrames.assets.textures.ui.panelBg
    end
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.textures.ui.inputBg) then
        return EXUI.EXFrames.assets.textures.ui.inputBg
    end
    return EXUI.const.textures.frame.inputs.editboxBg
end

local function GetListMenuPanelBorderTexture()
    if (EXUI.EXFrames and EXUI.EXFrames.assets and EXUI.EXFrames.assets.textures.ui.panelBorder) then
        return EXUI.EXFrames.assets.textures.ui.panelBorder
    end
    return GetListMenuPanelBgTexture()
end

local function ApplyListMenuSliceTexture(tex, texturePath, r, g, b, a)
    tex:SetTexture(texturePath)
    tex:SetVertexColor(r, g, b, a)
    if (tex.SetTextureSliceMargins) then
        tex:SetTextureSliceMargins(6, 6, 6, 6)
        tex:SetTextureSliceMode(Enum.UITextureSliceMode.Stretched)
    end
    tex:SetAllPoints()
end

local function SetListMenuRowIcon(texture, icon)
    if (not texture) then return end
    if (not icon) then
        texture:Hide()
        return
    end
    texture:Show()
    if (C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon)) then
        texture:SetAtlas(icon)
    else
        texture:SetTexture(icon)
    end
    local inset = 0.125
    texture:SetTexCoord(inset, 1 - inset, inset, 1 - inset)
end

local function InvokeCompartmentAddonClick(addonData, buttonName)
    if (not addonData or not addonData.func) then return end
    local ok = pcall(addonData.func, nil, { buttonName = buttonName or 'LeftButton' }, nil)
    if (not ok) then
        pcall(addonData.func)
    end
end

local function MeasureListMenuWidth(panel, entries)
    if (not panel.measureFont) then
        panel.measureFont = panel:CreateFontString(nil, 'ARTWORK')
        panel.measureFont:SetFont(GetListMenuFont(), 10, 'OUTLINE')
        panel.measureFont:Hide()
    end

    local maxText = 0
    for _, entry in ipairs(entries) do
        panel.measureFont:SetText(entry.text or '')
        maxText = math.max(maxText, panel.measureFont:GetStringWidth())
    end

    local anchorWidth = panel.anchorWidth or LIST_MENU_MIN_WIDTH
    local contentWidth = maxText + LIST_MENU_ICON_COLUMN + LIST_MENU_TEXT_PADDING
    return math.min(
        LIST_MENU_MAX_WIDTH,
        math.max(LIST_MENU_MIN_WIDTH, anchorWidth, contentWidth)
    )
end

local function PositionListMenuPanel(panel, anchorBtn)
    panel:ClearAllPoints()
    panel:SetClampedToScreen(true)

    local panelHeight = panel:GetHeight() * panel:GetEffectiveScale()
    local screenW = GetScreenWidth()
    local screenH = GetScreenHeight()

    local left, bottom, width, height = anchorBtn:GetRect()
    local anchorTop = bottom + height
    local anchorCenterX = left + (width / 2)

    local spaceBelow = bottom - LIST_MENU_GAP - panelHeight
    local spaceAbove = screenH - anchorTop - LIST_MENU_GAP - panelHeight
    local placeBelow = spaceBelow >= 0 or spaceBelow >= spaceAbove

    local panelPoint, anchorPoint, yOff
    if (placeBelow) then
        panelPoint, anchorPoint, yOff = 'TOP', 'BOTTOM', -LIST_MENU_GAP
    else
        panelPoint, anchorPoint, yOff = 'BOTTOM', 'TOP', LIST_MENU_GAP
    end

    if ((anchorCenterX / screenW) > 0.5) then
        panel:SetPoint(panelPoint .. 'RIGHT', anchorBtn, anchorPoint .. 'RIGHT', 0, yOff)
    else
        panel:SetPoint(panelPoint .. 'LEFT', anchorBtn, anchorPoint .. 'LEFT', 0, yOff)
    end
end

local function ConfigureListMenuRow(row, entry, theme, parentPanel)
    local bgR, bgG, bgB, bgA = UnpackThemeColor(theme.backgroundLight)
    local accentR, accentG, accentB, accentA = UnpackThemeColor(theme.accent)

    SetListMenuRowIcon(row.icon, entry.icon)
    row.label:SetText(entry.text or '')
    row.listEntry = entry

    row.bg:SetVertexColor(bgR, bgG, bgB, bgA)
    row:SetScript('OnEnter', function(btn)
        btn.bg:SetVertexColor(accentR, accentG, accentB, accentA)
        if (btn.listEntry and btn.listEntry.onEnter) then
            pcall(btn.listEntry.onEnter, btn)
        end
    end)
    row:SetScript('OnLeave', function(btn)
        btn.bg:SetVertexColor(bgR, bgG, bgB, bgA)
        if (btn.listEntry and btn.listEntry.onLeave) then
            pcall(btn.listEntry.onLeave, btn)
        end
    end)
    row:SetScript('OnClick', function(btn, button)
        if (btn.listEntry and btn.listEntry.onClick) then
            pcall(btn.listEntry.onClick, btn, button)
        end
        if (parentPanel) then
            parentPanel:Hide()
        end
    end)
end

local function CreateListMenuPanel(frameName)
    local theme = EXUI.const.theme
    local panel = CreateFrame('Frame', frameName, UIParent)
    panel:SetFrameStrata('TOOLTIP')
    panel:SetClampedToScreen(true)
    panel:EnableMouse(true)
    panel:Hide()

    local bg = panel:CreateTexture(nil, 'BACKGROUND')
    ApplyListMenuSliceTexture(bg, GetListMenuPanelBgTexture(), UnpackThemeColor(theme.backgroundDeep))
    panel.bg = bg

    local border = panel:CreateTexture(nil, 'OVERLAY', nil, 1)
    ApplyListMenuSliceTexture(border, GetListMenuPanelBorderTexture(), UnpackThemeColor(theme.border))
    panel.border = border

    panel.rows = {}
    panel.rowPool = CreateFramePool('Button', panel)

    panel.SetEntries = function(f, entries, anchorBtn)
        for _, row in ipairs(f.rows) do
            row:Hide()
            f.rowPool:Release(row)
        end
        wipe(f.rows)

        f.anchorBtn = anchorBtn
        f.anchorWidth = anchorBtn and anchorBtn:GetWidth() or LIST_MENU_MIN_WIDTH

        local count = #entries
        if (count == 0) then
            f:SetSize(LIST_MENU_MIN_WIDTH, LIST_MENU_ROW_HEIGHT)
            return
        end

        local width = MeasureListMenuWidth(f, entries)
        local height = count * (LIST_MENU_ROW_HEIGHT + LIST_MENU_ROW_GAP) - LIST_MENU_ROW_GAP
            + (LIST_MENU_PADDING * 2)
        f:SetSize(width + (LIST_MENU_PADDING * 2), height)

        local previous
        for index, entry in ipairs(entries) do
            local row = f.rowPool:Acquire()
            row:SetParent(f)
            row:SetSize(width, LIST_MENU_ROW_HEIGHT)
            row:SetFrameLevel(f:GetFrameLevel() + 1)
            row:RegisterForClicks('AnyUp')

            if (not row.bg) then
                local rowBg = row:CreateTexture(nil, 'BACKGROUND')
                ApplyListMenuSliceTexture(rowBg, GetListMenuPanelBgTexture(), UnpackThemeColor(theme.backgroundLight))
                row.bg = rowBg

                local icon = row:CreateTexture(nil, 'ARTWORK')
                icon:SetSize(18, 18)
                icon:SetPoint('LEFT', row, 'LEFT', 4, 0)
                row.icon = icon

                local label = row:CreateFontString(nil, 'OVERLAY')
                label:SetFont(GetListMenuFont(), 10, 'OUTLINE')
                label:SetTextColor(UnpackThemeColor(theme.text))
                label:SetPoint('LEFT', icon, 'RIGHT', 6, 0)
                label:SetPoint('RIGHT', row, 'RIGHT', -6, 0)
                label:SetJustifyH('LEFT')
                row.label = label
            end

            ConfigureListMenuRow(row, entry, theme, f)

            if (previous) then
                row:SetPoint('TOPLEFT', previous, 'BOTTOMLEFT', 0, -LIST_MENU_ROW_GAP)
            else
                row:SetPoint('TOPLEFT', f, 'TOPLEFT', LIST_MENU_PADDING, -LIST_MENU_PADDING)
            end

            row:Show()
            f.rows[index] = row
            previous = row
        end
    end

    panel.ShowAt = function(f, anchorBtn, entries)
        if (not anchorBtn or #entries == 0) then return end
        f:SetEntries(entries, anchorBtn)
        f:Show()
        PositionListMenuPanel(f, anchorBtn)
    end

    if (not panel.dismissSetup) then
        panel.dismissSetup = true
        panel:SetScript('OnShow', function(f)
            f:SetScript('OnUpdate', function(frame)
                if (not IsMouseButtonDown('LeftButton')) then return end
                if (frame:IsMouseOver()) then return end
                if (frame.anchorBtn and frame.anchorBtn:IsMouseOver()) then return end
                frame:Hide()
            end)
        end)
        panel:SetScript('OnHide', function(f)
            f:SetScript('OnUpdate', nil)
            f.anchorBtn = nil
            if (f.onHideCallback) then
                f.onHideCallback()
                f.onHideCallback = nil
            end
        end)
    end

    return panel
end

minimap.GetListMenuPanel = function(self, key)
    self.listMenuPanels = self.listMenuPanels or {}
    if (not self.listMenuPanels[key]) then
        self.listMenuPanels[key] = CreateListMenuPanel('ExalityUIListMenu_' .. key)
    end
    return self.listMenuPanels[key]
end

minimap.GetAddonCompartmentCount = function(self)
    if (not AddonCompartmentFrame or not AddonCompartmentFrame.registeredAddons) then return 0 end
    return #AddonCompartmentFrame.registeredAddons
end

minimap.GetSortedAddonCompartmentEntries = function(self)
    if (not AddonCompartmentFrame or not AddonCompartmentFrame.registeredAddons) then return {} end
    local entries = {}
    for index, addonData in ipairs(AddonCompartmentFrame.registeredAddons) do
        entries[index] = {
            text = addonData.text,
            icon = addonData.icon,
            onClick = function(_, button)
                InvokeCompartmentAddonClick(addonData, button)
            end,
            onEnter = addonData.funcOnEnter and function(row)
                pcall(addonData.funcOnEnter, row)
            end or nil,
            onLeave = addonData.funcOnLeave and function(row)
                pcall(addonData.funcOnLeave, row)
            end or nil,
        }
    end
    table.sort(entries, function(a, b)
        return SortAddonCompartmentEntries(
            { text = a.text },
            { text = b.text }
        )
    end)
    return entries
end

minimap.IsCompartmentMenuOpen = function(self)
    local panel = self.listMenuPanels and self.listMenuPanels.compartment
    return panel and panel:IsShown()
end

minimap.CloseCompartmentMenu = function(self)
    local panel = self.listMenuPanels and self.listMenuPanels.compartment
    if (panel) then
        panel:Hide()
    end
end

minimap.IsDrawerMenuOpen = function(self)
    local panel = self.listMenuPanels and self.listMenuPanels.drawer
    return panel and panel:IsShown()
end

minimap.CloseDrawerMenu = function(self)
    local panel = self.listMenuPanels and self.listMenuPanels.drawer
    if (panel) then
        panel:Hide()
    end
    self.drawerOpen = false
end

minimap.GetButtonListIcon = function(self, btn, blizzKey)
    if (blizzKey == 'mail') then
        return EXUI.const.textures.minimap.mail
    end
    if (not btn) then return nil end
    local iconTex = self:FindButtonIcon(btn)
    if (not iconTex) then return nil end
    if (iconTex.GetAtlas) then
        local atlas = iconTex:GetAtlas()
        if (atlas and atlas ~= '') then
            return atlas
        end
    end
    return iconTex:GetTexture()
end

minimap.GetDrawerMenuEntries = function(self)
    local entries = {}
    local db = self.Data:GetDB()
    local blizzButtons = db.blizzButtons or {}

    for key, label in EXUI.utils.spairs(BLIZZ_BUTTON_LABELS, function(t, a, b) return t[a] < t[b] end) do
        if (blizzButtons[key] == 'drawer') then
            local btn = GetBlizzButton(key)
            if (btn) then
                table.insert(entries, {
                    text = label,
                    icon = self:GetButtonListIcon(btn, key),
                    sortKey = label,
                    onClick = function(_, button)
                        if (btn.OpenMenu and button == 'LeftButton') then
                            btn:OpenMenu()
                        elseif (btn.Click) then
                            btn:Click(button)
                        end
                    end,
                })
            end
        end
    end

    local ldbButtons = db.ldbButtons or {}
    local ldbNames = {}
    for name, cfg in pairs(ldbButtons) do
        if (cfg.placement == 'drawer') then
            table.insert(ldbNames, name)
        end
    end
    table.sort(ldbNames)

    for _, name in ipairs(ldbNames) do
        local btn = ldbi:GetMinimapButton(name)
        if (btn) then
            local onEnter = btn:GetScript('OnEnter')
            local onLeave = btn:GetScript('OnLeave')
            table.insert(entries, {
                text = name,
                icon = self:GetButtonListIcon(btn),
                sortKey = name,
                onClick = function(_, button)
                    if (btn.Click) then
                        btn:Click(button)
                    end
                end,
                onEnter = onEnter and function(row)
                    onEnter(btn)
                end or nil,
                onLeave = onLeave and function()
                    onLeave(btn)
                end or nil,
            })
        end
    end

    table.sort(entries, function(a, b)
        return strcmputf8i(a.sortKey or a.text or '', b.sortKey or b.text or '') < 0
    end)
    return entries
end

minimap.RefreshDrawerMenu = function(self)
    if (not self.drawerOpen or not self:IsDrawerMenuOpen() or not self.drawerButton) then return end
    local entries = self:GetDrawerMenuEntries()
    if (#entries == 0) then
        self:CloseDrawerMenu()
        return
    end
    local panel = self:GetListMenuPanel('drawer')
    panel.onHideCallback = function()
        minimap.drawerOpen = false
    end
    panel:ShowAt(self.drawerButton, entries)
end

minimap.ToggleDrawerMenu = function(self, anchorBtn)
    if (not anchorBtn) then return end

    if (self:IsDrawerMenuOpen() and self.listMenuPanels and self.listMenuPanels.drawer
        and self.listMenuPanels.drawer.anchorBtn == anchorBtn) then
        self:CloseDrawerMenu()
        return
    end

    self:OpenDrawerMenu(anchorBtn)
end

minimap.OpenDrawerMenu = function(self, anchorBtn)
    local entries = self:GetDrawerMenuEntries()
    if (#entries == 0) then return end

    self:CloseCompartmentMenu()
    self.drawerOpen = true
    local panel = self:GetListMenuPanel('drawer')
    panel.onHideCallback = function()
        minimap.drawerOpen = false
    end
    panel:ShowAt(anchorBtn, entries)
end

minimap.HideBlizzAddonCompartmentFrame = function(self)
    if (not AddonCompartmentFrame) then return end
    self.configuringAddonCompartment = true
    AddonCompartmentFrame:Hide()
    self.configuringAddonCompartment = false
end

minimap.ToggleCompartmentMenu = function(self, anchorBtn)
    if (not anchorBtn) then return end

    local panel = self.listMenuPanels and self.listMenuPanels.compartment
    if (self:IsCompartmentMenuOpen() and panel and panel.anchorBtn == anchorBtn) then
        self:CloseCompartmentMenu()
        return
    end

    self:OpenCompartmentMenu(anchorBtn)
end

minimap.OpenCompartmentMenu = function(self, anchorBtn)
    if (not AddonCompartmentFrame or not anchorBtn) then return end
    local entries = self:GetSortedAddonCompartmentEntries()
    if (#entries == 0) then return end

    self:CloseDrawerMenu()
    self:GetListMenuPanel('compartment'):ShowAt(anchorBtn, entries)
end

minimap.CreateAddonCompartment = function(self)
    if (self.compartmentButton) then return end

    self.compartmentButton = CreateFrame('Button', nil, Minimap)
    EXUI:SetSize(self.compartmentButton, 22, 22)
    self.compartmentButton:SetFrameLevel(25)

    local compartmentBgSize = EXUI:ScalePixel(22)
    local bg = self.compartmentButton:CreateTexture(nil, 'BACKGROUND')
    bg:SetPoint('CENTER')
    self:ApplyMinimapButtonBackground(bg, compartmentBgSize, self:GetMinimapButtonBgColor())
    self.compartmentButton.bg = bg

    local icon = self.compartmentButton:CreateTexture(nil, 'ARTWORK')
    icon:SetPoint('CENTER')
    icon:SetSize(EXUI:ScalePixel(14), EXUI:ScalePixel(14))
    icon:SetTexture(EXUI.const.textures.frame.settingsIcon)
    if (icon.SetMaskTexture) then
        icon:SetMaskTexture(EXUI.const.textures.frame.iconMask)
    end
    icon:SetVertexColor(1, 1, 1, 1)
    self.compartmentButton.icon = icon

    local accent = EXUI.const.colors.accent
    self.compartmentButton:SetScript('OnEnter', function(btn)
        btn.icon:SetVertexColor(accent[1], accent[2], accent[3], accent[4] or 1)
        if (AddonCompartmentFrame and AddonCompartmentFrame:GetScript('OnEnter')) then
            AddonCompartmentFrame:GetScript('OnEnter')(AddonCompartmentFrame)
        end
    end)
    self.compartmentButton:SetScript('OnLeave', function(btn)
        btn.icon:SetVertexColor(1, 1, 1, 1)
        if (AddonCompartmentFrame and AddonCompartmentFrame:GetScript('OnLeave')) then
            AddonCompartmentFrame:GetScript('OnLeave')(AddonCompartmentFrame)
        end
    end)

    self.compartmentButton:SetScript('OnClick', function(btn)
        minimap:ToggleCompartmentMenu(btn)
    end)

    self:SetupAddonCompartmentFixes()
end

minimap.SetupAddonCompartmentFixes = function(self)
    if (self.addonCompartmentHooksSetup or not AddonCompartmentFrame) then return end
    self.addonCompartmentHooksSetup = true
    HideBlizzAddonCompartmentChrome(AddonCompartmentFrame)

    hooksecurefunc(AddonCompartmentFrame, 'UpdateDisplay', function()
        if (not minimap.enabled) then return end
        minimap:ConfigureAddonCompartment()
    end)
end

minimap.ConfigureAddonCompartment = function(self)
    if (not self.compartmentButton) then return end
    local db = self.Data:GetDB()
    local count = self:GetAddonCompartmentCount()

    if (not db.addonCompartmentShow or count == 0) then
        self.compartmentButton:Hide()
        self:CloseCompartmentMenu()
        self:HideBlizzAddonCompartmentFrame()
        return
    end

    self.compartmentButton:Show()
    self.compartmentButton:ClearAllPoints()
    EXUI:SetPoint(self.compartmentButton, db.addonCompartmentAnchor, Minimap, db.addonCompartmentRelativeAnchor,
        db.addonCompartmentXOff, db.addonCompartmentYOff)
    self:HideBlizzAddonCompartmentFrame()
end

minimap.ConfigureDrawer = function(self)
    if (not self.drawerButton) then return end
    local db = self.Data:GetDB()

    if (not db.drawerEnable) then
        self.drawerButton:Hide()
        self:CloseDrawerMenu()
        return
    end

    self.drawerButton:Show()
    self.drawerButton:ClearAllPoints()
    EXUI:SetPoint(self.drawerButton, db.drawerAnchor, Minimap, db.drawerRelativeAnchor, db.drawerXOff,
        db.drawerYOff)
    self:RefreshDrawerMenu()
end

minimap.ApplyBlizzButton = function(self, key)
    if (self.applyingBlizzButton) then return end

    local btn = GetBlizzButton(key)
    if (not btn) then return end

    if (key == 'calendar') then
        self:SuppressBlizzFrame(btn)
        return
    end

    local db = self.Data:GetDB()
    local blizzButtons = db.blizzButtons or {}
    local placement = blizzButtons[key] or 'outside'
    local angles = db.blizzButtonAngles or {}

    if (placement == 'hidden') then
        btn:Hide()
        return
    end

    if (placement == 'drawer') then
        btn:Hide()
        if (self.drawerOpen) then
            self:RefreshDrawerMenu()
        end
        return
    end

    local angle = angles[key] or DEFAULT_BLIZZ_ANGLES[key] or 180
    self.applyingBlizzButton = true
    if (key == 'missions') then
        self:RepositionMissionsButton()
    elseif (key == 'difficulty') then
        local label = self:GetInstanceDifficultyLabel()
        if (not label) then
            btn:Hide()
        else
            self:PlaceOrbitButton(btn, angle)
            self:StyleBlizzDifficultyButton(btn, label)
        end
    else
        self:PlaceOrbitButton(btn, angle)
    end

    if (key == 'mail') then
        self:StyleBlizzMailButton(btn)
    end
    self.applyingBlizzButton = false
end

minimap.ApplyLdbButton = function(self, name, cfg)
    local btn = ldbi:GetMinimapButton(name)
    if (not btn) then return end

    self.applyingLdbButton = true
    local placement = cfg.placement or 'drawer'
    if (placement == 'hidden') then
        ldbi:Hide(name)
        ldbi:ShowOnEnter(name, false)
        self.applyingLdbButton = false
        return
    end

    if (placement == 'drawer') then
        ldbi:ShowOnEnter(name, false)
        ldbi:Hide(name)
        if (self.drawerOpen) then
            self:RefreshDrawerMenu()
        end
        self.applyingLdbButton = false
        return
    end

    ldbi:ShowOnEnter(name, false)
    local angle = self:GetLdbButtonAngle(name, cfg)
    if (btn.db) then
        btn.db.minimapPos = angle
    end
    self:PlaceOrbitButton(btn, angle)
    self:StyleMinimapButton(btn)
    self:SetupLdbDragSave(name, btn)
    self.applyingLdbButton = false
end

minimap.HookLdbShow = function(self)
    if (self.ldbShowHooked) then return end
    self.ldbShowHooked = true
    hooksecurefunc(ldbi, 'Show', function(_, name)
        if (not minimap.enabled or minimap.applyingLdbButton) then return end
        local ldbButtons = minimap.Data:GetValue('ldbButtons') or {}
        local cfg = ldbButtons[name]
        if (not cfg) then return end

        minimap.applyingLdbButton = true
        if (cfg.placement == 'outside') then
            local ldbBtn = ldbi:GetMinimapButton(name)
            local angle = minimap:GetLdbButtonAngle(name, cfg)
            if (ldbBtn and ldbBtn.db) then
                ldbBtn.db.minimapPos = angle
            end
            minimap:PlaceOrbitButton(ldbBtn, angle)
            minimap:StyleMinimapButton(ldbBtn)
            minimap:SetupLdbDragSave(name, ldbBtn)
        else
            ldbi:Hide(name)
            ldbi:ShowOnEnter(name, false)
            if (cfg.placement == 'drawer' and minimap.drawerOpen) then
                minimap:RefreshDrawerMenu()
            end
        end
        minimap.applyingLdbButton = false
    end)
end

minimap.ApplyButtons = function(self)
    local db = self.Data:GetDB()
    for key in pairs(BLIZZ_BUTTON_LABELS) do
        self:ApplyBlizzButton(key)
    end

    self:SyncLdbButtons()
    local ldbButtons = db.ldbButtons or {}
    for name, cfg in pairs(ldbButtons) do
        self:ApplyLdbButton(name, cfg)
    end

    if (not self.ldbCallbackRegistered) then
        self:HookLdbShow()
        ldbi.RegisterCallback(self, 'LibDBIcon_IconCreated', function(_, _, buttonName)
            if (not minimap.enabled) then return end
            minimap:SyncLdbButtons()
            local ldbButtons = minimap.Data:GetValue('ldbButtons') or {}
            local cfg = ldbButtons[buttonName]
            if (cfg) then
                minimap:ApplyLdbButton(buttonName, cfg)
            end
            local selected = optionsController:GetSelectedModule()
            if (optionsFields.splitView and selected and selected.module == minimap) then
                optionsFields:RefreshItemList()
            end
        end)
        self.ldbCallbackRegistered = true
    end

    self:ConfigureDrawer()
    self:ConfigureAddonCompartment()
end

minimap.HideDefaultMinimapChrome = function(self)
    local hidden = self.hiddenParent
    if (MinimapBorder) then MinimapBorder:SetParent(hidden) end
    if (MinimapBorderTop) then MinimapBorderTop:SetParent(hidden) end
    if (MinimapBackdrop) then MinimapBackdrop:SetParent(hidden) end
    if (MinimapCompassTexture) then MinimapCompassTexture:SetParent(hidden) end
    if (MinimapCluster and MinimapCluster.EnableMouse) then
        MinimapCluster:EnableMouse(false)
    end
    if (MinimapCluster and MinimapCluster.BorderTop) then
        self:SuppressBlizzFrame(MinimapCluster.BorderTop)
    end
    if (MinimapCluster and MinimapCluster.ZoneTextButton) then
        self:SuppressBlizzFrame(MinimapCluster.ZoneTextButton)
    end
    if (MinimapZoneTextButton) then
        self:SuppressBlizzFrame(MinimapZoneTextButton)
    end
    if (MinimapZoneText) then
        self:SuppressBlizzFrame(MinimapZoneText)
    end
    self:SuppressBlizzClockFrames()
    self:SuppressMinimapZoomControls()
    self:SuppressMinimapCraftingOrder()
    self:SuppressTrackingButton()
end

minimap.SuppressMinimapCraftingOrder = function(self)
    local frame = MinimapCluster and MinimapCluster.IndicatorFrame and
        MinimapCluster.IndicatorFrame.CraftingOrderFrame
    if (frame) then
        self:SuppressBlizzFrame(frame)
    end
end

minimap.SuppressMinimapZoomControls = function(self)
    if (Minimap.ZoomHitArea) then
        self:SuppressBlizzFrame(Minimap.ZoomHitArea)
    end
    if (Minimap.ZoomIn) then
        self:SuppressBlizzFrame(Minimap.ZoomIn)
    end
    if (Minimap.ZoomOut) then
        self:SuppressBlizzFrame(Minimap.ZoomOut)
    end
end

minimap.SuppressBlizzClockFrames = function(self)
    if (GameTimeFrame) then
        self:SuppressBlizzFrame(GameTimeFrame)
    end
    if (TimeManagerClockButton) then
        self:SuppressBlizzFrame(TimeManagerClockButton)
    end
    if (TimeManagerClockTicker) then
        self:SuppressBlizzFrame(TimeManagerClockTicker)
    end
    if (MinimapCluster and MinimapCluster.TimeManagerClockButton) then
        self:SuppressBlizzFrame(MinimapCluster.TimeManagerClockButton)
    end
end

minimap.SuppressBlizzFrame = function(self, frame)
    if (not frame or not self.hiddenParent) then return end
    self.suppressedFrames = self.suppressedFrames or {}
    if (self.suppressedFrames[frame]) then
        frame:Hide()
        return
    end
    self.suppressedFrames[frame] = true
    frame:SetParent(self.hiddenParent)
    frame:Hide()
    hooksecurefunc(frame, 'Show', function(f)
        if (minimap.enabled) then
            f:Hide()
        end
    end)
    hooksecurefunc(frame, 'SetParent', function(f, parent)
        if (minimap.suppressingFrame or not minimap.enabled or parent == minimap.hiddenParent) then return end
        minimap.suppressingFrame = true
        f:SetParent(minimap.hiddenParent)
        minimap.suppressingFrame = false
    end)
end

minimap.ConfigureMinimap = function(self)
    local db = self.Data:GetDB()
    local borderSize = db.borderSize or 1

    EXUI:SetSize(Minimap, db.size, db.size)
    Minimap:ClearAllPoints()
    EXUI:SetPoint(Minimap, db.anchorPoint, UIParent, db.relativeAnchor, db.xOffset, db.yOffset)
    Minimap:Show()
    Minimap:EnableMouse(true)

    if (self.borderContainer) then
        if (borderSize > 0) then
            local borderThickness = EXUI:ScalePixels(borderSize, Minimap)
            local outerSize = db.size + (borderThickness * 2)
            EXUI:SetSize(self.borderContainer, outerSize, outerSize)
            self.borderContainer:ClearAllPoints()
            EXUI:SetPoint(self.borderContainer, 'CENTER', Minimap, 'CENTER', 0, 0)
            if (self.borderContainer.SetFixedFrameStrata) then
                self.borderContainer:SetFixedFrameStrata(true)
                self.borderContainer:SetFrameStrata('BACKGROUND')
            end
            if (self.borderContainer.SetFixedFrameLevel) then
                self.borderContainer:SetFixedFrameLevel(true)
                self.borderContainer:SetFrameLevel(MINIMAP_BORDER_FRAME_LEVEL)
            end
            self.border:SetBorderThickness(borderSize)
            local r, g, b, a = UnpackColor(db.borderColor)
            self.border:SetBorderColor(r, g, b, a)
            self.borderContainer:Show()
        else
            self.borderContainer:Hide()
        end
    end

    self:HideDefaultMinimapChrome()
    self:ApplySquareShape()
    self:SetupBlizzButtonFixes()
    self:ConfigureClickHijack()
    self:RepositionMissionsButton()
end

minimap.RegisterEditorFrames = function(self)
    if (self.editorRegistered) then return end
    self.editorRegistered = true

    local editorOnShow = function(frame)
        frame.editor:SetEditorAsMovable()
    end

    editor:RegisterFrameForEditor(Minimap, 'Minimap', function(frame)
        local point, _, relativePoint, xOfs, yOfs = frame:GetPoint(1)
        self.Data:SetValue('anchorPoint', point)
        self.Data:SetValue('relativeAnchor', relativePoint)
        self.Data:SetValue('xOffset', xOfs)
        self.Data:SetValue('yOffset', yOfs)
        self:ConfigureMinimap()
    end, editorOnShow)
end

minimap.RefreshRuntime = function(self)
    if (not self.enabled) then return end
    self:SetupBlizzButtonFixes()
    self:SuppressBlizzClockFrames()
    self:SuppressMinimapZoomControls()
    self:SuppressMinimapCraftingOrder()
    self:SuppressTrackingButton()
    self:SyncLdbButtons()
    self:ApplyButtons()
    self:ConfigureAddonCompartment()
    self:SetupMinimapMouseHandler()
end

minimap.Configure = function(self)
    if (not self.enabled) then return end
    self:ConfigureMinimap()
    self:ConfigureZoneText()
    self:ConfigureClock()
    self:ApplyButtons()
end

minimap.Enable = function(self)
    if (self.enabled) then return end
    self.enabled = true
    Minimap:EnableMouseWheel(true)
    self:SetupMinimapFrame()
    self:ApplySquareShape()
    self:ApplyHybridMinimap()
    self:Configure()
    self:RefreshRuntime()
end

minimap.Disable = function(self)
    if (not self.enabled) then return end
    self.enabled = false

    if (self.clockTicker) then
        self.clockTicker:Cancel()
        self.clockTicker = nil
    end

    if (self.eventFrame) then
        self.eventFrame:UnregisterAllEvents()
    end

    if (self.zoneFrame) then
        self.zoneFrame:UnregisterAllEvents()
    end

    if (self.drawerButton) then self.drawerButton:Hide() end
    if (self.compartmentButton) then self.compartmentButton:Hide() end
    self:CloseDrawerMenu()
    self:CloseCompartmentMenu()
    if (AddonCompartmentFrame) then AddonCompartmentFrame:Hide() end
    if (self.borderContainer) then self.borderContainer:Hide() end
    if (self.zoneFrame) then self.zoneFrame:Hide() end
    if (self.clockFrame) then self.clockFrame:Hide() end
    self:ClearMinimapMouseHandler()

    if (editor.IsFrameRegistered) then
        if (editor:IsFrameRegistered(Minimap)) then
            editor:UnregisterFrameForEditor(Minimap)
        end
    end

    self.editorRegistered = false
    self.drawerOpen = false
end
