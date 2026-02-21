local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Battle Resurrection
--
-- Uses the WoW shared pool API through GetSpellCharges(20484).
-- Shows icon, charges and recharge timer.
-------------------------------------------------------------------------------

local BREZ_SPELL_ID = 20484; -- Rebirth (shared battle resurrection pool)

-------------------------------------------------------------------------------
-- API compatibility
-------------------------------------------------------------------------------

local function QueryBrezCharges()
    if (C_Spell and C_Spell.GetSpellCharges) then
        local info = C_Spell.GetSpellCharges(BREZ_SPELL_ID);
        if (info) then
            return info.currentCharges, info.maxCharges, info.cooldownStartTime, info.cooldownDuration;
        end
        return nil;
    end
    local charges, maxCharges, started, duration = GetSpellCharges(BREZ_SPELL_ID);
    if (charges == 0 and maxCharges == 0) then return nil; end
    return charges, maxCharges, started, duration;
end

local function GetBrezTexture()
    if (C_Spell and C_Spell.GetSpellTexture) then
        return C_Spell.GetSpellTexture(BREZ_SPELL_ID);
    end
    return GetSpellTexture(BREZ_SPELL_ID);
end

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local _frame    = nil;
local _ticker   = nil;
local _inCombat = false;

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ShouldShow(hasPoolData)
    if (not ST.db or not ST.db.battleRez) then return false; end
    local br = ST.db.battleRez;
    if (not br.enabled) then return false; end

    -- Placement mode: keep icon visible while unlocked.
    if (br.showWhenUnlocked and not br.locked) then
        return true;
    end

    if (br.hideOutOfCombat and not _inCombat) then return false; end
    if (not hasPoolData) then return false; end
    return true;
end

local function ApplyLock()
    if (not _frame or not ST.db or not ST.db.battleRez) then return; end
    local locked = ST.db.battleRez.locked;
    _frame:SetMovable(not locked);
    _frame:EnableMouse(not locked);
end

local function ApplyScale()
    if (not _frame or not ST.db or not ST.db.battleRez) then return; end
    _frame:SetScale(ST.db.battleRez.scale or 1.0);
end

-------------------------------------------------------------------------------
-- Overlay frame
-------------------------------------------------------------------------------

local function CreateBrezFrame()
    if (_frame) then return _frame; end

    local f = CreateFrame("Frame", "ARTBattleRezFrame", UIParent);
    f:SetSize(64, 64);
    f:SetPoint("TOP", UIParent, "TOP", 0, -200);
    f:SetFrameStrata("HIGH");
    f:SetClampedToScreen(true);
    f:SetMovable(true);
    f:EnableMouse(true);
    f:RegisterForDrag("LeftButton");
    f:SetScript("OnDragStart", function(self)
        if (self:IsMovable()) then
            self:StartMoving();
        end
    end);
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        if (ST.db and ST.db.battleRez) then
            ST.db.battleRez.position = { left = self:GetLeft(), top = self:GetTop() };
        end
    end);

    local tex = f:CreateTexture(nil, "BACKGROUND");
    tex:SetAllPoints();
    tex:SetTexture(GetBrezTexture());
    tex:SetTexCoord(0.08, 0.92, 0.08, 0.92);

    local cd = CreateFrame("Cooldown", nil, f, "CooldownFrameTemplate");
    cd:SetAllPoints();
    cd:SetDrawEdge(false);
    cd:SetHideCountdownNumbers(true);
    cd:SetFrameLevel(f:GetFrameLevel() + 10);
    f.cooldown = cd;

    local textLayer = CreateFrame("Frame", nil, f);
    textLayer:SetAllPoints();
    textLayer:SetFrameLevel(f:GetFrameLevel() + 20);

    local timeText = textLayer:CreateFontString(nil, "ARTWORK");
    timeText:SetAllPoints();
    timeText:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE");
    timeText:SetJustifyH("CENTER");
    timeText:SetJustifyV("MIDDLE");
    timeText:SetTextColor(1, 1, 1, 1);
    timeText:SetText("");
    f.timeText = timeText;

    local chargeText = textLayer:CreateFontString(nil, "ARTWORK");
    chargeText:SetAllPoints();
    chargeText:SetFont("Fonts\\FRIZQT__.TTF", 16, "OUTLINE");
    chargeText:SetJustifyH("RIGHT");
    chargeText:SetJustifyV("BOTTOM");
    chargeText:SetShadowOffset(1, -1);
    chargeText:SetTextColor(1, 1, 1, 1);
    chargeText:SetText("");
    f.chargeText = chargeText;

    f:Hide();
    _frame = f;
    return f;
end

local function ApplySavedPosition(f)
    local pos = ST.db and ST.db.battleRez and ST.db.battleRez.position;
    f:ClearAllPoints();
    if (pos and pos.left and pos.top) then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top);
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -200);
    end
end

-------------------------------------------------------------------------------
-- Updates
-------------------------------------------------------------------------------

local function OnTick()
    if (not _frame) then return; end

    local charges, maxCharges, started, duration = QueryBrezCharges();
    local hasPoolData = (charges ~= nil and maxCharges ~= nil);

    if (not ShouldShow(hasPoolData)) then
        _frame:Hide();
        return;
    end

    if (not _frame:IsShown()) then
        _frame:Show();
    end

    if (hasPoolData) then
        _frame.chargeText:SetText(charges or "");
        if ((charges or 0) == 0) then
            _frame.chargeText:SetTextColor(1, 0, 0, 1);
        else
            _frame.chargeText:SetTextColor(1, 1, 1, 1);
        end
    else
        _frame.chargeText:SetText("");
        _frame.chargeText:SetTextColor(1, 1, 1, 1);
    end

    if (charges and maxCharges and charges < maxCharges and started and duration and duration > 0) then
        _frame.cooldown:SetCooldown(started, duration);
        _frame.cooldown:Show();

        local remaining = duration - (GetTime() - started);
        if (remaining > 60) then
            _frame.timeText:SetFormattedText("%d:%02d", math.floor(remaining / 60), remaining % 60);
        elseif (remaining > 0) then
            _frame.timeText:SetFormattedText("%d", math.ceil(remaining));
        else
            _frame.timeText:SetText("");
        end
    else
        _frame.cooldown:SetCooldown(0, 0);
        _frame.timeText:SetText("");
    end
end

-------------------------------------------------------------------------------
-- Enable / Disable
-------------------------------------------------------------------------------

local function EnableTracker()
    if (not _frame) then
        CreateBrezFrame();
        ApplySavedPosition(_frame);
    end
    ApplyLock();
    ApplyScale();
    if (not _ticker) then
        _ticker = C_Timer.NewTicker(0.1, OnTick);
    end
    OnTick();
end

local function DisableTracker()
    if (_ticker) then _ticker:Cancel(); _ticker = nil; end
    if (_frame) then _frame:Hide(); end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
eventFrame:SetScript("OnEvent", function(self, event)
    if (event == "PLAYER_REGEN_DISABLED") then
        _inCombat = true;
        OnTick();
    elseif (event == "PLAYER_REGEN_ENABLED") then
        _inCombat = false;
        OnTick();
    end
end);

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN");
    CreateBrezFrame();
    ApplySavedPosition(_frame);
    ApplyLock();
    ApplyScale();
    _inCombat = UnitAffectingCombat("player") and true or false;

    if (ST.db and ST.db.battleRez and ST.db.battleRez.enabled) then
        EnableTracker();
    else
        DisableTracker();
    end
end);

-------------------------------------------------------------------------------
-- Public API (used by Options.lua Tools tab)
-------------------------------------------------------------------------------

function ST:ResetBrezPosition()
    if (ST.db and ST.db.battleRez) then
        ST.db.battleRez.position = nil;
    end
    if (_frame) then
        ApplySavedPosition(_frame);
    end
end

function ST:BuildBattleRezSection(parent, yOff, FONT, PADDING, ROW_HEIGHT,
    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,
    SkinButton, CreateCheckbox, CreateActionButton, Track)

    local db = ST.db;
    if (not db or not db.battleRez) then return yOff; end
    local br = db.battleRez;

    local title = parent:CreateFontString(nil, "OVERLAY");
    title:SetFont(FONT, 13, "OUTLINE");
    title:SetPoint("TOPLEFT", PADDING, yOff);
    title:SetTextColor(unpack(COLOR_ACCENT));
    title:SetText("Battle Resurrection");
    Track(title);
    yOff = yOff - 24;

    Track(CreateCheckbox(parent, PADDING, yOff, "Enable battle resurrection", br.enabled, function(val)
        br.enabled = val;
        if (val) then
            EnableTracker();
        else
            DisableTracker();
        end
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateCheckbox(parent, PADDING, yOff, "Hide when out of combat", br.hideOutOfCombat, function(val)
        br.hideOutOfCombat = val;
        OnTick();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateCheckbox(parent, PADDING, yOff, "Lock position", br.locked, function(val)
        br.locked = val;
        ApplyLock();
        OnTick();
    end));
    yOff = yOff - ROW_HEIGHT;

    Track(CreateCheckbox(parent, PADDING, yOff, "Show when unlocked", br.showWhenUnlocked, function(val)
        br.showWhenUnlocked = val;
        OnTick();
    end));
    yOff = yOff - ROW_HEIGHT;

    local scaleLabel = parent:CreateFontString(nil, "OVERLAY");
    scaleLabel:SetFont(FONT, 11);
    scaleLabel:SetPoint("TOPLEFT", PADDING, yOff - 5);
    scaleLabel:SetTextColor(unpack(COLOR_MUTED));
    scaleLabel:SetText("Scale:");
    Track(scaleLabel);

    local scalePct = parent:CreateFontString(nil, "OVERLAY");
    scalePct:SetFont(FONT, 11);
    scalePct:SetWidth(44);
    scalePct:SetPoint("TOPLEFT", PADDING + 90, yOff - 5);
    scalePct:SetTextColor(1, 1, 1);
    scalePct:SetText(math.floor((br.scale or 1.0) * 100) .. "%");
    Track(scalePct);

    local function ApplyScaleStep(delta)
        local cur = math.floor((br.scale or 1.0) * 10 + 0.5);
        cur = math.max(5, math.min(20, cur + delta)); -- 50% .. 200%
        br.scale = cur / 10;
        if (_frame) then _frame:SetScale(br.scale); end
        scalePct:SetText(math.floor(br.scale * 100) .. "%");
    end

    local minusBtn = CreateActionButton(parent, PADDING + 52, yOff, "-", 34, function()
        ApplyScaleStep(-1);
    end);
    Track(minusBtn);

    local plusBtn = CreateActionButton(parent, PADDING + 138, yOff, "+", 34, function()
        ApplyScaleStep(1);
    end);
    Track(plusBtn);

    yOff = yOff - ROW_HEIGHT - 8;

    Track(CreateActionButton(parent, PADDING, yOff, "Reset", 120, function()
        ST:ResetBrezPosition();
    end));
    yOff = yOff - ROW_HEIGHT - 8;

    return yOff;
end
