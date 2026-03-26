local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

local Core = RRT_NS.UI.Core
local RRTUI = Core.RRTUI
local build_media_options = Core.build_media_options
local build_growdirection_options = Core.build_growdirection_options
local build_raidframeicon_options = Core.build_raidframeicon_options
local build_sound_dropdown = Core.build_sound_dropdown

local function BuildReminderOptions()
    return {
        {
            type = "label",
            get = function() return L["rem_spell_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_tts"],
            desc = L["rem_tts_desc"],
            get = function() return RRT.ReminderSettings["SpellTTS"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["SpellTTS"] = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_tts_timer"],
            desc = L["rem_tts_timer_desc"],
            get = function() return RRT.ReminderSettings["SpellTTSTimer"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["SpellTTSTimer"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = L["rem_duration"],
            desc = L["rem_duration_desc"],
            get = function() return RRT.ReminderSettings["SpellDuration"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["SpellDuration"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_countdown"],
            desc = L["rem_countdown_desc"],
            get = function() return RRT.ReminderSettings["SpellCountdown"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["SpellCountdown"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_announce_dur"],
            desc = L["rem_announce_dur_spell_desc"],
            get = function() return RRT.ReminderSettings["AnnounceSpellDuration"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["AnnounceSpellDuration"] = value
                RRT_NS:ProcessReminder()

            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_spellname"],
            desc = L["rem_spellname_desc"],
            get = function() return RRT.ReminderSettings["SpellName"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["SpellName"] = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_spellname_tts"],
            desc = L["rem_spellname_tts_desc"],
            get = function() return RRT.ReminderSettings.SpellNameTTS end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.SpellNameTTS = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_bars"],
            desc = L["rem_bars_desc"],
            get = function() return RRT.ReminderSettings["Bars"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["Bars"] = value
            end,
            nocombat = true,
        },
        {
            type = "range",
            boxfirst = true,
            name = L["rem_sticky"],
            desc = L["rem_sticky_desc"],
            get = function() return RRT.ReminderSettings["Sticky"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["Sticky"] = value
            end,
            nocombat = true,
            min = 0,
            max = 10,
        },
        {
            type = "label",
            get = function() return L["rem_text_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["rem_grow_dir"],
            desc = L["rem_grow_dir_desc"],
            get = function() return RRT.ReminderSettings.TextSettings.GrowDirection end,
            values = function() return build_growdirection_options("TextSettings") end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_tts"],
            desc = L["rem_tts_desc"],
            get = function() return RRT.ReminderSettings["TextTTS"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["TextTTS"] = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_tts_timer"],
            desc = L["rem_tts_timer_desc"],
            get = function() return RRT.ReminderSettings["TextTTSTimer"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["TextTTSTimer"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 0,
            max = 20,
            nocombat = true,
        },

        {
            type = "range",
            name = L["rem_duration"],
            desc = L["rem_duration_desc"],
            get = function() return RRT.ReminderSettings["TextDuration"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["TextDuration"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_countdown"],
            desc = L["rem_countdown_desc"],
            get = function() return RRT.ReminderSettings["TextCountdown"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["TextCountdown"] = value
                RRT_NS:ProcessReminder()
            end,
            min = 0,
            max = 5,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_announce_dur"],
            desc = L["rem_announce_dur_text_desc"],
            get = function() return RRT.ReminderSettings["AnnounceTextDuration"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["AnnounceTextDuration"] = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["rem_font"],
            desc = L["rem_font_desc"],
            get = function() return RRT.ReminderSettings.TextSettings.Font end,
            values = function() return build_media_options("TextSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_font_size"],
            desc = L["rem_font_size_desc"],
            get = function() return RRT.ReminderSettings.TextSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.TextSettings.FontSize = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },

        {
            type = "color",
            name = L["rem_text_color"],
            desc = L["rem_text_color_desc"],
            get = function() return RRT.ReminderSettings.TextSettings.colors end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.TextSettings.colors = {r, g, b, a}
                RRT_NS:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = L["rem_spacing"],
            desc = L["rem_spacing_text_desc"],
            get = function() return RRT.ReminderSettings.TextSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.TextSettings["Spacing"] = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_center_aligned"],
            desc = L["rem_center_aligned_desc"],
            get = function() return RRT.ReminderSettings.TextSettings.CenterAligned end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.TextSettings.CenterAligned = value
                RRT_NS:UpdateExistingFrames()
            end,
            nocombat = true,
        },

        {
            type = "breakline"
        },
        {
            type = "label",
            get = function() return L["rem_icon_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["rem_grow_dir"],
            desc = L["rem_grow_dir_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.GrowDirection end,
            values = function() return build_growdirection_options("IconSettings", true) end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_icon_width"],
            desc = L["rem_icon_width_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.Width = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_icon_height"],
            desc = L["rem_icon_height_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.Height = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 20,
            max = 200,
            nocombat = true,
        },

        {
            type = "select",
            name = L["rem_font"],
            desc = L["rem_font_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.Font end,
            values = function() return build_media_options("IconSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_font_size"],
            desc = L["rem_font_size_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.FontSize = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_text_x_offset"],
            desc = L["rem_text_x_offset_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.xTextOffset end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.xTextOffset = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_text_y_offset"],
            desc = L["rem_text_y_offset_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.yTextOffset end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.yTextOffset = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = -500,
            max = 500,
            nocombat = true,
        },
        {
            type = "toggle",
            name = L["rem_right_aligned"],
            desc = L["rem_right_aligned_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.RightAlignedText end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.RightAlignedText = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_timer_font_size"],
            desc = L["rem_timer_font_size_desc"],
            get = function() return RRT.ReminderSettings.IconSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings.TimerFontSize = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_spacing"],
            desc = L["rem_spacing_icon_desc"],
            get = function() return RRT.ReminderSettings.IconSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings["Spacing"] = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = -5,
            max = 20,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_icon_glow"],
            desc = L["rem_icon_glow_desc"],
            get = function() return RRT.ReminderSettings.IconSettings["Glow"] or 0 end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.IconSettings["Glow"] = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 0,
            max = 30,
            nocombat = true,
        },

        {
            type = "label",
            get = function() return L["rem_bar_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "select",
            name = L["rem_grow_dir"],
            desc = L["rem_grow_dir_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.GrowDirection end,
            values = function() return build_growdirection_options("BarSettings") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_bar_width"],
            desc = L["rem_bar_width_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.BarSettings.Width = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 80,
            max = 500,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_bar_height"],
            desc = L["rem_bar_height_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.BarSettings.Height = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 10,
            max = 100,
            nocombat = true,
        },
        {
            type = "select",
            name = L["rem_texture"],
            desc = L["rem_texture_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.Texture end,
            values = function() return build_media_options("BarSettings", "Texture", true) end,
            nocombat = true,
        },
        {
            type = "select",
            name = L["rem_font"],
            desc = L["rem_font_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.Font end,
            values = function() return build_media_options("BarSettings", "Font") end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_font_size"],
            desc = L["rem_font_size_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.BarSettings.FontSize = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_timer_font_size"],
            desc = L["rem_timer_font_size_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.TimerFontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.BarSettings.TimerFontSize = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 200,
            nocombat = true,
        },
        {
            type = "color",
            name = L["rem_bar_color"],
            desc = L["rem_bar_color_desc"],
            get = function() return RRT.ReminderSettings.BarSettings.colors end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.BarSettings.colors = {r, g, b, a}
                RRT_NS:UpdateExistingFrames()
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "range",
            name = L["rem_spacing"],
            desc = L["rem_spacing_bar_desc"],
            get = function() return RRT.ReminderSettings.BarSettings["Spacing"] or 0 end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.BarSettings["Spacing"] = value
                RRT_NS:UpdateExistingFrames()
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
            get = function() return L["rem_raidframe_icon_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "range",
            name = L["rem_icon_width"],
            desc = L["rem_icon_width_desc"],
            get = function() return RRT.ReminderSettings.UnitIconSettings.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.UnitIconSettings.Width = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_icon_height"],
            desc = L["rem_icon_height_desc"],
            get = function() return RRT.ReminderSettings.UnitIconSettings.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.UnitIconSettings.Height = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "select",
            name = L["rem_position"],
            desc = L["rem_position_desc"],
            get = function() return RRT.ReminderSettings.UnitIconSettings.Position end,
            values = function() return build_raidframeicon_options() end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_x_offset"],
            desc = "",
            get = function() return RRT.ReminderSettings.UnitIconSettings.xOffset end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.UnitIconSettings.xOffset= value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },
        {
            type = "range",
            name = L["rem_y_offset"],
            desc = "",
            get = function() return RRT.ReminderSettings.UnitIconSettings.yOffset end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.UnitIconSettings.yOffset = value
                RRT_NS:UpdateExistingFrames()
            end,
            min = 5,
            max = 60,
            nocombat = true,
        },

        {
            type = "color",
            name = L["rem_glow_color"],
            desc = L["rem_glow_color_desc"],
            get = function() return RRT.ReminderSettings.GlowSettings.colors end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.GlowSettings.colors = {r, g, b, a}
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "label",
            get = function() return L["rem_universal_settings"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_hide_timer_text"],
            desc = L["rem_hide_timer_text_desc"],
            get = function() return RRT.ReminderSettings["HideTimerText"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["HideTimerText"] = value
                RRT_NS:UpdateExistingFrames()
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_play_sound"],
            desc = L["rem_play_sound_desc"],
            get = function() return RRT.ReminderSettings["PlayDefaultSound"] end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings["PlayDefaultSound"] = value
                RRT_NS:ProcessReminder()
            end,
            nocombat = true,
        },

        {
            type = "select",
            name = L["rem_sound"],
            desc = L["rem_sound_desc"],
            get = function() return RRT.ReminderSettings.DefaultSound end,
            values = function() return build_sound_dropdown() end,
            nocombat = true,
        },

        {
            type = "breakline",
        },

        {
            type = "label",
            get  = function() return L["rem_manage_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type      = "button",
            name      = L["opt_move_text_display"] or "Move Text Display",
            desc      = L["opt_move_text_display_desc"],
            nocombat  = true,
            spacement = true,
            func      = function()
                if RRT_NS.RRTFrame.generic_display:IsMovable() then
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, false)
                else
                    RRT_NS.RRTFrame.generic_display.Text:SetText(
                        "Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
                    RRT_NS.RRTFrame.generic_display:SetSize(
                        RRT_NS.RRTFrame.generic_display.Text:GetStringWidth(),
                        RRT_NS.RRTFrame.generic_display.Text:GetStringHeight())
                    RRT_NS:ToggleMoveFrames(RRT_NS.RRTFrame.generic_display, true)
                end
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_use_shared"],
            desc = L["rem_use_shared_desc"],
            get = function() return RRT.ReminderSettings.enabled end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.enabled = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_use_personal"],
            desc = L["rem_use_personal_desc"],
            get = function() return RRT.ReminderSettings.PersNote end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.PersNote = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["rem_use_mrt"],
            desc = L["rem_use_mrt_desc"],
            get = function() return RRT.ReminderSettings.MRTNote end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.MRTNote = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Outside of Raid",
            desc = "With this enabled the Notes will still show outside of raid instances.",
            get = function() return RRT.ReminderSettings.ShowOutsideOfRaid end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ShowOutsideOfRaid = value
                RRT_NS:UpdateReminderFrame(true)
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = L["rem_shared_btn"],
            desc = L["rem_shared_btn_desc"],
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
            name = L["rem_personal_btn"],
            desc = L["rem_personal_btn_desc"],
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
            name = L["rem_share_rc"],
            desc = L["rem_share_rc_desc"],
            get = function() return RRT.ReminderSettings.AutoShare end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.AutoShare = value
            end,
            nocombat = true,
        },

        {
            type = "button",
            name = L["rem_test_active"],
            desc = L["rem_test_active_desc"],
            func = function(self)
                if not RRT_NS.TestingReminder then
                    RRT_NS.TestingReminder = true
                    RRT_NS:StartReminders(1, true)
                else
                    RRT_NS.TestingReminder = false
                    RRT_NS:HideAllReminders()
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
            get = function() return L["remn_intro"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
            spacement = true,
        },
        {
            type = "label",
            get = function() return L["remn_all_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["remn_toggle_all"],
            desc = L["remn_toggle_all_desc"],
            func = function(self)
                if RRT_NS.ReminderFrameMover and RRT_NS.ReminderFrameMover:IsMovable() then
                    RRT_NS:UpdateReminderFrame(false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.ReminderFrameMover, false)
                    RRT_NS.ReminderFrameMover.Resizer:Hide()
                    RRT_NS.ReminderFrameMover:SetResizable(false)
                    RRT.ReminderSettings.ReminderFrame.Moveable = false
                else
                    RRT_NS:UpdateReminderFrame(false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.ReminderFrameMover, true)
                    RRT_NS.ReminderFrameMover.Resizer:Show()
                    RRT_NS.ReminderFrameMover:SetResizable(true)
                    RRT_NS.ReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRT.ReminderSettings.ReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_show_all"],
            desc = L["remn_show_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ReminderFrame.enabled = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_font_size_all"],
            desc = L["remn_font_size_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ReminderFrame.FontSize = value
                RRT_NS:UpdateReminderFrame(false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = L["remn_font_all"],
            desc = L["remn_font_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.Font end,
            values = function()
                return build_media_options("ReminderFrame", "Font", false, true, false)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_width_all"],
            desc = L["remn_width_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ReminderFrame.Width = value
                RRT_NS:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_height_all"],
            desc = L["remn_height_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ReminderFrame.Height = value
                RRT_NS:UpdateReminderFrame(false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = L["remn_bg_all"],
            desc = L["remn_bg_all_desc"],
            get = function() return RRT.ReminderSettings.ReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.ReminderFrame.BGcolor = {r, g, b, a}
                RRT_NS:UpdateReminderFrame(false, true)
            end,
            hasAlpha = true,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_textnote_in_all"],
            desc = L["remn_textnote_in_all_desc"],
            get = function() return RRT.ReminderSettings.TextInSharedNote end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.TextInSharedNote = value
                RRT_NS:UpdateReminderFrame(false, true)
            end,
        },
        {
            type = "label",
            get = function() return L["remn_universal"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_hide_names"],
            desc = L["remn_hide_names_desc"],
            get = function() return RRT.ReminderSettings.HidePlayerNames end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.HidePlayerNames = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(true)
            end,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_only_spell"],
            desc = L["remn_only_spell_desc"],
            get = function() return RRT.ReminderSettings.OnlySpellReminders end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.OnlySpellReminders = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(false, true, true)
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
            get = function() return L["remn_pers_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["remn_toggle_pers"],
            desc = L["remn_toggle_pers_desc"],
            func = function(self)
                if RRT_NS.PersonalReminderFrameMover and RRT_NS.PersonalReminderFrameMover:IsMovable() then
                    RRT_NS:UpdateReminderFrame(false, false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.PersonalReminderFrameMover, false)
                    RRT_NS.PersonalReminderFrameMover.Resizer:Hide()
                    RRT_NS.PersonalReminderFrameMover:SetResizable(false)
                    RRT.ReminderSettings.PersonalReminderFrame.Moveable = false
                else
                    RRT_NS:UpdateReminderFrame(false, false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.PersonalReminderFrameMover, true)
                    RRT_NS.PersonalReminderFrameMover.Resizer:Show()
                    RRT_NS.PersonalReminderFrameMover:SetResizable(true)
                    RRT_NS.PersonalReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRT.ReminderSettings.PersonalReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_show_pers"],
            desc = L["remn_show_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.PersonalReminderFrame.enabled = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_font_size_pers"],
            desc = L["remn_font_size_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.PersonalReminderFrame.FontSize = value
                RRT_NS:UpdateReminderFrame(false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = L["remn_font_pers"],
            desc = L["remn_font_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.Font end,
            values = function()
                return build_media_options("PersonalReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_width_pers"],
            desc = L["remn_width_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.PersonalReminderFrame.Width = value
                RRT_NS:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_height_pers"],
            desc = L["remn_height_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.PersonalReminderFrame.Height = value
                RRT_NS:UpdateReminderFrame(false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = L["remn_bg_pers"],
            desc = L["remn_bg_pers_desc"],
            get = function() return RRT.ReminderSettings.PersonalReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.PersonalReminderFrame.BGcolor = {r, g, b, a}
                RRT_NS:UpdateReminderFrame(false, false, true)
            end,
            hasAlpha = true,
            nocombat = true

        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_textnote_in_pers"],
            desc = L["remn_textnote_in_pers_desc"],
            get = function() return RRT.ReminderSettings.TextInPersonalNote end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.TextInPersonalNote = value
                RRT_NS:UpdateReminderFrame(true)
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
            get = function() return L["remn_text_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },

        {
            type = "button",
            name = L["remn_toggle_text"],
            desc = L["remn_toggle_text_desc"],
            func = function(self)
                if RRT_NS.ExtraReminderFrameMover and RRT_NS.ExtraReminderFrameMover:IsMovable() then
                    RRT_NS:UpdateReminderFrame(false, false, false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.ExtraReminderFrameMover, false)
                    RRT_NS.ExtraReminderFrameMover.Resizer:Hide()
                    RRT_NS.ExtraReminderFrameMover:SetResizable(false)
                    RRT.ReminderSettings.ExtraReminderFrame.Moveable = false
                else
                    RRT_NS:UpdateReminderFrame(false, false, false, true)
                    RRT_NS:ToggleMoveFrames(RRT_NS.ExtraReminderFrameMover, true)
                    RRT_NS.ExtraReminderFrameMover.Resizer:Show()
                    RRT_NS.ExtraReminderFrameMover:SetResizable(true)
                    RRT_NS.ExtraReminderFrameMover:SetResizeBounds(100, 100, 2000, 2000)
                    RRT.ReminderSettings.ExtraReminderFrame.Moveable = true
                end
            end,
            nocombat = true,
            spacement = true
        },
        {
            type = "toggle",
            boxfirst = true,
            name = L["remn_show_text"],
            desc = L["remn_show_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.enabled end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ExtraReminderFrame.enabled = value
                RRT_NS:ProcessReminder()
                RRT_NS:UpdateReminderFrame(false, false, false, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_font_size_text"],
            desc = L["remn_font_size_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.FontSize end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ExtraReminderFrame.FontSize = value
                RRT_NS:UpdateReminderFrame(false, false, false, true)
            end,
            min = 2,
            max = 40,
            nocombat = true,
        },
        {
            type = "select",
            name = L["remn_font_text"],
            desc = L["remn_font_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.Font end,
            values = function()
                return build_media_options("ExtraReminderFrame", "Font", false, true, true)
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_width_text"],
            desc = L["remn_width_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.Width end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ExtraReminderFrame.Width = value
                RRT_NS:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },
        {
            type = "range",
            name = L["remn_height_text"],
            desc = L["remn_height_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.Height end,
            set = function(self, fixedparam, value)
                RRT.ReminderSettings.ExtraReminderFrame.Height = value
                RRT_NS:UpdateReminderFrame(false, false, false, true)
            end,
            min = 100,
            max = 2000,
            nocombat = true,
        },

        {
            type = "color",
            name = L["remn_bg_text"],
            desc = L["remn_bg_text_desc"],
            get = function() return RRT.ReminderSettings.ExtraReminderFrame.BGcolor end,
            set = function(self, r, g, b, a)
                RRT.ReminderSettings.ExtraReminderFrame.BGcolor = {r, g, b, a}
                RRT_NS:UpdateReminderFrame(false, false, false, true)
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
            get = function() return L["remn_timeline_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type = "button",
            name = L["remn_open_timeline"],
            desc = L["remn_open_timeline_desc"],
            func = function(self)
                RRT_NS:ToggleTimelineWindow()
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

local function BuildPreviewEntry()
    return {
        {
            type = "label",
            get  = function() return L["rem_manage_section"] end,
            text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE"),
        },
        {
            type      = "button",
            name      = L["rem_preview"],
            desc      = L["rem_preview_desc"],
            nocombat  = true,
            spacement = true,
            func = function(self)
                if RRT_NS.PreviewTimer then
                    RRT_NS.PreviewTimer:Cancel()
                    RRT_NS.PreviewTimer = nil
                end
                if RRT_NS.IsInPreview then
                    RRT_NS.IsInPreview = false
                    RRT_NS:HideAllReminders()
                    for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                        if RRT_NS[v] then RRT_NS[v]:StopMovingOrSizing() end
                        RRT_NS:ToggleMoveFrames(RRT_NS[v], false)
                    end
                    return
                end
                RRT_NS.PreviewTimer = C_Timer.NewTimer(12, function()
                    if RRT_NS.IsInPreview then
                        RRT_NS.IsInPreview = false
                        RRT_NS:HideAllReminders()
                        for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                            if RRT_NS[v] then RRT_NS[v]:StopMovingOrSizing() end
                            RRT_NS:ToggleMoveFrames(RRT_NS[v], false)
                        end
                    end
                end)
                RRT_NS.IsInPreview = true
                for _, v in ipairs({"IconMover", "BarMover", "TextMover"}) do
                    RRT_NS:ToggleMoveFrames(RRT_NS[v], true)
                end
                RRT_NS.AllGlows = RRT_NS.AllGlows or {}
                RRT_NS.PlayedSound = {}
                RRT_NS.StartedCountdown = {}
                RRT_NS.GlowStarted = {}
                local info1 = { text="Personals", phase=1, id=1, TTS=RRT.ReminderSettings.TextTTS and "Personals", TTSTimer=RRT.ReminderSettings.TextTTSTimer, countdown=RRT.ReminderSettings.TextCountdown, dur=RRT.ReminderSettings.TextDuration }
                RRT_NS:DisplayReminder(info1)
                local info2 = { text="Stack on |TInterface\\TargetingFrame\\UI-RaidTargetingIcon_7:0|t", phase=1, id=2, TTS=false, TTSTimer=RRT.ReminderSettings.TextTTSTimer, countdown=false, dur=RRT.ReminderSettings.TextDuration }
                RRT_NS:DisplayReminder(info2)
                local info3 = { text="Give Ironbark", IconOverwrite=true, spellID=102342, phase=1, id=3, TTS=RRT.ReminderSettings.SpellTTS and "Give Ironbark", TTSTimer=RRT.ReminderSettings.SpellTTSTimer, countdown=RRT.ReminderSettings.SpellCountdown, dur=RRT.ReminderSettings.SpellDuration, glowunit={"player"} }
                RRT_NS:DisplayReminder(info3)
                local info4 = { text=RRT.ReminderSettings.SpellName and C_Spell.GetSpellInfo(115203).name, IconOverwrite=true, spellID=115203, phase=1, id=4, TTS=false, TTSTimer=RRT.ReminderSettings.SpellTTSTimer, countdown=false, dur=RRT.ReminderSettings.SpellDuration }
                RRT_NS:DisplayReminder(info4)
                local info5 = { text="Breath", BarOverwrite=true, spellID=1256855, phase=1, id=5, TTS=false, TTSTimer=RRT.ReminderSettings.SpellTTSTimer, countdown=false, dur=RRT.ReminderSettings.SpellDuration, glowunit={"player"} }
                RRT_NS:DisplayReminder(info5)
                local info6 = { text="Dodge", BarOverwrite=true, spellID=193171, phase=1, id=6, TTS=false, TTSTimer=RRT.ReminderSettings.SpellTTSTimer, countdown=false, dur=RRT.ReminderSettings.SpellDuration }
                RRT_NS:DisplayReminder(info6)
                RRT_NS:UpdateExistingFrames()
            end,
        },
    }
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.Reminders = {
    BuildOptions         = BuildReminderOptions,
    BuildNoteOptions     = BuildReminderNoteOptions,
    BuildCallback        = BuildReminderCallback,
    BuildNoteCallback    = BuildReminderNoteCallback,
    BuildPreviewEntry    = BuildPreviewEntry,
}
