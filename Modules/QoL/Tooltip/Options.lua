local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.Tooltip then return {} end
    return RRT.Tooltip
end

local function mod() return RRT_NS.Tooltip end

local function BuildTooltipOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["tt_enable"],
            desc = L["tt_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v)
                mdb().enabled = v
                if v then local m = mod(); if m then m:Enable() end end
            end,
        },

        {
            type = "label", get = function() return L["tt_unit_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_show_mount"],
            desc = L["tt_show_mount_desc"],
            get  = function() return mdb().showMount end,
            set  = function(_, _, v) mdb().showMount = v end,
        },

        {
            type = "label", get = function() return L["tt_item_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_show_item_id"],
            desc = L["tt_show_item_id_desc"],
            get  = function() return mdb().showItemID end,
            set  = function(_, _, v) mdb().showItemID = v end,
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_show_item_spell_id"],
            desc = L["tt_show_item_spell_id_desc"],
            get  = function() return mdb().showItemSpellID end,
            set  = function(_, _, v) mdb().showItemSpellID = v end,
        },

        {
            type = "label", get = function() return L["tt_spell_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_show_spell_id"],
            desc = L["tt_show_spell_id_desc"],
            get  = function() return mdb().showSpellID end,
            set  = function(_, _, v) mdb().showSpellID = v end,
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_show_node_id"],
            desc = L["tt_show_node_id_desc"],
            get  = function() return mdb().showNodeID end,
            set  = function(_, _, v) mdb().showNodeID = v end,
        },

        { type = "breakline" },

        {
            type = "label", get = function() return L["tt_copy_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["tt_ctrl_c"],
            desc = L["tt_ctrl_c_desc"],
            get  = function() return mdb().copyOnCtrlC end,
            set  = function(_, _, v) mdb().copyOnCtrlC = v end,
            spacement = true,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Tooltip = {
    BuildOptions  = BuildTooltipOptions,
    BuildCallback = BuildCallback,
}
