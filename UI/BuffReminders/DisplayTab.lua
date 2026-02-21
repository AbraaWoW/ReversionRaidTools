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

local CATEGORY_ORDER = { "raid", "presence", "targeted", "self", "pet", "consumable", "custom" }
local CATEGORY_LABELS = {
    raid = "Raid Buffs",
    presence = "Presence Buffs",
    targeted = "Targeted Buffs",
    self = "Self Buffs",
    pet = "Pet Reminders",
    consumable = "Consumables",
    custom = "Custom Buffs",
}

local DEFAULTS = {
    iconSize = 64,
    textSize = 20,
    iconAlpha = 1,
    textAlpha = 1,
    textColor = { 1, 1, 1 },
    spacing = 0.2,
    iconZoom = 8,
    borderSize = 2,
    growDirection = "CENTER",
    showExpirationGlow = true,
    glowWhenMissing = true,
    expirationThreshold = 15,
    glowType = 1,
    glowColor = { 1, 0.82, 0, 1 },
    useCustomGlowColor = false,
    glowSize = 2,
    showConsumablesWithoutItems = false,
    consumableDisplayMode = "sub_icons",
    petDisplayMode = "generic",
}

local CATEGORY_DEFAULTS = {
    raid = {
        split = false,
        clickable = true,
        clickableHighlight = true,
        priority = 1,
        useCustomAppearance = false,
        showText = true,
        showBuffReminder = true,
        buffTextSize = 14,
    },
    presence = { split = false, clickable = false, clickableHighlight = true, priority = 2, useCustomAppearance = false, showText = true },
    targeted = { split = false, clickable = false, clickableHighlight = true, priority = 3, useCustomAppearance = false, showText = true },
    self = { split = false, clickable = true, clickableHighlight = true, priority = 4, useCustomAppearance = false, showText = true },
    pet = { split = false, clickable = true, clickableHighlight = true, priority = 5, useCustomAppearance = false, showText = true },
    consumable = {
        split = false,
        clickable = true,
        clickableHighlight = true,
        priority = 6,
        useCustomAppearance = false,
        showText = true,
        subIconSide = "BOTTOM",
    },
    custom = { split = false, clickable = false, clickableHighlight = true, priority = 7, useCustomAppearance = false, showText = true },
}

local GROW_DIRECTIONS = {
    { value = "LEFT", label = "Left" },
    { value = "CENTER", label = "Center" },
    { value = "RIGHT", label = "Right" },
    { value = "UP", label = "Up" },
    { value = "DOWN", label = "Down" },
}

local GLOW_TYPES = {
    { value = 1, label = "Pixel" },
    { value = 2, label = "AutoCast" },
    { value = 3, label = "Button Border" },
    { value = 4, label = "Proc Ring" },
}

local CONSUMABLE_MODES = {
    { value = "icon_only", label = "Icon Only" },
    { value = "sub_icons", label = "Sub Icons" },
    { value = "expanded", label = "Expanded" },
}

local PET_MODES = {
    { value = "generic", label = "Generic" },
    { value = "expanded", label = "Expanded" },
}

local SUB_ICON_SIDES = {
    { value = "TOP", label = "Top" },
    { value = "BOTTOM", label = "Bottom" },
    { value = "LEFT", label = "Left" },
    { value = "RIGHT", label = "Right" },
}

local function DeepCopy(value)
    if type(value) ~= "table" then
        return value
    end
    local out = {}
    for k, v in pairs(value) do
        out[k] = DeepCopy(v)
    end
    return out
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
        table.insert(values, {
            label = opt.label,
            value = opt.value,
            onclick = function(_, _, value)
                if onSelect then
                    onSelect(value)
                end
            end,
        })
    end
    return values
end

local function EnsureDB()
    RRTDB.BuffReminders = RRTDB.BuffReminders or {}
    local db = RRTDB.BuffReminders
    db.enabledBuffs = db.enabledBuffs or {}
    db.customBuffs = db.customBuffs or {}
    db.defaults = db.defaults or {}
    db.categorySettings = db.categorySettings or {}

    for key, value in pairs(DEFAULTS) do
        if db.defaults[key] == nil then
            db.defaults[key] = DeepCopy(value)
        end
    end

    for _, category in ipairs(CATEGORY_ORDER) do
        db.categorySettings[category] = db.categorySettings[category] or {}
        local catDefaults = CATEGORY_DEFAULTS[category] or {}
        for key, value in pairs(catDefaults) do
            if db.categorySettings[category][key] == nil then
                db.categorySettings[category][key] = DeepCopy(value)
            end
        end
    end

    return db
end

local function BuildDisplayTab(parent)
    local db = EnsureDB()

    if parent.DisplayView then
        parent.DisplayView:Show()
        if parent.DisplayView.Refresh then
            parent.DisplayView:Refresh()
        end
        return parent.DisplayView
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
    content:SetSize(math.max(200, container:GetWidth() - 30), 1200)
    scroll:SetScrollChild(content)

    container:SetScript("OnSizeChanged", function(_, width)
        content:SetWidth(math.max(200, width - 30))
    end)

    local refreshers = {}
    local selectedCategory = "raid"

    local function registerRefresher(fn)
        table.insert(refreshers, fn)
    end

    local function makeHeader(x, y, text)
        local header = content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyRRTFont(header, 11)
        header:SetPoint("TOPLEFT", content, "TOPLEFT", x, y)
        header:SetText("|cffffcc00" .. text .. "|r")
        return y - 22
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

    local function makeSlider(x, y, width, labelText, min, max, step, getValue, setValue)
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
    local gap = 16
    local totalWidth = content:GetWidth() - (margin * 2)
    local colWidth = math.floor((totalWidth - (gap * 2)) / 3)

    local col1x = margin
    local col2x = margin + colWidth + gap
    local col3x = col2x + colWidth + gap

    local col1y = -10
    local col2y = -10
    local col3y = -10

    col1y = makeHeader(col1x, col1y, "Global Appearance")
    col1y = makeSlider(col1x, col1y, colWidth, "Icon Size", 24, 96, 1,
        function() return db.defaults.iconSize or DEFAULTS.iconSize end,
        function(value) db.defaults.iconSize = value end)
    col1y = makeSlider(col1x, col1y, colWidth, "Text Size", 8, 40, 1,
        function() return db.defaults.textSize or DEFAULTS.textSize end,
        function(value) db.defaults.textSize = value end)
    col1y = makeSlider(col1x, col1y, colWidth, "Icon Zoom (%)", 0, 30, 1,
        function() return db.defaults.iconZoom or DEFAULTS.iconZoom end,
        function(value) db.defaults.iconZoom = value end)
    col1y = makeSlider(col1x, col1y, colWidth, "Border Size", 0, 8, 1,
        function() return db.defaults.borderSize or DEFAULTS.borderSize end,
        function(value) db.defaults.borderSize = value end)
    col1y = makeSlider(col1x, col1y, colWidth, "Icon Alpha (%)", 10, 100, 1,
        function() return math.floor((db.defaults.iconAlpha or DEFAULTS.iconAlpha) * 100 + 0.5) end,
        function(value) db.defaults.iconAlpha = value / 100 end)
    col1y = makeSlider(col1x, col1y, colWidth, "Text Alpha (%)", 10, 100, 1,
        function() return math.floor((db.defaults.textAlpha or DEFAULTS.textAlpha) * 100 + 0.5) end,
        function(value) db.defaults.textAlpha = value / 100 end)
    col1y = makeSlider(col1x, col1y, colWidth, "Spacing (%)", 0, 100, 1,
        function() return math.floor((db.defaults.spacing or DEFAULTS.spacing) * 100 + 0.5) end,
        function(value) db.defaults.spacing = value / 100 end)
    col1y = makeDropdown(col1x, col1y, colWidth, "Grow Direction", GROW_DIRECTIONS,
        function() return db.defaults.growDirection or DEFAULTS.growDirection end,
        function(value) db.defaults.growDirection = value end)

    col2y = makeHeader(col2x, col2y, "Expiration Glow")
    col2y = makeSwitch(col2x, col2y, colWidth, "Show Expiration Glow",
        function() return db.defaults.showExpirationGlow ~= false end,
        function(value) db.defaults.showExpirationGlow = value end)
    col2y = makeSwitch(col2x, col2y, colWidth, "Glow When Missing",
        function() return db.defaults.glowWhenMissing ~= false end,
        function(value) db.defaults.glowWhenMissing = value end)
    col2y = makeSlider(col2x, col2y, colWidth, "Threshold (minutes)", 1, 60, 1,
        function() return db.defaults.expirationThreshold or DEFAULTS.expirationThreshold end,
        function(value) db.defaults.expirationThreshold = value end)
    col2y = makeDropdown(col2x, col2y, colWidth, "Glow Type", GLOW_TYPES,
        function() return db.defaults.glowType or DEFAULTS.glowType end,
        function(value) db.defaults.glowType = value end)
    col2y = makeSlider(col2x, col2y, colWidth, "Glow Size", 1, 10, 1,
        function() return db.defaults.glowSize or DEFAULTS.glowSize end,
        function(value) db.defaults.glowSize = value end)

    col3y = makeHeader(col3x, col3y, "Modes & Behavior")
    col3y = makeSwitch(col3x, col3y, colWidth, "Show consumables even without items",
        function() return db.defaults.showConsumablesWithoutItems == true end,
        function(value) db.defaults.showConsumablesWithoutItems = value end)
    col3y = makeDropdown(col3x, col3y, colWidth, "Consumable Display Mode", CONSUMABLE_MODES,
        function() return db.defaults.consumableDisplayMode or DEFAULTS.consumableDisplayMode end,
        function(value) db.defaults.consumableDisplayMode = value end)
    col3y = makeDropdown(col3x, col3y, colWidth, "Pet Display Mode", PET_MODES,
        function() return db.defaults.petDisplayMode or DEFAULTS.petDisplayMode end,
        function(value) db.defaults.petDisplayMode = value end)

    local nextY = math.min(col1y, col2y, col3y) - 18

    local perCategoryHeaderY = nextY
    nextY = makeHeader(margin, perCategoryHeaderY, "Per-Category Customization")

    nextY = makeDropdown(margin, nextY, 260, "Category", {
        { value = "raid", label = "Raid Buffs" },
        { value = "presence", label = "Presence Buffs" },
        { value = "targeted", label = "Targeted Buffs" },
        { value = "self", label = "Self Buffs" },
        { value = "pet", label = "Pet Reminders" },
        { value = "consumable", label = "Consumables" },
        { value = "custom", label = "Custom Buffs" },
    },
        function() return selectedCategory end,
        function(value)
            selectedCategory = value
            if container.Refresh then
                container:Refresh()
            end
        end)

    local twoColWidth = math.floor((totalWidth - gap) / 2)
    local catCol1x = margin
    local catCol2x = margin + twoColWidth + gap
    local catCol1y = nextY
    local catCol2y = nextY

    local function GetCatSettings()
        db.categorySettings[selectedCategory] = db.categorySettings[selectedCategory] or {}
        return db.categorySettings[selectedCategory]
    end

    makeDropdown(catCol2x, perCategoryHeaderY, twoColWidth, "Category Grow Direction", GROW_DIRECTIONS,
        function()
            local cs = GetCatSettings()
            return cs.growDirection or db.defaults.growDirection or DEFAULTS.growDirection
        end,
        function(value) GetCatSettings().growDirection = value end)

    catCol1y = makeSwitch(catCol1x, catCol1y, twoColWidth, "Use Custom Appearance",
        function() return GetCatSettings().useCustomAppearance == true end,
        function(value) GetCatSettings().useCustomAppearance = value end)

    catCol1y = makeSwitch(catCol1x, catCol1y, twoColWidth, "Split Into Separate Frame",
        function() return GetCatSettings().split == true end,
        function(value) GetCatSettings().split = value end)

    catCol1y = makeSwitch(catCol1x, catCol1y, twoColWidth, "Clickable Icons",
        function() return GetCatSettings().clickable == true end,
        function(value) GetCatSettings().clickable = value end)

    catCol1y = makeSwitch(catCol1x, catCol1y, twoColWidth, "Clickable Highlight",
        function() return GetCatSettings().clickableHighlight ~= false end,
        function(value) GetCatSettings().clickableHighlight = value end)

    catCol1y = makeSwitch(catCol1x, catCol1y, twoColWidth, "Show Text Overlay",
        function() return GetCatSettings().showText ~= false end,
        function(value) GetCatSettings().showText = value end)

    catCol1y = makeSlider(catCol1x, catCol1y, twoColWidth, "Priority", 1, 20, 1,
        function()
            local cs = GetCatSettings()
            local cd = CATEGORY_DEFAULTS[selectedCategory] or {}
            return cs.priority or cd.priority or 1
        end,
        function(value) GetCatSettings().priority = value end)


    catCol2y = makeSlider(catCol2x, catCol2y, twoColWidth, "Category Icon Size", 24, 96, 1,
        function()
            local cs = GetCatSettings()
            return cs.iconSize or db.defaults.iconSize or DEFAULTS.iconSize
        end,
        function(value) GetCatSettings().iconSize = value end)

    catCol2y = makeSlider(catCol2x, catCol2y, twoColWidth, "Category Spacing (%)", 0, 100, 1,
        function()
            local cs = GetCatSettings()
            local spacing = cs.spacing
            if spacing == nil then
                spacing = db.defaults.spacing or DEFAULTS.spacing
            end
            return math.floor(spacing * 100 + 0.5)
        end,
        function(value) GetCatSettings().spacing = value / 100 end)

    catCol2y = makeDropdown(catCol2x, catCol2y, twoColWidth, "Consumable Sub-Icon Side", SUB_ICON_SIDES,
        function()
            local cs = GetCatSettings()
            return cs.subIconSide or "BOTTOM"
        end,
        function(value) GetCatSettings().subIconSide = value end)

    catCol2y = makeSwitch(catCol2x, catCol2y, twoColWidth, "Raid BUFF! Text (raid only)",
        function()
            local cs = GetCatSettings()
            if selectedCategory ~= "raid" then
                return false
            end
            return cs.showBuffReminder ~= false
        end,
        function(value)
            if selectedCategory == "raid" then
                GetCatSettings().showBuffReminder = value
            end
        end)

    catCol2y = makeSlider(catCol2x, catCol2y, twoColWidth, "Raid BUFF! Text Size", 8, 30, 1,
        function()
            local cs = GetCatSettings()
            return cs.buffTextSize or 14
        end,
        function(value)
            if selectedCategory == "raid" then
                GetCatSettings().buffTextSize = value
            end
        end)

    local resetY = math.min(catCol1y, catCol2y) - 8

    local resetBtn = DF:CreateButton(content, function()
        db.categorySettings[selectedCategory] = DeepCopy(CATEGORY_DEFAULTS[selectedCategory] or {})
        if container.Refresh then
            container:Refresh()
        end
    end, 190, 22, "Reset Selected Category")
    resetBtn:SetTemplate(options_button_template)
    resetBtn:SetPoint("TOPLEFT", content, "TOPLEFT", margin, resetY)

    local runtimeDisplay = RRT.BuffReminders and RRT.BuffReminders.Display

    local unlockBtn = DF:CreateButton(content, function()
        if runtimeDisplay and runtimeDisplay.ToggleLock then
            runtimeDisplay.ToggleLock()
        end
    end, 90, 22, "Unlock")
    unlockBtn:SetTemplate(options_button_template)
    unlockBtn:SetPoint("LEFT", resetBtn, "RIGHT", 8, 0)

    local testBtn = DF:CreateButton(content, function(self)
        if runtimeDisplay and runtimeDisplay.ToggleTestMode then
            local isOn = runtimeDisplay.ToggleTestMode()
            if self and self.text and self.text.SetText then
                self.text:SetText(isOn and "Stop Test" or "Test")
            end
        end
    end, 90, 22, "Test")
    testBtn:SetTemplate(options_button_template)
    testBtn:SetPoint("LEFT", unlockBtn, "RIGHT", 8, 0)

    registerRefresher(function()
        local hasRuntime = runtimeDisplay and runtimeDisplay.ToggleLock and runtimeDisplay.ToggleTestMode

        if unlockBtn then
            if unlockBtn.SetEnabled then
                unlockBtn:SetEnabled(hasRuntime and true or false)
            elseif hasRuntime then
                unlockBtn:Enable()
            else
                unlockBtn:Disable()
            end
        end

        if testBtn then
            if testBtn.SetEnabled then
                testBtn:SetEnabled(hasRuntime and true or false)
            elseif hasRuntime then
                testBtn:Enable()
            else
                testBtn:Disable()
            end
        end

        if runtimeDisplay and runtimeDisplay.IsTestMode and testBtn and testBtn.text and testBtn.text.SetText then
            testBtn.text:SetText(runtimeDisplay.IsTestMode() and "Stop Test" or "Test")
        elseif testBtn and testBtn.text and testBtn.text.SetText then
            testBtn.text:SetText("Test")
        end
    end)

    local function refreshAll()
        EnsureDB()
        for _, fn in ipairs(refreshers) do
            fn()
        end
        local finalY = resetY - 36
        content:SetHeight(math.max(1200, math.abs(finalY) + 40))
    end

    container.Refresh = refreshAll
    container:Refresh()
    parent.DisplayView = container
    return container
end

RRT.UI.BuffReminders.Display = {
    Build = BuildDisplayTab,
}
