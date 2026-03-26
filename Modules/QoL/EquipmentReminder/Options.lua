local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.EquipmentReminder then return {} end
    return RRT.EquipmentReminder
end

local function mod() return RRT_NS.EquipmentReminder end

local function BuildEquipmentReminderOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["eqr_enable"],
            desc = L["eqr_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v)
                mdb().enabled = v
                local m = mod(); if m then m:UpdateDisplay() end
            end,
        },

        {
            type = "label", get = function() return L["eqr_triggers_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["eqr_show_on_instance"],
            desc = L["eqr_show_on_instance_desc"],
            get  = function() return mdb().showOnInstance end,
            set  = function(_, _, v) mdb().showOnInstance = v end,
        },
        {
            type = "toggle", boxfirst = true, name = L["eqr_show_on_readycheck"],
            desc = L["eqr_show_on_readycheck_desc"],
            get  = function() return mdb().showOnReadyCheck end,
            set  = function(_, _, v) mdb().showOnReadyCheck = v end,
        },

        {
            type = "label", get = function() return L["eqr_display_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range", name = L["eqr_auto_hide_delay"],
            desc = L["eqr_auto_hide_delay_desc"],
            min = 0, max = 60, step = 1,
            get  = function() return mdb().autoHideDelay or 10 end,
            set  = function(_, _, v) mdb().autoHideDelay = v end,
        },
        {
            type = "range", name = L["eqr_icon_size"],
            desc = L["eqr_icon_size_desc"],
            min = 20, max = 80, step = 2,
            get  = function() return mdb().iconSize or 40 end,
            set  = function(_, _, v) mdb().iconSize = v end,
        },

        { type = "breakline" },

        {
            type = "label", get = function() return L["eqr_enchant_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["eqr_enchant_enable"],
            desc = L["eqr_enchant_enable_desc"],
            get  = function() return mdb().ecEnabled end,
            set  = function(_, _, v) mdb().ecEnabled = v end,
        },
        {
            type = "toggle", boxfirst = true, name = L["eqr_enchant_all_specs"],
            desc = L["eqr_enchant_all_specs_desc"],
            get  = function() return mdb().ecUseAllSpecs end,
            set  = function(_, _, v) mdb().ecUseAllSpecs = v end,
        },
        {
            type = "button", name = L["eqr_manage_rules"],
            desc = L["eqr_manage_rules_desc"],
            func = function()
                local m = mod(); if m then m:ToggleEnchantPanel() end
            end,
        },

        {
            type = "button", name = L["eqr_show_frame"],
            desc = L["eqr_show_frame_desc"],
            func = function()
                local m = mod(); if m then m:ShowFrame() end
            end,
        },
        {
            type = "button", name = L["eqr_reset_position"],
            desc = L["eqr_reset_position_desc"],
            func = function()
                if RRT and RRT.EquipmentReminder then
                    RRT.EquipmentReminder.point = "CENTER"
                    RRT.EquipmentReminder.x     = 0
                    RRT.EquipmentReminder.y     = 100
                end
                local m = mod(); if m then m:ShowFrame() end
            end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.EquipmentReminder = {
    BuildOptions  = BuildEquipmentReminderOptions,
    BuildCallback = BuildCallback,
}
