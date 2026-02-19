local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Raid Check (compact)
-------------------------------------------------------------------------------

local _frame = nil;
local _rows = {};
local _eventFrame = CreateFrame("Frame");

local FONT = "Fonts\\FRIZQT__.TTF";
local COLOR_BG = { 0.08, 0.08, 0.08, 0.95 };
local COLOR_BORDER = { 0.2, 0.2, 0.2, 1 };
local COLOR_SECTION = { 0.12, 0.12, 0.12, 1 };
local COLOR_ACCENT = { 0.30, 0.72, 1.00 };
local COLOR_MUTED = { 0.55, 0.55, 0.55 };
local COLOR_LABEL = { 0.85, 0.85, 0.85 };
local COLOR_BTN = { 0.18, 0.18, 0.18, 1 };
local COLOR_BTN_HOVER = { 0.25, 0.25, 0.25, 1 };
local COLOR_DANGER = { 0.90, 0.24, 0.24 };

local FOOD_KEYWORDS = { "well fed", "bien nourri" };
local FLASK_KEYWORDS = { "phial", "flask", "flacon" };
local VANTUS_KEYWORDS = { "vantus" };

local AUGMENT_RUNE_IDS = {
    [393438] = true, [393439] = true, [393440] = true, [393441] = true, [393442] = true,
    [347901] = true, [347902] = true, [347903] = true, [270058] = true, [224001] = true,
};

local RAID_BUFF_IDS = {
    FORT = { [21562] = true },
    AI   = { [1459] = true },
    MOTW = { [1126] = true },
    BRNZ = { [381748] = true },
    BS   = { [6673] = true },
};

local function SkinPanel(frame, bgColor, borderColor)
    if (not frame.SetBackdrop) then
        Mixin(frame, BackdropTemplateMixin);
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    frame:SetBackdropColor(unpack(bgColor or COLOR_SECTION));
    frame:SetBackdropBorderColor(unpack(borderColor or COLOR_BORDER));
end

local function SkinButton(btn, color, hoverColor)
    local bg = btn:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    bg:SetVertexColor(unpack(color or COLOR_BTN));
    btn._bg = bg;

    btn:SetScript("OnEnter", function(self)
        self._bg:SetVertexColor(unpack(hoverColor or COLOR_BTN_HOVER));
    end);
    btn:SetScript("OnLeave", function(self)
        self._bg:SetVertexColor(unpack(color or COLOR_BTN));
    end);
end

local function SafeLower(v)
    if (type(v) ~= "string") then return ""; end
    return string.lower(v);
end

local function StrHasAny(hay, words)
    hay = SafeLower(hay);
    for i = 1, #words do
        if (string.find(hay, words[i], 1, true)) then
            return true;
        end
    end
    return false;
end

local function HasID(set, id)
    return id and set[id] and true or false;
end

local function GetUnitBuffNameAndSpellID(unit, index)
    if (C_UnitAuras and C_UnitAuras.GetBuffDataByIndex) then
        local data = C_UnitAuras.GetBuffDataByIndex(unit, index);
        if (not data) then return nil, nil; end
        return data.name, data.spellId;
    end

    if (AuraUtil and AuraUtil.ForEachAura) then
        local auraName, auraSpellID = nil, nil;
        local n = 0;
        AuraUtil.ForEachAura(unit, "HELPFUL", nil, function(aura)
            n = n + 1;
            if (n == index) then
                auraName = aura.name;
                auraSpellID = aura.spellId;
                return true;
            end
            return false;
        end, true);
        return auraName, auraSpellID;
    end

    return nil, nil;
end

local function UnitAurasFlags(unit)
    local hasFood, hasFlask, hasVantus, hasRune = false, false, false, false;
    local hasFort, hasAI, hasMotW, hasBronze = false, false, false, false;
    local hasPowerSpeed = false;

    for i = 1, 80 do
        local name, spellID = GetUnitBuffNameAndSpellID(unit, i);
        if (not name) then break; end

        if (not hasFood and StrHasAny(name, FOOD_KEYWORDS)) then hasFood = true; end
        if (not hasFlask and StrHasAny(name, FLASK_KEYWORDS)) then hasFlask = true; end
        if (not hasVantus and StrHasAny(name, VANTUS_KEYWORDS)) then hasVantus = true; end

        if (not hasRune) then
            if (spellID and AUGMENT_RUNE_IDS[spellID]) then
                hasRune = true;
            elseif (StrHasAny(name, { "augment rune", "rune d", "rune" }) and not StrHasAny(name, VANTUS_KEYWORDS)) then
                hasRune = true;
            end
        end

        if (not hasFort) then
            hasFort = HasID(RAID_BUFF_IDS.FORT, spellID) or StrHasAny(name, { "power word: fortitude", "mot de pouvoir : robustesse", "robustesse" });
        end
        if (not hasAI) then
            hasAI = HasID(RAID_BUFF_IDS.AI, spellID) or StrHasAny(name, { "arcane intellect", "intelligence des arcanes" });
        end
        if (not hasMotW) then
            hasMotW = HasID(RAID_BUFF_IDS.MOTW, spellID) or StrHasAny(name, { "mark of the wild", "marque du fauve" });
        end
        if (not hasBronze) then
            hasBronze = HasID(RAID_BUFF_IDS.BRNZ, spellID) or StrHasAny(name, { "blessing of the bronze", "benediction du bronze" });
        end
        if (not hasPowerSpeed) then
            hasPowerSpeed = HasID(RAID_BUFF_IDS.BS, spellID)
                or StrHasAny(name, { "battle shout", "cri de guerre", "skyfury", "fureur-du-ciel", "fureur du ciel" });
        end

        if (hasFood and hasFlask and hasVantus and hasRune and hasFort and hasAI and hasMotW and hasBronze and hasPowerSpeed) then
            break;
        end
    end

    return hasFood, hasFlask, hasVantus, hasRune, hasFort, hasAI, hasMotW, hasBronze, hasPowerSpeed;
end

local function GetPlayerDurabilityPercent()
    local curTotal, maxTotal = 0, 0;
    for slot = 1, 17 do
        if (slot ~= 4) then
            local cur, max = GetInventoryItemDurability(slot);
            if (cur and max and max > 0) then
                curTotal = curTotal + cur;
                maxTotal = maxTotal + max;
            end
        end
    end
    if (maxTotal <= 0) then return "-"; end
    local pct = math.floor((curTotal / maxTotal) * 100 + 0.5);
    return tostring(pct) .. "%";
end

local function GetUnitDurabilityText(unit)
    if (UnitIsUnit(unit, "player")) then
        return GetPlayerDurabilityPercent();
    end

    local sawAny = false;
    for slot = 1, 17 do
        if (slot ~= 4) then
            local broken = GetInventoryItemBroken(unit, slot);
            if (broken ~= nil) then
                sawAny = true;
                if (broken) then return "Broken"; end
            end
        end
    end

    if (sawAny) then return "OK"; end
    return "-";
end

local function GetClassColor(classTag)
    local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS;
    if (tbl and classTag and tbl[classTag]) then
        local cc = tbl[classTag];
        return cc.r, cc.g, cc.b;
    end
    return 1, 1, 1;
end
local function GroupUnits()
    local out = {};
    if (IsInRaid()) then
        for i = 1, GetNumGroupMembers() do out[#out + 1] = "raid" .. i; end
    elseif (IsInGroup()) then
        out[#out + 1] = "player";
        for i = 1, GetNumSubgroupMembers() do out[#out + 1] = "party" .. i; end
    else
        out[#out + 1] = "player";
    end
    return out;
end

local function SetCell(fs, text, ok)
    fs:SetText(text);
    if (ok == nil) then
        fs:SetTextColor(0.9, 0.9, 0.9);
    elseif (ok) then
        fs:SetTextColor(0.2, 0.95, 0.2);
    else
        fs:SetTextColor(0.95, 0.2, 0.2);
    end
end

local function SetBoolCell(fs, ok)
    if (ok == nil) then
        SetCell(fs, "-", nil);
    elseif (ok) then
        SetCell(fs, "V", true);
    else
        SetCell(fs, "X", false);
    end
end

local function NewCol(row, x, w)
    local fs = row:CreateFontString(nil, "OVERLAY");
    fs:SetFont(FONT, 11, "OUTLINE");
    fs:SetPoint("LEFT", x, 0);
    fs:SetWidth(w);
    fs:SetJustifyH("CENTER");
    return fs;
end

local function EnsureRow(i, parent)
    if (_rows[i]) then return _rows[i]; end

    local row = CreateFrame("Frame", nil, parent);
    row:SetSize(690, 18);

    local bg = row:CreateTexture(nil, "BACKGROUND");
    bg:SetAllPoints();
    if (i % 2 == 0) then
        bg:SetColorTexture(1, 1, 1, 0.03);
    else
        bg:SetColorTexture(1, 1, 1, 0.00);
    end

    row.name = row:CreateFontString(nil, "OVERLAY");
    row.name:SetFont(FONT, 11, "OUTLINE");
    row.name:SetPoint("LEFT", 4, 0);
    row.name:SetWidth(150);
    row.name:SetJustifyH("LEFT");

    row.flask = NewCol(row, 160, 40);
    row.food  = NewCol(row, 202, 40);
    row.rune  = NewCol(row, 244, 40);
    row.vant  = NewCol(row, 286, 40);
    row.fort  = NewCol(row, 328, 40);
    row.ai    = NewCol(row, 370, 40);
    row.motw  = NewCol(row, 412, 40);
    row.brnz  = NewCol(row, 454, 40);
    row.ps    = NewCol(row, 496, 40);

    row.dura = row:CreateFontString(nil, "OVERLAY");
    row.dura:SetFont(FONT, 11, "OUTLINE");
    row.dura:SetPoint("LEFT", 540, 0);
    row.dura:SetWidth(72);
    row.dura:SetJustifyH("CENTER");

    _rows[i] = row;
    return row;
end

local function HideUnusedRows(from)
    for i = from, #_rows do _rows[i]:Hide(); end
end

local function BuildFrame()
    if (_frame) then return _frame; end

    local f = CreateFrame("Frame", "RRTRaidCheckFrame", UIParent, "BackdropTemplate");
    f:SetSize(720, 450);
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 20);
    f:SetFrameStrata("DIALOG");
    f:SetClampedToScreen(true);
    f:SetMovable(true);
    f:EnableMouse(true);
    SkinPanel(f, COLOR_BG, COLOR_BORDER);

    local titleBar = CreateFrame("Frame", nil, f);
    titleBar:SetHeight(30);
    titleBar:SetPoint("TOPLEFT", 0, 0);
    titleBar:SetPoint("TOPRIGHT", 0, 0);
    titleBar:EnableMouse(true);
    titleBar:RegisterForDrag("LeftButton");
    titleBar:SetScript("OnDragStart", function() f:StartMoving(); end);
    titleBar:SetScript("OnDragStop", function() f:StopMovingOrSizing(); end);

    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    titleBg:SetVertexColor(unpack(COLOR_SECTION));

    local titleAccent = titleBar:CreateTexture(nil, "BORDER");
    titleAccent:SetPoint("BOTTOMLEFT", 0, 0);
    titleAccent:SetPoint("BOTTOMRIGHT", 0, 0);
    titleAccent:SetHeight(1);
    titleAccent:SetTexture("Interface\\BUTTONS\\WHITE8X8");
    titleAccent:SetVertexColor(unpack(COLOR_ACCENT));

    local titleLogo = titleBar:CreateTexture(nil, "ARTWORK");
    titleLogo:SetSize(22, 22);
    titleLogo:SetPoint("LEFT", 8, 0);
    titleLogo:SetTexture("Interface\\Icons\\ability_evoker_reversion2");

    local title = titleBar:CreateFontString(nil, "OVERLAY");
    title:SetFont(FONT, 14, "OUTLINE");
    title:SetPoint("CENTER", 0, 0);
    title:SetTextColor(unpack(COLOR_ACCENT));
    title:SetText("Reversion Raid Check");

    local closeBtn = CreateFrame("Button", nil, titleBar);
    closeBtn:SetSize(20, 20);
    closeBtn:SetPoint("RIGHT", -6, 0);
    SkinButton(closeBtn, COLOR_BTN, COLOR_BTN_HOVER);

    local closeText = closeBtn:CreateFontString(nil, "OVERLAY");
    closeText:SetFont(FONT, 16, "OUTLINE");
    closeText:SetPoint("CENTER", 0, 0);
    closeText:SetText("X");
    closeText:SetTextColor(unpack(COLOR_DANGER));

    closeBtn:SetScript("OnEnter", function() closeText:SetTextColor(1, 1, 1); end);
    closeBtn:SetScript("OnLeave", function() closeText:SetTextColor(unpack(COLOR_DANGER)); end);
    closeBtn:SetScript("OnClick", function() f:Hide(); end);

    local headers = {
        {"Player", 12, 150, "LEFT"},
        {"Flsk", 168, 40, "CENTER"},
        {"Food", 210, 40, "CENTER"},
        {"Rune", 252, 40, "CENTER"},
        {"Vnt", 294, 40, "CENTER"},
        {"Fort", 336, 40, "CENTER"},
        {"AI", 378, 40, "CENTER"},
        {"MotW", 420, 40, "CENTER"},
        {"Brnz", 462, 40, "CENTER"},
        {"P/S", 504, 40, "CENTER"},
        {"Dura", 548, 72, "CENTER"},
    };

    for i = 1, #headers do
        local h = f:CreateFontString(nil, "OVERLAY");
        h:SetFont(FONT, 11, "OUTLINE");
        h:SetPoint("TOPLEFT", headers[i][2], -40);
        h:SetWidth(headers[i][3]);
        h:SetJustifyH(headers[i][4]);
        h:SetTextColor(unpack(COLOR_ACCENT));
        h:SetText(headers[i][1]);
    end

    local line = f:CreateTexture(nil, "ARTWORK");
    line:SetColorTexture(1, 1, 1, 0.08);
    line:SetPoint("TOPLEFT", 8, -58);
    line:SetPoint("TOPRIGHT", -8, -58);
    line:SetHeight(1);

    local scroll = CreateFrame("ScrollFrame", nil, f);
    local glossary = f:CreateFontString(nil, "OVERLAY");
    glossary:SetFont(FONT, 10);
    glossary:SetPoint("BOTTOMLEFT", 10, 10);
    glossary:SetPoint("BOTTOMRIGHT", -10, 10);
    glossary:SetJustifyH("LEFT");
    glossary:SetTextColor(unpack(COLOR_MUTED));
    glossary:SetText("Flsk=Flask  Food=Food buff  Rune=Augment Rune  Vnt=Vantus  Fort=Fortitude  AI=Arcane Intellect  MotW=Mark of the Wild  Brnz=Blessing of the Bronze  P/S=Power/Speed  Dura=Durability");

    scroll:SetPoint("TOPLEFT", 8, -62);
    scroll:SetPoint("BOTTOMRIGHT", -8, 24);

    local content = CreateFrame("Frame", nil, scroll);
    content:SetSize(690, 1);
    scroll:SetScrollChild(content);

    f.content = content;
    f.scrollFrame = scroll;

    f:EnableMouseWheel(true);
    f:SetScript("OnMouseWheel", function(self, delta)
        local sf = self.scrollFrame;
        local child = self.content;
        if (not sf or not child) then return; end
        local current = sf:GetVerticalScroll();
        local maxScroll = math.max(0, child:GetHeight() - sf:GetHeight());
        local newScroll = math.max(0, math.min(current - (delta * 30), maxScroll));
        sf:SetVerticalScroll(newScroll);
    end);

    _frame = f;
    return f;
end

function ST:RefreshRaidCheck()
    local f = BuildFrame();
    local units = GroupUnits();

    local y = -2;
    local rowIndex = 1;

    for i = 1, #units do
        local unit = units[i];
        if (UnitExists(unit)) then
            local row = EnsureRow(rowIndex, f.content);
            row:SetPoint("TOPLEFT", 0, y);
            row:Show();

            local name = GetUnitName(unit, true) or UnitName(unit) or unit;
            local class = select(2, UnitClass(unit));
            local r, g, b = GetClassColor(class);
            row.name:SetText(name);
            row.name:SetTextColor(r, g, b);

            local hasFood, hasFlask, hasVantus, hasRune, hasFort, hasAI, hasMotW, hasBronze, hasPowerSpeed = UnitAurasFlags(unit);
            SetBoolCell(row.flask, hasFlask);
            SetBoolCell(row.food, hasFood);
            SetBoolCell(row.rune, hasRune);
            SetBoolCell(row.vant, hasVantus);
            SetBoolCell(row.fort, hasFort);
            SetBoolCell(row.ai, hasAI);
            SetBoolCell(row.motw, hasMotW);
            SetBoolCell(row.brnz, hasBronze);
            SetBoolCell(row.ps, hasPowerSpeed);

            local dura = GetUnitDurabilityText(unit);
            row.dura:SetText(dura);
            if (dura == "Broken") then
                row.dura:SetTextColor(0.95, 0.2, 0.2);
            elseif (dura == "-") then
                row.dura:SetTextColor(0.8, 0.8, 0.8);
            else
                row.dura:SetTextColor(0.2, 0.95, 0.2);
            end

            y = y - 19;
            rowIndex = rowIndex + 1;
        end
    end

    HideUnusedRows(rowIndex);
    f.content:SetSize(690, math.max(360, -y + 20));
end

function ST:ShowRaidCheck()
    local f = BuildFrame();
    f:Show();
    ST:RefreshRaidCheck();
end

function ST:ToggleRaidCheck()
    local f = BuildFrame();
    if (f:IsShown()) then f:Hide(); else ST:ShowRaidCheck(); end
end

_eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
_eventFrame:RegisterEvent("UNIT_AURA");
_eventFrame:RegisterEvent("READY_CHECK");
_eventFrame:RegisterEvent("READY_CHECK_CONFIRM");
_eventFrame:RegisterEvent("READY_CHECK_FINISHED");
_eventFrame:SetScript("OnEvent", function(_, event, unit)
    if (not _frame or not _frame:IsShown()) then return; end
    if (event == "UNIT_AURA") then
        if (not unit) then return; end
        if (unit ~= "player" and not string.find(unit, "party", 1, true) and not string.find(unit, "raid", 1, true)) then
            return;
        end
    end
    ST:RefreshRaidCheck();
end);

SLASH_RRTRAIDCHECK1 = "/rrtcheck";
SlashCmdList.RRTRAIDCHECK = function()
    if (ST and ST.ToggleRaidCheck) then ST:ToggleRaidCheck(); end
end
