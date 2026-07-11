---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---@class EXUICooldownsItemIdInput
local itemIdInput = EXUI:GetModule('cooldowns-item-id-input')

local SEARCH_DEBOUNCE = 0.2
local INPUT_HEIGHT = 28
local ROW_HEIGHT = 24

local function trim(text)
    if not text then
        return ''
    end
    return (text:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function getProvider()
    return EXUI:GetModule('cooldowns-item-index')
end

local function hideAutocomplete(frame)
    if frame.searchTimer then
        frame.searchTimer:Cancel()
        frame.searchTimer = nil
    end
    local listMenu = EXFrames:GetFrame('list-menu-frame')
    if listMenu and listMenu:IsOpen() and listMenu:GetAnchor() == frame.autocompleteAnchor then
        listMenu:Hide()
    end
end

local function setRowIcon(texture, icon)
    if not texture then
        return
    end
    if not icon then
        texture:Hide()
        return
    end
    texture:Show()
    if C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(icon) then
        texture:SetAtlas(icon)
    else
        texture:SetTexture(icon)
    end
    texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
end

local function updateDisplayValue(frame, entry)
    if entry then
        setRowIcon(frame.selectedIcon, entry.icon)
        frame.selectedName:SetText(string.format('%s (%d)', entry.name or tostring(entry.itemID), entry.itemID))
    else
        setRowIcon(frame.selectedIcon, nil)
        frame.selectedName:SetText('No item selected')
    end
end

local function setSelected(frame, itemID, triggerChange)
    frame.selectedID = itemID and tonumber(itemID) or nil
    local provider = getProvider()
    local entry = provider and frame.selectedID and provider:GetEntry(frame.selectedID) or nil
    updateDisplayValue(frame, entry)

    frame.suppressInputChange = true
    frame.editBox:SetText('')
    frame.suppressInputChange = false

    if triggerChange and frame.onChange and not frame.suppressOnChange then
        frame.onChange(frame.selectedID)
    end
end

local function resolveAndSet(frame, text)
    local provider = getProvider()
    if not provider then
        return
    end
    local itemID = provider:ResolveInput(text)
    if itemID then
        provider:RegisterItemID(itemID)
        setSelected(frame, itemID, true)
    end
end

local function runAutocomplete(frame)
    local provider = getProvider()
    if not provider or not frame.editBox:HasFocus() then
        return
    end

    local text = trim(frame.editBox:GetText())
    if text == '' then
        hideAutocomplete(frame)
        return
    end

    local results = provider:GetAutocompleteResults(text)
    if #results == 0 then
        hideAutocomplete(frame)
        return
    end

    local entries = provider:BuildSearchMenuEntries(results, function(itemID)
        setSelected(frame, itemID, true)
        hideAutocomplete(frame)
    end)
    EXFrames:GetFrame('list-menu-frame'):ShowAt(frame.autocompleteAnchor, entries)
end

local function configureFrame(frame)
    local sectionLabel = frame:CreateFontString(nil, 'OVERLAY')
    sectionLabel:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    sectionLabel:SetPoint('TOPLEFT', 0, 0)
    sectionLabel:SetWidth(0)
    frame.sectionLabel = sectionLabel

    local inputArea = CreateFrame('Frame', nil, frame)
    inputArea:SetPoint('TOPLEFT', sectionLabel, 'BOTTOMLEFT', 0, -4)
    inputArea:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, 0)
    inputArea:SetHeight(INPUT_HEIGHT)
    frame.inputArea = inputArea
    frame.autocompleteAnchor = inputArea

    local bgTex = inputArea:CreateTexture(nil, 'BACKGROUND')
    bgTex:SetTexture(EXFrames.assets.textures.ui.inputBg)
    bgTex:SetVertexColor(unpack(EXFrames.Theme.backgroundDeep))
    bgTex:SetTextureSliceMargins(6, 6, 6, 6)
    bgTex:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    bgTex:SetAllPoints()
    EXFrames:ApplyInputBorder(inputArea, 1)

    local clearBtn = CreateFrame('Button', nil, inputArea)
    clearBtn:SetSize(18, 18)
    clearBtn:SetPoint('RIGHT', inputArea, 'RIGHT', -6, 0)
    local clearText = clearBtn:CreateFontString(nil, 'OVERLAY')
    clearText:SetFont(EXFrames.assets.font.default(), 13, 'OUTLINE')
    clearText:SetPoint('CENTER')
    clearText:SetText('×')
    clearText:SetTextColor(unpack(EXFrames.Theme.danger))
    clearBtn:SetScript('OnClick', function()
        setSelected(frame, nil, true)
    end)

    local input = CreateFrame('EditBox', nil, inputArea)
    frame.editBox = input
    input:SetAutoFocus(false)
    input:SetFont(EXFrames.assets.font.default(), 11, 'OUTLINE')
    input:SetPoint('TOPLEFT', 6, -7)
    input:SetPoint('BOTTOMRIGHT', clearBtn, 'BOTTOMLEFT', -6, 2)
    input:SetJustifyV('MIDDLE')
    input:SetTextInsets(8, 0, 0, 0)

    input:SetScript('OnTextChanged', function(_, changed)
        if not changed or frame.suppressInputChange then
            return
        end
        if frame.searchTimer then
            frame.searchTimer:Cancel()
        end
        frame.searchTimer = C_Timer.NewTimer(SEARCH_DEBOUNCE, function()
            frame.searchTimer = nil
            runAutocomplete(frame)
        end)
    end)

    input:SetScript('OnEscapePressed', function(self)
        hideAutocomplete(frame)
        self:ClearFocus()
    end)

    input:SetScript('OnEnterPressed', function(self)
        resolveAndSet(frame, self:GetText())
        hideAutocomplete(frame)
    end)

    input:SetScript('OnEditFocusGained', function()
        local provider = getProvider()
        if provider then
            provider:EnsureIndex()
        end
    end)

    input:SetScript('OnEditFocusLost', function()
        C_Timer.After(0.05, function()
            if frame.editBox and not frame.editBox:HasFocus() then
                local listMenu = EXFrames:GetFrame('list-menu-frame')
                if listMenu and listMenu:IsOpen() and listMenu:GetAnchor() == frame.autocompleteAnchor then
                    return
                end
                local text = trim(frame.editBox:GetText())
                if text ~= '' then
                    resolveAndSet(frame, text)
                end
                hideAutocomplete(frame)
            end
        end)
    end)

    local selectedRow = CreateFrame('Frame', nil, frame)
    selectedRow:SetPoint('TOPLEFT', inputArea, 'BOTTOMLEFT', 0, -6)
    selectedRow:SetPoint('TOPRIGHT', inputArea, 'BOTTOMRIGHT', 0, -6)
    selectedRow:SetHeight(ROW_HEIGHT)

    local selectedBg = selectedRow:CreateTexture(nil, 'BACKGROUND')
    selectedBg:SetTexture(EXFrames.assets.textures.ui.inputBg)
    selectedBg:SetVertexColor(unpack(EXFrames.Theme.backgroundLight))
    selectedBg:SetTextureSliceMargins(4, 4, 4, 4)
    selectedBg:SetTextureSliceMode(Enum.UITextureSliceMode.Tiled)
    selectedBg:SetAllPoints()

    local selectedIcon = selectedRow:CreateTexture(nil, 'ARTWORK')
    selectedIcon:SetSize(18, 18)
    selectedIcon:SetPoint('LEFT', 4, 0)
    frame.selectedIcon = selectedIcon

    local selectedName = selectedRow:CreateFontString(nil, 'OVERLAY')
    selectedName:SetFont(EXFrames.assets.font.default(), 10, 'OUTLINE')
    selectedName:SetPoint('LEFT', selectedIcon, 'RIGHT', 6, 0)
    selectedName:SetPoint('RIGHT', selectedRow, 'RIGHT', -8, 0)
    selectedName:SetJustifyH('LEFT')
    selectedName:SetWordWrap(false)
    frame.selectedName = selectedName

    frame.SetOptionData = function(self, option)
        self.optionData = option
        self.onChange = option.onChange
        self.sectionLabel:SetText(option.label or 'Item')
        self.suppressOnChange = true
        setSelected(self, option.currentValue and option.currentValue() or nil, false)
        self.suppressOnChange = false
    end

    frame.GetState = function(self)
        return self.selectedID
    end

    frame.SetState = function(self, value)
        setSelected(self, value, false)
    end

    frame.SetFrameWidth = function(self, width)
        self:SetWidth(width)
    end

    frame:SetHeight(64)
end

itemIdInput.Create = function(self)
    local frame = CreateFrame('Frame', nil, UIParent)
    configureFrame(frame)

    frame.Destroy = function(f)
        hideAutocomplete(f)
        f:SetParent(nil)
        f:Hide()
    end

    return frame
end
