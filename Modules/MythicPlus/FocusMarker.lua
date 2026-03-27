local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Focus Marker — applique un marqueur sur la cible du focus via bouton sécurisé
-- Fonctionne en et hors combat grâce à SecureActionButtonTemplate.
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    enabled      = false,
    locked       = true,
    markerIndex  = 8,   -- 1=Star 2=Circle 3=Diamond 4=Triangle 5=Moon 6=Square 7=Cross 8=Skull
    announce     = false,
    onlyDungeon  = false,
    buttonWidth  = 110,
    buttonHeight = 24,
    fontSize     = 10,
    pos          = nil,
}

local MARKER_NAMES = {
    [1] = "Star",   [2] = "Circle",  [3] = "Diamond", [4] = "Triangle",
    [5] = "Moon",   [6] = "Square",  [7] = "Cross",   [8] = "Skull",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Frame container (movable, non-secure)
-- ─────────────────────────────────────────────────────────────────────────────
local _frame = CreateFrame("Frame", "RRTFocusMarker", UIParent, "BackdropTemplate")
_frame:SetSize(120, 44)
_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
_frame:SetMovable(true)
_frame:SetClampedToScreen(true)
_frame:Hide()

-- Zone de drag en haut (non couverte par le bouton sécurisé)
local _dragHandle = CreateFrame("Frame", nil, _frame)
_dragHandle:SetPoint("TOPLEFT")
_dragHandle:SetPoint("TOPRIGHT")
_dragHandle:SetHeight(16)
_dragHandle:EnableMouse(true)
_dragHandle:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and _frame:IsMovable() then _frame:StartMoving() end
end)
_dragHandle:SetScript("OnMouseUp", function(self)
    _frame:StopMovingOrSizing()
    local p, _, rp, x, y = _frame:GetPoint()
    if RRT and RRT.MP_FocusMarker then
        RRT.MP_FocusMarker.pos = { point = p, relPoint = rp, x = x, y = y }
    end
end)

local _dragLabel = _dragHandle:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
_dragLabel:SetPoint("CENTER")
do local f, _, fl = GameFontNormalSmall:GetFont(); if f then _dragLabel:SetFont(f, 8, fl or "") end end
_dragLabel:SetText("Focus Marker")
_dragLabel:SetTextColor(0.7, 0.7, 0.7, 1)

-- ─────────────────────────────────────────────────────────────────────────────
-- Secure button — exécuté par le moteur WoW, valide en combat
-- ─────────────────────────────────────────────────────────────────────────────
local _btn = CreateFrame("Button", "RRTFocusMarkerBtn", _frame, "SecureActionButtonTemplate,BackdropTemplate")
_btn:SetSize(110, 24)
_btn:SetPoint("BOTTOM", _frame, "BOTTOM", 0, 2)
_btn:SetAttribute("type", "macro")
-- macrotext mis à jour dans UpdateMacroText()

local _btnLabel = _btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
_btnLabel:SetPoint("CENTER")
_btnLabel:SetText("Mark Focus")

_btn:SetBackdrop({
    bgFile   = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
_btn:SetBackdropColor(0.12, 0.12, 0.12, 0.85)
_btn:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
_btn:SetScript("OnEnter", function(self)
    self:SetBackdropBorderColor(0.6, 0.6, 0.6, 1)
end)
_btn:SetScript("OnLeave", function(self)
    self:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- State
-- ─────────────────────────────────────────────────────────────────────────────
local function db() return RRT and RRT.MP_FocusMarker or DEFAULTS end

local function UpdateButtonStyle()
    local d  = db()
    local idx = d.markerIndex or 8
    _btn:SetAttribute("macrotext", string.format("/tm [@focus,exists] %d", idx))
    local name = MARKER_NAMES[idx] or tostring(idx)
    _btnLabel:SetText("Mark (" .. name .. ")")

    local bw = d.buttonWidth  or 110
    local bh = d.buttonHeight or 24
    local fs = d.fontSize     or 10
    _btn:SetSize(bw, bh)
    _frame:SetSize(bw + 10, bh + 18)  -- +18 pour le drag handle
    do local f, _, fl = GameFontNormalSmall:GetFont()
        if f then _btnLabel:SetFont(f, fs, fl or "") end
    end
end

-- Alias pour compatibilité interne
local UpdateMacroText = UpdateButtonStyle

-- ─────────────────────────────────────────────────────────────────────────────
-- READY_CHECK announce (hors combat uniquement — SendChatMessage est protégé)
-- ─────────────────────────────────────────────────────────────────────────────
local _ev = CreateFrame("Frame", "RRTFocusMarkerEv")

local function IsInDungeon()
    local inI, t = IsInInstance()
    return inI and (t == "party" or t == "raid")
end

local function ShouldShow()
    local d = db()
    if not d.enabled then return false end
    if d.onlyDungeon and not IsInDungeon() then return false end
    return true
end

local function OnEvent(_, event)
    local d = db()
    if not d.enabled then return end

    if event == "PLAYER_ENTERING_WORLD" then
        if ShouldShow() then
            _frame:Show()
        else
            _frame:Hide()
        end
        return
    end

    if event == "READY_CHECK" and d.announce then
        if PlayerIsInCombat() then return end
        local idx  = d.markerIndex or 8
        local name = MARKER_NAMES[idx] or tostring(idx)
        local msg  = string.format("My kick marker is {%s}", name)
        if IsInRaid() then
            pcall(SendChatMessage, msg, "RAID")
        elseif IsInGroup() then
            pcall(SendChatMessage, msg, "PARTY")
        end
    end
end

_ev:RegisterEvent("READY_CHECK")
_ev:RegisterEvent("PLAYER_ENTERING_WORLD")
_ev:SetScript("OnEvent", nil)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS     = DEFAULTS
module.MARKER_NAMES = MARKER_NAMES

function module:Enable()
    local d = db()
    if d.pos then
        _frame:ClearAllPoints()
        _frame:SetPoint(d.pos.point, UIParent, d.pos.relPoint, d.pos.x, d.pos.y)
    end
    local unlocked = not d.locked
    _frame:SetMovable(unlocked)
    _dragHandle:EnableMouse(unlocked)
    UpdateMacroText()
    if d.enabled then
        _ev:SetScript("OnEvent", OnEvent)
        if ShouldShow() then
            _frame:Show()
        else
            _frame:Hide()
        end
    else
        _ev:SetScript("OnEvent", nil)
        _frame:Hide()
    end
end

local _previewMode = false

function module:UpdateDisplay()
    UpdateMacroText()
    if _previewMode then
        -- En preview : juste rafraîchir le label, ne pas toucher la visibilité
        return
    end
    self:Enable()
end

function module:SetPreviewMode(enabled)
    _previewMode = enabled
    if enabled then
        UpdateMacroText()
        _frame:SetMovable(true)
        _dragHandle:EnableMouse(true)
        _frame:Show()
    else
        _previewMode = false
        -- Restaure l'état complet (locked, onlyDungeon, enabled)
        self:Enable()
    end
end

function module:ResetPosition()
    _frame:ClearAllPoints()
    _frame:SetPoint("CENTER", UIParent, "CENTER", 0, 160)
    if RRT and RRT.MP_FocusMarker then RRT.MP_FocusMarker.pos = nil end
end

RRT_NS.MP_FocusMarker = module
