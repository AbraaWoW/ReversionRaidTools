local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core = RRT.UI.Core
local window_width = Core.window_width
local window_height = Core.window_height
local options_text_template = Core.options_text_template
local options_dropdown_template = Core.options_dropdown_template
local options_switch_template = Core.options_switch_template
local options_slider_template = Core.options_slider_template
local options_button_template = Core.options_button_template

local SUB_TABS_LIST = {
    { name = "Frames",     text = "Frames"     },
    { name = "Interrupts", text = "Interrupts" },
    { name = "Raids",      text = "Raids"      },
    { name = "Groups",     text = "Groups"     },
    { name = "Note",       text = "Note"       },
    { name = "Tools",      text = "Tools"      },
}

-------------------------------------------------------------------------------
-- Widget helpers (matching AbraaRaidTools style)
-------------------------------------------------------------------------------

local FONT           = "Fonts\\FRIZQT__.TTF"
local PADDING        = 12
local ROW_HEIGHT     = 26
local COLOR_ACCENT   = { 0.30, 0.72, 1.00 }
local COLOR_LABEL    = { 0.85, 0.85, 0.85 }
local COLOR_MUTED    = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }
local COLOR_SECTION  = { 0.12, 0.12, 0.12, 1.0 }
local COLOR_BORDER   = { 0.2, 0.2, 0.2, 1.0 }

local function SkinPanel(frame, bgColor, borderColor)
    if not frame then return end
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor or COLOR_SECTION))
    frame:SetBackdropBorderColor(unpack(borderColor or COLOR_BORDER))
end

local function SkinButton(btn, color, hoverColor)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    bg:SetVertexColor(unpack(color or COLOR_BTN))
    btn._bg = bg

    btn:SetScript("OnEnter", function(self)
        self._bg:SetVertexColor(unpack(hoverColor or COLOR_BTN_HOVER))
    end)
    btn:SetScript("OnLeave", function(self)
        self._bg:SetVertexColor(unpack(color or COLOR_BTN))
    end)
end

local function CreateActionButton(parent, xOff, yOff, text, width, onClick, color)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetPoint("TOPLEFT", xOff, yOff)
    btn:SetSize(width, ROW_HEIGHT)
    SkinButton(btn, color or COLOR_BTN, COLOR_BTN_HOVER)

    local btnText = btn:CreateFontString(nil, "OVERLAY")
    btnText:SetFont(FONT, 11)
    btnText:SetPoint("CENTER", 0, 0)
    btnText:SetTextColor(unpack(COLOR_LABEL))
    btnText:SetText(text)

    btn:SetScript("OnClick", onClick)
    return btn
end

local function CreateCheckbox(parent, xOff, yOff, text, checked, onChange)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", xOff, yOff)
    cb:SetSize(22, 22)
    cb:SetChecked(checked)

    local label = cb:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12)
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetTextColor(unpack(COLOR_LABEL))
    label:SetText(text)
    cb.label = label

    cb:SetScript("OnClick", function(self)
        local val = self:GetChecked()
        if onChange then onChange(val) end
    end)
    return cb
end

-- Scrollable content host for tall sub-tabs
local function CreateScrollContent(parent, contentHeight)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0,   0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 0)

    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(820)
    content:SetHeight(contentHeight or 1400)
    scroll:SetScrollChild(content)
    return content
end

-- No-op Track (section builders require it; we build each tab once)
local function Track(w) return w end

-------------------------------------------------------------------------------
-- Tab content builders
-------------------------------------------------------------------------------

local function BuildFramesTab(parent)
    local mod = RRT.UI and RRT.UI.SetupManager and RRT.UI.SetupManager.SpellTrackerFrames
    if mod and mod.BuildUI then
        mod.BuildUI(parent)
    else
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
        label:SetJustifyH("LEFT")
        label:SetText("SpellTracker Frames module not available.")
    end
end

local function BuildInterruptsTab(parent)
    local mod = RRT.UI and RRT.UI.SetupManager and RRT.UI.SetupManager.SpellTrackerInterrupts
    if mod and mod.BuildUI then
        mod.BuildUI(parent)
    else
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
        label:SetJustifyH("LEFT")
        label:SetText("SpellTracker Interrupts module not available.")
    end
end

local function BuildRaidsTab(parent)
    local options = {
        {
            type = "button",
            name = "Default Arrangement",
            desc = "Sorts groups into a default order (tanks - melee - ranged - healer)",
            func = function()
                RRT:SplitGroupInit(false, true, false)
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "button",
            name = "Split Groups",
            desc = "Splits the group evenly into 2 groups. It will even out tanks, melee, ranged and healers, as well as trying to balance the groups by class and specs",
            func = function()
                RRT:SplitGroupInit(false, false, false)
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "button",
            name = "Split Evens/Odds",
            desc = "Same as the button above but using groups 1/3/5 and 2/4/6.",
            func = function()
                RRT:SplitGroupInit(false, false, true)
            end,
            nocombat = true,
            spacement = true,
        },
        {
            type = "breakline",
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show Missing Raidbuffs in Raid-Tab",
            desc = "Show a list of missing raidbuffs in your comp in the raid tab. In there you can swap between Mythic and Flex, which will then only consider players up to group 4/6 respectively.",
            get = function() return RRTDB.Settings.MissingRaidBuffs end,
            set = function(self, fixedparam, value)
                RRTDB.Settings.MissingRaidBuffs = value
                RRT:UpdateRaidBuffFrame()
            end,
            nocombat = true,
        },
    }

    DF:BuildMenu(parent, options, 10, -10, window_height - 10, false,
        options_text_template, options_dropdown_template, options_switch_template,
        true, options_slider_template, options_button_template, function() end)
end

local function BuildGroupsTab(parent)
    local mod = RRT.UI and RRT.UI.SetupManager and RRT.UI.SetupManager.RaidGroups
    if mod and mod.BuildUI then
        mod.BuildUI(parent)
    else
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
        label:SetJustifyH("LEFT")
        label:SetText("RaidGroups module not available.")
    end
end

local function BuildNoteTab(parent)
    local mod = RRT.UI and RRT.UI.SetupManager and RRT.UI.SetupManager.Note
    if mod and mod.BuildUI then
        mod.BuildUI(parent)
    else
        local label = parent:CreateFontString(nil, "OVERLAY", "GameFontDisable")
        label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, -12)
        label:SetJustifyH("LEFT")
        label:SetText("Note module not available.")
    end
end

local function BuildToolsTab(parent)
    local toolsPanel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    toolsPanel:SetPoint("TOPLEFT", parent, "TOPLEFT", 0, 0)
    toolsPanel:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", 0, 0)
    toolsPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    toolsPanel:SetBackdropColor(0, 0, 0, 0.18)

    local colGap = 12
    local colWidth = math.floor((820 - (colGap * 2)) / 3)
    local topPadding = 10
    local leftPadding = 10

    local columns = {}
    for i = 1, 3 do
        local colName = "RRT_SetupManagerToolsCol" .. i
        local col = CreateFrame("Frame", colName, toolsPanel, "BackdropTemplate")
        col:SetSize(colWidth, window_height - 150)
        col:SetPoint("TOPLEFT", toolsPanel, "TOPLEFT", leftPadding + (i - 1) * (colWidth + colGap), -topPadding)
        col:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
        })
        col:SetBackdropColor(0, 0, 0, 0.12)
        columns[i] = col
    end

    local tools = RRT.Tools or {}
    local toolDefs = {
        { mod = tools.BattleRez,   title = "Battle Resurrection" },
        { mod = tools.MarksBar,    title = "Marks Bar" },
        { mod = tools.CombatTimer, title = "Combat Timer" },
    }

    for i, def in ipairs(toolDefs) do
        local col = columns[i]
        local options = def.mod and def.mod.BuildOptions and def.mod.BuildOptions()

        if options and #options > 0 then
            DF:BuildMenu(col, options, 8, -8, window_height - 170, false,
                options_text_template, options_dropdown_template, options_switch_template,
                true, options_slider_template, options_button_template, function() end)
        else
            local lbl = col:CreateFontString(nil, "OVERLAY", "GameFontDisable")
            lbl:SetPoint("TOPLEFT", col, "TOPLEFT", PADDING, -PADDING)
            lbl:SetJustifyH("LEFT")
            lbl:SetText(def.title .. " module not available.")
        end
    end
end

-------------------------------------------------------------------------------
-- Main builder
-------------------------------------------------------------------------------

local function BuildSetupManagerUI(parent)
    if parent.SetupManagerSubTabs then
        return parent.SetupManagerSubTabs
    end

    local container = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    container:SetSize(window_width - 20, window_height - 110)
    container:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -90)
    container:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
    })
    container:SetBackdropColor(0, 0, 0, 0.2)

    local navWidth = 140
    local nav = CreateFrame("Frame", nil, container)
    nav:SetPoint("TOPLEFT",    container, "TOPLEFT",    8, -8)
    nav:SetPoint("BOTTOMLEFT", container, "BOTTOMLEFT", 8,  8)
    nav:SetWidth(navWidth)

    local divider = container:CreateTexture(nil, "ARTWORK")
    divider:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    divider:SetPoint("TOPLEFT",    nav, "TOPRIGHT",    8, 0)
    divider:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 8, 0)
    divider:SetWidth(1)

    local contentHost = CreateFrame("Frame", nil, container)
    contentHost:SetPoint("TOPLEFT",     nav,       "TOPRIGHT",     16, 0)
    contentHost:SetPoint("BOTTOMRIGHT", container, "BOTTOMRIGHT", -8,  8)

    local subFrames = {}
    local buttons   = {}
    local currentTab = SUB_TABS_LIST[1].name

    local function EnsureTabFrame(tabName)
        if subFrames[tabName] then return subFrames[tabName] end

        local frame = CreateFrame("Frame", "RRT_SetupManager_" .. tabName, contentHost)
        frame:SetAllPoints(contentHost)
        frame:Hide()

        if tabName == "Frames" then
            BuildFramesTab(frame)
        elseif tabName == "Interrupts" then
            BuildInterruptsTab(frame)
        elseif tabName == "Raids" then
            BuildRaidsTab(frame)
        elseif tabName == "Groups" then
            BuildGroupsTab(frame)
        elseif tabName == "Note" then
            BuildNoteTab(frame)
        elseif tabName == "Tools" then
            BuildToolsTab(frame)
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
            frame:Hide()
        end
        local frame = EnsureTabFrame(tabName)
        frame:Show()
        UpdateButtonState()
    end

    local y = -2
    local btnHeight = 24
    local btnGap    = 4
    for _, tab in ipairs(SUB_TABS_LIST) do
        local tabName = tab.name
        local btn = DF:CreateButton(nav, function()
            SelectTab(tabName)
        end, navWidth - 4, btnHeight, tab.text)

        local btnFrame = btn.widget or btn
        btn:SetTemplate(options_button_template)

        if btn.SetPoint then
            btn:SetPoint("TOPLEFT", nav, "TOPLEFT", 2, y)
        elseif btnFrame and btnFrame.SetPoint then
            btnFrame:SetPoint("TOPLEFT", nav, "TOPLEFT", 2, y)
        end

        if btnFrame and btnFrame.SetBackdrop then
            btnFrame:SetBackdrop({
                bgFile   = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            btnFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.8)
        end

        -- Override hover to avoid DF white flash
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

        buttons[tabName] = btn
        y = y - (btnHeight + btnGap)
    end

    SelectTab(currentTab)

    parent.SetupManagerSubTabs = container
    return container
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.SetupManager = {
    BuildUI = BuildSetupManagerUI,
}

