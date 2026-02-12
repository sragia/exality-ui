---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

core:AddOption({
    name = 'Player',
    id = 'player',
    menu = {
        {
            name = 'General',
            id = 'general',
            options = {
                function()
                    return EXUI:GetModule('uf-options-general-frame'):GetOptions('player')
                end
            }
        },
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('player')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('player', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('player', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('player')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('player', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('player', 'name')
                end,
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('player', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('player', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('player', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('player', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('player')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('player', 'powerHeight')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('player', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('player')
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
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'castbar')
                end,
                function()
                    return EXUI:GetModule('uf-options-cast-bar'):GetOptions('player')
                end
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('player', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('player', 'debuffs', false)
                end
            }
        },
        {
            name = 'Custom Auras',
            id = 'auras',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('player', 'auras', false, true)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('player')
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('player', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('player', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('player')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('player', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Raid Role Icons',
            id = 'raidroles',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('player', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('player', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('player')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('player', 'raidRoles')
                end,
            }
        },
        {
            name = 'Combat Icon',
            id = 'combatindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('player', 'combatIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'combatIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('player', 'combatIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('player', 'combatIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('player')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('player', 'combatIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('player')
                end
            }
        }
    }
})
