local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Death Alert — affiche le nom du joueur mort avec animation de fondu
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    enabled      = false,
    locked       = true,
    displayTime  = 4,    -- seconds the alert stays visible
    fontSize     = 24,
    fontOutline  = "OUTLINE",
    playSound    = false,
    sound        = nil,
    playTTS      = false,
    tts          = "",
    ttsVolume    = 50,
    byRole       = {
        tank    = { enabled = true,  color = { r = 0.0, g = 0.7, b = 1.0, a = 1 } },
        healer  = { enabled = true,  color = { r = 0.0, g = 1.0, b = 0.5, a = 1 } },
        damager = { enabled = true,  color = { r = 1.0, g = 0.3, b = 0.3, a = 1 } },
    },
    pos = nil,
}

local _frame = CreateFrame("Frame", "RRTDeathAlert", UIParent, "BackdropTemplate")
_frame:SetSize(250, 40)
_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
_frame:SetMovable(true)
_frame:SetClampedToScreen(true)
_frame:Hide()

local _label = _frame:CreateFontString(nil, "OVERLAY")
_label:SetFont(STANDARD_TEXT_FONT, 24, "OUTLINE")
_label:SetPoint("CENTER")
_label:SetText("")

_frame:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and self:IsMovable() then self:StartMoving() end
end)
_frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if RRT and RRT.MP_DeathAlert then
        RRT.MP_DeathAlert.pos = { point = p, relPoint = rp, x = x, y = y }
    end
end)

local function db() return RRT and RRT.MP_DeathAlert or DEFAULTS end

-- Fade-out animation
local _fadeTimer   = nil
local _displayTimer = nil

local function HideAlert()
    _frame:Hide()
    _frame:SetAlpha(1)
    if _fadeTimer  then _fadeTimer:Cancel();   _fadeTimer   = nil end
    if _displayTimer then _displayTimer:Cancel(); _displayTimer = nil end
end

local function StartFade()
    local d    = db()
    local dur  = 0.8
    local step = 0.05
    local acc  = 0
    _fadeTimer = C_Timer.NewTicker(step, function(self)
        acc = acc + step
        local alpha = 1 - (acc / dur)
        if alpha <= 0 then
            self:Cancel()
            _fadeTimer = nil
            HideAlert()
        else
            _frame:SetAlpha(alpha)
        end
    end)
end

local function ShowAlert(name, role)
    local d = db()
    if not d.enabled then return end

    local byRole = d.byRole or DEFAULTS.byRole
    if not byRole then byRole = DEFAULTS.byRole end
    local roleData = byRole[role or "damager"] or byRole["damager"]
    if roleData and not roleData.enabled then return end

    HideAlert()

    -- Font + text
    _label:SetFont(STANDARD_TEXT_FONT, d.fontSize or 24, d.fontOutline or "OUTLINE")
    _label:SetText(name .. " died!")
    local c = (roleData and roleData.color) or { r = 1, g = 0.3, b = 0.3, a = 1 }
    _label:SetTextColor(c.r, c.g, c.b, c.a or 1)
    _frame:SetSize(math.max(_label:GetStringWidth() + 10, 100), math.max(_label:GetStringHeight() + 4, 28))
    _frame:SetAlpha(1)
    _frame:Show()

    -- Sound / TTS
    if d.playSound and d.sound then
        pcall(PlaySoundFile, RRT_NS.LSM:Fetch("sound", d.sound), "Master")
    elseif d.playTTS and d.tts and d.tts ~= "" then
        local msg = d.tts:gsub("{name}", name)
        pcall(C_VoiceChat.SpeakText, 0, msg, 1, d.ttsVolume or 50, true)
    end

    -- Start fade after displayTime
    local displayTime = d.displayTime or 4
    _displayTimer = C_Timer.NewTimer(displayTime, function()
        _displayTimer = nil
        StartFade()
    end)
end

-- Unit role helper
local function GetUnitRole(unit)
    local role = UnitGroupRolesAssigned(unit)
    if role == "TANK"   then return "tank"    end
    if role == "HEALER" then return "healer"  end
    return "damager"
end

-- Event frame
local _ev = CreateFrame("Frame", "RRTDeathAlertEv")

local function OnEvent(self, event, ...)
    local d = db()
    if not d.enabled then return end

    if event == "UNIT_DIED" then
        local destGUID = ...
        if not destGUID then return end
        local unit = UnitTokenFromGUID(destGUID)
        if not unit then return end
        if not UnitIsPlayer(unit) then return end
        if not (UnitInRaid(unit) or UnitInParty(unit) or UnitIsUnit(unit, "player")) then return end
        local name = UnitName(unit) or "Unknown"
        local role = GetUnitRole(unit)
        ShowAlert(name, role)
    end
end

_ev:RegisterEvent("UNIT_DIED")
_ev:SetScript("OnEvent", nil)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    local d = db()
    -- Ensure nested tables are initialised (shallow copy doesn't deep-copy byRole)
    if not d.byRole then
        d.byRole = {
            tank    = { enabled = true,  color = { r = 0.0, g = 0.7, b = 1.0, a = 1 } },
            healer  = { enabled = true,  color = { r = 0.0, g = 1.0, b = 0.5, a = 1 } },
            damager = { enabled = true,  color = { r = 1.0, g = 0.3, b = 0.3, a = 1 } },
        }
    end
    if d.pos then
        _frame:ClearAllPoints()
        _frame:SetPoint(d.pos.point, UIParent, d.pos.relPoint, d.pos.x, d.pos.y)
    end
    _frame:SetMovable(not d.locked)
    _frame:EnableMouse(not d.locked)
    if d.enabled then
        _ev:SetScript("OnEvent", OnEvent)
    else
        HideAlert()
        _ev:SetScript("OnEvent", nil)
    end
end

function module:UpdateDisplay() self:Enable() end

function module:SetPreviewMode(enabled)
    if enabled then
        local d = db()
        _label:SetFont(STANDARD_TEXT_FONT, d.fontSize or 24, d.fontOutline or "OUTLINE")
        _label:SetText("Abraa died!")
        local c = (d.byRole and d.byRole["healer"] and d.byRole["healer"].color)
            or { r = 0, g = 1, b = 0.5, a = 1 }
        _label:SetTextColor(c.r, c.g, c.b, c.a or 1)
        _frame:SetSize(math.max(_label:GetStringWidth() + 10, 100), math.max(_label:GetStringHeight() + 4, 28))
        _frame:SetAlpha(1)
        _frame:Show()
    else
        HideAlert()
        if not (db().enabled) then _frame:Hide() end
    end
end

function module:ResetPosition()
    _frame:ClearAllPoints()
    _frame:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
    if RRT and RRT.MP_DeathAlert then RRT.MP_DeathAlert.pos = nil end
end

RRT_NS.MP_DeathAlert = module
