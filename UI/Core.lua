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
    { name = "RaidInspect", text = "Raid Inspect" },
    { name = "Profiles", text = "Profiles" },
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
local function build_media_options(typename, settingname, isTexture, isReminder, _unusedPersonal, GlobalFont)
    local list = RRT.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, font in ipairs(list) do
        tinsert(t, {
            label = font,
            value = i,
            onclick = function(_, _, value)
                if GlobalFont then
                    RRTDB.Settings.GlobalFont = list[value]
                    if (RRT and RRT.ApplyGlobalFontToAddonUI) then
                        RRT:ApplyGlobalFontToAddonUI(false, true)
                    end
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

local function get_global_font_path()
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    if (RRT and RRT.LSM and RRT.LSM.Fetch) then
        local fetched = RRT.LSM:Fetch("font", fontName)
        if (fetched and fetched ~= "") then
            return fetched
        end
    end
    return "Fonts\\FRIZQT__.TTF"
end

local function set_fontstring_font(fs, fontPath)
    if (not fs or not fs.GetObjectType or fs:GetObjectType() ~= "FontString") then
        return
    end
    local _, size, flags = fs:GetFont()
    local finalSize = tonumber(size) or 10
    pcall(fs.SetFont, fs, fontPath, finalSize, flags or "")
end

local function apply_font_recursive(obj, fontPath, visited)
    if (not obj or visited[obj]) then
        return
    end
    visited[obj] = true

    if (obj.GetObjectType) then
        if (obj:GetObjectType() == "FontString") then
            set_fontstring_font(obj, fontPath)
        end

        if (obj.GetRegions) then
            local regions = { obj:GetRegions() }
            for i = 1, #regions do
                local region = regions[i]
                if (region and region.GetObjectType and region:GetObjectType() == "FontString") then
                    set_fontstring_font(region, fontPath)
                end
            end
        end

        if (obj.GetChildren) then
            local children = { obj:GetChildren() }
            for i = 1, #children do
                apply_font_recursive(children[i], fontPath, visited)
            end
        end
    end
end

local function apply_global_font_to_df_templates(fontPath)
    if (options_text_template) then
        options_text_template.font = fontPath
    end
    if (options_button_template) then
        options_button_template.textfont = fontPath
    end
    if (options_dropdown_template) then
        options_dropdown_template.textfont = fontPath
    end
    if (options_switch_template) then
        options_switch_template.textfont = fontPath
    end
    if (options_slider_template) then
        options_slider_template.textfont = fontPath
    end

    local fontTemplates = DF and DF.font_templates
    if (fontTemplates) then
        if (fontTemplates["OPTIONS_FONT_TEMPLATE"]) then
            fontTemplates["OPTIONS_FONT_TEMPLATE"].font = fontPath
        end
        if (fontTemplates["ORANGE_FONT_TEMPLATE"]) then
            fontTemplates["ORANGE_FONT_TEMPLATE"].font = fontPath
        end
        if (fontTemplates["SMALL_SILVER"]) then
            fontTemplates["SMALL_SILVER"].font = fontPath
        end
    end

    local buttonTemplates = DF and DF.button_templates
    if (buttonTemplates and buttonTemplates["OPTIONS_BUTTON_TEMPLATE"]) then
        buttonTemplates["OPTIONS_BUTTON_TEMPLATE"].textfont = fontPath
    end
    local dropdownTemplates = DF and DF.dropdown_templates
    if (dropdownTemplates and dropdownTemplates["OPTIONS_DROPDOWN_TEMPLATE"]) then
        dropdownTemplates["OPTIONS_DROPDOWN_TEMPLATE"].textfont = fontPath
    end
    local switchTemplates = DF and DF.switch_templates
    if (switchTemplates and switchTemplates["OPTIONS_CHECKBOX_TEMPLATE"]) then
        switchTemplates["OPTIONS_CHECKBOX_TEMPLATE"].textfont = fontPath
    end
    local sliderTemplates = DF and DF.slider_templates
    if (sliderTemplates and sliderTemplates["OPTIONS_SLIDER_TEMPLATE"]) then
        sliderTemplates["OPTIONS_SLIDER_TEMPLATE"].textfont = fontPath
    end
end

local function apply_templates_to_options_widget(widget)
    if (not widget) then
        return
    end

    if (widget.hasLabel and widget.hasLabel.SetTemplate) then
        pcall(widget.hasLabel.SetTemplate, widget.hasLabel, options_text_template)
    end

    local widgetType = widget.widget_type
    if (widget.SetTemplate) then
        if (widgetType == "label") then
            pcall(widget.SetTemplate, widget, options_text_template)
        elseif (widgetType == "select") then
            pcall(widget.SetTemplate, widget, options_dropdown_template)
        elseif (widgetType == "toggle") then
            pcall(widget.SetTemplate, widget, options_switch_template)
        elseif (widgetType == "range") then
            pcall(widget.SetTemplate, widget, options_slider_template)
        elseif (widgetType == "execute") then
            pcall(widget.SetTemplate, widget, options_button_template)
        elseif (widgetType == "textentry") then
            pcall(widget.SetTemplate, widget, options_dropdown_template)
        end
    end
end

local function refresh_options_panel_font(panel)
    if (not panel) then
        return
    end

    if (type(panel.widget_list) == "table") then
        for i = 1, #panel.widget_list do
            apply_templates_to_options_widget(panel.widget_list[i])
        end
    end
end

function RRT:ApplyGlobalFontToAddonUI(skipTrackerRefresh, forceApply)
    local fontPath = get_global_font_path()
    if (not forceApply and self._lastAppliedGlobalFontPath == fontPath) then
        return
    end
    self._lastAppliedGlobalFontPath = fontPath

    apply_global_font_to_df_templates(fontPath)

    local visited = {}
    local roots = {}

    local function AddRoot(root)
        if (root) then
            roots[#roots + 1] = root
        end
    end

    AddRoot(RRT.RRTUI)
    AddRoot(RRT.RRTFrame)
    AddRoot(RRT.RaidBuffCheck)

    if (RRT.RRTUI) then
        AddRoot(RRT.RRTUI.MenuFrame)
        AddRoot(RRT.RRTUI.version_scrollbox)
        AddRoot(RRT.RRTUI.nickname_frame)
        AddRoot(RRT.RRTUI.cooldowns_frame)
        AddRoot(RRT.RRTUI.reminders_frame)
        AddRoot(RRT.RRTUI.pasound_frame)
        AddRoot(RRT.RRTUI.personal_reminders_frame)
        AddRoot(RRT.RRTUI.export_string_popup)
        AddRoot(RRT.RRTUI.import_string_popup)
        AddRoot(RRT.RRTUI.StatusBar)
    end

    if (RRT.SpellTracker and RRT.SpellTracker.displayFrames) then
        for _, display in pairs(RRT.SpellTracker.displayFrames) do
            AddRoot(display.frame)
            AddRoot(display.title)
        end
    end

    for i = 1, #roots do
        apply_font_recursive(roots[i], fontPath, visited)
    end

    if (RRT.RRTUI and RRT.RRTUI.MenuFrame) then
        for i = 1, #TABS_LIST do
            local tabName = TABS_LIST[i] and TABS_LIST[i].name
            if (tabName and RRT.RRTUI.MenuFrame.GetTabFrameByName) then
                local tab = RRT.RRTUI.MenuFrame:GetTabFrameByName(tabName)
                refresh_options_panel_font(tab)
            end
        end
    end
    refresh_options_panel_font(RRT.RaidBuffCheck)

    if (not skipTrackerRefresh and RRT.SpellTracker and RRT.SpellTracker.RefreshDisplay) then
        RRT.SpellTracker:RefreshDisplay()
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













