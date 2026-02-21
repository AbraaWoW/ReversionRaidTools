local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Combat Timer
--
-- Always visible when enabled: counts up during combat, shows 0:00.0 at rest.
-- Options: hide out of combat, lock position, scale.
-- Uses OnUpdate for smooth sub-second display (standard addon approach).
-------------------------------------------------------------------------------

local _frame    = nil;
local _inCombat = false;
local _total    = 0;

local function FormatTime(t)
    local s = t < 0 and 0 or t;
    return string.format("%d:%02d.%1d",
        math.floor(s / 60),
        math.floor(s % 60),
        math.floor((s * 10) % 10));
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ShouldShow()
    if not ST.db or not ST.db.combatTimer then return false; end
    local ct = ST.db.combatTimer;
    if not ct.enabled then return false; end
    if ct.hideOutOfCombat and not _inCombat then return false; end
    return true;
end

local function RefreshVisibility()
    if not _frame then return; end
    if ShouldShow() then _frame:Show(); else _frame:Hide(); end
end

local function ApplyLock()
    if not _frame or not ST.db or not ST.db.combatTimer then return; end
    local locked = ST.db.combatTimer.locked;
    _frame:SetMovable(not locked);
    _frame:EnableMouse(not locked);
end

local function ApplyScale()
    if not _frame or not ST.db or not ST.db.combatTimer then return; end
    _frame:SetScale(ST.db.combatTimer.scale or 1.0);
end

-------------------------------------------------------------------------------
-- Frame
-------------------------------------------------------------------------------

local function CreateCombatTimerFrame()
    if _frame then return _frame; end

    local f = CreateFrame("Frame", "ARTCombatTimerFrame", UIParent, "BackdropTemplate");
    f:SetSize(90, 30);
    f:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    f:SetFrameStrata("HIGH");
    f:SetClampedToScreen(true);
    f:SetMovable(true);
    f:EnableMouse(true);
    f:RegisterForDrag("LeftButton");
    f:SetScript("OnDragStart", function(self)
        if self:IsMovable() then self:StartMoving(); end
    end);
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing();
        if ST.db and ST.db.combatTimer then
            ST.db.combatTimer.position = { left = self:GetLeft(), top = self:GetTop() };
        end
    end);

    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    });
    f:SetBackdropColor(0, 0, 0, 0.7);
    f:SetBackdropBorderColor(0.1, 0.1, 0.1, 0.7);

    local txt = f:CreateFontString(nil, "OVERLAY");
    txt:SetFont("Fonts\\FRIZQT__.TTF", 18, "OUTLINE");
    txt:SetPoint("CENTER", 0, 0);
    txt:SetTextColor(1, 1, 1, 1);
    txt:SetShadowOffset(1, -1);
    txt:SetText("0:00.0");
    f.txt = txt;

    f:SetScript("OnUpdate", function(self, elapsed)
        if not _inCombat then return; end
        _total = _total + elapsed;
        self.txt:SetText(FormatTime(_total));
    end);

    f:Hide();
    _frame = f;
    return f;
end

local function ApplySavedPosition(f)
    local pos = ST.db and ST.db.combatTimer and ST.db.combatTimer.position;
    f:ClearAllPoints();
    if pos and pos.left and pos.top then
        f:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", pos.left, pos.top);
    else
        f:SetPoint("CENTER", UIParent, "CENTER", 0, 200);
    end
end

-------------------------------------------------------------------------------
-- Combat events
-------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame");
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED");
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED");
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        if not ST.db or not ST.db.combatTimer or not ST.db.combatTimer.enabled then return; end
        _total    = 0;
        _inCombat = true;
        if _frame then _frame.txt:SetText("0:00.0"); end
        RefreshVisibility();
    elseif event == "PLAYER_REGEN_ENABLED" then
        _inCombat = false;
        if _frame then _frame.txt:SetText("0:00.0"); end
        RefreshVisibility();
    end
end);

-------------------------------------------------------------------------------
-- Bootstrap
-------------------------------------------------------------------------------

local initFrame = CreateFrame("Frame");
initFrame:RegisterEvent("PLAYER_LOGIN");
initFrame:SetScript("OnEvent", function(self, event)
    self:UnregisterEvent("PLAYER_LOGIN");
    CreateCombatTimerFrame();
    ApplySavedPosition(_frame);
    ApplyLock();
    ApplyScale();
    RefreshVisibility();
end);

-------------------------------------------------------------------------------
-- Public API (used by Options.lua Tools tab)
-------------------------------------------------------------------------------

function ST:ResetCombatTimerPosition()
    if ST.db and ST.db.combatTimer then
        ST.db.combatTimer.position = nil;
    end
    if _frame then
        ApplySavedPosition(_frame);
    end
end

-- Build the Tools tab Combat Timer section (called from Options.lua)
function ST:BuildCombatTimerSection(parent, yOff, FONT, PADDING, ROW_HEIGHT,
    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,
    SkinButton, CreateCheckbox, CreateActionButton, Track)

    local db = ST.db;
    if not db or not db.combatTimer then return yOff; end
    local ct = db.combatTimer;

    -- Section title
    local title = parent:CreateFontString(nil, "OVERLAY");
    title:SetFont(FONT, 13, "OUTLINE");
    title:SetPoint("TOPLEFT", PADDING, yOff);
    title:SetTextColor(unpack(COLOR_ACCENT));
    title:SetText("Combat Timer");
    Track(title);
    yOff = yOff - 24;

    -- Enable toggle
    Track(CreateCheckbox(parent, PADDING, yOff, "Enable combat timer", ct.enabled, function(val)
        ct.enabled = val;
        if not val then
            _inCombat = false;
            if _frame then _frame:Hide(); end
        else
            if _frame then _frame.txt:SetText("0:00.0"); end
            RefreshVisibility();
        end
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Hide out of combat toggle
    Track(CreateCheckbox(parent, PADDING, yOff, "Hide when out of combat", ct.hideOutOfCombat, function(val)
        ct.hideOutOfCombat = val;
        RefreshVisibility();
    end));
    yOff = yOff - ROW_HEIGHT;

    -- Lock position toggle
    Track(CreateCheckbox(parent, PADDING, yOff, "Lock position", ct.locked, function(val)
        ct.locked = val;
        ApplyLock();
    end));
    yOff = yOff - ROW_HEIGHT - 8;

    -- Scale row: label  [−]  [100%]  [+]
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
    scalePct:SetText(math.floor((ct.scale or 1.0) * 100) .. "%");
    Track(scalePct);

    local function ApplyScaleStep(delta)
        local cur = math.floor((ct.scale or 1.0) * 10 + 0.5);
        cur = math.max(5, math.min(20, cur + delta));  -- 50% … 200%
        ct.scale = cur / 10;
        if _frame then _frame:SetScale(ct.scale); end
        scalePct:SetText(math.floor(ct.scale * 100) .. "%");
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

    -- Reset position button
    Track(CreateActionButton(parent, PADDING, yOff, "Reset", 120, function()
        ST:ResetCombatTimerPosition();
    end));
    yOff = yOff - ROW_HEIGHT - 8;

    return yOff;
end



