local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled   = false,
    instances = {},
}

local isLogging = false

-- ─────────────────────────────────────────────────────────────────────────────
-- DB helper
-- ─────────────────────────────────────────────────────────────────────────────
local function db()
    if not RRT or not RRT.CombatLogger then return nil end
    return RRT.CombatLogger
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Advanced Combat Logging prompt
-- ─────────────────────────────────────────────────────────────────────────────
StaticPopupDialogs["RRT_ACL_PROMPT"] = {
    text      = "%s",
    button1   = "Enable & Reload",
    button2   = "Skip",
    OnAccept  = function()
        C_CVar.SetCVar("advancedCombatLogging", 1)
        ReloadUI()
    end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

local function CheckAdvancedLogging()
    if C_CVar.GetCVar("advancedCombatLogging") ~= "1" then
        StaticPopup_Show("RRT_ACL_PROMPT",
            "|cFFBB66FFReversion Raid Tools|r\n\nAdvanced Combat Logging is disabled.\nEnable it for better log quality (requires UI reload).")
        return false
    end
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Per-zone prompt
-- ─────────────────────────────────────────────────────────────────────────────
StaticPopupDialogs["RRT_COMBATLOG_PROMPT"] = {
    text    = "%s",
    button1 = "Always Log",
    button2 = "Never Log",
    OnAccept = function(self)
        local data = self.data
        if not data or not db() then return end
        db().instances = db().instances or {}
        db().instances[data.key] = { enabled = true, name = data.zoneName, diffName = data.diffName }
        if CheckAdvancedLogging() then
            LoggingCombat(true)
            isLogging = true
        end
    end,
    OnCancel = function(self)
        local data = self.data
        if not data or not db() then return end
        db().instances = db().instances or {}
        db().instances[data.key] = { enabled = false, name = data.zoneName, diffName = data.diffName }
        if isLogging then
            LoggingCombat(false)
            isLogging = false
        end
    end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Zone check
-- ─────────────────────────────────────────────────────────────────────────────
local function OnZoneChanged()
    local d = db()
    if not d or not d.enabled then
        if isLogging then LoggingCombat(false); isLogging = false end
        return
    end

    local zoneName, instanceType, difficulty, _, _, _, _, instanceID = GetInstanceInfo()
    local diffName = GetDifficultyInfo and GetDifficultyInfo(difficulty) or tostring(difficulty)

    local shouldTrack = (instanceType == "raid") or (instanceType == "party" and difficulty == 8)

    if not shouldTrack then
        if isLogging then LoggingCombat(false); isLogging = false end
        return
    end

    d.instances = d.instances or {}
    local key   = instanceID .. ":" .. difficulty
    local saved = d.instances[key]

    if saved and saved.enabled == true then
        if not isLogging then
            if CheckAdvancedLogging() then LoggingCombat(true); isLogging = true end
        end
    elseif saved and saved.enabled == false then
        if isLogging then LoggingCombat(false); isLogging = false end
    else
        -- First time — start logging and ask
        if not isLogging then
            if not CheckAdvancedLogging() then return end
            LoggingCombat(true)
            isLogging = true
        end
        local promptText = "|cFFBB66FFReversion Raid Tools|r\n\nAutomatically log combat in |cFFFF9900"
            .. (zoneName or "?") .. "|r (" .. (diffName or "") .. ")?"
        local dialog = StaticPopup_Show("RRT_COMBATLOG_PROMPT", promptText)
        if dialog then
            dialog.data = { key = key, zoneName = zoneName, diffName = diffName }
        end
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTCombatLoggerEvents")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        isLogging = LoggingCombat()
        OnZoneChanged()
    elseif event == "CHALLENGE_MODE_START" then
        local d = db()
        if d and d.enabled and not isLogging then
            if CheckAdvancedLogging() then LoggingCombat(true); isLogging = true end
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    isLogging = LoggingCombat()
    OnZoneChanged()
end

function module:Disable()
    if isLogging then LoggingCombat(false); isLogging = false end
end

function module:UpdateDisplay()
    local d = db()
    if not d or not d.enabled then self:Disable() end
end

function module:IsLogging()
    return isLogging
end

-- Export
RRT_NS.CombatLogger = module
