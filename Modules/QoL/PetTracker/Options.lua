local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.PetTracker then return {} end
    return RRT.PetTracker
end

local function mod() return RRT_NS.PetTracker end
local function refresh() local m = mod(); if m then m:UpdateDisplay() end end

local function BuildPetTrackerOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["pet_enable"],
            desc = L["pet_enable_desc"],
            get  = function() return RRT and RRT.QoL and RRT.QoL.PetTrackerEnabled end,
            set  = function(_, _, v)
                if RRT and RRT.QoL then RRT.QoL.PetTrackerEnabled = v end
                refresh()
            end,
        },

        {
            type = "label", get = function() return L["pet_conditions_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "toggle", boxfirst = true, name = L["pet_combat_only"],
            desc = L["pet_combat_only_desc"],
            get  = function() return mdb().combatOnly end,
            set  = function(_, _, v) mdb().combatOnly = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["pet_instance_only"],
            desc = L["pet_instance_only_desc"],
            get  = function() return mdb().onlyInInstance end,
            set  = function(_, _, v) mdb().onlyInInstance = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["pet_hide_mounted"],
            desc = L["pet_hide_mounted_desc"],
            get  = function() return mdb().hideWhenMounted end,
            set  = function(_, _, v) mdb().hideWhenMounted = v; refresh() end,
        },
        {
            type = "toggle", boxfirst = true, name = L["pet_warn_passive"],
            desc = L["pet_warn_passive_desc"],
            get  = function() return mdb().showPassive end,
            set  = function(_, _, v) mdb().showPassive = v; refresh() end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.PetTracker = {
    BuildOptions  = BuildPetTrackerOptions,
    BuildCallback = BuildCallback,
}
