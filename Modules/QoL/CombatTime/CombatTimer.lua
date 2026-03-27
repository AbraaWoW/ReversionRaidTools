local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled         = false,
    locked          = true,
    timeFormat      = "CLOCK",
    fontSize        = 18,
    fontOutline     = "OUTLINE",
    fontColor       = { r = 1, g = 1, b = 1, a = 1 },
    fontShadowColor = { r = 0, g = 0, b = 0, a = 1 },
    fontShadowX     = 1,
    fontShadowY     = -1,
    useClassColor   = false,
    stickyDuration  = 5,
    pos             = nil,  -- { point, relPoint, x, y }
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Time formats (from ItruliaQoL)
-- ─────────────────────────────────────────────────────────────────────────────
local TIME_FORMATS = {
    SECONDS         = { label = "180",      fn = function(s) return string.format("%d", math.floor(s)) end },
    SECONDS_BRACKET = { label = "[180]",    fn = function(s) return string.format("[%d]", math.floor(s)) end },
    CLOCK           = { label = "1:23",     fn = function(s) local m = math.floor(s/60); return string.format("%d:%02d", m, math.floor(s%60)) end },
    CLOCK_BRACKET   = { label = "[1:23]",   fn = function(s) local m = math.floor(s/60); return string.format("[%d:%02d]", m, math.floor(s%60)) end },
}

local DEFAULT_POINT = { "TOP", UIParent, "TOP", 0, -200 }

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function Get(key)
    local db = RRT.CombatTimer
    if db and db[key] ~= nil then return db[key] end
    return DEFAULTS[key]
end

local function GetTextColor()
    if Get("useClassColor") then
        local _, class = UnitClass("player")
        if class and RAID_CLASS_COLORS[class] then
            local c = RAID_CLASS_COLORS[class]
            return c.r, c.g, c.b
        end
    end
    local fc = Get("fontColor")
    return fc.r, fc.g, fc.b
end

local function FormatTime(seconds)
    local fmt = Get("timeFormat") or "CLOCK"
    local entry = TIME_FORMATS[fmt] or TIME_FORMATS.CLOCK
    return entry.fn(seconds)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame
-- ─────────────────────────────────────────────────────────────────────────────
local clock = CreateFrame("Frame", "RRTCombatTimer", UIParent, "BackdropTemplate")
clock:SetSize(100, 30)
clock:SetPoint("TOP", UIParent, "TOP", 0, -200)
clock:SetClampedToScreen(true)
clock:SetMovable(true)
clock:Hide()

local clockLabel = clock:CreateFontString(nil, "ARTWORK")
clockLabel:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
clockLabel:SetPoint("CENTER")
clockLabel:SetText("0:00")

-- "Unlocked" hint label
local unlockLabel = clock:CreateFontString(nil, "OVERLAY")
unlockLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
unlockLabel:SetPoint("BOTTOM", clock, "TOP", 0, 4)
unlockLabel:SetText("Unlocked — drag to move")
unlockLabel:SetTextColor(0.639, 0.188, 0.788, 0.9)
unlockLabel:Hide()

-- ─────────────────────────────────────────────────────────────────────────────
-- Drag / Lock / Position (based on LanternUX.MakeDraggable)
-- ─────────────────────────────────────────────────────────────────────────────
local BASE_W, BASE_H = clock:GetSize()
local PAD = 6

local UNLOCK_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

clock:SetScript("OnMouseDown", function(self, button)
    if button == "LeftButton" and self:IsMovable() then
        self:StartMoving()
    end
end)

clock:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local point, _, relPoint, x, y = self:GetPoint()
    RRT.CombatTimer.pos = { point = point, relPoint = relPoint, x = x, y = y }
end)

function clock:UpdateLock()
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

function clock:RestorePosition()
    local pos = Get("pos")
    if not pos then return end
    self:ClearAllPoints()
    self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

function clock:ResetPosition()
    self:ClearAllPoints()
    self:SetPoint(DEFAULT_POINT[1], DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
    RRT.CombatTimer.pos = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Font / Color refresh
-- ─────────────────────────────────────────────────────────────────────────────
local function RefreshFont()
    clockLabel:SetFont(STANDARD_TEXT_FONT, Get("fontSize"), Get("fontOutline"))
    local sc = Get("fontShadowColor") or DEFAULTS.fontShadowColor
    clockLabel:SetShadowColor(sc.r, sc.g, sc.b, sc.a)
    clockLabel:SetShadowOffset(Get("fontShadowX") or 1, Get("fontShadowY") or -1)
end

local function RefreshColor()
    local r, g, b = GetTextColor()
    local a = 1
    if not Get("useClassColor") then
        local fc = Get("fontColor")
        a = fc.a or 1
    end
    clockLabel:SetTextColor(r, g, b, a)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- State & timer
-- ─────────────────────────────────────────────────────────────────────────────
local startedAt    = nil
local active       = false
local lingerTimer  = nil
local previewMode  = false

-- OnUpdate: real-time clock, throttled (display changes once/second max)
local _clockAcc = 0
clock:SetScript("OnUpdate", function(_, elapsed)
    if previewMode then return end
    if not (active and startedAt) then return end
    _clockAcc = _clockAcc + elapsed
    if _clockAcc < 0.1 then return end  -- 10 fps is plenty for a M:SS timer
    _clockAcc = 0
    clockLabel:SetText(FormatTime(GetTime() - startedAt))
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTCombatTimerEvents")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if not Get("enabled") then return end

    if event == "PLAYER_REGEN_DISABLED" then
        active     = true
        startedAt  = GetTime()
        if lingerTimer then lingerTimer:Cancel(); lingerTimer = nil end
        clock:SetAlpha(1)
        clock:Show()

    elseif event == "PLAYER_REGEN_ENABLED" then
        active = false
        local sticky = Get("stickyDuration")
        if sticky > 0 then
            lingerTimer = C_Timer.NewTimer(sticky, function()
                local locked = Get("locked")
                if not active and clock and locked then
                    clock:Hide()
                end
                lingerTimer = nil
            end)
        elseif Get("locked") then
            clock:Hide()
        end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS     = DEFAULTS
module.TIME_FORMATS = TIME_FORMATS

function module:Enable()
    clock:RestorePosition()
    clock:UpdateLock()
    RefreshFont()
    RefreshColor()
    if Get("enabled") and not Get("locked") then
        clock:Show()
    end
end

function module:Disable()
    clock:Hide()
    active    = false
    startedAt = nil
    previewMode = false
    if lingerTimer then lingerTimer:Cancel(); lingerTimer = nil end
end

function module:UpdateDisplay()
    if not Get("enabled") then
        clock:Hide()
        return
    end
    clock:RestorePosition()
    clock:UpdateLock()
    RefreshFont()
    RefreshColor()
end

function module:SetPreviewMode(enabled)
    previewMode = enabled
    if enabled then
        RefreshFont()
        RefreshColor()
        clockLabel:SetText(FormatTime(222))
        clock:SetAlpha(1)
        clock:Show()
    else
        if clock and not active then
            if Get("locked") then clock:Hide() end
        end
    end
end

function module:ResetPosition()
    clock:ResetPosition()
end

-- Export
RRT_NS.CombatTimer = module
