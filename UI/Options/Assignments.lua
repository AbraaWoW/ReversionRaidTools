local _, RRT = ...
local DF = _G["DetailsFramework"]

local function BuildAssignmentsOptions()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Assignment on Pull",
            desc = "Shows your Assignment on Pull",
            get = function() return RRTDB.AssignmentSettings.OnPull end,
            set = function(self, fixedparam, value)
                RRTDB.AssignmentSettings.OnPull = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "For the following Boxes only the Settings of the Raidleader matter." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "label",
            get = function() return "Vaelgor & Ezzorak" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gloom Soaks",
            desc = "Automatically tells Group 2 to soak the first Cast of Gloom and Group 3 to soak the second cast",
            get = function() return RRTDB.AssignmentSettings[3178] and RRTDB.AssignmentSettings[3178].Soaks end,
            set = function(self, fixedparam, value)
                RRTDB.AssignmentSettings[3178] = RRTDB.AssignmentSettings[3178] or {}
                RRTDB.AssignmentSettings[3178].Soaks = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Lightblinded Vanguard" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Execution Sentence",
            desc = "Automatically assigns players to Star, Orange, Triangle and Purple for Execution Sentence. Melee are preferred for Star/Orange, Ranged for Triangle/Purple. You should be putting down World Markers for this.",
            get = function() return RRTDB.AssignmentSettings[3180] and RRTDB.AssignmentSettings[3180].Soaks end,
            set = function(self, fixedparam, value)
                RRTDB.AssignmentSettings[3180] = RRTDB.AssignmentSettings[3180] or {}
                RRTDB.AssignmentSettings[3180].Soaks = value
            end,
            nocombat = true,
        },
        {
            type = "label",
            get = function() return "Chimaerus" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Alndust Upheaval - Mythic",
            desc = "Automatically tells Groups 1&2 to soak the first Cast of Alndust Upheaval and Group 3&4 to soak the second cast",
            get = function() return RRTDB.AssignmentSettings[3306] and RRTDB.AssignmentSettings[3306].Soaks end,
            set = function(self, fixedparam, value)
                RRTDB.AssignmentSettings[3306] = RRTDB.AssignmentSettings[3306] or {}
                RRTDB.AssignmentSettings[3306].Soaks = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Alndust Upheaval - Normal/Heroic",
            desc = "For Normal & Heroic the Addon automatically splits healers & dps in half. Tanks are ignored.",
            get = function() return RRTDB.AssignmentSettings[3306] and RRTDB.AssignmentSettings[3306].SplitSoaks end,
            set = function(self, fixedparam, value)
                RRTDB.AssignmentSettings[3306] = RRTDB.AssignmentSettings[3306] or {}
                RRTDB.AssignmentSettings[3306].SplitSoaks = value
            end,
            nocombat = true,
        },
    }
end

local function BuildAssignmentsCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.Assignments = {
    BuildOptions = BuildAssignmentsOptions,
    BuildCallback = BuildAssignmentsCallback,
}

