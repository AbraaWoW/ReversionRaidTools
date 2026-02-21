local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local window_width = Core.window_width
local window_height = Core.window_height
local options_button_template = Core.options_button_template

local SUB_TABS_LIST = {
    { name = "Buffs", text = "Buffs" },
    { name = "Display", text = "Display" },
    { name = "Settings", text = "Settings" },
    { name = "ImportExport", text = "Import/Export" },
}

local function BuildPlaceholder(parent, text)
    if parent.PlaceholderText then
        return
    end

    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
    label:SetJustifyH("LEFT")
    label:SetText(text or "Coming soon")
    parent.PlaceholderText = label
end

local function BuildBuffRemindersUI(parent)
    if parent.BuffRemindersSubTabs then
        if parent.BuffRemindersSubTabs.RefreshCurrent then
            parent.BuffRemindersSubTabs:RefreshCurrent()
        end
        return parent.BuffRemindersSubTabs
    end

    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(window_width - 20, window_height - 110)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -90)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    container:SetBackdropColor(0, 0, 0, 0.2)
    container:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.4)

    local navWidth = 140
    local nav = CreateFrame("Frame", nil, container)
    nav:SetPoint("TOPLEFT", container, "TOPLEFT", 8, -8)
    nav:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 8, 8)
    nav:SetWidth(navWidth)

    local divider = container:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    divider:SetPoint("TOPLEFT", nav, "TOPRIGHT", 8, 0)
    divider:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 8, 0)
    divider:SetWidth(1)

    local contentHost = CreateFrame("Frame", nil, container)
    contentHost:SetPoint("TOPLEFT", nav, "TOPRIGHT", 16, 0)
    contentHost:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -8, 8)

    local subFrames = {}
    local buttons = {}
    local currentTab = SUB_TABS_LIST[1].name

    local function EnsureTabFrame(tabName)
        if subFrames[tabName] then
            return subFrames[tabName]
        end

        local frame = CreateFrame("Frame", nil, contentHost)
        frame:SetAllPoints(contentHost)
        frame:Hide()

        if tabName == "Buffs" then
            local buffsBuilder = RRT.UI.BuffReminders and RRT.UI.BuffReminders.Buffs
            if buffsBuilder and buffsBuilder.Build then
                buffsBuilder.Build(frame)
            else
                BuildPlaceholder(frame, "Buffs builder missing")
            end
        elseif tabName == "Display" then
            local displayBuilder = RRT.UI.BuffReminders and RRT.UI.BuffReminders.Display
            if displayBuilder and displayBuilder.Build then
                displayBuilder.Build(frame)
            else
                BuildPlaceholder(frame, "Display builder missing")
            end
        elseif tabName == "Settings" then
            local settingsBuilder = RRT.UI.BuffReminders and RRT.UI.BuffReminders.Settings
            if settingsBuilder and settingsBuilder.Build then
                settingsBuilder.Build(frame)
            else
                BuildPlaceholder(frame, "Settings builder missing")
            end
        elseif tabName == "ImportExport" then
            local importExportBuilder = RRT.UI.BuffReminders and RRT.UI.BuffReminders.ImportExport
            if importExportBuilder and importExportBuilder.Build then
                importExportBuilder.Build(frame)
            else
                BuildPlaceholder(frame, "Import/Export builder missing")
            end
        else
            BuildPlaceholder(frame, "Coming soon")
        end

        subFrames[tabName] = frame
        return frame
    end

    local function SetButtonTextColor(btn, r, g, b, a)
        if btn.SetTextColor then
            btn:SetTextColor(r, g, b, a)
        elseif btn.text and btn.text.SetTextColor then
            btn.text:SetTextColor(r, g, b, a)
        elseif btn.widget and btn.widget.text and btn.widget.text.SetTextColor then
            btn.widget.text:SetTextColor(r, g, b, a)
        end
    end

    local function UpdateButtonState()
        for tabName, btn in pairs(buttons) do
            local visualBtn = btn.widget or btn
            if tabName == currentTab then
                if visualBtn and visualBtn.SetBackdropColor then
                    visualBtn:SetBackdropColor(0.16, 0.16, 0.16, 0.95)
                end
                SetButtonTextColor(btn, 1, 0.82, 0, 1)
            else
                if visualBtn and visualBtn.SetBackdropColor then
                    visualBtn:SetBackdropColor(0.08, 0.08, 0.08, 0.75)
                end
                SetButtonTextColor(btn, 1, 1, 1, 1)
            end
        end
    end

    local function SelectTab(tabName)
        currentTab = tabName

        for name, frame in pairs(subFrames) do
            if name == tabName then
                frame:Show()
            else
                frame:Hide()
            end
        end

        local frame = EnsureTabFrame(tabName)
        frame:Show()
        UpdateButtonState()
    end

    local y = -2
    local btnHeight = 24
    local btnGap = 4
    for _, tab in ipairs(SUB_TABS_LIST) do
        local btn = DF:CreateButton(nav, function()
            SelectTab(tab.name)
        end, navWidth - 4, 24, tab.text)
        local btnFrame = btn.widget or btn

        btn:SetTemplate(options_button_template)
        if btn.SetPoint then
            btn:SetPoint("TOPLEFT", nav, "TOPLEFT", 2, y)
        elseif btnFrame and btnFrame.SetPoint then
            btnFrame:SetPoint("TOPLEFT", nav, "TOPLEFT", 2, y)
        end

        -- Backdrop for active state tinting
        if btnFrame and btnFrame.SetBackdrop then
            btnFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            btnFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
        end

        -- Override DF's white hover flash
        local tabName = tab.name
        if btnFrame and btnFrame.SetScript then
            btnFrame:SetScript("OnEnter", function(self)
                if tabName ~= currentTab then
                    self:SetBackdropColor(0.14, 0.14, 0.14, 0.95)
                end
            end)
            btnFrame:SetScript("OnLeave", function(self)
                if tabName ~= currentTab then
                    self:SetBackdropColor(0.08, 0.08, 0.08, 0.75)
                end
            end)
        end

        buttons[tab.name] = btn

        y = y - (btnHeight + btnGap)
    end

    function container:RefreshCurrent()
        local frame = subFrames[currentTab]
        if frame and frame.BuffsView and frame.BuffsView.Refresh then
            frame.BuffsView:Refresh()
        end
        if frame and frame.DisplayView and frame.DisplayView.Refresh then
            frame.DisplayView:Refresh()
        end
        if frame and frame.SettingsView and frame.SettingsView.Refresh then
            frame.SettingsView:Refresh()
        end
        if frame and frame.ImportExportView and frame.ImportExportView.Refresh then
            frame.ImportExportView:Refresh()
        end
    end

    SelectTab(currentTab)

    parent.BuffRemindersSubTabs = container
    return container
end

RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.BuffReminders = {
    BuildUI = BuildBuffRemindersUI,
}
