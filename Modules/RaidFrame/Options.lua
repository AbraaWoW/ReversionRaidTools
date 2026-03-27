local _, RRT_NS = ...
local DF = _G["DetailsFramework"]
local L = RRT_NS.L

-- Session-only UI state (not persisted) — declared here so all builders can access it
local profileUI = {
    newRaidZoneID      = "",
    raidValidated      = false,
    raidValidatedName  = "",
    newRaidName        = "",
    bossTargetRaid     = "",
    newBossName        = "",
    newSpellID         = "",
    spellValidated     = false,
    spellValidatedName = "",
    spell1 = 0, spell2 = 0, spell3 = 0, spell4 = 0,
    enabled = true,
}

-- Callback set by BuildProfileOverview so add/remove spell can trigger a live refresh
local _overviewRefresh = nil

-- Callback set by UI.lua after DF:BuildMenu so Clear All can refresh DF widgets immediately
local _menuRefresh = nil
local function SetMenuRefreshCallback(fn) _menuRefresh = fn end

-- Selected values for the boss-section dropdowns.
-- Updated via option.onclick (the only guaranteed DF callback path).
-- DF only calls RunHooksForWidget("OnOptionSelected") when the option has onclick,
-- so we embed onclick on every option entry in the values function.
local _selectedBossRaid  = ""   -- updated by boss "Select Raid" dropdown onclick
local _selectedBossName  = ""   -- updated by boss "Select Boss" dropdown onclick
local _selectedSpellIdx  = nil  -- index of spell selected for removal

-- Legacy entry refs (kept for compat, no longer used for value reading)
local _bossRaidDropEntry = nil
local _bossSelectEntry   = nil
local _topRaidDropEntry  = nil

-- ── PA filter helpers ─────────────────────────────────────────────────────
local function IsInPAFilter(spellID)
    for id in (RRT.Settings.RaidFrame.paSpellIDs or ""):gmatch("%d+") do
        if tonumber(id) == spellID then return true end
    end
    return false
end

local function TogglePAFilter(spellID, checked)
    local s = RRT.Settings.RaidFrame
    local ids = {}
    for id in (s.paSpellIDs or ""):gmatch("%d+") do
        local n = tonumber(id)
        if n and n ~= spellID then tinsert(ids, tostring(n)) end
    end
    if checked then tinsert(ids, tostring(spellID)) end
    s.paSpellIDs = table.concat(ids, ",")
    local RF = RRT_NS.RaidFrame
    RF._needsPARebuild = true
    local f = RF.frame
    if f and f:IsShown() then f:Refresh() end
end

-- Confirmation dialog for "Clear All Profiles"
StaticPopupDialogs["RRT_CONFIRM_CLEAR_PROFILES"] = {
    text      = "|cFFFF4444Warning:|r This will delete ALL raid profiles and boss spells. This cannot be undone. Continue?",
    button1   = "Yes, delete all",
    button2   = "Cancel",
    OnAccept  = function()
        local s = RRT.Settings.RaidFrame
        s.debuffProfiles      = {}
        s.raidBossOrder       = {}
        s.raidLabels          = {}
        s.raidZoneIDs         = {}
        s.activeRaid          = ""
        s.activeBoss          = ""
        profileUI.bossTargetRaid     = ""
        profileUI.newBossName        = ""
        profileUI.newSpellID         = ""
        profileUI.spellValidated     = false
        profileUI.spellValidatedName = ""
        profileUI.spell1 = 0; profileUI.spell2 = 0
        profileUI.spell3 = 0; profileUI.spell4 = 0
        _selectedBossRaid = ""
        _selectedBossName = ""
        _selectedSpellIdx = nil
        -- Defer to next frame so the StaticPopup is fully dismissed before refreshing
        C_Timer.After(0, function()
            if _overviewRefresh then _overviewRefresh() end
            if _menuRefresh then _menuRefresh() end
        end)
        print("|cFFBB66FFRaidFrame:|r " .. (RRT_NS.L and RRT_NS.L["msg_raidframe_all_cleared"] or "All profiles cleared."))
    end,
    timeout   = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

local function BuildFrameOptions()
    return {
        { type = "label", get = function() return L["header_raidframe"] end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_enable"],
            desc     = L["opt_raidframe_enable_desc"],
            get      = function() return RRT.Settings.RaidFrame.enabled end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.enabled = value
                local f = RRT_NS.RaidFrame.frame
                if f then
                    if value then f:Show(); f:Refresh() else f:Hide() end
                end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_show_all"],
            desc     = L["opt_raidframe_show_all_desc"],
            get      = function() return RRT.Settings.RaidFrame.showAll end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.showAll = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_lock"],
            desc     = L["opt_raidframe_lock_desc"],
            get      = function() return RRT.Settings.RaidFrame.locked end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.locked = value
            end,
        },

        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_hide_header"],
            desc     = L["opt_raidframe_hide_header_desc"],
            get      = function() return RRT.Settings.RaidFrame.hideHeader end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.hideHeader = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_show_role_icons"],
            desc     = L["opt_raidframe_show_role_icons_desc"],
            get      = function() return RRT.Settings.RaidFrame.showRoleIcons end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.showRoleIcons = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_sort_by_role"],
            desc     = L["opt_raidframe_sort_by_role_desc"],
            get      = function() return RRT.Settings.RaidFrame.sortByRole end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.sortByRole = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_grow_up"],
            desc     = L["opt_raidframe_grow_up_desc"],
            get      = function() return RRT.Settings.RaidFrame.growUp end,
            set      = function(self, _, value)
                local s = RRT.Settings.RaidFrame
                s.growUp = value
                -- Switch the frame anchor so the player row stays at the same screen position
                local f = RRT_NS.RaidFrame.frame
                if f then
                    local h = f:GetHeight() or 0
                    local pos = s.position
                    if value then
                        -- TOPLEFT → BOTTOMLEFT: move y up by frame height
                        s.position = { point = "BOTTOMLEFT", x = pos.x, y = pos.y + h }
                    else
                        -- BOTTOMLEFT → TOPLEFT: move y down by frame height
                        s.position = { point = "TOPLEFT",    x = pos.x, y = pos.y - h }
                    end
                    f:ClearAllPoints()
                    local p = s.position
                    f:SetPoint(p.point, UIParent, p.point, p.x, p.y)
                    if f:IsShown() then f:Refresh() end
                end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_show_debuffs"],
            desc     = L["opt_raidframe_show_debuffs_desc"],
            get      = function() return RRT.Settings.RaidFrame.showDebuffs end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.showDebuffs = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },

        {
            type     = "toggle",
            boxfirst = true,
            name     = L["opt_raidframe_debuff_pulse"],
            desc     = L["opt_raidframe_debuff_pulse_desc"],
            get      = function() return RRT.Settings.RaidFrame.debuffPulse end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.debuffPulse = value
            end,
        },
        {
            type = "range",
            name = L["opt_raidframe_dbf_icon_size"],
            desc = L["opt_raidframe_dbf_icon_size_desc"],
            min  = 10,
            max  = 30,
            step = 1,
            get  = function() return RRT.Settings.RaidFrame.dbfIconSize or 14 end,
            set  = function(self, _, value)
                RRT.Settings.RaidFrame.dbfIconSize = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type = "range",
            name = L["opt_raidframe_bg_alpha"],
            desc = L["opt_raidframe_bg_alpha_desc"],
            min  = 0,
            max  = 1,
            step = 0.05,
            get  = function() return RRT.Settings.RaidFrame.bgAlpha or 0.85 end,
            set  = function(self, _, value)
                RRT.Settings.RaidFrame.bgAlpha = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },

        {
            type = "range",
            name = "Scale",
            desc = "Global scale of the Raid Frame (bars and icons).",
            min  = 0.5,
            max  = 2.0,
            step = 0.05,
            get  = function() return RRT.Settings.RaidFrame.barScale or 1.0 end,
            set  = function(self, _, value)
                RRT.Settings.RaidFrame.barScale = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },
        {
            type     = "toggle",
            boxfirst = true,
            name     = "Auras on left",
            desc     = "Display aura icons to the left of the bar instead of the right.",
            get      = function() return RRT.Settings.RaidFrame.aurasOnLeft end,
            set      = function(self, _, value)
                RRT.Settings.RaidFrame.aurasOnLeft = value
                local f = RRT_NS.RaidFrame.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },

        { type = "blank" },

        { type = "label", get = function() return "|cFFBB66FF" .. L["pa_filter_label"] .. "|r" end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },
        { type = "label", get = function() return L["pa_filter_desc"] end },
        {
            type  = "input",
            name  = L["pa_filter_input_name"],
            desc  = L["pa_filter_input_desc"],
            get   = function() return RRT.Settings.RaidFrame.paSpellIDs or "" end,
            set   = function(self, _, value)
                RRT.Settings.RaidFrame.paSpellIDs = value or ""
                local RF = RRT_NS.RaidFrame
                RF._needsPARebuild = true
                local f = RF.frame
                if f and f:IsShown() then f:Refresh() end
            end,
        },

        { type = "blank" },

        {
            type      = "button",
            name      = L["opt_raidframe_move"],
            desc      = L["opt_raidframe_move_desc"],
            nocombat  = true,
            spacement = true,
            func      = function()
                RRT_NS.RaidFrame:TogglePreview()
                RRT_NS.RaidFrame:ToggleMovePreview()
            end,
        },

    }
end

-- ── Encounter Journal import ──────────────────────────────────────────────
-- Profiles are keyed by a language-agnostic string:
--   • EJ-imported raids/bosses  → EJ numeric ID as string ("1234")
--   • Manually entered EJ IDs   → same (numeric string)
--   • Manually typed names      → the typed name as-is (no EJ link)
-- EJ IDs always take precedence: matching is by numeric map ID, display names are
-- resolved dynamically from the EJ API so they always show in the client locale.

-- Returns the current localized name for a profile key.
-- Numeric keys → EJ lookup; string keys → returned as-is.
local function EJRaidLabel(key)
    -- User-defined custom label takes priority
    local labels = RRT.Settings and RRT.Settings.RaidFrame and RRT.Settings.RaidFrame.raidLabels
    if labels and labels[key] and labels[key] ~= "" then
        return labels[key]
    end
    -- Numeric key → EJ API fallback
    local numID = tonumber(key)
    if not numID then return key end
    local label = key
    pcall(function()
        EJ_SelectInstance(numID)
        local name = EJ_GetInstanceInfo()
        if name and name ~= "" then label = name end
    end)
    return label
end

local function EJBossLabel(key)
    local numID = tonumber(key)
    if not numID then return key end
    local label = key
    pcall(function()
        local info = C_EncounterJournal and C_EncounterJournal.GetEncounterInfo(numID)
        if info and info.name and info.name ~= "" then label = info.name end
    end)
    return label
end

-- Imports raids/bosses from the Encounter Journal into debuffProfiles.
-- matchMapID: numeric instance map ID from GetInstanceInfo(); nil = import all.
--   Matching is purely numeric (dungeonAreaMapID from EJ_GetInstanceInfo), no locale involved.
-- Returns found (bool), foundKey (the EJ instance ID as string, e.g. "1234").
local function EJImport(matchMapID)
    local s = RRT.Settings.RaidFrame
    local found    = false
    local foundKey = nil

    local function absorbInstance(val)
        -- instKey is always the EJ numeric instance ID as a string
        local instKey, instMapID
        if type(val) == "number" then
            instKey = tostring(val)
            local ok = pcall(EJ_SelectInstance, val)
            if not ok then return end
            -- EJ_GetInstanceInfo() → name, desc, bg, btn1, btn2, lore, dungeonAreaMapID, link
            local ok2, _, _, _, _, _, _, mapID = pcall(EJ_GetInstanceInfo)
            instMapID = ok2 and tonumber(mapID) or nil
        elseif type(val) == "string" and val ~= "" then
            -- Fallback: old API returned string names; use as key, no map ID available
            instKey   = val
            instMapID = nil
            pcall(EJ_SelectInstance, val)
        else
            return
        end

        if matchMapID and instMapID ~= matchMapID then return end
        if not s.debuffProfiles[instKey] then s.debuffProfiles[instKey] = {} end

        for j = 1, 30 do
            local ok2, enc = pcall(EJ_GetEncounterInfoByIndex, j)
            if not ok2 or not enc then break end
            local encKey
            if type(enc) == "number" then
                local okN, encName = pcall(EJ_GetEncounterInfo, enc)
                encKey = tostring(enc) .. (okN and encName and (" (" .. encName .. ")") or "")
            elseif type(enc) == "string" and enc ~= "" then
                encKey = enc
            end
            if encKey and not s.debuffProfiles[instKey][encKey] then
                s.debuffProfiles[instKey][encKey] = { 0, 0, 0, 0 }
            end
        end

        found    = true
        foundKey = instKey
    end

    -- Tier-based iteration (primary)
    for tier = 1, 30 do
        if not pcall(EJ_SelectTier, tier) then break end
        for inst = 1, 100 do
            local ok, val = pcall(EJ_GetInstanceByIndex, inst, true)
            if not ok or not val then break end
            absorbInstance(val)
            if matchMapID and found then return found, foundKey end
        end
    end

    -- Flat fallback if tier-based returned nothing
    if not found then
        for inst = 1, 200 do
            local ok, val = pcall(EJ_GetInstanceByIndex, inst, true)
            if not ok or not val then break end
            absorbInstance(val)
            if matchMapID and found then return found, foundKey end
        end
    end

    return found, foundKey
end

local function BuildProfileOptions()
    local RF = RRT_NS.RaidFrame
    local s  = function() return RRT.Settings.RaidFrame end

    return {
        { type = "label", get = function() return L["header_raidframe_profiles"] end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        {
            type  = "button",
            name  = L["opt_raidframe_load_defaults"],
            desc  = L["opt_raidframe_load_defaults_desc"],
            func  = function()
                RRT_NS.RaidFrame:PopulateDefaults()
                if _overviewRefresh then _overviewRefresh() end
                if _menuRefresh     then _menuRefresh()     end
            end,
        },

        { type = "blank" },

        -- ── Raid ──────────────────────────────────────────────────────────────
        (function()
            _topRaidDropEntry = {
                type   = "dropdown",
                name   = L["opt_raidframe_select_raid"],
                values = function()
                    local t = { { value = "", label = L["opt_none"] } }
                    for _, name in ipairs(RF:GetRaidNames()) do
                        tinsert(t, { value = name, label = EJRaidLabel(name) })
                    end
                    return t
                end,
                get = function() return s().activeRaid or "" end,
            }
            return _topRaidDropEntry
        end)(),
        -- Raid Name (required)
        {
            type = "textentry",
            name = L["opt_raidframe_new_raid_name"],
            desc = L["opt_raidframe_new_raid_name_desc"],
            get  = function() return profileUI.newRaidName end,
            set  = function(self, _, value) profileUI.newRaidName = value end,
        },
        -- Zone ID (from wowhead.com/zone=ID) — used for auto-detection on zone enter
        {
            type = "textentry",
            name = L["opt_raidframe_new_raid_ej_id"],
            desc = L["opt_raidframe_new_raid_ej_id_desc"],
            get  = function() return profileUI.newRaidZoneID end,
            set  = function(self, _, value) profileUI.newRaidZoneID = value end,
        },
        -- Add + Delete side by side
        {
            type   = "button",
            inline = true,
            name   = L["opt_raidframe_add_raid"],
            desc   = L["opt_raidframe_add_raid_desc"],
            func = function()
                local customName = profileUI.newRaidName
                local zoneRaw    = profileUI.newRaidZoneID
                if not customName or customName == "" then return end
                -- Key: numeric zone ID if provided, else the name itself
                local key
                local zoneID = tonumber(zoneRaw)
                if zoneID then
                    key = tostring(math.floor(zoneID))
                else
                    key = customName
                end
                if not s().debuffProfiles[key] then s().debuffProfiles[key] = {} end
                -- Store custom display name
                s().raidLabels = s().raidLabels or {}
                s().raidLabels[key] = customName
                -- Store zone ID mapping for auto-detection
                s().raidZoneIDs = s().raidZoneIDs or {}
                if zoneID then
                    s().raidZoneIDs[zoneID] = key
                end
                s().activeRaid = key
                s().activeBoss = ""
                profileUI.newRaidName  = ""
                profileUI.newRaidZoneID = ""
                profileUI.spell1 = 0; profileUI.spell2 = 0
                profileUI.spell3 = 0; profileUI.spell4 = 0
            end,
        },
        {
            type   = "button",
            inline = true,
            name   = L["opt_raidframe_del_raid"],
            desc   = L["opt_raidframe_del_raid_desc"],
            func = function()
                local raid = s().activeRaid
                if raid and raid ~= "" then
                    -- Remove zone ID mapping for this raid
                    s().raidZoneIDs = s().raidZoneIDs or {}
                    for zoneID, key in pairs(s().raidZoneIDs) do
                        if key == raid then
                            s().raidZoneIDs[zoneID] = nil
                            break
                        end
                    end
                    RF:DeleteRaid(raid)
                    s().activeRaid = ""
                    s().activeBoss = ""
                    profileUI.spell1 = 0; profileUI.spell2 = 0
                    profileUI.spell3 = 0; profileUI.spell4 = 0
                end
            end,
        },

        -- ── Boss ──────────────────────────────────────────────────────────────
        -- Select which raid this boss belongs to
        -- onclick on every option is the only guaranteed DF callback path
        {
            type   = "dropdown",
            name   = L["opt_raidframe_boss_target_raid"],
            values = function()
                local t = { {
                    value   = "",
                    label   = L["opt_none"],
                    onclick = function(_, _, v) _selectedBossRaid = v; _selectedBossName = "" end,
                } }
                for _, name in ipairs(RF:GetRaidNames()) do
                    local n = name  -- capture for closure
                    tinsert(t, {
                        value   = n,
                        label   = EJRaidLabel(n),
                        onclick = function(_, _, v) _selectedBossRaid = v; _selectedBossName = "" end,
                    })
                end
                return t
            end,
            get = function() return _selectedBossRaid end,
        },
        -- Select existing boss (for deletion / spell editing)
        {
            type   = "dropdown",
            name   = L["opt_raidframe_select_boss"],
            values = function()
                local t = { {
                    value   = "",
                    label   = L["opt_none"],
                    onclick = function(_, _, v) _selectedBossName = v end,
                } }
                if _selectedBossRaid ~= "" then
                    for _, name in ipairs(RF:GetBossNames(_selectedBossRaid)) do
                        local n = name
                        tinsert(t, {
                            value   = n,
                            label   = EJBossLabel(n),
                            onclick = function(_, _, v) _selectedBossName = v end,
                        })
                    end
                end
                return t
            end,
            get = function() return _selectedBossName end,
        },
        -- New boss name
        {
            type = "textentry",
            name = L["opt_raidframe_new_boss_name"],
            desc = L["opt_raidframe_new_boss_name_desc"],
            get  = function() return profileUI.newBossName end,
            set  = function(self, _, value) profileUI.newBossName = value end,
        },
        -- Add Boss + Delete Boss side by side
        {
            type   = "button",
            inline = true,
            name   = L["opt_raidframe_add_boss"],
            desc   = L["opt_raidframe_add_boss_desc"],
            func   = function()
                local raidName = _selectedBossRaid
                local bossName = profileUI.newBossName
                if raidName == "" then
                    print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_select_raid_first"])
                    return
                end
                if not bossName or bossName == "" then
                    print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_enter_boss_name"])
                    return
                end
                RF:SaveBossSpells(raidName, bossName, {})
                s().activeBoss = bossName
                -- Auto-select the new boss so spells can be added immediately
                _selectedBossName = bossName
                profileUI.newBossName = ""
                profileUI.spell1 = 0; profileUI.spell2 = 0
                profileUI.spell3 = 0; profileUI.spell4 = 0
                if _overviewRefresh then _overviewRefresh() end
            end,
        },
        {
            type   = "button",
            inline = true,
            name   = L["opt_raidframe_del_boss"],
            desc   = L["opt_raidframe_del_boss_desc"],
            func   = function()
                local raidName = _selectedBossRaid
                local bossName = _selectedBossName
                if raidName ~= "" and bossName ~= "" then
                    RF:DeleteBoss(raidName, bossName)
                    _selectedBossName = ""
                    s().activeBoss = ""
                    profileUI.spell1 = 0; profileUI.spell2 = 0
                    profileUI.spell3 = 0; profileUI.spell4 = 0
                    if _overviewRefresh then _overviewRefresh() end
                end
            end,
        },

        -- ── Spell management ──────────────────────────────────────────────────
        { type = "label", get = function() return L["header_raidframe_spell"] end,
          text_template = DF:GetTemplate("font", "ORANGE_FONT_TEMPLATE") },

        -- Spell ID — press Enter to validate, shows name in chat
        {
            type = "textentry",
            name = L["opt_raidframe_new_spell"],
            desc = L["opt_raidframe_new_spell_desc"] .. "\n\nPress Enter to validate and show the spell name.",
            get  = function() return profileUI.newSpellID end,
            set  = function(self, _, value)
                profileUI.newSpellID         = value
                profileUI.spellValidated     = false
                profileUI.spellValidatedName = ""
            end,
            hooks = {
                OnEnterPressed = function()
                    local id = tonumber(profileUI.newSpellID)
                    if not id then
                        print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_invalid_spell_id"])
                        return
                    end
                    local ok, name = pcall(C_Spell.GetSpellName, id)
                    if ok and name and name ~= "" then
                        profileUI.spellValidated     = true
                        profileUI.spellValidatedName = name
                        print("|cFFBB66FFRaidFrame:|r " .. string.format(L["msg_raidframe_ej_valid"], name))
                    else
                        profileUI.spellValidated     = false
                        profileUI.spellValidatedName = ""
                        print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_invalid_spell_id"])
                    end
                end,
            },
        },

        -- Add Spell button
        {
            type      = "button",
            name      = L["opt_raidframe_add_spell"],
            desc      = L["opt_raidframe_add_spell_desc"],
            spacement = true,
            func      = function()
                local raidName = _selectedBossRaid
                local bossName = _selectedBossName
                if raidName == "" or bossName == "" then
                    print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_select_boss_first"])
                    return
                end
                local id = tonumber(profileUI.newSpellID)
                if not id or id <= 0 then
                    print("|cFFBB66FFRaidFrame:|r " .. L["msg_raidframe_invalid_spell_id"])
                    return
                end
                local spells = RF:GetBossSpells(raidName, bossName)
                for _, existing in ipairs(spells) do
                    if existing == id then return end
                end
                local clean = {}
                for _, v in ipairs(spells) do
                    if v and v > 0 then tinsert(clean, v) end
                end
                tinsert(clean, id)
                RF:SaveBossSpells(raidName, bossName, clean)
                profileUI.newSpellID         = ""
                profileUI.spellValidated     = false
                profileUI.spellValidatedName = ""
                _selectedSpellIdx = nil
                if _overviewRefresh then _overviewRefresh() end
            end,
        },

        -- Select spell to remove
        {
            type      = "dropdown",
            name      = L["opt_raidframe_remove_spell"],
            desc      = L["opt_raidframe_remove_spell_desc"],
            spacement = true,
            get       = function()
                return _selectedSpellIdx or 0
            end,
            values = function()
                local t = { { label = L["opt_none"], value = 0,
                    onclick = function() _selectedSpellIdx = nil end } }
                if _selectedBossRaid == "" or _selectedBossName == "" then return t end
                local spells = RF:GetBossSpells(_selectedBossRaid, _selectedBossName)
                for i, id in ipairs(spells) do
                    if id and id > 0 then
                        local ok, name = pcall(C_Spell.GetSpellName, id)
                        local label = tostring(id)
                        if ok and name and name ~= "" then label = label .. " - " .. name end
                        local idx = i
                        tinsert(t, {
                            label   = label,
                            value   = idx,
                            onclick = function() _selectedSpellIdx = idx end,
                        })
                    end
                end
                return t
            end,
        },

        -- Remove selected spell button
        {
            type = "button",
            name = L["opt_raidframe_remove_spell"],
            desc = L["opt_raidframe_remove_spell_desc"],
            func = function()
                if not _selectedSpellIdx or _selectedBossRaid == "" or _selectedBossName == "" then return end
                local current = RF:GetBossSpells(_selectedBossRaid, _selectedBossName)
                local clean = {}
                for j, v in ipairs(current) do
                    if j ~= _selectedSpellIdx and v and v > 0 then tinsert(clean, v) end
                end
                RF:SaveBossSpells(_selectedBossRaid, _selectedBossName, clean)
                _selectedSpellIdx = nil
                if _overviewRefresh then _overviewRefresh() end
            end,
        },

    }
end

local function BuildAllOptions()
    return BuildFrameOptions()
end

local function BuildMidnightCallback()
    return function() end
end

-- ── Custom scrollbar (same dark style as NotePanel / SaveNote) ───────────────
local function MakeScrollBar(sf)
    local SBAR_W = 8
    local track = CreateFrame("Frame", nil, sf:GetParent(), "BackdropTemplate")
    track:SetBackdrop({ bgFile   = "Interface\\Buttons\\WHITE8X8",
                        edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    track:SetBackdropColor(0.08, 0.08, 0.10, 0.90)
    track:SetBackdropBorderColor(0, 0, 0, 0.6)
    track:SetWidth(SBAR_W)

    local thumb = CreateFrame("Frame", nil, track, "BackdropTemplate")
    thumb:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    thumb:SetBackdropColor(0.45, 0.45, 0.45, 0.75)
    thumb:SetWidth(SBAR_W - 2)
    thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
    thumb:EnableMouse(true)

    local function Update()
        local trackH = track:GetHeight()
        local range  = sf:GetVerticalScrollRange()
        if range <= 0 then
            thumb:SetHeight(math.max(1, trackH))
            thumb:ClearAllPoints()
            thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, 0)
            return
        end
        local thumbH = math.max(16, trackH * trackH / (trackH + range))
        thumb:SetHeight(thumbH)
        local pos = -(sf:GetVerticalScroll() / range) * (trackH - thumbH)
        thumb:ClearAllPoints()
        thumb:SetPoint("TOPLEFT", track, "TOPLEFT", 1, pos)
    end

    sf:HookScript("OnVerticalScroll",     Update)
    sf:HookScript("OnScrollRangeChanged", Update)

    local dragging, startY, startScroll = false, 0, 0
    thumb:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        dragging    = true
        startY      = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        startScroll = sf:GetVerticalScroll()
    end)
    thumb:SetScript("OnMouseUp", function() dragging = false end)
    thumb:SetScript("OnUpdate", function()
        if not dragging then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local range  = sf:GetVerticalScrollRange()
        local avail  = trackH - thumb:GetHeight()
        if avail <= 0 then return end
        sf:SetVerticalScroll(math.max(0, math.min(range,
            startScroll + (startY - curY) * range / avail)))
    end)
    track:EnableMouse(true)
    track:SetScript("OnMouseDown", function(_, btn)
        if btn ~= "LeftButton" then return end
        local trackH = track:GetHeight()
        local curY   = select(2, GetCursorPosition()) / UIParent:GetEffectiveScale()
        local bounds = { track:GetBoundsRect() }
        local topPx  = bounds[4]
        local frac   = math.max(0, math.min(1, (topPx - curY) / trackH))
        sf:SetVerticalScroll(frac * sf:GetVerticalScrollRange())
    end)
    thumb:SetScript("OnEnter", function(self) self:SetBackdropColor(0.65, 0.65, 0.65, 0.95) end)
    thumb:SetScript("OnLeave", function(self) self:SetBackdropColor(0.45, 0.45, 0.45, 0.75) end)
    return track
end

-- ── Right-side profile overview panel ────────────────────────────────────────
-- Creates a scrollable panel showing all raids > bosses > spells.
-- Uses a plain ScrollFrame + custom dark scrollbar (same as Send Note preview).
-- The caller (UI.lua) is responsible for anchoring/sizing the returned frame.
local function BuildProfileOverview(parent)
    local LINE_H   = 20
    local SBAR_W   = 8
    local HEADER_H = 26   -- space for title + buttons

    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bg:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
    bg:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.8)

    local header = bg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then header:SetFont(f, 9, fl or "") end end
    header:SetPoint("TOPLEFT", bg, "TOPLEFT", 8, -6)
    header:SetText("|cFFFFAA00" .. L["header_raidframe_spell_list"] .. "|r")

    local clearBtn = CreateFrame("Button", nil, bg, "BackdropTemplate")
    clearBtn:SetSize(120, 18)
    clearBtn:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -4, -3)
    clearBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    clearBtn:SetBackdropColor(0.3, 0.05, 0.05, 0.85)
    clearBtn:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
    local clearBtnLabel = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then clearBtnLabel:SetFont(f, 9, fl or "") end end
    clearBtnLabel:SetPoint("CENTER", clearBtn, "CENTER", 0, 0)
    clearBtnLabel:SetText(L["opt_raidframe_clear_all_profiles"])
    clearBtnLabel:SetTextColor(1, 0.5, 0.5, 1)
    clearBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.5, 0.08, 0.08, 0.95)
        self:SetBackdropBorderColor(1, 0.3, 0.3, 1)
        clearBtnLabel:SetTextColor(1, 0.75, 0.75, 1)
    end)
    clearBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.3, 0.05, 0.05, 0.85)
        self:SetBackdropBorderColor(0.6, 0.15, 0.15, 1)
        clearBtnLabel:SetTextColor(1, 0.5, 0.5, 1)
    end)
    clearBtn:SetScript("OnClick", function()
        StaticPopup_Show("RRT_CONFIRM_CLEAR_PROFILES")
    end)

    local refreshBtn = CreateFrame("Button", nil, bg, "BackdropTemplate")
    refreshBtn:SetSize(60, 18)
    refreshBtn:SetPoint("TOPRIGHT", clearBtn, "TOPLEFT", -4, 0)
    refreshBtn:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    refreshBtn:SetBackdropColor(0.05, 0.15, 0.3, 0.85)
    refreshBtn:SetBackdropBorderColor(0.2, 0.5, 0.8, 1)
    local refreshBtnLabel = refreshBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then refreshBtnLabel:SetFont(f, 9, fl or "") end end
    refreshBtnLabel:SetPoint("CENTER", refreshBtn, "CENTER", 0, 0)
    refreshBtnLabel:SetText(L["opt_raidframe_reload"] or "Reload")
    refreshBtnLabel:SetTextColor(0.5, 0.8, 1, 1)
    refreshBtn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(0.08, 0.25, 0.5, 0.95)
        self:SetBackdropBorderColor(0.4, 0.7, 1, 1)
        refreshBtnLabel:SetTextColor(0.75, 1, 1, 1)
    end)
    refreshBtn:SetScript("OnLeave", function(self)
        self:SetBackdropColor(0.05, 0.15, 0.3, 0.85)
        self:SetBackdropBorderColor(0.2, 0.5, 0.8, 1)
        refreshBtnLabel:SetTextColor(0.5, 0.8, 1, 1)
    end)
    refreshBtn:SetScript("OnClick", function()
        ReloadUI()
    end)

    -- Build flat row list from debuffProfiles
    local function buildData()
        local rows = {}
        local s        = RRT.Settings and RRT.Settings.RaidFrame
        local profiles = s and s.debuffProfiles
        if not profiles then return rows end

        -- Build reverse lookup: profileKey → zoneID (for display)
        local keyToZone = {}
        for zoneID, key in pairs(s.raidZoneIDs or {}) do
            keyToZone[key] = zoneID
        end

        local activeRaid = s.activeRaid or ""

        local raidKeys = {}
        for k in pairs(profiles) do tinsert(raidKeys, k) end
        table.sort(raidKeys)
        for _, rk in ipairs(raidKeys) do
            local label  = EJRaidLabel(rk)
            local zoneID = keyToZone[rk]
            local suffix = zoneID and ("  |cFF888888[Zone: " .. zoneID .. "]|r") or ""
            local active = (rk == activeRaid) and " |cFF00FF00[active]|r" or ""
            tinsert(rows, { kind = "raid", text = label .. suffix .. active })

            -- Use insertion order when available, fall back to alpha sort
            local bossKeys = s.raidBossOrder and s.raidBossOrder[rk]
            if not bossKeys or #bossKeys == 0 then
                bossKeys = {}
                for k in pairs(profiles[rk]) do tinsert(bossKeys, k) end
                table.sort(bossKeys)
            end
            for _, bk in ipairs(bossKeys) do
                tinsert(rows, { kind = "boss", text = EJBossLabel(bk) })
                local spells = profiles[rk][bk]
                for i = 1, #spells do
                    local id = spells[i]
                    if id and id > 0 then
                        local ok, name = pcall(C_Spell.GetSpellName, id)
                        local spellName = (ok and name and name ~= "") and (" - " .. name) or ""
                        local paTag = ""
                        local okPA, isPA = pcall(C_UnitAuras.AuraIsPrivate, id)
                        local isPABool = okPA and isPA or false
                        if isPABool then paTag = " |cFFBB66FF[PA]|r" end
                        tinsert(rows, { kind = "spell", text = tostring(id) .. spellName .. paTag, spellID = id, isPA = isPABool })
                    end
                end
            end
        end
        return rows
    end

    -- ── ScrollFrame + custom scrollbar ───────────────────────────────────────
    local scrollFrame = CreateFrame("ScrollFrame", "RRTProfileOverviewScroll", bg)
    scrollFrame:SetPoint("TOPLEFT",     bg, "TOPLEFT",     4,             -HEADER_H)
    scrollFrame:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -(SBAR_W + 6),  4)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(1)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)

    local sbar = MakeScrollBar(scrollFrame)
    sbar:SetPoint("TOPRIGHT",    bg, "TOPRIGHT",    -4, -HEADER_H)
    sbar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -4,  4)
    sbar:SetWidth(SBAR_W)

    -- ── Row pool ─────────────────────────────────────────────────────────────
    local rowPool = {}

    local function Rebuild()
        local contentW = scrollFrame:GetWidth()
        if contentW < 10 then return end

        scrollContent:SetWidth(contentW)

        local rows = buildData()
        for i, d in ipairs(rows) do
            if not rowPool[i] then
                local row = CreateFrame("Frame", nil, scrollContent)
                row:SetHeight(LINE_H)
                local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
                lbl:SetJustifyH("LEFT")
                lbl:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label = lbl
                rowPool[i] = row
            end
            local row = rowPool[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -((i - 1) * LINE_H))
            row:SetWidth(contentW)
            row:Show()

            row.label:ClearAllPoints()
            if d.kind == "raid" then
                row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(1, 0.67, 0, 1)
            elseif d.kind == "boss" then
                row.label:SetPoint("LEFT", row, "LEFT", 16, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(0.53, 0.8, 1, 1)
            else
                row.label:SetPoint("LEFT", row, "LEFT", 28, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(1, 1, 1, 0.85)
            end
        end
        for i = #rows + 1, #rowPool do rowPool[i]:Hide() end

        scrollContent:SetHeight(math.max(1, #rows * LINE_H))
        scrollFrame:UpdateScrollChildRect()
    end

    bg:SetScript("OnShow", function()
        if scrollFrame:GetWidth() < 10 then
            C_Timer.After(0, function() Rebuild() end)
        else
            Rebuild()
        end
    end)

    bg:HookScript("OnSizeChanged", function() Rebuild() end)

    _overviewRefresh = function()
        if bg:IsShown() then
            Rebuild()
        end
    end

    return bg
end

-- ── PA Picker Panel ───────────────────────────────────────────────────────
-- Displayed on the right side of the "Raidframe" sub-tab.
-- Shows only Private Aura spells from the boss profiles, grouped by Raid > Boss.
-- Each spell has a checkbox that writes its ID into paSpellIDs.
local function BuildPAPickerPanel(parent)
    local LINE_H   = 20
    local SBAR_W   = 8
    local HEADER_H = 30

    local bg = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    bg:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    bg:SetBackdropColor(0.05, 0.05, 0.05, 0.6)
    bg:SetBackdropBorderColor(0.15, 0.15, 0.15, 0.8)

    local hdr = bg:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then hdr:SetFont(f, 9, fl or "") end end
    hdr:SetPoint("TOPLEFT", bg, "TOPLEFT", 8, -8)
    hdr:SetText("|cFFBB66FFPrivate Auras|r  |cFF888888" .. L["pa_picker_header_desc"] .. "|r")

    local sep = bg:CreateTexture(nil, "ARTWORK")
    sep:SetColorTexture(0.25, 0.25, 0.25, 0.8)
    sep:SetHeight(1)
    sep:SetPoint("TOPLEFT",  bg, "TOPLEFT",  4, -(HEADER_H - 2))
    sep:SetPoint("TOPRIGHT", bg, "TOPRIGHT", -4, -(HEADER_H - 2))

    -- Build data: only PA spells, grouped Raid > Boss
    local function buildData()
        local rows = {}
        local s        = RRT.Settings and RRT.Settings.RaidFrame
        local profiles = s and s.debuffProfiles
        if not profiles then return rows end

        local raidKeys = {}
        for k in pairs(profiles) do tinsert(raidKeys, k) end
        table.sort(raidKeys)

        local anyPA = false
        for _, rk in ipairs(raidKeys) do
            local bossKeys = s.raidBossOrder and s.raidBossOrder[rk]
            if not bossKeys or #bossKeys == 0 then
                bossKeys = {}
                for k in pairs(profiles[rk]) do tinsert(bossKeys, k) end
                table.sort(bossKeys)
            end

            local raidBlock = {}
            for _, bk in ipairs(bossKeys) do
                local spells    = profiles[rk][bk]
                local bossBlock = {}
                for i = 1, #spells do
                    local id = spells[i]
                    if id and id > 0 then
                        local okPA, isPA = pcall(C_UnitAuras.AuraIsPrivate, id)
                        if okPA and isPA then
                            local ok, nm = pcall(C_Spell.GetSpellName, id)
                            local label = (ok and nm and nm ~= "") and nm or tostring(id)
                            tinsert(bossBlock, { kind = "spell", text = label, spellID = id })
                            anyPA = true
                        end
                    end
                end
                if #bossBlock > 0 then
                    tinsert(raidBlock, { kind = "boss", text = EJBossLabel(bk) })
                    for _, r in ipairs(bossBlock) do tinsert(raidBlock, r) end
                end
            end
            if #raidBlock > 0 then
                tinsert(rows, { kind = "raid", text = EJRaidLabel(rk) })
                for _, r in ipairs(raidBlock) do tinsert(rows, r) end
            end
        end

        if not anyPA then
            tinsert(rows, { kind = "empty", text = "|cFF666666" .. L["pa_picker_empty"] .. "|r" })
        end
        return rows
    end

    -- ScrollFrame
    local scrollFrame = CreateFrame("ScrollFrame", nil, bg)
    scrollFrame:SetPoint("TOPLEFT",     bg, "TOPLEFT",     4,             -HEADER_H)
    scrollFrame:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -(SBAR_W + 6),  4)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), cur - delta * 30)))
    end)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetWidth(1)
    scrollContent:SetHeight(1)
    scrollFrame:SetScrollChild(scrollContent)

    local sbar = MakeScrollBar(scrollFrame)
    sbar:SetPoint("TOPRIGHT",    bg, "TOPRIGHT",    -4, -HEADER_H)
    sbar:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", -4,  4)
    sbar:SetWidth(SBAR_W)

    local rowPool = {}

    local function Rebuild()
        local contentW = scrollFrame:GetWidth()
        if contentW < 10 then return end
        scrollContent:SetWidth(contentW)

        local rows = buildData()
        for i, d in ipairs(rows) do
            if not rowPool[i] then
                local row = CreateFrame("Frame", nil, scrollContent)
                row:SetHeight(LINE_H)
                local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
                lbl:SetJustifyH("LEFT")
                row.label = lbl
                local chk = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
                chk:SetSize(16, 16)
                chk:SetPoint("LEFT", row, "LEFT", 28, 0)
                chk:Hide()
                row.check = chk
                rowPool[i] = row
            end
            local row = rowPool[i]
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", scrollContent, "TOPLEFT", 0, -((i - 1) * LINE_H))
            row:SetWidth(contentW)
            row:Show()

            row.check:Hide()
            row.label:ClearAllPoints()

            if d.kind == "raid" then
                row.label:SetPoint("LEFT",  row, "LEFT",  4, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(1, 0.67, 0, 1)
            elseif d.kind == "boss" then
                row.label:SetPoint("LEFT",  row, "LEFT",  16, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(0.53, 0.8, 1, 1)
            elseif d.kind == "spell" then
                row.check:Show()
                row.check:SetChecked(IsInPAFilter(d.spellID))
                local sid = d.spellID
                row.check:SetScript("OnClick", function(self)
                    TogglePAFilter(sid, self:GetChecked())
                end)
                row.label:SetPoint("LEFT",  row.check, "RIGHT", 4, 0)
                row.label:SetPoint("RIGHT", row,       "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(1, 1, 1, 0.9)
            else -- empty
                row.label:SetPoint("LEFT",  row, "LEFT",  8, 0)
                row.label:SetPoint("RIGHT", row, "RIGHT", -4, 0)
                row.label:SetText(d.text)
                row.label:SetTextColor(0.5, 0.5, 0.5, 1)
            end
        end
        for i = #rows + 1, #rowPool do rowPool[i]:Hide() end
        scrollContent:SetHeight(math.max(1, #rows * LINE_H))
        scrollFrame:UpdateScrollChildRect()
    end

    bg:SetScript("OnShow", function()
        if scrollFrame:GetWidth() < 10 then
            C_Timer.After(0, Rebuild)
        else
            Rebuild()
        end
    end)
    bg:HookScript("OnSizeChanged", function() Rebuild() end)
    bg.Refresh = Rebuild

    return bg
end

-- Export
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.Options = RRT_NS.UI.Options or {}
RRT_NS.UI.Options.RaidFrame = {
    BuildFrameOptions         = BuildFrameOptions,
    BuildAllOptions           = BuildAllOptions,
    BuildProfileOptions       = BuildProfileOptions,
    BuildProfileOverview      = BuildProfileOverview,
    BuildPAPickerPanel        = BuildPAPickerPanel,
    BuildCallback             = BuildMidnightCallback,
    SetMenuRefreshCallback    = SetMenuRefreshCallback,
}
