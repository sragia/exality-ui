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
                    onChange = function(f, value)
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
            name = 'Health',
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
        }
    }
})