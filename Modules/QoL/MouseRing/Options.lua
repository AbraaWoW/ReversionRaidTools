local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.MouseRing then return {} end
    return RRT.MouseRing
end

local function mod() return RRT_NS.MouseRing end

local function refresh(method, ...)
    local m = mod()
    if m and m[method] then m[method](m, ...) end
end

local function makeDropdown(items, getKey, setFn)
    local t = {}
    for i, item in ipairs(items) do
        tinsert(t, {
            label = item[2], value = i,
            onclick = function(_, _, value) setFn(items[value][1]) end,
        })
    end
    local function get()
        local current = getKey()
        for i, item in ipairs(items) do if item[1] == current then return i end end
        return 1
    end
    return t, get
end

-------------------------------------------------------------------------------
-- Mouse Ring options (ring, dot, cast, GCD only — Trail is a separate tab)
-------------------------------------------------------------------------------

local function BuildMouseRingOptions()
    local shapeItems = {
        { "ring",      "Circle"    },
        { "thin_ring", "Thin Ring" },
    }
    local castStyleItems = {
        { "segments", "Segments" },
        { "fill",     "Fill"     },
        { "swipe",    "Swipe"    },
    }
    local r1ShapeVals, r1ShapeGet = makeDropdown(shapeItems,
        function() return mdb().ring1Shape or "ring" end,
        function(v) mdb().ring1Shape = v; refresh("UpdateRing",1); refresh("UpdateGCD"); refresh("UpdateCast") end)
    local r2ShapeVals, r2ShapeGet = makeDropdown(shapeItems,
        function() return mdb().ring2Shape or "thin_ring" end,
        function(v) mdb().ring2Shape = v; refresh("UpdateRing",2) end)
    local castStyleVals, castStyleGet = makeDropdown(castStyleItems,
        function() return mdb().castStyle or "segments" end,
        function(v) mdb().castStyle = v; refresh("UpdateCast") end)

    return {
        -- Enable + Preview
        {
            type = "toggle", boxfirst = true,
            name = L["mr_enable"],
            desc = L["mr_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v)
                mdb().enabled = v
                if v then refresh("Enable") else refresh("Disable") end
            end,
        },
        {
            type = "button", name = L["mr_preview"],
            desc = L["mr_preview_desc"],
            func = function()
                local m = mod()
                if m then m:SetPreviewMode(not m:IsPreviewActive()) end
            end,
        },

        -- Visibility
        {
            type = "label", get = function() return L["mr_visibility_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_show_ooc"],
            desc = L["mr_show_ooc_desc"],
            get  = function() return mdb().showOutOfCombat end,
            set  = function(_, _, v) mdb().showOutOfCombat = v; refresh("UpdateVisibility") end,
        },
        {
            type = "range", name = L["mr_combat_opacity"], min = 0, max = 1,
            desc = L["mr_combat_opacity_desc"],
            get  = function() return mdb().opacityInCombat or 1.0 end,
            set  = function(_, _, v) mdb().opacityInCombat = v; refresh("UpdateVisibility") end,
        },
        {
            type = "range", name = L["mr_ooc_opacity"], min = 0, max = 1,
            desc = L["mr_ooc_opacity_desc"],
            get  = function() return mdb().opacityOutOfCombat or 1.0 end,
            set  = function(_, _, v) mdb().opacityOutOfCombat = v; refresh("UpdateVisibility") end,
        },

        -- Ring 1 (same column as Visibility — no breakline)
        {
            type = "label", get = function() return L["mr_ring1_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_ring1_enable"],
            desc = L["mr_ring1_enable_desc"],
            get  = function() return mdb().ring1Enabled end,
            set  = function(_, _, v) mdb().ring1Enabled = v; refresh("UpdateRing",1); refresh("UpdateVisibility") end,
        },
        {
            type = "dropdown", name = L["mr_shape"], desc = L["mr_ring1_shape_desc"],
            get = r1ShapeGet, values = function() return r1ShapeVals end,
        },
        {
            type = "color", name = L["mr_color"], desc = L["mr_ring1_color_desc"],
            get = function() local c = mdb().ring1Color or {}; return c.r or 1, c.g or 0.66, c.b or 0, 1 end,
            set = function(self, r, g, b, a) mdb().ring1Color = {r=r,g=g,b=b}; refresh("UpdateRing",1) end,
        },
        {
            type = "range", name = L["mr_size"], min = 16, max = 80,
            desc = L["mr_ring1_size_desc"],
            get  = function() return mdb().ring1Size or 48 end,
            set  = function(_, _, v) mdb().ring1Size = v; refresh("UpdateRing",1); refresh("UpdateGCD"); refresh("UpdateCast") end,
        },

        -- ── Column 2 : Cast Effect + GCD ──────────────────────────────
        { type = "breakline" },
        {
            type = "label", get = function() return L["mr_cast_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_cast_enable"],
            desc = L["mr_cast_enable_desc"],
            get  = function() return mdb().castEnabled end,
            set  = function(_, _, v) mdb().castEnabled = v end,
        },
        {
            type = "dropdown", name = L["mr_style"], desc = L["mr_cast_style_desc"],
            get = castStyleGet, values = function() return castStyleVals end,
        },
        {
            type = "color", name = L["mr_color"], desc = L["mr_cast_color_desc"],
            get = function() local c = mdb().castColor or {}; return c.r or 1, c.g or 0.66, c.b or 0, 1 end,
            set = function(self, r, g, b, a) mdb().castColor = {r=r,g=g,b=b}; refresh("UpdateCast") end,
        },
        {
            type = "range", name = L["mr_swipe_offset"], min = 0, max = 32,
            desc = L["mr_swipe_offset_desc"],
            get  = function() return mdb().castOffset or 8 end,
            set  = function(_, _, v) mdb().castOffset = v; refresh("UpdateCast") end,
        },

        -- GCD (same column as Cast Effect — no breakline)
        {
            type = "label", get = function() return L["mr_gcd_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_gcd_enable"],
            desc = L["mr_gcd_enable_desc"],
            get  = function() return mdb().gcdEnabled end,
            set  = function(_, _, v) mdb().gcdEnabled = v; refresh("SetGCDEnabled", v); refresh("UpdateGCD") end,
        },
        {
            type = "color", name = L["mr_color"], desc = L["mr_gcd_color_desc"],
            get = function() local c = mdb().gcdColor or {}; return c.r or 0, c.g or 0.56, c.b or 0.91, 1 end,
            set = function(self, r, g, b, a) mdb().gcdColor = {r=r,g=g,b=b}; refresh("UpdateGCD") end,
        },
        {
            type = "range", name = L["mr_gcd_offset"], min = 0, max = 32,
            desc = L["mr_gcd_offset_desc"],
            get  = function() return mdb().gcdOffset or 8 end,
            set  = function(_, _, v) mdb().gcdOffset = v; refresh("UpdateGCD"); refresh("UpdateCast") end,
        },

        -- ── Column 3 : Ring 2 + Center Dot ───────────────────────────
        { type = "breakline" },
        {
            type = "label", get = function() return L["mr_ring2_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_ring2_enable"],
            desc = L["mr_ring2_enable_desc"],
            get  = function() return mdb().ring2Enabled end,
            set  = function(_, _, v) mdb().ring2Enabled = v; refresh("UpdateRing",2); refresh("UpdateVisibility") end,
        },
        {
            type = "dropdown", name = L["mr_shape"], desc = L["mr_ring2_shape_desc"],
            get = r2ShapeGet, values = function() return r2ShapeVals end,
        },
        {
            type = "color", name = L["mr_color"], desc = L["mr_ring2_color_desc"],
            get = function() local c = mdb().ring2Color or {}; return c.r or 1, c.g or 1, c.b or 1, 1 end,
            set = function(self, r, g, b, a) mdb().ring2Color = {r=r,g=g,b=b}; refresh("UpdateRing",2) end,
        },
        {
            type = "range", name = L["mr_size"], min = 16, max = 80,
            desc = L["mr_ring2_size_desc"],
            get  = function() return mdb().ring2Size or 32 end,
            set  = function(_, _, v) mdb().ring2Size = v; refresh("UpdateRing",2) end,
        },

        -- Center Dot (same column as Ring 2 — no breakline)
        {
            type = "label", get = function() return L["mr_dot_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["mr_dot_enable"],
            desc = L["mr_dot_enable_desc"],
            get  = function() return mdb().dotEnabled end,
            set  = function(_, _, v) mdb().dotEnabled = v; refresh("UpdateDot"); refresh("UpdateVisibility") end,
        },
        {
            type = "color", name = L["mr_color"], desc = L["mr_dot_color_desc"],
            get = function() local c = mdb().dotColor or {}; return c.r or 1, c.g or 1, c.b or 1, 1 end,
            set = function(self, r, g, b, a) mdb().dotColor = {r=r,g=g,b=b}; refresh("UpdateDot") end,
        },
        {
            type = "range", name = L["mr_size"], min = 2, max = 24,
            desc = L["mr_dot_size_desc"],
            get  = function() return mdb().dotSize or 8 end,
            set  = function(_, _, v) mdb().dotSize = v; refresh("UpdateDot") end,
        },
    }
end

-------------------------------------------------------------------------------
-- Trail options (separate tab)
-------------------------------------------------------------------------------

local function BuildTrailOptions()
    local trailStyleItems = {
        { "glow",      "Glow"       },
        { "line",      "Line"       },
        { "thickline", "Thick Line" },
        { "dots",      "Dots"       },
        { "custom",    "Custom"     },
    }
    local colorPresetItems = {
        { "custom",  "Custom"  }, { "class",   "Class"   },
        { "gold",    "Gold"    }, { "arcane",  "Arcane"  },
        { "fel",     "Fel"     }, { "fire",    "Fire"    },
        { "frost",   "Frost"   }, { "holy",    "Holy"    },
        { "shadow",  "Shadow"  }, { "rainbow", "Rainbow" },
        { "alar",    "Alar"    }, { "ember",   "Ember"   },
        { "ocean",   "Ocean"   },
    }
    local sparkleItems = {
        { "off",     "Off"     },
        { "static",  "Static"  },
        { "twinkle", "Twinkle" },
    }

    local trailStyleVals, trailStyleGet = makeDropdown(trailStyleItems,
        function() return mdb().trailStyle or "glow" end,
        function(v)
            local d = mdb(); d.trailStyle = v
            local m = mod()
            local preset = m and m.TRAIL_STYLE_PRESETS and m.TRAIL_STYLE_PRESETS[v]
            if preset then
                d.trailMaxPoints = preset.maxPoints; d.trailDotSize = preset.dotSize
                d.trailDotSpacing = preset.dotSpacing; d.trailShrink = preset.shrink
                d.trailShrinkDistance = preset.shrinkDistance
            end
            refresh("UpdateTrail"); refresh("EnsureTrail")
        end)

    local colorPresetVals, colorPresetGet = makeDropdown(colorPresetItems,
        function() return mdb().trailColorPreset or "custom" end,
        function(v) mdb().trailColorPreset = v end)

    local sparkleVals, sparkleGet = makeDropdown(sparkleItems,
        function() return mdb().trailSparkle or "off" end,
        function(v) mdb().trailSparkle = v end)

    return {
        {
            type = "toggle", boxfirst = true, name = L["tr_enable"],
            desc = L["tr_enable_desc"],
            get  = function() return mdb().trailEnabled end,
            set  = function(_, _, v) mdb().trailEnabled = v; refresh("EnsureTrail") end,
        },
        {
            type = "label", get = function() return L["tr_style_color_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "dropdown", name = L["mr_style"],
            desc = L["tr_style_desc"],
            get = trailStyleGet, values = function() return trailStyleVals end,
        },
        {
            type = "dropdown", name = L["tr_color_preset"],
            desc = L["tr_color_preset_desc"],
            get = colorPresetGet, values = function() return colorPresetVals end,
        },
        {
            type = "color", name = L["tr_custom_color"],
            desc = L["tr_custom_color_desc"],
            get = function() local c = mdb().trailColor or {}; return c.r or 1, c.g or 1, c.b or 1, 1 end,
            set = function(self, r, g, b, a) mdb().trailColor = {r=r,g=g,b=b} end,
        },
        { type = "breakline" },
        {
            type = "label", get = function() return L["tr_tuning_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range", name = L["tr_duration"], min = 0.1, max = 2.0,
            desc = L["tr_duration_desc"],
            get  = function() return mdb().trailDuration or 0.4 end,
            set  = function(_, _, v) mdb().trailDuration = v end,
        },
        {
            type = "range", name = L["tr_max_points"], min = 5, max = 400,
            desc = L["tr_max_points_desc"],
            get  = function() return mdb().trailMaxPoints or 20 end,
            set  = function(_, _, v) mdb().trailMaxPoints = v; refresh("UpdateTrail"); refresh("EnsureTrail") end,
        },
        {
            type = "range", name = L["tr_dot_size"], min = 4, max = 48,
            desc = L["tr_dot_size_desc"],
            get  = function() return mdb().trailDotSize or 24 end,
            set  = function(_, _, v) mdb().trailDotSize = v; mdb().trailStyle = "custom"; refresh("UpdateTrail") end,
        },
        {
            type = "range", name = L["tr_dot_spacing"], min = 1, max = 16,
            desc = L["tr_dot_spacing_desc"],
            get  = function() return mdb().trailDotSpacing or 2 end,
            set  = function(_, _, v) mdb().trailDotSpacing = v; mdb().trailStyle = "custom" end,
        },
        { type = "breakline" },
        {
            type = "label", get = function() return L["tr_effects_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["tr_shrink_age"],
            desc = L["tr_shrink_age_desc"],
            get  = function() return mdb().trailShrink end,
            set  = function(_, _, v) mdb().trailShrink = v; mdb().trailStyle = "custom" end,
        },
        {
            type = "toggle", boxfirst = true, name = L["tr_taper_distance"],
            desc = L["tr_taper_distance_desc"],
            get  = function() return mdb().trailShrinkDistance end,
            set  = function(_, _, v) mdb().trailShrinkDistance = v; mdb().trailStyle = "custom" end,
        },
        {
            type = "dropdown", name = L["tr_sparkle"],
            desc = L["tr_sparkle_desc"],
            get = sparkleGet, values = function() return sparkleVals end,
        },
    }
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.MouseRing = {
    BuildOptions      = BuildMouseRingOptions,
    BuildTrailOptions = BuildTrailOptions,
    BuildCallback     = BuildCallback,
}
