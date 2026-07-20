---@class ExalityUI
local EXUI = select(2, ...)

ExalityUI = {}

---@class ExalityFrames
local EXFrames = EXUI.EXFrames

EXFrames:Configure({
    logoPath = [[Interface/Addons/ExalityUI/Assets/Images/logo_icon.png]],
    defaultFontPath = [[Interface/Addons/ExalityUI/Assets/Fonts/DMSans.ttf]],
    scalePixel = function(value, region, minPixels)
        return EXUI:ScalePixel(value, region, minPixels)
    end,
    snapFrame = function(frame)
        EXUI:SnapFrameToPixels(frame)
    end,
    addPixelPerfectBorder = function(frame, thickness, options)
        return EXUI:AddPixelPerfectBorder(frame, thickness, options)
    end,
})

EXUI.const = {
    theme = {

        white           = { 237 / 255, 237 / 255, 237 / 255, 1 }, -- #ededed
        accent          = { 1, 68 / 255, 0, 1 },                  -- #FF4400
        accentLight     = { 1, 110 / 255, 51 / 255, 1 },          -- #FF6E33  button hover
        accentDark      = { 184 / 255, 51 / 255, 0, 1 },          -- #B83300  pressed / deep accent

        background      = { 23 / 255, 20 / 255, 18 / 255, 1 },    -- #image.png  main window bg
        backgroundLight = { 38 / 255, 32 / 255, 28 / 255, 1 },    -- #26201C  elevated rows / submenu
        backgroundDeep  = { 13 / 255, 11 / 255, 10 / 255, 1 },    -- #0D0B0A  deepest dark
        backgroundPanel = { 48 / 255, 40 / 255, 34 / 255, 0.4 },  -- #302822  panels / tabs / header


        border         = { 61 / 255, 53 / 255, 48 / 255, 1 },      -- #3D3530  warm neutral border
        borderActive   = { 217 / 255, 69 / 255, 16 / 255, 1 },     -- #D94510  selected border
        borderInactive = { 168 / 255, 158 / 255, 148 / 255, 0.8 }, -- #A89E94  editor unselected
        text           = { 237 / 255, 230 / 255, 223 / 255, 1 },   -- #EDE6DF  warm off-white
        textMuted      = { 138 / 255, 128 / 255, 118 / 255, 1 },   -- #8A8076
        danger         = { 232 / 255, 48 / 255, 80 / 255, 1 },     -- #E83050  close / destructive
        dangerHover    = { 245 / 255, 64 / 255, 96 / 255, 1 },     -- #F54060  close hover
        success        = { 107 / 255, 168 / 255, 50 / 255, 1 },    -- #6BA832  success
        successDark    = { 82 / 255, 130 / 255, 38 / 255, 1 },     -- #528226  success dark
        inProgress     = { 245 / 255, 160 / 255, 32 / 255, 1 },    -- #F5A020  amber progress
        faded          = { 28 / 255, 24 / 255, 22 / 255, 1 },      -- #1C1816  muted button bg
        gray           = { 110 / 255, 100 / 255, 92 / 255, 1 },    -- #6E645C

        minimap        = {
            buttonBg = { 13 / 255, 11 / 255, 10 / 255, 1 },    -- #0D0B0A  ldb / drawer buttons
            mailButtonBg = { 92 / 255, 34 / 255, 8 / 255, 1 }, -- #5C2208  dark accent blend for mail
        },
    },
    textures = {
        frame = {
            bg = [[Interface/Addons/ExalityUI/Assets/Images/Frames/window-bg]],
            resizeBtn = [[Interface/Addons/ExalityUI/Assets/Images/Frames/expand-btn]],
            resizeBtnHighlight = [[Interface/Addons/ExalityUI/Assets/Images/Frames/expand-highlight]],
            closeBtn = [[Interface/Addons/ExalityUI/Assets/Images/Frames/close-btn]],
            closeIcon = [[Interface/Addons/ExalityUI/Assets/Images/Icons/x.png]],
            copyIcon = [[Interface/Addons/ExalityUI/Assets/Images/Frames/copy.png]],
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
            whiteTextured = [[Interface/Addons/ExalityUI/ExalityFrames/Assets/white-textured.png]],
            gradientBottom = [[Interface/Addons/ExalityUI/Assets/Images/Frames/gradient-bottom.png]],
            gradientTop = [[Interface/Addons/ExalityUI/Assets/Images/Frames/gradient-top.png]],
            icons = {
                info = [[Interface/Addons/ExalityUI/Assets/Images/Frames/info_icon.png]],
                fullscreen = [[Interface/Addons/ExalityUI/Assets/Images/Icons/fullscreen.png]],
                minimize = [[Interface/Addons/ExalityUI/Assets/Images/Icons/minimize.png]],
                chevronLeft = [[Interface/Addons/ExalityUI/Assets/Images/Icons/chevron-left.png]],
                chevronRight = [[Interface/Addons/ExalityUI/Assets/Images/Icons/chevron-right.png]],
                plus = [[Interface/Addons/ExalityUI/Assets/Images/Icons/plus.png]],
                duplicate = [[Interface/Addons/ExalityUI/Assets/Images/Icons/duplicate.png]],
                delete = [[Interface/Addons/ExalityUI/Assets/Images/Icons/delete.png]],
                auraTypeBorder = [[Interface/Addons/ExalityUI/Assets/Images/Icons/aura-type-border.png]],
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
                supermax = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/border-supermax.png]],
            },
            highlight = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/highlight.png]],
            dot = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/dot.png]],
            toBlizzIcon = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/to-blizz-icon.png]],
            characterGlow = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/character-glow.png]],
            check = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/check.png]],
            coins = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/coins.png]],
            panel = {
                bg = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/panel-bg.png]],
                border = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/panel-border.png]],
            },
            input = {
                bg = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/input-bg.png]],
                border = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/input-border.png]],
                buttonBg = [[Interface/Addons/ExalityUI/Assets/Images/CharacterFrame/button-bg.png]],
            },
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
        minimap = {
            drawerOpen = [[Interface/Addons/ExalityUI/Assets/Images/Minimap/open.png]],
            mail = [[Interface/Addons/ExalityUI/Assets/Images/Minimap/mail.png]],
        },
        unitFrames = {
            dispelOverlay = [[Interface/Addons/ExalityUI/Assets/Images/UnitFrames/dispel-overlay.png]],
        },
        skins = {
            btnHighlight = [[Interface/Addons/ExalityUI/Assets/Images/Skins/btn-highlight.png]],
            lfgLeftBg = [[Interface/Addons/ExalityUI/Assets/Images/Skins/lfg-left-bg.jpg]],
            lfgLeftBtnBg = [[Interface/Addons/ExalityUI/Assets/Images/Skins/lfg-left-btn-bg.png]],
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
        Bahnschrift = [[Interface\AddOns\ExalityUI\Assets\Fonts\bahnschrift.ttf]],
        DEFAULT = [[Interface\AddOns\ExalityUI\Assets\Fonts\DMSans.ttf]],
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
        backgroundOnly = {
            bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
            tile = false,
        },
        pixelPerfect = function(borderSize, region)
            borderSize = borderSize or 1
            local edge = EXUI:ScalePixels(borderSize, region)
            return {
                bgFile = "Interface\\BUTTONS\\WHITE8X8.blp",
                edgeFile = "Interface\\BUTTONS\\WHITE8X8.blp",
                tile = false,
                tileSize = 0,
                edgeSize = edge,
                insets = { left = 0, right = 0, top = 0, bottom = 0 }
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
    -- Ordered lowest → highest to match in-game frame strata stacking.
    frameStrata = {
        BACKGROUND = { label = 'BACKGROUND', order = 1 },
        LOW = { label = 'LOW', order = 2 },
        MEDIUM = { label = 'MEDIUM', order = 3 },
        HIGH = { label = 'HIGH', order = 4 },
        DIALOG = { label = 'DIALOG', order = 5 },
        FULLSCREEN = { label = 'FULLSCREEN', order = 6 },
        FULLSCREEN_DIALOG = { label = 'FULLSCREEN_DIALOG', order = 7 },
        TOOLTIP = { label = 'TOOLTIP', order = 8 },
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


EXFrames:SetTheme(EXUI.const.theme)
