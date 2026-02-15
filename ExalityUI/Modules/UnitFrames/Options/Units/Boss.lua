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
            name = 'General',
            id = 'general',
            options = {
                function()
                    return EXUI:GetModule('uf-options-general-frame'):GetOptions('boss')
                end
            }
        },
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
                    onChange = function(value)
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
                    onChange = function(value)
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
            name = 'Health Text',
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
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('boss')
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
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('boss', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('boss')
                    end,
                    width = 25
                }
            }
        },
        {
            name = 'Cast Bar',
            id = 'castbar',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'castbar')
                end,
                function()
                    return EXUI:GetModule('uf-options-cast-bar'):GetOptions('boss')
                end
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('boss', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('boss', 'debuffs', false)
                end
            }
        },
        {
            name = 'Custom Auras',
            id = 'auras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('boss', 'auras', false, true)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('boss', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('boss')
                end
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('boss')
                end
            }
        }
    }
})
