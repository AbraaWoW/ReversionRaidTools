local _, RRT_NS = ...

-- ─────────────────────────────────────────────────────────────────────────────
-- CDNote — MRT-compatible note renderer & reminder injector
-- Rendering pipeline mirrors MRT's txtWithIcons (Note.lua).
-- ─────────────────────────────────────────────────────────────────────────────

local module = {}

module.DEFAULTS = { noteText = "" }

-- ─────────────────────────────────────────────────────────────────────────────
-- Class colours (WoW standard hex AARRGGBB)
-- ─────────────────────────────────────────────────────────────────────────────

local CLASS_COLORS = {
    WARRIOR     = "ffc79c6e", PALADIN     = "fff58cba", HUNTER      = "ffabd473",
    ROGUE       = "fffff569", PRIEST      = "ffffffff", DEATHKNIGHT = "ffc41f3b",
    SHAMAN      = "ff0070de", MAGE        = "ff69ccf0", WARLOCK     = "ff9482c9",
    MONK        = "ff00ff96", DRUID       = "ffff7d0a", DEMONHUNTER = "ffa330c9",
    EVOKER      = "ff33937f",
}

-- ─────────────────────────────────────────────────────────────────────────────
-- Icon tables  (keys include braces, matching MRT's allIcons / %b{} approach)
-- ─────────────────────────────────────────────────────────────────────────────

local CLASS_PATH = "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES"
local ROLE_PATH  = "Interface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES"

local function CI(l,r,t,b)  -- class icon crop
    return "|T"..CLASS_PATH..":16:16:0:0:256:256:"..l..":"..r..":"..t..":"..b.."|t"
end
local function RI(l,r,t,b)  -- role icon crop
    return "|T"..ROLE_PATH..":16:16:0:0:64:64:"..l..":"..r..":"..t..":"..b.."|t"
end
local function RaidIcon(i)
    return "|TInterface\\TargetingFrame\\UI-RaidTargetingIcon_"..i..":16:16|t"
end

-- ALL_ICONS: keyed by the full {token} string (with braces), used with %b{}
local ALL_ICONS = {}

-- Raid target icons (English + French + German + numeric)
local function AddRaid(name, idx)
    ALL_ICONS["{"..name.."}"] = RaidIcon(idx)
end
AddRaid("star",1);  AddRaid("rt1",1); AddRaid("1",1)
AddRaid("circle",2);AddRaid("rt2",2); AddRaid("2",2)
AddRaid("diamond",3);AddRaid("rt3",3);AddRaid("3",3)
AddRaid("triangle",4);AddRaid("rt4",4);AddRaid("4",4)
AddRaid("moon",5);  AddRaid("rt5",5); AddRaid("5",5)
AddRaid("square",6);AddRaid("rt6",6); AddRaid("6",6)
AddRaid("cross",7); AddRaid("rt7",7); AddRaid("7",7)
AddRaid("skull",8); AddRaid("rt8",8); AddRaid("8",8)
-- French
AddRaid("étoile",1); AddRaid("cercle",2); AddRaid("losange",3)
AddRaid("lune",5); AddRaid("carré",6); AddRaid("croix",7); AddRaid("crâne",8)
-- German
AddRaid("stern",1); AddRaid("kreis",2); AddRaid("diamant",3)
AddRaid("dreieck",4); AddRaid("mond",5); AddRaid("quadrat",6)
AddRaid("kreuz",7); AddRaid("totenschädel",8)

-- Role icons
ALL_ICONS["{tank}"]   = RI(0,  19, 22, 41)
ALL_ICONS["{healer}"] = RI(20, 39, 1,  20)
ALL_ICONS["{dps}"]    = RI(20, 39, 22, 41)

-- Class icons
local classIconDefs = {
    warrior     = CI(0,64,0,64),       paladin     = CI(0,64,128,192),
    hunter      = CI(0,64,64,128),     rogue       = CI(127,190,0,64),
    priest      = CI(127,190,64,128),  deathknight = CI(64,128,128,192),
    shaman      = CI(64,127,64,128),   mage        = CI(64,127,0,64),
    warlock     = CI(190,253,64,128),  monk        = CI(128,189,128,192),
    druid       = CI(190,253,0,64),    demonhunter = CI(190,253,128,192),
    evoker      = "|Tinterface/icons/classicon_evoker:16|t",
}
classIconDefs.dk     = classIconDefs.deathknight
classIconDefs.dh     = classIconDefs.demonhunter
classIconDefs.war    = classIconDefs.warrior
classIconDefs.pal    = classIconDefs.paladin
classIconDefs.hun    = classIconDefs.hunter
classIconDefs.rog    = classIconDefs.rogue
classIconDefs.pri    = classIconDefs.priest
classIconDefs.sham   = classIconDefs.shaman
classIconDefs.lock   = classIconDefs.warlock
classIconDefs.dru    = classIconDefs.druid
classIconDefs.dragon = classIconDefs.evoker
for name, tex in pairs(classIconDefs) do
    ALL_ICONS["{"..name.."}"] = tex
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Auto-colour: build name→coloured-name map from raid/party roster
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildAutoColorData()
    local data = {}
    local function AddUnit(unit)
        local name = UnitName(unit)
        local _, classToken = UnitClass(unit)
        if name and classToken then
            local color = CLASS_COLORS[classToken]
            if color then
                data[name] = "|c"..color..name.."|r"
                local short = name:match("^([^%-]+)")
                if short and short ~= name then
                    data[short] = "|c"..color..short.."|r"
                end
            end
        end
    end
    if IsInRaid() then
        for i = 1, GetNumGroupMembers() do AddUnit("raid"..i) end
    elseif IsInGroup() then
        for i = 1, GetNumSubgroupMembers() do AddUnit("party"..i) end
    end
    AddUnit("player")
    return data
end

-- ─────────────────────────────────────────────────────────────────────────────
-- FormatNote(noteText) → fully rendered string (preserves newlines)
-- Mirrors MRT's txtWithIcons pipeline order exactly.
-- In preview mode ALL role/class/group/phase-filtered content is shown.
-- ─────────────────────────────────────────────────────────────────────────────

local function FormatNote(noteText)
    if not noteText or noteText == "" then return "" end
    local t = noteText

    -- {self} → personal note content
    if t:find("{self}", 1, true) then
        local selfText = ""
        pcall(function() selfText = (VMRT and VMRT.Note and VMRT.Note.SelfText) or "" end)
        t = t:gsub("{self}", selfText)
    end

    -- Multi-line role blocks: replace \n with placeholder so .- can cross lines
    local NL = "\1"
    t = t:gsub("\n", NL)
    -- Preview shows ALL content — strip role filter tags, keep inner text
    t = t:gsub("{[Tt]}(.-)%{/[Tt]%}", "%1")
    t = t:gsub("{[Hh]}(.-)%{/[Hh]%}", "%1")
    t = t:gsub("{[Dd]}(.-)%{/[Dd]%}", "%1")
    -- Remove {0}...{/0} hidden blocks
    t = t:gsub("{0}(.-)%{/0%}", "")
    t = t:gsub(NL, "\n")

    -- Strip any orphaned single role/hidden tags
    t = t:gsub("{/?[Tt]}", ""):gsub("{/?[Hh]}", ""):gsub("{/?[Dd]}", "")
    t = t:gsub("{/?0}", "")

    -- Normalise newlines around filter blocks (MRT pipeline step)
    t = t:gsub("(\n{!?[CcPpGg]:?[^}]+})\n", "%1")
    t = t:gsub("\n({/[CcPpGg]}\n)", "%1")

    -- Player filter {p:name}...{/p} → show content
    t = t:gsub("{!?[Pp]:([^}]+)}(.-)%{/[Pp]%}", "%2")
    -- Class filter {c:class}...{/c} → show content
    t = t:gsub("{!?[Cc]:([^}]+)}(.-)%{/[Cc]%}", "%2")
    -- classunique filter → show content
    t = t:gsub("{[Cc][Ll][Aa][Ss][Ss][Uu][Nn][Ii][Qq][Uu][Ee]:[^}]+}(.-)%{/[Cc][Ll][Aa][Ss][Ss][Uu][Nn][Ii][Qq][Uu][Ee]%}", "%1")
    -- Group filter {g2}...{/g} → show content
    t = t:gsub("{!?[Gg](%d+)}(.-)%{/[Gg]%}", "%2")
    -- Race filter → show content
    t = t:gsub("{!?[Rr][Aa][Cc][Ee]:([^}]+)}(.-)%{/[Rr][Aa][Cc][Ee]%}", "%2")
    -- Encounter filter → show content
    t = t:gsub("{[Ee]:([^}]+)}(.-)%{/[Ee]%}", "%2")
    -- Zone filter → show content
    t = t:gsub("{[Zz]:([^}]+)}(.-)%{/[Zz]%}", "%2")
    -- Phase filter {p2}...{/p} → show content
    t = t:gsub("{!?[Pp][Gg]?([^}:][^}]*)}(.-)%{/[Pp]%}", "%2")

    -- Strip any remaining orphaned filter tags
    t = t:gsub("{!?[PpCcGgRrEeZz][%a]*:?[^}]*}", "")
    t = t:gsub("{/?[PpCcGgRrEeZz][%a]*}", "")

    -- {icon:path} → 16px texture
    t = t:gsub("{icon:([^}]+)}", "|T%1:16|t")

    -- {spell:ID} or {spell:ID:size}
    t = t:gsub("{spell:(%d+):?(%d*)}", function(id, size)
        local sz = math.min(tonumber(size) or 0, 40)
        if sz == 0 then sz = 16 end
        local tex = C_Spell.GetSpellTexture(tonumber(id))
        return "|T"..(tex or "Interface\\Icons\\INV_MISC_QUESTIONMARK")..":"..sz.."|t "
    end)

    -- Remove {time:...} markers entirely
    t = t:gsub("{time:[^}]+}%s*", "")

    -- {text}...{/text} → keep inner
    t = t:gsub("{[Tt][Ee][Xx][Tt]}(.-)%{/[Tt][Ee][Xx][Tt]%}", "%1")
    t = t:gsub("{/?[Tt][Ee][Xx][Tt]}", "")

    -- {everyone}, {self} remnants → strip
    t = t:gsub("{everyone}", ""):gsub("{self}", "")

    -- All remaining {token} → look up in ALL_ICONS (raid marks, roles, classes)
    t = t:gsub("%b{}", function(s)
        return ALL_ICONS[s] or ALL_ICONS[s:lower()] or ""
    end)

    -- Normalise escaped pipes: ||c → |c, ||r → |r
    t = t:gsub("||([cr])", "|%1")

    -- Auto-colour player names by class colour (word-by-word, skip |T...|t tokens)
    local colorData = BuildAutoColorData()
    if next(colorData) then
        t = t:gsub("[^ \n,%(%)%[%]_%$#@!&|]+", function(word)
            return colorData[word] or word
        end)
    end

    -- Remove trailing newlines
    t = t:gsub("\n+$", "")

    return t
end

-- ─────────────────────────────────────────────────────────────────────────────
-- StripTags — plain text with no icons/colours, used for AddToReminder
-- ─────────────────────────────────────────────────────────────────────────────

local function StripTags(line)
    line = line:gsub("||([cr])", "|%1")
    line = line:gsub("{[Tt]}(.-)%{/[Tt]%}", "%1")
    line = line:gsub("{[Hh]}(.-)%{/[Hh]%}", "%1")
    line = line:gsub("{[Dd]}(.-)%{/[Dd]%}", "%1")
    line = line:gsub("{time:[^}]+}", "")
    line = line:gsub("{spell:%d+:?%d*}", "")
    line = line:gsub("{[Tt][Ee][Xx][Tt]}(.-)%{/[Tt][Ee][Xx][Tt]%}", "%1")
    line = line:gsub("{[^}]*}", "")
    line = line:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
    line = line:gsub("%s+", " ")
    return line:match("^%s*(.-)%s*$")
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Helpers
-- ─────────────────────────────────────────────────────────────────────────────

local function TimeToSeconds(timeStr)
    if not timeStr then return nil end
    local m, s = timeStr:match("^(%d+):(%d+)")
    if m and s then return tonumber(m) * 60 + tonumber(s) end
    m, s = timeStr:match("^(%d+)%.(%d+)")
    if m and s then return tonumber(m) * 60 + tonumber(s) end
    local sOnly = tonumber(timeStr:match("^(%d+)$"))
    if sOnly then return sOnly end
    return nil
end

local function FormatTime(seconds)
    if not seconds then return "?" end
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

local function ExtractSpells(line)
    local spells = {}
    for id in line:gmatch("{spell:(%d+):?%d*}") do
        table.insert(spells, tonumber(id))
    end
    return spells
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Player keyword matching (for reminder injection)
-- ─────────────────────────────────────────────────────────────────────────────

local function BuildPlayerKeywords(extra)
    local kw = {}
    local name = UnitName("player")
    if name then kw[name:lower()] = true end
    local _, classToken = UnitClass("player")
    if classToken then kw["class:"..classToken:lower()] = true; kw[classToken:lower()] = true end
    local specIndex = GetSpecialization and GetSpecialization()
    if specIndex then
        local _, specName = GetSpecializationInfo(specIndex)
        if specName then kw["spec:"..specName:lower()] = true end
    end
    local role = UnitGroupRolesAssigned and UnitGroupRolesAssigned("player")
    if role and role ~= "NONE" then kw["role:"..role:lower()] = true end
    for i = 1, GetNumGroupMembers() do
        if UnitIsUnit("raid"..i, "player") then
            local _, _, subgroup = GetRaidRosterInfo(i)
            if subgroup then kw["group:"..subgroup] = true end
            break
        end
    end
    kw["everyone"] = true; kw["all"] = true
    if extra and extra ~= "" then
        for word in extra:gmatch("[^,]+") do
            word = word:match("^%s*(.-)%s*$"):lower()
            if word ~= "" then kw[word] = true end
        end
    end
    return kw
end

local function LineMatchesKeywords(text, keywords)
    if not text or text == "" then return false end
    local plain = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):lower()
    plain = plain:gsub("(%a+)%-[%a]+", "%1")
    for kw in pairs(keywords) do
        if plain:find(kw, 1, true) then return true end
    end
    return false
end

local function HasComplexCondition(entry)
    for _, cond in ipairs(entry.conditions) do
        if cond:match("^p[g]?%d") or cond:match("^S[CA][CSAR]") then return true end
    end
    return false
end

-- ─────────────────────────────────────────────────────────────────────────────
-- ParseNote — extracts {time:} entries for reminder injection
-- ─────────────────────────────────────────────────────────────────────────────

local function ParseNote(noteText)
    local entries = {}
    if not noteText or noteText == "" then return entries end
    noteText = noteText:gsub("kazestart.-kazeend", "")

    for line in (noteText.."\n"):gmatch("([^\n]*)\n") do
        if not line:match("^%s*$") then
            if line:find("{time:") then
                local entry = { type="timer", seconds={}, conditions={}, spells={} }
                for token in line:gmatch("{time:([^}]+)}") do
                    local timePart = token:match("^([^,]+)")
                    local condStr  = token:match("^[^,]+,(.+)$")
                    local secs = TimeToSeconds(timePart)
                    if secs then table.insert(entry.seconds, secs) end
                    if condStr then
                        for cond in condStr:gmatch("[^,]+") do
                            local c = cond:match("^%s*(.-)%s*$")
                            if c ~= "" then table.insert(entry.conditions, c) end
                        end
                    end
                end
                entry.spells      = ExtractSpells(line)
                entry.displayText = StripTags(line)
                entry.rawLine     = line
                if #entry.seconds > 0 and entry.displayText ~= "" then
                    table.insert(entries, entry)
                end
            else
                local display = StripTags(line)
                if display ~= "" then
                    table.insert(entries, { type="text", displayText=display, rawLine=line })
                end
            end
        end
    end
    return entries
end

-- ─────────────────────────────────────────────────────────────────────────────
-- Exports
-- ─────────────────────────────────────────────────────────────────────────────

module.ParseNote           = ParseNote
module.FormatNote          = FormatNote
module.FormatTime          = FormatTime
module.StripTags           = StripTags
module.BuildPlayerKeywords = BuildPlayerKeywords
module.LineMatchesKeywords = LineMatchesKeywords
module.HasComplexCondition = HasComplexCondition

function module:Enable() end

RRT_NS.CDNote = module
