local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Constants
-- ─────────────────────────────────────────────────────────────────────────────
local VIGOR_SPELL         = 372608
local SECOND_WIND_SPELL   = 425782
local WHIRLING_SURGE_SPELL = 361584

local SPEED_RECIPROCAL    = 0.01176
local SPEED_DISPLAY_FACTOR = 14.285
local THRILL_THRESHOLD    = 6.003
local GROUND_SKIM_DURATION = 8.28
local THROTTLE            = 0.0333
local NUM_CHARGES         = 6
local BAR_TEXTURE         = [[Interface\Buttons\WHITE8x8]]
local THRILL_SPEED_THRESHOLD = 0.60

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults (exported for EventHandler to apply on first load)
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled            = false,
    barWidth           = 36,
    speedHeight        = 14,
    chargeHeight       = 14,
    gap                = 0,
    showSpeedText      = true,
    swapPosition       = false,
    hideWhenGroundedFull = false,
    showSecondWind     = true,
    showWhirlingSurge  = true,
    showThrillTick     = false,
    unlocked           = false,
    posX               = 0,
    posY               = 200,
    speedColorR        = 0.31, speedColorG = 1.00, speedColorB = 0.89,
    thrillColorR       = 0.35, thrillColorG = 0.68, thrillColorB = 1.00,
    chargeColorR       = 1.00, chargeColorG = 0.23, chargeColorB = 0.53,
    speedFontSize      = 12,
    speedTextOffsetX   = 0,
    speedTextOffsetY   = 0,
    surgeIconSize      = 0,
    surgeAnchor        = "RIGHT",
    surgeOffsetX       = 6,
    surgeOffsetY       = 0,
    bgColorR           = 0.12, bgColorG = 0.12, bgColorB = 0.12, bgAlpha = 0.8,
    borderColorR       = 0,    borderColorG = 0,  borderColorB = 0,
    borderAlpha        = 1,
    borderSize         = 1,
    iconBorderColorR   = 0,    iconBorderColorG = 0, iconBorderColorB = 0,
    iconBorderAlpha    = 1,
    iconBorderSize     = 1,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsSecret(value)
    return issecretvalue and issecretvalue(value) or false
end

local function Get(key)
    local db = RRT.Dragonriding
    if db and db[key] ~= nil then return db[key] end
    return DEFAULTS[key]
end

local function GetColor(rKey, gKey, bKey)
    return Get(rKey), Get(gKey), Get(bKey)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────
local prevSpeed      = 0
local elapsed        = 0
local lastColorState = nil
local uiBuilt        = false

local mainFrame, speedBar, speedText, speedTextFrame, thrillTick
local chargeBars     = {}
local chargeDividers = {}
local secondWindBars = {}
local surgeFrame, surgeCooldown, surgeBorder
local eventFrame

local eventsRegistered = false
local DYNAMIC_EVENTS = {
    "ACTIONBAR_UPDATE_COOLDOWN",
    "ACTIONBAR_UPDATE_STATE",
    "UPDATE_BONUS_ACTIONBAR",
    "PLAYER_CAN_GLIDE_CHANGED",
    "PLAYER_IS_GLIDING_CHANGED",
}

local function RegisterDynamicEvents()
    if eventsRegistered or not eventFrame then return end
    for _, event in ipairs(DYNAMIC_EVENTS) do
        eventFrame:RegisterEvent(event)
    end
    eventsRegistered = true
end

local function UnregisterDynamicEvents()
    if not eventsRegistered or not eventFrame then return end
    for _, event in ipairs(DYNAMIC_EVENTS) do
        eventFrame:UnregisterEvent(event)
    end
    eventsRegistered = false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Query helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsEnabled()
    return RRT.Dragonriding and RRT.Dragonriding.enabled
end

local function IsSkyriding()
    if GetBonusBarIndex() == 11 and GetBonusBarOffset() == 5 then
        return true
    end
    if UnitPowerBarID("player") == 650 then return false end
    local _, canGlide = C_PlayerInfo.GetGlidingInfo()
    return canGlide and UnitPowerBarID("player") ~= 0
end

local function IsGliding()
    local gliding = C_PlayerInfo.GetGlidingInfo()
    return gliding
end

local function GetForwardSpeed()
    local _, _, spd = C_PlayerInfo.GetGlidingInfo()
    return spd or 0
end

local function GetVigorInfo()
    local ok, data = pcall(C_Spell.GetSpellCharges, VIGOR_SPELL)
    if not ok or not data then return 0, 6, 0, 0, false, false end
    local cc = data.currentCharges
    local mc = data.maxCharges
    local cs = data.cooldownStartTime
    local cd = data.cooldownDuration
    if IsSecret(cc) or IsSecret(mc) or IsSecret(cs) or IsSecret(cd) then
        return 0, 6, 0, 0, false, false
    end
    local isThrill    = cd > 0 and cd <= THRILL_THRESHOLD
    local isGroundSkim = math.abs(cd - GROUND_SKIM_DURATION) < 0.05 and not isThrill
    return cc, mc, cs, cd, isThrill, isGroundSkim
end

local function GetSecondWindCharges()
    local ok, data = pcall(C_Spell.GetSpellCharges, SECOND_WIND_SPELL)
    if not ok or not data then return 0 end
    local cc = data.currentCharges
    if IsSecret(cc) then return 0 end
    return cc
end

local function GetWhirlingSurgeCooldown()
    local ok, data = pcall(C_Spell.GetSpellCooldown, WHIRLING_SURGE_SPELL)
    if not ok or not data then return 0, 0 end
    local s, d = data.startTime, data.duration
    if IsSecret(s) or IsSecret(d) then return 0, 0 end
    return s, d
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Color / Update functions
-- ─────────────────────────────────────────────────────────────────────────────
local function ApplyColors(isThrill)
    local state = isThrill and "thrill" or "speed"
    if state == lastColorState then return end
    lastColorState = state
    if isThrill then
        speedBar:SetStatusBarColor(GetColor("thrillColorR", "thrillColorG", "thrillColorB"))
    else
        speedBar:SetStatusBarColor(GetColor("speedColorR",  "speedColorG",  "speedColorB"))
    end
    local cr, cg, cb = GetColor("chargeColorR", "chargeColorG", "chargeColorB")
    for i = 1, NUM_CHARGES do
        chargeBars[i]:SetStatusBarColor(cr, cg, cb)
    end
end

local function UpdateSpeedBar(rawSpeed)
    local scaled = math.min(rawSpeed * SPEED_RECIPROCAL, 1.0)
    prevSpeed = prevSpeed + (scaled - prevSpeed) * 0.15
    speedBar:SetValue(prevSpeed)
    if Get("showSpeedText") then
        local display = math.floor(rawSpeed * SPEED_DISPLAY_FACTOR)
        speedText:SetText(display > 0 and tostring(display) or "")
    end
end

local function UpdateCharges(charges, maxCharges, startTime, duration)
    local now = GetTime()
    for i = 1, NUM_CHARGES do
        if i > maxCharges then
            chargeBars[i]:SetValue(0)
        elseif i <= charges then
            chargeBars[i]:SetValue(1)
        elseif i == charges + 1 and duration > 0 and startTime > 0 then
            local progress = (now - startTime) / duration
            chargeBars[i]:SetValue(math.min(progress, 1))
        else
            chargeBars[i]:SetValue(0)
        end
    end
end

local function UpdateSecondWind(charges, totalFilled)
    if not Get("showSecondWind") then
        for i = 1, NUM_CHARGES do secondWindBars[i]:SetValue(0) end
        return
    end
    for i = 1, NUM_CHARGES do
        secondWindBars[i]:SetValue(i <= totalFilled and 1 or 0)
    end
end

local function UpdateWhirlingSurge(startTime, duration)
    if not Get("showWhirlingSurge") or not surgeFrame then
        if surgeFrame then surgeFrame:Hide() end
        return
    end
    surgeFrame:Show()
    if startTime > 0 and duration > 0 then
        surgeCooldown:SetCooldown(startTime, duration)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Layout
-- ─────────────────────────────────────────────────────────────────────────────
local function UpdateLayout()
    if not mainFrame then return end

    local speedHeight  = Get("speedHeight")
    local chargeHeight = Get("chargeHeight")
    local gap          = Get("gap")
    local barWidthCfg  = Get("barWidth")
    local borderSize   = Get("borderSize")
    local totalHeight  = speedHeight + gap + chargeHeight
    local totalWidth   = NUM_CHARGES * barWidthCfg + (NUM_CHARGES - 1) * gap
    local barWidth     = barWidthCfg

    mainFrame:ClearAllPoints()
    mainFrame:SetPoint("CENTER", UIParent, "CENTER", Get("posX"), Get("posY"))
    mainFrame:SetSize(totalWidth + borderSize * 2, totalHeight + borderSize * 2)
    mainFrame:SetBackdrop({
        bgFile   = BAR_TEXTURE,
        edgeFile = BAR_TEXTURE,
        edgeSize = borderSize,
        insets   = { left = borderSize, right = borderSize, top = borderSize, bottom = borderSize },
    })
    mainFrame:SetBackdropColor(
        Get("bgColorR"), Get("bgColorG"), Get("bgColorB"), Get("bgAlpha"))
    mainFrame:SetBackdropBorderColor(
        Get("borderColorR"), Get("borderColorG"), Get("borderColorB"), Get("borderAlpha"))

    local swapPosition = Get("swapPosition")
    local speedY  = swapPosition and -borderSize                       or -(chargeHeight + gap + borderSize)
    local chargeY = swapPosition and -(speedHeight + gap + borderSize) or -borderSize

    speedBar:ClearAllPoints()
    speedBar:SetSize(totalWidth, speedHeight)
    speedBar:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", borderSize, speedY)

    speedText:SetFont(STANDARD_TEXT_FONT, Get("speedFontSize"), "OUTLINE")
    local fontSize = Get("speedFontSize")
    speedTextFrame:SetSize(math.max(44, fontSize * 2.5), math.max(24, fontSize + 12))
    speedTextFrame:ClearAllPoints()
    speedTextFrame:SetPoint("RIGHT", mainFrame, "RIGHT", Get("speedTextOffsetX"), Get("speedTextOffsetY"))
    speedTextFrame:SetShown(IsEnabled() and Get("showSpeedText"))

    if thrillTick then
        thrillTick:SetShown(Get("showThrillTick"))
        thrillTick:ClearAllPoints()
        thrillTick:SetSize(1, speedHeight)
        thrillTick:SetPoint("LEFT", speedBar, "LEFT", totalWidth * THRILL_SPEED_THRESHOLD, 0)
    end

    for i = 1, NUM_CHARGES do
        local xOff = borderSize + (i - 1) * (barWidth + gap)

        secondWindBars[i]:ClearAllPoints()
        secondWindBars[i]:SetSize(barWidth, chargeHeight)
        secondWindBars[i]:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOff, chargeY)

        chargeBars[i]:ClearAllPoints()
        chargeBars[i]:SetSize(barWidth, chargeHeight)
        chargeBars[i]:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOff, chargeY)

        if chargeDividers[i] then
            chargeDividers[i]:ClearAllPoints()
            chargeDividers[i]:SetSize(1, chargeHeight)
            chargeDividers[i]:SetPoint("TOPLEFT", mainFrame, "TOPLEFT", xOff + barWidth, chargeY)
        end
    end

    if surgeFrame then
        surgeFrame:ClearAllPoints()
        local surgeIconSize = Get("surgeIconSize")
        local iconSize = surgeIconSize > 0 and surgeIconSize or (chargeHeight + speedHeight + gap)
        surgeFrame:SetSize(iconSize, iconSize)

        local anchor = Get("surgeAnchor")
        local ox, oy = Get("surgeOffsetX"), Get("surgeOffsetY")
        if anchor == "LEFT" then
            surgeFrame:SetPoint("RIGHT",  mainFrame, "LEFT",   -ox,  oy)
        elseif anchor == "TOP" then
            surgeFrame:SetPoint("BOTTOM", mainFrame, "TOP",     ox,  oy)
        elseif anchor == "BOTTOM" then
            surgeFrame:SetPoint("TOP",    mainFrame, "BOTTOM",  ox, -oy)
        else -- RIGHT
            surgeFrame:SetPoint("LEFT",   mainFrame, "RIGHT",   ox,  oy)
        end
        surgeFrame:SetShown(Get("showWhirlingSurge"))

        if surgeBorder then
            local ibs = Get("iconBorderSize")
            surgeBorder:ClearAllPoints()
            surgeBorder:SetPoint("TOPLEFT",     surgeFrame, "TOPLEFT",     -ibs,  ibs)
            surgeBorder:SetPoint("BOTTOMRIGHT", surgeFrame, "BOTTOMRIGHT",  ibs, -ibs)
            surgeBorder:SetBackdrop({ edgeFile = BAR_TEXTURE, edgeSize = ibs })
            surgeBorder:SetBackdropBorderColor(
                Get("iconBorderColorR"), Get("iconBorderColorG"), Get("iconBorderColorB"),
                Get("iconBorderAlpha"))
        end
    end

    -- Re-apply StatusBar colors so options changes are immediately visible
    if speedBar then
        speedBar:SetStatusBarColor(Get("speedColorR"), Get("speedColorG"), Get("speedColorB"))
    end
    local cr, cg, cb = Get("chargeColorR"), Get("chargeColorG"), Get("chargeColorB")
    for i = 1, NUM_CHARGES do
        if chargeBars[i] then
            chargeBars[i]:SetStatusBarColor(cr, cg, cb)
        end
    end

    lastColorState = nil
end

-- ─────────────────────────────────────────────────────────────────────────────
-- OnUpdate tick
-- ─────────────────────────────────────────────────────────────────────────────
local function OnUpdate(self, dt)
    elapsed = elapsed + dt
    if elapsed < THROTTLE then return end
    elapsed = 0

    if not mainFrame or not speedBar then return end

    if not IsEnabled() or not IsSkyriding() then
        mainFrame:Hide()
        mainFrame:SetAlpha(0)
        if speedTextFrame then speedTextFrame:Hide() end
        eventFrame:SetScript("OnUpdate", nil)
        prevSpeed = 0
        lastColorState = nil
        return
    end

    local charges, maxCharges, startTime, duration, isThrill = GetVigorInfo()

    if Get("hideWhenGroundedFull") and not IsGliding() and charges >= maxCharges then
        mainFrame:Hide()
        mainFrame:SetAlpha(0)
        if speedTextFrame then speedTextFrame:Hide() end
        eventFrame:SetScript("OnUpdate", nil)
        return
    end

    mainFrame:Show()
    mainFrame:SetAlpha(1)
    if speedTextFrame and Get("showSpeedText") then speedTextFrame:Show() end

    UpdateSpeedBar(GetForwardSpeed())
    UpdateCharges(charges, maxCharges, startTime, duration)
    ApplyColors(isThrill)

    if Get("showSecondWind") then
        local swCharges = GetSecondWindCharges()
        UpdateSecondWind(charges, charges + swCharges)
    else
        UpdateSecondWind(0, 0)
    end

    if Get("showWhirlingSurge") then
        local sStart, sDur = GetWhirlingSurgeCooldown()
        UpdateWhirlingSurge(sStart, sDur)
    else
        UpdateWhirlingSurge(0, 0)
    end
end

local function ActivateUpdater()
    if not mainFrame or not IsEnabled() then return end
    eventFrame:SetScript("OnUpdate", OnUpdate)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- UI Construction
-- ─────────────────────────────────────────────────────────────────────────────
local function BuildUI()
    if uiBuilt then return end
    uiBuilt = true

    mainFrame = CreateFrame("Frame", "RRTDragonriding", UIParent, "BackdropTemplate")
    mainFrame:SetFrameStrata("MEDIUM")
    mainFrame:SetFrameLevel(100)
    mainFrame:SetClampedToScreen(true)
    mainFrame:SetMovable(true)
    mainFrame:RegisterForDrag("LeftButton")

    mainFrame:SetScript("OnDragStart", function(self)
        if Get("unlocked") then self:StartMoving() end
    end)
    mainFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local uw, uh = UIParent:GetSize()
        if cx and cy then
            RRT.Dragonriding.posX = math.floor(cx - uw / 2)
            RRT.Dragonriding.posY = math.floor(cy - uh / 2)
        end
    end)

    speedBar = CreateFrame("StatusBar", nil, mainFrame)
    speedBar:SetStatusBarTexture(BAR_TEXTURE)
    speedBar:SetMinMaxValues(0, 1)
    speedBar:SetValue(0)
    speedBar:SetStatusBarColor(GetColor("speedColorR", "speedColorG", "speedColorB"))

    thrillTick = speedBar:CreateTexture(nil, "OVERLAY")
    thrillTick:SetColorTexture(0.01, 0.56, 0.91, 1)

    speedTextFrame = CreateFrame("Frame", "RRTDragonridingSpeedText", UIParent, "BackdropTemplate")
    speedTextFrame:SetFrameStrata("MEDIUM")
    speedTextFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 10)
    speedTextFrame:SetSize(44, 24)
    speedTextFrame:SetClampedToScreen(true)
    speedTextFrame:SetMovable(true)
    speedTextFrame:RegisterForDrag("LeftButton")
    speedTextFrame:SetScript("OnDragStart", function(self)
        if Get("unlocked") then self:StartMoving() end
    end)
    speedTextFrame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local cx, cy = self:GetCenter()
        local mx, my = mainFrame:GetCenter()
        local fw     = self:GetWidth()
        local mw     = mainFrame:GetWidth()
        if cx and cy and mx and my then
            RRT.Dragonriding.speedTextOffsetX = math.floor((cx + fw / 2) - (mx + mw / 2))
            RRT.Dragonriding.speedTextOffsetY = math.floor(cy - my)
        end
        self:ClearAllPoints()
        self:SetPoint("RIGHT", mainFrame, "RIGHT",
            Get("speedTextOffsetX"), Get("speedTextOffsetY"))
    end)

    speedText = speedTextFrame:CreateFontString(nil, "OVERLAY")
    speedText:SetFont(STANDARD_TEXT_FONT, Get("speedFontSize"), "OUTLINE")
    speedText:SetAllPoints()
    speedText:SetJustifyH("RIGHT")
    speedText:SetJustifyV("MIDDLE")
    speedText:SetText("")

    for i = 1, NUM_CHARGES do
        local sw = CreateFrame("StatusBar", nil, mainFrame)
        sw:SetStatusBarTexture(BAR_TEXTURE)
        sw:SetMinMaxValues(0, 1)
        sw:SetValue(0)
        sw:SetStatusBarColor(0.00, 0.49, 0.79, 0.5) -- secondWind tint
        secondWindBars[i] = sw

        local cb = CreateFrame("StatusBar", nil, mainFrame)
        cb:SetStatusBarTexture(BAR_TEXTURE)
        cb:SetMinMaxValues(0, 1)
        cb:SetValue(0)
        cb:SetFrameLevel(sw:GetFrameLevel() + 1)
        cb:SetStatusBarColor(GetColor("chargeColorR", "chargeColorG", "chargeColorB"))
        chargeBars[i] = cb
    end

    local dividerFrame = CreateFrame("Frame", nil, mainFrame)
    dividerFrame:SetAllPoints()
    dividerFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 5)
    for i = 1, NUM_CHARGES - 1 do
        local div = dividerFrame:CreateTexture(nil, "OVERLAY")
        div:SetColorTexture(0, 0, 0, 1)
        chargeDividers[i] = div
    end

    surgeFrame = CreateFrame("Frame", nil, mainFrame)
    surgeFrame:SetFrameLevel(mainFrame:GetFrameLevel() + 2)

    local icon = C_Spell.GetSpellTexture(WHIRLING_SURGE_SPELL) or 134400
    local surgeIcon = surgeFrame:CreateTexture(nil, "ARTWORK")
    surgeIcon:SetAllPoints()
    surgeIcon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    surgeIcon:SetTexture(icon)

    surgeCooldown = CreateFrame("Cooldown", nil, surgeFrame, "CooldownFrameTemplate")
    surgeCooldown:SetPoint("TOPLEFT",     surgeFrame, "TOPLEFT",     0,  1)
    surgeCooldown:SetPoint("BOTTOMRIGHT", surgeFrame, "BOTTOMRIGHT", 0,  0)
    surgeCooldown:SetDrawEdge(false)
    surgeCooldown:SetDrawBling(false)
    surgeCooldown:SetSwipeColor(0, 0, 0, 0.8)
    surgeCooldown:SetHideCountdownNumbers(false)

    surgeBorder = CreateFrame("Frame", nil, surgeFrame, "BackdropTemplate")
    surgeBorder:SetFrameLevel(surgeFrame:GetFrameLevel() + 3)

    UpdateLayout()
    mainFrame:Hide()
    if speedTextFrame then speedTextFrame:Hide() end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    if not C_PlayerInfo or not C_PlayerInfo.GetGlidingInfo then return end
    BuildUI()
    if IsEnabled() then
        RegisterDynamicEvents()
        ActivateUpdater()
    end
end

function module:Disable()
    UnregisterDynamicEvents()
    if eventFrame then eventFrame:SetScript("OnUpdate", nil) end
    if mainFrame  then mainFrame:Hide(); mainFrame:SetAlpha(0) end
    if speedTextFrame then speedTextFrame:Hide() end
    prevSpeed = 0
    lastColorState = nil
end

function module:UpdateDisplay()
    if not uiBuilt then
        if not C_PlayerInfo or not C_PlayerInfo.GetGlidingInfo then return end
        BuildUI()
    end
    UpdateLayout()
    if IsEnabled() then
        if mainFrame then mainFrame:EnableMouse(Get("unlocked")) end
        -- show preview
        if eventFrame then eventFrame:SetScript("OnUpdate", nil) end
        if mainFrame  then mainFrame:Show(); mainFrame:SetAlpha(1) end
        if speedTextFrame then speedTextFrame:SetShown(Get("showSpeedText")) end
        speedBar:SetValue(0.65)
        speedBar:SetStatusBarColor(Get("speedColorR"), Get("speedColorG"), Get("speedColorB"))
        if Get("showSpeedText") then speedText:SetText("456") end
        local cr, cg, cb = GetColor("chargeColorR", "chargeColorG", "chargeColorB")
        for i = 1, NUM_CHARGES do
            chargeBars[i]:SetValue(i <= 4 and 1 or (i == 5 and 0.6 or 0))
            chargeBars[i]:SetStatusBarColor(cr, cg, cb)
            secondWindBars[i]:SetValue(i <= 5 and 1 or 0)
        end
        lastColorState = nil
    else
        if mainFrame then
            mainFrame:Hide()
            mainFrame:SetAlpha(0)
            mainFrame:EnableMouse(false)
        end
        if speedTextFrame then speedTextFrame:Hide() end
        if eventFrame then eventFrame:SetScript("OnUpdate", nil) end
        UnregisterDynamicEvents()
    end
end

function module:HidePreview()
    prevSpeed = 0
    lastColorState = nil
    if IsEnabled() then
        RegisterDynamicEvents()
        ActivateUpdater()
    else
        if mainFrame then
            mainFrame:Hide()
            mainFrame:SetAlpha(0)
        end
        if speedTextFrame then speedTextFrame:Hide() end
        if eventFrame then eventFrame:SetScript("OnUpdate", nil) end
        UnregisterDynamicEvents()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Event frame (handles skyriding state changes)
-- ─────────────────────────────────────────────────────────────────────────────
eventFrame = CreateFrame("Frame", "RRTDragonridingEvents")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(self, event)
    if not uiBuilt or not IsEnabled() then return end

    if event == "PLAYER_REGEN_ENABLED" then
        -- no CDM/BCM logic needed in RRT
        return
    end

    if event == "PLAYER_SPECIALIZATION_CHANGED" then
        C_Timer.After(0.2, function()
            if mainFrame then UpdateLayout() end
        end)
        return
    end

    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(0.5, function()
            if mainFrame then UpdateLayout() end
        end)
        return
    end

    ActivateUpdater()
end)

-- Export
RRT_NS.Dragonriding = module
