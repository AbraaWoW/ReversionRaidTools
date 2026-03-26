local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.BattleRez then return {} end
    return RRT.BattleRez
end

local function mod() return RRT_NS.BattleRez end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local function BuildBattleRezOptions()
    local opts = {}

    -- ── Column 1 : Enable + Display ─────────────────────────────────────
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_enable"],
        desc = L["br_enable_desc"],
        get  = function() return mdb().enabled end,
        set  = function(_, _, v) mdb().enabled = v; refresh() end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_lock"],
        desc = L["br_lock_desc"],
        get  = function() return mdb().locked end,
        set  = function(_, _, v)
            mdb().locked = v
            local m = mod(); if m then m:UpdateLock() end
        end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["br_visibility_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_show_mplus"],
        desc = L["br_show_mplus_desc"],
        get  = function() return mdb().showInMplus end,
        set  = function(_, _, v) mdb().showInMplus = v; refresh() end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_show_raid"],
        desc = L["br_show_raid_desc"],
        get  = function() return mdb().showInRaid end,
        set  = function(_, _, v) mdb().showInRaid = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["br_content_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_show_timer"],
        desc = L["br_show_timer_desc"],
        get  = function() return mdb().showTimer end,
        set  = function(_, _, v) mdb().showTimer = v end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_show_count"],
        desc = L["br_show_count_desc"],
        get  = function() return mdb().showCount end,
        set  = function(_, _, v) mdb().showCount = v end,
    }
    opts[#opts+1] = {
        type = "toggle", boxfirst = true, name = L["br_death_warning"],
        desc = L["br_death_warning_desc"],
        get  = function() return mdb().deathWarning end,
        set  = function(_, _, v) mdb().deathWarning = v end,
    }

    -- ── Column 2 : Size + Position ──────────────────────────────────────
    opts[#opts+1] = { type = "breakline" }

    opts[#opts+1] = {
        type = "label", get = function() return L["br_size_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
    }
    opts[#opts+1] = {
        type = "range", name = L["br_icon_size"], min = 20, max = 100, step = 2,
        desc = L["br_icon_size_desc"],
        get  = function() return mdb().iconSize or 40 end,
        set  = function(_, _, v) mdb().iconSize = v; refresh() end,
    }

    opts[#opts+1] = {
        type = "label", get = function() return L["br_position_header"] end,
        text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        spacement = true,
    }
    opts[#opts+1] = {
        type = "button", name = L["br_reset_position"],
        desc = L["br_reset_position_desc"],
        func = function() local m = mod(); if m then m:ResetPosition() end end,
    }

    return opts
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.BattleRez = {
    BuildOptions  = BuildBattleRezOptions,
    BuildCallback = BuildCallback,
}
