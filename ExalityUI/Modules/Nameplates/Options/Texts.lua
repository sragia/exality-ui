---@class ExalityUI
local EXUI = select(2, ...)

---@class EXUINameplatesOptionsHelpers
local helpers = EXUI:GetModule('np-options-helpers')

---@class EXUINameplatesCustomTexts
local ctCore = EXUI:GetModule('np-custom-texts')

---@class EXUINameplatesCore
local npCore = EXUI:GetModule('np-core')

---@class EXUINameplatesOptionsTexts
local texts = EXUI:GetModule('np-options-texts')

local function tagField(prefix)
    return {
        type = 'edit-box',
        label = 'Tag',
        name = prefix .. 'Tag',
        width = 25,
        currentValue = function()
            return npCore:GetValue(prefix .. 'Tag')
        end,
        onChange = function(value)
            helpers.Set(prefix .. 'Tag', value)
        end,
    }
end

local function tagInfoButton()
    return {
        type = 'button',
        icon = {
            file = EXUI.const.textures.frame.icons.info,
            width = 16,
            height = 16,
        },
        onClick = function()
            EXUI:GetModule('uf-options-tags-info'):Show()
        end,
        tooltip = { text = 'Available tags' },
        color = { 3 / 255, 140 / 255, 252 / 255, 1 },
        width = 8,
    }
end

local function textSection(prefix, extra)
    local options = {}
    for _, field in ipairs(helpers.TextOptions(prefix)) do
        table.insert(options, field)
    end
    if extra then
        for _, field in ipairs(extra) do
            table.insert(options, field)
        end
    end
    table.insert(options, tagField(prefix))
    table.insert(options, tagInfoButton())
    return options
end

function texts:GetMenu()
    return {
        {
            id = 'name',
            name = 'Name',
            options = function()
                return textSection('name', {
                    helpers.Range('Max Width %', 'nameMaxWidth', 0, 100, 1, 25),
                })
            end,
        },
        {
            id = 'health',
            name = 'Health',
            options = function()
                return textSection('health')
            end,
        },
        {
            id = 'healthperc',
            name = 'Health %',
            options = function()
                return textSection('healthperc')
            end,
        },
        {
            id = 'custom',
            name = 'Custom Texts',
            options = function()
                local options = {}
                local list = ctCore:List()
                local hasAny = false
                for id, db in pairs(list) do
                    hasAny = true
                    table.insert(options, {
                        type = 'button',
                        label = 'Edit  ' .. (db.tag or id),
                        width = 70,
                        color = { 219 / 255, 73 / 255, 0, 1 },
                        onClick = function()
                            EXUI:GetModule('np-custom-texts-editor'):Show(id)
                        end,
                    })
                    table.insert(options, {
                        type = 'button',
                        label = 'Delete',
                        width = 30,
                        color = { 171 / 255, 0, 20 / 255, 1 },
                        onClick = function()
                            ctCore:Delete(id)
                            npCore:UpdateAllPlates()
                            EXUI:GetModule('np-options'):RefreshCurrentView()
                        end,
                    })
                end
                if not hasAny then
                    table.insert(options, {
                        type = 'description',
                        label = 'No custom texts added yet.',
                        width = 100,
                    })
                end
                table.insert(options, {
                    type = 'button',
                    label = 'Add Custom Text',
                    onClick = function()
                        ctCore:Create()
                        npCore:UpdateAllPlates()
                        EXUI:GetModule('np-options'):RefreshCurrentView()
                    end,
                    width = 100,
                    color = { 30 / 255, 120 / 255, 0, 1 },
                })
                return options
            end,
        },
    }
end
