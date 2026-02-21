local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI
local LDBIcon = Core.LDBIcon
local build_media_options = Core.build_media_options

local function BuildGeneralOptions()
    local tts_text_preview = ""
    local client = IsWindowsClient()

    return {
        { type = "label", get = function() return "General Options" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Disable Minimap Button",
            desc = "Hide the minimap button.",
            get = function() return RRTDB.Settings["Minimap"].hide end,
            set = function(self, fixedparam, value)
                RRTDB.Settings["Minimap"].hide = value
                if (LDBIcon and LDBIcon.Refresh) then LDBIcon:Refresh("RRT", RRTDB.Settings["Minimap"]) end
            end,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Enable Debug Logging",
            desc = "Enables Debug Logging, which prints a bunch of information and adds it to DevTool. This might Error if you do not have the DevTool Addon installed.",
            get = function() return RRTDB.Settings["DebugLogs"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["DEBUGLOGS"] = true
                RRTDB.Settings["DebugLogs"] = value
            end,
        },

        {
            type = "breakline"
        },
        { type = "label", get = function() return "TTS Options" end,     text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "range",
            name = "TTS Voice",
            desc = "Voice to use for TTS. Most users will only have ~2 different voices. These voices depend on your installed language packs.",
            get = function() return RRTDB.Settings["TTSVoice"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["TTS_VOICE"] = true
                RRTDB.Settings["TTSVoice"] = value
            end,
            min = 1,
            max = client and 20 or 100,
        },
        {
            type = "range",
            name = "TTS Volume",
            desc = "Volume of the TTS",
            get = function() return RRTDB.Settings["TTSVolume"] end,
            set = function(self, fixedparam, value)
                RRTDB.Settings["TTSVolume"] = value
            end,
            min = 0,
            max = 100,
        },
        {
            type = "textentry",
            name = "TTS Preview",
            desc = [[Enter any text to preview TTS

Press 'Enter' to hear the TTS]],
            get = function() return tts_text_preview end,
            set = function(self, fixedparam, value)
                tts_text_preview = value
            end,
            hooks = {
                OnEnterPressed = function(self)
                    RRTAPI:TTS(tts_text_preview, RRTDB.Settings["TTSVoice"])
                end
            }
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable TTS",
            desc = "Enable TTS",
            get = function() return RRTDB.Settings["TTS"] end,
            set = function(self, fixedparam, value)
                RRTUI.OptionsChanged.general["TTS_ENABLED"] = true
                RRTDB.Settings["TTS"] = value
            end,
        },
        {
            type = "breakline",
        },
        {
            type = "button",
            name = "Export Settings",
            desc = "Exports your current settings to a string that can be shared with others.",
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
            name = "Import Settings",
            desc = "Imports settings from a string shared by others. Confirming the Import will force reload your UI for the changes to take effect.",
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
            type = "breakline",
        },

        {
            type = "button",
            name = "Move Text Display",
            desc = "This lets you move the generic text display used for example the ready check module or the assignments on pull.",
            func = function(self)
                if RRT.RRTFrame.generic_display:IsMovable() then
                    RRT:ToggleMoveFrames(RRT.RRTFrame.generic_display, false)
                else
                    RRT.RRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
                    RRT.RRTFrame.generic_display:SetSize(RRT.RRTFrame.generic_display.Text:GetStringWidth(), RRT.RRTFrame.generic_display.Text:GetStringHeight())
                    RRT:ToggleMoveFrames(RRT.RRTFrame.generic_display, true)
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "select",
            name = "Global Font",
            desc = "This changes the Font for everything that doesn't have a specific setting for that. Mainly useful for language compatibility.",
            get = function() return RRTDB.Settings.GlobalFont end,
            values = function() return build_media_options(false, false, false, false, false, true) end,
            nocombat = true,
        },

    }
end

local function BuildGeneralCallback()
    return function()
        wipe(RRTUI.OptionsChanged["general"])
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.General = {
    BuildOptions = BuildGeneralOptions,
    BuildCallback = BuildGeneralCallback,
}





