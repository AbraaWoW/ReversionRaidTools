local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI

local function BuildQoLOptions()
    return {
        {
            type = "label",
            get = function() return "Text Display Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Preview/Unlock",
            desc = "Preview and Move the Text Display.",
            func = function(self)
                RRT.IsQoLTextPreview = not RRT.IsQoLTextPreview
                RRT:ToggleQoLTextPreview()
            end,
            spacement = true
        },
        {
            type = "range",
            name = "Font Size",
            desc = "Font Size for Text Display. The Font itself is controlled by the Global Font found in General Settings.",
            get = function() return RRTDB.QoL.TextDisplay.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.TextDisplay.FontSize = value
                RRT:UpdateQoLTextDisplay()
            end,
            min = 5,
            max = 70,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gateway Useable Display",
            desc = "Whether you want to see a display when you are able to use the gateway.",
            get = function() return RRTDB.QoL.GatewayUseableDisplay end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.GatewayUseableDisplay = value
                RRT:QoLEvents("ACTIONBAR_UPDATE_USABLE")
                RRT:ToggleQoLEvent("ACTIONBAR_UPDATE_USABLE", value)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Reset Boss Display",
            desc = "Shows a Text while out of combat when you have the lust debuff to remind you that the boss needs to be reset.",
            get = function() return RRTDB.QoL.ResetBossDisplay end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.ResetBossDisplay = value
                local diff = RRT:DifficultyCheck(14)
                if diff or not value then RRT:UpdateQoLTextDisplay() end
                local turnon = value and diff and not RRT:Restricted()
                RRT:ToggleQoLEvent("UNIT_AURA", turnon)
                RRT:ToggleQoLEvent("ADDON_RESTRICTION_STATE_CHANGED", turnon)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Loot Boss Reminder",
            desc = "Shows a Text after killing a Raid-Boss to remind you to loot the boss for your crests.",
            get = function() return RRTDB.QoL.LootBossReminder end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.LootBossReminder = value
                RRT:UpdateQoLTextDisplay()
                local turnon = value and RRT:DifficultyCheck(14)
                RRT:ToggleQoLEvent("ENCOUNTER_END", turnon)
                RRT:ToggleQoLEvent("LOOT_OPENED", turnon)
                RRT:ToggleQoLEvent("CHAT_MSG_MONEY", turnon)
                RRT:ToggleQoLEvent("ENCOUNTER_START", turnon)

            end,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "General Automations" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Confirm Decor Purchases",
            desc = "Automatically confirms buying decor items without showing the confirmation popup.",
            get = function() return RRTDB.QoL.AutoBuyDecorItems end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoBuyDecorItems = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Skip Gossip Dialogs",
            desc = "Automatically selects the only available option in NPC gossip windows. Hold Shift to temporarily disable this behavior.",
            get = function() return RRTDB.QoL.AutoSkipGossipDialogs end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoSkipGossipDialogs = value
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Accept Group Invites",
            desc = "Instantly accepts incoming group invites.",
            get = function() return RRTDB.QoL.AutoAcceptGroupInvites end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoAcceptGroupInvites = value
                RRT:InitQoLAutoAcceptGroupInvite()
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Confirm Role Checks",
            desc = "Automatically confirms your selected role when role check appears.",
            get = function() return RRTDB.QoL.AutoConfirmRoleChecks end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoConfirmRoleChecks = value
                RRT:InitQoLAutoAcceptRole()
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Screenshot on Achievement",
            desc = "Automatically takes a screenshot when you earn an achievement.",
            get = function() return RRTDB.QoL.AchievementScreenshot end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AchievementScreenshot = value
                RRT:InitQoLAchievementScreenshot()
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Start Combat Log in Instance",
            desc = "Automatically starts combat log in instance and stops it 30s after leaving.",
            get = function() return RRTDB.QoL.AutoCombatLogInInstance end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoCombatLogInInstance = value
                RRT:UpdateQoLCombatLogAutomation()
            end,
        },
        {
            type = "breakline",
        },
        {
            type = "label",
            get = function() return "Other QoL Things" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE")
        },
        {
            type = "button",
            name = "Check Vantus-Rune",
            desc = "Check the Vantus Rune status for all raid members.",
            func = function(self)
                RRT:VantusRuneCheck()
            end,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Repair",
            desc = "Whether you want to automatically repair your equipment when visiting a vendor (prefers guild repairs).",
            get = function() return RRTDB.QoL.AutoRepair end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoRepair = value
                RRT:ToggleQoLEvent("MERCHANT_SHOW", value)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Auto-Invite on Whisper",
            desc = "Whether you want to automatically invite Guild-Members when they whisper you with 'inv' or 'invite'.",
            get = function() return RRTDB.QoL.AutoInvite end,
            set = function(self, fixedparam, value)
                RRTDB.QoL.AutoInvite = value
                RRT:ToggleQoLEvent("CHAT_MSG_WHISPER", value)
                RRT:ToggleQoLEvent("CHAT_MSG_BN_WHISPER", value)
            end,
        },
    }
end

local function BuildQoLCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.QoL = {
    BuildOptions = BuildQoLOptions,
    BuildCallback = BuildQoLCallback,
}




