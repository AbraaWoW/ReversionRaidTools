local _, RRT = ...
local DF = _G["DetailsFramework"]

local options_text_template
local options_switch_template
local options_button_template

local function EnsureTemplates()
    if options_button_template then return end
    local Core = RRT.UI and RRT.UI.Core
    if not Core then return end
    options_text_template   = Core.options_text_template
    options_switch_template = Core.options_switch_template
    options_button_template = Core.options_button_template
end

-------------------------------------------------------------------------------
-- Combat Timer
-- Always visible when enabled: counts up during combat, shows 0:00.0 at rest.
-------------------------------------------------------------------------------

local _frame    = nil
local _inCombat = false
local _total    = 0

local FONT         = "Fonts\\FRIZQT__.TTF"
local PADDING      = 12
local ROW_HEIGHT   = 26
local COLOR_ACCENT = { 0.30, 0.72, 1.00 }
local COLOR_LABEL  = { 0.85, 0.85, 0.85 }
local COLOR_MUTED  = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }

local function GetDB()
    return RRTDB and RRTDB.CombatTimer
end

local function FormatTime(t)
    local s = t < 0 and 0 or t
    return string.format("%d:%02d.%1d",
        math.floor(s / 60),
        math.floor(s % 60),
        math.floor((s * 10) % 10))
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ShouldShow()
    local ct = GetDB()
    if not ct then return false end
    if not ct.enabled then return false end
    if ct.hideOutOfCombat and not _inCombat then return false end
    return true
end

local function RefreshVisibility()
    if not _frame then return end
    if ShouldShow() then _frame:Show() else _frame:Hide() end
end

local function ApplyLock()
    local ct = GetDB()
    if not _frame or not ct then return end
    _frame:SetMovable(not ct.locked)
    _frame:EnableMouse(not ct.locked)
end

local function ApplyScale()
    local ct = GetDB()
    if not _frame or not ct then return end
    _frame:SetScale(ct.scale or 1.0)
end

local function ApplySavedPosition(f)
    local ct = GetDB()
    local pos = ct and ct.position
    f:ClearAllPoints()
    if pos and pos.left and pos.top then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    end
end

-------------------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------------------

local function CreateCombatTimerFrame()
    if _frame then return _frame end

    local f = CreateFrame("Frame", "RRTCombatTimerFrame", UIParent, "BackdropTemplate")
    f:SetSize(90, 30)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    f:SetFrameStrata("HIGH")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if self:IsMovable() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local ct = GetDB()
        if ct then ct.position = { left = self:GetLeft(), top = self:GetTop() } end
    end)

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.7)

    local txt = f:CreateFontString(nil, "OVERLAY")
    txt:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    txt:SetPoint("CENTER", 0, 0)
    txt:SetTextColor(1, 1, 1, 1)
    txt:SetShadowOffset(1, -1)
    txt:SetText("0:00.0")
    f.txt = txt

    f:SetScript("OnUpdate", function(self, elapsed)
        if not _inCombat then return end
        _total = _total + elapsed
        self.txt:SetText(FormatTime(_total))
    end)

    f:Hide()
    _frame = f
    return f
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local ctEventFrame = CreateFrame("Frame")
ctEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
ctEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
ctEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        local ct = GetDB()
        if not ct or not ct.enabled then return end
        _total    = 0
        _inCombat = true
        if _frame then _frame.txt:SetText("0:00.0") end
        RefreshVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        _inCombat = false
        if _frame then _frame.txt:SetText("0:00.0") end
        RefreshVisibility()
    end
end)

local ctInitFrame = CreateFrame("Frame")
ctInitFrame:RegisterEvent("PLAYER_LOGIN")
ctInitFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    CreateCombatTimerFrame()
    ApplySavedPosition(_frame)
    ApplyLock()
    ApplyScale()
    RefreshVisibility()
end)

-------------------------------------------------------------------------------
-- Settings UI
-------------------------------------------------------------------------------

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

local function CreateActionButton(parent, xOff, yOff, text, width, onClick)
    EnsureTemplates()
    local btn
    if DF and DF.CreateButton then
        btn = DF:CreateButton(parent, onClick, width, ROW_HEIGHT, text)
        if options_button_template then btn:SetTemplate(options_button_template) end
        if btn.SetPoint then
            btn:SetPoint("TOPLEFT", xOff, yOff)
        else
            local f = btn.widget or btn
            if f and f.SetPoint then f:SetPoint("TOPLEFT", xOff, yOff) end
        end
    else
        btn = CreateFrame("Button", nil, parent)
        btn:SetPoint("TOPLEFT", xOff, yOff)
        btn:SetSize(width, ROW_HEIGHT)
        SkinButton(btn)
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11)
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetTextColor(unpack(COLOR_LABEL))
        lbl:SetText(text)
        btn:SetScript("OnClick", onClick)
    end
    return btn
end

local function CreateCheckbox(parent, xOff, yOff, text, checked, onChange)
    EnsureTemplates()
    if DF and DF.CreateSwitch then
        local sw = DF:CreateSwitch(parent, function(_, _, value)
            if onChange then onChange(value and true or false) end
        end, checked and true or false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
        sw:SetAsCheckBox()
        sw:SetPoint("TOPLEFT", xOff, yOff)
        if sw.Text then sw.Text:SetText(""); sw.Text:Hide() end
        local label = DF:CreateLabel(parent, text, 10, "white")
        if options_text_template and label.SetTemplate then label:SetTemplate(options_text_template) end
        label:SetPoint("LEFT", sw, "RIGHT", 4, 0)
        return sw
    end

    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", xOff, yOff)
    cb:SetSize(22, 22)
    cb:SetChecked(checked)
    local label = cb:CreateFontString(nil, "OVERLAY")
    label:SetFont(FONT, 12)
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetTextColor(unpack(COLOR_LABEL))
    label:SetText(text)
    cb:SetScript("OnClick", function(self)
        if onChange then onChange(self:GetChecked()) end
    end)
    return cb
end

local function BuildCombatTimerUI(parent)
    EnsureTemplates()
    local ct = GetDB()
    if not ct then return end
    local yOff = -10

    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", PADDING, yOff)
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText("Combat Timer")
    yOff = yOff - 24

    CreateCheckbox(parent, PADDING, yOff, "Enable combat timer", ct.enabled, function(val)
        ct.enabled = val
        if not val then
            _inCombat = false
            if _frame then _frame:Hide() end
        else
            if _frame then _frame.txt:SetText("0:00.0") end
            RefreshVisibility()
        end
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Hide when out of combat", ct.hideOutOfCombat, function(val)
        ct.hideOutOfCombat = val
        RefreshVisibility()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Lock position", ct.locked, function(val)
        ct.locked = val
        ApplyLock()
    end)
    yOff = yOff - ROW_HEIGHT - 8

    local scaleLabel = parent:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont(FONT, 11)
    scaleLabel:SetPoint("TOPLEFT", PADDING, yOff - 5)
    scaleLabel:SetTextColor(unpack(COLOR_MUTED))
    scaleLabel:SetText("Scale:")

    local scalePct = parent:CreateFontString(nil, "OVERLAY")
    scalePct:SetFont(FONT, 11)
    scalePct:SetWidth(44)
    scalePct:SetPoint("TOPLEFT", PADDING + 90, yOff - 5)
    scalePct:SetTextColor(1, 1, 1)
    scalePct:SetText(math.floor((ct.scale or 1.0) * 100) .. "%")

    local function ApplyScaleStep(delta)
        local cur = math.floor((ct.scale or 1.0) * 10 + 0.5)
        cur = math.max(5, math.min(20, cur + delta))
        ct.scale = cur / 10
        if _frame then _frame:SetScale(ct.scale) end
        scalePct:SetText(math.floor(ct.scale * 100) .. "%")
    end

    CreateActionButton(parent, PADDING + 52, yOff, "-", 34, function() ApplyScaleStep(-1) end)
    CreateActionButton(parent, PADDING + 138, yOff, "+", 34, function() ApplyScaleStep(1) end)
    yOff = yOff - ROW_HEIGHT - 8

    CreateActionButton(parent, PADDING, yOff, "Reset Position", 120, function()
        local db = GetDB()
        if db then db.position = nil end
        if _frame then ApplySavedPosition(_frame) end
    end)
end

local function BuildCombatTimerOptions()
    return {
        { type = "label", get = function() return "Combat Timer" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable combat timer",
            get = function() return (GetDB() and GetDB().enabled) and true or false end,
            set = function(self, fixedparam, value)
                local ct = GetDB(); if not ct then return end
                ct.enabled = value and true or false
                if not ct.enabled then
                    _inCombat = false
                    if _frame then _frame:Hide() end
                else
                    if _frame then _frame.txt:SetText("0:00.0") end
                    RefreshVisibility()
                end
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide when out of combat",
            get = function() return (GetDB() and GetDB().hideOutOfCombat) and true or false end,
            set = function(self, fixedparam, value)
                local ct = GetDB(); if not ct then return end
                ct.hideOutOfCombat = value and true or false
                RefreshVisibility()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lock position",
            get = function() return (GetDB() and GetDB().locked) and true or false end,
            set = function(self, fixedparam, value)
                local ct = GetDB(); if not ct then return end
                ct.locked = value and true or false
                ApplyLock()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Scale",
            get = function()
                local ct = GetDB(); if not ct then return 100 end
                return math.floor((ct.scale or 1.0) * 100)
            end,
            set = function(self, fixedparam, value)
                local ct = GetDB(); if not ct then return end
                ct.scale = (value or 100) / 100
                ApplyScale()
            end,
            min = 50,
            max = 200,
            step = 1,
        },
    }
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.Tools = RRT.Tools or {}
RRT.Tools.CombatTimer = {
    BuildUI = BuildCombatTimerUI,
    BuildOptions = BuildCombatTimerOptions,
}
