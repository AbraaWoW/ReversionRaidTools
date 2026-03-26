local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled      = false,
    showEnter    = true,
    showLeave    = true,
    enterText    = "IN COMBAT",
    leaveText    = "OUT OF COMBAT",
    enterColor   = { r = 1,   g = 0.2, b = 0.2 },
    leaveColor   = { r = 0.2, g = 1,   b = 0.2 },
    fontSize     = 28,
    fontOutline  = "OUTLINE",
    fadeDuration = 2.0,
    soundEnabled = false,
    locked       = true,
    pos          = nil,
}

local DEFAULT_POINT = { "CENTER", UIParent, "CENTER", 0, 200 }

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function Get(key)
    local db = RRT.CombatAlert
    if db and db[key] ~= nil then return db[key] end
    return DEFAULTS[key]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame
-- ─────────────────────────────────────────────────────────────────────────────
local banner = CreateFrame("Frame", "RRTCombatAlert", UIParent, "BackdropTemplate")
banner:SetSize(400, 50)
banner:SetPoint(DEFAULT_POINT[1], DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
banner:SetFrameStrata("HIGH")
banner:SetClampedToScreen(true)
banner:SetMovable(true)
banner:Hide()

local label = banner:CreateFontString(nil, "ARTWORK")
label:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
label:SetPoint("CENTER")
label:SetShadowOffset(2, -2)
label:SetShadowColor(0, 0, 0, 0.8)

-- "Unlocked" hint label
local unlockLabel = banner:CreateFontString(nil, "OVERLAY")
unlockLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
unlockLabel:SetPoint("BOTTOM", banner, "TOP", 0, 4)
unlockLabel:SetText("Unlocked — drag to move")
unlockLabel:SetTextColor(0.639, 0.188, 0.788, 0.9)
unlockLabel:Hide()

-- ─────────────────────────────────────────────────────────────────────────────
-- Drag / Lock / Position
-- ─────────────────────────────────────────────────────────────────────────────
local BASE_W, BASE_H = banner:GetSize()
local PAD = 6

local UNLOCK_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

banner:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and self:IsMovable() then
        self:StartMoving()
    end
end)

banner:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    RRT.CombatAlert.pos = { point = point, relPoint = relPoint, x = x, y = y }
end)

function banner:UpdateLock()
    local locked = Get("locked")
    self:SetMovable(not locked)
    self:EnableMouse(not locked)

    if not locked then
        self:SetSize(BASE_W + PAD * 2, BASE_H + PAD * 2)
        self:SetBackdrop(UNLOCK_BACKDROP)
        self:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        self:SetBackdropBorderColor(0.639, 0.188, 0.788, 0.6)
        unlockLabel:Show()
        self:SetAlpha(1)
        self:Show()
    else
        self:SetSize(BASE_W, BASE_H)
        self:SetBackdrop(nil)
        unlockLabel:Hide()
    end
end

function banner:RestorePosition()
    local pos = Get("pos")
    if not pos then return end
    self:ClearAllPoints()
    self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

function banner:ResetPosition()
    self:ClearAllPoints()
    self:SetPoint(DEFAULT_POINT[1], DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
    RRT.CombatAlert.pos = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Font refresh
-- ─────────────────────────────────────────────────────────────────────────────
local function RefreshFont()
    label:SetFont(STANDARD_TEXT_FONT, Get("fontSize"), Get("fontOutline"))
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Flash logic
-- ─────────────────────────────────────────────────────────────────────────────
local flashAt    = nil
local previewMode  = false
local previewPhase = "enter"

-- Forward ref — module defined below
local module

local function Flash(text, color)
    RefreshFont()
    label:SetText(text)
    label:SetTextColor(color.r, color.g, color.b, 1)
    flashAt = GetTime()
    banner:SetAlpha(1)
    banner:Show()

    if not previewMode and Get("soundEnabled") then
        pcall(PlaySound, SOUNDKIT.RAID_BOSS_EMOTE, "Master")
    end
end

banner:SetScript("OnUpdate", function(self)
    if not flashAt then return end
    local elapsed = GetTime() - flashAt
    local dur     = Get("fadeDuration")

    if elapsed >= dur then
        self:Hide()
        flashAt = nil
        if previewMode and module then
            previewPhase = (previewPhase == "enter") and "leave" or "enter"
            C_Timer.After(0.3, function()
                if previewMode then module:ShowPreviewAlert() end
            end)
        end
        return
    end

    -- Hold for first 40%, then fade out
    local holdTime = dur * 0.4
    if elapsed <= holdTime then
        self:SetAlpha(1)
    else
        local fadeProgress = (elapsed - holdTime) / (dur - holdTime)
        self:SetAlpha(1 - fadeProgress)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTCombatAlertEvents")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if not Get("enabled") then return end

    if event == "PLAYER_REGEN_DISABLED" then
        if not Get("showEnter") then return end
        Flash(Get("enterText"), Get("enterColor"))

    elseif event == "PLAYER_REGEN_ENABLED" then
        if not Get("showLeave") then return end
        Flash(Get("leaveText"), Get("leaveColor"))
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    banner:RestorePosition()
    banner:UpdateLock()
    RefreshFont()
end

function module:Disable()
    banner:Hide()
    flashAt     = nil
    previewMode = false
end

function module:UpdateDisplay()
    banner:RestorePosition()
    banner:UpdateLock()
    RefreshFont()
    if not Get("enabled") then
        banner:Hide()
    end
end

function module:ShowPreviewAlert()
    if not previewMode then return end
    local text, color
    if previewPhase == "enter" then
        text  = Get("enterText")
        color = Get("enterColor")
    else
        text  = Get("leaveText")
        color = Get("leaveColor")
    end
    Flash(text, color)
end

function module:SetPreviewMode(enabled)
    previewMode = enabled
    if enabled then
        banner:RestorePosition()
        banner:UpdateLock()
        RefreshFont()
        previewPhase = "enter"
        self:ShowPreviewAlert()
    else
        flashAt = nil
        if banner then banner:Hide() end
    end
end

function module:IsPreviewActive()
    return previewMode
end

function module:UpdateLock()
    banner:UpdateLock()
end

function module:ResetPosition()
    banner:ResetPosition()
end

-- Export
RRT_NS.CombatAlert = module
