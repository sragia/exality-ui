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
        Texture = EXUI.const.masque.rectangle.border,
        EmptyTexture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },
    Cooldown = {
        SetAllPoints = true,
    },
    Highlight = {
        Texture = EXUI.const.masque.rectangle.highlight,
        Color = { 1, 1, 1, 0.6 },
        BlendMode = "BLEND",
        SetAllPoints = true,
    },
    Pushed = {
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },
    SpellHighlight = {
        Texture = EXUI.const.masque.rectangle.spellHighlight,
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        SetAllPoints = true,
    },
    Flash = {
        Color = { 0, 0, 0, 0.3 },
        BlendMode = "ADD",
        SetAllPoints = true,
    },
    Checked = {
        Color = { 1, 1, 1, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },
})

Masque:AddSkin('ExalityUI Square w/ Backdrop', {
    Author = 'Exality',
    Version = '1.0.0',
    Shape = 'Square',
    Backdrop = {
        Color = { 0, 0, 0, 0.7 },
        BorderColor = { 0, 0, 0, 1 },
        EdgeSize = 1,
        Insets = { left = 0, right = 0, top = 0, bottom = 0 },
    },
    Icon = {
        TexCoords = { EXUI.utils.getTexCoords(36, 36, 15) },
    },
    Normal = {
        Texture = EXUI.const.masque.rectangle.border,
        EmptyTexture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },
    Cooldown = {
        SetAllPoints = true,
    },
    Highlight = {
        Texture = EXUI.const.masque.rectangle.highlight,
        Color = { 1, 1, 1, 0.6 },
        BlendMode = "BLEND",
        SetAllPoints = true,
    },
    Pushed = {
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },
    SpellHighlight = {
        Texture = EXUI.const.masque.rectangle.spellHighlight,
        Color = { 237 / 255, 162 / 255, 0, 1 },
        BlendMode = "BLEND",
        SetAllPoints = true,
    },
    Flash = {
        Color = { 0, 0, 0, 0.3 },
        BlendMode = "ADD",
        SetAllPoints = true,
    },
    Checked = {
        Color = { 1, 1, 1, 1 },
        BlendMode = "BLEND",
        Texture = EXUI.const.masque.rectangle.border,
        SetAllPoints = true,
    },

})
