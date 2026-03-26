local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────────────────────
local FIRST_SLOT    = 1
local LAST_SLOT     = 19
local POLL_INTERVAL = 3
local FLOOR_PCT     = 15  -- below this: full red

local RED_R,  RED_G,  RED_B  = 1.0, 0.0,  0.0
local PINK_R, PINK_G, PINK_B = 1.0, 0.41, 0.71

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsEnabled()
    return RRT and RRT.QoL and RRT.QoL.DurabilityWarning
end

local function GetThreshold()
    return (RRT and RRT.QoL and RRT.QoL.DurabilityThreshold) or 50
end

local function GetWarningColor(pct, threshold)
    if pct <= FLOOR_PCT then
        return RED_R, RED_G, RED_B
    elseif pct >= threshold then
        return PINK_R, PINK_G, PINK_B
    end
    local t = (pct - FLOOR_PCT) / (threshold - FLOOR_PCT)
    return RED_R + t * (PINK_R - RED_R),
           RED_G + t * (PINK_G - RED_G),
           RED_B + t * (PINK_B - RED_B)
end

local function GetLowestDurability()
    local lowest
    for slot = FIRST_SLOT, LAST_SLOT do
        local current, maximum = GetInventoryItemDurability(slot)
        if current and maximum and maximum > 0 then
            local pct = (current / maximum) * 100
            if not lowest or pct < lowest then
                lowest = pct
            end
        end
    end
    return lowest
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Update QoLTextDisplays entry
-- ─────────────────────────────────────────────────────────────────────────────
local function SetDisplay(pct, threshold)
    local r, g, b = GetWarningColor(pct, threshold)
    local hex = string.format("%02X%02X%02X",
        math.floor(r * 255 + 0.5),
        math.floor(g * 255 + 0.5),
        math.floor(b * 255 + 0.5))
    local text = string.format("|cFF%s\u{26A0} Durability: %d%%|r", hex, pct)
    RRT_NS.QoLTextDisplays = RRT_NS.QoLTextDisplays or {}
    RRT_NS.QoLTextDisplays.Durability = { SettingsName = "DurabilityWarning", text = text }
    RRT_NS:UpdateQoLTextDisplay()
end

local function ClearDisplay()
    if not RRT_NS.QoLTextDisplays then return end
    RRT_NS.QoLTextDisplays.Durability = nil
    RRT_NS:UpdateQoLTextDisplay()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Check & poll
-- ─────────────────────────────────────────────────────────────────────────────
local function CheckAndUpdate()
    if not IsEnabled() then
        ClearDisplay()
        return
    end
    local lowest    = GetLowestDurability()
    local threshold = GetThreshold()
    if not lowest or lowest >= threshold then
        ClearDisplay()
    else
        SetDisplay(math.floor(lowest), threshold)
    end
end

local pollTimer = nil

local function StopPolling()
    if pollTimer then
        pollTimer:Cancel()
        pollTimer = nil
    end
end

local function StartPolling()
    StopPolling()
    if not IsEnabled() then return end
    pollTimer = C_Timer.NewTicker(POLL_INTERVAL, CheckAndUpdate)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTDurabilityEvents")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_DISABLED" then
        ClearDisplay()
        StopPolling()
    elseif event == "PLAYER_REGEN_ENABLED" then
        CheckAndUpdate()
        StartPolling()
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}

function module:Enable()
    CheckAndUpdate()
    StartPolling()
end

function module:Disable()
    StopPolling()
    ClearDisplay()
end

function module:Refresh()
    if IsEnabled() then
        CheckAndUpdate()
        StartPolling()
    else
        StopPolling()
        ClearDisplay()
    end
end

-- Export
RRT_NS.Durability = module
