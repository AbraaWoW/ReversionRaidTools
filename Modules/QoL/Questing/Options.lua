local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mod() return RRT_NS.Questing end

local function BuildQuestingOptions()
    return {
        -- ── Faster Loot ──────────────────────────────────────────────────────
        {
            type = "label", get = function() return L["qst_faster_loot_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_faster_loot"],
            desc = L["qst_faster_loot_desc"],
            get  = function() return RRT.QoL and RRT.QoL.FasterLoot end,
            set  = function(_, _, v)
                if RRT.QoL then RRT.QoL.FasterLoot = v end
                local m = mod(); if m then m:EnableFasterLoot(v) end
            end,
            spacement = true,
        },

        -- ── Skip Cinematics ───────────────────────────────────────────────────
        {
            type = "label", get = function() return L["qst_skip_cinematics_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_skip_cinematics"],
            desc = L["qst_skip_cinematics_desc"],
            get  = function() return RRT.QoL and RRT.QoL.SkipCinematics end,
            set  = function(_, _, v)
                if RRT.QoL then RRT.QoL.SkipCinematics = v end
                local m = mod(); if m then m:EnableSkipCinematics(v) end
            end,
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_skip_message"],
            desc = L["qst_skip_message_desc"],
            get  = function() return RRT.QoL and RRT.QoL.SkipCinematicsMessage end,
            set  = function(_, _, v) if RRT.QoL then RRT.QoL.SkipCinematicsMessage = v end end,
        },

        -- ── Auto Quest ────────────────────────────────────────────────────────
        { type = "breakline" },
        {
            type = "label", get = function() return L["qst_auto_quest_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_auto_quest"],
            desc = L["qst_auto_quest_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.enabled end,
            set  = function(_, _, v)
                if RRT.AutoQuest then RRT.AutoQuest.enabled = v end
                local m = mod(); if m then m:EnableAutoQuest(v) end
            end,
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_auto_accept"],
            desc = L["qst_auto_accept_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.autoAccept end,
            set  = function(_, _, v) if RRT.AutoQuest then RRT.AutoQuest.autoAccept = v end end,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_auto_turnin"],
            desc = L["qst_auto_turnin_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.autoTurnIn end,
            set  = function(_, _, v) if RRT.AutoQuest then RRT.AutoQuest.autoTurnIn = v end end,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_auto_reward"],
            desc = L["qst_auto_reward_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.autoSelectSingleReward end,
            set  = function(_, _, v) if RRT.AutoQuest then RRT.AutoQuest.autoSelectSingleReward = v end end,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_auto_gossip"],
            desc = L["qst_auto_gossip_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.autoSelectSingleGossip end,
            set  = function(_, _, v) if RRT.AutoQuest then RRT.AutoQuest.autoSelectSingleGossip = v end end,
        },
        {
            type = "toggle", boxfirst = true, name = L["qst_skip_trivial"],
            desc = L["qst_skip_trivial_desc"],
            get  = function() return RRT.AutoQuest and RRT.AutoQuest.skipTrivialQuests end,
            set  = function(_, _, v) if RRT.AutoQuest then RRT.AutoQuest.skipTrivialQuests = v end end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Questing = {
    BuildOptions  = BuildQuestingOptions,
    BuildCallback = BuildCallback,
}
