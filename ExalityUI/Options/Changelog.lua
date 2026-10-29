---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIChangelog
local changelog = EXUI:GetModule('changelog')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

changelog.window = nil

changelog.Init = function(self)
end

local WHITE = 'Interface\\BUTTONS\\WHITE8X8.blp'
local NEW_COLOR = { 235 / 255, 122 / 255, 52 / 255 }
local FOREVER_COLOR = { 35 / 255, 159 / 255, 199 / 255 }
local FOREVER_ICON = '|TInterface/Addons/ExalityUI/Assets/Images/Generic/wow-forever.png:13:11|t '
local FOREVER_SECTION_ICON = '|TInterface/Addons/ExalityUI/Assets/Images/Generic/wow-forever.png:17:15|t '
local PAD = 6
local LATEST_HEADER_HEIGHT = 34
local HEADER_HEIGHT = 26

local TAG_PALETTE = {
    'f2c879', 'c9a3ff', '84c5f5', '7fd6c6', '98d68f', 'f5a97f', 'f59ab8', 'a9a5f5', 'd9c48c', '9fc7d9',
}

local TAG_COLORS = {
    ['Options'] = 'f2c879',
    ['General'] = 'f2c879',
    ['Misc'] = '9fb0c2',
    ['Auras'] = 'c9a3ff',
    ['Cooldowns'] = '84c5f5',
    ['Resource Displays'] = '7fd6c6',
    ['Unit Frames'] = '98d68f',
    ['Nameplates'] = 'bcd98a',
    ['Action Bars'] = 'f5a97f',
    ['Skins'] = 'f59ab8',
    ['BW Skin'] = 'f59ab8',
    ['Objective Tracker'] = 'e8d47a',
    ['Mythic+ Timer'] = 'e8d47a',
    ['Bags'] = 'f09a8a',
    ['Minimap'] = '8fb3f5',
    ['Character Frame'] = 'a9a5f5',
    ['Profiles'] = 'd6a6e0',
    ['Damage Meters'] = 'f08585',
    ['Pixel Perfect'] = '7fd6c6',
    ['XP Bar'] = 'a9a5f5',
    ['Chat'] = '7fd6c6',
}

local function GetTagColor(tag)
    local color = TAG_COLORS[tag]
    if color then return color end
    local sum = 0
    for i = 1, #tag do
        sum = sum + tag:byte(i)
    end
    return TAG_PALETTE[(sum % #TAG_PALETTE) + 1]
end

local function HexToRGB(hex)
    return tonumber(hex:sub(1, 2), 16) / 255, tonumber(hex:sub(3, 4), 16) / 255, tonumber(hex:sub(5, 6), 16) / 255
end

local function CreateText(parent, size, r, g, b)
    local fs = parent:CreateFontString(nil, 'OVERLAY')
    fs:SetFont(EXUI.const.fonts.DEFAULT, size, 'OUTLINE')
    fs:SetJustifyH('LEFT')
    fs:SetWordWrap(true)
    fs:SetNonSpaceWrap(false)
    fs:SetTextColor(r, g, b, 1)
    return fs
end

local function CreatePillFrame(parent, text, r, g, b, fontSize)
    local pill = CreateFrame('Frame', nil, parent)

    local label = CreateText(pill, fontSize, r, g, b)
    label:SetText(text)
    label:SetJustifyH('CENTER')
    label:SetJustifyV('MIDDLE')
    label:SetWordWrap(false)
    EXUI:SetSize(pill, math.ceil(label:GetStringWidth()) + 10, 15)
    label:SetAllPoints(pill)
    EXUI:EnableNativeRounding(label)

    local bg = pill:CreateTexture(nil, 'ARTWORK')
    bg:SetTexture(WHITE)
    bg:SetVertexColor(r, g, b, 0.18)
    bg:SetAllPoints()
    return pill
end

local function CreatePill(parent, anchor, text, r, g, b)
    local pill = CreatePillFrame(parent, text, r, g, b, 9)
    EXUI:SetPoint(pill, 'LEFT', anchor, 'RIGHT', 10, 0)
    return pill
end

local TAG_GAP = 3
local TAG_COLUMN_GAP = 8

---@param tags string|string[]
---@return Frame[] pills, number maxWidth
local function CreateTagPills(parent, tags)
    if type(tags) == 'string' then
        tags = { tags }
    end
    local pills = {}
    local maxWidth = 0
    for _, tag in ipairs(tags) do
        local r, g, b = HexToRGB(GetTagColor(tag))
        local pill = CreatePillFrame(parent, tag, r, g, b, 10)
        table.insert(pills, pill)
        maxWidth = math.max(maxWidth, pill:GetWidth())
    end
    return pills, maxWidth
end

---Stacks pills right-aligned in the tag column. If the stack is taller than the text, the text gets centered
---on it, otherwise the first pill is centered on the first line.
---@return number rowHeight, number textOffset
local function PlaceTagPills(pills, fs, textHeight)
    local pillHeight = pills[1]:GetHeight()
    local stackHeight = #pills * pillHeight + (#pills - 1) * TAG_GAP
    local textOffset, firstTop, rowHeight = 0, 0, 0

    if stackHeight > textHeight then
        textOffset = (stackHeight - textHeight) / 2
        firstTop = textOffset
        rowHeight = stackHeight
    else
        firstTop = pillHeight / 2 - fs:GetLineHeight() / 2
        rowHeight = math.max(textHeight, stackHeight - firstTop)
    end

    for i, pill in ipairs(pills) do
        pill:ClearAllPoints()
        EXUI:SetPoint(pill, 'TOPRIGHT', fs, 'TOPLEFT', -TAG_COLUMN_GAP, firstTop - (i - 1) * (pillHeight + TAG_GAP))
    end
    return rowHeight, textOffset
end

local function CreateBullet(parent, fs, size, r, g, b, a)
    local tex = parent:CreateTexture(nil, 'ARTWORK')
    tex:SetTexture(WHITE)
    tex:SetVertexColor(r, g, b, a)
    EXUI:SetSize(tex, size, size)
    EXUI:SetPoint(tex, 'CENTER', fs, 'TOPLEFT', -8 - size / 2, -fs:GetLineHeight() / 2)
    return tex
end

local function UpdateHeaderState(group)
    local header = group.header
    header.chevron:SetRotation(group.collapsed and 0 or math.rad(-90))
    local alpha = (group.collapsed and not header:IsMouseOver()) and 0.75 or 1
    header.title:SetAlpha(alpha)
    header.chevron:SetAlpha(alpha)
end

local function CreateHeader(parent, version, isLatest)
    local accent = EXUI.const.colors.accent
    local secondary = EXUI.const.colors.accentSecondary

    local header = CreateFrame('Button', nil, parent)
    header:SetHeight(isLatest and LATEST_HEADER_HEIGHT or HEADER_HEIGHT)

    local chevron = header:CreateTexture(nil, 'OVERLAY')
    chevron:SetTexture(EXUI.const.textures.frame.icons.chevronRight)
    chevron:SetSize(10, 10)
    chevron:SetPoint('LEFT', 0, 0)
    chevron:SetVertexColor(accent[1], accent[2], accent[3], 1)
    header.chevron = chevron

    local title = CreateText(header, isLatest and 20 or 15, accent[1], accent[2], accent[3])
    title:SetText(version.version)
    title:SetWordWrap(false)
    title:SetPoint('LEFT', chevron, 'RIGHT', 8, 0)
    header.title = title
    local last = title

    if version.subtitle then
        local subtitle = CreateText(header, 12, 0.6, 0.6, 0.6)
        subtitle:SetText(version.subtitle)
        subtitle:SetWordWrap(false)
        subtitle:SetPoint('BOTTOMLEFT', title, 'BOTTOMRIGHT', 10, 1)
        last = subtitle
    end
    if isLatest then
        CreatePill(header, last, 'LATEST', secondary[1], secondary[2], secondary[3])
    end

    local divider = header:CreateTexture(nil, 'ARTWORK')
    divider:SetTexture(WHITE)
    divider:SetVertexColor(1, 1, 1, 0.1)
    divider:SetHeight(EXUI:ScalePixels(1, header))
    divider:SetPoint('BOTTOMLEFT')
    divider:SetPoint('BOTTOMRIGHT')

    return header
end

---@param parent Frame
---@return table groups { header: Button, content: Frame, collapsed: boolean, blocks: { fs: FontString, indent: number, spacing: number, after?: number, wrap?: boolean, pills?: Frame[] }[] }[]
local function BuildGroups(parent)
    local groups = {}
    local accent = EXUI.const.colors.accent
    local content, blocks
    local columnBlocks = {}
    local tagColumnWidth = 0

    local function Add(fs, indent, spacing, wrap)
        local block = { fs = fs, indent = indent, spacing = spacing, wrap = wrap }
        table.insert(blocks, block)
        return block
    end

    local function AddParagraph(text, indent)
        local fs = CreateText(content, 11, 0.78, 0.77, 0.75)
        fs:SetText(text)
        Add(fs, indent, 6, true)
    end

    local function AddChange(entry, indent)
        local text, tag, subItems = entry, nil, nil
        if type(entry) == 'table' then
            tag = entry[1]
            text = entry.forever and (FOREVER_ICON .. entry[2]) or entry[2]
            subItems = entry[3]
        end

        local fs = CreateText(content, 11, 0.86, 0.85, 0.83)
        fs:SetText(text)
        if not tag then
            CreateBullet(content, fs, 4, accent[1], accent[2], accent[3], 0.7)
            indent = indent + 14
        end
        local block = Add(fs, indent, 6, true)

        if tag then
            local pills, width = CreateTagPills(content, tag)
            tagColumnWidth = math.max(tagColumnWidth, width)
            block.pills = pills
            table.insert(columnBlocks, block)
        end

        if subItems then
            for _, subText in ipairs(subItems) do
                local subFs = CreateText(content, 11, 0.68, 0.67, 0.65)
                subFs:SetText(subText)
                CreateBullet(content, subFs, 3, 0.55, 0.55, 0.55, 0.8)
                local subBlock = Add(subFs, indent + 16, 3, true)
                if tag then
                    table.insert(columnBlocks, subBlock)
                end
            end
        end
    end

    local function AddChanges(changes, indent)
        if not changes then return end
        for _, entry in ipairs(changes) do
            AddChange(entry, indent)
        end
    end

    for index, version in ipairs(EXUI.GetChangelog and EXUI.GetChangelog() or {}) do
        content = CreateFrame('Frame', nil, parent)
        content:SetAllPoints(parent)
        blocks = {}

        local group = {
            header = CreateHeader(parent, version, index == 1),
            content = content,
            blocks = blocks,
            collapsed = index ~= 1,
        }
        table.insert(groups, group)

        if version.intro then
            for _, text in ipairs(version.intro) do
                AddParagraph(text, PAD)
            end
        end

        AddChanges(version.changes, PAD)

        if version.sections then
            for _, section in ipairs(version.sections) do
                local sectionTitle = CreateText(content, 14, 1, 1, 1)
                sectionTitle:SetText(section.forever and (FOREVER_SECTION_ICON .. section.title) or section.title)
                sectionTitle:SetWordWrap(false)

                local bar = content:CreateTexture(nil, 'ARTWORK')
                bar:SetTexture(WHITE)
                if section.forever then
                    bar:SetVertexColor(FOREVER_COLOR[1], FOREVER_COLOR[2], FOREVER_COLOR[3], 1)
                else
                    bar:SetVertexColor(accent[1], accent[2], accent[3], 1)
                end
                bar:SetWidth(2)
                bar:SetPoint('TOPRIGHT', sectionTitle, 'TOPLEFT', -6, 1)
                bar:SetPoint('BOTTOMRIGHT', sectionTitle, 'BOTTOMLEFT', -6, -1)

                if section.new then
                    CreatePill(content, sectionTitle, 'NEW', NEW_COLOR[1], NEW_COLOR[2], NEW_COLOR[3])
                end
                local sectionBlock = Add(sectionTitle, PAD + 8, 16)
                sectionBlock.after = 2

                if section.text then
                    for _, text in ipairs(section.text) do
                        AddParagraph(text, PAD + 8)
                    end
                end
                AddChanges(section.changes, PAD + 8)
            end
        end

        if version.notes then
            for _, text in ipairs(version.notes) do
                AddParagraph('|cffdb4900Note:|r ' .. text, PAD)
            end
        end

        group.header:SetScript('OnClick', function()
            group.collapsed = not group.collapsed
            changelog:Layout(true)
        end)
        group.header:SetScript('OnEnter', function() UpdateHeaderState(group) end)
        group.header:SetScript('OnLeave', function() UpdateHeaderState(group) end)
    end

    local columnOffset = math.ceil(tagColumnWidth) + TAG_COLUMN_GAP
    for _, block in ipairs(columnBlocks) do
        block.indent = block.indent + columnOffset
    end
    return groups
end

changelog.SetupWindow = function(self)
    local window = EXFrames:GetFrame('window-frame'):Create({
        size = { 600, optionsMain.LAYOUT.window[2] },
        title = 'Changelog'
    })

    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(window.container)
    scrollFrame:SetPoint('TOPLEFT', 0, -10)
    scrollFrame:SetPoint('BOTTOMRIGHT', -5, 10)
    window.scrollFrame = scrollFrame
    window.groups = BuildGroups(scrollFrame.child)

    self.window = window
end

---@param force? boolean
changelog.Layout = function(self, force)
    local window = self.window
    if not window then return end

    local width = window.container:GetWidth() - 10
    if not force and window.layoutWidth == width then return end
    window.layoutWidth = width

    local child = window.scrollFrame.child
    local y = 0
    local prevExpanded = false
    for index, group in ipairs(window.groups) do
        local header = group.header
        y = y + (index == 1 and 4 or (prevExpanded and 28 or 6))
        header:ClearAllPoints()
        header:SetPoint('TOPLEFT', child, 'TOPLEFT', PAD, -y)
        header:SetWidth(width - PAD * 2)
        y = y + header:GetHeight()
        UpdateHeaderState(group)

        group.content:SetShown(not group.collapsed)
        if not group.collapsed then
            y = y + 6
            for _, block in ipairs(group.blocks) do
                local fs = block.fs
                y = y + block.spacing
                if block.wrap then
                    fs:SetWidth(width - block.indent - PAD)
                end
                local rowHeight, textOffset = fs:GetStringHeight(), 0
                if block.pills then
                    rowHeight, textOffset = PlaceTagPills(block.pills, fs, rowHeight)
                end
                fs:ClearAllPoints()
                fs:SetPoint('TOPLEFT', child, 'TOPLEFT', block.indent, -(y + textOffset))
                y = y + rowHeight + (block.after or 0)
            end
        end
        prevExpanded = not group.collapsed
    end

    window.scrollFrame:UpdateScrollChild(width, y + 10)
end

changelog.Show = function(self)
    if not self.window then
        self:SetupWindow()
    end

    self.window:ShowWindow()
    self:Layout()
end
