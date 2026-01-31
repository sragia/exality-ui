---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Pet',
    id = 'pet',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('pet')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('pet', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('pet', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('pet', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('pet')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('pet', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('pet', 'name')
                end
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('pet', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('pet', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('pet', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('pet', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('pet', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('pet', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('pet')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('pet', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('pet', 'powerHeight')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('pet', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('pet')
                    end,
                    width = 25
                }
            },
        },
        {
            name = 'Buffs',
            id = 'buffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('pet', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('pet', 'debuffs', false)
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('pet', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('pet', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('pet', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('pet')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('pet', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('pet')
                end
            }
        }
    }
})
