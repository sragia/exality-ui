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

EXUI.utils = {
    GetItemEnchant = function(itemLink)
        MyScanningTooltip:ClearTooltip()
        MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        MyScanningTooltip:SetHyperlink(itemLink)
        local enchantKey = ENCHANTED_TOOLTIP_LINE:gsub("%%s", "(.+)")
        for i = 1, MyScanningTooltip:NumLines() do
            if _G["ExalityUIScanningTooltipTextLeft" .. i]:GetText() and
                _G["ExalityUIScanningTooltipTextLeft" .. i]:GetText()
                    :match(enchantKey) then
                -- name,id
                local name =
                    _G["ExalityUIScanningTooltipTextLeft" .. i]:GetText()
                name = name:match("^%w+: (.*)")
                local _, _, enchantId = strsplit(":", itemLink)
                return name, enchantId
            end
        end
    end,
    GetItemGems = function(itemLink)
        local t = {}
        for i = 1, MAX_NUM_SOCKETS do
            local name, iLink = C_Item.GetItemGem(itemLink, i)
            if iLink then
                local icon = select(10, C_Item.GetItemInfo(iLink))
                table.insert(t, {name = name, icon = icon})
            end
        end
        MyScanningTooltip:ClearTooltip()
        MyScanningTooltip:SetOwner(UIParent, "ANCHOR_NONE")
        MyScanningTooltip:SetHyperlink(itemLink)
        for i = 1, MAX_NUM_SOCKETS do
            local tex = _G["ExalityUIScanningTooltipTexture" .. i]:GetTexture()
            if tex then
                tex = tostring(tex)
                if tex == '458977' then
                    table.insert(t, {name = "Empty Slot", icon = tex})
                end
            end
        end
        return t
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
    getIlvlColor = function(ilvl)
        if not ilvl then return "ffffffff" end
        local colors = EXUI.const.ilvlColors
        for i = 1, #colors do
            if colors[i].ilvl > ilvl then return colors[i].str end
        end
        return "fffffb26"
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
    addDebugTexture = function(frame)
        local tex = frame:CreateTexture()
        tex:SetTexture(EXUI.const.textures.frame.bg)
        tex:SetTexCoord(0.49, 0.51, 0.49, 0.51)
        tex:SetVertexColor(1, 0, 0, 0.4)
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
    organizeFramesInList = function(children, gap, parentContainer)
        local prev = nil

        for _, child in ipairs_reverse(children) do
            child:ClearAllPoints()
        end 

        for indx, child in ipairs(children) do
            if (not prev) then
                child:SetPoint('TOPLEFT', parentContainer, 'TOPLEFT', 0, -gap)
                child:SetPoint('TOPRIGHT', parentContainer, 'TOPRIGHT', 0, -gap)
            else
                child:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -gap)
                child:SetPoint('TOPRIGHT', prev, 'BOTTOMRIGHT', 0, -gap)
            end
            child:Show()
            prev = child
        end
    end,
    organizeFramesInGrid = function(gridId, children, gap, parentContainer, startOffsetX, startOffsetY)
        local maxWidth = parentContainer:GetWidth() - startOffsetX * 2

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

        local rows = {{}}
        local runningPerc = 100
        for _, child in ipairs(children) do
            local childPerc = child.optionData and child.optionData.width or 25
            if ((runningPerc - childPerc) < 0) then
                table.insert(rows, {child})
                runningPerc = 100 - childPerc
            else
                table.insert(rows[#rows], child)
                runningPerc = runningPerc - childPerc
            end
        end
        local prevRowFrame = nil
        for _, row  in ipairs(rows) do
            local rowFrame = CreateRowFrame(parentContainer)
            table.insert(rowFrames[gridId], rowFrame)
            if (prevRowFrame) then
                rowFrame:SetPoint('TOPLEFT', prevRowFrame, 'BOTTOMLEFT', 0, -gap)
                rowFrame:SetPoint('TOPRIGHT', prevRowFrame, 'BOTTOMRIGHT', 0, -gap)
            else
                rowFrame:SetPoint('TOPLEFT', startOffsetX, -startOffsetY)
                rowFrame:SetPoint('TOPRIGHT', -startOffsetX, -startOffsetY)
            end
            local rowFrames = #row
            local rowMaxWidth = maxWidth - (rowFrames * gap)
            local rowMaxHeight = 0
            local prev = nil
            for _, child in ipairs(row) do
                child:SetParent(rowFrame)
                local perc = child.optionData and child.optionData.width or 25
                child:SetFrameWidth(perc/100 * rowMaxWidth)
                if (prev) then
                    child:SetPoint('TOPLEFT', prev, 'TOPRIGHT', gap, 0)
                else
                    child:SetPoint('TOPLEFT', rowFrame, 'TOPLEFT', 0, 0)
                end
                local childHeight = child:GetHeight()
                if (childHeight > rowMaxHeight) then
                    rowMaxHeight = childHeight
                end
                prev = child
            end

            -- center child in row vertically
            local prevPad = 0
            for _, child in ipairs(row) do
                local childHeight = child:GetHeight()
                local topPad = (rowMaxHeight - childHeight) / 2
                if (prevPad > 0) then
                    topPad = topPad - prevPad
                end
                prevPad = topPad
                local point, relativeTo, relativePoint, xOfs, yOfs = child:GetPoint(1)
                child:SetPoint(point, relativeTo, relativePoint, xOfs, yOfs - topPad)
            end
            rowFrame:SetHeight(rowMaxHeight)
            rowFrame:Show()
            prevRowFrame = rowFrame
        end
    end,
    getPowerTypeColor = function(powerType)
        if (powerType == Enum.PowerType.Mana) then
            return 0, 54/255, 204/255 , 1
        elseif (powerType == Enum.PowerType.Rage) then
            return 181/255, 0, 9/255, 1
        elseif (powerType == Enum.PowerType.Energy) then
            return 230/255, 199/255, 0, 1
        elseif (powerType == Enum.PowerType.Focus) then
            return 1, 157/255, 87/255, 1
        else
            return 230/255, 199/255, 0, 1
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
    end
}
