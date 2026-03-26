local _, RRT_NS = ...

local BAR_TEXTURE    = [[Interface\Buttons\WHITE8x8]]
local CIRCLE_TEXTURE = [[Interface\AddOns\ReversionRaidTools\Media\Crosshair\ring]]
local TEXEL_HALF     = 0.5 / 512
local PI             = math.pi
local sin, cos       = math.sin, math.cos

-- ── defaults ──────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled          = false,
    combatOnly       = false,
    hideWhileMounted = false,
    showTop    = true,  showRight  = true,
    showBottom = true,  showLeft   = true,
    size       = 20,
    thickness  = 2,
    gap        = 6,
    colorR = 1, colorG = 1, colorB = 1,
    useClassColor        = false,
    opacity              = 0.8,
    outlineEnabled       = false,
    outlineWeight        = 1,
    outlineR = 0, outlineG = 0, outlineB = 0,
    outlineUseClassColor = false,
    dotEnabled           = false,
    dotSize              = 4,
    circleEnabled        = false,
    circleSize           = 30,
    circleUseClassColor  = false,
    offsetX = 0, offsetY = 0,
    meleeRecolor         = false,
    meleeRecolorBorder   = true,
    meleeRecolorArms     = true,
    meleeRecolorDot      = false,
    meleeRecolorCircle   = false,
    meleeOutColorR = 1, meleeOutColorG = 0.2, meleeOutColorB = 0.2,
    meleeOutUseClassColor = false,
    meleeSoundEnabled    = false,
    meleeSoundInterval   = 3,
    meleeSpellOverrides  = {},
}

local DEFAULT_MELEE_SPELLS = {
    DEATHKNIGHT = { 49998,  49998,  49998       },
    DEMONHUNTER = { 162794, 344859              },
    DRUID       = { nil,    5221,   33917, nil  },
    HUNTER      = { nil,    nil,    186270      },
    MONK        = { 205523, 205523, 205523      },
    PALADIN     = { nil,    96231,  96231       },
    ROGUE       = { 1752,   1752,   1752        },
    SHAMAN      = { nil,    73899,  nil         },
    WARRIOR     = { 6552,   6552,   6552        },
}

local ARM_DEFS = {
    { key = "showTop",    base = 0           },
    { key = "showRight",  base = PI / 2      },
    { key = "showBottom", base = PI          },
    { key = "showLeft",   base = 3 * PI / 2  },
}

-- ── helpers ────────────────────────────────────────────────────────────
local function mdb()
    if not RRT or not RRT.Crosshair then return {} end
    return RRT.Crosshair
end

local function GetEffectiveColor(d, rKey, gKey, bKey, classKey)
    if d[classKey] then
        local _, classFile = UnitClass("player")
        local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFile]
        if c then return c.r, c.g, c.b end
    end
    return d[rKey] or 1, d[gKey] or 1, d[bKey] or 1
end

local function GetClassName()  return select(2, UnitClass("player")) end
local function GetSpecIndex()  return GetSpecialization() or 0 end

-- ── state ──────────────────────────────────────────────────────────────
local inCombat            = false
local isMounted           = false
local isOutOfMelee        = false
local hpalEnabled         = false
local meleeCheckSupported = false
local cachedMeleeSpellId  = nil

-- ── frame + textures ───────────────────────────────────────────────────
local crosshairFrame = CreateFrame("Frame", "RRTCrosshair", UIParent)
crosshairFrame:SetFrameStrata("HIGH")
crosshairFrame:SetFrameLevel(50)
crosshairFrame:EnableMouse(false)
crosshairFrame:Hide()

local arms    = {}
local shadows = {}
for i = 1, #ARM_DEFS do
    local s = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 0)
    s:SetTexture(BAR_TEXTURE)
    s:SetVertexColor(0, 0, 0, 1)
    shadows[i] = s

    local t = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 1)
    t:SetTexture(BAR_TEXTURE)
    arms[i] = t
end

local dotShadow = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 0)
dotShadow:SetTexture(BAR_TEXTURE)
dotShadow:SetVertexColor(0, 0, 0, 1)

local dot = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 1)
dot:SetTexture(BAR_TEXTURE)

local circleShadow = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 0)
circleShadow:SetTexture(CIRCLE_TEXTURE, "CLAMP", "CLAMP", "TRILINEAR")
circleShadow:SetVertexColor(0, 0, 0, 1)
circleShadow:SetTexCoord(TEXEL_HALF, 1 - TEXEL_HALF, TEXEL_HALF, 1 - TEXEL_HALF)
if circleShadow.SetSnapToPixelGrid then
    circleShadow:SetSnapToPixelGrid(false)
    circleShadow:SetTexelSnappingBias(0)
end

local circleRing = crosshairFrame:CreateTexture(nil, "ARTWORK", nil, 1)
circleRing:SetTexture(CIRCLE_TEXTURE, "CLAMP", "CLAMP", "TRILINEAR")
circleRing:SetTexCoord(TEXEL_HALF, 1 - TEXEL_HALF, TEXEL_HALF, 1 - TEXEL_HALF)
if circleRing.SetSnapToPixelGrid then
    circleRing:SetSnapToPixelGrid(false)
    circleRing:SetTexelSnappingBias(0)
end

-- ── melee spell cache ──────────────────────────────────────────────────
local function GetMeleeSpellKey()
    local classFile = GetClassName()
    local specIndex = GetSpecIndex()
    if not classFile or specIndex == 0 then return nil end
    return classFile .. "_" .. specIndex
end

local function GetDefaultMeleeSpell()
    local classSpells = DEFAULT_MELEE_SPELLS[GetClassName()]
    return classSpells and classSpells[GetSpecIndex()]
end

local function GetCurrentMeleeSpell()
    local d   = mdb()
    local key = GetMeleeSpellKey()
    if not key then return nil end
    if d.meleeSpellOverrides and d.meleeSpellOverrides[key] then
        return d.meleeSpellOverrides[key]
    end
    return GetDefaultMeleeSpell()
end

local function CacheMeleeSpell()
    if hpalEnabled then return end
    cachedMeleeSpellId  = GetCurrentMeleeSpell()
    meleeCheckSupported = (cachedMeleeSpellId ~= nil)
end

local function HasAttackableTarget()
    if not UnitExists("target")                   then return false end
    if not UnitCanAttack("player", "target")      then return false end
    if UnitIsDeadOrGhost("target")                then return false end
    return true
end

-- ── layout ─────────────────────────────────────────────────────────────
local function ApplyLayout()
    local d = mdb()
    if not d.enabled then return end

    local size  = d.size      or 20
    local thick = d.thickness or 2
    local gap   = d.gap       or 6
    local r1, g1, b1 = GetEffectiveColor(d, "colorR", "colorG", "colorB", "useClassColor")
    local alpha = d.opacity   or 0.8
    local ox    = d.offsetX   or 0
    local oy    = d.offsetY   or 0
    local outline = d.outlineEnabled
    local ow    = d.outlineWeight or 1
    local olR, olG, olB = GetEffectiveColor(d, "outlineR", "outlineG", "outlineB", "outlineUseClassColor")

    local meleeOut      = d.meleeRecolor and isOutOfMelee
    local moR, moG, moB = GetEffectiveColor(d, "meleeOutColorR", "meleeOutColorG", "meleeOutColorB", "meleeOutUseClassColor")

    if meleeOut and d.meleeRecolorBorder ~= false then
        outline = true
        olR, olG, olB = moR, moG, moB
    end

    local span = (gap + size) + (outline and ow or 0) + 2
    crosshairFrame:SetSize(span * 2, span * 2)
    crosshairFrame:ClearAllPoints()
    local uiScale   = UIParent:GetEffectiveScale()
    local snappedOx = math.floor(ox * uiScale + 0.5) / uiScale
    local snappedOy = math.floor(oy * uiScale + 0.5) / uiScale
    crosshairFrame:SetPoint("CENTER", UIParent, "CENTER", snappedOx, snappedOy)

    local cx, cy = span, span

    for i, def in ipairs(ARM_DEFS) do
        local arm = arms[i]
        local shd = shadows[i]
        if d[def.key] ~= false then
            local cr, cg, cb = r1, g1, b1
            if meleeOut and d.meleeRecolorArms then cr, cg, cb = moR, moG, moB end
            local angle = def.base
            local dist  = gap + size / 2
            local ax    = cx + dist * sin(angle)
            local ay    = cy + dist * cos(angle)
            arm:SetSize(thick, size)
            arm:ClearAllPoints()
            arm:SetPoint("CENTER", crosshairFrame, "BOTTOMLEFT", ax, ay)
            arm:SetRotation(-angle)
            arm:SetVertexColor(cr, cg, cb, alpha)
            arm:Show()
            if outline then
                shd:SetSize(thick + ow * 2, size + ow * 2)
                shd:ClearAllPoints()
                shd:SetPoint("CENTER", crosshairFrame, "BOTTOMLEFT", ax, ay)
                shd:SetRotation(-angle)
                shd:SetVertexColor(olR, olG, olB, alpha)
                shd:Show()
            else
                shd:Hide()
            end
        else
            arm:Hide()
            shd:Hide()
        end
    end

    if d.dotEnabled then
        local ds        = d.dotSize or 4
        local dr, dg, db_ = r1, g1, b1
        if meleeOut and d.meleeRecolorDot then dr, dg, db_ = moR, moG, moB end
        dot:SetSize(ds, ds)
        dot:ClearAllPoints()
        dot:SetPoint("CENTER", crosshairFrame, "BOTTOMLEFT", cx, cy)
        dot:SetVertexColor(dr, dg, db_, alpha)
        dot:Show()
        if outline then
            dotShadow:SetSize(ds + ow * 2, ds + ow * 2)
            dotShadow:ClearAllPoints()
            dotShadow:SetPoint("CENTER", dot, "CENTER", 0, 0)
            dotShadow:SetVertexColor(olR, olG, olB, alpha)
            dotShadow:Show()
        else
            dotShadow:Hide()
        end
    else
        dot:Hide()
        dotShadow:Hide()
    end

    if d.circleEnabled then
        local cs        = d.circleSize or 30
        local cR, cG, cB
        if d.circleR ~= nil or d.circleUseClassColor then
            cR, cG, cB = GetEffectiveColor(d, "circleR", "circleG", "circleB", "circleUseClassColor")
        else
            cR, cG, cB = r1, g1, b1
        end
        if meleeOut and d.meleeRecolorCircle then cR, cG, cB = moR, moG, moB end
        circleRing:SetSize(cs, cs)
        circleRing:ClearAllPoints()
        circleRing:SetPoint("CENTER", crosshairFrame, "BOTTOMLEFT", cx, cy)
        circleRing:SetVertexColor(cR, cG, cB, alpha)
        circleRing:Show()
        if outline then
            circleShadow:SetSize(cs + ow * 2, cs + ow * 2)
            circleShadow:ClearAllPoints()
            circleShadow:SetPoint("CENTER", circleRing, "CENTER", 0, 0)
            circleShadow:SetVertexColor(olR, olG, olB, alpha)
            circleShadow:Show()
        else
            circleShadow:Hide()
        end
    else
        circleRing:Hide()
        circleShadow:Hide()
    end
end

local function RefreshVisibility()
    local d = mdb()
    if not d.enabled                         then crosshairFrame:Hide(); return end
    if d.combatOnly and not inCombat         then crosshairFrame:Hide(); return end
    if d.hideWhileMounted and isMounted      then crosshairFrame:Hide(); return end
    crosshairFrame:Show()
end

local function UpdateDisplay()
    ApplyLayout()
    RefreshVisibility()
end

-- ── melee sound ────────────────────────────────────────────────────────
local DEFAULT_MELEE_SOUND  = 8959  -- SOUNDKIT fallback
local meleeSoundTicker     = nil
local lastMeleeSoundTime   = 0
local MELEE_SOUND_COOLDOWN = 0.9

local function StopMeleeSound()
    if meleeSoundTicker then
        meleeSoundTicker:Cancel()
        meleeSoundTicker = nil
    end
end

local function PlayMeleeSoundOnce()
    local now = GetTime()
    if now - lastMeleeSoundTime < MELEE_SOUND_COOLDOWN then return end
    lastMeleeSoundTime = now
    local soundID = mdb().meleeSoundID or DEFAULT_MELEE_SOUND
    PlaySound(soundID, "Master")
end

local function StartMeleeSound()
    StopMeleeSound()
    local interval = mdb().meleeSoundInterval or 3
    PlayMeleeSoundOnce()
    if interval > 0 then
        meleeSoundTicker = C_Timer.NewTicker(interval, PlayMeleeSoundOnce)
    end
end

-- ── melee range tick ───────────────────────────────────────────────────
local TICK_RATE   = 0.05
local tickAcc     = 0
local lastInRange = nil
local tickFrame   = CreateFrame("Frame")

local function ShouldTickRun()
    if hpalEnabled then return false end
    local d = mdb()
    if not d.enabled or not d.meleeRecolor then return false end
    if not meleeCheckSupported              then return false end
    if not HasAttackableTarget()            then return false end
    return true
end

local function TickMeleeRangeCheck()
    local d = mdb()
    if not d.meleeRecolor or not meleeCheckSupported then
        if isOutOfMelee then isOutOfMelee = false; ApplyLayout() end
        StopMeleeSound(); lastInRange = nil; return
    end
    local wasOut = isOutOfMelee
    if not HasAttackableTarget() then
        isOutOfMelee = false; StopMeleeSound(); lastInRange = nil
    else
        local inMelee = C_Spell.IsSpellInRange(cachedMeleeSpellId, "target")
        if inMelee == nil then return end
        isOutOfMelee = not inMelee
        if isOutOfMelee then
            if d.meleeSoundEnabled and lastInRange == true then StartMeleeSound() end
        else
            StopMeleeSound()
        end
        lastInRange = inMelee
    end
    if isOutOfMelee ~= wasOut then ApplyLayout() end
end

local function StartMeleeTick()
    tickFrame:SetScript("OnUpdate", function(_, elapsed)
        tickAcc = tickAcc + elapsed
        if tickAcc < TICK_RATE then return end
        tickAcc = 0
        TickMeleeRangeCheck()
    end)
end

local function StopMeleeTick()
    tickFrame:SetScript("OnUpdate", nil)
    tickAcc = 0
    if isOutOfMelee then isOutOfMelee = false; ApplyLayout() end
    StopMeleeSound(); lastInRange = nil
end

local function EvaluateMeleeTick()
    if ShouldTickRun() then StartMeleeTick() else StopMeleeTick() end
end

-- ── Holy Paladin fallback ──────────────────────────────────────────────
local HPAL_ITEM_ID   = 129055
local hpalTickAcc    = 0
local hpalTickFrame  = CreateFrame("Frame")

local function HpalCheckMeleeRange()
    local d = mdb()
    if not d.enabled or not d.meleeRecolor then return end
    local wasOut = isOutOfMelee
    if not HasAttackableTarget() then
        isOutOfMelee = false; StopMeleeSound(); lastInRange = nil
    else
        local inMelee = C_Item.IsItemInRange(HPAL_ITEM_ID, "target")
        if inMelee == nil then return end
        isOutOfMelee = not inMelee
        if isOutOfMelee then
            if d.meleeSoundEnabled and lastInRange == true then StartMeleeSound() end
        else
            StopMeleeSound()
        end
        lastInRange = inMelee
    end
    if isOutOfMelee ~= wasOut then ApplyLayout() end
end

local function StartHpalTick()
    hpalTickFrame:SetScript("OnUpdate", function(_, elapsed)
        hpalTickAcc = hpalTickAcc + elapsed
        if hpalTickAcc < TICK_RATE then return end
        hpalTickAcc = 0
        HpalCheckMeleeRange()
    end)
end

local function StopHpalTick()
    hpalTickFrame:SetScript("OnUpdate", nil)
    hpalTickAcc = 0
    if isOutOfMelee then isOutOfMelee = false; ApplyLayout() end
    StopMeleeSound(); lastInRange = nil
end

local function EvaluateHpalMode()
    local d = mdb()
    local shouldEnable = GetClassName() == "PALADIN" and GetSpecIndex() == 1
        and d.enabled and d.meleeRecolor
    if shouldEnable then
        hpalEnabled = true; meleeCheckSupported = true
        StartHpalTick()
    else
        hpalEnabled = false
        StopHpalTick()
    end
end

-- ── events ─────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:RegisterEvent("DISPLAY_SIZE_CHANGED")
eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
eventFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
eventFrame:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")

eventFrame:SetScript("OnEvent", function(_, event)
    if event == "DISPLAY_SIZE_CHANGED" then
        isMounted = IsMounted()
        EvaluateHpalMode(); CacheMeleeSpell(); UpdateDisplay()
    elseif event == "PLAYER_REGEN_DISABLED" then
        inCombat = true;  RefreshVisibility()
    elseif event == "PLAYER_REGEN_ENABLED" then
        inCombat = false; RefreshVisibility()
    elseif event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        isMounted = IsMounted(); RefreshVisibility()
    elseif event == "PLAYER_TARGET_CHANGED" then
        isOutOfMelee = false; lastInRange = nil
        StopMeleeSound(); ApplyLayout(); EvaluateMeleeTick()
    elseif event == "PLAYER_ENTERING_WORLD" then
        EvaluateHpalMode(); CacheMeleeSpell(); EvaluateMeleeTick()
    elseif event == "PLAYER_LEAVING_WORLD" then
        StopMeleeTick(); StopHpalTick()
    elseif event == "ACTIVE_TALENT_GROUP_CHANGED" then
        EvaluateHpalMode(); CacheMeleeSpell(); EvaluateMeleeTick()
    end
end)

-- ── module API ─────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    isMounted = IsMounted()
    EvaluateHpalMode()
    CacheMeleeSpell()
    UpdateDisplay()
end

function module:Disable()
    StopMeleeTick()
    StopHpalTick()
    crosshairFrame:Hide()
end

function module:UpdateDisplay()
    UpdateDisplay()
end

function module:GetMeleeRangeInfo()
    return {
        GetCurrentSpell = GetCurrentMeleeSpell,
        GetDefaultSpell = GetDefaultMeleeSpell,
        GetSpellKey     = GetMeleeSpellKey,
        RefreshCache    = CacheMeleeSpell,
    }
end

RRT_NS.Crosshair = module
