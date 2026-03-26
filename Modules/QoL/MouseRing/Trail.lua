local _, RRT_NS = ...

-- Ported from Lantern/CursorRing Trail.lua by Abraa
local module = RRT_NS.MouseRing
if not module then return end

local ASSET_PATH = module._assetPath

local function db()                  return module._db()         end
local function frames()              return module._frames()     end
local function ShouldShow()          return module._shouldShow() end
local function GetCurrentOpacity()   return module._getOpacity() end
local function GetPlayerClassColor() return module._classColor() end

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------

local TRAIL_UPDATE_INTERVAL   = 0.016
local TRAIL_MOVE_THRESHOLD_SQ = 4
local TRAIL_MAX_ALPHA         = 0.8

local SPARKLE_POOL_SIZE    = 40
local SPARKLE_DURATION     = 0.4
local SPARKLE_SIZE_MIN     = 6
local SPARKLE_SIZE_MAX     = 18
local SPARKLE_OFFSET       = 10
local SPARKLE_CHANCE       = 0.30
local SPARKLE_DRIFT_Y      = 18
local SPARKLE_TWINKLE_SPEED = 14

local TRAIL_TEXCOORD_HALF = 0.5 / 128

local floor = math.floor
local sqrt  = math.sqrt
local max   = math.max

-------------------------------------------------------------------------------
-- Presets
-------------------------------------------------------------------------------

local TRAIL_STYLE_PRESETS = {
    glow      = { maxPoints = 20,  dotSize = 24, dotSpacing = 2, shrink = true,  shrinkDistance = false },
    line      = { maxPoints = 60,  dotSize = 12, dotSpacing = 1, shrink = false, shrinkDistance = true  },
    thickline = { maxPoints = 60,  dotSize = 22, dotSpacing = 1, shrink = false, shrinkDistance = true  },
    dots      = { maxPoints = 12,  dotSize = 18, dotSpacing = 8, shrink = true,  shrinkDistance = false },
}

local TRAIL_COLOR_PRESETS = {
    gold   = { r = 1.0,  g = 0.66, b = 0.0  },
    arcane = { r = 0.64, g = 0.21, b = 0.93 },
    fel    = { r = 0.0,  g = 0.9,  b = 0.1  },
    fire   = { r = 1.0,  g = 0.3,  b = 0.0  },
    frost  = { r = 0.5,  g = 0.8,  b = 1.0  },
    holy   = { r = 1.0,  g = 0.9,  b = 0.5  },
    shadow = { r = 0.5,  g = 0.0,  b = 0.8  },
}

local TRAIL_GRADIENT_PRESETS = {
    rainbow = true,
    alar    = { from = { r=1.0, g=0.55, b=0.05 }, to = { r=0.95, g=0.05, b=0.65 } },
    ember   = { from = { r=1.0, g=0.95, b=0.3  }, to = { r=0.8,  g=0.1,  b=0.0  } },
    ocean   = { from = { r=0.3, g=1.0,  b=1.0  }, to = { r=0.0,  g=0.15, b=0.7  } },
}

module.TRAIL_STYLE_PRESETS = TRAIL_STYLE_PRESETS
module.TRAIL_COLOR_PRESETS = TRAIL_COLOR_PRESETS

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local trailBuf          = {}
local trailPoolSize     = 0
local trailHead         = 0
local trailCount        = 0
local trailActive       = false
local trailUpdateTimer  = 0
local lastTrailX, lastTrailY = 0, 0
local rainbowHueOffset  = 0
local trailDormant      = false
local trailLastUpdateTime = nil
local sparkleBuf        = {}
local sparkleHead       = 0

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function ResolveTrailColor()
    local d = db()
    local preset = d.trailColorPreset
    if preset == "class" then return GetPlayerClassColor() end
    local static = TRAIL_COLOR_PRESETS[preset]
    if static then return static end
    return d.trailColor
end

local function HSVtoRGB(h, s, v)
    local i = floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1-f) * s)
    local m = i % 6
    if m == 0 then return v,t,p end
    if m == 1 then return q,v,p end
    if m == 2 then return p,v,t end
    if m == 3 then return p,q,v end
    if m == 4 then return t,p,v end
    return v,p,q
end

local function ResolveGradientColor(preset, t)
    if preset == "rainbow" then
        return HSVtoRGB((t * 0.83 + rainbowHueOffset) % 1, 1, 1)
    end
    local grad = TRAIL_GRADIENT_PRESETS[preset]
    if grad then
        local a, b = grad.from, grad.to
        return a.r+(b.r-a.r)*t, a.g+(b.g-a.g)*t, a.b+(b.b-a.b)*t
    end
    return 1, 1, 1
end

-------------------------------------------------------------------------------
-- Pool & Frame Management
-------------------------------------------------------------------------------

local function EnsureTrailPool(count)
    local f = frames()
    local d = db()
    if not f.trailContainer then return end
    for i = trailPoolSize + 1, count do
        local tex = f.trailContainer:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(ASSET_PATH.."trail_glow.tga","CLAMP","CLAMP","TRILINEAR")
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF,1-TRAIL_TEXCOORD_HALF,TRAIL_TEXCOORD_HALF,1-TRAIL_TEXCOORD_HALF)
        tex:SetBlendMode("ADD")
        tex:SetSize(d.trailDotSize or 24, d.trailDotSize or 24)
        tex:Hide()
        trailBuf[i] = { x=0, y=0, time=0, tex=tex, active=false }
    end
    for i = count + 1, trailPoolSize do
        local pt = trailBuf[i]
        if pt then pt.active = false; if pt.tex then pt.tex:Hide() end end
    end
    trailPoolSize = count
    trailHead = 0; trailCount = 0; trailDormant = false; trailLastUpdateTime = nil
end

local function ResetTrailState()
    for i = 1, trailPoolSize do
        local pt = trailBuf[i]
        if pt then pt.active = false; if pt.tex then pt.tex:Hide() end end
    end
    for i = 1, SPARKLE_POOL_SIZE do
        local sp = sparkleBuf[i]
        if sp then sp.active = false; if sp.tex then sp.tex:Hide() end end
    end
    trailHead = 0; trailCount = 0; sparkleHead = 0; trailDormant = false; trailLastUpdateTime = nil
end

local function CreateTrailFrame()
    local f = frames()
    local d = db()
    if f.trailContainer then return end

    local container = CreateFrame("Frame", "RRTCursorRingTrail", UIParent)
    container:SetSize(1, 1)
    container:SetFrameStrata("TOOLTIP"); container:SetFrameLevel(1)
    container:EnableMouse(false)
    container:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
    f.trailContainer = container

    EnsureTrailPool(d.trailMaxPoints or 20)

    for i = 1, SPARKLE_POOL_SIZE do
        local tex = container:CreateTexture(nil, "BACKGROUND")
        tex:SetTexture(ASSET_PATH.."trail_glow.tga","CLAMP","CLAMP","TRILINEAR")
        tex:SetTexCoord(TRAIL_TEXCOORD_HALF,1-TRAIL_TEXCOORD_HALF,TRAIL_TEXCOORD_HALF,1-TRAIL_TEXCOORD_HALF)
        tex:SetBlendMode("ADD"); tex:Hide()
        sparkleBuf[i] = { x=0, y=0, time=0, size=4, r=1,g=1,b=1, tex=tex, active=false }
    end

    container:SetScript("OnUpdate", function(_, elapsed)
        local d = db()
        if not d.trailEnabled or not trailActive then return end
        trailUpdateTimer = trailUpdateTimer + elapsed
        if trailUpdateTimer < TRAIL_UPDATE_INTERVAL then return end
        trailUpdateTimer = 0

        local now = GetTime()
        local maxPts = trailPoolSize

        if trailLastUpdateTime and (now - trailLastUpdateTime) > 0.25 then
            ResetTrailState()
            local cx, cy = GetCursorPosition()
            local sc = UIParent:GetEffectiveScale()
            lastTrailX, lastTrailY = floor(cx/sc+0.5), floor(cy/sc+0.5)
            trailLastUpdateTime = now; return
        end
        trailLastUpdateTime = now

        local cx, cy = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        local x, y = floor(cx/scale+0.5), floor(cy/scale+0.5)

        if trailDormant then
            local ddx, ddy = x-lastTrailX, y-lastTrailY
            if ddx*ddx + ddy*ddy < TRAIL_MOVE_THRESHOLD_SQ then return end
            trailDormant = false
        end

        local opacity    = GetCurrentOpacity()
        local spacing    = d.trailDotSpacing or 2
        local spacingSq  = spacing * spacing
        local dotSize    = d.trailDotSize or 24
        local shouldShrink = d.trailShrink
        local shrinkDist = d.trailShrinkDistance
        local anyShrink  = shouldShrink or shrinkDist

        local tc = ResolveTrailColor()
        local gradientPreset = TRAIL_GRADIENT_PRESETS[d.trailColorPreset] and d.trailColorPreset or nil

        local dx, dy = x-lastTrailX, y-lastTrailY
        local distSq = dx*dx + dy*dy
        if distSq >= spacingSq then
            local dist = sqrt(distSq)
            local n = floor(dist / spacing)
            if n > maxPts then n = maxPts end
            local ux, uy = dx/dist, dy/dist
            local sparkleEnabled = d.trailSparkle ~= "off" and sparkleBuf[1]
            local sparkleColor
            if sparkleEnabled then
                if gradientPreset then
                    local sr, sg, sb = ResolveGradientColor(gradientPreset, 0)
                    sparkleColor = { sr, sg, sb }
                else
                    sparkleColor = { tc.r, tc.g, tc.b }
                end
            end
            for s = 1, n do
                local px = lastTrailX + ux*spacing*s
                local py = lastTrailY + uy*spacing*s
                trailHead = (trailHead % maxPts) + 1
                local slot = trailBuf[trailHead]
                slot.x, slot.y, slot.time, slot.active = px, py, now, true
                if trailCount < maxPts then trailCount = trailCount + 1 end
                rainbowHueOffset = rainbowHueOffset + 0.001
                local tex = slot.tex
                if tex then tex:ClearAllPoints(); tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", px, py) end
                if sparkleEnabled and math.random() < SPARKLE_CHANCE then
                    sparkleHead = (sparkleHead % SPARKLE_POOL_SIZE) + 1
                    local sp = sparkleBuf[sparkleHead]
                    local sx = px + (math.random()*2-1)*SPARKLE_OFFSET
                    local sy = py + (math.random()*2-1)*SPARKLE_OFFSET
                    local sz = SPARKLE_SIZE_MIN + math.random()*(SPARKLE_SIZE_MAX-SPARKLE_SIZE_MIN)
                    sp.x, sp.y, sp.time, sp.active = sx, sy, now, true
                    sp.size = sz; sp.r, sp.g, sp.b = sparkleColor[1], sparkleColor[2], sparkleColor[3]
                    local stex = sp.tex
                    if stex then
                        stex:SetSize(sz,sz); stex:ClearAllPoints()
                        stex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", sx, sy)
                    end
                end
            end
            lastTrailX = lastTrailX + ux*spacing*n
            lastTrailY = lastTrailY + uy*spacing*n
        end

        local dur = d.trailDuration > 0 and d.trailDuration or 0.1
        local invDur = 1 / dur
        local anyActive = false

        local visibleCount = 0
        if shrinkDist or gradientPreset then
            local idx = trailHead
            for i = 1, maxPts do
                local pt = trailBuf[idx]
                if pt and pt.active then
                    if (now - pt.time)*invDur < 1 then visibleCount = visibleCount + 1 end
                end
                idx = idx - 1; if idx < 1 then idx = maxPts end
            end
        end

        local rank = 0
        local idx = trailHead
        for i = 1, maxPts do
            local pt = trailBuf[idx]
            if pt and pt.active and pt.tex then
                local fade = 1 - ((now - pt.time) * invDur)
                if fade <= 0 then
                    pt.active = false; trailCount = trailCount - 1; pt.tex:Hide()
                else
                    anyActive = true; rank = rank + 1
                    local distScale = 1
                    if shrinkDist and visibleCount > 1 then
                        distScale = sqrt(1 - ((rank-1)/(visibleCount-1)))
                    end
                    local alpha = fade * distScale * opacity * TRAIL_MAX_ALPHA
                    if gradientPreset then
                        local t = (visibleCount > 1) and ((rank-1)/(visibleCount-1)) or 0
                        local gr,gg,gb = ResolveGradientColor(gradientPreset, t)
                        pt.tex:SetVertexColor(gr, gg, gb, alpha)
                    else
                        pt.tex:SetVertexColor(tc.r, tc.g, tc.b, alpha)
                    end
                    if anyShrink then
                        local sc = distScale
                        if shouldShrink then sc = sc * fade end
                        pt.tex:SetSize(dotSize*sc, dotSize*sc)
                    end
                    pt.tex:Show()
                end
            end
            idx = idx - 1; if idx < 1 then idx = maxPts end
        end

        local sparkleMode = d.trailSparkle
        if sparkleMode ~= "off" then
            local invSpkDur = 1 / SPARKLE_DURATION
            local isTwinkle = (sparkleMode == "twinkle")
            for i = 1, SPARKLE_POOL_SIZE do
                local sp = sparkleBuf[i]
                if sp and sp.active then
                    local age = now - sp.time
                    if age >= SPARKLE_DURATION then
                        sp.active = false; sp.tex:Hide()
                    else
                        anyActive = true
                        local t = age * invSpkDur
                        local fade = (1-t)*(1-t)
                        local alpha
                        if isTwinkle then
                            local twinkle = 0.5 + 0.5*math.sin(age*SPARKLE_TWINKLE_SPEED)
                            alpha = fade * twinkle * opacity
                            sp.tex:ClearAllPoints()
                            sp.tex:SetPoint("CENTER", UIParent, "BOTTOMLEFT", sp.x, sp.y + t*SPARKLE_DRIFT_Y)
                        else
                            alpha = fade * opacity
                        end
                        sp.tex:SetVertexColor(sp.r, sp.g, sp.b, alpha)
                        sp.tex:Show()
                    end
                end
            end
        end

        if not anyActive then
            local ddx, ddy = x-lastTrailX, y-lastTrailY
            if ddx*ddx + ddy*ddy < TRAIL_MOVE_THRESHOLD_SQ then trailDormant = true end
        end
    end)

    container:Show()
end

-------------------------------------------------------------------------------
-- Module API
-------------------------------------------------------------------------------

function module:UpdateTrailVisibility()
    local d = db()
    trailActive = d.trailEnabled and ShouldShow()
    if not trailActive then
        for i = 1, trailPoolSize do
            local pt = trailBuf[i]
            if pt and pt.active and pt.tex then pt.tex:Hide() end
        end
    end
end

function module:UpdateTrail()
    local f = frames(); local d = db()
    if not f.trailContainer then return end
    local newSize = d.trailMaxPoints or 20
    if newSize ~= trailPoolSize then EnsureTrailPool(newSize) end
    local dotSize = d.trailDotSize or 24
    for i = 1, trailPoolSize do
        local pt = trailBuf[i]
        if pt and pt.tex then pt.tex:SetSize(dotSize, dotSize) end
    end
end

function module:EnsureTrail()
    local f = frames(); local d = db()
    if not f.trailContainer and d.trailEnabled then
        CreateTrailFrame()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        lastTrailX, lastTrailY = x/scale, y/scale
    end
    self:UpdateTrailVisibility()
end

function module:CreateTrailIfEnabled()
    local d = db()
    if d.trailEnabled then
        CreateTrailFrame()
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        lastTrailX, lastTrailY = x/scale, y/scale
    end
end

function module:DestroyTrail()
    local f = frames()
    if f.trailContainer then
        f.trailContainer:SetScript("OnUpdate", nil)
        f.trailContainer:Hide()
    end
    for i = 1, trailPoolSize do
        local pt = trailBuf[i]
        if pt then if pt.tex then pt.tex:Hide() end; pt.active = false end
    end
    for i = 1, SPARKLE_POOL_SIZE do
        local sp = sparkleBuf[i]
        if sp then if sp.tex then sp.tex:Hide() end; sp.active = false end
    end
    trailHead = 0; trailCount = 0; sparkleHead = 0; trailPoolSize = 0
    trailActive = false; trailDormant = false; trailLastUpdateTime = nil
    f.trailContainer = nil
end
