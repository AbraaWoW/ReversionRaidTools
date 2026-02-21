local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local _noteEditor = nil;
local _titleEditor = nil;

local function EnsureNoteDB()
    if (not ST.db) then return nil; end
    if (type(ST.db.note) ~= "table") then
        ST.db.note = {};
    end

    local noteDB = ST.db.note;
    if (type(noteDB.text) ~= "string") then noteDB.text = ""; end
    if (type(noteDB.title) ~= "string") then noteDB.title = ""; end
    if (type(noteDB.saved) ~= "table") then noteDB.saved = {}; end
    if (type(noteDB.importText) ~= "string") then noteDB.importText = ""; end
    if (type(noteDB.parsedText) ~= "string") then noteDB.parsedText = ""; end
    if (type(noteDB.parsedStats) ~= "table") then noteDB.parsedStats = {}; end

    return noteDB;
end

local function NormalizeTitle(title)
    title = strtrim(tostring(title or ""));
    if (title == "") then
        title = "Untitled";
    end
    return title;
end

local function FindSavedNoteIndex(noteDB, title)
    local wanted = NormalizeTitle(title):lower();
    for i, item in ipairs(noteDB.saved) do
        if (type(item) == "table" and type(item.title) == "string" and item.title:lower() == wanted) then
            return i;
        end
    end
    return nil;
end

function ST:GetNoteText()
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return ""; end
    return noteDB.text or "";
end

function ST:SetNoteText(text)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return; end
    noteDB.text = tostring(text or "");
end

function ST:GetNoteTitle()
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return ""; end
    return noteDB.title or "";
end

function ST:SetNoteTitle(title)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return; end
    noteDB.title = NormalizeTitle(title);
end

function ST:GetSavedNoteTitles()
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return {}; end

    local titles = {};
    for _, item in ipairs(noteDB.saved) do
        if (type(item) == "table" and type(item.title) == "string" and item.title ~= "") then
            table.insert(titles, item.title);
        end
    end
    table.sort(titles, function(a, b) return a:lower() < b:lower(); end);
    return titles;
end

function ST:SaveNamedNote(title, text)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return false; end

    local finalTitle = NormalizeTitle(title or noteDB.title);
    local finalText = tostring(text or noteDB.text or "");

    local idx = FindSavedNoteIndex(noteDB, finalTitle);
    if (idx) then
        noteDB.saved[idx].title = finalTitle;
        noteDB.saved[idx].text = finalText;
        noteDB.saved[idx].updatedAt = time();
    else
        table.insert(noteDB.saved, {
            title = finalTitle,
            text = finalText,
            updatedAt = time(),
        });
    end

    noteDB.title = finalTitle;
    noteDB.text = finalText;
    return true;
end

function ST:LoadNamedNote(title)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return false; end

    local idx = FindSavedNoteIndex(noteDB, title);
    if (not idx) then return false; end

    local item = noteDB.saved[idx];
    noteDB.title = item.title or "Untitled";
    noteDB.text = tostring(item.text or "");
    return true;
end

function ST:DeleteNamedNote(title)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return false; end

    local idx = FindSavedNoteIndex(noteDB, title);
    if (not idx) then return false; end

    table.remove(noteDB.saved, idx);

    if (noteDB.title and noteDB.title:lower() == NormalizeTitle(title):lower()) then
        noteDB.title = "";
        noteDB.text = "";
    end

    return true;
end

local function ResolveChatChannel(mode)
    if (mode and mode ~= "AUTO") then
        return mode;
    end

    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        return "INSTANCE_CHAT";
    end
    if (IsInRaid()) then
        if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then
            return "RAID_WARNING";
        end
        return "RAID";
    end
    if (IsInGroup()) then
        return "PARTY";
    end

    return "SAY";
end

local function SendChatLine(message, channel)
    if (not message or message == "") then return false; end
    if (C_ChatInfo and C_ChatInfo.SendChatMessage) then
        C_ChatInfo.SendChatMessage(message, channel);
    else
        SendChatMessage(message, channel);
    end
    return true;
end

local function BuildParsedText(rawText)
    local out = {};
    local seen = {};
    local stats = {
        inputLines = 0,
        keptLines = 0,
        droppedEmpty = 0,
        droppedDuplicate = 0,
    };

    rawText = tostring(rawText or ""):gsub("\r\n", "\n"):gsub("\r", "\n");
    for rawLine in rawText:gmatch("([^\n]*)\n?") do
        if (rawLine == "" and stats.inputLines > 0 and rawText:sub(-1) ~= "\n") then
            break;
        end
        stats.inputLines = stats.inputLines + 1;
        local line = strtrim(rawLine or "");
        if (line == "") then
            stats.droppedEmpty = stats.droppedEmpty + 1;
        else
            line = line:gsub("%s+", " ");
            local key = line:lower();
            if (seen[key]) then
                stats.droppedDuplicate = stats.droppedDuplicate + 1;
            else
                seen[key] = true;
                table.insert(out, line);
                stats.keptLines = stats.keptLines + 1;
            end
        end
    end

    return table.concat(out, "\n"), stats;
end

function ST:ImportNoteText(rawText)
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return false; end
    noteDB.importText = tostring(rawText or "");
    noteDB.parsedText = "";
    noteDB.parsedStats = {};
    return true;
end

function ST:ParseImportedNoteText()
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return false; end

    local parsed, stats = BuildParsedText(noteDB.importText or "");
    noteDB.parsedText = parsed or "";
    noteDB.parsedStats = stats or {};
    return true, noteDB.parsedText, noteDB.parsedStats;
end

function ST:GetParsedNoteText()
    local noteDB = EnsureNoteDB();
    if (not noteDB) then return ""; end
    return noteDB.parsedText or "";
end

local function SendTextToChat(self, text, mode)
    if (strtrim(text or "") == "") then
        self:Print("Note is empty.");
        return;
    end

    local channel = ResolveChatChannel(mode);
    if (channel == "RAID_WARNING" and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player"))) then
        channel = "RAID";
    end
    if (channel == "RAID" and not IsInRaid()) then
        channel = IsInGroup() and "PARTY" or "SAY";
    end

    local sent = 0;
    local maxLen = 240;

    for rawLine in tostring(text):gmatch("[^\r\n]+") do
        local line = strtrim(rawLine);
        while (line ~= "") do
            local piece = line;
            if (#piece > maxLen) then
                local cut = maxLen;
                local prefix = piece:sub(1, maxLen);
                local spacePos = prefix:match(".*() ");
                if (spacePos and spacePos > 80) then
                    cut = spacePos;
                end
                piece = line:sub(1, cut);
                line = strtrim(line:sub(cut + 1));
            else
                line = "";
            end

            if (SendChatLine(piece, channel)) then
                sent = sent + 1;
            end
        end
    end

    self:Print("Note sent to " .. channel .. " (" .. sent .. " line(s)).");
end

function ST:SendNoteToChat(mode)
    SendTextToChat(self, self:GetNoteText(), mode);
end

function ST:SendParsedNoteToChat(mode)
    SendTextToChat(self, self:GetParsedNoteText(), mode);
end

function ST:BuildNoteSection(parent, yOff,
    FONT, PADDING, ROW_HEIGHT,
    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,
    SkinPanel, SkinButton, CreateActionButton, Track)

    EnsureNoteDB();

    local title = parent:CreateFontString(nil, "OVERLAY");
    title:SetFont(FONT, 13, "OUTLINE");
    title:SetPoint("TOPLEFT", PADDING, yOff);
    title:SetTextColor(unpack(COLOR_ACCENT));
    title:SetText("Note");
    Track(title);
    yOff = yOff - 24;

    local hint = parent:CreateFontString(nil, "OVERLAY");
    hint:SetFont(FONT, 11);
    hint:SetPoint("TOPLEFT", PADDING, yOff);
    hint:SetTextColor(unpack(COLOR_MUTED));
    hint:SetText("Create notes with title, save, reload, and send to chat.");
    Track(hint);
    yOff = yOff - 24;

    local parentWidth = parent:GetWidth();
    if (not parentWidth or parentWidth <= 0) then parentWidth = 780; end

    local titleLabel = parent:CreateFontString(nil, "OVERLAY");
    titleLabel:SetFont(FONT, 11);
    titleLabel:SetPoint("TOPLEFT", PADDING, yOff - 3);
    titleLabel:SetTextColor(unpack(COLOR_LABEL));
    titleLabel:SetText("Title");
    Track(titleLabel);

    local titleBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate");
    titleBox:SetPoint("TOPLEFT", PADDING + 40, yOff);
    titleBox:SetSize(260, ROW_HEIGHT - 4);
    titleBox:SetAutoFocus(false);
    titleBox:SetMaxLetters(80);
    titleBox:SetText(ST:GetNoteTitle());
    titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    titleBox:SetScript("OnEnterPressed", function(self)
        ST:SetNoteTitle(self:GetText());
        self:ClearFocus();
    end);
    titleBox:SetScript("OnTextChanged", function(self, userInput)
        if (userInput) then ST:SetNoteTitle(self:GetText()); end
    end);
    Track(titleBox);
    _titleEditor = titleBox;

    local selectBtn;
    selectBtn = CreateActionButton(parent, PADDING + 308, yOff, "Load...", 90, function()
        local titles = ST:GetSavedNoteTitles();
        if (#titles == 0) then
            ST:Print("No saved notes.");
            return;
        end

        MenuUtil.CreateContextMenu(selectBtn, function(_, root)
            for _, savedTitle in ipairs(titles) do
                root:CreateButton(savedTitle, function()
                    if (ST:LoadNamedNote(savedTitle)) then
                        if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle()); end
                        if (_noteEditor) then _noteEditor:SetText(ST:GetNoteText()); end
                        ST:Print("Note loaded: " .. savedTitle);
                    end
                end);
            end
        end);
    end);
    Track(selectBtn);

    local saveNamedBtn = CreateActionButton(parent, PADDING + 404, yOff, "Save Note", 100, function()
        local titleVal = _titleEditor and _titleEditor:GetText() or ST:GetNoteTitle();
        local textVal = _noteEditor and _noteEditor:GetText() or ST:GetNoteText();
        ST:SaveNamedNote(titleVal, textVal);
        if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle()); end
        ST:Print("Note saved: " .. ST:GetNoteTitle());
    end);
    Track(saveNamedBtn);

    local deleteBtn = CreateActionButton(parent, PADDING + 510, yOff, "Delete", 90, function()
        local titleVal = _titleEditor and _titleEditor:GetText() or ST:GetNoteTitle();
        titleVal = NormalizeTitle(titleVal);
        if (ST:DeleteNamedNote(titleVal)) then
            if (_titleEditor) then _titleEditor:SetText(""); end
            if (_noteEditor) then _noteEditor:SetText(""); end
            ST:Print("Note deleted: " .. titleVal);
        else
            ST:Print("Note not found: " .. titleVal);
        end
    end);
    Track(deleteBtn);

    yOff = yOff - ROW_HEIGHT - 8;

    local boxHolder = CreateFrame("Frame", nil, parent, "BackdropTemplate");
    boxHolder:SetPoint("TOPLEFT", PADDING, yOff);
    boxHolder:SetSize(parentWidth - (PADDING * 2), 360);
    SkinPanel(boxHolder, { 0.06, 0.06, 0.06, 0.95 }, { 0.2, 0.2, 0.2, 1.0 });
    Track(boxHolder);

    local scroll = CreateFrame("ScrollFrame", nil, boxHolder, "UIPanelScrollFrameTemplate");
    scroll:SetPoint("TOPLEFT", 6, -6);
    scroll:SetPoint("BOTTOMRIGHT", -24, 6);
    Track(scroll);

    local editBox = CreateFrame("EditBox", nil, scroll);
    editBox:SetMultiLine(true);
    editBox:SetAutoFocus(false);
    editBox:EnableMouse(true);
    editBox:SetWidth(parentWidth - (PADDING * 2) - 36);
    editBox:SetHeight(360);
    editBox:SetMaxLetters(0);
    editBox:SetFont(FONT, 12);
    editBox:SetTextInsets(2, 2, 2, 2);
    editBox:SetJustifyH("LEFT");
    editBox:SetJustifyV("TOP");
    editBox:SetText(ST:GetNoteText());
    editBox:SetScript("OnMouseDown", function(self)
        self:SetFocus();
    end);
    editBox:SetScript("OnEscapePressed", function(self)
        self:ClearFocus();
    end);
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if (userInput) then
            ST:SetNoteText(self:GetText());
        end

        local width = self:GetWidth();
        local height = self:GetHeight();
        local textHeight = self:GetStringHeight() + 24;
        if (textHeight > height) then
            self:SetSize(width, textHeight);
        elseif (height > 360 and textHeight < 340) then
            self:SetSize(width, 360);
        end
    end);
    scroll:SetScrollChild(editBox);
    Track(editBox);
    _noteEditor = editBox;

    yOff = yOff - 370;

    Track(CreateActionButton(parent, PADDING, yOff, "Save Text", 100, function()
        if (_noteEditor) then
            ST:SetNoteText(_noteEditor:GetText());
            ST:Print("Text saved.");
        end
    end));

    Track(CreateActionButton(parent, PADDING + 106, yOff, "New", 80, function()
        ST:SetNoteTitle("");
        ST:SetNoteText("");
        if (_titleEditor) then _titleEditor:SetText(""); end
        if (_noteEditor) then
            _noteEditor:SetText("");
            _noteEditor:SetFocus();
        end
    end));

    Track(CreateActionButton(parent, PADDING + 192, yOff, "Send Auto", 110, function()
        ST:SendNoteToChat("AUTO");
    end));

    Track(CreateActionButton(parent, PADDING + 308, yOff, "Send Raid", 110, function()
        ST:SendNoteToChat("RAID");
    end));

    Track(CreateActionButton(parent, PADDING + 424, yOff, "Send RW", 110, function()
        ST:SendNoteToChat("RAID_WARNING");
    end));

    yOff = yOff - ROW_HEIGHT - 10;

    Track(CreateActionButton(parent, PADDING, yOff, "Import V1", 100, function()
        local rawText = _noteEditor and _noteEditor:GetText() or ST:GetNoteText();
        ST:ImportNoteText(rawText);
        ST:Print("Imported raw text (" .. tostring(strlen(rawText or "")) .. " chars).");
    end));

    Track(CreateActionButton(parent, PADDING + 106, yOff, "Parse V1", 90, function()
        local ok, parsed, stats = ST:ParseImportedNoteText();
        if (not ok) then
            ST:Print("Parse failed.");
            return;
        end
        local kept = (stats and stats.keptLines) or 0;
        local dropped = ((stats and stats.droppedEmpty) or 0) + ((stats and stats.droppedDuplicate) or 0);
        ST:Print("Parsed note (" .. kept .. " kept / " .. dropped .. " dropped).");
        if (parsed and parsed ~= "") then
            ST:SetNoteText(parsed);
            if (_noteEditor) then _noteEditor:SetText(parsed); end
        end
    end));

    Track(CreateActionButton(parent, PADDING + 202, yOff, "Preview V1", 100, function()
        local parsed = ST:GetParsedNoteText();
        if (strtrim(parsed or "") == "") then
            ST:Print("Nothing to preview. Use Import V1 then Parse V1.");
            return;
        end
        ST:SetNoteText(parsed);
        if (_noteEditor) then _noteEditor:SetText(parsed); end
        ST:Print("Preview loaded in editor.");
    end));

    Track(CreateActionButton(parent, PADDING + 308, yOff, "Send Parsed", 120, function()
        ST:SendParsedNoteToChat("AUTO");
    end));

    yOff = yOff - ROW_HEIGHT - 10;

    local contentHeight = math.max(64, math.abs(yOff) + PADDING);
    parent:SetHeight(contentHeight);
    return yOff;
end
