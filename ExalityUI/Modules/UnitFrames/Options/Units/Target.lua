---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Target',
    id = 'target',
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function() 
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('target')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function() 
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'nameMaxWidth')
                    end,
                    onChange = function(f,value)
                        ufCore:UpdateValueForUnit('target', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function() 
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('target', 'name')
                end,
                function() 
                    return EXUI:GetModule('uf-options-tag'):GetOptions('target', 'name')
                end
            }
        },
        {
            name = 'Health',
            id = 'health',
            options = {
                function() 
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'health')
                end,
                function() 
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('target', 'health')
                end,
                function() 
                    return EXUI:GetModule('uf-options-tag'):GetOptions('target', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function() 
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'healthperc')
                end,
                function() 
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('target', 'healthperc')
                end,
                function() 
                    return EXUI:GetModule('uf-options-tag'):GetOptions('target', 'healthperc')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function() 
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'powerHeight')
                    end,
                    onChange = function(self, value)
                        ufCore:UpdateValueForUnit('target', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                    width = 25
                }
            }
        }
    }
})