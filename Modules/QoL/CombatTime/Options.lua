local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.CombatTimer then return {} end
    return RRT.CombatTimer
end

local function mod() return RRT_NS.CombatTimer end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }
local OUTLINE_LABELS = { "None", "Outline", "Thick" }

-- Time format selector helpers
local FORMAT_ORDER = { "SECONDS", "SECONDS_BRACKET", "CLOCK", "CLOCK_BRACKET" }

local function build_format_options()
    local t = {}
    local fmts = RRT_NS.CombatTimer and RRT_NS.CombatTimer.TIME_FORMATS or {}
    for _, key in ipairs(FORMAT_ORDER) do
        local entry = fmts[key]
        if entry then
            local k = key
            tinsert(t, {
                label   = entry.label,
                value   = k,
                onclick = function()
                    mdb().timeFormat = k
                    refresh()
                end,
            })
        end
    end
    return t
end

local function get_format_label()
    local fmt  = mdb().timeFormat or "CLOCK"
    local fmts = RRT_NS.CombatTimer and RRT_NS.CombatTimer.TIME_FORMATS or {}
    local entry = fmts[fmt]
    return entry and entry.label or fmt
end

local function BuildCombatTimeOptions()
    local opts = {}

    -- ── Column 1 : Enable + Lock + Timing ──────────────────────────────
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ct_enable"],
        desc = L["ct_enable_desc"],
        get  = function() return mdb().enabled end,
        set  = function(_, _, v) mdb().enabled = v; refresh() end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ct_lock"],
        desc = L["ct_lock_desc"],
        get  = function() return mdb().locked end,
        set  = function(_, _, v) mdb().locked = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_timing_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "select", name = L["ct_time_format"],
        desc = L["ct_time_format_desc"],
        get    = get_format_label,
        values = build_format_options,
    }
    opts[#opts+1] = {
        type = "range", name = L["ct_sticky_duration"], min = 0, max = 30, step = 1,
        desc = L["ct_sticky_duration_desc"],
        get  = function() return mdb().stickyDuration or 5 end,
        set  = function(_, _, v) mdb().stickyDuration = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_font_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "range", name = L["ct_font_size"], min = 10, max = 72, step = 1,
        desc = L["ct_font_size_desc"],
        get  = function() return mdb().fontSize or 18 end,
        set  = function(_, _, v) mdb().fontSize = v; refresh() end,
    }

    -- Font Outline buttons
    for i, outline in ipairs(OUTLINES) do
        local label = OUTLINE_LABELS[i]
        opts[#opts+1] = {
            type = "button", name = label,
            desc = "Set font outline to: " .. label,
            func = function()
                mdb().fontOutline = outline
                refresh()
            end,
        }
    end

    -- ── Column 2 : Appearance + Shadow + Position ───────────────────────
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_appearance_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type = "color", name = L["ct_text_color"],
        desc = L["ct_text_color_desc"],
        get  = function()
            local fc = mdb().fontColor or {}
            return fc.r or 1, fc.g or 1, fc.b or 1, fc.a or 1
        end,
        set  = function(self, r, g, b, a)
            local d = mdb()
            if not d.fontColor then d.fontColor = {} end
            d.fontColor.r = r; d.fontColor.g = g; d.fontColor.b = b; d.fontColor.a = a
            refresh()
        end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ct_use_class_color"],
        desc = L["ct_use_class_color_desc"],
        get  = function() return mdb().useClassColor end,
        set  = function(_, _, v) mdb().useClassColor = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_shadow_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "color", name = L["ct_shadow_color"],
        desc = L["ct_shadow_color_desc"],
        get  = function()
            local sc = mdb().fontShadowColor or {}
            return sc.r or 0, sc.g or 0, sc.b or 0, sc.a or 1
        end,
        set  = function(self, r, g, b, a)
            local d = mdb()
            if not d.fontShadowColor then d.fontShadowColor = {} end
            d.fontShadowColor.r = r; d.fontShadowColor.g = g; d.fontShadowColor.b = b; d.fontShadowColor.a = a
            refresh()
        end,
    }
    opts[#opts+1] = {
        type = "range", name = L["ct_shadow_x"], min = -5, max = 5, step = 1,
        desc = L["ct_shadow_x_desc"],
        get  = function() return mdb().fontShadowX or 1 end,
        set  = function(_, _, v) mdb().fontShadowX = v; refresh() end,
    }
    opts[#opts+1] = {
        type = "range", name = L["ct_shadow_y"], min = -5, max = 5, step = 1,
        desc = L["ct_shadow_y_desc"],
        get  = function() return mdb().fontShadowY or -1 end,
        set  = function(_, _, v) mdb().fontShadowY = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_position_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "button", name = L["ct_reset_position"],
        desc = L["ct_reset_position_desc"],
        func = function()
            local m = mod()
            if m then m:ResetPosition() end
        end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ct_preview_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "button", name = L["ct_preview_on"],
        desc = L["ct_preview_on_desc"],
        func = function()
            local m = mod()
            if m then m:SetPreviewMode(true) end
        end,
    }
    opts[#opts+1] = {
        type = "button", name = L["ct_preview_off"],
        desc = L["ct_preview_off_desc"],
        func = function()
            local m = mod()
            if m then m:SetPreviewMode(false) end
        end,
    }

    return opts
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.CombatTime = {
    BuildOptions  = BuildCombatTimeOptions,
    BuildCallback = BuildCallback,
}
