local _, RRT_NS = ...
local RaidFrame = RRT_NS.RaidFrame

local AceComm = LibStub and LibStub("AceComm-3.0", true)
if not AceComm then return end

local PREFIX = "RRT_DBF"

-- Remote debuff state: [playerName][spellID] = true
-- Read by GetUnitDebuffs in RaidFrame.lua
RaidFrame._remoteDebuffs = {}

-- Own active configured debuffs cache: [spellID] = true
local _ownState = {}

-- ── Helpers ───────────────────────────────────────────────────────────────────

local function GetConfiguredSpellSet()
    local s = RRT.Settings and RRT.Settings.RaidFrame
    if not s or not s.activeRaid or s.activeRaid == "" then return {} end
    local set = {}
    for _, bossSpells in pairs(s.debuffProfiles[s.activeRaid] or {}) do
        for _, spellID in ipairs(bossSpells) do
            if spellID and spellID > 0 then
                set[spellID] = true
            end
        end
    end
    return set
end

local function SendMsg(msg)
    if IsInRaid() then
        AceComm:SendCommMessage(PREFIX, msg, "RAID")
    elseif IsInGroup() then
        AceComm:SendCommMessage(PREFIX, msg, "PARTY")
    end
end

-- ── Own aura scan ─────────────────────────────────────────────────────────────
-- Called on every UNIT_AURA("player"). Detects appearances/disappearances
-- of configured spells and broadcasts ON:/OFF: accordingly.

local function ScanOwnAuras()
    local configured = GetConfiguredSpellSet()

    -- Detect new appearances
    for spellID in pairs(configured) do
        local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        local hasIt = ok and result ~= nil
        local hadIt = _ownState[spellID] == true
        if hasIt and not hadIt then
            _ownState[spellID] = true
            SendMsg("ON:" .. spellID)
        elseif not hasIt and hadIt then
            _ownState[spellID] = nil
            SendMsg("OFF:" .. spellID)
        end
    end

    -- Clear spells no longer configured
    for spellID in pairs(_ownState) do
        if not configured[spellID] then
            _ownState[spellID] = nil
        end
    end
end

-- Broadcast the full current state (used on join / roster update).
local function BroadcastFullState()
    local configured = GetConfiguredSpellSet()
    local active = {}
    wipe(_ownState)
    for spellID in pairs(configured) do
        local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and result then
            _ownState[spellID] = true
            tinsert(active, tostring(spellID))
        end
    end
    SendMsg("S:" .. table.concat(active, ","))
end

-- ── Message handler ───────────────────────────────────────────────────────────

local function HandleMessage(_, message, _, sender)
    local senderName = Ambiguate(sender, "short")
    if senderName == UnitName("player") then return end

    local configured = GetConfiguredSpellSet()

    if message:sub(1, 3) == "ON:" then
        local spellID = tonumber(message:sub(4))
        if spellID and configured[spellID] then
            if not RaidFrame._remoteDebuffs[senderName] then
                RaidFrame._remoteDebuffs[senderName] = {}
            end
            RaidFrame._remoteDebuffs[senderName][spellID] = true
            RaidFrame:RequestRefresh()
        end

    elseif message:sub(1, 4) == "OFF:" then
        local spellID = tonumber(message:sub(5))
        if spellID and RaidFrame._remoteDebuffs[senderName] then
            RaidFrame._remoteDebuffs[senderName][spellID] = nil
            RaidFrame:RequestRefresh()
        end

    elseif message:sub(1, 2) == "S:" then
        -- Full state: replace all data for this sender
        local payload = message:sub(3)
        RaidFrame._remoteDebuffs[senderName] = {}
        if payload ~= "" then
            for idStr in payload:gmatch("%d+") do
                local spellID = tonumber(idStr)
                if spellID and configured[spellID] then
                    RaidFrame._remoteDebuffs[senderName][spellID] = true
                end
            end
        end
        RaidFrame:RequestRefresh()
    end
end

-- ── Event frame ───────────────────────────────────────────────────────────────

local commFrame = CreateFrame("Frame")
commFrame:RegisterUnitEvent("UNIT_AURA", "player")
commFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
commFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

commFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "UNIT_AURA" then
        ScanOwnAuras()

    elseif event == "GROUP_ROSTER_UPDATE" then
        -- Remove stale entries for players who left the group
        local inGroup = {}
        local n = GetNumGroupMembers()
        for i = 1, n do
            local unit = IsInRaid() and ("raid" .. i) or ("party" .. i)
            local name = GetUnitName(unit, false)
            if name then inGroup[name] = true end
        end
        for name in pairs(RaidFrame._remoteDebuffs) do
            if not inGroup[name] then
                RaidFrame._remoteDebuffs[name] = nil
            end
        end
        -- Broadcast our state to newly joined members
        C_Timer.After(0.5, BroadcastFullState)

    elseif event == "PLAYER_ENTERING_WORLD" then
        wipe(RaidFrame._remoteDebuffs)
        wipe(_ownState)
        C_Timer.After(3, BroadcastFullState)
    end
end)

-- ── Register comm prefix ──────────────────────────────────────────────────────

AceComm:RegisterComm(PREFIX, HandleMessage)
