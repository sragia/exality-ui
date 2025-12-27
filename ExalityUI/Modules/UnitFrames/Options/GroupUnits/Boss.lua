---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Boss',
    id = 'boss',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('boss')
                end,
                {
                    type = 'range',
                    label = 'Spacing',
                    name = 'spacing',
                    min = 0,
                    max = 30,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('boss', 'spacing')
                    end,
                    onChange = function(_, value)
                        ufCore:UpdateValueForUnit('boss', 'spacing', value)
                        ufCore:UpdateFrameForUnit('boss')
                    end,
                    width = 20
                }
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('boss', 'nameMaxWidth')
                    end,
                    onChange = function(f, value)
                        ufCore:UpdateValueForUnit('boss', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('boss')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('boss', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('boss', 'name')
                end
            }
        },
        {
            name = 'Health',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('boss', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('boss', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('boss', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('boss', 'healthperc')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('boss', 'powerHeight')
                    end,
                    onChange = function(self, value)
                        ufCore:UpdateValueForUnit('boss', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('boss')
                    end,
                    width = 25
                }
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('boss', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('boss', 'debuffs', false)
                end
            }
        },
    }
})
