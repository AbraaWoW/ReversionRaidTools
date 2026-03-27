local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Focus Interrupt Indicator
-- Affiche le texte "INTERRUPT" quand le focus cast quelque chose d'interruptible.
-- L'alpha reflète la disponibilité de l'interrupt du joueur en temps réel.
-- Source : ItruliaQoL/src/focus-interrupt-indicator
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    enabled     = false,
    locked      = true,
    displayText = "INTERRUPT",
    color       = { r = 1, g = 0.2, b = 0.2, a = 1 },
    fontSize    = 28,
    fontOutline = "OUTLINE",
    playSound   = false,
    sound       = nil,
    playTTS     = false,
    tts         = "",
    ttsVolume   = 50,
    pos         = nil,
}

-- Interrupt spell IDs per specialization (spec ID → spellID ou nil)
local INTERRUPT_BY_SPEC = {
    -- Death Knight
    [250] = 47528, [251] = 47528, [252] = 47528,
    -- Demon Hunter
    [577] = 183752, [581] = 183752, [1480] = 183752,
    -- Druid (Balance=78675, Feral/Guardian=106839, Resto=nil)
    [102] = 78675, [103] = 106839, [104] = 106839, [105] = nil,
    -- Evoker
    [1467] = 351338, [1468] = 351338, [1473] = 351338,
    -- Hunter (MM/BM=Counter Shot, SV=Muzzle)
    [253] = 147362, [254] = 147362, [255] = 187707,
    -- Mage
    [62] = 2139, [63] = 2139, [64] = 2139,
    -- Monk (Brewmaster/Windwalker=Spear Hand, Mistweaver=nil)
    [268] = 116705, [269] = 116705, [270] = nil,
    -- Paladin (Holy=nil, Prot/Ret=Rebuke)
    [65] = nil, [66] = 96231, [70] = 96231,
    -- Priest (Shadow=Silence, Holy/Disc=nil)
    [256] = nil, [257] = nil, [258] = 15487,
    -- Rogue
    [259] = 1766, [260] = 1766, [261] = 1766,
    -- Shaman
    [262] = 57994, [263] = 57994, [264] = 57994,
    -- Warlock (Affliction/Destro=Spell Lock, Demo=Axe Toss)
    [265] = 19647, [266] = 119914, [267] = 19647,
    -- Warrior
    [71] = 6552, [72] = 6552, [73] = 6552,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame
-- ─────────────────────────────────────────────────────────────────────────────
local _frame = CreateFrame("Frame", "RRTFocusInterrupt", UIParent, "BackdropTemplate")
_frame:SetSize(150, 36)
_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
_frame:SetMovable(true)
_frame:SetClampedToScreen(true)
_frame:Hide()

local _label = _frame:CreateFontString(nil, "OVERLAY")
_label:SetFont(STANDARD_TEXT_FONT, 28, "OUTLINE")
_label:SetPoint("CENTER")
_label:SetText("INTERRUPT")

_frame:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and self:IsMovable() then self:StartMoving() end
end)
_frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if RRT and RRT.MP_FocusInterrupt then
        RRT.MP_FocusInterrupt.pos = { point = p, relPoint = rp, x = x, y = y }
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────
local _interruptId      = nil   -- spell ID du joueur (mis à jour selon spec)
local _focusCasting     = false -- le focus est en train de caster
local _notInterruptible = false -- le cast n'est pas interruptible
local _soundPlayed      = false
local _previewMode      = false

local function db() return RRT and RRT.MP_FocusInterrupt or DEFAULTS end

local function RefreshStyle()
    local d = db()
    _label:SetFont(STANDARD_TEXT_FONT, d.fontSize or 28, d.fontOutline or "OUTLINE")
    local c = d.color or DEFAULTS.color
    _label:SetTextColor(c.r, c.g, c.b, c.a or 1)
    _label:SetText(d.displayText or "INTERRUPT")
    _frame:SetSize(math.max(_label:GetStringWidth() + 10, 50), math.max(_label:GetStringHeight() + 4, 20))
end

local function GetInterruptSpell()
    local specID = GetSpecializationInfo(GetSpecialization() or 0)
    if specID then
        return INTERRUPT_BY_SPEC[specID]
    end
    return nil
end

local function PlayAlert()
    local d = db()
    if d.playSound and d.sound then
        pcall(PlaySoundFile, RRT_NS.LSM:Fetch("sound", d.sound), "Master")
    elseif d.playTTS and d.tts and d.tts ~= "" then
        pcall(C_VoiceChat.SpeakText, 0, d.tts, 1, d.ttsVolume or 50, true)
    end
end

local function CheckFocusCast()
    _focusCasting     = false
    _notInterruptible = false

    if not UnitExists("focus") then return end

    -- Channel en cours ?
    local _, _, _, _, _, _, _, notInt = UnitChannelInfo("focus")
    if notInt ~= nil then
        _focusCasting     = true
        _notInterruptible = notInt
        return
    end

    -- Cast en cours ?
    local _, _, _, _, _, _, _, notInt2 = UnitCastingInfo("focus")
    if notInt2 ~= nil then
        _focusCasting     = true
        _notInterruptible = notInt2
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- OnUpdate — alpha temps réel selon cooldown
-- ─────────────────────────────────────────────────────────────────────────────
local _acc = 0
local function OnUpdate(_, elapsed)
    _acc = _acc + elapsed
    if _acc < 0.05 then return end  -- ~20 fps, suffit
    _acc = 0

    if _previewMode then
        _frame:SetAlpha(1)
        if not _frame:IsShown() then RefreshStyle(); _frame:Show() end
        return
    end

    if not _focusCasting or _notInterruptible then
        _frame:Hide()
        _soundPlayed = false
        return
    end

    -- Cooldown de l'interrupt du joueur
    local ready = true
    if _interruptId then
        local cd = C_Spell.GetSpellCooldown(_interruptId)
        if cd and cd.startTime and cd.startTime > 0 then
            ready = false
        end
    end

    _frame:SetAlpha(ready and 1 or 0.4)

    if not _frame:IsShown() then
        RefreshStyle()
        _frame:Show()
    end

    if ready and not _soundPlayed then
        _soundPlayed = true
        PlayAlert()
    elseif not ready then
        _soundPlayed = false
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local _ev = CreateFrame("Frame", "RRTFocusInterruptEv")

local function OnEvent(_, event)
    local d = db()
    if not d.enabled then return end

    if event == "PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_ENTERING_WORLD" then
        _interruptId = GetInterruptSpell()
        CheckFocusCast()

    elseif event == "PLAYER_FOCUS_CHANGED" then
        _focusCasting = false
        _soundPlayed  = false
        _frame:Hide()
        CheckFocusCast()

    elseif event == "UNIT_SPELLCAST_START"
        or event == "UNIT_SPELLCAST_CHANNEL_START" then
        CheckFocusCast()

    elseif event == "UNIT_SPELLCAST_STOP"
        or event == "UNIT_SPELLCAST_FAILED"
        or event == "UNIT_SPELLCAST_INTERRUPTED"
        or event == "UNIT_SPELLCAST_CHANNEL_STOP" then
        _focusCasting = false
        _soundPlayed  = false
        _frame:Hide()
    end
end

_ev:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
_ev:RegisterEvent("PLAYER_ENTERING_WORLD")
_ev:RegisterEvent("PLAYER_FOCUS_CHANGED")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_START",          "focus")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_START",  "focus")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_STOP",           "focus")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_FAILED",         "focus")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_INTERRUPTED",    "focus")
_ev:RegisterUnitEvent("UNIT_SPELLCAST_CHANNEL_STOP",   "focus")
_ev:SetScript("OnEvent", nil)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    local d = db()
    if d.pos then
        _frame:ClearAllPoints()
        _frame:SetPoint(d.pos.point, UIParent, d.pos.relPoint, d.pos.x, d.pos.y)
    end
    _frame:SetMovable(not d.locked)
    _frame:EnableMouse(not d.locked)
    if d.enabled then
        _interruptId = GetInterruptSpell()
        RefreshStyle()
        _ev:SetScript("OnEvent", OnEvent)
        _frame:SetScript("OnUpdate", OnUpdate)
    else
        _frame:Hide()
        _focusCasting = false
        _ev:SetScript("OnEvent", nil)
        _frame:SetScript("OnUpdate", nil)
    end
end

function module:UpdateDisplay() self:Enable() end

function module:SetPreviewMode(enabled)
    _previewMode = enabled
    if enabled then
        RefreshStyle()
        _frame:SetAlpha(1)
        _frame:Show()
        -- S'assurer que OnUpdate tourne pour maintenir la frame visible
        _frame:SetScript("OnUpdate", OnUpdate)
    else
        _previewMode = false
        if not db().enabled then
            _frame:Hide()
            _frame:SetScript("OnUpdate", nil)
        end
    end
end

function module:ResetPosition()
    _frame:ClearAllPoints()
    _frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
    if RRT and RRT.MP_FocusInterrupt then RRT.MP_FocusInterrupt.pos = nil end
end

RRT_NS.MP_FocusInterrupt = module
