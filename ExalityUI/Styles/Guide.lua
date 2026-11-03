---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUIStylesGuide
local guide = EXUI:GetModule('styles-guide')

guide.window = nil

local WIDTH = 560
local PADDING = 14
local BULLET_INDENT = 14
local LINE_GAP = 6

-- `text` in a line is drawn as a highlighted file name or value.
local SECTIONS = {
    {
        title = 'Where files go',
        lines = {
            'Put your images in `World of Warcraft\\_retail_\\Interface\\Styles\\`.',
            'In the style, type just the file name, e.g. `my-mask.png`.',
            'A full path like `Interface\\AddOns\\MyMedia\\mask.tga` works too.',
            'New files need a full game restart. Changes to existing files only need a `/reload`.',
        },
    },
    {
        title = 'File format',
        lines = {
            '32-bit `PNG` or `TGA` with an alpha channel.',
            'Draw in white. Colors come from the border color settings.',
            'Small canvases like `16x16` or `32x32` work well for masks and borders.',
        },
    },
    {
        title = 'Mask',
        lines = {
            'The shape itself: white where things stay visible, transparent where they get cut away.',
            'Straight edges should touch the canvas edges.',
        },
    },
    {
        title = 'Border',
        lines = {
            'An outline of the same shape, on the same canvas size, usually `1px` wide.',
            'Transparent inside. Make it from the mask so the two line up.',
        },
    },
    {
        title = 'Margins',
        lines = {
            'Images are cut into 9 parts: corners keep their size, the middle stretches.',
            'Each margin is how many pixels from that side belong to a corner, so every corner can differ.',
            'Use the corner size `+ 1`, and keep left + right and top + bottom smaller than the canvas.',
            'Slanted sides: set left and right to the slant width, top and bottom to `0`.',
            'All margins `0` stretches the whole image. Works for any shape, but distorts with the frame size.',
            'Corners are drawn in screen pixels, so they stay the same size on every frame.',
        },
    },
    {
        title = 'Target Glow (optional)',
        lines = {
            'The nameplate target glow sits outside the plate, so it needs its own image.',
            'Draw a soft glow band around a cutout that matches your shape.',
            'Glow Band is the distance from the canvas edge to the cutout.',
            'The glow image must be `512x96`. It uses the style\'s margins plus the band.',
            'Leave it empty to use the default glow.',
        },
    },
    {
        title = 'Examples and sharing',
        lines = {
            'Built-in styles: `Interface\\AddOns\\ExalityUI\\Assets\\Images\\UnitFrames\\Masks\\`.',
            'Built-in glows: `Interface\\AddOns\\ExalityUI\\Assets\\Images\\Nameplates\\`.',
            'Duplicate a built-in style to start from working values.',
            'Profile exports include your styles, but not the image files. Share those separately.',
        },
    },
}

local function colorCode(color)
    return string.format('|cff%02x%02x%02x', color[1] * 255, color[2] * 255, color[3] * 255)
end

local function highlight(text)
    local code = colorCode(EXFrames.Theme.accentLight)
    return (text:gsub('`(.-)`', code .. '%1|r'))
end

local function CreateFont(parent, size)
    local font = parent:CreateFontString(nil, 'OVERLAY')
    font:SetFont(EXFrames.assets.font.default(), size, 'OUTLINE')
    font:SetJustifyH('LEFT')
    return font
end

local function CreateIntro(parent)
    local intro = CreateFrame('Frame', nil, parent)
    intro:SetWidth(WIDTH)

    local title = CreateFont(intro, 18)
    title:SetPoint('TOPLEFT')
    title:SetText('Making your own styles')
    title:SetTextColor(unpack(EXFrames.Theme.white))

    local subtitle = CreateFont(intro, 11)
    subtitle:SetPoint('TOPLEFT', title, 'BOTTOMLEFT', 0, -6)
    subtitle:SetWidth(WIDTH)
    subtitle:SetText('A style is a mask and a border image, plus margins that say how they stretch. '
        .. 'Styles can be used on unit frames, nameplates, cast bars and aura icons.')
    subtitle:SetTextColor(unpack(EXFrames.Theme.textMuted))

    intro:SetHeight(title:GetStringHeight() + subtitle:GetStringHeight() + 6)
    return intro
end

local function CreateCard(parent, index, section)
    local card = EXFrames:GetFrame('panel-frame'):Create()
    card:SetParent(parent)
    card:SetSubtleChrome()
    card:SetWidth(WIDTH)

    local number = CreateFont(card, 14)
    number:SetPoint('TOPLEFT', PADDING, -PADDING)
    number:SetText(string.format('%02d', index))
    number:SetTextColor(unpack(EXFrames.Theme.accentLight))

    local title = CreateFont(card, 14)
    title:SetPoint('LEFT', number, 'RIGHT', 8, 0)
    title:SetText(section.title)
    title:SetTextColor(unpack(EXFrames.Theme.white))

    local textWidth = WIDTH - PADDING * 2 - BULLET_INDENT
    local height = PADDING + number:GetStringHeight() + 10
    local prev
    for _, line in ipairs(section.lines) do
        local bullet = card:CreateTexture(nil, 'OVERLAY')
        bullet:SetColorTexture(unpack(EXFrames.Theme.accentLight))
        bullet:SetSize(4, 4)

        local text = CreateFont(card, 11)
        text:SetWidth(textWidth)
        text:SetText(highlight(line))
        text:SetTextColor(unpack(EXFrames.Theme.text))
        if prev then
            text:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -LINE_GAP)
            height = height + LINE_GAP
        else
            text:SetPoint('TOPLEFT', number, 'BOTTOMLEFT', BULLET_INDENT, -10)
        end
        bullet:SetPoint('TOPRIGHT', text, 'TOPLEFT', -8, -4)
        height = height + text:GetStringHeight()
        prev = text
    end

    card:SetHeight(height + PADDING)
    return card
end

guide.Create = function(self)
    self.window = EXFrames:GetFrame('window-frame'):Create({
        size = { 620, 600 },
        title = 'Styles Guide'
    })
    local container = self.window.container
    local scrollFrame = EXFrames:GetFrame('smooth-scroll-frame'):Create()
    scrollFrame:SetParent(container)
    scrollFrame:SetPoint('TOPLEFT', 10, -10)
    scrollFrame:SetPoint('BOTTOMRIGHT', -5, 10)
    self.window.scrollFrame = scrollFrame

    local items = { CreateIntro(scrollFrame.child) }
    for index, section in ipairs(SECTIONS) do
        table.insert(items, CreateCard(scrollFrame.child, index, section))
    end
    EXUI.utils.organizeFramesInList(items, 12, scrollFrame.child)
end

guide.Show = function(self)
    if (not self.window) then
        self:Create()
    end

    self.window:ShowWindow()
    self.window.scrollFrame:UpdateScrollChild(self.window.container:GetWidth() - 20,
        self.window.container:GetHeight() - 20)
end
