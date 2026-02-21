local ADDON_NAME, NS = ...
local ST = NS.SpellTracker
if (not ST) then return
 end
local COMM_PREFIX = "ARTN"
local MAX_CHUNK_LEN = 220
local _noteEditor = nil
local _titleEditor = nil
local _noteWindow = nil
local _incomingChunks = {}
local _sendCounter = 0
local _renderCache = { source = nil, lines = nil, hasTimed = false }
local _tickerElapsed = 0
local _savedDropdownBuildID = 0
local function EnsureNoteDB()    if (not ST.db) then return nil
 end    if (type(ST.db.note) ~= "table") then        ST.db.note = {}
    end    local noteDB = ST.db.note
    if (type(noteDB.text) ~= "string") then noteDB.text = ""
 end    if (type(noteDB.title) ~= "string") then noteDB.title = ""
 end    if (type(noteDB.saved) ~= "table") then noteDB.saved = {}
 end    if (type(noteDB.onlyPromoted) ~= "boolean") then noteDB.onlyPromoted = true
 end    if (type(noteDB.showOnReceive) ~= "boolean") then noteDB.showOnReceive = true
 end    if (type(noteDB.visible) ~= "boolean") then noteDB.visible = true
 end    if (type(noteDB.timerAnchor) ~= "number") then noteDB.timerAnchor = 0
 end    if (type(noteDB.window) ~= "table") then noteDB.window = {}
 end    local wnd = noteDB.window
    if (type(wnd.width) ~= "number") then wnd.width = 560
 end    if (type(wnd.height) ~= "number") then wnd.height = 360
 end    if (type(wnd.x) ~= "number") then wnd.x = 0
 end    if (type(wnd.y) ~= "number") then wnd.y = 0
 end    if (type(wnd.point) ~= "string" or wnd.point == "") then wnd.point = "LEFT"
 end    if (type(wnd.relativePoint) ~= "string" or wnd.relativePoint == "") then wnd.relativePoint = "LEFT"
 end    if (wnd.point == "LEFT" and wnd.relativePoint == "LEFT" and wnd.x == 0 and wnd.y == 0) then wnd.x = 30
 end    if (type(wnd.opacity) ~= "number") then wnd.opacity = 0.78
 end    if (type(wnd.fontSize) ~= "number") then wnd.fontSize = 12
 end    if (type(wnd.scale) ~= "number") then wnd.scale = 1.0
 end    if (type(wnd.alwaysOnTop) ~= "boolean") then wnd.alwaysOnTop = false
 end    if (type(wnd.locked) ~= "boolean") then wnd.locked = false
 end    if (type(wnd.showTitleBar) ~= "boolean") then wnd.showTitleBar = true
 end    if (type(wnd.autoHideOutOfCombat) ~= "boolean") then wnd.autoHideOutOfCombat = false
 end    return noteDB
end
local function ResolveScrollBar(scrollFrame)    if (not scrollFrame) then return nil
 end    if (scrollFrame.ScrollBar) then return scrollFrame.ScrollBar
 end    local sfName = scrollFrame.GetName and scrollFrame:GetName()
    if (sfName and _G[sfName .. "ScrollBar"]) then        return _G[sfName .. "ScrollBar"]
    end    for _, child in ipairs({ scrollFrame:GetChildren() }) do        if (child and child.GetObjectType and child:GetObjectType() == "Slider") then            return child
        end    end    return nil
end
local function SkinScrollBar(scrollFrame)    local sb = ResolveScrollBar(scrollFrame)
    if (not sb or sb._artSkinned) then return
 end    sb._artSkinned = true
    sb:SetWidth(13)
    local bg = sb:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetTexture("Interface\\Buttons\\WHITE8X8")
    bg:SetVertexColor(0.07, 0.07, 0.08, 0.95)
    local thumb = sb:GetThumbTexture()
    if (not thumb) then        thumb = sb:CreateTexture(nil, "ARTWORK")
        sb:SetThumbTexture(thumb)
    end    thumb:SetTexture("Interface\\Buttons\\WHITE8X8")
    thumb:SetSize(10, 26)
    thumb:SetVertexColor(0.30, 0.72, 1.00, 0.9)
    local function SkinArrow(btn, arrowText)        if (not btn or btn._artSkinnedArrow) then return
 end        btn._artSkinnedArrow = true
        local nt = btn.GetNormalTexture and btn:GetNormalTexture()
        local ht = btn.GetHighlightTexture and btn:GetHighlightTexture()
        local pt = btn.GetPushedTexture and btn:GetPushedTexture()
        local dt = btn.GetDisabledTexture and btn:GetDisabledTexture()
        if (nt) then nt:SetAlpha(0)
 end        if (ht) then ht:SetAlpha(0)
 end        if (pt) then pt:SetAlpha(0)
 end        if (dt) then dt:SetAlpha(0)
 end        local abg = btn:CreateTexture(nil, "BACKGROUND")
        abg:SetAllPoints()
        abg:SetTexture("Interface\\Buttons\\WHITE8X8")
        abg:SetVertexColor(0.14, 0.14, 0.15, 0.95)
        local afs = btn:CreateFontString(nil, "OVERLAY")
        afs:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
        afs:SetPoint("CENTER", 0, 0)
        afs:SetTextColor(0.55, 0.55, 0.55, 1.0)
        afs:SetText(arrowText)
        btn:HookScript("OnEnter", function()            abg:SetVertexColor(0.19, 0.19, 0.21, 1.0)
            afs:SetTextColor(0.30, 0.72, 1.00, 1.0)
        end)
        btn:HookScript("OnLeave", function()            abg:SetVertexColor(0.14, 0.14, 0.15, 0.95)
            afs:SetTextColor(0.55, 0.55, 0.55, 1.0)
        end)
    end    local sbName = sb.GetName and sb:GetName()
    local upBtn = sb.ScrollUpButton or (sbName and _G[sbName .. "ScrollUpButton"])
    local downBtn = sb.ScrollDownButton or (sbName and _G[sbName .. "ScrollDownButton"])
    SkinArrow(upBtn, "^")
    SkinArrow(downBtn, "v")
end
local function NormalizeTitle(title)    title = strtrim(tostring(title or ""))
    if (title == "") then        return "Untitled"
    end    return title
end
local function SafePlainText(text)    return tostring(text or ""):gsub("|", "||")
end
local function FormatOffset(seconds)    seconds = math.max(0, math.floor(tonumber(seconds) or 0))
    local m = math.floor(seconds / 60)
    local s = seconds % 60
    return string.format("%d:%02d", m, s)
end
local function ParseTimeSpec(spec)    spec = strtrim(tostring(spec or ""))
    if (spec == "") then return nil
 end    local m, sec = spec:match("^(%d+):(%d%d?)$")
    if (m and sec) then        sec = tonumber(sec)
        if (sec and sec < 60) then            return tonumber(m) * 60 + sec
        end        return nil
    end    local onlySec = tonumber(spec)
    if (onlySec) then        return math.max(0, math.floor(onlySec))
    end    return nil
end
local function ResolveSpellToken(spellID)    local id = tonumber(spellID)
    if (not id) then return "Spell ?"
 end    local name, tex
    if (C_Spell and C_Spell.GetSpellName) then        name = C_Spell.GetSpellName(id)
    elseif (GetSpellInfo) then        name = GetSpellInfo(id)
    end    if (C_Spell and C_Spell.GetSpellTexture) then        tex = C_Spell.GetSpellTexture(id)
    elseif (GetSpellTexture) then        tex = GetSpellTexture(id)
    end    if (type(name) ~= "string" or name == "") then        name = "Spell " .. tostring(id)
    end    if (tex) then        return "|T" .. tostring(tex) .. ":14|t " .. name
    end    return name
end
local function ExpandDisplayTokens(text)    local out = SafePlainText(text)
    out = out:gsub("{spell:(%d+)}", function(id)        return ResolveSpellToken(id)
    end)
    return out
end
local function ParseTimedPrefix(line, runningOffset)    local tSpec = line:match("^%{time:([^,}]+)")
    if (tSpec) then        local offset = ParseTimeSpec(tSpec)
        if (offset ~= nil) then            local rest = line:gsub("^%{time:[^}]+%}%s*", "", 1)
            local msg = strtrim(rest or "")
            if (msg ~= "") then                return true, offset, msg, offset
            end        end    end    local mm, ss, msg = line:match("^%[(%d+):(%d%d?)%]%s+(.+)$")
    if (mm and ss and msg) then        local sec = tonumber(ss)
        if (sec and sec < 60) then            local offset = tonumber(mm) * 60 + sec
            return true, offset, strtrim(msg), offset
        end    end    mm, ss, msg = line:match("^(%d+):(%d%d?)%s+(.+)$")
    if (mm and ss and msg) then        local sec = tonumber(ss)
        if (sec and sec < 60) then            local offset = tonumber(mm) * 60 + sec
            return true, offset, strtrim(msg), offset
        end    end    mm, ss, msg = line:match("^%+(%d+):(%d%d?)%s+(.+)$")
    if (mm and ss and msg) then        local sec = tonumber(ss)
        if (sec and sec < 60) then            local offset = math.max(0, runningOffset + tonumber(mm) * 60 + sec)
            return true, offset, strtrim(msg), offset
        end    end    local ds, dmsg = line:match("^%+(%d+)%s+(.+)$")
    if (ds and dmsg) then        local offset = math.max(0, runningOffset + tonumber(ds))
        return true, offset, strtrim(dmsg), offset
    end    return false, 0, line, runningOffset
end
local function BuildDisplayLines(rawText)    local lines = {}
    local hasTimed = false
    local rollingOffset = 0
    rawText = tostring(rawText or ""):gsub("\r\n", "\n"):gsub("\r", "\n")
    for rawLine in (rawText .. "\n"):gmatch("(.-)\n") do        local line = strtrim(rawLine or "")
        if (line == "") then            table.insert(lines, { text = "", isBlank = true })
        else            local isTimed, offset, message, nextOffset = ParseTimedPrefix(line, rollingOffset)
            if (isTimed) then                rollingOffset = nextOffset
                hasTimed = true
            end            message = ExpandDisplayTokens(message or "")
            table.insert(lines, {                offset = isTimed and offset or nil,                text = message,                isTimed = isTimed,            })
        end    end    return lines, hasTimed
end
local function InvalidateRenderCache()    _renderCache.source = nil
    _renderCache.lines = nil
    _renderCache.hasTimed = false
end
local function GetDisplayLines()    local src = ST:GetNoteText()
    if (_renderCache.source == src and _renderCache.lines) then        return _renderCache.lines, _renderCache.hasTimed
    end    local lines, hasTimed = BuildDisplayLines(src)
    _renderCache.source = src
    _renderCache.lines = lines
    _renderCache.hasTimed = hasTimed
    return lines, hasTimed
end
local function BuildStyledDisplayText()    local noteDB = EnsureNoteDB()
    local lines, hasTimed = GetDisplayLines()
    local out = {}
    local timerRunning = noteDB and noteDB.timerAnchor and noteDB.timerAnchor > 0
    local now = GetTime()
    local elapsed = timerRunning and (now - noteDB.timerAnchor) or 0
    for _, row in ipairs(lines or {}) do        if (row.isBlank) then            table.insert(out, " ")
        else            local msg = row.text or ""
            if (row.isTimed and row.offset) then                if (timerRunning) then                    local remain = math.floor(row.offset - elapsed + 0.5)
                    if (remain > 15) then                        table.insert(out, "|cff66dd66[" .. FormatOffset(remain) .. "]|r " .. msg)
                    elseif (remain > 5) then                        table.insert(out, "|cffffc44d[" .. FormatOffset(remain) .. "]|r " .. msg)
                    elseif (remain > 0) then                        table.insert(out, "|cffff5555[" .. FormatOffset(remain) .. "]|r |cffffcc66>>|r " .. msg)
                    else                        table.insert(out, "|cff888888[+" .. FormatOffset(math.abs(remain)) .. "]|r " .. msg)
                    end                else                    table.insert(out, "|cff66b3ff[" .. FormatOffset(row.offset) .. "]|r " .. msg)
                end            else                table.insert(out, "|cffdddddd" .. msg .. "|r")
            end        end    end    local rendered = table.concat(out, "\n")
    if (strtrim(rendered) == "") then        rendered = "|cff888888(No note)|r"
    end    return rendered, hasTimed
end
function ST:GetNoteText()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return ""
 end    return noteDB.text or ""
end
function ST:SetNoteText(text)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    noteDB.text = tostring(text or "")
    InvalidateRenderCache()
end
function ST:GetNoteTitle()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return ""
 end    return noteDB.title or ""
end
function ST:SetNoteTitle(title)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    noteDB.title = NormalizeTitle(title)
end
local function FindSavedNoteIndex(noteDB, title)    if (not noteDB or type(noteDB.saved) ~= "table") then return nil
 end    local wanted = NormalizeTitle(title):lower()
    for i, item in ipairs(noteDB.saved) do        if (type(item) == "table" and type(item.title) == "string" and item.title:lower() == wanted) then            return i
        end    end    return nil
end
function ST:GetSavedNoteTitles()    local noteDB = EnsureNoteDB()
    if (not noteDB or type(noteDB.saved) ~= "table") then return {}
 end    local titles = {}
    for _, item in ipairs(noteDB.saved) do        if (type(item) == "table" and type(item.title) == "string" and item.title ~= "") then            table.insert(titles, item.title)
        end    end    table.sort(titles, function(a, b)        return a:lower() < b:lower()
    end)
    return titles
end
function ST:SaveNamedNote(title, text)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return false
 end    local finalTitle = NormalizeTitle(title or noteDB.title)
    local finalText = tostring(text or noteDB.text or "")
    local idx = FindSavedNoteIndex(noteDB, finalTitle)
    if (idx) then        noteDB.saved[idx].title = finalTitle
        noteDB.saved[idx].text = finalText
        noteDB.saved[idx].updatedAt = time()
    else        table.insert(noteDB.saved, {            title = finalTitle,            text = finalText,            updatedAt = time(),        })
    end    noteDB.title = finalTitle
    noteDB.text = finalText
    return true
end
function ST:LoadNamedNote(title)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return false
 end    local idx = FindSavedNoteIndex(noteDB, title)
    if (not idx) then return false
 end    local item = noteDB.saved[idx]
    noteDB.title = item.title or "Untitled"
    noteDB.text = tostring(item.text or "")
    return true
end
function ST:DeleteNamedNote(title)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return false
 end    local idx = FindSavedNoteIndex(noteDB, title)
    if (not idx) then return false
 end    table.remove(noteDB.saved, idx)
    return true
end
local function SaveWindowPosition(frame)    local noteDB = EnsureNoteDB()
    if (not noteDB or not noteDB.window or not frame) then return
 end    local p, _, rp, x, y = frame:GetPoint(1)
    if (p and rp) then        noteDB.window.point = p
        noteDB.window.relativePoint = rp
        noteDB.window.x = tonumber(x) or 0
        noteDB.window.y = tonumber(y) or 0
    end
end
local function SaveWindowSize(frame)    local noteDB = EnsureNoteDB()
    if (not noteDB or not noteDB.window or not frame) then return
 end    noteDB.window.width = math.floor(frame:GetWidth() + 0.5)
    noteDB.window.height = math.floor(frame:GetHeight() + 0.5)
end
local function ClampNumber(v, minV, maxV)
    v = tonumber(v) or minV
    if (v < minV) then return minV end
    if (v > maxV) then return maxV end
    return v
end

local function ShouldAutoHideNoteWindow(noteDB)
    if (not noteDB or not noteDB.window) then return false end
    if (not noteDB.window.autoHideOutOfCombat) then return false end
    return not UnitAffectingCombat("player")
end

local function ApplyNoteWindowSettings()
    if (not _noteWindow) then return end
    local noteDB = EnsureNoteDB()
    if (not noteDB or not noteDB.window) then return end
    local wnd = noteDB.window

    wnd.opacity = ClampNumber(wnd.opacity, 0.20, 1.00)
    wnd.fontSize = math.floor(ClampNumber(wnd.fontSize, 9, 24) + 0.5)
    wnd.scale = ClampNumber(wnd.scale, 0.70, 1.50)

    _noteWindow:SetScale(wnd.scale)
    _noteWindow:SetFrameStrata(wnd.alwaysOnTop and "TOOLTIP" or "HIGH")
    _noteWindow:SetBackdropColor(0.03, 0.03, 0.03, wnd.opacity)

    if (_noteWindow.textFS) then
        _noteWindow.textFS:SetFont("Fonts\\FRIZQT__.TTF", wnd.fontSize, "")
    end

    if (_noteWindow.topBar and _noteWindow.scroll) then
        if (wnd.showTitleBar) then
            _noteWindow.topBar:Show()
            if (_noteWindow.closeBtn) then _noteWindow.closeBtn:Show() end
            _noteWindow.scroll:ClearAllPoints()
            _noteWindow.scroll:SetPoint("TOPLEFT", 6, -28)
            _noteWindow.scroll:SetPoint("BOTTOMRIGHT", -26, 8)
        else
            _noteWindow.topBar:Hide()
            if (_noteWindow.closeBtn) then _noteWindow.closeBtn:Hide() end
            _noteWindow.scroll:ClearAllPoints()
            _noteWindow.scroll:SetPoint("TOPLEFT", 6, -6)
            _noteWindow.scroll:SetPoint("BOTTOMRIGHT", -26, 8)
        end
    end

    _noteWindow:SetMovable(not wnd.locked)
    if (wnd.locked) then
        _noteWindow:RegisterForDrag()
    else
        _noteWindow:RegisterForDrag("LeftButton")
    end

    if (_noteWindow.resizeGrip) then
        _noteWindow.resizeGrip:EnableMouse(not wnd.locked)
        _noteWindow.resizeGrip:SetAlpha(wnd.locked and 0.2 or 0.8)
    end
end

local function ApplyNoteWindowVisibilityState()
    if (not _noteWindow) then return end
    local noteDB = EnsureNoteDB()
    if (not noteDB) then return end
    if (not noteDB.visible) then
        _noteWindow:Hide()
        return
    end
    if (ShouldAutoHideNoteWindow(noteDB)) then
        _noteWindow:Hide()
        return
    end
    ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
    _noteWindow:Show()
end
local function CanSenderControlNote(senderShort)    if (not senderShort or senderShort == "") then return false
 end    local me = Ambiguate(UnitName("player") or "", "short")
    if (senderShort == me) then        return true
    end    if (not IsInRaid()) then        return true
    end    local count = GetNumGroupMembers() or 0
    for i = 1, count do        local unit = "raid" .. i
        local name = UnitName(unit)
        if (name and Ambiguate(name, "short") == senderShort) then            return UnitIsGroupLeader(unit) or UnitIsGroupAssistant(unit)
        end    end    return false
end
function ST:CanSendRaidNote()    if (IsInRaid()) then        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then        return UnitIsGroupLeader("player") or UnitIsGroupAssistant("player")
    end    if (IsInGroup()) then        return UnitIsGroupLeader("player")
    end    return false
end
local function ResolveAddonDist()    if (IsInGroup(LE_PARTY_CATEGORY_INSTANCE)) then        return "INSTANCE_CHAT"
    end    if (IsInRaid()) then        return "RAID"
    end    if (IsInGroup()) then        return "PARTY"
    end    return nil
end
local function ReflowNoteWindowText()    if (not _noteWindow or not _noteWindow.content or not _noteWindow.textFS) then return
 end    local width = math.max(120, _noteWindow:GetWidth() - 44)
    _noteWindow.content:SetWidth(width)
    _noteWindow.textFS:SetWidth(width - 4)
    local h = math.max(20, math.ceil(_noteWindow.textFS:GetStringHeight()) + 12)
    _noteWindow.content:SetHeight(h)
end
function ST:StartNoteTimer(silent)    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    noteDB.timerAnchor = GetTime()
    self:RefreshNoteWindow()
    if (not silent) then        self:Print("Note timer started.")
    end
end
function ST:ResetNoteTimer()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    noteDB.timerAnchor = 0
    self:RefreshNoteWindow()
    self:Print("Note timer reset.")
end
function ST:RefreshNoteWindow()    if (not _noteWindow) then return
 end    local noteDB = EnsureNoteDB()
    local title = self:GetNoteTitle()
    local styledText, hasTimed = BuildStyledDisplayText()
    if (_noteWindow.titleFS) then        if (noteDB and noteDB.timerAnchor and noteDB.timerAnchor > 0 and hasTimed) then            local elapsed = math.max(0, math.floor(GetTime() - noteDB.timerAnchor))
            _noteWindow.titleFS:SetText("|cff4db8ff" .. SafePlainText(title ~= "" and title or "Raid Note") .. "|r  |cff88ff88(" .. FormatOffset(elapsed) .. ")|r")
        else            _noteWindow.titleFS:SetText("|cff4db8ff" .. SafePlainText(title ~= "" and title or "Raid Note") .. "|r")
        end    end    if (_noteWindow.textFS) then        _noteWindow.textFS:SetText(styledText)
    end    ApplyNoteWindowSettings()
    ReflowNoteWindowText()
end
function ST:ShowNoteWindow()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    if (not _noteWindow) then return
 end    noteDB.visible = true
    local wnd = noteDB.window or {}
    _noteWindow:ClearAllPoints()
    _noteWindow:SetPoint(wnd.point or "LEFT", UIParent, wnd.relativePoint or "LEFT", wnd.x or 30, wnd.y or 0)
    ApplyNoteWindowSettings()
    ApplyNoteWindowVisibilityState()
end
function ST:HideNoteWindow()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    if (not _noteWindow) then return
 end    noteDB.visible = false
    _noteWindow:Hide()
end
function ST:ToggleNoteWindow()    if (_noteWindow and _noteWindow:IsShown()) then        self:HideNoteWindow()
    else        self:ShowNoteWindow()
    end
end
local function CreateNoteWindow()    if (_noteWindow) then return _noteWindow
 end    local noteDB = EnsureNoteDB()
    if (not noteDB) then return nil
 end    local frame = CreateFrame("Frame", "AbraaRaidTools_NoteWindow", UIParent, "BackdropTemplate")
    frame:SetClampedToScreen(true)
    frame:SetFrameStrata("HIGH")
    frame:SetSize(noteDB.window.width or 560, noteDB.window.height or 360)
    frame:SetPoint(noteDB.window.point or "LEFT", UIParent, noteDB.window.relativePoint or "LEFT", noteDB.window.x or 30, noteDB.window.y or 0)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetResizable(true)
    frame:SetResizeBounds(300, 180, 1800, 1200)
    frame:SetBackdrop({        bgFile = "Interface\\Buttons\\WHITE8X8",        edgeFile = "Interface\\Buttons\\WHITE8X8",        edgeSize = 1,    })
    frame:SetBackdropColor(0.03, 0.03, 0.03, noteDB.window.opacity or 0.78)
    frame:SetBackdropBorderColor(0.25, 0.25, 0.25, 1.0)
    frame:SetScript("OnDragStart", function(self)        self:StartMoving()
    end)
    frame:SetScript("OnDragStop", function(self)        self:StopMovingOrSizing()
        SaveWindowPosition(self)
    end)
    frame:SetScript("OnSizeChanged", function(self)        SaveWindowSize(self)
        ReflowNoteWindowText()
    end)
    local top = CreateFrame("Frame", nil, frame, "BackdropTemplate")
    top:SetPoint("TOPLEFT", 0, 0)
    top:SetPoint("TOPRIGHT", 0, 0)
    top:SetHeight(24)
    top:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    top:SetBackdropColor(0.10, 0.10, 0.10, 0.95)
    local titleFS = top:CreateFontString(nil, "OVERLAY")
    titleFS:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    titleFS:SetPoint("LEFT", 8, 0)
    local close = CreateFrame("Button", nil, top)
    close:SetPoint("RIGHT", -4, 0)
    close:SetSize(20, 20)
    close:SetNormalFontObject(GameFontNormal)
    close:SetHighlightFontObject(GameFontHighlight)
    close:SetText("X")
    close:SetScript("OnClick", function()        ST:HideNoteWindow()
    end)
    local scroll = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -28)
    scroll:SetPoint("BOTTOMRIGHT", -26, 8)
    local content = CreateFrame("Frame", nil, scroll)
    content:SetSize(math.max(120, frame:GetWidth() - 44), 120)
    local textFS = content:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    textFS:SetPoint("TOPLEFT", 2, -2)
    textFS:SetWidth(math.max(120, frame:GetWidth() - 48))
    textFS:SetJustifyH("LEFT")
    textFS:SetJustifyV("TOP")
    textFS:SetTextColor(0.92, 0.92, 0.92, 1.0)
    textFS:SetWordWrap(true)
    textFS:SetSpacing(2)
    scroll:SetScrollChild(content)
    SkinScrollBar(scroll)
    local resizeGrip = CreateFrame("Frame", nil, frame)
    resizeGrip:SetPoint("BOTTOMRIGHT", 0, 0)
    resizeGrip:SetSize(16, 16)
    resizeGrip:EnableMouse(true)
    local gripTex = resizeGrip:CreateTexture(nil, "ARTWORK")
    gripTex:SetAllPoints()
    gripTex:SetTexture("Interface\\CHATFRAME\\UI-ChatIM-SizeGrabber-Up")
    gripTex:SetVertexColor(0.9, 0.9, 0.9, 0.8)
    resizeGrip:SetScript("OnMouseDown", function()        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeGrip:SetScript("OnMouseUp", function()        frame:StopMovingOrSizing()
        SaveWindowSize(frame)
        SaveWindowPosition(frame)
    end)
    frame.titleFS = titleFS
    frame.content = content
    frame.textFS = textFS
    frame.topBar = top
    frame.closeBtn = close
    frame.scroll = scroll
    frame.resizeGrip = resizeGrip
    frame:Hide()
    _noteWindow = frame
    ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
    if (noteDB.visible) then
        ApplyNoteWindowVisibilityState()
    end
    return frame
end
local function SendNotePayload(payload, dist)    if (not payload or payload == "" or not dist) then return false
 end    if (C_ChatInfo and C_ChatInfo.SendAddonMessage) then        local ok = pcall(C_ChatInfo.SendAddonMessage, COMM_PREFIX, payload, dist)
        return ok
    end    if (SendAddonMessage) then        local ok = pcall(SendAddonMessage, COMM_PREFIX, payload, dist)
        return ok
    end    return false
end
function ST:BroadcastRaidNote()    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    local dist = ResolveAddonDist()
    if (not dist) then        self:Print("You must be in a group to send a note.")
        return
    end    if (not self:CanSendRaidNote()) then        self:Print("Only raid leader or assistants can send the raid note.")
        return
    end    local title = NormalizeTitle(self:GetNoteTitle())
    local text = tostring(self:GetNoteText() or "")
    if (strtrim(text) == "") then        self:Print("Note is empty.")
        return
    end    _sendCounter = (_sendCounter % 9999) + 1
    local noteID = string.format("%d-%04d", math.floor(GetTime() * 1000), _sendCounter)
    SendNotePayload("S\t" .. noteID .. "\t" .. title, dist)
    for i = 1, #text, MAX_CHUNK_LEN do        local chunk = text:sub(i, i + MAX_CHUNK_LEN - 1)
        SendNotePayload("C\t" .. noteID .. "\t" .. chunk, dist)
    end    SendNotePayload("E\t" .. noteID, dist)
    self:Print("Raid note sent to " .. dist .. ".")
end
local function HandleNoteAddonMessage(_, _, prefix, message, _, sender)    if (prefix ~= COMM_PREFIX) then return
 end    local noteDB = EnsureNoteDB()
    if (not noteDB) then return
 end    local senderShort = Ambiguate(sender or "", "short")
    if (noteDB.onlyPromoted and not CanSenderControlNote(senderShort)) then        return
    end    local cmd, noteID, payload = message:match("^(%u)\t([^\t]+)\t?(.*)$")
    if (not cmd or not noteID) then return
 end    if (cmd == "S") then        _incomingChunks[noteID] = {            sender = senderShort,            title = payload or "",            chunks = {},            startedAt = GetTime(),        }
    elseif (cmd == "C") then        local pack = _incomingChunks[noteID]
        if (not pack) then            pack = {                sender = senderShort,                title = "",                chunks = {},                startedAt = GetTime(),            }
            _incomingChunks[noteID] = pack
        end        table.insert(pack.chunks, payload or "")
    elseif (cmd == "E") then        local pack = _incomingChunks[noteID]
        if (not pack) then return
 end        local text = table.concat(pack.chunks, "")
        local title = NormalizeTitle(pack.title)
        ST:SetNoteTitle(title)
        ST:SetNoteText(text)
        noteDB.lastUpdateSender = pack.sender
        noteDB.lastUpdateTime = time()
        ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle())
 end        if (_noteEditor) then _noteEditor:SetText(ST:GetNoteText())
 end        if (noteDB.showOnReceive) then            ST:ShowNoteWindow()
        end        ST:Print("Raid note received from " .. SafePlainText(tostring(pack.sender)) .. ".")
        _incomingChunks[noteID] = nil
    end    local now = GetTime()
    for id, pack in pairs(_incomingChunks) do        if ((now - (pack.startedAt or now)) > 60) then            _incomingChunks[id] = nil
        end    end
end
local function EnsureComm()    if (C_ChatInfo and C_ChatInfo.RegisterAddonMessagePrefix) then        pcall(C_ChatInfo.RegisterAddonMessagePrefix, COMM_PREFIX)
    end
end
local _commFrame = CreateFrame("Frame")
_commFrame:RegisterEvent("CHAT_MSG_ADDON")
_commFrame:SetScript("OnEvent", HandleNoteAddonMessage)
local _encounterFrame = CreateFrame("Frame")
_encounterFrame:RegisterEvent("ENCOUNTER_START")
_encounterFrame:SetScript("OnEvent", function(_, event)    if (event == "ENCOUNTER_START") then        ST:StartNoteTimer(true)
    end
end)
local _combatStateFrame = CreateFrame("Frame")
_combatStateFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
_combatStateFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
_combatStateFrame:SetScript("OnEvent", function()
    ApplyNoteWindowVisibilityState()
end)
local _liveTicker = CreateFrame("Frame")
_liveTicker:SetScript("OnUpdate", function(_, elapsed)    _tickerElapsed = _tickerElapsed + elapsed
    if (_tickerElapsed < 0.2) then return
 end    _tickerElapsed = 0
    if (not _noteWindow or not _noteWindow:IsShown()) then return
 end    local noteDB = EnsureNoteDB()
    if (not noteDB or not noteDB.timerAnchor or noteDB.timerAnchor <= 0) then return
 end    local _, hasTimed = GetDisplayLines()
    if (not hasTimed) then return
 end    ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
end)
local _initFrame = CreateFrame("Frame")
_initFrame:RegisterEvent("PLAYER_LOGIN")
_initFrame:SetScript("OnEvent", function(self)    self:UnregisterAllEvents()
    EnsureNoteDB()
    EnsureComm()
    CreateNoteWindow()
end)
function ST:BuildNoteSection(parent, yOff,    FONT, PADDING, ROW_HEIGHT,    COLOR_MUTED, COLOR_LABEL, COLOR_ACCENT, COLOR_BTN, COLOR_BTN_HOVER,    SkinPanel, SkinButton, CreateActionButton, Track)    local noteDB = EnsureNoteDB()
    EnsureComm()
    CreateNoteWindow()
    local parentWidth = parent:GetWidth()
    if (not parentWidth or parentWidth <= 0) then parentWidth = 780
 end    local sectionWidth = math.max(560, parentWidth - (PADDING * 2))
    local colGap = 14
    local leftMinW = 220
    local rightColW = math.max(360, math.floor(sectionWidth * 0.60))
    local maxRight = math.max(260, sectionWidth - leftMinW - colGap)
    if (rightColW > maxRight) then rightColW = maxRight
 end    local leftColW = sectionWidth - rightColW - colGap
    local leftX = PADDING
    local rightX = PADDING + leftColW + colGap
    local topY = yOff
    local titleLabel = parent:CreateFontString(nil, "OVERLAY")
    titleLabel:SetFont(FONT, 11, "")
    titleLabel:SetPoint("TOPLEFT", leftX, topY - 3)
    titleLabel:SetTextColor(unpack(COLOR_LABEL))
    titleLabel:SetText("Title")
    Track(titleLabel)
    local titleBox = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
    titleBox:SetPoint("TOPLEFT", leftX + 40, topY)
    titleBox:SetSize(math.max(120, math.min(leftColW - 180, 150)), ROW_HEIGHT - 4)
    titleBox:SetAutoFocus(false)
    titleBox:SetMaxLetters(80)
    titleBox:SetText(ST:GetNoteTitle())
    titleBox:SetScript("OnEscapePressed", function(self) self:ClearFocus()
 end)
    titleBox:SetScript("OnEnterPressed", function(self)        ST:SetNoteTitle(self:GetText())
        ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        self:ClearFocus()
    end)
    titleBox:SetScript("OnTextChanged", function(self, userInput)        if (userInput) then            ST:SetNoteTitle(self:GetText())
            ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        end    end)
    Track(titleBox)
    _titleEditor = titleBox
    local editorTopY = topY - ROW_HEIGHT - 8
    local editorHeight = 392
    local boxHolder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    boxHolder:SetPoint("TOPLEFT", leftX, editorTopY)
    boxHolder:SetSize(leftColW, editorHeight)
    SkinPanel(boxHolder, { 0.06, 0.06, 0.06, 0.95 }, { 0.2, 0.2, 0.2, 1.0 })
    Track(boxHolder)
    local scroll = CreateFrame("ScrollFrame", nil, boxHolder, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", 6, -6)
    scroll:SetPoint("BOTTOMRIGHT", -24, 6)
    Track(scroll)
    local editBox = CreateFrame("EditBox", nil, scroll)
    editBox:SetMultiLine(true)
    editBox:SetAutoFocus(false)
    editBox:EnableMouse(true)
    if (editBox.EnableKeyboard) then editBox:EnableKeyboard(true)
 end    if (editBox.SetFontObject and ChatFontNormal) then        editBox:SetFontObject(ChatFontNormal)
    end    editBox:SetWidth(leftColW - 36)
    editBox:SetHeight(editorHeight)
    editBox:SetMaxLetters(100000)
    editBox:SetTextInsets(2, 2, 2, 2)
    editBox:SetJustifyH("LEFT")
    editBox:SetJustifyV("TOP")
    editBox:SetText(ST:GetNoteText())
    boxHolder:SetScript("OnMouseDown", function()        editBox:SetFocus()
    end)
    scroll:SetScript("OnMouseDown", function()        editBox:SetFocus()
    end)
    editBox:SetScript("OnMouseDown", function(self)        self:SetFocus()
    end)
    editBox:SetScript("OnCursorChanged", function(_, x, y, w, h)        if (ScrollFrame_OnCursorChanged) then            ScrollFrame_OnCursorChanged(scroll, x, y, w, h)
        end    end)
    editBox:SetScript("OnEscapePressed", function(self)        self:ClearFocus()
    end)
    editBox:SetScript("OnTextChanged", function(self, userInput)        if (userInput) then            ST:SetNoteText(self:GetText())
            ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        end    end)
    scroll:SetScrollChild(editBox)
    SkinScrollBar(scroll)
    Track(editBox)
    _noteEditor = editBox
    local leftActionsY = editorTopY - editorHeight - 10
    local leftBtnGap = 8
    local leftBtnW = math.floor((leftColW - leftBtnGap) / 2)
    local loadRowY = leftActionsY - ROW_HEIGHT - 4
    local selectorY = loadRowY - ROW_HEIGHT - 6
    local selectedSavedTitle = nil
    local selectorHolder = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    selectorHolder:SetPoint("TOPLEFT", leftX, selectorY)
    selectorHolder:SetSize(leftColW, ROW_HEIGHT)
    SkinPanel(selectorHolder, { 0.06, 0.06, 0.06, 0.95 }, { 0.2, 0.2, 0.2, 1.0 })
    Track(selectorHolder)

    _savedDropdownBuildID = _savedDropdownBuildID + 1
    local dropdownName = "AbraaRaidToolsSavedNotesDropDown" .. tostring(_savedDropdownBuildID)
    local selectorDropDown = CreateFrame("Frame", dropdownName, selectorHolder, "UIDropDownMenuTemplate")
    selectorDropDown:ClearAllPoints()
    selectorDropDown:SetPoint("TOPLEFT", -12, 8)
    UIDropDownMenu_SetWidth(selectorDropDown, math.max(80, leftColW - 34))
    UIDropDownMenu_SetText(selectorDropDown, "Select saved note...")
    Track(selectorDropDown)

    local ddName = selectorDropDown:GetName()
    local ddLeft = ddName and _G[ddName .. "Left"]
    local ddMiddle = ddName and _G[ddName .. "Middle"]
    local ddRight = ddName and _G[ddName .. "Right"]
    if (ddLeft) then ddLeft:Hide() end
    if (ddMiddle) then ddMiddle:Hide() end
    if (ddRight) then ddRight:Hide() end

    local ddButton = ddName and _G[ddName .. "Button"]
    if (ddButton) then
        ddButton:ClearAllPoints()
        ddButton:SetPoint("RIGHT", selectorHolder, "RIGHT", -2, 0)
        ddButton:SetSize(ROW_HEIGHT - 2, ROW_HEIGHT - 2)
        local nt = ddButton:GetNormalTexture()
        local ht = ddButton:GetHighlightTexture()
        local dt = ddButton:GetDisabledTexture()
        local pt = ddButton:GetPushedTexture()
        if (nt) then nt:SetAlpha(0) end
        if (ht) then ht:SetAlpha(0) end
        if (dt) then dt:SetAlpha(0) end
        if (pt) then pt:SetAlpha(0) end

        local arrowBG = ddButton:CreateTexture(nil, "BACKGROUND")
        arrowBG:SetAllPoints()
        arrowBG:SetTexture("Interface\\Buttons\\WHITE8X8")
        arrowBG:SetVertexColor(0.14, 0.14, 0.15, 0.95)

        local arrowFS = ddButton:CreateFontString(nil, "OVERLAY")
        arrowFS:SetFont(FONT, 10, "OUTLINE")
        arrowFS:SetPoint("CENTER", 0, 0)
        arrowFS:SetText("v")
        arrowFS:SetTextColor(unpack(COLOR_MUTED))

        ddButton:HookScript("OnEnter", function()
            if (GameTooltip and GameTooltip:IsShown()) then GameTooltip:Hide() end
            arrowBG:SetVertexColor(0.19, 0.19, 0.21, 1.0)
            arrowFS:SetTextColor(unpack(COLOR_ACCENT))
        end)
        ddButton:HookScript("OnLeave", function()
            arrowBG:SetVertexColor(0.14, 0.14, 0.15, 0.95)
            arrowFS:SetTextColor(unpack(COLOR_MUTED))
        end)
    end

    local ddText = ddName and _G[ddName .. "Text"]
    local function ApplySavedDropdownSkin()
        if (ddLeft) then ddLeft:Hide(); ddLeft:SetAlpha(0); end
        if (ddMiddle) then ddMiddle:Hide(); ddMiddle:SetAlpha(0); end
        if (ddRight) then ddRight:Hide(); ddRight:SetAlpha(0); end

        if (ddButton) then
            local nt = ddButton:GetNormalTexture()
            local ht = ddButton:GetHighlightTexture()
            local dt = ddButton:GetDisabledTexture()
            local pt = ddButton:GetPushedTexture()
            if (nt) then nt:SetAlpha(0); nt:Hide(); end
            if (ht) then ht:SetAlpha(0); ht:Hide(); end
            if (dt) then dt:SetAlpha(0); dt:Hide(); end
            if (pt) then pt:SetAlpha(0); pt:Hide(); end
        end

        if (ddText) then
            ddText:SetFont(FONT, 11, "")
            ddText:SetTextColor(unpack(COLOR_LABEL))
            ddText:ClearAllPoints()
            ddText:SetPoint("LEFT", selectorHolder, "LEFT", 10, 0)
            ddText:SetPoint("RIGHT", ddButton, "LEFT", -6, 0)
            ddText:SetJustifyH("LEFT")
            if (ddText.SetJustifyV) then ddText:SetJustifyV("MIDDLE") end
        end
    end

    if (not selectorDropDown._artSavedSkinHooked) then
        selectorDropDown._artSavedSkinHooked = true
        selectorDropDown:HookScript("OnShow", ApplySavedDropdownSkin)
        selectorHolder:HookScript("OnShow", function()
            ApplySavedDropdownSkin()
            local elapsedAccum = 0
            selectorHolder:SetScript("OnUpdate", function(_, elapsed)
                elapsedAccum = elapsedAccum + elapsed
                if (elapsedAccum >= 0.12) then
                    elapsedAccum = 0
                    ApplySavedDropdownSkin()
                end
            end)
        end)
        selectorHolder:HookScript("OnHide", function()
            selectorHolder:SetScript("OnUpdate", nil)
        end)
        if (ddButton) then
            ddButton:HookScript("OnShow", ApplySavedDropdownSkin)
        end
    end

    ApplySavedDropdownSkin()
    local loadActionBtn = nil
    local deleteActionBtn = nil
    local function SetSavedActionsEnabled(enabled)
        if (loadActionBtn) then
            loadActionBtn:SetEnabled(enabled)
            loadActionBtn:SetAlpha(enabled and 1.0 or 0.5)
        end
        if (deleteActionBtn) then
            deleteActionBtn:SetEnabled(enabled)
            deleteActionBtn:SetAlpha(enabled and 1.0 or 0.5)
        end
    end
    local function RefreshSavedInfo()
        local titles = ST:GetSavedNoteTitles()
        local foundSelected = false
        for _, t in ipairs(titles) do
            if (selectedSavedTitle == t) then
                foundSelected = true
                break
            end
        end
        if ((not foundSelected) and #titles > 0) then
            selectedSavedTitle = titles[1]
        elseif (#titles == 0) then
            selectedSavedTitle = nil
        end
        if (not selectedSavedTitle) then
            UIDropDownMenu_SetText(selectorDropDown, "Select saved note...")
            SetSavedActionsEnabled(false)
        else
            UIDropDownMenu_SetText(selectorDropDown, selectedSavedTitle)
            SetSavedActionsEnabled(true)
        end
        ApplySavedDropdownSkin()
    end
    local function InitSavedDropdown(_, level)
        if (level ~= 1) then return end
        local titles = ST:GetSavedNoteTitles()
        if (#titles == 0) then
            local info = UIDropDownMenu_CreateInfo()
            info.text = "No saved notes"
            info.isTitle = true
            info.notCheckable = true
            info.tooltipOnButton = false
            info.tooltipWhileDisabled = false
            UIDropDownMenu_AddButton(info, level)
            return
        end
        for _, savedTitle in ipairs(titles) do
            local isSelected = (selectedSavedTitle == savedTitle)
            local info = UIDropDownMenu_CreateInfo()
            info.text = isSelected and ("|cff4CFF4C" .. savedTitle .. "|r") or savedTitle
                        info.notCheckable = true
            info.tooltipOnButton = false
            info.tooltipWhileDisabled = false
            info.func = function()
                selectedSavedTitle = savedTitle
                RefreshSavedInfo()
                CloseDropDownMenus()
            end
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(selectorDropDown, InitSavedDropdown)
    ApplySavedDropdownSkin()
    Track(CreateActionButton(parent, leftX, leftActionsY, "Save", leftBtnW, function()        local titleVal = _titleEditor and _titleEditor:GetText() or ST:GetNoteTitle()
        local textVal = _noteEditor and _noteEditor:GetText() or ST:GetNoteText()
        ST:SaveNamedNote(titleVal, textVal)
        selectedSavedTitle = ST:GetNoteTitle()
        if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle())
 end        if (_noteEditor) then _noteEditor:SetText(ST:GetNoteText())
 end        ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        ST:Print("Note saved: " .. ST:GetNoteTitle())
        RefreshSavedInfo()
    end))
    Track(CreateActionButton(parent, leftX + leftBtnW + leftBtnGap, leftActionsY, "Clear", leftBtnW, function()        ST:SetNoteTitle("")
        ST:SetNoteText("")
        ST:ResetNoteTimer()
        if (_titleEditor) then _titleEditor:SetText("")
 end        if (_noteEditor) then            _noteEditor:SetText("")
            _noteEditor:SetFocus()
        end        ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
    end))
    loadActionBtn = CreateActionButton(parent, leftX, loadRowY, "Load", leftBtnW, function()        if (not selectedSavedTitle or selectedSavedTitle == "") then            ST:Print("Select a saved note first.")
            return
        end        if (ST:LoadNamedNote(selectedSavedTitle)) then            if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle())
 end            if (_noteEditor) then _noteEditor:SetText(ST:GetNoteText())
 end            ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
            ST:Print("Note loaded: " .. selectedSavedTitle)
        else            ST:Print("Note not found: " .. tostring(selectedSavedTitle))
        end        RefreshSavedInfo()
    end)
    Track(loadActionBtn)
    deleteActionBtn = CreateActionButton(parent, leftX + leftBtnW + leftBtnGap, loadRowY, "Delete", leftBtnW, function()        if (not selectedSavedTitle or selectedSavedTitle == "") then            ST:Print("Select a saved note first.")
            return
        end        local titleToDelete = selectedSavedTitle
        if (ST:DeleteNamedNote(titleToDelete)) then            ST:Print("Note deleted: " .. titleToDelete)
            if (ST:GetNoteTitle() == titleToDelete) then                ST:SetNoteTitle("")
                ST:SetNoteText("")
                if (_titleEditor) then _titleEditor:SetText("")
 end                if (_noteEditor) then _noteEditor:SetText("")
 end                ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
            end            selectedSavedTitle = nil
        else            ST:Print("Note not found: " .. titleToDelete)
        end        RefreshSavedInfo()
    end)
    Track(deleteActionBtn)
    RefreshSavedInfo()
    local rightY = topY
    local btnGap = 8
    local mainBtnW = math.floor((rightColW - (btnGap * 2)) / 3)
    local secondaryBtnW = math.floor((rightColW - btnGap) / 2)
    local timerStatus = parent:CreateFontString(nil, "OVERLAY")
    timerStatus:SetFont(FONT, 11, "")
    timerStatus:SetPoint("TOPLEFT", rightX, rightY - ROW_HEIGHT - 9)
    timerStatus:SetTextColor(unpack(COLOR_MUTED))
    Track(timerStatus)
    local testTimerBtnText = nil
    local function RefreshTimerActionUI()        local running = (noteDB.timerAnchor and noteDB.timerAnchor > 0)
        timerStatus:SetText("")
        if (testTimerBtnText) then            testTimerBtnText:SetText(running and "Stop Timer" or "Test Timer")
        end    end    Track(CreateActionButton(parent, rightX, rightY, "Send", mainBtnW, function()        ST:BroadcastRaidNote()
        RefreshTimerActionUI()
    end))
    local testTimerBtn = CreateFrame("Button", nil, parent)
    testTimerBtn:SetPoint("TOPLEFT", rightX + mainBtnW + btnGap, rightY)
    testTimerBtn:SetSize(mainBtnW, ROW_HEIGHT)
    SkinButton(testTimerBtn, COLOR_BTN, COLOR_BTN_HOVER)
    testTimerBtnText = testTimerBtn:CreateFontString(nil, "OVERLAY")
    testTimerBtnText:SetFont(FONT, 11)
    testTimerBtnText:SetPoint("CENTER", 0, 0)
    testTimerBtnText:SetTextColor(unpack(COLOR_LABEL))
    testTimerBtn:SetScript("OnClick", function()        if (noteDB.timerAnchor and noteDB.timerAnchor > 0) then            ST:ResetNoteTimer()
        else            ST:StartNoteTimer()
        end        RefreshTimerActionUI()
    end)
    Track(testTimerBtn)
    RefreshTimerActionUI()
    rightY = topY - ROW_HEIGHT - 1
    local function LoadKazeNoteTestLines()        local sample = table.concat({            "{time:0:10} PRE-PULL: defensive personals ready",            "{time:0:25} Tank swap + external",            "{time:0:40} Group soak + healer CD",            "{time:1:00} Burst phase - lust + potions",            "{time:1:20} Rotating interrupts (Kaze note test)",            "{time:1:45} Raid-wide defensive",            "{time:2:05} Movement + spread",            "{time:2:25} Final burn",        }, "\n")
        ST:SetNoteTitle("Kaze Note Test")
        ST:SetNoteText(sample)
        ST:ResetNoteTimer()
        ApplyNoteWindowSettings()
    ST:RefreshNoteWindow()
        if (_titleEditor) then _titleEditor:SetText(ST:GetNoteTitle())
 end        if (_noteEditor) then            _noteEditor:SetText(ST:GetNoteText())
            _noteEditor:SetFocus()
        end        ST:Print("Kaze note test lines loaded.")
    end    Track(CreateActionButton(parent, rightX + ((mainBtnW + btnGap) * 2), topY, "Kaze Test", mainBtnW, function()        LoadKazeNoteTestLines()
        RefreshTimerActionUI()
    end))
    local promotedOnly = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    promotedOnly:SetPoint("TOPLEFT", rightX, rightY)
    promotedOnly:SetSize(22, 22)
    promotedOnly:SetChecked(noteDB.onlyPromoted)
    promotedOnly:SetScript("OnClick", function(self)        noteDB.onlyPromoted = self:GetChecked() and true or false
    end)
    Track(promotedOnly)
    local promotedOnlyLabel = promotedOnly:CreateFontString(nil, "OVERLAY")
    promotedOnlyLabel:SetFont(FONT, 11, "")
    promotedOnlyLabel:SetPoint("LEFT", promotedOnly, "RIGHT", 4, 0)
    promotedOnlyLabel:SetTextColor(unpack(COLOR_LABEL))
    promotedOnlyLabel:SetText("Accept notes only from raid lead/assist")
    Track(promotedOnlyLabel)
    rightY = rightY - ROW_HEIGHT
    local autoShow = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    autoShow:SetPoint("TOPLEFT", rightX, rightY)
    autoShow:SetSize(22, 22)
    autoShow:SetChecked(noteDB.showOnReceive)
    autoShow:SetScript("OnClick", function(self)        noteDB.showOnReceive = self:GetChecked() and true or false
    end)
    Track(autoShow)
    local autoShowLabel = autoShow:CreateFontString(nil, "OVERLAY")
    autoShowLabel:SetFont(FONT, 11, "")
    autoShowLabel:SetPoint("LEFT", autoShow, "RIGHT", 4, 0)
    autoShowLabel:SetTextColor(unpack(COLOR_LABEL))
    autoShowLabel:SetText("Auto-show note window when a note is received")
    Track(autoShowLabel)
    rightY = rightY - ROW_HEIGHT - 2

    local alwaysOnTop = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    alwaysOnTop:SetPoint("TOPLEFT", rightX, rightY)
    alwaysOnTop:SetSize(22, 22)
    alwaysOnTop:SetChecked(noteDB.window.alwaysOnTop)
    alwaysOnTop:SetScript("OnClick", function(self)
        noteDB.window.alwaysOnTop = self:GetChecked() and true or false
        ApplyNoteWindowSettings()
        ApplyNoteWindowVisibilityState()
    end)
    Track(alwaysOnTop)
    local alwaysOnTopLabel = alwaysOnTop:CreateFontString(nil, "OVERLAY")
    alwaysOnTopLabel:SetFont(FONT, 11, "")
    alwaysOnTopLabel:SetPoint("LEFT", alwaysOnTop, "RIGHT", 4, 0)
    alwaysOnTopLabel:SetTextColor(unpack(COLOR_LABEL))
    alwaysOnTopLabel:SetText("Always on top")
    Track(alwaysOnTopLabel)

    rightY = rightY - ROW_HEIGHT

    local lockWindow = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    lockWindow:SetPoint("TOPLEFT", rightX, rightY)
    lockWindow:SetSize(22, 22)
    lockWindow:SetChecked(noteDB.window.locked)
    lockWindow:SetScript("OnClick", function(self)
        noteDB.window.locked = self:GetChecked() and true or false
        ApplyNoteWindowSettings()
    end)
    Track(lockWindow)
    local lockWindowLabel = lockWindow:CreateFontString(nil, "OVERLAY")
    lockWindowLabel:SetFont(FONT, 11, "")
    lockWindowLabel:SetPoint("LEFT", lockWindow, "RIGHT", 4, 0)
    lockWindowLabel:SetTextColor(unpack(COLOR_LABEL))
    lockWindowLabel:SetText("Lock window position")
    Track(lockWindowLabel)

    rightY = rightY - ROW_HEIGHT

    local showTitleBar = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    showTitleBar:SetPoint("TOPLEFT", rightX, rightY)
    showTitleBar:SetSize(22, 22)
    showTitleBar:SetChecked(noteDB.window.showTitleBar)
    showTitleBar:SetScript("OnClick", function(self)
        noteDB.window.showTitleBar = self:GetChecked() and true or false
        ApplyNoteWindowSettings()
        ApplyNoteWindowVisibilityState()
    end)
    Track(showTitleBar)
    local showTitleBarLabel = showTitleBar:CreateFontString(nil, "OVERLAY")
    showTitleBarLabel:SetFont(FONT, 11, "")
    showTitleBarLabel:SetPoint("LEFT", showTitleBar, "RIGHT", 4, 0)
    showTitleBarLabel:SetTextColor(unpack(COLOR_LABEL))
    showTitleBarLabel:SetText("Show title bar")
    Track(showTitleBarLabel)

    rightY = rightY - ROW_HEIGHT

    local autoHideOOC = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    autoHideOOC:SetPoint("TOPLEFT", rightX, rightY)
    autoHideOOC:SetSize(22, 22)
    autoHideOOC:SetChecked(noteDB.window.autoHideOutOfCombat)
    autoHideOOC:SetScript("OnClick", function(self)
        noteDB.window.autoHideOutOfCombat = self:GetChecked() and true or false
        ApplyNoteWindowVisibilityState()
    end)
    Track(autoHideOOC)
    local autoHideOOCLabel = autoHideOOC:CreateFontString(nil, "OVERLAY")
    autoHideOOCLabel:SetFont(FONT, 11, "")
    autoHideOOCLabel:SetPoint("LEFT", autoHideOOC, "RIGHT", 4, 0)
    autoHideOOCLabel:SetTextColor(unpack(COLOR_LABEL))
    autoHideOOCLabel:SetText("Auto-hide out of combat")
    Track(autoHideOOCLabel)

    rightY = rightY - ROW_HEIGHT - 2

    local function CreateWindowValueRow(labelText, valueFormatter, onMinus, onPlus)
        local rowLabel = parent:CreateFontString(nil, "OVERLAY")
        rowLabel:SetFont(FONT, 11, "")
        rowLabel:SetPoint("TOPLEFT", rightX, rightY - 4)
        rowLabel:SetTextColor(unpack(COLOR_LABEL))
        rowLabel:SetText(labelText)
        Track(rowLabel)

        local minusBtn = nil
        local plusBtn = nil

        local valueFS = parent:CreateFontString(nil, "OVERLAY")
        valueFS:SetFont(FONT, 11, "")
        valueFS:SetPoint("TOPLEFT", rightX + 196, rightY - 4)
        valueFS:SetTextColor(unpack(COLOR_ACCENT))
        Track(valueFS)

        local function RefreshValue()
            valueFS:SetText(valueFormatter())
        end

        minusBtn = CreateActionButton(parent, rightX + 140, rightY, "-", 22, function()
            onMinus()
            RefreshValue()
        end)
        plusBtn = CreateActionButton(parent, rightX + 166, rightY, "+", 22, function()
            onPlus()
            RefreshValue()
        end)
        Track(minusBtn)
        Track(plusBtn)

        RefreshValue()
        return RefreshValue
    end

    local refreshOpacity = CreateWindowValueRow("Opacity", function()
        return string.format("%d%%", math.floor((noteDB.window.opacity or 0.78) * 100 + 0.5))
    end, function()
        noteDB.window.opacity = ClampNumber((noteDB.window.opacity or 0.78) - 0.05, 0.20, 1.00)
        ApplyNoteWindowSettings()
    end, function()
        noteDB.window.opacity = ClampNumber((noteDB.window.opacity or 0.78) + 0.05, 0.20, 1.00)
        ApplyNoteWindowSettings()
    end)

    rightY = rightY - ROW_HEIGHT

    local refreshFontSize = CreateWindowValueRow("Font size", function()
        return tostring(math.floor(noteDB.window.fontSize or 12))
    end, function()
        noteDB.window.fontSize = math.floor(ClampNumber((noteDB.window.fontSize or 12) - 1, 9, 24))
        ApplyNoteWindowSettings()
        ST:RefreshNoteWindow()
    end, function()
        noteDB.window.fontSize = math.floor(ClampNumber((noteDB.window.fontSize or 12) + 1, 9, 24))
        ApplyNoteWindowSettings()
        ST:RefreshNoteWindow()
    end)

    rightY = rightY - ROW_HEIGHT

    local refreshScale = CreateWindowValueRow("Window scale", function()
        return string.format("%.2f", noteDB.window.scale or 1.0)
    end, function()
        noteDB.window.scale = ClampNumber((noteDB.window.scale or 1.0) - 0.05, 0.70, 1.50)
        ApplyNoteWindowSettings()
        ApplyNoteWindowVisibilityState()
    end, function()
        noteDB.window.scale = ClampNumber((noteDB.window.scale or 1.0) + 0.05, 0.70, 1.50)
        ApplyNoteWindowSettings()
        ApplyNoteWindowVisibilityState()
    end)

    local function RefreshWindowOptionValues()
        refreshOpacity()
        refreshFontSize()
        refreshScale()
    end

    rightY = rightY - ROW_HEIGHT - 2

    Track(CreateActionButton(parent, rightX, rightY, "Reset Window", secondaryBtnW, function()
        noteDB.window.width = 560
        noteDB.window.height = 360
        noteDB.window.point = "LEFT"
        noteDB.window.relativePoint = "LEFT"
        noteDB.window.x = 30
        noteDB.window.y = 0
        noteDB.window.opacity = 0.78
        noteDB.window.fontSize = 12
        noteDB.window.scale = 1.0
        noteDB.window.alwaysOnTop = false
        noteDB.window.locked = false
        noteDB.window.showTitleBar = true
        noteDB.window.autoHideOutOfCombat = false

        alwaysOnTop:SetChecked(false)
        lockWindow:SetChecked(false)
        showTitleBar:SetChecked(true)
        autoHideOOC:SetChecked(false)

        if (_noteWindow) then
            _noteWindow:SetSize(noteDB.window.width, noteDB.window.height)
            _noteWindow:ClearAllPoints()
            _noteWindow:SetPoint("LEFT", UIParent, "LEFT", noteDB.window.x, noteDB.window.y)
        end

        ApplyNoteWindowSettings()
        ApplyNoteWindowVisibilityState()
        RefreshWindowOptionValues()
    end))

    rightY = rightY - ROW_HEIGHT

    Track(CreateActionButton(parent, rightX, rightY, "Show/Hide Window", secondaryBtnW, function()        ST:ToggleNoteWindow()
    end))
    rightY = rightY - ROW_HEIGHT
    local leftBottomY = selectorY - ROW_HEIGHT - 8
    local rightBottomY = rightY - ROW_HEIGHT
    local bottomY = math.min(leftBottomY, rightBottomY)
    yOff = bottomY - 8
    local contentHeight = math.max(64, math.abs(yOff) + PADDING)
    parent:SetHeight(contentHeight)
    return yOff
end




































