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
-- Marks Bar
-- Shows target marks, world markers, and raid tool buttons (ready/roles/pull).
-------------------------------------------------------------------------------

local _frame      = nil
local _pullTicker = nil

local FONT         = "Fonts\\FRIZQT__.TTF"
local PADDING      = 12
local ROW_HEIGHT   = 26
local COLOR_ACCENT = { 0.30, 0.72, 1.00 }
local COLOR_LABEL  = { 0.85, 0.85, 0.85 }
local COLOR_MUTED  = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }

local function GetDB()
    return RRTDB and RRTDB.MarksBar
end

local function RRT_Print(msg)
    print("|cFF33FF99[Reversion Raid Tools]|r " .. tostring(msg))
end

local function InCombatBlocked(action)
    if InCombatLockdown() then
        RRT_Print(action .. " is blocked during combat.")
        return true
    end
    return false
end

-------------------------------------------------------------------------------
-- Chat / pull helpers
-------------------------------------------------------------------------------

local function TMSlash()
    return (SLASH_TARGET_MARKER1 and strtrim(SLASH_TARGET_MARKER1) ~= "") and strtrim(SLASH_TARGET_MARKER1) or "/tm"
end

local function CWMSlash()
    return (SLASH_CLEAR_WORLD_MARKER1 and strtrim(SLASH_CLEAR_WORLD_MARKER1) ~= "") and strtrim(SLASH_CLEAR_WORLD_MARKER1) or "/cwm"
end

local function SendGroupMessage(msg)
    if not msg or msg == "" then return end
    if IsInRaid() then
        local canWarn = UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
        SendChatMessage(msg, canWarn and "RAID_WARNING" or "RAID")
    elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        SendChatMessage(msg, "INSTANCE_CHAT")
    elseif IsInGroup() then
        SendChatMessage(msg, "PARTY")
    else
        print(msg)
    end
end

local function CancelPullCountdown()
    if _pullTicker then
        _pullTicker:Cancel()
        _pullTicker = nil
    end
end

local function StartPullCountdown(seconds)
    seconds = tonumber(seconds) or 10
    seconds = math.max(3, math.min(30, math.floor(seconds + 0.5)))
    CancelPullCountdown()
    local remaining = seconds
    SendGroupMessage("Pull in " .. remaining .. "...")
    _pullTicker = C_Timer.NewTicker(1, function()
        remaining = remaining - 1
        if remaining <= 0 then
            SendGroupMessage("PULL!")
            CancelPullCountdown()
            return
        end
        SendGroupMessage(tostring(remaining))
    end)
end

local function CanStartRolePoll()
    if not IsInGroup() then return false end
    if IsInRaid() then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end
    return UnitIsGroupLeader("player")
end

local function StartRolePoll()
    if not IsInGroup() then RRT_Print("You are not in a group."); return end
    if not CanStartRolePoll() then RRT_Print("Role check requires leader/assistant."); return end
    if C_PartyInfo and C_PartyInfo.InitiateRolePoll then C_PartyInfo.InitiateRolePoll(); return end
    if InitiateRolePoll then InitiateRolePoll(); return end
    RRT_Print("Role check API not available.")
end

-------------------------------------------------------------------------------
-- Position / lock / scale
-------------------------------------------------------------------------------

local function ApplySavedPosition(f)
    local cfg = GetDB()
    local pos = cfg and cfg.position
    f:ClearAllPoints()
    if pos and pos.left and pos.top then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top)
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    end
end

local function ApplyLock()
    if not _frame then return end
    local cfg = GetDB()
    if not cfg then return end
    _frame:SetMovable(not cfg.locked)
    _frame:EnableMouse(not cfg.locked)
end

local function ApplyScale()
    if not _frame then return end
    local cfg = GetDB()
    if not cfg then return end
    _frame:SetScale(cfg.scale or 1.0)
end

local function HasVisibleRows(cfg)
    return cfg and (cfg.showTargetMarks or cfg.showWorldMarks or cfg.showRaidTools)
end

local function RefreshVisibility()
    if not _frame then return end
    local cfg = GetDB()
    if not cfg or not cfg.enabled or not HasVisibleRows(cfg) then
        _frame:Hide()
        CancelPullCountdown()
        return
    end
    _frame:Show()
end

-------------------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------------------

local function MakeBorder(parent)
    local b = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    b:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    b:SetBackdropColor(0.05, 0.05, 0.05, 0.8)
    b:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
    return b
end

local function UpdateLayout()
    if not _frame then return end
    local cfg = GetDB()
    if not cfg then return end

    local baseX   = 8
    local rowY    = -6
    local maxWidth = 120
    local rightX  = baseX + 8 * 24 + 6

    if _frame.targetHeader then _frame.targetHeader:Hide() end
    if _frame.worldHeader  then _frame.worldHeader:Hide()  end

    if cfg.showTargetMarks then
        for i = 1, 8 do
            local btn = _frame.targetButtons[i]
            btn:Show(); btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", baseX + (i - 1) * 24, rowY)
        end
    else
        for i = 1, 8 do _frame.targetButtons[i]:Hide() end
    end

    if cfg.showRaidTools then
        local w = _frame.raidTools[1]
        w:Show(); w:SetSize(64, 22); w:ClearAllPoints()
        w:SetPoint("TOPLEFT", rightX, rowY)
        w.text:SetText("Ready")
        maxWidth = math.max(maxWidth, rightX + 64 + 8)
    else
        _frame.raidTools[1]:Hide()
    end

    maxWidth = math.max(maxWidth, baseX + (8 * 24) + 8)
    rowY = rowY - 24

    if cfg.showWorldMarks then
        for i = 1, 8 do
            local btn = _frame.worldButtons[i]
            btn:Show(); btn:ClearAllPoints()
            btn:SetPoint("TOPLEFT", baseX + (i - 1) * 24, rowY - 1)
        end
    else
        for i = 1, 8 do _frame.worldButtons[i]:Hide() end
    end

    if _frame.clearAll then
        _frame.clearAll:Show(); _frame.clearAll:SetSize(64, 22); _frame.clearAll:ClearAllPoints()
        _frame.clearAll:SetPoint("TOPLEFT", rightX, rowY)
        maxWidth = math.max(maxWidth, rightX + 64 + 8)
    end

    maxWidth = math.max(maxWidth, baseX + (8 * 24) + 8)
    rowY = rowY - 26

    if cfg.showRaidTools then
        local labels = { "Roles", "Pull", "Cancel" }
        local x = baseX
        for i = 2, 4 do
            local w = _frame.raidTools[i]
            w:Show(); w:SetSize(64, 22); w:ClearAllPoints()
            w:SetPoint("TOPLEFT", x, rowY)
            w.text:SetText(labels[i - 1])
            x = x + 64 + 6
        end
        maxWidth = math.max(maxWidth, x + 2)
        rowY = rowY - 24
    else
        for i = 2, 4 do _frame.raidTools[i]:Hide() end
    end

    local height = math.max(42, math.abs(rowY) + 8)
    _frame:SetSize(maxWidth, height)
end

local function CreateMarksBarFrame()
    if _frame then return _frame end

    local f = CreateFrame("Frame", "RRTMarksBarFrame", UIParent, "BackdropTemplate")
    f:SetSize(460, 42)
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 80)
    f:SetFrameStrata("MEDIUM")
    f:SetClampedToScreen(true)
    f:SetMovable(true)
    f:EnableMouse(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if self:IsMovable() then self:StartMoving() end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cfg = GetDB()
        if cfg then cfg.position = { left = self:GetLeft(), top = self:GetTop() } end
    end)

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetBackdropColor(0, 0, 0, 0.7)
    f:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)

    local targetHeader = f:CreateFontString(nil, "OVERLAY")
    targetHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    targetHeader:SetText("")
    f.targetHeader = targetHeader

    local worldHeader = f:CreateFontString(nil, "OVERLAY")
    worldHeader:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    worldHeader:SetText("")
    f.worldHeader = worldHeader

    f.targetButtons = {}
    for i = 1, 8 do
        local wrap = MakeBorder(f)
        wrap:SetSize(22, 22)
        local b = CreateFrame("Button", nil, wrap, "SecureActionButtonTemplate")
        b:SetAllPoints()
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetAttribute("type", "macro")
        b:SetAttribute("macrotext1", string.format("%s %d", TMSlash(), i))
        b:SetAttribute("macrotext2", string.format("%s %d", TMSlash(), 0))
        local t = b:CreateTexture(nil, "ARTWORK")
        t:SetPoint("TOPLEFT", 1, -1)
        t:SetPoint("BOTTOMRIGHT", -1, 1)
        t:SetTexture("Interface\\TargetingFrame\\UI-RaidTargetingIcons")
        SetRaidTargetIconTexture(t, i)
        f.targetButtons[i] = wrap
    end

    f.worldButtons = {}
    local wColors = {
        {0.15,0.58,1.00},{0.06,0.66,0.06},{0.66,0.20,0.74},{0.74,0.10,0.10},
        {0.95,0.92,0.22},{0.92,0.48,0.12},{0.35,0.55,0.70},{0.92,0.92,0.92},
    }
    for i = 1, 8 do
        local wrap = MakeBorder(f)
        wrap:SetSize(22, 22)
        local b = CreateFrame("Button", nil, wrap, "SecureActionButtonTemplate")
        b:SetAllPoints()
        b:RegisterForClicks("AnyDown", "AnyUp")
        b:SetAttribute("type", "worldmarker")
        b:SetAttribute("marker", tostring(i))
        b:SetAttribute("action1", "set")
        b:SetAttribute("action2", "clear")
        local color = wrap:CreateTexture(nil, "ARTWORK")
        color:SetPoint("TOPLEFT", 3, -3)
        color:SetPoint("BOTTOMRIGHT", -3, 3)
        color:SetColorTexture(unpack(wColors[i]))
        f.worldButtons[i] = wrap
    end

    local clearAllWrap = MakeBorder(f)
    clearAllWrap:SetSize(64, 22)
    local clearAll = CreateFrame("Button", nil, clearAllWrap, "SecureActionButtonTemplate")
    clearAll:SetAllPoints()
    clearAll:RegisterForClicks("AnyDown", "AnyUp")
    clearAll:SetAttribute("type", "macro")
    clearAll:SetAttribute("macrotext", string.format(
        "%s %d\n%s 1\n%s 2\n%s 3\n%s 4\n%s 5\n%s 6\n%s 7\n%s 8",
        TMSlash(), 0, CWMSlash(), CWMSlash(), CWMSlash(), CWMSlash(),
        CWMSlash(), CWMSlash(), CWMSlash(), CWMSlash()))
    local clearAllText = clearAll:CreateFontString(nil, "OVERLAY")
    clearAllText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    clearAllText:SetPoint("CENTER", 0, 0)
    clearAllText:SetTextColor(0.85, 0.85, 0.85, 1)
    clearAllText:SetText("Clear")
    f.clearAll = clearAllWrap

    local function MakeRaidToolButton(onClick)
        local wrap = MakeBorder(f)
        wrap:SetSize(64, 22)
        local b = CreateFrame("Button", nil, wrap)
        b:SetAllPoints()
        b:SetScript("OnClick", onClick)
        local txt = b:CreateFontString(nil, "OVERLAY")
        txt:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        txt:SetPoint("CENTER", 0, 0)
        txt:SetTextColor(0.88, 0.88, 0.88, 1)
        wrap.text = txt
        return wrap
    end

    f.raidTools = {}
    f.raidTools[1] = MakeRaidToolButton(function()
        if DoReadyCheck then
            DoReadyCheck()
        elseif C_PartyInfo and C_PartyInfo.DoReadyCheck then
            C_PartyInfo.DoReadyCheck()
        end
        if RRT and RRT.ShowRaidCheck then
            C_Timer.After(0.05, function() RRT:ShowRaidCheck() end)
        end
    end)
    f.raidTools[2] = MakeRaidToolButton(function() StartRolePoll() end)
    f.raidTools[3] = MakeRaidToolButton(function()
        local cfg = GetDB()
        StartPullCountdown((cfg and cfg.pullTimer) or 10)
    end)
    f.raidTools[4] = MakeRaidToolButton(function()
        CancelPullCountdown()
        SendGroupMessage("Pull canceled.")
    end)

    _frame = f
    return f
end

-------------------------------------------------------------------------------
-- Bootstrap
-------------------------------------------------------------------------------

local mbInitFrame = CreateFrame("Frame")
mbInitFrame:RegisterEvent("PLAYER_LOGIN")
mbInitFrame:SetScript("OnEvent", function(self)
    self:UnregisterEvent("PLAYER_LOGIN")
    CreateMarksBarFrame()
    ApplySavedPosition(_frame)
    ApplyLock()
    ApplyScale()
    UpdateLayout()
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

local function BuildMarksBarUI(parent)
    EnsureTemplates()
    local cfg = GetDB()
    if not cfg then return end
    local yOff = -10

    local title = parent:CreateFontString(nil, "OVERLAY")
    title:SetFont(FONT, 12, "OUTLINE")
    title:SetPoint("TOPLEFT", PADDING, yOff)
    title:SetTextColor(1, 0.82, 0, 1)
    title:SetText("Marks Bar")
    yOff = yOff - 24

    CreateCheckbox(parent, PADDING, yOff, "Enable marks bar", cfg.enabled, function(val)
        cfg.enabled = val
        RefreshVisibility()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Show target marks", cfg.showTargetMarks, function(val)
        if InCombatBlocked("Changing marks bar layout") then return end
        cfg.showTargetMarks = val; UpdateLayout(); RefreshVisibility()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Show world markers", cfg.showWorldMarks, function(val)
        if InCombatBlocked("Changing marks bar layout") then return end
        cfg.showWorldMarks = val; UpdateLayout(); RefreshVisibility()
    end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Show raid tools", cfg.showRaidTools, function(val)
        if InCombatBlocked("Changing marks bar layout") then return end
        cfg.showRaidTools = val; UpdateLayout(); RefreshVisibility()
    end)
    yOff = yOff - ROW_HEIGHT

    local pullLabel = parent:CreateFontString(nil, "OVERLAY")
    pullLabel:SetFont(FONT, 11)
    pullLabel:SetPoint("TOPLEFT", PADDING, yOff - 5)
    pullLabel:SetTextColor(unpack(COLOR_MUTED))
    pullLabel:SetText("Pull Timer:")

    local pullSecs = parent:CreateFontString(nil, "OVERLAY")
    pullSecs:SetFont(FONT, 11)
    pullSecs:SetWidth(44)
    pullSecs:SetPoint("TOPLEFT", PADDING + 90, yOff - 5)
    pullSecs:SetTextColor(1, 1, 1)
    pullSecs:SetText(tostring(cfg.pullTimer or 10) .. "s")

    local function SetPull(delta)
        cfg.pullTimer = math.max(3, math.min(30, (cfg.pullTimer or 10) + delta))
        pullSecs:SetText(tostring(cfg.pullTimer) .. "s")
    end

    CreateActionButton(parent, PADDING + 52, yOff, "-", 34, function() SetPull(-1) end)
    CreateActionButton(parent, PADDING + 138, yOff, "+", 34, function() SetPull(1) end)
    yOff = yOff - ROW_HEIGHT

    CreateCheckbox(parent, PADDING, yOff, "Lock position", cfg.locked, function(val)
        if InCombatBlocked("Changing marks bar lock") then return end
        cfg.locked = val; ApplyLock()
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
    scalePct:SetText(math.floor((cfg.scale or 1.0) * 100) .. "%")

    local function ApplyScaleStep(delta)
        local cur = math.floor((cfg.scale or 1.0) * 10 + 0.5)
        cur = math.max(5, math.min(20, cur + delta))
        cfg.scale = cur / 10
        ApplyScale()
        scalePct:SetText(math.floor(cfg.scale * 100) .. "%")
    end

    CreateActionButton(parent, PADDING + 52, yOff, "-", 34, function() ApplyScaleStep(-1) end)
    CreateActionButton(parent, PADDING + 138, yOff, "+", 34, function() ApplyScaleStep(1) end)
    yOff = yOff - ROW_HEIGHT - 8

    CreateActionButton(parent, PADDING, yOff, "Reset Position", 120, function()
        if InCombatBlocked("Resetting marks bar") then return end
        local db = GetDB()
        if db then db.position = nil end
        if _frame then ApplySavedPosition(_frame) end
    end)
end

local function BuildMarksBarOptions()
    return {
        { type = "label", get = function() return "Marks Bar" end, text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        {
            type = "toggle",
            boxfirst = true,
            name = "Enable marks bar",
            get = function() return (GetDB() and GetDB().enabled) and true or false end,
            set = function(self, fixedparam, value)
                local cfg = GetDB(); if not cfg then return end
                cfg.enabled = value and true or false
                RefreshVisibility()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show target marks",
            get = function() return (GetDB() and GetDB().showTargetMarks) and true or false end,
            set = function(self, fixedparam, value)
                if InCombatBlocked("Changing marks bar layout") then return end
                local cfg = GetDB(); if not cfg then return end
                cfg.showTargetMarks = value and true or false
                UpdateLayout()
                RefreshVisibility()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show world markers",
            get = function() return (GetDB() and GetDB().showWorldMarks) and true or false end,
            set = function(self, fixedparam, value)
                if InCombatBlocked("Changing marks bar layout") then return end
                local cfg = GetDB(); if not cfg then return end
                cfg.showWorldMarks = value and true or false
                UpdateLayout()
                RefreshVisibility()
            end,
            nocombat = true,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Show raid tools",
            get = function() return (GetDB() and GetDB().showRaidTools) and true or false end,
            set = function(self, fixedparam, value)
                if InCombatBlocked("Changing marks bar layout") then return end
                local cfg = GetDB(); if not cfg then return end
                cfg.showRaidTools = value and true or false
                UpdateLayout()
                RefreshVisibility()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Pull Timer",
            get = function()
                local cfg = GetDB(); if not cfg then return 10 end
                return cfg.pullTimer or 10
            end,
            set = function(self, fixedparam, value)
                local cfg = GetDB(); if not cfg then return end
                cfg.pullTimer = math.max(3, math.min(30, math.floor((value or 10) + 0.5)))
            end,
            min = 3,
            max = 30,
            step = 1,
        },
        {
            type = "toggle",
            boxfirst = true,
            name = "Lock position",
            get = function() return (GetDB() and GetDB().locked) and true or false end,
            set = function(self, fixedparam, value)
                if InCombatBlocked("Changing marks bar lock") then return end
                local cfg = GetDB(); if not cfg then return end
                cfg.locked = value and true or false
                ApplyLock()
            end,
            nocombat = true,
        },
        {
            type = "range",
            name = "Scale",
            get = function()
                local cfg = GetDB(); if not cfg then return 100 end
                return math.floor((cfg.scale or 1.0) * 100)
            end,
            set = function(self, fixedparam, value)
                local cfg = GetDB(); if not cfg then return end
                cfg.scale = (value or 100) / 100
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
RRT.Tools.MarksBar = {
    BuildUI = BuildMarksBarUI,
    BuildOptions = BuildMarksBarOptions,
}
