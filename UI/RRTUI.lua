local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

-- Get references from Core module
local Core = RRT_NS.UI.Core
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
local BuildVersionCheckUI = RRT_NS.UI.VersionCheck.BuildVersionCheckUI
local BuildRaidUI = RRT_NS.UI.Raid.BuildRaidUI
local BuildRemindersEditUI = RRT_NS.UI.Reminders.BuildRemindersEditUI
local BuildPersonalRemindersEditUI = RRT_NS.UI.Reminders.BuildPersonalRemindersEditUI
local BuildCooldownsEditUI = RRT_NS.UI.Cooldowns.BuildCooldownsEditUI
local BuildPASoundEditUI     = RRT_NS.UI.PrivateAuras.BuildPASoundEditUI
local BuildBuffSoundEditUI   = RRT_NS.UI.PrivateAuras.BuildBuffSoundEditUI
local BuildDebuffSoundEditUI = RRT_NS.UI.PrivateAuras.BuildDebuffSoundEditUI
local BuildExportStringUI = RRT_NS.UI.General.BuildExportStringUI
local BuildImportStringUI = RRT_NS.UI.General.BuildImportStringUI
local BuildRaidFrameUI    = RRT_NS.UI.RaidFrame.BuildRaidFrameUI
local BuildQoLUI            = RRT_NS.UI.QoL.BuildQoLUI
local BuildNoteUI           = RRT_NS.UI.Note.BuildNoteUI
local BuildMythicPlusUI     = RRT_NS.UI.MythicPlus.BuildMythicPlusUI

-- Get options builders from modules
local BuildGeneralOptions = RRT_NS.UI.Options.General.BuildOptions
local BuildGeneralCallback = RRT_NS.UI.Options.General.BuildCallback
local BuildSetupManagerOptions = RRT_NS.UI.Options.SetupManager.BuildOptions
local BuildSetupManagerCallback = RRT_NS.UI.Options.SetupManager.BuildCallback
local BuildEncounterAlertsUI = RRT_NS.UI.EncounterAlerts.BuildEncounterAlertsUI
local BuildReadyCheckOptions = RRT_NS.UI.Options.ReadyCheck.BuildOptions
local BuildRaidBuffMenu = RRT_NS.UI.Options.ReadyCheck.BuildRaidBuffMenu
local BuildReadyCheckCallback = RRT_NS.UI.Options.ReadyCheck.BuildCallback
local BuildPrivateAurasOptions  = RRT_NS.UI.Options.PrivateAuras.BuildOptions
local BuildPrivateAurasCallback = RRT_NS.UI.Options.PrivateAuras.BuildCallback
local BuildNicknamesOptions     = RRT_NS.UI.Options.Nicknames.BuildOptions
local BuildNicknamesCallback    = RRT_NS.UI.Options.Nicknames.BuildCallback
local BuildNicknameEditUI       = RRT_NS.UI.Nicknames.BuildNicknameEditUI

function RRTUI:Init()
    RRT_NS.IsBuilding = true
    -- Create the scale bar
    DF:CreateScaleBar(RRTUI, RRT.RRTUI)
    local scale = math.max(RRT.RRTUI.scale, 0.6) -- prevent negative numbers
    RRTUI:SetScale(scale)

    -- Create the tab container
    -- 7 tabs (General merged with Nicknames via sidebar): row1 = General/Raid/Note/PrivateAura, row2 = EncounterAlerts/Versions/QoL
    local tabList = TABS_LIST()
    local tabContainer = DF:CreateTabContainer(RRTUI, "Reversion", "RRTUI_TabsTemplate", tabList, {
        width = window_width,
        height = window_height - 5,
        backdrop_color = { 0, 0, 0, 0.2 },
        backdrop_border_color = { 0.1, 0.1, 0.1, 0.4 },
        button_selected_border_color = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1},
        button_width = 200,
    })
    tabContainer:SetPoint("CENTER", RRTUI, "CENTER", 0, 0)
    RRTUI.MenuFrame = tabContainer  -- Store reference for later access

    -- Style main tab buttons to match sidebar style (dark backdrop + theme border)
    local tc          = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    local tabThemeR   = tc[1]
    local tabThemeG   = tc[2]
    local tabThemeB   = tc[3]
    local activeTabBtn = nil

    local TAB_BACKDROP = {
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    }

    local function TabBtn_Normal(b)
        b:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        b:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
    end

    local function TabBtn_Active(b)
        b:SetBackdropColor(tabThemeR*0.4, tabThemeG*0.4, tabThemeB*0.4, 0.8)
        b:SetBackdropBorderColor(tabThemeR, tabThemeG, tabThemeB, 1)
    end

    for _, btn in ipairs(tabContainer.AllButtons) do
        local b = btn.button
        b:SetHighlightTexture("")
        b:SetPushedTexture("")
        btn.textsize  = 10
        btn.textcolor = {0.9, 0.9, 0.9, 1}
        if btn.selectedUnderlineGlow then
            btn.selectedUnderlineGlow:SetVertexColor(tabThemeR, tabThemeG, tabThemeB, 1)
        end

        if b.SetBackdrop then
            b:SetBackdrop(TAB_BACKDROP)
            TabBtn_Normal(b)

            b:SetScript("OnEnter", function(self)
                if activeTabBtn ~= self then
                    self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
                end
            end)
            b:SetScript("OnLeave", function(self)
                if activeTabBtn ~= self then
                    TabBtn_Normal(self)
                end
            end)

            local origClick = b:GetScript("OnClick")
            b:SetScript("OnClick", function(self, ...)
                if activeTabBtn and activeTabBtn ~= self then
                    TabBtn_Normal(activeTabBtn)
                end
                TabBtn_Active(self)
                activeTabBtn = self
                if origClick then origClick(self, ...) end
            end)
        end
    end

    -- Mark the first tab as active on startup
    if tabContainer.AllButtons[1] then
        local b = tabContainer.AllButtons[1].button
        if b and b.SetBackdrop then
            TabBtn_Active(b)
            activeTabBtn = b
        end
    end

    -- Get tab frames
    local general_tab       = tabContainer:GetTabFrameByName("General")
    local raid_tab          = tabContainer:GetTabFrameByName("Raid")
    local mythicplus_tab    = tabContainer:GetTabFrameByName("MythicPlus")
    local note_tab          = tabContainer:GetTabFrameByName("Note")
    local versions_tab      = tabContainer:GetTabFrameByName("Versions")
    local encounteralerts_tab = tabContainer:GetTabFrameByName("EncounterAlerts")
    local privateaura_tab   = tabContainer:GetTabFrameByName("PrivateAura")
    local QoL_tab           = tabContainer:GetTabFrameByName("QoL")

    -- Generic text display
    RRT_NS.RRTFrame.generic_display = CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
    RRT_NS.RRTFrame.generic_display:Hide()
    RRT_NS.RRTFrame.generic_display:SetPoint(RRT.Settings.GenericDisplay.Anchor, RRT_NS.RRTFrame, RRT.Settings.GenericDisplay.relativeTo, RRT.Settings.GenericDisplay.xOffset, RRT.Settings.GenericDisplay.yOffset)
    RRT_NS.RRTFrame.generic_display.Text = RRT_NS.RRTFrame.generic_display:CreateFontString(nil, "OVERLAY")
    RRT_NS.RRTFrame.generic_display.Text:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.Settings.GlobalFontSize, "OUTLINE")
    RRT_NS.RRTFrame.generic_display.Text:SetPoint("TOPLEFT", RRT_NS.RRTFrame.generic_display, "TOPLEFT", 0, 0)
    RRT_NS.RRTFrame.generic_display.Text:SetJustifyH("LEFT")
    RRT_NS.RRTFrame.generic_display.Text:SetText("Things that might be displayed here:\nReady Check Module\nAssignments on Pull\n")
    RRT_NS.RRTFrame.generic_display:SetSize(RRT_NS.RRTFrame.generic_display.Text:GetStringWidth(), RRT_NS.RRTFrame.generic_display.Text:GetStringHeight())
    RRT_NS:MoveFrameInit(RRT_NS.RRTFrame.generic_display, "Generic")

    -- Frame to display secret text
    RRT_NS.RRTFrame.SecretDisplay = CreateFrame("Frame", nil, RRT_NS.RRTFrame, "BackdropTemplate")
    RRT_NS.RRTFrame.SecretDisplay:Hide()
    RRT_NS.RRTFrame.SecretDisplay:SetPoint(RRT.Settings.GenericDisplay.Anchor, RRT_NS.RRTFrame, RRT.Settings.GenericDisplay.relativeTo, RRT.Settings.GenericDisplay.xOffset, RRT.Settings.GenericDisplay.yOffset)
    RRT_NS.RRTFrame.SecretDisplay.Text = RRT_NS.RRTFrame.SecretDisplay:CreateFontString(nil, "OVERLAY")
    RRT_NS.RRTFrame.SecretDisplay.Text:SetFont(RRT_NS.LSM:Fetch("font", RRT.Settings.GlobalFont), RRT.Settings.GlobalEncounterFontSize, "OUTLINE")
    RRT_NS.RRTFrame.SecretDisplay.Text:SetPoint("TOPLEFT", RRT_NS.RRTFrame.generic_display, "TOPLEFT", 0, 0)
    RRT_NS.RRTFrame.SecretDisplay.Text:SetJustifyH("LEFT")
    RRT_NS.RRTFrame.SecretDisplay.Text:SetText("")
    RRT_NS.RRTFrame.SecretDisplay:SetSize(2000, 2000)

    -- Build options tables from modules
    local general_options1_table    = BuildGeneralOptions()
    local nicknames_options1_table  = BuildNicknamesOptions()
    BuildEncounterAlertsUI(encounteralerts_tab)
    local RaidBuffMenu = BuildRaidBuffMenu()
    local privateaura_options1_table = BuildPrivateAurasOptions()

    -- Build callbacks
    local general_callback    = BuildGeneralCallback()
    local nicknames_callback  = BuildNicknamesCallback()
    local privateaura_callback = BuildPrivateAurasCallback()

    -- General tab — sidebar with sub-tabs: General / Nicknames
    do
        local SIDEBAR_W = 130
        local ITEM_H    = 20
        local PAD       = 4
        local SECTIONS  = {
            { name = "General",   key = "general",   options = general_options1_table,   callback = general_callback },
            { name = "Nicknames", key = "nicknames",  options = nicknames_options1_table,  callback = nicknames_callback },
        }

        local breadcrumb = general_tab:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        breadcrumb:SetPoint("TOPLEFT", general_tab, "TOPLEFT", 10, -76)
        breadcrumb:SetText("|cFFBB66FF" .. SECTIONS[1].name .. "|r")

        local sidebar = CreateFrame("Frame", nil, general_tab, "BackdropTemplate")
        sidebar:SetPoint("TOPLEFT",    general_tab, "TOPLEFT",    4, -100)
        sidebar:SetPoint("BOTTOMLEFT", general_tab, "BOTTOMLEFT", 4,  22)
        sidebar:SetWidth(SIDEBAR_W)
        sidebar:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
        sidebar:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

        local contentArea = CreateFrame("Frame", nil, general_tab)
        contentArea:SetPoint("TOPLEFT",     general_tab, "TOPLEFT",     SIDEBAR_W + 8, -100)
        contentArea:SetPoint("BOTTOMRIGHT", general_tab, "BOTTOMRIGHT", -4, 22)

        local panels = {}
        for _, sec in ipairs(SECTIONS) do
            local panel = CreateFrame("Frame", "RRTGeneralSection_" .. sec.key, contentArea)
            panel:SetAllPoints(contentArea)
            panel:Hide()
            DF:BuildMenu(panel, sec.options, 10, -5, window_height - 120, false,
                options_text_template, options_dropdown_template, options_switch_template,
                true, options_slider_template, options_button_template, sec.callback)
            panels[sec.key] = panel
        end

        local activeBtn   = nil
        local currentName = SECTIONS[1].name

        local function SelectSection(key, btn, name)
            for k, p in pairs(panels) do p:SetShown(k == key) end
            if activeBtn then
                activeBtn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
                activeBtn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
            end
            local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
            btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
            btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
            activeBtn    = btn
            currentName  = name
            local hex = string.format("%02X%02X%02X",
                math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
            breadcrumb:SetText("|cFF" .. hex .. name .. "|r")
        end

        for i, sec in ipairs(SECTIONS) do
            local btn = CreateFrame("Button", nil, sidebar, "BackdropTemplate")
            btn:SetSize(SIDEBAR_W - PAD * 2, ITEM_H)
            btn:SetPoint("TOPLEFT", sidebar, "TOPLEFT", PAD, -(PAD + (i - 1) * (ITEM_H + 4)))
            btn:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
            btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)

            local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            do local f, _, fl = GameFontNormalSmall:GetFont()
               if f then btnText:SetFont(f, 9, fl or "") end
            end
            btnText:SetPoint("CENTER", btn, "CENTER", 0, 0)
            btnText:SetText(sec.name)
            btnText:SetTextColor(0.9, 0.9, 0.9, 1)

            local key  = sec.key
            local name = sec.name
            btn:SetScript("OnClick", function(self) SelectSection(key, self, name) end)
            btn:SetScript("OnEnter", function(self)
                if activeBtn ~= self then self:SetBackdropColor(0.15, 0.15, 0.15, 0.8) end
            end)
            btn:SetScript("OnLeave", function(self)
                if activeBtn ~= self then self:SetBackdropColor(0.1, 0.1, 0.1, 0.6) end
            end)

            if i == 1 then SelectSection(key, btn, name) end
        end

        tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
            if activeBtn then
                activeBtn:SetBackdropColor(r*0.4, g*0.4, b*0.4, 0.8)
                activeBtn:SetBackdropBorderColor(r, g, b, 1)
            end
            local hex = string.format("%02X%02X%02X",
                math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
            breadcrumb:SetText("|cFF" .. hex .. currentName .. "|r")
        end)
    end
    DF:BuildMenu(RRT_NS.RaidBuffCheck, RaidBuffMenu, 2, -30, 40, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        nil)
    DF:BuildMenu(privateaura_tab, privateaura_options1_table, 10, -100, window_height - 10, false, options_text_template,
        options_dropdown_template, options_switch_template, true, options_slider_template, options_button_template,
        privateaura_callback)
    -- Note tab — sub-tab container
    BuildNoteUI(note_tab)
    BuildQoLUI(QoL_tab)

    BuildMythicPlusUI(mythicplus_tab)
    RRT_NS.RaidBuffCheck:SetMovable(false)
    RRT_NS.RaidBuffCheck:EnableMouse(false)

    -- Build UI components from modules
    RRTUI.version_scrollbox = BuildVersionCheckUI(versions_tab)
    RRTUI.raid_panels = BuildRaidUI(raid_tab)
    RRTUI.cooldowns_frame = BuildCooldownsEditUI()
    RRTUI.reminders_frame = BuildRemindersEditUI()
    RRTUI.pasound_frame    = BuildPASoundEditUI()
    RRTUI.buffsound_frame  = BuildBuffSoundEditUI()
    RRTUI.debuffsound_frame = BuildDebuffSoundEditUI()
    RRTUI.personal_reminders_frame = BuildPersonalRemindersEditUI()
    RRTUI.export_string_popup = BuildExportStringUI()
    RRTUI.import_string_popup = BuildImportStringUI()
    RRTUI.raidframe           = BuildRaidFrameUI()
    RRTUI.nickname_frame      = BuildNicknameEditUI()

    -- Version Number in status bar
    local versionNumber = " v"..C_AddOns.GetAddOnMetadata("ReversionRaidTools", "Version")
    --[==[@debug@
        if versionNumber == " v1.0.0" then
            versionNumber = " Dev Build"
        end
    --@end-debug@]==]
    local function BuildThemeText(r, g, b)
        local hex = string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        return hex
    end

    local c = RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
    local initHex = BuildThemeText(c[1], c[2], c[3])
    RRTUI.Title:SetText("|cFF" .. initHex .. "Reversion|r Raid Tools")
    RRTUI.StatusBar.authorName:SetText("|cFF" .. initHex .. "Reversion Raid Tools|r" .. versionNumber .. " | |cFFFFFFFF" .. authorsString .. "|r")

    -- Register theme color callback for title, status bar, and tab buttons
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        tabThemeR, tabThemeG, tabThemeB = r, g, b
        local hex = BuildThemeText(r, g, b)
        RRTUI.Title:SetText("|cFF" .. hex .. "Reversion|r Raid Tools")
        RRTUI.StatusBar.authorName:SetText("|cFF" .. hex .. "Reversion Raid Tools|r" .. versionNumber .. " | |cFFFFFFFF" .. authorsString .. "|r")
        -- Update tab buttons
        if activeTabBtn then TabBtn_Active(activeTabBtn) end
        for _, btn in ipairs(tabContainer.AllButtons) do
            if btn.selectedUnderlineGlow then
                btn.selectedUnderlineGlow:SetVertexColor(r, g, b, a or 1)
            end
        end
    end)

    RRT_NS.IsBuilding = false
end

function RRT_NS:NickNamesSyncPopup(unit, nicknametable)
    local popup = DF:CreateSimplePanel(UIParent, 300, 120, "Sync Nicknames", "RRTSyncNicknamesPopup", {
        DontRightClickClose = true
    })
    popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)

    local label = DF:CreateLabel(popup,
        RRTAPI:Shorten(unit) .. " wants to sync their nicknames with you.", 11)
    label:SetPoint("TOPLEFT",    popup, "TOPLEFT",    10, -30)
    label:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 40)
    label:SetJustifyH("CENTER")

    local btn_cancel = DF:CreateButton(popup, function() popup:Hide() end, 130, 20, "Cancel")
    btn_cancel:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, 10)
    btn_cancel:SetTemplate(options_button_template)

    local btn_accept = DF:CreateButton(popup, function()
        RRT_NS:SyncNickNamesAccept(nicknametable)
        popup:Hide()
    end, 130, 20, "Accept")
    btn_accept:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, 10)
    btn_accept:SetTemplate(options_button_template)

    popup:Show()
    return popup
end

function RRTUI:ToggleOptions()
    if RRTUI:IsShown() then
        RRTUI:Hide()
    else
        RRTUI:Show()
    end
end

function RRT_NS:DisplayText(text, duration)
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

function RRT_NS:DisplaySecretText(format, Hide, args)
    if self.RRTFrame and self.RRTFrame.SecretDisplay then
        if Hide then
            self.RRTFrame.SecretDisplay:Hide()
            self.RRTFrame.SecretDisplay.Text:Hide()
            return
        end
        self.RRTFrame.SecretDisplay.Text:SetFormattedText(format or "%s", unpack(args or {}))
        self.RRTFrame.SecretDisplay:Show()
        self.RRTFrame.SecretDisplay.Text:Show()
    end
end