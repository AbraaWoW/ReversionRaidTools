local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.Dragonriding then return {} end
    return RRT.Dragonriding
end

local function mod() return RRT_NS.Dragonriding end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local function BuildDragonridingOptions()
    return {
        -- ── Column 1 : Enable + Layout + Behavior ──────────────────────────

        -- Enable & Unlock
        {
            type = "toggle", boxfirst = true, name = L["drg_enable"],
            desc = L["drg_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_unlock"],
            desc = L["drg_unlock_desc"],
            get  = function() return mdb().unlocked end,
            set  = function(_, _, v) mdb().unlocked = v; refresh() end,
        },

        -- Layout
        {
            type = "label", get = function() return L["drg_layout_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range", name = L["drg_bar_width"], min = 10, max = 100,
            desc = L["drg_bar_width_desc"],
            get  = function() return mdb().barWidth or 36 end,
            set  = function(_, _, v) mdb().barWidth = v; refresh() end,
        },
        {
            type = "range", name = L["drg_speed_bar_height"], min = 6, max = 50,
            desc = L["drg_speed_bar_height_desc"],
            get  = function() return mdb().speedHeight or 14 end,
            set  = function(_, _, v) mdb().speedHeight = v; refresh() end,
        },
        {
            type = "range", name = L["drg_charge_bar_height"], min = 6, max = 50,
            desc = L["drg_charge_bar_height_desc"],
            get  = function() return mdb().chargeHeight or 14 end,
            set  = function(_, _, v) mdb().chargeHeight = v; refresh() end,
        },
        {
            type = "range", name = L["drg_bar_gap"], min = 0, max = 40,
            desc = L["drg_bar_gap_desc"],
            get  = function() return mdb().gap or 0 end,
            set  = function(_, _, v) mdb().gap = v; refresh() end,
        },

        -- Behavior
        {
            type = "label", get = function() return L["drg_behavior_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_speed_text"],
            desc = L["drg_speed_text_desc"],
            get  = function() return mdb().showSpeedText end,
            set  = function(_, _, v) mdb().showSpeedText = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_thrill_tick"],
            desc = L["drg_thrill_tick_desc"],
            get  = function() return mdb().showThrillTick end,
            set  = function(_, _, v) mdb().showThrillTick = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_swap_bars"],
            desc = L["drg_swap_bars_desc"],
            get  = function() return mdb().swapPosition end,
            set  = function(_, _, v) mdb().swapPosition = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_hide_grounded"],
            desc = L["drg_hide_grounded_desc"],
            get  = function() return mdb().hideWhenGroundedFull end,
            set  = function(_, _, v) mdb().hideWhenGroundedFull = v; refresh() end,
        },

        -- ── Column 2 : Colors + Features ───────────────────────────────────
        { type = "breakline" },

        -- Speed / Thrill Colors
        {
            type = "label", get = function() return L["drg_speed_thrill_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "color", name = L["drg_speed_color"],
            desc = L["drg_speed_color_desc"],
            get  = function() local d = mdb(); return d.speedColorR  or 0.00, d.speedColorG  or 0.49, d.speedColorB  or 0.79, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.speedColorR  = r; d.speedColorG  = g; d.speedColorB  = b; refresh() end,
        },
        {
            type = "color", name = L["drg_thrill_color"],
            desc = L["drg_thrill_color_desc"],
            get  = function() local d = mdb(); return d.thrillColorR or 1.00, d.thrillColorG or 0.66, d.thrillColorB or 0.00, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.thrillColorR = r; d.thrillColorG = g; d.thrillColorB = b; refresh() end,
        },

        -- Charge Color
        {
            type = "label", get = function() return L["drg_charge_color_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "color", name = L["drg_vigor_color"],
            desc = L["drg_vigor_color_desc"],
            get  = function() local d = mdb(); return d.chargeColorR or 0.01, d.chargeColorG or 0.56, d.chargeColorB or 0.91, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.chargeColorR = r; d.chargeColorG = g; d.chargeColorB = b; refresh() end,
        },

        -- Background
        {
            type = "label", get = function() return L["drg_bg_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "color", name = L["drg_bg_color"],
            desc = L["drg_bg_color_desc"],
            get  = function() local d = mdb(); return d.bgColorR or 0.12, d.bgColorG or 0.12, d.bgColorB or 0.12, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.bgColorR = r; d.bgColorG = g; d.bgColorB = b; refresh() end,
        },
        {
            type = "range", name = L["drg_bg_opacity"], min = 0, max = 1,
            desc = L["drg_bg_opacity_desc"],
            get  = function() return mdb().bgAlpha or 0.8 end,
            set  = function(_, _, v) mdb().bgAlpha = v; refresh() end,
        },

        -- Border
        {
            type = "label", get = function() return L["drg_border_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "color", name = L["drg_border_color"],
            desc = L["drg_border_color_desc"],
            get  = function() local d = mdb(); return d.borderColorR or 0, d.borderColorG or 0, d.borderColorB or 0, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.borderColorR = r; d.borderColorG = g; d.borderColorB = b; refresh() end,
        },
        {
            type = "range", name = L["drg_border_opacity"], min = 0, max = 1,
            desc = L["drg_border_opacity_desc"],
            get  = function() return mdb().borderAlpha or 1 end,
            set  = function(_, _, v) mdb().borderAlpha = v; refresh() end,
        },
        {
            type = "range", name = L["drg_border_size"], min = 1, max = 5,
            desc = L["drg_border_size_desc"],
            get  = function() return mdb().borderSize or 1 end,
            set  = function(_, _, v) mdb().borderSize = v; refresh() end,
        },

        -- Features
        {
            type = "label", get = function() return L["drg_features_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_second_wind"],
            desc = L["drg_second_wind_desc"],
            get  = function() return mdb().showSecondWind end,
            set  = function(_, _, v) mdb().showSecondWind = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["drg_whirling_surge"],
            desc = L["drg_whirling_surge_desc"],
            get  = function() return mdb().showWhirlingSurge end,
            set  = function(_, _, v) mdb().showWhirlingSurge = v; refresh() end,
        },

        -- ── Column 3 : Position + Speed Text + Surge Icon ──────────────────
        { type = "breakline" },

        -- Position
        {
            type = "label", get = function() return L["drg_position_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range", name = L["drg_offset_x"], min = -500, max = 500,
            desc = L["drg_offset_x_desc"],
            get  = function() return mdb().posX or 0 end,
            set  = function(_, _, v) mdb().posX = v; refresh() end,
        },
        {
            type = "range", name = L["drg_offset_y"], min = -500, max = 500,
            desc = L["drg_offset_y_desc"],
            get  = function() return mdb().posY or 200 end,
            set  = function(_, _, v) mdb().posY = v; refresh() end,
        },
        {
            type = "button", name = L["drg_reset_position"],
            desc = L["drg_reset_position_desc"],
            func = function() local d = mdb(); d.posX = 0; d.posY = 200; refresh() end,
        },

        -- Speed Text
        {
            type = "label", get = function() return L["drg_speed_text_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range", name = L["drg_font_size"], min = 6, max = 32,
            desc = L["drg_font_size_desc"],
            get  = function() return mdb().speedFontSize or 12 end,
            set  = function(_, _, v) mdb().speedFontSize = v; refresh() end,
        },
        {
            type = "range", name = L["drg_text_offset_x"], min = -200, max = 200,
            desc = L["drg_text_offset_x_desc"],
            get  = function() return mdb().speedTextOffsetX or 0 end,
            set  = function(_, _, v) mdb().speedTextOffsetX = v; refresh() end,
        },
        {
            type = "range", name = L["drg_text_offset_y"], min = -200, max = 200,
            desc = L["drg_text_offset_y_desc"],
            get  = function() return mdb().speedTextOffsetY or 0 end,
            set  = function(_, _, v) mdb().speedTextOffsetY = v; refresh() end,
        },

        -- Whirling Surge Icon
        {
            type = "label", get = function() return L["drg_surge_icon_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range", name = L["drg_icon_size"], min = 0, max = 64,
            desc = L["drg_icon_size_desc"],
            get  = function() return mdb().surgeIconSize or 0 end,
            set  = function(_, _, v) mdb().surgeIconSize = v; refresh() end,
        },
        -- Anchor buttons
        {
            type = "label", get = function() return L["drg_icon_anchor_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "button", name = L["drg_anchor_right"],
            desc = L["drg_anchor_right_desc"],
            func = function() mdb().surgeAnchor = "RIGHT"; refresh() end,
        },
        {
            type = "button", name = L["drg_anchor_left"],
            desc = L["drg_anchor_left_desc"],
            func = function() mdb().surgeAnchor = "LEFT"; refresh() end,
        },
        {
            type = "button", name = L["drg_anchor_top"],
            desc = L["drg_anchor_top_desc"],
            func = function() mdb().surgeAnchor = "TOP"; refresh() end,
        },
        {
            type = "button", name = L["drg_anchor_bottom"],
            desc = L["drg_anchor_bottom_desc"],
            func = function() mdb().surgeAnchor = "BOTTOM"; refresh() end,
        },
        {
            type = "range", name = L["drg_icon_offset_x"], min = -50, max = 50,
            desc = L["drg_icon_offset_x_desc"],
            get  = function() return mdb().surgeOffsetX or 6 end,
            set  = function(_, _, v) mdb().surgeOffsetX = v; refresh() end,
        },
        {
            type = "range", name = L["drg_icon_offset_y"], min = -50, max = 50,
            desc = L["drg_icon_offset_y_desc"],
            get  = function() return mdb().surgeOffsetY or 0 end,
            set  = function(_, _, v) mdb().surgeOffsetY = v; refresh() end,
        },
        {
            type = "color", name = L["drg_icon_border_color"],
            desc = L["drg_icon_border_color_desc"],
            get  = function() local d = mdb(); return d.iconBorderColorR or 0, d.iconBorderColorG or 0, d.iconBorderColorB or 0, 1 end,
            set  = function(self, r, g, b, a) local d = mdb(); d.iconBorderColorR = r; d.iconBorderColorG = g; d.iconBorderColorB = b; refresh() end,
        },
        {
            type = "range", name = L["drg_icon_border_opacity"], min = 0, max = 1,
            desc = L["drg_icon_border_opacity_desc"],
            get  = function() return mdb().iconBorderAlpha or 1 end,
            set  = function(_, _, v) mdb().iconBorderAlpha = v; refresh() end,
        },
        {
            type = "range", name = L["drg_icon_border_size"], min = 1, max = 5,
            desc = L["drg_icon_border_size_desc"],
            get  = function() return mdb().iconBorderSize or 1 end,
            set  = function(_, _, v) mdb().iconBorderSize = v; refresh() end,
        },
    }
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Dragonriding = {
    BuildOptions  = BuildDragonridingOptions,
    BuildCallback = BuildCallback,
}
