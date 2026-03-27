local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Potion Alert — affiche un texte quand la potion de combat est disponible
-- ─────────────────────────────────────────────────────────────────────────────

local DEFAULTS = {
    enabled           = false,
    locked            = true,
    enabledInDungeons = true,
    enabledInRaids    = true,
    displayText       = "Potion ready",
    color             = { r = 1, g = 1, b = 1, a = 1 },
    fontSize          = 18,
    fontOutline       = "OUTLINE",
    playSound         = false,
    sound             = nil,
    playTTS           = false,
    tts               = "",
    ttsVolume         = 50,
    pos               = nil,
}

local POTIONS = {
    212263, 212264, 212265,   -- Tempered Potion (TWW)
    241292, 241293,           -- Draught of Rampant Abandon (Midnight)
    241308, 241309,           -- Light's Potential (Midnight)
}

local _frame = CreateFrame("Frame", "RRTPotionAlert", UIParent, "BackdropTemplate")
_frame:SetSize(150, 30)
_frame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
_frame:SetMovable(true)
_frame:SetClampedToScreen(true)
_frame:Hide()

local _label = _frame:CreateFontString(nil, "OVERLAY")
_label:SetFont(STANDARD_TEXT_FONT, 18, "OUTLINE")
_label:SetPoint("CENTER")
_label:SetText("Potion ready")

_frame:SetScript("OnMouseDown", function(self, btn)
    if btn == "LeftButton" and self:IsMovable() then self:StartMoving() end
end)
_frame:SetScript("OnMouseUp", function(self)
    self:StopMovingOrSizing()
    local p, _, rp, x, y = self:GetPoint()
    if RRT and RRT.MP_PotionAlert then
        RRT.MP_PotionAlert.pos = { point = p, relPoint = rp, x = x, y = y }
    end
end)

local _onCD = false
local function db() return RRT and RRT.MP_PotionAlert or DEFAULTS end

local function InMythicDungeon()
    local inI, t = IsInInstance()
    if not inI or t ~= "party" then return false end
    return GetDifficultyInfo(GetDungeonDifficultyID()) == "Mythic"
end
local function InRaid() local inI, t = IsInInstance(); return inI and t == "raid" end

local function RefreshStyle()
    local d = db()
    _label:SetFont(STANDARD_TEXT_FONT, d.fontSize or 18, d.fontOutline or "OUTLINE")
    local c = d.color or DEFAULTS.color
    _label:SetTextColor(c.r, c.g, c.b, c.a or 1)
    _label:SetText(d.displayText or "Potion ready")
    _frame:SetSize(math.max(_label:GetStringWidth() + 10, 50), math.max(_label:GetStringHeight() + 4, 20))
end

local function OnEvent(self, event, ...)
    local d = db()
    _frame:Hide()

    if event == "ENCOUNTER_START" then
        _onCD = false
        return
    end

    local potion
    for _, id in ipairs(POTIONS) do
        local _, _, enabled = C_Container.GetItemCooldown(id)
        if enabled then potion = id; break end
    end
    if not potion then return end

    if (d.enabledInDungeons and InMythicDungeon())
    or (d.enabledInRaids and InRaid() and PlayerIsInCombat()) then
        local start = C_Container.GetItemCooldown(potion)
        if start == 0 then
            if _onCD then
                if d.playSound and d.sound then
                    pcall(PlaySoundFile, RRT_NS.LSM:Fetch("sound", d.sound), "Master")
                elseif d.playTTS and d.tts and d.tts ~= "" then
                    pcall(C_VoiceChat.SpeakText, 0, d.tts, 1, d.ttsVolume or 50, true)
                end
            end
            _onCD = false
            RefreshStyle()
            _frame:Show()
        else
            _onCD = true
        end
    end
end

local _ev = CreateFrame("Frame", "RRTPotionAlertEv")
_ev:RegisterEvent("PLAYER_ENTERING_WORLD")
_ev:RegisterEvent("BAG_UPDATE_COOLDOWN")
_ev:RegisterEvent("SPELL_UPDATE_COOLDOWN")
_ev:RegisterEvent("PLAYER_REGEN_ENABLED")
_ev:RegisterEvent("PLAYER_REGEN_DISABLED")
_ev:RegisterEvent("ENCOUNTER_START")
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
        RefreshStyle()
        _ev:SetScript("OnEvent", OnEvent)
    else
        _frame:Hide()
        _ev:SetScript("OnEvent", nil)
    end
end

function module:UpdateDisplay() self:Enable() end

function module:ResetPosition()
    _frame:ClearAllPoints()
    _frame:SetPoint("CENTER", UIParent, "CENTER", 0, 300)
    if RRT and RRT.MP_PotionAlert then RRT.MP_PotionAlert.pos = nil end
end

RRT_NS.MP_PotionAlert = module
