---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Target',
    id = 'target',
    allowPreview = true,
    menu = {
        {
            name = 'General',
            id = 'general',
            options = {
                function()
                    return EXUI:GetModule('uf-options-general-frame'):GetOptions('target')
                end
            }
        },
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
                    onChange = function(value)
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
            name = 'Health Text',
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
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('target')
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
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('target')
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
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'castbar')
                end,
                function()
                    return EXUI:GetModule('uf-options-cast-bar'):GetOptions('target')
                end
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('target', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('target', 'debuffs', false)
                end
            }
        },
        {
            name = 'Custom Auras',
            id = 'auras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('target', 'auras', false, true)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            allowPreview = true,
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('target')
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('target', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Raid Role Icons',
            id = 'raidroles',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('target', 'raidRoles')
                end,
            }
        },
        {
            name = 'Combat Icon',
            id = 'combatindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'combatIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'combatIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'combatIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'combatIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('target', 'combatIndicator')
                end
            }
        },
        {
            name = 'Offline Text',
            id = 'offline',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('target', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('target', 'offline')
                end
            }
        },
        {
            name = 'Summon Indicator',
            id = 'summonindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'summon')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'summonScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'summonScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'summonScale', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('target', 'summon')
                end,
            }
        },
        {
            name = 'Phase Indicator',
            id = 'phaseindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('target', 'phaseIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'phaseIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('target', 'phaseIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('target', 'phaseIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('target')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('target', 'phaseIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('target')
                end
            }
        }
    }
})
