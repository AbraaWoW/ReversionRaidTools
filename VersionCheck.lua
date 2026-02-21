local _, RRT = ... -- Internal namespace

function RRT:RequestVersionNumber(type, name) -- type == "Addon" or "WA" or "Note"
    if (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player") or RRTDB.Settings["Debug"]) then
        local unit, ver, url, ignore = self:GetVersionNumber(type, name, "player")
        self:VersionResponse({name = UnitName("player"), version = "No Response", ignoreCheck = ignore})
        self:Broadcast("RRT_VERSION_REQUEST", "RAID", type, name)
        for unit in self:IterateGroupMembers() do
            if UnitInRaid(unit) and not UnitIsUnit("player", unit) then
                local index = UnitInRaid(unit)
                local response = select(8, GetRaidRosterInfo(index)) and "No Response" or "Offline"
                self:VersionResponse({name = UnitName(unit), version = response, ignoreCheck = false})
            end
        end
        return {name = UnitName("player"), version = ver, ignoreCheck = ignore}, url
    end
end
function RRT:VersionResponse(data)
    self.RRTUI.version_scrollbox:AddData(data)
end


function RRT:GetVersionNumber(type, name, unit)
    local ignoreCheck = false
    for u in self:IterateGroupMembers() do
       if C_FriendList.IsIgnored(u) then
            ignoreCheck = true
            break
       end
    end
    if type == "Addon" then
        local ver = C_AddOns.GetAddOnMetadata(name, "Version") or "Addon Missing"
        if ver ~= "Addon Missing" then
            ver = C_AddOns.IsAddOnLoaded(name) and ver or "Addon not enabled"
        end
        return unit, ver, "", ignoreCheck
    elseif type == "Note" then
        local note = self:GetNote()
        local hashed
        if C_AddOns.IsAddOnLoaded("MRT") then
            hashed = self:GetHash(note) or "Note Missing"
        else
            hashed = C_AddOns.GetAddOnMetadata("MRT", "Version") and "MRT not enabled" or "MRT not installed"
        end

        return unit, hashed, "", ignoreCheck
    elseif type == "Reminder" then
        local reminder = self.Reminder and self.Reminder ~= "" and self:GetHash(self.Reminder) or "Reminder Missing"
        return unit, reminder, "", ignoreCheck
    end
end


