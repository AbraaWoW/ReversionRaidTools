local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.TalentReminder then return {} end
    return RRT.TalentReminder
end

local function mod() return RRT_NS.TalentReminder end

local function BuildTalentReminderOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["talr_enable"],
            desc = L["talr_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v)
                mdb().enabled = v
                local m = mod(); if m then m:UpdateDisplay() end
            end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.TalentReminder = {
    BuildOptions  = BuildTalentReminderOptions,
    BuildCallback = BuildCallback,
}
