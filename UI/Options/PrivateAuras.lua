local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI
local build_PAgrowdirection_options = Core.build_PAgrowdirection_options

local function BuildPrivateAurasOptions()
    return {
        {
            type = "label",
            get = function() return "Personal Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura Display is enabled",
            get = function() return RRTDB.PASettings.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.enabled = value
                RRT:InitPA()
            end,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Private Auras to move them around.",
            func = function(self)
                RRT.IsPAPreview = not RRT.IsPAPreview
                RRT:UpdatePADisplay(true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRTDB.PASettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PASettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRTDB.PASettings.Spacing end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.Spacing = value
                RRT:UpdatePADisplay(true)
            end,
            min = -5,
            max = 20,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRTDB.PASettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.Width = value
                RRT:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRTDB.PASettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.Height = value
                RRT:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRTDB.PASettings.xOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.xOffset = value
                RRT:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRTDB.PASettings.yOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.yOffset = value
                RRT:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRTDB.PASettings.Limit end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.Limit = value
                RRT:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will create a 2nd Stack-Size Text on top of the first one. If big enough you will barely notice the original one. Unfortunately that is the only viable workaround at the moment. You can disable this by setting the Scale to 1.",
            get = function() return RRTDB.PASettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.StackScale = value
                RRT:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
            step = 0.1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Upscale Duration Text",
            desc = "This will upscale the Duration Text(uses same scale as stack text). Unfortunately using this means you will see '6 s' instead of just '6' as this is how Blizzard displays it. This can only be used together with the Stack-Size Scaling because it is not possible to hide the Stack-Size from a secondary display.",
            get = function() return RRTDB.PASettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.UpscaleDuration = value
                RRT:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Player Private Auras. This includes stuff like the dispel icon.",
            get = function() return RRTDB.PASettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.HideBorder = value
                RRT:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return RRTDB.PASettings.HideTooltip end,
            set = function(self, fixedparam, value)
                RRTDB.PASettings.HideTooltip = value
                RRT:UpdatePADisplay(true)
            end,
        },
        {
            type = "label",
            get = function() return "Personal Private Aura Text-Warning" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura Text-Warning is enabled",
            get = function() return RRTDB.PATextSettings.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.PATextSettings.enabled = value
                RRT:InitTextPA()
            end,
        },
        {
            type = "range",
            name = "Scale",
            desc = "Scale of the Private Aura Text-Warning Anchor",
            get = function() return RRTDB.PATextSettings.Scale end,
            set = function(self, fixedparam, value)
                RRTDB.PATextSettings.Scale = value
                RRT:UpdatePADisplay(true)
            end,
            min = 0.1,
            max = 5,
            step = 0.1,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "RaidFrame Private Aura Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Aura on Raidframes are enabled",
            get = function() return RRTDB.PARaidSettings.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.enabled = value
                if RRTDB.PARaidSettings.enabled then
                    RRT:InitRaidPA(not UnitInRaid("player"))
                else
                    RRT:InitRaidPA(true)
                    RRT:InitRaidPA(false)
                end
            end,
        },
        {
            type = "button",
            name = "Preview",
            desc = "Preview Private Auras on your own Raidframe. This only works if you actually have a frame for yourself and you can't drag this one around, use the x/y offset instead.",
            func = function(self)
                RRT.IsRaidPAPreview = not RRT.IsRaidPAPreview
                RRT:UpdatePADisplay(false)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change.",
            get = function() return RRTDB.PARaidSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "GrowDirection") end,
        },
        {
            type = "select",
            name = "Row-Grow Direction",
            desc = "Row-Grow Direction for a Grid-Style. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change.",
            get = function() return RRTDB.PARaidSettings.RowGrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "RowGrowDirection") end,
        },
        {
            type = "range",
            name = "Icons per Row",
            desc = "How many Icons will be displayed per Row.",
            get = function() return RRTDB.PARaidSettings.PerRow end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.PerRow = value
                RRT:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRTDB.PARaidSettings.Spacing end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.Spacing = value
                RRT:UpdatePADisplay(false)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRTDB.PARaidSettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.Width = value
                RRT:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRTDB.PARaidSettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.Height = value
                RRT:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRTDB.PARaidSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.xOffset = value
                RRT:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRTDB.PARaidSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.yOffset = value
                RRT:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRTDB.PARaidSettings.Limit end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.Limit = value
                RRT:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "Same as the other Stack-Scales but for this I recommend to use this because the default display is in a rather bad spot. The default is 1.1 to have it enabled but not too big.",
            get = function() return RRTDB.PARaidSettings.StackScale or 1.1 end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.StackScale = value
                RRT:UpdatePADisplay(false)
            end,
            min = 1,
            max = 5,
            step = 0.1,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Raidframe Private Auras. This includes stuff like the dispel icon. (Tooltip is always disabled for Raidframes)",
            get = function() return RRTDB.PARaidSettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.HideBorder = value
                RRT:UpdatePADisplay(false)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Duration Text",
            desc = "Hide the duration text on the Raidframe Private Auras. Since it's not feasible to rescale the duration text this option exists instead if you think it is overlapping too much and you're fine with only having the swipe.",
            get = function() return RRTDB.PARaidSettings.HideDurationText end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.HideDurationText = value
                RRT:UpdatePADisplay(false)
            end,
        },
        {
            type = "breakline"
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Debuff-Type Indicator",
            desc = "This will attach the Blizzard Debuff-Type Indicator to ALL Private Aura Displays. This only works if the Border is enabled. This is a global setting and it will apply to all private auras, regardless which addon is creating them.",
            get = function() return RRTDB.PARaidSettings.DebuffTypeBorder end,
            set = function(self, fixedparam, value)
                RRTDB.PARaidSettings.DebuffTypeBorder = value
                C_UnitAuras.TriggerPrivateAuraShowDispelType(value)
            end,
        },
        {
            type = "label",
            get = function() return "Private Aura Sounds" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Edit Sounds",
            desc = "Open the Private Aura Sounds Editor",
            func = function()
                if not RRTUI.pasound_frame:IsShown() then
                    RRTUI.pasound_frame:Show()
                end
            end,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default RAID Private Aura Sounds",
            desc = "This applies Sounds to all Raid Private Auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spellid's yourself previously this button will NOT overwrite that.",
            get = function() return RRTDB.UseDefaultPASounds end,
            set = function(self, fixedparam, value)
                RRTDB.UseDefaultPASounds = value
                if RRTDB.UseDefaultPASounds then
                    RRT:ApplyDefaultPASounds(true)
                    RRT:RefreshPASoundEditUI()
                end
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default M+ Private Aura Sounds",
            desc = "This will likely be less maintained than the Raid ones, otherwise it works the same as that one.",
            get = function() return RRTDB.PASounds.UseDefaultMPlusPASounds end,
            set = function(self, fixedparam, value)
                RRTDB.PASounds.UseDefaultMPlusPASounds = value
                if RRTDB.PASounds.UseDefaultMPlusPASounds then
                    RRT:ApplyDefaultPASounds(true, true)
                    RRT:RefreshPASoundEditUI()
                end
            end,
        },
        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return "Co-Tank Private Auras" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enabled",
            desc = "Whether Private Auras for Co-Tanks are enabled",
            get = function() return RRTDB.PATankSettings.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.enabled = value
            end,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Co-Tank Private Auras.",
            func = function(self)
                RRT.IsTankPAPreview = not RRT.IsTankPAPreview
                RRT:UpdatePADisplay(false, true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRTDB.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRTDB.PATankSettings.Spacing end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.Spacing = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRTDB.PATankSettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.Width = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRTDB.PATankSettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.Height = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRTDB.PATankSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.xOffset = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRTDB.PATankSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.yOffset = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRTDB.PATankSettings.Limit end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.Limit = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will create a 2nd Stack-Size Text on top of the first one. If big enough you will barely notice the original one. Unfortunately that is the only viable workaround at the moment. You can disable this by setting the Scale to 1.",
            get = function() return RRTDB.PATankSettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.StackScale = value
                RRT:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
            step = 0.1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Upscale Duration Text",
            desc = "This will upscale the Duration Text(uses same scale as stack text). Unfortunately using this means you will see '6 s' instead of just '6' as this is how Blizzard displays it. This can only be used together with the Stack-Size Scaling because it is not possible to hide the Stack-Size from a secondary display.",
            get = function() return RRTDB.PATankSettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.UpscaleDuration = value
                RRT:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Co-Tank Private Auras. This includes stuff like the dispel icon.",
            get = function() return RRTDB.PATankSettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.HideBorder = value
                RRT:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return RRTDB.PATankSettings.HideTooltip end,
            set = function(self, fixedparam, value)
                RRTDB.PATankSettings.HideTooltip = value
                RRT:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "This is the Grow-Direction used if there are more than 2 tanks. Rarely ever happens these days but has to be included.",
            get = function() return RRTDB.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "MultiTankGrowDirection") end,
        },
    }
end

local function BuildPrivateAurasCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.PrivateAuras = {
    BuildOptions = BuildPrivateAurasOptions,
    BuildCallback = BuildPrivateAurasCallback,
}


