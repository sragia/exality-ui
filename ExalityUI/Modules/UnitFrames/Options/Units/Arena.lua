---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Arena',
    id = 'arena',
    allowPreview = true,
    menu = {
        {
            name = 'General',
            id = 'general',
            options = {
                function()
                    return EXUI:GetModule('uf-options-general-frame'):GetOptions('arena')
                end
            }
        },
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('arena')
                end,
                {
                    type = 'range',
                    label = 'Spacing',
                    name = 'spacing',
                    min = 0,
                    max = 30,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('arena', 'spacing')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('arena', 'spacing', value)
                        ufCore:UpdateFrameForUnit('arena')
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
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('arena', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('arena', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('arena')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('arena', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('arena', 'name')
                end
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('arena', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('arena', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('arena', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('arena', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('arena')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('arena', 'powerHeight')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('arena', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('arena')
                    end,
                    width = 25
                }
            }
        },
        {
            name = 'Cast Bar',
            id = 'castbar',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'castbar')
                end,
                function()
                    return EXUI:GetModule('uf-options-cast-bar'):GetOptions('arena')
                end
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('arena', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('arena', 'debuffs', false)
                end
            }
        },
        {
            name = 'Custom Auras',
            id = 'auras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('arena', 'auras', false, true)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('arena')
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('arena', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('arena', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('arena', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('arena')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('arena', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('arena')
                end
            }
        }
    }
})
