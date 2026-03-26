local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.DontRelease then return {} end
    return RRT.DontRelease
end

local function BuildDontReleaseOptions()
    return {
        {
            type = "toggle", boxfirst = true, name = L["dnr_enable"],
            desc = L["dnr_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v end,
        },

        {
            type = "label", get = function() return L["dnr_how_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get  = function()
                return L["dnr_how_text"]
            end,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.DontRelease = {
    BuildOptions  = BuildDontReleaseOptions,
    BuildCallback = BuildCallback,
}
