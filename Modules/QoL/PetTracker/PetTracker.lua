local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults  (enabled state stored in RRT.QoL.PetTrackerEnabled)
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    combatOnly      = false,
    onlyInInstance  = false,
    hideWhenMounted = true,
    showPassive     = true,
}

local WARNING_NONE      = 0
local WARNING_MISSING   = 1
local WARNING_PASSIVE   = 2
local WARNING_WRONG_PET = 3

local isMounted   = false
local isInVehicle = false
local isDead      = false
local isInCombat  = false

-- ─────────────────────────────────────────────────────────────────────────────
-- DB helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function IsEnabled()
    return RRT and RRT.QoL and RRT.QoL.PetTrackerEnabled
end

local function Get(key)
    local d = RRT and RRT.PetTracker
    if d and d[key] ~= nil then return d[key] end
    return DEFAULTS[key]
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Pet class detection (no ns.SpecUtil dependency)
-- ─────────────────────────────────────────────────────────────────────────────
local HUNTER_NO_PET_TALENTS = { 466846, 1232995, 1223323 }
local GRIMOIRE_OF_SACRIFICE  = 108503
local GRIMOIRE_SACRIFICE_BUFF = 196099
local FELGUARD_SPELL         = 30146
local DEMONOLOGY_SPEC        = 2
local UNHOLY_DK_SPEC         = 3
local FROST_MAGE_SPEC        = 3
local WATER_ELEMENTAL_SPELL  = 31687

local function GetClass()
    local _, class = UnitClass("player")
    return class
end

local function GetSpecIndex()
    return GetSpecialization() or 0
end

local function IsPetClass()
    local cls = GetClass()
    return cls == "HUNTER" or cls == "WARLOCK" or cls == "DEATHKNIGHT" or cls == "MAGE"
end

local function ShouldHavePet()
    local cls     = GetClass()
    local specIdx = GetSpecIndex()

    if cls == "HUNTER" then
        for _, id in ipairs(HUNTER_NO_PET_TALENTS) do
            if IsPlayerSpell(id) then return false end
        end
        return true

    elseif cls == "WARLOCK" then
        if IsPlayerSpell(GRIMOIRE_OF_SACRIFICE) then
            if C_UnitAuras.GetPlayerAuraBySpellID(GRIMOIRE_SACRIFICE_BUFF) then return false end
        end
        return true

    elseif cls == "DEATHKNIGHT" then
        return specIdx == UNHOLY_DK_SPEC

    elseif cls == "MAGE" then
        return specIdx == FROST_MAGE_SPEC and IsPlayerSpell(WATER_ELEMENTAL_SPELL)
    end
    return false
end

local FELGUARD_FAMILY_NAMES = {
    enUS = "felguard", enGB = "felguard", deDE = "teufelswache",
    esES = "guardia vil", esMX = "guardia vil", frFR = "gangregarde",
    koKR = "지옥수호병", ptBR = "vil guard", ruRU = "страж скверны",
    zhCN = "恶魔卫士", zhTW = "惡魔守衛",
}

local function IsWrongPet()
    if GetClass() ~= "WARLOCK" then return false end
    if GetSpecIndex() ~= DEMONOLOGY_SPEC then return false end
    if not IsPlayerSpell(FELGUARD_SPELL) then return false end
    local petFamily = UnitCreatureFamily("pet")
    if not petFamily then return false end
    local lf      = petFamily:lower()
    local builtIn = FELGUARD_FAMILY_NAMES[GetLocale()]
    if builtIn and lf:find(builtIn, 1, true) then return false end
    return true
end

local function IsPetPassive()
    if not PetHasActionBar() then return false end
    for i = 1, NUM_PET_ACTION_SLOTS or 10 do
        local name, _, _, isActive = GetPetActionInfo(i)
        if name == "PET_MODE_PASSIVE" and isActive then return true end
    end
    return false
end

local function EvaluateWarning()
    if not IsEnabled()     then return WARNING_NONE end
    if not IsPetClass()    then return WARNING_NONE end
    if isDead or isInVehicle then return WARNING_NONE end
    if Get("hideWhenMounted") and isMounted  then return WARNING_NONE end
    if Get("combatOnly")      and not isInCombat then return WARNING_NONE end
    if Get("onlyInInstance") then
        local inInstance = IsInInstance()
        if not inInstance then return WARNING_NONE end
    end
    if not ShouldHavePet() then return WARNING_NONE end
    if not UnitExists("pet") then return WARNING_MISSING end
    if IsWrongPet()          then return WARNING_WRONG_PET end
    if IsPetPassive() then
        return Get("showPassive") and WARNING_PASSIVE or WARNING_NONE
    end
    return WARNING_NONE
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Text Display integration
-- ─────────────────────────────────────────────────────────────────────────────
local petIconStr = nil
local function GetPetIcon()
    if petIconStr then return petIconStr end
    local tex = C_Spell.GetSpellTexture(883)
    petIconStr = tex and ("|T" .. tex .. ":14:14:0:0:64:64:4:60:4:60|t") or ""
    return petIconStr
end

local function SetDisplay(warning)
    RRT_NS.QoLTextDisplays = RRT_NS.QoLTextDisplays or {}
    local text
    if warning == WARNING_MISSING then
        text = GetPetIcon() .. "|cFFFF4444 No Pet!|r"
    elseif warning == WARNING_PASSIVE then
        text = GetPetIcon() .. "|cFFFFAA00 Pet is Passive|r"
    elseif warning == WARNING_WRONG_PET then
        text = GetPetIcon() .. "|cFFFF4444 Wrong Pet!|r"
    end

    if text then
        RRT_NS.QoLTextDisplays.PetTracker = { SettingsName = "PetTrackerEnabled", text = text }
    else
        RRT_NS.QoLTextDisplays.PetTracker = nil
    end
    RRT_NS:UpdateQoLTextDisplay()
end

local function Refresh()
    SetDisplay(EvaluateWarning())
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local dismountTimer = nil
local DISMOUNT_DELAY = 5

local eventFrame = CreateFrame("Frame", "RRTPetTrackerEvents")
eventFrame:RegisterEvent("UNIT_PET")
eventFrame:RegisterEvent("PET_BAR_UPDATE")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
eventFrame:RegisterEvent("UNIT_ENTERED_VEHICLE")
eventFrame:RegisterEvent("UNIT_EXITED_VEHICLE")
eventFrame:RegisterEvent("PLAYER_DEAD")
eventFrame:RegisterEvent("PLAYER_ALIVE")
eventFrame:RegisterEvent("PLAYER_UNGHOST")
eventFrame:RegisterEvent("SPELLS_CHANGED")
eventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        local was = isMounted
        isMounted = IsMounted()
        if was and not isMounted then
            if dismountTimer then dismountTimer:Cancel() end
            dismountTimer = C_Timer.NewTimer(DISMOUNT_DELAY, function()
                dismountTimer = nil
                Refresh()
            end)
            return
        elseif isMounted then
            if dismountTimer then dismountTimer:Cancel(); dismountTimer = nil end
        end
    elseif event == "UNIT_ENTERED_VEHICLE" and arg1 == "player" then
        isInVehicle = true
    elseif event == "UNIT_EXITED_VEHICLE" and arg1 == "player" then
        isInVehicle = false
    elseif event == "PLAYER_DEAD" then
        isDead = true
    elseif event == "PLAYER_ALIVE" or event == "PLAYER_UNGHOST" then
        isDead = false
    elseif event == "PLAYER_REGEN_DISABLED" then
        isInCombat = true
    elseif event == "PLAYER_REGEN_ENABLED" then
        isInCombat = false
    end
    Refresh()
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    isMounted   = IsMounted()
    isInVehicle = UnitInVehicle("player")
    isDead      = UnitIsDeadOrGhost("player")
    isInCombat  = UnitAffectingCombat("player")
    Refresh()
end

function module:Disable()
    RRT_NS.QoLTextDisplays = RRT_NS.QoLTextDisplays or {}
    RRT_NS.QoLTextDisplays.PetTracker = nil
    RRT_NS:UpdateQoLTextDisplay()
end

function module:UpdateDisplay()
    if IsEnabled() then Refresh() else self:Disable() end
end

-- Export
RRT_NS.PetTracker = module
