local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

-- ─────────────────────────────────────────────────────────────────────────────
-- CDNote — Panel UI
-- Left  : multiline EditBox (paste MRT note) + Import VMRT + Clear buttons
-- Right : rendered/formatted preview (DF:CreateScrollBox + DF:ReskinSlider)
-- ─────────────────────────────────────────────────────────────────────────────

local PANEL_LEFT_W = 450
local ROW_H        = 17
local SBAR_W       = 8   -- custom scrollbar width (edit side only)

-- ─── Custom scrollbar for the EditBox ScrollFrame ─────────────────────────────
-- (Raw ScrollFrames can't use DF:ReskinSlider — styled to match DF neutral theme)
local function MakeScrollBar(sf)
    local track = CreateFrame("Frame", nil, sf:GetParent(), "BackdropTemplate")
    track:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    track:SetBackdropColor(0.08, 0.08, 0.10, 0.90)
    track:SetBackdropBorderColor(0, 0, 0, 0.6)
    track:SetWidth(SBAR_W)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    thumb:SetBackdropColor(0.45, 0.45, 0.45, 0.75)
    thumb:SetWidth(SBAR_W - 2)
    thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
    thumb:EnableMouse(true)

    local function Update()
        local trackH = track:GetHeight()
        local range = sf:GetVerticalScrollRange()
        if range <= 0 then
            thumb:SetHeight(trackH)
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
            return
        end
        local thumbH = math.max(16, trackH * trackH / (trackH + range))
        thumb:SetHeight(thumbH)
        local scroll = sf:GetVerticalScroll()
        local pos = -(scroll / range) * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, pos)
    end

    sf:SetScript("OnScrollRangeChanged", function() Update() end) -- SetScript to override Blizzard default that calls the removed ScrollingEdit_OnScrollRangeChanged
    sf:HookScript("OnVerticalScroll",    Update)

    -- Thumb drag
    local dragging, startY, startScroll = false, 0, 0
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging    = true
        startY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        startScroll = sf:GetVerticalScroll()
    end)
    local function StopDrag() dragging = false end
    thumb:SetScript("OnMouseUp",  StopDrag)
    thumb:SetScript("OnUpdate", function()
        if not dragging then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local range  = sf:GetVerticalScrollRange()
        local avail  = trackH - thumb:GetHeight()
        if avail <= 0 then return end
        sf:SetVerticalScroll(math.max(0, math.min(range, startScroll + (startY - curY) * range / avail)))
    end)

    -- Track click
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        local trackH = track:GetHeight()
        local curY  = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local bounds = { track:GetBoundsRect() }
        local topPx  = bounds[4]
        local frac   = math.max(0, math.min(1, (topPx - curY) / trackH))
        sf:SetVerticalScroll(frac * sf:GetVerticalScrollRange())
    end)

    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)

    return track
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Import Note popup (Viserio / raw MRT paste)
-- ─────────────────────────────────────────────────────────────────────────────

local ImportNotePopup   -- created once, reused
local SaveNotePopup     -- created once, reused

-- ─────────────────────────────────────────────────────────────────────────────
-- Main panel builder — called from Raid/UI.lua
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildCDNotePanel(panel)
    local Core                = RRT_NS.UI.Core
    local options_button_template = Core.options_button_template

    -- window_height - top offset(100) - bottom offset(22) = ~518
    local W = Core.window_width  - 130 - 12
    local H = Core.window_height - 100 - 22

    local rightX = PANEL_LEFT_W + 8
    local rightW = W - PANEL_LEFT_W - 8

    -- ── Left: Note Editor ────────────────────────────────────────────────────
    local BTN_H      = 20
    local BTN_PAD    = 4
    local LBL_H      = 18
    local editH      = H - LBL_H - BTN_H * 2 - BTN_PAD * 3

    local leftBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    leftBg:SetPoint("TOPLEFT",    panel, "TOPLEFT",    0, 0)
    leftBg:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    leftBg:SetWidth(PANEL_LEFT_W)
    DF:ApplyStandardBackdrop(leftBg)

    local editTopLabel = leftBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    editTopLabel:SetPoint("TOPLEFT", leftBg, "TOPLEFT", 6, -4)
    editTopLabel:SetText(L["cdn_paste_label"] or "Note (format MRT) :")
    editTopLabel:SetTextColor(1, 0.82, 0, 1)   -- yellow, same as section titles

    -- ScrollFrame for EditBox
    local editScroll = CreateFrame("ScrollFrame", "RRTCDNoteEditScroll", leftBg)
    editScroll:SetPoint("TOPLEFT",    leftBg, "TOPLEFT",    4, -LBL_H)
    editScroll:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 4, BTN_H * 2 + BTN_PAD * 3)
    editScroll:SetWidth(PANEL_LEFT_W - 4 - SBAR_W - 6)
    editScroll:EnableMouseWheel(true)
    editScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local editBox = CreateFrame("EditBox", "RRTCDNoteEditBox", editScroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:EnableKeyboard(true)
    editBox:SetMaxLetters(0)
    editBox:SetFontObject(ChatFontNormal)
    editBox:SetWidth(PANEL_LEFT_W - 4 - SBAR_W - 6)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    -- Keep cursor visible while typing: scroll down if cursor goes past the bottom
    editBox:SetScript("OnCursorChanged", function(self, x, y, w, h)
        local sf = editScroll
        local top    = sf:GetVerticalScroll()
        local bottom = top + sf:GetHeight()
        local curBot = y + h  -- y is negative (top-down)
        if -y < top then
            sf:SetVerticalScroll(math.max(0, -y))
        elseif -curBot > bottom then
            sf:SetVerticalScroll(-curBot - sf:GetHeight())
        end
    end)
    editScroll:SetScrollChild(editBox)
    editScroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)

    -- Neutral-gray scrollbar for the edit area (anchor-based height tracks leftBg)
    local editSbar = MakeScrollBar(editScroll)
    editSbar:SetPoint("TOPLEFT",    leftBg, "TOPLEFT",    PANEL_LEFT_W - SBAR_W - 4, -LBL_H)
    editSbar:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", PANEL_LEFT_W - SBAR_W - 4,  BTN_H * 2 + BTN_PAD * 3)
    editSbar:SetWidth(SBAR_W)

    -- ── Import popup opener ───────────────────────────────────────────────────
    local function OpenImportPopup()
        if not ImportNotePopup then
            local popup = DF:CreateSimplePanel(RRT_NS.UI.Core.RRTUI, 600, 420,
                "Import Note Viserio / MRT", "RRTCDNoteImport", { DontRightClickClose = true })
            popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            popup:SetFrameLevel(100)
            ImportNotePopup = popup

            local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -12)
            lbl:SetText("Colle le code Viserio ou la note MRT brute :")
            lbl:SetTextColor(1, 0.82, 0, 1)

            -- text area (NewSpecialLuaEditorEntry = scrollable multiline editbox)
            popup.textBox = DF:NewSpecialLuaEditorEntry(popup, 280, 80, _, "RRTCDNoteImportBox", true, false, true)
            popup.textBox:SetPoint("TOPLEFT",    popup, "TOPLEFT",    10, -28)
            popup.textBox:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, BTN_H * 2 + BTN_PAD * 3)
            DF:ApplyStandardBackdrop(popup.textBox)
            DF:ReskinSlider(popup.textBox.scroll)
            popup.textBox:SetScript("OnMouseDown", function(self) self:SetFocus() end)

            -- Row 1 (bottom): [Annuler]  [Confirmer]
            local btnConfirm = DF:CreateButton(popup, function()
                local text = popup.textBox:GetText()
                if text and text ~= "" then
                    editBox:SetText(text)
                    if RRT and RRT.CDNote then RRT.CDNote.noteText = text end
                    if panel._Rebuild then panel._Rebuild() end
                end
                popup.textBox:SetText("")
                popup:Hide()
            end, 110, BTN_H, "Confirmer")
            btnConfirm:SetTemplate(options_button_template)
            btnConfirm:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, BTN_PAD)

            local btnCancel = DF:CreateButton(popup, function()
                popup.textBox:SetText("")
                popup:Hide()
            end, 80, BTN_H, "Annuler")
            btnCancel:SetTemplate(options_button_template)
            btnCancel:SetPoint("RIGHT", btnConfirm, "LEFT", -4, 0)

            -- Row 2 (above row 1): [Import depuis MRT (auto)]
            local btnMRT = DF:CreateButton(popup, function()
                local ok, vmrt = pcall(function() return VMRT end)
                if ok and vmrt and vmrt.Note and vmrt.Note.Text1 and vmrt.Note.Text1 ~= "" then
                    popup.textBox:SetText(vmrt.Note.Text1)
                    popup.textBox:SetFocus()
                else
                    DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r MRT non détecté ou note vide.")
                end
            end, 180, BTN_H, "Import depuis MRT (auto)")
            btnMRT:SetTemplate(options_button_template)
            btnMRT:SetPoint("BOTTOMLEFT", popup, "BOTTOMLEFT", 10, BTN_PAD + BTN_H + BTN_PAD)
        end

        ImportNotePopup.textBox:SetText("")
        ImportNotePopup.textBox:SetFocus()
        ImportNotePopup:Show()
    end

    -- DF-styled buttons
    local btnImport = DF:CreateButton(leftBg, function()
        OpenImportPopup()
    end, 120, BTN_H, L["cdn_import_vmrt"] or "Import VMRT")
    btnImport:SetTemplate(options_button_template)
    btnImport:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 4, BTN_PAD)

    local btnClear = DF:CreateButton(leftBg, function()
        editBox:SetText("")
        if RRT and RRT.CDNote then RRT.CDNote.noteText = "" end
        if panel._Rebuild then panel._Rebuild() end
    end, 60, BTN_H, L["cdn_clear"] or "Effacer")
    btnClear:SetTemplate(options_button_template)
    btnClear:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -4, BTN_PAD)

    -- ── Push buttons (row above Import/Clear) ────────────────────────────────
    local row2Y   = BTN_PAD + BTN_H + BTN_PAD  -- 28px from bottom
    local HALF_W  = math.floor((PANEL_LEFT_W - 4 - 4 - 4) / 2)  -- 2 equal buttons

    local function GetNoteText()
        return (RRT and RRT.CDNote and RRT.CDNote.noteText) or editBox:GetText()
    end

    -- Save note to SaveNote library with a custom name + date-time suffix
    local function AutoSaveNote(noteType, text, customName)
        if not text or text == "" or not RRT then return end
        RRT.CDNote                     = RRT.CDNote or {}
        RRT.CDNote.savedNotes          = RRT.CDNote.savedNotes or {}
        RRT.CDNote.savedNotes.all      = RRT.CDNote.savedNotes.all or {}
        RRT.CDNote.savedNotes.personal = RRT.CDNote.savedNotes.personal or {}

        local baseName = customName
        if not baseName or baseName:match("^%s*$") then
            -- fallback: extract first line
            baseName = ""
            for line in (text .. "\n"):gmatch("([^\n]*)\n") do
                local clean = line
                    :gsub("|T[^|]+|t", "")
                    :gsub("|c%x%x%x%x%x%x%x%x", "")
                    :gsub("|r", "")
                    :gsub("%s+", " ")
                    :match("^%s*(.-)%s*$")
                if clean and clean ~= "" then baseName = clean; break end
            end
            if baseName == "" then baseName = "Note" end
            if #baseName > 40 then baseName = baseName:sub(1, 40) .. "…" end
        end

        local name  = baseName .. " - " .. date("%d/%m/%y") .. " - " .. date("%H:%M")
        local notes = RRT.CDNote.savedNotes[noteType]
        for i, note in ipairs(notes) do
            if note.name == name then
                notes[i].text = text; notes[i].savedAt = time(); return
            end
        end
        table.insert(notes, { name = name, text = text, savedAt = time() })
    end

    -- Popup: ask for a save name before pushing
    local function ShowSaveNamePopup(text, onConfirm)
        if not SaveNotePopup then
            local popup = DF:CreateSimplePanel(Core.RRTUI, 340, 110,
                "Sauvegarder la note", "RRTSaveNoteNamePopup",
                { DontRightClickClose = true, NoScripts = true })
            popup:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
            popup:SetFrameLevel(100)
            SaveNotePopup = popup

            local lbl = popup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            lbl:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -30)
            lbl:SetText("Nom de la sauvegarde :")
            lbl:SetTextColor(1, 0.82, 0, 1)

            popup.nameInput = DF:CreateTextEntry(popup, function() end, 316, 20)
            popup.nameInput:SetTemplate(options_button_template)
            popup.nameInput:SetPoint("TOPLEFT", popup, "TOPLEFT", 10, -48)

            popup.btnConfirm = DF:CreateButton(popup, nil, 110, BTN_H, "Confirmer")
            popup.btnConfirm:SetTemplate(options_button_template)
            popup.btnConfirm:SetPoint("BOTTOMRIGHT", popup, "BOTTOMRIGHT", -10, BTN_PAD + 2)

            local btnCancel = DF:CreateButton(popup, function() popup:Hide() end,
                80, BTN_H, "Annuler")
            btnCancel:SetTemplate(options_button_template)
            btnCancel:SetPoint("RIGHT", popup.btnConfirm, "LEFT", -4, 0)
        end

        -- Pre-fill with first meaningful line of the note (stripped)
        local suggestion = ""
        for line in (text .. "\n"):gmatch("([^\n]*)\n") do
            local clean = line
                :gsub("|T[^|]+|t", "")
                :gsub("|c%x%x%x%x%x%x%x%x", "")
                :gsub("|r", "")
                :gsub("%s+", " ")
                :match("^%s*(.-)%s*$")
            if clean and clean ~= "" then suggestion = clean; break end
        end
        if #suggestion > 40 then suggestion = suggestion:sub(1, 40) end
        SaveNotePopup.nameInput:SetText(suggestion ~= "" and suggestion or "Note")

        -- Wire confirm (re-set each time so onConfirm captures the right action)
        SaveNotePopup.btnConfirm:SetScript("OnClick", function()
            local name = SaveNotePopup.nameInput:GetText()
            if not name or name:match("^%s*$") then
                DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r Entrez un nom d'abord.")
                return
            end
            onConfirm(name)
            SaveNotePopup:Hide()
        end)

        SaveNotePopup:Show()
    end

    local btnPushAll = DF:CreateButton(leftBg, function()
        local text = GetNoteText()
        if not text or text == "" then return end
        ShowSaveNamePopup(text, function(name)
            AutoSaveNote("all", text, name)
            RRT_NS.Reminder = text
            RRT_NS:ProcessReminder()
            RRT_NS:UpdateReminderFrame(false, true)
            RRT_NS:FireCallback("RRT_REMINDER_CHANGED", RRT_NS.PersonalReminder, RRT_NS.Reminder)
        end)
    end, HALF_W, BTN_H, L["cdn_push_all"] or "Push for All")
    btnPushAll:SetTemplate(options_button_template)
    btnPushAll:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 4, row2Y)

    local btnPushPersonal = DF:CreateButton(leftBg, function()
        local text = GetNoteText()
        if not text or text == "" then return end
        ShowSaveNamePopup(text, function(name)
            AutoSaveNote("personal", text, name)
            RRT_NS.PersonalReminder = text
            RRT_NS:ProcessReminder()
            RRT_NS:UpdateReminderFrame(false, false, true)
            RRT_NS:FireCallback("RRT_REMINDER_CHANGED", RRT_NS.PersonalReminder, RRT_NS.Reminder)
        end)
    end, HALF_W, BTN_H, L["cdn_push_personal"] or "Push Personal")
    btnPushPersonal:SetTemplate(options_button_template)
    btnPushPersonal:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 4 + HALF_W + 4, row2Y)

    -- ── Right: Rendered Note Display (plain ScrollFrame + matching custom scrollbar) ──
    local rightBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    rightBg:SetPoint("TOPLEFT",     panel, "TOPLEFT",     rightX, 0)
    rightBg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0,      0)
    DF:ApplyStandardBackdrop(rightBg)

    local dispTopLabel = rightBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dispTopLabel:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 6, -4)
    dispTopLabel:SetText(L["cdn_preview_label"] or "Aperçu :")
    dispTopLabel:SetTextColor(1, 0.82, 0, 1)

    local dispContentW = rightW - 4 - SBAR_W - 6   -- usable label width

    local dispScroll = CreateFrame("ScrollFrame", "RRTCDNoteDispScroll", rightBg)
    dispScroll:SetPoint("TOPLEFT",     rightBg, "TOPLEFT",     4,             -LBL_H)
    dispScroll:SetPoint("BOTTOMRIGHT", rightBg, "BOTTOMRIGHT", -(SBAR_W + 6), 0)
    dispScroll:EnableMouseWheel(true)
    dispScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local dispContent = CreateFrame("Frame", nil, dispScroll)
    dispContent:SetWidth(dispContentW)
    dispContent:SetHeight(1)
    dispScroll:SetScrollChild(dispContent)

    -- Custom scrollbar — same dark style as the edit side
    local dispSbar = MakeScrollBar(dispScroll)
    dispSbar:SetPoint("TOPRIGHT",    rightBg, "TOPRIGHT",    -4, -LBL_H)
    dispSbar:SetPoint("BOTTOMRIGHT", rightBg, "BOTTOMRIGHT", -4, 0)
    dispSbar:SetWidth(SBAR_W)

    -- Reusable line pool (WoW FontStrings can't be destroyed; pool avoids recreation)
    local dispLinePool = {}
    local function GetDispLine(i)
        if not dispLinePool[i] then
            local line = CreateFrame("Frame", nil, dispContent)
            line:SetPoint("TOPLEFT", dispContent, "TOPLEFT", 0, -((i - 1) * ROW_H))
            line:SetHeight(ROW_H)
            line:SetWidth(dispContentW)
            local fs = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetJustifyH("LEFT")
            line.label = fs
            dispLinePool[i] = line
        end
        return dispLinePool[i]
    end

    -- ── Rebuild helper ───────────────────────────────────────────────────────
    local function RebuildDisplay()
        local lines    = {}
        local noteText = (RRT and RRT.CDNote and RRT.CDNote.noteText) or editBox:GetText()

        if noteText == "" then
            table.insert(lines, {
                text   = L["cdn_empty"] or "Colle une note MRT dans l'éditeur à gauche.",
                r=0.45, g=0.45, b=0.45, indent=0,
            })
        else
            local rendered   = RRT_NS.CDNote.FormatNote(noteText)
            local playerName = (UnitName("player") or ""):lower()

            for line in (rendered.."\n"):gmatch("([^\n]*)\n") do
                if line:match("^%s*$") then
                    table.insert(lines, { text="", r=1, g=1, b=1, indent=0 })
                else
                    local plain = line
                        :gsub("|T[^|]+|t", "")
                        :gsub("|c%x%x%x%x%x%x%x%x", "")
                        :gsub("|r", "")
                        :gsub("%s+", " ")
                        :match("^%s*(.-)%s*$")

                    local isSection  = plain:len() >= 3
                        and plain:match("%u")
                        and not plain:match("%l")
                        and plain:match("^[%u%s%d%p]+$")
                    local isBullet   = line:match("^%s*%*")
                    local isNumbered = line:match("^%s*%d+%.")

                    if isSection then
                        table.insert(lines, { text="", r=1, g=1, b=1, indent=0 })
                        table.insert(lines, { text="|cFFFFAA00"..plain.."|r", r=1, g=1, b=1, indent=0 })
                    elseif isBullet then
                        local content = line:match("^%s*%*%s*(.-)%s*$") or line
                        table.insert(lines, { text="• "..content, r=0.90, g=0.90, b=0.90, indent=12 })
                    elseif isNumbered then
                        table.insert(lines, { text=line, r=0.88, g=0.88, b=0.88, indent=8 })
                    else
                        local plainLow  = plain:lower():gsub("(%a+)%-[%a]+", "%1")
                        local isPersonal = playerName ~= "" and plainLow:find(playerName, 1, true)
                        if isPersonal then
                            table.insert(lines, { text=line, r=1, g=0.88, b=0.30, indent=8 })
                        else
                            table.insert(lines, { text=line, r=0.88, g=0.88, b=0.88, indent=8 })
                        end
                    end
                end
            end
        end

        for i, entry in ipairs(lines) do
            local line = GetDispLine(i)
            line:Show()
            line.label:ClearAllPoints()
            line.label:SetPoint("LEFT", line, "LEFT", 4 + (entry.indent or 0), 0)
            line.label:SetWidth(dispContentW - 4 - (entry.indent or 0))
            line.label:SetText(entry.text)
            line.label:SetTextColor(entry.r, entry.g, entry.b, 1)
        end
        for i = #lines + 1, #dispLinePool do
            dispLinePool[i]:Hide()
        end
        dispContent:SetHeight(math.max(1, #lines * ROW_H))
        dispScroll:UpdateScrollChildRect()
        dispScroll:SetVerticalScroll(0)
    end

    panel._Rebuild = RebuildDisplay

    -- Save noteText immediately on every keystroke; debounce only the visual rebuild
    local rebuildTimer = nil
    editBox:SetScript("OnTextChanged", function(self)
        if RRT and RRT.CDNote then RRT.CDNote.noteText = self:GetText() end
        if rebuildTimer then rebuildTimer:Cancel() end
        rebuildTimer = C_Timer.NewTimer(1.2, function()
            rebuildTimer = nil
            RebuildDisplay()
        end)
    end)

    -- Sync on show
    panel:HookScript("OnShow", function()
        local saved = (RRT and RRT.CDNote and RRT.CDNote.noteText) or ""
        if editBox:GetText() ~= saved then
            editBox:SetText(saved)
        end
        RebuildDisplay()
    end)
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.BuildCDNotePanel = BuildCDNotePanel
