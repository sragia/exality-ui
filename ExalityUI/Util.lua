---@class ExalityUI
local EXUI = select(2, ...)

local randCharSet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
local rowFramePool = CreateFramePool('Frame', UIParent)
local rowFrames = {}

-- Proper base64 decoder for Lua
local function decodeBase64(encodedString)
    -- Base64 character set
    local b64chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local b64dec = {}
    for i = 1, #b64chars do
        b64dec[string.sub(b64chars, i, i)] = i - 1
    end

    -- Remove any whitespace and padding
    encodedString = encodedString:gsub("%s+", "")

    -- Add padding if needed
    local padding = 4 - (#encodedString % 4)
    if padding < 4 then
        encodedString = encodedString .. string.rep("=", padding)
    end

    -- Decode base64
    local result = {}
    local i = 1
    while i <= #encodedString do
        local a = b64dec[encodedString:sub(i, i)] or 0
        local b = b64dec[encodedString:sub(i + 1, i + 1)] or 0
        local c = b64dec[encodedString:sub(i + 2, i + 2)] or 0
        local d = b64dec[encodedString:sub(i + 3, i + 3)] or 0

        table.insert(result, string.char(bit.lshift(a, 2) + bit.rshift(b, 4)))
        if encodedString:sub(i + 2, i + 2) ~= "=" then
            table.insert(result, string.char(bit.lshift(bit.band(b, 15), 4) + bit.rshift(c, 2)))
        end
        if encodedString:sub(i + 3, i + 3) ~= "=" then
            table.insert(result, string.char(bit.lshift(bit.band(c, 3), 6) + d))
        end

        i = i + 4
    end

    return table.concat(result)
end

-- Simple JSON to Lua table converter
local function jsonToLuaTable(jsonString)
    -- Convert JSON to Lua table format manually
    local luaString = jsonString

    -- Convert arrays
    luaString = luaString:gsub('%[', '{'):gsub('%]', '}')

    -- Convert objects
    luaString = luaString:gsub('"([^"]+)"%s*:%s*"([^"]*)"', '["%1"] = "%2"')
    luaString = luaString:gsub('"([^"]+)"%s*:%s*{', '["%1"] = {')
    luaString = luaString:gsub('"([^"]+)"%s*:%s*([^,}]+)', '["%1"] = %2')

    -- Convert boolean values
    luaString = luaString:gsub('true', 'true'):gsub('false', 'false')
    luaString = luaString:gsub('null', 'nil')

    -- Convert empty strings in arrays
    luaString = luaString:gsub('""', '""')

    -- Try to load and execute
    local success, result = pcall(function()
        return loadstring('return ' .. luaString)()
    end)

    if success then
        return result
    else
        print("Failed to parse as Lua:", result)
        return nil
    end
end

local function CreateRowFrame(parent)
    local frame = rowFramePool:Acquire()
    frame.Destroy = function(self)
        rowFramePool:Release(self)
    end
    frame:SetParent(parent)

    return frame
end

local MyScanningTooltip = CreateFrame("GameTooltip", "ExalityUIScanningTooltip",
    UIParent, "GameTooltipTemplate")

function MyScanningTooltip.ClearTooltip(self)
    local TooltipName = self:GetName()
    self:ClearLines()
    for i = 1, 10 do
        _G[TooltipName .. "Texture" .. i]:SetTexture(nil)
        _G[TooltipName .. "Texture" .. i]:ClearAllPoints()
        _G[TooltipName .. "Texture" .. i]:SetPoint("TOPLEFT", self)
    end
end

local enchantNameCache = {}
local gemResultCache = {}
local gemResultScratch = {}
local gemPendingCallbacks = {}

local function resolveEnchantName(itemLink, enchantId)
    MyScanningTooltip:ClearTooltip()
    MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
    MyScanningTooltip:SetHyperlink(itemLink)
    local enchantKey = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
    for i = 1, MyScanningTooltip:NumLines() do
        local line = _G["ExalityUIScanningTooltipTextLeft" .. i]:GetText()
        if line and line:match(enchantKey) then
            return line:match("^%w+: (.*)")
        end
    end
end

local function snapshotGemScratch()
    local copy = {}
    for i = 1, #gemResultScratch do
        copy[i] = gemResultScratch[i]
    end
    return copy
end

local function copyGemsToScratch(source)
    wipe(gemResultScratch)
    for i = 1, #source do
        gemResultScratch[i] = source[i]
    end
    return gemResultScratch
end

local function canContinueOnItemLoad(item)
    return item and not item:IsItemEmpty() and item:GetItemID()
end

local function fireGemReady(itemLink)
    local pending = gemPendingCallbacks[itemLink]
    gemPendingCallbacks[itemLink] = nil
    if not pending then
        return
    end
    for i = 1, #pending do
        pending[i]()
    end
end

local function buildItemGems(itemLink)
    wipe(gemResultScratch)
    local emptyIcon = EXUI.const.textures.characterFrame.gem.empty
    local complete = true

    local parentItem = Item:CreateFromItemLink(itemLink)
    if not parentItem:IsItemDataCached() then
        complete = false
    end

    local socketCount = C_Item.GetItemNumSockets(itemLink) or 0
    local maxIndex = math.max(socketCount, MAX_NUM_SOCKETS)
    for i = 1, maxIndex do
        local gemID = C_Item.GetItemGemID(itemLink, i)
        if gemID then
            local icon = C_Item.GetItemIconByID(gemID)
            local name, iLink = C_Item.GetItemGem(itemLink, i)
            if not icon or not iLink then
                complete = false
            end
            gemResultScratch[#gemResultScratch + 1] = {
                name = name,
                icon = icon,
                iLink = iLink,
                gemID = gemID,
            }
        elseif i <= socketCount then
            gemResultScratch[#gemResultScratch + 1] = {
                name = "Empty Slot",
                icon = emptyIcon,
            }
        end
    end

    local snapshot = snapshotGemScratch()
    if complete then
        gemResultCache[itemLink] = snapshot
    end
    return snapshot, complete
end

local function requestGemData(itemLink)
    local parentItem = Item:CreateFromItemLink(itemLink)
    if not canContinueOnItemLoad(parentItem) then
        gemPendingCallbacks[itemLink] = nil
        return
    end

    local function tryRebuild()
        if not gemPendingCallbacks[itemLink] then
            return
        end

        local _, complete = buildItemGems(itemLink)
        if complete then
            fireGemReady(itemLink)
            return
        end

        if not parentItem:IsItemDataCached() then
            parentItem:ContinueOnItemLoad(tryRebuild)
            return
        end

        local requested = false
        local socketCount = C_Item.GetItemNumSockets(itemLink) or 0
        local maxIndex = math.max(socketCount, MAX_NUM_SOCKETS)
        for i = 1, maxIndex do
            local gemID = C_Item.GetItemGemID(itemLink, i)
            if gemID then
                local gemItem = Item:CreateFromItemID(gemID)
                if canContinueOnItemLoad(gemItem) and not gemItem:IsItemDataCached() then
                    requested = true
                    gemItem:ContinueOnItemLoad(tryRebuild)
                end
            end
        end

        if not requested then
            gemPendingCallbacks[itemLink] = nil
        end
    end

    if not parentItem:IsItemDataCached() then
        parentItem:ContinueOnItemLoad(tryRebuild)
    else
        tryRebuild()
    end
end

EXUI.utils = {
    GetItemEnchant = function(itemLink)
        if not itemLink then
            return
        end
        local _, _, enchantId = strsplit(":", itemLink)
        enchantId = tonumber(enchantId)
        if not enchantId or enchantId == 0 then
            return
        end
        if enchantNameCache[enchantId] ~= nil then
            local cached = enchantNameCache[enchantId]
            return cached ~= false and cached or nil, enchantId
        end
        local name = resolveEnchantName(itemLink, enchantId)
        enchantNameCache[enchantId] = name or false
        return name, enchantId
    end,
    GetItemGems = function(itemLink, onReady)
        if not itemLink then
            return gemResultScratch
        end
        local cached = gemResultCache[itemLink]
        local complete = cached ~= nil
        if not cached then
            cached, complete = buildItemGems(itemLink)
        end
        copyGemsToScratch(cached)

        if onReady and not complete then
            local pending = gemPendingCallbacks[itemLink]
            if pending then
                pending[#pending + 1] = onReady
            else
                gemPendingCallbacks[itemLink] = { onReady }
                requestGemData(itemLink)
            end
            local nowCached = gemResultCache[itemLink]
            if nowCached then
                copyGemsToScratch(nowCached)
            end
        end

        return gemResultScratch
    end,
    createSimpleText = function(textValue, size, textAlign, parent, maxwidth)
        local frame = CreateFrame('Frame')
        frame:SetSize(1, 1)
        local text = frame:CreateFontString(nil, 'OVERLAY')
        text:SetWidth(maxwidth or 0)
        text:SetJustifyH(textAlign or 'LEFT')
        text:SetFont(EXUI.const.fonts.DEFAULT, size or 12, 'OUTLINE')
        text:SetPoint(textAlign or 'LEFT')
        if (textValue) then text:SetText(textValue) end
        frame.SetText = function(self, value) text:SetText(value) end
        if (parent) then frame:SetParent(parent) end
        return frame
    end,
    getIlvlInfo = function(ilvl)
        local colors = EXUI.const.ilvlColors
        local result = colors[1]
        if ilvl then
            for i = 1, #colors do
                if ilvl >= colors[i].ilvl then
                    result = colors[i]
                else
                    break
                end
            end
        end
        return result
    end,
    getIlvlColor = function(ilvl)
        return EXUI.utils.getIlvlInfo(ilvl).color
    end,
    isEmpty = function(t)
        for _ in pairs(t) do
            return false
        end
        return true
    end,
    spairs = function(t, order)
        -- collect the keys
        local keys = {}
        for k in pairs(t) do
            keys[#keys + 1] = k
        end

        -- if order function given, sort by it by passing the table and keys a, b,
        -- otherwise just sort the keys
        if order then
            table.sort(
                keys,
                function(a, b)
                    return order(t, a, b)
                end
            )
        else
            table.sort(keys)
        end

        -- return the iterator function
        local i = 0
        return function()
            i = i + 1
            if keys[i] then
                return keys[i], t[keys[i]]
            end
        end
    end,
    getKeys = function(t)
        local keys = {}
        for k in pairs(t) do
            keys[#keys + 1] = k
        end
        return keys
    end,
    append = function(target, source)
        if not target or not source then
            return target
        end
        for _, value in ipairs(source) do
            target[#target + 1] = value
        end
        return target
    end,
    deepCloneTable = function(orig)
        local orig_type = type(orig)
        local copy
        if orig_type == 'table' then
            copy = {}
            for orig_key, orig_value in next, orig, nil do
                copy[EXUI.utils.deepCloneTable(orig_key)] = EXUI.utils.deepCloneTable(orig_value)
            end
            setmetatable(copy, EXUI.utils.deepCloneTable(getmetatable(orig)))
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end,
    degToRad = function(degrees)
        return degrees * math.pi / 180
    end,
    animation = {
        getAnimationGroup = function(f)
            return f:CreateAnimationGroup();
        end,
        fade = function(f, duration, from, to, ag)
            ag = ag or f:CreateAnimationGroup()
            local fade = ag:CreateAnimation('Alpha')
            fade:SetFromAlpha(from or 0)
            fade:SetToAlpha(to or 1)
            fade:SetDuration(duration or 1)
            fade:SetSmoothing((from > to) and 'OUT' or 'IN')
            local finishScript = ag:GetScript('OnFinished')
            ag:SetScript(
                'OnFinished',
                function(...)
                    if (finishScript) then finishScript(...) end
                    f:SetAlpha(to)
                end
            )
            return ag
        end,
        diveIn = function(f, duration, xOff, yOff, smoothing, ag)
            ag = ag or f:CreateAnimationGroup()
            local translate = ag:CreateAnimation('Translation')
            translate:SetOffset(xOff, -yOff)
            translate:SetDuration(duration)
            translate:SetSmoothing(smoothing)
            ag:SetScript('OnPlay', function()
                if (smoothing == 'OUT') then
                    return
                end

                for i = 1, f:GetNumPoints() do
                    local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
                    f:SetPoint(point, relativeTo, relativePoint, xOfs + xOff, yOfs + yOff)
                end
            end)
            local finishScript = ag:GetScript('OnFinished')
            ag:SetScript('OnFinished', function(...)
                if (finishScript) then finishScript(...) end

                if (smoothing == 'OUT') then
                    return
                end

                for i = 1, f:GetNumPoints() do
                    local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
                    f:SetPoint(point, relativeTo, relativePoint, xOfs - xOff, yOfs - yOff)
                end
            end)

            return ag
        end,
        move = function(f, duration, xOff, yOff, ag)
            ag = ag or f:CreateAnimationGroup()
            local translate = ag:CreateAnimation('Translation')
            translate:SetOffset(xOff, yOff)
            translate:SetDuration(duration)
            local finishScript = ag:GetScript('OnFinished')
            ag:SetScript('OnFinished', function(...)
                if (finishScript) then finishScript(...) end

                for i = 1, f:GetNumPoints() do
                    local point, relativeTo, relativePoint, xOfs, yOfs = f:GetPoint(i)
                    f:SetPoint(point, relativeTo, relativePoint, xOfs + xOff, yOfs + yOff)
                end
            end)

            return ag
        end
    },
    addObserver = function(t, force)
        if (t.observable and not force) then
            return t
        end

        t.observable = {}
        t.Observe = function(_, key, onChangeFunc)
            if (type(key) == 'table') then
                for _, k in ipairs(key) do
                    t.observable[k] = t.observable[k] or {}
                    table.insert(t.observable[k], onChangeFunc)
                end
            else
                t.observable[key] = t.observable[key] or {}
                table.insert(t.observable[key], onChangeFunc)
            end
        end
        t.SetValue = function(self, key, value)
            local oldValue = t[key]
            t[key] = value
            if (t.observable[key]) then
                for _, func in ipairs(t.observable[key]) do
                    func(value, oldValue, key, self)
                end
            end
            if (t.observable['']) then
                for _, func in ipairs(t.observable['']) do
                    func(value, oldValue, key, self)
                end
            end
        end
        t.ObserveAll = function(_, onChangeFunc)
            t.observable[''] = t.observable[''] or {}
            table.insert(t.observable[''], onChangeFunc)
        end

        t.ClearObservable = function(self)
            self.observable = {}
        end

        return t
    end,
    printOut = function(outputString)
        print("|cffc334eb[ExalityUI]|r " .. outputString)
    end,
    addDebugTexture = function(frame, r, g, b, a)
        local tex = frame:CreateTexture()
        tex:SetTexture(EXUI.const.textures.frame.bg)
        tex:SetTexCoord(0.49, 0.51, 0.49, 0.51)
        tex:SetVertexColor(r or 1, g or 0, b or 0, a or 0.4)
        tex:SetAllPoints()
    end,
    debugWithDevTools = function(data)
        C_Timer.After(1, function()
            if (not DevTool) then
                print('DEBUG no devtool')
                return
            end
            if (DevTool.AddData) then
                DevTool:AddData(data)
            elseif (DevTool_AddData) then
                DevTool_AddData(data)
            else
                print('Devtool Available but no AddData function')
            end
        end)
    end,
    suggestMatch = function(userInput, source)
        local suggestions = {}
        for _, data in pairs(source) do
            local matchinString = (data.id or '')
            local matchStart, matchEnd = string.find(string.lower(matchinString), string.lower(userInput), 1, true)
            if matchStart ~= nil then
                table.insert(suggestions,
                    {
                        str = matchinString,
                        score = matchEnd - matchStart + 1 + (matchStart - 1) / #matchinString,
                        data = data
                    })
            else
                local words = {}
                for word in string.gmatch(string.lower(userInput), '%S+') do
                    table.insert(words, word)
                end
                local pattern = ''
                for j = 1, #words do
                    pattern = pattern .. words[j] .. '%S*'
                end
                local phraseStart, phraseEnd = string.find(string.lower(matchinString), pattern, 1, true)
                if phraseStart ~= nil then
                    table.insert(suggestions, {
                        str = matchinString,
                        score = phraseEnd - phraseStart + 1 +
                            (phraseStart - 1) / #matchinString,
                        data = data
                    })
                end
            end
        end
        table.sort(suggestions, function(a, b) return a.score < b.score end)
        return suggestions
    end,
    switch = function(condition, cases)
        return (cases[condition] or cases.default)()
    end,
    generateRandomString = function(length)
        length = length or 10
        local output = ""
        for i = 1, length do
            local rand = math.random(#randCharSet)
            output = output .. string.sub(randCharSet, rand, rand)
        end
        return output
    end,
    compareSemver = function(v1, v2)
        -- -1 - older
        -- 0 - equal
        -- 1 - newer
        local function splitVersion(version)
            return version:match("(%d+)%.(%d+)%.(%d+)")
        end

        local major1, minor1, patch1 = splitVersion(v1)
        local major2, minor2, patch2 = splitVersion(v2)
        if (not tonumber(major1) or not tonumber(major2)) then
            return 0
        end

        if tonumber(major1) > tonumber(major2) then
            return 1
        elseif tonumber(major1) < tonumber(major2) then
            return -1
        else
            if tonumber(minor1) > tonumber(minor2) then
                return 1
            elseif tonumber(minor1) < tonumber(minor2) then
                return -1
            else
                if tonumber(patch1) > tonumber(patch2) then
                    return 1
                elseif tonumber(patch1) < tonumber(patch2) then
                    return -1
                else
                    return 0
                end
            end
        end
    end,
    decodeFromGoogleSheets = function(encodedString)
        -- Decode base64
        local decoded = decodeBase64(encodedString)
        if not decoded or #decoded == 0 then
            print("Failed to decode base64")
            return nil
        end

        -- Convert JSON to Lua table
        local success, data = pcall(function()
            return jsonToLuaTable(decoded)
        end)

        if not success or not data then
            print("JSON parsing failed")
            print("Error:", data)
            return nil
        end

        return data
    end,
    arrayIndexForvalue = function(arr, value)
        for index, val in ipairs(arr) do
            if val == value then
                return index + 1
            end
        end
        return nil
    end,
    findGroupForPlayer = function(playerName)
        for i = 1, GetNumGroupMembers() do
            local name, _, group = GetRaidRosterInfo(i)
            if (Ambiguate(name, 'short') == playerName) then
                return group
            end
        end
    end,
    organizeFramesInList = function(children, gap, parentContainer, gapX, noAnchoring)
        local prev = nil
        gapX = gapX or 0

        for _, child in ipairs_reverse(children) do
            child:ClearAllPoints()
        end

        local currentY = 0
        for indx, child in ipairs(children) do
            if (not prev) then
                child:SetPoint('TOPLEFT', parentContainer, 'TOPLEFT', gapX, -gap)
                child:SetPoint('TOPRIGHT', parentContainer, 'TOPRIGHT', -gapX, -gap)
                currentY = (2 * -gap) - child:GetHeight()
            else
                if (noAnchoring) then
                    child:SetPoint('TOPLEFT', parentContainer, 'TOPLEFT', gapX, currentY)
                    child:SetPoint('TOPRIGHT', parentContainer, 'TOPRIGHT', -gapX, currentY)
                else
                    child:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -gap)
                    child:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -gap)
                end

                currentY = currentY - (child:GetHeight() + gap)
            end
            child:Show()
            prev = child
        end
    end,
    organizeFramesInGrid = function(gridId, children, gap, parentContainer, startOffsetX, startOffsetY)
        gap = EXUI:ScalePixel(gap, parentContainer)
        startOffsetX = EXUI:ScalePixel(startOffsetX or 0, parentContainer)
        startOffsetY = EXUI:ScalePixel(startOffsetY or 0, parentContainer)
        local maxWidth = EXUI:ScalePixel(math.max(1, parentContainer:GetWidth() - startOffsetX * 2), parentContainer)

        if (rowFrames[gridId]) then
            for _, frame in ipairs(rowFrames[gridId]) do
                frame:Destroy()
            end
            rowFrames[gridId] = {}
        else
            rowFrames[gridId] = {}
        end
        for _, child in ipairs_reverse(children) do
            child:ClearAllPoints()
        end

        local rows = { {} }
        local runningPerc = 100
        for _, child in ipairs(children) do
            local childPerc = child.optionData and child.optionData.width or 25
            if ((runningPerc - childPerc) < 0) then
                table.insert(rows, { child })
                runningPerc = 100 - childPerc
            else
                table.insert(rows[#rows], child)
                runningPerc = runningPerc - childPerc
            end
        end
        local prevRowFrame = nil

        local totalHeight = startOffsetY
        for i, row in ipairs(rows) do
            local rowFrame = CreateRowFrame(parentContainer)
            table.insert(rowFrames[gridId], rowFrame)
            if (prevRowFrame) then
                rowFrame:SetPoint('TOPLEFT', prevRowFrame, 'BOTTOMLEFT', 0, -gap)
                rowFrame:SetPoint('TOPRIGHT', prevRowFrame, 'BOTTOMRIGHT', 0, -gap)
            else
                rowFrame:SetPoint('TOPLEFT', startOffsetX, -startOffsetY)
                rowFrame:SetPoint('TOPRIGHT', -startOffsetX, -startOffsetY)
            end
            local numCols = #row
            local rowMaxWidth = maxWidth - (numCols * gap)
            local rowMaxHeight = 0
            local prev = nil
            for _, child in ipairs(row) do
                child:SetParent(rowFrame)
                local perc = child.optionData and child.optionData.width or 25
                child:SetFrameWidth(EXUI:ScalePixel(perc / 100 * rowMaxWidth, parentContainer))
                if (prev) then
                    child:SetPoint('LEFT', prev, 'RIGHT', gap, 0)
                    child:SetPoint('TOP', 0, 0)
                else
                    child:SetPoint('LEFT')
                    child:SetPoint('TOP')
                end
                local childHeight = child:GetHeight()
                if (childHeight > rowMaxHeight) then
                    rowMaxHeight = childHeight
                end
                prev = child
            end

            rowMaxHeight = EXUI:ScalePixel(rowMaxHeight, parentContainer)

            -- vertically align children within the row (default: center)
            for _, child in ipairs(row) do
                local childHeight = child:GetHeight()
                local align = child.optionData and child.optionData.align or 'CENTER'
                local topPad = 0
                if align == 'BOTTOM' then
                    topPad = rowMaxHeight - childHeight
                elseif align == 'TOP' then
                    topPad = 0
                else
                    topPad = math.floor((rowMaxHeight - childHeight) / 2)
                end
                topPad = EXUI:ScalePixel(topPad, parentContainer)
                child:SetPoint('TOP', 0, -topPad)
            end
            rowFrame:SetHeight(rowMaxHeight)
            rowFrame:Show()
            prevRowFrame = rowFrame
            totalHeight = totalHeight + rowMaxHeight
            if i < #rows then
                totalHeight = totalHeight + gap
            end
        end

        if parentContainer and parentContainer.exuiAutoSizeHeight then
            parentContainer:SetHeight(EXUI:ScalePixel(totalHeight + startOffsetY, parentContainer))
        end
    end,
    getPowerTypeColor = function(powerType)
        if (powerType == Enum.PowerType.Mana) then
            return 0, 54 / 255, 204 / 255, 1
        elseif (powerType == Enum.PowerType.Rage) then
            return 181 / 255, 0, 9 / 255, 1
        elseif (powerType == Enum.PowerType.Energy) then
            return 230 / 255, 199 / 255, 0, 1
        elseif (powerType == Enum.PowerType.Focus) then
            return 1, 157 / 255, 87 / 255, 1
        else
            return 230 / 255, 199 / 255, 0, 1
        end
    end,
    getJustifyHFromAnchor = function(anchor)
        if (string.find(anchor, 'LEFT')) then
            return 'LEFT'
        elseif (string.find(anchor, 'RIGHT')) then
            return 'RIGHT'
        elseif (string.find(anchor, 'CENTER')) then
            return 'CENTER'
        end
        return 'LEFT'
    end,
    capitalize = function(str)
        return str:gsub('^%l', string.upper)
    end,
    combineArrays = function(...)
        local output = {}
        for _, array in ipairs(...) do
            tAppendAll(output, array)
        end
        return output
    end,
    getTexCoords = function(width, height, zoom)
        zoom = zoom or 0
        local zoomReduction = (zoom / 100) / 2
        if (width > height) then
            local ratio = 1 - (height / width)
            return 0 + zoomReduction, 1 - zoomReduction, 0 + zoomReduction + ratio / 2, 1 - zoomReduction - ratio / 2
        else
            local ratio = 1 - (width / height)
            return 0 + zoomReduction + ratio / 2, 1 - zoomReduction - ratio / 2, 0 + zoomReduction, 1 - zoomReduction
        end
    end,
    formatTime = function(seconds, excludeSeconds)
        local hours = math.floor(seconds / 3600)
        local minutes = math.floor((seconds % 3600) / 60)
        local seconds = seconds % 60
        if (hours > 0) then
            if (excludeSeconds) then
                return string.format('%dh %dm', hours, minutes)
            else
                return string.format('%dh %dm %ds', hours, minutes, seconds)
            end
        elseif (minutes > 0) then
            if (excludeSeconds) then
                return string.format('%dm', minutes)
            else
                return string.format('%dm %ds', minutes, seconds)
            end
        else
            -- Ignore excludeseconds as that's all we have left
            return string.format('%ds', seconds)
        end
    end,
    formatNumber = function(number)
        if not number then return "0" end
        local absNum = math.abs(number)
        if absNum >= 1e9 then
            return string.format("%.2fB", number / 1e9)
        elseif absNum >= 1e6 then
            return string.format("%.2fM", number / 1e6)
        elseif absNum >= 1e3 then
            return string.format("%.2fK", number / 1e3)
        else
            return tostring(math.floor(number + 0.5))
        end
    end,
    formatNumberWithCommas = function(value)
        if (not value) then
            return 0
        end
        local k
        local formatted = value
        while true do
            formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", "%1,%2")
            if (k == 0) then
                break
            end
        end
        return formatted
    end,
    spreadTable = function(target, source)
        for _, value in ipairs(source) do
            table.insert(target, value)
        end

        return target
    end,
    nextFrame = function(func)
        C_Timer.After(0, function()
            func()
        end)
    end
}
