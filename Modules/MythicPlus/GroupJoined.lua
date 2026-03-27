local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Group Joined — Greeting & Farewell
-- Uniquement dans les donjons et Mythic+ (instance de type "party")
-- Variables : {name} = nom du joueur  {dungeon} = nom du donjon  {level} = niveau clef M+
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    -- Greeting : envoyé quand on rejoint un groupe dans un donjon
    enabled        = false,
    message        = "Hey ! o/",
    delay          = 2,

    -- Farewell : envoyé à la fin d'une clef Mythic+
    farewellEnabled = false,
    farewellMessage = "GG everyone! Thanks for the key! See you next time :)",
    farewellDelay   = 3,
}

local function db() return RRT and RRT.MP_GroupJoined or DEFAULTS end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsInDungeon()
    local inI, t = IsInInstance()
    return inI and t == "party"
end

local function GetDungeonName()
    local mapID = C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
                  and C_ChallengeMode.GetActiveChallengeMapID()
    if mapID and mapID > 0 then
        local name = C_ChallengeMode.GetMapUIInfo(mapID)
        if name then return name end
    end
    return GetRealZoneText() or ""
end

local function ApplyVars(msg, vars)
    if not msg or msg == "" then return nil end
    return (msg:gsub("{(%w+)}", function(k) return vars[k] or ("{" .. k .. "}") end))
end

local function Send(msg, vars)
    local text = ApplyVars(msg, vars or {})
    if not text then return end
    if not IsInGroup() then return end
    pcall(SendChatMessage, text, "PARTY")
end

local function BaseVars()
    return { name = UnitName("player") or "", dungeon = GetDungeonName() }
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Timers & state
-- ─────────────────────────────────────────────────────────────────────────────
local _joinTimer     = nil
local _farewellTimer = nil

local function CancelAll()
    if _joinTimer     then _joinTimer:Cancel();     _joinTimer     = nil end
    if _farewellTimer then _farewellTimer:Cancel(); _farewellTimer = nil end
end

local function Schedule(timer, delay, fn)
    if timer then timer:Cancel() end
    if (delay or 0) <= 0 then fn(); return nil end
    return C_Timer.NewTimer(delay, fn)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local _ev = CreateFrame("Frame", "RRTGroupJoinedEv")

local function OnEvent(self, event, ...)
    local d = db()

    if event == "GROUP_JOINED" or event == "LFG_LIST_JOINED_GROUP" then
        if not d.enabled then return end
        -- Annule tout timer précédent pour éviter le double-envoi
        if _joinTimer then _joinTimer:Cancel(); _joinTimer = nil end
        _joinTimer = Schedule(_joinTimer, d.delay or 2, function()
            _joinTimer = nil
            local dd = db()
            if not dd.enabled then return end
            Send(dd.message, BaseVars())
        end)

    elseif event == "CHALLENGE_MODE_COMPLETED"
        or event == "SCENARIO_COMPLETED" then
        if not d.farewellEnabled then return end
        -- CHALLENGE_MODE_COMPLETED : args = mapID, level, time, onTime
        -- SCENARIO_COMPLETED       : args = scenarioID (pas de level)
        local mapID, level
        if event == "CHALLENGE_MODE_COMPLETED" then
            mapID, level = ...
        else
            -- SCENARIO_COMPLETED : vérifie qu'on est bien dans un M+ avant d'envoyer
            if not (C_ChallengeMode and C_ChallengeMode.GetActiveChallengeMapID
                    and C_ChallengeMode.GetActiveChallengeMapID() > 0) then
                return
            end
        end
        -- Guard : évite le double-envoi si les deux events se déclenchent
        if _farewellTimer then return end
        local vars = BaseVars()
        vars.level = tostring(level or "")
        if mapID and mapID > 0 then
            local name = C_ChallengeMode.GetMapUIInfo(mapID)
            if name then vars.dungeon = name end
        end
        _farewellTimer = Schedule(_farewellTimer, d.farewellDelay or 3, function()
            _farewellTimer = nil
            if not db().farewellEnabled then return end
            Send(db().farewellMessage, vars)
        end)

    elseif event == "GROUP_LEFT" or event == "PLAYER_LEAVING_WORLD" then
        CancelAll()
    end
end

_ev:RegisterEvent("GROUP_JOINED")
_ev:RegisterEvent("LFG_LIST_JOINED_GROUP")
_ev:RegisterEvent("CHALLENGE_MODE_COMPLETED")
_ev:RegisterEvent("SCENARIO_COMPLETED")
_ev:RegisterEvent("GROUP_LEFT")
_ev:RegisterEvent("PLAYER_LEAVING_WORLD")
_ev:SetScript("OnEvent", nil)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    local d = db()
    if d.enabled or d.farewellEnabled then
        _ev:SetScript("OnEvent", OnEvent)
    else
        CancelAll()
        _ev:SetScript("OnEvent", nil)
    end
end

function module:UpdateDisplay() self:Enable() end

RRT_NS.MP_GroupJoined = module
