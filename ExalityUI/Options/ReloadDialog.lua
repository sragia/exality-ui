---@class ExalityUI
local EXUI = select(2, ...)

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

---------

---@class EXUIOptionsReloadDialog
local optionsReloadDialog = EXUI:GetModule('options-reload-dialog')

optionsReloadDialog.dialog = nil

optionsReloadDialog.Init = function(self)
    EXUI.utils.addObserver(self)
    self.dialog = EXFrames:GetFrame('dialog-frame'):Create()
    self.dialog:SetText('Reload UI to apply changes.')
    self.dialog:SetButtons({
        {
            text = 'Reload UI',
            onClick = function()
                ReloadUI()
            end,
            color = { 25 / 255, 120 / 255, 0, 1 }
        },
        {
            text = 'Will Reload Later',
            onClick = function()
                self.dialog:HideDialog()
            end,
            color = { 158 / 255, 0, 32 / 255, 1 }
        }
    })
end

optionsReloadDialog.ShowDialog = function(self)
    self.dialog:ShowDialog()
end
