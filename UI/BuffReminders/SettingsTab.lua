local _, RRT = ...
local DF = _G["DetailsFramework"]

RRT.BuffReminders = RRT.BuffReminders or {}
RRT.UI = RRT.UI or {}
RRT.UI.BuffReminders = RRT.UI.BuffReminders or {}

local Core = RRT.UI.Core
local options_switch_template = Core.options_switch_template
local options_dropdown_template = Core.options_dropdown_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template
local apply_scrollbar_style = Core.apply_scrollbar_style

local TRACKING_MODES = {
    { value = "all", label = "All buffs, all players" },
    { value = "my_buffs", label = "Only my buffs, all players" },
    { value = "personal", label = "Only buffs I need" },
    { value = "smart", label = "Smart" },
}

local function EnsureDB()
    RRTDB.BuffReminders = RRTDB.BuffReminders or {}
    local db = RRTDB.BuffReminders
    if db.showOnlyInGroup == nil then db.showOnlyInGroup = false end
    if db.hideWhileResting == nil then db.hideWhileResting = false end
    if db.showOnlyOnReadyCheck == nil then db.showOnlyOnReadyCheck = false end
    if db.readyCheckDuration == nil then db.readyCheckDuration = 15 end
    if db.buffTrackingMode == nil then db.buffTrackingMode = "all" end
    if db.showLoginMessages == nil then db.showLoginMessages = true end
    if db.hidePetWhileMounted == nil then db.hidePetWhileMounted = true end
    if db.petPassiveOnlyInCombat == nil then db.petPassiveOnlyInCombat = false end
    return db
end

local function ApplyRRTFont(fontString, size)
    if not fontString then
        return
    end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then
        fontString:SetFont(fetched, size or 10, "OUTLINE")
    end
end

local function BuildDropdownValues(options, onSelect)
    local values = {}
    for _, opt in ipairs(options) do
        values[#values + 1] = {
            label = opt.label,
            value = opt.value,
            onclick = function(_, _, value)
                if onSelect then
                    onSelect(value)
                end
            end,
        }
    end
    return values
end

local function BuildSettingsTab(parent)
    local db = EnsureDB()

    if parent.SettingsView then
        parent.SettingsView:Show()
        if parent.SettingsView.Refresh then
            parent.SettingsView:Refresh()
        end
        return parent.SettingsView
    end

    local container = CreateFrame("Frame", nil, parent)
    container:SetAllPoints()

    local scroll = CreateFrame("ScrollFrame", nil, container, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", container, "TOPLEFT", 6, -38)
    scroll:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -26, 6)
    if apply_scrollbar_style then
        apply_scrollbar_style(scroll)
    end

    local content = CreateFrame("Frame", nil, scroll)
    content:SetPoint("TOPLEFT")
    content:SetSize(math.max(200, container:GetWidth() - 30), 700)
    scroll:SetScrollChild(content)

    container:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(math.max(200, width - 30))
    end)

    local refreshers = {}
    local function registerRefresher(fn)
        refreshers[#refreshers + 1] = fn
    end

    local function triggerDisplayRefresh()
        local display = RRT.BuffReminders and RRT.BuffReminders.Display
        if display and display.Update then
            display.Update()
        end
    end

    local function makeHeader(x, y, text)
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyRRTFont(header, 11)
        header:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        header:SetText("|cffffcc00" .. text .. "|r")
        return y - 20
    end

    local function makeSwitch(x, y, width, labelText, getValue, setValue)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        row:SetSize(width, 22)

        local sw = DF:CreateSwitch(row, function(_, _, value)
            setValue(value and true or false)
        end, false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
        sw:SetAsCheckBox()
        sw:SetPoint("LEFT", row, "LEFT", 0, 0)
        if sw.Text then
            sw.Text:SetText("")
            sw.Text:Hide()
        end

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyRRTFont(label, 10)
        label:SetPoint("LEFT", row, "LEFT", 24, 0)
        label:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        label:SetJustifyH("LEFT")
        label:SetText(labelText)

        registerRefresher(function()
            sw:SetValue(getValue() and true or false)
        end)

        return y - 24
    end

    local function makeSlider(x, y, width, labelText, min, max, step, getValue, setValue, enabledFn)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        row:SetSize(width, 30)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyRRTFont(label, 10)
        label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        label:SetText(labelText)

        local sliderWidth = math.max(120, width - 8)
        local slider = DF:CreateSlider(row, sliderWidth, 16, min, max, step, min, false)
        slider:SetTemplate(options_slider_template)
        slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -12)
        slider:SetHook("OnValueChanged", function(_, _, value)
            setValue(value)
        end)

        registerRefresher(function()
            slider:SetValue(getValue())
            local enabled = enabledFn == nil or enabledFn()
            if slider.Enable then
                if enabled then
                    slider:Enable()
                else
                    slider:Disable()
                end
            end
            if label.SetAlpha then
                label:SetAlpha(enabled and 1 or 0.45)
            end
        end)

        return y - 34
    end

    local function makeDropdown(x, y, width, labelText, options, getValue, setValue)
        local row = CreateFrame("Frame", nil, content)
        row:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        row:SetSize(width, 44)

        local label = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyRRTFont(label, 10)
        label:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
        label:SetText(labelText)

        local dd = DF:CreateDropDown(row, function()
            return BuildDropdownValues(options, function(value)
                setValue(value)
            end)
        end, nil, math.max(120, width - 10))
        dd:SetTemplate(options_dropdown_template)
        dd:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -16)

        registerRefresher(function()
            dd:Refresh()
            dd:Select(getValue())
        end)

        return y - 48
    end

    local margin = 14
    local columnWidth = math.max(220, content:GetWidth() - (margin * 2))
    local y = -10

    y = makeHeader(margin, y, "Display Behavior")
    y = makeSwitch(margin, y, columnWidth, "Show only in group/raid",
        function() return db.showOnlyInGroup ~= false end,
        function(value)
            db.showOnlyInGroup = value
            triggerDisplayRefresh()
        end)
    y = makeSwitch(margin, y, columnWidth, "Hide while resting",
        function() return db.hideWhileResting == true end,
        function(value)
            db.hideWhileResting = value
            triggerDisplayRefresh()
        end)
    y = makeSwitch(margin, y, columnWidth, "Show only on ready check",
        function() return db.showOnlyOnReadyCheck == true end,
        function(value)
            db.showOnlyOnReadyCheck = value
            triggerDisplayRefresh()
            if container.Refresh then
                container:Refresh()
            end
        end)
    y = makeSlider(margin + 24, y, columnWidth - 24, "Ready check duration (sec)", 10, 30, 1,
        function() return db.readyCheckDuration or 15 end,
        function(value)
            db.readyCheckDuration = value
        end,
        function()
            return db.showOnlyOnReadyCheck == true
        end)
    y = makeDropdown(margin, y, columnWidth, "Buff tracking mode", TRACKING_MODES,
        function() return db.buffTrackingMode or "all" end,
        function(value)
            db.buffTrackingMode = value
            triggerDisplayRefresh()
        end)
    y = makeSwitch(margin, y, columnWidth, "Show login messages",
        function() return db.showLoginMessages ~= false end,
        function(value)
            db.showLoginMessages = value
        end)

    y = y - 8
    y = makeHeader(margin, y, "Pet Behavior")
    y = makeSwitch(margin, y, columnWidth, "Hide pet reminder while mounted",
        function() return db.hidePetWhileMounted ~= false end,
        function(value)
            db.hidePetWhileMounted = value
            triggerDisplayRefresh()
        end)
    y = makeSwitch(margin, y, columnWidth, "Pet passive only in combat",
        function() return db.petPassiveOnlyInCombat == true end,
        function(value)
            db.petPassiveOnlyInCombat = value
            triggerDisplayRefresh()
        end)

    y = y - 10
    y = makeHeader(margin, y, "Runtime")

    local runtimeDisplay = RRT.BuffReminders and RRT.BuffReminders.Display
    local runtimeRow = CreateFrame("Frame", nil, content)
    runtimeRow:SetPoint("TOPLEFT", content, "TOPLEFT", margin, y)
    runtimeRow:SetSize(columnWidth, 24)

    local lockBtn = DF:CreateButton(runtimeRow, function(self)
        if runtimeDisplay and runtimeDisplay.ToggleLock then
            runtimeDisplay.ToggleLock()
            local current = (RRTDB.BuffReminders and RRTDB.BuffReminders.locked) ~= false
            if self and self.text and self.text.SetText then
                self.text:SetText(current and "Unlock" or "Lock")
            end
        end
    end, 90, 22, "Unlock")
    lockBtn:SetTemplate(options_button_template)
    lockBtn:SetPoint("LEFT", runtimeRow, "LEFT", 0, 0)

    local testBtn = DF:CreateButton(runtimeRow, function(self)
        if runtimeDisplay and runtimeDisplay.ToggleTestMode then
            local isOn = runtimeDisplay.ToggleTestMode()
            if self and self.text and self.text.SetText then
                self.text:SetText(isOn and "Stop Test" or "Test")
            end
        end
    end, 90, 22, "Test")
    testBtn:SetTemplate(options_button_template)
    testBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)

    registerRefresher(function()
        db = EnsureDB()
        local hasRuntime = runtimeDisplay and runtimeDisplay.ToggleLock and runtimeDisplay.ToggleTestMode

        if lockBtn.SetEnabled then
            lockBtn:SetEnabled(hasRuntime and true or false)
        elseif hasRuntime then
            lockBtn:Enable()
        else
            lockBtn:Disable()
        end

        if testBtn.SetEnabled then
            testBtn:SetEnabled(hasRuntime and true or false)
        elseif hasRuntime then
            testBtn:Enable()
        else
            testBtn:Disable()
        end

        if lockBtn.text and lockBtn.text.SetText then
            local locked = (db.locked ~= false)
            lockBtn.text:SetText(locked and "Unlock" or "Lock")
        end

        if testBtn.text and testBtn.text.SetText then
            local isOn = runtimeDisplay and runtimeDisplay.IsTestMode and runtimeDisplay.IsTestMode()
            testBtn.text:SetText(isOn and "Stop Test" or "Test")
        end
    end)

    local function refreshAll()
        db = EnsureDB()
        for _, fn in ipairs(refreshers) do
            fn()
        end
        content:SetHeight(math.max(700, math.abs(y) + 120))
    end

    container.Refresh = refreshAll
    container:Refresh()
    parent.SettingsView = container
    return container
end

RRT.UI.BuffReminders.Settings = {
    Build = BuildSettingsTab,
}
