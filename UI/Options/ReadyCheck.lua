local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI

local function BuildReadyCheckOptions()
    return {
        {
            type = "label",
            get = function() return "Gear/Misc Checks" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Missing/Wrong Item Check",
            desc = "Checks if any slots are empty or have an item with the wrong armor type equipped",
            get = function() return RRTDB.ReadyCheckSettings.MissingItemCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.MissingItemCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Item Level Check",
            desc = "Checks if you have any slot equipped below the minimum item level",
            get = function() return RRTDB.ReadyCheckSettings.ItemLevelCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.ItemLevelCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Embellishment Check",
            desc = "Checks if you have 2 Embellishments equipped",
            get = function() return RRTDB.ReadyCheckSettings.CraftedCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.CraftedCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "4pc Check",
            desc = "Checks if you have 4pc of the current raid-tier equipped.",
            get = function() return RRTDB.ReadyCheckSettings.TierCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.TierCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enchant Check",
            desc = "Checks if you have all slots enchanted",
            get = function() return RRTDB.ReadyCheckSettings.EnchantCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.EnchantCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gem Check",
            desc = "Checks if you have all slots gemmed. Checking for the unique epic gem currently only works on an english client.",
            get = function() return RRTDB.ReadyCheckSettings.GemCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.GemCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Repair Check",
            desc = "Checks if any piece needs repair",
            get = function() return RRTDB.ReadyCheckSettings.RepairCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.RepairCheck = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Gateway Control Shard Check",
            desc = "Checks if you have a Gateway Control Shard and whether or not it is located on your actionbars",
            get = function() return RRTDB.ReadyCheckSettings.GatewayShardCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.GatewayShardCheck = value
            end,
            nocombat = true,
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "Buff Checks" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Raid-Buff Check",
            desc = "Checks if any relevant class needs your buff",
            get = function() return RRTDB.ReadyCheckSettings.RaidBuffCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.RaidBuffCheck = value
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Healer Soulstone Check",
            desc = "Checks for Warlocks whether they have soulstoned a healer and it has at least 5m duration left. It will only check this if Soulstone is ready or has less than 30s CD left.",
            get = function() return RRTDB.ReadyCheckSettings.SoulstoneCheck end,
            set = function(self, fixedparam, value)
                RRTDB.ReadyCheckSettings.SoulstoneCheck = value
            end,
            nocombat = true,
        },

        {
            type = "breakline"
        },

        {
            type = "label",
            get = function() return "Cooldowns Options" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Cooldown Checking",
            desc = "Enable cooldown checking for your cooldowns on ready check. This is only active in Heroic and Mythic Raids.",
            get = function() return RRTDB.Settings["CheckCooldowns"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["CHECK_COOLDOWNS"] = true
                RRTDB.Settings["CheckCooldowns"] = value
            end,
            nocombat = true
        },
        {
            type = "range",
            name = "Pull Timer",
            desc = "Pull timer used for cooldown checking.",
            get = function() return RRTDB.Settings["CooldownThreshold"] end,
            set = function(self, fixedparam, value)
                RRTDB.Settings["CooldownThreshold"] = value
            end,
            min = 10,
            max = 60,
            step = 1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Unready on Cooldown",
            desc = "Automatically unready if a tracked spell is on cooldown.",
            get = function() return RRTDB.Settings["UnreadyOnCooldown"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["UNREADY_ON_COOLDOWN"] = true
                RRTDB.Settings["UnreadyOnCooldown"] = value
            end,
            nocombat = true
        },
        {
            type = "button",
            name = "Edit Cooldowns",
            desc = "Edit the cooldowns checked on the ready check.",
            func = function(self)
                if not RRTUI.cooldowns_frame:IsShown() then
                    RRTUI.cooldowns_frame:Show()
                end
            end,
            nocombat = true
        }
    }
end

local function BuildRaidBuffMenu()
    return {
        {
            type = "toggle",
            boxfirst = true,
            name = "Flex Raid",
            desc = "Check raid buffs up to Group 6 instead of only Group 4.",
            get = function() return RRTDB.Settings.FlexRaid end,
            set = function(self, fixedparam, value)
                RRTDB.Settings.FlexRaid = value
                RRT:UpdateRaidBuffFrame()
            end,
        },
        {
            type = "button",
            name = "Disable this Feature",
            desc = "Disable the Missing Raid Buffs Feature. You can re-enable it in the Setup Manager Settings.",
            func = function(self)
                RRTDB.Settings.MissingRaidBuffs = false
                RRT:UpdateRaidBuffFrame()
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
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.ReadyCheck = {
    BuildOptions = BuildReadyCheckOptions,
    BuildRaidBuffMenu = BuildRaidBuffMenu,
    BuildCallback = BuildReadyCheckCallback,
}


