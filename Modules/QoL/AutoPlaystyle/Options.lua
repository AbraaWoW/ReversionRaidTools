local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local function mdb()
    if not RRT or not RRT.AutoPlaystyle then return {} end
    return RRT.AutoPlaystyle
end

local PLAYSTYLE_GLOBALS = {
    "GROUP_FINDER_GENERAL_PLAYSTYLE1",
    "GROUP_FINDER_GENERAL_PLAYSTYLE2",
    "GROUP_FINDER_GENERAL_PLAYSTYLE3",
    "GROUP_FINDER_GENERAL_PLAYSTYLE4",
}
local PLAYSTYLE_FALLBACKS = { "Learning", "Relaxed", "Competitive", "Carry Offered" }

local function GetPlaystyleName(i)
    if PLAYSTYLE_GLOBALS[i] and _G[PLAYSTYLE_GLOBALS[i]] then
        return _G[PLAYSTYLE_GLOBALS[i]]
    end
    return PLAYSTYLE_FALLBACKS[i]
end

local function build_playstyle_options()
    local t = {}
    for i = 1, 4 do
        local idx = i
        tinsert(t, {
            label   = GetPlaystyleName(idx),
            value   = idx,
            onclick = function()
                mdb().playstyle = idx
            end,
        })
    end
    return t
end

local function BuildAutoPlaystyleOptions()
    return {
        {
            type = "label",
            get  = function() return L["ap_header"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle", boxfirst = true,
            name = L["ap_enable"],
            desc = L["ap_enable_desc"],
            get  = function() return mdb().enabled end,
            set  = function(_, _, v) mdb().enabled = v end,
        },
        {
            type = "label",
            get  = function() return L["ap_section_playstyle"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type   = "select",
            name   = L["ap_playstyle_select"],
            desc   = L["ap_playstyle_select_desc"],
            get    = function()
                local ps = mdb().playstyle or 3
                return GetPlaystyleName(ps)
            end,
            values = build_playstyle_options,
        },
    }
end

local function BuildCallback() return function() end end

RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.AutoPlaystyle = {
    BuildOptions  = BuildAutoPlaystyleOptions,
    BuildCallback = BuildCallback,
}
