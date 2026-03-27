local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local LDB = LibStub("LibDataBroker-1.1")
local LDBIcon = LDB and LibStub("LibDBIcon-1.0")

-- Window dimensions
local window_width = 1050
local window_height = 640

-- Tabs configuration (text resolved lazily via L at build time)
local function MakeTabs()
    local L = RRT_NS.L
    return {
        { name = "General",         text = L["tab_general"] },
        { name = "Raid",            text = L["tab_raid"] },
        { name = "MythicPlus",      text = L["tab_mythicplus"] },
        { name = "Note",            text = L["tab_note"] },
        { name = "PrivateAura",     text = L["tab_private_aura"] },
        { name = "EncounterAlerts", text = L["tab_encounter_alerts"] },
        { name = "Versions",        text = L["tab_versions"] },
        { name = "QoL",             text = L["tab_quality_of_life"] },
    }
end
local TABS_LIST = MakeTabs

local authorsString = "By Abraa"

-- Override the DF font template used for button text in BuildMenu.
-- setExecuteProperties() overwrites button text settings with textTemplate AFTER
-- applying the button template, so we must fix the font template too.
DF.font_templates["OPTIONS_FONT_TEMPLATE"] = {
    color = {0.9, 0.9, 0.9, 1},
    size  = 10,
    font  = DF:GetBestFontForLanguage(),
}

-- Override the DF button template so every button in the addon matches the
-- dark sidebar-button style (dark bg, gray border, GameFontNormalSmall / 10pt).
DF.button_templates["OPTIONS_BUTTON_TEMPLATE"] = {
    backdrop = {
        edgeFile = [[Interface\Buttons\WHITE8X8]],
        edgeSize = 1,
        bgFile   = [[Interface\Buttons\WHITE8X8]],
    },
    backdropcolor       = {0.1,  0.1,  0.1,  0.6},
    backdropbordercolor = {0.25, 0.25, 0.25, 0.8},
    onentercolor        = {0.15, 0.15, 0.15, 0.8},
    onenterbordercolor  = {0.4,  0.4,  0.4,  1.0},
    textcolor           = {0.9,  0.9,  0.9,  1.0},
    textsize            = 10,
}

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
local RRTUI = DF:CreateSimplePanel(UIParent, window_width, window_height, "|cFFBB66FFReversion|r Raid Tools", "RRTUI",
    RRTUI_panel_options)
RRTUI:SetPoint("CENTER")
RRTUI:SetFrameStrata("HIGH")
DF:BuildStatusbarAuthorInfo(RRTUI.StatusBar, _, "x |cFFBB66FFbird|r")
RRTUI.StatusBar.discordTextEntry:SetText("https://discord.gg/5bhTbtQtCf")

-- Red close button
do
    local btn = RRTUI.Close
    if btn then
        btn:GetNormalTexture():SetVertexColor(1, 0.15, 0.15, 1)
        btn:GetHighlightTexture():SetVertexColor(1, 0.4, 0.4, 1)
        btn:GetPushedTexture():SetVertexColor(0.7, 0.05, 0.05, 1)
        btn:SetAlpha(1)
    end
end

RRTUI.OptionsChanged = {
    ["general"]   = {},
    ["raid"]      = {},
    ["versions"]  = {},
    ["nicknames"] = {},
}

-- Applies the current GlobalFont/GlobalFontSize to all addon display frames.
-- Excludes DF framework chrome (tab labels, option headers, window title).
function RRT_NS:ApplyGlobalFont()
    local font  = self.LSM:Fetch("font", RRT.Settings.GlobalFont)
    local sz    = RRT.Settings.GlobalFontSize or 20
    local encSz = RRT.Settings.GlobalEncounterFontSize or 20

    if self.RRTFrame then
        -- Generic text display (Ready Check, Assignments on Pull, …)
        local gd = self.RRTFrame.generic_display
        if gd and gd.Text then
            gd.Text:SetFont(font, sz, "OUTLINE")
        end
        -- Encounter alerts secret display
        local sd = self.RRTFrame.SecretDisplay
        if sd and sd.Text then
            sd.Text:SetFont(font, encSz, "OUTLINE")
        end
        -- QoL text display
        if self.RRTFrame.QoLText and self.RRTFrame.QoLText.text then
            local qolSz = RRT.QoL and RRT.QoL.TextDisplay and RRT.QoL.TextDisplay.FontSize or sz
            self.RRTFrame.QoLText.text:SetFont(font, qolSz, "OUTLINE")
        end
    end
    -- Private Aura text mover
    if self.PATextMoverFrame and self.PATextMoverFrame.Text then
        local paSz = RRT.PATextSettings and RRT.PATextSettings.Scale and (RRT.PATextSettings.Scale * 20) or sz
        self.PATextMoverFrame.Text:SetFont(font, paSz, "OUTLINE")
    end
    -- Private Aura raid preview icon labels
    if self.PARaidPreviewIcons then
        for i = 1, #self.PARaidPreviewIcons do
            local ico = self.PARaidPreviewIcons[i]
            if ico and ico.Text then
                ico.Text:SetFont(font, 16, "OUTLINE")
            end
        end
    end

    -- Brief preview so the user can see the font change immediately
    if self.RRTFrame and self.RRTFrame.generic_display then
        local gd = self.RRTFrame.generic_display
        gd.Text:SetFont(font, sz, "OUTLINE")
        gd.Text:SetText("Font preview: " .. (RRT.Settings.GlobalFont or ""))
        gd:SetSize(gd.Text:GetStringWidth(), gd.Text:GetStringHeight())
        gd:Show()
        if self._fontPreviewTimer then self._fontPreviewTimer:Cancel() end
        self._fontPreviewTimer = C_Timer.NewTimer(3, function()
            self._fontPreviewTimer = nil
            gd:Hide()
        end)
    end
end

-- Shared helper functions
local function build_media_options(typename, settingname, isTexture, isReminder, Personal, GlobalFont)
    local list = RRT_NS.LSM:List(isTexture and "statusbar" or "font")
    local t = {}
    for i, font in ipairs(list) do
        tinsert(t, {
            label = font,
            value = i,
            onclick = function(_, _, value)
                if GlobalFont then
                    RRT.Settings.GlobalFont = list[value]
                    RRT_NS:ApplyGlobalFont()
                    return
                end
                RRT.ReminderSettings[typename][settingname] = list[value]
                if isReminder then
                    RRT_NS:UpdateReminderFrame(true)
                else
                    RRT_NS:UpdateExistingFrames()
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
                RRT.ReminderSettings[SettingName]["GrowDirection"] = list[value]
                RRT_NS:UpdateExistingFrames()
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
                (list[value] == RRT[SettingName]["RowGrowDirection"] or
                (list[value] == "UP" and RRT[SettingName]["RowGrowDirection"] == "DOWN") or (list[value] == "DOWN" and RRT[SettingName]["RowGrowDirection"] == "UP") or
                (list[value] == "LEFT" and RRT[SettingName]["RowGrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and RRT[SettingName]["RowGrowDirection"] == "LEFT")) then
                    RRT[SettingName]["RowGrowDirection"] = RRT[SettingName]["GrowDirection"]
                    swapped = true

                elseif SecondaryName == "RowGrowDirection" and
                (list[value] == RRT[SettingName]["GrowDirection"] or
                (list[value] == "UP" and RRT[SettingName]["GrowDirection"] == "DOWN") or (list[value] == "DOWN" and RRT[SettingName]["GrowDirection"] == "UP") or
                (list[value] == "LEFT" and RRT[SettingName]["GrowDirection"] == "RIGHT") or (list[value] == "RIGHT" and RRT[SettingName]["GrowDirection"] == "LEFT")) then
                    RRT[SettingName]["GrowDirection"] = RRT[SettingName]["RowGrowDirection"]
                    swapped = true
                end
                RRT[SettingName][SecondaryName] = list[value]
                RRT_NS:UpdatePADisplay(SettingName == "PASettings", SettingName == "PATankSettings")

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
                RRT.ReminderSettings.UnitIconSettings.Position = list[value]
                RRT_NS:UpdateExistingFrames()
            end
        })
    end
    return t
end

local soundlist = RRT_NS.LSM:List("sound")
local function build_sound_dropdown()
    local t = {}
    for i, sound in ipairs(soundlist) do
        tinsert(t, {
            label = sound,
            value = i,
            onclick = function(_, _, value)
                local toplay = RRT_NS.LSM:Fetch("sound", sound)
                PlaySoundFile(toplay, "Master")
                RRT.ReminderSettings.DefaultSound = soundlist[value]
                return value
            end
        })
    end
    return t
end

-- Export to namespace
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Core = {
    RRTUI = RRTUI,
    window_width = window_width,
    window_height = window_height,
    TABS_LIST = MakeTabs,
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
    LDBIcon = LDBIcon,
}

-- Make RRTUI accessible globally through RRT_NS
RRT_NS.RRTUI = RRTUI
