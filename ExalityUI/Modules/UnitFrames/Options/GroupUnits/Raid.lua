---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Raid',
    id = 'raid',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('raid')
                end,
                {
                    type = 'range',
                    label = 'Spacing X',
                    name = 'spacingX',
                    min = -30,
                    max = 30,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'spacingX')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'spacingX', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                    width = 20
                },
                {
                    type = 'range',
                    label = 'Spacing Y',
                    name = 'spacingY',
                    min = -30,
                    max = 30,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'spacingY')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'spacingY', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                    width = 20
                },
                {
                    type = 'spacer',
                    width = 60
                },
                {
                    type = 'dropdown',
                    label = 'Group Direction',
                    name = 'groupDirection',
                    getOptions = function()
                        return {
                            ['RIGHT'] = 'Right',
                            ['LEFT'] = 'Left',
                        }
                    end,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'groupDirection')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'groupDirection', value)
                        ufCore:UpdateFrameForUnit('raid')
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
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'name')
                end,
                {
                    type = 'range',
                    label = 'Name Max Width %',
                    name = 'nameMaxWidth',
                    min = 0,
                    max = 100,
                    step = 1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'nameMaxWidth')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'nameMaxWidth', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('raid', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('raid', 'name')
                end
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('raid', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('raid', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('raid', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('raid', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('raid')
                end
            }
        },
        {
            name = 'Buffs',
            id = 'buffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('raid', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('raid', 'debuffs', false)
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('raid', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Raid Role Icons',
            id = 'raidroles',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('raid', 'raidRoles')
                end,
            }
        },
        {
            name = 'Offline Text',
            id = 'offline',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('raid', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('raid', 'offline')
                end
            }
        },
        {
            name = 'Resurrect Indicator',
            id = 'resurrectindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'ressurect')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'ressurectScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'ressurectScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'ressurectScale', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('raid', 'ressurect')
                end,
            }
        },
        {
            name = 'Summon Indicator',
            id = 'summonindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'summon')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'summonScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('raid', 'summonScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('raid', 'summonScale', value)
                        ufCore:UpdateFrameForUnit('raid')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('raid', 'summon')
                end,
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('raid', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('raid')
                end
            }
        }
    }
})
