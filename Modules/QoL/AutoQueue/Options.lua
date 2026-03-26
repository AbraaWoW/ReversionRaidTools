local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.AutoQueue then return {} end
    return RRT.AutoQueue
end

local function BuildAutoQueueOptions()
    return {
        {
            type = "label",
            get  = function() return L["aq_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true,
            name = L["aq_enable"],
            desc = L["aq_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v end,
        },

        -- ── Role Check ────────────────────────────────────────────────────
        {
            type = "label",
            get  = function() return L["aq_section_rolecheck"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["aq_rolecheck"],
            desc = L["aq_rolecheck_desc"],
            get  = function() return mdb().autoAcceptRoleCheck end,
            set  = function(_, _, v) mdb().autoAcceptRoleCheck = v end,
        },

        -- ── One-Click Sign-Up ─────────────────────────────────────────────
        {
            type = "label",
            get  = function() return L["aq_section_oneclick"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["aq_oneclick"],
            desc = L["aq_oneclick_desc"],
            get  = function() return mdb().oneClickSignUp end,
            set  = function(_, _, v) mdb().oneClickSignUp = v end,
        },

        -- ── Announce ──────────────────────────────────────────────────────
        {
            type = "label",
            get  = function() return L["aq_section_announce"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["aq_announce"],
            desc = L["aq_announce_desc"],
            get  = function() return mdb().announce end,
            set  = function(_, _, v) mdb().announce = v end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.AutoQueue = {
    BuildOptions  = BuildAutoQueueOptions,
    BuildCallback = BuildCallback,
}
