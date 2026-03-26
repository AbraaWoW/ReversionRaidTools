local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return L["qol_text_display_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = L["qol_preview_unlock"],
            desc = L["qol_preview_unlock_desc"],
            func = function(self)
                RRT_NS.IsQoLTextPreview = not RRT_NS.IsQoLTextPreview
                RRT_NS:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = L["qol_font_size"],
            desc = L["qol_font_size_desc"],
            get = function() return RRT.QoL.TextDisplay.FontSize end,
            set = function(self, fixedparam, value)
                RRT.QoL.TextDisplay.FontSize = value
                RRT_NS:UpdateQoLTextDisplay()
            end,
            min = 5,
            max = 70,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_gateway_display"],
            desc = L["qol_gateway_display_desc"],
            get = function() return RRT.QoL.GatewayUseableDisplay end,
            set = function(self, fixedparam, value)
                RRT.QoL.GatewayUseableDisplay = value
                RRT_NS:QoLEvents("ACTIONBAR_UPDATE_USABLE")
                RRT_NS:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", value)
            end,
            icontexture = 607512,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_reset_boss"],
            desc = L["qol_reset_boss_desc"],
            get = function() return RRT.QoL.ResetBossDisplay end,
            set = function(self, fixedparam, value)
                RRT.QoL.ResetBossDisplay = value
                local diff = RRT_NS:DifficultyCheck(14)
                if diff or not value then RRT_NS:UpdateQoLTextDisplay() end
                local turnon = value and diff and not RRT_NS:Restricted()
                RRT_NS:ToggleQoLEvent("UNIT_AURA", turnon)
                RRT_NS:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", turnon)
            end,
            icontexture = 136090,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_loot_boss"],
            desc = L["qol_loot_boss_desc"],
            get = function() return RRT.QoL.LootBossReminder end,
            set = function(self, fixedparam, value)
                RRT.QoL.LootBossReminder = value
                RRT_NS:UpdateQoLTextDisplay()
                local turnon = value and RRT_NS:DifficultyCheck(14)
                RRT_NS:ToggleQoLEvent("ENCOUNTER_END", turnon)
                RRT_NS:ToggleQoLEvent("LOOT_OPENED", turnon)
                RRT_NS:ToggleQoLEvent("CHAT_MSG_MONEY", turnon)
                RRT_NS:ToggleQoLEvent("ENCOUNTER_START", turnon)
            end,
            icontexture = 7639523,
            iconsize = {16, 16},
        },
        {
            type = "label",
            get = function() return L["qol_consumable_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_soulwell"],
            desc = L["qol_soulwell_desc"],
            get = function() return RRT.QoL.SoulwellDropped end,
            set = function(self, fixedparam, value)
                RRT.QoL.SoulwellDropped = value
            end,
            icontexture = 538745,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_feast"],
            desc = L["qol_feast_desc"],
            get = function() return RRT.QoL.FeastDropped end,
            set = function(self, fixedparam, value)
                RRT.QoL.FeastDropped = value
            end,
            icontexture = 5793729,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_cauldron"],
            desc = L["qol_cauldron_desc"],
            get = function() return RRT.QoL.CauldronDropped end,
            set = function(self, fixedparam, value)
                RRT.QoL.CauldronDropped = value
            end,
            icontexture = 1385153,
            iconsize = {16, 16},
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_repair_notif"],
            desc = L["qol_repair_notif_desc"],
            get = function() return RRT.QoL.RepairDropped end,
            set = function(self, fixedparam, value)
                RRT.QoL.RepairDropped = value
            end,
            icontexture = 1405803,
            iconsize = {16, 16},
        },
        {
            type = "range",
            name = L["qol_consumable_duration"],
            desc = L["qol_consumable_duration_desc"],
            get = function() return RRT.QoL.ConsumableNotificationDurationSeconds or 5 end,
            set = function(self, fixedparam, value)
                RRT.QoL.ConsumableNotificationDurationSeconds = value
            end,
            min = 1,
            max = 20,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return L["qol_other_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["qol_auto_repair"],
            desc = L["qol_auto_repair_desc"],
            get = function() return RRT.QoL.AutoRepair end,
            set = function(self, fixedparam, value)
                RRT.QoL.AutoRepair = value
                RRT_NS:ToggleQoLEvent("MERCHANT_SHOW", value)
            end,
            icontexture = 134520,
            iconsize = {16, 16},
            spacement = true,
        },

        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return L["qol_chat_interface_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true,
            name = L["qol_chat_filter"],
            desc = L["qol_chat_filter_desc"],
            get  = function() return RRT.QoL.ChatFilter end,
            set  = function(_, _, v)
                RRT.QoL.ChatFilter = v
                if v then RRT_NS:EnableChatFilter() else RRT_NS:DisableChatFilter() end
            end,
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["qol_login_message"],
            desc = L["qol_login_message_desc"],
            get  = function() return RRT.QoL.ChatFilterLoginMessage end,
            set  = function(_, _, v) RRT.QoL.ChatFilterLoginMessage = v end,
        },
        {
            type = "button", name = L["qol_restore_keywords"],
            desc = L["qol_restore_keywords_desc"],
            func = function() RRT_NS:RestoreChatFilterDefaults() end,
        },
        {
            type = "button", name = L["qol_clear_keywords"],
            desc = L["qol_clear_keywords_desc"],
            func = function()
                if RRT.QoL then RRT.QoL.ChatFilterKeywords = {} end
            end,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["qol_delete_confirm"],
            desc = L["qol_delete_confirm_desc"],
            get  = function() return RRT.QoL.DeleteConfirm end,
            set  = function(_, _, v)
                RRT.QoL.DeleteConfirm = v
                if v then RRT_NS:EnableDeleteConfirm() else RRT_NS:DisableDeleteConfirm() end
            end,
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true,
            name = L["qol_disable_auto_spells"],
            desc = L["qol_disable_auto_spells_desc"],
            get  = function() return RRT.QoL.DisableAutoAddSpells end,
            set  = function(_, _, v)
                RRT.QoL.DisableAutoAddSpells = v
                if v then RRT_NS:EnableDisableAutoAddSpells() else RRT_NS:DisableDisableAutoAddSpells() end
            end,
        },
    }
end

local function BuildHUDOptions()
    return {}
end

local function BuildCombatOptions()
    return {}
end

local function BuildQoLCallback()
    return function() end
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.QoL = {
    BuildOptions       = BuildQoLOptions,
    BuildHUDOptions    = BuildHUDOptions,
    BuildCombatOptions = BuildCombatOptions,
    BuildCallback      = BuildQoLCallback,
}
