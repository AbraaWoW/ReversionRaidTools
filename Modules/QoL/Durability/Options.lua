local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function refresh()
    local m = RRT_NS.Durability
    if m then m:Refresh() end
end

local function BuildDurabilityOptions()
    return {
        -- ── Column 1 : Enable + Threshold ──────────────────────────────────

        {
            type = "toggle", boxfirst = true, name = L["dur_enable"],
            desc = L["dur_enable_desc"],
            get  = function() return RRT.QoL and RRT.QoL.DurabilityWarning end,
            set  = function(_, _, v)
                if RRT.QoL then RRT.QoL.DurabilityWarning = v end
                refresh()
            end,
        },
        {
            type = "range", name = L["dur_threshold"], min = 1, max = 100,
            desc = L["dur_threshold_desc"],
            get  = function() return (RRT.QoL and RRT.QoL.DurabilityThreshold) or 50 end,
            set  = function(_, _, v)
                if RRT.QoL then RRT.QoL.DurabilityThreshold = v end
                refresh()
            end,
        },

    }
end

local function BuildCallback() return function() end end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Durability = {
    BuildOptions  = BuildDurabilityOptions,
    BuildCallback = BuildCallback,
}
