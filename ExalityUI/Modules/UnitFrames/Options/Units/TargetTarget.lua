---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUIUnitFramesOptionsCore
local core = EXUI:GetModule('uf-options-core')

---@class EXUIUnitFramesCore
local ufCore = EXUI:GetModule('uf-core')

core:AddOption({
    name = 'Target of Target',
    id = 'targettarget',
    allowPreview = true,
    menu = {
        {
            name = 'Size & Position',
            id = 'sizeposition',
            options = {
                function()
                    return EXUI:GetModule('uf-options-size-and-position'):GetOptions('targettarget')
                end
            }
        },
        {
            name = 'Name',
            id = 'name',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('targettarget', 'name')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('targettarget', 'name')
                end
            }
        },
        {
            name = 'Health Text',
            id = 'health',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('targettarget', 'health')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('targettarget', 'health')
                end
            }
        },
        {
            name = 'Health %',
            id = 'healthperc',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('targettarget', 'healthperc')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('targettarget', 'healthperc')
                end
            }
        },
        {
            name = 'Absorbs',
            id = 'absorbs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-absorbs'):GetOptions('targettarget')
                end
            }
        },
        {
            name = 'Power',
            id = 'power',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'power')
                end,
                {
                    type = 'range',
                    name = 'powerHeight',
                    label = 'Height',
                    currentValue = function()
                        return ufCore:GetValueForUnit('targettarget', 'powerHeight')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('targettarget', 'powerHeight', value)
                        ufCore:UpdateFrameForUnit('targettarget')
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
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('targettarget', 'buffs', true)
                end
            }
        },
        {
            name = 'Debuffs',
            id = 'debuffs',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-auras'):GetOptions('targettarget', 'debuffs', false)
                end
            }
        },
        {
            name = 'Private Auras',
            id = 'privateauras',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'privateAuras')
                end,
                function()
                    return EXUI:GetModule('uf-options-private-auras'):GetOptions('targettarget')
                end
            }
        },
        {
            name = 'Marker Icon',
            id = 'markericon',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'raidTargetIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidTargetIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('targettarget', 'raidTargetIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('targettarget', 'raidTargetIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('targettarget')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('targettarget', 'raidTargetIndicator')
                end,
            }
        },
        {
            name = 'Raid Role Icons',
            id = 'raidroles',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'raidRoles')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'raidRolesScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('targettarget', 'raidRolesScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('targettarget', 'raidRolesScale', value)
                        ufCore:UpdateFrameForUnit('targettarget')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('targettarget', 'raidRoles')
                end,
            }
        },
        {
            name = 'Offline Text',
            id = 'offline',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-generic-text'):GetOptions('targettarget', 'offline')
                end,
                function()
                    return EXUI:GetModule('uf-options-tag'):GetOptions('targettarget', 'offline')
                end
            }
        },
        {
            name = 'Summon Indicator',
            id = 'summonindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'summon')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'summonScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('targettarget', 'summonScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('targettarget', 'summonScale', value)
                        ufCore:UpdateFrameForUnit('targettarget')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('targettarget', 'summon')
                end,
            }
        },
        {
            name = 'Phase Indicator',
            id = 'phaseindicator',
            options = {
                function()
                    return EXUI:GetModule('uf-options-generic-enable'):GetOptions('targettarget', 'phaseIndicator')
                end,
                {
                    type = 'range',
                    label = 'Scale',
                    name = 'phaseIndicatorScale',
                    min = 0.1,
                    max = 3,
                    step = 0.1,
                    currentValue = function()
                        return ufCore:GetValueForUnit('targettarget', 'phaseIndicatorScale')
                    end,
                    onChange = function(value)
                        ufCore:UpdateValueForUnit('targettarget', 'phaseIndicatorScale', value)
                        ufCore:UpdateFrameForUnit('targettarget')
                    end,
                },
                function()
                    return EXUI:GetModule('uf-options-generic-position'):GetOptions('targettarget', 'phaseIndicator')
                end,
            }
        },
        {
            name = 'Custom Texts',
            id = 'customtexts',
            options = {
                function()
                    return EXUI:GetModule('uf-options-custom-texts'):GetOptions('targettarget')
                end
            }
        }
    }
})
