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
-- Battle Resurrection
-- Self-contained tool: tracks shared b-rez pool charges and recharge timer.
-------------------------------------------------------------------------------

local BREZ_SPELL_ID = 20484

local _frame    = nil
local _ticker   = nil
local _inCombat = false

local FONT         = "Fonts\\FRIZQT__.TTF"
local PADDING      = 12
local ROW_HEIGHT   = 26
local COLOR_ACCENT = { 0.30, 0.72, 1.00 }
local COLOR_LABEL  = { 0.85, 0.85, 0.85 }
local COLOR_MUTED  = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }

local function GetDB()
    return RRTDB and RRTDB.BattleRez
end

-------------------------------------------------------------------------------
-- API compatibility
-------------------------------------------------------------------------------

local function QueryBrezCharges()
    if C_Spell and C_Spell.GetSpellCharges then
        local info = C_Spell.GetSpellCharges(BREZ_SPELL_ID)
        if info then
            return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration
        end
        return nil
    end
    local charges, maxCharges, started, duration = GetSpellCharges(BREZ_SPELL_ID)
    if charges == 0 and maxCharges == 0 then return nil end
    return charges, maxCharges, started, duration
end

local function GetBrezTexture()
    if C_Spell and C_Spell.GetSpellTexture then
        return C_Spell.GetSpellTexture(BREZ_SPELL_ID)
    end
    return GetSpellTexture(BREZ_SPELL_ID)
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ShouldShow(hasPoolData)
    local br = GetDB()
    if not br then return false end
    if not br.enabled then return false end
    if br.showWhenUnlocked and not br.locked then return true end
    if br.hideOutOfCombat and not _inCombat then return false end
    if not hasPoolData then return false end
    return true
end

local function ApplyLock()
    local br = GetDB()
    if not _frame or not br then return end
    _frame:SetMovable(not br.locked)
    _frame:EnableMouse(not br.locked)
end

local function ApplyScale()
    local br = GetDB()
    if not _frame or not br then return end
    _frame:SetScale(br.scale or 1.0)
end

local function ApplySavedPosition(f)
    local br = GetDB()
    local pos = br and br.position
    f:ClearAllPoints()
    if pos and pos.left and pos.top then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -200)
    end
end

-------------------------------------------------------------------------------
-- Tick / display
-------------------------------------------------------------------------------

local function OnTick()
    if not _frame then return end
    local charges, maxCharges, started, duration = QueryBrezCharges()
    local hasPoolData = charges ~= nil and maxCharges ~= nil

    if not ShouldShow(hasPoolData) then
        _frame:Hide()
        return
    end

    if not _frame:IsShown() then _frame:Show() end

    if hasPoolData then
        _frame.chargeText:SetText(charges or "")
        if (charges or 0) == 0 then
            _frame.chargeText:SetTextColor(1, 0, 0, 1)
        else
            _frame.chargeText:SetTextColor(1, 1, 1, 1)
        end
    else
        _frame.chargeText:SetText("")
        _frame.chargeText:SetTextColor(1, 1, 1, 1)
    end

    if charges and maxCharges and charges < maxCharges and started and duration and duration > 0 then
        _frame.cooldown:SetCooldown(started, duration)
        _frame.cooldown:Show()
        local remaining = duration - (GetTime() - started)
        if remaining > 60 then
            _frame.timeText:SetFormattedText("%d:%02d", math.floor(remaining / 60), remaining % 60)
        elseif remaining > 0 then
            _frame.timeText:SetFormattedText("%d", math.ceil(remaining))
        else
            _frame.timeText:SetText("")
        end
    else
        _frame.cooldown:SetCooldown(0, 0)
        _frame.timeText:SetText("")
    end
end

-------------------------------------------------------------------------------
-- Overlay frame
-------------------------------------------------------------------------------

local function CreateBrezFrame()
    if _frame then return _frame end

    local f = CreateFrame("Frame", "RRTBattleRezFrame", UIParent)
    f:SetSize(64, 64)
    f:SetPoint("TOP", UIParent, "TOP", 0, -200)
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
        local br = GetDB()
        if br then br.position = { left = self:GetLeft(), top = self:GetTop() } end
    end)

    local tex = f:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    tex:SetTexture(GetBrezTexture())
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate")
    cd:SetAllPoints()
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(true)
    cd:SetFrameLevel(f:GetFrameLevel() + 10)
    f.cooldown = cd

    local textLayer = CreateFrame("Frame", nil, f)
    textLayer:SetAllPoints()
    textLayer:SetFrameLevel(f:GetFrameLevel() + 20)

    local timeText = textLayer:CreateFontString(nil, "ARTWORK")
    timeText:SetAllPoints()
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE")
    timeText:SetJustifyH("CENTER")
    timeText:SetJustifyV("MIDDLE")
    timeText:SetTextColor(1, 1, 1, 1)
    timeText:SetText("")
    f.timeText = timeText

    local chargeText = textLayer:CreateFontString(nil, "ARTWORK")
    chargeText:SetAllPoints()
    chargeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE")
    chargeText:SetJustifyH("RIGHT")
    chargeText:SetJustifyV("BOTTOM")
    chargeText:SetShadowOffset(1, -1)
    chargeText:SetTextColor(1, 1, 1, 1)
    chargeText:SetText("")
    f.chargeText = chargeText

    f:Hide()
    _frame = f
    return f
end

-------------------------------------------------------------------------------
-- Enable / Disable
-------------------------------------------------------------------------------

local function EnableTracker()
    if not _frame then
        CreateBrezFrame()
        ApplySavedPosition(_frame)
    end
    ApplyLock()
    ApplyScale()
    if not _ticker then
        _ticker = C_Timer.NewTicker(0.1, OnTick)
    end
    OnTick()
end

local function DisableTracker()
    if _ticker then _ticker:Cancel(); _ticker = nil end
    if _frame then _frame:Hide() end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local brezEventFrame = CreateFrame("Frame")
brezEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
brezEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
brezEventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        _inCombat = true
        OnTick()
    elseif event == "PLAYER_REGEN_ENABLED" then
        _inCombat = false
        OnTick()
    end
end)

local brezInitFrame = CreateFrame("Frame")
brezInitFrame:RegisterEvent("PLAYER_LOGIN")
brezInitFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    CreateBrezFrame()
    ApplySavedPosition(_frame)
    ApplyLock()
    ApplyScale()
    _inCombat = UnitAffectingCombat("player") and true or false
    local br = GetDB()
    if br and br.enabled then
        EnableTracker()
    else
        DisableTracker()
    end
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

local function BuildBattleRezUI(parent)
    EnsureTemplates()
    local br = GetDB()
    if not br then return end
    local yOff = -10

    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", PADDING, yOff)
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText("Battle Resurrection")
    yOff = yOff - 24

    CreateCheckbox(parent, PADDING, yOff, "Enable battle resurrection", br.enabled, function(val)
        br.enabled = val
        if val then EnableTracker() else DisableTracker() end
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Hide when out of combat", br.hideOutOfCombat, function(val)
        br.hideOutOfCombat = val
        OnTick()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Lock position", br.locked, function(val)
        br.locked = val
        ApplyLock()
        OnTick()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Show when unlocked", br.showWhenUnlocked, function(val)
        br.showWhenUnlocked = val
        OnTick()
    end)
    yOff = yOff - ROW_HEIGHT

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
    scalePct:SetText(math.floor((br.scale or 1.0) * 100) .. "%")

    local function ApplyScaleStep(delta)
        local cur = math.floor((br.scale or 1.0) * 10 + 0.5)
        cur = math.max(5, math.min(20, cur + delta))
        br.scale = cur / 10
        if _frame then _frame:SetScale(br.scale) end
        scalePct:SetText(math.floor(br.scale * 100) .. "%")
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

local function BuildBattleRezOptions()
    return {
        { type = "label", get = function() return "Battle Resurrection" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable battle resurrection",
            get = function() return (GetDB() and GetDB().enabled) and true or false end,
            set = function(self, fixedparam, value)
                local br = GetDB(); if not br then return end
                br.enabled = value and true or false
                if br.enabled then EnableTracker() else DisableTracker() end
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Hide when out of combat",
            get = function() return (GetDB() and GetDB().hideOutOfCombat) and true or false end,
            set = function(self, fixedparam, value)
                local br = GetDB(); if not br then return end
                br.hideOutOfCombat = value and true or false
                OnTick()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lock position",
            get = function() return (GetDB() and GetDB().locked) and true or false end,
            set = function(self, fixedparam, value)
                local br = GetDB(); if not br then return end
                br.locked = value and true or false
                ApplyLock()
                OnTick()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show when unlocked",
            get = function() return (GetDB() and GetDB().showWhenUnlocked) and true or false end,
            set = function(self, fixedparam, value)
                local br = GetDB(); if not br then return end
                br.showWhenUnlocked = value and true or false
                OnTick()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Scale",
            get = function()
                local br = GetDB(); if not br then return 100 end
                return math.floor((br.scale or 1.0) * 100)
            end,
            set = function(self, fixedparam, value)
                local br = GetDB(); if not br then return end
                br.scale = (value or 100) / 100
                ApplyScale()
                OnTick()
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
RRT.Tools.BattleRez = {
    BuildUI = BuildBattleRezUI,
    BuildOptions = BuildBattleRezOptions,
}
