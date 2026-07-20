---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUISkins
local skins = EXUI:GetModule('skins')

---@class EXUIQuestLogSkin
local questLogSkin = EXUI:GetModule('skin-QuestLog')

local PANEL_BG_ALPHA = 0.9
local ROW_HIGHLIGHT_ALPHA = 0.5

local function GetTheme()
    return EXUI.const.theme
end

local function StripQuestLogBorder(borderFrame)
    if (not borderFrame) then return end
    skins:StripRegions(borderFrame, { 'Border', 'TopDetail', 'Shadow' })
end

local function SkinQuestListSeparator(separator)
    if (not separator) then return end
    local divider = separator.Divider
    if (not divider) then return end

    if (not divider.exuiSkinned) then
        divider.exuiSkinned = true
        skins:StripTexture(divider)
        divider:SetTexture(EXUI.const.textures.frame.solidBg)
        divider:Show()
        divider:ClearAllPoints()
        divider:SetHeight(EXUI:ScalePixel(1, separator, 1))
        divider:SetPoint('LEFT', separator, 'LEFT', 2, 0)
        divider:SetPoint('RIGHT', separator, 'RIGHT', -2, 0)
    end

    divider:SetVertexColor(unpack(GetTheme().border))
end

local function SkinQuestsList(questsFrame)
    local scrollFrame = questsFrame and questsFrame.ScrollFrame
    if (not scrollFrame) then return end
    local th = GetTheme()

    -- Main parchment + ornate border; the list text (gold) reads fine on dark.
    skins:StripRegions(scrollFrame, { 'Background', 'Edge' })
    StripQuestLogBorder(scrollFrame.BorderFrame)
    skins:SkinMinimalScrollBar(scrollFrame.ScrollBar)

    if (scrollFrame.SearchBox) then
        skins:SkinSearchBox(scrollFrame.SearchBox)
    end

    local contents = scrollFrame.Contents
    if (contents) then
        if (contents.StoryHeader and not contents.StoryHeader.exuiSkinned) then
            contents.StoryHeader.exuiSkinned = true
            skins:StripRegions(contents.StoryHeader, { 'Background', 'HighlightTexture' })
            skins:AddBackdrop(contents.StoryHeader, { color = th.backgroundPanel })
        end
        if (contents.Separator) then
            SkinQuestListSeparator(contents.Separator)
        end
    end
end

local function SkinDetailsFrame(details)
    if (not details or details.exuiSkinned) then return end
    details.exuiSkinned = true

    -- Keep details.Bg (parchment) and the rewards band: Blizzard renders the quest
    -- description in dark parchment fonts; going dark here needs a font recolor pass.
    skins:StripRegions(details, { 'SealMaterialBG' })
    StripQuestLogBorder(details.BorderFrame)

    if (details.BackFrame) then
        skins:StripAllTextures(details.BackFrame)
        skins:SkinPanelButton(details.BackFrame.BackButton)
    end

    for _, key in ipairs({ 'AbandonButton', 'ShareButton', 'TrackButton' }) do
        local button = details[key]
        if (button) then
            skins:StripAtlasRegions(button, 'UI-Frame-BtnDivMiddle')
            skins:SkinPanelButton(button)
        end
    end

    if (details.ScrollFrame) then
        skins:SkinMinimalScrollBar(details.ScrollFrame.ScrollBar)
    end
end

local function SkinSessionManagement(sessionManagement)
    if (not sessionManagement or sessionManagement.exuiSkinned) then return end
    sessionManagement.exuiSkinned = true

    skins:StripRegions(sessionManagement, { 'BG' })
    skins:AddBackdrop(sessionManagement, { color = GetTheme().backgroundPanel })
end

---Recolor the pooled quest rows' yellow hover glow to the theme accent.
function questLogSkin:RestyleListRows()
    local scrollFrame = QuestScrollFrame
    local contents = scrollFrame and scrollFrame.Contents
    if (not contents) then return end

    local th = GetTheme()
    for _, child in ipairs({ contents:GetChildren() }) do
        local highlight = child.HighlightTexture
        if (highlight and not child.exuiRowStyled and highlight.SetDesaturated) then
            child.exuiRowStyled = true
            highlight:SetDesaturated(true)
            highlight:SetVertexColor(th.accent[1], th.accent[2], th.accent[3], ROW_HIGHLIGHT_ALPHA)
        end
    end
end

local function SkinPopupDetailFrame()
    local popup = QuestLogPopupDetailFrame
    if (not popup or popup.exuiSkinned) then return end
    popup.exuiSkinned = true

    skins:SkinPanelFrame(popup, { hidePortrait = true, backdropAlpha = PANEL_BG_ALPHA })

    for _, key in ipairs({ 'AbandonButton', 'TrackButton', 'ShareButton' }) do
        skins:SkinPanelButton(popup[key])
    end

    if (popup.ScrollFrame) then
        skins:SkinMinimalScrollBar(popup.ScrollFrame.ScrollBar)
    end
end

function questLogSkin:SkinFrame()
    local questMap = QuestMapFrame
    if (not questMap) then return end
    local th = GetTheme()

    skins:AddBackdrop(questMap, { color = th.background, alpha = PANEL_BG_ALPHA })

    -- 1px divider against the map canvas; the outer window border covers the rest.
    if (not questMap.exuiSeparator) then
        local separator = questMap:CreateTexture(nil, 'OVERLAY')
        separator:SetTexture(EXUI.const.textures.frame.solidBg)
        separator:SetPoint('TOPLEFT')
        separator:SetPoint('BOTTOMLEFT')
        separator:SetWidth(EXUI:ScalePixel(1, questMap, 1))
        questMap.exuiSeparator = separator
    end
    questMap.exuiSeparator:SetVertexColor(unpack(th.border))

    SkinQuestsList(questMap.QuestsFrame)
    if (questMap.QuestsFrame) then
        SkinDetailsFrame(questMap.QuestsFrame.DetailsFrame)
    end
    SkinSessionManagement(questMap.QuestSessionManagement)
    SkinPopupDetailFrame()
end

function questLogSkin:InstallHooks()
    if (self.hooksInstalled) then return end
    self.hooksInstalled = true

    -- Rows are pooled and refreshed wholesale; restyle new ones after each update.
    if (type(QuestLogQuests_Update) == 'function') then
        hooksecurefunc('QuestLogQuests_Update', function()
            self:RestyleListRows()
        end)
    end
end

function questLogSkin:Install()
    if (self.installed or not QuestMapFrame) then return end
    self.installed = true

    self:InstallHooks()
    self:SkinFrame()
    self:RestyleListRows()
end

questLogSkin.Init = function(self)
    if (not skins:IsEnabled('WorldMap')) then return end

    if (QuestMapFrame) then
        self:Install()
        return
    end

    EXUI:RegisterEventHandler('ADDON_LOADED', 'skin-QuestLog', function(_, addon)
        if (addon ~= 'Blizzard_UIPanels_Game') then return end
        self:Install()
    end)
end
