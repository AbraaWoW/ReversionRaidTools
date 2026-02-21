local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Raid Groups
--
-- Lets you plan 8 raid subgroups of 5 players each, then apply them in-game
-- using SetRaidSubgroup / SwapRaidSubgroup (same logic as raid roster processors).
-- Group assignments are saved between sessions and support named profiles.
-------------------------------------------------------------------------------

local NUM_GROUPS     = 8;
local SLOTS_PER_GRP  = 5;
local NUM_SLOTS      = NUM_GROUPS * SLOTS_PER_GRP;  -- 40

local COL_W     = 185;   -- EditBox width
local COL_GAP   = 12;    -- gap between left/right group in a pair
local PAIR_GAP  = 12;    -- vertical gap between group pairs
local HDR_H     = 20;    -- group header height
local SLOT_H    = 20;    -- slot height
local SLOT_GAP  = 2;     -- gap between slots

-- X origins for the two group columns in each pair
local GX_LEFT   = 12;
local GX_RIGHT  = GX_LEFT + COL_W + COL_GAP;
-- Height of one group block (header + 5 slots)
local BLOCK_H   = HDR_H + SLOTS_PER_GRP * (SLOT_H + SLOT_GAP);

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function SlotIdx(group, pos)
    return (group - 1) * SLOTS_PER_GRP + pos;
end

local function Trim(s)
    if (not s) then return ""; end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""));
end

local function NormalizeNameToken(token)
    token = Trim((token or ""):gsub('"', ""));
    if (token == "" or token == "-") then
        return nil;
    end
    return token;
end

local function SplitByTab(text)
    local out = {};
    local s = text or "";
    local start = 1;
    while true do
        local idx = string.find(s, "\t", start, true);
        if (not idx) then
            out[#out + 1] = string.sub(s, start);
            break;
        end
        out[#out + 1] = string.sub(s, start, idx - 1);
        start = idx + 1;
    end
    return out;
end

local function CollectLines(text)
    local lines = {};
    if (not text) then return lines; end
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n");
    for raw in string.gmatch(text, "([^\n]*)\n?") do
        if (raw == "" and #lines > 0 and lines[#lines] == "") then
            -- avoid duplicate final empty capture
        else
            lines[#lines + 1] = Trim(raw);
        end
    end
    while (#lines > 0 and lines[#lines] == "") do
        table.remove(lines, #lines);
    end
    return lines;
end

local function ParseNamesFromLine(line)
    local names = {};
    for token in string.gmatch(line or "", "%S+") do
        local n = NormalizeNameToken(token);
        if (n) then names[#names + 1] = n; end
    end
    return names;
end

local function EnsureDB()
    if (not ST.db) then return nil; end
    local db = ST.db;
    if (type(db.raidGroups) ~= "table") then
        db.raidGroups = {};
    end
    db.raidGroups.profiles = db.raidGroups.profiles or {};
    db.raidGroups.currentSlots = db.raidGroups.currentSlots or {};
    return db.raidGroups;
end

-- Returns player name with realm stripped (for matching needGroup keys).
local function ShortName(name)
    if (not name) then return nil; end
    return name:match("^(.-)%-") or name;
end

-- Returns r, g, b class color for a name visible to the client.
local function NameColor(name)
    if (not name or name == "") then return 0.5, 0.5, 0.5; end
    local _, class = UnitClass(name);
    if (class) then return ST:GetClassColor(class); end
    return 0.7, 0.7, 0.7;
end

-- List of raid members not present in the current slot grid.
local function GetUnassigned(slots)
    local inGrid = {};
    for i = 1, NUM_SLOTS do
        local n = slots[i];
        if (n and n ~= "") then
            inGrid[n] = true;
            inGrid[ShortName(n)] = true;
        end
    end
    local result = {};
    if (not IsInGroup()) then return result; end
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i);
        if (name and not inGrid[name] and not inGrid[ShortName(name)]) then
            table.insert(result, name);
        end
    end
    return result;
end

local function BuildExportString(slots)
    local parts = {};
    for i = 1, NUM_SLOTS do
        parts[i] = slots[i] or "";
    end
    return "RRT_RG1:" .. table.concat(parts, "\t");
end

local function ParseImportedSlots(text)
    if (not text or Trim(text) == "") then
        return nil, "Import text is empty.";
    end

    local raw = Trim(text);

    -- Native compact format
    if (string.sub(raw, 1, 8) == "RRT_RG1:") then
        local payload = string.sub(raw, 9);
        local fields = SplitByTab(payload);
        local out = {};
        for i = 1, NUM_SLOTS do
            out[i] = NormalizeNameToken(fields[i]);
        end
        return out;
    end

    local lines = CollectLines(raw);
    if (#lines == 0) then
        return nil, "No valid lines found in import text.";
    end

    local out = {};

    -- Text layout: 40 lines (G1 then G2 ... G8, each 5 names)
    if (#lines == 40) then
        local idx = 1;
        for g = 1, NUM_GROUPS do
            for p = 1, SLOTS_PER_GRP do
                out[SlotIdx(g, p)] = NormalizeNameToken(lines[idx]);
                idx = idx + 1;
            end
        end
        return out;
    end

    -- Text layout: 20 lines, two columns (G1 G2 / G3 G4 ...)
    if (#lines == 20) then
        for i = 1, 20 do
            local pair = math.floor((i - 1) / SLOTS_PER_GRP);
            local row  = ((i - 1) % SLOTS_PER_GRP) + 1;
            local g1   = pair * 2 + 1;
            local g2   = g1 + 1;
            local names = ParseNamesFromLine(lines[i]);
            out[SlotIdx(g1, row)] = names[1];
            out[SlotIdx(g2, row)] = names[2];
        end
        return out;
    end

    -- Text layout: 5 lines, 8 columns
    if (#lines == 5) then
        for row = 1, 5 do
            local names = ParseNamesFromLine(lines[row]);
            for g = 1, NUM_GROUPS do
                out[SlotIdx(g, row)] = names[g];
            end
        end
        return out;
    end

    -- Fallback: 8 lines (one line per group, up to 5 names each)
    if (#lines == 8) then
        for g = 1, NUM_GROUPS do
            local names = ParseNamesFromLine(lines[g]);
            for p = 1, SLOTS_PER_GRP do
                out[SlotIdx(g, p)] = names[p];
            end
        end
        return out;
    end

    return nil, "Unsupported text format. Use RRT_RG1, text formats (20/5/40 lines), or 8 lines by group.";
end

-------------------------------------------------------------------------------
-- Apply logic (mirrors roster processing)
-------------------------------------------------------------------------------

local _applyData  = nil;
local _applyTimer = nil;

local applyFrame = CreateFrame("Frame");

local function FinishApply(ok)
    _applyData = nil;
    applyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE");
    if (ok) then
        ST:Print("Raid groups applied.");
    end
end

local function ProcessRoster()
    if (not _applyData) then return; end

    -- Abort if anyone entered combat
    for i = 1, 40 do
        if (UnitAffectingCombat("raid" .. i)) then
            ST:Print("Cannot apply groups: players are in combat.");
            FinishApply(false);
            return;
        end
    end

    local needGroup = _applyData.needGroup;

    -- Build current state
    local currentGroup = {};
    local nameToID     = {};
    local groupSize    = {};
    for i = 1, NUM_GROUPS do groupSize[i] = 0; end

    for i = 1, GetNumGroupMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i);
        if (name) then
            local key = needGroup[name] and name or ShortName(name);
            currentGroup[key] = subgroup;
            nameToID[key]     = i;
            groupSize[subgroup] = groupSize[subgroup] + 1;
        end
    end

    if (not _applyData.groupsReady) then
        -- Phase 1: move players where there is free space
        local moved = false;
        for name, tg in pairs(needGroup) do
            if (currentGroup[name] and currentGroup[name] ~= tg) then
                if (groupSize[tg] < SLOTS_PER_GRP) then
                    SetRaidSubgroup(nameToID[name], tg);
                    groupSize[currentGroup[name]] = groupSize[currentGroup[name]] - 1;
                    groupSize[tg]                 = groupSize[tg] + 1;
                    moved = true;
                end
            end
        end
        if (moved) then return; end

        -- Phase 2: swap pairs of players between full groups
        local swapDone = {};
        local swapped  = false;
        for name, tg in pairs(needGroup) do
            if (not swapDone[name] and currentGroup[name] and currentGroup[name] ~= tg) then
                for name2, tg2 in pairs(needGroup) do
                    if (not swapDone[name2] and name2 ~= name
                        and currentGroup[name2] == tg
                        and tg2 ~= tg) then
                        SwapRaidSubgroup(nameToID[name], nameToID[name2]);
                        swapDone[name]  = true;
                        swapDone[name2] = true;
                        swapped = true;
                        break;
                    end
                end
            end
        end
        if (swapped) then return; end

        _applyData.groupsReady = true;
    end

    FinishApply(true);
end

applyFrame:SetScript("OnEvent", function(self, event)
    if (event == "GROUP_ROSTER_UPDATE") then
        if (_applyTimer) then _applyTimer:Cancel(); end
        _applyTimer = C_Timer.NewTimer(0.5, function()
            _applyTimer = nil;
            ProcessRoster();
        end);
    end
end);

function ST:ApplyRaidGroups(slots)
    if (not IsInRaid()) then
        ST:Print("You must be in a raid to apply groups.");
        return;
    end
    for i = 1, 40 do
        if (UnitAffectingCombat("raid" .. i)) then
            ST:Print("Cannot apply groups: players are in combat.");
            return;
        end
    end

    local needGroup = {};
    for g = 1, NUM_GROUPS do
        for p = 1, SLOTS_PER_GRP do
            local name = slots[SlotIdx(g, p)];
            if (name and name ~= "") then
                needGroup[name] = g;
            end
        end
    end

    _applyData = { needGroup = needGroup, groupsReady = false };
    applyFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    ProcessRoster();
end

-------------------------------------------------------------------------------
-- Options tab UI
-------------------------------------------------------------------------------

function ST:BuildRaidGroupsSection(parent, yOff, FONT, PADDING, ROW_HEIGHT,
    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,
    SkinButton, CreateCheckbox, CreateActionButton, Track)

    local rg = EnsureDB();
    if (not rg) then return yOff; end
    local slots = rg.currentSlots;

    -- Keep reference to all slot EditBoxes so we can refresh the unassigned panel
    local slotEdits      = {};
    local unassignLabels = {};  -- FontStrings for the unassigned list

    ----------------------------------------------------------------------------
    -- Helpers scoped to this build
    ----------------------------------------------------------------------------

    local function RefreshColors()
        for i = 1, NUM_SLOTS do
            local eb = slotEdits[i];
            if (eb) then
                local r, g, b = NameColor(eb:GetText());
                eb:SetTextColor(r, g, b, 1);
            end
        end
    end

    local function RefreshUnassigned()
        local unassigned = GetUnassigned(slots);
        for i, fs in ipairs(unassignLabels) do
            local name = unassigned[i];
            if (name) then
                local r, g, b = NameColor(name);
                fs:SetTextColor(r, g, b);
                fs:SetText(ShortName(name));
                fs:Show();
            else
                fs:Hide();
            end
        end
    end

    local function ApplySlotsToEditor(srcSlots)
        for i = 1, NUM_SLOTS do
            local v = srcSlots[i];
            slots[i] = (v and v ~= "") and v or nil;
            local eb = slotEdits[i];
            if (eb) then
                local text = slots[i] or "";
                eb:SetText(text);
                local r, g, b = NameColor(text);
                eb:SetTextColor(r, g, b, 1);
            end
        end
        RefreshUnassigned();
    end

    local function OnSlotChanged(self)
        local idx  = self.slotIdx;
        local text = Trim(self:GetText());
        slots[idx] = (text ~= "") and text or nil;
        local r, g, b = NameColor(text);
        self:SetTextColor(r, g, b, 1);
        RefreshUnassigned();
    end

    local function MakeSlotEditBox(group, pos, baseX, baseY)
        local idx = SlotIdx(group, pos);
        local ySlot = baseY - HDR_H - (pos - 1) * (SLOT_H + SLOT_GAP);

        -- Container frame with backdrop
        local container = CreateFrame("Frame", nil, parent, "BackdropTemplate");
        container:SetSize(COL_W, SLOT_H);
        container:SetPoint("TOPLEFT", baseX, ySlot);
        container:SetBackdrop({
            bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
            edgeFile = "Interface\\BUTTONS\\WHITE8X8",
            edgeSize = 1,
        });
        container:SetBackdropColor(0.08, 0.08, 0.08, 0.95);
        container:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);
        Track(container);

        local eb = CreateFrame("EditBox", nil, container);
        eb:SetPoint("TOPLEFT", 3, -1);
        eb:SetPoint("BOTTOMRIGHT", -3, 1);
        eb:SetAutoFocus(false);
        if (eb.SetFontObject and ChatFontNormal) then
            eb:SetFontObject(ChatFontNormal);
        end
        eb:SetMaxLetters(64);
        eb:SetTextInsets(2, 2, 0, 0);
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
        eb:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);

        local saved = slots[idx];
        if (saved and saved ~= "") then
            eb:SetText(saved);
            local r, g, b = NameColor(saved);
            eb:SetTextColor(r, g, b, 1);
        else
            eb:SetText("");
            eb:SetTextColor(0.55, 0.55, 0.55, 1);
        end

        eb.slotIdx = idx;
        eb:SetScript("OnTextChanged", OnSlotChanged);
        Track(eb);

        slotEdits[idx] = eb;
        return container;
    end

    local function MakeGroupBlock(group, bx, by)
        -- Header
        local hdr = parent:CreateFontString(nil, "OVERLAY");
        hdr:SetFont(FONT, 11, "OUTLINE");
        hdr:SetPoint("TOPLEFT", bx, by);
        hdr:SetTextColor(unpack(COLOR_ACCENT));
        hdr:SetText("Group " .. group);
        Track(hdr);

        -- 5 slots
        for pos = 1, SLOTS_PER_GRP do
            MakeSlotEditBox(group, pos, bx, by);
        end
    end

    ----------------------------------------------------------------------------
    -- Grid: 4 rows of 2 groups each
    ----------------------------------------------------------------------------

    local gridTop = yOff;

    for pair = 0, 3 do
        local gLeft  = pair * 2 + 1;
        local gRight = pair * 2 + 2;
        local pairY  = gridTop - pair * (BLOCK_H + PAIR_GAP);

        MakeGroupBlock(gLeft,  GX_LEFT,  pairY);
        MakeGroupBlock(gRight, GX_RIGHT, pairY);
    end

    local gridBottom = gridTop - 4 * (BLOCK_H + PAIR_GAP) + PAIR_GAP;

    ----------------------------------------------------------------------------
    -- Unassigned panel (right of grid)
    ----------------------------------------------------------------------------

    local unassignX = GX_RIGHT + COL_W + 20;

    local uHdr = parent:CreateFontString(nil, "OVERLAY");
    uHdr:SetFont(FONT, 11, "OUTLINE");
    uHdr:SetPoint("TOPLEFT", unassignX, gridTop);
    uHdr:SetTextColor(unpack(COLOR_MUTED));
    uHdr:SetText("Not assigned:");
    Track(uHdr);

    -- Pre-create 40 label slots (max raid size)
    for i = 1, 40 do
        local fs = parent:CreateFontString(nil, "OVERLAY");
        fs:SetFont(FONT, 11);
        fs:SetPoint("TOPLEFT", unassignX + 6, gridTop - HDR_H - (i - 1) * 16);
        fs:SetText("");
        fs:Hide();
        Track(fs);
        unassignLabels[i] = fs;
    end

    RefreshUnassigned();

    ----------------------------------------------------------------------------
    -- Profiles panel (right of unassigned)
    ----------------------------------------------------------------------------

    local profX = unassignX + 175;
    local profY = gridTop;

    local profHdr = parent:CreateFontString(nil, "OVERLAY");
    profHdr:SetFont(FONT, 11, "OUTLINE");
    profHdr:SetPoint("TOPLEFT", profX, profY);
    profHdr:SetTextColor(unpack(COLOR_ACCENT));
    profHdr:SetText("Saved Profiles");
    Track(profHdr);
    profY = profY - 22;

    -- Profile name input + Save button
    local saveContainer = CreateFrame("Frame", nil, parent, "BackdropTemplate");
    saveContainer:SetSize(180, 22);
    saveContainer:SetPoint("TOPLEFT", profX, profY);
    saveContainer:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    saveContainer:SetBackdropColor(0.08, 0.08, 0.08, 0.95);
    saveContainer:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);
    Track(saveContainer);

    local nameInput = CreateFrame("EditBox", nil, saveContainer);
    nameInput:SetPoint("TOPLEFT", 3, -2);
    nameInput:SetPoint("BOTTOMRIGHT", -3, 2);
    nameInput:SetAutoFocus(false);
    if (nameInput.SetFontObject and ChatFontNormal) then
        nameInput:SetFontObject(ChatFontNormal);
    end
    nameInput:SetMaxLetters(40);
    nameInput:SetTextInsets(2, 2, 0, 0);
    nameInput:SetTextColor(0.85, 0.85, 0.85, 1);
    nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    nameInput:SetScript("OnEnterPressed", function(self) self:ClearFocus(); end);
    Track(nameInput);

    local function RebuildProfileList() end  -- defined below after rows setup

    local saveBtn = CreateActionButton(parent, profX + 184, profY, "Save", 60, function()
        local name = Trim(nameInput:GetText());
        if (not name or name == "") then
            ST:Print("Enter a profile name first.");
            return;
        end

        local snapshot = {};
        for i = 1, NUM_SLOTS do snapshot[i] = slots[i]; end

        local replaced = false;
        for i = 1, #rg.profiles do
            if (rg.profiles[i].name == name) then
                rg.profiles[i].slots = snapshot;
                rg.profiles[i].savedAt = time();
                replaced = true;
                break;
            end
        end
        if (not replaced) then
            table.insert(rg.profiles, { name = name, slots = snapshot, savedAt = time() });
        end

        nameInput:SetText("");
        RebuildProfileList();
        ST:Print(replaced and ("Raid groups profile updated: " .. name) or ("Raid groups profile saved: " .. name));
    end);
    Track(saveBtn);

    profY = profY - 28;

    -- Profile rows area
    local PROF_ROW_H = 22;
    local MAX_PROFILES_SHOWN = 14;
    local profRowY = profY;

    -- Pre-create MAX_PROFILES_SHOWN rows (each = name label + load btn + del btn)
    local profRowFrames = {};
    for i = 1, MAX_PROFILES_SHOWN do
        local rowFrame = CreateFrame("Frame", nil, parent);
        rowFrame:SetSize(280, PROF_ROW_H);
        rowFrame:SetPoint("TOPLEFT", profX, profRowY - (i - 1) * (PROF_ROW_H + 2));
        rowFrame:Hide();
        Track(rowFrame);

        local nameLbl = rowFrame:CreateFontString(nil, "OVERLAY");
        nameLbl:SetFont(FONT, 11);
        nameLbl:SetPoint("TOPLEFT", 0, -4);
        nameLbl:SetWidth(160);
        nameLbl:SetTextColor(unpack(COLOR_LABEL));
        rowFrame.nameLbl = nameLbl;

        -- Load button
        local loadBtn = CreateFrame("Button", nil, rowFrame);
        loadBtn:SetSize(48, 18);
        loadBtn:SetPoint("LEFT", nameLbl, "RIGHT", 4, 0);
        SkinButton(loadBtn, COLOR_BTN, COLOR_BTN_HOVER);
        local loadTxt = loadBtn:CreateFontString(nil, "OVERLAY");
        loadTxt:SetFont(FONT, 10, "OUTLINE");
        loadTxt:SetPoint("CENTER");
        loadTxt:SetText("Load");
        loadTxt:SetTextColor(0.85, 0.85, 0.85);
        rowFrame.loadBtn = loadBtn;

        -- Delete button
        local delBtn = CreateFrame("Button", nil, rowFrame);
        delBtn:SetSize(18, 18);
        delBtn:SetPoint("LEFT", loadBtn, "RIGHT", 4, 0);
        SkinButton(delBtn, { 0.4, 0.1, 0.1, 1 }, { 0.6, 0.15, 0.15, 1 });
        local delLineA = delBtn:CreateTexture(nil, "OVERLAY");
        delLineA:SetSize(10, 2);
        delLineA:SetPoint("CENTER", 0, 0);
        delLineA:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        delLineA:SetRotation(math.rad(45));

        local delLineB = delBtn:CreateTexture(nil, "OVERLAY");
        delLineB:SetSize(10, 2);
        delLineB:SetPoint("CENTER", 0, 0);
        delLineB:SetTexture("Interface\\BUTTONS\\WHITE8X8");
        delLineB:SetRotation(math.rad(-45));

        local function SetDeleteIconColor(r, g, b, a)
            delLineA:SetVertexColor(r, g, b, a or 1);
            delLineB:SetVertexColor(r, g, b, a or 1);
        end

        SetDeleteIconColor(1, 0.85, 0.85, 1);
        delBtn:HookScript("OnEnter", function() SetDeleteIconColor(1, 1, 1, 1); end);
        delBtn:HookScript("OnLeave", function() SetDeleteIconColor(1, 0.85, 0.85, 1); end);
        rowFrame.delBtn = delBtn;

        profRowFrames[i] = rowFrame;
    end

    RebuildProfileList = function()
        local profiles = rg.profiles;
        for i = 1, MAX_PROFILES_SHOWN do
            local row  = profRowFrames[i];
            local prof = profiles[i];
            if (prof) then
                row.nameLbl:SetText(prof.name);
                local idx = i;
                row.loadBtn:SetScript("OnClick", function()
                    ApplySlotsToEditor(prof.slots or {});
                end);
                row.delBtn:SetScript("OnClick", function()
                    table.remove(rg.profiles, idx);
                    RebuildProfileList();
                end);
                row:Show();
            else
                row:Hide();
            end
        end
    end;

    RebuildProfileList();

    ----------------------------------------------------------------------------
    -- Import/Export (text formats)
    ----------------------------------------------------------------------------

    local ioTopY = profRowY - (MAX_PROFILES_SHOWN * (PROF_ROW_H + 2)) - 8;

    local ioHdr = parent:CreateFontString(nil, "OVERLAY");
    ioHdr:SetFont(FONT, 11, "OUTLINE");
    ioHdr:SetPoint("TOPLEFT", profX, ioTopY);
    ioHdr:SetTextColor(unpack(COLOR_MUTED));
    ioHdr:SetText("Import / Export");
    Track(ioHdr);

    local ioBox = CreateFrame("Frame", nil, parent, "BackdropTemplate");
    ioBox:SetSize(250, 72);
    ioBox:SetPoint("TOPLEFT", profX, ioTopY - 16);
    ioBox:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    ioBox:SetBackdropColor(0.08, 0.08, 0.08, 0.95);
    ioBox:SetBackdropBorderColor(0.2, 0.2, 0.2, 1);
    Track(ioBox);

    local ioEdit = CreateFrame("EditBox", nil, ioBox);
    ioEdit:SetMultiLine(true);
    ioEdit:SetPoint("TOPLEFT", 4, -4);
    ioEdit:SetPoint("BOTTOMRIGHT", -4, 4);
    ioEdit:SetAutoFocus(false);
    if (ioEdit.SetFontObject and ChatFontNormal) then
        ioEdit:SetFontObject(ChatFontNormal);
    end
    ioEdit:SetTextInsets(2, 2, 0, 0);
    ioEdit:SetTextColor(0.85, 0.85, 0.85, 1);
    ioEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus(); end);
    Track(ioEdit);

    Track(CreateActionButton(parent, profX, ioTopY - 94, "Export", 80, function()
        local str = BuildExportString(slots);
        ioEdit:SetText(str);
        ioEdit:SetFocus();
        ioEdit:HighlightText();
        ST:Print("Raid groups exported (RRT_RG1). You can copy the text.");
    end));

    Track(CreateActionButton(parent, profX + 88, ioTopY - 94, "Import", 80, function()
        local text = ioEdit:GetText();
        local parsed, err = ParseImportedSlots(text);
        if (not parsed) then
            ST:Print("Import failed: " .. (err or "invalid format"));
            return;
        end
        ApplySlotsToEditor(parsed);
        ST:Print("Raid groups imported.");
    end));

    ----------------------------------------------------------------------------
    -- Action buttons (below the grid)
    ----------------------------------------------------------------------------

    local btnY = gridBottom - 10;

    Track(CreateActionButton(parent, GX_LEFT, btnY, "Load Current Roster", 170, function()
        if (not IsInGroup()) then
            ST:Print("You are not in a group.");
            return;
        end
        -- Wipe existing slots
        for i = 1, NUM_SLOTS do slots[i] = nil; end
        -- Fill from current in-game subgroups
        local groupLists = {};
        for g = 1, NUM_GROUPS do groupLists[g] = {}; end
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i);
            if (name and subgroup) then
                table.insert(groupLists[subgroup], ShortName(name));
            end
        end
        for g = 1, NUM_GROUPS do
            for p = 1, SLOTS_PER_GRP do
                local name = groupLists[g][p];
                slots[SlotIdx(g, p)] = name;
                local eb = slotEdits[SlotIdx(g, p)];
                if (eb) then
                    eb:SetText(name or "");
                    local r, gb, b = NameColor(name);
                    eb:SetTextColor(r, gb, b, 1);
                end
            end
        end
        RefreshColors();
        RefreshUnassigned();
    end));

    Track(CreateActionButton(parent, GX_LEFT + 178, btnY, "Apply Groups", 130, function()
        ST:ApplyRaidGroups(slots);
    end));

    Track(CreateActionButton(parent, GX_LEFT + 316, btnY, "Clear All", 90, function()
        for i = 1, NUM_SLOTS do
            slots[i] = nil;
            local eb = slotEdits[i];
            if (eb) then
                eb:SetText("");
                eb:SetTextColor(0.55, 0.55, 0.55, 1);
            end
        end
        RefreshUnassigned();
    end));

    -- Keep unassigned list synced while the tab is visible.
    local watcher = CreateFrame("Frame");
    watcher:RegisterEvent("GROUP_ROSTER_UPDATE");
    watcher:SetScript("OnEvent", function()
        if (parent and parent:IsVisible()) then
            RefreshUnassigned();
            RefreshColors();
        end
    end);
    Track(watcher);

    btnY = btnY - ROW_HEIGHT;
    local bottomY = ioTopY - 96 - ROW_HEIGHT - 12;
    yOff = math.min(btnY - 8, bottomY);

    return yOff;
end




