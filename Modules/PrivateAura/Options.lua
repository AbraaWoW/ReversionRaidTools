local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
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
            get = function() return RRT.PASettings.enabled end,
            set = function(self, fixedparam, value)
                RRT.PASettings.enabled = value
                RRT_NS:InitPA()
            end,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Private Auras to move them around.",
            func = function(self)
                RRT_NS.IsPAPreview = not RRT_NS.IsPAPreview
                RRT_NS:UpdatePADisplay(true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRT.PASettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PASettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRT.PASettings.Spacing end,
            set = function(self, fixedparam, value)
                RRT.PASettings.Spacing = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = -5,
            max = 20,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRT.PASettings.Width end,
            set = function(self, fixedparam, value)
                RRT.PASettings.Width = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRT.PASettings.Height end,
            set = function(self, fixedparam, value)
                RRT.PASettings.Height = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRT.PASettings.xOffset end,
            set = function(self, fixedparam, value)
                RRT.PASettings.xOffset = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRT.PASettings.yOffset end,
            set = function(self, fixedparam, value)
                RRT.PASettings.yOffset = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRT.PASettings.Limit end,
            set = function(self, fixedparam, value)
                RRT.PASettings.Limit = value
                RRT_NS:UpdatePADisplay(true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will create a 2nd Stack-Size Text on top of the first one. If big enough you will barely notice the original one. Unfortunately that is the only viable workaround at the moment. You can disable this by setting the Scale to 1.",
            get = function() return RRT.PASettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                RRT.PASettings.StackScale = value
                RRT_NS:UpdatePADisplay(true)
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
            get = function() return RRT.PASettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                RRT.PASettings.UpscaleDuration = value
                RRT_NS:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Alternate Display",
            desc = "Enable an alternate Display. This display does not duplicate the stack-text and will always upscale the duration without adding 's'. It is however very volatile with the position of the stack-text. I don't recommend using a stack-scale greater than 2.5",
            get = function() return RRT.PASettings.AlternateDisplay end,
            set = function(self, fixedparam, value)
                RRT.PASettings.AlternateDisplay = value
                RRT_NS:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Player Private Auras. This includes stuff like the dispel icon.",
            get = function() return RRT.PASettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRT.PASettings.HideBorder = value
                RRT_NS:UpdatePADisplay(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return RRT.PASettings.HideTooltip end,
            set = function(self, fixedparam, value)
                RRT.PASettings.HideTooltip = value
                RRT_NS:UpdatePADisplay(true)
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
            get = function() return RRT.PATextSettings.enabled end,
            set = function(self, fixedparam, value)
                RRT.PATextSettings.enabled = value
                RRT_NS:InitTextPA()
            end,
        },
        {
            type = "range",
            name = "Scale",
            desc = "Scale of the Private Aura Text-Warning Anchor",
            get = function() return RRT.PATextSettings.Scale end,
            set = function(self, fixedparam, value)
                RRT.PATextSettings.Scale = value
                RRT_NS:UpdatePADisplay(true)
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
            get = function() return RRT.PARaidSettings.enabled end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.enabled = value
                if RRT.PARaidSettings.enabled then
                    RRT_NS:InitRaidPA(not UnitInRaid("player"))
                else
                    RRT_NS:InitRaidPA(true)
                    RRT_NS:InitRaidPA(false)
                end
            end,
        },
        {
            type = "button",
            name = "Preview",
            desc = "Preview Private Auras on your own Raidframe. This only works if you actually have a frame for yourself and you can't drag this one around, use the x/y offset instead.",
            func = function(self)
                RRT_NS.IsRaidPAPreview = not RRT_NS.IsRaidPAPreview
                RRT_NS:UpdatePADisplay(false)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change.",
            get = function() return RRT.PARaidSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "GrowDirection") end,
        },
        {
            type = "select",
            name = "Row-Grow Direction",
            desc = "Row-Grow Direction for a Grid-Style. If you select a conflicting grow direction(for example both right, or one right and the other left) the other grow option will automatically change.",
            get = function() return RRT.PARaidSettings.RowGrowDirection end,
            values = function() return build_PAgrowdirection_options("PARaidSettings", "RowGrowDirection") end,
        },
        {
            type = "range",
            name = "Icons per Row",
            desc = "How many Icons will be displayed per Row.",
            get = function() return RRT.PARaidSettings.PerRow end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.PerRow = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRT.PARaidSettings.Spacing end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.Spacing = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRT.PARaidSettings.Width end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.Width = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRT.PARaidSettings.Height end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.Height = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = 4,
            max = 50,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRT.PARaidSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.xOffset = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRT.PARaidSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.yOffset = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = -200,
            max = 200,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRT.PARaidSettings.Limit end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.Limit = value
                RRT_NS:UpdatePADisplay(false)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "Same as the other Stack-Scales but for this I recommend to use this because the default display is in a rather bad spot. The default is 1.1 to have it enabled but not too big.",
            get = function() return RRT.PARaidSettings.StackScale or 1.1 end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.StackScale = value
                RRT_NS:UpdatePADisplay(false)
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
            get = function() return RRT.PARaidSettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.HideBorder = value
                RRT_NS:UpdatePADisplay(false)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Duration Text",
            desc = "Hide the duration text on the Raidframe Private Auras. Since it's not feasible to rescale the duration text this option exists instead if you think it is overlapping too much and you're fine with only having the swipe.",
            get = function() return RRT.PARaidSettings.HideDurationText end,
            set = function(self, fixedparam, value)
                RRT.PARaidSettings.HideDurationText = value
                RRT_NS:UpdatePADisplay(false)
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
            get = function() return RRT.PARaidSettings.DebuffTypeBorder end,
            set = function(self, fixedparam, value)
                if RRT_NS.IsBuilding then return end
                RRT.PARaidSettings.DebuffTypeBorder = value
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
            type = "button",
            name = "Buff Sounds",
            desc = "Play a sound when a buff appears on you. Works with any spell ID, not just Private Auras.",
            func = function()
                if not RRTUI.buffsound_frame:IsShown() then
                    RRTUI.buffsound_frame:Show()
                end
            end,
            spacement = true,
        },
        {
            type = "button",
            name = "Debuff Sounds",
            desc = "Play a sound when a debuff appears on you. Works with any spell ID.",
            func = function()
                if not RRTUI.debuffsound_frame:IsShown() then
                    RRTUI.debuffsound_frame:Show()
                end
            end,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default RAID Private Aura Sounds",
            desc = "This applies Sounds to all Raid Private Auras based on my personal selection. You can still edit them later. If you made changes, added or deleted one of these spellid's yourself previously this button will NOT overwrite that.",
            get = function() return RRT.PASounds.UseDefaultPASounds end,
            set = function(self, fixedparam, value)
                RRT.PASounds.UseDefaultPASounds = value
                if RRT.PASounds.UseDefaultPASounds then
                    RRT_NS:ApplyDefaultPASounds(true)
                    RRT_NS:RefreshPASoundEditUI()
                end
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use Default M+ Private Aura Sounds",
            desc = "This will likely be less maintained than the Raid ones, otherwise it works the same as that one.",
            get = function() return RRT.PASounds.UseDefaultMPlusPASounds end,
            set = function(self, fixedparam, value)
                RRT.PASounds.UseDefaultMPlusPASounds = value
                if RRT.PASounds.UseDefaultMPlusPASounds then
                    RRT_NS:ApplyDefaultPASounds(true, true)
                    RRT_NS:RefreshPASoundEditUI()
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
            get = function() return RRT.PATankSettings.enabled end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.enabled = value
            end,
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview Co-Tank Private Auras.",
            func = function(self)
                RRT_NS.IsTankPAPreview = not RRT_NS.IsTankPAPreview
                RRT_NS:UpdatePADisplay(false, true)
            end,
            spacement = true
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRT.PATankSettings.GrowDirection end,
            values = function() return build_PAgrowdirection_options("PATankSettings", "GrowDirection") end,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing of the Private Aura Display",
            get = function() return RRT.PATankSettings.Spacing end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.Spacing = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = -5,
            max = 10,
        },

        {
            type = "range",
            name = "Width",
            desc = "Width of the Private Aura Display",
            get = function() return RRT.PATankSettings.Width end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.Width = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Private Aura Display",
            get = function() return RRT.PATankSettings.Height end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.Height = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = 10,
            max = 500,
        },

        {
            type = "range",
            name = "X-Offset",
            desc = "X-Offset of the Private Aura Display",
            get = function() return RRT.PATankSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.xOffset = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Y-Offset",
            desc = "Y-Offset of the Private Aura Display",
            get = function() return RRT.PATankSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.yOffset = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = -3000,
            max = 3000,
        },
        {
            type = "range",
            name = "Max-Icons",
            desc = "Maximum number of icons to display",
            get = function() return RRT.PATankSettings.Limit end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.Limit = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
            min = 1,
            max = 10,
        },
        {
            type = "range",
            name = "Stack-Scale",
            desc = "This will create a 2nd Stack-Size Text on top of the first one. If big enough you will barely notice the original one. Unfortunately that is the only viable workaround at the moment. You can disable this by setting the Scale to 1.",
            get = function() return RRT.PATankSettings.StackScale or 4 end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.StackScale = value
                RRT_NS:UpdatePADisplay(false, true)
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
            get = function() return RRT.PATankSettings.UpscaleDuration end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.UpscaleDuration = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Alternate Display",
            desc = "Enable an alternate Display. This display does not duplicate the stack-text and will always upscale the duration without adding 's'. It is however very volatile with the position of the stack-text. I don't recommend using a stack-scale greater than 2.5",
            get = function() return RRT.PATankSettings.AlternateDisplay end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.AlternateDisplay = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Border",
            desc = "Hide the Blizzard-border around the Co-Tank Private Auras. This includes stuff like the dispel icon.",
            get = function() return RRT.PATankSettings.HideBorder end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.HideBorder = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Tooltip",
            desc = "Hide tooltips on mouseover. The frame will be clickthrough regardless.",
            get = function() return RRT.PATankSettings.HideTooltip end,
            set = function(self, fixedparam, value)
                RRT.PATankSettings.HideTooltip = value
                RRT_NS:UpdatePADisplay(false, true)
            end,
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "This is the Grow-Direction used if there are more than 2 tanks. Rarely ever happens these days but has to be included.",
            get = function() return RRT.PATankSettings.GrowDirection end,
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
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.PrivateAuras = {
    BuildOptions = BuildPrivateAurasOptions,
    BuildCallback = BuildPrivateAurasCallback,
}
