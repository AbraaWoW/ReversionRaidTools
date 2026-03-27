local _, RRT_NS = ...

local RaidFrame = {}
RRT_NS.RaidFrame = RaidFrame

local MAX_DBF_SLOTS = 8
RaidFrame.MAX_DBF_SLOTS = MAX_DBF_SLOTS

-- PopulateDefaults — reads from RRT_NS.RaidData (Core/RaidData.lua).
-- raidKey = "Extension - Instance"  (e.g. "Midnight - The Voidspire")
-- bossKey = "id (Name)"  (e.g. "3176 (Imperator Averzian)"), or boss.name if id == 0
function RaidFrame:PopulateDefaults()
    local data = RRT_NS.RaidData
    if not data then return end
    local s = RRT.Settings.RaidFrame

    for _, ext in ipairs(data) do
        for _, inst in ipairs(ext.instances or {}) do
            local raidKey = ext.extension .. " - " .. inst.instance
            if not s.debuffProfiles[raidKey] then s.debuffProfiles[raidKey] = {} end
            if not s.raidBossOrder[raidKey]  then s.raidBossOrder[raidKey]  = {} end

            -- Auto-populate zone ID from RaidData if not already mapped
            if inst.instanceID and inst.instanceID > 0 then
                s.raidZoneIDs = s.raidZoneIDs or {}
                if not s.raidZoneIDs[inst.instanceID] then
                    s.raidZoneIDs[inst.instanceID] = raidKey
                end
            end

            for _, boss in ipairs(inst.bosses or {}) do
                local bossKey = (boss.id and boss.id > 0) and (tostring(boss.id) .. " (" .. boss.name .. ")") or boss.name
                if not s.debuffProfiles[raidKey][bossKey] then
                    s.debuffProfiles[raidKey][bossKey] = {}
                    tinsert(s.raidBossOrder[raidKey], bossKey)
                end
                local existing = s.debuffProfiles[raidKey][bossKey]
                local seen = {}
                for _, id in ipairs(existing) do seen[id] = true end
                for _, sp in ipairs(boss.spells or {}) do
                    if sp.spellID and not seen[sp.spellID] then
                        tinsert(existing, sp.spellID)
                        seen[sp.spellID] = true
                    end
                end
            end
        end
    end

    -- Set active raid to the first entry if not yet set
    if s.activeRaid == "" then
        local enc = data[1]
        if enc and enc.instances and enc.instances[1] then
            s.activeRaid = enc.extension .. " - " .. enc.instances[1].instance
        end
    end
    _spellIDCache = nil
end

function RaidFrame:Init()
    if not RRT.Settings.RaidFrame then
        RRT.Settings.RaidFrame = {}
    end
    local s = RRT.Settings.RaidFrame
    if s.enabled        == nil then s.enabled        = false end
    if s.locked         == nil then s.locked         = false end
    if s.showAll        == nil then s.showAll        = true  end
    if s.spell1         == nil then s.spell1         = 0     end
    if s.spell2         == nil then s.spell2         = 0     end
    if s.hideHeader     == nil then s.hideHeader     = false end
    if s.showRoleIcons  == nil then s.showRoleIcons  = false end
    if s.sortByRole     == nil then s.sortByRole     = false end
    if s.showDebuffs    == nil then s.showDebuffs    = true  end
    if s.showAllDebuffs == nil then s.showAllDebuffs = false  end
    if s.bgAlpha        == nil then s.bgAlpha        = 0.85  end
    if s.dbfIconSize    == nil then s.dbfIconSize    = 14    end
    if s.debuffPulse    == nil then s.debuffPulse    = true  end
    if s.excludeSpells  == nil then s.excludeSpells  = ""    end
    if s.spell3         == nil then s.spell3         = 0     end
    if s.spell4         == nil then s.spell4         = 0     end
    if s.spells               == nil then s.spells               = {}    end
    if s.debuffProfiles       == nil then s.debuffProfiles       = {}    end
    if s.raidBossOrder        == nil then s.raidBossOrder        = {}    end
    -- Migrate existing raids: populate raidBossOrder for any raid that has bosses but no order entry
    for raidKey, bosses in pairs(s.debuffProfiles or {}) do
        if not s.raidBossOrder[raidKey] or #s.raidBossOrder[raidKey] == 0 then
            local order = {}
            for bossName in pairs(bosses) do tinsert(order, bossName) end
            table.sort(order)
            s.raidBossOrder[raidKey] = order
        end
    end
    if s.raidLabels           == nil then s.raidLabels           = {}    end
    if s.raidZoneIDs          == nil then s.raidZoneIDs          = {}    end
    if s.showSpellIDTooltip   == nil then s.showSpellIDTooltip   = true  end
    if s.activeRaid     == nil then s.activeRaid     = ""    end
    if s.activeBoss     == nil then s.activeBoss     = ""    end
    if s.growUp         == nil then s.growUp         = false end
    if s.barScale       == nil then s.barScale       = 1.0   end
    if s.aurasOnLeft    == nil then s.aurasOnLeft    = false end
    if s.paSpellIDs     == nil then s.paSpellIDs     = ""    end
    if not s.position then
        s.position = { point = "TOPLEFT", x = 200, y = -200 }
    end
    -- Auto-populate default boss profiles on first install
    if next(s.debuffProfiles) == nil then
        self:PopulateDefaults()
    end
end

-- Cached flat list of spell IDs aggregated from all debuffProfiles.
-- Rebuilt only when profile data changes, not on every refresh.
local _spellIDCache = nil

local function BuildSpellIDCache(s)
    _spellIDCache = {}
    local seen = {}
    for _, bosses in pairs(s.debuffProfiles or {}) do
        for _, spells in pairs(bosses) do
            for i = 1, #spells do
                local spellID = spells[i]
                if spellID and spellID > 0 and not seen[spellID] then
                    seen[spellID] = true
                    tinsert(_spellIDCache, spellID)
                end
            end
        end
    end
end

local function safeGetAura(unit, spellID)
    if not spellID or spellID == 0 then return nil end
    -- Midnight 12.x: C_UnitAuras.GetAuraDataBySpellID was removed.
    -- For the local player, use GetPlayerAuraBySpellID instead (not restricted).
    -- For other units the function no longer exists; return nil (PA anchors handle display).
    if unit == "player" then
        local ok, result = pcall(C_UnitAuras.GetPlayerAuraBySpellID, spellID)
        if ok and result then return result end
        return nil
    end
    if C_UnitAuras.GetAuraDataBySpellID then
        local ok, result = pcall(C_UnitAuras.GetAuraDataBySpellID, unit, spellID, "HARMFUL")
        if ok and result then return result end
    end
    return nil
end

function RaidFrame:GetUnitDebuffs(unit)
    -- Preview mode: return fake auras for every unit
    if self._previewMode and self._previewAuras then
        return self._previewAuras
    end

    local s = RRT.Settings.RaidFrame
    local debuffs = {}

    if s.showAllDebuffs then
        -- Build exclusion set from comma-separated spell IDs
        local excluded = {}
        for id in (s.excludeSpells or ""):gmatch("%d+") do
            excluded[tonumber(id)] = true
        end
        -- Iterate all HARMFUL auras on unit — keep only boss/NPC-applied debuffs
        local i = 1
        while #debuffs < MAX_DBF_SLOTS do
            local ok, aura = pcall(C_UnitAuras.GetAuraDataByIndex, unit, i, "HARMFUL")
            if not ok or not aura then break end
            -- In Midnight 12.x, sourceUnit/spellId/icon are secret values for other players.
            -- Wrap the filter in pcall: if any field access fails, skip this aura silently.
            pcall(function()
                local fromBoss = aura.sourceUnit and not UnitIsPlayer(aura.sourceUnit)
                if fromBoss and not excluded[aura.spellId] then
                    tinsert(debuffs, aura)
                end
            end)
            i = i + 1
            if i > 40 then break end
        end
    else
        -- Use cached flat spell ID list (rebuilt only when profiles change)
        if not _spellIDCache then BuildSpellIDCache(s) end
        for i = 1, #_spellIDCache do
            local spellID = _spellIDCache[i]
            if #debuffs >= MAX_DBF_SLOTS then break end
            local a = safeGetAura(unit, spellID)
            if a then
                a._configSpellID = spellID
                tinsert(debuffs, a)
            elseif unit ~= "player" then
                -- API couldn't read the aura (Midnight restriction) —
                -- fall back to comm data broadcast by that player's client
                local name = GetUnitName(unit, false)
                local remote = name and self._remoteDebuffs and self._remoteDebuffs[name]
                if remote and remote[spellID] then
                    local ok, icon = pcall(C_Spell.GetSpellTexture, spellID)
                    if ok and icon then
                        tinsert(debuffs, {
                            icon           = icon,
                            applications   = 0,
                            _configSpellID = spellID,
                            _fromComm      = true,
                        })
                    end
                end
            end
        end
    end

    return debuffs
end

function RaidFrame:GetData()
    if self._movePreviewMode and self._movePreviewData then
        -- If debuff preview is also active, inject preview auras into every fake row
        local auras = (self._previewMode and self._previewAuras) or nil
        for _, entry in ipairs(self._movePreviewData) do
            entry.debuffs = auras or {}
        end
        return self._movePreviewData
    end

    local result = {}
    local numMembers = GetNumGroupMembers()

    local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }

    local function addUnit(unit)
        if not UnitExists(unit) then return end
        local guid = UnitGUID(unit)
        if not guid then return end
        local name = GetUnitName(unit, false) or "?"
        local _, class = UnitClass(unit)
        local debuffs = self:GetUnitDebuffs(unit)
        local role = UnitGroupRolesAssigned(unit) or "NONE"
        tinsert(result, {
            unit      = unit,
            guid      = guid,
            name      = name,
            class     = class or "WARRIOR",
            role      = role,
            roleOrder = ROLE_ORDER[role] or 4,
            debuffs   = debuffs,
        })
    end

    if numMembers > 0 then
        if IsInRaid() then
            for i = 1, numMembers do addUnit("raid" .. i) end
        else
            addUnit("player")
            for i = 1, numMembers - 1 do addUnit("party" .. i) end
        end
    else
        addUnit("player")
    end

    return result
end

-- Throttled refresh to avoid UNIT_AURA spam
function RaidFrame:RequestRefresh()
    if self._pending then return end
    self._pending = true
    C_Timer.After(0.15, function()
        self._pending = false
        if self.frame and self.frame:IsShown() then
            self.frame:Refresh()
        end
    end)
end

RaidFrame.DBF_SLOT_SZ = 14  -- must match UI.lua DBF_ICON_SZ

-- ── Private Aura anchor management ───────────────────────────────────────
-- Called from Refresh() when the unit→row mapping changes or spell IDs change.
-- For each configured spell that is a Private Aura, attaches an AddPrivateAuraAnchor
-- to the corresponding debuff slot frame so Blizzard renders the icon automatically.
function RaidFrame:RebuildPAAnchors(visible, rows)
    -- RemovePrivateAuraAnchor is blocked during combat lockdown in Midnight 12.x.
    -- Defer the rebuild to PLAYER_REGEN_ENABLED instead.
    if InCombatLockdown() then
        self._pendingPARebuild = true
        return
    end
    self._pendingPARebuild = nil

    -- Remove old anchors
    for _, id in ipairs(self._paAnchors or {}) do
        C_UnitAuras.RemovePrivateAuraAnchor(id)
    end
    self._paAnchors = {}

    local s = RRT.Settings.RaidFrame
    if not s.showDebuffs then return end

    -- Build the spell ID whitelist (if any).
    -- When non-empty, anchors are created by spellID so only those specific
    -- Private Auras are shown. When empty, fall back to positional auraIndex
    -- (show whatever PA Blizzard puts in each slot).
    local paFilter = {}
    for id in (s.paSpellIDs or ""):gmatch("%d+") do
        tinsert(paFilter, tonumber(id))
    end
    local useSpellFilter = #paFilter > 0

    local sz = s.dbfIconSize or self.DBF_SLOT_SZ
    for rowIdx, entry in ipairs(visible) do
        if rowIdx > 40 then break end
        local row = rows[rowIdx]
        if not row or not row:IsShown() then break end

        if useSpellFilter then
            -- Spell-ID mode: one anchor per configured spell, up to MAX_DBF_SLOTS
            for slotIdx = 1, math.min(#paFilter, MAX_DBF_SLOTS) do
                local slot = row.dbfSlots[slotIdx]
                local sf   = slot and slot.sf
                if sf then
                    local ok, id = pcall(C_UnitAuras.AddPrivateAuraAnchor, {
                        unitToken            = entry.unit,
                        spellID              = paFilter[slotIdx],
                        parent               = sf,
                        showCountdownFrame   = true,
                        showCountdownNumbers = true,
                        iconInfo = {
                            iconAnchor = {
                                point         = "CENTER",
                                relativeTo    = sf,
                                relativePoint = "CENTER",
                                offsetX       = 0,
                                offsetY       = 0,
                            },
                            borderScale = -100,
                            iconWidth   = sz,
                            iconHeight  = sz,
                        },
                    })
                    if ok and id then tinsert(self._paAnchors, id) end
                end
            end
        else
            -- Positional mode: show all PAs in slot order (BigWigs style)
            for slotIdx = 1, MAX_DBF_SLOTS do
                local slot = row.dbfSlots[slotIdx]
                local sf   = slot and slot.sf
                if sf then
                    local ok, id = pcall(C_UnitAuras.AddPrivateAuraAnchor, {
                        unitToken            = entry.unit,
                        auraIndex            = slotIdx,
                        parent               = sf,
                        showCountdownFrame   = true,
                        showCountdownNumbers = true,
                        iconInfo = {
                            iconAnchor = {
                                point         = "CENTER",
                                relativeTo    = sf,
                                relativePoint = "CENTER",
                                offsetX       = 0,
                                offsetY       = 0,
                            },
                            borderScale = -100,
                            iconWidth   = sz,
                            iconHeight  = sz,
                        },
                    })
                    if ok and id then tinsert(self._paAnchors, id) end
                end
            end
        end
    end
end

-- ── Raid/Boss profile helpers ─────────────────────────────────────────────
function RaidFrame:GetRaidNames()
    local names = {}
    for name in pairs(RRT.Settings.RaidFrame.debuffProfiles) do
        tinsert(names, name)
    end
    table.sort(names)
    return names
end

function RaidFrame:GetBossNames(raidName)
    local names = {}
    local raid = RRT.Settings.RaidFrame.debuffProfiles[raidName]
    if raid then
        for name in pairs(raid) do tinsert(names, name) end
        table.sort(names)
    end
    return names
end

function RaidFrame:GetBossSpells(raidName, bossName)
    local raid = RRT.Settings.RaidFrame.debuffProfiles[raidName]
    if raid and raid[bossName] then return raid[bossName] end
    return {}
end

function RaidFrame:SaveBossSpells(raidName, bossName, spells)
    local s = RRT.Settings.RaidFrame
    if not s.debuffProfiles[raidName] then s.debuffProfiles[raidName] = {} end
    -- Track insertion order only on first save (new boss)
    if not s.debuffProfiles[raidName][bossName] then
        if not s.raidBossOrder[raidName] then s.raidBossOrder[raidName] = {} end
        tinsert(s.raidBossOrder[raidName], bossName)
    end
    s.debuffProfiles[raidName][bossName] = spells
    _spellIDCache = nil  -- invalidate cache
end

function RaidFrame:DeleteBoss(raidName, bossName)
    local s = RRT.Settings.RaidFrame
    if s.debuffProfiles[raidName] then s.debuffProfiles[raidName][bossName] = nil end
    local order = s.raidBossOrder and s.raidBossOrder[raidName]
    if order then
        for i = #order, 1, -1 do
            if order[i] == bossName then tremove(order, i) end
        end
    end
    _spellIDCache = nil  -- invalidate cache
end

function RaidFrame:DeleteRaid(raidName)
    local s = RRT.Settings.RaidFrame
    s.debuffProfiles[raidName] = nil
    if s.raidBossOrder then s.raidBossOrder[raidName] = nil end
    _spellIDCache = nil  -- invalidate cache
end

-- Real boss debuff spell IDs used for the preview (Nerub-ar Palace / current tier)
local PREVIEW_SPELL_IDS = {
    443612,  -- Sikran: Phase Lunge
    434793,  -- Ulgrax: Digestive Acid
    442432,  -- Broodtwister Ovi'nax: Volatile Infection
    440247,  -- The Bloodbound Horror: Blood Pool
}

function RaidFrame:TogglePreview()
    self._previewMode = not self._previewMode

    if self._previewMode then
        -- Collect spell IDs: prefer active raid profile, fall back to hardcoded list
        local s = RRT.Settings.RaidFrame
        local spellSource = PREVIEW_SPELL_IDS
        if s.activeRaid and s.activeRaid ~= "" and s.debuffProfiles[s.activeRaid] then
            local collected = {}
            local seen = {}
            for _, spells in pairs(s.debuffProfiles[s.activeRaid]) do
                for _, id in ipairs(spells) do
                    if id and id > 0 and not seen[id] then
                        seen[id] = true
                        tinsert(collected, id)
                        if #collected >= MAX_DBF_SLOTS then break end
                    end
                end
                if #collected >= MAX_DBF_SLOTS then break end
            end
            if #collected > 0 then spellSource = collected end
        end

        -- Build fake aura objects from collected spell IDs
        self._previewAuras = {}
        for _, spellID in ipairs(spellSource) do
            local ok, icon = pcall(C_Spell.GetSpellTexture, spellID)
            if ok and icon then
                tinsert(self._previewAuras, {
                    icon           = icon,
                    applications   = 0,
                    _configSpellID = spellID,
                })
            end
            if #self._previewAuras >= MAX_DBF_SLOTS then break end
        end
        -- Ensure debuffs are visible for the preview
        self._previewShowDebuffs = RRT.Settings.RaidFrame.showDebuffs
        RRT.Settings.RaidFrame.showDebuffs = true
    else
        self._previewAuras = nil
        -- Restore showDebuffs
        if self._previewShowDebuffs ~= nil then
            RRT.Settings.RaidFrame.showDebuffs = self._previewShowDebuffs
            self._previewShowDebuffs = nil
        end
    end

    if not self.frame then return end
    if self._previewMode and not self.frame:IsShown() then
        self.frame:Show()
    end
    self.frame:Refresh()
end

function RaidFrame:Toggle()
    if not self.frame then return end
    if self.frame:IsShown() then
        self.frame:Hide()
    else
        self._needsPARebuild = true
        self.frame:Show()
        self.frame:Refresh()
    end
end

-- 10 fake players used by ToggleMovePreview
local MOVE_PREVIEW_PLAYERS = {
    { name = "Tankàrius",   class = "WARRIOR",     role = "TANK"    },
    { name = "Lumnara",     class = "PALADIN",      role = "HEALER"  },
    { name = "Drakonis",    class = "DEATHKNIGHT",  role = "TANK"    },
    { name = "Sylvina",     class = "DRUID",        role = "HEALER"  },
    { name = "Xelthar",     class = "MAGE",         role = "DAMAGER" },
    { name = "Rhovax",      class = "HUNTER",       role = "DAMAGER" },
    { name = "Zephiria",    class = "ROGUE",        role = "DAMAGER" },
    { name = "Mordecai",    class = "WARLOCK",      role = "DAMAGER" },
    { name = "Elowen",      class = "PRIEST",       role = "HEALER"  },
    { name = "Grombash",    class = "SHAMAN",       role = "DAMAGER" },
}

function RaidFrame:ToggleMovePreview()
    if not self.frame then return end

    if self._movePreviewMode then
        -- Turn off
        self._movePreviewMode = false
        self._movePreviewData = nil
        RRT.Settings.RaidFrame.locked  = self._moveSavedLocked
        RRT.Settings.RaidFrame.showAll = self._moveSavedShowAll
        self._moveSavedLocked  = nil
        self._moveSavedShowAll = nil
        if not self._moveWasShown then
            self.frame:Hide()
        else
            self.frame:Refresh()
        end
        return
    end

    -- Turn on
    self._movePreviewMode  = true
    self._moveWasShown     = self.frame:IsShown()
    self._moveSavedLocked  = RRT.Settings.RaidFrame.locked
    self._moveSavedShowAll = RRT.Settings.RaidFrame.showAll

    -- Build 10 fake entries with no debuffs
    local ROLE_ORDER = { TANK = 1, HEALER = 2, DAMAGER = 3, NONE = 4 }
    self._movePreviewData = {}
    for i, p in ipairs(MOVE_PREVIEW_PLAYERS) do
        tinsert(self._movePreviewData, {
            unit      = "player",
            guid      = "preview" .. i,
            name      = p.name,
            class     = p.class,
            role      = p.role,
            roleOrder = ROLE_ORDER[p.role] or 4,
            debuffs   = {},
        })
    end

    RRT.Settings.RaidFrame.locked  = false
    RRT.Settings.RaidFrame.showAll = true
    self.frame:Show()
    self.frame:Refresh()
end
