local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local RRTUI = Core.RRTUI
local build_media_options = Core.build_media_options
local build_growdirection_options = Core.build_growdirection_options
local build_raidframeicon_options = Core.build_raidframeicon_options
local build_sound_dropdown = Core.build_sound_dropdown

local function BuildReminderOptions()
    return {
        {
            type = "label",
            get = function() return "Spell Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return RRTDB.ReminderSettings["SpellTTS"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["SpellTTS"] = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return RRTDB.ReminderSettings["SpellTTSTimer"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["SpellTTSTimer"] = value
                RRT:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return RRTDB.ReminderSettings["SpellDuration"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["SpellDuration"] = value
                RRT:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return RRTDB.ReminderSettings["SpellCountdown"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["SpellCountdown"] = value
                RRT:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'SpellName in 10'",
            get = function() return RRTDB.ReminderSettings["AnnounceSpellDuration"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["AnnounceSpellDuration"] = value
                RRT:ProcessReminder()

            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "SpellName",
            desc = "Display the SpellName if no text is provided",
            get = function() return RRTDB.ReminderSettings["SpellName"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["SpellName"] = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "SpellName TTS if empty",
            desc = "This will make it so that the SpellName is still played as TTS even if the text of the reminder remains empty (so even if you have 'SpellName' unticked).",
            get = function() return RRTDB.ReminderSettings.SpellNameTTS end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.SpellNameTTS = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Bars",
            desc = "Show Progress Bars instead of icons",
            get = function() return RRTDB.ReminderSettings["Bars"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["Bars"] = value
            end,
            nocombat = true,
        },
        {
            type = "range",
            boxfirst = true,
            name = "Sticky",
            desc = "Keep Reminders shown for X seconds if the spell hasn't been pressed yet",
            get = function() return RRTDB.ReminderSettings["Sticky"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["Sticky"] = value
            end,
            nocombat = true,
            min = 0,
            max = 10,
        },
        {
            type = "label",
            get = function() return "Text Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRTDB.ReminderSettings.TextSettings.GrowDirection end,
            values = function() return build_growdirection_options("TextSettings") end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "TTS",
            desc = "Whether a TTS sound should be played",
            get = function() return RRTDB.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["TextTTS"] = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "TTSTimer",
            desc = "At how much remaining Time the TTS should be played",
            get = function() return RRTDB.ReminderSettings["TextTTSTimer"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["TextTTSTimer"] = value
                RRT:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = "Duration",
            desc = "How long a reminder should be shown for",
            get = function() return RRTDB.ReminderSettings["TextDuration"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["TextDuration"] = value
                RRT:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Countdown",
            desc = "Whether or not you want a countdown for these reminders. 0 = disabled",
            get = function() return RRTDB.ReminderSettings["TextCountdown"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["TextCountdown"] = value
                RRT:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Announce Duration",
            desc = "When TTS is played, this will also announce the remaining duration of the reminder. So for example it could say 'Spread in 10'",
            get = function() return RRTDB.ReminderSettings["AnnounceTextDuration"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["AnnounceTextDuration"] = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return RRTDB.ReminderSettings.TextSettings.Font end,
            values = function() return build_media_options("TextSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return RRTDB.ReminderSettings.TextSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.TextSettings.FontSize = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },

        {
            type = "color",
            name = "Text-Color",
            desc = "Color of Text-Reminders",
            get = function() return RRTDB.ReminderSettings.TextSettings.colors end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.TextSettings.colors = {r, g, b, a}
                RRT:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Text reminders",
            get = function() return RRTDB.ReminderSettings.TextSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.TextSettings["Spacing"] = value
                RRT:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRTDB.ReminderSettings.IconSettings.GrowDirection end,
            values = function() return build_growdirection_options("IconSettings", true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return RRTDB.ReminderSettings.IconSettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.Width = value
                RRT:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return RRTDB.ReminderSettings.IconSettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.Height = value
                RRT:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },

        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return RRTDB.ReminderSettings.IconSettings.Font end,
            values = function() return build_media_options("IconSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return RRTDB.ReminderSettings.IconSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.FontSize = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Text-X-Offset",
            desc = "X-Offset of the Text of the Icon",
            get = function() return RRTDB.ReminderSettings.IconSettings.xTextOffset end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.xTextOffset = value
                RRT:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = "Text-Y-Offset",
            desc = "Y-Offset of the Text of the Icon",
            get = function() return RRTDB.ReminderSettings.IconSettings.yTextOffset end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.yTextOffset = value
                RRT:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "toggle",
            name = "Right-Aligned Text",
            desc = "Change the Text to be right-aligned, you still have to fix the offset yourself.",
            get = function() return RRTDB.ReminderSettings.IconSettings.RightAlignedText end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.RightAlignedText = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return RRTDB.ReminderSettings.IconSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings.TimerFontSize = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Icon reminders",
            get = function() return RRTDB.ReminderSettings.IconSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings["Spacing"] = value
                RRT:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Glow",
            desc = "At how many seconds you want the Icon to start glowing. 0 = disabled",
            get = function() return RRTDB.ReminderSettings.IconSettings["Glow"] or 0 end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.IconSettings["Glow"] = value
                RRT:UpdateExistingFrames()
            end,
            min = 0,
            max = 30,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Timer Text",
            desc = "Hides the Timer Text shown on the Icon",
            get = function() return RRTDB.ReminderSettings["HideTimerText"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["HideTimerText"] = value
                RRT:UpdateExistingFrames()
            end,
            nocombat = true,
        },

        {
            type = "label",
            get = function() return "Bar Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = "Grow Direction",
            desc = "Grow Direction",
            get = function() return RRTDB.ReminderSettings.BarSettings.GrowDirection end,
            values = function() return build_growdirection_options("BarSettings") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Width",
            desc = "Width of the Bar",
            get = function() return RRTDB.ReminderSettings.BarSettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.BarSettings.Width = value
                RRT:UpdateExistingFrames()
            end,
            min = 80,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = "Bar-Height",
            desc = "Height of the Bar",
            get = function() return RRTDB.ReminderSettings.BarSettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.BarSettings.Height = value
                RRT:UpdateExistingFrames()
            end,
            min = 10,
            max = 100,
            nocombat = true,
        },
        {
            type = "select",
            name = "Texture",
            desc = "Texture",
            get = function() return RRTDB.ReminderSettings.BarSettings.Texture end,
            values = function() return build_media_options("BarSettings", "Texture", true) end,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font",
            get = function() return RRTDB.ReminderSettings.BarSettings.Font end,
            values = function() return build_media_options("BarSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font Size",
            get = function() return RRTDB.ReminderSettings.BarSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.BarSettings.FontSize = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = "Timer-Text Font-Size",
            desc = "Font Size of the Timer-Text",
            get = function() return RRTDB.ReminderSettings.BarSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.BarSettings.TimerFontSize = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "color",
            name = "Bar-Color",
            desc = "Color of the Bars",
            get = function() return RRTDB.ReminderSettings.BarSettings.colors end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.BarSettings.colors = {r, g, b, a}
                RRT:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = "Spacing",
            desc = "Spacing between Bar reminders",
            get = function() return RRTDB.ReminderSettings.BarSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.BarSettings["Spacing"] = value
                RRT:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return "Raidframe Icon Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range",
            name = "Icon-Width",
            desc = "Width of the Icon",
            get = function() return RRTDB.ReminderSettings.UnitIconSettings.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.UnitIconSettings.Width = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "Icon-Height",
            desc = "Height of the Icon",
            get = function() return RRTDB.ReminderSettings.UnitIconSettings.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.UnitIconSettings.Height = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "select",
            name = "Position",
            desc = "position on the raidframe",
            get = function() return RRTDB.ReminderSettings.UnitIconSettings.Position end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = "x-Offset",
            desc = "",
            get = function() return RRTDB.ReminderSettings.UnitIconSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.UnitIconSettings.xOffset= value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = "y-Offset",
            desc = "",
            get = function() return RRTDB.ReminderSettings.UnitIconSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.UnitIconSettings.yOffset = value
                RRT:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },

        {
            type = "color",
            name = "Glow-Color",
            desc = "Color of Raidframe Glows",
            get = function() return RRTDB.ReminderSettings.GlowSettings.colors end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.GlowSettings.colors = {r, g, b, a}
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "label",
            get = function() return "Universal Settings" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Play Sound instead of TTS",
            desc = "This will play the selected sound for all reminders instead of using TTS as long as the TTS&Sound fields are empty. The time the sound is played at still uses the TTSTimer value. This also means that any setting that converts the spellName into TTS for example also needs to be disabled for this to work.",
            get = function() return RRTDB.ReminderSettings["PlayDefaultSound"] end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings["PlayDefaultSound"] = value
                RRT:ProcessReminder()
            end,
            nocombat = true,
        },

        {
            type = "select",
            name = "Sound",
            desc = "Sound",
            get = function() return RRTDB.ReminderSettings.DefaultSound end,
            values = function() return build_sound_dropdown() end,
            nocombat = true,
        },

        {
            type = "breakline",
        },

        {
            type = "label",
            get = function() return "Manage Reminders" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = "Preview Alerts",
            desc = "Preview Reminders and unlock their anchors to move them around",
            func = function(self)
                if RRT.PreviewTimer then
                    RRT.PreviewTimer:Cancel()
                    RRT.PreviewTimer = nil
                end
                if RRT.IsInPreview then
                    RRT.IsInPreview = false
                    RRT:HideAllReminders()
                    for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                        if RRT[v] then
                            RRT[v]:StopMovingOrSizing()
                        end
                        RRT:ToggleMoveFrames(RRT[v], false)
                    end
                    return
                end
                RRT.PreviewTimer = C_Timer.NewTimer(12, function()
                    if RRT.IsInPreview then
                        RRT.IsInPreview = false
                        RRT:HideAllReminders()
                        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                            if RRT[v] then
                                RRT[v]:StopMovingOrSizing()
                            end
                            RRT:ToggleMoveFrames(RRT[v], false)
                        end
                    end
                end)
                RRT.IsInPreview = true
                for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                    RRT:ToggleMoveFrames(RRT[v], true)
                end
                RRT:UpdateExistingFrames()
                RRT.AllGlows = RRT.AllGlows or {}
                local MyFrame = RRT.LGF.GetUnitFrame("player")
                RRT.PlayedSound = {}
                RRT.StartedCountdown = {}
                RRT.GlowStarted = {}
                local info1 = {
                    text = "Personals",
                    phase = 1,
                    id = 1,
                    TTS = RRTDB.ReminderSettings.TextTTS and "Personals",
                    TTSTimer = RRTDB.ReminderSettings.TextTTSTimer,
                    countdown = RRTDB.ReminderSettings.TextCountdown,
                    dur = RRTDB.ReminderSettings.TextDuration,
                }
                RRT:DisplayReminder(info1)
                local info2 = {
                    text = "Stack on |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t",
                    phase = 1,
                    id = 2,
                    TTS = false,
                    TTSTimer = RRTDB.ReminderSettings.TextTTSTimer,
                    countdown = false,
                    dur = RRTDB.ReminderSettings.TextDuration,
                }
                RRT:DisplayReminder(info2)
                local info3 = {
                    text = "Give Ironbark",
                    IconOverwrite = true,
                    spellID = 102342,
                    phase = 1,
                    id = 3,
                    TTS = RRTDB.ReminderSettings.SpellTTS and "Give Ironbark",
                    TTSTimer = RRTDB.ReminderSettings.SpellTTSTimer,
                    countdown = RRTDB.ReminderSettings.SpellCountdown,
                    dur = RRTDB.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                RRT:DisplayReminder(info3)
                local info4 = {
                    text = RRTDB.ReminderSettings.SpellName and C_Spell.GetSpellInfo(115203).name,
                    IconOverwrite = true,
                    spellID = 115203,
                    phase = 1,
                    id = 4,
                    TTS = false,
                    TTSTimer = RRTDB.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = RRTDB.ReminderSettings.SpellDuration,
                }
                RRT:DisplayReminder(info4)
                local info5 = {
                    text = "Breath",
                    BarOverwrite = true,
                    spellID = 1256855,
                    phase = 1,
                    id = 5,
                    TTS = false,
                    TTSTimer = RRTDB.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = RRTDB.ReminderSettings.SpellDuration,
                    glowunit = {"player"},
                }
                RRT:DisplayReminder(info5)
                local info6 = {
                    text = "Dodge",
                    BarOverwrite = true,
                    spellID = 193171,
                    phase = 1,
                    id = 6,
                    TTS = false,
                    TTSTimer = RRTDB.ReminderSettings.SpellTTSTimer,
                    countdown = false,
                    dur = RRTDB.ReminderSettings.SpellDuration,
                }
                RRT:DisplayReminder(info6)
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use Shared Reminders",
            desc = "Enables reminders set by the raidleader or shared by an assist",
            get = function() return RRTDB.ReminderSettings.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.enabled = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use Personal Reminders",
            desc = "Enables reminders set into your personal reminder",
            get = function() return RRTDB.ReminderSettings.PersNote end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.PersNote = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Use MRT Note Reminders",
            desc = "Enables reminders entered into MRT note",
            get = function() return RRTDB.ReminderSettings.MRTNote end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.MRTNote = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = "Shared Reminders",
            desc = "Shows a list of all Reminders",
            func = function(self)
                if not RRTUI.reminders_frame:IsShown() then
                    RRTUI.reminders_frame:Show()
                else
                    RRTUI.reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "button",
            name = "Personal Reminders",
            desc = "Shows a list of all Personal Reminders",
            func = function(self)
                if not RRTUI.personal_reminders_frame:IsShown() then
                    RRTUI.personal_reminders_frame:Show()
                else
                    RRTUI.personal_reminders_frame:Hide()
                end
            end,
            nocombat = true,
            spacement = true
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Share on Ready Check",
            desc = "Automatically share the current active reminder on ready check if you are the raidleader.",
            get = function() return RRTDB.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = "Use TimelineReminders",
            desc = "Toggling this on will make RRTDB not display any reminders, but still allow TimelineReminders to read any shared or personal reminder you have and also allow the Note-Display to work.",
            get = function() return RRTDB.ReminderSettings.UseTimelineReminders end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.UseTimelineReminders = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(true)
                RRT:FireCallback("RRT_REMINDER_CHANGED", RRT.PersonalReminder, RRT.Reminder)
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = "Test Active Reminder",
            desc = "Runs a test for the currently active reminder. This will only show phase 1 timers. Press again to cancel the test.",
            func = function(self)
                if not RRT.TestingReminder then
                    RRT.TestingReminder = true
                    RRT:StartReminders(1, true)
                else
                    RRT.TestingReminder = false
                    RRT:HideAllReminders()
                end
            end,
            nocombat = true,
            spacement = true
        },
    }
end

local function BuildReminderNoteOptions()
    return {
        {
            type = "label",
            get = function() return "This tab is purely for Settings to display Reminders as a Note on-screen. They have no effect on how the in-combat alerts work.\nThere are 3 types of displays. The first one shows all reminders, the second one shows only those that will activate for you. And the third shows all text that is not a reminder." end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "All Reminders Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Toggle All Reminders",
            desc = "Locks/Unlocks the All Reminders Note to be moved around",
            func = function(self)
                if RRT.ReminderFrameMover and RRT.ReminderFrameMover:IsMovable() then
                    RRT:UpdateReminderFrame(false, true)
                    RRT:ToggleMoveFrames(RRT.ReminderFrameMover, false)
                    RRT.ReminderFrameMover.Resizer:Hide()
                    RRT.ReminderFrameMover:SetResizable(false)
                    RRTDB.ReminderSettings.ReminderFrame.Moveable = false
                else
                    RRT:UpdateReminderFrame(false, true)
                    RRT:ToggleMoveFrames(RRT.ReminderFrameMover, true)
                    RRT.ReminderFrameMover.Resizer:Show()
                    RRT.ReminderFrameMover:SetResizable(true)
                    RRT.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRTDB.ReminderSettings.ReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show All Reminders Note",
            desc = "Whether you want to show the All Reminders Note on screen permanently",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ReminderFrame.enabled = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the All Reminders Note",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ReminderFrame.FontSize = value
                RRT:UpdateReminderFrame(false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the All Reminders Note",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.Font end,
            values = function()
                return build_media_options("ReminderFrame", "Font", false, true, false)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the All Reminders Note",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ReminderFrame.Width = value
                RRT:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the All Reminders Note",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ReminderFrame.Height = value
                RRT:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the All Reminders Note when unlocked",
            get = function() return RRTDB.ReminderSettings.ReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.ReminderFrame.BGcolor = {r, g, b, a}
                RRT:UpdateReminderFrame(false, true)
            end,
            hasAlpha = true,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text-Note in All Reminders Note",
            desc = "Display the Text-Note inside the All Reminders Note.",
            get = function() return RRTDB.ReminderSettings.TextInSharedNote end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.TextInSharedNote = value
                RRT:UpdateReminderFrame(false, true)
            end,
        },
        {
            type = "label",
            get = function() return "Universal Settings - these apply to all 3 Notes" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide Player-Names in Note",
            desc = "Hides the Player Names for Reminders in the Note.",
            get = function() return RRTDB.ReminderSettings.HidePlayerNames end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.HidePlayerNames = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Only Spell-Reminders",
            desc = "With this enabled you will only see Spell-Reminders in your notes.",
            get = function() return RRTDB.ReminderSettings.OnlySpellReminders end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.OnlySpellReminders = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(false, true)
            end,
        },
        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Personal Reminder-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Toggle Pers Reminder",
            desc = "Locks/Unlocks the Personal Reminders Note to be moved around",
            func = function(self)
                if RRT.PersonalReminderFrameMover and RRT.PersonalReminderFrameMover:IsMovable() then
                    RRT:UpdateReminderFrame(false, false, true)
                    RRT:ToggleMoveFrames(RRT.PersonalReminderFrameMover, false)
                    RRT.PersonalReminderFrameMover.Resizer:Hide()
                    RRT.PersonalReminderFrameMover:SetResizable(false)
                    RRTDB.ReminderSettings.PersonalReminderFrame.Moveable = false
                else
                    RRT:UpdateReminderFrame(false, false, true)
                    RRT:ToggleMoveFrames(RRT.PersonalReminderFrameMover, true)
                    RRT.PersonalReminderFrameMover.Resizer:Show()
                    RRT.PersonalReminderFrameMover:SetResizable(true)
                    RRT.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRTDB.ReminderSettings.PersonalReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Personal Reminder Note",
            desc = "Whether you want to display the Note for Reminders only relevant to you",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.PersonalReminderFrame.enabled = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Personal Reminders Note",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.PersonalReminderFrame.FontSize = value
                RRT:UpdateReminderFrame(false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Personal Reminders Note",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.Font end,
            values = function()
                return build_media_options("PersonalReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Personal Reminders Note",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.PersonalReminderFrame.Width = value
                RRT:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Personal Reminders Note",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.PersonalReminderFrame.Height = value
                RRT:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Personal Reminders Note when unlocked",
            get = function() return RRTDB.ReminderSettings.PersonalReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.PersonalReminderFrame.BGcolor = {r, g, b, a}
                RRT:UpdateReminderFrame(false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text-Note in Personal Reminders Note",
            desc = "Display the Text-Note inside the Personal Reminders Note.",
            get = function() return RRTDB.ReminderSettings.TextInPersonalNote end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.TextInPersonalNote = value
                RRT:UpdateReminderFrame(true)
            end,
        },

        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Text-Note" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = "Toggle Text Note",
            desc = "Locks/Unlocks the Text Note to be moved around. This Note shows anything from the reminders that it is not an actual reminder string. So you can put any text in there to be displayed.",
            func = function(self)
                if RRT.ExtraReminderFrameMover and RRT.ExtraReminderFrameMover:IsMovable() then
                    RRT:UpdateReminderFrame(false, false, false, true)
                    RRT:ToggleMoveFrames(RRT.ExtraReminderFrameMover, false)
                    RRT.ExtraReminderFrameMover.Resizer:Hide()
                    RRT.ExtraReminderFrameMover:SetResizable(false)
                    RRTDB.ReminderSettings.ExtraReminderFrame.Moveable = false
                else
                    RRT:UpdateReminderFrame(false, false, false, true)
                    RRT:ToggleMoveFrames(RRT.ExtraReminderFrameMover, true)
                    RRT.ExtraReminderFrameMover.Resizer:Show()
                    RRT.ExtraReminderFrameMover:SetResizable(true)
                    RRT.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRTDB.ReminderSettings.ExtraReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Text Note",
            desc = "Whether you want to display the Text-Note",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ExtraReminderFrame.enabled = value
                RRT:ProcessReminder()
                RRT:UpdateReminderFrame(false, false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Font-Size",
            desc = "Font-Size of the Text-Note",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ExtraReminderFrame.FontSize = value
                RRT:UpdateReminderFrame(false, false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = "Font",
            desc = "Font of the Text-Note",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.Font end,
            values = function()
                return build_media_options("ExtraReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Width",
            desc = "Width of the Text-Note",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ExtraReminderFrame.Width = value
                RRT:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = "Height",
            desc = "Height of the Text-Note",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRTDB.ReminderSettings.ExtraReminderFrame.Height = value
                RRT:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = "Background-Color",
            desc = "Color of the Background of the Text-Note when unlocked",
            get = function() return RRTDB.ReminderSettings.ExtraReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRTDB.ReminderSettings.ExtraReminderFrame.BGcolor = {r, g, b, a}
                RRT:UpdateReminderFrame(false, false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "breakline",
            spacement = true,
        },
        {
            type = "label",
            get = function() return "" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return "Timeline" end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = "Open Timeline",
            desc = "Opens the Timeline window (Also opened by the `/ns tl` or `/ns timeline` slash command)",
            func = function(self)
                RRT:ToggleTimelineWindow()
            end,
            spacement = true,
            button_template = DF:GetTemplate("button", "details_forge_button_template"),

        }
    }
end

local function BuildReminderCallback()
    return function()
        -- No specific callback needed
    end
end

local function BuildReminderNoteCallback()
    return function()
        -- No specific callback needed
    end
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.Reminders = {
    BuildOptions = BuildReminderOptions,
    BuildNoteOptions = BuildReminderNoteOptions,
    BuildCallback = BuildReminderCallback,
    BuildNoteCallback = BuildReminderNoteCallback,
}



