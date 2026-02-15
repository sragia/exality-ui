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
            name = 'General',
            id = 'general',
            options = {
                function()
                    return EXUI:GetModule('uf-options-general-frame'):GetOptions('focus')
                end
            }
        },
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
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('focus', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('focus', 'name')
                end
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('focus', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('focus', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('focus', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('focus', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('focus')
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
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                    width = 25
                }
            },
        },
        {
            name = 'Buffs',
            id = 'buffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('focus', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('focus', 'debuffs', false)
                end
            }
        },
        {
            name = 'Custom Auras',
            id = 'auras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('focus', 'auras', false, true)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('focus')
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            allowPreview = true,
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
                    onChange = function(value)
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
            name = 'Raid Role Icons',
            id = 'raidroles',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('focus', 'raidRoles')
                end,
            }
        },
        {
            name = 'Offline Text',
            id = 'offline',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('focus', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('focus', 'offline')
                end
            }
        },
        {
            name = 'Resurrect Indicator',
            id = 'resurrectindicator',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'ressurect')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'ressurectScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'ressurectScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'ressurectScale', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('focus', 'ressurect')
                end,
            }
        },
        {
            name = 'Summon Indicator',
            id = 'summonindicator',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'summon')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'summonScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'summonScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'summonScale', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('focus', 'summon')
                end,
            }
        },
        {
            name = 'Phase Indicator',
            id = 'phaseindicator',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('focus', 'phaseIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'phaseIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('focus', 'phaseIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('focus', 'phaseIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('focus')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('focus', 'phaseIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('focus')
                end
            }
        }
    }
})
