local _, RRT = ... -- Internal namespace

local function PrintPerfReport()
    local ST = RRT and RRT.SpellTracker
    if (not ST or not ST.GetPerfReport) then
        print("|cFF00FFFFRRT|r SpellTracker perf module unavailable.")
        return
    end
    local report = ST:GetPerfReport() or "No data."
    for line in string.gmatch(report, "[^\n]+") do
        print("|cFF00FFFFRRT|r " .. line)
    end
end

SLASH_RRTUI1 = "/rrt"
SlashCmdList["RRTUI"] = function(msg)
    if msg == "wipe" then
        wipe(RRTDB)
        ReloadUI()
    elseif msg == "debug" then
        if RRTDB.Settings["Debug"] then
            RRTDB.Settings["Debug"] = false
            print("|cFF00FFFFRRT|r Debug mode is now disabled")
        else
            RRTDB.Settings["Debug"] = true
            print("|cFF00FFFFRRT|r Debug mode is now enabled, please disable it when you are done testing.")
        end
    elseif msg == "cd" then
        if RRT.RRTUI.cooldowns_frame:IsShown() then
            RRT.RRTUI.cooldowns_frame:Hide()
        else
            RRT.RRTUI.cooldowns_frame:Show()
        end
    elseif msg == "reminders" or msg == "r" then
        if not RRT.RRTUI.reminders_frame:IsShown() then
            RRT.RRTUI.reminders_frame:Show()
        else
            RRT.RRTUI.reminders_frame:Hide()
        end
    elseif msg == "preminders" or msg == "pr" then
        if not RRT.RRTUI.personal_reminders_frame:IsShown() then
            RRT.RRTUI.personal_reminders_frame:Show()
        else
            RRT.RRTUI.personal_reminders_frame:Hide()
        end
    elseif msg == "note" or msg == "n" then -- Toggle Showing/Hiding ALL Notes
        local ShouldShow = not (RRTDB.ReminderSettings.ReminderFrame.enabled or RRTDB.ReminderSettings.PersonalReminderFrame.enabled or RRTDB.ReminderSettings.ExtraReminderFrame.enabled)
        RRTDB.ReminderSettings.ReminderFrame.enabled = ShouldShow
        RRTDB.ReminderSettings.PersonalReminderFrame.enabled = ShouldShow
        RRTDB.ReminderSettings.ExtraReminderFrame.enabled = ShouldShow
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(true)
    elseif msg == "anote" or msg == "an" or msg == "snote" or msg == "sn" then -- Toggle the "All Reminders Note"
        RRTDB.ReminderSettings.ReminderFrame.enabled = not RRTDB.ReminderSettings.ReminderFrame.enabled
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(false, true)
    elseif msg == "pnote" or msg == "pn" then -- Toggle the "Personal Reminders Note"
        RRTDB.ReminderSettings.PersonalReminderFrame.enabled = not RRTDB.ReminderSettings.PersonalReminderFrame.enabled
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(false, false, true)
    elseif msg == "tnote" or msg == "tn" then -- Toggle the "Text Note"
        RRTDB.ReminderSettings.ExtraReminderFrame.enabled = not RRTDB.ReminderSettings.ExtraReminderFrame.enabled
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(false, false, false, true)
    elseif msg == "clear" or msg == "c" then -- Clear Active Reminder
        RRTDB.ActiveReminder = nil
        RRT.Reminder = ""
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(true)
    elseif msg == "pclear" or msg == "pc" then -- Clear Active Personal Reminder
        RRTDB.ActivePersonalReminder = nil
        RRT.PersonalReminder = ""
        RRT:ProcessReminder()
        RRT:UpdateReminderFrame(true)
    elseif msg == "timeline" or msg == "tl" then
        RRT:ToggleTimelineWindow()
    elseif msg == "br" or msg == "buffreminders" then
        RRT.RRTUI:Show()
        if RRT.RRTUI.MenuFrame and RRT.RRTUI.MenuFrame.SelectTabByName then
            RRT.RRTUI.MenuFrame:SelectTabByName("BuffReminders")
        end
    elseif msg == "perf on" then
        local ST = RRT and RRT.SpellTracker
        if (ST and ST.SetPerfEnabled) then
            ST:SetPerfEnabled(true)
            print("|cFF00FFFFRRT|r SpellTracker perf ON")
        else
            print("|cFF00FFFFRRT|r SpellTracker perf unavailable.")
        end
    elseif msg == "perf off" then
        local ST = RRT and RRT.SpellTracker
        if (ST and ST.SetPerfEnabled) then
            ST:SetPerfEnabled(false)
            print("|cFF00FFFFRRT|r SpellTracker perf OFF")
        else
            print("|cFF00FFFFRRT|r SpellTracker perf unavailable.")
        end
    elseif msg == "perf reset" then
        local ST = RRT and RRT.SpellTracker
        if (ST and ST.ResetPerfStats) then
            ST:ResetPerfStats()
            print("|cFF00FFFFRRT|r SpellTracker perf stats reset")
        else
            print("|cFF00FFFFRRT|r SpellTracker perf unavailable.")
        end
    elseif msg == "perf" or msg == "perf report" then
        PrintPerfReport()
    elseif msg == "help" then
        print("|cFF00FFFFRRT|r Available commands: (use '/rrt')\n")
        print("  |cFF00FFFF/rrt debug|r - Toggle debug mode - mainly used for development")
        print("  |cFF00FFFF/rrt wipe|r - Wipe ALL RRTDB settings and reload UI")
        print("  |cFF00FFFF/rrt cd|r - Toggle cooldowns frame")
        print("  |cFF00FFFF/rrt clear|r or |cFF00FFFF/rrt c|r - Clear active reminder")
        print("  |cFF00FFFF/rrt pclear|r or |cFF00FFFF/rrt pc|r - Clear active personal reminder")
        print("  |cFF00FFFF/rrt reminders|r or |cFF00FFFF/rrt r|r - Shortcut to shared reminders list")
        print("  |cFF00FFFF/rrt preminders|r or |cFF00FFFF/rrt pr|r - Shortcut to personal reminders list")
        print("  |cFF00FFFF/rrt note|r or |cFF00FFFF/rrt n|r - Toggle all notes (all reminders, personal reminders, and text note)")
        print("  |cFF00FFFF/rrt anote|r or |cFF00FFFF/rrt an|r or |cFF00FFFF/rrt snote|r or |cFF00FFFF/rrt sn|r - Toggle shared reminders note")
        print("  |cFF00FFFF/rrt pnote|r or |cFF00FFFF/rrt pn|r - Toggle personal reminders note")
        print("  |cFF00FFFF/rrt tnote|r or |cFF00FFFF/rrt tn|r - Toggle text note")
        print("  |cFF00FFFF/rrt timeline|r or |cFF00FFFF/rrt tl|r - Toggle timeline window")
        print("  |cFF00FFFF/rrt br|r - Open Buff Reminders tab")
        print("  |cFF00FFFF/rrt perf on|r - Enable lightweight SpellTracker CPU profiling")
        print("  |cFF00FFFF/rrt perf off|r - Disable SpellTracker CPU profiling")
        print("  |cFF00FFFF/rrt perf reset|r - Reset profiling counters")
        print("  |cFF00FFFF/rrt perf|r - Show profiling report")
    elseif msg == "" then
        RRT.RRTUI:ToggleOptions()
    elseif msg then
        print("|cFF00FFFFRRT|r Unknown command. Type |cFF00FFFF/rrt help|r for a list of commands.")
    else
        RRT.RRTUI:ToggleOptions()
    end
end








