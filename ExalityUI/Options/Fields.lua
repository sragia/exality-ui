---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIOptionsController
local optionsController = EXUI:GetModule('options-controller')

-------------

---@class EXUIOptionsFields
local optionsFields = EXUI:GetModule('options-fields')

optionsFields.container = nil
optionsFields.fields = {}

optionsFields.Init = function(self)
    EXUI.utils.addObserver(self)

    optionsController:Observe('selectedModule', function(value)
        self:Refresh()
    end)
end

optionsFields.Create = function(self, container)
    self.container = container

    self:Refresh()
end

optionsFields.Refresh = function(self)
    local currentModule = optionsController:GetSelectedModule()

    for _, field in pairs(self.fields) do
        field:Destroy()
    end
    self.fields = {}

    if (currentModule) then
        local fields = currentModule:GetOptions()
        for _, field in ipairs(fields) do
            local fieldFrame = self:GetField(field)
            if (fieldFrame) then
                fieldFrame:SetOptionData(field)
                table.insert(self.fields, fieldFrame)
            end
        end
    end

    EXUI.utils.organizeFramesInGrid('fields', self.fields, 10, self.container, 10, 10)
end

optionsFields.GetField = function(self, field)
    return EXUI.utils.switch(field.type, {
        ['editbox'] = function()
            local f = EXUI:GetModule('edit-box-input'):Create({
                label = 'Edit Box',
                onChange = field.onChange,
                initial = field.currentValue and field.currentValue() or nil,
            })
            f:SetHeight(40)
            return f
        end,
        ['range'] = function()
            local f = EXUI:GetModule('range-input'):Create()
            f:SetOnChange(field.onChange)
            return f
        end,
        ['button'] = function()
            local f = EXUI:GetModule('button'):Create()
            return f
        end,
        ['toggle'] = function()
            local f = EXUI:GetModule('toggle'):Create({
                text = field.label,
                value = field.currentValue and field.currentValue() or false,
            })
            f:Observe('value', field.onObserve)
            return f
        end,
        ['dropdown'] = function()
            local f = EXUI:GetModule('dropdown'):Create({})
            return f
        end,
        ['spacer'] = function()
            local f = EXUI:GetModule('spacer'):Create()
            return f
        end,
        ['color-picker'] = function()
            local f = EXUI:GetModule('color-picker'):Create()
            return f
        end,
        ['title'] = function()
            local f = EXUI:GetModule('title'):Create()
            return f
        end,
        ['description'] = function()
            local f = EXUI:GetModule('description'):Create()
            return f
        end,
        default = function()
            EXUI.utils.printOut('Unknown Field Type: ' .. field.type)    
        end
    })
end
