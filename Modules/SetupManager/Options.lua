local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function BuildSetupManagerOptions()
    return {
        {
            type = "button",
            name = L["sm_default_arrangement"],
            desc = L["sm_default_arrangement_desc"],
            func = function(self)
                RRT_NS:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = L["sm_split_groups"],
            desc = L["sm_split_groups_desc"],
            func = function(self)
                RRT_NS:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "button",
            name = L["sm_split_evens_odds"],
            desc = L["sm_split_evens_odds_desc"],
            func = function(self)
                RRT_NS:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "breakline"
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["sm_show_missing_buffs"],
            desc = L["sm_show_missing_buffs_desc"],
            get = function() return RRT.Settings.MissingRaidBuffs end,
            set = function(self, fixedparam, value)
                RRT.Settings.MissingRaidBuffs = value
                RRT_NS:UpdateRaidBuffFrame()
            end,
            nocombat = true,
        },
    }
end

local function BuildSetupManagerCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.SetupManager = {
    BuildOptions = BuildSetupManagerOptions,
    BuildCallback = BuildSetupManagerCallback,
}
