local _, RRT = ...
local DF = _G["DetailsFramework"]

-- Templates resolved lazily (Core.lua may not be loaded yet at file scope)
local options_switch_template
local options_button_template
local options_dropdown_template
local options_slider_template
local apply_scrollbar_style

local function EnsureTemplates()
    if options_switch_template then return end
    local Core              = RRT.UI.Core
    options_switch_template   = Core.options_switch_template
    options_button_template   = Core.options_button_template
    options_dropdown_template = Core.options_dropdown_template
    options_slider_template   = Core.options_slider_template
    apply_scrollbar_style     = Core.apply_scrollbar_style
end

-------------------------------------------------------------------------------
-- Constants  (matching SetupManager / Tools tab visual style)
-------------------------------------------------------------------------------

local FONT           = "Fonts\\FRIZQT__.TTF"
local FRAME_WIDTH    = 820
local PADDING        = 12
local ROW_HEIGHT     = 26
local SIDEBAR_WIDTH  = 160
local COLUMN_GAP     = 10

local COLOR_ACCENT   = { 0.30, 0.72, 1.00 }
local COLOR_LABEL    = { 0.85, 0.85, 0.85 }
local COLOR_MUTED    = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.10, 0.10, 0.10, 1.0 }
local COLOR_BTN_ACT  = { 0.20, 0.20, 0.20, 1.0 }
local COLOR_BTN_HOV  = { 0.16, 0.16, 0.16, 1.0 }
local COLOR_SECTION  = { 0.08, 0.08, 0.08, 0.70 }
local COLOR_BORDER   = { 0.20, 0.20, 0.20, 0.80 }

local LAYOUT_OPTIONS     = { "bar", "icon" }
local LAYOUT_LABELS      = { bar = "Bar", icon = "Icon" }
local GROW_DIR_OPTIONS   = { "down", "up" }
local GROW_DIR_LABELS    = { down = "Down", up = "Up" }
local SORT_MODE_OPTIONS  = { "remaining", "basecd" }
local SORT_MODE_LABELS   = { remaining = "Remaining", basecd = "Base CD" }
local GROUP_MODE_OPTIONS = { "any", "party", "raid" }
local GROUP_MODE_LABELS  = { any = "Any Group", party = "Party Only (5)", raid = "Raid Only" }
local OUTLINE_OPTIONS    = { "", "OUTLINE", "THICKOUTLINE" }
local OUTLINE_LABELS     = { [""] = "None", OUTLINE = "Outline", THICKOUTLINE = "Thick Outline" }

local CLASS_ORDER = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER",
    "MAGE", "MONK", "PALADIN", "PRIEST", "ROGUE",
    "SHAMAN", "WARLOCK", "WARRIOR",
}
local CLASS_DISPLAY_NAMES = {
    WARRIOR="Warrior", PALADIN="Paladin", HUNTER="Hunter", ROGUE="Rogue",
    PRIEST="Priest", DEATHKNIGHT="Death Knight", SHAMAN="Shaman", MAGE="Mage",
    WARLOCK="Warlock", MONK="Monk", DRUID="Druid", DEMONHUNTER="Demon Hunter",
    EVOKER="Evoker",
}

-------------------------------------------------------------------------------
-- Font helper (matches Buff Reminders / SettingsTab style)
-------------------------------------------------------------------------------

local function ApplyRRTFont(fs, size)
    if not fs then return end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then fs:SetFont(fetched, size or 10, "OUTLINE") end
end

-------------------------------------------------------------------------------
-- Widget helpers
-------------------------------------------------------------------------------

-- DF-styled navigation button (matches SetupManager / BuffReminders nav style)
local function MakeNavButton(parent, x, y, w, h, text, onClick, Track)
    local btn = DF:CreateButton(parent, onClick, w, h or ROW_HEIGHT, text)
    local btnFrame = btn.widget or btn
    btn:SetTemplate(options_button_template)
    if btn.SetPoint then
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    elseif btnFrame and btnFrame.SetPoint then
        btnFrame:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end
    if btnFrame and btnFrame.SetBackdrop then
        btnFrame:SetBackdrop({ bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=1 })
        btnFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.75)
        btnFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
    end
    btn._active = false
    btn._btnFrame = btnFrame
    local function ApplyState(active)
        btn._active = active
        if btnFrame and btnFrame.SetBackdropColor then
            if active then btnFrame:SetBackdropColor(0.16, 0.16, 0.16, 0.95)
            else btnFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.75) end
        end
        local r, g, b = active and 1 or 1, active and 0.82 or 1, active and 0 or 1
        if btn.SetTextColor then btn:SetTextColor(r, g, b, 1)
        elseif btn.text and btn.text.SetTextColor then btn.text:SetTextColor(r, g, b, 1)
        elseif btn.widget and btn.widget.text then btn.widget.text:SetTextColor(r, g, b, 1) end
    end
    if btnFrame and btnFrame.SetScript then
        btnFrame:SetScript("OnEnter", function(self)
            if not btn._active then self:SetBackdropColor(0.14, 0.14, 0.14, 0.95) end
        end)
        btnFrame:SetScript("OnLeave", function(self)
            if not btn._active then self:SetBackdropColor(0.08, 0.08, 0.08, 0.75) end
        end)
    end
    btn._ApplyState = ApplyState
    if Track then Track(btn) end
    return btn
end

local function SetTabActive(btn, active)
    if btn._ApplyState then
        btn._ApplyState(active)
    end
end

-- Action button using DF template (matches BuildMenu / Raids tab style)
local function MakeButton(parent, x, y, w, h, text, onClick, Track)
    local btn = DF:CreateButton(parent, onClick, w, h or ROW_HEIGHT, text)
    btn:SetTemplate(options_button_template)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    if Track then Track(btn) end
    return btn
end

-- Section header (gold, RRT font — matches Buff Reminders style)
local function MakeHeader(parent, x, y, text, Track)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyRRTFont(fs, 11)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText("|cffffcc00" .. text .. "|r")
    if Track then Track(fs) end
    return y - 20
end

local function MakeLabel(parent, x, y, text, Track)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(fs, 10)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    if Track then Track(fs) end
    return fs
end

-- Toggle row (DF switch + RRT font label — matches Buff Reminders style)
local function MakeSwitch(parent, x, y, width, labelText, getValue, setValue, Track)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width, 22)
    if Track then Track(row) end

    local sw = DF:CreateSwitch(row, function(_, _, value)
        setValue(value and true or false)
    end, getValue() and true or false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
    sw:SetAsCheckBox()
    sw:SetPoint("LEFT", row, "LEFT", 0, 0)
    if sw.Text then sw.Text:SetText(""); sw.Text:Hide() end

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(lbl, 10)
    lbl:SetPoint("LEFT", row, "LEFT", 24, 0)
    lbl:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    lbl:SetJustifyH("LEFT")
    lbl:SetText(labelText)

    return y - 26, sw
end

-- Slider row (DF slider + RRT font label)
local function MakeSlider(parent, x, y, width, labelText, minVal, maxVal, step, getValue, setValue, Track)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width, 34)
    if Track then Track(row) end

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(lbl, 10)
    lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    lbl:SetText(labelText)

    local slider = DF:CreateSlider(row, math.max(120, width - 8), 16, minVal, maxVal, step, minVal, false)
    slider:SetTemplate(options_slider_template)
    slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    slider:SetValue(getValue())
    slider:SetHook("OnValueChanged", function(_, _, value) setValue(value) end)

    return y - 38, slider
end

-- Dropdown row (DF dropdown + RRT font label)
local function MakeDropdown(parent, x, y, width, labelText, options, labels, getValue, setValue, Track)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    row:SetSize(width, 44)
    if Track then Track(row) end

    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(lbl, 10)
    lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    lbl:SetText(labelText)

    local function BuildValues()
        local values = {}
        for _, opt in ipairs(options) do
            table.insert(values, {
                label   = labels[opt] or opt,
                value   = opt,
                onclick = function(_, _, v) setValue(v) end,
            })
        end
        return values
    end

    local dd = DF:CreateDropDown(row, BuildValues, nil, math.max(120, width - 10))
    dd:SetTemplate(options_dropdown_template)
    dd:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -16)
    dd:Select(getValue())

    return y - 48, dd
end

local function MakeScrollContent(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0); scroll:SetPoint("BOTTOMRIGHT", -20, 0)
    apply_scrollbar_style(scroll)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur  = self:GetVerticalScroll()
        local ch   = self:GetScrollChild(); if not ch then return end
        local maxS = math.max(0, ch:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxS)))
    end)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(FRAME_WIDTH); content:SetHeight(800)
    scroll:SetScrollChild(content)
    return scroll, content
end

local function SkinPanel(frame)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({ bgFile="Interface\\BUTTONS\\WHITE8X8", edgeFile="Interface\\BUTTONS\\WHITE8X8", edgeSize=1 })
    frame:SetBackdropColor(unpack(COLOR_SECTION))
    frame:SetBackdropBorderColor(unpack(COLOR_BORDER))
end

-------------------------------------------------------------------------------
-- Sub-builder: Settings tab
-------------------------------------------------------------------------------

local function BuildFrameSettings(ST, content, frameIndex, yOff, Track, Rebuild)
    local frameConfig = ST:GetFrameConfig(frameIndex)
    if not frameConfig then return yOff end

    local function DestroyAndRefresh()
        local d = ST.displayFrames and ST.displayFrames[frameIndex]
        if d then if d.frame then d.frame:Hide(); d.frame:SetParent(nil) end; ST.displayFrames[frameIndex] = nil end
        ST:RefreshDisplay()
    end

    yOff = MakeHeader(content, PADDING + 4, yOff, "Frame Settings", Track)

    -- Name input
    MakeLabel(content, PADDING + 4, yOff, "Frame Name", Track)
    yOff = yOff - 16
    local editBox = DF:CreateTextEntry(content, function() end, 200, 20)
    editBox:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING + 4, yOff)
    editBox:SetTemplate(options_dropdown_template)
    editBox:SetText(frameConfig.name or "")
    editBox:SetHook("OnEnterPressed", function(self)
        self:ClearFocus()
        frameConfig.name = self:GetText()
        DestroyAndRefresh()
    end)
    editBox:SetHook("OnEscapePressed", function(self)
        self:ClearFocus()
    end)
    Track(editBox); yOff = yOff - 30

    yOff, _ = MakeSwitch(content, PADDING + 4, yOff, 220, "Enable",
        function() return frameConfig.enabled end,
        function(v) frameConfig.enabled = v; ST:RefreshDisplay() end, Track)

    yOff, _ = MakeDropdown(content, PADDING + 4, yOff, 220, "Sort Order",
        SORT_MODE_OPTIONS, SORT_MODE_LABELS,
        function() return frameConfig.sortMode or "remaining" end,
        function(v) frameConfig.sortMode = v; ST:RefreshDisplay() end, Track)

    yOff, _ = MakeSwitch(content, PADDING + 4, yOff, 220, "Show Self",
        function() return frameConfig.showSelf end,
        function(v) frameConfig.showSelf = v; ST:RefreshDisplay() end, Track)

    yOff, _ = MakeSwitch(content, PADDING + 4, yOff, 220, "Self On Top",
        function() return frameConfig.selfOnTop end,
        function(v) frameConfig.selfOnTop = v; ST:RefreshDisplay() end, Track)

    local layout = frameConfig.layout or "bar"
    if layout == "bar" then
        yOff, _ = MakeSlider(content, PADDING + 4, yOff, 220, "Bar Width", 120, 400, 1,
            function() return frameConfig.barWidth or 220 end,
            function(v) frameConfig.barWidth = v; ST:RefreshBarLayout(frameIndex); ST:RefreshDisplay() end, Track)
        yOff, _ = MakeSlider(content, PADDING + 4, yOff, 220, "Bar Height", 16, 40, 1,
            function() return frameConfig.barHeight or 28 end,
            function(v) frameConfig.barHeight = v; ST:RefreshBarLayout(frameIndex); ST:RefreshDisplay() end, Track)
        yOff, _ = MakeDropdown(content, PADDING + 4, yOff, 220, "Grow Direction",
            GROW_DIR_OPTIONS, GROW_DIR_LABELS,
            function() return frameConfig.growUp and "up" or "down" end,
            function(v) frameConfig.growUp = (v == "up"); DestroyAndRefresh() end, Track)
    elseif layout == "icon" then
        yOff, _ = MakeSlider(content, PADDING + 4, yOff, 220, "Icon Size", 16, 48, 1,
            function() return frameConfig.iconSize or 28 end,
            function(v) frameConfig.iconSize = v; ST:RefreshIconLayout(frameIndex) end, Track)
        yOff, _ = MakeSwitch(content, PADDING + 4, yOff, 220, "Show Names",
            function() return frameConfig.showNames end,
            function(v) frameConfig.showNames = v; ST:RefreshDisplay() end, Track)
    end

    yOff, _ = MakeSwitch(content, PADDING + 4, yOff, 220, "Lock Position",
        function() return frameConfig.locked end,
        function(v)
            frameConfig.locked = v
            local d = ST.displayFrames and ST.displayFrames[frameIndex]
            if d and d.title then if v then d.title:Hide() else d.title:Show() end end
        end, Track)

    yOff = yOff - 4
    MakeButton(content, PADDING + 4, yOff, 180, ROW_HEIGHT, "Reset Frame Position", function()
        ST:ResetPosition(frameIndex); ST:Print((frameConfig.name or "Frame") .. " position reset.")
    end, Track)
    yOff = yOff - ROW_HEIGHT - 8

    return yOff
end

-------------------------------------------------------------------------------
-- Sub-builder: Spells tab
-------------------------------------------------------------------------------

local function BuildFrameSpells(ST, content, frameIndex, yOff, Track, Rebuild, spellFilter, toggleFilter)
    local frameConfig = ST:GetFrameConfig(frameIndex)
    if not frameConfig then return yOff end
    local selectedSpells = frameConfig.spells
    local MAIN_WIDTH = FRAME_WIDTH - SIDEBAR_WIDTH - COLUMN_GAP - PADDING * 2

    local spellsByClass = {}
    if ST.spellDB then
        for id, spell in pairs(ST.spellDB) do
            if spell.category ~= "interrupt" and (not spellFilter or spell.category == spellFilter) then
                local cls = spell.class or "Custom"
                if not spellsByClass[cls] then spellsByClass[cls] = {} end
                table.insert(spellsByClass[cls], { id=id, category=spell.category, name=C_Spell.GetSpellName(id) or ("Spell "..id) })
            end
        end
    end
    local CAT_ORDER = { interrupt=1, defensive=2, cooldown=3, healer=4, mobility=5 }
    for _, spells in pairs(spellsByClass) do
        table.sort(spells, function(a, b)
            local ao, bo = CAT_ORDER[a.category] or 99, CAT_ORDER[b.category] or 99
            if ao ~= bo then return ao < bo end
            return (a.name or "") < (b.name or "")
        end)
    end

    -- Action + filter row
    MakeButton(content, PADDING + 4,  yOff, 90, ROW_HEIGHT, "Select All", function()
        if not ST.spellDB then return end
        for id, spell in pairs(ST.spellDB) do
            if (not spellFilter or spell.category == spellFilter) and spell.category ~= "interrupt" then
                selectedSpells[id] = true
            end
        end; ST:RefreshDisplay(); Rebuild()
    end, Track)
    MakeButton(content, PADDING + 98, yOff, 90, ROW_HEIGHT, "Deselect All", function()
        for id in pairs(selectedSpells) do
            if not spellFilter or (ST.spellDB and ST.spellDB[id] and ST.spellDB[id].category == spellFilter) then
                selectedSpells[id] = nil
            end
        end; ST:RefreshDisplay(); Rebuild()
    end, Track)

    local filterDefs = {
        { "All", nil }, { "Defensive", "defensive" }, { "Cooldown", "cooldown" },
        { "Healer", "healer" }, { "Mobility", "mobility" },
    }
    local fbx = PADDING + 196
    for _, fd in ipairs(filterDefs) do
        local label, cat = fd[1], fd[2]
        local isActive = (spellFilter == cat)
        local fb = MakeNavButton(content, fbx, yOff, 76, ROW_HEIGHT, label, function() toggleFilter(cat) end, Track)
        SetTabActive(fb, isActive)
        fbx = fbx + 80
    end
    yOff = yOff - ROW_HEIGHT - 10

    -- Add custom spell row
    do
        local CLASS_OPTS = { "WARRIOR","PALADIN","DEATHKNIGHT","DEMONHUNTER","DRUID","EVOKER","HUNTER","MAGE","MONK","PRIEST","ROGUE","SHAMAN","WARLOCK","CUSTOM" }
        local CLASS_LBLS = { WARRIOR="Warrior",PALADIN="Paladin",DEATHKNIGHT="Death Knight",DEMONHUNTER="Demon Hunter",DRUID="Druid",EVOKER="Evoker",HUNTER="Hunter",MAGE="Mage",MONK="Monk",PRIEST="Priest",ROGUE="Rogue",SHAMAN="Shaman",WARLOCK="Warlock",CUSTOM="Custom" }
        local CAT_OPTS   = { "cooldown","healer","defensive","mobility","custom" }
        local CAT_LBLS   = { cooldown="Cooldown",healer="Healer CD",defensive="Defensive",mobility="Mobility",custom="Custom" }
        local addClass, addCat, addCD = "CUSTOM", "cooldown", 0

        MakeLabel(content, PADDING + 4, yOff, "Add Spell ID:", Track)
        local spellInput = DF:CreateTextEntry(content, function() end, 80, 20)
        spellInput:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING + 90, yOff + 2)
        spellInput:SetTemplate(options_dropdown_template)
        if spellInput.SetNumeric then spellInput:SetNumeric(true) end
        if spellInput.SetMaxLetters then spellInput:SetMaxLetters(10) end
        Track(spellInput)

        local spellPrev = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyRRTFont(spellPrev, 10)
        spellPrev:SetPoint("TOPLEFT", content, "TOPLEFT", PADDING + 180, yOff)
        spellPrev:SetWidth(180); spellPrev:SetText(""); Track(spellPrev)

        spellInput:SetHook("OnTextChanged", function()
            local id = tonumber(spellInput:GetText())
            if not id then spellPrev:SetText(""); return end
            local name = C_Spell.GetSpellName(id)
            if name then spellPrev:SetTextColor(1, 0.82, 0, 1); spellPrev:SetText(name)
            else spellPrev:SetTextColor(1, 0.30, 0.30); spellPrev:SetText("Unknown spell") end
        end)
        yOff = yOff - ROW_HEIGHT

        local nx = PADDING + 4
        MakeLabel(content, nx, yOff, "Class", Track)
        local classDD = DF:CreateDropDown(content, function()
            local values = {}
            for _, opt in ipairs(CLASS_OPTS) do
                table.insert(values, { label=CLASS_LBLS[opt] or opt, value=opt, onclick=function(_, _, v) addClass = v end })
            end
            return values
        end, nil, 120)
        classDD:SetTemplate(options_dropdown_template)
        classDD:SetPoint("TOPLEFT", content, "TOPLEFT", nx, yOff - 14)
        classDD:Select(addClass); Track(classDD); nx = nx + 128

        MakeLabel(content, nx, yOff, "Category", Track)
        local catDD = DF:CreateDropDown(content, function()
            local values = {}
            for _, opt in ipairs(CAT_OPTS) do
                table.insert(values, { label=CAT_LBLS[opt] or opt, value=opt, onclick=function(_, _, v) addCat = v end })
            end
            return values
        end, nil, 110)
        catDD:SetTemplate(options_dropdown_template)
        catDD:SetPoint("TOPLEFT", content, "TOPLEFT", nx, yOff - 14)
        catDD:Select(addCat); Track(catDD); nx = nx + 118

        MakeLabel(content, nx, yOff, "CD (s)", Track)
        local cdInput = DF:CreateTextEntry(content, function() end, 50, ROW_HEIGHT - 2)
        cdInput:SetPoint("TOPLEFT", content, "TOPLEFT", nx, yOff - 14)
        cdInput:SetTemplate(options_dropdown_template)
        if cdInput.SetNumeric then cdInput:SetNumeric(true) end
        if cdInput.SetMaxLetters then cdInput:SetMaxLetters(5) end
        cdInput:SetText("0")
        cdInput:SetHook("OnTextChanged", function() addCD = tonumber(cdInput:GetText()) or 0 end)
        Track(cdInput); nx = nx + 58

        local function DoAdd()
            local id = tonumber(spellInput:GetText()); if not id then return end
            local name = C_Spell.GetSpellName(id)
            if not name then spellPrev:SetTextColor(1,0.3,0.3); spellPrev:SetText("Unknown spell"); return end
            if not ST.spellDB[id] then
                ST.spellDB[id] = { id=id, cd=addCD, duration=nil, charges=nil,
                    class=addClass=="CUSTOM" and "Custom" or addClass, specs=nil, category=addCat }
            end
            selectedSpells[id] = true; spellInput:SetText(""); cdInput:SetText("0"); spellPrev:SetText("")
            ST:RefreshDisplay(); Rebuild()
        end
        spellInput:SetHook("OnEnterPressed", DoAdd)
        MakeButton(content, nx, yOff - 14, 70, ROW_HEIGHT - 2, "+ Add", DoAdd, Track)
        yOff = yOff - ROW_HEIGHT * 2 - 10
    end

    -- Spell toggle (icon + checkbox + label)
    local function CreateSpellToggle(par, x, y, width, spellID, text, checked, onToggle)
        local row = CreateFrame("Frame", nil, par)
        row:SetPoint("TOPLEFT", x, y); row:SetSize(width - 20, 19); Track(row)

        local icon = row:CreateTexture(nil, "ARTWORK")
        icon:SetSize(14, 14); icon:SetPoint("LEFT", 0, 0)
        icon:SetTexture(ST._GetSpellTexture(spellID)); icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

        local sw = DF:CreateSwitch(row, function(_, _, value)
            checked = value and true or false
            if onToggle then onToggle(checked) end
        end, checked and true or false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
        sw:SetAsCheckBox()
        sw:SetPoint("LEFT", row, "LEFT", 18, 0)
        if sw.Text then sw.Text:SetText(""); sw.Text:Hide() end
        Track(sw)

        local lbl = row:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11)
        lbl:SetPoint("LEFT", row, "LEFT", 40, 0); lbl:SetPoint("RIGHT", 0, 0)
        lbl:SetTextColor(unpack(COLOR_LABEL)); lbl:SetJustifyH("LEFT"); lbl:SetWordWrap(false); lbl:SetText(text)
        -- Delete button
        local del = CreateFrame("Button", nil, par)
        del:SetPoint("TOPLEFT", x + width - 10, y + 4); del:SetSize(10, 10); Track(del)
        local dbg = del:CreateTexture(nil, "BACKGROUND")
        dbg:SetAllPoints()
        dbg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
        dbg:SetVertexColor(0.4, 0.1, 0.1, 1)

        local delTxt = del:CreateFontString(nil, "OVERLAY")
        delTxt:SetFont(FONT, 7, "OUTLINE")
        delTxt:SetPoint("CENTER", 0, 0)
        delTxt:SetTextColor(1, 0.6, 0.6, 1)
        delTxt:SetText("X")

        del:SetScript("OnEnter", function()
            dbg:SetVertexColor(0.6, 0.15, 0.15, 1)
            delTxt:SetTextColor(1, 1, 1, 1)
        end)
        del:SetScript("OnLeave", function()
            dbg:SetVertexColor(0.4, 0.1, 0.1, 1)
            delTxt:SetTextColor(1, 0.6, 0.6, 1)
        end)
        del:SetScript("OnClick", function() ST.spellDB[spellID]=nil; selectedSpells[spellID]=nil; ST:RefreshDisplay(); Rebuild() end)
    end

    -- Two-column class layout
    local classSections = {}
    for _, cls in ipairs(CLASS_ORDER) do
        local cs = spellsByClass[cls]
        if cs and #cs > 0 then table.insert(classSections, { cls=cls, spells=cs, height=18+(#cs*20)+10 }) end
    end
    local avail = MAIN_WIDTH - (PADDING+4)*2 + PADDING
    local colW = math.floor((avail - 10) / 2)
    local cols, colH = {}, {}
    for i = 1, 2 do cols[i] = {}; colH[i] = 0 end
    for _, s in ipairs(classSections) do
        local t = 1; for i = 2, 2 do if colH[i] < colH[t] then t = i end end
        table.insert(cols[t], s); colH[t] = colH[t] + s.height
    end
    local startY = yOff; local lowestY = yOff; local startX = PADDING + 4
    for col = 1, 2 do
        local cX = startX + (col-1)*(colW+10); local cY = startY
        for _, section in ipairs(cols[col]) do
            local r,g,b = ST:GetClassColor(section.cls)
            local cl = content:CreateFontString(nil,"OVERLAY"); cl:SetFont(FONT,12,"OUTLINE")
            cl:SetPoint("TOPLEFT",cX,cY); cl:SetTextColor(r,g,b)
            cl:SetText(CLASS_DISPLAY_NAMES[section.cls] or section.cls); Track(cl); cY = cY - 18
            for _, spell in ipairs(section.spells) do
                local spellID = spell.id; local chk = selectedSpells[spellID] or false
                local txt = spell.name.." |cFF888888["..spell.category.."]|r"
                CreateSpellToggle(content, cX+4, cY, colW-4, spellID, txt, chk, function(val)
                    if val then selectedSpells[spellID]=true else selectedSpells[spellID]=nil end; ST:RefreshDisplay()
                end); cY = cY - 20
            end; cY = cY - 10
        end; if cY < lowestY then lowestY = cY end
    end
    return lowestY - 4
end

-------------------------------------------------------------------------------
-- Sub-builder: Display tab
-------------------------------------------------------------------------------

local function BuildFrameDisplay(ST, content, frameIndex, yOff, Track, Rebuild)
    local frameConfig = ST:GetFrameConfig(frameIndex); if not frameConfig then return yOff end
    local function DAR()
        local d = ST.displayFrames and ST.displayFrames[frameIndex]
        if d then if d.frame then d.frame:Hide(); d.frame:SetParent(nil) end; ST.displayFrames[frameIndex]=nil end; ST:RefreshDisplay()
    end

    yOff = MakeHeader(content, PADDING + 4, yOff, "Display Settings", Track)

    yOff, _ = MakeDropdown(content, PADDING+4, yOff, 220, "Layout", LAYOUT_OPTIONS, LAYOUT_LABELS,
        function() return frameConfig.layout or "bar" end,
        function(v) if frameConfig.layout~=v then frameConfig.layout=v; DAR(); Rebuild() end end, Track)
    yOff, _ = MakeSlider(content, PADDING+4, yOff, 220, "Scale", 70, 180, 1,
        function() return math.floor((frameConfig.displayScale or 1)*100) end,
        function(v) frameConfig.displayScale=v/100
            if frameConfig.layout=="bar" then ST:RefreshBarLayout(frameIndex) else ST:RefreshIconLayout(frameIndex) end; ST:RefreshDisplay()
        end, Track)
    yOff, _ = MakeDropdown(content, PADDING+4, yOff, 220, "Font Outline", OUTLINE_OPTIONS, OUTLINE_LABELS,
        function() return frameConfig.fontOutline or "OUTLINE" end,
        function(v) frameConfig.fontOutline=v
            if frameConfig.layout=="bar" then ST:RefreshBarLayout(frameIndex) else ST:RefreshIconLayout(frameIndex) end; ST:RefreshDisplay()
        end, Track)
    yOff, _ = MakeSlider(content, PADDING+4, yOff, 220, "Opacity", 0, 100, 1,
        function() return math.floor((frameConfig.barAlpha or 1)*100) end,
        function(v) frameConfig.barAlpha=v/100
            if frameConfig.layout=="bar" then ST:RefreshBarLayout(frameIndex) else ST:RefreshIconLayout(frameIndex) end; ST:RefreshDisplay()
        end, Track)
    yOff, _ = MakeSlider(content, PADDING+4, yOff, 220, "Spacing", 0, 12, 1,
        function() return frameConfig.iconSpacing or 2 end,
        function(v) frameConfig.iconSpacing=v
            if frameConfig.layout=="bar" then ST:RefreshBarLayout(frameIndex) else ST:RefreshIconLayout(frameIndex) end; ST:RefreshDisplay()
        end, Track)
    return yOff
end

-------------------------------------------------------------------------------
-- Sub-builder: Interrupts content
-------------------------------------------------------------------------------

local function BuildInterruptsContent(ST, content, yOff, Track, Rebuild)
    local frameConfig = ST:GetFrameConfig("interrupts"); if not frameConfig then return yOff end
    local function DAR()
        local d = ST.displayFrames and ST.displayFrames["interrupts"]
        if d then if d.frame then d.frame:Hide(); d.frame:SetParent(nil) end; ST.displayFrames["interrupts"]=nil end; ST:RefreshDisplay()
    end

    yOff = MakeHeader(content, PADDING + 4, yOff, "Interrupts Frame", Track)

    yOff, _ = MakeDropdown(content, PADDING+4, yOff, 220, "Layout", LAYOUT_OPTIONS, LAYOUT_LABELS,
        function() return frameConfig.layout or "bar" end,
        function(v) if frameConfig.layout~=v then frameConfig.layout=v; DAR(); Rebuild() end end, Track)
    yOff, _ = MakeDropdown(content, PADDING+4, yOff, 220, "Show In", GROUP_MODE_OPTIONS, GROUP_MODE_LABELS,
        function() return frameConfig.groupMode or "any" end,
        function(v) frameConfig.groupMode=v; ST:RefreshDisplay() end, Track)
    yOff, _ = MakeDropdown(content, PADDING+4, yOff, 220, "Grow Direction", GROW_DIR_OPTIONS, GROW_DIR_LABELS,
        function() return frameConfig.growUp and "up" or "down" end,
        function(v) frameConfig.growUp=(v=="up"); DAR(); Rebuild() end, Track)
    yOff, _ = MakeSwitch(content, PADDING+4, yOff, 280, "Enable",
        function() return frameConfig.enabled end,
        function(v) frameConfig.enabled=v; if v and ST._previewActive then ST:DeactivatePreview() end; ST:RefreshDisplay() end, Track)
    yOff, _ = MakeSwitch(content, PADDING+4, yOff, 280, "Lock Position",
        function() return frameConfig.locked end,
        function(v) frameConfig.locked=v
            local d=ST.displayFrames and ST.displayFrames["interrupts"]
            if d and d.title then if v then d.title:Hide() else d.title:Show() end end
            if frameConfig.layout=="bar" then ST:RefreshBarLayout("interrupts") else ST:RefreshIconLayout("interrupts") end; ST:RefreshDisplay()
        end, Track)
    yOff, _ = MakeSwitch(content, PADDING+4, yOff, 280, "Hide Out of Combat",
        function() return frameConfig.hideOutOfCombat end,
        function(v) frameConfig.hideOutOfCombat=v; ST:RefreshDisplay() end, Track)
    yOff, _ = MakeSwitch(content, PADDING+4, yOff, 280, "Show Player Names",
        function() return frameConfig.showNames end,
        function(v) frameConfig.showNames=v
            if frameConfig.layout=="bar" then ST:RefreshBarLayout("interrupts") else ST:RefreshIconLayout("interrupts") end; ST:RefreshDisplay()
        end, Track)
    yOff, _ = MakeSlider(content, PADDING+4, yOff, 220, "Scale", 70, 180, 1,
        function() return math.floor((frameConfig.displayScale or 1)*100) end,
        function(v) frameConfig.displayScale=v/100
            if frameConfig.layout=="bar" then ST:RefreshBarLayout("interrupts") else ST:RefreshIconLayout("interrupts") end; ST:RefreshDisplay()
        end, Track)

    yOff = yOff - 4
    MakeButton(content, PADDING+4,   yOff, 140, ROW_HEIGHT, "Reset Position", function()
        ST:ResetPosition("interrupts"); ST:Print("Interrupts position reset.")
    end, Track)
    local testLabel = ST._intTestActive and "Disable Test" or "Test"
    MakeButton(content, PADDING+154, yOff, 100, ROW_HEIGHT, testLabel, function()
        if ST._intTestActive then ST._intTestActive=nil; ST:DeactivatePreview(); ST:Print("Test disabled.")
        else ST._intTestActive=true; if ST.SetPreviewMode then ST:SetPreviewMode("party5") end
            ST:ActivatePreview(); ST:Print("Test enabled (Interrupts only.)") end; Rebuild()
    end, Track)
    yOff = yOff - ROW_HEIGHT - 8
    return yOff
end

-------------------------------------------------------------------------------
-- Frames tab UI
-------------------------------------------------------------------------------

local function BuildFramesUI(parent)
    EnsureTemplates()
    local ST = RRT.SpellTracker
    if not ST then
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        lbl:SetPoint("TOPLEFT", 12, -12); lbl:SetJustifyH("LEFT"); lbl:SetText("SpellTracker not available."); return
    end

    parent:HookScript("OnShow", function() ST._embeddedPanelOpen = true end)
    parent:HookScript("OnHide", function()
        ST._embeddedPanelOpen = false; if ST._previewActive then ST:DeactivatePreview() end
    end)
    ST._embeddedPanelOpen = true

    local scroll, scrollContent = MakeScrollContent(parent)

    local _selectedFrameIndex = 1
    local _frameTabs  = {}
    local _spellFilter = nil
    local _children   = {}

    local function Track(w) table.insert(_children, w); return w end

    local BuildContent
    local creatingFrame = false
    local function Rebuild()
        for _, c in ipairs(_children) do
            if c.UnregisterAllEvents then c:UnregisterAllEvents() end; c:Hide(); c:SetParent(nil)
        end; wipe(_children); BuildContent()
    end

    BuildContent = function()
        local db = ST.db
        if not db then
            local lbl = scrollContent:CreateFontString(nil,"OVERLAY","GameFontDisable")
            lbl:SetPoint("TOPLEFT",12,-12); lbl:SetText("SpellTracker DB not ready."); table.insert(_children,lbl); return
        end
        local savedScroll = scroll:GetVerticalScroll()
        local yOff = -8

        -- Sidebar (subtle, matching SetupManager container style)
        local sidebar = CreateFrame("Frame", nil, scrollContent, "BackdropTemplate")
        sidebar:SetPoint("TOPLEFT", PADDING, yOff); sidebar:SetWidth(SIDEBAR_WIDTH); sidebar:SetHeight(1)
        SkinPanel(sidebar); Track(sidebar)

        local MAIN_WIDTH = FRAME_WIDTH - SIDEBAR_WIDTH - COLUMN_GAP - PADDING * 2
        local main = CreateFrame("Frame", nil, scrollContent)
        main:SetPoint("TOPLEFT", sidebar, "TOPRIGHT", COLUMN_GAP, 0)
        main:SetWidth(MAIN_WIDTH); main:SetHeight(1); Track(main)

        -- Sidebar: header
        local sideY = -10
        local sideTitle = sidebar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ApplyRRTFont(sideTitle, 11)
        sideTitle:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 8, sideY)
        sideTitle:SetText("|cffffcc00Frames|r"); Track(sideTitle)
        sideY = sideY - 22

        -- "+ New Frame" nav button
        local newBtn = MakeNavButton(sidebar, 8, sideY, SIDEBAR_WIDTH - 16, ROW_HEIGHT, "+ New Frame", function()
            if creatingFrame then return end
            creatingFrame = true
            C_Timer.After(0, function() creatingFrame = false end)
            local before = #(db.frames or {}); local idx = ST:CreateCustomFrame()
            if not idx then idx = #(db.frames or {}) end
            if idx <= before then ST:Print("Unable to create a new frame."); return end
            local fc = ST:GetFrameConfig(idx)
            if fc then fc.locked=false; fc.position={point="CENTER",relativePoint="CENTER",x=0,y=-150} end
            _selectedFrameIndex=idx; _frameTabs[idx]="settings"; Rebuild(); ST:RefreshDisplay()
            if not ST._previewActive and not IsInGroup() and not IsInRaid() then
                ST:ActivatePreview(); ST:Print("Preview enabled for new frame."); Rebuild()
            end
        end, Track)
        SetTabActive(newBtn, false); sideY = sideY - ROW_HEIGHT - 6

        local frameCount = #(db.frames or {})
        _selectedFrameIndex = frameCount > 0 and math.max(1, math.min(_selectedFrameIndex or 1, frameCount)) or 1

        -- Frame list
        for frameIndex, frameConfig in ipairs(db.frames or {}) do
            local fIdx = frameIndex
            local isSelected = fIdx == _selectedFrameIndex
            local row = CreateFrame("Frame", nil, sidebar)
            row:SetPoint("TOPLEFT", sidebar, "TOPLEFT", 6, sideY); row:SetSize(SIDEBAR_WIDTH - 12, 24); Track(row)

            local nameBtn = MakeNavButton(row, 0, 0, SIDEBAR_WIDTH - 34, 24, frameConfig.name or ("Frame "..fIdx), function() _selectedFrameIndex=fIdx; Rebuild() end, Track)
            SetTabActive(nameBtn, isSelected)

            local delBtn = CreateFrame("Button", nil, row)
            delBtn:SetPoint("TOPRIGHT", 0, 0); delBtn:SetSize(22, 24)
            local dbg = delBtn:CreateTexture(nil,"BACKGROUND"); dbg:SetAllPoints()
            dbg:SetTexture("Interface\\BUTTONS\\WHITE8X8"); dbg:SetVertexColor(0.4,0.1,0.1,1)
            local dt = delBtn:CreateFontString(nil,"OVERLAY"); dt:SetFont(FONT,11,"OUTLINE"); dt:SetPoint("CENTER",0,0)
            dt:SetTextColor(1,0.6,0.6); dt:SetText("X"); Track(delBtn)
            delBtn:SetScript("OnEnter", function() dbg:SetVertexColor(0.6,0.15,0.15,1) end)
            delBtn:SetScript("OnLeave", function() dbg:SetVertexColor(0.4,0.1,0.1,1) end)
            delBtn:SetScript("OnClick", function()
                ST:DeleteCustomFrame(fIdx)
                local nt={}; for idx,v in pairs(_frameTabs) do if idx>fIdx then nt[idx-1]=v elseif idx<fIdx then nt[idx]=v end end; _frameTabs=nt
                local rem=#(ST.db and ST.db.frames or {}); _selectedFrameIndex=rem>0 and math.max(1,math.min(_selectedFrameIndex,rem)) or 1
                Rebuild(); ST:RefreshDisplay()
            end)
            sideY = sideY - 26
        end; sideY = sideY - 6

        -- Preview Mode
        local pmTitle = sidebar:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
        ApplyRRTFont(pmTitle, 10); pmTitle:SetPoint("TOPLEFT",sidebar,"TOPLEFT",8,sideY)
        pmTitle:SetText("Preview Mode"); Track(pmTitle); sideY = sideY - 20

        local pvLbl = ST._previewActive and "Disable Preview" or "Toggle Preview"
        MakeNavButton(sidebar, 8, sideY, SIDEBAR_WIDTH - 16, ROW_HEIGHT, pvLbl, function()
            if ST._previewActive then ST:DeactivatePreview(); ST:Print("Preview disabled.")
            else
                if ST.SetPreviewMode then ST:SetPreviewMode("party5") end
                ST:ActivatePreview()
                ST:Print("Preview enabled") end; Rebuild()
        end, Track); sideY = sideY - ROW_HEIGHT - 8

        -- Main panel
        local mainY = 0
        if frameCount > 0 then
            local fi = _selectedFrameIndex; local fc = ST:GetFrameConfig(fi); local at = _frameTabs[fi] or "settings"

            -- Sub-tab buttons (Settings / Spells / Display)
            local tabDefs = { {"Settings","settings"}, {"Spells","spells"}, {"Display","display"} }
            local tx = PADDING + 4
            local tabBtns = {}
            for _, td in ipairs(tabDefs) do
                local tabLabel, tabId = td[1], td[2]
                local tb = MakeNavButton(main, tx, -6, 84, 22, tabLabel, function()
                    _frameTabs[fi] = tabId; Rebuild()
                end, Track)
                SetTabActive(tb, at == tabId); tabBtns[tabId] = tb; tx = tx + 88
            end

            -- Spell count label
            local sc = 0; if fc and fc.spells then for _ in pairs(fc.spells) do sc = sc + 1 end end
            local scLbl = main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            ApplyRRTFont(scLbl, 10)
            scLbl:SetPoint("TOPRIGHT",main,"TOPRIGHT",-PADDING,-10)
            scLbl:SetText(sc.." spells selected"); Track(scLbl)

            mainY = -6 - 28
            if at == "settings" then
                mainY = BuildFrameSettings(ST, main, fi, mainY, Track, Rebuild)
            elseif at == "spells" then
                mainY = BuildFrameSpells(ST, main, fi, mainY, Track, Rebuild, _spellFilter, function(cat)
                    _spellFilter = (_spellFilter == cat) and nil or cat; Rebuild()
                end)
            else
                mainY = BuildFrameDisplay(ST, main, fi, mainY, Track, Rebuild)
            end
        else
            local hint = main:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
            ApplyRRTFont(hint, 10)
            hint:SetPoint("TOPLEFT",main,"TOPLEFT",PADDING+4,-20)
            hint:SetText("No frames configured. Click \"+ New Frame\" to get started.")
            Track(hint); mainY = -50
        end

        local mH = math.max(64, math.abs(mainY)+PADDING); local sH = math.max(100, math.abs(sideY)+PADDING)
        main:SetHeight(mH); sidebar:SetHeight(sH)
        local total = math.max(mH,sH)+math.abs(yOff)+20; scrollContent:SetHeight(total)
        local maxS = math.max(0, total-scroll:GetHeight()); scroll:SetVerticalScroll(math.min(savedScroll,maxS))
    end

    BuildContent()
end

-------------------------------------------------------------------------------
-- Interrupts tab UI
-------------------------------------------------------------------------------

local function BuildInterruptsUI(parent)
    EnsureTemplates()
    local ST = RRT.SpellTracker
    if not ST then
        local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        lbl:SetPoint("TOPLEFT", 12, -12); lbl:SetJustifyH("LEFT"); lbl:SetText("SpellTracker not available."); return
    end

    parent:HookScript("OnShow", function() ST._embeddedPanelOpen = true end)
    parent:HookScript("OnHide", function()
        ST._embeddedPanelOpen = false; if ST._previewActive then ST:DeactivatePreview() end
    end)
    ST._embeddedPanelOpen = true

    local scroll, scrollContent = MakeScrollContent(parent)
    local _children = {}
    local function Track(w) table.insert(_children, w); return w end

    local BuildContent
    local function Rebuild()
        for _, c in ipairs(_children) do
            if c.UnregisterAllEvents then c:UnregisterAllEvents() end; c:Hide(); c:SetParent(nil)
        end; wipe(_children); BuildContent()
    end

    BuildContent = function()
        if not ST.db then return end
        local saved = scroll:GetVerticalScroll()
        local finalY = BuildInterruptsContent(ST, scrollContent, -8, Track, Rebuild)
        local h = math.max(64, math.abs(finalY)+PADDING); scrollContent:SetHeight(h)
        local maxS = math.max(0, h-scroll:GetHeight()); scroll:SetVerticalScroll(math.min(saved,maxS))
    end

    BuildContent()
end

-------------------------------------------------------------------------------
-- Exports
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.SetupManager = RRT.UI.SetupManager or {}
RRT.UI.SetupManager.SpellTrackerFrames     = { BuildUI = BuildFramesUI     }
RRT.UI.SetupManager.SpellTrackerInterrupts = { BuildUI = BuildInterruptsUI }
