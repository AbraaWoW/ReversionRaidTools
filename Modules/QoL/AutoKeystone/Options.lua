local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.AutoKeystone then return {} end
    return RRT.AutoKeystone
end

local function BuildAutoKeystoneOptions()
    return {
        {
            type = "label",
            get  = function() return L["ak_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true,
            name = L["ak_enable"],
            desc = L["ak_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v end,
        },
        {
            type = "label",
            get  = function() return " " end,
        },
        {
            type = "label",
            get  = function() return "|cFFAAAAAA" .. L["ak_note"] .. "|r" end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.AutoKeystone = {
    BuildOptions  = BuildAutoKeystoneOptions,
    BuildCallback = BuildCallback,
}
