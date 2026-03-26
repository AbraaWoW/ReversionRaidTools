local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI

local function BuildReadyCheckOptions()
    return {
        {
            type = "label",
            get = function() return L["rc_gear_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_item_check"],
            desc = L["rc_gear_item_check_desc"],
            get = function() return RRT.ReadyCheckSettings.MissingItemCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.MissingItemCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_ilvl_check"],
            desc = L["rc_gear_ilvl_check_desc"],
            get = function() return RRT.ReadyCheckSettings.ItemLevelCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.ItemLevelCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_embellishment"],
            desc = L["rc_gear_embellishment_desc"],
            get = function() return RRT.ReadyCheckSettings.CraftedCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.CraftedCheck = value
            end,
            nocombat = true,
            icontexture = 4549159,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_4pc"],
            desc = L["rc_gear_4pc_desc"],
            get = function() return RRT.ReadyCheckSettings.TierCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.TierCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_enchant"],
            desc = L["rc_gear_enchant_desc"],
            get = function() return RRT.ReadyCheckSettings.EnchantCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.EnchantCheck = value
            end,
            nocombat = true,
            icontexture = 4620672,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_gem"],
            desc = L["rc_gear_gem_desc"],
            get = function() return RRT.ReadyCheckSettings.GemCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.GemCheck = value
            end,
            nocombat = true,
            icontexture = 135998,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_repair"],
            desc = L["rc_gear_repair_desc"],
            get = function() return RRT.ReadyCheckSettings.RepairCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.RepairCheck = value
            end,
            nocombat = true,
            icontexture = 134520,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_gear_gateway"],
            desc = L["rc_gear_gateway_desc"],
            get = function() return RRT.ReadyCheckSettings.GatewayShardCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.GatewayShardCheck = value
            end,
            nocombat = true,
            icontexture = 607513,
            iconsize = {16, 16},
        },

        {
            type = "label",
            get = function() return L["rc_exceptions_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_exceptions_gateway_bind"],
            desc = L["rc_exceptions_gateway_bind_desc"],
            get = function() return RRT.ReadyCheckSettings.SkipGatewayKeybindCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.SkipGatewayKeybindCheck = value
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = L["rc_move_display"],
            desc = L["rc_move_display_desc"],
            func = function(self)
                if RRT_NS.RRTFrame.generic_display:IsMovable() then
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, false)
                else
                    RRT_NS.RRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
                    RRT_NS.RRTFrame.generic_display:SetSize(RRT_NS.RRTFrame.generic_display.Text:GetStringWidth(), RRT_NS.RRTFrame.generic_display.Text:GetStringHeight())
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, true)
                end
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return L["rc_buff_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_buff_raidbuff"],
            desc = L["rc_buff_raidbuff_desc"],
            get = function() return RRT.ReadyCheckSettings.RaidBuffCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.RaidBuffCheck = value
            end,
            nocombat = true,
            icontexture = 136078,
            iconsize = {16, 16},
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_buff_soulstone"],
            desc = L["rc_buff_soulstone_desc"],
            get = function() return RRT.ReadyCheckSettings.SoulstoneCheck end,
            set = function(self, fixedparam, value)
                RRT.ReadyCheckSettings.SoulstoneCheck = value
            end,
            nocombat = true,
            icontexture = 136210,
            iconsize = {16, 16},
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return L["rc_cd_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_cd_enable"],
            desc = L["rc_cd_enable_desc"],
            get = function() return RRT.Settings["CheckCooldowns"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["CHECK_COOLDOWNS"] = true
                RRT.Settings["CheckCooldowns"] = value
            end,
            nocombat = true
        },
        {
            type = "range",
            name = L["rc_cd_pull_timer"],
            desc = L["rc_cd_pull_timer_desc"],
            get = function() return RRT.Settings["CooldownThreshold"] end,
            set = function(self, fixedparam, value)
                RRT.Settings["CooldownThreshold"] = value
            end,
            min = 10,
            max = 60,
            step = 1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_cd_unready"],
            desc = L["rc_cd_unready_desc"],
            get = function() return RRT.Settings["UnreadyOnCooldown"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["UNREADY_ON_COOLDOWN"] = true
                RRT.Settings["UnreadyOnCooldown"] = value
            end,
            nocombat = true
        },
        {
            type = "button",
            name = L["rc_cd_edit"],
            desc = L["rc_cd_edit_desc"],
            func = function(self)
                if not RRTUI.cooldowns_frame:IsShown() then
                    RRTUI.cooldowns_frame:Show()
                end
            end,
            nocombat = true
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return L["rc_utilities_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = L["rc_vantus"],
            desc = L["rc_vantus_desc"],
            func = function()
                RRT_NS:VantusRuneCheck()
            end,
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_auto_invite"],
            desc = L["rc_auto_invite_desc"],
            get = function() return RRT.QoL.AutoInvite end,
            set = function(_, _, value)
                RRT.QoL.AutoInvite = value
                RRT_NS:ToggleQoLEvent("CHAT_MSG_WHISPER", value)
                RRT_NS:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", value)
            end,
            icontexture = 133460,
            iconsize = {16, 16},
        },
    }
end

local function BuildRaidBuffMenu()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = L["rc_flex_raid"],
            desc = L["rc_flex_raid_desc"],
            get = function() return RRT.Settings.FlexRaid end,
            set = function(self, fixedparam, value)
                RRT.Settings.FlexRaid = value
                RRT_NS:UpdateRaidBuffFrame()
            end,
        },
        {
            type = "button",
            name = L["rc_disable_feature"],
            desc = L["rc_disable_feature_desc"],
            func = function(self)
                RRT.Settings.MissingRaidBuffs = false
                RRT_NS:UpdateRaidBuffFrame()
            end,
        }
    }
end

local function BuildReadyCheckCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.ReadyCheck = {
    BuildOptions = BuildReadyCheckOptions,
    BuildRaidBuffMenu = BuildRaidBuffMenu,
    BuildCallback = BuildReadyCheckCallback,
}
