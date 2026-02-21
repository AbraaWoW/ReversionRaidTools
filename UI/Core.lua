local _, RRT = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width = 1050
local window_height = 640

-- Tabs configuration
local TABS_LIST = {
    { name = "General",   text = "General" },
    { name = "Nicknames", text = "Nicknames" },
    { name = "Versions",  text = "Versions" },
    { name = "SetupManager", text = "Setup Manager"},
    { name = "ReadyCheck", text = "Ready Check"},
    { name = "Reminders", text = "Reminders"},
    { name = "Reminders-Note", text = "Reminders-Note"},
    { name = "Assignments", text = "Assignments"},
    { name = "EncounterAlerts", text = "Encounter Alerts"},
    { name = "PrivateAura", text = "Private Auras"},
    { name = "QoL", text = "Quality of Life" },
    { name = "BuffReminders", text = "Buff Reminders" },
}

local authorsString = "By Abraa"

-- Templates
local options_text_template = DF:GetTemplate("font", "OPTIONS_FONT_TEMPLATE")
local options_dropdown_template = DF:GetTemplate("dropdown", "OPTIONS_DROPDOWN_TEMPLATE")
local options_switch_template = DF:GetTemplate("switch", "OPTIONS_CHECKBOX_TEMPLATE")
local options_slider_template = DF:GetTemplate("slider", "OPTIONS_SLIDER_TEMPLATE")
local options_button_template = DF:GetTemplate("button", "OPTIONS_BUTTON_TEMPLATE")

-- Create main panel
local RRTUI_panel_options = {
    UseStatusBar = true
}
local RRTUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFFC9A227Reversion|r Raid Tools", "RRTUI",
    RRTUI_panel_options)
RRTUI:SetPoint("CENTER")
RRTUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(RRTUI.StatusBar, _, "x |cFF00FFFFbird|r")
if RRTUI.StatusBar.discordLabel and RRTUI.StatusBar.discordLabel.SetText then
    RRTUI.StatusBar.discordLabel:SetText("Twitch:")
end
RRTUI.StatusBar.discordTextEntry:SetText("https://twitch.tv/fakeheal66")

RRTUI.OptionsChanged = {
    ["general"] = {},
    ["nicknames"] = {},
    ["versions"] = {},
}

-- Shared helper functions
local function build_media_options(typename, settingname, isTexture, isReminder, Personal, GlobalFont)
    local list = RRT.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, font in ipairs(list) do
        tinsert(t, {
            label = font,
            value = i,
            onclick = function(_, _, value)
                if GlobalFont then
                    RRTDB.Settings.GlobalFont = list[value]
                    return
                end
                RRTDB.ReminderSettings[typename][settingname] = list[value]
                if isReminder then
                    RRT:UpdateReminderFrame(true)
                else
                    RRT:UpdateExistingFrames()
                end
            end
        })
    end
    return t
end

local function build_growdirection_options(SettingName, Icons)
    local list = Icons and {"Up", "Down", "Left", "Right"} or {"Up", "Down"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                RRTDB.ReminderSettings[SettingName]["GrowDirection"] = list[value]
                RRT:UpdateExistingFrames()
            end
        })
    end
    return t
end

local function build_PAgrowdirection_options(SettingName, SecondaryName)
    local list = {"LEFT", "RIGHT", "UP", "DOWN"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                local swapped = false
                if SecondaryName == "GrowDirection" and
                (list[value] == RRTDB[SettingName]["RowGrowDirection"] or
                (list[value] == "UP" and RRTDB[SettingName]["RowGrowDirection"] == "DOWN") or (list[value] == "DOWN" and RRTDB[SettingName]["RowGrowDirection"] == "UP") or
                (list[value] == "LEFT" and RRTDB[SettingName]["RowGrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and RRTDB[SettingName]["RowGrowDirection"] == "LEFT")) then
                    RRTDB[SettingName]["RowGrowDirection"] = RRTDB[SettingName]["GrowDirection"]
                    swapped = true

                elseif SecondaryName == "RowGrowDirection" and
                (list[value] == RRTDB[SettingName]["GrowDirection"] or
                (list[value] == "UP" and RRTDB[SettingName]["GrowDirection"] == "DOWN") or (list[value] == "DOWN" and RRTDB[SettingName]["GrowDirection"] == "UP") or
                (list[value] == "LEFT" and RRTDB[SettingName]["GrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and RRTDB[SettingName]["GrowDirection"] == "LEFT")) then
                    RRTDB[SettingName]["GrowDirection"] = RRTDB[SettingName]["RowGrowDirection"]
                    swapped = true
                end
                RRTDB[SettingName][SecondaryName] = list[value]
                RRT:UpdatePADisplay(SettingName == "PASettings", SettingName == "PATankSettings")

                if swapped then RRTUI.MenuFrame:GetTabFrameByName("PrivateAura"):RefreshOptions() end
            end
        })
    end
    return t
end

local function build_raidframeicon_options()
    local list = {"TOPLEFT", "TOP", "TOPRIGHT", "LEFT", "CENTER", "RIGHT", "BOTTOMLEFT", "BOTTOM", "BOTTOMRIGHT"}
    local t = {}
    for i, v in ipairs(list) do
        tinsert(t, {
            label = v,
            value = i,
            onclick = function(_, _, value)
                RRTDB.ReminderSettings.UnitIconSettings.Position = list[value]
                RRT:UpdateExistingFrames()
            end
        })
    end
    return t
end

local function apply_scrollbar_style(scrollObject)
    if not (DF and scrollObject) then
        return
    end

    -- Match Versions tab scrollbar style everywhere possible.
    pcall(function()
        DF:ReskinSlider(scrollObject)
    end)

    if scrollObject.ScrollBar then
        pcall(function()
            DF:ReskinSlider(scrollObject.ScrollBar)
        end)
    end
end

local soundlist = RRT.LSM:List("sound")
local function build_sound_dropdown()
    local t = {}
    for i, sound in ipairs(soundlist) do
        tinsert(t, {
            label = sound,
            value = i,
            onclick = function(_, _, value)
                local toplay = RRT.LSM:Fetch("sound", sound)
                PlaySoundFile(toplay, "Master")
                RRTDB.ReminderSettings.DefaultSound = soundlist[value]
                return value
            end
        })
    end
    return t
end

-- Export to namespace
RRT.UI = RRT.UI or {}
RRT.UI.Core = {
    RRTUI = RRTUI,
    window_width = window_width,
    window_height = window_height,
    TABS_LIST = TABS_LIST,
    authorsString = authorsString,
    options_text_template = options_text_template,
    options_dropdown_template = options_dropdown_template,
    options_switch_template = options_switch_template,
    options_slider_template = options_slider_template,
    options_button_template = options_button_template,
    build_media_options = build_media_options,
    build_growdirection_options = build_growdirection_options,
    build_PAgrowdirection_options = build_PAgrowdirection_options,
    build_raidframeicon_options = build_raidframeicon_options,
    build_sound_dropdown = build_sound_dropdown,
    apply_scrollbar_style = apply_scrollbar_style,
    LDBIcon = LDBIcon,
}

-- Make RRTUI accessible globally through RRT
RRT.RRTUI = RRTUI













