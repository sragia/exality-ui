---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Party',
    id = 'party',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('party')
                end,
                {
                    type = 'range',
                    label = 'Spacing',
                    name = 'spacing',
                    min = -30,
                    max = 30,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'spacing')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'spacing', value)
                        ufCore:UpdateFrameForUnit('party')
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
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('party')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('party', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('party', 'name')
                end
            }
        },
        {
            name = 'Health',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('party', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('party', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('party', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('party', 'healthperc')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'powerHeight')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('party')
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
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('party', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('party', 'debuffs', false)
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('party')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('party', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Raid Role Icons',
            id = 'raidroles',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('party')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('party', 'raidRoles')
                end,
            }
        },
        {
            name = 'Offline Text',
            id = 'offline',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('party', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('party', 'offline')
                end
            }
        },
        {
            name = 'Resurrect Indicator',
            id = 'resurrectindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'ressurect')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'ressurectScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'ressurectScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'ressurectScale', value)
                        ufCore:UpdateFrameForUnit('party')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('party', 'ressurect')
                end,
            }
        },
        {
            name = 'Summon Indicator',
            id = 'summonindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'summon')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'summonScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('party', 'summonScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('party', 'summonScale', value)
                        ufCore:UpdateFrameForUnit('party')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('party', 'summon')
                end,
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('party', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('party')
                end
            }
        }
    }
})
