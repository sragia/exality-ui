---@class ExalityUI
local EXUI = select(2, ...)

-- Establish a reference to Masque.
local Masque = LibStub("Masque", true)

if (not Masque) then return end

Masque:AddSkin('ExalityUI Rectangle', {
    Author = 'Exality',
    Version = '1.0.0',
    Shape = 'Rectangle',
    Backdrop = {
        Hide = true,
    },
    Icon = {
        Width = 36,
        Height = 20,
        TexCoords = { EXUI.utils.getTexCoords(36, 20, 15) },
    },
    Border = {
        Width = 36,
        Height = 20,
    },
    Normal = {
        Hide = true
    },
    Highlight = {
        Width = 36,
        Height = 20,
        Texture = EXUI.const.masque.rectangle.highlight,
        Color = { 1, 1, 1, 0.6 },
        BlendMode = "BLEND",
    },
    Pushed = {
        Width = 36,
        Height = 20,
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border
    },
    Cooldown = {
        Width = 36,
        Height = 20,
    },
    AutoCastable = {
        Width = 36,
        Height = 20,
    },
    SpellHighlight = {
        Width = 36,
        Height = 20,
        Texture = EXUI.const.masque.rectangle.spellHighlight,
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
    },
    Flash = {
        Width = 36,
        Height = 20,
        Color = { 0, 0, 0, 0.3 },
        BlendMode = "ADD",
    },
    Checked = {
        Width = 36,
        Height = 20,
        Color = { 1, 1, 1, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border
    },

})
