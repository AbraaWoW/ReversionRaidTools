local _, RRT_NS = ...

-- Ported from Lantern/CursorRing by Abraa
local ASSET_PATH = "Interface\\AddOns\\ReversionRaidTools\\Media\\MouseRing\\"

local CAST_SEGMENTS        = 36
local GCD_SPELL_ID         = 61304
local GCD_SHOW_DELAY       = 0.07
local CAST_TICKER_INTERVAL = 0.033
local ALPHA_CHECK_INTERVAL = 0.5
local TEXCOORD_HALF        = 0.5 / 256

local floor = math.floor
local sqrt  = math.sqrt
local max   = math.max
local rad   = math.rad

local SHAPES = { ring = "ring.tga", thin_ring = "thin_ring.tga" }
local FILLS  = { ring = "ring_fill.tga", thin_ring = "thin_ring_fill.tga" }

local DEFAULTS = {
    enabled             = false,
    showOutOfCombat     = true,
    opacityInCombat     = 1.0,
    opacityOutOfCombat  = 1.0,
    ring1Enabled        = true,
    ring1Size           = 48,
    ring1Shape          = "ring",
    ring1Color          = { r = 1.0, g = 0.66, b = 0.0 },
    ring2Enabled        = false,
    ring2Size           = 32,
    ring2Shape          = "thin_ring",
    ring2Color          = { r = 1.0, g = 1.0, b = 1.0 },
    dotEnabled          = false,
    dotColor            = { r = 1.0, g = 1.0, b = 1.0 },
    dotSize             = 8,
    castEnabled         = true,
    castStyle           = "segments",
    castColor           = { r = 1.0, g = 0.66, b = 0.0 },
    castOffset          = 8,
    gcdEnabled          = false,
    gcdColor            = { r = 0.0, g = 0.56, b = 0.91 },
    gcdOffset           = 8,
    trailEnabled        = false,
    trailStyle          = "glow",
    trailDuration       = 0.4,
    trailColor          = { r = 1.0, g = 1.0, b = 1.0 },
    trailMaxPoints      = 20,
    trailDotSize        = 24,
    trailDotSpacing     = 2,
    trailShrink         = true,
    trailShrinkDistance = false,
    trailColorPreset    = "custom",
    trailSparkle        = "off",
}

-------------------------------------------------------------------------------
-- Module
-------------------------------------------------------------------------------

local module = {}
RRT_NS.MouseRing = module

-------------------------------------------------------------------------------
-- State
-------------------------------------------------------------------------------

local db
local frames      = {}
local inCombat    = false
local inInstance  = false
local isCasting   = false
local gcdActive   = false
local castTicker  = nil
local gcdDelayTimer   = nil
local previewMode     = false
local previewLoopTimer = nil
local fakeCastTimer   = nil
local fakeGCDTimer    = nil
local lastRingX, lastRingY = 0, 0

-------------------------------------------------------------------------------
-- Database
-------------------------------------------------------------------------------

local function getDB()
    if not RRT.MouseRing then RRT.MouseRing = {} end
    local d = RRT.MouseRing
    for k, v in pairs(DEFAULTS) do
        if d[k] == nil then
            if type(v) == "table" then
                d[k] = { r = v.r, g = v.g, b = v.b }
            else
                d[k] = v
            end
        end
    end
    if type(d.trailSparkle) == "boolean" then
        d.trailSparkle = d.trailSparkle and "twinkle" or "off"
    end
    db = d
    return d
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function clamp01(v)
    if v < 0 then return 0 end
    if v > 1 then return 1 end
    return v
end

local cachedClassColor = nil
local function GetPlayerClassColor()
    if not cachedClassColor then
        local _, classToken = UnitClass("player")
        if classToken and RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken] then
            local c = RAID_CLASS_COLORS[classToken]
            cachedClassColor = { r = c.r, g = c.g, b = c.b }
        else
            cachedClassColor = { r = 1, g = 1, b = 1 }
        end
    end
    return cachedClassColor
end

local function RefreshCombatCache()
    inCombat = InCombatLockdown() or UnitAffectingCombat("player")
    local inInst, instType = IsInInstance()
    inInstance = inInst and (instType == "party" or instType == "raid"
        or instType == "pvp" or instType == "arena" or instType == "scenario")
end

local function ShouldShow()
    if previewMode then return true end
    if inCombat or inInstance then return true end
    return db.showOutOfCombat
end

local function GetCurrentOpacity()
    if previewMode then return 1.0 end
    return (inCombat or inInstance) and db.opacityInCombat or db.opacityOutOfCombat
end

-- Bridge for Trail.lua
module._assetPath = ASSET_PATH
function module._db()         return db end
function module._frames()     return frames end
function module._shouldShow() return ShouldShow() end
function module._getOpacity() return GetCurrentOpacity() end
function module._classColor() return GetPlayerClassColor() end

local function GetContainerSize()
    local s = max(db.ring1Enabled and db.ring1Size or 0, db.ring2Enabled and db.ring2Size or 0)
    if db.gcdEnabled then s = max(s, db.ring1Size + db.gcdOffset * 2) end
    if db.castEnabled and db.castStyle == "swipe" then
        s = max(s, db.ring1Size + db.gcdOffset * 2 + db.castOffset * 2)
    end
    return max(s, 16)
end

local function SetTexProps(tex)
    if tex.SetSnapToPixelGrid then
        tex:SetSnapToPixelGrid(false)
        tex:SetTexelSnappingBias(0)
    end
end

-------------------------------------------------------------------------------
-- GCD Cooldown
-------------------------------------------------------------------------------

local function FetchGCDCooldown()
    if C_Spell and C_Spell.GetSpellCooldown then
        local result = C_Spell.GetSpellCooldown(GCD_SPELL_ID)
        if type(result) == "table" then
            return result.startTime or result.start, result.duration, result.modRate
        end
    end
    return nil, nil, nil
end

local function SetupCooldownFrame(cd, parent)
    cd:SetDrawSwipe(true)
    cd:SetDrawEdge(false)
    cd:SetHideCountdownNumbers(true)
    cd:SetReverse(true)
    if cd.SetDrawBling     then cd:SetDrawBling(false) end
    if cd.SetUseCircularEdge then cd:SetUseCircularEdge(true) end
    SetTexProps(cd)
    cd:SetFrameStrata("TOOLTIP")
    cd:SetFrameLevel(parent:GetFrameLevel() + 5)
    cd:EnableMouse(false)
    cd:Hide()
end

-------------------------------------------------------------------------------
-- Cast Ticker
-------------------------------------------------------------------------------

local function StopCastTicker()
    if castTicker then castTicker:Cancel(); castTicker = nil end
    isCasting = false
    if frames.castSegments then
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i]
            if seg then seg:SetVertexColor(1,1,1,0); seg:Hide() end
        end
    end
    if frames.castOverlay then
        frames.castOverlay:SetAlpha(0); frames.castOverlay:SetSize(1,1); frames.castOverlay:Hide()
    end
    if frames.castCooldown then frames.castCooldown:Hide() end
end

local function StartCastTicker()
    if castTicker then return end
    if db.castStyle == "swipe" then return end
    castTicker = C_Timer.NewTicker(CAST_TICKER_INTERVAL, function()
        local now = GetTime()
        local progress = 0
        local _,_,_,castStart,castEnd = UnitCastingInfo("player")
        local _,_,_,chanStart,chanEnd = UnitChannelInfo("player")
        if castStart then
            progress = (now - castStart/1000) / ((castEnd - castStart)/1000)
        elseif chanStart then
            progress = 1 - (now - chanStart/1000) / ((chanEnd - chanStart)/1000)
        else
            StopCastTicker(); return
        end
        progress = clamp01(progress)
        local visible = ShouldShow()
        local c = db.castColor
        if db.castStyle == "segments" and frames.castSegments then
            local lit = floor(progress * CAST_SEGMENTS + 0.5)
            for i = 1, CAST_SEGMENTS do
                local seg = frames.castSegments[i]
                if seg then
                    local show = visible and (i <= lit)
                    seg:SetShown(show)
                    if show then seg:SetVertexColor(c.r, c.g, c.b, 1) end
                end
            end
        elseif db.castStyle == "fill" and frames.castOverlay then
            local show = visible and progress > 0
            frames.castOverlay:SetShown(show)
            if show then
                frames.castOverlay:SetAlpha(1)
                local sz = db.ring1Size * max(progress, 0.01)
                frames.castOverlay:SetSize(sz, sz)
            end
        end
    end)
end

-------------------------------------------------------------------------------
-- GCD
-------------------------------------------------------------------------------

local function ProcessGCDUpdate()
    if gcdDelayTimer then gcdDelayTimer:Cancel(); gcdDelayTimer = nil end
    if not db.gcdEnabled or not frames.gcdCooldown then
        if frames.gcdCooldown then frames.gcdCooldown:Hide(); gcdActive = false end
        return
    end
    if not ShouldShow() then frames.gcdCooldown:Hide(); gcdActive = false; return end
    if isCasting then return end
    local start, duration, modRate = FetchGCDCooldown()
    if start and duration and duration > 0 and start > 0 then
        gcdDelayTimer = C_Timer.NewTimer(GCD_SHOW_DELAY, function()
            gcdDelayTimer = nil
            if isCasting or not ShouldShow() or not frames.gcdCooldown then return end
            frames.gcdCooldown:Show(); gcdActive = true
            if modRate then frames.gcdCooldown:SetCooldown(start, duration, modRate)
            else frames.gcdCooldown:SetCooldown(start, duration) end
        end)
    else
        frames.gcdCooldown:Hide(); gcdActive = false
    end
end

-------------------------------------------------------------------------------
-- Visibility
-------------------------------------------------------------------------------

local function UpdateVisibility()
    if not frames.container then return end
    local show = ShouldShow()
    local alpha = GetCurrentOpacity()
    frames.container:SetShown(show)
    frames.container:SetAlpha(alpha)
    if frames.ring1Tex then frames.ring1Tex:SetShown(show and db.ring1Enabled) end
    if frames.ring2Tex then frames.ring2Tex:SetShown(show and db.ring2Enabled) end
    if frames.dotTex   then frames.dotTex:SetShown(show and db.dotEnabled) end
end

-------------------------------------------------------------------------------
-- Appearance Updates
-------------------------------------------------------------------------------

local function UpdateDotAppearance()
    if not frames.dotTex then return end
    local c = db.dotColor
    frames.dotTex:SetVertexColor(c.r, c.g, c.b, 1)
    frames.dotTex:SetSize(db.dotSize, db.dotSize)
    frames.dotTex:SetShown(db.dotEnabled)
end

local function UpdateRingAppearance(ringNum)
    local prefix = "ring" .. ringNum
    local tex = frames[prefix .. "Tex"]
    if not tex or not frames.container then return end
    local enabled = db[prefix .. "Enabled"]
    local size    = db[prefix .. "Size"]
    local shape   = db[prefix .. "Shape"]
    local color   = db[prefix .. "Color"]
    tex:SetTexture(ASSET_PATH .. (SHAPES[shape] or "ring.tga"), "CLAMP", "CLAMP", "TRILINEAR")
    tex:SetTexCoord(TEXCOORD_HALF, 1-TEXCOORD_HALF, TEXCOORD_HALF, 1-TEXCOORD_HALF)
    tex:SetSize(size, size)
    tex:SetVertexColor(color.r, color.g, color.b, 1)
    tex:SetShown(enabled)
    frames.container:SetSize(GetContainerSize(), GetContainerSize())
    if ringNum == 1 and frames.castSegments then
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i]
            if seg then seg:SetSize(db.ring1Size, db.ring1Size) end
        end
    end
end

local function UpdateGCDAppearance()
    if not frames.gcdCooldown then return end
    local size = db.ring1Size + db.gcdOffset * 2
    frames.gcdCooldown:SetSize(size, size)
    frames.gcdCooldown:SetSwipeTexture(ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga"))
    local c = db.gcdColor
    frames.gcdCooldown:SetSwipeColor(c.r, c.g, c.b, 1)
    if frames.container then frames.container:SetSize(GetContainerSize(), GetContainerSize()) end
end

local function UpdateCastAppearance()
    if not frames.container then return end
    if frames.castSegments then
        local texPath = (db.castStyle == "fill")
            and (ASSET_PATH .. (FILLS[db.ring1Shape] or "ring_fill.tga"))
            or  (ASSET_PATH .. "cast_segment.tga")
        for i = 1, CAST_SEGMENTS do
            local seg = frames.castSegments[i]
            if seg then seg:SetTexture(texPath, "CLAMP","CLAMP","TRILINEAR"); seg:SetSize(db.ring1Size, db.ring1Size) end
        end
    end
    if frames.castOverlay then
        local fillPath = ASSET_PATH .. (FILLS[db.ring1Shape] or "ring_fill.tga")
        frames.castOverlay:SetTexture(fillPath, "CLAMP","CLAMP","TRILINEAR")
        local c = db.castColor
        frames.castOverlay:SetVertexColor(c.r, c.g, c.b, 1)
    end
    if frames.castCooldown then
        local size = db.ring1Size + db.gcdOffset*2 + db.castOffset*2
        frames.castCooldown:SetSize(size, size)
        frames.castCooldown:SetSwipeTexture(ASSET_PATH .. (SHAPES[db.ring1Shape] or "ring.tga"))
        local c = db.castColor
        frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1)
    end
    frames.container:SetSize(GetContainerSize(), GetContainerSize())
end

-- Public API for Options
function module:UpdateRing(ringNum) UpdateRingAppearance(ringNum) end
function module:UpdateDot()         UpdateDotAppearance() end
function module:UpdateGCD()         UpdateGCDAppearance() end
function module:UpdateCast()        UpdateCastAppearance() end
function module:UpdateVisibility()
    UpdateVisibility()
    if self.UpdateTrailVisibility then self:UpdateTrailVisibility() end
end

-------------------------------------------------------------------------------
-- Preview
-------------------------------------------------------------------------------

function module:SetPreviewMode(enabled)
    previewMode = enabled
    if previewLoopTimer then previewLoopTimer:Cancel(); previewLoopTimer = nil end
    if enabled then
        self:TestBoth()
        previewLoopTimer = C_Timer.NewTicker(3, function()
            if not previewMode then return end
            self:TestBoth()
        end)
    end
    UpdateVisibility()
    if self.UpdateTrailVisibility then self:UpdateTrailVisibility() end
end

function module:IsPreviewActive() return previewMode end

function module:TestCast(duration)
    duration = duration or 2.5
    if not frames.container or not db.castEnabled then return end
    if fakeCastTimer then fakeCastTimer:Cancel(); fakeCastTimer = nil end
    StopCastTicker()
    isCasting = true
    local startTime = GetTime()
    local c = db.castColor
    if db.castStyle == "swipe" and frames.castCooldown then
        frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1)
        frames.castCooldown:Show()
        frames.castCooldown:SetCooldown(startTime, duration)
        fakeCastTimer = C_Timer.NewTimer(duration, function()
            fakeCastTimer = nil; isCasting = false; frames.castCooldown:Hide()
        end)
    else
        castTicker = C_Timer.NewTicker(CAST_TICKER_INTERVAL, function()
            local progress = clamp01((GetTime() - startTime) / duration)
            if progress >= 1 then StopCastTicker(); isCasting = false; return end
            if db.castStyle == "segments" and frames.castSegments then
                local lit = floor(progress * CAST_SEGMENTS + 0.5)
                for i = 1, CAST_SEGMENTS do
                    local seg = frames.castSegments[i]
                    if seg then
                        local show = (i <= lit); seg:SetShown(show)
                        if show then seg:SetVertexColor(c.r, c.g, c.b, 1) end
                    end
                end
            elseif db.castStyle == "fill" and frames.castOverlay then
                local show = progress > 0; frames.castOverlay:SetShown(show)
                if show then
                    frames.castOverlay:SetAlpha(1)
                    frames.castOverlay:SetSize(db.ring1Size * max(progress, 0.01), db.ring1Size * max(progress, 0.01))
                end
            end
        end)
    end
end

function module:TestGCD(duration)
    duration = duration or 1.5
    if not frames.gcdCooldown or not db.gcdEnabled then return end
    if fakeGCDTimer then fakeGCDTimer:Cancel(); fakeGCDTimer = nil end
    local c = db.gcdColor
    frames.gcdCooldown:SetSwipeColor(c.r, c.g, c.b, 1)
    frames.gcdCooldown:Show(); gcdActive = true
    frames.gcdCooldown:SetCooldown(GetTime(), duration)
    fakeGCDTimer = C_Timer.NewTimer(duration, function()
        fakeGCDTimer = nil; frames.gcdCooldown:Hide(); gcdActive = false
    end)
end

function module:TestBoth() self:TestGCD(1.5); self:TestCast(2.5) end

-------------------------------------------------------------------------------
-- Frame Creation
-------------------------------------------------------------------------------

local function CreateRingTexture(parent, ringNum)
    local prefix = "ring" .. ringNum
    local tex = parent:CreateTexture(nil, "BORDER")
    tex:SetTexture(ASSET_PATH .. (SHAPES[db[prefix.."Shape"]] or "ring.tga"), "CLAMP","CLAMP","TRILINEAR")
    tex:SetTexCoord(TEXCOORD_HALF, 1-TEXCOORD_HALF, TEXCOORD_HALF, 1-TEXCOORD_HALF)
    tex:SetSize(db[prefix.."Size"], db[prefix.."Size"])
    tex:SetPoint("CENTER")
    local c = db[prefix.."Color"]
    tex:SetVertexColor(c.r, c.g, c.b, 1)
    SetTexProps(tex)
    tex:SetShown(db[prefix.."Enabled"])
    return tex
end

local function CreateDotTexture(parent)
    local dot = parent:CreateTexture(nil, "OVERLAY")
    dot:SetTexture(ASSET_PATH .. "dot.tga", "CLAMP","CLAMP","TRILINEAR")
    dot:SetSize(db.dotSize, db.dotSize); dot:SetPoint("CENTER")
    local c = db.dotColor; dot:SetVertexColor(c.r, c.g, c.b, 1)
    SetTexProps(dot); dot:SetShown(db.dotEnabled)
    return dot
end

local function CreateCastSegments(parent)
    local segments = {}
    for i = 1, CAST_SEGMENTS do
        local seg = parent:CreateTexture(nil, "ARTWORK")
        seg:SetTexture(ASSET_PATH.."cast_segment.tga","CLAMP","CLAMP","TRILINEAR")
        seg:SetSize(db.ring1Size, db.ring1Size); seg:SetPoint("CENTER")
        seg:SetRotation(rad((i-1) * (360/CAST_SEGMENTS)))
        seg:SetVertexColor(1,1,1,0)
        seg:SetTexCoord(TEXCOORD_HALF,1-TEXCOORD_HALF,TEXCOORD_HALF,1-TEXCOORD_HALF)
        SetTexProps(seg); seg:Hide()
        segments[i] = seg
    end
    return segments
end

local function CreateCastOverlay(parent)
    local overlay = parent:CreateTexture(nil, "OVERLAY")
    overlay:SetTexture(ASSET_PATH..(FILLS[db.ring1Shape] or "ring_fill.tga"),"CLAMP","CLAMP","TRILINEAR")
    local c = db.castColor; overlay:SetVertexColor(c.r, c.g, c.b, 1)
    overlay:SetAlpha(0); overlay:SetSize(1,1); overlay:SetPoint("CENTER")
    overlay:SetTexCoord(TEXCOORD_HALF,1-TEXCOORD_HALF,TEXCOORD_HALF,1-TEXCOORD_HALF)
    SetTexProps(overlay); overlay:Hide()
    return overlay
end

local function CreateFrames()
    if frames.container then return end
    local container = CreateFrame("Frame", "RRTCursorRing", UIParent)
    container:SetSize(GetContainerSize(), GetContainerSize())
    container:SetFrameStrata("TOOLTIP"); container:SetIgnoreParentScale(false)
    container:EnableMouse(false); container:SetClampedToScreen(false)
    frames.container = container

    frames.ring2Tex = CreateRingTexture(container, 2)
    frames.ring1Tex = CreateRingTexture(container, 1)
    frames.dotTex   = CreateDotTexture(container)

    local gcdSize = db.ring1Size + db.gcdOffset * 2
    local gcdCd = CreateFrame("Cooldown", "RRTCursorRing_GCD", container)
    gcdCd:SetSize(gcdSize, gcdSize); gcdCd:SetPoint("CENTER")
    SetupCooldownFrame(gcdCd, container)
    gcdCd:SetSwipeTexture(ASSET_PATH..(SHAPES[db.ring1Shape] or "ring.tga"))
    local gc = db.gcdColor; gcdCd:SetSwipeColor(gc.r, gc.g, gc.b, 1)
    gcdCd:SetScript("OnCooldownDone", function() gcdActive=false; gcdCd:Hide() end)
    frames.gcdCooldown = gcdCd

    local castSize = db.ring1Size + db.gcdOffset*2 + db.castOffset*2
    local castCd = CreateFrame("Cooldown", "RRTCursorRing_Cast", container)
    castCd:SetSize(castSize, castSize); castCd:SetPoint("CENTER")
    SetupCooldownFrame(castCd, container)
    castCd:SetFrameLevel(container:GetFrameLevel() + 6)
    castCd:SetSwipeTexture(ASSET_PATH..(SHAPES[db.ring1Shape] or "ring.tga"))
    local cc = db.castColor; castCd:SetSwipeColor(cc.r, cc.g, cc.b, 1)
    castCd:SetScript("OnCooldownDone", function() castCd:Hide() end)
    frames.castCooldown = castCd

    frames.castSegments = CreateCastSegments(container)
    frames.castOverlay  = CreateCastOverlay(container)

    local alphaTimer = 0
    container:SetScript("OnUpdate", function(self, elapsed)
        local x, y = GetCursorPosition()
        local scale = UIParent:GetEffectiveScale()
        x, y = floor(x/scale+0.5), floor(y/scale+0.5)
        if x ~= lastRingX or y ~= lastRingY then
            lastRingX, lastRingY = x, y
            self:ClearAllPoints()
            self:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
        end
        alphaTimer = alphaTimer + elapsed
        if alphaTimer >= ALPHA_CHECK_INTERVAL then
            alphaTimer = 0
            -- Stop preview if RRT UI is hidden
            if previewMode and RRT_NS.RRTUI and not RRT_NS.RRTUI:IsShown() then
                module:SetPreviewMode(false)
            end
            UpdateVisibility()
        end
    end)

    if module.CreateTrailIfEnabled then module:CreateTrailIfEnabled() end

    local x, y = GetCursorPosition()
    local scale = UIParent:GetEffectiveScale()
    x, y = floor(x/scale+0.5), floor(y/scale+0.5)
    lastRingX, lastRingY = x, y
    container:ClearAllPoints()
    container:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    UpdateVisibility()
    if module.UpdateTrailVisibility then module:UpdateTrailVisibility() end
    container:Show()
end

local function DestroyFrames()
    StopCastTicker()
    if gcdDelayTimer    then gcdDelayTimer:Cancel();    gcdDelayTimer    = nil end
    if previewLoopTimer then previewLoopTimer:Cancel(); previewLoopTimer = nil end
    if fakeCastTimer    then fakeCastTimer:Cancel();    fakeCastTimer    = nil end
    if fakeGCDTimer     then fakeGCDTimer:Cancel();     fakeGCDTimer     = nil end
    if frames.container then
        frames.container:SetScript("OnUpdate", nil)
        frames.container:Hide()
    end
    if module.DestroyTrail then module:DestroyTrail() end
    gcdActive = false; isCasting = false; previewMode = false
    frames.container = nil; frames.ring1Tex = nil; frames.ring2Tex = nil
    frames.dotTex = nil; frames.gcdCooldown = nil; frames.castCooldown = nil
    frames.castSegments = nil; frames.castOverlay = nil
end

-------------------------------------------------------------------------------
-- GCD event toggle
-------------------------------------------------------------------------------

function module:SetGCDEnabled(enabled)
    if self._eventFrame then
        if enabled then self._eventFrame:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        else
            self._eventFrame:UnregisterEvent("SPELL_UPDATE_COOLDOWN")
            if frames.gcdCooldown then frames.gcdCooldown:Hide() end
            gcdActive = false
        end
    end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local function OnEvent(_, event, unit)
    if event == "PLAYER_ENTERING_WORLD" then
        RefreshCombatCache()
        if not frames.container then CreateFrames() end
        UpdateVisibility()
        if module.UpdateTrailVisibility then module:UpdateTrailVisibility() end
        C_Timer.After(0, function()
            if frames.container and frames.container:IsShown() then
                local x, y = GetCursorPosition()
                local scale = UIParent:GetEffectiveScale()
                x, y = floor(x/scale+0.5), floor(y/scale+0.5)
                lastRingX, lastRingY = x, y
                frames.container:ClearAllPoints()
                frames.container:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
            end
        end)

    elseif event == "PLAYER_LEAVING_WORLD" then
        DestroyFrames()

    elseif event == "PLAYER_REGEN_DISABLED" or event == "PLAYER_REGEN_ENABLED" then
        RefreshCombatCache()
        UpdateVisibility()
        if module.UpdateTrailVisibility then module:UpdateTrailVisibility() end

    elseif event == "UNIT_SPELLCAST_START" or event == "UNIT_SPELLCAST_CHANNEL_START" then
        if unit == "player" and db.castEnabled then
            local _,_,_,startTime,endTime
            if event == "UNIT_SPELLCAST_CHANNEL_START" then
                _,_,_,startTime,endTime = UnitChannelInfo("player")
            else
                _,_,_,startTime,endTime = UnitCastingInfo("player")
            end
            if startTime and endTime then
                if gcdDelayTimer then gcdDelayTimer:Cancel(); gcdDelayTimer = nil end
                isCasting = true
                if db.castStyle == "swipe" and frames.castCooldown then
                    local dur = (endTime - startTime) / 1000
                    local start = startTime / 1000
                    local c = db.castColor
                    frames.castCooldown:SetSwipeColor(c.r, c.g, c.b, 1)
                    frames.castCooldown:Show()
                    frames.castCooldown:SetCooldown(start, dur)
                else
                    StartCastTicker()
                end
            end
        end

    elseif event == "UNIT_SPELLCAST_STOP" or event == "UNIT_SPELLCAST_CHANNEL_STOP"
        or event == "UNIT_SPELLCAST_INTERRUPTED" or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_FAILED_QUIET" then
        if unit == "player" then
            if UnitCastingInfo("player") or UnitChannelInfo("player") then return end
            StopCastTicker(); isCasting = false
        end

    elseif event == "SPELL_UPDATE_COOLDOWN" then
        ProcessGCDUpdate()
    end
end

-------------------------------------------------------------------------------
-- Init / Enable / Disable
-------------------------------------------------------------------------------

function module:Enable()
    getDB()
    if not db.enabled then return end
    RefreshCombatCache()
    local ef = CreateFrame("Frame")
    ef:RegisterEvent("PLAYER_ENTERING_WORLD")
    ef:RegisterEvent("PLAYER_LEAVING_WORLD")
    ef:RegisterEvent("PLAYER_REGEN_DISABLED")
    ef:RegisterEvent("PLAYER_REGEN_ENABLED")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_START",         "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_STOP",          "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START", "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP",  "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED",   "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_FAILED",        "player")
    ef:RegisterUnitEvent("UNIT_SPELLCAST_FAILED_QUIET",  "player")
    if db.gcdEnabled then ef:RegisterEvent("SPELL_UPDATE_COOLDOWN") end
    ef:SetScript("OnEvent", OnEvent)
    self._eventFrame = ef
    if IsLoggedIn and IsLoggedIn() then CreateFrames() end
end

function module:Disable()
    DestroyFrames()
    if self._eventFrame then
        self._eventFrame:UnregisterAllEvents()
        self._eventFrame:SetScript("OnEvent", nil)
        self._eventFrame = nil
    end
end

function module:Reload()
    self:Disable()
    self:Enable()
end
