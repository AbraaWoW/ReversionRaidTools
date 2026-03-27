local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Healer Mana Indicator — affiche la mana % de chaque soigneur du groupe
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    enabled     = false,
    locked      = true,
    fontSize    = 14,
    fontOutline = "OUTLINE",
    lowThreshold  = 30,   -- % mana considered "low" (turns orange)
    critThreshold = 15,   -- % mana considered "critical" (turns red)
    pos         = nil,
}

local ROW_H    = 18
local ROW_PAD  = 2
local MIN_W    = 120
local PAD_W    = 16   -- padding horizontal de la frame

local _frame = CreateFrame("Frame", "RRTHealerMana", UIParent, "BackdropTemplate")
_frame:SetSize(MIN_W, 20)
_frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
_frame:SetMovable(true)
_frame:SetClampedToScreen(true)
_frame:Hide()

_frame:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and not db().locked and (_previewMode or self:IsMovable()) then
        self:StartMoving()
    end
end)
_frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if RRT and RRT.MP_HealerMana then
        RRT.MP_HealerMana.pos = { point = p, relPoint = rp, x = x, y = y }
    end
end)

local function db() return RRT and RRT.MP_HealerMana or DEFAULTS end

-- Label pool
local _labels = {}
local function GetLabel(i)
    if not _labels[i] then
        local fs = _frame:CreateFontString(nil, "OVERLAY")
        fs:SetFont(STANDARD_TEXT_FONT, 14, "OUTLINE")
        fs:SetJustifyH("LEFT")
        _labels[i] = fs
    end
    return _labels[i]
end

-- Repositionne les labels et retourne la largeur max du contenu
local function RepositionLabels(rowH)
    local maxW = MIN_W
    for i, lbl in ipairs(_labels) do
        lbl:ClearAllPoints()
        lbl:SetPoint("TOPLEFT", _frame, "TOPLEFT", PAD_W * 0.5, -((i - 1) * (rowH + ROW_PAD)))
        local w = lbl:GetStringWidth()
        if w > maxW then maxW = w end
    end
    return maxW
end

local function HideLabels(from)
    for i = from, #_labels do
        _labels[i]:SetText("")
    end
end

local function GetHealers()
    local healers = {}
    local units = {}
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do tinsert(units, "raid"..i) end
    elseif IsInGroup() then
        tinsert(units, "player")
        for i = 1, GetNumSubgroupMembers() do tinsert(units, "party"..i) end
    else
        tinsert(units, "player")
    end
    for _, unit in ipairs(units) do
        if UnitExists(unit) and UnitGroupRolesAssigned(unit) == "HEALER" then
            tinsert(healers, unit)
        end
    end
    return healers
end

local function RefreshDisplay()
    local d     = db()
    local healers = GetHealers()

    if #healers == 0 then
        _frame:Hide()
        return
    end

    local low  = d.lowThreshold  or 30
    local crit = d.critThreshold or 15
    local fontSize = d.fontSize  or 14
    local outline  = d.fontOutline or "OUTLINE"
    local rowH = math.max(fontSize, ROW_H)

    for i, unit in ipairs(healers) do
        local lbl  = GetLabel(i)
        lbl:SetFont(STANDARD_TEXT_FONT, fontSize, outline)

        local name = UnitName(unit) or "?"
        local maxM = UnitPowerMax(unit, Enum.PowerType.Mana)
        local curM = UnitPower(unit, Enum.PowerType.Mana)
        local pct  = 0
        if maxM and maxM > 0 then
            local ok, val = pcall(function() return math.floor(curM / maxM * 100) end)
            if ok and val then pct = val end
        end

        local r, g, b
        if pct <= crit then
            r, g, b = 1, 0.2, 0.2      -- red
        elseif pct <= low then
            r, g, b = 1, 0.65, 0.0     -- orange
        else
            r, g, b = 0.2, 0.9, 0.2    -- green
        end

        lbl:SetTextColor(r, g, b, 1)
        lbl:SetText(string.format("%s: %d%%", name, pct))
    end

    local maxW = RepositionLabels(rowH)
    HideLabels(#healers + 1)
    local totalH = #healers * (rowH + ROW_PAD) - ROW_PAD
    _frame:SetSize(maxW + PAD_W, math.max(totalH, fontSize))
    _frame:Show()
end

-- Throttled OnUpdate — refresh every 0.5s while enabled
local _acc = 0
local _previewMode = false

local function OnUpdate(_, elapsed)
    if _previewMode then return end  -- preview gère son propre affichage
    _acc = _acc + elapsed
    if _acc < 0.5 then return end
    _acc = 0
    local d = db()
    if not d.enabled then return end
    RefreshDisplay()
end

-- Events for roster changes (force immediate refresh)
local _ev = CreateFrame("Frame", "RRTHealerManaEv")

local function OnEvent(self, event)
    if _previewMode then return end
    local d = db()
    if not d.enabled then return end
    _acc = 0.5  -- trigger immediate refresh on next OnUpdate tick
    RefreshDisplay()
end

_ev:RegisterEvent("GROUP_ROSTER_UPDATE")
_ev:RegisterEvent("PLAYER_ENTERING_WORLD")
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
    local unlocked = not d.locked
    _frame:SetMovable(unlocked)
    _frame:EnableMouse(unlocked)
    if d.enabled then
        _ev:SetScript("OnEvent", OnEvent)
        _frame:SetScript("OnUpdate", OnUpdate)
        RefreshDisplay()
    else
        _frame:Hide()
        _frame:SetScript("OnUpdate", nil)
        _ev:SetScript("OnEvent", nil)
    end
end

function module:UpdateDisplay()
    if _previewMode then
        self:SetPreviewMode(true)
    else
        self:Enable()
    end
end

function module:SetPreviewMode(enabled)
    _previewMode = enabled
    local d = db()
    if enabled then
        -- Toujours draggable en preview pour positionner
        _frame:SetMovable(true)
        _frame:EnableMouse(true)

        local fontSize = d.fontSize or 14
        local outline  = d.fontOutline or "OUTLINE"
        local rowH     = math.max(fontSize, ROW_H)
        local low      = d.lowThreshold  or 30
        local crit     = d.critThreshold or 15
        local samples  = {
            { name = "Healer1", pct = 82 },
            { name = "Healer2", pct = 24 },
            { name = "Healer3", pct = 9  },
        }
        for i, s in ipairs(samples) do
            local lbl = GetLabel(i)
            lbl:SetFont(STANDARD_TEXT_FONT, fontSize, outline)
            local r, g, b
            if s.pct <= crit then r,g,b = 1,0.2,0.2
            elseif s.pct <= low then r,g,b = 1,0.65,0
            else r,g,b = 0.2,0.9,0.2 end
            lbl:SetTextColor(r, g, b, 1)
            lbl:SetText(string.format("%s: %d%%", s.name, s.pct))
        end
        local maxW = RepositionLabels(rowH)
        HideLabels(4)
        local totalH = 3 * (rowH + ROW_PAD) - ROW_PAD
        _frame:SetSize(maxW + PAD_W, math.max(totalH, fontSize))
        _frame:Show()
    else
        _previewMode = false
        -- Restaurer le réglage locked
        local unlocked = not d.locked
        _frame:SetMovable(unlocked)
        _frame:EnableMouse(unlocked)
        _frame:Hide()
        if d.enabled then RefreshDisplay() end
    end
end

function module:ResetPosition()
    _frame:ClearAllPoints()
    _frame:SetPoint("CENTER", UIParent, "CENTER", 200, 0)
    if RRT and RRT.MP_HealerMana then RRT.MP_HealerMana.pos = nil end
end

RRT_NS.MP_HealerMana = module
