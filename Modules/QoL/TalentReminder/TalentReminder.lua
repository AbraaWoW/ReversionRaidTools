local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- Defaults
-- ─────────────────────────────────────────────────────────────────────────────
local DEFAULTS = {
    enabled  = false,
    loadouts = {},
}

local lastCheckedZone = nil

-- ─────────────────────────────────────────────────────────────────────────────
-- DB helper
-- ─────────────────────────────────────────────────────────────────────────────
local function db()
    if not RRT or not RRT.TalentReminder then return nil end
    return RRT.TalentReminder
end

local function ChatMsg(text)
    DEFAULT_CHAT_FRAME:AddMessage("|cFFBB66FFRRT:|r " .. text)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- TLX (TalentLoadoutsEx) helpers — all pcall-guarded
-- ─────────────────────────────────────────────────────────────────────────────
local function IsTLXAvailable()
    local ok, result = pcall(function()
        return C_AddOns.IsAddOnLoaded("TalentLoadoutsEx")
            and _G.TLX ~= nil
            and _G.TalentLoadoutEx ~= nil
    end)
    return ok and result
end

local function GetCurrentTLXLoadout()
    if not IsTLXAvailable() then return nil, nil end
    local ok, result = pcall(function()
        local tlx = _G.TLX
        if not tlx or not tlx.GetLoadedData then return nil end
        local loaded = { tlx.GetLoadedData() }
        if loaded[1] then return { name = loaded[1].name, text = loaded[1].text } end
        return nil
    end)
    if ok and result then return result.name, result.text end
    return nil, nil
end

local function GetTLXLoadouts()
    if not IsTLXAvailable() then return nil end
    local ok, result = pcall(function()
        local _, class = UnitClass("player")
        local specIndex = GetSpecialization()
        if not class or not specIndex then return nil end
        local tlxData = _G.TalentLoadoutEx
        if not tlxData or not tlxData[class] then return nil end
        local specTable = tlxData[class][specIndex]
        if not specTable then return nil end
        local loadouts = {}
        for _, entry in ipairs(specTable) do
            if entry.text and not entry.isLegacy then
                table.insert(loadouts, entry)
            end
        end
        return #loadouts > 0 and loadouts or nil
    end)
    return ok and result or nil
end

local function GetTLXLoadoutByName(name)
    local loadouts = GetTLXLoadouts()
    if not loadouts then return nil end
    for _, entry in ipairs(loadouts) do
        if entry.name == name then return entry end
    end
    return nil
end

local function GetConfigName(configID)
    local info = C_Traits.GetConfigInfo(configID)
    return info and info.name or "Unknown"
end

local function SwapToTLXLoadout(name)
    if InCombatLockdown() then ChatMsg("|cFFFF4444Cannot change talents in combat.|r"); return false end
    local loadout = GetTLXLoadoutByName(name)
    if not loadout then ChatMsg("|cFFFF4444Loadout '" .. name .. "' not found.|r"); return false end
    C_Timer.After(0, function()
        if InCombatLockdown() then return end
        pcall(function()
            local h = SlashCmdList["TalentLoadoutsEx_Load"]
            if h then h(name) end
        end)
    end)
    ChatMsg(string.format("Swapping to |cFFFF9900%s|r", name))
    return true
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Blizzard talent helpers
-- ─────────────────────────────────────────────────────────────────────────────
local function GetSpecID()
    return PlayerUtil and PlayerUtil.GetCurrentSpecID and PlayerUtil.GetCurrentSpecID() or 0
end

local function GetSpecName()
    local idx = GetSpecialization()
    if idx then
        local _, name = GetSpecializationInfo(idx)
        return name or "Unknown"
    end
    return "Unknown"
end

local function GetCurrentTalentInfo()
    if IsTLXAvailable() then
        local tlxName, tlxExport = GetCurrentTLXLoadout()
        if tlxName then return tlxName, tlxExport, tlxName end
        local activeConfigID = C_ClassTalents.GetActiveConfigID()
        local exportString   = activeConfigID and C_Traits.GenerateImportString(activeConfigID)
        return nil, exportString, "Unsaved Build"
    end

    local specID        = GetSpecID()
    local activeConfigID = C_ClassTalents.GetActiveConfigID()
    if not activeConfigID then return nil, nil, nil end

    local savedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    local configName    = "Unsaved Build"
    if savedConfigID then
        local info = C_Traits.GetConfigInfo(savedConfigID)
        if info and info.name then configName = info.name end
    end

    local exportString = C_Traits.GenerateImportString(activeConfigID)
    return savedConfigID or activeConfigID, exportString, configName
end

local function SwapToSaved(saved)
    if InCombatLockdown() then ChatMsg("|cFFFF4444Cannot change talents in combat.|r"); return false end
    if saved.tlxMode and saved.tlxName then return SwapToTLXLoadout(saved.tlxName) end

    local specID  = GetSpecID()
    local configs = C_ClassTalents.GetConfigIDsBySpecID(specID) or {}
    for index, id in ipairs(configs) do
        if id == saved.configID then
            if ClassTalentHelper and ClassTalentHelper.SwitchToLoadoutByIndex then
                ClassTalentHelper.SwitchToLoadoutByIndex(index)
                ChatMsg(string.format("Swapping to |cFFFF9900%s|r", saved.configName or "saved build"))
                return true
            end
        end
    end
    ChatMsg("|cFFFF4444Loadout not found.|r")
    return false
end

local function TriggerUIRebuild()
    if RRT_NS and RRT_NS.UI and RRT_NS.UI.RebuildTalentLoadouts then
        RRT_NS.UI.RebuildTalentLoadouts()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Static Popups
-- ─────────────────────────────────────────────────────────────────────────────
StaticPopupDialogs["RRT_TALENT_SAVE"] = {
    text    = "%s",
    button1 = "Save Build",
    button2 = "Skip",
    OnAccept = function(self)
        local data = self.data
        if not data or not db() then return end
        db().loadouts = db().loadouts or {}

        if IsTLXAvailable() then
            local tlxName, tlxExport = GetCurrentTLXLoadout()
            if tlxName then
                db().loadouts[data.key] = { tlxMode = true, tlxName = tlxName, exportString = tlxExport,
                    name = data.name, diffName = data.diffName }
                ChatMsg(string.format("Saved TLX loadout for |cFFFF9900%s|r", data.name))
                TriggerUIRebuild()
                return
            else
                ChatMsg("|cFFFF4444No TLX loadout active. Select a loadout first.|r"); return
            end
        end

        local configID, exportString, configName = GetCurrentTalentInfo()
        db().loadouts[data.key] = { configID = configID, exportString = exportString, configName = configName,
            name = data.name, diffName = data.diffName }
        ChatMsg(string.format("Saved |cFFFF9900%s|r for %s", configName, data.name))
        TriggerUIRebuild()
    end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["RRT_TALENT_MISMATCH"] = {
    text    = "%s",
    button1 = "Swap Talents",
    button2 = "Update Saved",
    button3 = "Ignore",
    OnAccept = function(self)
        local data = self.data
        if data and data.saved then SwapToSaved(data.saved) end
    end,
    OnCancel = function(self)
        local data = self.data
        if not data or not db() then return end
        db().loadouts = db().loadouts or {}

        if IsTLXAvailable() then
            local tlxName, tlxExport = GetCurrentTLXLoadout()
            if tlxName then
                db().loadouts[data.key] = { tlxMode = true, tlxName = tlxName, exportString = tlxExport,
                    name = data.name, diffName = data.diffName }
                ChatMsg(string.format("Updated saved build for |cFFFF9900%s|r", data.name))
                TriggerUIRebuild()
                return
            end
        end

        local configID, exportString, configName = GetCurrentTalentInfo()
        db().loadouts[data.key] = { configID = configID, exportString = exportString, configName = configName,
            name = data.name, diffName = data.diffName }
        ChatMsg(string.format("Updated saved build for |cFFFF9900%s|r", data.name))
        TriggerUIRebuild()
    end,
    OnAlt = function() end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["RRT_TALENT_TLX_UNAVAILABLE"] = {
    text    = "%s",
    button1 = "Update Saved",
    button2 = "Ignore",
    OnAccept = function(self)
        local data = self.data
        if not data or not db() then return end
        db().loadouts = db().loadouts or {}

        if IsTLXAvailable() then
            local tlxName, tlxExport = GetCurrentTLXLoadout()
            if tlxName then
                db().loadouts[data.key] = { tlxMode = true, tlxName = tlxName, exportString = tlxExport,
                    name = data.name, diffName = data.diffName }
                ChatMsg(string.format("Updated saved build for |cFFFF9900%s|r", data.name))
                TriggerUIRebuild()
                return
            end
        end

        local configID, exportString, configName = GetCurrentTalentInfo()
        db().loadouts[data.key] = { configID = configID, exportString = exportString,
            configName = configName, name = data.name, diffName = data.diffName }
        ChatMsg(string.format("Updated saved build for |cFFFF9900%s|r", data.name))
        TriggerUIRebuild()
    end,
    OnCancel = function() end,
    timeout = 0, whileDead = false, hideOnEscape = true, preferredIndex = 3,
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Core check
-- ─────────────────────────────────────────────────────────────────────────────
local function CheckTalents(key, displayName, diffName)
    if InCombatLockdown() then return end
    local d = db()
    if not d or not d.enabled then return end
    d.loadouts = d.loadouts or {}

    local saved                              = d.loadouts[key]
    local configID, exportString, configName = GetCurrentTalentInfo()

    if not saved then
        if IsTLXAvailable() then
            local tlxName = GetCurrentTLXLoadout()
            if not tlxName then
                ChatMsg(string.format("No TLX loadout active for |cFFFF9900%s|r. Select a loadout first.", displayName))
                return
            end
        end
        local diffPart = diffName and (" (" .. diffName .. ")") or ""
        local promptText = "|cFFBB66FFReversion Raid Tools|r\n\n"
            .. string.format("Save your current build for |cFFFF9900%s|r%s?\n\n(%s — %s)",
                displayName, diffPart, GetSpecName(), configName or "Unsaved Build")
        local dialog = StaticPopup_Show("RRT_TALENT_SAVE", promptText)
        if dialog then dialog.data = { key = key, name = displayName, diffName = diffName } end
    else
        local isMismatch = false
        local savedDisplayName = saved.configName or saved.tlxName or "Saved Build"

        if saved.tlxMode then
            local tlxUnavailableReason = nil
            if not IsTLXAvailable() then
                tlxUnavailableReason = "TalentLoadoutsEx not loaded"
            else
                local tlxLoadout = GetTLXLoadoutByName(saved.tlxName)
                if not tlxLoadout then
                    tlxUnavailableReason = "Loadout '" .. (saved.tlxName or "?") .. "' not found"
                end
            end

            if tlxUnavailableReason then
                local promptText = "|cFFBB66FFReversion Raid Tools|r\n\n"
                    .. "|cFFFF4444" .. tlxUnavailableReason .. "|r\n\n"
                    .. "Saved TLX loadout for:\n"
                    .. "|cFFFF9900" .. displayName .. "|r\n\n"
                    .. "Current: |cFF00FF00" .. (configName or "?") .. "|r"
                local dialog = StaticPopup_Show("RRT_TALENT_TLX_UNAVAILABLE", promptText)
                if dialog then dialog.data = { key = key, name = displayName, diffName = diffName } end
                return
            end

            local currentTLX = GetCurrentTLXLoadout()
            isMismatch = (currentTLX ~= saved.tlxName)
            savedDisplayName = saved.tlxName
        else
            isMismatch = (saved.configID ~= configID)
        end

        if isMismatch then
            local promptText = "|cFFBB66FFReversion Raid Tools|r\n\n"
                .. string.format("Talent mismatch for |cFFFF9900%s|r!\n\nActive:  |cFFFF4444%s|r\nSaved:   |cFF00FF00%s|r",
                    displayName, configName or "?", savedDisplayName)
            local dialog = StaticPopup_Show("RRT_TALENT_MISMATCH", promptText)
            if dialog then dialog.data = { key = key, name = displayName, diffName = diffName, saved = saved } end
        end
    end
end

local function OnZoneChanged()
    if InCombatLockdown() then return end
    local d = db()
    if not d or not d.enabled then return end

    local zoneName, instanceType, difficulty, _, _, _, _, instanceID, _, _, _, difficultyName = GetInstanceInfo()

    -- Only check in Mythic+ (difficulty 23)
    if instanceType ~= "party" or difficulty ~= 23 then
        lastCheckedZone = nil
        return
    end

    local specID = GetSpecID()
    if specID == 0 then return end

    local key = specID .. ":" .. instanceID .. ":" .. difficulty
    if lastCheckedZone == key then return end
    lastCheckedZone = key

    C_Timer.After(1, function()
        if not InCombatLockdown() then
            CheckTalents(key, zoneName or "Mythic+", difficultyName)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Events
-- ─────────────────────────────────────────────────────────────────────────────
local eventFrame = CreateFrame("Frame", "RRTTalentReminderEvents")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
eventFrame:RegisterEvent("TRAIT_CONFIG_UPDATED")

eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_ENTERING_WORLD" then
        C_Timer.After(1, function()
            if not InCombatLockdown() then OnZoneChanged() end
        end)
    elseif event == "PLAYER_SPECIALIZATION_CHANGED" then
        lastCheckedZone = nil
    elseif event == "TRAIT_CONFIG_UPDATED" then
        lastCheckedZone = nil
        C_Timer.After(0.5, function()
            if not InCombatLockdown() then OnZoneChanged() end
        end)
    end
end)

-- ─────────────────────────────────────────────────────────────────────────────
-- Module API
-- ─────────────────────────────────────────────────────────────────────────────
local module = {}
module.DEFAULTS = DEFAULTS

function module:Enable()
    lastCheckedZone = nil
    C_Timer.After(1, function()
        if not InCombatLockdown() then OnZoneChanged() end
    end)
end

function module:UpdateDisplay()
    local d = db()
    if not d or not d.enabled then return end
end

function module:ForceCheck()
    lastCheckedZone = nil
    C_Timer.After(0, function()
        if not InCombatLockdown() then OnZoneChanged() end
    end)
end

function module:ClearSaved()
    local d = db()
    if d then d.loadouts = {} end
    lastCheckedZone = nil
    if RRT_NS and RRT_NS.UI and RRT_NS.UI.RebuildTalentLoadouts then
        RRT_NS.UI.RebuildTalentLoadouts()
    end
end

-- Export
RRT_NS.TalentReminder = module
