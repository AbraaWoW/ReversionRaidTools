local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

-- ─────────────────────────────────────────────────────────────────────────────
-- SaveNote — dropdown (All / Personal) + list + right preview
-- ─────────────────────────────────────────────────────────────────────────────

local LIST_ROW_H = 20
local DISP_ROW_H = 17
local SBAR_W     = 8
local BTN_H      = 20
local BTN_PAD    = 4
local LBL_H      = 18
local DROP_H     = 20

-- ── Custom scrollbar (same dark style as NotePanel) ──────────────────────────
local function MakeScrollBar(sf)
    local track = CreateFrame("Frame", nil, sf:GetParent(), "BackdropTemplate")
    track:SetBackdrop({ bgFile   = "Interface\\Buttons\\WHITE8X8",
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
        local range  = sf:GetVerticalScrollRange()
        if range <= 0 then
            thumb:SetHeight(math.max(1, trackH))
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
            return
        end
        local thumbH = math.max(16, trackH * trackH / (trackH + range))
        thumb:SetHeight(thumbH)
        local pos = -(sf:GetVerticalScroll() / range) * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, pos)
    end

    sf:HookScript("OnVerticalScroll",     Update)
    sf:HookScript("OnScrollRangeChanged", Update)

    local dragging, startY, startScroll = false, 0, 0
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging    = true
        startY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        startScroll = sf:GetVerticalScroll()
    end)
    thumb:SetScript("OnMouseUp", function() dragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not dragging then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local range  = sf:GetVerticalScrollRange()
        local avail  = trackH - thumb:GetHeight()
        if avail <= 0 then return end
        sf:SetVerticalScroll(math.max(0, math.min(range,
            startScroll + (startY - curY) * range / avail)))
    end)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local bounds = { track:GetBoundsRect() }
        local topPx  = bounds[4]
        local frac   = math.max(0, math.min(1, (topPx - curY) / trackH))
        sf:SetVerticalScroll(frac * sf:GetVerticalScrollRange())
    end)
    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)
    return track
end

-- ── Storage helpers ───────────────────────────────────────────────────────────
local function EnsureStorage()
    if not RRT then return end
    RRT.CDNote                     = RRT.CDNote or {}
    RRT.CDNote.savedNotes          = RRT.CDNote.savedNotes or {}
    RRT.CDNote.savedNotes.all      = RRT.CDNote.savedNotes.all or {}
    RRT.CDNote.savedNotes.personal = RRT.CDNote.savedNotes.personal or {}
end

local function GetNoteList(noteType)
    EnsureStorage()
    return (RRT and RRT.CDNote and RRT.CDNote.savedNotes
            and RRT.CDNote.savedNotes[noteType]) or {}
end

-- ── Main panel builder ────────────────────────────────────────────────────────
local function BuildSaveNotePanel(panel)
    local Core                    = RRT_NS.UI.Core
    local options_button_template = Core.options_button_template
    local options_dropdown_template = Core.options_dropdown_template

    local W            = Core.window_width - 130 - 12  -- 908
    local PANEL_LEFT_W = math.floor((W - 8) / 2)       -- 450
    local rightX       = PANEL_LEFT_W + 8
    local rightW       = W - PANEL_LEFT_W - 8

    -- list top offset = title label + gap + dropdown + gap
    local LIST_TOP_Y = -(BTN_PAD + LBL_H + BTN_PAD + DROP_H + BTN_PAD)
    -- bottom area = Load/Delete row + padding
    local BOTTOM_H   = BTN_PAD + BTN_H + BTN_PAD

    -- ── Left panel ───────────────────────────────────────────────────────────
    local leftBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    leftBg:SetPoint("TOPLEFT",    panel, "TOPLEFT",    0, 0)
    leftBg:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 0, 0)
    leftBg:SetWidth(PANEL_LEFT_W)
    DF:ApplyStandardBackdrop(leftBg)

    local titleLbl = leftBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    titleLbl:SetPoint("TOPLEFT", leftBg, "TOPLEFT", 6, -BTN_PAD)
    titleLbl:SetText(L["savenote_title_all"] or "All Notes")
    titleLbl:SetTextColor(1, 0.82, 0, 1)

    -- ── State (forward-declared so dropdown onclick can reference them) ───────
    local noteType      = "all"
    local selectedIndex = nil
    local rowPool       = {}
    local RefreshList   -- forward declaration
    local RefreshPreview -- forward declaration

    -- ── Dropdown All / Personal ───────────────────────────────────────────────
    local DROPDOWN_OPTS = {
        { label = L["savenote_title_all"]      or "All Notes",      value = "all"      },
        { label = L["savenote_title_personal"] or "Personal Notes", value = "personal" },
    }

    local dropdown = DF:CreateDropDown(leftBg,
        function()
            local t = {}
            for _, opt in ipairs(DROPDOWN_OPTS) do
                local v = opt.value
                local lbl = opt.label
                tinsert(t, {
                    label   = lbl,
                    value   = v,
                    onclick = function(_, _, value)
                        noteType = value
                        titleLbl:SetText(value == "all"
                            and (L["savenote_title_all"]      or "All Notes")
                            or  (L["savenote_title_personal"] or "Personal Notes"))
                        selectedIndex = nil
                        if RefreshList    then RefreshList()        end
                        if RefreshPreview then RefreshPreview(nil)  end
                    end,
                })
            end
            return t
        end,
        "all", PANEL_LEFT_W - 8)
    dropdown:SetTemplate(options_dropdown_template)
    dropdown:SetPoint("TOPLEFT", leftBg, "TOPLEFT", 4, -(BTN_PAD + LBL_H + BTN_PAD))

    -- ── List ScrollFrame ──────────────────────────────────────────────────────
    local listContentW = PANEL_LEFT_W - 4 - SBAR_W - 6

    local listScroll = CreateFrame("ScrollFrame", nil, leftBg)
    listScroll:SetPoint("TOPLEFT",     leftBg, "TOPLEFT",     4,             LIST_TOP_Y)
    listScroll:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -(SBAR_W + 6), BOTTOM_H)
    listScroll:EnableMouseWheel(true)
    listScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local listContent = CreateFrame("Frame", nil, listScroll)
    listContent:SetWidth(listContentW)
    listContent:SetHeight(1)
    listScroll:SetScrollChild(listContent)

    local emptyLbl = listContent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    emptyLbl:SetPoint("TOP", listContent, "TOP", 0, -10)
    emptyLbl:SetText("|cFF666666" .. (L["savenote_empty"] or "Aucune note sauvegardée.") .. "|r")

    local listSbar = MakeScrollBar(listScroll)
    listSbar:SetPoint("TOPRIGHT",    leftBg, "TOPRIGHT",    -4, LIST_TOP_Y)
    listSbar:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -4, BOTTOM_H)
    listSbar:SetWidth(SBAR_W)

    -- ── Bottom buttons ────────────────────────────────────────────────────────
    local btnHalf = math.floor((PANEL_LEFT_W - 4 - 4 - 4) / 2)

    local btnDelete = DF:CreateButton(leftBg, nil, btnHalf, BTN_H,
        L["savenote_delete"] or "Supprimer")
    btnDelete:SetTemplate(options_button_template)
    btnDelete:SetPoint("BOTTOMRIGHT", leftBg, "BOTTOMRIGHT", -4, BTN_PAD)

    local btnLoad = DF:CreateButton(leftBg, nil, btnHalf, BTN_H,
        L["savenote_load"] or "Charger")
    btnLoad:SetTemplate(options_button_template)
    btnLoad:SetPoint("BOTTOMLEFT", leftBg, "BOTTOMLEFT", 4, BTN_PAD)

    -- ── Right panel — Preview ─────────────────────────────────────────────────
    local rightBg = CreateFrame("Frame", nil, panel, "BackdropTemplate")
    rightBg:SetPoint("TOPLEFT",     panel, "TOPLEFT",     rightX, 0)
    rightBg:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", 0,      0)
    DF:ApplyStandardBackdrop(rightBg)

    local dispTopLabel = rightBg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dispTopLabel:SetPoint("TOPLEFT", rightBg, "TOPLEFT", 6, -BTN_PAD)
    dispTopLabel:SetText(L["cdn_preview_label"] or "Aperçu :")
    dispTopLabel:SetTextColor(1, 0.82, 0, 1)

    local dispContentW = rightW - 4 - SBAR_W - 6

    local PUSH_BOTTOM_H = BTN_PAD + BTN_H + BTN_PAD

    local dispScroll = CreateFrame("ScrollFrame", "RRTSaveNoteDispScroll", rightBg)
    dispScroll:SetPoint("TOPLEFT",     rightBg, "TOPLEFT",     4,             -LBL_H)
    dispScroll:SetPoint("BOTTOMRIGHT", rightBg, "BOTTOMRIGHT", -(SBAR_W + 6), PUSH_BOTTOM_H)
    dispScroll:EnableMouseWheel(true)
    dispScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local dispContent = CreateFrame("Frame", nil, dispScroll)
    dispContent:SetWidth(dispContentW)
    dispContent:SetHeight(1)
    dispScroll:SetScrollChild(dispContent)

    local dispSbar = MakeScrollBar(dispScroll)
    dispSbar:SetPoint("TOPRIGHT",    rightBg, "TOPRIGHT",    -4, -LBL_H)
    dispSbar:SetPoint("BOTTOMRIGHT", rightBg, "BOTTOMRIGHT", -4, PUSH_BOTTOM_H)
    dispSbar:SetWidth(SBAR_W)

    -- ── Push buttons (bottom of preview panel) ────────────────────────────────
    local pushHalf = math.floor((rightW - 4 - 4 - 4) / 2)

    local function GetSelectedText()
        if not selectedIndex then return nil end
        local notes = GetNoteList(noteType)
        return notes[selectedIndex] and notes[selectedIndex].text or nil
    end

    local btnPushAll = DF:CreateButton(rightBg, function()
        local text = GetSelectedText()
        if not text or text == "" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " ..
                (L["savenote_no_selection"] or "Sélectionnez une note d'abord."))
            return
        end
        RRT_NS.Reminder = text
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(false, true)
        RRT_NS:FireCallback("RRT_REMINDER_CHANGED", RRT_NS.PersonalReminder, RRT_NS.Reminder)
    end, pushHalf, BTN_H, L["cdn_push_all"] or "Push for All")
    btnPushAll:SetTemplate(options_button_template)
    btnPushAll:SetPoint("BOTTOMLEFT", rightBg, "BOTTOMLEFT", 4, BTN_PAD)

    local btnPushPersonal = DF:CreateButton(rightBg, function()
        local text = GetSelectedText()
        if not text or text == "" then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " ..
                (L["savenote_no_selection"] or "Sélectionnez une note d'abord."))
            return
        end
        RRT_NS.PersonalReminder = text
        RRT_NS:ProcessReminder()
        RRT_NS:UpdateReminderFrame(false, false, true)
        RRT_NS:FireCallback("RRT_REMINDER_CHANGED", RRT_NS.PersonalReminder, RRT_NS.Reminder)
    end, pushHalf, BTN_H, L["cdn_push_personal"] or "Push Personal")
    btnPushPersonal:SetTemplate(options_button_template)
    btnPushPersonal:SetPoint("BOTTOMLEFT", rightBg, "BOTTOMLEFT", 4 + pushHalf + 4, BTN_PAD)

    local dispLinePool = {}
    local function GetDispLine(i)
        if not dispLinePool[i] then
            local line = CreateFrame("Frame", nil, dispContent)
            line:SetPoint("TOPLEFT", dispContent, "TOPLEFT", 0, -((i - 1) * DISP_ROW_H))
            line:SetHeight(DISP_ROW_H)
            line:SetWidth(dispContentW)
            local fs = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            fs:SetJustifyH("LEFT")
            line.label = fs
            dispLinePool[i] = line
        end
        return dispLinePool[i]
    end

    -- ── Preview renderer (same logic as NotePanel RebuildDisplay) ─────────────
    RefreshPreview = function(text)
        local lines = {}

        if not text or text == "" then
            table.insert(lines, {
                text = "|cFF555555" .. (L["cdn_empty"] or "Sélectionnez une note pour voir l'aperçu.") .. "|r",
                r=1, g=1, b=1, indent=0,
            })
        else
            local rendered   = RRT_NS.CDNote.FormatNote(text)
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
        dispContent:SetHeight(math.max(1, #lines * DISP_ROW_H))
        dispScroll:UpdateScrollChildRect()
        dispScroll:SetVerticalScroll(0)
    end

    -- ── Button callbacks ──────────────────────────────────────────────────────
    btnDelete:SetScript("OnClick", function()
        if not selectedIndex then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " ..
                (L["savenote_no_selection"] or "Sélectionnez une note d'abord."))
            return
        end
        local notes = GetNoteList(noteType)
        table.remove(notes, selectedIndex)
        selectedIndex = nil
        RefreshList()
        RefreshPreview(nil)
    end)

    btnLoad:SetScript("OnClick", function()
        if not selectedIndex then
            DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " ..
                (L["savenote_no_selection"] or "Sélectionnez une note d'abord."))
            return
        end
        local notes = GetNoteList(noteType)
        local note  = notes[selectedIndex]
        if not note then return end
        if noteType == "all" then
            if RRT then
                RRT.CDNote          = RRT.CDNote or {}
                RRT.CDNote.noteText = note.text
            end
        else
            RRT_NS.PersonalReminder = note.text
            RRT_NS:ProcessReminder()
            RRT_NS:UpdateReminderFrame(false, false, true)
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " ..
            (L["savenote_loaded"] or "Chargé : ") .. "|cFFFFFFFF" .. note.name .. "|r")
    end)

    -- ── RefreshList ───────────────────────────────────────────────────────────
    RefreshList = function()
        local notes = GetNoteList(noteType)
        local tc    = (RRT and RRT.Settings and RRT.Settings.TabSelectionColor)
                      or {0.639, 0.188, 0.788, 1}

        for i, note in ipairs(notes) do
            if not rowPool[i] then
                local row = CreateFrame("Button", nil, listContent, "BackdropTemplate")
                row:SetHeight(LIST_ROW_H)
                row:SetWidth(listContentW)
                row:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
                row:SetBackdropColor(0, 0, 0, 0)

                local sep = row:CreateTexture(nil, "BACKGROUND")
                sep:SetColorTexture(0.3, 0.3, 0.3, 0.25)
                sep:SetPoint("BOTTOMLEFT",  row, "BOTTOMLEFT",  0, 0)
                sep:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
                sep:SetHeight(1)

                local nameLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                nameLbl:SetPoint("LEFT",  row, "LEFT",  4,   0)
                nameLbl:SetPoint("RIGHT", row, "RIGHT", -64, 0)
                nameLbl:SetJustifyH("LEFT")
                row.nameLbl = nameLbl

                local dateLbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                dateLbl:SetPoint("RIGHT", row, "RIGHT", -2, 0)
                dateLbl:SetWidth(62)
                dateLbl:SetJustifyH("RIGHT")
                row.dateLbl = dateLbl

                rowPool[i] = row
            end

            local row    = rowPool[i]
            local curIdx = i

            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", listContent, "TOPLEFT", 0, -((i - 1) * LIST_ROW_H))
            row:Show()

            row.nameLbl:SetText(note.name)
            local d = (note.savedAt and note.savedAt > 0)
                      and date("%d/%m/%y", note.savedAt) or "?"
            row.dateLbl:SetText("|cFF888888" .. d .. "|r")

            if selectedIndex == i then
                row:SetBackdropColor(tc[1]*0.3, tc[2]*0.3, tc[3]*0.3, 0.85)
            else
                row:SetBackdropColor(0, 0, 0, 0)
            end

            row:SetScript("OnClick", function()
                selectedIndex = curIdx
                RefreshList()
                local n = GetNoteList(noteType)
                if n[curIdx] then RefreshPreview(n[curIdx].text) end
            end)
            row:SetScript("OnEnter", function(self)
                if selectedIndex ~= curIdx then self:SetBackdropColor(0.15, 0.15, 0.15, 0.6) end
            end)
            row:SetScript("OnLeave", function(self)
                if selectedIndex ~= curIdx then self:SetBackdropColor(0, 0, 0, 0) end
            end)
        end

        for i = #notes + 1, #rowPool do rowPool[i]:Hide() end
        if selectedIndex and selectedIndex > #notes then selectedIndex = nil end
        emptyLbl:SetShown(#notes == 0)
        listContent:SetHeight(math.max(1, #notes * LIST_ROW_H))
        listScroll:UpdateScrollChildRect()
    end

    panel:HookScript("OnShow", function()
        selectedIndex = nil
        RefreshList()
        RefreshPreview(nil)
    end)
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.BuildSaveNotePanel = BuildSaveNotePanel
