local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function BuildGeneralOptions()
    local t = {
        {
            type = "label",
            get  = function() return L["raid_general"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_show_assignment_on_pull"],
            desc     = L["opt_show_assignment_on_pull_desc"],
            get      = function() return RRT.AssignmentSettings.OnPull end,
            set      = function(self, _, value) RRT.AssignmentSettings.OnPull = value end,
            nocombat = true,
        },
        {
            type = "label",
            get  = function()
                return "Enabling these adds some generic premade Reminders to some of the bosses. Think of these like text-reminders for an upcoming ability from previous WA packs."
            end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "range",
            name = "Encounter Text Font-Size",
            desc = "Some encounters might display static text. The position is set in the General-Tab but you can change the font-size here.",
            get  = function() return RRT.Settings["GlobalEncounterFontSize"] end,
            set  = function(self, _, value)
                RRT.Settings["GlobalEncounterFontSize"] = value
                RRT_NS.RRTFrame.SecretDisplay.Text:SetFont(
                    RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont),
                    RRT.Settings.GlobalEncounterFontSize, "OUTLINE")
            end,
            min = 0,
            max = 100,
        },
        {
            type = "breakline",
        },
    }
    -- Append Preview Alerts entries from Reminders
    local remOpt = RRT_NS.UI and RRT_NS.UI.Options and RRT_NS.UI.Options.Reminders
    if remOpt and remOpt.BuildPreviewEntry then
        for _, e in ipairs(remOpt.BuildPreviewEntry()) do
            tinsert(t, e)
        end
    end
    return t
end

local function BuildMidnightOptions()
    return {
        -- Imperator Averzian
        {
            type = "label",
            get  = function() return "Imperator Averzian" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Imperator Averzian.",
            get         = function() return RRT.EncounterAlerts[3176] and RRT.EncounterAlerts[3176].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3176] = RRT.EncounterAlerts[3176] or {}
                RRT.EncounterAlerts[3176].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3176)
            end,
            nocombat    = true,
            icontexture = 7448209,
            iconsize    = {16, 16},
        },

        -- Vorasius
        {
            type = "label",
            get  = function() return "Vorasius" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Vorasius.",
            get         = function() return RRT.EncounterAlerts[3177] and RRT.EncounterAlerts[3177].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3177] = RRT.EncounterAlerts[3177] or {}
                RRT.EncounterAlerts[3177].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3177)
            end,
            nocombat    = true,
            icontexture = 7448210,
            iconsize    = {16, 16},
        },

        -- Fallen King Salhadaar
        {
            type = "label",
            get  = function() return "Fallen King Salhadaar" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Fallen King Salhadaar.",
            get         = function() return RRT.EncounterAlerts[3179] and RRT.EncounterAlerts[3179].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3179] = RRT.EncounterAlerts[3179] or {}
                RRT.EncounterAlerts[3179].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3179)
            end,
            nocombat    = true,
            icontexture = 7448212,
            iconsize    = {16, 16},
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "CC Adds Display",
            desc        = "Toggles the CC Display above the nameplate of the adds on/off.",
            get         = function() return RRT.EncounterAlerts[3179] and RRT.EncounterAlerts[3179].CCAddsDisplay end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3179] = RRT.EncounterAlerts[3179] or {}
                RRT.EncounterAlerts[3179].CCAddsDisplay = value
            end,
            nocombat    = true,
            icontexture = 7448212,
            iconsize    = {16, 16},
        },

        -- Vaelgor & Ezzorak
        {
            type = "label",
            get  = function() return "Vaelgor & Ezzorak" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Vaelgor & Ezzorak.",
            get         = function() return RRT.EncounterAlerts[3178] and RRT.EncounterAlerts[3178].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3178] = RRT.EncounterAlerts[3178] or {}
                RRT.EncounterAlerts[3178].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3178)
            end,
            nocombat    = true,
            icontexture = 7448207,
            iconsize    = {16, 16},
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Health Display",
            desc        = "Shows health of Vaelgor & Ezzorak side by side using the text display from the General-Tab.",
            get         = function() return RRT.EncounterAlerts[3178] and RRT.EncounterAlerts[3178].HealthDisplay end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3178] = RRT.EncounterAlerts[3178] or {}
                RRT.EncounterAlerts[3178].HealthDisplay = value
            end,
            nocombat    = true,
            icontexture = 7448207,
            iconsize    = {16, 16},
        },

        -- Lightblinded Vanguard
        {
            type = "label",
            get  = function() return "Lightblinded Vanguard" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Lightblinded Vanguard.",
            get         = function() return RRT.EncounterAlerts[3180] and RRT.EncounterAlerts[3180].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3180] = RRT.EncounterAlerts[3180] or {}
                RRT.EncounterAlerts[3180].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3180)
            end,
            nocombat    = true,
            icontexture = 7448211,
            iconsize    = {16, 16},
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Nameplate Taunt Alerts",
            desc        = "Displays a Taunt label under the boss nameplate when you should taunt during the Judgment cast. The alert clears after you taunt or after 3 seconds. Requires the boss nameplate to be visible when the cast starts. Only active for tanks.",
            get         = function() return RRT.EncounterAlerts[3180] and RRT.EncounterAlerts[3180].TauntAlerts end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3180] = RRT.EncounterAlerts[3180] or {}
                RRT.EncounterAlerts[3180].TauntAlerts = value
            end,
            nocombat    = true,
            icontexture = 7448211,
            iconsize    = {16, 16},
        },

        -- Crown of the Cosmos
        {
            type = "label",
            get  = function() return "Crown of the Cosmos" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Crown of the Cosmos.",
            get         = function() return RRT.EncounterAlerts[3181] and RRT.EncounterAlerts[3181].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3181] = RRT.EncounterAlerts[3181] or {}
                RRT.EncounterAlerts[3181].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3181)
            end,
            nocombat    = true,
            icontexture = 7448205,
            iconsize    = {16, 16},
        },

        -- Chimaerus
        {
            type = "label",
            get  = function() return "Chimaerus" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Chimaerus.",
            get         = function() return RRT.EncounterAlerts[3306] and RRT.EncounterAlerts[3306].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3306] = RRT.EncounterAlerts[3306] or {}
                RRT.EncounterAlerts[3306].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3306)
            end,
            nocombat    = true,
            icontexture = 7448202,
            iconsize    = {16, 16},
        },

        -- Belo'ren
        {
            type = "label",
            get  = function() return "Belo'ren" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Beloren.",
            get         = function() return RRT.EncounterAlerts[3182] and RRT.EncounterAlerts[3182].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3182] = RRT.EncounterAlerts[3182] or {}
                RRT.EncounterAlerts[3182].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3182)
            end,
            nocombat    = true,
            icontexture = 7448203,
            iconsize    = {16, 16},
        },

        -- Midnight Falls
        {
            type = "label",
            get  = function() return "Midnight Falls" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type        = "toggle",
            boxfirst    = true,
            name        = "Generic Alerts",
            desc        = "Enables Alerts for Midnight Falls.",
            get         = function() return RRT.EncounterAlerts[3183] and RRT.EncounterAlerts[3183].enabled end,
            set         = function(self, _, value)
                RRT.EncounterAlerts[3183] = RRT.EncounterAlerts[3183] or {}
                RRT.EncounterAlerts[3183].enabled = value
                RRT_NS:FireCallback("RRT_ALERT_TOGGLE", 3183)
            end,
            nocombat    = true,
            icontexture = 7448204,
            iconsize    = {16, 16},
        },
    }
end

local function BuildCallback()
    return function() end
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.EncounterAlerts = {
    BuildGeneralOptions  = BuildGeneralOptions,
    BuildMidnightOptions = BuildMidnightOptions,
    BuildCallback        = BuildCallback,
    -- Legacy
    BuildOptions         = function() return {} end,
}
