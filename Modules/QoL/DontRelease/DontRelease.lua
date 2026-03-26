local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────────────────────
local REQUIRED_HOLD = 1.0   -- seconds Alt must be held to unlock the button

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────
local blocker    = nil
local timerLabel = nil
local pressStart = 0
local isReady    = false

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsEnabled()
    return RRT and RRT.DontRelease and RRT.DontRelease.enabled
end

local function BuildBlocker(releaseBtn)
    if blocker then return blocker end

    blocker = CreateFrame("Button", nil, releaseBtn)
    blocker:SetAllPoints()
    blocker:SetFrameStrata("DIALOG")
    blocker:EnableMouse(true)
    blocker:RegisterForClicks("AnyUp", "AnyDown")

    local bg = blocker:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.05, 0.05, 0.05, 0.85)

    timerLabel = blocker:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    timerLabel:SetPoint("CENTER", 0, 0)
    timerLabel:SetTextColor(0.639, 0.188, 0.788, 1)
    local fontFile, fontSize, fontFlags = timerLabel:GetFont()
    timerLabel:SetFont(fontFile, fontSize * 0.75, fontFlags)

    blocker:SetScript("OnClick", function() end)

    return blocker
end

local function TickTimer(self, dt)
    if isReady then
        blocker:Hide()
        return
    end

    if IsAltKeyDown() then
        if pressStart == 0 then pressStart = GetTime() end
        local left = REQUIRED_HOLD - (GetTime() - pressStart)
        if left <= 0 then
            isReady = true
            blocker:Hide()
        else
            timerLabel:SetText(string.format("Hold Alt  %.1fs", left))
        end
    else
        pressStart = 0
        timerLabel:SetText(string.format("Hold Alt  %.1fs", REQUIRED_HOLD))
    end
end

local function ClearState()
    pressStart = 0
    isReady    = false
    if blocker then
        blocker:SetScript("OnUpdate", nil)
        blocker:Hide()
    end
end

local function ActivateProtection()
    if not IsEnabled() then return end

    local _, instanceType = GetInstanceInfo()
    if instanceType ~= "party" and instanceType ~= "raid" then return end

    local visible, popup = StaticPopup_Visible("DEATH")
    if not visible or not popup then return end

    local btn = popup.GetButton and popup:GetButton(1)
    if not btn then return end

    BuildBlocker(btn)
    ClearState()
    timerLabel:SetText(string.format("Hold Alt  %.1fs", REQUIRED_HOLD))
    blocker:Show()
    blocker:SetScript("OnUpdate", TickTimer)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local watcher = CreateFrame("Frame", "RRTDontReleaseEvents")
watcher:RegisterEvent("PLAYER_DEAD")
watcher:RegisterEvent("PLAYER_ALIVE")
watcher:RegisterEvent("PLAYER_UNGHOST")

watcher:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_DEAD" then
        C_Timer.After(0.05, ActivateProtection)
    else
        ClearState()
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}

function module:UpdateDisplay()
    if not IsEnabled() then ClearState() end
end

-- Export
RRT_NS.DontRelease = module
