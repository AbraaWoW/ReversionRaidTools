local _, RRT_NS = ...
local LibTranslit = LibStub("LibTranslit-1.0", true)

-- ─────────────────────────────────────────────────────────────────────────────
-- Nicknames — in-memory lookup tables (rebuilt from RRT.NickNames on init)
-- ─────────────────────────────────────────────────────────────────────────────

local fullCharList   = {}   -- "Name-Realm" -> nickname
local fullNameList   = {}   -- "Name"       -> nickname
local sortedCharList = {}   -- nickname     -> { "Name-Realm" -> true }
local CharList       = {}   -- nickname     -> { "Name"       -> true }
local Grid2Status           -- set in InitNickNames when Grid2 is available

-- ─────────────────────────────────────────────────────────────────────────────
-- RRTAPI query functions (override stubs in Functions.lua)
-- ─────────────────────────────────────────────────────────────────────────────

function RRTAPI:GetCharacters(str)
    if not str then return end
    if not sortedCharList[str] then
        return CharList[str] and CopyTable(CharList[str])
    else
        return sortedCharList[str] and CopyTable(sortedCharList[str])
    end
end

function RRTAPI:GetAllCharacters()
    return CopyTable(fullCharList)
end

function RRTAPI:GetName(str, AddonName)
    if (not str) or issecretvalue(str) then return str end
    local unitname = UnitExists(str) and UnitName(str) or str
    if issecretvalue(unitname) then return unitname end
    -- If GlobalNickNames is off, or this addon's integration is disabled, just return (with optional translit)
    if ((not RRT.Settings["GlobalNickNames"]) or (AddonName and not RRT.Settings[AddonName])) and AddonName ~= "Note" then
        if RRT.Settings["Translit"] and LibTranslit then
            unitname = LibTranslit:Transliterate(unitname)
        end
        return unitname
    end
    if UnitExists(str) then
        local name, realm = UnitFullName(str)
        if not realm then realm = GetNormalizedRealmName() end
        if issecretvalue(name) or issecretvalue(realm) then return name end
        local nickname = name and realm and fullCharList[name.."-"..realm]
        if nickname and RRT.Settings["Translit"] and LibTranslit then
            nickname = LibTranslit:Transliterate(nickname)
        end
        if RRT.Settings["Translit"] and LibTranslit and not nickname then
            name = issecretvalue(name) and name or LibTranslit:Transliterate(name)
        end
        return nickname or name
    else
        local nickname = fullCharList[str] or fullNameList[str]
        if nickname and RRT.Settings["Translit"] and LibTranslit then
            nickname = LibTranslit:Transliterate(nickname)
        end
        return nickname or unitname
    end
end

function RRTAPI:GetChar(name, nick, AddonName)
    if UnitExists(name) and UnitIsConnected(name) then return name end
    name = nick and RRTAPI:GetName(name, AddonName) or name
    if UnitExists(name) and UnitIsConnected(name) then return name end
    local chars = RRTAPI:GetCharacters(name)
    if chars then
        local newname, newrealm
        for k, _ in pairs(chars) do
            local n, realm = strsplit("-", k)
            local i = UnitInRaid(k)
            if UnitIsVisible(n) or (i and select(3, GetRaidRosterInfo(i)) <= 4) then
                newname, newrealm = n, realm
                if UnitIsUnit(n, "player") then return n, realm end
            end
        end
        if newname and newrealm then return newname, newrealm end
    end
    return name
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Own nickname management
-- ─────────────────────────────────────────────────────────────────────────────

function RRT_NS:NickNameUpdated(nickname)
    local name, realm = UnitFullName("player")
    if not realm then realm = GetNormalizedRealmName() end
    local oldnick = RRT.NickNames[name.."-"..realm]
    if (not oldnick) or oldnick ~= nickname then
        self:SendNickName("Any")
        self:NewNickName("player", nickname, name, realm)
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Unit frame integration callbacks
-- ─────────────────────────────────────────────────────────────────────────────

function RRT_NS:BlizzardNickNameUpdated()
    C_Timer.After(0.1, function()
        if C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") and RRT.Settings["Blizzard"] and not self.BlizzardNickNamesHook then
            self.BlizzardNickNamesHook = true
            hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
                if frame:IsForbidden() or not frame.unit then return end
                frame.name:SetText(RRTAPI:GetName(frame.unit, "Blizzard"))
            end)
        end
        if UnitInRaid("player") then
            for group = 1, 8 do
                for member = 1, 5 do
                    local frame = _G["CompactRaidGroup"..group.."Member"..member]
                    if frame and not frame:IsForbidden() and frame.unit then
                        frame.name:SetText(RRTAPI:GetName(frame.unit, "Blizzard"))
                    end
                end
            end
        else
            for member = 1, 5 do
                local frame = _G["CompactPartyFrameMember"..member]
                if frame and not frame:IsForbidden() and frame.unit then
                    frame.name:SetText(RRTAPI:GetName(frame.unit, "Blizzard"))
                end
            end
        end
    end)
end

function RRT_NS:WipeCellDB()
    if CellDB then
        for name, nickname in pairs(RRT.NickNames) do
            local i = tIndexOf(CellDB.nicknames.list, name..":"..nickname)
            if i then
                local charname = strsplit("-", name)
                Cell.Fire("UpdateNicknames", "list-update", name, charname)
                table.remove(CellDB.nicknames.list, i)
            end
        end
    end
end

function RRT_NS:CellInsertName(name, realm, nickname, ingroup)
    if tInsertUnique(CellDB.nicknames.list, name.."-"..realm..":"..nickname) and ingroup then
        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname)
    end
end

function RRT_NS:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname)
    if CellDB then
        if RRT.Settings["Cell"] and RRT.Settings["GlobalNickNames"] then
            if all then
                for u in self:IterateGroupMembers() do
                    local n, r = UnitFullName(u)
                    if not r then r = GetNormalizedRealmName() end
                    if RRT.NickNames[n.."-"..r] then
                        local nick = RRT.NickNames[n.."-"..r]
                        local i = tIndexOf(CellDB.nicknames.list, n.."-"..r..":"..nick)
                        if i then
                            CellDB.nicknames.list[i] = n.."-"..r..":"..nick
                            Cell.Fire("UpdateNicknames", "list-update", n.."-"..r, nick)
                        else
                            self:CellInsertName(n, r, nick, true)
                        end
                    end
                end
                return
            elseif nickname == "" then
                if oldnick then
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        table.remove(CellDB.nicknames.list, i)
                        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, name)
                    end
                end
            elseif unit then
                local ingroup = false
                for u in self:IterateGroupMembers() do
                    if UnitExists(unit) and UnitIsUnit(u, unit) then ingroup = true; break end
                end
                if oldnick then
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        CellDB.nicknames.list[i] = name.."-"..realm..":"..nickname
                        if ingroup then Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname) end
                    else
                        self:CellInsertName(name, realm, nickname, ingroup)
                    end
                else
                    self:CellInsertName(name, realm, nickname, ingroup)
                end
            end
        else
            self:WipeCellDB()
        end
    end
end

function RRT_NS:ElvUINickNameUpdated()
    if ElvUF and ElvUF.Tags then
        ElvUF.Tags:RefreshMethods("RRTNickName")
        for i = 1, 12 do
            ElvUF.Tags:RefreshMethods("RRTNickName:"..i)
        end
    end
end

function RRT_NS:UnhaltedNickNameUpdated()
    if UUFG and UUFG.UpdateAllTags then UUFG:UpdateAllTags() end
end

function RRT_NS:VuhDoNickNameUpdated()
    if C_AddOns.IsAddOnLoaded("VuhDo") and RRT.Settings["VuhDo"] and not self.VuhDoNickNamesHook then
        self.VuhDoNickNamesHook = true
        local hookedFrames = {}
        hooksecurefunc('VUHDO_getBarText', function(aBar)
            local bar = aBar:GetName()..'TxPnlUnN'
            if bar and not hookedFrames[bar] then
                hookedFrames[bar] = true
                hooksecurefunc(_G[bar], 'SetText', function(self2, txt)
                    if txt then
                        local n = txt:match('%w+$')
                        if n then
                            self2:SetFormattedText('%s%s', txt:gsub(n, ''), RRTAPI:GetName(n, "VuhDo") or "")
                        end
                    end
                end)
            end
        end)
    end
end

function RRT_NS:DandersFramesNickNameUpdated(all, unit)
    if DandersFrames then
        if all then
            DandersFrames:IterateCompactFrames(function(frame)
                DandersFrames:UpdateName(frame)
            end)
        elseif unit then
            local frame = DandersFrames:GetFrameForUnit(unit)
            if frame then DandersFrames:UpdateName(frame) end
        end
        if RRT.Settings["DandersFrames"] then
            function DandersFrames:GetUnitName(unit)
                local name = UnitName(unit)
                return name and RRTAPI:GetName(name, "DandersFrames") or name
            end
        end
    end
end

function RRT_NS:Grid2NickNameUpdated(all, unit)
    if Grid2Status then
        if all then
            for u in self:IterateGroupMembers() do
                Grid2Status:UpdateIndicators(u)
            end
        else
            for u in self:IterateGroupMembers() do
                if unit then
                    if UnitExists(unit) and UnitIsUnit(u, unit) then
                        Grid2Status:UpdateIndicators(u)
                        break
                    end
                else
                    Grid2Status:UpdateIndicators(u)
                end
            end
        end
    end
end

function RRT_NS:UpdateNickNameDisplay(all, unit, name, realm, oldnick, nickname)
    self:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname)
    if nickname == "" and name and realm and RRT.NickNames[name.."-"..realm] then
        RRT.NickNames[name.."-"..realm] = nil
        fullCharList[name.."-"..realm]  = nil
        fullNameList[name]               = nil
        if sortedCharList[nickname] then sortedCharList[nickname][name.."-"..realm] = nil end
        if CharList[nickname] then CharList[nickname][name] = nil end
    end
    self:Grid2NickNameUpdated(all, unit)
    self:BlizzardNickNameUpdated()
    self:ElvUINickNameUpdated()
    self:UnhaltedNickNameUpdated()
    self:VuhDoNickNameUpdated()
    self:DandersFramesNickNameUpdated(all, unit)
end

function RRT_NS:GlobalNickNameUpdate()
    if RRT.Settings["GlobalNickNames"] then
        for fullname, nickname in pairs(RRT.NickNames) do
            local name = strsplit("-", fullname)
            fullCharList[fullname] = nickname
            fullNameList[name]     = nickname
            if not sortedCharList[nickname] then sortedCharList[nickname] = {} end
            sortedCharList[nickname][fullname] = true
            if not CharList[nickname] then CharList[nickname] = {} end
            CharList[nickname][name] = true
        end
    end
    self:UpdateNickNameDisplay(true)
end

-- ─────────────────────────────────────────────────────────────────────────────
-- CRUD
-- ─────────────────────────────────────────────────────────────────────────────

function RRT_NS:WipeNickNames()
    self:WipeCellDB()
    RRT.NickNames  = {}
    fullCharList   = {}
    fullNameList   = {}
    sortedCharList = {}
    CharList       = {}
    self:UpdateNickNameDisplay(true)
end

function RRT_NS:NewNickName(unit, nickname, name, realm, channel)
    if self:Restricted() then return end
    if unit ~= "player" and RRT.Settings["AcceptNickNames"] ~= 3 then
        if channel == "GUILD" and RRT.Settings["AcceptNickNames"] ~= 2 then return end
        if channel == "RAID"  and RRT.Settings["AcceptNickNames"] ~= 1 then return end
    end
    if not nickname or not name or not realm then return end
    local oldnick = RRT.NickNames[name.."-"..realm]
    if oldnick and oldnick == nickname then return end
    if nickname == "" then
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
        return
    end
    nickname = self:Utf8Sub(nickname, 1, 12)
    RRT.NickNames[name.."-"..realm]    = nickname
    fullCharList[name.."-"..realm]     = nickname
    fullNameList[name]                  = nickname
    if not sortedCharList[nickname] then sortedCharList[nickname] = {} end
    sortedCharList[nickname][name.."-"..realm] = true
    if not CharList[nickname] then CharList[nickname] = {} end
    CharList[nickname][name] = true
    if RRT.Settings["GlobalNickNames"] then
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
    end
end

function RRT_NS:AddNickName(name, realm, nickname)
    if name and realm and nickname ~= nil then
        local unit
        if UnitExists(name) then
            for u in self:IterateGroupMembers() do
                if UnitIsUnit(u, name) then unit = u; break end
            end
        end
        self:NewNickName(unit, nickname, name, realm)
    end
end

function RRT_NS:ImportNickNames(str)
    if str and str ~= "" then
        str = str:gsub("%s+", "")
        for _, s in pairs({strsplit(";", str)}) do
            if s ~= "" then
                local namewithrealm, nickname = strsplit(":", s)
                if namewithrealm and nickname then
                    local name, realm = strsplit("-", namewithrealm)
                    if name and realm then
                        RRT.NickNames[name.."-"..realm] = nickname
                    end
                end
            end
        end
        self:GlobalNickNameUpdate()
    end
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Sync
-- ─────────────────────────────────────────────────────────────────────────────

function RRT_NS:SendNickName(channel, requestback)
    requestback = requestback or false
    local now = GetTime()
    if (self.LastNickNameSend and self.LastNickNameSend > now - 0.25) or RRT.Settings["ShareNickNames"] == 4 then return end
    if requestback and (self.LastNickNameSend and self.LastNickNameSend > now - 2) then return end
    self.LastNickNameSend = now
    local nickname = RRT.Settings["MyNickName"]
    if (not nickname) or self:Restricted() then return end
    local name, realm = UnitFullName("player")
    if not realm then realm = GetNormalizedRealmName() end
    if UnitInRaid("player") and (RRT.Settings["ShareNickNames"] == 1 or RRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "RAID") then
        self:Broadcast("RRT_NICKNAMES_COMMS", "RAID", nickname, name, realm, requestback, "RAID")
    end
    if (RRT.Settings["ShareNickNames"] == 2 or RRT.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "GUILD") then
        self:Broadcast("RRT_NICKNAMES_COMMS", "GUILD", nickname, name, realm, requestback, "GUILD")
    end
end

function RRT_NS:SyncNickNames()
    local now = GetTime()
    if (self.LastNickNameSync and self.LastNickNameSync > now - 4) or RRT.Settings["NickNamesSyncSend"] == 3 then return end
    self.LastNickNameSync = now
    local channel = RRT.Settings["NickNamesSyncSend"] == 1 and "RAID" or "GUILD"
    self:Broadcast("RRT_NICKNAMES_SYNC", channel, RRT.NickNames, channel)
end

function RRT_NS:SyncNickNamesAccept(nicknametable)
    for name, nickname in pairs(nicknametable) do
        RRT.NickNames[name] = nickname
    end
    self:GlobalNickNameUpdate()
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Init (called from EventHandler ADDON_LOADED)
-- ─────────────────────────────────────────────────────────────────────────────

function RRT_NS:InitNickNames()
    -- Rebuild lookup tables from SavedVariables
    for fullname, nickname in pairs(RRT.NickNames) do
        local name = strsplit("-", fullname)
        fullCharList[fullname] = nickname
        fullNameList[name]     = nickname
        if not sortedCharList[nickname] then sortedCharList[nickname] = {} end
        sortedCharList[nickname][fullname] = true
        if not CharList[nickname] then CharList[nickname] = {} end
        CharList[nickname][name] = true
    end

    if RRT.Settings["GlobalNickNames"] and RRT.Settings["Blizzard"] then
        self:BlizzardNickNameUpdated()
    end

    -- Grid2 status module
    if Grid2 then
        Grid2Status = Grid2.statusPrototype:new("RRTNickName")
        Grid2Status.IsActive = Grid2.statusLibrary.IsActive
        function Grid2Status:UNIT_NAME_UPDATE(_, unit) self:UpdateIndicators(unit) end
        function Grid2Status:OnEnable()  self:RegisterEvent("UNIT_NAME_UPDATE") end
        function Grid2Status:OnDisable() self:UnregisterEvent("UNIT_NAME_UPDATE") end
        function Grid2Status:GetText(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "Grid2") or name
        end
        local function CreateGrid2(baseKey, dbx)
            Grid2:RegisterStatus(Grid2Status, {"text"}, baseKey, dbx)
            return Grid2Status
        end
        Grid2.setupFunc["RRTNickName"] = CreateGrid2
        Grid2:DbSetStatusDefaultValue("RRTNickName", {type = "RRTNickName"})
    end

    -- ElvUI tags
    if ElvUF and ElvUF.Tags then
        ElvUF.Tags.Events['RRTNickName'] = 'UNIT_NAME_UPDATE'
        ElvUF.Tags.Methods['RRTNickName'] = function(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "ElvUI") or name
        end
        for i = 1, 12 do
            ElvUF.Tags.Events['RRTNickName:'..i]  = 'UNIT_NAME_UPDATE'
            ElvUF.Tags.Methods['RRTNickName:'..i] = function(unit)
                local name = UnitName(unit)
                name = name and RRTAPI:GetName(name, "ElvUI") or name
                return RRT_NS:Utf8Sub(name, 1, i)
            end
        end
    end

    -- Cell
    if CellDB and RRT.Settings["Cell"] then
        for name, nickname in pairs(RRT.NickNames) do
            if tInsertUnique(CellDB.nicknames.list, name..":"..nickname) then
                Cell.Fire("UpdateNicknames", "list-update", name, nickname)
            end
        end
    end

    -- DandersFrames
    if DandersFrames and RRT.Settings["DandersFrames"] then
        function DandersFrames:GetUnitName(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "DandersFrames") or name
        end
    end

    -- Unhalted Unit Frames
    C_AddOns.LoadAddOn("UnhaltedUnitFrames")
    if UUFG then
        UUFG:AddTag("RRTNickName", "UNIT_NAME_UPDATE", function(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "Unhalted") or name
        end, "Name", "[RRT] NickName")
    end

    -- VuhDo
    C_AddOns.LoadAddOn("VuhDo")
    self:VuhDoNickNameUpdated()
end
