local _, RRT = ...
local DF = _G["DetailsFramework"]

local function BuildEncounterAlertsOptions()
    return {
        {
            type = "label",
            get = function() return "Midnight S1" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Imperator Averzian",
            desc = "Enables Alerts for Imperator Averzian.",
            get = function() return RRTDB.EncounterAlerts[3176] and RRTDB.EncounterAlerts[3176].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3176] = RRTDB.EncounterAlerts[3176] or {}
                RRTDB.EncounterAlerts[3176].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Vorasius",
            desc = "Enables Alerts for Vorasius.",
            get = function() return RRTDB.EncounterAlerts[3177] and RRTDB.EncounterAlerts[3177].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3177] = RRTDB.EncounterAlerts[3177] or {}
                RRTDB.EncounterAlerts[3177].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Fallen King Salhadaar",
            desc = "Enables Alerts for Fallen King Salhadaar.",
            get = function() return RRTDB.EncounterAlerts[3179] and RRTDB.EncounterAlerts[3179].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3179] = RRTDB.EncounterAlerts[3179] or {}
                RRTDB.EncounterAlerts[3179].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Vaelgor & Ezzorak",
            desc = "Enables Alerts for Vaelgor & Ezzorak.",
            get = function() return RRTDB.EncounterAlerts[3178] and RRTDB.EncounterAlerts[3178].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3178] = RRTDB.EncounterAlerts[3178] or {}
                RRTDB.EncounterAlerts[3178].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lightblinded Vanguard",
            desc = "Enables Alerts for Lightblinded Vanguard.",
            get = function() return RRTDB.EncounterAlerts[3180] and RRTDB.EncounterAlerts[3180].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3180] = RRTDB.EncounterAlerts[3180] or {}
                RRTDB.EncounterAlerts[3180].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Crown of the Cosmos",
            desc = "Enables Alerts for Crown of the Cosmos.",
            get = function() return RRTDB.EncounterAlerts[3181] and RRTDB.EncounterAlerts[3181].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3181] = RRTDB.EncounterAlerts[3181] or {}
                RRTDB.EncounterAlerts[3181].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Chimaerus",
            desc = "Enables Alerts for Chimaerus.",
            get = function() return RRTDB.EncounterAlerts[3306] and RRTDB.EncounterAlerts[3306].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3306] = RRTDB.EncounterAlerts[3306] or {}
                RRTDB.EncounterAlerts[3306].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Beloren",
            desc = "Enables Alerts for Beloren.",
            get = function() return RRTDB.EncounterAlerts[3182] and RRTDB.EncounterAlerts[3182].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3182] = RRTDB.EncounterAlerts[3182] or {}
                RRTDB.EncounterAlerts[3182].enabled = value
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Midnight Falls",
            desc = "Enables Alerts for Midnight Falls.",
            get = function() return RRTDB.EncounterAlerts[3183] and RRTDB.EncounterAlerts[3183].enabled end,
            set = function(self, fixedparam, value)
                RRTDB.EncounterAlerts[3183] = RRTDB.EncounterAlerts[3183] or {}
                RRTDB.EncounterAlerts[3183].enabled = value
            end,
            nocombat = true,
        },
    }
end

local function BuildEncounterAlertsCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.EncounterAlerts = {
    BuildOptions = BuildEncounterAlertsOptions,
    BuildCallback = BuildEncounterAlertsCallback,
}

