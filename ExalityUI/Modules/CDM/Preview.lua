---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

---@class EXUIOptionsMain
local optionsMain = EXUI:GetModule('options-main')

---@class EXUICDMData
local data = EXUI:GetModule('cdm-data')

---@class EXUICDMPreview
local preview = EXUI:GetModule('cdm-preview')

-- Only the item or group selected in options is previewed, so a big setup never shows all at once.

local MODULE_NAME = 'Cooldown Manager'

function preview:Init()
    local function sync()
        preview:Sync()
    end
    optionsController:Observe('selectedModule', sync)
    hooksecurefunc(optionsFields, 'RefreshFields', sync)
    hooksecurefunc(optionsFields, 'Refresh', sync)
    hooksecurefunc(optionsMain, 'Show', function()
        preview:HookWindow(optionsMain.window)
        sync()
    end)
end

function preview:HookWindow(window)
    if not window or self.hookedWindow == window then
        return
    end
    self.hookedWindow = window
    window:HookScript('OnShow', function()
        preview:Sync()
    end)
    window:HookScript('OnHide', function()
        preview:Sync()
    end)
end

function preview:GetSelection()
    local window = optionsMain.window
    if not window or not window:IsShown() or optionsController:GetSelectedModuleName() ~= MODULE_NAME then
        return nil
    end
    return data:GetNode(optionsFields.currItemID) and optionsFields.currItemID or nil
end

function preview:IsPreviewed(id)
    return self.selected ~= nil and data:Contains(self.selected, id)
end

-- Groups holding the selection have to stay shown too, or they would hide it.
function preview:IsShownForPreview(id)
    return self.selected ~= nil and (data:Contains(self.selected, id) or data:Contains(id, self.selected))
end

function preview:Sync()
    local selected = self:GetSelection()
    if selected == self.selected then
        return
    end
    self.selected = selected
    local cdm = EXUI:GetModule('cdm')
    if self.ticker then
        self.ticker:Cancel()
        self.ticker = nil
    end
    if selected then
        self.ticker = C_Timer.NewTicker(EXUI:GetModule('cdm-element').PREVIEW_LOOP, function()
            cdm:RestartPreviews()
        end)
    end
    cdm:ApplyPreview()
end
