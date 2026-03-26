local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.Crosshair then return {} end
    return RRT.Crosshair
end

local function mod() return RRT_NS.Crosshair end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local function ApplyPreset(preset)
    local d = mdb()
    if preset == "cross" then
        d.showTop, d.showRight, d.showBottom, d.showLeft = true, true, true, true
        d.dotEnabled = false; d.circleEnabled = false
    elseif preset == "dot" then
        d.showTop, d.showRight, d.showBottom, d.showLeft = false, false, false, false
        d.dotEnabled = true; d.circleEnabled = false
    elseif preset == "circle" then
        d.showTop, d.showRight, d.showBottom, d.showLeft = true, true, true, true
        d.dotEnabled = true; d.circleEnabled = true
    end
    refresh()
end

local function BuildCrosshairOptions()
    return {
        -- ── Column 1 : Enable + Shape + Arms + Dimensions ─────────────────

        -- Enable & Visibility
        {
            type = "toggle", boxfirst = true, name = L["ch_enable"],
            desc = L["ch_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_combat_only"],
            desc = L["ch_combat_only_desc"],
            get  = function() return mdb().combatOnly end,
            set  = function(_, _, v) mdb().combatOnly = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_hide_mounted"],
            desc = L["ch_hide_mounted_desc"],
            get  = function() return mdb().hideWhileMounted end,
            set  = function(_, _, v) mdb().hideWhileMounted = v; refresh() end,
        },

        -- Shape presets
        {
            type = "label", get = function() return L["ch_shape_preset_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "button", name = L["ch_preset_cross"],
            desc = L["ch_preset_cross_desc"],
            func = function() ApplyPreset("cross") end,
        },
        {
            type = "button", name = L["ch_preset_dot"],
            desc = L["ch_preset_dot_desc"],
            func = function() ApplyPreset("dot") end,
        },
        {
            type = "button", name = L["ch_preset_circle"],
            desc = L["ch_preset_circle_desc"],
            func = function() ApplyPreset("circle") end,
        },

        -- Arms
        {
            type = "label", get = function() return L["ch_arms_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_arm_top"],
            get  = function() return mdb().showTop    ~= false end,
            set  = function(_, _, v) mdb().showTop    = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_arm_bottom"],
            get  = function() return mdb().showBottom ~= false end,
            set  = function(_, _, v) mdb().showBottom = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_arm_left"],
            get  = function() return mdb().showLeft   ~= false end,
            set  = function(_, _, v) mdb().showLeft   = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_arm_right"],
            get  = function() return mdb().showRight  ~= false end,
            set  = function(_, _, v) mdb().showRight  = v; refresh() end,
        },

        -- Dimensions
        {
            type = "label", get = function() return L["ch_dimensions_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range", name = L["ch_arm_length"], min = 2, max = 80,
            desc = L["ch_arm_length_desc"],
            get  = function() return mdb().size or 20 end,
            set  = function(_, _, v) mdb().size = v; refresh() end,
        },
        {
            type = "range", name = L["ch_thickness"], min = 1, max = 20,
            desc = L["ch_thickness_desc"],
            get  = function() return mdb().thickness or 2 end,
            set  = function(_, _, v) mdb().thickness = v; refresh() end,
        },
        {
            type = "range", name = L["ch_center_gap"], min = 0, max = 40,
            desc = L["ch_center_gap_desc"],
            get  = function() return mdb().gap or 6 end,
            set  = function(_, _, v) mdb().gap = v; refresh() end,
        },

        -- ── Column 2 : Color + Outline + Dot + Circle ────────────────────
        { type = "breakline" },

        -- Color & Opacity
        {
            type = "label", get = function() return L["ch_color_opacity_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "color", name = L["ch_color"],
            desc = L["ch_color_desc"],
            get  = function() local d = mdb(); return d.colorR or 1, d.colorG or 1, d.colorB or 1, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.colorR = r; d.colorG = g; d.colorB = b; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_use_class_color"],
            desc = L["ch_use_class_color_desc"],
            get  = function() return mdb().useClassColor end,
            set  = function(_, _, v) mdb().useClassColor = v; refresh() end,
        },
        {
            type = "range", name = L["ch_opacity"], min = 0, max = 1,
            desc = L["ch_opacity_desc"],
            get  = function() return mdb().opacity or 0.8 end,
            set  = function(_, _, v) mdb().opacity = v; refresh() end,
        },

        -- Outline
        {
            type = "label", get = function() return L["ch_outline_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_outline_enable"],
            desc = L["ch_outline_enable_desc"],
            get  = function() return mdb().outlineEnabled end,
            set  = function(_, _, v) mdb().outlineEnabled = v; refresh() end,
        },
        {
            type = "range", name = L["ch_outline_weight"], min = 1, max = 6,
            desc = L["ch_outline_weight_desc"],
            get  = function() return mdb().outlineWeight or 1 end,
            set  = function(_, _, v) mdb().outlineWeight = v; refresh() end,
        },
        {
            type = "color", name = L["ch_outline_color"],
            desc = L["ch_outline_color_desc"],
            get  = function() local d = mdb(); return d.outlineR or 0, d.outlineG or 0, d.outlineB or 0, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.outlineR = r; d.outlineG = g; d.outlineB = b; refresh() end,
        },

        -- Center Dot
        {
            type = "label", get = function() return L["ch_dot_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_dot_enable"],
            desc = L["ch_dot_enable_desc"],
            get  = function() return mdb().dotEnabled end,
            set  = function(_, _, v) mdb().dotEnabled = v; refresh() end,
        },
        {
            type = "range", name = L["ch_dot_size"], min = 1, max = 16,
            desc = L["ch_dot_size_desc"],
            get  = function() return mdb().dotSize or 4 end,
            set  = function(_, _, v) mdb().dotSize = v; refresh() end,
        },

        -- Circle
        {
            type = "label", get = function() return L["ch_circle_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_circle_enable"],
            desc = L["ch_circle_enable_desc"],
            get  = function() return mdb().circleEnabled end,
            set  = function(_, _, v) mdb().circleEnabled = v; refresh() end,
        },
        {
            type = "range", name = L["ch_circle_size"], min = 10, max = 120,
            desc = L["ch_circle_size_desc"],
            get  = function() return mdb().circleSize or 30 end,
            set  = function(_, _, v) mdb().circleSize = v; refresh() end,
        },
        {
            type = "color", name = L["ch_circle_color"],
            desc = L["ch_circle_color_desc"],
            get  = function() local d = mdb(); return d.circleR or 1, d.circleG or 1, d.circleB or 1, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.circleR = r; d.circleG = g; d.circleB = b; refresh() end,
        },

        -- ── Column 3 : Position + Melee Detection ────────────────────────
        { type = "breakline" },

        -- Position
        {
            type = "label", get = function() return L["ch_position_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range", name = L["ch_offset_x"], min = -200, max = 200,
            desc = L["ch_offset_x_desc"],
            get  = function() return mdb().offsetX or 0 end,
            set  = function(_, _, v) mdb().offsetX = v; refresh() end,
        },
        {
            type = "range", name = L["ch_offset_y"], min = -200, max = 200,
            desc = L["ch_offset_y_desc"],
            get  = function() return mdb().offsetY or 0 end,
            set  = function(_, _, v) mdb().offsetY = v; refresh() end,
        },
        {
            type = "button", name = L["ch_reset_position"],
            desc = L["ch_reset_position_desc"],
            func = function() local d = mdb(); d.offsetX = 0; d.offsetY = 0; refresh() end,
        },

        -- Melee Detection
        {
            type = "label", get = function() return L["ch_melee_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_melee_recolor"],
            desc = L["ch_melee_recolor_desc"],
            get  = function() return mdb().meleeRecolor end,
            set  = function(_, _, v) mdb().meleeRecolor = v; refresh() end,
        },
        {
            type = "color", name = L["ch_melee_color"],
            desc = L["ch_melee_color_desc"],
            get  = function() local d = mdb(); return d.meleeOutColorR or 1, d.meleeOutColorG or 0.2, d.meleeOutColorB or 0.2, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.meleeOutColorR = r; d.meleeOutColorG = g; d.meleeOutColorB = b; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_melee_recolor_arms"],
            desc = L["ch_melee_recolor_arms_desc"],
            get  = function() return mdb().meleeRecolorArms end,
            set  = function(_, _, v) mdb().meleeRecolorArms = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_melee_recolor_border"],
            desc = L["ch_melee_recolor_border_desc"],
            get  = function() return mdb().meleeRecolorBorder ~= false end,
            set  = function(_, _, v) mdb().meleeRecolorBorder = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_melee_recolor_dot"],
            desc = L["ch_melee_recolor_dot_desc"],
            get  = function() return mdb().meleeRecolorDot end,
            set  = function(_, _, v) mdb().meleeRecolorDot = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_melee_recolor_circle"],
            desc = L["ch_melee_recolor_circle_desc"],
            get  = function() return mdb().meleeRecolorCircle end,
            set  = function(_, _, v) mdb().meleeRecolorCircle = v; refresh() end,
        },

        -- Range Sound
        {
            type = "label", get = function() return L["ch_sound_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["ch_sound_enable"],
            desc = L["ch_sound_enable_desc"],
            get  = function() return mdb().meleeSoundEnabled end,
            set  = function(_, _, v) mdb().meleeSoundEnabled = v end,
        },
        {
            type = "range", name = L["ch_sound_interval"], min = 0, max = 15,
            desc = L["ch_sound_interval_desc"],
            get  = function() return mdb().meleeSoundInterval or 3 end,
            set  = function(_, _, v) mdb().meleeSoundInterval = v end,
        },
    }
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Crosshair = {
    BuildOptions  = BuildCrosshairOptions,
    BuildCallback = BuildCallback,
}
