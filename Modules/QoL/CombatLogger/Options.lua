local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.CombatLogger then return {} end
    return RRT.CombatLogger
end

local function mod() return RRT_NS.CombatLogger end

local function BuildCombatLoggerOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["cl_enable"],
            desc = L["cl_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v)
                mdb().enabled = v
                local m = mod()
                if m then if v then m:Enable() else m:Disable() end end
            end,
        },

        {
            type = "label", get = function() return L["cl_status_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get  = function()
                local m = mod()
                if m and m:IsLogging() then
                    return "|cFF00FF00Currently logging combat.|r"
                end
                return "|cFFAAAAAACombat log inactive.|r"
            end,
        },

        {
            type = "label", get = function() return L["cl_actions_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "button", name = L["cl_force_zone_check"],
            desc = L["cl_force_zone_check_desc"],
            func = function()
                local m = mod(); if m then m:Enable() end
            end,
        },
        {
            type = "button", name = L["cl_clear_zones"],
            desc = L["cl_clear_zones_desc"],
            func = function()
                if RRT and RRT.CombatLogger then RRT.CombatLogger.instances = {} end
            end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.CombatLogger = {
    BuildOptions  = BuildCombatLoggerOptions,
    BuildCallback = BuildCallback,
}
