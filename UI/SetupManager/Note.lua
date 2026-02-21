local _, RRT = ...

-------------------------------------------------------------------------------
-- Note sub-tab
-- Create, save, load, and send notes to chat.
-------------------------------------------------------------------------------

local _noteEditor  = nil
local _titleEditor = nil

local FONT         = "Fonts\\FRIZQT__.TTF"
local PADDING      = 12
local ROW_HEIGHT   = 26
local COLOR_ACCENT = { 0.30, 0.72, 1.00 }
local COLOR_LABEL  = { 0.85, 0.85, 0.85 }
local COLOR_MUTED  = { 0.55, 0.55, 0.55 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }
local COLOR_SECTION  = { 0.06, 0.06, 0.06, 0.95 }
local COLOR_BORDER   = { 0.2,  0.2,  0.2,  1.0  }

local function RRT_Print(msg)
    print("|cFF33FF99[Reversion Raid Tools]|r " .. tostring(msg))
end

-------------------------------------------------------------------------------
-- DB
-------------------------------------------------------------------------------

local function EnsureNoteDB()
    if not RRTDB then return nil end
    RRTDB.Note = RRTDB.Note or {}
    local noteDB = RRTDB.Note
    if type(noteDB.text)        ~= "string" then noteDB.text        = ""  end
    if type(noteDB.title)       ~= "string" then noteDB.title       = ""  end
    if type(noteDB.saved)       ~= "table"  then noteDB.saved       = {}  end
    if type(noteDB.importText)  ~= "string" then noteDB.importText  = ""  end
    if type(noteDB.parsedText)  ~= "string" then noteDB.parsedText  = ""  end
    if type(noteDB.parsedStats) ~= "table"  then noteDB.parsedStats = {}  end
    return noteDB
end

-------------------------------------------------------------------------------
-- Note helpers
-------------------------------------------------------------------------------

local function NormalizeTitle(title)
    title = strtrim(tostring(title or ""))
    if title == "" then title = "Untitled" end
    return title
end

local function FindSavedNoteIndex(noteDB, title)
    local wanted = NormalizeTitle(title):lower()
    for i, item in ipairs(noteDB.saved) do
        if type(item) == "table" and type(item.title) == "string"
           and item.title:lower() == wanted then
            return i
        end
    end
    return nil
end

local function GetNoteText()
    local noteDB = EnsureNoteDB()
    if not noteDB then return "" end
    return noteDB.text or ""
end

local function SetNoteText(text)
    local noteDB = EnsureNoteDB()
    if noteDB then noteDB.text = tostring(text or "") end
end

local function GetNoteTitle()
    local noteDB = EnsureNoteDB()
    if not noteDB then return "" end
    return noteDB.title or ""
end

local function SetNoteTitle(title)
    local noteDB = EnsureNoteDB()
    if noteDB then noteDB.title = NormalizeTitle(title) end
end

local function GetSavedNoteTitles()
    local noteDB = EnsureNoteDB()
    if not noteDB then return {} end
    local titles = {}
    for _, item in ipairs(noteDB.saved) do
        if type(item) == "table" and type(item.title) == "string" and item.title ~= "" then
            table.insert(titles, item.title)
        end
    end
    table.sort(titles, function(a, b) return a:lower() < b:lower() end)
    return titles
end

local function SaveNamedNote(title, text)
    local noteDB = EnsureNoteDB()
    if not noteDB then return false end
    local finalTitle = NormalizeTitle(title or noteDB.title)
    local finalText  = tostring(text or noteDB.text or "")
    local idx = FindSavedNoteIndex(noteDB, finalTitle)
    if idx then
        noteDB.saved[idx].title     = finalTitle
        noteDB.saved[idx].text      = finalText
        noteDB.saved[idx].updatedAt = time()
    else
        table.insert(noteDB.saved, { title = finalTitle, text = finalText, updatedAt = time() })
    end
    noteDB.title = finalTitle
    noteDB.text  = finalText
    return true
end

local function LoadNamedNote(title)
    local noteDB = EnsureNoteDB()
    if not noteDB then return false end
    local idx = FindSavedNoteIndex(noteDB, title)
    if not idx then return false end
    local item = noteDB.saved[idx]
    noteDB.title = item.title or "Untitled"
    noteDB.text  = tostring(item.text or "")
    return true
end

local function DeleteNamedNote(title)
    local noteDB = EnsureNoteDB()
    if not noteDB then return false end
    local idx = FindSavedNoteIndex(noteDB, title)
    if not idx then return false end
    table.remove(noteDB.saved, idx)
    if noteDB.title and noteDB.title:lower() == NormalizeTitle(title):lower() then
        noteDB.title = ""; noteDB.text = ""
    end
    return true
end

local function ResolveChatChannel(mode)
    if mode and mode ~= "AUTO" then return mode end
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then
        return (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and "RAID_WARNING" or "RAID"
    end
    if IsInGroup() then return "PARTY" end
    return "SAY"
end

local function SendChatLine(message, channel)
    if not message or message == "" then return false end
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(message, channel)
    else
        SendChatMessage(message, channel)
    end
    return true
end

local function SendTextToChat(text, mode)
    if strtrim(text or "") == "" then RRT_Print("Note is empty."); return end
    local channel = ResolveChatChannel(mode)
    if channel == "RAID_WARNING" and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
        channel = "RAID"
    end
    if channel == "RAID" and not IsInRaid() then
        channel = IsInGroup() and "PARTY" or "SAY"
    end
    local sent = 0
    local maxLen = 240
    for rawLine in tostring(text):gmatch("[^\r\n]+") do
        local line = strtrim(rawLine)
        while line ~= "" do
            local piece = line
            if #piece > maxLen then
                local prefix   = piece:sub(1, maxLen)
                local spacePos = prefix:match(".*() ")
                local cut = (spacePos and spacePos > 80) and spacePos or maxLen
                piece = line:sub(1, cut)
                line  = strtrim(line:sub(cut + 1))
            else
                line = ""
            end
            if SendChatLine(piece, channel) then sent = sent + 1 end
        end
    end
    RRT_Print("Note sent to " .. channel .. " (" .. sent .. " line(s)).")
end

local function BuildParsedText(rawText)
    local out, seen = {}, {}
    local stats = { inputLines = 0, keptLines = 0, droppedEmpty = 0, droppedDuplicate = 0 }
    rawText = tostring(rawText or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for rawLine in rawText:gmatch("([^\n]*)\n?") do
        if rawLine == "" and stats.inputLines > 0 and rawText:sub(-1) ~= "\n" then break end
        stats.inputLines = stats.inputLines + 1
        local line = strtrim(rawLine or "")
        if line == "" then
            stats.droppedEmpty = stats.droppedEmpty + 1
        else
            line = line:gsub("%s+", " ")
            local key = line:lower()
            if seen[key] then
                stats.droppedDuplicate = stats.droppedDuplicate + 1
            else
                seen[key] = true
                table.insert(out, line)
                stats.keptLines = stats.keptLines + 1
            end
        end
    end
    return table.concat(out, "\n"), stats
end

-------------------------------------------------------------------------------
-- Widget helpers
-------------------------------------------------------------------------------

local function SkinPanel(frame, bgColor, borderColor)
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
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

local function CreateActionButton(parent, xOff, yOff, text, width, onClick)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetPoint("TOPLEFT", xOff, yOff)
    btn:SetSize(width, ROW_HEIGHT)
    SkinButton(btn)
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11)
    lbl:SetPoint("CENTER", 0, 0)
    lbl:SetTextColor(unpack(COLOR_LABEL))
    lbl:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

-------------------------------------------------------------------------------
-- UI builder
-------------------------------------------------------------------------------

local function BuildNoteUI(parent)
    EnsureNoteDB()

    -- Scroll content
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0,   0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(820)
    content:SetHeight(1200)
    scroll:SetScrollChild(content)

    local yOff = -10

    local sectionTitle = content:CreateFontString(nil, "OVERLAY")
    sectionTitle:SetFont(FONT, 13, "OUTLINE")
    sectionTitle:SetPoint("TOPLEFT", PADDING, yOff)
    sectionTitle:SetTextColor(unpack(COLOR_ACCENT))
    sectionTitle:SetText("Note")
    yOff = yOff - 24

    local hint = content:CreateFontString(nil, "OVERLAY")
    hint:SetFont(FONT, 11)
    hint:SetPoint("TOPLEFT", PADDING, yOff)
    hint:SetTextColor(unpack(COLOR_MUTED))
    hint:SetText("Create notes with title, save, reload, and send to chat.")
    yOff = yOff - 24

    -- Title row
    local titleLabel = content:CreateFontString(nil, "OVERLAY")
    titleLabel:SetFont(FONT, 11)
    titleLabel:SetPoint("TOPLEFT", PADDING, yOff - 3)
    titleLabel:SetTextColor(unpack(COLOR_LABEL))
    titleLabel:SetText("Title")

    local titleBox = CreateFrame("EditBox", nil, content, "InputBoxTemplate")
    titleBox:SetPoint("TOPLEFT", PADDING + 40, yOff)
    titleBox:SetSize(260, ROW_HEIGHT - 4)
    titleBox:SetAutoFocus(false)
    titleBox:SetMaxLetters(80)
    titleBox:SetText(GetNoteTitle())
    titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    titleBox:SetScript("OnEnterPressed", function(self)
        SetNoteTitle(self:GetText()); self:ClearFocus()
    end)
    titleBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then SetNoteTitle(self:GetText()) end
    end)
    _titleEditor = titleBox

    local selectBtn
    selectBtn = CreateActionButton(content, PADDING + 308, yOff, "Load...", 90, function()
        local titles = GetSavedNoteTitles()
        if #titles == 0 then RRT_Print("No saved notes."); return end
        MenuUtil.CreateContextMenu(selectBtn, function(_, root)
            for _, savedTitle in ipairs(titles) do
                root:CreateButton(savedTitle, function()
                    if LoadNamedNote(savedTitle) then
                        if _titleEditor then _titleEditor:SetText(GetNoteTitle()) end
                        if _noteEditor  then _noteEditor:SetText(GetNoteText())   end
                        RRT_Print("Note loaded: " .. savedTitle)
                    end
                end)
            end
        end)
    end)

    CreateActionButton(content, PADDING + 404, yOff, "Save Note", 100, function()
        local titleVal = _titleEditor and _titleEditor:GetText() or GetNoteTitle()
        local textVal  = _noteEditor  and _noteEditor:GetText()  or GetNoteText()
        SaveNamedNote(titleVal, textVal)
        if _titleEditor then _titleEditor:SetText(GetNoteTitle()) end
        RRT_Print("Note saved: " .. GetNoteTitle())
    end)

    CreateActionButton(content, PADDING + 510, yOff, "Delete", 90, function()
        local titleVal = _titleEditor and _titleEditor:GetText() or GetNoteTitle()
        titleVal = NormalizeTitle(titleVal)
        if DeleteNamedNote(titleVal) then
            if _titleEditor then _titleEditor:SetText("") end
            if _noteEditor  then _noteEditor:SetText("")  end
            RRT_Print("Note deleted: " .. titleVal)
        else
            RRT_Print("Note not found: " .. titleVal)
        end
    end)

    yOff = yOff - ROW_HEIGHT - 8

    -- Main text area
    local boxHolder = CreateFrame("Frame", nil, content, "BackdropTemplate")
    boxHolder:SetPoint("TOPLEFT", PADDING, yOff)
    boxHolder:SetSize(780, 360)
    SkinPanel(boxHolder, { 0.06, 0.06, 0.06, 0.95 }, { 0.2, 0.2, 0.2, 1.0 })

    local textScroll = CreateFrame("ScrollFrame", nil, boxHolder, "UIPanelScrollFrameTemplate")
    textScroll:SetPoint("TOPLEFT", 6, -6)
    textScroll:SetPoint("BOTTOMRIGHT", -24, 6)

    local editBox = CreateFrame("EditBox", nil, textScroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    editBox:SetWidth(780 - 36)
    editBox:SetHeight(360)
    editBox:SetMaxLetters(0)
    editBox:SetFont(FONT, 12, "")
    editBox:SetTextInsets(2, 2, 2, 2)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetText(GetNoteText())
    editBox:SetScript("OnMouseDown",    function(self) self:SetFocus() end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if userInput then SetNoteText(self:GetText()) end
        local w, h = self:GetWidth(), self:GetHeight()
        local textH = (self.GetStringHeight and self:GetStringHeight() or h) + 24
        if textH > h then
            self:SetSize(w, textH)
        elseif h > 360 and textH < 340 then
            self:SetSize(w, 360)
        end
    end)
    textScroll:SetScrollChild(editBox)
    _noteEditor = editBox

    yOff = yOff - 370

    -- Send/save row
    CreateActionButton(content, PADDING, yOff, "Save Text", 100, function()
        if _noteEditor then
            SetNoteText(_noteEditor:GetText())
            RRT_Print("Text saved.")
        end
    end)

    CreateActionButton(content, PADDING + 106, yOff, "New", 80, function()
        SetNoteTitle(""); SetNoteText("")
        if _titleEditor then _titleEditor:SetText("") end
        if _noteEditor  then _noteEditor:SetText(""); _noteEditor:SetFocus() end
    end)

    CreateActionButton(content, PADDING + 192, yOff, "Send Auto", 110, function()
        SendTextToChat(GetNoteText(), "AUTO")
    end)

    CreateActionButton(content, PADDING + 308, yOff, "Send Raid", 110, function()
        SendTextToChat(GetNoteText(), "RAID")
    end)

    CreateActionButton(content, PADDING + 424, yOff, "Send RW", 110, function()
        SendTextToChat(GetNoteText(), "RAID_WARNING")
    end)

    yOff = yOff - ROW_HEIGHT - 10

    -- Parse/import row
    CreateActionButton(content, PADDING, yOff, "Import V1", 100, function()
        local rawText = _noteEditor and _noteEditor:GetText() or GetNoteText()
        local noteDB = EnsureNoteDB()
        if noteDB then
            noteDB.importText  = tostring(rawText or "")
            noteDB.parsedText  = ""
            noteDB.parsedStats = {}
        end
        RRT_Print("Imported raw text (" .. tostring(strlen(rawText or "")) .. " chars).")
    end)

    CreateActionButton(content, PADDING + 106, yOff, "Parse V1", 90, function()
        local noteDB = EnsureNoteDB()
        if not noteDB then return end
        local parsed, stats = BuildParsedText(noteDB.importText or "")
        noteDB.parsedText  = parsed or ""
        noteDB.parsedStats = stats or {}
        local kept    = (stats and stats.keptLines) or 0
        local dropped = ((stats and stats.droppedEmpty) or 0) + ((stats and stats.droppedDuplicate) or 0)
        RRT_Print("Parsed note (" .. kept .. " kept / " .. dropped .. " dropped).")
        if parsed and parsed ~= "" then
            SetNoteText(parsed)
            if _noteEditor then _noteEditor:SetText(parsed) end
        end
    end)

    CreateActionButton(content, PADDING + 202, yOff, "Preview V1", 100, function()
        local noteDB = EnsureNoteDB()
        local parsed = noteDB and noteDB.parsedText or ""
        if strtrim(parsed or "") == "" then
            RRT_Print("Nothing to preview. Use Import V1 then Parse V1."); return
        end
        SetNoteText(parsed)
        if _noteEditor then _noteEditor:SetText(parsed) end
        RRT_Print("Preview loaded in editor.")
    end)

    CreateActionButton(content, PADDING + 308, yOff, "Send Parsed", 120, function()
        local noteDB = EnsureNoteDB()
        SendTextToChat((noteDB and noteDB.parsedText) or "", "AUTO")
    end)

    yOff = yOff - ROW_HEIGHT - 10
    content:SetHeight(math.max(64, math.abs(yOff) + PADDING))
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.SetupManager = RRT.UI.SetupManager or {}
RRT.UI.SetupManager.Note = { BuildUI = BuildNoteUI }
