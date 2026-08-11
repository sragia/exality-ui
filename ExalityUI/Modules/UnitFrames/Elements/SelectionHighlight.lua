---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local core = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesElementsSelectionHighlight
local selectionHighlight = EXUI:GetModule('uf-element-selection-highlight')

local DEFAULT_BORDER = { r = 0, g = 0, b = 0, a = 1 }

local eventsRegistered = false

local function ApplyBorderColor(frame, color)
    local border = frame.ElementFrame and frame.ElementFrame.PPBorder
    if not border then
        return
    end
    border:SetBorderColor(color.r, color.g, color.b, color.a)
end

local function GetUnitToken(frame)
    return frame.displayedUnit or frame.unit
end

selectionHighlight.Update = function(self, frame)
    local db = frame.db
    local border = frame.ElementFrame and frame.ElementFrame.PPBorder
    if not border or not db then
        return
    end

    local unit = GetUnitToken(frame)
    if not unit then
        ApplyBorderColor(frame, DEFAULT_BORDER)
        return
    end

    if db.targetBorderEnable and UnitExists('target') and UnitIsUnit(unit, 'target') then
        ApplyBorderColor(frame, db.targetBorderColor or DEFAULT_BORDER)
        return
    end

    if db.mouseoverBorderEnable and UnitExists('mouseover') and UnitIsUnit(unit, 'mouseover') then
        ApplyBorderColor(frame, db.mouseoverBorderColor or DEFAULT_BORDER)
        return
    end

    ApplyBorderColor(frame, DEFAULT_BORDER)
end

local function UpdateFrameList(frames)
    for _, frame in ipairs(frames) do
        if frame and frame.SelectionHighlight then
            selectionHighlight:Update(frame)
        end
    end
end

local function UpdateAll()
    UpdateFrameList(core.partyFrames)
    UpdateFrameList(core.raidFrames)
end

local function EnsureEvents()
    if eventsRegistered then
        return
    end
    eventsRegistered = true

    local watcher = CreateFrame('Frame')
    watcher:RegisterEvent('PLAYER_TARGET_CHANGED')
    watcher:RegisterEvent('UPDATE_MOUSEOVER_UNIT')
    watcher:SetScript('OnEvent', UpdateAll)
end

selectionHighlight.Create = function(self, frame)
    EnsureEvents()
    return {}
end
