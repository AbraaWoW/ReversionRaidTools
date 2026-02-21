local _, RRT = ...
local DF = _G["DetailsFramework"]

-- Get references from Core module
local Core = RRT.UI.Core
local RRTUI = Core.RRTUI
local window_width = Core.window_width
local window_height = Core.window_height
local TABS_LIST = Core.TABS_LIST
local authorsString = Core.authorsString
local options_text_template = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template

-- Get UI builder functions from modules
local BuildVersionCheckUI = RRT.UI.VersionCheck.BuildVersionCheckUI
local BuildNicknameEditUI = RRT.UI.Nicknames.BuildNicknameEditUI
local BuildRemindersEditUI = RRT.UI.Reminders.BuildRemindersEditUI
local BuildPersonalRemindersEditUI = RRT.UI.Reminders.BuildPersonalRemindersEditUI
local BuildCooldownsEditUI = RRT.UI.Cooldowns.BuildCooldownsEditUI
local BuildPASoundEditUI = RRT.UI.PrivateAuras.BuildPASoundEditUI
local BuildExportStringUI = RRT.UI.General.BuildExportStringUI
local BuildImportStringUI = RRT.UI.General.BuildImportStringUI

-- Get options builders from modules
local BuildGeneralOptions = RRT.UI.Options.General.BuildOptions
local BuildGeneralCallback = RRT.UI.Options.General.BuildCallback
local BuildNicknamesOptions = RRT.UI.Options.Nicknames.BuildOptions
local BuildNicknamesCallback = RRT.UI.Options.Nicknames.BuildCallback
local BuildSetupManagerUI = RRT.UI.Options.SetupManager.BuildUI
local BuildReminderOptions = RRT.UI.Options.Reminders.BuildOptions
local BuildReminderNoteOptions = RRT.UI.Options.Reminders.BuildNoteOptions
local BuildReminderCallback = RRT.UI.Options.Reminders.BuildCallback
local BuildReminderNoteCallback = RRT.UI.Options.Reminders.BuildNoteCallback
local BuildAssignmentsOptions = RRT.UI.Options.Assignments.BuildOptions
local BuildAssignmentsCallback = RRT.UI.Options.Assignments.BuildCallback
local BuildEncounterAlertsOptions = RRT.UI.Options.EncounterAlerts.BuildOptions
local BuildEncounterAlertsCallback = RRT.UI.Options.EncounterAlerts.BuildCallback
local BuildReadyCheckOptions = RRT.UI.Options.ReadyCheck.BuildOptions
local BuildRaidBuffMenu = RRT.UI.Options.ReadyCheck.BuildRaidBuffMenu
local BuildReadyCheckCallback = RRT.UI.Options.ReadyCheck.BuildCallback
local BuildPrivateAurasOptions = RRT.UI.Options.PrivateAuras.BuildOptions
local BuildPrivateAurasCallback = RRT.UI.Options.PrivateAuras.BuildCallback
local BuildQoLOptions = RRT.UI.Options.QoL.BuildOptions
local BuildQoLCallback = RRT.UI.Options.QoL.BuildCallback
local BuildBuffRemindersUI = RRT.UI.Options.BuffReminders.BuildUI
local BuildRaidInspectUI = RRT.UI.Options.RaidInspect and RRT.UI.Options.RaidInspect.BuildUI
local BuildProfilesUI = RRT.UI.Options.Profiles and RRT.UI.Options.Profiles.BuildUI

function RRTUI:Init()
    -- Create the scale bar
    local scaleMin, scaleMax = 0.6, 2.0
    RRTDB.RRTUI.scale = math.max(scaleMin, math.min(scaleMax, RRTDB.RRTUI.scale or 2.0))

    local scaleBar = DF:CreateScaleBar(RRTUI, RRTDB.RRTUI)
    if scaleBar and scaleBar.SetMinMaxValues then
        scaleBar:SetMinMaxValues(scaleMin, scaleMax)
    end

    RRTUI:SetScale(RRTDB.RRTUI.scale)

    -- Create the tab container
    local tabContainer = DF:CreateTabContainer(RRTUI, "Reversion", "RRTUI_TabsTemplate", TABS_LIST, {
        width = window_width,
        height = window_height - 5,
        button_width = 94,
        button_height = 18,
        button_text_size = 9,
        button_x = 118,
        button_y = 1,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 }
    })
    tabContainer:SetPoint("CENTER", RRTUI, "CENTER", 0, 0)
    local tabContainerFrame = tabContainer.widget or tabContainer

    local globalTopSeparator = tabContainerFrame:CreateTexture(nil, "ARTWORK")
    globalTopSeparator:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    globalTopSeparator:SetPoint("TOPLEFT", tabContainerFrame, "TOPLEFT", 8, -95)
    globalTopSeparator:SetPoint("TOPRIGHT", tabContainerFrame, "TOPRIGHT", -8, -95)
    globalTopSeparator:SetHeight(1)

    RRTUI.MenuFrame = tabContainer  -- Store reference for later access

    -- Get tab frames
    local general_tab = tabContainer:GetTabFrameByName("General")
    local nicknames_tab = tabContainer:GetTabFrameByName("Nicknames")
    local cooldowns_tab = tabContainer:GetTabFrameByName("Cooldowns")
    local versions_tab = tabContainer:GetTabFrameByName("Versions")
    local setupmanager_tab = tabContainer:GetTabFrameByName("SetupManager")
    local reminder_tab = tabContainer:GetTabFrameByName("Reminders")
    local reminder_note_tab = tabContainer:GetTabFrameByName("Reminders-Note")
    local assignments_tab = tabContainer:GetTabFrameByName("Assignments")
    local encounteralerts_tab = tabContainer:GetTabFrameByName("EncounterAlerts")
    local readycheck_tab = tabContainer:GetTabFrameByName("ReadyCheck")
    local privateaura_tab = tabContainer:GetTabFrameByName("PrivateAura")
    local QoL_tab = tabContainer:GetTabFrameByName("QoL")
    local buffreminders_tab = tabContainer:GetTabFrameByName("BuffReminders")
    local raidinspect_tab = tabContainer:GetTabFrameByName("RaidInspect")
    local profiles_tab = tabContainer:GetTabFrameByName("Profiles")

    -- Generic text display
    RRT.RRTFrame.generic_display = CreateFrame("Frame", nil, RRT.RRTFrame, "BackdropTemplate")
    RRT.RRTFrame.generic_display:Hide()
    RRT.RRTFrame.generic_display:SetPoint(RRTDB.Settings.GenericDisplay.Anchor, RRT.RRTFrame, RRTDB.Settings.GenericDisplay.relativeTo, RRTDB.Settings.GenericDisplay.xOffset, RRTDB.Settings.GenericDisplay.yOffset)
    RRT.RRTFrame.generic_display.Text = RRT.RRTFrame.generic_display:CreateFontString(nil, "OVERLAY")
    RRT.RRTFrame.generic_display.Text:SetFont(RRT.LSM:Fetch("font", RRTDB.Settings.GlobalFont), 20, "OUTLINE")
    RRT.RRTFrame.generic_display.Text:SetPoint("TOPLEFT", RRT.RRTFrame.generic_display, "TOPLEFT", 0, 0)
    RRT.RRTFrame.generic_display.Text:SetJustifyH("LEFT")
    RRT.RRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
    RRT.RRTFrame.generic_display:SetSize(RRT.RRTFrame.generic_display.Text:GetStringWidth(), RRT.RRTFrame.generic_display.Text:GetStringHeight())
    RRT:MoveFrameInit(RRT.RRTFrame.generic_display, "Generic")

    -- Build options tables from modules
    local general_options1_table = BuildGeneralOptions()
    local nicknames_options1_table = BuildNicknamesOptions()
    BuildSetupManagerUI(setupmanager_tab)
    local reminder_options1_table = BuildReminderOptions()
    local reminder_note_options1_table = BuildReminderNoteOptions()
    local assignments_options1_table = BuildAssignmentsOptions()
    local encounteralerts_options1_table = BuildEncounterAlertsOptions()
    local readycheck_options1_table = BuildReadyCheckOptions()
    local RaidBuffMenu = BuildRaidBuffMenu()
    local privateaura_options1_table = BuildPrivateAurasOptions()
    local QoL_options1_table = BuildQoLOptions()

    -- Build callbacks
    local general_callback = BuildGeneralCallback()
    local nicknames_callback = BuildNicknamesCallback()

    local reminder_callback = BuildReminderCallback()
    local reminder_note_callback = BuildReminderNoteCallback()
    local assignments_callback = BuildAssignmentsCallback()
    local encounteralerts_callback = BuildEncounterAlertsCallback()
    local readycheck_callback = BuildReadyCheckCallback()
    local privateaura_callback = BuildPrivateAurasCallback()
    local QoL_callback = BuildQoLCallback()

    -- Build options menu for each tab
    DF:BuildMenu(general_tab, general_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        general_callback)
    DF:BuildMenu(nicknames_tab, nicknames_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nicknames_callback)
    DF:BuildMenu(reminder_tab, reminder_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_callback)
    DF:BuildMenu(reminder_note_tab, reminder_note_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        reminder_note_callback)
    DF:BuildMenu(assignments_tab, assignments_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        assignments_callback)
    DF:BuildMenu(encounteralerts_tab, encounteralerts_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        encounteralerts_callback)
    DF:BuildMenu(readycheck_tab, readycheck_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        readycheck_callback)
    DF:BuildMenu(RRT.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
    DF:BuildMenu(privateaura_tab, privateaura_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        privateaura_callback)
    DF:BuildMenu(QoL_tab, QoL_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        QoL_callback)
    BuildBuffRemindersUI(buffreminders_tab)
    if BuildRaidInspectUI then
        BuildRaidInspectUI(raidinspect_tab)
    end
    if BuildProfilesUI then
        BuildProfilesUI(profiles_tab)
    end
    RRT.RaidBuffCheck:SetMovable(false)
    RRT.RaidBuffCheck:EnableMouse(false)

    -- Build UI components from modules
    RRTUI.version_scrollbox = BuildVersionCheckUI(versions_tab)
    RRTUI.nickname_frame = BuildNicknameEditUI()
    RRTUI.cooldowns_frame = BuildCooldownsEditUI()
    RRTUI.reminders_frame = BuildRemindersEditUI()
    RRTUI.pasound_frame = BuildPASoundEditUI()
    RRTUI.personal_reminders_frame = BuildPersonalRemindersEditUI()
    RRTUI.export_string_popup = BuildExportStringUI()
    RRTUI.import_string_popup = BuildImportStringUI()

    -- Version Number in status bar
    local versionNumber = " v"..C_AddOns.GetAddOnMetadata("ReversionRaidTools", "Version")
    --[==[@debug@
        if versionNumber == " v12.0.21" then
            versionNumber = " Dev Build"
        end
    --@end-debug@]==]
    local versionTitle = "|cFFC9A227Reversion Raid Tools|r"
    local statusBarText = versionTitle .. "|cFFFFFFFF" .. versionNumber .. " | " .. (authorsString) .. "|r"
    RRTUI.StatusBar.authorName:SetText(statusBarText)

    if (RRT.ApplyGlobalFontToAddonUI) then
        RRT:ApplyGlobalFontToAddonUI(false, true)
    end

    if (not self._globalFontHooksInstalled) then
        self._globalFontHooksInstalled = true

        self:HookScript("OnShow", function()
            if (RRT.ApplyGlobalFontToAddonUI) then
                RRT:ApplyGlobalFontToAddonUI(true, true)
            end
        end)
    end
end

function RRTUI:ToggleOptions()
    if RRTUI:IsShown() then
        RRTUI:Hide()
    else
        RRTUI:Show()
        if (RRT.ApplyGlobalFontToAddonUI) then
            RRT:ApplyGlobalFontToAddonUI(true, true)
        end
    end
end

function RRT:NickNamesSyncPopup(unit, nicknametable)
    local popup = DF:CreateSimplePanel(UIParent, 300, 120, "Sync Nicknames", "SyncNicknamesPopup", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local label = DF:CreateLabel(popup, RRTAPI:Shorten(unit) .. " is attempting to sync their nicknames with you.", 11)

    label:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
    label:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    label:SetJustifyH("CENTER")

    local cancel_button = DF:CreateButton(popup, function() popup:Hide() end, 130, 20, "Cancel")
    cancel_button:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    cancel_button:SetTemplate(options_button_template)

    local accept_button = DF:CreateButton(popup, function()
        RRT:SyncNickNamesAccept(nicknametable)
        popup:Hide()
    end, 130, 20, "Accept")
    accept_button:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    accept_button:SetTemplate(options_button_template)

    return popup
end

function RRT:DisplayText(text, duration)
    if self:Restricted() then return end
    if self.RRTFrame and self.RRTFrame.generic_display then
        self.RRTFrame.generic_display.Text:SetText(text)
        self.RRTFrame.generic_display:Show()
        self.RRTFrame.generic_display.Text:Show()
        if self.TextHideTimer then
            self.TextHideTimer:Cancel()
            self.TextHideTimer = nil
        end
        self.TextHideTimer = C_Timer.NewTimer(duration or 10, function() self.RRTFrame.generic_display:Hide() end)
    end
end














