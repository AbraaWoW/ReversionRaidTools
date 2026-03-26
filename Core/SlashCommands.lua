local _, RRT_NS = ... -- Internal namespace

SLASH_RRTUI1 = "/rvr"
SLASH_RRTUI2 = "/rrt"
SlashCmdList["RRTUI"] = function(msg)
    if msg == "wipe" then
        wipe(RRT)
        ReloadUI()
    elseif msg == "debug" then
        if RRT.Settings["Debug"] then
            RRT.Settings["Debug"] = false
            print("|cFFBB66FFRRT|r Debug mode is now disabled")
        else
            RRT.Settings["Debug"] = true
            print("|cFFBB66FFRRT|r Debug mode is now enabled, please disable it when you are done testing.")
        end
    elseif msg == "cd" then
        if RRT_NS.RRTUI.cooldowns_frame:IsShown() then
            RRT_NS.RRTUI.cooldowns_frame:Hide()
        else
            RRT_NS.RRTUI.cooldowns_frame:Show()
        end
    elseif msg == "reminders" or msg == "r" then
        if not RRT_NS.RRTUI.reminders_frame:IsShown() then
            RRT_NS.RRTUI.reminders_frame:Show()
        else
            RRT_NS.RRTUI.reminders_frame:Hide()
        end
    elseif msg == "preminders" or msg == "pr" then
        if not RRT_NS.RRTUI.personal_reminders_frame:IsShown() then
            RRT_NS.RRTUI.personal_reminders_frame:Show()
        else
            RRT_NS.RRTUI.personal_reminders_frame:Hide()
        end
    elseif msg == "note" or msg == "n" then -- Toggle Showing/Hiding ALL Notes
        local ShouldShow = not (RRT.ReminderSettings.ReminderFrame.enabled or RRT.ReminderSettings.PersonalReminderFrame.enabled or RRT.ReminderSettings.ExtraReminderFrame.enabled)
        RRT.ReminderSettings.ReminderFrame.enabled = ShouldShow
        RRT.ReminderSettings.PersonalReminderFrame.enabled = ShouldShow
        RRT.ReminderSettings.ExtraReminderFrame.enabled = ShouldShow
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(true)
    elseif msg == "anote" or msg == "an" or msg == "snote" or msg == "sn" then -- Toggle the "All Reminders Note"
        RRT.ReminderSettings.ReminderFrame.enabled = not RRT.ReminderSettings.ReminderFrame.enabled
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(false, true)
    elseif msg == "pnote" or msg == "pn" then -- Toggle the "Personal Reminders Note"
        RRT.ReminderSettings.PersonalReminderFrame.enabled = not RRT.ReminderSettings.PersonalReminderFrame.enabled
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(false, false, true)
    elseif msg == "tnote" or msg == "tn" then -- Toggle the "Text Note"
        RRT.ReminderSettings.ExtraReminderFrame.enabled = not RRT.ReminderSettings.ExtraReminderFrame.enabled
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(false, false, false, true)
    elseif msg == "clear" or msg == "c" then -- Clear Active Reminder
        RRT_NS:SetReminder(nil)
        RRT_NS:Broadcast("RRT_REM_SHARE", "RAID", " ", nil, true)
    elseif msg == "pclear" or msg == "pc" then -- Clear Active Personal Reminder
        RRT_NS:SetReminder(nil, true)
    elseif msg == "timeline" or msg == "tl" then
        RRT_NS:ToggleTimelineWindow()
    elseif msg == "raidframe" or msg == "rf" then
        RRT_NS.RaidFrame:Toggle()
    elseif msg == "invite" then
        RRT_NS:InviteFromReminder(RRT.ActiveReminder, true)
    elseif msg == "arrange" then
        RRT_NS:ArrangeFromReminder(RRT.ActiveReminder, true)
    elseif msg == "help" then
        print("|cFFBB66FFRRT|r Available commands: (either '/rvr' or '/rrt' work)\n")
        print("  |cFFBB66FF/rvr debug|r - Toggle debug mode - mainly used for development")
        print("  |cFFBB66FF/rvr wipe|r - Wipe ALL RRT settings and reload UI")
        print("  |cFFBB66FF/rvr cd|r - Toggle cooldowns frame")
        print("  |cFFBB66FF/rvr clear|r or |cFFBB66FF/rvr c|r - Clear active reminder")
        print("  |cFFBB66FF/rvr pclear|r or |cFFBB66FF/rvr pc|r - Clear active personal reminder")
        print("  |cFFBB66FF/rvr reminders|r or |cFFBB66FF/rvr r|r - Shortcut to shared reminders list")
        print("  |cFFBB66FF/rvr preminders|r or |cFFBB66FF/rvr pr|r - Shortcut to personal reminders list")
        print("  |cFFBB66FF/rvr note|r or |cFFBB66FF/rvr n|r - Toggle all notes (all reminders, personal reminders, and text note)")
        print("  |cFFBB66FF/rvr anote|r or |cFFBB66FF/rvr an|r or |cFFBB66FF/rvr snote|r or |cFFBB66FF/rvr sn|r - Toggle shared reminders note")
        print("  |cFFBB66FF/rvr pnote|r or |cFFBB66FF/rvr pn|r - Toggle personal reminders note")
        print("  |cFFBB66FF/rvr tnote|r or |cFFBB66FF/rvr tn|r - Toggle text note")
        print("  |cFFBB66FF/rvr timeline|r or |cFFBB66FF/rvr tl|r - Toggle timeline window")
        print("  |cFFBB66FF/rvr invite|r - Invite players from active reminder to group")
        print("  |cFFBB66FF/rvr arrange|r - Arrange players from active reminder in group")
    elseif msg == "" then
        RRT_NS.RRTUI:ToggleOptions()
    elseif msg then
        print("|cFFBB66FFRRT|r Unknown command. Type |cFFBB66FF/rvr help|r for a list of commands.")
    else
        RRT_NS.RRTUI:ToggleOptions()
    end
end

SLASH_RRTRL1 = "/rl"
SlashCmdList["RRTRL"] = function()
    if RRT and RRT.Settings and RRT.Settings.RLAlias then
        ReloadUI()
    end
end