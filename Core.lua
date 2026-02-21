local ADDON_NAME, NS = ...;

-------------------------------------------------------------------------------
-- Module namespace (shared across ReversionRaidTools files via addon table)
-------------------------------------------------------------------------------

local ST = {};
NS.SpellTracker = ST;

-- Tracked player data
ST.trackedPlayers = {};   -- "Name-Realm" -> { class, spec, spells = { [spellID] = state } }
ST.excludedPlayers = {};  -- "Name-Realm" -> true
ST._recentCasts = {};     -- "Name" -> GetTime() of last cast (for interrupt correlation)

-- Player info
ST.playerClass = nil;
ST.playerName = nil;

-- DB reference (set on init)
ST.db = nil;

-------------------------------------------------------------------------------
-- Print Helper
-------------------------------------------------------------------------------

function ST:Print(msg)
    print("|cFF33FF99[Reversion Raid Tools]|r " .. tostring(msg))
end

local function IsAddonOutdated()
    local tocInterface = nil;
    if (C_AddOns and C_AddOns.GetAddOnMetadata) then
        tocInterface = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Interface");
    elseif (GetAddOnMetadata) then
        tocInterface = GetAddOnMetadata(ADDON_NAME, "Interface");
    end
    if (not tocInterface) then return false; end

    -- Parse highest supported interface from .toc (e.g. "120000, 120001" → 120001)
    local maxToc = 0;
    for num in tostring(tocInterface):gmatch("(%d+)") do
        local n = tonumber(num);
        if (n and n > maxToc) then maxToc = n; end
    end

    -- Current client interface version
    local clientInterface = select(4, GetBuildInfo()) or 0;
    -- Compare major version (first 2 digits = expansion.major)
    -- e.g. toc 120001, client 120100 → outdated
    return clientInterface > maxToc;
end

function ST:PrintWelcome()
    ST:Print("Reversion Raid Tools — Menu: /rrt");
    if (IsAddonOutdated()) then
        print("|cFFFF9900[Reversion Raid Tools] WARNING:|r Addon may be outdated for this game version. Some features might not work correctly.");
    end
end

-------------------------------------------------------------------------------
-- DB Defaults
-------------------------------------------------------------------------------

local DEFAULTS = {
    frames = {},  -- array of custom frame configs
    interruptFrame = nil,
    profiles = {},
    activeProfile = nil,
    autoLoad = {},  -- { HEALER = "profileName", DAMAGER = "profileName", TANK = "profileName" }
    uiScale = 1.0,
    battleRez   = { enabled = false, position = nil, hideOutOfCombat = false, locked = false, scale = 1.0, showWhenUnlocked = true },
    combatTimer  = { enabled = false, position = nil, hideOutOfCombat = false, locked = false, scale = 1.0 },
    marksBar    = { enabled = false, position = nil, locked = false, scale = 1.0, showTargetMarks = true, showWorldMarks = true, showRaidTools = true, pullTimer = 10 },
    raidGroups   = { profiles = {}, currentSlots = {} },
    note         = { text = "", title = "", saved = {} },
};
local MAX_SAVED_CUSTOM_FRAMES = 20;

local function TrimText(s)
    if (type(s) ~= "string") then return ""; end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""));
end

local function RepairFrameNames(frames)
    if (type(frames) ~= "table") then return; end

    local usedAuto = {};
    local function NextAutoName()
        local idx = 1;
        while (usedAuto[idx]) do
            idx = idx + 1;
        end
        usedAuto[idx] = true;
        return "Frame " .. idx;
    end

    for i = 1, #frames do
        local cfg = frames[i];
        if (type(cfg) == "table") then
            local name = TrimText(cfg.name);
            local keepCurrent = (name ~= "");
            if (keepCurrent) then
                local n = tonumber(name:match("^Frame%s+(%d+)$"));
                if (n and n > 0) then
                    if (usedAuto[n]) then
                        keepCurrent = false;
                    else
                        usedAuto[n] = true;
                    end
                end
            end

            if (not keepCurrent) then
                cfg.name = NextAutoName();
            else
                cfg.name = name;
            end
        end
    end
end

local FRAME_DEFAULTS = {
    name         = "New Frame",
    spells       = {},        -- { [spellID] = true, ... }
    enabled      = true,
    layout       = "bar",     -- "bar" or "icon"
    locked       = false,
    position     = nil,
    barWidth     = 220,
    barHeight    = 28,
    barAlpha     = 0.9,
    displayScale = 1.0,
    iconSize     = 28,
    iconSpacing  = 2,
    hideOutOfCombat = false,
    groupMode    = "any",    -- "any" | "party" | "raid"
    showNames    = true,
    growUp       = false,
    showSelf     = true,
    sortMode     = "remaining",
    selfOnTop    = false,
    font         = "Friz Quadrata TT",
    fontOutline  = "OUTLINE",
};
ST.FRAME_DEFAULTS = FRAME_DEFAULTS;

local INTERRUPT_FRAME_DEFAULTS = {
    name            = "Interrupts",
    spells          = {},        -- interrupt-only selection
    enabled         = false,
    layout          = "bar",
    locked          = false,
    position        = { point = "CENTER", relativePoint = "CENTER", x = 0, y = 0, isTitleAnchor = true },
    barWidth        = 220,
    barHeight       = 28,
    barAlpha        = 0.9,
    displayScale    = 1.0,
    iconSize        = 28,
    iconSpacing     = 2,
    hideOutOfCombat = false,
    groupMode       = "any",     -- "any" | "party" | "raid"
    showNames       = true,
    growUp          = false,
    showSelf        = true,
    sortMode        = "remaining",
    selfOnTop       = false,
    font            = "Friz Quadrata TT",
    fontOutline     = "OUTLINE",
    isInterruptFrame = true,
};

local function getDB()
    if (not _G.RRTDB) then _G.RRTDB = {}; end
    local db = _G.RRTDB;
    for k, v in pairs(DEFAULTS) do
        if (db[k] == nil) then
            if (type(v) == "table") then
                local copy = {};
                for dk, dv in pairs(v) do copy[dk] = dv; end
                db[k] = copy;
            else
                db[k] = v;
            end
        end
    end

    -- Safety net: recover from corrupted/duplicated frame lists in saved variables.
    if (type(db.frames) ~= "table") then
        db.frames = {};
    else
        local sanitized = {};
        for i = 1, #db.frames do
            local cfg = db.frames[i];
            if (type(cfg) == "table") then
                sanitized[#sanitized + 1] = cfg;
                if (#sanitized >= MAX_SAVED_CUSTOM_FRAMES) then
                    break;
                end
            end
        end
        if (#sanitized ~= #db.frames) then
            db.frames = sanitized;
        end
    end
    RepairFrameNames(db.frames);

    -- Backfill nested tool defaults for existing users (older DBs may miss keys).
    if (type(db.battleRez) == "table") then
        for k, v in pairs(DEFAULTS.battleRez) do
            if (db.battleRez[k] == nil) then
                db.battleRez[k] = v;
            end
        end
    end
    if (type(db.combatTimer) == "table") then
        for k, v in pairs(DEFAULTS.combatTimer) do
            if (db.combatTimer[k] == nil) then
                db.combatTimer[k] = v;
            end
        end
    end
    if (type(db.marksBar) == "table") then
        for k, v in pairs(DEFAULTS.marksBar) do
            if (db.marksBar[k] == nil) then
                db.marksBar[k] = v;
            end
        end
    end
    if (type(db.note) == "table") then
        for k, v in pairs(DEFAULTS.note) do
            if (db.note[k] == nil) then
                db.note[k] = v;
            end
        end
    end

    ST.db = db;
    return db;
end
function ST:GetFrameConfig(frameIndex)
    local db = getDB();
    if (frameIndex == "interrupts") then
        if (not db.interruptFrame) then db.interruptFrame = {}; end
        for k, v in pairs(INTERRUPT_FRAME_DEFAULTS) do
            if (db.interruptFrame[k] == nil) then
                if (type(v) == "table") then
                    local copy = {};
                    for dk, dv in pairs(v) do copy[dk] = dv; end
                    db.interruptFrame[k] = copy;
                else
                    db.interruptFrame[k] = v;
                end
            end
        end

        -- First-time setup: preselect all interrupt spells for the dedicated frame.
        if (not db.interruptFrame._initializedInterrupts) then
            db.interruptFrame.spells = db.interruptFrame.spells or {};
            for spellID, spell in pairs(ST.spellDB or {}) do
                if (spell.category == "interrupt") then
                    db.interruptFrame.spells[spellID] = true;
                end
            end
            db.interruptFrame._initializedInterrupts = true;
        end
        if (db.interruptFrame.position and db.interruptFrame.position.isTitleAnchor == nil) then
            db.interruptFrame.position.point = "CENTER";
            db.interruptFrame.position.relativePoint = "CENTER";
            db.interruptFrame.position.isTitleAnchor = true;
        end
        db.interruptFrame.name = "Interrupts";
        return db.interruptFrame;
    else
        local frameConfig = db.frames[frameIndex];
        if (not frameConfig) then return nil; end
        -- Apply defaults for missing fields
        for k, v in pairs(FRAME_DEFAULTS) do
            if (frameConfig[k] == nil) then
                if (type(v) == "table") then
                    local copy = {};
                    for dk, dv in pairs(v) do copy[dk] = dv; end
                    frameConfig[k] = copy;
                else
                    frameConfig[k] = v;
                end
            end
        end
        return frameConfig;
    end
end

-------------------------------------------------------------------------------
-- Init / Enable / Disable
-------------------------------------------------------------------------------

function ST:Init()
    getDB();
end

function ST:Enable()
    getDB();

    -- Always start with preview/test disabled after login/reload.
    ST._previewActive = false;
    ST._intTestActive = nil;
    if (ST.DeactivatePreview) then
        ST:DeactivatePreview();
    end

    -- Safety: if ALL frames are disabled, re-enable them all.
    -- (Can happen if a /reload occurred while the old Test button had set them all to false.)
    local db = ST.db;
    if (db and db.frames and #db.frames > 0) then
        local anyEnabled = false;
        for _, fc in ipairs(db.frames) do
            if (fc.enabled) then anyEnabled = true; break; end
        end
        if (not anyEnabled) then
            for _, fc in ipairs(db.frames) do
                fc.enabled = true;
            end
        end
    end

    local _, cls = UnitClass("player");
    ST.playerClass = cls;
    ST.playerName = UnitName("player");

    -- Engine.lua handles the rest (events, detection, display)
    if (ST.EnableEngine) then
        ST:EnableEngine();
    end
end

function ST:Disable()
    if (ST.DisableEngine) then
        ST:DisableEngine();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
end

-------------------------------------------------------------------------------
-- Bootstrap
-------------------------------------------------------------------------------

local loader = CreateFrame("Frame");
loader:RegisterEvent("ADDON_LOADED");
loader:SetScript("OnEvent", function(self, event, addonName)
    if (event == "ADDON_LOADED") then
        if (addonName ~= ADDON_NAME) then return; end
        self:UnregisterEvent("ADDON_LOADED");
        self:RegisterEvent("PLAYER_LOGIN");

        ST:Init();
        ST:Enable();
    elseif (event == "PLAYER_LOGIN") then
        self:UnregisterEvent("PLAYER_LOGIN");
        ST:PrintWelcome();
    end
end);







