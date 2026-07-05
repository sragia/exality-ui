---@class ExalityUI
local EXUI = select(2, ...)

ExalityUI = {}

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

EXFrames:Configure({
    logoPath = [[Interface/Addons/ExalityUI/Assets/Images/logo_icon.png]],
    defaultFontPath = [[Interface/Addons/ExalityUI/Assets/Fonts/DMSans.ttf]],
})

EXFrames:SetTheme({
    white           = { 237 / 255, 237 / 255, 237 / 255, 1 }, -- #ededed
    accent          = { 1, 68 / 255, 0, 1 },                  -- #FF4400
    accentLight     = { 1, 113 / 255, 61 / 255, 1 },          -- #71713D
    accentDark      = { 158 / 255, 42 / 255, 0, 1 },          -- #9E2A00

    background      = { 17 / 255, 25 / 255, 19 / 255, 1 },    -- #111913  main window bg
    backgroundLight = { 30 / 255, 48 / 255, 36 / 255, 1 },    -- #1e3024
    backgroundDeep  = { 11 / 255, 18 / 255, 13 / 255, 1 },    -- #0B120D  deepest dark
    backgroundPanel = { 26 / 255, 36 / 255, 29 / 255, 0.4 },  -- #2B382F  panels / header


    border       = { 38 / 255, 41 / 255, 34 / 255, 1 },    -- #262922
    borderActive = { 171 / 255, 46 / 255, 32 / 255, 1 },   -- #AB2E20  selected border
    text         = { 244 / 255, 243 / 255, 238 / 255, 1 }, -- #F4F3EE
    textMuted    = { 138 / 255, 138 / 255, 138 / 255, 1 }, -- #8A8A8A
    danger       = { 245 / 255, 7 / 255, 68 / 255, 1 },    -- #f50744  close / destructive
    dangerHover  = { 245 / 255, 7 / 255, 68 / 255, 1 },    -- #f50744  close / destructive
    success      = { 113 / 255, 173 / 255, 42 / 255, 1 },  -- #71AD2A  success
    successDark  = { 85 / 255, 138 / 255, 34 / 255, 1 },   -- #558A22  success
    inProgress   = { 242 / 255, 109 / 255, 0, 1 },         -- #f26d00
    faded        = { 28 / 255, 28 / 255, 28 / 255, 1 },    -- #1c1c1c
    gray         = { 116 / 255, 116 / 255, 116 / 255, 1 }, -- #747474
})

EXUI.const = {
    textures = {
        frame = {
            bg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/window-bg]],
            resizeBtn = [[Interface/Addons/ExalityUI/Assets/Images/Frames/expand-btn]],
            resizeBtnHighlight = [[Interface/Addons/ExalityUI/Assets/Images/Frames/expand-highlight]],
            closeBtn = [[Interface/Addons/ExalityUI/Assets/Images/Frames/close-btn]],
            closeIcon = [[Interface/Addons/ExalityUI/Assets/Images/Frames/close-icon.png]],
            statusBar = [[Interface/Addons/ExalityUI/Assets/Images/Frames/statusBar]],
            iconMask = [[Interface/Addons/ExalityUI/Assets/Images/Frames/icon-mask]],
            titleBg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/title-bg.png]],
            roundedSquare = [[Interface/Addons/ExalityUI/Assets/Images/Frames/rounded-square.png]],
            settingsIcon = [[Interface/Addons/ExalityUI/Assets/Images/Frames/settings-icon.png]],
            inputs = {
                toggle = [[Interface/Addons/ExalityUI/Assets/Images/Frames/toggle]],
                editboxBg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/editbox-bg]],
                editboxHover = [[Interface/Addons/ExalityUI/Assets/Images/Frames/editbox-hover]],
                buttonBg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/button-bg.png]],
                buttonHover = [[Interface/Addons/ExalityUI/Assets/Images/Frames/button-hover.png]],
                chevronDown = [[Interface/Addons/ExalityUI/Assets/Images/Frames/chevronDown]],
            },
            range = {
                editbox = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/editbox.png]],
                dot = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/dot.png]],
                dotActive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/dot-active.png]],
                leftArrow = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/left-arrow.png]],
                rightArrow = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/right-arrow.png]],
                leftArrowActive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/left-arrow-active.png]],
                rightArrowActive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/right-arrow-active.png]],
                track = [[Interface/Addons/ExalityUI/Assets/Images/Frames/range-input/track.png]],
            },
            editor = {
                arrowActive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/editor/arrow-active.png]],
                arrowInactive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/editor/arrow-inactive.png]],
            },
            tabs = {
                active = [[Interface/Addons/ExalityUI/Assets/Images/Frames/tabs/active.png]],
                inactive = [[Interface/Addons/ExalityUI/Assets/Images/Frames/tabs/inactive.png]],
            },
            solidBg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/white.png]],
            icons = {
                info = [[Interface/Addons/ExalityUI/Assets/Images/Frames/info_icon.png]],
            },
            previewIcon = [[Interface/Addons/ExalityUI/Assets/Images/Frames/preview_icon.png]],
        },
        paperDoll = {
            charBg = [[Interface/Addons/ExalityUI/Assets/Images/PaperDoll/charBg.png]],
        },
        raidTools = {
            check = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/check.png]],
            skull = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/skull.png]],
            clock = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/clock.png]],
        },
        characterFrame = {
            border = {
                empty = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-empty.png]],
                white = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-white.png]],
                uncommon = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-uncommon.png]],
                rare = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-rare.png]],
                epic = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-epic.png]],
                legendary = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-legendary.png]],
                max = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-max.png]],
            },
            highlight = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/highlight.png]],
            dot = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/dot.png]],
            toBlizzIcon = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/to-blizz-icon.png]],
            characterGlow = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/character-glow.png]],
            gem = {
                empty = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/gem-empty.png]],
                border = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-gem.png]],
            },
            stats = {
                bars = {
                    stats = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/stats-bar-stats.png]],
                    header = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/stats-bar-header.png]],
                }
            }
        },
        vignetteGradient = [[Interface/Addons/ExalityUI/Assets/Images/Frames/vignette.png]],
        logo = [[Interface/Addons/ExalityUI/Assets/Images/logo_icon.png]],
        unitFrames = {
            dispelOverlay = [[Interface/Addons/ExalityUI/Assets/Images/UnitFrames/dispel-overlay.png]],
        }
    },
    masque = {
        rectangle = {
            border = [[Interface/Addons/ExalityUI/Assets/Images/Masque/Border.png]],
            highlight = [[Interface/Addons/ExalityUI/Assets/Images/Masque/Highlight.png]],
            spellHighlight = [[Interface/Addons/ExalityUI/Assets/Images/Masque/SpellHighlight.png]],
        }
    },
    fonts = {
        Bahnschrift = [[Interface/Addons/ExalityUI/Assets/Fonts/bahnschrift.ttf]],
        DEFAULT = [[Interface/Addons/ExalityUI/Assets/Fonts/DMSans.ttf]],
    },
    backdrop = {
        DEFAULT = {
            bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
            tile = false,
            tileSize = 0,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        },
        pixelPerfect = function()
            return {
                bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
                edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
                edgeSize = EXUI:ScalePixel(1)
            }
        end
    },
    ilvlColors = {
        -- Midnight --
        { ilvl = 200, str = "ff26ff3f" }, { ilvl = 540, str = "ff26ffba" },
        { ilvl = 230, str = "ff26e2ff" }, { ilvl = 560, str = "ff26a0ff" },
        { ilvl = 240, str = "ff2663ff" }, { ilvl = 580, str = "ff8e26ff" },
        { ilvl = 250, str = "ffe226ff" }, { ilvl = 600, str = "ffff2696" },
        { ilvl = 260, str = "ffff2634" }, { ilvl = 620, str = "ffff7526" },
        { ilvl = 277, str = "ffffc526" }
    },
    anchorPoints = {
        TOPLEFT = 'TOPLEFT',
        TOPRIGHT = 'TOPRIGHT',
        BOTTOMLEFT = 'BOTTOMLEFT',
        BOTTOMRIGHT = 'BOTTOMRIGHT',
        CENTER = 'CENTER',
        TOP = 'TOP',
        BOTTOM = 'BOTTOM',
        LEFT = 'LEFT',
        RIGHT = 'RIGHT',
    },
    frameStrata = {
        BACKGROUND = 'BACKGROUND',
        LOW = 'LOW',
        MEDIUM = 'MEDIUM',
        HIGH = 'HIGH',
        DIALOG = 'DIALOG',
        FULLSCREEN = 'FULLSCREEN',
        FULLSCREEN_DIALOG = 'FULLSCREEN_DIALOG',
        TOOLTIP = 'TOOLTIP',
    },
    fontFlags = {
        OUTLINE = 'OUTLINE',
        THICKOUTLINE = 'THICKOUTLINE',
        MONOCHROME = 'MONOCHROME',
        [""] = 'NONE',
    },
    colWidth = 150,
    colors = {
        red = { 158 / 255, 0, 32 / 255, 1 },
        gray = { 122 / 255, 122 / 255, 122 / 255, 1 },
        accent = { 219 / 255, 73 / 255, 0, 1 },
        accentSecondary = { 0, 153 / 255, 242 / 255, 1 },
        white = { 237 / 255, 237 / 255, 237 / 255, 1 },
    }
}
