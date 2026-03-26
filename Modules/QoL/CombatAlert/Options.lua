local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.CombatAlert then return {} end
    return RRT.CombatAlert
end

local function mod() return RRT_NS.CombatAlert end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local OUTLINES = { "NONE", "OUTLINE", "THICKOUTLINE" }
local OUTLINE_LABELS = { "None", "Outline", "Thick" }

local function BuildCombatAlertOptions()
    local opts = {}

    -- ── Column 1 : Enable + Lock + Fade + Sound ─────────────────────────
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ca_enable"],
        desc = L["ca_enable_desc"],
        get  = function() return mdb().enabled end,
        set  = function(_, _, v) mdb().enabled = v; refresh() end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ca_lock"],
        desc = L["ca_lock_desc"],
        get  = function() return mdb().locked end,
        set  = function(_, _, v)
            mdb().locked = v
            local m = mod(); if m then m:UpdateLock() end
        end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_timing_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "range", name = L["ca_fade_duration"], min = 0.5, max = 5.0, step = 0.5,
        desc = L["ca_fade_duration_desc"],
        get  = function() return mdb().fadeDuration or 2.0 end,
        set  = function(_, _, v) mdb().fadeDuration = v end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_sound_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ca_play_sound"],
        desc = L["ca_play_sound_desc"],
        get  = function() return mdb().soundEnabled end,
        set  = function(_, _, v) mdb().soundEnabled = v end,
    }

    -- ── Column 2 : Enter + Leave alerts ─────────────────────────────────
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_enter_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ca_show_enter"],
        desc = L["ca_show_enter_desc"],
        get  = function() return mdb().showEnter end,
        set  = function(_, _, v) mdb().showEnter = v end,
    }
    opts[#opts+1] = {
        type = "color", name = L["ca_enter_color"],
        desc = L["ca_enter_color_desc"],
        get  = function()
            local c = mdb().enterColor
            if not c then return 1, 0.2, 0.2, 1 end
            return c.r or 1, c.g or 0.2, c.b or 0.2, 1
        end,
        set  = function(self, r, g, b, a)
            local d = mdb()
            if not d.enterColor then d.enterColor = {} end
            d.enterColor.r = r; d.enterColor.g = g; d.enterColor.b = b
        end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_leave_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["ca_show_leave"],
        desc = L["ca_show_leave_desc"],
        get  = function() return mdb().showLeave end,
        set  = function(_, _, v) mdb().showLeave = v end,
    }
    opts[#opts+1] = {
        type = "color", name = L["ca_leave_color"],
        desc = L["ca_leave_color_desc"],
        get  = function()
            local c = mdb().leaveColor
            if not c then return 0.2, 1, 0.2, 1 end
            return c.r or 0.2, c.g or 1, c.b or 0.2, 1
        end,
        set  = function(self, r, g, b, a)
            local d = mdb()
            if not d.leaveColor then d.leaveColor = {} end
            d.leaveColor.r = r; d.leaveColor.g = g; d.leaveColor.b = b
        end,
    }

    -- ── Column 3 : Font + Position + Preview ────────────────────────────
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_font_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type = "range", name = L["ca_font_size"], min = 14, max = 72, step = 1,
        desc = L["ca_font_size_desc"],
        get  = function() return mdb().fontSize or 28 end,
        set  = function(_, _, v) mdb().fontSize = v; refresh() end,
    }

    for i, outline in ipairs(OUTLINES) do
        local lbl = OUTLINE_LABELS[i]
        opts[#opts+1] = {
            type = "button", name = lbl,
            desc = "Set font outline to: " .. lbl,
            func = function() mdb().fontOutline = outline; refresh() end,
        }
    end

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_position_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "button", name = L["ca_reset_position"],
        desc = L["ca_reset_position_desc"],
        func = function() local m = mod(); if m then m:ResetPosition() end end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["ca_preview_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "button", name = L["ca_preview_on"],
        desc = L["ca_preview_on_desc"],
        func = function() local m = mod(); if m then m:SetPreviewMode(true) end end,
    }
    opts[#opts+1] = {
        type = "button", name = L["ca_preview_off"],
        desc = L["ca_preview_off_desc"],
        func = function() local m = mod(); if m then m:SetPreviewMode(false) end end,
    }

    return opts
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.CombatAlert = {
    BuildOptions  = BuildCombatAlertOptions,
    BuildCallback = BuildCallback,
}
