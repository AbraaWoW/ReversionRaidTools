local _, RRT = ...
local DF = _G["DetailsFramework"]

-------------------------------------------------------------------------------
-- Reversion Raid Tools – Note sub-tab
-- Standalone, MRT Note feature-parity, DF-styled (matches Frames tab).
-- DB: RRTDB.Note   Comm prefix: RRTN
-------------------------------------------------------------------------------

-------------------------------------------------------------------------------
-- DF Templates (resolved lazily after Core loads)
-------------------------------------------------------------------------------

local options_switch_template, options_button_template
local options_dropdown_template, options_slider_template
local apply_scrollbar_style

local function EnsureTemplates()
    if options_switch_template then return end
    local Core = RRT.UI and RRT.UI.Core
    if not Core then return end
    options_switch_template   = Core.options_switch_template
    options_button_template   = Core.options_button_template
    options_dropdown_template = Core.options_dropdown_template
    options_slider_template   = Core.options_slider_template
    apply_scrollbar_style     = Core.apply_scrollbar_style
end

-------------------------------------------------------------------------------
-- Constants  (matching SpellTrackerFrames / SetupManager style)
-------------------------------------------------------------------------------

local COMM_PREFIX  = "RRTN"
local MAX_CHUNK    = 220
local MAX_HISTORY  = 10
local TOTAL_DRAFTS = 10
local DRAFT_NAMES  = {
    "Shared", "Personal",
    "Note 1", "Note 2", "Note 3", "Note 4",
    "Note 5", "Note 6", "Note 7", "Note 8",
}

local FONT        = "Fonts\\FRIZQT__.TTF"
local FRAME_WIDTH = 820
local PADDING     = 12
local ROW_HEIGHT  = 26
local ICON_SZ     = 20

local COLOR_LABEL   = { 0.85, 0.85, 0.85 }
local COLOR_MUTED   = { 0.55, 0.55, 0.55 }
local COLOR_BTN     = { 0.10, 0.10, 0.10, 1.0 }
local COLOR_BTN_HOV = { 0.16, 0.16, 0.16, 1.0 }
local COLOR_SECTION = { 0.08, 0.08, 0.08, 0.70 }
local COLOR_BORDER  = { 0.20, 0.20, 0.20, 0.80 }

-------------------------------------------------------------------------------
-- Icon / token map
-------------------------------------------------------------------------------

local _RT  = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_"
local _CCS = "Interface\\GLUES\\CHARACTERCREATE\\UI-CharacterCreate-Classes"
local _LFG = "Interface\\LFGFrame\\UI-LFG-ICON-ROLES"

local function _CI(col, row)
    local x1, x2 = col * 64, col * 64 + 64
    local y1, y2 = row * 64, row * 64 + 64
    return string.format("|T%s:16:16:0:0:256:512:%d:%d:%d:%d|t", _CCS, x1, x2, y1, y2)
end
local function _RI(l, r, t, b)
    return string.format("|T%s:16:16:0:0:64:64:%d:%d:%d:%d|t", _LFG, l, r, t, b)
end

local ICON_MAP = {
    ["{rt1}"] = "|T".._RT.."1:16|t", ["{rt2}"] = "|T".._RT.."2:16|t",
    ["{rt3}"] = "|T".._RT.."3:16|t", ["{rt4}"] = "|T".._RT.."4:16|t",
    ["{rt5}"] = "|T".._RT.."5:16|t", ["{rt6}"] = "|T".._RT.."6:16|t",
    ["{rt7}"] = "|T".._RT.."7:16|t", ["{rt8}"] = "|T".._RT.."8:16|t",
    ["{star}"]     = "|T".._RT.."1:16|t", ["{circle}"]   = "|T".._RT.."2:16|t",
    ["{diamond}"]  = "|T".._RT.."3:16|t", ["{triangle}"] = "|T".._RT.."4:16|t",
    ["{moon}"]     = "|T".._RT.."5:16|t", ["{square}"]   = "|T".._RT.."6:16|t",
    ["{cross}"]    = "|T".._RT.."7:16|t", ["{skull}"]    = "|T".._RT.."8:16|t",
    ["{D}"]      = _RI(20,39,22,41), ["{dps}"]    = _RI(20,39,22,41),
    ["{H}"]      = _RI(20,39, 1,20), ["{healer}"] = _RI(20,39, 1,20),
    ["{T}"]      = _RI( 0,19,22,41), ["{tank}"]   = _RI( 0,19,22,41),
    ["{alliance}"] = "|TInterface\\FactionFrame\\PVP-Currency-Alliance:16|t",
    ["{horde}"]    = "|TInterface\\FactionFrame\\PVP-Currency-Horde:16|t",
    ["{warrior}"]     = _CI(0,0), ["{war}"]    = _CI(0,0),
    ["{paladin}"]     = _CI(1,0), ["{pal}"]    = _CI(1,0),
    ["{hunter}"]      = _CI(2,0), ["{hun}"]    = _CI(2,0),
    ["{rogue}"]       = _CI(3,0), ["{rog}"]    = _CI(3,0),
    ["{priest}"]      = _CI(0,1), ["{pri}"]    = _CI(0,1),
    ["{deathknight}"] = _CI(1,1), ["{dk}"]     = _CI(1,1),
    ["{shaman}"]      = _CI(2,1), ["{sham}"]   = _CI(2,1),
    ["{mage}"]        = _CI(3,1), ["{mag}"]    = _CI(3,1),
    ["{warlock}"]     = _CI(0,2), ["{lock}"]   = _CI(0,2),
    ["{monk}"]        = _CI(1,2), ["{mon}"]    = _CI(1,2),
    ["{druid}"]       = _CI(2,2), ["{dru}"]    = _CI(2,2),
    ["{demonhunter}"] = _CI(3,2), ["{dh}"]     = _CI(3,2),
    ["{evoker}"]      = _CI(0,3), ["{dragon}"] = _CI(0,3), ["{evo}"] = _CI(0,3),
}

local CLASS_TOKEN = {
    warrior="WARRIOR",      war="WARRIOR",      paladin="PALADIN",    pal="PALADIN",
    hunter="HUNTER",        hun="HUNTER",       rogue="ROGUE",        rog="ROGUE",
    priest="PRIEST",        pri="PRIEST",       deathknight="DEATHKNIGHT", dk="DEATHKNIGHT",
    shaman="SHAMAN",        sham="SHAMAN",      mage="MAGE",          mag="MAGE",
    warlock="WARLOCK",      lock="WARLOCK",     monk="MONK",          mon="MONK",
    druid="DRUID",          dru="DRUID",        demonhunter="DEMONHUNTER", dh="DEMONHUNTER",
    evoker="EVOKER",        dragon="EVOKER",    evo="EVOKER",
}
local CLASS_HEX = {
    WARRIOR="C69B3A", PALADIN="F48CBA", HUNTER="AAD372",  ROGUE="FFF468",
    PRIEST="FFFFFF",  DEATHKNIGHT="C41E3A", SHAMAN="0070DD", MAGE="3FC7EB",
    WARLOCK="8788EE", MONK="00FF98",    DRUID="FF7C0A",   DEMONHUNTER="A330C9",
    EVOKER="33937F",
}

-------------------------------------------------------------------------------
-- Module state
-------------------------------------------------------------------------------

local _noteEditor     = nil
local _titleEditor    = nil
local _noteWindow     = nil
local _draftDD        = nil
local _incomingChunks = {}
local _sendCounter    = 0
local _renderCache    = { src = nil, lines = nil, hasTimed = false }
local _tickerElapsed  = 0
local _autoColors     = {}

-------------------------------------------------------------------------------
-- DB
-------------------------------------------------------------------------------

local function EnsureDB()
    if not RRTDB then return nil end
    RRTDB.Note = RRTDB.Note or {}
    local db = RRTDB.Note
    if type(db.drafts) ~= "table" then db.drafts = {} end
    for i = 1, TOTAL_DRAFTS do
        if type(db.drafts[i]) ~= "table" then
            db.drafts[i] = { title = DRAFT_NAMES[i] or ("Note " .. i), text = "" }
        end
        if type(db.drafts[i].title) ~= "string" then db.drafts[i].title = DRAFT_NAMES[i] or ("Note "..i) end
        if type(db.drafts[i].text)  ~= "string" then db.drafts[i].text  = "" end
    end
    if type(db.activeDraft)  ~= "number"  or db.activeDraft < 1 or db.activeDraft > TOTAL_DRAFTS then db.activeDraft  = 1     end
    if type(db.history)      ~= "table"   then db.history      = {}    end
    if type(db.selfText)     ~= "string"  then db.selfText     = ""    end
    if type(db.onlyPromoted) ~= "boolean" then db.onlyPromoted = true  end
    if type(db.showOnReceive)~= "boolean" then db.showOnReceive= true  end
    if type(db.visible)      ~= "boolean" then db.visible      = true  end
    if type(db.timerAnchor)  ~= "number"  then db.timerAnchor  = 0     end
    if type(db.window) ~= "table" then db.window = {} end
    local w = db.window
    if type(w.width)               ~= "number"  then w.width               = 560    end
    if type(w.height)              ~= "number"  then w.height              = 360    end
    if type(w.x)                   ~= "number"  then w.x                   = 30     end
    if type(w.y)                   ~= "number"  then w.y                   = 0      end
    if type(w.point)               ~= "string"  then w.point               = "LEFT" end
    if type(w.relativePoint)       ~= "string"  then w.relativePoint       = "LEFT" end
    if type(w.opacity)             ~= "number"  then w.opacity             = 0.78   end
    if type(w.fontSize)            ~= "number"  then w.fontSize            = 12     end
    if type(w.scale)               ~= "number"  then w.scale               = 1.0    end
    if type(w.alwaysOnTop)         ~= "boolean" then w.alwaysOnTop         = false  end
    if type(w.locked)              ~= "boolean" then w.locked              = false  end
    if type(w.showTitleBar)        ~= "boolean" then w.showTitleBar        = true   end
    if type(w.autoHideOutOfCombat) ~= "boolean" then w.autoHideOutOfCombat = false  end
    return db
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function RRT_Print(msg)
    print("|cFF33FF99[RRT Note]|r " .. tostring(msg))
end
local function Clamp(v, lo, hi)
    v = tonumber(v) or lo; return v < lo and lo or v > hi and hi or v
end
local function SafeText(s)
    return tostring(s or ""):gsub("|", "||")
end
local function FormatOffset(seconds)
    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end
local function ParseTimeSpec(spec)
    spec = strtrim(tostring(spec or "")); if spec == "" then return nil end
    local m, s = spec:match("^(%d+):(%d%d?)$")
    if m and s then s = tonumber(s); if s and s < 60 then return tonumber(m)*60+s end; return nil end
    local n = tonumber(spec); return n and math.max(0, math.floor(n)) or nil
end

local function ApplyRRTFont(fs, size)
    if not fs then return end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched  = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then fs:SetFont(fetched, size or 10, "OUTLINE") end
end

-------------------------------------------------------------------------------
-- Roster / auto-colors
-------------------------------------------------------------------------------

local function UpdateAutoColors()
    wipe(_autoColors)
    local function AddUnit(unit)
        local name = UnitName(unit); local _, class = UnitClass(unit)
        if name and class then local hex = CLASS_HEX[class]; if hex then _autoColors[name] = "|cFF"..hex end end
    end
    local count = GetNumGroupMembers()
    if count == 0 then AddUnit("player"); return end
    local prefix = IsInRaid() and "raid" or "party"
    for i = 1, count do AddUnit(prefix .. i) end
    AddUnit("player")
end

local function GetRoster()
    local roster, count = {}, GetNumGroupMembers()
    if count == 0 then
        local name = UnitName("player"); local _, class = UnitClass("player"); local race = UnitRace("player")
        if name then table.insert(roster, { name=name, class=class or "", group=1, race=race or "" }) end
        return roster
    end
    local inRaid = IsInRaid(); local prefix = inRaid and "raid" or "party"
    for i = 1, count do
        local unit = prefix .. i; local name = UnitName(unit)
        if name then
            local _, class = UnitClass(unit)
            local subgroup = inRaid and (tonumber(select(3, GetRaidRosterInfo(i))) or 1) or 1
            local race = UnitRace(unit)
            table.insert(roster, { name=name, class=class or "", group=subgroup, race=race or "" })
        end
    end
    return roster
end

local function ColoredName(name)
    local col = _autoColors[name]
    return col and (col .. SafeText(name) .. "|r") or SafeText(name)
end
local function GetPlayersOfClass(key)
    local cls = CLASS_TOKEN[key:lower()]; if not cls then return "" end
    local n = {}; for _, m in ipairs(GetRoster()) do if m.class == cls then table.insert(n, ColoredName(m.name)) end end
    return table.concat(n, ", ")
end
local function GetPlayersOfGroup(g)
    g = tonumber(g) or 1; local n = {}
    for _, m in ipairs(GetRoster()) do if m.group == g then table.insert(n, ColoredName(m.name)) end end
    return table.concat(n, ", ")
end
local function GetPlayersOfRace(race)
    local rLow = race:lower(); local n = {}
    for _, m in ipairs(GetRoster()) do if m.race:lower() == rLow then table.insert(n, ColoredName(m.name)) end end
    return table.concat(n, ", ")
end
local function GetSpellDisplay(spellID, size)
    local id = tonumber(spellID); if not id then return tostring(spellID) end
    size = tonumber(size) or 14; local name, tex
    if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(id) elseif GetSpellInfo then name = (GetSpellInfo(id)) end
    if C_Spell and C_Spell.GetSpellTexture then tex = C_Spell.GetSpellTexture(id) elseif GetSpellTexture then tex = GetSpellTexture(id) end
    name = (type(name)=="string" and name~="") and name or ("Spell "..id)
    return tex and string.format("|T%s:%d|t %s", tex, size, name) or name
end
local function GetEncounterDisplay(id)
    id = tonumber(id); if not id then return "?" end
    if EJ_GetEncounterInfo then local n = EJ_GetEncounterInfo(id); if n and n~="" then return n end end
    return "Encounter "..id
end

-------------------------------------------------------------------------------
-- Format engine
-------------------------------------------------------------------------------

local function FormatText(rawText, db)
    local t = tostring(rawText or "")
    t = t:gsub("||c", "\0ESC_C\0")
    local selfStr = (db and db.selfText ~= "") and db.selfText or (UnitName("player") or "Self")
    t = t:gsub("{self}", SafeText(selfStr))
    t = t:gsub("{p:([^}]+)}", function(n) return ColoredName(n) end)
    t = t:gsub("{classunique:([^}]+)}", function(cls)
        local all = GetPlayersOfClass(cls); if all=="" then return "{classunique:"..cls.."}" end
        return (all:match("^([^,]+)") or all)
    end)
    t = t:gsub("{c:([^}]+)}", function(cls) local r=GetPlayersOfClass(cls); return r~="" and r or "{c:"..cls.."}" end)
    t = t:gsub("{g(%d)}", function(n) local r=GetPlayersOfGroup(tonumber(n)); return r~="" and r or "{g"..n.."}" end)
    t = t:gsub("{race:([^}]+)}", function(race) local r=GetPlayersOfRace(race); return r~="" and r or "{race:"..race.."}" end)
    t = t:gsub("{e:(%d+)}", function(id) return GetEncounterDisplay(id) end)
    t = t:gsub("{spell:(%d+):?(%d*)}", function(id, sz) return GetSpellDisplay(id, sz~="" and sz or nil) end)
    t = t:gsub("{icon:([^}]+)}", function(path) return string.format("|T%s:16|t", path) end)
    t = t:gsub("{[%a%d]+}", function(tok) return ICON_MAP[tok] or tok end)
    if next(_autoColors) then
        local sorted = {}; for name in pairs(_autoColors) do table.insert(sorted, name) end
        table.sort(sorted, function(a,b) return #a>#b end)
        for _, name in ipairs(sorted) do
            local col = _autoColors[name]
            if col then
                local esc = name:gsub("([%-%.%(%)%[%]%*%+%?%^%$%%])", "%%%1")
                t = t:gsub(esc, col..name.."|r")
            end
        end
    end
    t = t:gsub("\0ESC_C\0", "|c")
    return t
end

local function StripForChat(rawText, db)
    local t = tostring(rawText or "")
    t = t:gsub("{time:[^}]+}%s*", "")
    local selfStr = (db and db.selfText ~= "") and db.selfText or (UnitName("player") or "Self")
    t = t:gsub("{self}", selfStr)
    t = t:gsub("{p:([^}]+)}", function(n) return n end)
    t = t:gsub("{classunique:([^}]+)}", function(cls)
        local all = GetPlayersOfClass(cls):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r","")
        return all~="" and (all:match("^([^,]+)") or all) or cls
    end)
    t = t:gsub("{c:([^}]+)}", function(cls)
        return (GetPlayersOfClass(cls):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""))
    end)
    t = t:gsub("{g(%d)}", function(n)
        return (GetPlayersOfGroup(tonumber(n)):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""))
    end)
    t = t:gsub("{race:([^}]+)}", function(race)
        return (GetPlayersOfRace(race):gsub("|c%x%x%x%x%x%x%x%x",""):gsub("|r",""))
    end)
    t = t:gsub("{e:(%d+)}", function(id) return GetEncounterDisplay(id) end)
    t = t:gsub("{spell:(%d+):?(%d*)}", function(id)
        local n; if C_Spell and C_Spell.GetSpellName then n=C_Spell.GetSpellName(tonumber(id))
        elseif GetSpellInfo then n=(GetSpellInfo(tonumber(id))) end
        return (type(n)=="string" and n~="") and n or ("Spell "..id)
    end)
    t = t:gsub("{icon:[^}]+}", ""):gsub("{[^}]+}", ""):gsub("|T[^|]+|t%s?",""):gsub("||c","|c")
    return t
end

-------------------------------------------------------------------------------
-- Timer / timed-line parsing
-------------------------------------------------------------------------------

local function ParseTimedLine(line, rollingOffset)
    local tSpec = line:match("^%{time:([^,}]+)")
    if tSpec then
        local off = ParseTimeSpec(tSpec)
        if off then
            local rest = strtrim(line:gsub("^%{time:[^}]*%}%s*","",1))
            if rest~="" then return true, off, rest, off end
        end
    end
    local mm, ss, msg = line:match("^%[(%d+):(%d%d?)%]%s+(.+)$")
    if mm and ss and msg then ss=tonumber(ss); if ss and ss<60 then return true, tonumber(mm)*60+ss, strtrim(msg), tonumber(mm)*60+ss end end
    mm, ss, msg = line:match("^(%d+):(%d%d?)%s+(.+)$")
    if mm and ss and msg then ss=tonumber(ss); if ss and ss<60 then return true, tonumber(mm)*60+ss, strtrim(msg), tonumber(mm)*60+ss end end
    mm, ss, msg = line:match("^%+(%d+):(%d%d?)%s+(.+)$")
    if mm and ss and msg then ss=tonumber(ss); if ss and ss<60 then local off=math.max(0,rollingOffset+tonumber(mm)*60+ss); return true,off,strtrim(msg),off end end
    local ds, dmsg = line:match("^%+(%d+)%s+(.+)$")
    if ds and dmsg then local off=math.max(0,rollingOffset+tonumber(ds)); return true,off,strtrim(dmsg),off end
    return false, 0, line, rollingOffset
end

local function BuildDisplayLines(rawText)
    local lines, hasTimed, rolling = {}, false, 0
    rawText = tostring(rawText or ""):gsub("\r\n","\n"):gsub("\r","\n")
    for rawLine in (rawText.."\n"):gmatch("(.-)\n") do
        local line = strtrim(rawLine or "")
        if line=="" then table.insert(lines,{isBlank=true,text=""})
        else
            local isTimed, off, msg, nextRolling = ParseTimedLine(line, rolling)
            if isTimed then rolling=nextRolling; hasTimed=true end
            table.insert(lines,{isTimed=isTimed,offset=isTimed and off or nil,text=msg})
        end
    end
    return lines, hasTimed
end

local function InvalidateCache()
    _renderCache.src=nil; _renderCache.lines=nil; _renderCache.hasTimed=false
end
local function GetDisplayLines(rawText)
    if _renderCache.src==rawText and _renderCache.lines then return _renderCache.lines, _renderCache.hasTimed end
    local lines, hasTimed = BuildDisplayLines(rawText)
    _renderCache.src=rawText; _renderCache.lines=lines; _renderCache.hasTimed=hasTimed
    return lines, hasTimed
end
local function BuildStyledText(db)
    local draft = db and db.drafts and db.drafts[db.activeDraft or 1]
    local rawText = (draft and draft.text) or ""
    local lines, hasTimed = GetDisplayLines(rawText)
    local timerRunning = db and db.timerAnchor and db.timerAnchor > 0
    local elapsed = timerRunning and (GetTime()-db.timerAnchor) or 0
    local out = {}
    for _, row in ipairs(lines) do
        if row.isBlank then table.insert(out," ")
        else
            local msg = FormatText(row.text, db)
            if row.isTimed and row.offset then
                if timerRunning then
                    local r = math.floor(row.offset-elapsed+0.5)
                    if r>15 then      table.insert(out,"|cff66dd66["..FormatOffset(r).."]|r "..msg)
                    elseif r>5 then   table.insert(out,"|cffffc44d["..FormatOffset(r).."]|r "..msg)
                    elseif r>0 then   table.insert(out,"|cffff5555["..FormatOffset(math.abs(r)).."]|r |cffffcc66>>|r "..msg)
                    else              table.insert(out,"|cff888888[+"..FormatOffset(math.abs(r)).."]|r "..msg) end
                else table.insert(out,"|cff66b3ff["..FormatOffset(row.offset).."]|r "..msg) end
            else table.insert(out,"|cffdddddd"..msg.."|r") end
        end
    end
    local rendered = table.concat(out,"\n")
    if strtrim(rendered)=="" then rendered="|cff888888(Note is empty)|r" end
    return rendered, hasTimed
end

-------------------------------------------------------------------------------
-- Scroll bar skin (for display window – created before templates load)
-------------------------------------------------------------------------------

local function SkinScrollBar(sf)
    if not sf then return end
    local sb = sf.ScrollBar
    if not sb then local n=sf.GetName and sf:GetName(); if n then sb=_G[n.."ScrollBar"] end end
    if not sb then for _,ch in ipairs({sf:GetChildren()}) do if ch and ch.GetObjectType and ch:GetObjectType()=="Slider" then sb=ch; break end end end
    if not sb or sb._rrtSkinned then return end
    sb._rrtSkinned=true; sb:SetWidth(13)
    local bg=sb:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8"); bg:SetVertexColor(0.07,0.07,0.08,0.95)
    local thumb=sb:GetThumbTexture()
    if not thumb then thumb=sb:CreateTexture(nil,"ARTWORK"); sb:SetThumbTexture(thumb) end
    thumb:SetTexture("Interface\\Buttons\\WHITE8X8"); thumb:SetSize(10,26); thumb:SetVertexColor(0.30,0.72,1.00,0.9)
    local function SkinArrow(btn, ch)
        if not btn or btn._rrtArr then return end; btn._rrtArr=true
        for _,g in ipairs({"GetNormalTexture","GetHighlightTexture","GetPushedTexture","GetDisabledTexture"}) do local tx=btn[g] and btn[g](btn); if tx then tx:SetAlpha(0) end end
        local abg=btn:CreateTexture(nil,"BACKGROUND"); abg:SetAllPoints(); abg:SetTexture("Interface\\Buttons\\WHITE8X8"); abg:SetVertexColor(0.14,0.14,0.15,0.95)
        local afs=btn:CreateFontString(nil,"OVERLAY"); afs:SetFont(FONT,10,"OUTLINE"); afs:SetPoint("CENTER"); afs:SetText(ch); afs:SetTextColor(0.55,0.55,0.55)
        btn:HookScript("OnEnter", function() abg:SetVertexColor(0.22,0.22,0.24,1); afs:SetTextColor(0.30,0.72,1.00) end)
        btn:HookScript("OnLeave", function() abg:SetVertexColor(0.14,0.14,0.15,0.95); afs:SetTextColor(0.55,0.55,0.55) end)
    end
    local sbn=sb.GetName and sb:GetName()
    SkinArrow(sb.ScrollUpButton or (sbn and _G[sbn.."ScrollUpButton"]),"^")
    SkinArrow(sb.ScrollDownButton or (sbn and _G[sbn.."ScrollDownButton"]),"v")
end

-------------------------------------------------------------------------------
-- Display window
-------------------------------------------------------------------------------

local function SaveWinPos()
    if not _noteWindow then return end
    local db=EnsureDB(); if not db then return end
    local p,_,rp,x,y=_noteWindow:GetPoint(1)
    if p and rp then db.window.point=p; db.window.relativePoint=rp; db.window.x=tonumber(x) or 0; db.window.y=tonumber(y) or 0 end
end
local function SaveWinSize()
    if not _noteWindow then return end
    local db=EnsureDB(); if not db then return end
    db.window.width=math.floor(_noteWindow:GetWidth()+0.5); db.window.height=math.floor(_noteWindow:GetHeight()+0.5)
end
local function ReflowWin()
    if not _noteWindow or not _noteWindow.textFS then return end
    local w=math.max(120,_noteWindow:GetWidth()-44)
    if _noteWindow.content then _noteWindow.content:SetWidth(w) end
    _noteWindow.textFS:SetWidth(w-4)
    local h=math.max(20,math.ceil(_noteWindow.textFS:GetStringHeight())+12)
    if _noteWindow.content then _noteWindow.content:SetHeight(h) end
end
local function ApplyWinSettings()
    if not _noteWindow then return end
    local db=EnsureDB(); if not db then return end
    local w=db.window
    w.opacity=Clamp(w.opacity,0.20,1.00); w.fontSize=math.floor(Clamp(w.fontSize,9,24)+0.5); w.scale=Clamp(w.scale,0.70,1.50)
    _noteWindow:SetScale(w.scale); _noteWindow:SetFrameStrata(w.alwaysOnTop and "TOOLTIP" or "HIGH")
    _noteWindow:SetBackdropColor(0.03,0.03,0.03,w.opacity)
    if _noteWindow.textFS then _noteWindow.textFS:SetFont(FONT,w.fontSize,"") end
    if _noteWindow.topBar and _noteWindow.winScroll then
        if w.showTitleBar then
            _noteWindow.topBar:Show(); if _noteWindow.closeBtn then _noteWindow.closeBtn:Show() end
            _noteWindow.winScroll:ClearAllPoints(); _noteWindow.winScroll:SetPoint("TOPLEFT",6,-28); _noteWindow.winScroll:SetPoint("BOTTOMRIGHT",-26,8)
        else
            _noteWindow.topBar:Hide(); if _noteWindow.closeBtn then _noteWindow.closeBtn:Hide() end
            _noteWindow.winScroll:ClearAllPoints(); _noteWindow.winScroll:SetPoint("TOPLEFT",6,-6); _noteWindow.winScroll:SetPoint("BOTTOMRIGHT",-26,8)
        end
    end
    _noteWindow:SetMovable(not w.locked); _noteWindow:RegisterForDrag(w.locked and nil or "LeftButton")
    if _noteWindow.resizeGrip then _noteWindow.resizeGrip:EnableMouse(not w.locked); _noteWindow.resizeGrip:SetAlpha(w.locked and 0.2 or 0.8) end
end
local function RefreshWin()
    if not _noteWindow then return end
    local db=EnsureDB(); if not db then return end
    local draft=db.drafts and db.drafts[db.activeDraft or 1]
    local title=(draft and draft.title) or "Note"
    if _noteWindow.titleFS then
        local rawText=(draft and draft.text) or ""; local _,hasTimed=GetDisplayLines(rawText)
        local timerRunning=db.timerAnchor and db.timerAnchor>0
        if timerRunning and hasTimed then
            local elapsed=math.max(0,math.floor(GetTime()-db.timerAnchor))
            _noteWindow.titleFS:SetText("|cff4db8ff"..SafeText(title).."|r  |cff88ff88("..FormatOffset(elapsed)..")|r")
        else _noteWindow.titleFS:SetText("|cff4db8ff"..SafeText(title).."|r") end
    end
    if _noteWindow.textFS then _noteWindow.textFS:SetText(BuildStyledText(db)) end
    ApplyWinSettings(); ReflowWin()
end
local function ShowWin()
    local db=EnsureDB(); if not db or not _noteWindow then return end
    db.visible=true; local w=db.window
    _noteWindow:ClearAllPoints(); _noteWindow:SetPoint(w.point or "LEFT",UIParent,w.relativePoint or "LEFT",w.x or 30,w.y or 0)
    _noteWindow:SetSize(w.width or 560,w.height or 360); ApplyWinSettings(); RefreshWin(); _noteWindow:Show()
end
local function HideWin()
    local db=EnsureDB(); if db then db.visible=false end; if _noteWindow then _noteWindow:Hide() end
end
local function ToggleWin()
    if _noteWindow and _noteWindow:IsShown() then HideWin() else ShowWin() end
end
local function ApplyVisibilityState()
    if not _noteWindow then return end; local db=EnsureDB(); if not db then return end
    if not db.visible then _noteWindow:Hide(); return end
    if db.window.autoHideOutOfCombat and not UnitAffectingCombat("player") then _noteWindow:Hide(); return end
    ApplyWinSettings(); RefreshWin(); _noteWindow:Show()
end
local function CreateWin()
    if _noteWindow then return _noteWindow end
    local db=EnsureDB(); if not db then return nil end
    local w=db.window
    local frame=CreateFrame("Frame","RRTUI_NoteWindow",UIParent,"BackdropTemplate")
    frame:SetClampedToScreen(true); frame:SetFrameStrata("HIGH"); frame:SetSize(w.width,w.height)
    frame:SetPoint(w.point,UIParent,w.relativePoint,w.x,w.y)
    frame:EnableMouse(true); frame:SetMovable(true); frame:RegisterForDrag("LeftButton")
    frame:SetResizable(true); frame:SetResizeBounds(300,180,1800,1200)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(0.03,0.03,0.03,w.opacity); frame:SetBackdropBorderColor(0.25,0.25,0.25,1.0)
    frame:SetScript("OnDragStart",function(self) self:StartMoving() end)
    frame:SetScript("OnDragStop",function(self) self:StopMovingOrSizing(); SaveWinPos() end)
    frame:SetScript("OnSizeChanged",function() SaveWinSize(); ReflowWin() end)
    local top=CreateFrame("Frame",nil,frame,"BackdropTemplate")
    top:SetPoint("TOPLEFT",0,0); top:SetPoint("TOPRIGHT",0,0); top:SetHeight(24)
    top:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8"}); top:SetBackdropColor(0.10,0.10,0.10,0.95)
    local titleFS=top:CreateFontString(nil,"OVERLAY"); titleFS:SetFont(FONT,12,"OUTLINE"); titleFS:SetPoint("LEFT",8,0)
    titleFS:SetText("|cff4db8ffRaid Note|r")
    local closeBtn=CreateFrame("Button",nil,top)
    closeBtn:SetPoint("RIGHT",-4,0); closeBtn:SetSize(20,20)
    closeBtn:SetNormalFontObject(GameFontNormal); closeBtn:SetHighlightFontObject(GameFontHighlight)
    closeBtn:SetText("X"); closeBtn:SetScript("OnClick",function() HideWin() end)
    local sf=CreateFrame("ScrollFrame",nil,frame,"UIPanelScrollFrameTemplate")
    sf:SetPoint("TOPLEFT",6,-28); sf:SetPoint("BOTTOMRIGHT",-26,8)
    local content=CreateFrame("Frame",nil,sf); content:SetSize(math.max(120,frame:GetWidth()-44),120)
    local textFS=content:CreateFontString(nil,"ARTWORK","GameFontHighlightSmall")
    textFS:SetPoint("TOPLEFT",2,-2); textFS:SetWidth(math.max(120,frame:GetWidth()-48))
    textFS:SetJustifyH("LEFT"); textFS:SetJustifyV("TOP"); textFS:SetTextColor(0.92,0.92,0.92,1.0)
    textFS:SetWordWrap(true); textFS:SetSpacing(2); sf:SetScrollChild(content); SkinScrollBar(sf)
    local grip=CreateFrame("Frame",nil,frame); grip:SetPoint("BOTTOMRIGHT",0,0); grip:SetSize(16,16); grip:EnableMouse(true)
    local gripTex=grip:CreateTexture(nil,"ARTWORK"); gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Up"); gripTex:SetVertexColor(0.9,0.9,0.9,0.8)
    grip:SetScript("OnMouseDown",function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp",function() frame:StopMovingOrSizing(); SaveWinSize(); SaveWinPos() end)
    frame.titleFS=titleFS; frame.topBar=top; frame.closeBtn=closeBtn
    frame.winScroll=sf; frame.content=content; frame.textFS=textFS; frame.resizeGrip=grip; frame:Hide()
    _noteWindow=frame; ApplyWinSettings(); RefreshWin()
    if db.visible then ApplyVisibilityState() end
    return frame
end

-------------------------------------------------------------------------------
-- Comm
-------------------------------------------------------------------------------

local function EnsureComm()
    if C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix then
        pcall(C_ChatInfo.RegisterAddonMessagePrefix, COMM_PREFIX)
    end
end
local function CanSendNote()
    if IsInRaid() or IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end
    return true
end
local function CanReceiveFrom(senderShort)
    local db=EnsureDB(); if not db then return false end
    if not db.onlyPromoted then return true end
    local me=Ambiguate(UnitName("player") or "","short"); if senderShort==me then return true end
    if not IsInRaid() then return true end
    for i=1,GetNumGroupMembers() do
        local unit="raid"..i; local name=UnitName(unit)
        if name and Ambiguate(name,"short")==senderShort then return UnitIsGroupLeader(unit) or UnitIsGroupAssistant(unit) end
    end
    return false
end
local function ResolveAddonDist()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
    if IsInRaid() then return "RAID" end; if IsInGroup() then return "PARTY" end; return nil
end
local function BroadcastNote()
    local db=EnsureDB(); if not db then return end
    if not CanSendNote() then RRT_Print("Only leader/assist can send the note."); return end
    local dist=ResolveAddonDist(); if not dist then RRT_Print("You must be in a group."); return end
    local draft=db.drafts and db.drafts[db.activeDraft or 1]
    local title=(draft and draft.title) or "Note"; local text=(draft and draft.text) or ""
    if strtrim(text)=="" then RRT_Print("Note is empty."); return end
    _sendCounter=(_sendCounter%9999)+1
    local noteID=string.format("%d-%04d",math.floor(GetTime()*1000),_sendCounter)
    local function Send(p) if C_ChatInfo and C_ChatInfo.SendAddonMessage then pcall(C_ChatInfo.SendAddonMessage,COMM_PREFIX,p,dist) end end
    Send("S\t"..noteID.."\t"..title)
    for i=1,#text,MAX_CHUNK do Send("C\t"..noteID.."\t"..text:sub(i,i+MAX_CHUNK-1)) end
    Send("E\t"..noteID); RRT_Print("Note sent to "..dist..".")
end
local function HandleComm(_,_,prefix,message,_,sender)
    if prefix~=COMM_PREFIX then return end
    local db=EnsureDB(); if not db then return end
    local senderShort=Ambiguate(sender or "","short")
    if not CanReceiveFrom(senderShort) then return end
    local cmd,noteID,payload=message:match("^(%u)\t([^\t]+)\t?(.*)$"); if not cmd or not noteID then return end
    if cmd=="S" then _incomingChunks[noteID]={sender=senderShort,title=payload or "",chunks={},t=GetTime()}
    elseif cmd=="C" then
        local pack=_incomingChunks[noteID]
        if not pack then pack={sender=senderShort,title="",chunks={},t=GetTime()}; _incomingChunks[noteID]=pack end
        table.insert(pack.chunks, payload or "")
    elseif cmd=="E" then
        local pack=_incomingChunks[noteID]; if not pack then return end
        local text=table.concat(pack.chunks,"")
        local draft=db.drafts and db.drafts[db.activeDraft or 1]
        if draft then if pack.title~="" then draft.title=pack.title end; draft.text=text end
        InvalidateCache(); RefreshWin()
        if _titleEditor then _titleEditor:SetText((draft and draft.title) or "") end
        if _noteEditor  then _noteEditor:SetText(text) end
        if db.showOnReceive then ShowWin() end
        RRT_Print("Note received from "..SafeText(tostring(pack.sender)).."."); _incomingChunks[noteID]=nil
    end
    local now=GetTime(); for id,pack in pairs(_incomingChunks) do if (now-(pack.t or now))>60 then _incomingChunks[id]=nil end end
end

-------------------------------------------------------------------------------
-- Timer / History / Chat
-------------------------------------------------------------------------------

local function StartTimer()
    local db=EnsureDB(); if not db then return end; db.timerAnchor=GetTime(); InvalidateCache(); RefreshWin(); RRT_Print("Timer started.")
end
local function ResetTimer()
    local db=EnsureDB(); if not db then return end; db.timerAnchor=0; InvalidateCache(); RefreshWin(); RRT_Print("Timer reset.")
end

local function PushHistory()
    local db=EnsureDB(); if not db then return end
    local draft=db.drafts and db.drafts[db.activeDraft or 1]; if not draft then return end
    table.insert(db.history,1,{idx=db.activeDraft,text=draft.text})
    if #db.history>MAX_HISTORY then table.remove(db.history) end
end
local function UndoHistory()
    local db=EnsureDB(); if not db or #db.history==0 then RRT_Print("Nothing to undo."); return end
    local entry=table.remove(db.history,1); if not entry then return end
    local draft=db.drafts and db.drafts[entry.idx or db.activeDraft or 1]
    if draft then draft.text=entry.text; if _noteEditor then _noteEditor:SetText(draft.text) end; InvalidateCache(); RefreshWin(); RRT_Print("Undo applied.") end
end

local function SendToChat(rawText, mode, db)
    if strtrim(rawText or "")=="" then RRT_Print("Note is empty."); return end
    local function resolve()
        if mode and mode~="AUTO" then return mode end
        if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then return "INSTANCE_CHAT" end
        if IsInRaid() then return (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) and "RAID_WARNING" or "RAID" end
        if IsInGroup() then return "PARTY" end; return "SAY"
    end
    local channel=resolve()
    if channel=="RAID_WARNING" and not (UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")) then channel="RAID" end
    if channel=="RAID" and not IsInRaid() then channel=IsInGroup() and "PARTY" or "SAY" end
    local plain=StripForChat(rawText,db); local sent,maxLen=0,240
    for rawLine in tostring(plain):gmatch("[^\r\n]+") do
        local line=strtrim(rawLine)
        while line~="" do
            local piece=line
            if #piece>maxLen then local sp=piece:sub(1,maxLen):match(".*() "); local cut=(sp and sp>80) and sp or maxLen; piece=line:sub(1,cut); line=strtrim(line:sub(cut+1)) else line="" end
            if piece~="" then
                if C_ChatInfo and C_ChatInfo.SendChatMessage then pcall(C_ChatInfo.SendChatMessage,piece,channel) else pcall(SendChatMessage,piece,channel) end
                sent=sent+1
            end
        end
    end
    RRT_Print("Sent to "..channel.." ("..sent.." lines).")
end

-------------------------------------------------------------------------------
-- Draft helpers
-------------------------------------------------------------------------------

local function SwitchDraft(newIdx)
    local db=EnsureDB(); if not db then return end
    newIdx=Clamp(newIdx,1,TOTAL_DRAFTS); db.activeDraft=newIdx
    local draft=db.drafts and db.drafts[newIdx]
    if _titleEditor then _titleEditor:SetText((draft and draft.title) or "") end
    if _noteEditor  then _noteEditor:SetText((draft and draft.text)  or "") end
    if _draftDD     then _draftDD:Select(newIdx) end
    InvalidateCache(); RefreshWin()
end

-------------------------------------------------------------------------------
-- DF Widget helpers  (matching SpellTrackerFrames style)
-------------------------------------------------------------------------------

local function SkinPanel(frame)
    if not frame then return end
    if not frame.SetBackdrop then Mixin(frame, BackdropTemplateMixin) end
    frame:SetBackdrop({bgFile="Interface\\BUTTONS\\WHITE8X8",edgeFile="Interface\\BUTTONS\\WHITE8X8",edgeSize=1})
    frame:SetBackdropColor(unpack(COLOR_SECTION))
    frame:SetBackdropBorderColor(unpack(COLOR_BORDER))
end

local function MakeHeader(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    ApplyRRTFont(fs, 11)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText("|cffffcc00" .. text .. "|r")
    return y - 20
end

local function MakeLabel(parent, x, y, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(fs, 10)
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetText(text)
    return fs
end

local function MakeButton(parent, x, y, w, h, text, onClick)
    local btn = DF:CreateButton(parent, onClick, w, h or ROW_HEIGHT, text)
    btn:SetTemplate(options_button_template)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    return btn
end

-- Tiny raw button for the icon toolbar (20x20, WoW texture markup as label)
local function MakeIconBtn(parent, x, y, iconStr, token)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetPoint("TOPLEFT", x, y); btn:SetSize(ICON_SZ, ICON_SZ)
    local bg = btn:CreateTexture(nil,"BACKGROUND"); bg:SetAllPoints()
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8"); bg:SetVertexColor(unpack(COLOR_BTN))
    btn:SetScript("OnEnter", function() bg:SetVertexColor(unpack(COLOR_BTN_HOV))
        if token then GameTooltip:SetOwner(btn,"ANCHOR_TOP"); GameTooltip:SetText(token,1,1,1,1,true); GameTooltip:Show() end
    end)
    btn:SetScript("OnLeave", function() bg:SetVertexColor(unpack(COLOR_BTN)); GameTooltip:Hide() end)
    local fs = btn:CreateFontString(nil,"OVERLAY"); fs:SetFont(FONT,13,""); fs:SetPoint("CENTER"); fs:SetText(iconStr)
    btn:SetScript("OnClick", function() if _noteEditor then _noteEditor:Insert(token) end end)
    return btn
end

local function MakeSwitch(parent, x, y, width, labelText, getValue, setValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); row:SetSize(width, 22)
    local sw = DF:CreateSwitch(row, function(_, _, value)
        setValue(value and true or false)
    end, getValue() and true or false, 20, 20, nil, nil, nil, nil, nil, nil, nil, nil, options_switch_template)
    sw:SetAsCheckBox(); sw:SetPoint("LEFT", row, "LEFT", 0, 0)
    if sw.Text then sw.Text:SetText(""); sw.Text:Hide() end
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(lbl, 10); lbl:SetPoint("LEFT", row, "LEFT", 24, 0); lbl:SetPoint("RIGHT", row, "RIGHT", -2, 0)
    lbl:SetJustifyH("LEFT"); lbl:SetText(labelText)
    return y - 26, sw
end

local function MakeSlider(parent, x, y, width, labelText, minVal, maxVal, step, getValue, setValue)
    local row = CreateFrame("Frame", nil, parent)
    row:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); row:SetSize(width, 34)
    local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ApplyRRTFont(lbl, 10); lbl:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0); lbl:SetText(labelText)
    local slider = DF:CreateSlider(row, math.max(120, width - 8), 16, minVal, maxVal, step, minVal, false)
    slider:SetTemplate(options_slider_template); slider:SetPoint("TOPLEFT", row, "TOPLEFT", 0, -14)
    slider:SetValue(getValue()); slider:SetHook("OnValueChanged", function(_, _, value) setValue(value) end)
    return y - 38, slider
end

local function MakeScrollContent(parent)
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 0, 0); scroll:SetPoint("BOTTOMRIGHT", -20, 0)
    if apply_scrollbar_style then apply_scrollbar_style(scroll) else SkinScrollBar(scroll) end
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll(); local ch = self:GetScrollChild(); if not ch then return end
        local maxS = math.max(0, ch:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxS)))
    end)
    local c = CreateFrame("Frame", nil, scroll); c:SetWidth(FRAME_WIDTH); c:SetHeight(1200)
    scroll:SetScrollChild(c); return scroll, c
end

-------------------------------------------------------------------------------
-- BuildNoteUI
-------------------------------------------------------------------------------

local function BuildNoteUI(parent)
    EnsureTemplates()
    local db = EnsureDB()
    EnsureComm(); CreateWin(); UpdateAutoColors()

    local LEFT_W  = 490
    local RIGHT_X = LEFT_W + 14
    local RIGHT_W = FRAME_WIDTH - RIGHT_X - PADDING
    local PAD     = PADDING

    local scroll, content = MakeScrollContent(parent)

    -- Inner editor scroll (separate apply for DF skin later)
    local function ApplyEditorScrollSkin(sf)
        if apply_scrollbar_style then apply_scrollbar_style(sf) else SkinScrollBar(sf) end
    end

    local yOff = -8   -- left column
    local ry   = -8   -- right column

    ---------------------------------------------------------------------------
    -- LEFT: Draft selector
    ---------------------------------------------------------------------------
    ry = MakeHeader(content, RIGHT_X, ry, "Note")
    yOff = MakeHeader(content, PAD, yOff, "Draft")

    -- DF Dropdown (matches Sort Order style from Frames)
    MakeLabel(content, PAD, yOff, "Active Draft")
    yOff = yOff - 16

    local function BuildDraftValues()
        local vals = {}
        for i = 1, TOTAL_DRAFTS do
            local draft = db.drafts and db.drafts[i]
            local lbl = (draft and draft.title) or ("Draft "..i)
            table.insert(vals, { label=lbl, value=i, onclick=function(_,_,v) SwitchDraft(v) end })
        end
        return vals
    end

    local dd = DF:CreateDropDown(content, BuildDraftValues, nil, LEFT_W - 10)
    dd:SetTemplate(options_dropdown_template)
    dd:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, yOff)
    dd:Select(db.activeDraft)
    _draftDD = dd
    yOff = yOff - 30

    -- Draft action buttons
    local bw3 = math.floor((LEFT_W - 10) / 3)
    MakeButton(content, PAD, yOff, bw3, ROW_HEIGHT, "Undo", function()
        UndoHistory()
    end)
    MakeButton(content, PAD + bw3 + 5, yOff, bw3, ROW_HEIGHT, "Clear Draft", function()
        local draft = db.drafts and db.drafts[db.activeDraft or 1]
        if draft then PushHistory(); draft.text=""; if _noteEditor then _noteEditor:SetText("") end; InvalidateCache(); RefreshWin() end
    end)
    MakeButton(content, PAD + (bw3+5)*2, yOff, bw3, ROW_HEIGHT, "Save Draft", function()
        local draft = db.drafts and db.drafts[db.activeDraft or 1]; if not draft then return end
        PushHistory()
        if _noteEditor  then draft.text=_noteEditor:GetText() end
        if _titleEditor then local t=strtrim(_titleEditor:GetText()); if t~="" then draft.title=t end end
        if _draftDD then _draftDD:Select(db.activeDraft) end
        RRT_Print("Draft saved: "..(draft.title))
    end)
    yOff = yOff - ROW_HEIGHT - 8

    ---------------------------------------------------------------------------
    -- LEFT: Title (matches Frame Name style)
    ---------------------------------------------------------------------------
    MakeLabel(content, PAD, yOff, "Title")
    yOff = yOff - 16

    local titleEntry = DF:CreateTextEntry(content, function() end, LEFT_W, 20)
    titleEntry:SetPoint("TOPLEFT", content, "TOPLEFT", PAD, yOff)
    titleEntry:SetTemplate(options_dropdown_template)
    local d0 = db.drafts and db.drafts[db.activeDraft or 1]
    titleEntry:SetText((d0 and d0.title) or "")
    titleEntry:SetHook("OnEnterPressed", function(self)
        self:ClearFocus()
        local draft = db.drafts and db.drafts[db.activeDraft or 1]
        if draft then
            local t = strtrim(self:GetText()); if t~="" then draft.title=t end
            if _draftDD then _draftDD:Select(db.activeDraft) end
        end
    end)
    titleEntry:SetHook("OnEscapePressed", function(self) self:ClearFocus() end)
    _titleEditor = titleEntry
    yOff = yOff - 30

    ---------------------------------------------------------------------------
    -- LEFT: Icon toolbar
    ---------------------------------------------------------------------------
    MakeLabel(content, PAD, yOff, "Insert token:")
    yOff = yOff - 16

    -- Row 1: RT icons + roles
    local tx = PAD
    for i = 1, 8 do
        local tok = "{rt"..i.."}"
        MakeIconBtn(content, tx, yOff, ICON_MAP[tok] or tok, tok)
        tx = tx + ICON_SZ + 2
    end
    tx = tx + 6
    for _, tok in ipairs({"{tank}","{healer}","{dps}"}) do
        MakeIconBtn(content, tx, yOff, ICON_MAP[tok] or tok, tok)
        tx = tx + ICON_SZ + 2
    end
    yOff = yOff - ICON_SZ - 3

    -- Row 2: Class icons
    tx = PAD
    for _, tok in ipairs({"{war}","{pal}","{hun}","{rog}","{pri}","{dk}","{sham}","{mag}","{lock}","{mon}","{dru}","{dh}","{evo}"}) do
        MakeIconBtn(content, tx, yOff, ICON_MAP[tok] or tok, tok)
        tx = tx + ICON_SZ + 2
    end
    yOff = yOff - ICON_SZ - 3

    -- Row 3: Text token buttons (DF style)
    local textToks = {
        {"{self}","{self}"},  {"{D}","{D}"}, {"{H}","{H}"}, {"{T}","{T}"},
        {"{time:}","{time:0:00} "}, {"{p:}","{p:Name}"}, {"{c:}","{c:warrior}"},
    }
    tx = PAD
    for _, def in ipairs(textToks) do
        local lbl, tok = def[1], def[2]
        local w = math.max(40, #lbl * 7 + 10)
        MakeButton(content, tx, yOff, w, 22, lbl, function()
            if _noteEditor then _noteEditor:Insert(tok) end
        end)
        tx = tx + w + 4
    end
    yOff = yOff - 22 - 6

    ---------------------------------------------------------------------------
    -- LEFT: Editor
    ---------------------------------------------------------------------------
    local editorH = 330
    local edPanel = CreateFrame("Frame", nil, content, "BackdropTemplate")
    edPanel:SetPoint("TOPLEFT", PAD, yOff); edPanel:SetSize(LEFT_W, editorH); SkinPanel(edPanel)

    local edScroll = CreateFrame("ScrollFrame", nil, edPanel, "UIPanelScrollFrameTemplate")
    edScroll:SetPoint("TOPLEFT",6,-6); edScroll:SetPoint("BOTTOMRIGHT",-24,6)

    local editBox = CreateFrame("EditBox", nil, edScroll)
    editBox:SetMultiLine(true); editBox:SetAutoFocus(false); editBox:EnableMouse(true)
    if editBox.EnableKeyboard then editBox:EnableKeyboard(true) end
    editBox:SetWidth(LEFT_W - 36); editBox:SetHeight(editorH); editBox:SetMaxLetters(0)
    editBox:SetFont(FONT, 12, ""); editBox:SetTextInsets(2,2,2,2)
    editBox:SetJustifyH("LEFT"); editBox:SetJustifyV("TOP")
    local dInit = db.drafts and db.drafts[db.activeDraft or 1]
    editBox:SetText((dInit and dInit.text) or "")
    edPanel:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    edScroll:SetScript("OnMouseDown", function() editBox:SetFocus() end)
    editBox:SetScript("OnMouseDown",  function(self) self:SetFocus() end)
    editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    editBox:SetScript("OnCursorChanged", function(_, x, y, w, h)
        if ScrollFrame_OnCursorChanged then ScrollFrame_OnCursorChanged(edScroll, x, y, w, h) end
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)
        if not userInput then return end
        local draft = db.drafts and db.drafts[db.activeDraft or 1]
        if draft then draft.text=self:GetText(); InvalidateCache(); RefreshWin() end
    end)
    edScroll:SetScrollChild(editBox); ApplyEditorScrollSkin(edScroll)
    _noteEditor = editBox
    yOff = yOff - editorH - 6

    ---------------------------------------------------------------------------
    -- LEFT: Action buttons
    ---------------------------------------------------------------------------
    MakeButton(content, PAD, yOff, bw3, ROW_HEIGHT, "Send (Auto)", function()
        local draft=db.drafts and db.drafts[db.activeDraft or 1]; SendToChat((draft and draft.text) or "","AUTO",db)
    end)
    MakeButton(content, PAD+bw3+5, yOff, bw3, ROW_HEIGHT, "Send Raid Warn", function()
        local draft=db.drafts and db.drafts[db.activeDraft or 1]; SendToChat((draft and draft.text) or "","RAID_WARNING",db)
    end)
    MakeButton(content, PAD+(bw3+5)*2, yOff, bw3, ROW_HEIGHT, "Broadcast Note", function()
        BroadcastNote()
    end)
    yOff = yOff - ROW_HEIGHT - 4

    local timerBtnRef
    local function RefreshTimerBtn()
        local running = db.timerAnchor and db.timerAnchor > 0
        if timerBtnRef then timerBtnRef:SetText(running and "Reset Timer" or "Start Timer") end
    end
    timerBtnRef = MakeButton(content, PAD, yOff, bw3, ROW_HEIGHT, "Start Timer", function()
        if db.timerAnchor and db.timerAnchor>0 then ResetTimer() else StartTimer() end; RefreshTimerBtn()
    end)
    MakeButton(content, PAD+bw3+5, yOff, bw3, ROW_HEIGHT, "Show / Hide Window", function()
        ToggleWin()
    end)
    yOff = yOff - ROW_HEIGHT - PADDING

    ---------------------------------------------------------------------------
    -- RIGHT: Receive options
    ---------------------------------------------------------------------------
    ry = MakeHeader(content, RIGHT_X, ry, "Receive Options")
    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Accept notes only from leader / assist",
        function() return db.onlyPromoted end, function(v) db.onlyPromoted=v end)
    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Auto-show window when a note is received",
        function() return db.showOnReceive end, function(v) db.showOnReceive=v end)
    ry = ry - 6

    ---------------------------------------------------------------------------
    -- RIGHT: Window settings
    ---------------------------------------------------------------------------
    ry = MakeHeader(content, RIGHT_X, ry, "Display Window")

    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Always on top",
        function() return db.window.alwaysOnTop end,
        function(v) db.window.alwaysOnTop=v; ApplyWinSettings() end)
    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Lock window position",
        function() return db.window.locked end,
        function(v) db.window.locked=v; ApplyWinSettings() end)
    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Show title bar",
        function() return db.window.showTitleBar end,
        function(v) db.window.showTitleBar=v; ApplyWinSettings() end)
    ry, _ = MakeSwitch(content, RIGHT_X, ry, RIGHT_W, "Auto-hide out of combat",
        function() return db.window.autoHideOutOfCombat end,
        function(v) db.window.autoHideOutOfCombat=v; ApplyVisibilityState() end)
    ry = ry - 4

    -- Opacity (20-100 % mapped to 0.20-1.00)
    ry, _ = MakeSlider(content, RIGHT_X, ry, RIGHT_W, "Opacity (%)", 20, 100, 5,
        function() return math.floor((db.window.opacity or 0.78)*100+0.5) end,
        function(v) db.window.opacity=Clamp(v/100,0.20,1.00); ApplyWinSettings() end)

    -- Font size
    ry, _ = MakeSlider(content, RIGHT_X, ry, RIGHT_W, "Font size", 9, 24, 1,
        function() return math.floor(db.window.fontSize or 12) end,
        function(v) db.window.fontSize=math.floor(v); ApplyWinSettings(); RefreshWin() end)

    -- Scale (70-150 % mapped to 0.70-1.50)
    ry, _ = MakeSlider(content, RIGHT_X, ry, RIGHT_W, "Scale (%)", 70, 150, 5,
        function() return math.floor((db.window.scale or 1.0)*100+0.5) end,
        function(v) db.window.scale=Clamp(v/100,0.70,1.50); ApplyWinSettings() end)
    ry = ry - 4

    MakeButton(content, RIGHT_X, ry, RIGHT_W, ROW_HEIGHT, "Reset Window", function()
        local w=db.window; w.width=560; w.height=360; w.x=30; w.y=0
        w.point="LEFT"; w.relativePoint="LEFT"; w.opacity=0.78; w.fontSize=12; w.scale=1.0
        w.alwaysOnTop=false; w.locked=false; w.showTitleBar=true; w.autoHideOutOfCombat=false
        if _noteWindow then _noteWindow:ClearAllPoints(); _noteWindow:SetSize(560,360); _noteWindow:SetPoint("LEFT",UIParent,"LEFT",30,0) end
        ApplyWinSettings()
    end)
    ry = ry - ROW_HEIGHT - 8

    ---------------------------------------------------------------------------
    -- RIGHT: {self} config
    ---------------------------------------------------------------------------
    ry = MakeHeader(content, RIGHT_X, ry, "{self} Substitution")
    MakeLabel(content, RIGHT_X, ry, "Replaces {self} in notes")
    ry = ry - 18

    local selfEntry = DF:CreateTextEntry(content, function() end, RIGHT_W, 20)
    selfEntry:SetPoint("TOPLEFT", content, "TOPLEFT", RIGHT_X, ry)
    selfEntry:SetTemplate(options_dropdown_template)
    selfEntry:SetText(db.selfText or "")
    selfEntry:SetHook("OnTextChanged", function(self) db.selfText=self:GetText(); InvalidateCache(); RefreshWin() end)
    selfEntry:SetHook("OnEscapePressed", function(self) self:ClearFocus() end)
    ry = ry - 28

    ---------------------------------------------------------------------------
    -- RIGHT: Token reference
    ---------------------------------------------------------------------------
    ry = MakeHeader(content, RIGHT_X, ry, "Token Reference")
    local helpLines = {
        "|cffaaaaaa{self}|r = {self} text above",
        "|cffaaaaaa{p:Name}|r = class-colored name",
        "|cffaaaaaa{c:warrior}|r = all warriors",
        "|cffaaaaaa{classunique:mage}|r = first mage only",
        "|cffaaaaaa{g1}..{g8}|r = group N members",
        "|cffaaaaaa{race:Tauren}|r = players by race",
        "|cffaaaaaa{e:ID}|r = encounter name (EJ)",
        "|cffaaaaaa{spell:ID}|r = spell icon + name",
        "|cffaaaaaa{icon:path}|r = custom texture",
        "|cffaaaaaa{time:1:30} text|r = timer line",
        "|cffaaaaaa{rt1}..{rt8}|r = raid target icons",
        "|cffaaaaaa{tank} {healer} {dps}|r = role icons",
        "|cffaaaaaa{war} {pal}..{evo}|r = class icons",
        "|cffaaaaaa{D} {H} {T}|r = role icons (alt)",
        "|cffaaaaaa||cffRRGGBBtext|r|r = color code",
    }
    for _, line in ipairs(helpLines) do
        local fs = content:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        ApplyRRTFont(fs, 10)
        fs:SetPoint("TOPLEFT", content, "TOPLEFT", RIGHT_X, ry - 1)
        fs:SetTextColor(0.72, 0.72, 0.72); fs:SetText(line); fs:SetJustifyH("LEFT")
        ry = ry - 13
    end

    ---------------------------------------------------------------------------
    -- Finalize content height
    ---------------------------------------------------------------------------
    local totalH = math.max(math.abs(yOff), math.abs(ry)) + PADDING + 30
    content:SetHeight(totalH)
end

-------------------------------------------------------------------------------
-- Module-level events
-------------------------------------------------------------------------------

local _commFrame = CreateFrame("Frame")
_commFrame:RegisterEvent("CHAT_MSG_ADDON")
_commFrame:SetScript("OnEvent", HandleComm)

local _encounterFrame = CreateFrame("Frame")
_encounterFrame:RegisterEvent("ENCOUNTER_START")
_encounterFrame:SetScript("OnEvent", function(_, event)
    if event == "ENCOUNTER_START" then
        local db=EnsureDB(); if db then db.timerAnchor=GetTime(); InvalidateCache(); RefreshWin() end
    end
end)

local _combatFrame = CreateFrame("Frame")
_combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
_combatFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
_combatFrame:SetScript("OnEvent", function() ApplyVisibilityState() end)

local _rosterFrame = CreateFrame("Frame")
_rosterFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
_rosterFrame:SetScript("OnEvent", function() UpdateAutoColors(); InvalidateCache(); RefreshWin() end)

local _ticker = CreateFrame("Frame")
_ticker:SetScript("OnUpdate", function(_, elapsed)
    _tickerElapsed = _tickerElapsed + elapsed; if _tickerElapsed < 0.2 then return end; _tickerElapsed = 0
    if not _noteWindow or not _noteWindow:IsShown() then return end
    local db=EnsureDB(); if not db or not db.timerAnchor or db.timerAnchor<=0 then return end
    local draft=db.drafts and db.drafts[db.activeDraft or 1]; local rawText=(draft and draft.text) or ""
    local _, hasTimed=GetDisplayLines(rawText); if hasTimed then RefreshWin() end
end)

local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function(self)
    self:UnregisterAllEvents(); EnsureDB(); EnsureComm(); CreateWin(); UpdateAutoColors()
end)

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.SetupManager = RRT.UI.SetupManager or {}
RRT.UI.SetupManager.Note = { BuildUI = BuildNoteUI }
