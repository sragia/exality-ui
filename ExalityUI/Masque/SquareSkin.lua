---@class ExalityUI
local EXUI = select(2, ...)

-- Establish a reference to Masque.
local Masque = LibStub("Masque", true)

if (not Masque) then return end

Masque:AddSkin('ExalityUI Square', {
    Author = 'Exality',
    Version = '1.0.0',
    Shape = 'Square',
    Backdrop = {
        Hide = true,
    },
    Icon = {
        TexCoords = { EXUI.utils.getTexCoords(36, 36, 15) },
    },
    Normal = {
        Hide = true
    },
    Cooldown = {
        Width = 36,
        Height = 36,
    },
    Highlight = {
        Texture = EXUI.const.masque.rectangle.highlight,
        Color = { 1, 1, 1, 0.6 },
        BlendMode = "BLEND",
    },
    Pushed = {
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border
    },
    SpellHighlight = {
        Texture = EXUI.const.masque.rectangle.spellHighlight,
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
    },
    Flash = {
        Color = { 0, 0, 0, 0.3 },
        BlendMode = "ADD",
    },
    Checked = {
        Color = { 1, 1, 1, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border
    },

})
