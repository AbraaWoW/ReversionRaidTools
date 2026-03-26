local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled      = false,
    locked       = true,
    iconSize     = 40,
    showTimer    = true,
    showCount    = true,
    showInMplus  = true,
    showInRaid   = true,
    deathWarning = false,
    pos          = nil,
}

local DEFAULT_POINT = { "CENTER", UIParent, "CENTER", 0, 150 }

-- Combat rez spell IDs (Rebirth, Raise Ally, Soulstone, Rewind)
local COMBAT_REZ_SPELL_IDS = { 20484, 61999, 20707, 391054 }

local inMythicPlus    = false
local encounterActive = false

local function IsSecret(v)
    return issecretvalue and issecretvalue(v) or false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- DB helper
-- ─────────────────────────────────────────────────────────────────────────────
local function Get(key)
    local d = RRT.BattleRez
    if d and d[key] ~= nil then return d[key] end
    return DEFAULTS[key]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame
-- ─────────────────────────────────────────────────────────────────────────────
local rezFrame = CreateFrame("Frame", "RRTBattleRez", UIParent, "BackdropTemplate")
rezFrame:SetSize(40, 40)
rezFrame:SetPoint(DEFAULT_POINT[1], DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
rezFrame:SetClampedToScreen(true)
rezFrame:SetMovable(true)
rezFrame:Hide()

local iconBg = rezFrame:CreateTexture(nil, "BACKGROUND")
iconBg:SetAllPoints()
iconBg:SetColorTexture(0, 0, 0, 0.5)

local iconTex = rezFrame:CreateTexture(nil, "ARTWORK")
iconTex:SetAllPoints()
iconTex:SetTexture("Interface\\Icons\\Spell_Nature_Reincarnation")

local timerLabel = rezFrame:CreateFontString(nil, "OVERLAY")
timerLabel:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
timerLabel:SetPoint("CENTER", rezFrame, "CENTER", 0, 0)
timerLabel:SetShadowOffset(1, -1)
timerLabel:SetShadowColor(0, 0, 0, 1)

local countLabel = rezFrame:CreateFontString(nil, "OVERLAY")
countLabel:SetFont(STANDARD_TEXT_FONT, 11, "OUTLINE")
countLabel:SetPoint("BOTTOMRIGHT", rezFrame, "BOTTOMRIGHT", -2, 2)
countLabel:SetShadowOffset(1, -1)
countLabel:SetShadowColor(0, 0, 0, 1)

local unlockLabel = rezFrame:CreateFontString(nil, "OVERLAY")
unlockLabel:SetFont(STANDARD_TEXT_FONT, 10, "OUTLINE")
unlockLabel:SetPoint("BOTTOM", rezFrame, "TOP", 0, 4)
unlockLabel:SetText("Unlocked — drag to move")
unlockLabel:SetTextColor(0.639, 0.188, 0.788, 0.9)
unlockLabel:Hide()

-- ─────────────────────────────────────────────────────────────────────────────
-- Drag / Lock / Position
-- ─────────────────────────────────────────────────────────────────────────────
local BASE_W, BASE_H = rezFrame:GetSize()
local PAD = 4

local UNLOCK_BACKDROP = {
    bgFile   = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    edgeSize = 1,
    insets   = { left = 0, right = 0, top = 0, bottom = 0 },
}

rezFrame:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and self:IsMovable() then self:StartMoving() end
end)
rezFrame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    RRT.BattleRez.pos = { point = p, relPoint = rp, x = x, y = y }
end)

function rezFrame:UpdateLock()
    local locked = Get("locked")
    local sz = Get("iconSize") or 40
    local fontSize = math.max(8, math.floor(sz * 0.40))
    self:SetMovable(not locked)
    self:EnableMouse(not locked)
    countLabel:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    timerLabel:SetFont(STANDARD_TEXT_FONT, fontSize, "OUTLINE")
    if not locked then
        self:SetSize(sz + PAD * 2, sz + PAD * 2)
        self:SetBackdrop(UNLOCK_BACKDROP)
        self:SetBackdropColor(0.05, 0.05, 0.05, 0.85)
        self:SetBackdropBorderColor(0.639, 0.188, 0.788, 0.6)
        unlockLabel:Show()
        self:SetAlpha(1)
        self:Show()
    else
        self:SetSize(sz, sz)
        self:SetBackdrop(nil)
        unlockLabel:Hide()
    end
end

function rezFrame:RestorePosition()
    local pos = Get("pos")
    if not pos then return end
    self:ClearAllPoints()
    self:SetPoint(pos.point, UIParent, pos.relPoint, pos.x, pos.y)
end

function rezFrame:ResetPosition()
    self:ClearAllPoints()
    self:SetPoint(DEFAULT_POINT[1], DEFAULT_POINT[2], DEFAULT_POINT[3], DEFAULT_POINT[4], DEFAULT_POINT[5])
    RRT.BattleRez.pos = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Logic
-- ─────────────────────────────────────────────────────────────────────────────
local function GetRezCharges()
    for _, spellID in ipairs(COMBAT_REZ_SPELL_IDS) do
        local ok, charges = pcall(C_Spell.GetSpellCharges, spellID)
        if ok and charges then return charges, spellID end
    end
    return nil, nil
end

local function ShouldShow()
    if not Get("enabled") then return false end
    if not Get("locked") then return true end
    if inMythicPlus   and Get("showInMplus") then return true end
    if encounterActive and Get("showInRaid")  then return true end
    return false
end

local rezElapsed = 0
rezFrame:SetScript("OnUpdate", function(self, dt)
    rezElapsed = rezElapsed + dt
    if rezElapsed < 0.1 then return end
    rezElapsed = 0

    local charges, spellID = GetRezCharges()
    if charges then
        local icon = C_Spell.GetSpellTexture(spellID)
        iconTex:SetTexture(icon or "Interface\\Icons\\Spell_Nature_Reincarnation")
        local cc = charges.currentCharges
        local mc = charges.maxCharges

        if Get("showCount") then
            countLabel:SetText(not IsSecret(cc) and tostring(cc or 0) or "?")
            countLabel:Show()
        else
            countLabel:Hide()
        end

        if Get("showTimer") then
            local cd = charges.cooldownDuration
            local cs = charges.cooldownStartTime
            if not IsSecret(cc) and not IsSecret(mc) and cc and mc and cc < mc
               and cd and cs and not IsSecret(cd) and not IsSecret(cs) then
                local rem = cd - (GetTime() - cs)
                if rem > 0 then
                    timerLabel:SetText(string.format("%d:%02d", math.floor(rem / 60), math.floor(rem % 60)))
                    timerLabel:Show()
                    iconTex:SetDesaturated(cc == 0)
                else
                    timerLabel:Hide()
                    iconTex:SetDesaturated(false)
                end
            else
                timerLabel:Hide()
                iconTex:SetDesaturated(not IsSecret(cc) and cc == 0 or false)
            end
        else
            timerLabel:Hide()
        end
    else
        iconTex:SetTexture("Interface\\Icons\\Spell_Nature_Reincarnation")
        timerLabel:Hide()
        if Get("showCount") then countLabel:SetText("0"); countLabel:Show() else countLabel:Hide() end
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTBattleRezEvents")
eventFrame:RegisterEvent("ENCOUNTER_START")
eventFrame:RegisterEvent("ENCOUNTER_END")
eventFrame:RegisterEvent("CHALLENGE_MODE_START")
eventFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
eventFrame:RegisterEvent("UNIT_DIED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ENCOUNTER_START" then
        encounterActive = true
    elseif event == "ENCOUNTER_END" then
        encounterActive = false
    elseif event == "CHALLENGE_MODE_START" then
        inMythicPlus = true
    elseif event == "CHALLENGE_MODE_COMPLETED" then
        inMythicPlus = false
    elseif event == "UNIT_DIED" then
        if not Get("deathWarning") then return end
        if IsSecret(arg1) or not arg1 then return end
        local unit = UnitTokenFromGUID(arg1)
        if not unit then return end
        if not (UnitInRaid(unit) or UnitInParty(unit) or UnitIsUnit(unit, "player")) then return end
        local name = UnitName(unit) or "Unknown"
        pcall(PlaySound, SOUNDKIT.RAID_WARNING or 8959, "Master")
        RaidNotice_AddMessage(RaidWarningFrame, name .. " died", ChatTypeInfo["RAID_WARNING"])
        return
    end

    if ShouldShow() then
        rezFrame:Show()
    elseif Get("locked") then
        rezFrame:Hide()
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    local _, instanceType, difficulty = GetInstanceInfo()
    inMythicPlus    = (instanceType == "party" and difficulty == 8)
    encounterActive = (C_InstanceEncounter and C_InstanceEncounter.IsEncounterInProgress()) or false
    rezFrame:RestorePosition()
    rezFrame:UpdateLock()
    if ShouldShow() then rezFrame:Show() end
end

function module:Disable()
    rezFrame:Hide()
end

function module:UpdateDisplay()
    rezFrame:RestorePosition()
    rezFrame:UpdateLock()
    if not Get("enabled") then
        rezFrame:Hide()
    elseif ShouldShow() then
        rezFrame:Show()
    elseif Get("locked") then
        rezFrame:Hide()
    end
end

function module:ResetPosition()
    rezFrame:ResetPosition()
end

function module:UpdateLock()
    rezFrame:UpdateLock()
end

-- Export
RRT_NS.BattleRez = module
