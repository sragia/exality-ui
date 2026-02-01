---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIChangelog
local changelog = EXUI:GetModule('changelog')

changelog.window = nil

changelog.Init = function(self)
end

---Parse simple markdown (# ## -) into display blocks
---@param text string
---@return table blocks {type: string, text: string}[]
local function parseMarkdown(text)
    local blocks = {}
    local lines = {}

    for line in (text or ''):gmatch('[^\r\n]+') do
        table.insert(lines, line)
    end

    for _, line in ipairs(lines) do
        local trimmed = line:match('^%s*(.-)%s*$')
        if trimmed == '' then
            table.insert(blocks, { type = 'spacer', text = '' })
        elseif trimmed:match('^#%s+(.+)$') then
            table.insert(blocks, { type = 'h1', text = trimmed:match('^#%s+(.+)$') })
        elseif trimmed:match('^##%s+(.+)$') then
            table.insert(blocks, { type = 'h2', text = trimmed:match('^##%s+(.+)$') })
        elseif trimmed:match('^%-%s+(.+)$') then
            table.insert(blocks, { type = 'list', text = trimmed:match('^%-%s+(.+)$') })
        else
            table.insert(blocks, { type = 'paragraph', text = trimmed })
        end
    end

    return blocks
end

changelog.SetupWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 500, 600 },
        title = 'Changelog'
    })

    local scrollFrame = EXFrames:GetFrame('scroll-frame'):Create()
    scrollFrame:SetParent(window.container)
    scrollFrame:SetPoint('TOPLEFT', 0, -10)
    scrollFrame:SetPoint('BOTTOMRIGHT', -30, 10)
    window.scrollFrame = scrollFrame

    local child = scrollFrame.child
    local font = EXUI.const.fonts.DEFAULT
    local blocks = parseMarkdown(EXUI.changelog or '')
    local textFrames = {}

    for _, block in ipairs(blocks) do
        local textFrame = child:CreateFontString(nil, 'OVERLAY')
        textFrame:SetJustifyH('LEFT')
        textFrame:SetWordWrap(true)
        textFrame:SetNonSpaceWrap(false)

        if block.type == 'h1' then
            textFrame:SetFont(font, 20, 'OUTLINE')
            textFrame:SetTextColor(1, 0.9, 0.6, 1)
            textFrame:SetText(block.text)
        elseif block.type == 'h2' then
            textFrame:SetFont(font, 16, 'OUTLINE')
            textFrame:SetTextColor(1, 1, 1, 1)
            textFrame:SetText(block.text)
        elseif block.type == 'list' then
            textFrame:SetFont(font, 12, 'OUTLINE')
            textFrame:SetTextColor(0.85, 0.85, 0.85, 1)
            textFrame:SetText('  • ' .. block.text)
        elseif block.type == 'spacer' then
            textFrame:SetFont(font, 6, 'OUTLINE')
            textFrame:SetText(' ')
        else
            textFrame:SetFont(font, 10, 'OUTLINE')
            textFrame:SetTextColor(0.85, 0.85, 0.85, 1)
            textFrame:SetText(block.text)
        end

        table.insert(textFrames, textFrame)
    end

    local gap = 6
    EXUI.utils.organizeFramesInList(textFrames, gap, child)
    window.changelogTextFrames = textFrames
    window.changelogGap = gap

    self.window = window
end

changelog.UpdateScrollHeight = function(self)
    local window = self.window
    if not window then return end

    local width = window.container:GetWidth() - 30
    local viewportHeight = window.container:GetHeight() - 20

    window.scrollFrame:UpdateScrollChild(width, viewportHeight)
end

changelog.Show = function(self)
    if not self.window then
        self:SetupWindow()
    end

    self.window:ShowWindow()
    self:UpdateScrollHeight()
end
