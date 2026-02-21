local _, RRT = ...
local DF = _G["DetailsFramework"]

local Core          = RRT.UI.Core
local window_width  = Core.window_width
local window_height = Core.window_height
local options_button_template = Core.options_button_template
local options_dropdown_template = Core.options_dropdown_template
local apply_scrollbar_style = Core.apply_scrollbar_style

local LibSerialize  = LibStub and LibStub("LibSerialize", true)
local LibDeflate    = LibStub and LibStub("LibDeflate",   true)

-------------------------------------------------------------------------------
-- Keys snapshotted into each profile (all user-configurable RRTDB settings)
-------------------------------------------------------------------------------

local SNAPSHOT_KEYS = {
    "Settings",            -- General: TTS, minimap, font …
    "NickNames",           -- Nickname mappings
    "ReminderSettings",    -- Reminder display / frame settings
    "Reminders",           -- Configured reminder spells
    "PersonalReminders",   -- Personal reminder spells
    "ReadyCheckSettings",  -- Ready-check settings
    "AssignmentSettings",  -- Assignment configuration
    "EncounterAlerts",     -- Encounter-alert settings
    "BattleRez",           -- Battle-rez tool config
    "CombatTimer",         -- Combat-timer config
    "MarksBar",            -- Marks-bar config
    "RaidGroups",          -- Raid-group profiles & current slots
    "Note",                -- Note text & saved notes
    "QoL",                 -- Quality-of-Life toggles
    "PASettings",          -- Private Auras (player)
    "PATankSettings",      -- Private Auras (tank)
    "PARaidSettings",      -- Private Auras (raid)
    "PATextSettings",      -- PA text settings
    "PASounds",            -- PA sounds
    "BuffReminders",       -- Buff-reminders configuration
    "RRTUI",               -- Window scale & frame positions
    "CooldownList",        -- Configured cooldowns
    "SpellTracker",        -- SpellTracker frames + its own profiles
}

-------------------------------------------------------------------------------
-- Profile DB  (lazy, stored under RRTDB.RRTProfiles)
-------------------------------------------------------------------------------

local function EnsureDB()
    if not RRTDB then return nil end
    RRTDB.RRTProfiles = RRTDB.RRTProfiles or {}
    local db = RRTDB.RRTProfiles
    if type(db.profiles) ~= "table" then db.profiles = {} end
    return db
end

-------------------------------------------------------------------------------
-- Deep copy (primitives + tables, no metatables)
-------------------------------------------------------------------------------

local function DeepCopy(orig)
    if type(orig) ~= "table" then return orig end
    local copy = {}
    for k, v in pairs(orig) do copy[DeepCopy(k)] = DeepCopy(v) end
    return copy
end

-------------------------------------------------------------------------------
-- Snapshot helpers
-------------------------------------------------------------------------------

local function CreateSnapshot()
    local snap = {}
    for _, key in ipairs(SNAPSHOT_KEYS) do
        if RRTDB[key] ~= nil then snap[key] = DeepCopy(RRTDB[key]) end
    end
    return snap
end

local function RestoreSnapshot(snap)
    if type(snap) ~= "table" then return end
    for _, key in ipairs(SNAPSHOT_KEYS) do
        if snap[key] ~= nil then RRTDB[key] = DeepCopy(snap[key]) end
    end
end

-------------------------------------------------------------------------------
-- Custom serialiser / parser  (fallback when LibSerialize is absent)
-- Based on Profiles.lua (SpellTracker) by Abraa
-------------------------------------------------------------------------------

local MAX_DEPTH = 30

local function SV(v, d)   -- SerializeValue
    if d > MAX_DEPTH then return "nil" end
    local t = type(v)
    if t == "string" then
        local e = v:gsub("\\","\\\\"):gsub('"','\\"'):gsub("\n","\\n"):gsub("\r","\\r")
        return '"'..e..'"'
    elseif t == "number" then
        if v == math.floor(v) then return tostring(math.floor(v)) end
        return string.format("%.6g", v)
    elseif t == "boolean" then return v and "true" or "false"
    elseif t == "table" then
        local parts, maxN, cnt = {}, 0, 0
        for k in pairs(v) do
            cnt = cnt + 1
            if type(k)=="number" and k==math.floor(k) and k>0 and k>maxN then maxN=k end
        end
        if maxN==cnt and maxN>0 then
            for i=1,maxN do parts[#parts+1]=SV(v[i],d+1) end
        else
            local keys={}; for k in pairs(v) do keys[#keys+1]=k end
            table.sort(keys,function(a,b) return tostring(a)<tostring(b) end)
            for _,k in ipairs(keys) do
                local ks = type(k)=="number" and ("["..SV(k,d+1).."]") or tostring(k)
                parts[#parts+1] = ks.."="..SV(v[k],d+1)
            end
        end
        return "{"..table.concat(parts,",").."}"
    end
    return "nil"
end

-- Parser state helpers
local function CP(s) return {s=s,p=1} end
local function Pk(x) return x.s:sub(x.p,x.p) end
local function Sk(x) x.p=x.p+1 end
local function SW(x)
    while x.p<=#x.s do
        local c=x.s:sub(x.p,x.p)
        if c==" "or c=="\t"or c=="\n"or c=="\r" then x.p=x.p+1 else break end
    end
end

local PV  -- forward decl

local function PSt(x)
    Sk(x); local r={}
    while x.p<=#x.s do
        local c=x.s:sub(x.p,x.p)
        if c=="\\" then
            Sk(x); local n=x.s:sub(x.p,x.p)
            if n=="n" then r[#r+1]="\n" elseif n=="r" then r[#r+1]="\r"
            elseif n=='"' then r[#r+1]='"' elseif n=="\\" then r[#r+1]="\\"
            else r[#r+1]=n end; Sk(x)
        elseif c=='"' then Sk(x); return table.concat(r)
        else r[#r+1]=c; Sk(x) end
    end
end

local function PNm(x)
    local s=x.p
    if x.s:sub(x.p,x.p)=="-" then Sk(x) end
    while x.p<=#x.s and x.s:sub(x.p,x.p):match("[0-9]") do Sk(x) end
    if x.p<=#x.s and x.s:sub(x.p,x.p)=="." then
        Sk(x); while x.p<=#x.s and x.s:sub(x.p,x.p):match("[0-9]") do Sk(x) end
    end
    if x.p<=#x.s and x.s:sub(x.p,x.p):match("[eE]") then
        Sk(x)
        if x.p<=#x.s and x.s:sub(x.p,x.p):match("[%+%-]") then Sk(x) end
        while x.p<=#x.s and x.s:sub(x.p,x.p):match("[0-9]") do Sk(x) end
    end
    return tonumber(x.s:sub(s,x.p-1))
end

local function PTb(x)
    Sk(x); local res,ai={},1
    SW(x); if Pk(x)=="}" then Sk(x); return res end
    while x.p<=#x.s do
        SW(x); if Pk(x)=="}" then Sk(x); return res end
        local key,sp=nil,x.p
        if Pk(x)=="[" then
            Sk(x); SW(x); key=PV(x); SW(x)
            if Pk(x)=="]" then Sk(x) end; SW(x)
            if Pk(x)=="=" then Sk(x) else x.p=sp; key=nil end
        else
            local is=x.p
            while x.p<=#x.s and x.s:sub(x.p,x.p):match("[%w_]") do Sk(x) end
            local ie=x.p; SW(x)
            if Pk(x)=="=" and ie>is then key=x.s:sub(is,ie-1); Sk(x) else x.p=sp end
        end
        SW(x); local val=PV(x)
        if key~=nil then
            local nk=tonumber(key)
            if nk and type(key)=="string" and tostring(nk)==key then res[nk]=val else res[key]=val end
        else res[ai]=val; ai=ai+1 end
        SW(x); if Pk(x)=="," then Sk(x) end
    end
    return res
end

PV = function(x)
    SW(x); if x.p>#x.s then return nil end
    local c=Pk(x)
    if c=='"' then return PSt(x)
    elseif c=="{" then return PTb(x)
    elseif c=="-" or c:match("[0-9]") then return PNm(x)
    elseif x.s:sub(x.p,x.p+3)=="true"  then x.p=x.p+4; return true
    elseif x.s:sub(x.p,x.p+4)=="false" then x.p=x.p+5; return false
    elseif x.s:sub(x.p,x.p+2)=="nil"   then x.p=x.p+3; return nil end
    return nil
end

-------------------------------------------------------------------------------
-- Export / Import
-- "RRTP2:" = LibSerialize+LibDeflate (compact)
-- "RRTP1:" = plain custom serialiser (fallback)
-------------------------------------------------------------------------------

local function ExportProfile(name)
    local db = EnsureDB(); if not db then return nil end
    local entry = db.profiles[name]
    if not entry or type(entry.data) ~= "table" then return nil end
    if LibSerialize and LibDeflate then
        local ok, res = pcall(function()
            local ser  = LibSerialize:Serialize(entry.data)
            local comp = LibDeflate:CompressDeflate(ser, {level = 9})
            return "RRTP2:" .. LibDeflate:EncodeForPrint(comp)
        end)
        if ok then return res end
    end
    local ok, res = pcall(function() return "RRTP1:" .. SV(entry.data, 0) end)
    return ok and res or nil
end

local function ImportProfile(str)
    if type(str) ~= "string" then return false, "Invalid input." end
    str = strtrim(str)
    local data
    if str:sub(1,6) == "RRTP2:" then
        if not (LibSerialize and LibDeflate) then
            return false, "LibSerialize/LibDeflate not available."
        end
        local ok, res = pcall(function()
            local comp = LibDeflate:DecodeForPrint(str:sub(7)); if not comp then error("decode") end
            local raw  = LibDeflate:DecompressDeflate(comp);    if not raw  then error("decompress") end
            local ok2, d = LibSerialize:Deserialize(raw);       if not ok2  then error("deserialize") end
            return d
        end)
        if not ok or type(res) ~= "table" then
            return false, "Compressed import failed: " .. tostring(res)
        end
        data = res
    elseif str:sub(1,6) == "RRTP1:" then
        local ok, res = pcall(function() return PV(CP(str:sub(7))) end)
        if not ok or type(res) ~= "table" then return false, "Parse failed." end
        data = res
    else
        return false, "Invalid format — expected RRTP1: or RRTP2: prefix."
    end
    local db = EnsureDB(); if not db then return false, "No database." end
    local name, n = "Imported", 1
    while db.profiles[name] do n=n+1; name="Imported "..n end
    db.profiles[name] = { data = DeepCopy(data), savedAt = time() }
    return true, name
end

-------------------------------------------------------------------------------
-- Profile CRUD
-------------------------------------------------------------------------------

local function RRT_Print(msg) print("|cFFC9A227[RRT Profiles]|r " .. tostring(msg)) end

local function NextProfileName()
    local db = EnsureDB(); if not db then return "Profile 1" end
    local i = 1; while db.profiles["Profile "..i] do i=i+1 end; return "Profile "..i
end

local function SaveProfile(name)
    local db = EnsureDB(); if not db then return end
    db.profiles[name] = { data = CreateSnapshot(), savedAt = time() }
    db.active = name
end

local function LoadProfile(name)
    if InCombatLockdown() then RRT_Print("Cannot load a profile during combat."); return false end
    local db = EnsureDB(); if not db then return false end
    local entry = db.profiles[name]
    if not entry or type(entry.data) ~= "table" then
        RRT_Print("Profile not found: " .. tostring(name)); return false
    end
    RestoreSnapshot(entry.data)
    db.active = name
    pcall(function() if RRT.UpdateReminderFrame  then RRT:UpdateReminderFrame(true) end end)
    pcall(function() if RRT.UpdateExistingFrames then RRT:UpdateExistingFrames()    end end)
    local LDBIcon = Core.LDBIcon
    if LDBIcon and RRTDB.Settings and RRTDB.Settings.Minimap then
        pcall(function()
            if RRTDB.Settings.Minimap.hide then LDBIcon:Hide("RRT") else LDBIcon:Show("RRT") end
        end)
    end
    RRT_Print("Profile '"..name.."' loaded. Some changes need |cFFFFD700/reload|r to fully apply.")
    return true
end

local function DeleteProfile(name)
    local db = EnsureDB(); if not db then return end
    db.profiles[name] = nil
    if db.active == name then db.active = nil end
end

local function GetProfileNames()
    local db = EnsureDB(); if not db then return {} end
    local names = {}
    for n in pairs(db.profiles) do names[#names+1] = n end
    table.sort(names); return names
end

-------------------------------------------------------------------------------
-- Visual helpers
-------------------------------------------------------------------------------

local FONT            = "Fonts\\FRIZQT__.TTF"
local COLOR_ACCENT    = {0.30, 0.72, 1.00, 1.0}
local COLOR_BTN       = {0.10, 0.13, 0.18, 0.90}
local COLOR_BTN_HOVER = {0.18, 0.25, 0.35, 0.95}
local COLOR_DEL       = {0.20, 0.05, 0.05, 0.90}
local COLOR_DEL_HOV   = {0.35, 0.08, 0.08, 0.95}
local COLOR_LABEL     = {0.85, 0.85, 0.85, 1.0}
local COLOR_MUTED     = {0.55, 0.55, 0.55, 1.0}
local COLOR_SECTION   = {0.12, 0.12, 0.12, 1.0}
local COLOR_BORDER    = {0.2, 0.2, 0.2, 1.0}

local function SkinPanel(frame, bgColor, borderColor)
    if not frame then return end
    if not frame.SetBackdrop then
        Mixin(frame, BackdropTemplateMixin)
    end
    frame:SetBackdrop({
        bgFile   = "Interface\\BUTTONS\\WHITE8X8",
        edgeFile = "Interface\\BUTTONS\\WHITE8X8",
        edgeSize = 1,
    })
    frame:SetBackdropColor(unpack(bgColor or COLOR_SECTION))
    frame:SetBackdropBorderColor(unpack(borderColor or COLOR_BORDER))
end

local function SkinBtn(btn, col, hov)
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(); bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(unpack(col or COLOR_BTN)); btn._bg = bg
    btn:SetScript("OnEnter", function(s) s._bg:SetVertexColor(unpack(hov or COLOR_BTN_HOVER)) end)
    btn:SetScript("OnLeave", function(s) s._bg:SetVertexColor(unpack(col or COLOR_BTN))       end)
end

local function MakeBtn(parent, text, w, h, onClick, danger)
    if DF and DF.CreateButton then
        local btnObj = DF:CreateButton(parent, onClick, w, h, text)
        local btn = (btnObj and (btnObj.widget or btnObj.button)) or btnObj
        if options_button_template and btnObj and btnObj.SetTemplate then
            btnObj:SetTemplate(options_button_template)
        else
            if btn then
                SkinBtn(btn, danger and COLOR_DEL or COLOR_BTN, danger and COLOR_DEL_HOV or COLOR_BTN_HOVER)
            end
        end
        if btnObj and btnObj.SetTextColor then
            btnObj:SetTextColor(unpack(COLOR_LABEL))
        end
        if btn and btn.SetScript then
            btn:SetScript("OnClick", onClick)
        end
        return btn
    end

    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(w, h)
    if options_button_template and btn.SetTemplate then
        btn:SetTemplate(options_button_template)
    else
        SkinBtn(btn, danger and COLOR_DEL or COLOR_BTN, danger and COLOR_DEL_HOV or COLOR_BTN_HOVER)
    end
    local lbl = btn:CreateFontString(nil, "OVERLAY")
    lbl:SetFont(FONT, 11, ""); lbl:SetPoint("CENTER", 0, 0)
    lbl:SetTextColor(unpack(COLOR_LABEL)); lbl:SetText(text)
    btn:SetScript("OnClick", onClick)
    return btn
end

local function MakeSep(parent, y)
    local t = parent:CreateTexture(nil, "ARTWORK"); t:SetHeight(1)
    t:SetPoint("TOPLEFT",  parent, "TOPLEFT",  8,  y)
    t:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -8, y)
    t:SetColorTexture(unpack(COLOR_BORDER)); return t
end

local function MakeLabel(parent, text, x, y, size, r, g, b)
    local fs = parent:CreateFontString(nil, "OVERLAY")
    fs:SetFont(FONT, size or 11, "")
    fs:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    fs:SetTextColor(r or COLOR_MUTED[1], g or COLOR_MUTED[2], b or COLOR_MUTED[3]); fs:SetText(text); return fs
end

local function MakeEdit(parent, x, y, w, h)
    local e = CreateFrame("EditBox", nil, parent)
    e:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y); e:SetSize(w, h or 20)
    e:SetAutoFocus(false)
    if e.SetFontObject and ChatFontNormal then e:SetFontObject(ChatFontNormal) end
    e:SetTextInsets(4, 4, 0, 0)
    e:SetTextColor(0.85, 0.85, 0.85, 1)
    if options_dropdown_template and e.SetTemplate then
        e:SetTemplate(options_dropdown_template)
    elseif options_button_template and e.SetTemplate then
        e:SetTemplate(options_button_template)
    end
    e:SetScript("OnEnterPressed",  function(s) s:ClearFocus() end)
    e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
    return e
end

-------------------------------------------------------------------------------
-- BuildProfilesUI
-- Fixed header area is built once.  Only the profile row list is rebuilt
-- inside Refresh() using a row pool (same pattern as Note.lua / RaidInspect).
-------------------------------------------------------------------------------

local function BuildProfilesUI(parent)
    if parent.ProfilesPanel and parent.ProfilesPanel.Refresh then
        parent.ProfilesPanel:Refresh()
        return parent.ProfilesPanel
    end

    local PANEL_W    = window_width - 20    -- 1030
    local PANEL_H    = window_height - 110  -- 530
    -- Vertical layout constants (px from panel top, negative = down)
    local Y_TITLE    = -14
    local Y_SEP1     = -36
    local Y_ROW1     = -50   -- name + create + save-active
    local Y_ROW2     = -80   -- import area
    local Y_SEP2     = -108
    local Y_LISTHDR  = -118
    local Y_SCROLL   = -138
    -- Bottom: export box always sits at y_bottom+10, reserved 32 px
    local EXPORT_RSV = 36    -- pixels reserved at panel bottom for export box

    local panel = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    panel:SetSize(PANEL_W, PANEL_H)
    panel:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -90)
    SkinPanel(panel, { 0, 0, 0, 0.2 }, COLOR_BORDER)

    --------------------------------------------------------------------------
    -- Fixed header  (created once, never destroyed)
    --------------------------------------------------------------------------

    -- Title
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightLarge")
    title:SetPoint("TOPLEFT", panel, "TOPLEFT", 12, Y_TITLE)
    title:SetText("Profiles")
    title:SetTextColor(unpack(COLOR_ACCENT))

    local activeLbl = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    activeLbl:SetPoint("LEFT", title, "RIGHT", 20, 0)
    activeLbl:SetText("Active: -")
    activeLbl:SetTextColor(unpack(COLOR_MUTED))

    MakeSep(panel, Y_SEP1)

    -- Row 1: profile name input + Create + Save Active
    MakeLabel(panel, "Name:", 12, Y_ROW1 + 1)

    local nameEdit = MakeEdit(panel, 66, Y_ROW1, 220)
    nameEdit:SetText(NextProfileName())

    local createBtn = MakeBtn(panel, "Create", 90, 22, function() end)
    createBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 294, Y_ROW1 - 1)

    local saveActiveBtn = MakeBtn(panel, "Save Active", 110, 22, function() end)
    saveActiveBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 392, Y_ROW1 - 1)

    -- Row 2: Import
    MakeLabel(panel, "Import:", 12, Y_ROW2 + 1)

    local importEdit = MakeEdit(panel, 72, Y_ROW2, 420)
    importEdit:SetText("")

    local importBtn = MakeBtn(panel, "Import", 90, 22, function() end)
    importBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 500, Y_ROW2 - 1)

    MakeSep(panel, Y_SEP2)
    MakeLabel(panel, "Saved Profiles", 12, Y_LISTHDR, 11, 0.85, 0.85, 0.85)

    -- Export box (always at bottom, hidden until user clicks Export)
    local exportLbl = panel:CreateFontString(nil, "OVERLAY")
    exportLbl:SetFont(FONT, 10, "")
    exportLbl:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 12, EXPORT_RSV - 2)
    exportLbl:SetTextColor(unpack(COLOR_MUTED))
    exportLbl:SetText("Export string — click to select all, then Ctrl-C:")
    exportLbl:Hide()

    local exportEdit = CreateFrame("EditBox", nil, panel)
    exportEdit:SetPoint("BOTTOMLEFT",  panel, "BOTTOMLEFT",  12, 10)
    exportEdit:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -12, 10)
    exportEdit:SetHeight(20)
    exportEdit:SetAutoFocus(false)
    if exportEdit.SetFontObject and ChatFontNormal then exportEdit:SetFontObject(ChatFontNormal) end
    exportEdit:SetTextInsets(4, 4, 0, 0)
    exportEdit:SetTextColor(0.85, 0.85, 0.85, 1)
    if options_dropdown_template and exportEdit.SetTemplate then
        exportEdit:SetTemplate(options_dropdown_template)
    elseif options_button_template and exportEdit.SetTemplate then
        exportEdit:SetTemplate(options_button_template)
    end
    exportEdit:SetText("")
    exportEdit:SetScript("OnMouseUp",      function(s) s:HighlightText() end)
    exportEdit:SetScript("OnEscapePressed", function(s)
        s:ClearFocus(); s:SetText(""); s:Hide(); exportLbl:Hide()
    end)
    exportEdit:Hide()

    --------------------------------------------------------------------------
    -- Scroll frame for profile rows  (persistent frame, dynamic content)
    --------------------------------------------------------------------------

    local scrollFrame = CreateFrame("ScrollFrame", nil, panel, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT",     panel, "TOPLEFT",     8,   Y_SCROLL)
    scrollFrame:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -28, EXPORT_RSV)
    scrollFrame:EnableMouseWheel(true)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local cur  = self:GetVerticalScroll()
        local ch   = self:GetScrollChild(); if not ch then return end
        local maxS = math.max(0, ch:GetHeight() - self:GetHeight())
        self:SetVerticalScroll(math.max(0, math.min(cur - delta * 30, maxS)))
    end)
    if apply_scrollbar_style then
        apply_scrollbar_style(scrollFrame)
    end

    local ROW_H     = 28
    local ROW_GAP   = 2
    local LIST_W    = PANEL_W - 48   -- panel - scrollbar margin - left margin

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetWidth(LIST_W)
    content:SetHeight(1)
    scrollFrame:SetScrollChild(content)

    local _rowPool = {}   -- reused row frames

    --------------------------------------------------------------------------
    -- Wire up buttons with closures (now panel-level references exist)
    --------------------------------------------------------------------------

    createBtn:SetScript("OnClick", function()
        local db = EnsureDB(); if not db then return end
        local name = strtrim(nameEdit:GetText() or "")
        if name == "" then RRT_Print("Profile name required."); return end
        if db.profiles[name] then RRT_Print("Profile '"..name.."' already exists."); return end
        SaveProfile(name)
        nameEdit:SetText(NextProfileName())
        panel:Refresh()
    end)

    saveActiveBtn:SetScript("OnClick", function()
        local db = EnsureDB(); if not db then return end
        if not db.active then RRT_Print("No active profile. Create one first."); return end
        SaveProfile(db.active)
        panel:Refresh()
    end)

    importBtn:SetScript("OnClick", function()
        local str = strtrim(importEdit:GetText() or "")
        if str == "" then RRT_Print("Paste an export string first."); return end
        local ok, result = ImportProfile(str)
        if ok then
            importEdit:SetText("")
            RRT_Print("Imported as '"..result.."'.")
            panel:Refresh()
        else
            RRT_Print("Import failed: " .. (result or "?"))
        end
    end)

    --------------------------------------------------------------------------
    -- Refresh: rebuilds only the profile row list
    --------------------------------------------------------------------------

    function panel:Refresh()
        local db = EnsureDB()
        if not db then
            activeLbl:SetText("Active: |cFFFF4444database unavailable|r")
            return
        end

        activeLbl:SetText("Active: |cFF4ADF6F" .. (db.active or "-") .. "|r")

        local names = GetProfileNames()

        -- Hide all rows from previous pass
        for _, row in ipairs(_rowPool) do row:Hide() end

        for i, pname in ipairs(names) do
            local isActive = (db.active == pname)
            local entry    = db.profiles[pname]

            -- Grow pool
            local row = _rowPool[i]
            if not row then
                row = CreateFrame("Frame", nil, content)
                row:SetHeight(ROW_H)

                row.bg = row:CreateTexture(nil, "BACKGROUND")
                row.bg:SetAllPoints()
                row.bg:SetTexture("Interface\\Buttons\\WHITE8X8")

                row.nameLbl = row:CreateFontString(nil, "OVERLAY")
                row.nameLbl:SetFont(FONT, 11, "")
                row.nameLbl:SetPoint("LEFT", row, "LEFT", 8, 0)
                row.nameLbl:SetWidth(320); row.nameLbl:SetJustifyH("LEFT")
                row.nameLbl:SetWordWrap(false)

                row.dateLbl = row:CreateFontString(nil, "OVERLAY")
                row.dateLbl:SetFont(FONT, 9, "")
                row.dateLbl:SetPoint("LEFT", row, "LEFT", 336, 0)
                row.dateLbl:SetTextColor(unpack(COLOR_MUTED))

                -- Buttons: Load | Save | Export | Delete
                row.deleteBtn = MakeBtn(row, "Delete", 70, 20, function() end, true)
                row.deleteBtn:SetPoint("RIGHT", row, "RIGHT", -4, 0)

                row.exportBtn = MakeBtn(row, "Export", 70, 20, function() end)
                row.exportBtn:SetPoint("RIGHT", row.deleteBtn, "LEFT", -4, 0)

                row.saveBtn = MakeBtn(row, "Save", 60, 20, function() end)
                row.saveBtn:SetPoint("RIGHT", row.exportBtn, "LEFT", -4, 0)

                row.loadBtn = MakeBtn(row, "Load", 60, 20, function() end)
                row.loadBtn:SetPoint("RIGHT", row.saveBtn, "LEFT", -4, 0)

                _rowPool[i] = row
            end

            -- Position
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT",  content, "TOPLEFT",  0, -(i - 1) * (ROW_H + ROW_GAP))
            row:SetPoint("TOPRIGHT", content, "TOPRIGHT", 0, -(i - 1) * (ROW_H + ROW_GAP))

            -- Populate
            row.bg:SetVertexColor(
                isActive and 0.05 or 0.03,
                isActive and 0.12 or 0.03,
                isActive and 0.05 or 0.03, 0.80)

            if isActive then
                row.nameLbl:SetText("|cFF4ADF6F"..pname.."|r |cFF555555(active)|r")
            else
                row.nameLbl:SetText(pname)
            end

            row.dateLbl:SetText(entry and entry.savedAt and date("%Y-%m-%d %H:%M", entry.savedAt) or "")

            -- Rewire button callbacks (capture current pname)
            local capturedName = pname
            row.loadBtn:SetScript("OnClick", function()
                local ok = LoadProfile(capturedName)
                if ok then panel:Refresh() end
            end)
            row.saveBtn:SetScript("OnClick", function()
                SaveProfile(capturedName); panel:Refresh()
            end)
            row.exportBtn:SetScript("OnClick", function()
                local str = ExportProfile(capturedName)
                if str then
                    exportEdit:SetText(str); exportEdit:Show()
                    exportLbl:Show(); exportEdit:SetFocus(); exportEdit:HighlightText()
                else
                    RRT_Print("Export failed for '"..capturedName.."'.")
                end
            end)
            row.deleteBtn:SetScript("OnClick", function()
                DeleteProfile(capturedName); panel:Refresh()
            end)

            row:Show()
        end

        -- Empty-list hint
        local emptyHint = content.emptyHint
        if not emptyHint then
            emptyHint = content:CreateFontString(nil, "OVERLAY")
            emptyHint:SetFont(FONT, 11, "")
            emptyHint:SetPoint("TOPLEFT", content, "TOPLEFT", 8, -8)
            emptyHint:SetTextColor(unpack(COLOR_MUTED))
            emptyHint:SetText("No profiles saved yet — enter a name above and click |cFFFFD700Create|r.")
            content.emptyHint = emptyHint
        end
        emptyHint:SetShown(#names == 0)

        content:SetHeight(math.max(30, #names * (ROW_H + ROW_GAP)))
    end

    panel:Refresh()
    parent.ProfilesPanel = panel
    return panel
end

-------------------------------------------------------------------------------
-- Export
-------------------------------------------------------------------------------

RRT.UI = RRT.UI or {}
RRT.UI.Options = RRT.UI.Options or {}
RRT.UI.Options.Profiles = {
    BuildUI = BuildProfilesUI,
}
