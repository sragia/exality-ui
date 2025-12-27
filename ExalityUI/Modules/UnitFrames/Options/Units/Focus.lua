---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Focus',
    id = 'focus',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('focus')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('focus', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('focus', 'name')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'powerHeight')
                    end,
                    onChange = function(self, value)
                        ufCore:UpdateValueForUnit('focus', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                    width = 25
                }
            },
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(f, value)
                        ufCore:UpdateValueForUnit('focus', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('focus', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('focus', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('focus', 'debuffs', false)
                end
            }
        },
    }
})
