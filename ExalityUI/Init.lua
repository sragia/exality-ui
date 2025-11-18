---@class ExalityUI
local EXUI = select(2, ...)

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
        },
        paperDoll = {
            charBg = [[Interface/Addons/ExalityUI/Assets/Images/PaperDoll/charBg.png]],
        },
        raidTools = {
            check = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/check.png]],
            skull = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/skull.png]],
            clock = [[Interface/Addons/ExalityUI/Assets/Images/Frames/raid-tools/clock.png]],
        },
        vignetteGradient = [[Interface/Addons/ExalityUI/Assets/Images/Frames/vignette.png]],
        logo = [[Interface/Addons/ExalityUI/Assets/Images/logo_icon.png]],
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
        }
    },
    ilvlColors = {
        -- Midnight --
        {ilvl = 200, str = "ff26ff3f"}, {ilvl = 540, str = "ff26ffba"},
        {ilvl = 230, str = "ff26e2ff"}, {ilvl = 560, str = "ff26a0ff"},
        {ilvl = 240, str = "ff2663ff"}, {ilvl = 580, str = "ff8e26ff"},
        {ilvl = 250, str = "ffe226ff"}, {ilvl = 600, str = "ffff2696"},
        {ilvl = 260, str = "ffff2634"}, {ilvl = 620, str = "ffff7526"},
        {ilvl = 277, str = "ffffc526"}
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
    fontFlags = {
        OUTLINE = 'OUTLINE',
        THICKOUTLINE = 'THICKOUTLINE',
        MONOCHROME = 'MONOCHROME',
        [""] = 'NONE',
    },
    colWidth = 150
}
