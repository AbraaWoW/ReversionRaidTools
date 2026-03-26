local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function BuildGeneralOptions()
    return {
        {
            type = "label",
            get  = function() return L["raid_general"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type      = "button",
            name      = L["opt_move_text_display"] or "Move Text Display",
            desc      = L["opt_move_text_display_desc"],
            nocombat  = true,
            spacement = true,
            func      = function()
                if RRT_NS.RRTFrame.generic_display:IsMovable() then
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, false)
                else
                    RRT_NS.RRTFrame.generic_display.Text:SetText(
                        "Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
                    RRT_NS.RRTFrame.generic_display:SetSize(
                        RRT_NS.RRTFrame.generic_display.Text:GetStringWidth(),
                        RRT_NS.RRTFrame.generic_display.Text:GetStringHeight())
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, true)
                end
            end,
        },
    }
end

local function BuildMidnightOptions()
    return {
        {
            type = "label",
            get  = function() return L["header_assignment_leader_only"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        -- Vaelgor & Ezzorak
        {
            type = "label",
            get  = function() return L["boss_vaelgor_ezzorak_assign"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type         = "toggle",
            boxfirst     = true,
            name         = L["opt_gloom_soaks"] or "Gloom Soaks - Mythic Only",
            desc         = L["opt_gloom_soaks_desc"] or "Assigns Group 1&2 to soak the first cast, Group 3&4 to soak the second cast.",
            get          = function() return RRT.AssignmentSettings[3178] and RRT.AssignmentSettings[3178].Soaks end,
            set          = function(self, _, value)
                RRT.AssignmentSettings[3178] = RRT.AssignmentSettings[3178] or {}
                RRT.AssignmentSettings[3178].Soaks = value
            end,
            nocombat     = true,
            icontexture  = 4914669,
            iconsize     = {16, 16},
        },

        -- Lightblinded Vanguard
        {
            type = "label",
            get  = function() return L["boss_lightblinded_assign"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type         = "toggle",
            boxfirst     = true,
            name         = L["opt_execution_sentence"] or "Execution Sentence - Mythic Only",
            desc         = L["opt_execution_sentence_desc"],
            get          = function() return RRT.AssignmentSettings[3180] and RRT.AssignmentSettings[3180].Soaks end,
            set          = function(self, _, value)
                RRT.AssignmentSettings[3180] = RRT.AssignmentSettings[3180] or {}
                RRT.AssignmentSettings[3180].Soaks = value
            end,
            nocombat     = true,
            icontexture  = 613954,
            iconsize     = {16, 16},
        },

        -- Chimaerus
        {
            type = "label",
            get  = function() return L["boss_chimaerus_assign"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type         = "toggle",
            boxfirst     = true,
            name         = L["opt_alndust_mythic"] or "Alndust Upheaval - Mythic",
            desc         = L["opt_alndust_mythic_desc"] or "Automatically tells Groups 1&2 to soak the first cast and Group 3&4 to soak the second cast.",
            get          = function() return RRT.AssignmentSettings[3306] and RRT.AssignmentSettings[3306].Soaks end,
            set          = function(self, _, value)
                RRT.AssignmentSettings[3306] = RRT.AssignmentSettings[3306] or {}
                RRT.AssignmentSettings[3306].Soaks = value
            end,
            nocombat     = true,
            icontexture  = 5788297,
            iconsize     = {16, 16},
        },
        {
            type         = "toggle",
            boxfirst     = true,
            name         = L["opt_alndust_normal"] or "Alndust Upheaval - Normal/Heroic",
            desc         = L["opt_alndust_normal_desc"] or "For Normal & Heroic the Addon automatically splits healers & dps in half. Tanks are ignored.",
            get          = function() return RRT.AssignmentSettings[3306] and RRT.AssignmentSettings[3306].SplitSoaks end,
            set          = function(self, _, value)
                RRT.AssignmentSettings[3306] = RRT.AssignmentSettings[3306] or {}
                RRT.AssignmentSettings[3306].SplitSoaks = value
            end,
            nocombat     = true,
            icontexture  = 5788297,
            iconsize     = {16, 16},
        },
    }
end

local function BuildCallback()
    return function() end
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Assignments = {
    BuildGeneralOptions  = BuildGeneralOptions,
    BuildMidnightOptions = BuildMidnightOptions,
    BuildCallback        = BuildCallback,
    -- Legacy (kept for safety)
    BuildOptions         = function() return {} end,
}
