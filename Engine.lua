local ADDON_NAME, NS = ...;
local ST = NS.SpellTracker;
if (not ST) then return; end

-------------------------------------------------------------------------------
-- Secret Value Unwrapping
--
-- In Patch 12.0.0, Blizzard introduced "secret values" that restrict addon
-- access to party member spell data. A StatusBar's OnValueChanged callback
-- receives a clean copy bypassing the secret wrapper.
--
-- These frames MUST be created at file scope (clean load-time context).
-------------------------------------------------------------------------------

local _unwrapResult = nil;
local _unwrapFrame = CreateFrame("StatusBar");
_unwrapFrame:SetMinMaxValues(0, 9999999);
_unwrapFrame:SetScript("OnValueChanged", function(_, val)
    _unwrapResult = val;
end);

local _unwrapWorks = true;

local function Unwrap(secretValue)
    if (not _unwrapWorks) then return secretValue; end
    _unwrapResult = nil;
    _unwrapFrame:SetValue(0);
    pcall(_unwrapFrame.SetValue, _unwrapFrame, secretValue);
    return _unwrapResult;
end

local _unwrapWarned = false;

local function ValidateUnwrap()
    local test = Unwrap(47528);
    if (test ~= 47528) then
        _unwrapWorks = false;
        if (not _unwrapWarned and ST.Print) then
            _unwrapWarned = true;
            ST:Print("|cFFFF6600Warning:|r Secret value unwrapping is no longer working. "
                .. "Party/raid member tracking may be inaccurate.");
        end
    else
        _unwrapWorks = true;
    end
end

-- Pre-created watcher frames for group units (must be at file scope)
-- Support up to 40 raid members
local _groupWatchers = {};
local _petWatchers = {};
for i = 1, 40 do
    _groupWatchers[i] = CreateFrame("Frame");
    _petWatchers[i] = CreateFrame("Frame");
end

-- Self-cast watcher frame (must be at file scope for clean context)
local _selfFrame = CreateFrame("Frame");

-- Inspect state
local _inspectPending = {};
local _inspectInProgress = false;
local _inspectCurrentUnit = nil;
local _inspectedNames = {};
local _inspectRetries = {};
local MAX_INSPECT_RETRIES = 3;

-------------------------------------------------------------------------------
-- Group Unit Iterator
--
-- Returns unit IDs based on group type (raid or party).
-------------------------------------------------------------------------------

local function GroupUnitIterator()
    local units = {};
    if (IsInRaid()) then
        for i = 1, 40 do
            local u = "raid" .. i;
            if (UnitExists(u) and not UnitIsUnit(u, "player")) then
                table.insert(units, u);
            end
        end
    elseif (IsInGroup()) then
        for i = 1, 4 do
            local u = "party" .. i;
            if (UnitExists(u)) then
                table.insert(units, u);
            end
        end
    end
    return units;
end

-------------------------------------------------------------------------------
-- CD Resolution
-------------------------------------------------------------------------------

local function ResolveCd(spell, spec)
    if (spell.cdBySpec and spec and spell.cdBySpec[spec]) then
        return spell.cdBySpec[spec];
    end
    return spell.cd;
end

-------------------------------------------------------------------------------
-- Register Player
--
-- Register ALL spells for a player's class (no category filtering).
-- The filtering by frame happens at display time only.
-------------------------------------------------------------------------------

local function RegisterPlayer(name, class)
    if (ST.excludedPlayers[name]) then return; end

    if (not ST.trackedPlayers[name]) then
        ST.trackedPlayers[name] = { class = class, spec = nil, spells = {} };
    end

    local player = ST.trackedPlayers[name];
    player.class = class;

    local classSpells = ST:GetSpellsForClass(class, player.spec);
    for spellID, spell in pairs(classSpells) do
        if (not player.spells[spellID]) then
            player.spells[spellID] = {
                category   = spell.category,
                state      = "ready",
                cdEnd      = 0,
                activeEnd  = 0,
                charges    = spell.charges or 1,
                maxCharges = spell.charges or 1,
                baseCd     = ResolveCd(spell, player.spec),
            };
        end
    end
end

-------------------------------------------------------------------------------
-- Identify Player Spells
-------------------------------------------------------------------------------

local function IdentifyPlayerSpells()
    local class = ST.playerClass;
    local name = ST.playerName;
    if (not class or not name) then return; end

    if (not ST.trackedPlayers[name]) then
        ST.trackedPlayers[name] = { class = class, spec = nil, spells = {} };
    end
    local player = ST.trackedPlayers[name];

    local specIndex = GetSpecialization();
    if (specIndex) then
        player.spec = GetSpecializationInfo(specIndex);
    end

    local classSpells = ST:GetSpellsForClass(class, player.spec);
    for spellID, spell in pairs(classSpells) do
        if (IsSpellKnown(spellID) or IsSpellKnown(spellID, true) or IsPlayerSpell(spellID)) then
            if (not player.spells[spellID]) then
                player.spells[spellID] = {
                    category   = spell.category,
                    state      = "ready",
                    cdEnd      = 0,
                    activeEnd  = 0,
                    charges    = spell.charges or 1,
                    maxCharges = spell.charges or 1,
                    baseCd     = ResolveCd(spell, player.spec),
                };
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Record Spell Cast
-------------------------------------------------------------------------------

local function RecordSpellCast(unit, spellID, name)
    if (not name or ST.excludedPlayers[name]) then return; end

    local resolvedID = ST.spellAliases[spellID] or spellID;
    local spellData = ST.spellDB[resolvedID];
    if (not spellData) then return; end

    local player = ST.trackedPlayers[name];
    if (not player) then
        local ok, _, cls = pcall(UnitClass, unit);
        if (not ok or not cls) then return; end
        RegisterPlayer(name, cls);
        player = ST.trackedPlayers[name];
        if (not player) then return; end
    end

    local spellState = player.spells[resolvedID];
    if (not spellState) then return; end

    local now = GetTime();

    if (spellState.maxCharges > 1) then
        spellState.charges = math.max(0, spellState.charges - 1);
        if (spellState.cdEnd <= now) then
            spellState.cdEnd = now + spellState.baseCd;
        end
        if (spellData.duration) then
            spellState.state = "active";
            spellState.activeEnd = now + spellData.duration;
        elseif (spellState.charges == 0) then
            spellState.state = "cooldown";
        end
    else
        if (spellData.duration) then
            spellState.state = "active";
            spellState.activeEnd = now + spellData.duration;
            spellState.cdEnd = now + spellState.baseCd;
        else
            spellState.state = "cooldown";
            spellState.cdEnd = now + spellState.baseCd;
        end
    end

    ST._recentCasts[name] = now;
end

-------------------------------------------------------------------------------
-- Group Watchers
-------------------------------------------------------------------------------

local function OnGroupSpellCast(self, _, _, _, taintedSpellID)
    local name = UnitName(self.unit);
    local cleanID = Unwrap(taintedSpellID);
    if (cleanID) then
        local resolvedID = ST.spellAliases[cleanID] or cleanID;
        if (ST.spellDB[resolvedID]) then
            RecordSpellCast(self.unit, cleanID, name);
        elseif (name) then
            ST._recentCasts[name] = GetTime();
        end
    end
end

local function OnPetSpellCast(self, _, _, _, taintedSpellID)
    local name = UnitName(self.ownerUnit);
    local cleanID = Unwrap(taintedSpellID);
    if (cleanID) then
        local resolvedID = ST.spellAliases[cleanID] or cleanID;
        if (ST.spellDB[resolvedID]) then
            RecordSpellCast(self.ownerUnit, cleanID, name);
        elseif (name) then
            ST._recentCasts[name] = GetTime();
        end
    end
end

local RefreshGroupWatchers;

RefreshGroupWatchers = function()
    -- Unregister all first
    for i = 1, 40 do
        _groupWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();
    end

    local units = GroupUnitIterator();
    for i, unit in ipairs(units) do
        if (i > 40) then break; end
        _groupWatchers[i].unit = unit;
        _groupWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", unit);
        _groupWatchers[i]:SetScript("OnEvent", OnGroupSpellCast);

        -- Detect pet unit
        local petUnit;
        if (unit:find("^party")) then
            petUnit = unit:gsub("^party", "partypet");
        elseif (unit:find("^raid")) then
            petUnit = unit:gsub("^raid", "raidpet");
        end
        if (petUnit and UnitExists(petUnit)) then
            _petWatchers[i].ownerUnit = unit;
            _petWatchers[i]:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", petUnit);
            _petWatchers[i]:SetScript("OnEvent", OnPetSpellCast);
        end
    end
end;

-------------------------------------------------------------------------------
-- Group Registration and Pruning
-------------------------------------------------------------------------------

local function RegisterGroupByClass()
    local units = GroupUnitIterator();
    for _, u in ipairs(units) do
        local name = UnitName(u);
        local _, cls = UnitClass(u);
        if (name and cls and not ST.trackedPlayers[name] and not ST.excludedPlayers[name]) then
            RegisterPlayer(name, cls);
        end
    end
end

local function PruneTrackedPlayers()
    local active = {};
    local units = GroupUnitIterator();
    for _, u in ipairs(units) do
        local name = UnitName(u);
        if (name) then active[name] = true; end
    end

    if (ST.playerName) then
        active[ST.playerName] = true;
    end

    for name in pairs(ST.trackedPlayers) do
        if (not active[name]) then ST.trackedPlayers[name] = nil; end
    end
    for name in pairs(ST.excludedPlayers) do
        if (not active[name]) then ST.excludedPlayers[name] = nil; end
    end
    for name in pairs(_inspectedNames) do
        if (not active[name]) then _inspectedNames[name] = nil; end
    end
    for name in pairs(_inspectRetries) do
        if (not active[name]) then _inspectRetries[name] = nil; end
    end
end

-------------------------------------------------------------------------------
-- Self-Cooldown Tracking
-------------------------------------------------------------------------------

local function UpdateSelfCooldowns()
    local name = ST.playerName;
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    local now = GetTime();
    for spellID, spellState in pairs(player.spells) do
        if (IsSpellKnown(spellID) or IsPlayerSpell(spellID)) then
            local ok, cdInfo = pcall(C_Spell.GetSpellCooldown, spellID);
            if (ok and cdInfo) then
                local dur = Unwrap(cdInfo.duration);
                local start = Unwrap(cdInfo.startTime);
                if (dur and start and dur > 1.5) then
                    local cdEnd = start + dur;
                    spellState.cdEnd = cdEnd;
                    if (spellState.state == "ready" and cdEnd > now) then
                        local spellData = ST.spellDB[spellID];
                        if (spellData and spellData.duration and spellState.activeEnd > now) then
                            spellState.state = "active";
                        else
                            spellState.state = "cooldown";
                        end
                    end
                end
            end

            local ok2, chargeInfo = pcall(C_Spell.GetSpellCharges, spellID);
            if (ok2 and chargeInfo) then
                local maxCh = Unwrap(chargeInfo.maxCharges);
                if (maxCh and maxCh > 1) then
                    spellState.charges = Unwrap(chargeInfo.currentCharges) or spellState.charges;
                    spellState.maxCharges = maxCh;
                    local cdDur = Unwrap(chargeInfo.cooldownDuration);
                    local cdStart = Unwrap(chargeInfo.cooldownStartTime);
                    if (cdDur and cdStart and cdDur > 0) then
                        spellState.cdEnd = cdStart + cdDur;
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------------
-- Buff Tracking
-------------------------------------------------------------------------------

local function CheckUnitBuffs(unit)
    local name = UnitName(unit);
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end

    local durationSpells;
    for spellID, spellState in pairs(player.spells) do
        local spellData = ST.spellDB[spellID];
        if (spellData and spellData.duration) then
            if (not durationSpells) then durationSpells = {}; end
            durationSpells[spellID] = true;
        end
    end
    if (not durationSpells) then return; end

    local now = GetTime();
    local isPlayer = UnitIsUnit(unit, "player");

    local activeAuras = {};
    if (isPlayer) then
        for spellID in pairs(durationSpells) do
            local aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID);
            if (not aura) then
                aura = C_UnitAuras.GetPlayerAuraBySpellID(spellID, "HARMFUL");
            end
            if (aura) then
                activeAuras[spellID] = aura.expirationTime;
            end
        end
    else
        for i = 1, 40 do
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HELPFUL");
            if (not data) then break; end
            local cleanId = Unwrap(data.spellId);
            if (cleanId and durationSpells[cleanId]) then
                activeAuras[cleanId] = Unwrap(data.expirationTime);
            end
        end
        for i = 1, 40 do
            local data = C_UnitAuras.GetAuraDataByIndex(unit, i, "HARMFUL");
            if (not data) then break; end
            local cleanId = Unwrap(data.spellId);
            if (cleanId and durationSpells[cleanId] and not activeAuras[cleanId]) then
                activeAuras[cleanId] = Unwrap(data.expirationTime);
            end
        end
    end

    for spellID in pairs(durationSpells) do
        local spellState = player.spells[spellID];
        local expiry = activeAuras[spellID];
        if (expiry) then
            if (spellState.state ~= "active" and spellState.cdEnd <= now) then
                spellState.cdEnd = now + spellState.baseCd;
            end
            spellState.state = "active";
            if (expiry > 0) then
                spellState.activeEnd = expiry;
            else
                spellState.activeEnd = now + ST.spellDB[spellID].duration;
            end
        elseif (spellState.state == "active" and now >= spellState.activeEnd) then
            spellState.state = "cooldown";
        end
    end
end

-------------------------------------------------------------------------------
-- State Ticker
-------------------------------------------------------------------------------

local _tickerFrame = CreateFrame("Frame");
local _tickerElapsed = 0;
local TICK_INTERVAL = 0.1;

local function OnTick(_, elapsed)
    _tickerElapsed = _tickerElapsed + elapsed;
    if (_tickerElapsed < TICK_INTERVAL) then return; end
    _tickerElapsed = 0;

    local now = GetTime();
    for _, player in pairs(ST.trackedPlayers) do
        for spellID, s in pairs(player.spells) do
            if (s.state == "active" and now >= s.activeEnd) then
                if (s.maxCharges > 1 and s.charges > 0) then
                    s.state = "ready";
                else
                    s.state = "cooldown";
                end
            end
            if (s.state == "cooldown" and now >= s.cdEnd) then
                if (s.maxCharges > 1) then
                    s.charges = s.charges + 1;
                    if (s.charges >= s.maxCharges) then
                        s.state = "ready";
                        s.cdEnd = 0;
                        s.activeEnd = 0;
                    else
                        s.state = "ready";
                        s.cdEnd = now + s.baseCd;
                    end
                else
                    s.state = "ready";
                    s.cdEnd = 0;
                    s.activeEnd = 0;
                end
            end
        end
    end

    if (ST.RefreshDisplay) then
        ST:RefreshDisplay();
    end
end

-------------------------------------------------------------------------------
-- Inspect System
-------------------------------------------------------------------------------

local function ApplySpecOverrides(player, name, specID)
    -- Check interrupt exclusion
    local intConfig = ST.interruptConfig;
    if (intConfig and intConfig.specsWithoutInterrupt and intConfig.specsWithoutInterrupt[specID]) then
        for spellID, spellState in pairs(player.spells) do
            if (spellState.category == "interrupt") then
                player.spells[spellID] = nil;
            end
        end
    end

    -- Re-evaluate spells based on spec
    local classSpells = ST:GetSpellsForClass(player.class, specID);
    -- Remove spells that don't belong to this spec
    for spellID, spellState in pairs(player.spells) do
        if (not classSpells[spellID]) then
            player.spells[spellID] = nil;
        end
    end
    -- Add spec-specific spells
    for spellID, spell in pairs(classSpells) do
        if (not player.spells[spellID]) then
            player.spells[spellID] = {
                category   = spell.category,
                state      = "ready",
                cdEnd      = 0,
                activeEnd  = 0,
                charges    = spell.charges or 1,
                maxCharges = spell.charges or 1,
                baseCd     = ResolveCd(spell, specID),
            };
        else
            player.spells[spellID].baseCd = ResolveCd(spell, specID);
        end
    end
end

local function ScanTalentModifiers(player)
    local configID = -1;
    local ok, configInfo = pcall(C_Traits.GetConfigInfo, configID);
    if (not ok or not configInfo or not configInfo.treeIDs or #configInfo.treeIDs == 0) then
        return;
    end

    local ok2, nodeIDs = pcall(C_Traits.GetTreeNodes, configInfo.treeIDs[1]);
    if (not ok2 or not nodeIDs) then
        return;
    end

    for _, nodeID in ipairs(nodeIDs) do
        local ok3, nodeInfo = pcall(C_Traits.GetNodeInfo, configID, nodeID);
        if (ok3 and nodeInfo and nodeInfo.activeEntry
            and nodeInfo.activeRank and nodeInfo.activeRank > 0) then
            local entryID = nodeInfo.activeEntry.entryID;
            if (entryID) then
                local ok4, entryInfo = pcall(C_Traits.GetEntryInfo, configID, entryID);
                if (ok4 and entryInfo and entryInfo.definitionID) then
                    local ok5, defInfo = pcall(C_Traits.GetDefinitionInfo, entryInfo.definitionID);
                    if (ok5 and defInfo and defInfo.spellID) then
                        for _, talentMod in ipairs(ST.talentModifiers) do
                            if (talentMod.spellID == defInfo.spellID) then
                                local spellState = player.spells[talentMod.affectsSpell];
                                if (spellState) then
                                    if (talentMod.cdReductionPct) then
                                        spellState.baseCd = math.max(1, spellState.baseCd * (1 - talentMod.cdReductionPct));
                                    elseif (talentMod.cdReduction) then
                                        spellState.baseCd = math.max(1, spellState.baseCd - talentMod.cdReduction);
                                    end
                                end
                            end
                        end

                        if (ST.interruptConfig and ST.interruptConfig.kickBonuses) then
                            local kickMod = ST.interruptConfig.kickBonuses[defInfo.spellID];
                            if (kickMod and player.spells) then
                                for spellID, spellState in pairs(player.spells) do
                                    if (spellState.category == "interrupt") then
                                        spellState.kickBonus = kickMod.reduction;
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

local ProcessNextInspect;

local function ApplyInspectResults(unit)
    local name = UnitName(unit);
    if (not name) then return; end

    local player = ST.trackedPlayers[name];
    if (not player) then
        _inspectedNames[name] = true;
        return;
    end

    local specID = GetInspectSpecialization(unit);
    if (specID and specID > 0) then
        player.spec = specID;
        ApplySpecOverrides(player, name, specID);
        ScanTalentModifiers(player);
        ClearInspectPlayer();
        _inspectedNames[name] = true;
        _inspectRetries[name] = nil;
    else
        ClearInspectPlayer();
        local retries = (_inspectRetries[name] or 0) + 1;
        _inspectRetries[name] = retries;
        if (retries < MAX_INSPECT_RETRIES) then
            C_Timer.After(1, function()
                if (not _inspectedNames[name]) then
                    table.insert(_inspectPending, unit);
                    ProcessNextInspect();
                end
            end);
        else
            _inspectedNames[name] = true;
        end
    end
end

ProcessNextInspect = function()
    if (_inspectInProgress) then return; end
    while (#_inspectPending > 0) do
        local unit = table.remove(_inspectPending, 1);
        if (UnitExists(unit) and UnitIsConnected(unit)) then
            local name = UnitName(unit);
            if (name and not _inspectedNames[name]) then
                _inspectInProgress = true;
                _inspectCurrentUnit = unit;
                NotifyInspect(unit);
                C_Timer.After(5, function()
                    if (_inspectInProgress and _inspectCurrentUnit == unit) then
                        _inspectInProgress = false;
                        _inspectCurrentUnit = nil;
                        local n = UnitName(unit);
                        if (n and not _inspectedNames[n]) then
                            local retries = (_inspectRetries[n] or 0) + 1;
                            _inspectRetries[n] = retries;
                            if (retries < MAX_INSPECT_RETRIES) then
                                table.insert(_inspectPending, unit);
                            end
                        end
                        ProcessNextInspect();
                    end
                end);
                return;
            end
        end
    end
end

local function QueueInspects()
    _inspectPending = {};
    local units = GroupUnitIterator();
    for _, u in ipairs(units) do
        local name = UnitName(u);
        if (name and not _inspectedNames[name]) then
            local player = ST.trackedPlayers[name];
            if (not player or not player.spec) then
                table.insert(_inspectPending, u);
            end
        end
    end
    ProcessNextInspect();
end

-------------------------------------------------------------------------------
-- Mob Interrupt Correlation
-------------------------------------------------------------------------------

local CORRELATE_WINDOW = 0.5;
local RECENT_CAST_TTL  = 1.0;

local function CorrelateInterrupt(unit)
    if (not ST._recentCasts) then return; end
    local now = GetTime();
    local closest, closestDelta = nil, 999;

    for name, ts in pairs(ST._recentCasts) do
        local delta = now - ts;
        if (delta > RECENT_CAST_TTL) then
            ST._recentCasts[name] = nil;
        elseif (delta < closestDelta) then
            closestDelta = delta;
            closest = name;
        end
    end

    if (not closest or closestDelta >= CORRELATE_WINDOW) then return; end

    local player = ST.trackedPlayers[closest];
    if (player) then
        for spellID, spellState in pairs(player.spells) do
            if (spellState.category == "interrupt" and spellState.kickBonus) then
                local adjusted = spellState.cdEnd - spellState.kickBonus;
                spellState.cdEnd = math.max(adjusted, now);
            end
        end
    end
end

local _mobFrame = CreateFrame("Frame");
_mobFrame:SetScript("OnEvent", function(_, _, unit)
    CorrelateInterrupt(unit);
end);

local _npCastFrames = {};
local function OnNameplateCastInterrupted(_, _, u)
    CorrelateInterrupt(u);
end
local _npFrame = CreateFrame("Frame");
_npFrame:SetScript("OnEvent", function(_, event, unit)
    if (event == "NAME_PLATE_UNIT_ADDED") then
        if (not _npCastFrames[unit]) then
            _npCastFrames[unit] = CreateFrame("Frame");
            _npCastFrames[unit]:SetScript("OnEvent", OnNameplateCastInterrupted);
        end
        _npCastFrames[unit]:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", unit);
    elseif (event == "NAME_PLATE_UNIT_REMOVED") then
        if (_npCastFrames[unit]) then
            _npCastFrames[unit]:UnregisterAllEvents();
        end
    end
end);

-------------------------------------------------------------------------------
-- Communication
-------------------------------------------------------------------------------

local COMM_PREFIX = "RRT";
local lastJoinBroadcast = 0;

local function SendMessage(payload)
    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "INSTANCE_CHAT");
        if (ok) then return; end
    end
    if (IsInRaid()) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "RAID");
        if (ok) then return; end
    end
    if (IsInGroup(LE_PARTY_CATEGORY_HOME)) then
        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, "PARTY");
        if (ok) then return; end
    end
end

local function BroadcastJoin()
    if (not ST.playerClass or not ST.playerName) then return; end
    local now = GetTime();
    if (now - lastJoinBroadcast < 3) then return; end
    lastJoinBroadcast = now;

    local player = ST.trackedPlayers[ST.playerName];
    if (not player) then return; end
    local kickID, kickCd;
    for spellID, spellState in pairs(player.spells) do
        if (spellState.category == "interrupt") then
            kickID = spellID;
            kickCd = spellState.baseCd;
            break;
        end
    end
    if (not kickID) then return; end

    SendMessage("J:" .. ST.playerClass .. ":" .. kickID .. ":" .. (kickCd or 15));

    -- Also broadcast current CD states for all tracked spells
    for spellID, spellState in pairs(player.spells) do
        local remaining = spellState.cdEnd - now;
        if (remaining > 1) then
            SendMessage("C:" .. spellID .. ":" .. string.format("%.1f", remaining));
        end
    end
end

local function BroadcastCast(resolvedID)
    local name = ST.playerName;
    if (not name) then return; end
    local player = ST.trackedPlayers[name];
    if (not player) then return; end
    local spellState = player.spells[resolvedID];
    if (not spellState) then return; end
    local remaining = spellState.cdEnd - GetTime();
    if (remaining > 1) then
        SendMessage("C:" .. resolvedID .. ":" .. string.format("%.1f", remaining));
    end
end

local function HandleAddonMessage(_, event, prefix, message, channel, sender)
    if (prefix ~= COMM_PREFIX) then return; end
    local shortName = Ambiguate(sender, "short");
    if (shortName == ST.playerName) then return; end

    local cmd, arg1, arg2, arg3 = strsplit(":", message);

    if (cmd == "J") then
        local cls = arg1;
        local sid = tonumber(arg2);
        local cd = tonumber(arg3);
        if (not cls or not sid or not ST.spellDB[sid]) then return; end

        local player = ST.trackedPlayers[shortName];
        if (not player) then return; end

        local spellState = player.spells[sid];
        if (spellState and cd and cd > 0) then
            spellState.baseCd = cd;
        end

        BroadcastJoin();

    elseif (cmd == "C") then
        local sid = tonumber(arg1);
        local cd = tonumber(arg2);
        if (not sid or not cd or cd <= 0) then return; end

        local player = ST.trackedPlayers[shortName];
        if (not player) then
            -- Player not yet registered — try to register them
            local unit = nil;
            local units = GroupUnitIterator();
            for _, u in ipairs(units) do
                if (Ambiguate(UnitName(u) or "", "short") == shortName) then
                    unit = u; break;
                end
            end
            if (unit) then
                local _, cls = UnitClass(unit);
                if (cls) then RegisterPlayer(shortName, cls); end
                player = ST.trackedPlayers[shortName];
            end
        end
        if (not player) then return; end

        local spellState = player.spells[sid];
        if (spellState) then
            local now = GetTime();
            spellState.state = "cooldown";
            spellState.cdEnd = now + cd;
        end
    end
end

local _commFrame = CreateFrame("Frame");
_commFrame:SetScript("OnEvent", HandleAddonMessage);

-------------------------------------------------------------------------------
-- Engine Enable / Disable
-------------------------------------------------------------------------------

local _eventFrame = CreateFrame("Frame");

function ST:EnableEngine()
    ValidateUnwrap();
    C_Timer.NewTicker(300, ValidateUnwrap);

    _eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE");
    _eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD");
    _eventFrame:RegisterEvent("LOADING_SCREEN_DISABLED");
    _eventFrame:RegisterEvent("UNIT_PET");
    _eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN");
    _eventFrame:RegisterEvent("SPELLS_CHANGED");
    _eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED");
    _eventFrame:RegisterEvent("INSPECT_READY");
    _eventFrame:RegisterEvent("READY_CHECK");
    _eventFrame:RegisterEvent("CHALLENGE_MODE_START");
    _eventFrame:RegisterEvent("ROLE_CHANGED_INFORM");
    -- Register UNIT_AURA globally (filter in handler)
    _eventFrame:RegisterEvent("UNIT_AURA");
    _eventFrame:SetScript("OnEvent", function(_, event, ...)
        if (event == "GROUP_ROSTER_UPDATE") then
            PruneTrackedPlayers();
            RegisterGroupByClass();
            RefreshGroupWatchers();
            QueueInspects();
        elseif (event == "PLAYER_ENTERING_WORLD" or event == "LOADING_SCREEN_DISABLED") then
            PruneTrackedPlayers();
            RegisterGroupByClass();
            RefreshGroupWatchers();
            C_Timer.After(2, function() RegisterGroupByClass(); QueueInspects(); end);
            C_Timer.After(5, function() RegisterGroupByClass(); QueueInspects(); end);
            C_Timer.After(10, function() RegisterGroupByClass(); QueueInspects(); end);
            -- Auto-load profile by role on login/reload
            C_Timer.After(3, function()
                if (ST.AutoLoadProfileForCurrentRole) then
                    ST:AutoLoadProfileForCurrentRole();
                end
            end);
        elseif (event == "UNIT_PET") then
            local unit = ...;
            RefreshGroupWatchers();
            if (not unit or unit == "player") then
                IdentifyPlayerSpells();
                C_Timer.After(0.5, IdentifyPlayerSpells);
                C_Timer.After(1.5, IdentifyPlayerSpells);
                C_Timer.After(3.0, IdentifyPlayerSpells);
            end
        elseif (event == "SPELL_UPDATE_COOLDOWN") then
            UpdateSelfCooldowns();
        elseif (event == "SPELLS_CHANGED") then
            IdentifyPlayerSpells();
            if (ST.playerClass == "WARLOCK") then
                C_Timer.After(1.5, IdentifyPlayerSpells);
                C_Timer.After(3.0, IdentifyPlayerSpells);
            end
        elseif (event == "PLAYER_SPECIALIZATION_CHANGED") then
            local unit = ...;
            if (not unit or unit == "player") then
                IdentifyPlayerSpells();
                -- Auto-load profile for new spec/role
                C_Timer.After(0.5, function()
                    if (ST.AutoLoadProfileForCurrentRole) then
                        ST:AutoLoadProfileForCurrentRole();
                    end
                end);
            else
                local name = UnitName(unit);
                if (name) then
                    _inspectedNames[name] = nil;
                    local _, cls = UnitClass(unit);
                    if (cls) then RegisterPlayer(name, cls); end
                    C_Timer.After(1, QueueInspects);
                end
            end
        elseif (event == "ROLE_CHANGED_INFORM") then
            local units = GroupUnitIterator();
            for _, u in ipairs(units) do
                local name = UnitName(u);
                local player = name and ST.trackedPlayers[name];
                if (player and player.spec) then
                    ApplySpecOverrides(player, name, player.spec);
                end
            end
        elseif (event == "UNIT_AURA") then
            local unit = ...;
            -- Only process friendly group units to avoid "secret value" errors
            -- from nameplate/enemy unit tokens in WoW 12.0+
            if (type(unit) == "string" and (
                unit == "player" or
                unit:sub(1, 5) == "party" or
                unit:sub(1, 4) == "raid"
            )) then
                local name = UnitName(unit);
                if (name and ST.trackedPlayers[name]) then
                    CheckUnitBuffs(unit);
                end
            end
        elseif (event == "READY_CHECK") then
            _inspectedNames = {};
            QueueInspects();
        elseif (event == "CHALLENGE_MODE_START") then
            QueueInspects();
        elseif (event == "INSPECT_READY") then
            if (_inspectInProgress and _inspectCurrentUnit) then
                ApplyInspectResults(_inspectCurrentUnit);
                _inspectInProgress = false;
                _inspectCurrentUnit = nil;
                ProcessNextInspect();
            end
        end
    end);

    -- Self-cast watcher
    _selfFrame:RegisterUnitEvent("UNIT_SPELLCAST_SUCCEEDED", "player", "pet");
    _selfFrame:SetScript("OnEvent", function(_, _, unit, _, spellID)
        local name = ST.playerName;
        if (not name) then return; end

        if (unit == "pet") then
            local cleanID = Unwrap(spellID);
            local matchID = cleanID or spellID;
            local resolvedID = ST.spellAliases[matchID] or matchID;
            if (ST.spellDB[resolvedID]) then
                RecordSpellCast("player", resolvedID, name);
                BroadcastCast(resolvedID);
            end
        else
            local resolvedID = ST.spellAliases[spellID] or spellID;
            if (ST.spellDB[resolvedID]) then
                RecordSpellCast("player", resolvedID, name);
                BroadcastCast(resolvedID);
            end
        end
    end);

    -- Interrupt tracking
    C_ChatInfo.RegisterAddonMessagePrefix(COMM_PREFIX);
    _mobFrame:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED", "target", "focus");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED");
    _npFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED");
    _commFrame:RegisterEvent("CHAT_MSG_ADDON");

    -- Start state ticker
    _tickerFrame:SetScript("OnUpdate", OnTick);

    -- Initial setup
    IdentifyPlayerSpells();
    RegisterGroupByClass();
    RefreshGroupWatchers();
end

function ST:DisableEngine()
    _eventFrame:UnregisterAllEvents();
    _eventFrame:SetScript("OnEvent", nil);
    _selfFrame:UnregisterAllEvents();
    _selfFrame:SetScript("OnEvent", nil);
    _tickerFrame:SetScript("OnUpdate", nil);

    _mobFrame:UnregisterAllEvents();
    _npFrame:UnregisterAllEvents();
    _commFrame:UnregisterAllEvents();
    for _, frame in pairs(_npCastFrames) do
        frame:UnregisterAllEvents();
    end
    wipe(_npCastFrames);

    for i = 1, 40 do
        _groupWatchers[i]:UnregisterAllEvents();
        _petWatchers[i]:UnregisterAllEvents();
    end

    ST.trackedPlayers = {};
    ST.excludedPlayers = {};
    ST._recentCasts = {};

    _inspectPending = {};
    _inspectInProgress = false;
    _inspectCurrentUnit = nil;
    _inspectedNames = {};
    _inspectRetries = {};

    if (ST.HideAllDisplays) then
        ST:HideAllDisplays();
    end
end


