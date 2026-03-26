local _, RRT_NS = ...

-- ═══════════════════════════════════════════════════════════════════════════
-- DB helpers
-- ═══════════════════════════════════════════════════════════════════════════

local function GetDB()
    RRT.CustomEncounterAlerts = RRT.CustomEncounterAlerts or {}
    return RRT.CustomEncounterAlerts
end

local function NextID()
    local db, max = GetDB(), 0
    for _, a in ipairs(db) do if (a.id or 0) > max then max = a.id end end
    return max + 1
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Runtime — hooked from EventHandler after EncounterAlertStart
-- ═══════════════════════════════════════════════════════════════════════════

function RRT_NS:ProcessCustomEncounterAlerts(encID)
    local db = GetDB()
    if #db == 0 then return end
    local diff = self:DifficultyCheck(14) or 0
    for _, alert in ipairs(db) do
        if alert.enabled and alert.encID == encID then
            if alert.diff == 0 or alert.diff == diff then
                local a = self:CreateDefaultAlert(
                    alert.label   or "",
                    alert.type    or "Bar",
                    (alert.spellID and alert.spellID ~= 0) and alert.spellID or nil,
                    alert.dur     or 5,
                    alert.phase   or 1,
                    encID
                )
                -- Optional overrides
                if alert.tts      ~= nil  then a.TTS      = alert.tts      end
                if alert.ttsTimer ~= nil  then a.TTSTimer = alert.ttsTimer end
                if alert.countdown        then a.countdown= alert.countdown end
                if alert.sound    ~= ""   and alert.sound then a.sound = alert.sound end
                if alert.colors   ~= ""   and alert.colors then a.colors = alert.colors end
                for _, t in ipairs(alert.times or {}) do
                    a.time = t
                    self:AddToReminder(a)
                end
            end
        end
    end
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Style constants  (match the rest of the addon)
-- ═══════════════════════════════════════════════════════════════════════════

local C_PURPLE  = { 0.733, 0.400, 1.000 }   -- #BB66FF
local C_ORANGE  = { 1.000, 0.800, 0.200 }
local C_GREY    = { 0.700, 0.700, 0.700 }
local C_RED     = { 1.000, 0.300, 0.300 }
local C_GREEN   = { 0.300, 1.000, 0.500 }
local C_BG      = { 0.05,  0.05,  0.05,  0.85 }
local C_BG_ROW1 = { 0.09,  0.09,  0.09,  0.70 }
local C_BG_ROW2 = { 0.06,  0.06,  0.06,  0.70 }
local C_BORDER  = { 0.20,  0.20,  0.20,  0.90 }
local C_BORDER_A= { 0.55,  0.25,  0.85,  1.00 }  -- active / accent

local FORM_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
}

local DIFF_VALUES = { 0, 14, 15, 16 }
local DIFF_LABELS = { "All", "Normal", "Heroic", "Mythic" }
local DIFF_MAP    = { [0]="All", [14]="Normal", [15]="Heroic", [16]="Mythic" }
local TYPE_VALUES = { "Bar", "Text", "Icon" }

local LIST_ROW_H  = 44
local FORM_PAD    = 10

-- ═══════════════════════════════════════════════════════════════════════════
-- Widget helpers
-- ═══════════════════════════════════════════════════════════════════════════

local function ApplyBackdrop(f, bg, border)
    local b = bg or C_BG
    local e = border or C_BORDER
    f:SetBackdrop(FORM_BACKDROP)
    f:SetBackdropColor(b[1], b[2], b[3], b[4] or 0.85)
    f:SetBackdropBorderColor(e[1], e[2], e[3], e[4] or 1)
end

local function MakeLabel(parent, text, cr, cg, cb)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fs:SetText(text or "")
    fs:SetTextColor(cr or C_GREY[1], cg or C_GREY[2], cb or C_GREY[3], 1)
    return fs
end

local function MakeEditBox(parent, w, numeric, hint)
    local f = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    f:SetSize(w, 22)
    ApplyBackdrop(f, {0.08,0.08,0.08,0.9}, C_BORDER)

    local eb = CreateFrame("EditBox", nil, f)
    eb:SetPoint("TOPLEFT",     f, "TOPLEFT",     4, -3)
    eb:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, 3)
    eb:SetAutoFocus(false)
    eb:SetFontObject("GameFontHighlightSmall")
    if numeric then eb:SetNumeric(true) end

    if hint then
        local ht = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        ht:SetAllPoints(eb)
        ht:SetTextColor(0.4, 0.4, 0.4, 1)
        ht:SetText(hint)
        ht:SetJustifyH("LEFT")
        eb:SetScript("OnTextChanged", function(self)
            ht:SetShown(self:GetText() == "")
        end)
        eb:SetScript("OnEditFocusGained", function(self)
            ht:Hide()
        end)
        eb:SetScript("OnEditFocusLost", function(self)
            ht:SetShown(self:GetText() == "")
        end)
    end

    f.editbox = eb
    -- Forward common methods
    function f:GetText()    return eb:GetText()    end
    function f:SetText(t)   eb:SetText(t or "")   end
    function f:SetMaxLetters(n) eb:SetMaxLetters(n) end
    function f:SetFocus()   eb:SetFocus()          end
    return f
end

local function MakeCycleBtn(parent, values, labels, w)
    local idx = 1
    local tR, tG, tB = C_PURPLE[1], C_PURPLE[2], C_PURPLE[3]
    local f = CreateFrame("Button", nil, parent, "BackdropTemplate")
    f:SetSize(w or 70, 22)
    ApplyBackdrop(f, {0.10,0.08,0.14,0.9}, {tR*0.75, tG*0.75, tB*0.75, 1})

    local txt = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    txt:SetPoint("CENTER")
    txt:SetText((labels or values)[idx])
    txt:SetTextColor(tR, tG, tB, 1)

    f:SetScript("OnClick", function(self)
        idx = (idx % #values) + 1
        txt:SetText((labels or values)[idx])
    end)
    f:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(1, 0.8, 0.2, 1)
    end)
    f:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(tR*0.75, tG*0.75, tB*0.75, 1)
    end)

    function f:GetValue() return values[idx] end
    function f:GetLabel() return (labels or values)[idx] end
    function f:Reset()
        idx = 1
        txt:SetText((labels or values)[idx])
    end
    function f:SetByValue(v)
        for i, val in ipairs(values) do
            if val == v then
                idx = i
                txt:SetText((labels or values)[idx])
                return
            end
        end
    end
    function f:SetThemeColor(r, g, b)
        tR, tG, tB = r, g, b
        txt:SetTextColor(r, g, b, 1)
        ApplyBackdrop(self, {0.10,0.08,0.14,0.9}, {r*0.75, g*0.75, b*0.75, 1})
    end
    return f
end

local function MakeActionBtn(parent, text, w, h, r, g, b)
    local tR, tG, tB = r or C_PURPLE[1], g or C_PURPLE[2], b or C_PURPLE[3]
    local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
    btn:SetSize(w or 90, h or 24)
    ApplyBackdrop(btn, {0.10,0.08,0.12,0.9}, {tR, tG, tB, 1})

    local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    lbl:SetPoint("CENTER")
    lbl:SetText(text)
    lbl:SetTextColor(0.9, 0.9, 0.9, 1)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.18, 0.12, 0.22, 0.9)
        self:SetBackdropBorderColor(1, 1, 1, 1)
        lbl:SetTextColor(1, 1, 1, 1)
    end)
    btn:SetScript("OnLeave", function(self)
        ApplyBackdrop(self, {0.10,0.08,0.12,0.9}, {tR, tG, tB, 1})
        lbl:SetTextColor(0.9, 0.9, 0.9, 1)
    end)
    function btn:SetThemeColor(nr, ng, nb)
        tR, tG, tB = nr, ng, nb
        ApplyBackdrop(self, {0.10,0.08,0.12,0.9}, {nr, ng, nb, 1})
    end
    return btn
end

local function MakeSectionHeader(parent, text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(C_PURPLE[1], C_PURPLE[2], C_PURPLE[3], 0.4)
    line:SetHeight(1)

    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    lbl:SetText("|cFFBB66FF" .. text .. "|r")
    lbl._sectionText = text
    lbl._line = line

    return lbl, line
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Info helpers
-- ═══════════════════════════════════════════════════════════════════════════

local function GetSpellName(spellID)
    if not spellID or spellID == 0 then return nil end
    local ok, info = pcall(C_Spell.GetSpellInfo, spellID)
    return (ok and info and info.name) or nil
end

local function GetEncounterName(encID)
    if not encID or encID == 0 then return nil end
    local ok, name = pcall(EJ_GetEncounterInfo, encID)
    return (ok and name and name ~= "") and name or nil
end

local function ParseTimers(str)
    local t = {}
    for v in (str or ""):gmatch("[^,%s]+") do
        local n = tonumber(v)
        if n then t[#t+1] = n end
    end
    return t
end

local function FormatTimerList(times)
    if #times == 0 then return "none" end
    local parts = {}
    for _, t in ipairs(times) do parts[#parts+1] = tostring(t).."s" end
    local str = table.concat(parts, ", ")
    if #str > 60 then str = str:sub(1,58) .. "..." end
    return str
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Row pool (list rows)
-- ═══════════════════════════════════════════════════════════════════════════

local rowPool = {}

local function GetOrCreateRow(content, i)
    if rowPool[i] then return rowPool[i] end
    local row = CreateFrame("Frame", nil, content, "BackdropTemplate")
    row:SetHeight(LIST_ROW_H)

    row.check = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
    row.check:SetSize(20, 20)
    row.check:SetPoint("LEFT", row, "LEFT", 6, 0)

    -- Spell icon
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetSize(32, 32)
    row.icon:SetPoint("LEFT", row.check, "RIGHT", 6, 0)
    row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)

    row.info = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.info:SetPoint("LEFT", row.icon, "RIGHT", 6, 2)
    row.info:SetJustifyH("LEFT")
    row.info:SetWordWrap(false)

    row.sub = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.sub:SetPoint("BOTTOMLEFT", row.icon, "BOTTOMRIGHT", 6, 2)
    row.sub:SetJustifyH("LEFT")
    row.sub:SetTextColor(0.55, 0.55, 0.55, 1)

    row.del = MakeActionBtn(row, "X", 26, 20, C_RED[1], C_RED[2], C_RED[3])
    row.del:SetPoint("RIGHT", row, "RIGHT", -6, 0)

    rowPool[i] = row
    return row
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Panel builder
-- ═══════════════════════════════════════════════════════════════════════════

local function BuildCustomAlertsPanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetAllPoints(parent)

    local y = -FORM_PAD

    -- ───────────────────────────────────────────────────────────────────────
    -- SECTION: Add alert
    -- ───────────────────────────────────────────────────────────────────────
    local hdrLbl, hdrLine = MakeSectionHeader(panel, " Add Custom Alert ")
    hdrLbl:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)
    hdrLine:SetPoint("LEFT",  hdrLbl, "RIGHT",  4, 0)
    hdrLine:SetPoint("RIGHT", panel,  "RIGHT", -FORM_PAD, 0)
    hdrLine:SetPoint("TOP",   hdrLbl, "CENTER", 0, 0)
    y = y - 20

    -- Form container
    local form = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    form:SetPoint("TOPLEFT",  panel, "TOPLEFT",  FORM_PAD, y)
    form:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -FORM_PAD, y)
    form:SetHeight(210)
    ApplyBackdrop(form, C_BG, C_BORDER)
    y = y - 214

    local fy = -8  -- y inside form

    -- ── Row 1 : EncID / SpellID / Label ────────────────────────────────────
    local lEnc = MakeLabel(form, "Encounter ID")
    lEnc:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebEnc = MakeEditBox(form, 72, true, "3181")
    ebEnc:SetPoint("TOPLEFT", lEnc, "BOTTOMLEFT", 0, -3)
    ebEnc:SetMaxLetters(10)

    local lSpell = MakeLabel(form, "Spell ID")
    lSpell:SetPoint("TOPLEFT", form, "TOPLEFT", 96, fy)
    local ebSpell = MakeEditBox(form, 90, true, "0")
    ebSpell:SetPoint("TOPLEFT", lSpell, "BOTTOMLEFT", 0, -3)

    local lLbl = MakeLabel(form, "Label")
    lLbl:SetPoint("TOPLEFT", form, "TOPLEFT", 202, fy)
    local ebLabel = MakeEditBox(form, 160, false, "Explosion")
    ebLabel:SetPoint("TOPLEFT", lLbl, "BOTTOMLEFT", 0, -3)
    ebLabel:SetMaxLetters(48)

    fy = fy - 42

    -- ── Row 2 : Type / Dur / Phase / Difficulty ─────────────────────────────
    local lType = MakeLabel(form, "Type")
    lType:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local btnType = MakeCycleBtn(form, TYPE_VALUES, nil, 58)
    btnType:SetPoint("TOPLEFT", lType, "BOTTOMLEFT", 0, -3)

    local lDur = MakeLabel(form, "Dur (s)")
    lDur:SetPoint("TOPLEFT", form, "TOPLEFT", 80, fy)
    local ebDur = MakeEditBox(form, 44, true, "5")
    ebDur:SetPoint("TOPLEFT", lDur, "BOTTOMLEFT", 0, -3)
    ebDur:SetText("5")

    local lPhase = MakeLabel(form, "Phase")
    lPhase:SetPoint("TOPLEFT", form, "TOPLEFT", 152, fy)
    local ebPhase = MakeEditBox(form, 38, true, "1")
    ebPhase:SetPoint("TOPLEFT", lPhase, "BOTTOMLEFT", 0, -3)
    ebPhase:SetText("1")

    local lDiff = MakeLabel(form, "Difficulty")
    lDiff:SetPoint("TOPLEFT", form, "TOPLEFT", 206, fy)
    local btnDiff = MakeCycleBtn(form, DIFF_VALUES, DIFF_LABELS, 74)
    btnDiff:SetPoint("TOPLEFT", lDiff, "BOTTOMLEFT", 0, -3)

    fy = fy - 42

    -- ── Row 3 : Timers ───────────────────────────────────────────────────────
    local lTimes = MakeLabel(form, "Timers — seconds from phase start, comma-separated  (e.g. 33, 53, 75, 95)")
    lTimes:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebTimes = MakeEditBox(form, 360, false, "33,53,75,95,117")
    ebTimes:SetPoint("TOPLEFT", lTimes, "BOTTOMLEFT", 0, -3)
    ebTimes:SetMaxLetters(300)
    fy = fy - 38

    -- ── Row 4 : TTS / TTSTimer / Countdown ─────────────────────────────────
    local lTTS = MakeLabel(form, "TTS  (blank = off)")
    lTTS:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebTTS = MakeEditBox(form, 158, false, "Explosion!")
    ebTTS:SetPoint("TOPLEFT", lTTS, "BOTTOMLEFT", 0, -3)

    local lTTST = MakeLabel(form, "TTS timer (s)")
    lTTST:SetPoint("TOPLEFT", form, "TOPLEFT", 178, fy)
    local ebTTSTimer = MakeEditBox(form, 52, true, "")
    ebTTSTimer:SetPoint("TOPLEFT", lTTST, "BOTTOMLEFT", 0, -3)

    local lCD = MakeLabel(form, "Countdown (s)")
    lCD:SetPoint("TOPLEFT", form, "TOPLEFT", 244, fy)
    local ebCD = MakeEditBox(form, 52, true, "")
    ebCD:SetPoint("TOPLEFT", lCD, "BOTTOMLEFT", 0, -3)

    fy = fy - 38

    -- ── Row 5 : Sound / Colors ───────────────────────────────────────────────
    local lSound = MakeLabel(form, "Sound  (LSM name)")
    lSound:SetPoint("TOPLEFT", form, "TOPLEFT", 8, fy)
    local ebSound = MakeEditBox(form, 168, false, "")
    ebSound:SetPoint("TOPLEFT", lSound, "BOTTOMLEFT", 0, -3)

    local lColors = MakeLabel(form, "Bar color  (R G B A)")
    lColors:SetPoint("TOPLEFT", form, "TOPLEFT", 192, fy)
    local ebColors = MakeEditBox(form, 168, false, "")
    ebColors:SetPoint("TOPLEFT", lColors, "BOTTOMLEFT", 0, -3)

    -- ───────────────────────────────────────────────────────────────────────
    -- Info / preview row  (below form)
    -- ───────────────────────────────────────────────────────────────────────
    local infoBox = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    infoBox:SetPoint("TOPLEFT",  panel, "TOPLEFT",  FORM_PAD, y)
    infoBox:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -FORM_PAD, y)
    infoBox:SetHeight(38)
    ApplyBackdrop(infoBox, {0.04,0.06,0.04,0.85}, {0.2,0.5,0.2,0.7})
    y = y - 42

    local infoIcon = infoBox:CreateTexture(nil, "ARTWORK")
    infoIcon:SetSize(28, 28)
    infoIcon:SetPoint("LEFT", infoBox, "LEFT", 6, 0)
    infoIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")

    local infoText = infoBox:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    infoText:SetPoint("LEFT",  infoIcon, "RIGHT", 6, 2)
    infoText:SetPoint("RIGHT", infoBox,  "RIGHT", -8, 0)
    infoText:SetJustifyH("LEFT")
    infoText:SetWordWrap(true)
    infoText:SetText("|cFF888888Enter an Encounter ID and Spell ID to see a preview.|r")

    local function UpdateInfoPreview()
        local encID   = tonumber(ebEnc:GetText())
        local spellID = tonumber(ebSpell:GetText())
        local times   = ParseTimers(ebTimes:GetText())
        local type_   = btnType:GetValue()
        local phase   = tonumber(ebPhase:GetText()) or 1
        local diff    = btnDiff:GetLabel()

        local spellName = GetSpellName(spellID)
        local encName   = GetEncounterName(encID)

        -- Update icon
        if spellID and spellID ~= 0 then
            local ok, si = pcall(C_Spell.GetSpellInfo, spellID)
            if ok and si and si.iconID then
                infoIcon:SetTexture(si.iconID)
            else
                infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
            end
        else
            infoIcon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
        end

        local line1 = ""
        if spellID and spellID ~= 0 then
            line1 = "|cFFFFD700Spell:|r " .. (spellName and ("|cFFFFFFFF"..spellName.."|r") or "|cFFFF4444Unknown spell "..spellID.."|r")
        else
            line1 = "|cFF888888No spell ID - will display as text only|r"
        end

        local line2 = ""
        if encID and encID ~= 0 then
            local eName = encName and ("|cFFFFFFFF"..encName.."|r") or ("|cFFFF8844enc "..encID.." (unknown)|r")
            line2 = "-> |cFFBB66FF" .. type_ .. "|r in " .. eName .. "  Phase |cFF88FF88" .. phase .. "|r  |cFFAAAAAA" .. diff .. "|r  |cFFFFD700" .. #times .. " timer(s):|r " .. FormatTimerList(times)
        else
            line2 = "|cFF888888Fill Encounter ID to see full preview.|r"
        end

        infoText:SetText(line1 .. "\n" .. line2)
    end

    -- Live update on key fields
    local function Throttle(eb)
        local f = eb.editbox or eb
        local orig = f:GetScript("OnTextChanged")
        f:SetScript("OnTextChanged", function(self, ...)
            if orig then orig(self, ...) end
            UpdateInfoPreview()
        end)
    end
    Throttle(ebEnc); Throttle(ebSpell); Throttle(ebTimes)
    -- For cycle buttons, wrap with post-hook
    local origTypeClick = btnType:GetScript("OnClick")
    btnType:SetScript("OnClick", function(self, ...)
        if origTypeClick then origTypeClick(self, ...) end
        UpdateInfoPreview()
    end)
    local origDiffClick = btnDiff:GetScript("OnClick")
    btnDiff:SetScript("OnClick", function(self, ...)
        if origDiffClick then origDiffClick(self, ...) end
        UpdateInfoPreview()
    end)

    -- ───────────────────────────────────────────────────────────────────────
    -- Action buttons + status line
    -- ───────────────────────────────────────────────────────────────────────
    local btnTest = MakeActionBtn(panel, "> Test Preview", 110, 26, 0.3, 1, 0.5)
    btnTest:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)

    local btnAdd = MakeActionBtn(panel, "+ Add Alert", 100, 26)
    btnAdd:SetPoint("LEFT", btnTest, "RIGHT", 8, 0)

    local statusFS = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    statusFS:SetPoint("LEFT", btnAdd, "RIGHT", 12, 0)
    statusFS:SetText("")

    local function SetStatus(msg, r, g, b)
        statusFS:SetText(msg)
        statusFS:SetTextColor(r or 1, g or 1, b or 1, 1)
        C_Timer.After(4, function() statusFS:SetText("") end)
    end

    y = y - 34

    -- ───────────────────────────────────────────────────────────────────────
    -- SECTION: Saved alerts list
    -- ───────────────────────────────────────────────────────────────────────
    local hdr2Lbl, hdr2Line = MakeSectionHeader(panel, " Saved Custom Alerts ")
    hdr2Lbl:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD, y)
    hdr2Line:SetPoint("LEFT",  hdr2Lbl, "RIGHT",  4, 0)
    hdr2Line:SetPoint("RIGHT", panel,   "RIGHT", -FORM_PAD, 0)
    hdr2Line:SetPoint("TOP",   hdr2Lbl, "CENTER", 0, 0)
    y = y - 18

    local emptyLabel = MakeLabel(panel, "No custom alerts yet - add one above.", 0.45, 0.45, 0.45)
    emptyLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", FORM_PAD + 4, y)

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     FORM_PAD, y)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, 6)

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    scrollFrame:SetScript("OnSizeChanged", function(self, w)
        content:SetWidth(w)
        for _, row in ipairs(rowPool) do row:SetWidth(w) end
    end)

    -- ── List refresh ──────────────────────────────────────────────────────
    local function RefreshList()
        local db = GetDB()
        emptyLabel:SetShown(#db == 0)
        scrollFrame:SetShown(#db > 0)

        for i, alert in ipairs(db) do
            local row = GetOrCreateRow(content, i)
            row:SetWidth(content:GetWidth())
            row:SetPoint("TOPLEFT", content, "TOPLEFT", 0, -(i-1)*(LIST_ROW_H+2))
            row:Show()

            local bg = (i % 2 == 0) and C_BG_ROW1 or C_BG_ROW2
            ApplyBackdrop(row, bg, C_BORDER)

            -- Icon
            local sName = GetSpellName(alert.spellID)
            if alert.spellID and alert.spellID ~= 0 then
                local ok, si = pcall(C_Spell.GetSpellInfo, alert.spellID)
                if ok and si and si.iconID then
                    row.icon:SetTexture(si.iconID)
                    row.icon:Show()
                else
                    row.icon:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")
                    row.icon:Show()
                end
            else
                row.icon:SetTexture("Interface\\Icons\\Ability_Warrior_VictoryRush")
                row.icon:Show()
            end

            -- Enabled checkbox
            row.check:SetChecked(alert.enabled)
            row.check:SetScript("OnClick", function(self)
                alert.enabled = self:GetChecked()
            end)

            -- Main line
            local encName = GetEncounterName(alert.encID)
            local nameStr = encName and ("|cFFFFFFFF"..encName.."|r") or ("enc:|cFFFFD700"..tostring(alert.encID).."|r")
            local spellStr = sName and ("|cFFFFFFFF"..sName.."|r") or
                ((alert.spellID and alert.spellID ~= 0) and tostring(alert.spellID) or "|cFF888888text|r")

            local w = content:GetWidth() - 100
            row.info:SetWidth(w)
            local infoLine = "|cFFBB66FF" .. (alert.label or "?") .. "|r  " .. nameStr .. "  " .. spellStr .. "  |cFF88FF88" .. (alert.type or "Bar") .. "|r"
            row.info:SetText(infoLine)

            -- Sub line
            local timesStr = FormatTimerList(alert.times or {})
            local extras = {}
            if alert.tts and alert.tts ~= "" then extras[#extras+1] = "TTS" end
            if alert.sound and alert.sound ~= "" then extras[#extras+1] = "Sound" end
            if alert.colors and alert.colors ~= "" then extras[#extras+1] = "Color" end
            local extraStr = (#extras > 0) and ("  |cFFFFD700[" .. table.concat(extras, ",") .. "]|r") or ""
            local numTimers = #(alert.times or {})
            local subLine = "Phase |cFF88FF88" .. tostring(alert.phase or 1) .. "|r  " .. (DIFF_MAP[alert.diff] or "?") .. "  |cFFFFD700" .. numTimers .. " timer(s):|r " .. timesStr .. extraStr

            row.sub:SetWidth(w)
            row.sub:SetText(subLine)

            -- Delete button
            local idx = i
            row.del:SetScript("OnClick", function()
                table.remove(db, idx)
                RefreshList()
                SetStatus("Alert removed.", C_RED[1], C_RED[2], C_RED[3])
            end)
        end

        for i = #db+1, #rowPool do rowPool[i]:Hide() end
        content:SetHeight(math.max(1, #db * (LIST_ROW_H+2)))
    end

    panel:SetScript("OnShow", function()
        RefreshList()
        UpdateInfoPreview()
    end)

    -- ── Test button ───────────────────────────────────────────────────────
    btnTest:SetScript("OnClick", function()
        local spellID = tonumber(ebSpell:GetText())
        local label   = ebLabel:GetText()
        if label == "" then label = spellID and GetSpellName(spellID) or "Test Alert" end
        local dur     = tonumber(ebDur:GetText()) or 5
        local phase   = tonumber(ebPhase:GetText()) or 1
        local type_   = btnType:GetValue()

        local prevDebug = RRT.Settings["Debug"]
        RRT.Settings["Debug"] = true
        RRT_NS.PlayedSound      = RRT_NS.PlayedSound      or {}
        RRT_NS.StartedCountdown = RRT_NS.StartedCountdown or {}
        RRT_NS.GlowStarted      = RRT_NS.GlowStarted      or {}
        RRT_NS.DefaultAlertID   = (RRT_NS.DefaultAlertID  or 10000) + 1

        local info = {
            notsticky    = true,
            BarOverwrite = (type_ == "Bar"),
            IconOverwrite= (type_ == "Icon"),
            TTSTimer     = tonumber(ebTTSTimer:GetText()) or dur,
            phase        = phase,
            id           = RRT_NS.DefaultAlertID,
            time         = dur,
            text         = label,
            spellID      = (spellID and spellID ~= 0) and spellID or nil,
            dur          = dur,
            IsAlert      = true,
        }
        local tts = ebTTS:GetText()
        if tts ~= "" then info.TTS = tts end
        local cd = tonumber(ebCD:GetText())
        if cd then info.countdown = cd end
        local snd = ebSound:GetText()
        if snd ~= "" then info.sound = snd end
        local col = ebColors:GetText()
        if col ~= "" then info.colors = col end

        RRT_NS:DisplayReminder(info)
        RRT.Settings["Debug"] = prevDebug
        SetStatus("Showing preview...", C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)

    -- ── Add button ────────────────────────────────────────────────────────
    btnAdd:SetScript("OnClick", function()
        local encID   = tonumber(ebEnc:GetText())
        local spellID = tonumber(ebSpell:GetText()) or 0
        local label   = ebLabel:GetText()
        local dur     = tonumber(ebDur:GetText()) or 5
        local phase   = tonumber(ebPhase:GetText()) or 1
        local diff    = btnDiff:GetValue()
        local times   = ParseTimers(ebTimes:GetText())
        local tts     = ebTTS:GetText()
        local ttsT    = tonumber(ebTTSTimer:GetText())
        local cd      = tonumber(ebCD:GetText())
        local snd     = ebSound:GetText()
        local col     = ebColors:GetText()

        if not encID or encID == 0 then
            SetStatus("! Encounter ID is required.", C_RED[1], C_RED[2], C_RED[3]); return
        end
        if #times == 0 then
            SetStatus("! At least one timer is required.", C_RED[1], C_RED[2], C_RED[3]); return
        end
        if label == "" then
            label = GetSpellName(spellID) or (spellID ~= 0 and tostring(spellID) or "Alert")
        end

        local entry = {
            id      = NextID(),
            encID   = encID,
            spellID = spellID,
            label   = label,
            type    = btnType:GetValue(),
            dur     = dur,
            phase   = phase,
            diff    = diff,
            times   = times,
            enabled = true,
        }
        if tts  ~= "" then entry.tts       = tts  end
        if ttsT        then entry.ttsTimer  = ttsT end
        if cd          then entry.countdown = cd   end
        if snd  ~= "" then entry.sound     = snd  end
        if col  ~= "" then entry.colors    = col  end

        GetDB()[#GetDB()+1] = entry

        -- Reset form
        ebEnc:SetText(""); ebSpell:SetText(""); ebLabel:SetText("")
        ebTimes:SetText(""); ebDur:SetText("5"); ebPhase:SetText("1")
        ebTTS:SetText(""); ebTTSTimer:SetText(""); ebCD:SetText("")
        ebSound:SetText(""); ebColors:SetText("")
        btnType:Reset(); btnDiff:Reset()

        RefreshList()
        UpdateInfoPreview()

        local encName = GetEncounterName(encID)
        local where = encName or ("enc "..encID)
        SetStatus("Added to " .. where .. " - Phase " .. phase .. " (" .. #times .. " timers)", C_GREEN[1], C_GREEN[2], C_GREEN[3])
    end)

    -- ── Theme color support ───────────────────────────────────────────────
    local function GetThemeRGB()
        local c = (RRT and RRT.Settings and RRT.Settings.TabSelectionColor) or {0.733, 0.400, 1.000, 1}
        return c[1], c[2], c[3]
    end

    local function ApplyTheme(r, g, b)
        local hex = string.format("%02X%02X%02X", math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
        hdrLbl:SetText("|cFF" .. hex .. hdrLbl._sectionText .. "|r")
        hdrLbl._line:SetColorTexture(r, g, b, 0.4)
        hdr2Lbl:SetText("|cFF" .. hex .. hdr2Lbl._sectionText .. "|r")
        hdr2Lbl._line:SetColorTexture(r, g, b, 0.4)
        btnType:SetThemeColor(r, g, b)
        btnDiff:SetThemeColor(r, g, b)
        btnAdd:SetThemeColor(r, g, b)
    end

    ApplyTheme(GetThemeRGB())

    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b, a)
        ApplyTheme(r, g, b)
    end)

    return panel
end

-- ═══════════════════════════════════════════════════════════════════════════
-- Export  (RRT_NS.UI not yet initialized at this load stage)
-- ═══════════════════════════════════════════════════════════════════════════
RRT_NS.BuildCustomEncounterAlertsPanel = BuildCustomAlertsPanel
