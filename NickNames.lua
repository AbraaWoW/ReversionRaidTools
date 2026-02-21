local _, RRT = ... -- Internal namespace
local Grid2Status
local fullCharList = {}
local fullNameList = {}
local sortedCharList = {}
local CharList = {}
local LibTranslit = LibStub("LibTranslit-1.0")

function RRTAPI:GetCharacters(str) -- Returns table of all Characters from Nickname or Character Name
    if not str then
        error("RRTAPI:GetCharacters(str), str is nil")
        return
    end
    if not sortedCharList[str] then
        return CharList[str] and CopyTable(CharList[str])
    else
        return sortedCharList[str] and CopyTable(sortedCharList[str])
    end
end

function RRTAPI:GetAllCharacters()
    return CopyTable(fullCharList)
end

function RRTAPI:GetName(str, AddonName) -- Returns Nickname
    if (not str) or issecretvalue(str) then return str end
    local unitname = UnitExists(str) and UnitName(str) or str
    if issecretvalue(unitname) then return unitname end
    -- check if setting for the requesting addon is enabled, if not return the original name.
    -- if no AddonName is given we assume it's from an old WeakAura as they never specified
    if ((not RRTDB.Settings["GlobalNickNames"]) or (AddonName and not RRTDB.Settings[AddonName])) and AddonName ~= "Note" then
        if RRTDB.Settings["Translit"] then
            unitname = LibTranslit:Transliterate(unitname)
        end
        return unitname
    end

    if not str then
        error("RRTAPI:GetName(str), str is nil")
        return
    end
    if UnitExists(str) then
        local name, realm = UnitFullName(str)
        if not realm then
            realm = GetNormalizedRealmName()
        end
        if (issecretvalue(name) or issecretvalue(realm)) then return name end
        local nickname = name and realm and fullCharList[name.."-"..realm]
        if nickname and RRTDB.Settings["Translit"] then
            nickname = LibTranslit:Transliterate(nickname)
        end
        if RRTDB.Settings["Translit"] and not nickname then
            name = issecretvalue(name) and name or LibTranslit:Transliterate(name)
        end
        return nickname or name
    else
        local nickname = fullCharList[str]
        if not nickname then
            nickname = fullNameList[str]
        end
        if nickname and RRTDB.Settings["Translit"] then
            nickname = LibTranslit:Transliterate(nickname)
        end
        return nickname or unitname
    end
end

function RRTAPI:GetChar(name, nick, AddonName) -- Returns Char in Raid from Nickname or Character Name with nick = true
    if UnitExists(name) and UnitIsConnected(name) then return name end
    name = nick and RRTAPI:GetName(name, AddonName) or name
    if UnitExists(name) and UnitIsConnected(name) then return name end
    local chars = RRTAPI:GetCharacters(name)
    local newname, newrealm = nil
    if chars then
        for k, _ in pairs(chars) do
            local name, realm = strsplit("-", k)
            local i = UnitInRaid(k)
            if UnitIsVisible(name) or (i and select(3, GetRaidRosterInfo(i)) <= 4)  then
                newname, newrealm = name, realm
                if UnitIsUnit(name, "player") then
                    return name, realm
                end
            end
        end
        if newname and newrealm then
            return newname, newrealm
        end
    end
    return name -- Return input if nothing was found
end

-- Own NickName Change
function RRT:NickNameUpdated(nickname)
    local name, realm = UnitFullName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    local oldnick = RRTDB.NickNames[name .. "-" .. realm]
    if (not oldnick) or oldnick ~= nickname then
        self:SendNickName("Any")
        self:NewNickName("player", nickname, name, realm)
    end
end

-- Grid2 Option Change
function RRT:Grid2NickNameUpdated(all, unit)
    if Grid2 then
        if all then
            for u in self:IterateGroupMembers() do
                Grid2Status:UpdateIndicators(u)
            end
        else
            for u in self:IterateGroupMembers() do -- if unit is in group refresh grid2 display, could be a guild message instead
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

function RRT:DandersFramesNickNameUpdated(all, unit)
    if DandersFrames then
        if all then
            DandersFrames:IterateCompactFrames(function(frame)
                DandersFrames:UpdateNameText(frame)
            end)
        elseif unit then
            local frame = DandersFrames:GetFrameForUnit(unit)
            if frame then
                DandersFrames:UpdateNameText(frame)
            end
        end
    end
end

-- Wipe NickName Database
function RRT:WipeNickNames()
    self:WipeCellDB()
    RRTDB.NickNames = {}
    fullCharList = {}
    fullNameList = {}
    sortedCharList = {}
    CharList = {}
    -- all addons that need a display update, which is basically all but
    self:UpdateNickNameDisplay(true)
end

function RRT:WipeCellDB()
    if CellDB then
        for name, nickname in pairs(RRTDB.NickNames) do -- wipe cell database
            local i = tIndexOf(CellDB.nicknames.list, name..":"..nickname)
            if i then
                local charname = strsplit("-", name)
                Cell.Fire("UpdateNicknames", "list-update", name, charname)
                table.remove(CellDB.nicknames.list, i)
            end
        end
    end
end

function RRT:VuhDoNickNameUpdated()
    if C_AddOns.IsAddOnLoaded("VuhDo") and RRTDB.Settings["VuhDo"] and not self.VuhDoNickNamesHook then
        self.VuhDoNickNamesHook = true
        local hookedFrames = {}
        hooksecurefunc('VUHDO_getBarText', function(aBar)
            local bar = aBar:GetName() .. 'TxPnlUnN'
            if bar then
                if not hookedFrames[bar] then
                    hookedFrames[bar] = true
                    hooksecurefunc(_G[bar], 'SetText', function(self,txt)
                        if txt then
                            local name = txt:match('%w+$')
                            if name then
                                local preStr = txt:gsub(name, '')
                                self:SetFormattedText('%s%s',preStr,RRTAPI:GetName(name, "VuhDo") or "")
                            end
                        end
                    end)
                end
            end
        end)
    end

end

function RRT:BlizzardNickNameUpdated()
    C_Timer.After(0.1, function() -- delay everything to always do it after other reskin addons
        if C_AddOns.IsAddOnLoaded("Blizzard_CompactRaidFrames") and RRTDB.Settings["Blizzard"] and not self.BlizzardNickNamesHook then
            self.BlizzardNickNamesHook = true
            hooksecurefunc("CompactUnitFrame_UpdateName", function(frame)
                if frame:IsForbidden() or not frame.unit then
                    return
                end
                frame.name:SetText(RRTAPI:GetName(frame.unit, "Blizzard"))
            end)
        end
        local inRaid = UnitInRaid("player")
        if inRaid then
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

-- Cell Option Change
function RRT:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname)
    if CellDB then
        if RRTDB.Settings["Cell"] and RRTDB.Settings["GlobalNickNames"] then
            if all then -- update all units
                for u in self:IterateGroupMembers() do
                    local name, realm = UnitFullName(u)
                    if not realm then
                        realm = GetNormalizedRealmName()
                    end
                    if RRTDB.NickNames[name.."-"..realm] then
                        local nick = RRTDB.NickNames[name.."-"..realm]
                        local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..nick)
                        if i then -- update nickame if it already exists
                            CellDB.nicknames.list[i] = name.."-"..realm..":"..nick
                            Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nick)
                        else -- insert if it doesn't exist yet
                            self:CellInsertName(name, realm, nick, true)
                        end
                    end
                end
                return
            elseif nickname == "" then -- newnick is an empty string so remove any old nick we still have
                if oldnick then -- if there is an oldnick, remove it
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        table.remove(CellDB.nicknames.list, i)
                        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, name)
                    end
                end
            elseif unit then -- if the function was called for a sepcific unit
                local ingroup = false
                for u in self:IterateGroupMembers() do -- if unit is in group refresh cell display, could be a guild message instead
                    if UnitExists(unit) and UnitIsUnit(u, unit) then
                        ingroup = true
                        break
                    end
                end
                if oldnick then -- check if oldnick exists in database already and overwrite it if it does, otherwise insert
                    local i = tIndexOf(CellDB.nicknames.list, name.."-"..realm..":"..oldnick)
                    if i then
                        CellDB.nicknames.list[i] = name.."-"..realm..":"..nickname
                        if ingroup then
                            Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname)
                        end
                    else
                        self:CellInsertName(name, realm, nickname, ingroup)
                    end
                else -- if no old nickname, just insert the new one
                    self:CellInsertName(name, realm, nickname, ingroup)
                end
            end
        else
            self:WipeCellDB()
        end
    end
end

function RRT:CellInsertName(name, realm, nickname, ingroup)
    if tInsertUnique(CellDB.nicknames.list, name.."-"..realm..":"..nickname) and ingroup then
        Cell.Fire("UpdateNicknames", "list-update", name.."-"..realm, nickname)
    end
end



-- ElvUI Option Change
function RRT:ElvUINickNameUpdated()
    if not (RRTDB and RRTDB.Settings and RRTDB.Settings["ElvUI"]) then
        return
    end
    if not (ElvUF and ElvUF.Tags and ElvUF.Tags.RefreshMethods) then
        return
    end

    -- Avoid racing ElvUI/oUF frame construction on login.
    -- Repeated nickname updates are coalesced into one deferred refresh.
    if self._elvNickRefreshQueued then
        return
    end
    self._elvNickRefreshQueued = true

    C_Timer.After(1.5, function()
        self._elvNickRefreshQueued = nil
        if not (ElvUF and ElvUF.Tags and ElvUF.Tags.RefreshMethods) then
            return
        end

        local ok = pcall(function()
            ElvUF.Tags:RefreshMethods("NSNickName")
            for i=1, 12 do
                ElvUF.Tags:RefreshMethods("NSNickName:"..i)
            end
        end)

        if not ok and RRTDB and RRTDB.Settings and RRTDB.Settings["DebugLogs"] then
            print("|cFF00FFFFRRT|r ElvUI nickname refresh deferred due to ElvUI frame init state.")
        end
    end)
end

-- UUFG Option Change
function RRT:UnhaltedNickNameUpdated()
    if UUFG and UUFG.UpdateAllTags then
        UUFG:UpdateAllTags()
    end
end

-- Global NickName Option Change
function RRT:GlobalNickNameUpdate()
    if RRTDB.Settings["GlobalNickNames"] then
        for fullname, nickname in pairs(RRTDB.NickNames) do
            local name, realm = strsplit("-", fullname)
            fullCharList[fullname] = nickname
            fullNameList[name] = nickname
            if not sortedCharList[nickname] then
                sortedCharList[nickname] = {}
            end
            sortedCharList[nickname][fullname] = true
            if not CharList[nickname] then
                CharList[nickname] = {}
            end
            CharList[nickname][name] = true
        end
    end

    -- instant display update for all addons
    self:UpdateNickNameDisplay(true)
end



function RRT:UpdateNickNameDisplay(all, unit, name, realm, oldnick, nickname)
    self:CellNickNameUpdated(all, unit, name, realm, oldnick, nickname) -- always have to do cell before doing any changes to the nickname database
    if nickname == ""  and RRTDB.NickNames[name.."-"..realm] then
        RRTDB.NickNames[name.."-"..realm] = nil
        fullCharList[name.."-"..realm] = nil
        fullNameList[name] = nil
        sortedCharList[nickname] = nil
        CharList[nickname] = nil
    end
    self:Grid2NickNameUpdated(unit)
    if RRTDB.Settings["ElvUI"] then
        self:ElvUINickNameUpdated()
    end
    self:UnhaltedNickNameUpdated()
    self:BlizzardNickNameUpdated()
    self:DandersFramesNickNameUpdated(all, unit)
    self:VuhDoNickNameUpdated()
    self.Callbacks:Fire("RRT_NICKNAME_UPDATED", all, unit, name, realm, oldnick, nickname)
end

function RRT:InitNickNames()

    for fullname, nickname in pairs(RRTDB.NickNames) do
        local name, realm = strsplit("-", fullname)
        fullCharList[fullname] = nickname
        fullNameList[name] = nickname
        if not sortedCharList[nickname] then
            sortedCharList[nickname] = {}
        end
        sortedCharList[nickname][fullname] = true
        if not CharList[nickname] then
            CharList[nickname] = {}
        end
        CharList[nickname][name] = true
    end

    if RRTDB.Settings["GlobalNickNames"] and RRTDB.Settings["Blizzard"] then
    	self:BlizzardNickNameUpdated()
    end

    if Grid2 then
        Grid2Status = Grid2.statusPrototype:new("NSNickName")

        Grid2Status.IsActive = Grid2.statusLibrary.IsActive

        function Grid2Status:UNIT_NAME_UPDATE(_, unit)
            self:UpdateIndicators(unit)
        end

        function Grid2Status:OnEnable()
            self:RegisterEvent("UNIT_NAME_UPDATE")
        end

        function Grid2Status:OnDisable()
            self:UnregisterEvent("UNIT_NAME_UPDATE")
        end

        function Grid2Status:GetText(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "Grid2") or name
        end

        local function Create(baseKey, dbx)
            Grid2:RegisterStatus(Grid2Status, {"text"}, baseKey, dbx)
            return Grid2Status
        end

        Grid2.setupFunc["NSNickName"] = Create

        Grid2:DbSetStatusDefaultValue( "NSNickName", {type = "NSNickName"})
    end

    if RRTDB.Settings["ElvUI"] and ElvUF and ElvUF.Tags then
        ElvUF.Tags.Events['NSNickName'] = 'UNIT_NAME_UPDATE'
        ElvUF.Tags.Methods['NSNickName'] = function(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "ElvUI") or name
        end
        for i=1, 12 do
            ElvUF.Tags.Events['NSNickName:'..i] = 'UNIT_NAME_UPDATE'
            ElvUF.Tags.Methods['NSNickName:'..i] = function(unit)
                local name = UnitName(unit)
                name = name and RRTAPI:GetName(name, "ElvUI") or name
                return RRT:Utf8Sub(name, 1, i)
            end
        end
    end

    if CellDB and RRTDB.Settings["Cell"] then
        for name, nickname in pairs(RRTDB.NickNames) do
            if tInsertUnique(CellDB.nicknames.list, name..":"..nickname) then
                Cell.Fire("UpdateNicknames", "list-update", name, nickname)
            end
        end
    end

    if DandersFrames then
        function DandersFrames:GetUnitName(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "DandersFrames") or name
        end
    end

    C_AddOns.LoadAddOn("UnhaltedUnitFrames")
    if UUFG then
        UUFG:AddTag("NSNickName", "UNIT_NAME_UPDATE", function(unit)
            local name = UnitName(unit)
            return name and RRTAPI:GetName(name, "Unhalted") or name
        end, "Name", "[RRTDB] NickName")
    end

    C_AddOns.LoadAddOn("VuhDo")
    self:VuhDoNickNameUpdated()
end

function RRT:SendNickName(channel, requestback)
    requestback = requestback or false
    local now = GetTime()
    if (self.LastNickNameSend and self.LastNickNameSend > now-0.25) or RRTDB.Settings["ShareNickNames"] == 4 then return end -- don't let user spam nicknames
    if requestback and (self.LastNickNameSend and self.LastNickNameSend > now-2) or RRTDB.Settings["ShareNickNames"] == 4 then return end -- don't overspam on forming raid
    self.LastNickNameSend = now
    local nickname = RRTDB.Settings["MyNickName"]
    if (not nickname) or self:Restricted() then return end
    local name, realm = UnitFullName("player")
    if not realm then
        realm = GetNormalizedRealmName()
    end
    if nickname then
        if UnitInRaid("player") and (RRTDB.Settings["ShareNickNames"] == 1 or RRTDB.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "RAID") then
            self:Broadcast("RRT_NICKNAMES_COMMS", "RAID", nickname, name, realm, requestback, "RAID")
        end
        if (RRTDB.Settings["ShareNickNames"] == 2 or RRTDB.Settings["ShareNickNames"] == 3) and (channel == "Any" or channel == "GUILD") then
            self:Broadcast("RRT_NICKNAMES_COMMS", "GUILD", nickname, name, realm, requestback, "GUILD")
        end
    end
end

function RRT:NewNickName(unit, nickname, name, realm, channel)
    if self:Restricted() then return end
    if unit ~= "player" and RRTDB.Settings["AcceptNickNames"] ~= 3 then
        if channel == "GUILD" and RRTDB.Settings["AcceptNickNames"] ~= 2 then return end
        if channel == "RAID" and RRTDB.Settings["AcceptNickNames"] ~= 1 then return end
    end
    if not nickname or not name or not realm then return end
    local oldnick = RRTDB.NickNames[name.."-"..realm]
    if oldnick and oldnick == nickname then  return end -- stop early if we already have this exact nickname
    if nickname == "" then
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
        return
    end
    nickname = self:Utf8Sub(nickname, 1, 12)
    RRTDB.NickNames[name.."-"..realm] = nickname
    fullCharList[name.."-"..realm] = nickname
    fullNameList[name] = nickname
    if not sortedCharList[nickname] then
        sortedCharList[nickname] = {}
    end
    sortedCharList[nickname][name.."-"..realm] = true
    if not CharList[nickname] then
        CharList[nickname] = {}
    end
    CharList[nickname][name] = true
    if RRTDB.Settings["GlobalNickNames"] then
        self:UpdateNickNameDisplay(false, unit, name, realm, oldnick, nickname)
    end
end


function RRT:ImportNickNames(string) -- string format is charactername-realm:nickname;charactername-realm:nickname;...
    if string ~= "" then
        string = string.gsub(string, "%s+", "") -- remove all whitespaces
        for _, str in pairs({strsplit(";", string)}) do
            if str ~= "" then
                local namewithrealm, nickname = strsplit(":", str)
                if namewithrealm and nickname then
                    local name, realm = strsplit("-", namewithrealm)
                    local unit
                    if name and realm then
                        RRTDB.NickNames[name.."-"..realm] = nickname
                    end
                else
                    error("Error parsing names: "..str, 1)

                end
            end
        end
        self:GlobalNickNameUpdate()
    end
end

function RRT:SyncNickNames()
    local now = GetTime()
    if (self.LastNickNameSync and self.LastNickNameSync > now-4) or (RRTDB.Settings["NickNamesSyncSend"] == 3) then return end -- don't let user spam syncs / end early if set to none
    self.LastNickNameSync = now
    local channel = RRTDB.Settings["NickNamesSyncSend"] == 1 and "RAID" or "GUILD"
    self:Broadcast("RRT_NICKNAMES_SYNC", channel, RRTDB.NickNames, channel) -- channel is either GUILD or RAID
end

function RRT:SyncNickNamesAccept(nicknametable)
    for name, nickname in pairs(nicknametable) do
        RRTDB.NickNames[name] = nickname
    end
    self:GlobalNickNameUpdate()
end

function RRT:AddNickName(name, realm, nickname) -- keeping the nickname empty acts as removing the nickname for that character
    if name and realm and nickname then
        local unit
        if UnitExists(name) then
            for u in self:IterateGroupMembers() do
                if UnitIsUnit(u, name) then
                    unit = u
                    break
                end
            end
        end
        self:NewNickName(unit, nickname, name, realm, channel)
    end
end




