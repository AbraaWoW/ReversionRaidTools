local _, RRT = ...
local DF = _G["DetailsFramework"]
local LibDeflate = (LibStub and LibStub("LibDeflate", true)) or nil

-- Templates resolved lazily (Core.lua may not be loaded yet at file scope)
local options_button_template
local options_dropdown_template
local options_text_template
local apply_scrollbar_style

local function EnsureTemplates()
    if options_button_template then return end
    local Core = RRT.UI and RRT.UI.Core
    if not Core then return end
    options_button_template   = Core.options_button_template
    options_dropdown_template = Core.options_dropdown_template
    options_text_template     = Core.options_text_template
    apply_scrollbar_style     = Core.apply_scrollbar_style
end

local function ApplyRRTFont(fs, size)
    if not fs then return end
    local fontName = (RRTDB and RRTDB.Settings and RRTDB.Settings.GlobalFont) or "Friz Quadrata TT"
    local fetched = RRT.LSM and RRT.LSM.Fetch and RRT.LSM:Fetch("font", fontName)
    if fetched then
        fs:SetFont(fetched, size or 10, "OUTLINE")
    else
        fs:SetFont("Fonts\\FRIZQT__.TTF", size or 10, "OUTLINE")
    end
end

-------------------------------------------------------------------------------
-- RaidGroups sub-tab
-- Plan 8 raid subgroups of 5 players, apply in-game, save named profiles.
-------------------------------------------------------------------------------

local NUM_GROUPS    = 8
local SLOTS_PER_GRP = 5
local NUM_SLOTS     = NUM_GROUPS * SLOTS_PER_GRP  -- 40

local COL_W    = 185
local COL_GAP  = 12
local PAIR_GAP = 12
local HDR_H    = 20
local SLOT_H   = 20
local SLOT_GAP = 2

local GX_LEFT  = 12
local GX_RIGHT = GX_LEFT + COL_W + COL_GAP
local BLOCK_H  = HDR_H + SLOTS_PER_GRP * (SLOT_H + SLOT_GAP)

local FONT         = "Fonts\\FRIZQT__.TTF"
local PADDING      = 12
local ROW_HEIGHT   = 26
local COLOR_ACCENT = { 1.00, 0.82, 0.00 }
local COLOR_LABEL  = { 0.92, 0.92, 0.92 }
local COLOR_MUTED  = { 0.72, 0.72, 0.72 }
local COLOR_BTN      = { 0.18, 0.18, 0.18, 1.0 }
local COLOR_BTN_HOVER= { 0.25, 0.25, 0.25, 1.0 }

local function RRT_Print(msg)
    print("|cFF33FF99[Reversion Raid Tools]|r " .. tostring(msg))
end

-------------------------------------------------------------------------------
-- DB
-------------------------------------------------------------------------------

local function EnsureDB()
    if not RRTDB then return nil end
    -- Canonical key is lowercase (matches Core defaults). Keep uppercase as alias for compatibility.
    if type(RRTDB.raidGroups) ~= "table" then
        if type(RRTDB.RaidGroups) == "table" then
            RRTDB.raidGroups = RRTDB.RaidGroups
        else
            RRTDB.raidGroups = {}
        end
    end
    RRTDB.RaidGroups = RRTDB.raidGroups

    RRTDB.raidGroups.profiles     = RRTDB.raidGroups.profiles or {}
    RRTDB.raidGroups.currentSlots = RRTDB.raidGroups.currentSlots or {}
    if type(RRTDB.raidGroups.splitGroups) ~= "table" then
        RRTDB.raidGroups.splitGroups = { true, true, true, true, true, true, true, true }
    end
    for i = 1, NUM_GROUPS do
        if RRTDB.raidGroups.splitGroups[i] == nil then
            RRTDB.raidGroups.splitGroups[i] = true
        end
    end
    if type(RRTDB.raidGroups.splitParts) ~= "number" then
        RRTDB.raidGroups.splitParts = 2
    end
    RRTDB.raidGroups.splitParts = math.max(1, math.min(NUM_GROUPS, math.floor(RRTDB.raidGroups.splitParts)))
    if type(RRTDB.raidGroups.splitRule) ~= "number" then
        RRTDB.raidGroups.splitRule = 1
    end
    if RRTDB.raidGroups.splitRule ~= 1 and RRTDB.raidGroups.splitRule ~= 2 then
        RRTDB.raidGroups.splitRule = 1
    end
    if RRTDB.raidGroups.unassignedSource ~= "guild" then
        RRTDB.raidGroups.unassignedSource = "raid"
    end
    return RRTDB.raidGroups
end

-------------------------------------------------------------------------------
-- Helpers
-------------------------------------------------------------------------------

local function SlotIdx(group, pos)
    return (group - 1) * SLOTS_PER_GRP + pos
end

local function Trim(s)
    if not s then return "" end
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function NormalizeNameToken(token)
    token = Trim((token or ""):gsub('"', ""))
    if token == "" or token == "-" then return nil end
    return token
end

local function SplitByTab(text)
    local out = {}
    local s   = text or ""
    local start = 1
    while true do
        local idx = string.find(s, "\t", start, true)
        if not idx then out[#out + 1] = string.sub(s, start); break end
        out[#out + 1] = string.sub(s, start, idx - 1)
        start = idx + 1
    end
    return out
end

local function CollectLines(text)
    local lines = {}
    if not text then return lines end
    text = text:gsub("\r\n", "\n"):gsub("\r", "\n")
    for raw in string.gmatch(text, "([^\n]*)\n?") do
        if raw == "" and #lines > 0 and lines[#lines] == "" then
            -- skip duplicate trailing empty
        else
            lines[#lines + 1] = Trim(raw)
        end
    end
    while #lines > 0 and lines[#lines] == "" do table.remove(lines, #lines) end
    return lines
end

local function ParseNamesFromLine(line)
    local names = {}
    for token in string.gmatch(line or "", "%S+") do
        local n = NormalizeNameToken(token)
        if n then names[#names + 1] = n end
    end
    return names
end

local function StringToText(str)
    if str:find("\n") then
        local n = 0
        if str:find("%]$") then
            n = n + 1
        end
        while str:find("%[" .. string.rep("=", n) .. "%[") or str:find("%]" .. string.rep("=", n) .. "%]") do
            n = n + 1
        end
        return "[" .. string.rep("=", n) .. "[" .. str .. "]" .. string.rep("=", n) .. "]", true
    else
        return "\"" .. str:gsub("\\", "\\\\"):gsub("\"", "\\\"") .. "\""
    end
end

local function IterateTable(t)
    local prev
    local index = 1
    local indexMax
    local function it()
        if not indexMax then
            local v = t[index]
            if v ~= nil then
                index = index + 1
                return index - 1, v, true
            else
                indexMax = index - 1
            end
        end
        local k, v = next(t, prev)
        prev = k
        while k and type(k) == "number" and k >= 1 and k <= indexMax do
            k, v = next(t, prev)
            prev = k
        end
        return k, v, false
    end
    return it
end

local function TableToText(t, out, visited)
    visited = visited or {}
    visited[t] = true
    out = out or {"{"}
    local ignoreIndex = false
    for k, v, isIndex in IterateTable(t) do
        local line = ""
        local ignore = true
        if type(v) == "boolean" or type(v) == "number" or type(v) == "string" or type(v) == "table" then
            ignore = false
        end
        if type(v) == "table" and visited[v] then
            ignore = true
        end
        if ignore then
            ignoreIndex = true
        elseif isIndex and not ignoreIndex then
            -- implicit array index
        elseif type(k) == "number" then
            line = line .. "[" .. k .. "]="
        elseif type(k) == "string" then
            if k:match("[A-Za-z_][A-Za-z_0-9]*") == k then
                line = line .. k .. "="
            else
                local kstr, ismultiline = StringToText(k)
                line = line .. "[" .. (ismultiline and " " or "") .. kstr .. (ismultiline and " " or "") .. "]="
            end
        elseif type(k) == "boolean" then
            line = line .. "[" .. (k and "true" or "false") .. "]="
        else
            ignore = true
        end
        if not ignore then
            local tableToExplore
            if type(v) == "number" then
                line = line .. v .. ","
            elseif type(v) == "string" then
                line = line .. StringToText(v) .. ","
            elseif type(v) == "boolean" then
                line = line .. (v and "true" or "false") .. ","
            elseif type(v) == "table" then
                line = line .. "{"
                tableToExplore = v
            end
            out[#out + 1] = line
            if tableToExplore then
                TableToText(tableToExplore, out, visited)
                out[#out] = out[#out] .. ","
            end
        end
    end
    out[#out] = out[#out]:gsub(",$", "")
    out[#out + 1] = "}"
    return out
end

local function TextToTable(str, map, offset)
    if not map and string.byte(str, 1) == 123 then
        str = str:sub(2, -2)
    end
    local strlen = str:len()
    local i = 1
    local prev = 1
    map = map or {}
    offset = offset or 0

    local inTable, inString, inWideString
    local startTable, wideStringEqCount = 1, 0

    while i <= strlen do
        local b1 = string.byte(str, i)
        if not inString and not inTable and b1 == 123 then
            inTable = 0
            startTable = i
        elseif not inString and inTable and b1 == 123 then
            inTable = inTable + 1
        elseif not inString and inTable and b1 == 125 then
            if inTable == 0 then
                map[startTable + offset] = i + offset
                map[startTable + 0.5 + offset] = 1
                inTable = false
            else
                inTable = inTable - 1
            end
        elseif not inString and b1 == 34 then
            if map[i + offset + 0.5] == 2 then
                i = map[i + offset] - offset
            else
                inString = i
            end
        elseif inString and not inWideString and b1 == 92 then
            i = i + 1
        elseif inString and not inWideString and b1 == 34 then
            map[inString + offset] = i + offset
            map[inString + 0.5 + offset] = 2
            inString = false
        elseif not inString and b1 == 91 then
            if map[i + offset + 0.5] == 3 then
                i = map[i + offset] - offset
            else
                local k = i + 1
                local eqc = 0
                while k <= strlen do
                    local c1 = string.byte(str, k)
                    if c1 == 61 then
                        eqc = eqc + 1
                    elseif c1 == b1 then
                        inString = i
                        inWideString = i
                        i = k
                        wideStringEqCount = eqc
                        break
                    else
                        break
                    end
                    k = k + 1
                end
            end
        elseif inString and inWideString and b1 == 93 then
            local k = i + 1
            local eqc = 0
            while k <= strlen do
                local c1 = string.byte(str, k)
                if c1 == 61 then
                    eqc = eqc + 1
                elseif c1 == b1 then
                    if eqc == wideStringEqCount then
                        i = k
                        map[inWideString + offset] = i + offset
                        map[inWideString + 0.5 + offset] = 3
                        inString = false
                        inWideString = false
                    end
                    break
                else
                    break
                end
                k = k + 1
            end
        end
        if not inString and not inTable and (b1 == 44 or i == strlen) then
            map[-prev - offset] = i - (b1 == 44 and 1 or 0) + offset
            prev = i + 1
        end
        i = i + 1
    end

    local res = {}
    local numKey = 1
    i = 1
    while i <= strlen do
        if map[-i - offset] then
            local s, e = i, map[-i - offset] - offset
            local k = s
            local key, value
            local isError
            prev = k
            while k <= e do
                if map[k + offset] then
                    if map[k + 0.5 + offset] == 1 then
                        value = TextToTable(str:sub(k + 1, map[k + offset] - offset - 1), map, k + offset)
                    elseif map[k + 0.5 + offset] == 2 then
                        value = str:sub(k + 1, map[k + offset] - offset - 1):gsub("\\\"", "\""):gsub("\\\\", "\\")
                    elseif map[k + 0.5 + offset] == 3 then
                        value = str:sub(k, map[k + offset] - offset):gsub("^%[=*%[", ""):gsub("%]=*%]$", "")
                    end
                    k = map[k + offset] + 1 - offset
                else
                    local b1 = string.byte(str, k)
                    if b1 == 61 then
                        if value then
                            key = value
                            value = nil
                        else
                            key = str:sub(prev, k - 1):gsub("^%s+", ""):gsub("%s+$", "")
                            if key:find("^%[") and key:find("%]$") then
                                key = key:gsub("^%[", ""):gsub("%]$", "")
                                if tonumber(key) then
                                    key = tonumber(key)
                                end
                            elseif key == "true" then
                                key = true
                            elseif key == "false" then
                                key = false
                            elseif tonumber(key) then
                                key = tonumber(key)
                            else
                                key = key:match("[A-Za-z_][A-Za-z_0-9]*")
                            end
                            if not key then
                                isError = true
                                break
                            end
                        end
                        prev = k + 1
                    elseif k == e and not value then
                        value = str:sub(prev, k):gsub("^%s+", ""):gsub("%s+$", "")
                        if value == "true" then
                            value = true
                        elseif value == "false" then
                            value = false
                        else
                            value = tonumber(value)
                        end
                    end
                    k = k + 1
                end
            end
            if not isError then
                if not key then
                    key = numKey
                    numKey = numKey + 1
                end
                res[key] = value
            end
            i = map[-i - offset] - offset
        end
        i = i + 1
    end
    return res
end

local function ShortName(name)
    if not name then return nil end
    return name:match("^(.-)%-") or name
end

local function GetClassColor(class)
    local tbl = CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS
    if tbl and class and tbl[class] then
        local c = tbl[class]; return c.r, c.g, c.b
    end
    return 0.7, 0.7, 0.7
end

local function NameColor(name)
    if not name or name == "" then return 0.5, 0.5, 0.5 end
    local _, class = UnitClass(name)
    if class then return GetClassColor(class) end
    return 0.7, 0.7, 0.7
end

local function GetUnassigned(slots, source)
    local inGrid = {}
    for i = 1, NUM_SLOTS do
        local n = slots[i]
        if n and n ~= "" then
            inGrid[n] = true
            inGrid[ShortName(n)] = true
        end
    end
    local result = {}
    if source == "guild" then
        if IsInGuild and IsInGuild() then
            local num = GetNumGuildMembers and GetNumGuildMembers() or 0
            for i = 1, num do
                local name = GetGuildRosterInfo and GetGuildRosterInfo(i)
                local short = ShortName(name)
                if short and not inGrid[name] and not inGrid[short] then
                    table.insert(result, short)
                end
            end
        end
    else
        if not IsInGroup() then return result end
        for i = 1, GetNumGroupMembers() do
            local name = GetRaidRosterInfo(i)
            if name and not inGrid[name] and not inGrid[ShortName(name)] then
                table.insert(result, name)
            end
        end
    end
    return result
end

local function BuildExportString(slots)
    local parts = {}
    for i = 1, NUM_SLOTS do parts[i] = slots[i] or "" end
    return "RRT_RG1:" .. table.concat(parts, "\t")
end

local function BuildPackedExportString(slots)
    if not LibDeflate then
        return nil, "LibDeflate not available."
    end
    local payload = {}
    for i = 1, NUM_SLOTS do
        local name = slots[i]
        if name and name ~= "" then
            payload[i] = name
        end
    end
    local str = "0," .. table.concat(TableToText(payload))
    local compressed
    if #str < 1000000 then
        compressed = LibDeflate:CompressDeflate(str, { level = 5 })
    end
    return "RRTRGR" .. (compressed and "1" or "0") .. LibDeflate:EncodeForPrint(compressed or str)
end

local function ParsePackedExportString(raw)
    if not LibDeflate then
        return nil, "LibDeflate not available."
    end

    local headerLen = 7
    local header = raw:sub(1, headerLen)
    local prefix = header:sub(1, headerLen - 1)
    local mode = header:sub(headerLen, headerLen)
    if prefix ~= "RRTRGR" or (mode ~= "0" and mode ~= "1") then
        return nil, "Invalid packed string header."
    end

    local encodedPayload = raw:sub(headerLen + 1)
    local decoded = LibDeflate:DecodeForPrint(encodedPayload)
    if not decoded then
        return nil, "Failed to decode packed payload."
    end

    local decompressed
    if mode == "0" then
        decompressed = decoded
    else
        decompressed = LibDeflate:DecompressDeflate(decoded)
    end
    if not decompressed then
        return nil, "Failed to unpack packed payload."
    end

    local _, tableData = strsplit(",", decompressed, 2)
    tableData = tableData or decompressed
    local ok, parsed = pcall(TextToTable, tableData)
    if not ok or type(parsed) ~= "table" then
        return nil, "Failed to parse packed table."
    end

    local out = {}
    for i = 1, NUM_SLOTS do
        out[i] = NormalizeNameToken(parsed[i])
    end
    return out
end

local function ParseImportedSlots(text)
    if not text or Trim(text) == "" then return nil, "Import text is empty." end
    local raw = Trim(text)

    if raw:sub(1, 6) == "RRTRGR" then
        return ParsePackedExportString(raw)
    end

    if string.sub(raw, 1, 8) == "RRT_RG1:" or string.sub(raw, 1, 8) == "ART_RG1:" then
        local payload = string.sub(raw, 9)
        local fields  = SplitByTab(payload)
        local out = {}
        for i = 1, NUM_SLOTS do out[i] = NormalizeNameToken(fields[i]) end
        return out
    end

    local lines = CollectLines(raw)
    if #lines == 0 then return nil, "No valid lines found." end
    local out = {}

    if #lines == 40 then
        local idx = 1
        for g = 1, NUM_GROUPS do
            for p = 1, SLOTS_PER_GRP do
                out[SlotIdx(g, p)] = NormalizeNameToken(lines[idx]); idx = idx + 1
            end
        end
        return out
    end
    if #lines == 20 then
        for i = 1, 20 do
            local pair  = math.floor((i - 1) / SLOTS_PER_GRP)
            local row   = ((i - 1) % SLOTS_PER_GRP) + 1
            local g1    = pair * 2 + 1
            local names = ParseNamesFromLine(lines[i])
            out[SlotIdx(g1, row)]     = names[1]
            out[SlotIdx(g1 + 1, row)] = names[2]
        end
        return out
    end
    if #lines == 5 then
        for row = 1, 5 do
            local names = ParseNamesFromLine(lines[row])
            for g = 1, NUM_GROUPS do out[SlotIdx(g, row)] = names[g] end
        end
        return out
    end
    if #lines == 8 then
        for g = 1, NUM_GROUPS do
            local names = ParseNamesFromLine(lines[g])
            for p = 1, SLOTS_PER_GRP do out[SlotIdx(g, p)] = names[p] end
        end
        return out
    end

    return nil, "Unsupported format. Use RRT_RG1/ART_RG1/RRTRGR, 40/20/5/8-line text."
end

-------------------------------------------------------------------------------
-- Apply logic
-------------------------------------------------------------------------------

local _applyData  = nil
local _applyTimer = nil
local applyFrame  = CreateFrame("Frame")

local function FinishApply(ok)
    _applyData = nil
    applyFrame:UnregisterEvent("GROUP_ROSTER_UPDATE")
    if ok then RRT_Print("Raid groups applied.") end
end

local function ProcessRoster()
    if not _applyData then return end

    for i = 1, 40 do
        if UnitAffectingCombat("raid" .. i) then
            RRT_Print("Cannot apply groups: players are in combat.")
            FinishApply(false); return
        end
    end

    local needGroup = _applyData.needGroup
    local currentGroup, nameToID, groupSize = {}, {}, {}
    for i = 1, NUM_GROUPS do groupSize[i] = 0 end

    for i = 1, GetNumGroupMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name then
            local key = needGroup[name] and name or ShortName(name)
            currentGroup[key] = subgroup
            nameToID[key]     = i
            groupSize[subgroup] = groupSize[subgroup] + 1
        end
    end

    if not _applyData.groupsReady then
        local moved = false
        for name, tg in pairs(needGroup) do
            if currentGroup[name] and currentGroup[name] ~= tg then
                if groupSize[tg] < SLOTS_PER_GRP then
                    SetRaidSubgroup(nameToID[name], tg)
                    groupSize[currentGroup[name]] = groupSize[currentGroup[name]] - 1
                    groupSize[tg]                 = groupSize[tg] + 1
                    moved = true
                end
            end
        end
        if moved then return end

        local swapDone, swapped = {}, false
        for name, tg in pairs(needGroup) do
            if not swapDone[name] and currentGroup[name] and currentGroup[name] ~= tg then
                for name2, tg2 in pairs(needGroup) do
                    if not swapDone[name2] and name2 ~= name
                        and currentGroup[name2] == tg and tg2 ~= tg then
                        SwapRaidSubgroup(nameToID[name], nameToID[name2])
                        swapDone[name] = true; swapDone[name2] = true
                        swapped = true; break
                    end
                end
            end
        end
        if swapped then return end
        _applyData.groupsReady = true
    end

    FinishApply(true)
end

applyFrame:SetScript("OnEvent", function(self, event)
    if event == "GROUP_ROSTER_UPDATE" then
        if _applyTimer then _applyTimer:Cancel() end
        _applyTimer = C_Timer.NewTimer(0.5, function()
            _applyTimer = nil; ProcessRoster()
        end)
    end
end)

local function ApplyRaidGroups(slots)
    if not IsInRaid() then RRT_Print("You must be in a raid to apply groups."); return end
    if not UnitIsGroupLeader("player") and not UnitIsGroupAssistant("player") then
        RRT_Print("You must be raid leader or assistant to apply groups.")
        return
    end
    for i = 1, 40 do
        if UnitAffectingCombat("raid" .. i) then
            RRT_Print("Cannot apply groups: players are in combat."); return
        end
    end

    local needGroup = {}
    for g = 1, NUM_GROUPS do
        for p = 1, SLOTS_PER_GRP do
            local name = slots[SlotIdx(g, p)]
            if name and name ~= "" then needGroup[name] = g end
        end
    end

    _applyData = { needGroup = needGroup, groupsReady = false }
    applyFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    ProcessRoster()
end

-------------------------------------------------------------------------------
-- Widget helpers
-------------------------------------------------------------------------------

local function SkinButton(btn, color, hoverColor)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\BUTTONS\\WHITE8X8")
    bg:SetVertexColor(unpack(color or COLOR_BTN))
    btn._bg = bg
    btn:SetScript("OnEnter", function(self)
        self._bg:SetVertexColor(unpack(hoverColor or COLOR_BTN_HOVER))
    end)
    btn:SetScript("OnLeave", function(self)
        self._bg:SetVertexColor(unpack(color or COLOR_BTN))
    end)
end

local function CreateActionButton(parent, xOff, yOff, text, width, onClick)
    EnsureTemplates()

    local btn
    if DF and DF.CreateButton then
        btn = DF:CreateButton(parent, onClick, width, ROW_HEIGHT, text)
        if options_button_template then
            btn:SetTemplate(options_button_template)
        else
            local btnFrame = btn.widget or btn
            SkinButton(btnFrame)
        end
        if btn.SetPoint then
            btn:SetPoint("TOPLEFT", xOff, yOff)
        else
            local btnFrame = btn.widget or btn
            if btnFrame and btnFrame.SetPoint then
                btnFrame:SetPoint("TOPLEFT", xOff, yOff)
            end
        end
        if btn.SetTextColor then
            btn:SetTextColor(unpack(COLOR_LABEL))
        end
    else
        btn = CreateFrame("Button", nil, parent)
        btn:SetPoint("TOPLEFT", xOff, yOff)
        btn:SetSize(width, ROW_HEIGHT)
        SkinButton(btn)
        local lbl = btn:CreateFontString(nil, "OVERLAY")
        lbl:SetFont(FONT, 11)
        lbl:SetPoint("CENTER", 0, 0)
        lbl:SetTextColor(unpack(COLOR_LABEL))
        lbl:SetText(text)
        btn:SetScript("OnClick", onClick)
    end

    return btn
end

-------------------------------------------------------------------------------
-- UI builder
-------------------------------------------------------------------------------

local function BuildRaidGroupsUI(parent)
    EnsureTemplates()
    local rg = EnsureDB()
    if not rg then return end
    local slots = rg.currentSlots

    -- Scroll content
    local scroll = CreateFrame("ScrollFrame", nil, parent, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT",     parent, "TOPLEFT",     0,   0)
    scroll:SetPoint("BOTTOMRIGHT", parent, "BOTTOMRIGHT", -20, 0)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetWidth(820)
    content:SetHeight(980)
    scroll:SetScrollChild(content)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local maxScroll = math.max(0, content:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(cur - (delta * 20), maxScroll)))
    end)
    if apply_scrollbar_style then
        apply_scrollbar_style(scroll)
    elseif DF and DF.ReskinSlider then
        DF:ReskinSlider(scroll)
    end

    local yOff = -10

    -- Page visual container (aligns with options pages)
    local pageBg = CreateFrame("Frame", nil, content)
    pageBg:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    pageBg:SetSize(800, 900)
    -- Keep this sizing frame but without backdrop to remove the gray background.
    pageBg:SetFrameLevel(content:GetFrameLevel())

    local slotEdits = {}
    local slotFrames = {}
    local unassignRows = {}

    local function FindHoveredSlotIdx(excludeIdx)
        for i = 1, NUM_SLOTS do
            if i ~= excludeIdx then
                local f = slotFrames[i]
                if f and f:IsShown() and f:IsMouseOver() then
                    return i
                end
            end
        end
        return nil
    end

    local function SetSlotValue(idx, value)
        local v = NormalizeNameToken(value)
        slots[idx] = v
        local eb = slotEdits[idx]
        if eb then
            local text = v or ""
            eb:SetText(text)
            local r, g, b = NameColor(text)
            eb:SetTextColor(r, g, b, 1)
        end
    end

    local function RefreshColors()
        for i = 1, NUM_SLOTS do
            local eb = slotEdits[i]
            if eb then
                local r, g, b = NameColor(eb:GetText())
                eb:SetTextColor(r, g, b, 1)
            end
        end
    end

    local function RefreshUnassigned()
        local unassigned = GetUnassigned(slots, rg.unassignedSource)
        for i, row in ipairs(unassignRows) do
            local name = unassigned[i]
            if name then
                local short = ShortName(name)
                local r, g, b = NameColor(name)
                row.name = short
                row.label:SetText(short)
                row.label:SetTextColor(r, g, b, 1)
                row:Show()
            else
                row.name = nil
                row:Hide()
            end
        end
    end

    local function ApplySlotsToEditor(srcSlots)
        for i = 1, NUM_SLOTS do
            local v = srcSlots[i]
            SetSlotValue(i, (v and v ~= "") and v or nil)
        end
        RefreshUnassigned()
    end

    local function OnSlotChanged(self)
        local idx  = self.slotIdx
        local text = Trim(self:GetText())
        slots[idx] = NormalizeNameToken(text)
        local r, g, b = NameColor(text)
        self:SetTextColor(r, g, b, 1)
        RefreshUnassigned()
    end

    local function MakeSlotEditBox(group, pos, baseX, baseY)
        local idx  = SlotIdx(group, pos)
        local ySlot = baseY - HDR_H - (pos - 1) * (SLOT_H + SLOT_GAP)

        local container = CreateFrame("Frame", nil, content)
        container:SetSize(COL_W, SLOT_H)
        container:SetPoint("TOPLEFT", baseX, ySlot)

        local eb = CreateFrame("EditBox", nil, container)
        eb:SetPoint("TOPLEFT", 0, 0)
        eb:SetPoint("BOTTOMRIGHT", 0, 0)
        eb:SetAutoFocus(false)
        if eb.SetFontObject and ChatFontNormal then eb:SetFontObject(ChatFontNormal) end
        eb:SetMaxLetters(64)
        eb:SetTextInsets(2, 2, 0, 0)
        eb:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        eb:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
        if options_dropdown_template and eb.SetTemplate then
            eb:SetTemplate(options_dropdown_template)
        elseif options_button_template and eb.SetTemplate then
            eb:SetTemplate(options_button_template)
        end

        local saved = slots[idx]
        if saved and saved ~= "" then
            eb:SetText(saved)
            local r, g, b = NameColor(saved)
            eb:SetTextColor(r, g, b, 1)
        else
            eb:SetText("")
            eb:SetTextColor(0.55, 0.55, 0.55, 1)
        end

        eb.slotIdx = idx
        eb:SetScript("OnTextChanged", OnSlotChanged)
        slotEdits[idx] = eb
        slotFrames[idx] = container

        local function HandleSlotDragStop(self)
            local fromIdx = self.slotIdx
            local toIdx = FindHoveredSlotIdx(fromIdx)
            if toIdx and toIdx ~= fromIdx then
                local a = slots[fromIdx]
                local b = slots[toIdx]
                SetSlotValue(fromIdx, b)
                SetSlotValue(toIdx, a)
                RefreshUnassigned()
            end
        end

        container.slotIdx = idx
        container:EnableMouse(true)
        container:RegisterForDrag("LeftButton")
        container:SetScript("OnDragStart", function() end)
        container:SetScript("OnDragStop", HandleSlotDragStop)

        -- Allow dragging directly from the name field itself (MRT-like behavior).
        eb:EnableMouse(true)
        eb:RegisterForDrag("LeftButton")
        eb:SetScript("OnDragStart", function()
            -- Keep slot fixed; swap is handled on drag stop based on hovered target.
        end)
        eb:SetScript("OnDragStop", function()
            HandleSlotDragStop(container)
        end)
        return container
    end

    local function MakeGroupBlock(group, bx, by)
        local hdr = content:CreateFontString(nil, "OVERLAY")
        ApplyRRTFont(hdr, 11)
        hdr:SetPoint("TOPLEFT", bx, by)
        hdr:SetTextColor(unpack(COLOR_ACCENT))
        hdr:SetText("Group " .. group)
        for pos = 1, SLOTS_PER_GRP do
            MakeSlotEditBox(group, pos, bx, by)
        end
    end

    -- Grid: 4 rows of 2 groups each
    local gridTop = yOff
    for pair = 0, 3 do
        local gLeft  = pair * 2 + 1
        local gRight = pair * 2 + 2
        local pairY  = gridTop - pair * (BLOCK_H + PAIR_GAP)
        MakeGroupBlock(gLeft,  GX_LEFT,  pairY)
        MakeGroupBlock(gRight, GX_RIGHT, pairY)
    end
    local gridBottom = gridTop - 4 * (BLOCK_H + PAIR_GAP) + PAIR_GAP

    -- Unassigned panel
    local sidebarX = GX_RIGHT + COL_W + 20
    local unassignX = sidebarX
    local unassignTop = gridTop
    local unassignHeaderY = unassignTop - 38
    local uHdr = content:CreateFontString(nil, "OVERLAY")
    ApplyRRTFont(uHdr, 11)
    uHdr:SetPoint("TOPLEFT", unassignX, unassignHeaderY)
    uHdr:SetTextColor(unpack(COLOR_MUTED))
    uHdr:SetText("Not assigned:")

    local sourceRaidBtn
    local sourceGuildBtn
    local function RefreshUnassignedSourceButtons()
        if sourceRaidBtn and sourceRaidBtn.SetTextColor then
            local active = rg.unassignedSource == "raid"
            sourceRaidBtn:SetTextColor(active and 0.2 or 0.9, active and 1.0 or 0.9, active and 0.2 or 0.9, 1.0)
        end
        if sourceGuildBtn and sourceGuildBtn.SetTextColor then
            local active = rg.unassignedSource == "guild"
            sourceGuildBtn:SetTextColor(active and 0.2 or 0.9, active and 1.0 or 0.9, active and 0.2 or 0.9, 1.0)
        end
    end

    sourceRaidBtn = CreateActionButton(content, unassignX, unassignTop + 3, "Raid", 44, function()
        rg.unassignedSource = "raid"
        RefreshUnassignedSourceButtons()
        RefreshUnassigned()
    end)
    sourceGuildBtn = CreateActionButton(content, unassignX + 48, unassignTop + 3, "Guild", 50, function()
        rg.unassignedSource = "guild"
        if C_GuildInfo and C_GuildInfo.GuildRoster then
            C_GuildInfo.GuildRoster()
        end
        RefreshUnassignedSourceButtons()
        RefreshUnassigned()
    end)
    RefreshUnassignedSourceButtons()

    for i = 1, 40 do
        local row = CreateFrame("Button", nil, content)
        row:SetSize(160, 14)
        local defaultY = unassignHeaderY - HDR_H - (i - 1) * 16
        row:SetPoint("TOPLEFT", unassignX + 4, defaultY)
        row.defaultY = defaultY
        row:Hide()
        row:SetMovable(true)
        row:EnableMouse(true)
        row:RegisterForDrag("LeftButton")
        row:SetClampedToScreen(true)
        row._origStrata = row:GetFrameStrata()
        row._origLevel = row:GetFrameLevel()

        local lbl = row:CreateFontString(nil, "OVERLAY")
        ApplyRRTFont(lbl, 10)
        lbl:SetPoint("LEFT", row, "LEFT", 2, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetText("")
        row.label = lbl

        row:SetScript("OnDragStart", function(self)
            if not self.name then return end
            self:SetFrameStrata("TOOLTIP")
            self:SetFrameLevel(200)
            self:StartMoving()
        end)
        row:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            if self.name then
                local targetIdx = FindHoveredSlotIdx(nil)
                if targetIdx then
                    SetSlotValue(targetIdx, self.name)
                    RefreshUnassigned()
                end
            end
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", unassignX + 4, self.defaultY)
            self:SetFrameStrata(self._origStrata or "MEDIUM")
            self:SetFrameLevel(self._origLevel or 1)
        end)

        unassignRows[i] = row
    end
    RefreshUnassigned()

    -- Profiles panel
    local profX = sidebarX + 175
    local profY = gridTop

    local profHdr
    if DF and DF.CreateLabel then
        profHdr = DF:CreateLabel(content, "Saved Profiles", 9.5, "white")
        if profHdr.SetTemplate and options_text_template then
            profHdr:SetTemplate(options_text_template)
        end
    else
        profHdr = content:CreateFontString(nil, "OVERLAY")
        ApplyRRTFont(profHdr, 10)
        profHdr:SetTextColor(1, 1, 1, 1)
        profHdr:SetText("Saved Profiles")
    end
    profHdr:SetPoint("TOPLEFT", profX, profY)
    profY = profY - 22

    local saveContainer = CreateFrame("Frame", nil, content)
    saveContainer:SetSize(120, 22)
    saveContainer:SetPoint("TOPLEFT", profX, profY)

    local nameInput = CreateFrame("EditBox", nil, saveContainer)
    nameInput:SetPoint("TOPLEFT", 0, 0)
    nameInput:SetPoint("BOTTOMRIGHT", 0, 0)
    nameInput:SetAutoFocus(false)
    if nameInput.SetFontObject and ChatFontNormal then nameInput:SetFontObject(ChatFontNormal) end
    nameInput:SetMaxLetters(40)
    nameInput:SetTextInsets(2, 2, 0, 0)
    nameInput:SetTextColor(0.85, 0.85, 0.85, 1)
    nameInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    nameInput:SetScript("OnEnterPressed",  function(self) self:ClearFocus() end)
    if options_dropdown_template and nameInput.SetTemplate then
        nameInput:SetTemplate(options_dropdown_template)
    elseif options_button_template and nameInput.SetTemplate then
        nameInput:SetTemplate(options_button_template)
    end

    local selectedProfileName
    local profileDropdown

    local saveBtn = CreateActionButton(content, profX + 124, profY, "Save", 50, function()
        local name = Trim(nameInput:GetText())
        if not name or name == "" then RRT_Print("Enter a profile name first."); return end

        local snapshot = {}
        for i = 1, NUM_SLOTS do snapshot[i] = slots[i] end

        local replaced = false
        for i = 1, #rg.profiles do
            if rg.profiles[i].name == name then
                rg.profiles[i].slots   = snapshot
                rg.profiles[i].savedAt = time()
                replaced = true; break
            end
        end
        if not replaced then
            table.insert(rg.profiles, { name = name, slots = snapshot, savedAt = time() })
        end

        selectedProfileName = name
        if profileDropdown and profileDropdown.Refresh then
            profileDropdown:Refresh()
            if profileDropdown.Select then
                profileDropdown:Select(name)
            end
        end
        RRT_Print(replaced and ("Profile updated: " .. name) or ("Profile saved: " .. name))
    end)

    profY = profY - 28

    local function FindProfileIndexByName(name)
        if not name or name == "" then return nil end
        for i = 1, #rg.profiles do
            if rg.profiles[i].name == name then
                return i
            end
        end
        return nil
    end

    local function BuildProfileDropdownOptions()
        local opts = {}
        for i = 1, #rg.profiles do
            local prof = rg.profiles[i]
            opts[#opts + 1] = {
                label = prof.name,
                value = prof.name,
                onclick = function(_, _, value)
                    selectedProfileName = value
                    nameInput:SetText(value or "")
                end,
            }
        end
        if #opts == 0 then
            opts[#opts + 1] = {
                label = "(No profiles)",
                value = nil,
                onclick = function()
                    selectedProfileName = nil
                end,
            }
        end
        return opts
    end

    if DF and DF.CreateDropDown then
        profileDropdown = DF:CreateDropDown(content, BuildProfileDropdownOptions, nil, 228)
        if profileDropdown.SetTemplate and options_dropdown_template then
            profileDropdown:SetTemplate(options_dropdown_template)
        end
        profileDropdown:SetPoint("TOPLEFT", profX, profY)
    end

    local loadSelectedBtn = CreateActionButton(content, profX, profY - 28, "Load", 70, function()
        local idx = FindProfileIndexByName(selectedProfileName or Trim(nameInput:GetText()))
        if not idx then
            RRT_Print("Select a profile first.")
            return
        end
        local prof = rg.profiles[idx]
        selectedProfileName = prof.name
        nameInput:SetText(prof.name)
        ApplySlotsToEditor(prof.slots or {})
    end)

    local deleteSelectedBtn = CreateActionButton(content, profX + 76, profY - 28, "Delete", 70, function()
        local idx = FindProfileIndexByName(selectedProfileName or Trim(nameInput:GetText()))
        if not idx then
            RRT_Print("Select a profile first.")
            return
        end
        local name = rg.profiles[idx].name
        table.remove(rg.profiles, idx)
        selectedProfileName = nil
        nameInput:SetText("")
        if profileDropdown and profileDropdown.Refresh then
            profileDropdown:Refresh()
        end
        RRT_Print("Profile deleted: " .. name)
    end)

    if profileDropdown and profileDropdown.Refresh then
        profileDropdown:Refresh()
        if #rg.profiles > 0 then
            selectedProfileName = rg.profiles[1].name
            nameInput:SetText(selectedProfileName)
            if profileDropdown.Select then
                profileDropdown:Select(selectedProfileName)
            end
        end
    end

    profY = profY - 58

    -- Import / Export
    local ioTopY = profY - 8

    local ioHdr = content:CreateFontString(nil, "OVERLAY")
    ApplyRRTFont(ioHdr, 11)
    ioHdr:SetPoint("TOPLEFT", profX, ioTopY)
    ioHdr:SetTextColor(unpack(COLOR_MUTED))
    ioHdr:SetText("Import / Export")

    local ioBox = CreateFrame("Frame", nil, content)
    ioBox:SetSize(250, 72)
    ioBox:SetPoint("TOPLEFT", profX, ioTopY - 16)

    local ioEdit = CreateFrame("EditBox", nil, ioBox)
    ioEdit:SetMultiLine(true)
    ioEdit:SetPoint("TOPLEFT", 0, 0)
    ioEdit:SetPoint("BOTTOMRIGHT", 0, 0)
    ioEdit:SetAutoFocus(false)
    ioEdit:EnableMouse(true)
    if ioEdit.EnableKeyboard then ioEdit:EnableKeyboard(true) end
    if ioEdit.SetFontObject and ChatFontNormal then ioEdit:SetFontObject(ChatFontNormal) end
    ioEdit:SetTextInsets(2, 2, 0, 0)
    ioEdit:SetTextColor(0.85, 0.85, 0.85, 1)
    ioEdit:SetScript("OnMouseDown", function(self) self:SetFocus() end)
    ioEdit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    if options_dropdown_template and ioEdit.SetTemplate then
        ioEdit:SetTemplate(options_dropdown_template)
    elseif options_button_template and ioEdit.SetTemplate then
        ioEdit:SetTemplate(options_button_template)
    end

    CreateActionButton(content, profX, ioTopY - 94, "Export", 80, function()
        local str = BuildExportString(slots)
        ioEdit:SetText(str)
        ioEdit:SetFocus()
        ioEdit:HighlightText()
        RRT_Print("Exported (RRT_RG1). Copy the text above.")
    end)

    CreateActionButton(content, profX + 88, ioTopY - 94, "Import", 80, function()
        local text = ioEdit:GetText()
        local parsed, err = ParseImportedSlots(text)
        if not parsed then
            RRT_Print("Import failed: " .. (err or "invalid format")); return
        end
        ApplySlotsToEditor(parsed)
        RRT_Print("Raid groups imported.")
    end)

    CreateActionButton(content, profX + 176, ioTopY - 94, "Export RRT", 90, function()
        local str, err = BuildPackedExportString(slots)
        if not str then
            RRT_Print("Packed export failed: " .. (err or "unknown error"))
            return
        end
        ioEdit:SetText(str)
        ioEdit:SetFocus()
        ioEdit:HighlightText()
        RRT_Print("Exported packed string (RRTRGR).")
    end)

    local splitClassPrio = {
        WARRIOR = 15, PALADIN = 14, ROGUE = 13, DEATHKNIGHT = 12, DEMONHUNTER = 11,
        SHAMAN = 10, MONK = 9, DRUID = 8, HUNTER = 7, PRIEST = 6, MAGE = 5, WARLOCK = 4, EVOKER = 3,
    }

    local function SplitRosterInEditor()
        local groupMask = rg.splitGroups or {}
        local splitParts = math.max(1, tonumber(rg.splitParts) or 2)
        local splitRule = tonumber(rg.splitRule) or 1

        local selectedGroups = {}
        for g = 1, NUM_GROUPS do
            if groupMask[g] then
                selectedGroups[#selectedGroups + 1] = g
            end
        end
        if #selectedGroups == 0 then
            RRT_Print("Split: no groups selected.")
            return
        end
        if (#selectedGroups / splitParts) % 1 ~= 0 then
            RRT_Print("Split impossible: selected groups must be divisible by parts.")
            return
        end

        local roster = {}
        for _, g in ipairs(selectedGroups) do
            for p = 1, SLOTS_PER_GRP do
                local idx = SlotIdx(g, p)
                local name = NormalizeNameToken(slots[idx])
                if name then
                    local prio = 0
                    if UnitName(name) then prio = prio + 100 end
                    local role = UnitGroupRolesAssigned(name)
                    if role == "TANK" then
                        prio = prio + 60
                    elseif role == "DAMAGER" then
                        prio = prio + 40
                    elseif role == "HEALER" then
                        prio = prio + 20
                    end
                    local _, classTag = UnitClass(name)
                    if classTag then
                        prio = prio + (splitClassPrio[classTag] or 0)
                    end
                    roster[#roster + 1] = { name = name, prio = prio }
                end
            end
        end
        table.sort(roster, function(a, b)
            if a.prio == b.prio then
                return a.name < b.name
            end
            return a.prio > b.prio
        end)

        local splits = {}
        local selectedCount = #selectedGroups
        for pos, g in ipairs(selectedGroups) do
            local splitNum
            if splitRule == 2 then
                splitNum = ((pos - 1) % splitParts) + 1
            else
                splitNum = math.floor((pos - 1) / math.ceil(selectedCount / splitParts)) + 1
            end
            splits[splitNum] = splits[splitNum] or { groups = {}, curr = 1 }
            table.insert(splits[splitNum].groups, g)
        end

        -- Clear selected groups first.
        for _, g in ipairs(selectedGroups) do
            for p = 1, SLOTS_PER_GRP do
                SetSlotValue(SlotIdx(g, p), nil)
            end
        end

        local pos = 1
        for i = 1, selectedCount * SLOTS_PER_GRP do
            local s = splits[pos]
            local group = s.groups[math.floor((s.curr - 1) / SLOTS_PER_GRP) + 1]
            local gpos = ((s.curr - 1) % SLOTS_PER_GRP) + 1
            local idx = SlotIdx(group, gpos)
            SetSlotValue(idx, roster[i] and roster[i].name or nil)
            s.curr = s.curr + 1
            pos = pos + 1
            if pos > splitParts then pos = 1 end
        end

        RefreshColors()
        RefreshUnassigned()
        RRT_Print("Split roster applied. Parts: " .. splitParts .. ", Rule: " .. (splitRule == 2 and "alternating" or "contiguous"))
    end

    -- Action buttons below grid
    local btnY = gridBottom - 10

    CreateActionButton(content, GX_LEFT, btnY, "Set Current Roster", 170, function()
        if not IsInGroup() then RRT_Print("You are not in a group."); return end
        for i = 1, NUM_SLOTS do slots[i] = nil end
        local groupLists = {}
        for g = 1, NUM_GROUPS do groupLists[g] = {} end
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name and subgroup then
                table.insert(groupLists[subgroup], ShortName(name))
            end
        end
        for g = 1, NUM_GROUPS do
            for p = 1, SLOTS_PER_GRP do
                local name = groupLists[g][p]
                slots[SlotIdx(g, p)] = name
                local eb = slotEdits[SlotIdx(g, p)]
                if eb then
                    eb:SetText(name or "")
                    local r, gb, b = NameColor(name)
                    eb:SetTextColor(r, gb, b, 1)
                end
            end
        end
        RefreshColors()
        RefreshUnassigned()
    end)

    CreateActionButton(content, GX_LEFT, btnY - 30, "Clear All", 170, function()
        for i = 1, NUM_SLOTS do
            slots[i] = nil
            local eb = slotEdits[i]
            if eb then eb:SetText(""); eb:SetTextColor(0.55, 0.55, 0.55, 1) end
        end
        RefreshUnassigned()
    end)

    local splitBtn = CreateActionButton(content, GX_LEFT + 178, btnY, "Split Roster", 100, function()
        SplitRosterInEditor()
    end)

    -- Split controls are hidden by default and shown in a compact panel.
    local splitY = btnY - 30
    local splitOptionsFrame = CreateFrame("Frame", nil, content, "BackdropTemplate")
    splitOptionsFrame:SetPoint("TOPLEFT", GX_LEFT + 178, splitY - 28)
    splitOptionsFrame:SetSize(360, 58)
    splitOptionsFrame:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    splitOptionsFrame:SetBackdropColor(0.08, 0.08, 0.08, 0.85)
    splitOptionsFrame:SetBackdropBorderColor(0.2, 0.2, 0.2, 0.9)
    splitOptionsFrame:Hide()

    local splitOptionsVisible = false
    local splitOptionsToggleBtn = CreateActionButton(content, GX_LEFT + 178, splitY, "Split Options", 110, function()
        splitOptionsVisible = not splitOptionsVisible
        splitOptionsFrame:SetShown(splitOptionsVisible)
        if splitOptionsToggleBtn and splitOptionsToggleBtn.SetText then
            splitOptionsToggleBtn:SetText(splitOptionsVisible and "Hide Options" or "Split Options")
        end
    end)

    local optsHdr = splitOptionsFrame:CreateFontString(nil, "OVERLAY")
    ApplyRRTFont(optsHdr, 10)
    optsHdr:SetPoint("TOPLEFT", 8, -6)
    optsHdr:SetTextColor(unpack(COLOR_MUTED))
    optsHdr:SetText("Split options")

    local groupsLbl = splitOptionsFrame:CreateFontString(nil, "OVERLAY")
    ApplyRRTFont(groupsLbl, 10)
    groupsLbl:SetPoint("TOPLEFT", 8, -33)
    groupsLbl:SetTextColor(unpack(COLOR_MUTED))
    groupsLbl:SetText("Groups")

    local partsBtn
    local ruleBtn

    partsBtn = CreateActionButton(splitOptionsFrame, 96, -2, "", 78, function()
        rg.splitParts = (rg.splitParts % NUM_GROUPS) + 1
        if partsBtn and partsBtn.SetText then
            partsBtn:SetText("Parts: " .. rg.splitParts)
        end
    end)

    ruleBtn = CreateActionButton(splitOptionsFrame, 180, -2, "", 120, function()
        rg.splitRule = (rg.splitRule == 2) and 1 or 2
        if ruleBtn and ruleBtn.SetText then
            if rg.splitRule == 2 then
                ruleBtn:SetText("Rule: alternating")
            else
                ruleBtn:SetText("Rule: contiguous")
            end
        end
    end)

    local groupBtns = {}
    local function RefreshSplitControls()
        if partsBtn and partsBtn.SetText then
            partsBtn:SetText("Parts: " .. rg.splitParts)
        end
        if ruleBtn and ruleBtn.SetText then
            if rg.splitRule == 2 then
                ruleBtn:SetText("Rule: alternating")
            else
                ruleBtn:SetText("Rule: contiguous")
            end
        end
        for g = 1, NUM_GROUPS do
            local b = groupBtns[g]
            if b then
                local checked = rg.splitGroups[g]
                if b.SetTextColor then
                    if checked then
                        b:SetTextColor(0.2, 1.0, 0.2, 1.0)
                    else
                        b:SetTextColor(0.9, 0.9, 0.9, 1.0)
                    end
                end
            end
        end
    end

    local gX = 56
    for g = 1, NUM_GROUPS do
        local groupIndex = g
        local b = CreateActionButton(splitOptionsFrame, gX + (g - 1) * 24, -29, tostring(g), 22, function()
            rg.splitGroups[groupIndex] = not rg.splitGroups[groupIndex]
            RefreshSplitControls()
        end)
        groupBtns[groupIndex] = b
    end
    RefreshSplitControls()

    local applyY = splitY - 72
    CreateActionButton(content, GX_LEFT, applyY, "Apply Groups", 170, function()
        ApplyRaidGroups(slots)
    end)

    -- Clamp the scroll area to the actual UI content so wheel scrolling does not
    -- continue into empty space below the action/import buttons.
    do
        local buttonsBottom = btnY - ROW_HEIGHT
        local splitBottom = splitY - ROW_HEIGHT
        local applyBottom = applyY - ROW_HEIGHT
        local ioButtonsBottom = (ioTopY - 94) - ROW_HEIGHT
        local lowestY = math.min(buttonsBottom, ioButtonsBottom, splitBottom, applyBottom)
        local neededHeight = math.max(640, math.abs(lowestY) + 48)
        pageBg:SetHeight(neededHeight)
        content:SetHeight(neededHeight + 8)
    end

    -- Roster watcher
    local watcher = CreateFrame("Frame")
    watcher:RegisterEvent("GROUP_ROSTER_UPDATE")
    watcher:RegisterEvent("GUILD_ROSTER_UPDATE")
    watcher:SetScript("OnEvent", function()
        if content and content:IsVisible() then
            RefreshUnassigned()
            RefreshColors()
        end
    end)
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.SetupManager = RRT.UI.SetupManager or {}
RRT.UI.SetupManager.RaidGroups = { BuildUI = BuildRaidGroupsUI }
