local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

local LSM = LibStub and LibStub("LibSharedMedia-3.0", true);

-------------------------------------------------------------------------------
-- Shared constants (exported for sub-files)
-------------------------------------------------------------------------------

ST._SOLID = "Interface\\BUTTONS\\WHITE8X8";

ST._STATE_ORDER = { ready = 0, active = 1, cooldown = 2 };

ST._BAR_POOL_SIZE  = 80;   -- max rows per frame (40 players * 2 spells)
ST._ICON_POOL_SIZE = 120;  -- max spell icons across all players

local _frameID = 0;
function ST._FrameName(tag)
    _frameID = _frameID + 1;
    return "RRT_" .. tag .. "_" .. _frameID;
end

-------------------------------------------------------------------------------
-- Display frame storage
-------------------------------------------------------------------------------

ST.displayFrames = {};      -- frameIndex (number) -> { frame, title, barPool/iconPool/namePool }

-------------------------------------------------------------------------------
-- Shared helpers (exported for sub-files)
-------------------------------------------------------------------------------

ST._perf = ST._perf or { enabled = false, stats = {} };

function ST:SetPerfEnabled(enabled)
    local on = enabled and true or false;
    ST._perf.enabled = on;
    if (RRTDB and RRTDB.Settings) then
        RRTDB.Settings.SpellTrackerPerf = on;
    end
end

function ST:ResetPerfStats()
    if (ST._perf) then
        ST._perf.stats = {};
    end
end

function ST:_PerfStart()
    if (not ST._perf or not ST._perf.enabled) then return nil; end
    return debugprofilestop();
end

function ST:_PerfStop(metric, startedAt)
    if (not metric or not startedAt or not ST._perf or not ST._perf.enabled) then return; end
    local elapsed = debugprofilestop() - startedAt;
    local s = ST._perf.stats[metric];
    if (not s) then
        s = { count = 0, total = 0, max = 0 };
        ST._perf.stats[metric] = s;
    end
    s.count = s.count + 1;
    s.total = s.total + elapsed;
    if (elapsed > s.max) then s.max = elapsed; end
end

function ST:GetPerfReport()
    local perf = ST._perf;
    if (not perf) then return "SpellTracker perf unavailable."; end
    local lines = {};
    table.insert(lines, string.format("SpellTracker perf: %s", perf.enabled and "ON" or "OFF"));

    local rows = {};
    for name, s in pairs(perf.stats or {}) do
        local avg = (s.count > 0) and (s.total / s.count) or 0;
        table.insert(rows, { name = name, count = s.count, total = s.total, avg = avg, max = s.max });
    end
    table.sort(rows, function(a, b) return a.total > b.total; end);

    if (#rows == 0) then
        table.insert(lines, "No samples yet.");
        return table.concat(lines, "\n");
    end

    local limit = math.min(8, #rows);
    for i = 1, limit do
        local r = rows[i];
        table.insert(lines, string.format(
            "%d) %s - total %.2fms, avg %.3fms, max %.3fms, n=%d",
            i, r.name, r.total, r.avg, r.max, r.count
        ));
    end
    return table.concat(lines, "\n");
end

local _textureCache = {};

function ST._GetSpellTexture(spellID)
    local cached = _textureCache[spellID];
    if (cached ~= nil) then return cached; end
    local ok, tex = pcall(C_Spell.GetSpellTexture, spellID);
    local result = (ok and tex) or nil;
    _textureCache[spellID] = result or false;
    return result;
end

function ST._GetFontPath(fontName)
    if (not fontName or fontName == "" or fontName == "Global Font") then
        fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT";
    end
    if (LSM) then
        local path = LSM:Fetch("font", fontName);
        if (path) then return path; end
    end
    return "Fonts\\FRIZQT__.TTF";
end

function ST._ResolveFrameFontSize(frameConfig, fallback, minSize, maxSize)
    local size = tonumber(frameConfig and frameConfig.fontSize) or fallback or 12;
    local minV = minSize or 8;
    local maxV = maxSize or 40;
    if (size < minV) then size = minV; end
    if (size > maxV) then size = maxV; end
    return math.floor(size + 0.5);
end

function ST._FormatTime(seconds)
    if (seconds <= 0) then return ""; end
    if (seconds < 10) then return string.format("%.1f", seconds); end
    if (seconds < 60) then return string.format("%.0f", seconds); end
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60));
end

function ST._ApplyIconState(ico, state, spellID, cdEnd, activeEnd, baseCd, now)
    local tex = ST._GetSpellTexture(spellID);
    if (tex) then ico.icon:SetTexture(tex); end

    if (state == "ready") then
        ico.icon:SetDesaturated(false);
        ico.cooldown:Clear();
        ico.text:SetText("");
        ico.glow:Hide();
    elseif (state == "active") then
        ico.icon:SetDesaturated(false);
        ico.cooldown:Clear();
        local remaining = math.max(0, activeEnd - now);
        ico.text:SetText(ST._FormatTime(remaining));
        ico.text:SetTextColor(1, 0.9, 0.3);
        ico.glow:Show();
    elseif (state == "cooldown") then
        ico.icon:SetDesaturated(true);
        local remaining = math.max(0, cdEnd - now);
        if (remaining > 0) then
            ico.cooldown:SetCooldown(cdEnd - baseCd, baseCd);
        else
            ico.cooldown:Clear();
        end
        ico.text:SetText(ST._FormatTime(remaining));
        ico.text:SetTextColor(1, 1, 1);
        ico.glow:Hide();
    end
end

-------------------------------------------------------------------------------
-- Collect sorted entries for a custom frame
-------------------------------------------------------------------------------

local _sortEntries = {};
local _interruptAnchorDragging = false;

function ST._CollectSortedEntries(frameIndex)
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return {}; end

    wipe(_sortEntries);
    local entries = _sortEntries;
    local now = GetTime();
    local selectedSpells = frameConfig.spells;

    for playerName, player in pairs(ST.trackedPlayers) do
        local isSelf = (playerName == ST.playerName);
        if (isSelf and not frameConfig.showSelf) then
            -- Skip self
        else
            for spellID, spellState in pairs(player.spells) do
                local spellData = ST.spellDB[spellID];
                local isInterruptSpell = (spellData and spellData.category == "interrupt");
                local allowByType = (frameConfig.isInterruptFrame and isInterruptSpell) or (not frameConfig.isInterruptFrame);
                if (allowByType and ((ST._previewActive and not frameConfig.isInterruptFrame) or (ST._intTestActive and frameConfig.isInterruptFrame) or selectedSpells[spellID])) then
                    local remaining = 0;
                    if (spellState.state == "cooldown") then
                        remaining = math.max(0, spellState.cdEnd - now);
                    elseif (spellState.state == "active") then
                        remaining = math.max(0, spellState.activeEnd - now);
                    end

                    table.insert(entries, {
                        name      = playerName,
                        class     = player.class,
                        spellID   = spellID,
                        baseCd    = spellState.baseCd,
                        remaining = remaining,
                        state     = spellState.state,
                        cdEnd     = spellState.cdEnd,
                        activeEnd = spellState.activeEnd,
                        isSelf    = isSelf,
                    });
                end
            end
        end
    end

    -- Sort
    local selfOnTop = frameConfig.selfOnTop;
    local sortByBaseCd = (frameConfig.sortMode == "basecd");
    local STATE_ORDER = ST._STATE_ORDER;

    table.sort(entries, function(a, b)
        if (selfOnTop) then
            if (a.isSelf ~= b.isSelf) then return a.isSelf; end
        end
        local aOrder = STATE_ORDER[a.state] or 3;
        local bOrder = STATE_ORDER[b.state] or 3;
        if (aOrder ~= bOrder) then return aOrder < bOrder; end
        if (sortByBaseCd) then return a.baseCd < b.baseCd; end
        return a.remaining < b.remaining;
    end);

    return entries;
end

-------------------------------------------------------------------------------
-- Collect player spells for icon mode
-------------------------------------------------------------------------------

function ST._CollectPlayerFrameSpells(player, frameConfig)
    local spells = {};
    local selectedSpells = frameConfig.spells;
    for spellID, spellState in pairs(player.spells) do
        local spellData = ST.spellDB[spellID];
        local isInterruptSpell = (spellData and spellData.category == "interrupt");
        local allowByType = frameConfig.isInterruptFrame and isInterruptSpell or ((not frameConfig.isInterruptFrame) and (not isInterruptSpell));
        if (allowByType and ((ST._previewActive and not frameConfig.isInterruptFrame) or (ST._intTestActive and frameConfig.isInterruptFrame) or selectedSpells[spellID])) then
            table.insert(spells, {
                spellID   = spellID,
                state     = spellState.state,
                cdEnd     = spellState.cdEnd,
                activeEnd = spellState.activeEnd,
                baseCd    = spellState.baseCd,
            });
        end
    end
    return spells;
end

-------------------------------------------------------------------------------
-- Position persistence
-------------------------------------------------------------------------------

function ST._SavePosition(frameIndex)
    local display = ST.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig) then return; end

    if (frameConfig.isInterruptFrame and display.title and display.title.GetCenter) then
        local tx, ty = display.title:GetCenter();
        local ux, uy = UIParent:GetCenter();
        if (tx and ty and ux and uy) then
            frameConfig.position = {
                point = "CENTER",
                relativePoint = "CENTER",
                x = tx - ux,
                y = ty - uy,
                isTitleAnchor = true,
            };
        end
    else
        local point, _, relativePoint, x, y = display.frame:GetPoint();
        frameConfig.position = { point = point, relativePoint = relativePoint, x = x, y = y };
    end
end

function ST._ApplyInterruptAnchor(frameIndex)
    local display = ST.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (not frameConfig or not frameConfig.isInterruptFrame) then return; end
    if (_interruptAnchorDragging) then return; end

    local p = frameConfig.position;
    local x = 0;
    local y = 0;
    if (p and p.isTitleAnchor) then
        x = p.x or 0;
        y = p.y or 0;
    end

    display.frame:ClearAllPoints();
    if (frameConfig.growUp) then
        -- Title is fixed, bars/icons grow above it.
        display.frame:SetPoint("BOTTOM", UIParent, "CENTER", x, y + 9);
    else
        -- Title is fixed, bars/icons grow below it.
        display.frame:SetPoint("TOP", UIParent, "CENTER", x, y - 9);
    end
end

function ST._RestorePosition(frameIndex)
    local display = ST.displayFrames[frameIndex];
    if (not display or not display.frame) then return; end
    local frameConfig = ST:GetFrameConfig(frameIndex);
    if (frameConfig and frameConfig.isInterruptFrame) then
        ST._ApplyInterruptAnchor(frameIndex);
    elseif (frameConfig and frameConfig.position) then
        local p = frameConfig.position;
        display.frame:ClearAllPoints();
        display.frame:SetPoint(p.point or "CENTER", UIParent, p.relativePoint or "CENTER", p.x or 0, p.y or -150);
    end
end

-------------------------------------------------------------------------------
-- Shared frame factories
-------------------------------------------------------------------------------

function ST._CreateSpellIcon(parent, size)
    local frame = CreateFrame("Frame", ST._FrameName("SpellIcon"), parent);
    frame:SetSize(size, size);

    local icon = frame:CreateTexture(nil, "ARTWORK");
    icon:SetAllPoints();
    icon:SetTexCoord(0.08, 0.92, 0.08, 0.92);
    frame.icon = icon;

    local cd = CreateFrame("Cooldown", ST._FrameName("IconCooldown"), frame, "CooldownFrameTemplate");
    cd:SetAllPoints();
    cd:SetDrawEdge(false);
    cd:SetHideCountdownNumbers(true);
    frame.cooldown = cd;

    local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall");
    text:SetPoint("CENTER", 0, 0);
    text:SetShadowOffset(1, -1);
    text:SetShadowColor(0, 0, 0, 1);
    frame.text = text;

    local glow = CreateFrame("Frame", ST._FrameName("IconGlow"), frame, "BackdropTemplate");
    glow:SetPoint("TOPLEFT", -2, 2);
    glow:SetPoint("BOTTOMRIGHT", 2, -2);
    glow:SetFrameLevel(frame:GetFrameLevel() + 2);
    glow:SetBackdrop({ edgeFile = ST._SOLID, edgeSize = 2 });
    glow:SetBackdropBorderColor(0.30, 0.72, 1.00, 1);
    glow:Hide();
    frame.glow = glow;

    frame:Hide();
    return frame;
end

function ST._CreateTitleBar(frame, frameIndex, frameConfig)
    local label = frameConfig.isInterruptFrame and "Interrupts" or (frameConfig.name or ("Frame " .. frameIndex));

    local title = CreateFrame("Frame", ST._FrameName("TitleBar"), frame);
    title:SetHeight(18);
    if (frameConfig.isInterruptFrame) then
        -- Dedicated interrupts frame: title is the fixed anchor.
        if (frameConfig.growUp) then
            title:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, 0);
            title:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, 0);
        else
            title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 0);
            title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 0);
        end
    elseif (frameConfig.growUp) then
        title:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2);
        title:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2);
    else
        title:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2);
        title:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2);
    end
    title:EnableMouse(true);
    title:RegisterForDrag("LeftButton");
    title:SetScript("OnDragStart", function()
        if (not frameConfig.locked or IsShiftKeyDown()) then
            if (frameConfig.isInterruptFrame) then
                _interruptAnchorDragging = true;
            end
            frame:StartMoving();
        end
    end);
    title:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing();
        ST._SavePosition(frameIndex);
        if (frameConfig.isInterruptFrame) then
            _interruptAnchorDragging = false;
            if (ST._ApplyInterruptAnchor) then
                ST._ApplyInterruptAnchor(frameIndex);
            end
        end
    end);

    local titleBg = title:CreateTexture(nil, "BACKGROUND");
    titleBg:SetAllPoints();
    titleBg:SetTexture(ST._SOLID);
    titleBg:SetVertexColor(0.1, 0.1, 0.1, 0.8);

    local titleText = title:CreateFontString(nil, "OVERLAY");
    titleText:SetFont(
        ST._GetFontPath(frameConfig.font),
        ST._ResolveFrameFontSize(frameConfig, 12, 8, 40),
        frameConfig.fontOutline or "OUTLINE"
    );
    titleText:SetPoint("CENTER", 0, 0);
    titleText:SetText("|cFF4DB7FF" .. label .. " (unlocked)|r");
    title.text = titleText;

    if (frameConfig.locked) then title:Hide(); end

    return title;
end

-------------------------------------------------------------------------------
-- Visibility and RefreshDisplay (coordinator)
-------------------------------------------------------------------------------

local _refreshQueued = false;
function ST:RequestRefreshDisplay()
    if (_refreshQueued) then return; end
    _refreshQueued = true;
    C_Timer.After(0, function()
        _refreshQueued = false;
        if (ST and ST.RefreshDisplay) then
            ST:RefreshDisplay();
        end
    end);
end

function ST:RefreshDisplay()
    local _perfStart = ST:_PerfStart();
    local function _perfDone()
        ST:_PerfStop("RefreshDisplay", _perfStart);
    end
    -- Auto-disable preview when settings panel closes
    if (ST._previewActive) then
        local panelOpen = false;
        local arcPanel = _G["ReversionRaidToolsOptions"];
        if (arcPanel and arcPanel:IsShown()) then panelOpen = true; end
        if (SettingsPanel and SettingsPanel:IsShown()) then panelOpen = true; end
        if (ST._embeddedPanelOpen) then panelOpen = true; end
        if (not panelOpen) then
            ST:DeactivatePreview();
            _perfDone();
            return;
        end
    end

    local inRaid = IsInRaid();
    local inParty = IsInGroup() and (not inRaid);
    local inGroup = inParty or inRaid;
    local show = inGroup or ST._previewActive;
    local db = self.db;
    if (not db or not db.frames) then
        _perfDone();
        return;
    end

    -- Remove orphan display frames that no longer exist in saved config.
    for frameIndex, display in pairs(self.displayFrames) do
        if (type(frameIndex) == "number" and not db.frames[frameIndex]) then
            if (display and display.frame) then
                display.frame:Hide();
                display.frame:SetParent(nil);
            end
            self.displayFrames[frameIndex] = nil;
        end
    end

    local function CanShowFrame(frameConfig)
        if (frameConfig.isInterruptFrame) then
            -- Interrupt Test mode: always show the interrupt frame.
            if (ST._intTestActive) then
                if (frameConfig.hideOutOfCombat and not InCombatLockdown()) then return false; end
                return true;
            end
            -- Normal frame preview: hide the interrupt frame.
            if (ST._previewActive) then return false; end
            if (not frameConfig.enabled) then return false; end
            if (frameConfig.hideOutOfCombat and not InCombatLockdown()) then return false; end
            return true;
        end

        -- Interrupt Test mode: hide all normal frames.
        if (ST._intTestActive) then return false; end

        if (ST._previewActive) then
            return true;
        end

        local canShow = frameConfig.enabled and show;
        if (canShow) then
            local mode = frameConfig.groupMode or "any";
            if (mode == "party" and not inParty) then
                canShow = false;
            elseif (mode == "raid" and not inRaid) then
                canShow = false;
            end

            if (canShow and frameConfig.hideOutOfCombat and not InCombatLockdown()) then
                canShow = false;
            end
        end
        return canShow;
    end

    local function RenderFrame(frameIndex, frameConfig)
        local canShow = CanShowFrame(frameConfig);
        if (canShow) then
            local layout = frameConfig.layout or "bar";
            if (layout == "bar") then
                ST._BuildBarFrame(frameIndex);
                local display = self.displayFrames[frameIndex];
                if (display and display.frame) then
                    display.frame:Show();
                    if (ST._previewActive and not frameConfig.isInterruptFrame and not frameConfig.position) then
                        local idx = tonumber(frameIndex) or 1;
                        local col = (idx - 1) % 3;
                        local row = math.floor((idx - 1) / 3);
                        local x = -320 + (col * 320);
                        local y = 140 - (row * 180);
                        display.frame:ClearAllPoints();
                        display.frame:SetPoint("CENTER", UIParent, "CENTER", x, y);
                    end
                end
                ST._RenderBarFrame(frameIndex);
            elseif (layout == "icon") then
                ST._BuildIconFrame(frameIndex);
                local display = self.displayFrames[frameIndex];
                if (display and display.frame) then
                    display.frame:Show();
                    if (ST._previewActive and not frameConfig.isInterruptFrame and not frameConfig.position) then
                        local idx = tonumber(frameIndex) or 1;
                        local col = (idx - 1) % 3;
                        local row = math.floor((idx - 1) / 3);
                        local x = -320 + (col * 320);
                        local y = 140 - (row * 180);
                        display.frame:ClearAllPoints();
                        display.frame:SetPoint("CENTER", UIParent, "CENTER", x, y);
                    end
                end
                ST._RenderIconFrame(frameIndex);
            end
        else
            local display = self.displayFrames[frameIndex];
            if (display and display.frame) then
                display.frame:Hide();
            end
        end
    end

    for frameIndex, frameConfig in ipairs(db.frames) do
        -- Ensure defaults are applied
        ST:GetFrameConfig(frameIndex);
        RenderFrame(frameIndex, frameConfig);
    end

    -- Dedicated interrupts frame (independent from normal frames).
    local interruptConfig = ST:GetFrameConfig("interrupts");
    if (interruptConfig) then
        RenderFrame("interrupts", interruptConfig);
    end
    _perfDone();
end

-------------------------------------------------------------------------------
-- Cleanup
-------------------------------------------------------------------------------

function ST:HideAllDisplays()
    for _, display in pairs(self.displayFrames) do
        if (display.frame) then
            display.frame:Hide();
        end
    end
end

function ST:ResetPosition(frameIndex)
    local display = self.displayFrames[frameIndex];
    local frameConfig = self:GetFrameConfig(frameIndex);
    if (display and display.frame) then
        display.frame:ClearAllPoints();
        display.frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150);
    end
    if (frameConfig) then
        frameConfig.position = nil;
    end
end

-------------------------------------------------------------------------------
-- Preview Mode
-------------------------------------------------------------------------------

local PREVIEW_NAME_POOL = {
    "Thrall", "Jaina", "Valeera", "Anduin", "Sylvanas", "Khadgar",
    "Tyrande", "Voljin", "Rexxar", "Uther", "Malfurion", "Alleria",
    "Velen", "Kaelthas", "Garrosh", "Muradin",
};
local PREVIEW_CLASS_POOL = {
    "DEATHKNIGHT", "DEMONHUNTER", "DRUID", "EVOKER", "HUNTER", "MAGE",
    "MONK", "PALADIN", "PRIEST", "ROGUE", "SHAMAN", "WARLOCK", "WARRIOR",
};
local PREVIEW_MODE_COUNTS = {
    party5 = 5,
    raid20 = 20,
    raid40 = 40,
};
local PREVIEW_MIN_SPELLS = 4;
local PREVIEW_MAX_SPELLS = 9;

local function ShuffleArray(t)
    for i = #t, 2, -1 do
        local j = math.random(i);
        t[i], t[j] = t[j], t[i];
    end
end

local function BuildRandomPreviewPlayer(class, spec)
    local player = { class = class, spec = spec, spells = {} };
    local classSpells = ST:GetSpellsForClass(class, spec);

    local spellIDs = {};
    for spellID in pairs(classSpells) do
        table.insert(spellIDs, spellID);
    end
    if (#spellIDs == 0) then return player; end

    ShuffleArray(spellIDs);
    local wanted = math.random(PREVIEW_MIN_SPELLS, PREVIEW_MAX_SPELLS);
    local count = math.min(#spellIDs, wanted);

    for i = 1, count do
        local spellID = spellIDs[i];
        local spell = classSpells[spellID];
        local cd = (spell.cdBySpec and spec and spell.cdBySpec[spec]) or spell.cd;
        player.spells[spellID] = {
            category   = spell.category,
            state      = "ready",
            cdEnd      = 0,
            activeEnd  = 0,
            charges    = spell.charges or 1,
            maxCharges = spell.charges or 1,
            baseCd     = cd,
        };
    end

    -- Ensure interrupt preview always has at least one kick if available.
    local hasInterrupt = false;
    for id in pairs(player.spells) do
        local s = classSpells[id];
        if (s and s.category == "interrupt") then
            hasInterrupt = true;
            break;
        end
    end
    if (not hasInterrupt) then
        for id, s in pairs(classSpells) do
            if (s.category == "interrupt") then
                local cd = (s.cdBySpec and spec and s.cdBySpec[spec]) or s.cd;
                player.spells[id] = {
                    category   = s.category,
                    state      = "ready",
                    cdEnd      = 0,
                    activeEnd  = 0,
                    charges    = s.charges or 1,
                    maxCharges = s.charges or 1,
                    baseCd     = cd,
                };
                break;
            end
        end
    end

    return player;
end

local _previewTimer = nil;

function ST:GetPreviewMode()
    return ST._previewMode or "party5";
end

function ST:SetPreviewMode(mode)
    local key = tostring(mode or ""):lower();
    if (not PREVIEW_MODE_COUNTS[key]) then
        key = "party5";
    end
    ST._previewMode = key;
    if (ST._previewActive) then
        -- Rebuild preview roster with the new mode.
        ST:ActivatePreview();
    end
end

function ST:ActivatePreview()
    local mode = ST:GetPreviewMode();
    local targetCount = PREVIEW_MODE_COUNTS[mode] or PREVIEW_MODE_COUNTS.party5;

    if (not ST._previewActive) then
        ST._savedTrackedPlayers = ST.trackedPlayers;
    end
    ST._previewActive = true;
    ST.trackedPlayers = {};

    local names = {};
    for i = 1, #PREVIEW_NAME_POOL do
        names[i] = PREVIEW_NAME_POOL[i];
    end
    ShuffleArray(names);

    local classes = {};
    for i = 1, #PREVIEW_CLASS_POOL do
        classes[i] = PREVIEW_CLASS_POOL[i];
    end
    ShuffleArray(classes);

    local playerName = ST.playerName or UnitName("player");
    local playerClass = ST.playerClass or select(2, UnitClass("player"));
    local playerSpec = GetSpecializationInfo(GetSpecialization() or 0) or nil;
    local reserveSelf = (playerName and playerClass) and 1 or 0;

    local count = math.max(0, targetCount - reserveSelf);
    for i = 1, count do
        local name = names[((i - 1) % #names) + 1] .. i;
        local class = classes[((i - 1) % #classes) + 1];
        local player = BuildRandomPreviewPlayer(class, nil);
        ST.trackedPlayers[name] = player;
    end

    -- Keep self in preview to make testing selected spells easier.
    if (playerName and playerClass) then
        local selfPlayer = BuildRandomPreviewPlayer(playerClass, playerSpec);
        ST.trackedPlayers[playerName] = selfPlayer;
    end

    -- Start simulation ticker
    if (_previewTimer) then _previewTimer:Cancel(); end
    _previewTimer = C_Timer.NewTicker(2, function()
        if (not ST._previewActive) then
            if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end
            return;
        end
        local now = GetTime();
        for _, player in pairs(ST.trackedPlayers) do
            for spellID, spellState in pairs(player.spells) do
                if (spellState.state == "ready" and math.random() < 0.3) then
                    local spellData = ST.spellDB[spellID];
                    if (spellData and spellData.duration) then
                        spellState.state = "active";
                        spellState.activeEnd = now + spellData.duration;
                        spellState.cdEnd = now + spellState.baseCd;
                    else
                        spellState.state = "cooldown";
                        spellState.cdEnd = now + spellState.baseCd;
                    end
                end
            end
        end
        ST:RefreshDisplay();
    end);

    ST:RefreshDisplay();
end

function ST:DeactivatePreview()
    ST._previewActive = false;
    if (_previewTimer) then _previewTimer:Cancel(); _previewTimer = nil; end

    if (ST._savedTrackedPlayers) then
        ST.trackedPlayers = ST._savedTrackedPlayers;
        ST._savedTrackedPlayers = nil;
    else
        ST.trackedPlayers = {};
    end

    ST:RefreshDisplay();
end
