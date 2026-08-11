---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICharacterFrameTitles
local titles = EXUI:GetModule('character-frame-titles')

---@class EXUICharacterFrameWindow
local characterFrame = EXUI:GetModule('character-frame-window')

titles.container = nil
titles.selectedId = -1
titles.buttons = {}
titles.scrollFrame = nil

local ROW_HEIGHT = 22
local ROW_GAP = 3

local function GetKnownPlayerTitles()
    local playerTitles = {}
    playerTitles[1] = {
        name = PLAYER_TITLE_NONE or 'None',
        id = -1,
    }

    local titleCount = 1
    for i = 1, GetNumTitles() do
        if IsTitleKnown(i) then
            local tempName, playerTitle = GetTitleName(i)
            if tempName and playerTitle then
                titleCount = titleCount + 1
                playerTitles[titleCount] = {
                    name = strtrim(tempName),
                    id = i,
                }
            end
        end
    end

    table.sort(playerTitles, function(a, b)
        if a.id == -1 then
            return true
        end
        if b.id == -1 then
            return false
        end
        return a.name < b.name
    end)
    playerTitles[1].name = PLAYER_TITLE_NONE or 'None'

    return playerTitles
end

local function ApplyRowVisual(button, selected, hovered)
    local theme = EXUI.const.theme
    if selected then
        button.border:SetBorderColor(unpack(theme.accent))
        button.border:SetBorderThickness(2)
        button.bg:SetVertexColor(theme.backgroundLight[1], theme.backgroundLight[2], theme.backgroundLight[3], 0.9)
    elseif hovered then
        button.border:SetBorderColor(0.55, 0.55, 0.55, 1)
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0.2, 0.2, 0.2, 0.7)
    else
        button.border:SetBorderColor(unpack(theme.border))
        button.border:SetBorderThickness(1)
        button.bg:SetVertexColor(0, 0, 0, 0.55)
    end
end

titles.CreateRow = function(self, parent)
    local button = CreateFrame('Button', nil, parent)
    button:SetHeight(ROW_HEIGHT)

    button.bg = button:CreateTexture(nil, 'BACKGROUND')
    button.bg:SetTexture(EXUI.const.textures.frame.solidBg)
    button.bg:SetAllPoints()

    button.border = EXUI:AddPixelPerfectBorder(button, 1, { register = false })

    button.Text = button:CreateFontString(nil, 'OVERLAY')
    button.Text:SetFont(EXUI.const.fonts.DEFAULT, 12, 'OUTLINE')
    button.Text:SetPoint('LEFT', 8, 0)
    button.Text:SetPoint('RIGHT', -8, 0)
    button.Text:SetJustifyH('LEFT')
    button.Text:SetWordWrap(false)

    button:SetScript('OnEnter', function(btn)
        ApplyRowVisual(btn, btn.titleId == titles.selectedId, true)
    end)
    button:SetScript('OnLeave', function(btn)
        ApplyRowVisual(btn, btn.titleId == titles.selectedId, false)
    end)
    button:SetScript('OnClick', function(btn)
        PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_OFF)
        SetCurrentTitle(btn.titleId)
        titles.selectedId = btn.titleId
        titles:RefreshSelection()
        C_Timer.After(0, function()
            if characterFrame.window and characterFrame.window:IsShown() then
                characterFrame:UpdateHeader()
            end
        end)
    end)

    return button
end

titles.RefreshSelection = function(self)
    for _, button in ipairs(self.buttons) do
        if button:IsShown() then
            ApplyRowVisual(button, button.titleId == self.selectedId, false)
        end
    end
end

titles.UpdateScroll = function(self)
    if not self.scrollFrame then
        return
    end
    local width = math.max(1, self.scrollFrame:GetWidth())
    local height = math.max(1, self.scrollChild:GetHeight())
    self.scrollFrame:UpdateScrollChild(width, height)
end

titles.Update = function(self)
    if not self.container or not self.container:IsShown() then
        return
    end

    local currentTitle = GetCurrentTitle()
    if currentTitle > 0 and currentTitle <= GetNumTitles() and IsTitleKnown(currentTitle) then
        self.selectedId = currentTitle
    else
        self.selectedId = -1
    end

    local playerTitles = GetKnownPlayerTitles()
    local content = self.scrollChild
    local y = -2

    for i, titleInfo in ipairs(playerTitles) do
        local button = self.buttons[i]
        if not button then
            button = self:CreateRow(content)
            self.buttons[i] = button
        end

        button.titleId = titleInfo.id
        button.Text:SetText(titleInfo.name)
        button:ClearAllPoints()
        button:SetPoint('TOPLEFT', content, 'TOPLEFT', 2, y)
        button:SetPoint('TOPRIGHT', content, 'TOPRIGHT', -2, y)
        button:Show()
        ApplyRowVisual(button, titleInfo.id == self.selectedId, false)

        y = y - ROW_HEIGHT - ROW_GAP
    end

    for i = #playerTitles + 1, #self.buttons do
        self.buttons[i]:Hide()
    end

    content:SetHeight(math.max((-y) + 4, 1))
    self:UpdateScroll()
end

titles.Create = function(self, container)
    self.container = container

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 0, 0)
    scrollFrame:SetPoint('BOTTOMRIGHT', 0, 0)
    self.scrollFrame = scrollFrame
    self.scrollChild = scrollFrame.child

    scrollFrame:HookScript('OnSizeChanged', function()
        if container:IsShown() then
            titles:Update()
        end
    end)

    container:SetScript('OnShow', function()
        titles:Update()
    end)

    container:RegisterEvent('KNOWN_TITLES_UPDATE')
    container:RegisterEvent('UNIT_NAME_UPDATE')
    container:SetScript('OnEvent', function(_, event, unit)
        if event == 'UNIT_NAME_UPDATE' and unit ~= 'player' then
            return
        end
        titles:Update()
        if characterFrame.window and characterFrame.window:IsShown() then
            characterFrame:UpdateHeader()
        end
    end)
end
