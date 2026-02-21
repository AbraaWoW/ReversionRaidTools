local _, RRT = ... -- Internal namespace

RRT.SPECIALIZATION_MAP = {
    -- Death Knight
    BLOOD = 250,
    FROST_DK = 251,
    UNHOLY = 252,

    -- Demon Hunter
    HAVOC = 577,
    VENGEANCE = 581,
    DEVOURER = 1480,

    -- Druid
    BALANCE = 102,
    FERAL = 103,
    GUARDIAN = 104,
    RESTO_DRUID = 105,

    -- Evoker
    DEVASTATION = 1467,
    PRESERVATION = 1468,
    AUGMENTATION = 1473,

    -- Hunter
    BEAST_MASTERY = 253,
    MARKSMANSHIP = 254,
    SURVIVAL = 255,

    -- Mage
    ARCANE = 62,
    FIRE = 63,
    FROST_MAGE = 64,

    -- Monk
    BREWMASTER = 268,
    MISTWEAVER = 270,
    WINDWALKER = 269,

    -- Paladin
    HOLY_PALADIN = 65,
    PROTECTION_PALADIN = 66,
    RETRIBUTION = 70,

    -- Priest
    DISCIPLINE = 256,
    HOLY_PRIEST = 257,
    SHADOW = 258,

    -- Rogue
    ASSASSINATION = 259,
    OUTLAW = 260,
    SUBTLETY = 261,

    -- Shaman
    ELEMENTAL = 262,
    ENHANCEMENT = 263,
    RESTO_SHAMAN = 264,

    -- Warlock
    AFFLICTION = 265,
    DEMONOLOGY = 266,
    DESTRUCTION = 267,

    -- Warrior
    ARMS = 71,
    FURY = 72,
    PROTECTION_WARRIOR = 73,
}

RRT.CLASS_SPECIALIZATION_MAP = {
    ["Death Knight"] = { 250, 251, 252 },
    ["Demon Hunter"] = { 577, 581, 1480},
    ["Druid"] = { 102, 103, 104, 105 },
    ["Evoker"] = { 1467, 1468, 1473 },
    ["Hunter"] = { 253, 254, 255 },
    ["Mage"] = { 62, 63, 64 },
    ["Monk"] = { 268, 269, 270 },
    ["Paladin"] = { 65, 66, 70 },
    ["Priest"] = { 256, 257, 258 },
    ["Rogue"] = { 259, 260, 261 },
    ["Shaman"] = { 262, 263, 264 },
    ["Warlock"] = { 265, 266, 267 },
    ["Warrior"] = { 71, 72, 73 },
    ["ALL"] = { 1 },
}

function RRT:GetAllSpecializationIDs()
    local ids = {}
    for k, v in pairs(self.SPECIALIZATION_MAP) do
        tinsert(ids, v)
    end
    return ids
end

function RRT:CheckCooldowns()
    local spec = GetSpecializationInfo(GetSpecialization())
    if RRTDB.CooldownList then
        local now = GetTime()
        local highest = {text = "", time = 0}
        if RRTDB.CooldownList[spec] and RRTDB.CooldownList[spec]["spell"] then
            for k, v in pairs(RRTDB.CooldownList[spec]["spell"]) do
                local charges = C_Spell.GetSpellCharges(k)
                if charges then
                    local timeRemaining = charges.cooldownStartTime ~= 0 and charges.cooldownDuration + charges.cooldownStartTime - now
                    timeRemaining = timeRemaining and timeRemaining + ((charges.maxCharges - charges.currentCharges - 1) * charges.cooldownDuration)
                    if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                        if timeRemaining+v.offset > highest.time then
                            highest = {name = v.name, time = timeRemaining+v.offset}
                        end
                    end
                else
                    local cooldown = C_Spell.GetSpellCooldown(k)
                    local timeRemaining = cooldown and cooldown.duration ~= 0 and cooldown.duration + cooldown.startTime - now
                    if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                        if timeRemaining+v.offset > highest.time then
                            highest = {name = v.name, time = timeRemaining+v.offset}
                        end
                    end
                end
            end
        end
        if RRTDB.CooldownList[spec] and RRTDB.CooldownList[spec]["item"] then
            for k, v in pairs(RRTDB.CooldownList[spec]["item"]) do
                local startTime, duration = C_Container.GetItemCooldown(k)
                local timeRemaining = duration and duration ~= 0 and duration + startTime - now
                if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                    if timeRemaining+v.offset > highest.time then
                            highest = {name = v.name, time = timeRemaining+v.offset}
                    end
                end
            end
        end
        if RRTDB.CooldownList[1] and RRTDB.CooldownList[1]["spell"] then
            for k, v in pairs(RRTDB.CooldownList[1]["spell"]) do
                local charges = C_Spell.GetSpellCharges(k)
                if charges then
                    local timeRemaining = charges.cooldownStartTime ~= 0 and charges.cooldownDuration + charges.cooldownStartTime - now
                    timeRemaining = timeRemaining and timeRemaining + ((charges.maxCharges - charges.currentCharges - 1) * charges.cooldownDuration)
                    if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                        if timeRemaining+v.offset > highest.time then
                            highest = {name = v.name, time = timeRemaining+v.offset}
                        end
                    end
                else
                    local cooldown = C_Spell.GetSpellCooldown(k)
                    local timeRemaining = cooldown and cooldown.duration ~= 0 and cooldown.duration + cooldown.startTime - now
                    if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                        if timeRemaining+v.offset > highest.time then
                            highest = {name = v.name, time = timeRemaining+v.offset}
                        end
                    end
                end
            end
        end
        if RRTDB.CooldownList[1] and RRTDB.CooldownList[1]["item"] then
            for k, v in pairs(RRTDB.CooldownList[1]["item"]) do
                local startTime, duration = C_Container.GetItemCooldown(k)
                local timeRemaining = duration and duration ~= 0 and duration + startTime - now
                if timeRemaining and timeRemaining+v.offset > RRTDB.Settings["CooldownThreshold"] then
                    if timeRemaining+v.offset > highest.time then
                        highest = {name = v.name, time = timeRemaining+v.offset}
                    end
                end
            end
        end
        if highest.time > 0 then
            if RRTDB.Settings["UnreadyOnCooldown"] then ReadyCheckFrameNoButton:Click() end
            SendChatMessage("RRTDB: My "..highest.name.." is on cooldown for "..Round(highest.time).." seconds.", "RAID")
        end
    end
end

function RRT:AddTrackedCooldown(spec, id, type, offset)
    spec = tonumber(spec)
    id = tonumber(id)
    offset = tonumber(offset)
    type = string.lower(type)

    local name
    if type == "spell" then
        local spellName = C_Spell.GetSpellName(id)
        if spellName then
            name = spellName
        else
            name = "ERROR"
        end
    elseif type == "item" then
        local itemName = C_Item.GetItemNameByID(id)
        if itemName then
            name = itemName
        else
            name = "ERROR"
        end
    end
    RRTDB.CooldownList[spec] = RRTDB.CooldownList[spec] or {}
    RRTDB.CooldownList[spec][type] = RRTDB.CooldownList[spec][type] or {}
    RRTDB.CooldownList[spec][type][id] = { offset = offset, name = name }
end


function RRT:RemoveTrackedCooldown(spec, id, type)
    spec = tonumber(spec)
    id = tonumber(id)
    type = string.lower(type)
    if RRTDB.CooldownList[spec] and RRTDB.CooldownList[spec][type] and RRTDB.CooldownList[spec][type][id] then
        RRTDB.CooldownList[spec][type][id] = nil
    end
end
