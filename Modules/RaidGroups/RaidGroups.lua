local _, RRT_NS = ...
local DF = _G["DetailsFramework"]

-- ─────────────────────────────────────────────────────────────────
--  Module table
-- ─────────────────────────────────────────────────────────────────
local RG = {}
RRT_NS.RaidGroups = RG

RG.edits       = {}   -- [1..40] main grid edit boxes
RG.editsNIL    = {}   -- "not in list" slots
RG.processData = nil  -- active ApplyGroups state

-- ─────────────────────────────────────────────────────────────────
--  DB init  (called from EventHandler on ADDON_LOADED)
-- ─────────────────────────────────────────────────────────────────
function RG:InitDB()
    RRT.RaidGroupsDB = RRT.RaidGroupsDB or {}
    local db = RRT.RaidGroupsDB
    db.profiles    = db.profiles    or {}
    db.current     = db.current     or {}
    db.SplitGroups = db.SplitGroups or {true,true,true,true,true,true,true,true}
    db.SplitParts  = db.SplitParts  or 2
    db.SplitRule   = db.SplitRule   or 1
end

local function SaveCurrentGrid()
    local db = RRT.RaidGroupsDB
    if not db then return end
    db.current = {}
    for i = 1, 40 do
        db.current[i] = (RG.edits[i] and RG.edits[i]:GetText()) or ""
    end
end

-- ─────────────────────────────────────────────────────────────────
--  Helpers
-- ─────────────────────────────────────────────────────────────────
local function ClassColor(className)
    local c = RAID_CLASS_COLORS and RAID_CLASS_COLORS[className]
    if c then return c.r, c.g, c.b end
    return 0.7, 0.7, 0.7
end

local function RefreshEditColor(e)
    local name = e:GetText()
    if name and name ~= "" and UnitExists(name) then
        local _, cls = UnitClass(name)
        if cls then
            local r, g, b = ClassColor(cls)
            e:SetTextColor(r, g, b, 1)
            e:SetBackdropBorderColor(r*0.5, g*0.5, b*0.5, 1)
        end
        local role = UnitGroupRolesAssigned(name)
        if role == "HEALER" then
            e.roleIcon:SetAtlas("groupfinder-icon-role-large-heal"); e.roleIcon:Show()
        elseif role == "DAMAGER" then
            e.roleIcon:SetAtlas("groupfinder-icon-role-large-dps");  e.roleIcon:Show()
        elseif role == "TANK" then
            e.roleIcon:SetAtlas("groupfinder-icon-role-large-tank"); e.roleIcon:Show()
        else
            e.roleIcon:Hide()
        end
    else
        e:SetTextColor(0.7, 0.7, 0.7, 1)
        e:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
        if e.roleIcon then e.roleIcon:Hide() end
    end
end

function RG.UpdateColors()
    for i = 1, 40 do
        if RG.edits[i] then RefreshEditColor(RG.edits[i]) end
    end
end

function RG.UpdateNotInList()
    local inList = {}
    for i = 1, 40 do
        local t = RG.edits[i] and RG.edits[i]:GetText() or ""
        if t ~= "" then inList[t] = true end
    end
    local notIn = {}
    for i = 1, GetNumGroupMembers() do
        local name = GetRaidRosterInfo(i)
        if name then
            local short = name:match("^(.-)%-")
            if not inList[name] and not (short and inList[short]) then
                notIn[#notIn+1] = name
            end
        end
    end
    for i = 1, #RG.editsNIL do
        local e = RG.editsNIL[i]
        if notIn[i] then
            local name = notIn[i]
            e.playerName = name
            e:SetText(name)
            e:SetCursorPosition(1)
            local _, cls = UnitClass(name)
            if cls then
                local r, g, b = ClassColor(cls)
                e:SetTextColor(r, g, b, 1)
            else
                e:SetTextColor(0.7, 0.7, 0.7, 1)
            end
            local role = UnitGroupRolesAssigned(name)
            if role == "HEALER" then
                e.roleIcon:SetAtlas("groupfinder-icon-role-large-heal"); e.roleIcon:Show()
            elseif role == "DAMAGER" then
                e.roleIcon:SetAtlas("groupfinder-icon-role-large-dps");  e.roleIcon:Show()
            elseif role == "TANK" then
                e.roleIcon:SetAtlas("groupfinder-icon-role-large-tank"); e.roleIcon:Show()
            else
                e.roleIcon:Hide()
            end
            e:Show()
        else
            e:SetText("")
            e.playerName = nil
            e.roleIcon:Hide()
            e:Show()
        end
    end
end

-- ─────────────────────────────────────────────────────────────────
--  Group assignment logic  (ported from MRT RaidGroups.lua)
-- ─────────────────────────────────────────────────────────────────
function RG:ApplyGroups(list)
    if not IsInRaid() then
        print("|cffFF6060RRT Raid Groups:|r Must be in a raid.")
        return
    end
    local fighting = {}
    for i = 1, 40 do
        if UnitAffectingCombat("raid"..i) then
            fighting[#fighting+1] = UnitName("raid"..i) or ("raid"..i)
        end
    end
    if #fighting > 0 then
        print("|cffFF6060RRT Raid Groups:|r Players in combat: " .. table.concat(fighting, ", "))
        return
    end

    local needGroup = {}
    local needPos   = {}
    local RLName    = GetRaidRosterInfo(1)
    local isRLFound = false

    for g = 1, 8 do
        local pos = 1
        -- RL first so position 1 is reserved
        for s = 1, 5 do
            local name = list[(g-1)*5+s]
            if name and name ~= "" and name == RLName then
                needGroup[name] = g
                needPos[name]   = pos
                pos = pos + 1
                isRLFound = true
                break
            end
        end
        for s = 1, 5 do
            local name = list[(g-1)*5+s]
            if name and name ~= "" and name ~= RLName and UnitExists(name) then
                needGroup[name] = g
                needPos[name]   = pos
                pos = pos + 1
            end
        end
    end

    local _, _, RLGroup = GetRaidRosterInfo(1)
    self.processData = {
        needGroup   = needGroup,
        needPos     = needPos,
        lockedUnit  = {},
        groupsReady = false,
        groupWithRL = isRLFound and 0 or RLGroup,
    }

    if RG.applyButton then RG.applyButton:Disable() end
    self:ProcessRoster()
end

function RG:ProcessRoster()
    local pd = self.processData
    if not pd or not pd.needGroup then return end

    -- abort on combat
    for i = 1, 40 do
        if UnitAffectingCombat("raid"..i) then
            print("|cffFF6060RRT Raid Groups:|r Combat started — aborting.")
            pd.needGroup = nil
            if RG.applyButton then RG.applyButton:Enable() end
            return
        end
    end

    local needGroup  = pd.needGroup
    local needPos    = pd.needPos
    local lockedUnit = pd.lockedUnit

    -- build current roster state
    local currentGroup = {}
    local currentPos   = {}
    local nameToID     = {}
    local groupSize    = {0,0,0,0,0,0,0,0}

    for i = 1, GetNumGroupMembers() do
        local name, _, subgroup = GetRaidRosterInfo(i)
        if name then
            local short = name:match("^(.-)%-")
            if short and needGroup[short] then name = short end
            currentGroup[name] = subgroup
            nameToID[name]     = i
            groupSize[subgroup] = groupSize[subgroup] + 1
            currentPos[name]   = groupSize[subgroup]
        end
    end

    -- Phase 1: SetRaidSubgroup where target group has space
    if not pd.groupsReady then
        local moved = false
        for name, grp in pairs(needGroup) do
            if currentGroup[name] and currentGroup[name] ~= grp then
                if groupSize[grp] < 5 then
                    SetRaidSubgroup(nameToID[name], grp)
                    groupSize[ currentGroup[name] ] = groupSize[ currentGroup[name] ] - 1
                    groupSize[grp] = groupSize[grp] + 1
                    moved = true
                end
            end
        end
        if moved then return end

        -- Phase 2: SwapRaidSubgroup between misplaced players
        local swapped = {}
        local didSwap = false
        for name, grp in pairs(needGroup) do
            if not swapped[name] and currentGroup[name] and currentGroup[name] ~= grp then
                for name2, grp2 in pairs(currentGroup) do
                    if not swapped[name2] and grp2 == grp
                       and (not needGroup[name2] or needGroup[name2] ~= grp2) then
                        SwapRaidSubgroup(nameToID[name], nameToID[name2])
                        swapped[name]  = true
                        swapped[name2] = true
                        didSwap = true
                        break
                    end
                end
            end
        end
        if didSwap then return end
        pd.groupsReady = true
    end

    -- Phase 3: fix positions within groups (3-way swap via bridge)
    local swapped = {}
    local didSwap = false
    for name, pos in pairs(needPos) do
        if currentGroup[name] == pd.groupWithRL then pos = pos + 1 end
        if not lockedUnit[name] and currentPos[name] and currentPos[name] ~= pos
           and nameToID[name] ~= 1 and not swapped[name] then
            local bridge
            for n2, g2 in pairs(currentGroup) do
                if g2 ~= currentGroup[name] and nameToID[n2] ~= 1 and not swapped[n2] then
                    bridge = n2; break
                end
            end
            local target
            for n2, p2 in pairs(currentPos) do
                if currentGroup[n2] == currentGroup[name] and p2 == pos
                   and nameToID[n2] ~= 1 and not swapped[n2] then
                    target = n2; break
                end
            end
            if bridge and target then
                lockedUnit[name] = true
                SwapRaidSubgroup(nameToID[name],  nameToID[bridge])
                SwapRaidSubgroup(nameToID[bridge], nameToID[target])
                SwapRaidSubgroup(nameToID[name],  nameToID[bridge])
                swapped[name]   = true
                swapped[target] = true
                swapped[bridge] = true
                didSwap = true
            end
        end
    end
    if didSwap then return end

    -- Done
    pd.needGroup = nil
    if RG.applyButton then RG.applyButton:Enable() end
end

-- GROUP_ROSTER_UPDATE drives the multi-step assignment
do
    local _frame = CreateFrame("Frame")
    _frame:RegisterEvent("GROUP_ROSTER_UPDATE")
    _frame:SetScript("OnEvent", function()
        if RG.processData and RG.processData.needGroup then
            if RG._rosterTimer then RG._rosterTimer:Cancel() end
            RG._rosterTimer = C_Timer.NewTimer(0.5, function()
                RG._rosterTimer = nil
                RG:ProcessRoster()
            end)
        end
    end)
end

-- ─────────────────────────────────────────────────────────────────
--  Profiles
-- ─────────────────────────────────────────────────────────────────
function RG:GetProfileList()
    local list = {}
    local profiles = RRT.RaidGroupsDB.profiles
    for i = #profiles, 1, -1 do
        list[#list+1] = { profiles[i].name, profiles[i] }
    end
    return list
end

function RG:SaveProfile(name)
    if not name or name:trim() == "" then return end
    local rec = { name = name, time = time() }
    for i = 1, 40 do
        local t = RG.edits[i] and RG.edits[i]:GetText() or ""
        if t:trim() ~= "" then rec[i] = t end
    end
    local profiles = RRT.RaidGroupsDB.profiles
    profiles[#profiles+1] = rec
    if RG.RefreshPresets then RG.RefreshPresets() end
end

function RG:LoadProfile(rec)
    for i = 1, 40 do
        local e = RG.edits[i]
        if e then
            e:SetText(rec[i] or "")
            e:SetCursorPosition(1)
        end
    end
    RG.UpdateColors()
    RG.UpdateNotInList()
    SaveCurrentGrid()
end

function RG:DeleteProfile(rec)
    local profiles = RRT.RaidGroupsDB.profiles
    for i = #profiles, 1, -1 do
        if profiles[i] == rec then tremove(profiles, i); break end
    end
    if RG.RefreshPresets then RG.RefreshPresets() end
end

-- ─────────────────────────────────────────────────────────────────
--  Build UI panel
-- ─────────────────────────────────────────────────────────────────
function RG:BuildPanel(parent)
    local Core                = RRT_NS.UI.Core
    local options_btn_tmpl    = Core.options_button_template
    local options_drop_tmpl   = Core.options_dropdown_template

    -- ── layout constants ─────────────────────────────────────────
    local EDIT_W   = 145   -- edit box width
    local EDIT_H   = 17    -- edit box height
    local ROW_H    = 19    -- row stride
    local HDR_H    = 16    -- group header height
    local GRP_GAP  = 6     -- gap between groups
    local GRP_H    = HDR_H + 5 * ROW_H + GRP_GAP  -- ~117 px per group
    local COL_GAP  = 14    -- gap between the two group columns
    local COL2_X   = EDIT_W + COL_GAP             -- x of right group column
    local NIL_X    = COL2_X * 2 + 16              -- "not in list" x start
    local NIL_W    = 140
    local PRE_X    = NIL_X + NIL_W + 12           -- presets x start
    local PRE_W    = 160
    local TOP_Y    = -26   -- first row y from parent top

    -- ── edit box factory ─────────────────────────────────────────
    local function MakeEdit(p, w, h)
        local e = CreateFrame("EditBox", nil, p, "BackdropTemplate")
        e:SetSize(w or EDIT_W, h or EDIT_H)
        e:SetAutoFocus(false)
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then e:SetFont(f, 9, fl or "") end end
        e:SetTextInsets(3, 20, 1, 1)
        e:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        e:SetBackdropColor(0.08, 0.08, 0.08, 0.9)
        e:SetBackdropBorderColor(0.30, 0.30, 0.30, 1)
        e:SetScript("OnEscapePressed", function(s) s:ClearFocus() end)
        e:SetScript("OnEnterPressed",  function(s) s:ClearFocus() end)
        -- role icon
        local icon = e:CreateTexture(nil, "OVERLAY")
        icon:SetSize(13, 13)
        icon:SetPoint("RIGHT", e, "RIGHT", -3, 0)
        icon:Hide()
        e.roleIcon = icon
        return e
    end

    -- ── drag & drop helpers ───────────────────────────────────────
    local function RestoreEditPosition(e)
        local g   = e._group
        local s   = e._slot
        local col = (g - 1) % 2
        local row = math.floor((g - 1) / 2)
        local x   = 5 + col * COL2_X
        local y   = TOP_Y - row * GRP_H - HDR_H - (s - 1) * ROW_H
        e:ClearAllPoints()
        e:SetPoint("TOPLEFT", parent, "TOPLEFT", x, y)
    end

    local function OnMainDragStop(self)
        self:StopMovingOrSizing()
        for i = 1, 40 do
            local other = RG.edits[i]
            if other and other ~= self and other:IsMouseOver() then
                local t1, t2 = self:GetText(), other:GetText()
                self:SetText(t2);  self:SetCursorPosition(1)
                other:SetText(t1); other:SetCursorPosition(1)
                RefreshEditColor(self)
                RefreshEditColor(other)
                RG.UpdateNotInList()
                break
            end
        end
        RestoreEditPosition(self)
        self:ClearFocus()
    end

    -- ── build 40 main grid edit boxes ────────────────────────────
    RG._groupHeaders = {}
    for g = 1, 8 do
        local col = (g - 1) % 2
        local row = math.floor((g - 1) / 2)
        local gx  = 5 + col * COL2_X
        local gy  = TOP_Y - row * GRP_H

        -- group label (theme-colored)
        local c   = RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        local hex = string.format("%02X%02X%02X",
            math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
        local groupName = "Group " .. g
        local hdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then hdr:SetFont(f, 9, fl or "") end end
        hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", gx, gy)
        hdr:SetText("|cFF" .. hex .. groupName .. "|r")
        hdr._groupName = groupName
        RG._groupHeaders[g] = hdr

        for s = 1, 5 do
            local idx = (g-1)*5 + s
            local e   = MakeEdit(parent)
            e._group  = g
            e._slot   = s
            e._idx    = idx
            e:SetPoint("TOPLEFT", parent, "TOPLEFT", gx, gy - HDR_H - (s-1)*ROW_H)
            e:SetMovable(true)
            e:RegisterForDrag("LeftButton")
            e:SetScript("OnDragStart", function(self) self:StartMoving() end)
            e:SetScript("OnDragStop",  OnMainDragStop)
            e:SetScript("OnTextChanged", function(self, userInput)
                RefreshEditColor(self)
                if userInput then
                    RG.UpdateNotInList()
                    SaveCurrentGrid()
                end
            end)
            e:SetScript("OnEnter", function(self)
                local name = self:GetText()
                if name and name ~= "" then
                    GameTooltip:SetOwner(self, "ANCHOR_CURSOR_RIGHT")
                    GameTooltip:SetUnit(name)
                    GameTooltip:Show()
                end
            end)
            e:SetScript("OnLeave", function() GameTooltip:Hide() end)
            RG.edits[idx] = e
        end
    end

    -- ── "Not in list" column ─────────────────────────────────────
    local nilHdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then nilHdr:SetFont(f, 9, fl or "") end end
    nilHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", NIL_X, TOP_Y)
    nilHdr._groupName = "Not in list"
    RG._groupHeaders[#RG._groupHeaders+1] = nilHdr
    nilHdr:SetText("|cFF" .. (function()
        local c = RRT.Settings and RRT.Settings.TabSelectionColor or {0.639,0.188,0.788,1}
        return string.format("%02X%02X%02X", math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
    end)() .. "Not in list|r")

    local NIL_ROW_H = 16
    local NIL_ROWS  = 40
    local W         = Core.window_width  - 130 - 12
    local H         = Core.window_height - 100 - 22
    local NIL_VIS_H = H - math.abs(TOP_Y) - HDR_H - 6

    local nilScroll = CreateFrame("ScrollFrame", "RRTNilScroll", parent)
    nilScroll:SetPoint("TOPLEFT", parent, "TOPLEFT", NIL_X, TOP_Y - HDR_H - 2)
    nilScroll:SetSize(NIL_W + 12, NIL_VIS_H)
    nilScroll:EnableMouseWheel(true)
    nilScroll:SetScript("OnMouseWheel", function(self, delta)
        local cur = self:GetVerticalScroll()
        local max = self:GetVerticalScrollRange()
        self:SetVerticalScroll(math.max(0, math.min(max, cur - delta * 30)))
    end)

    local nilContent = CreateFrame("Frame", nil, nilScroll)
    nilContent:SetSize(NIL_W, NIL_ROWS * NIL_ROW_H)
    nilScroll:SetScrollChild(nilContent)

    for i = 1, NIL_ROWS do
        local e = MakeEdit(nilContent, NIL_W, NIL_ROW_H - 2)
        e:SetPoint("TOPLEFT", nilContent, "TOPLEFT", 0, -(i-1)*NIL_ROW_H)
        e:SetEnabled(false)
        e._nilIndex  = i
        e.playerName = nil

        e:SetMovable(true)
        e:RegisterForDrag("LeftButton")
        e:SetScript("OnDragStart", function(self) self:StartMoving() end)
        e:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            for idx = 1, 40 do
                local target = RG.edits[idx]
                if target and target:IsMouseOver() then
                    local name = self.playerName or self:GetText()
                    target:SetText(name)
                    target:SetCursorPosition(1)
                    RefreshEditColor(target)
                    RG.UpdateNotInList()
                    break
                end
            end
            self:ClearAllPoints()
            self:SetPoint("TOPLEFT", nilContent, "TOPLEFT", 0, -(self._nilIndex-1)*NIL_ROW_H)
            self:ClearFocus()
        end)
        RG.editsNIL[i] = e
    end

    -- ── Presets panel ─────────────────────────────────────────────
    local preHdr = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    do local f, _, fl = GameFontNormalSmall:GetFont(); if f then preHdr:SetFont(f, 9, fl or "") end end
    preHdr:SetPoint("TOPLEFT", parent, "TOPLEFT", PRE_X, TOP_Y)
    preHdr._groupName = "Presets (Quick Load)"
    RG._groupHeaders[#RG._groupHeaders+1] = preHdr
    preHdr:SetText("|cFF" .. (function()
        local c = RRT.Settings and RRT.Settings.TabSelectionColor or {0.639,0.188,0.788,1}
        return string.format("%02X%02X%02X", math.floor(c[1]*255+0.5), math.floor(c[2]*255+0.5), math.floor(c[3]*255+0.5))
    end)() .. "Presets (Quick Load)|r")

    local PRE_ROW_H = 22
    local PRE_ROWS  = 16

    local presetContainer = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    presetContainer:SetPoint("TOPLEFT", parent, "TOPLEFT", PRE_X, TOP_Y - HDR_H - 2)
    presetContainer:SetSize(PRE_W, PRE_ROWS * PRE_ROW_H + 4)
    presetContainer:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8" })
    presetContainer:SetBackdropColor(0.05, 0.05, 0.05, 0.6)

    local presetBtns = {}
    for i = 1, PRE_ROWS do
        local row = CreateFrame("Button", nil, presetContainer, "BackdropTemplate")
        row:SetSize(PRE_W - 4, PRE_ROW_H - 2)
        row:SetPoint("TOPLEFT", presetContainer, "TOPLEFT", 2, -2 - (i-1)*PRE_ROW_H)
        row:SetBackdrop({
            bgFile   = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        row:SetBackdropColor(0.1, 0.1, 0.1, 0)
        row:SetBackdropBorderColor(0, 0, 0, 0)

        local lbl = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
        lbl:SetPoint("LEFT",  row, "LEFT",  4, 0)
        lbl:SetPoint("RIGHT", row, "RIGHT", -18, 0)
        lbl:SetJustifyH("LEFT")
        lbl:SetTextColor(0.9, 0.9, 0.9, 1)
        row.label = lbl

        -- delete X button
        local del = CreateFrame("Button", nil, row)
        del:SetSize(14, 14)
        del:SetPoint("RIGHT", row, "RIGHT", -2, 0)
        del:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        del:GetNormalTexture():SetVertexColor(0.85, 0.15, 0.15, 1)
        del:Hide()
        row.delBtn = del

        row:SetScript("OnEnter", function(self)
            self:SetBackdropColor(0.18, 0.18, 0.18, 0.9)
            self.delBtn:Show()
            if self.rec then
                GameTooltip:SetOwner(self, "ANCHOR_LEFT")
                GameTooltip:AddLine(self.rec.name, 1, 1, 1)
                if self.rec.time then
                    GameTooltip:AddLine(date("%Y-%m-%d  %H:%M", self.rec.time), 0.6, 0.6, 0.6)
                end
                GameTooltip:Show()
            end
        end)
        row:SetScript("OnLeave", function(self)
            self:SetBackdropColor(0.1, 0.1, 0.1, 0)
            if not self.delBtn:IsMouseOver() then self.delBtn:Hide() end
            GameTooltip:Hide()
        end)
        row:SetScript("OnClick", function(self)
            if self.rec then RG:LoadProfile(self.rec) end
        end)

        del:SetScript("OnClick", function(self)
            local r = self:GetParent()
            if r.rec then RG:DeleteProfile(r.rec) end
        end)
        del:SetScript("OnLeave", function(self)
            if not self:GetParent():IsMouseOver() then
                self:Hide()
                self:GetParent():SetBackdropColor(0.1, 0.1, 0.1, 0)
            end
        end)

        row:Hide()
        presetBtns[i] = row
    end

    function RG.RefreshPresets()
        local list = RG:GetProfileList()
        for i = 1, PRE_ROWS do
            local row   = presetBtns[i]
            local entry = list[i]
            if entry then
                row.label:SetText(entry[1])
                row.rec = entry[2]
                row:Show()
            else
                row:Hide()
                row.rec = nil
            end
        end
    end

    -- ── Button column (same style as sidebar nav buttons) ────────
    local BTN_W   = 150
    local BTN_H   = 22
    local BTN_X   = PRE_X + PRE_W + 12
    local BTN_GAP = 4

    local BACKDROP = {
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    }

    local function ApplyNormal(btn)
        btn:SetBackdropColor(0.1, 0.1, 0.1, 0.6)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.25, 0.8)
    end

    local function ApplyThemeActive(btn)
        local c = RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        btn:SetBackdropColor(c[1]*0.4, c[2]*0.4, c[3]*0.4, 0.8)
        btn:SetBackdropBorderColor(c[1], c[2], c[3], 1)
    end

    local nextBtnY = TOP_Y

    local function MakeBtn(label, onClick)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(BTN_W, BTN_H)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", BTN_X, nextBtnY)
        nextBtnY = nextBtnY - BTN_H - BTN_GAP
        btn:SetBackdrop(BACKDROP)
        ApplyNormal(btn)

        local lbl = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then lbl:SetFont(f, 9, fl or "") end end
        lbl:SetPoint("CENTER")
        lbl:SetText(label)
        lbl:SetTextColor(0.9, 0.9, 0.9, 1)
        btn.label = lbl

        btn:SetScript("OnEnter", function(self)
            if not self._pressed then
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            end
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self._pressed = false
            ApplyNormal(self)
            lbl:SetTextColor(0.9, 0.9, 0.9, 1)
        end)
        btn:SetScript("OnMouseDown", function(self)
            self._pressed = true
            ApplyThemeActive(self)
            lbl:SetTextColor(1, 1, 1, 1)
        end)
        btn:SetScript("OnMouseUp", function(self)
            self._pressed = false
            if self:IsMouseOver() then
                self:SetBackdropColor(0.15, 0.15, 0.15, 0.8)
            else
                ApplyNormal(self)
                lbl:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end)
        btn:SetScript("OnClick", onClick)
        return btn
    end

    local function MakeSeparator(text)
        local sep = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then sep:SetFont(f, 9, fl or "") end end
        sep:SetPoint("TOPLEFT", parent, "TOPLEFT", BTN_X, nextBtnY)
        sep:SetWidth(BTN_W)
        sep:SetJustifyH("LEFT")
        sep:SetTextColor(0.5, 0.5, 0.5, 1)
        sep:SetText(text)
        nextBtnY = nextBtnY - 16
    end

    -- ── Buttons ───────────────────────────────────────────────────
    MakeSeparator("Roster")

    MakeBtn("Load Current Roster", function()
        local roster = {}
        for i = 1, 8 do roster[i] = {} end
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name then tinsert(roster[subgroup], name) end
        end
        for g = 1, 8 do
            for s = 1, 5 do
                local e = RG.edits[(g-1)*5+s]
                if e then
                    e:SetText(roster[g][s] or "")
                    e:SetCursorPosition(1)
                end
            end
        end
        RG.UpdateColors()
        RG.UpdateNotInList()
        SaveCurrentGrid()
    end)

    MakeBtn("Fill from Roster", function()
        -- Place each player not yet in the grid into their current raid subgroup
        local inGrid = {}
        for i = 1, 40 do
            local t = RG.edits[i] and RG.edits[i]:GetText() or ""
            if t ~= "" then inGrid[t] = true end
        end
        for i = 1, GetNumGroupMembers() do
            local name, _, subgroup = GetRaidRosterInfo(i)
            if name then
                local short = name:match("^(.-)%-") or name
                if not inGrid[name] and not inGrid[short] then
                    for s = 1, 5 do
                        local idx = (subgroup - 1) * 5 + s
                        local e = RG.edits[idx]
                        if e and e:GetText() == "" then
                            e:SetText(short)
                            e:SetCursorPosition(1)
                            inGrid[short] = true
                            break
                        end
                    end
                end
            end
        end
        RG.UpdateColors()
        RG.UpdateNotInList()
        SaveCurrentGrid()
    end)

    MakeBtn("Clear All", function()
        for i = 1, 40 do
            if RG.edits[i] then RG.edits[i]:SetText("") end
        end
        RG.UpdateColors()
        RG.UpdateNotInList()
        SaveCurrentGrid()
    end)

    nextBtnY = nextBtnY - 6
    RG.applyButton = MakeBtn("Apply Groups", function()
        local list = {}
        for i = 1, 40 do
            list[i] = RG.edits[i] and RG.edits[i]:GetText() or ""
        end
        RG:ApplyGroups(list)
    end)

    nextBtnY = nextBtnY - 10
    MakeSeparator("Presets")

    -- Save Preset popup
    local savePopup
    local function ShowSavePopup()
        if savePopup then savePopup:Show(); return end

        local c = RRT.Settings and RRT.Settings.TabSelectionColor or {0.639, 0.188, 0.788, 1}
        savePopup = CreateFrame("Frame", "RRTRaidGroupSavePopup", UIParent, "BackdropTemplate")
        savePopup:SetSize(280, 74)
        savePopup:SetPoint("CENTER")
        savePopup:SetFrameStrata("DIALOG")
        savePopup:SetBackdrop(BACKDROP)
        savePopup:SetBackdropColor(0.08, 0.08, 0.08, 0.97)
        savePopup:SetBackdropBorderColor(c[1], c[2], c[3], 1)

        local popLbl = savePopup:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then popLbl:SetFont(f, 9, fl or "") end end
        popLbl:SetPoint("TOPLEFT", savePopup, "TOPLEFT", 10, -10)
        popLbl:SetText("Preset name:")

        local entry = CreateFrame("EditBox", nil, savePopup, "BackdropTemplate")
        entry:SetSize(182, 22)
        entry:SetPoint("TOPLEFT", popLbl, "BOTTOMLEFT", 0, -4)
        entry:SetAutoFocus(true)
        do local f, _, fl = GameFontNormalSmall:GetFont(); if f then entry:SetFont(f, 9, fl or "") end end
        entry:SetTextInsets(4, 4, 1, 1)
        entry:SetBackdrop(BACKDROP)
        entry:SetBackdropColor(0.06, 0.06, 0.06, 1)
        entry:SetBackdropBorderColor(0.35, 0.35, 0.35, 1)

        local function DoSave()
            local name = entry:GetText()
            if name and name:trim() ~= "" then RG:SaveProfile(name) end
            entry:SetText("")
            savePopup:Hide()
        end
        entry:SetScript("OnEnterPressed",  DoSave)
        entry:SetScript("OnEscapePressed", function() savePopup:Hide() end)

        local okBtn = DF:CreateButton(savePopup, DoSave, 70, 22, "Save")
        okBtn:SetPoint("LEFT", entry, "RIGHT", 5, 0)
        if options_btn_tmpl then okBtn:SetTemplate(options_btn_tmpl) end

        savePopup:Show()
    end

    MakeBtn("Save Preset", ShowSavePopup)

    -- ── Theme color callback: update headers ─────────────────────
    RRT_NS.ThemeColorCallbacks = RRT_NS.ThemeColorCallbacks or {}
    tinsert(RRT_NS.ThemeColorCallbacks, function(r, g, b)
        if savePopup then savePopup:SetBackdropBorderColor(r, g, b, 1) end
        if RG._groupHeaders then
            local hex = string.format("%02X%02X%02X",
                math.floor(r*255+0.5), math.floor(g*255+0.5), math.floor(b*255+0.5))
            for _, hdr in ipairs(RG._groupHeaders) do
                hdr:SetText("|cFF" .. hex .. hdr._groupName .. "|r")
            end
        end
    end)

    -- ── GROUP_ROSTER_UPDATE refresh when panel is visible ─────────
    local evFrame = CreateFrame("Frame", nil, parent)
    evFrame:SetPoint("TOPLEFT"); evFrame:SetSize(1, 1)
    evFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
    evFrame:SetScript("OnEvent", function()
        if parent:IsVisible() then
            RG.UpdateColors()
            RG.UpdateNotInList()
        end
    end)

    parent:SetScript("OnShow", function()
        RG.UpdateColors()
        RG.UpdateNotInList()
        RG.RefreshPresets()
    end)

    -- initial fill — restore grid from last saved state
    local saved = RRT.RaidGroupsDB and RRT.RaidGroupsDB.current
    if saved then
        for i = 1, 40 do
            local e = RG.edits[i]
            if e then
                e:SetText(saved[i] or "")
                e:SetCursorPosition(1)
            end
        end
        RG.UpdateColors()
    end
    RG.RefreshPresets()
    RG.UpdateNotInList()
end

-- ─────────────────────────────────────────────────────────────────
--  Export
-- ─────────────────────────────────────────────────────────────────
RRT_NS.UI = RRT_NS.UI or {}
RRT_NS.UI.RaidGroups = {
    BuildRaidGroupsPanel = function(panel) RG:BuildPanel(panel) end,
}
