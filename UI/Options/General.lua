local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local LDBIcon = Core.LDBIcon
local build_media_options = Core.build_media_options
local L = RRT_NS.L

local LANG_OPTIONS = {
    { label = "English", value = 1, lang = "EN" },
    { label = "Français", value = 2, lang = "FR" },
}
local function build_language_options()
    local t = {}
    for i, v in ipairs(LANG_OPTIONS) do
        local lang = v.lang
        tinsert(t, {
            label = v.label,
            value = i,
            onclick = function()
                RRT.Settings.Language = lang
                print("|cFFBB66FFReversion Raid Tools:|r Language set to " .. v.label .. ". Type /reload to apply.")
            end
        })
    end
    return t
end

local CLASS_TAB_COLORS = {
    { name = "Death Knight",     hex = "C41E3A", color = {0.769, 0.118, 0.227, 1} },
    { name = "Demon Hunter",     hex = "A330C9", color = {0.639, 0.188, 0.788, 1} },
    { name = "Druid",            hex = "FF7C0A", color = {1.000, 0.486, 0.039, 1} },
    { name = "Evoker",           hex = "33937F", color = {0.200, 0.576, 0.498, 1} },
    { name = "Hunter",           hex = "AAD372", color = {0.667, 0.827, 0.447, 1} },
    { name = "Mage",             hex = "3FC7EB", color = {0.247, 0.780, 0.922, 1} },
    { name = "Monk",             hex = "00FF98", color = {0.000, 1.000, 0.596, 1} },
    { name = "Paladin",          hex = "F48CBA", color = {0.957, 0.549, 0.729, 1} },
    { name = "Priest",           hex = "FFFFFF", color = {1.000, 1.000, 1.000, 1} },
    { name = "Rogue",            hex = "FFF468", color = {1.000, 0.957, 0.408, 1} },
    { name = "Shaman",           hex = "0070DD", color = {0.000, 0.439, 0.867, 1} },
    { name = "Warlock",          hex = "8788EE", color = {0.529, 0.533, 0.933, 1} },
    { name = "Warrior",          hex = "C69B3A", color = {0.776, 0.608, 0.227, 1} },
}

local function ApplyTabSelectionColor(r, g, b, a)
    local tabContainer = RRTUI.MenuFrame
    if not tabContainer then return end
    RRT.Settings.TabSelectionColor = {r, g, b, a}
    tabContainer.ButtonSelectedBorderColor = RRT.Settings.TabSelectionColor
    for _, btn in ipairs(tabContainer.AllButtons) do
        if btn.selectedUnderlineGlow then
            btn.selectedUnderlineGlow:SetVertexColor(r, g, b, a)
        end
    end
    tabContainer:SelectTabByIndex(tabContainer.CurrentIndex)
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    for _, cb in ipairs(RRT_NS.ThemeColorCallbacks) do
        cb(r, g, b, a)
    end
end

local function build_class_color_options()
    local t = {}
    for i, v in ipairs(CLASS_TAB_COLORS) do
        local c = v.color
        tinsert(t, {
            label = "|cFF" .. v.hex .. v.name .. "|r",
            value = i,
            onclick = function()
                ApplyTabSelectionColor(c[1], c[2], c[3], c[4])
            end,
        })
    end
    return t
end

local function GetCurrentTabColorName()
    local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    for _, v in ipairs(CLASS_TAB_COLORS) do
        if math.abs(v.color[1] - c[1]) < 0.01 and
           math.abs(v.color[2] - c[2]) < 0.01 and
           math.abs(v.color[3] - c[3]) < 0.01 then
            return "|cFF" .. v.hex .. v.name .. "|r"
        end
    end
    return CLASS_TAB_COLORS[1].name
end

local function BuildGeneralOptions()
    local tts_text_preview = ""
    local client = IsWindowsClient()

    return {
        { type = "label", get = function() return L["header_general_options"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            name = L["opt_language"],
            desc = L["opt_language_desc"],
            values = build_language_options,
            get = function()
                local lang = RRT.Settings.Language or "EN"
                for _, v in ipairs(LANG_OPTIONS) do
                    if v.lang == lang then return v.label end
                end
                return "English"
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["gen_minimap_disable"],
            desc = L["gen_minimap_disable_desc"],
            get = function() return RRT.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                RRT.Settings["Minimap"].hide = value
                LDBIcon:Refresh("RRT", RRT.Settings["Minimap"])
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["gen_debug_logging"],
            desc = L["gen_debug_logging_desc"],
            get = function() return RRT.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["DEBUGLOGS"] = true
                RRT.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["opt_rl_alias"],
            desc = L["opt_rl_alias_desc"],
            get = function() return RRT.Settings["RLAlias"] end,
            set = function(self, fixedparam, value)
                RRT.Settings["RLAlias"] = value
            end,
        },


        {
            type = "breakline"
        },
        { type = "label", get = function() return L["gen_ui_appearance"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "select",
            name = L["gen_tab_color"],
            desc = L["gen_tab_color_desc"],
            get = GetCurrentTabColorName,
            values = build_class_color_options,
        },
        {
            type = "breakline"
        },
        { type = "label", get = function() return L["gen_tts_options"] end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "range",
            name = L["gen_tts_voice"],
            desc = L["gen_tts_voice_desc"],
            get = function() return RRT.Settings["TTSVoice"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["TTS_VOICE"] = true
                RRT.Settings["TTSVoice"] = value
            end,
            min = 1,
            max = client and 20 or 100,
        },
        {
            type = "range",
            name = L["gen_tts_volume"],
            desc = L["gen_tts_volume_desc"],
            get = function() return RRT.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                RRT.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = L["gen_tts_preview"],
            desc = L["gen_tts_preview_desc"],
            get = function() return tts_text_preview end,
            set = function(self, fixedparam, value)
                tts_text_preview = value
            end,
            hooks = {
                OnEnterPressed = function(self)
                    RRTAPI:TTS(tts_text_preview, RRT.Settings["TTSVoice"])
                end
            }
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["gen_tts_enable"],
            desc = L["gen_tts_enable_desc"],
            get = function() return RRT.Settings["TTS"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["TTS_ENABLED"] = true
                RRT.Settings["TTS"] = value
            end,
        },
        {
            type = "breakline",
        },
        {
            type = "button",
            name = L["gen_export"],
            desc = L["gen_export_desc"],
            func = function(self)
                if RRTUI.export_string_popup:IsShown() then
                    RRTUI.export_string_popup:Hide()
                else
                    RRTUI.export_string_popup:Show()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = L["gen_import"],
            desc = L["gen_import_desc"],
            func = function(self)
                if RRTUI.import_string_popup:IsShown() then
                    RRTUI.import_string_popup:Hide()
                else
                    RRTUI.import_string_popup:Show()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = L["gen_global_font"],
            desc = L["gen_global_font_desc"],
            get = function() return RRT.Settings.GlobalFont end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["gen_global_font_size"],
            desc = L["gen_global_font_size_desc"],
            get = function() return RRT.Settings["GlobalFontSize"] end,
            set = function(self, fixedparam, value)
                RRT.Settings["GlobalFontSize"] = value
                RRT_NS:ApplyGlobalFont()
            end,
            min = 0,
            max = 100,
        },
    }
end

local function BuildGeneralCallback()
    return function()
        wipe(RRTUI.OptionsChanged["general"])
    end
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.General = {
    BuildOptions = BuildGeneralOptions,
    BuildCallback = BuildGeneralCallback,
}
