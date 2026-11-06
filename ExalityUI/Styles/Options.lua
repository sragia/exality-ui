---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIStyles
local styles = EXUI:GetModule('styles')

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIStylesGuide
local guide = EXUI:GetModule('styles-guide')

---@class EXUIStylesOptions
local stylesOptions = EXUI:GetModule('styles-options')

stylesOptions.NAME = 'Styles'
stylesOptions.hideFromMenu = true
stylesOptions.useSplitView = true
stylesOptions.splitViewItemStyle = 'advanced'
stylesOptions.useInnerTabs = true

local PREVIEW_ICON = 136081
local MISSING_ICON = 134400
local GUIDE_ICON_COLOR = { 0.2, 0.4, 0.75, 1 }
local LIST_BORDER_COLOR = { 0.85, 0.85, 0.85, 1 }

-- Edit boxes report every keystroke, styles are re-applied once typing stops.
local applyTimer
local function scheduleApply(id, refreshList)
    if applyTimer then
        applyTimer:Cancel()
    end
    applyTimer = C_Timer.NewTimer(0.5, function()
        applyTimer = nil
        styles:RegisterCustom(id)
        if refreshList then
            optionsFields:RefreshItemList()
        end
    end)
end

local function selectStyle(id)
    optionsFields:Refresh()
    optionsFields:SetItemID(id)
end

stylesOptions.splitViewExtraButton = {
    actions = {
        {
            icon = 'plus',
            text = 'Create',
            onClick = function()
                selectStyle(styles:CreateCustom())
            end,
        },
        {
            icon = { file = EXUI.const.textures.frame.icons.info, width = 14, color = GUIDE_ICON_COLOR },
            align = 'right',
            tooltip = 'Guide',
            onClick = function()
                guide:Show()
            end,
        },
    },
}

stylesOptions.Init = function(self)
    optionsController:RegisterModule(self)
end

stylesOptions.GetName = function(self)
    return self.NAME
end

stylesOptions.GetOrder = function(self)
    return 25
end

stylesOptions.GetProfileExportSpec = function(self)
    return styles:GetProfileExportSpec()
end

-- Opens this page from pickers elsewhere in the options.
stylesOptions.Open = function(self)
    optionsController:SetSelectedModule(self.NAME)
end

stylesOptions.ContextMenu = function(self, builtin)
    local menu = {
        {
            label = 'Duplicate',
            color = { 2 / 255, 145 / 255, 227 / 255, 1 },
            onClick = function(itemID)
                selectStyle(styles:CreateCustom(itemID))
            end,
        },
    }
    if not builtin then
        table.insert(menu, {
            label = 'Delete',
            color = EXUI.EXFrames.Theme.danger,
            onClick = function(itemID)
                styles:DeleteCustom(itemID)
                optionsFields.currItemID = nil
                optionsFields:Refresh()
            end,
        })
    end
    return menu
end

-- Row icon shows the style the way an aura icon would look with it.
local function iconDecorator(styleID)
    return function(icon, holder)
        local maskPath, borderPath, margins = styles:GetArt(styleID)
        local mask = holder.exuiStyleMask or holder:CreateMaskTexture()
        holder.exuiStyleMask = mask
        mask:SetAllPoints(icon)
        mask:SetTexture(maskPath, 'CLAMPTOBLACKADDITIVE', 'CLAMPTOBLACKADDITIVE')
        -- Same as Shape.lua: Forever squeezes sliced icon masks into a corner
        if EXUI.IsForever() then
            mask:ClearTextureSlice()
        else
            styles:ApplySlices(mask, margins)
        end
        icon:AddMaskTexture(mask)

        local border = holder.exuiStyleBorder or holder:CreateTexture(nil, 'OVERLAY')
        holder.exuiStyleBorder = border
        border:SetAllPoints(icon)
        border:SetTexture(borderPath)
        styles:ApplySlices(border, margins)
        border:SetVertexColor(unpack(LIST_BORDER_COLOR))
        border:Show()

        return function()
            icon:RemoveMaskTexture(mask)
            border:Hide()
        end
    end
end

-- Where a style is the default, for the row's second line.
local function usageText(styleID)
    local used = {}
    for _, target in ipairs(styles:GetTargets()) do
        if target.get() == styleID then
            table.insert(used, target.label)
        end
    end
    return table.concat(used, ', ')
end

stylesOptions.GetSplitViewItems = function(self)
    local items = {}
    local lastGroup
    for _, style in ipairs(styles:List()) do
        local group = style.builtin and 'Built-in' or 'Custom'
        if group ~= lastGroup then
            table.insert(items, { type = 'category', ID = 'category-' .. group, label = group })
            lastGroup = group
        end
        table.insert(items, {
            ID = style.id,
            label = style.name,
            sublabel = usageText(style.id),
            reserveSubtext = true,
            icon = style.mask and PREVIEW_ICON or MISSING_ICON,
            iconDecorator = style.mask and iconDecorator(style.id) or nil,
            contextMenuItems = self:ContextMenu(style.builtin),
        })
    end
    return items
end

local function resolveStyleID(itemID)
    if styles:IsStyle(itemID) then
        return itemID
    end
    local first = styles:List()[1]
    return first and first.id
end

stylesOptions.UpdateOptionsChrome = function(self, fields)
    EXUI:GetModule('options-style-preview'):Show(resolveStyleID(fields.currItemID))
end

stylesOptions.TeardownOptionsChrome = function(self)
    EXUI:GetModule('options-style-preview'):Hide()
end

-- Built-in styles show the same fields as custom ones, read-only.
local function styleFields(id, style)
    local readOnly = style.builtin == true
    local custom = not readOnly and styles:GetCustom(id)

    local function get(key)
        if custom then
            return custom[key]
        end
        return style[key]
    end

    local function set(key, value, refreshList)
        custom[key] = value
        scheduleApply(id, refreshList)
    end

    local function fileField(key, label, tooltip)
        return {
            type = 'edit-box',
            label = label,
            name = key,
            width = 50,
            disabled = readOnly,
            tooltip = { text = tooltip },
            currentValue = function()
                return get(key) or ''
            end,
            onChange = function(value)
                set(key, value)
            end,
        }
    end

    local function marginField(index, side)
        return {
            type = 'range',
            label = side .. ' Margin',
            name = 'margin' .. side,
            min = 0,
            max = 64,
            step = 1,
            width = 25,
            disabled = readOnly,
            currentValue = function()
                return custom and styles:GetCustomMargins(id)[index] or style.margins[index]
            end,
            onChange = function(value)
                styles:GetCustomMargins(id)[index] = value
                scheduleApply(id)
            end,
        }
    end

    local fields = {}
    if readOnly then
        table.insert(fields, {
            type = 'disclaimer',
            width = 100,
            label = 'Built-in style. Duplicate it to make your own version.',
        })
    end
    local rest = {
        {
            type = 'edit-box',
            label = 'Name',
            name = 'name',
            width = 50,
            disabled = readOnly,
            currentValue = function()
                return get('name')
            end,
            onChange = function(value)
                set('name', value, true)
            end,
        },
        { type = 'spacer', width = 50 },
        { type = 'title', label = 'Shape', width = 100, size = 18 },
        fileField('mask', 'Mask File',
            'White shape on a transparent canvas. Everything inside the shape stays visible.'),
        fileField('border', 'Border File',
            'Outline drawn over the edge of the shape, same canvas size as the mask.'),
        {
            type = 'disclaimer',
            width = 100,
            label = 'Margins: pixels from each side of the image that keep their size, the middle stretches. '
                .. 'Use the corner size + 1. Set top and bottom to 0 for slanted sides, all 0 to stretch the whole image.',
        },
        marginField(1, 'Left'),
        marginField(2, 'Top'),
        marginField(3, 'Right'),
        marginField(4, 'Bottom'),
        { type = 'title', label = 'Target Glow (optional)', width = 100, size = 18 },
        {
            type = 'disclaimer',
            width = 100,
            label = 'Used around targeted nameplates. The glow sits outside the plate, so it needs its own art '
                .. 'with a cutout matching your shape. Leave empty to use the default glow.',
        },
        fileField('glow', 'Glow File',
            'Glow band around a cutout. The cutout must match the shape and start Glow Band pixels from the edge.'),
        {
            type = 'range',
            label = 'Glow Band',
            name = 'glowBand',
            min = 1,
            max = 64,
            step = 1,
            width = 50,
            disabled = readOnly,
            tooltip = { text = 'Width of the glow band in pixels, from canvas edge to cutout.' },
            currentValue = function()
                return get('glowBand')
            end,
            onChange = function(value)
                set('glowBand', value)
            end,
        },
    }
    for _, field in ipairs(rest) do
        table.insert(fields, field)
    end
    return fields
end

local function targetFields(id)
    local fields = {
        { type = 'title', label = 'Use This Style', width = 100, size = 18 },
        {
            type = 'disclaimer',
            width = 100,
            label = 'Sets the default style. Units and aura groups with their own style keep it.',
        },
    }
    for _, target in ipairs(styles:GetTargets()) do
        table.insert(fields, {
            type = 'checkbox',
            label = target.label,
            name = 'target-' .. target.id,
            width = 50,
            currentValue = function()
                return target.get() == id
            end,
            onChange = function(value)
                target.set(value and id or styles.NONE)
                optionsFields:RefreshItemList()
            end,
        })
    end
    return fields
end

stylesOptions.GetSectionTabs = function(self, itemID)
    if not styles:IsStyle(resolveStyleID(itemID)) then
        return {}
    end
    return {
        { ID = 'style', label = 'Style' },
        { ID = 'usage', label = 'Usage' },
    }
end

stylesOptions.GetOptions = function(self, tabID, itemID)
    itemID = resolveStyleID(itemID)
    local style = styles:Get(itemID)
    if not style then
        return {}
    end
    if tabID == 'usage' then
        return targetFields(itemID)
    end
    return styleFields(itemID, style)
end
